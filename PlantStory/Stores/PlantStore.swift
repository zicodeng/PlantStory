import Combine
import Foundation

@MainActor
final class PlantStore: ObservableObject {
    static let shared = PlantStore()

    @Published private(set) var plants: [Plant] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maxCareHistoryEntries = 10
    private var needsSaveAfterLoad = false

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = applicationSupport
            .appendingPathComponent("PlantStory", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destinationURL = directory.appendingPathComponent("plants.json")
        let legacyDirectoryName = ["Plant", "Care"].joined()
        let legacyURL = applicationSupport
            .appendingPathComponent(legacyDirectoryName, isDirectory: true)
            .appendingPathComponent("plants.json")
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

    func add(_ plant: Plant) {
        plants.insert(normalized(plant), at: 0)
        save()
    }

    func update(_ plant: Plant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        let previousFilenames = filenames(in: plants[index].photos)
        plants[index] = normalized(plant)
        if save() {
            PhotoFileStore.delete(previousFilenames.subtracting(filenames(in: plants[index].photos)))
        }
    }

    func delete(at offsets: IndexSet) {
        var removedFilenames = Set<String>()
        for index in offsets.sorted(by: >) {
            WateringReminderService.shared.cancel(plantID: plants[index].id)
            removedFilenames.formUnion(filenames(in: plants[index].photos))
            plants.remove(at: index)
        }
        if save() {
            PhotoFileStore.delete(removedFilenames)
        }
    }

    func delete(_ plant: Plant) {
        WateringReminderService.shared.cancel(plantID: plant.id)
        let removedFilenames = filenames(in: plant.photos)
        plants.removeAll { $0.id == plant.id }
        if save() {
            PhotoFileStore.delete(removedFilenames)
        }
    }

    func water(_ plant: Plant, on date: Date = .now) {
        water(plantID: plant.id, on: date)
    }

    func water(plantID: UUID, on date: Date = .now) {
        guard let index = plants.firstIndex(where: { $0.id == plantID }) else { return }
        plants[index].wateringHistory = cappedHistory(plants[index].wateringHistory + [date])
        plants[index].wateringReminder?.snoozedUntil = nil
        save()
    }

    func setWateringReminder(_ reminder: WateringReminder?, for plantID: UUID) {
        guard let index = plants.firstIndex(where: { $0.id == plantID }) else { return }
        plants[index].wateringReminder = reminder
        save()
    }

    func snoozeWateringReminder(for plantID: UUID, until date: Date) {
        guard let index = plants.firstIndex(where: { $0.id == plantID }),
              plants[index].wateringReminder != nil else { return }
        plants[index].wateringReminder?.snoozedUntil = date
        save()
    }

    func removeWatering(for plant: Plant, at offsets: IndexSet) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        let ordered = plants[index].wateringHistory.sorted(by: >)
        let removedDates = offsets.map { ordered[$0] }
        plants[index].wateringHistory.removeAll { removedDates.contains($0) }
        save()
    }

    func removeWatering(for plant: Plant, on date: Date) {
        guard let plantIndex = plants.firstIndex(where: { $0.id == plant.id }),
              let wateringIndex = plants[plantIndex].wateringHistory.firstIndex(of: date) else { return }
        plants[plantIndex].wateringHistory.remove(at: wateringIndex)
        save()
    }

    func fertilize(_ plant: Plant, on date: Date = .now) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        var history = plants[index].fertilizingHistory ?? []
        history.append(date)
        plants[index].fertilizingHistory = cappedHistory(history)
        save()
    }

    func removeFertilizing(for plant: Plant, on date: Date) {
        guard let plantIndex = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        var history = plants[plantIndex].fertilizingHistory ?? []
        guard let fertilizingIndex = history.firstIndex(of: date) else { return }
        history.remove(at: fertilizingIndex)
        plants[plantIndex].fertilizingHistory = history
        save()
    }

    func replaceAll(with restoredPlants: [Plant]) throws {
        let restoredPlants = restoredPlants.map { normalized($0) }
        let data = try encoder.encode(restoredPlants)
        try data.write(to: fileURL, options: .atomic)
        plants = restoredPlants
        WidgetWateringSnapshotWriter.update(plants: plants)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL, options: [.mappedIfSafe]),
              let savedPlants = try? decoder.decode([Plant].self, from: data) else { return }
        let normalizedPlants = savedPlants.map {
            normalized($0, materializePhotos: false)
        }
        plants = normalizedPlants
        needsSaveAfterLoad = normalizedPlants != savedPlants
    }

    private func normalized(
        _ plant: Plant,
        materializePhotos: Bool = true
    ) -> Plant {
        var plant = plant
        if materializePhotos {
            plant.photos = PhotoFileStore.materialize(plant.photos)
        }
        if plant.photos.isEmpty {
            plant.cardPhotoIndex = nil
        } else if let cardPhotoIndex = plant.cardPhotoIndex,
                  !plant.photos.indices.contains(cardPhotoIndex) {
            plant.cardPhotoIndex = plant.photos.indices.last
        }
        plant.wateringHistory = cappedHistory(plant.wateringHistory)
        plant.fertilizingHistory = cappedHistory(plant.fertilizingEvents)
        if var reminder = plant.wateringReminder {
            reminder.intervalDays = min(max(reminder.intervalDays, 1), 90)
            reminder.hour = min(max(reminder.hour, 0), 23)
            reminder.minute = min(max(reminder.minute, 0), 59)
            if var intervals = reminder.seasonalIntervals {
                for season in WateringSeason.allCases {
                    intervals[season] = min(max(intervals[season], 1), 90)
                }
                reminder.seasonalIntervals = intervals
            }
            plant.wateringReminder = reminder
        }
        return plant
    }

    var photoMigrationJobs: [PhotoStorageMigrationJob] {
        plants.flatMap { plant in
            plant.photos.enumerated().compactMap { index, photo in
                guard let data = photo.embeddedData else { return nil }
                return PhotoStorageMigrationJob(
                    key: "plant-\(plant.id.uuidString)-\(index)",
                    owner: .plant(plant.id),
                    photoIndex: index,
                    original: photo,
                    data: data
                )
            }
        }
    }

    var referencedPhotoFilenames: Set<String> {
        Set(plants.flatMap(\.photos).compactMap(\.filename))
    }

    func completePhotoMigration(
        replacements: [PhotoStorageMigrationReplacement]
    ) throws {
        guard !replacements.isEmpty || needsSaveAfterLoad else { return }
        let originalPlants = plants

        for replacement in replacements {
            guard case let .plant(id) = replacement.owner,
                  let plantIndex = plants.firstIndex(where: { $0.id == id }),
                  plants[plantIndex].photos.indices.contains(replacement.photoIndex),
                  plants[plantIndex].photos[replacement.photoIndex] == replacement.original else {
                continue
            }
            plants[plantIndex].photos[replacement.photoIndex] = replacement.migrated
        }

        do {
            try persistVerified()
            needsSaveAfterLoad = false
            WidgetWateringSnapshotWriter.update(plants: plants)
        } catch {
            plants = originalPlants
            throw error
        }
    }

    #if DEBUG
    func prepareLegacyPhotoMigrationTest() throws -> Int {
        let originalPlants = plants
        var convertedCount = 0

        for plantIndex in plants.indices {
            for photoIndex in plants[plantIndex].photos.indices {
                let photo = plants[plantIndex].photos[photoIndex]
                guard photo.filename != nil else { continue }
                guard let data = photo.loadData() else {
                    plants = originalPlants
                    throw CocoaError(.fileReadCorruptFile)
                }
                plants[plantIndex].photos[photoIndex] = PlantPhotoAsset(data: data)
                convertedCount += 1
            }
        }

        guard convertedCount > 0 else { return 0 }
        do {
            try persistVerified()
            needsSaveAfterLoad = false
            WidgetWateringSnapshotWriter.update(plants: plants)
            return convertedCount
        } catch {
            plants = originalPlants
            throw error
        }
    }
    #endif

    private func cappedHistory(_ history: [Date]) -> [Date] {
        Array(history.sorted(by: >).prefix(maxCareHistoryEntries))
    }

    private func filenames(in photos: [PlantPhotoAsset]) -> Set<String> {
        Set(photos.compactMap(\.filename))
    }

    @discardableResult
    private func save() -> Bool {
        do {
            let data = try encoder.encode(plants)
            try data.write(to: fileURL, options: .atomic)
            WidgetWateringSnapshotWriter.update(plants: plants)
            return true
        } catch {
            return false
        }
    }

    private func persistVerified() throws {
        let data = try encoder.encode(plants)
        _ = try decoder.decode([Plant].self, from: data)
        try data.write(to: fileURL, options: .atomic)
        let persistedData = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
        _ = try decoder.decode([Plant].self, from: persistedData)
    }
}
