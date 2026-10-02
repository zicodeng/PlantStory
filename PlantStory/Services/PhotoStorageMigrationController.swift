import Combine
import CryptoKit
import Foundation

enum PhotoStorageMigrationOwner: Equatable {
    case plant(UUID)
    case wildFind(UUID)
}

struct PhotoStorageMigrationJob {
    let key: String
    let owner: PhotoStorageMigrationOwner
    let photoIndex: Int
    let original: PlantPhotoAsset
    let data: Data
}

struct PhotoStorageMigrationReplacement {
    let owner: PhotoStorageMigrationOwner
    let photoIndex: Int
    let original: PlantPhotoAsset
    let migrated: PlantPhotoAsset
}

@MainActor
final class PhotoStorageMigrationController: ObservableObject {
    enum Status: Equatable {
        case checking
        case ready(completed: Int, total: Int)
        case optimizing(completed: Int, total: Int)
        case paused(completed: Int, total: Int)
        case lowStorage(required: Int64, available: Int64)
        case failed
        case complete(total: Int)
        case notNeeded
    }

    @Published private(set) var status: Status = .checking

    private weak var plantStore: PlantStore?
    private weak var wildFindStore: WildFindStore?
    private var migrationTask: Task<Void, Never>?
    private var isConfigured = false

    private static let pausedKey = "photoStorageMigration.isPaused"
    private static let completedTotalKey = "photoStorageMigration.completedTotal"
    private static let targetTotalKey = "photoStorageMigration.targetTotal"

    var shouldShowInSettings: Bool {
        switch status {
        case .notNeeded, .checking:
            return false
        default:
            return true
        }
    }

    func configure(plantStore: PlantStore, wildFindStore: WildFindStore) {
        guard !isConfigured else { return }
        self.plantStore = plantStore
        self.wildFindStore = wildFindStore
        isConfigured = true
        refreshStatus()
    }

    func startAutomaticallyIfEligible() async {
        guard isConfigured else { return }
        refreshStatus()
        guard case .ready = status else { return }

        do {
            try await Task.sleep(for: .seconds(2))
            try Task.checkCancellation()
        } catch {
            return
        }

        guard !UserDefaults.standard.bool(forKey: Self.pausedKey) else {
            refreshStatus()
            return
        }
        startOrResume()
    }

    func startOrResume() {
        guard migrationTask == nil else { return }
        UserDefaults.standard.set(false, forKey: Self.pausedKey)
        migrationTask = Task { [weak self] in
            await self?.runMigration()
        }
    }

    func pause() {
        UserDefaults.standard.set(true, forKey: Self.pausedKey)
        migrationTask?.cancel()
    }

    #if DEBUG
    var canPrepareLegacyTest: Bool {
        migrationTask == nil
    }

    func prepareLegacyTest() throws -> Int {
        guard migrationTask == nil else { return 0 }

        PhotoFileStore.removeMigrationJournal()
        do {
            let plantCount = try plantStore?.prepareLegacyPhotoMigrationTest() ?? 0
            let wildFindCount = try wildFindStore?.prepareLegacyPhotoMigrationTest() ?? 0
            let total = plantCount + wildFindCount

            guard total > 0 else { return 0 }
            resetForPausedLegacyTest()
            return total
        } catch {
            if !currentJobs.isEmpty {
                resetForPausedLegacyTest()
            }
            throw error
        }
    }

    private func resetForPausedLegacyTest() {
        UserDefaults.standard.removeObject(forKey: Self.completedTotalKey)
        UserDefaults.standard.removeObject(forKey: Self.targetTotalKey)
        UserDefaults.standard.set(true, forKey: Self.pausedKey)
        refreshStatus()
    }
    #endif

    private func refreshStatus() {
        let jobs = currentJobs
        guard !jobs.isEmpty else {
            finishAlreadyOptimizedState()
            return
        }

        let journal = loadJournal()
        let targetTotal = migrationTargetTotal(for: jobs.count)
        let finalizedCount = max(targetTotal - jobs.count, 0)
        let journalCount = jobs.reduce(into: 0) { count, job in
            guard let entry = journal.entries[job.key],
                  entry.byteCount == job.data.count,
                  PhotoFileStore.storedFileMatches(
                    filename: entry.filename,
                    expectedByteCount: entry.byteCount
                  ) else { return }
            count += 1
        }
        let progress = (
            completed: min(finalizedCount + journalCount, targetTotal),
            total: targetTotal
        )
        status = UserDefaults.standard.bool(forKey: Self.pausedKey)
            ? .paused(completed: progress.completed, total: progress.total)
            : .ready(completed: progress.completed, total: progress.total)
    }

    private func runMigration() async {
        defer { migrationTask = nil }

        let jobs = currentJobs
        guard !jobs.isEmpty else {
            finishAlreadyOptimizedState()
            return
        }

        do {
            let targetTotal = migrationTargetTotal(for: jobs.count)
            let finalizedCount = max(targetTotal - jobs.count, 0)
            status = .optimizing(completed: finalizedCount, total: targetTotal)
            let preparedJobs = try await prepare(jobs)
            try Task.checkCancellation()

            var journal = loadJournal()
            let reusableKeys = Set(preparedJobs.compactMap { job -> String? in
                guard let entry = journal.entries[job.job.key],
                      entry.digest == job.digest,
                      entry.byteCount == job.job.data.count,
                      PhotoFileStore.storedFileMatches(
                        filename: entry.filename,
                        expectedByteCount: entry.byteCount
                      ) else { return nil }
                return job.job.key
            })
            let remainingBytes = preparedJobs
                .filter { !reusableKeys.contains($0.job.key) }
                .reduce(Int64(0)) { $0 + Int64($1.job.data.count) }
            let safetyMargin = max(Int64(20 * 1_024 * 1_024), remainingBytes / 10)
            let requiredCapacity = remainingBytes + safetyMargin
            if remainingBytes > 0,
               let availableCapacity = PhotoFileStore.availableCapacity(),
               availableCapacity < requiredCapacity {
                status = .lowStorage(
                    required: requiredCapacity - availableCapacity,
                    available: availableCapacity
                )
                return
            }

            var replacements: [PhotoStorageMigrationReplacement] = []
            replacements.reserveCapacity(preparedJobs.count)
            var completed = finalizedCount
            status = .optimizing(completed: completed, total: targetTotal)

            for preparedJob in preparedJobs {
                try Task.checkCancellation()
                let job = preparedJob.job
                let entry: JournalEntry
                if reusableKeys.contains(job.key),
                   let existingEntry = journal.entries[job.key] {
                    entry = existingEntry
                } else {
                    let filename = "\(UUID().uuidString).jpg"
                    _ = try await store(job.data, filename: filename)
                    entry = JournalEntry(
                        filename: filename,
                        digest: preparedJob.digest,
                        byteCount: job.data.count
                    )
                    journal.entries[job.key] = entry
                    try saveJournal(journal)
                }

                replacements.append(
                    PhotoStorageMigrationReplacement(
                        owner: job.owner,
                        photoIndex: job.photoIndex,
                        original: job.original,
                        migrated: PlantPhotoAsset(filename: entry.filename)
                    )
                )
                completed += 1
                status = .optimizing(completed: completed, total: targetTotal)
            }

            try Task.checkCancellation()
            try plantStore?.completePhotoMigration(replacements: replacements)
            try wildFindStore?.completePhotoMigration(replacements: replacements)

            let remainingJobs = currentJobs
            guard remainingJobs.isEmpty else {
                refreshStatus()
                return
            }

            PhotoFileStore.removeMigrationJournal()
            let referencedFiles = (plantStore?.referencedPhotoFilenames ?? [])
                .union(wildFindStore?.referencedPhotoFilenames ?? [])
            PhotoFileStore.deleteUnreferencedFiles(keeping: referencedFiles)
            UserDefaults.standard.set(targetTotal, forKey: Self.completedTotalKey)
            UserDefaults.standard.removeObject(forKey: Self.targetTotalKey)
            UserDefaults.standard.set(false, forKey: Self.pausedKey)
            status = .complete(total: targetTotal)
        } catch is CancellationError {
            let jobs = currentJobs
            let targetTotal = migrationTargetTotal(for: jobs.count)
            let finalizedCount = max(targetTotal - jobs.count, 0)
            let completed = min(
                finalizedCount + completedJournalCount(for: jobs),
                targetTotal
            )
            status = .paused(completed: completed, total: targetTotal)
        } catch {
            status = .failed
        }
    }

    private var currentJobs: [PhotoStorageMigrationJob] {
        (plantStore?.photoMigrationJobs ?? []) + (wildFindStore?.photoMigrationJobs ?? [])
    }

    private func finishAlreadyOptimizedState() {
        do {
            try plantStore?.completePhotoMigration(replacements: [])
            try wildFindStore?.completePhotoMigration(replacements: [])
        } catch {
            status = .failed
            return
        }

        let targetTotal = UserDefaults.standard.integer(forKey: Self.targetTotalKey)
        if targetTotal > 0 {
            PhotoFileStore.removeMigrationJournal()
            let referencedFiles = (plantStore?.referencedPhotoFilenames ?? [])
                .union(wildFindStore?.referencedPhotoFilenames ?? [])
            PhotoFileStore.deleteUnreferencedFiles(keeping: referencedFiles)
            UserDefaults.standard.set(targetTotal, forKey: Self.completedTotalKey)
            UserDefaults.standard.removeObject(forKey: Self.targetTotalKey)
            UserDefaults.standard.set(false, forKey: Self.pausedKey)
        }

        let completedTotal = max(
            targetTotal,
            UserDefaults.standard.integer(forKey: Self.completedTotalKey)
        )
        if completedTotal > 0 {
            status = .complete(total: completedTotal)
        } else {
            status = .notNeeded
        }
    }

    private func completedJournalCount(for jobs: [PhotoStorageMigrationJob]) -> Int {
        let journal = loadJournal()
        return jobs.reduce(into: 0) { count, job in
            guard let entry = journal.entries[job.key],
                  entry.byteCount == job.data.count,
                  PhotoFileStore.storedFileMatches(
                    filename: entry.filename,
                    expectedByteCount: entry.byteCount
                  ) else { return }
            count += 1
        }
    }

    private func migrationTargetTotal(for currentJobCount: Int) -> Int {
        let storedTotal = UserDefaults.standard.integer(forKey: Self.targetTotalKey)
        let total = max(storedTotal, currentJobCount)
        if total != storedTotal {
            UserDefaults.standard.set(total, forKey: Self.targetTotalKey)
        }
        return total
    }

    private func prepare(
        _ jobs: [PhotoStorageMigrationJob]
    ) async throws -> [PreparedJob] {
        let task = Task.detached(priority: .utility) {
            try jobs.map { job in
                try Task.checkCancellation()
                let digest = SHA256.hash(data: job.data)
                    .map { String(format: "%02x", $0) }
                    .joined()
                return PreparedJob(job: job, digest: digest)
            }
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func store(_ data: Data, filename: String) async throws -> PlantPhotoAsset {
        let task = Task.detached(priority: .utility) {
            try Task.checkCancellation()
            return try PhotoFileStore.store(data, as: filename)
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private func loadJournal() -> MigrationJournal {
        guard let data = PhotoFileStore.migrationJournalData(),
              let journal = try? JSONDecoder().decode(MigrationJournal.self, from: data) else {
            return MigrationJournal()
        }
        return journal
    }

    private func saveJournal(_ journal: MigrationJournal) throws {
        let data = try JSONEncoder().encode(journal)
        try PhotoFileStore.writeMigrationJournal(data)
    }
}

private struct PreparedJob {
    let job: PhotoStorageMigrationJob
    let digest: String
}

private struct MigrationJournal: Codable {
    var entries: [String: JournalEntry] = [:]
}

private struct JournalEntry: Codable {
    let filename: String
    let digest: String
    let byteCount: Int
}
