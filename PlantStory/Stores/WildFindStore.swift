import Combine
import Foundation

@MainActor
final class WildFindStore: ObservableObject {
    @Published private(set) var finds: [WildFind] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var needsSaveAfterLoad = false

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = applicationSupport
            .appendingPathComponent("PlantStory", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destinationURL = directory.appendingPathComponent("wild-finds.json")
        let legacyDirectoryName = ["Plant", "Care"].joined()
        let legacyURL = applicationSupport
            .appendingPathComponent(legacyDirectoryName, isDirectory: true)
            .appendingPathComponent("wild-finds.json")
        if !FileManager.default.fileExists(atPath: destinationURL.path),
           FileManager.default.fileExists(atPath: legacyURL.path) {
            try? FileManager.default.copyItem(at: legacyURL, to: destinationURL)
        }
        fileURL = destinationURL

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func add(_ find: WildFind) {
        finds.insert(normalized(find), at: 0)
        save()
    }

    func update(_ find: WildFind) {
        guard let index = finds.firstIndex(where: { $0.id == find.id }) else { return }
        let previousFilenames = filenames(in: finds[index].photos)
        finds[index] = normalized(find)
        if save() {
            PhotoFileStore.delete(previousFilenames.subtracting(filenames(in: finds[index].photos)))
        }
    }

    func delete(_ find: WildFind) {
        let removedFilenames = filenames(in: find.photos)
        finds.removeAll { $0.id == find.id }
        if save() {
            PhotoFileStore.delete(removedFilenames)
        }
    }

    func replaceAll(with restoredFinds: [WildFind]) throws {
        let restoredFinds = restoredFinds.map { normalized($0) }
        let data = try encoder.encode(restoredFinds)
        try data.write(to: fileURL, options: .atomic)
        finds = restoredFinds
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL, options: [.mappedIfSafe]),
              let savedFinds = try? decoder.decode([WildFind].self, from: data) else { return }
        let normalizedFinds = savedFinds.map {
            normalized($0, materializePhotos: false)
        }
        finds = normalizedFinds
        needsSaveAfterLoad = normalizedFinds != savedFinds
    }

    private func normalized(
        _ find: WildFind,
        materializePhotos: Bool = true
    ) -> WildFind {
        var find = find
        if materializePhotos {
            find.photos = PhotoFileStore.materialize(find.photos)
        }
        return find
    }

    var photoMigrationJobs: [PhotoStorageMigrationJob] {
        finds.flatMap { find in
            find.photos.enumerated().compactMap { index, photo in
                guard let data = photo.embeddedData else { return nil }
                return PhotoStorageMigrationJob(
                    key: "wild-find-\(find.id.uuidString)-\(index)",
                    owner: .wildFind(find.id),
                    photoIndex: index,
                    original: photo,
                    data: data
                )
            }
        }
    }

    var referencedPhotoFilenames: Set<String> {
        Set(finds.flatMap(\.photos).compactMap(\.filename))
    }

    func completePhotoMigration(
        replacements: [PhotoStorageMigrationReplacement]
    ) throws {
        guard !replacements.isEmpty || needsSaveAfterLoad else { return }
        let originalFinds = finds

        for replacement in replacements {
            guard case let .wildFind(id) = replacement.owner,
                  let findIndex = finds.firstIndex(where: { $0.id == id }),
                  finds[findIndex].photos.indices.contains(replacement.photoIndex),
                  finds[findIndex].photos[replacement.photoIndex] == replacement.original else {
                continue
            }
            finds[findIndex].photos[replacement.photoIndex] = replacement.migrated
        }

        do {
            try persistVerified()
            needsSaveAfterLoad = false
        } catch {
            finds = originalFinds
            throw error
        }
    }

    #if DEBUG
    func prepareLegacyPhotoMigrationTest() throws -> Int {
        let originalFinds = finds
        var convertedCount = 0

        for findIndex in finds.indices {
            for photoIndex in finds[findIndex].photos.indices {
                let photo = finds[findIndex].photos[photoIndex]
                guard photo.filename != nil else { continue }
                guard let data = photo.loadData() else {
                    finds = originalFinds
                    throw CocoaError(.fileReadCorruptFile)
                }
                finds[findIndex].photos[photoIndex] = PlantPhotoAsset(data: data)
                convertedCount += 1
            }
        }

        guard convertedCount > 0 else { return 0 }
        do {
            try persistVerified()
            needsSaveAfterLoad = false
            return convertedCount
        } catch {
            finds = originalFinds
            throw error
        }
    }
    #endif

    private func filenames(in photos: [PlantPhotoAsset]) -> Set<String> {
        Set(photos.compactMap(\.filename))
    }

    @discardableResult
    private func save() -> Bool {
        do {
            let data = try encoder.encode(finds)
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func persistVerified() throws {
        let data = try encoder.encode(finds)
        _ = try decoder.decode([WildFind].self, from: data)
        try data.write(to: fileURL, options: .atomic)
        let persistedData = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
        _ = try decoder.decode([WildFind].self, from: persistedData)
    }
}
