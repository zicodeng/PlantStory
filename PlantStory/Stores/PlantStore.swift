import Combine
import Foundation

@MainActor
final class PlantStore: ObservableObject {
    @Published private(set) var plants: [Plant] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maxCareHistoryEntries = 10

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
        plants[index] = normalized(plant)
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            plants.remove(at: index)
        }
        save()
    }

    func delete(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
        save()
    }

    func water(_ plant: Plant, on date: Date = .now) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index].wateringHistory = cappedHistory(plants[index].wateringHistory + [date])
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
        let restoredPlants = restoredPlants.map(normalized)
        let data = try encoder.encode(restoredPlants)
        try data.write(to: fileURL, options: .atomic)
        plants = restoredPlants
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let savedPlants = try? decoder.decode([Plant].self, from: data) else { return }
        let normalizedPlants = savedPlants.map(normalized)
        plants = normalizedPlants
        if normalizedPlants != savedPlants {
            save()
        }
    }

    private func normalized(_ plant: Plant) -> Plant {
        var plant = plant
        plant.wateringHistory = cappedHistory(plant.wateringHistory)
        plant.fertilizingHistory = cappedHistory(plant.fertilizingEvents)
        return plant
    }

    private func cappedHistory(_ history: [Date]) -> [Date] {
        Array(history.sorted(by: >).prefix(maxCareHistoryEntries))
    }

    private func save() {
        guard let data = try? encoder.encode(plants) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
