import Foundation
import SwiftUI
import UserNotifications
import UIKit

enum WateringReminderText {
    static func schedule(_ reminder: WateringReminder) -> String {
        let time = timeString(hour: reminder.hour, minute: reminder.minute)
        if reminder.intervalDays == 1 {
            return AppLocalization.string("Every day at %@", time)
        }
        return AppLocalization.string("Every %lld days at %@", Int64(reminder.intervalDays), time)
    }

    static func nextCheck(for plant: Plant, now: Date = .now) -> String? {
        guard let dueDate = plant.nextWateringReminderDate(now: now) else { return nil }
        if dueDate <= now {
            return AppLocalization.string("Due now")
        }
        return AppLocalization.string(
            "Next check: %@",
            AppLocalization.dateString(dueDate, dateStyle: .medium, timeStyle: .short)
        )
    }

    static func cardStatus(for plant: Plant, now: Date = .now) -> LocalizedStringKey? {
        guard let dueDate = plant.nextWateringReminderDate(now: now) else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: dueDate)
        let dayDifference = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        if dayDifference < 0 {
            return "Overdue \(abs(dayDifference)) days"
        }
        if dayDifference == 0 {
            return "Due today"
        }
        if dayDifference == 1 {
            return "Tomorrow"
        }
        return "In \(dayDifference) days"
    }

    static func timeString(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        let formatter = DateFormatter()
        formatter.locale = AppLocalization.currentLocale
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@MainActor
final class WateringReminderService {
    static let shared = WateringReminderService()

    static let categoryIdentifier = "PLANTSTORY_WATERING_REMINDER"
    static let wateredActionIdentifier = "PLANTSTORY_WATERED"
    static let remindTomorrowActionIdentifier = "PLANTSTORY_REMIND_TOMORROW"
    static let plantIDUserInfoKey = "plantID"

    private let center = UNUserNotificationCenter.current()
    private let requestPrefix = "watering-reminder-"
    private let maximumScheduledOccurrencesPerPlant = 4
    private let notificationBudget = 60

    private init() {}

    func configureNotificationCategories() {
        let watered = UNNotificationAction(
            identifier: Self.wateredActionIdentifier,
            title: AppLocalization.string("Watered"),
            options: []
        )
        let remindTomorrow = UNNotificationAction(
            identifier: Self.remindTomorrowActionIdentifier,
            title: AppLocalization.string("Remind Tomorrow"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [watered, remindTomorrow],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorizationIfNeeded() async -> UNAuthorizationStatus {
        let status = await authorizationStatus()
        guard status == .notDetermined else { return status }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return await authorizationStatus()
        }
        return await authorizationStatus()
    }

    func reconcile(plants: [Plant]) async {
        configureNotificationCategories()

        let pending = await center.pendingNotificationRequests()
        let existingReminderIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(requestPrefix) }
        if !existingReminderIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: existingReminderIDs)
        }

        let activePlants = plants.filter {
            $0.wateringReminder != nil && !$0.isDeceased
        }
        let scheduledPlants = Array(
            activePlants
                .sorted {
                    ($0.nextWateringReminderDate() ?? .distantFuture) <
                    ($1.nextWateringReminderDate() ?? .distantFuture)
                }
                .prefix(notificationBudget)
        )
        let knownPlantIDs = plants.flatMap { plant in
            requestIdentifiers(for: plant.id)
        }
        center.removeDeliveredNotifications(withIdentifiers: knownPlantIDs)

        guard canSchedule(await authorizationStatus()) else { return }
        let occurrenceCount = min(
            maximumScheduledOccurrencesPerPlant,
            max(1, notificationBudget / max(scheduledPlants.count, 1))
        )
        for plant in scheduledPlants {
            try? await schedule(plant, occurrenceCount: occurrenceCount)
        }
    }

    func cancel(plantID: UUID) {
        let identifiers = requestIdentifiers(for: plantID)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func schedule(_ plant: Plant, occurrenceCount: Int) async throws {
        guard let reminder = plant.wateringReminder,
              let logicalDueDate = plant.nextWateringReminderDate() else { return }

        let calendar = Calendar.current
        let firstDeliveryDate = deliveryDate(for: logicalDueDate, reminder: reminder)

        for occurrence in 0..<occurrenceCount {
            let deliveryDate = calendar.date(
                byAdding: .day,
                value: reminder.intervalDays * occurrence,
                to: firstDeliveryDate
            ) ?? firstDeliveryDate
            let content = notificationContent(
                for: plant,
                reminder: reminder,
                occurrence: occurrence
            )
            let components = calendar.dateComponents(
                [.calendar, .timeZone, .year, .month, .day, .hour, .minute],
                from: deliveryDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: requestIdentifier(for: plant.id, occurrence: occurrence),
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }

    private func notificationContent(
        for plant: Plant,
        reminder: WateringReminder,
        occurrence: Int
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("Check %@’s soil", plant.name)
        if plant.lastWatered == nil {
            content.body = AppLocalization.string("A gentle reminder to see whether it needs water.")
        } else {
            let elapsedDays = reminder.intervalDays * (occurrence + 1)
            if elapsedDays == 1 {
                content.body = AppLocalization.string("It’s been a day since the last watering.")
            } else {
                content.body = AppLocalization.string(
                    "It’s been %lld days since the last watering.",
                    Int64(elapsedDays)
                )
            }
        }
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = [Self.plantIDUserInfoKey: plant.id.uuidString]
        return content
    }

    private func deliveryDate(for logicalDueDate: Date, reminder: WateringReminder) -> Date {
        let now = Date.now
        guard logicalDueDate <= now else { return logicalDueDate }

        var components = DateComponents()
        components.hour = reminder.hour
        components.minute = reminder.minute
        return Calendar.current.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(60)
    }

    private func requestIdentifier(for plantID: UUID, occurrence: Int) -> String {
        requestPrefix + plantID.uuidString + "-\(occurrence)"
    }

    private func requestIdentifiers(for plantID: UUID) -> [String] {
        let currentIdentifiers = (0..<maximumScheduledOccurrencesPerPlant).map {
            requestIdentifier(for: plantID, occurrence: $0)
        }
        // Include the original single-request identifier so development builds migrate cleanly.
        return currentIdentifiers + [requestPrefix + plantID.uuidString]
    }

    private func canSchedule(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }
}

final class PlantStoryAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in
            WateringReminderService.shared.configureNotificationCategories()
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let idString = response.notification.request.content.userInfo[
            WateringReminderService.plantIDUserInfoKey
        ] as? String,
        let plantID = UUID(uuidString: idString) else { return }

        await MainActor.run {
            switch response.actionIdentifier {
            case WateringReminderService.wateredActionIdentifier:
                PlantStore.shared.water(plantID: plantID)
            case WateringReminderService.remindTomorrowActionIdentifier:
                guard let plant = PlantStore.shared.plants.first(where: { $0.id == plantID }),
                      let reminder = plant.wateringReminder else { return }
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                let snoozedUntil = Calendar.current.date(
                    bySettingHour: reminder.hour,
                    minute: reminder.minute,
                    second: 0,
                    of: tomorrow
                ) ?? tomorrow
                PlantStore.shared.snoozeWateringReminder(for: plantID, until: snoozedUntil)
            default:
                AppNavigationStore.shared.showPlant(id: plantID)
            }
        }
    }
}
