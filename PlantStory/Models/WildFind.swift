import Foundation

struct WildFind: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var otherName: String?
    var species: String
    /// Optional so wild finds saved before general notes were added still decode correctly.
    var notes: String?
    /// Optional so wild finds saved before AI suggestions were added still decode correctly.
    var hasGeneratedAISuggestion: Bool?
    var discoveredDate: Date
    var photos: [Data]
    var photoDates: [Date]?
    var photoNotes: [String]?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        otherName: String? = nil,
        species: String = "",
        notes: String? = nil,
        hasGeneratedAISuggestion: Bool? = nil,
        discoveredDate: Date = .now,
        photos: [Data] = [],
        photoDates: [Date]? = nil,
        photoNotes: [String]? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.otherName = otherName
        self.species = species
        self.notes = notes
        self.hasGeneratedAISuggestion = hasGeneratedAISuggestion
        self.discoveredDate = discoveredDate
        self.photos = photos
        self.photoDates = photoDates
        self.photoNotes = photoNotes
        self.createdAt = createdAt
    }

    func dateForPhoto(at index: Int) -> Date {
        guard let photoDates, photoDates.indices.contains(index) else {
            return discoveredDate
        }
        return photoDates[index]
    }

    func noteForPhoto(at index: Int) -> String {
        guard let photoNotes, photoNotes.indices.contains(index) else { return "" }
        return photoNotes[index]
    }
}
