import Foundation

struct WildFind: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var otherName: String?
    var species: String
    /// Optional so wild finds saved before general notes were added still decode correctly.
    var notes: String?
    /// Retained only to migrate the short-lived plant-level location field into the first sighting.
    var location: String?
    /// Optional so wild finds saved before AI suggestions were added still decode correctly.
    var hasGeneratedAISuggestion: Bool?
    var discoveredDate: Date
    var photos: [Data]
    var photoDates: [Date]?
    var photoNotes: [String]?
    /// Optional so wild finds saved before per-photo sighting locations were added still decode correctly.
    var photoLocations: [String]?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        otherName: String? = nil,
        species: String = "",
        notes: String? = nil,
        location: String? = nil,
        hasGeneratedAISuggestion: Bool? = nil,
        discoveredDate: Date = .now,
        photos: [Data] = [],
        photoDates: [Date]? = nil,
        photoNotes: [String]? = nil,
        photoLocations: [String]? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.otherName = otherName
        self.species = species
        self.notes = notes
        self.location = location
        self.hasGeneratedAISuggestion = hasGeneratedAISuggestion
        self.discoveredDate = discoveredDate
        self.photos = photos
        self.photoDates = photoDates
        self.photoNotes = photoNotes
        self.photoLocations = photoLocations
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

    func locationForPhoto(at index: Int) -> String {
        if let photoLocations, photoLocations.indices.contains(index) {
            return photoLocations[index]
        }
        return index == 0 ? (location ?? "") : ""
    }
}
