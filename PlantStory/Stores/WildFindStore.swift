import Combine
import Foundation

@MainActor
final class WildFindStore: ObservableObject {
    @Published private(set) var finds: [WildFind] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

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
        finds.insert(find, at: 0)
        save()
    }

    func update(_ find: WildFind) {
        guard let index = finds.firstIndex(where: { $0.id == find.id }) else { return }
        finds[index] = find
        save()
    }

    func delete(_ find: WildFind) {
        finds.removeAll { $0.id == find.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let savedFinds = try? decoder.decode([WildFind].self, from: data) else { return }
        finds = savedFinds
    }

    private func save() {
        guard let data = try? encoder.encode(finds) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
