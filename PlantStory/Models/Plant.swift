import Foundation

struct Plant: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    /// Optional so plants saved before alternate-language names were added still decode correctly.
    var otherName: String?
    var species: String
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
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        otherName: String? = nil,
        species: String = "",
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
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.otherName = otherName
        self.species = species
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
        self.createdAt = createdAt
    }

    var daysRaised: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: acquisitionDate)
        let end = calendar.startOfDay(for: .now)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
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
}
