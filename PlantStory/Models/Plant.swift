import Foundation
import SwiftUI

enum WateringSeason: String, Codable, CaseIterable, Identifiable {
    static let storageKey = "activeWateringSeason"

    case spring
    case summer
    case fall
    case winter

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .spring: "Spring"
        case .summer: "Summer"
        case .fall: "Fall"
        case .winter: "Winter"
        }
    }

    var localizedTitle: String {
        switch self {
        case .spring: AppLocalization.string("Spring")
        case .summer: AppLocalization.string("Summer")
        case .fall: AppLocalization.string("Fall")
        case .winter: AppLocalization.string("Winter")
        }
    }

    var icon: String {
        switch self {
        case .spring: "camera.macro"
        case .summer: "sun.max.fill"
        case .fall: "leaf.fill"
        case .winter: "snowflake"
        }
    }

    var tint: Color {
        switch self {
        case .spring: .green
        case .summer: .orange
        case .fall: .brown
        case .winter: .blue
        }
    }

    static func suggested(for date: Date = .now, calendar: Calendar = .current) -> Self {
        switch calendar.component(.month, from: date) {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .fall
        default: .winter
        }
    }

    static var active: Self {
        guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
              let season = Self(rawValue: rawValue) else {
            return suggested()
        }
        return season
    }
}

struct SeasonalWateringIntervals: Codable, Equatable {
    var spring: Int
    var summer: Int
    var fall: Int
    var winter: Int

    init(defaultInterval: Int) {
        spring = defaultInterval
        summer = defaultInterval
        fall = defaultInterval
        winter = defaultInterval
    }

    subscript(season: WateringSeason) -> Int {
        get {
            switch season {
            case .spring: spring
            case .summer: summer
            case .fall: fall
            case .winter: winter
            }
        }
        set {
            switch season {
            case .spring: spring = newValue
            case .summer: summer = newValue
            case .fall: fall = newValue
            case .winter: winter = newValue
            }
        }
    }
}

struct WateringReminder: Codable, Equatable {
    var intervalDays: Int
    var hour: Int
    var minute: Int
    var startDate: Date
    var snoozedUntil: Date?
    /// Optional so reminders created before seasonal schedules were added still decode.
    var seasonalIntervals: SeasonalWateringIntervals?

    init(
        intervalDays: Int = 7,
        hour: Int = 9,
        minute: Int = 0,
        startDate: Date = .now,
        snoozedUntil: Date? = nil,
        seasonalIntervals: SeasonalWateringIntervals? = nil
    ) {
        self.intervalDays = intervalDays
        self.hour = hour
        self.minute = minute
        self.startDate = startDate
        self.snoozedUntil = snoozedUntil
        self.seasonalIntervals = seasonalIntervals
    }

    func effectiveIntervalDays(for season: WateringSeason = .active) -> Int {
        guard let seasonalIntervals else { return intervalDays }
        return seasonalIntervals[season]
    }

    var usesSeasonalSchedule: Bool {
        seasonalIntervals != nil
    }
}

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

    var title: LocalizedStringKey {
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
    /// Optional so plants saved before watering reminders were added still decode correctly.
    var wateringReminder: WateringReminder?
    /// Optional so plants saved before fertilizing history was added still decode correctly.
    var fertilizingHistory: [Date]?
    var photos: [Data]
    /// Optional so plants saved before garden card photo selection was added still decode correctly.
    var cardPhotoIndex: Int?
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
        wateringReminder: WateringReminder? = nil,
        fertilizingHistory: [Date]? = [],
        photos: [Data] = [],
        cardPhotoIndex: Int? = nil,
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
        self.wateringReminder = wateringReminder
        self.fertilizingHistory = fertilizingHistory
        self.photos = photos
        self.cardPhotoIndex = cardPhotoIndex
        self.photoDates = photoDates
        self.photoNotes = photoNotes
        self.photoEventTags = photoEventTags
        self.photoCustomEventTitles = photoCustomEventTitles
        self.createdAt = createdAt
    }

    var gardenCardPhoto: Data? {
        guard !photos.isEmpty else { return nil }
        guard let cardPhotoIndex, photos.indices.contains(cardPhotoIndex) else {
            return photos.last
        }
        return photos[cardPhotoIndex]
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

    func nextWateringReminderDate(
        now: Date = .now,
        calendar: Calendar = .current,
        season: WateringSeason = .active
    ) -> Date? {
        guard let reminder = wateringReminder, !isDeceased else { return nil }

        if let snoozedUntil = reminder.snoozedUntil, snoozedUntil > now {
            return snoozedUntil
        }

        let anchor = lastWatered ?? reminder.startDate
        guard let dueDay = calendar.date(
            byAdding: .day,
            value: reminder.effectiveIntervalDays(for: season),
            to: calendar.startOfDay(for: anchor)
        ) else { return nil }

        return calendar.date(
            bySettingHour: reminder.hour,
            minute: reminder.minute,
            second: 0,
            of: dueDay
        )
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
        var calendar = Calendar.current
        calendar.locale = AppLocalization.currentLocale
        let names = calendar.monthSymbols
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
