import SwiftUI
import UserNotifications

struct WateringReminderEditorView: View {
    @AppStorage(WateringSeason.storageKey) private var activeSeasonCode = WateringSeason.suggested().rawValue
    @EnvironmentObject private var store: PlantStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let plant: Plant

    @State private var isEnabled: Bool
    @State private var intervalDays: Int
    @State private var usesSeasonalSchedule: Bool
    @State private var seasonalIntervals: SeasonalWateringIntervals
    @State private var reminderTime: Date
    @State private var isSaving = false
    @State private var showingNotificationWarning = false

    private let presets = [3, 5, 7, 10, 14, 30]

    init(plant: Plant) {
        self.plant = plant
        let reminder = plant.wateringReminder
        let defaultInterval = reminder?.intervalDays ?? 7
        _isEnabled = State(initialValue: reminder != nil)
        _intervalDays = State(initialValue: defaultInterval)
        _usesSeasonalSchedule = State(initialValue: reminder?.usesSeasonalSchedule ?? false)
        _seasonalIntervals = State(
            initialValue: reminder?.seasonalIntervals
                ?? SeasonalWateringIntervals(defaultInterval: defaultInterval)
        )

        var components = DateComponents()
        components.hour = reminder?.hour ?? 9
        components.minute = reminder?.minute ?? 0
        _reminderTime = State(initialValue: Calendar.current.date(from: components) ?? .now)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Watering reminders", isOn: $isEnabled)
            } footer: {
                Text("Use reminders as a cue to check the soil—not as an instruction to water.")
            }

            if isEnabled {
                Section {
                    Toggle("Use seasonal intervals", isOn: $usesSeasonalSchedule)
                } footer: {
                    Text("Set one interval year-round, or choose a different interval for each season.")
                }

                if usesSeasonalSchedule {
                    Section {
                        LabeledContent("Active season") {
                            HStack(spacing: 5) {
                                Image(systemName: activeSeason.icon)
                                    .font(.caption.weight(.semibold))
                                Text(activeSeason.title)
                            }
                            .foregroundStyle(activeSeason.tint)
                        }

                        ForEach(WateringSeason.allCases) { season in
                            Stepper(value: intervalBinding(for: season), in: 1...90) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: season.icon)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(
                                                season == activeSeason
                                                    ? season.tint
                                                    : Color.secondary
                                            )
                                            .frame(width: 16)
                                        Text(season.title)
                                    }
                                    Spacer()
                                    Text(intervalText(seasonalIntervals[season]))
                                        .foregroundStyle(
                                            season == activeSeason ? season.tint : Color.secondary
                                        )
                                }
                            }
                        }
                    } header: {
                        Text("Seasonal intervals")
                    } footer: {
                        Text("The active season is shared by every plant. Change it in Settings under Watering Reminders.")
                    }
                } else {
                    Section("Check-in interval") {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { days in
                                    Button {
                                        intervalDays = days
                                    } label: {
                                        Text(AppLocalization.string("%lld days", Int64(days)))
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .foregroundStyle(intervalDays == days ? .white : Color("LeafGreen"))
                                            .background(
                                                intervalDays == days ? Color("LeafGreen") : Color("LeafGreen").opacity(0.12),
                                                in: Capsule()
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)

                        Stepper(value: $intervalDays, in: 1...90) {
                            LabeledContent("Custom interval") {
                                Text(intervalText(intervalDays))
                            }
                        }
                    }
                }

                Section("Reminder time") {
                    DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                Section("Preview") {
                    Label(scheduleText, systemImage: "bell.fill")
                    if let nextCheckText {
                        Text(nextCheckText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Watering Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isSaving)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .alert("Notifications are turned off", isPresented: $showingNotificationWarning) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
                dismiss()
            }
            Button("Not Now", role: .cancel) { dismiss() }
        } message: {
            Text("The reminder was saved, but PlantStory cannot alert you until notifications are enabled in iPhone Settings.")
        }
    }

    private func intervalText(_ days: Int) -> String {
        days == 1
            ? AppLocalization.string("Every day")
            : AppLocalization.string("Every %lld days", Int64(days))
    }

    private func intervalBinding(for season: WateringSeason) -> Binding<Int> {
        Binding(
            get: { seasonalIntervals[season] },
            set: { seasonalIntervals[season] = $0 }
        )
    }

    private var draftReminder: WateringReminder {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let existing = plant.wateringReminder
        return WateringReminder(
            intervalDays: intervalDays,
            hour: components.hour ?? 9,
            minute: components.minute ?? 0,
            startDate: existing?.startDate ?? .now,
            snoozedUntil: nil,
            seasonalIntervals: usesSeasonalSchedule ? seasonalIntervals : nil
        )
    }

    private var activeSeason: WateringSeason {
        WateringSeason(rawValue: activeSeasonCode) ?? .suggested()
    }

    private var scheduleText: String {
        WateringReminderText.schedule(draftReminder, season: activeSeason)
    }

    private var nextCheckText: String? {
        var draftPlant = plant
        draftPlant.wateringReminder = draftReminder
        return WateringReminderText.nextCheck(for: draftPlant, season: activeSeason)
    }

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        guard isEnabled else {
            store.setWateringReminder(nil, for: plant.id)
            WateringReminderService.shared.cancel(plantID: plant.id)
            dismiss()
            return
        }

        store.setWateringReminder(draftReminder, for: plant.id)
        let status = await WateringReminderService.shared.requestAuthorizationIfNeeded()
        await WateringReminderService.shared.reconcile(plants: store.plants)

        if status == .authorized || status == .provisional || status == .ephemeral {
            dismiss()
        } else {
            showingNotificationWarning = true
        }
    }
}

struct WateringRemindersSettingsView: View {
    @AppStorage(WateringSeason.storageKey) private var activeSeasonCode = WateringSeason.suggested().rawValue
    @EnvironmentObject private var store: PlantStore
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var activePlants: [Plant] {
        store.plants
            .filter { $0.wateringReminder != nil && !$0.isDeceased }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 9) {
                        sectionHeading("Notifications")

                        HStack(spacing: 14) {
                            Text("Status")
                                .font(.body)

                            Spacer(minLength: 12)

                            VStack(alignment: .trailing, spacing: 5) {
                                HStack(spacing: 7) {
                                    Image(systemName: notificationStatusIcon)
                                    Text(notificationStatusText)
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(notificationStatusColor)

                                if authorizationStatus == .denied {
                                    Button("Settings") { openNotificationSettings() }
                                        .font(.caption.weight(.semibold))
                                } else if authorizationStatus == .notDetermined {
                                    Button("Allow") {
                                        Task { await requestAuthorization() }
                                    }
                                    .font(.caption.weight(.semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )

                        Text("Reminders are scheduled on this iPhone. PlantStory does not use a server or upload reminder data.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        sectionHeading("Active season")

                        seasonSelector

                        Text("Choose the active season once. It applies to every plant using seasonal watering intervals.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        sectionHeading("Plant reminders")

                        Group {
                            if activePlants.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "bell.slash")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("No watering reminders")
                                        .font(.headline)
                                    Text("Open a plant and choose Set a watering reminder in its Watering section.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 26)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(activePlants.enumerated()), id: \.element.id) { index, plant in
                                        plantReminderRow(plant)
                                        if index < activePlants.count - 1 {
                                            Divider()
                                                .padding(.leading, 58)
                                        }
                                    }
                                }
                            }
                        }
                        .background(
                            Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Watering Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshAuthorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshAuthorizationStatus() }
        }
    }

    private func sectionHeading(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private var seasonSelector: some View {
        HStack(spacing: 4) {
            ForEach(WateringSeason.allCases) { season in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeSeasonCode = season.rawValue
                    }
                } label: {
                    HStack(spacing: seasonIconSpacing(for: season)) {
                        Image(systemName: season.icon)
                            .font(.caption.weight(.semibold))
                            .frame(width: 14)
                            .foregroundStyle(
                                season == activeSeason ? season.tint : Color.secondary
                            )
                        Text(season.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                season == activeSeason ? Color.primary : Color.secondary
                            )
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .contentShape(Rectangle())
                    .background(
                        season == activeSeason
                            ? season.tint.opacity(0.2)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(season.title)
                .accessibilityAddTraits(season == activeSeason ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Active season")
    }

    private func seasonIconSpacing(for season: WateringSeason) -> CGFloat {
        switch season {
        case .spring: 4
        case .winter: 2
        default: 3
        }
    }

    private func plantReminderRow(_ plant: Plant) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(plant.name)
                    .font(.headline)
                if let reminder = plant.wateringReminder {
                    Text(WateringReminderText.schedule(reminder, season: activeSeason))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let nextCheck = WateringReminderText.nextCheck(
                    for: plant,
                    season: activeSeason
                ) {
                    Text(nextCheck)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button {
                withAnimation {
                    store.setWateringReminder(nil, for: plant.id)
                    WateringReminderService.shared.cancel(plantID: plant.id)
                }
            } label: {
                Image(systemName: "bell.slash.fill")
                    .frame(width: 34, height: 34)
                    .background(.red.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            .accessibilityLabel(
                AppLocalization.string("Turn off reminder for %@", plant.name)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var notificationStatusText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            AppLocalization.string("Allowed")
        case .denied:
            AppLocalization.string("Off in iPhone Settings")
        case .notDetermined:
            AppLocalization.string("Not requested")
        @unknown default:
            AppLocalization.string("Unavailable")
        }
    }

    private var activeSeason: WateringSeason {
        WateringSeason(rawValue: activeSeasonCode) ?? .suggested()
    }

    private var notificationStatusIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: "checkmark.circle.fill"
        case .denied: "exclamationmark.triangle.fill"
        default: "questionmark.circle.fill"
        }
    }

    private var notificationStatusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: .green
        case .denied: .orange
        default: .secondary
        }
    }

    @MainActor
    private func requestAuthorization() async {
        authorizationStatus = await WateringReminderService.shared.requestAuthorizationIfNeeded()
        await WateringReminderService.shared.reconcile(plants: store.plants)
    }

    @MainActor
    private func refreshAuthorizationStatus() async {
        authorizationStatus = await WateringReminderService.shared.authorizationStatus()
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
