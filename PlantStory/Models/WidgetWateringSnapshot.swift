import Foundation

struct WidgetWateringItem: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let dueDate: Date
    let thumbnailData: Data?
}

struct WidgetWateringSnapshot: Codable, Equatable {
    let updatedAt: Date
    let languageCode: String
    let items: [WidgetWateringItem]

    static let empty = WidgetWateringSnapshot(
        updatedAt: .distantPast,
        languageCode: "en",
        items: []
    )
}

enum WidgetWateringSnapshotStore {
    static let appGroupIdentifier = "group.com.zicodeng.PlantStory"
    static let widgetKind = "PlantStoryWateringWidget"

    private static let snapshotKey = "wateringWidgetSnapshot"

    static func load() -> WidgetWateringSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetWateringSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    static func save(_ snapshot: WidgetWateringSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }
}
