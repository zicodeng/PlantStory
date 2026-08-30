import Foundation

enum PlantPhotoEventTag: String, Codable, CaseIterable, Identifiable {
    case repotted
    case pruned
    case fertilized
    case bloomed
    case newGrowth
    case pestDiscovered
    case treatmentApplied
    case cameHome
    case death
    case customEvent

    var id: Self { self }

    var title: String {
        switch self {
        case .repotted: "Repotted"
        case .pruned: "Pruned"
        case .fertilized: "Fertilized"
        case .bloomed: "Bloomed"
        case .newGrowth: "New growth"
        case .pestDiscovered: "Pest discovered"
        case .treatmentApplied: "Treatment applied"
        case .cameHome: "Came home"
        case .death: "Death"
        case .customEvent: "Custom event"
        }
    }

    var icon: String {
        switch self {
        case .repotted: "arrow.triangle.2.circlepath"
        case .pruned: "scissors"
        case .fertilized: "leaf.circle.fill"
        case .bloomed: "camera.macro"
        case .newGrowth: "leaf.fill"
        case .pestDiscovered: "ladybug.fill"
        case .treatmentApplied: "cross.case.fill"
        case .cameHome: "house.fill"
        case .death: "moon.stars.fill"
        case .customEvent: "sparkles"
        }
    }
}

struct Plant: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    /// Optional so plants saved before alternate-language names were added still decode correctly.
    var otherName: String?
    var species: String
    /// Optional so plants saved before locations were added still decode correctly.
    var location: String?
    var acquisitionDate: Date
    /// Calendar month numbers (1 = January). Optional so older saved plants still decode.
    var fertilizingMonths: [Int]?
    /// Calendar month numbers (1 = January). Optional so older saved plants still decode.
    var pruningMonths: [Int]?
    /// Optional so plants saved before AI suggestions were added still decode correctly.
    var hasGeneratedAISuggestion: Bool?
    var notes: String
    var wateringHistory: [Date]
    /// Optional so plants saved before fertilizing history was added still decode correctly.
    var fertilizingHistory: [Date]?
    var photos: [Data]
    /// Optional so plants saved by the first app version decode without migration errors.
    var photoDates: [Date]?
    /// Optional so plants saved before per-photo notes were added still decode correctly.
    var photoNotes: [String]?
    /// Optional so plants saved before timeline event tags were added still decode correctly.
    var photoEventTags: [PlantPhotoEventTag?]?
    /// Optional so plants saved before custom timeline event names were added still decode correctly.
    var photoCustomEventTitles: [String]?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        otherName: String? = nil,
        species: String = "",
        location: String? = nil,
        acquisitionDate: Date = .now,
        fertilizingMonths: [Int]? = nil,
        pruningMonths: [Int]? = nil,
        hasGeneratedAISuggestion: Bool? = nil,
        notes: String = "",
        wateringHistory: [Date] = [],
        fertilizingHistory: [Date]? = [],
        photos: [Data] = [],
        photoDates: [Date]? = nil,
        photoNotes: [String]? = nil,
        photoEventTags: [PlantPhotoEventTag?]? = nil,
        photoCustomEventTitles: [String]? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.otherName = otherName
        self.species = species
        self.location = location
        self.acquisitionDate = acquisitionDate
        self.fertilizingMonths = fertilizingMonths
        self.pruningMonths = pruningMonths
        self.hasGeneratedAISuggestion = hasGeneratedAISuggestion
        self.notes = notes
        self.wateringHistory = wateringHistory
        self.fertilizingHistory = fertilizingHistory
        self.photos = photos
        self.photoDates = photoDates
        self.photoNotes = photoNotes
        self.photoEventTags = photoEventTags
        self.photoCustomEventTitles = photoCustomEventTitles
        self.createdAt = createdAt
    }

    var daysRaised: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: acquisitionDate)
        let end = calendar.startOfDay(for: .now)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    /// A plant becomes a memorial when any photo is tagged as its death event.
    var deathDate: Date? {
        photos.indices
            .compactMap { index in
                eventTagForPhoto(at: index) == .death ? dateForPhoto(at: index) : nil
            }
            .min()
    }

    var isDeceased: Bool {
        deathDate != nil
    }

    var lastWatered: Date? {
        wateringHistory.max()
    }

    var fertilizingEvents: [Date] {
        fertilizingHistory ?? []
    }

    var lastFertilized: Date? {
        fertilizingEvents.max()
    }

    var fertilizingMonthNames: [String] {
        monthNames(for: fertilizingMonths)
    }

    var pruningMonthNames: [String] {
        monthNames(for: pruningMonths)
    }

    private func monthNames(for months: [Int]?) -> [String] {
        let names = Calendar.current.monthSymbols
        return Array(Set(months ?? []))
            .filter { (1...12).contains($0) }
            .sorted()
            .map { names[$0 - 1] }
    }

    func dateForPhoto(at index: Int) -> Date {
        guard let photoDates, photoDates.indices.contains(index) else {
            return acquisitionDate
        }
        return photoDates[index]
    }

    func noteForPhoto(at index: Int) -> String {
        guard let photoNotes, photoNotes.indices.contains(index) else { return "" }
        return photoNotes[index]
    }

    func eventTagForPhoto(at index: Int) -> PlantPhotoEventTag? {
        guard let photoEventTags, photoEventTags.indices.contains(index) else { return nil }
        return photoEventTags[index]
    }

    func customEventTitleForPhoto(at index: Int) -> String {
        guard let photoCustomEventTitles,
              photoCustomEventTitles.indices.contains(index) else { return "" }
        return photoCustomEventTitles[index]
    }
}
