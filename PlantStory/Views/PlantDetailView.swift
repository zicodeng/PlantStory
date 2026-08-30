import SwiftUI

private enum CareHistoryKind: String {
    case watering
    case fertilizing

    var entryTitle: String {
        switch self {
        case .watering: "watering entry"
        case .fertilizing: "fertilizing entry"
        }
    }
}

private struct CareHistoryDeletion: Identifiable {
    let id = UUID()
    let kind: CareHistoryKind
    let date: Date
}

struct PlantDetailView: View {
    @EnvironmentObject private var store: PlantStore
    @Environment(\.dismiss) private var dismiss
    let plant: Plant

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var careEntryToDelete: CareHistoryDeletion?
    @State private var showingAllWateringHistory = false
    @State private var showingAllFertilizingHistory = false
    @State private var heroPhoto: Data?

    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let waterBlue = Color(red: 0.22, green: 0.64, blue: 0.88)
    private let fertilizerGold = Color(red: 0.92, green: 0.56, blue: 0.16)

    init(plant: Plant) {
        self.plant = plant
        _heroPhoto = State(initialValue: plant.photos.randomElement())
    }

    private var currentPlant: Plant {
        store.plants.first(where: { $0.id == plant.id }) ?? plant
    }

    private var timelineEvents: [PlantTimelineEvent] {
        var result = [PlantTimelineEvent(
            id: "acquired-\(currentPlant.id)",
            date: currentPlant.acquisitionDate,
            kind: .acquired
        )]
        result += currentPlant.photos.indices.map { index in
            PlantTimelineEvent(
                id: "photo-\(index)",
                date: currentPlant.dateForPhoto(at: index),
                kind: .photo(
                    currentPlant.photos[index],
                    note: currentPlant.noteForPhoto(at: index),
                    eventTag: currentPlant.eventTagForPhoto(at: index),
                    customEventTitle: currentPlant.customEventTitleForPhoto(at: index)
                )
            )
        }
        return result.sorted { $0.date > $1.date }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                forest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        hero(width: max(0, geometry.size.width - 40))
                        metrics
                        if hasSeasonalCareSchedule {
                            seasonalCareSection
                        }
                        wateringSection
                        fertilizingSection
                        timelineSection
                        if !currentPlant.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            notesSection
                        }
                    }
                    .frame(width: max(0, geometry.size.width - 40))
                    .padding(.top, 16)
                    .padding(.bottom, 44)
                }
                .frame(width: geometry.size.width)
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(forest, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(lime)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEdit = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                PlantFormView(plant: currentPlant)
            }
        }
        .confirmationDialog(
            "Delete this plant?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.delete(currentPlant)
                dismiss()
            }
        } message: {
            Text("Its notes, photos, watering history, and fertilizing history will also be removed.")
        }
        .alert(item: $careEntryToDelete) { deletion in
            Alert(
                title: Text("Delete this \(deletion.kind.entryTitle)?"),
                message: Text("This removes the entry from \(currentPlant.name)’s history:\n\(deletion.date.formatted(date: .abbreviated, time: .shortened))"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteCareHistoryEntry(deletion)
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: currentPlant.photos) { _, photos in
            if let heroPhoto, photos.contains(heroPhoto) {
                return
            }
            heroPhoto = photos.randomElement()
        }
    }

    private func hero(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            PlantPhoto(data: heroPhoto, cornerRadius: 24)
                .frame(width: width, height: 310)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.76)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

            VStack(alignment: .leading, spacing: 8) {
                Label("PLANT PROFILE", systemImage: "leaf.fill")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(lime)

                Text(currentPlant.name)
                    .font(.system(size: 38, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                if let otherName = currentPlant.otherName, !otherName.isEmpty {
                    Text(otherName)
                        .font(.system(.headline, design: .serif, weight: .medium))
                        .foregroundStyle(.white.opacity(0.84))
                }
                if !currentPlant.species.isEmpty {
                    Text(currentPlant.species)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
            .padding(22)
        }
        .frame(width: width, height: 310)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
    }

    private var metrics: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                metricCard(
                    value: "\(currentPlant.daysRaised)",
                    label: "days raised",
                    icon: "sun.max.fill",
                    accent: lime
                )
                .containerRelativeFrame(.horizontal, count: 9, span: 4, spacing: 14)

                metricCard(
                    value: "\(currentPlant.wateringHistory.count)",
                    label: "waterings",
                    icon: "drop.fill",
                    accent: waterBlue
                )
                .containerRelativeFrame(.horizontal, count: 9, span: 4, spacing: 14)

                metricCard(
                    value: "\(currentPlant.fertilizingEvents.count)",
                    label: "fertilizations",
                    icon: "leaf.fill",
                    accent: fertilizerGold
                )
                .containerRelativeFrame(.horizontal, count: 9, span: 4, spacing: 14)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .accessibilityLabel("Plant statistics")
    }

    private func metricCard(value: String, label: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Label("Life timeline", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(currentPlant.photos.count) photos")
                    .font(.caption)
                    .foregroundStyle(lime)
                    .fixedSize()
            }

            VStack(spacing: 0) {
                ForEach(Array(timelineEvents.enumerated()), id: \.element.id) { index, event in
                    timelineRow(event, isLast: index == timelineEvents.count - 1)
                }
            }
        }
        .gardenCardStyle(panel: panel)
    }

    private func timelineRow(_ event: PlantTimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.color)
                        .frame(width: 32, height: 32)
                    Image(systemName: event.icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 3)
                        .frame(minHeight: event.hasPhotoNote ? 232 : (event.isPhoto ? 186 : 52))
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(event.date.formatted(date: .abbreviated, time: event.isPhoto ? .omitted : .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }

                if case let .photo(data, note, _, _) = event.kind {
                    if !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PlantPhoto(data: data, cornerRadius: 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var wateringSection: some View {
        careHistorySection(
            title: "Watering",
            status: lastWateredText,
            emptyMessage: "No waterings recorded yet.",
            actionTitle: "Water now",
            actionIcon: "drop.fill",
            rowIcon: "drop.circle.fill",
            accent: waterBlue,
            history: currentPlant.wateringHistory,
            isExpanded: $showingAllWateringHistory,
            historyKind: .watering,
            record: { store.water(currentPlant) }
        )
    }

    private var fertilizingSection: some View {
        careHistorySection(
            title: "Fertilizing",
            status: lastFertilizedText,
            emptyMessage: "No fertilizing recorded yet.",
            actionTitle: "Fertilize now",
            actionIcon: "leaf.fill",
            rowIcon: "leaf.circle.fill",
            accent: fertilizerGold,
            history: currentPlant.fertilizingEvents,
            isExpanded: $showingAllFertilizingHistory,
            historyKind: .fertilizing,
            record: { store.fertilize(currentPlant) }
        )
    }

    private func careHistorySection(
        title: String,
        status: String,
        emptyMessage: String,
        actionTitle: String,
        actionIcon: String,
        rowIcon: String,
        accent: Color,
        history: [Date],
        isExpanded: Binding<Bool>,
        historyKind: CareHistoryKind,
        record: @escaping () -> Void
    ) -> some View {
        let completeHistory = Array(history.sorted(by: >).prefix(10))
        let visibleHistory = Array(completeHistory.prefix(isExpanded.wrappedValue ? 10 : 3))

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button {
                    withAnimation { record() }
                } label: {
                    Label(actionTitle, systemImage: actionIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .foregroundStyle(.white)
                .fixedSize(horizontal: true, vertical: false)
            }

            if visibleHistory.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visibleHistory.enumerated()), id: \.element) { index, date in
                        HStack {
                            Image(systemName: rowIcon)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, accent)
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            Button(role: .destructive) {
                                careEntryToDelete = CareHistoryDeletion(
                                    kind: historyKind,
                                    date: date
                                )
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 34, height: 34)
                                    .background(.red.opacity(0.13), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red.opacity(0.9))
                            .accessibilityLabel("Delete \(historyKind.entryTitle) from \(date.formatted(date: .abbreviated, time: .shortened))")
                        }
                        .padding(.vertical, 13)
                        if index < visibleHistory.count - 1 {
                            Divider()
                                .overlay(.white.opacity(0.12))
                                .padding(.leading, 30)
                        }
                    }
                }

                if completeHistory.count > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.wrappedValue.toggle()
                        }
                    } label: {
                        Label(
                            isExpanded.wrappedValue
                                ? "Show less"
                                : "Show more (\(completeHistory.count - 3))",
                            systemImage: isExpanded.wrappedValue ? "chevron.up" : "chevron.down"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(accent)
                    .accessibilityHint(isExpanded.wrappedValue ? "Collapses history to three entries" : "Shows up to ten history entries")
                }
            }
        }
        .gardenCardStyle(panel: panel)
    }

    private func deleteCareHistoryEntry(_ deletion: CareHistoryDeletion) {
        withAnimation {
            switch deletion.kind {
            case .watering:
                store.removeWatering(for: currentPlant, on: deletion.date)
            case .fertilizing:
                store.removeFertilizing(for: currentPlant, on: deletion.date)
            }
        }
    }

    private var seasonalCareSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Seasonal care", systemImage: "calendar")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(.white)

            if !currentPlant.fertilizingMonthNames.isEmpty {
                seasonalCareRow(
                    title: "Best fertilizing months",
                    icon: "leaf.fill",
                    months: currentPlant.fertilizingMonthNames
                )
            }

            if !currentPlant.fertilizingMonthNames.isEmpty,
               !currentPlant.pruningMonthNames.isEmpty {
                Divider().overlay(.white.opacity(0.12))
            }

            if !currentPlant.pruningMonthNames.isEmpty {
                seasonalCareRow(
                    title: "Best pruning months",
                    icon: "scissors",
                    months: currentPlant.pruningMonthNames
                )
            }
        }
        .gardenCardStyle(panel: panel)
    }

    private func seasonalCareRow(title: String, icon: String, months: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            Text(months.joined(separator: "  •  "))
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(lime)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Notes", systemImage: "note.text")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(.white)
            Text(currentPlant.notes)
                .font(.body)
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .gardenCardStyle(panel: panel)
    }

    private var lastWateredText: String {
        guard let date = currentPlant.lastWatered else { return "Not watered yet" }
        return "Last watered \(date.formatted(.relative(presentation: .named)))"
    }

    private var lastFertilizedText: String {
        guard let date = currentPlant.lastFertilized else { return "Not fertilized yet" }
        return "Last fertilized \(date.formatted(.relative(presentation: .named)))"
    }

    private var hasSeasonalCareSchedule: Bool {
        !currentPlant.fertilizingMonthNames.isEmpty || !currentPlant.pruningMonthNames.isEmpty
    }
}

private struct PlantTimelineEvent: Identifiable {
    enum Kind {
        case photo(
            Data,
            note: String,
            eventTag: PlantPhotoEventTag?,
            customEventTitle: String
        )
        case acquired
    }

    let id: String
    let date: Date
    let kind: Kind

    var isPhoto: Bool {
        if case .photo = kind { return true }
        return false
    }

    var hasPhotoNote: Bool {
        if case let .photo(_, note, _, _) = kind { return !note.isEmpty }
        return false
    }

    var title: String {
        switch kind {
        case let .photo(_, _, eventTag, customEventTitle):
            if eventTag == .customEvent {
                let title = customEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                return title.isEmpty ? "Custom event" : title
            }
            return eventTag?.title ?? "A new moment"
        case .acquired: return "Came home"
        }
    }

    var icon: String {
        switch kind {
        case let .photo(_, _, eventTag, _): return eventTag?.icon ?? "camera.fill"
        case .acquired: return "house.fill"
        }
    }

    var color: Color {
        switch kind {
        case let .photo(_, _, eventTag, _): return photoColor(for: eventTag)
        case .acquired: return Color(red: 0.95, green: 0.62, blue: 0.25)
        }
    }

    private func photoColor(for eventTag: PlantPhotoEventTag?) -> Color {
        switch eventTag {
        case .repotted: Color(red: 0.68, green: 0.45, blue: 0.26)
        case .pruned: Color(red: 0.40, green: 0.72, blue: 0.28)
        case .fertilized: Color(red: 0.92, green: 0.56, blue: 0.16)
        case .bloomed: Color(red: 0.92, green: 0.30, blue: 0.52)
        case .newGrowth: Color(red: 0.36, green: 0.82, blue: 0.12)
        case .pestDiscovered: Color(red: 0.86, green: 0.28, blue: 0.20)
        case .treatmentApplied: Color(red: 0.22, green: 0.64, blue: 0.88)
        case .cameHome: Color(red: 0.95, green: 0.62, blue: 0.25)
        case .customEvent: Color(red: 0.56, green: 0.38, blue: 0.82)
        case .death: Color(red: 0.43, green: 0.47, blue: 0.45)
        case nil: Color(red: 0.36, green: 0.82, blue: 0.12)
        }
    }
}

private extension View {
    func gardenCardStyle(panel: Color) -> some View {
        self
            .padding(20)
            .background(panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }
}
