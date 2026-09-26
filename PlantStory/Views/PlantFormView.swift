import PhotosUI
import SwiftUI
import UIKit

private enum PlantFormAIAlert: Identifiable {
    case repeatRequest
    case error(String)

    var id: String {
        switch self {
        case .repeatRequest:
            return "repeat-request"
        case .error(let message):
            return "error-\(message)"
        }
    }
}

private enum PlantFormInput: Hashable {
    case name
    case otherName
    case species
    case location
    case photoCustomEventTitle(Int)
    case photoNote(Int)
    case notes
}

struct PlantFormView: View {
    @EnvironmentObject private var store: PlantStore
    @EnvironmentObject private var openAIKeyStore: OpenAIKeyStore
    @EnvironmentObject private var appNavigation: AppNavigationStore
    @Environment(\.aiFeaturesAvailable) private var aiFeaturesAvailable
    @Environment(\.dismiss) private var dismiss

    private let existingPlant: Plant?
    @State private var name: String
    @State private var otherName: String
    @State private var species: String
    @State private var location: String
    @State private var acquisitionDate: Date
    @State private var fertilizingMonths: Set<Int>
    @State private var pruningMonths: Set<Int>
    @State private var notes: String
    @State private var wateringReminder: WateringReminder?
    @State private var photos: [Data]
    @State private var cardPhotoIndex: Int?
    @State private var photoDates: [Date]
    @State private var photoNotes: [String]
    @State private var photoEventTags: [PlantPhotoEventTag?]
    @State private var photoCustomEventTitles: [String]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var isRequestingAISuggestion = false
    @State private var hasGeneratedAISuggestion = false
    @State private var aiSuggestion: PlantAISuggestion?
    @State private var aiAlert: PlantFormAIAlert?
    @State private var shouldRequestWateringReminderAuthorization = false
    @State private var isSaving = false
    @FocusState private var focusedInput: PlantFormInput?

    private let aiService = PlantAIService()
    private let photoControlSize: CGFloat = 36
    private let photoControlVisualSize: CGFloat = 20

    init(plant: Plant? = nil) {
        existingPlant = plant
        let existingPhotos = plant?.photos ?? []
        let savedDates = plant?.photoDates ?? []
        let normalizedDates = existingPhotos.indices.map { index in
            savedDates.indices.contains(index) ? savedDates[index] : (plant?.acquisitionDate ?? .now)
        }
        let savedNotes = plant?.photoNotes ?? []
        let normalizedNotes = existingPhotos.indices.map { index in
            savedNotes.indices.contains(index) ? savedNotes[index] : ""
        }
        let savedEventTags = plant?.photoEventTags ?? []
        let normalizedEventTags = existingPhotos.indices.map { index in
            savedEventTags.indices.contains(index) ? savedEventTags[index] : nil
        }
        let savedCustomEventTitles = plant?.photoCustomEventTitles ?? []
        let normalizedCustomEventTitles = existingPhotos.indices.map { index in
            savedCustomEventTitles.indices.contains(index) ? savedCustomEventTitles[index] : ""
        }

        _name = State(initialValue: plant?.name ?? "")
        _otherName = State(initialValue: plant?.otherName ?? "")
        _species = State(initialValue: plant?.species ?? "")
        _location = State(initialValue: plant?.location ?? "")
        _acquisitionDate = State(initialValue: plant?.acquisitionDate ?? .now)
        _fertilizingMonths = State(initialValue: Set(plant?.fertilizingMonths ?? []))
        _pruningMonths = State(initialValue: Set(plant?.pruningMonths ?? []))
        _notes = State(initialValue: plant?.notes ?? "")
        _wateringReminder = State(initialValue: plant?.wateringReminder)
        let hasLegacyAISuggestion = plant?.notes.localizedCaseInsensitiveContains("AI care suggestion:") ?? false
        _hasGeneratedAISuggestion = State(
            initialValue: plant?.hasGeneratedAISuggestion ?? hasLegacyAISuggestion
        )
        _photos = State(initialValue: existingPhotos)
        let savedCardPhotoIndex = plant?.cardPhotoIndex
        _cardPhotoIndex = State(
            initialValue: savedCardPhotoIndex.flatMap {
                existingPhotos.indices.contains($0) ? $0 : nil
            } ?? existingPhotos.indices.last
        )
        _photoDates = State(initialValue: normalizedDates)
        _photoNotes = State(initialValue: normalizedNotes)
        _photoEventTags = State(initialValue: normalizedEventTags)
        _photoCustomEventTitles = State(initialValue: normalizedCustomEventTitles)
    }

    var body: some View {
        Form {
            Section("Plant") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .plantFormInput(.name, focus: $focusedInput)
                TextField("Other name (optional)", text: $otherName)
                    .textInputAutocapitalization(.words)
                    .plantFormInput(.otherName, focus: $focusedInput)
                TextField("Species (optional)", text: $species)
                    .textInputAutocapitalization(.words)
                    .plantFormInput(.species, focus: $focusedInput)
                HStack(spacing: 10) {
                    TextField("Location (optional)", text: $location)
                        .textInputAutocapitalization(.words)
                        .plantFormInput(.location, focus: $focusedInput)

                    if !existingLocationOptions.isEmpty {
                        Menu {
                            ForEach(existingLocationOptions, id: \.self) { option in
                                Button {
                                    location = option
                                } label: {
                                    if locationMatches(option) {
                                        Label(option, systemImage: "checkmark")
                                    } else {
                                        Text(option)
                                    }
                                }
                            }

                            if normalizedLocation != nil {
                                Divider()
                                Button("Clear location", systemImage: "xmark") {
                                    location = ""
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.title3)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Choose an existing location")
                        .accessibilityHint("Shows locations already used by your plants")
                    }
                }
                DatePicker(
                    "Acquired",
                    selection: $acquisitionDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
            }

            if aiFeaturesAvailable {
                Section {
                    if openAIKeyStore.hasAPIKey {
                        Button {
                            requestAISuggestionTapped()
                        } label: {
                            HStack {
                                Label(
                                    aiSuggestionButtonTitle,
                                    systemImage: "sparkles"
                                )
                                Spacer()
                                if isRequestingAISuggestion {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(trimmedName.isEmpty || isRequestingAISuggestion)
                    } else {
                        Label("AI suggestions are off", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)

                        Button {
                            openAISettings()
                        } label: {
                            Label("Add API key in Settings", systemImage: "gearshape.fill")
                        }
                    }
                } header: {
                    Text("AI assistant")
                } footer: {
                    if openAIKeyStore.hasAPIKey {
                        Text("PlantStory sends the plant name to OpenAI only after you request a suggestion. Each request uses your OpenAI API credits, and you’ll review the result before applying it.")
                    } else {
                        Text("AI is optional. Add your own OpenAI API key in Settings to unlock plant suggestions.")
                    }
                }
            }

            Section {
                MonthSelectionGrid(selection: $fertilizingMonths)
            } header: {
                Text("Best fertilizing months")
            } footer: {
                Text("Choose the months when this plant benefits most from fertilizer.")
            }

            Section {
                MonthSelectionGrid(selection: $pruningMonths)
            } header: {
                Text("Best pruning months")
            } footer: {
                Text("Choose the months when pruning is best for this plant.")
            }

            Section {
                ForEach(photos.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            PlantPhoto(data: photos[index], cornerRadius: 12)
                                .frame(width: 104, height: 104)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 8) {
                                    Text("Photo \(index + 1)")
                                        .font(.subheadline.weight(.semibold))

                                    Spacer(minLength: 8)

                                    Button(role: .destructive) {
                                        removePhoto(at: index)
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .frame(width: photoControlSize, height: photoControlSize)
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Remove photo \(index + 1)")
                                }

                                Button {
                                    cardPhotoIndex = index
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Garden card photo")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)

                                        Spacer(minLength: 8)

                                        ZStack {
                                            Circle()
                                                .fill(cardPhotoIndex == index ? Color.green : Color.clear)

                                            Circle()
                                                .stroke(
                                                    cardPhotoIndex == index ? Color.green : Color.secondary,
                                                    lineWidth: 2
                                                )

                                            if cardPhotoIndex == index {
                                                Image(systemName: "checkmark")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .frame(
                                            width: photoControlVisualSize,
                                            height: photoControlVisualSize
                                        )
                                        .frame(width: photoControlSize, height: photoControlSize)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(cardPhotoIndex == index ? .isSelected : [])

                                HStack(spacing: 8) {
                                    Text("Date")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer(minLength: 8)

                                    DatePicker(
                                        "Date",
                                        selection: $photoDates[index],
                                        in: ...Date.now,
                                        displayedComponents: .date
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        TimelineEventMenu(selection: $photoEventTags[index])

                        if photoEventTags[index] == .customEvent {
                            TextField(
                                "Custom event name",
                                text: $photoCustomEventTitles[index]
                            )
                            .textInputAutocapitalization(.sentences)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                .secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .plantFormInput(
                                .photoCustomEventTitle(index),
                                focus: $focusedInput
                            )
                        }

                        TextField("Add a note about this photo…", text: $photoNotes[index], axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .plantFormInput(
                                .photoNote(index),
                                focus: $focusedInput
                            )
                    }
                    .padding(.vertical, 6)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 12))
                }

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 8,
                    matching: .images,
                    preferredItemEncoding: .current
                ) {
                    Label(photoPickerTitle, systemImage: "photo.badge.plus")
                }
                .disabled(isLoadingPhotos)
                .onChange(of: selectedItems) { _, items in
                    Task { await importPhotos(from: items) }
                }
            } header: {
                Text("Photos")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose which photo appears on the My Garden card.")
                    Text("Photo dates are filled from image metadata when available. You can adjust them, choose a timeline event, and add a note.")
                }
            }

            Section("Notes") {
                TextField("Light, location, milestones…", text: $notes, axis: .vertical)
                    .lineLimit(4...9)
                    .plantFormInput(.notes, focus: $focusedInput)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PlantFormKeyboardDismissInstaller(focus: $focusedInput))
        .navigationTitle(formTitle)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                    .fontWeight(.semibold)
                    .disabled(
                        trimmedName.isEmpty
                            || isLoadingPhotos
                            || isRequestingAISuggestion
                            || isSaving
                    )
            }
        }
        .sheet(item: $aiSuggestion) { suggestion in
            PlantAISuggestionReviewView(suggestion: suggestion) { setUpWateringReminder in
                apply(
                    suggestion,
                    setUpWateringReminder: setUpWateringReminder
                )
            }
        }
        .alert(item: $aiAlert) { alert in
            switch alert {
            case .repeatRequest:
                return Alert(
                    title: Text("Generate another suggestion?"),
                    message: Text("This sends another request and uses additional OpenAI API credits. If the plant name and species have not changed, the new suggestion will likely be similar."),
                    primaryButton: .default(Text("Generate Again")) {
                        Task { await requestAISuggestion() }
                    },
                    secondaryButton: .cancel()
                )
            case .error(let message):
                return Alert(
                    title: Text("AI suggestion unavailable"),
                    message: Text(message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var formTitle: LocalizedStringKey {
        existingPlant == nil ? "New plant" : "Edit plant"
    }

    private var aiSuggestionButtonTitle: LocalizedStringKey {
        hasGeneratedAISuggestion ? "Suggest again with AI" : "Suggest details with AI"
    }

    private var photoPickerTitle: LocalizedStringKey {
        isLoadingPhotos ? "Adding photos…" : "Add photos"
    }

    private func openAISettings() {
        dismiss()
        DispatchQueue.main.async {
            appNavigation.showSettings()
        }
    }

    private func requestAISuggestionTapped() {
        if hasGeneratedAISuggestion {
            aiAlert = .repeatRequest
        } else {
            Task { await requestAISuggestion() }
        }
    }

    private func removePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }

        if let selectedIndex = cardPhotoIndex {
            if selectedIndex == index {
                cardPhotoIndex = photos.count > 1 ? min(index, photos.count - 2) : nil
            } else if selectedIndex > index {
                cardPhotoIndex = selectedIndex - 1
            }
        }

        photos.remove(at: index)
        if photoDates.indices.contains(index) {
            photoDates.remove(at: index)
        }
        if photoNotes.indices.contains(index) {
            photoNotes.remove(at: index)
        }
        if photoEventTags.indices.contains(index) {
            photoEventTags.remove(at: index)
        }
        if photoCustomEventTitles.indices.contains(index) {
            photoCustomEventTitles.remove(at: index)
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        if var plant = existingPlant {
            plant.name = trimmedName
            plant.otherName = normalizedOtherName
            plant.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.location = normalizedLocation
            plant.acquisitionDate = acquisitionDate
            plant.fertilizingMonths = normalizedFertilizingMonths
            plant.pruningMonths = normalizedPruningMonths
            plant.hasGeneratedAISuggestion = hasGeneratedAISuggestion
            plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.wateringReminder = wateringReminder
            plant.photos = photos
            plant.cardPhotoIndex = cardPhotoIndex
            plant.photoDates = photoDates
            plant.photoNotes = normalizedPhotoNotes
            plant.photoEventTags = photoEventTags
            plant.photoCustomEventTitles = normalizedPhotoCustomEventTitles
            store.update(plant)
        } else {
            store.add(Plant(
                name: trimmedName,
                otherName: normalizedOtherName,
                species: species.trimmingCharacters(in: .whitespacesAndNewlines),
                location: normalizedLocation,
                acquisitionDate: acquisitionDate,
                fertilizingMonths: normalizedFertilizingMonths,
                pruningMonths: normalizedPruningMonths,
                hasGeneratedAISuggestion: hasGeneratedAISuggestion,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                wateringReminder: wateringReminder,
                photos: photos,
                cardPhotoIndex: cardPhotoIndex,
                photoDates: photoDates,
                photoNotes: normalizedPhotoNotes,
                photoEventTags: photoEventTags,
                photoCustomEventTitles: normalizedPhotoCustomEventTitles
            ))
        }

        if shouldRequestWateringReminderAuthorization {
            _ = await WateringReminderService.shared.requestAuthorizationIfNeeded()
            await WateringReminderService.shared.reconcile(plants: store.plants)
        }
        dismiss()
    }

    @MainActor
    private func requestAISuggestion() async {
        guard !trimmedName.isEmpty else { return }
        guard let apiKey = openAIKeyStore.apiKey() else {
            aiAlert = .error(
                AppLocalization.string(
                    "Your API key is no longer available. Add it again from the Settings tab."
                )
            )
            return
        }

        isRequestingAISuggestion = true
        defer { isRequestingAISuggestion = false }

        do {
            let suggestion = try await aiService.suggestDetails(
                plantName: trimmedName,
                existingSpecies: species.trimmingCharacters(in: .whitespacesAndNewlines),
                apiKey: apiKey
            )
            hasGeneratedAISuggestion = true
            aiSuggestion = suggestion
        } catch {
            aiAlert = .error(error.localizedDescription)
        }
    }

    private func apply(
        _ suggestion: PlantAISuggestion,
        setUpWateringReminder: Bool
    ) {
        let suggestedSpecies = suggestion.scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !suggestedSpecies.isEmpty {
            species = suggestedSpecies
        }

        let suggestedOtherName = suggestion.otherName.trimmingCharacters(in: .whitespacesAndNewlines)
        if otherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !suggestedOtherName.isEmpty {
            otherName = suggestedOtherName
        }

        let suggestedFertilizingMonths = Set(suggestion.fertilizingMonths.filter { (1...12).contains($0) })
        if !suggestedFertilizingMonths.isEmpty {
            fertilizingMonths = suggestedFertilizingMonths
        }

        let suggestedPruningMonths = Set(suggestion.pruningMonths.filter { (1...12).contains($0) })
        if !suggestedPruningMonths.isEmpty {
            pruningMonths = suggestedPruningMonths
        }

        if setUpWateringReminder {
            applySuggestedWateringReminder(suggestion.wateringIntervals)
        }

        let careNotes = formattedCareNotes(
            suggestion.careNotes,
            wateringIntervals: suggestion.wateringIntervals
        )
        let taxonomy = formattedTaxonomy(
            suggestion.taxonomy,
            species: suggestion.scientificName
        )
        let generatedNotes = [taxonomy, careNotes.isEmpty ? "" : "\(AppLocalization.string("Caring guide"))\n\(careNotes)"]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        if !generatedNotes.isEmpty, !notes.localizedCaseInsensitiveContains(generatedNotes) {
            let hasExistingNotes = !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let prefix = hasExistingNotes ? "\n\n────────────\n" : ""
            let sectionHeading = AppLocalization.string("AI generated notes below")
            notes += "\(prefix)\(sectionHeading)\n\n\(generatedNotes)"
        }
    }

    private func applySuggestedWateringReminder(_ suggestedIntervals: PlantAIWateringIntervals) {
        let defaultInterval = wateringReminder?.intervalDays ?? 7
        var intervals = wateringReminder?.seasonalIntervals
            ?? SeasonalWateringIntervals(defaultInterval: defaultInterval)

        for season in WateringSeason.allCases {
            guard let days = suggestedIntervals[season], (1...90).contains(days) else { continue }
            intervals[season] = days
        }

        if var reminder = wateringReminder {
            reminder.intervalDays = intervals[.active]
            reminder.seasonalIntervals = intervals
            wateringReminder = reminder
        } else {
            wateringReminder = WateringReminder(
                intervalDays: intervals[.active],
                hour: 9,
                minute: 0,
                startDate: .now,
                seasonalIntervals: intervals
            )
        }
        shouldRequestWateringReminderAuthorization = true
    }

    private func formattedCareNotes(
        _ careNotes: PlantAICareNotes,
        wateringIntervals: PlantAIWateringIntervals
    ) -> String {
        let fields = [
            (AppLocalization.string("Light"), careNotes.light),
            (AppLocalization.string("Water"), careNotes.watering),
            (AppLocalization.string("Soil"), careNotes.soil),
            (AppLocalization.string("Humidity"), careNotes.humidity),
            (AppLocalization.string("Temperature"), careNotes.temperature),
            (AppLocalization.string("Fertilizing"), careNotes.fertilizing),
            (AppLocalization.string("Pruning"), careNotes.pruning),
            (AppLocalization.string("Repotting"), careNotes.repotting),
            (AppLocalization.string("Toxicity"), careNotes.toxicity),
            (AppLocalization.string("Watch for"), careNotes.warningSigns)
        ]

        var sections = [fields.compactMap { label, value in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? nil : "• \(label): \(trimmedValue)"
        }
        .joined(separator: "\n")]

        if wateringIntervals.hasContent {
            let intervalLines: [String] = WateringSeason.allCases.compactMap { season -> String? in
                guard let days = wateringIntervals[season] else { return nil }
                return "• \(season.localizedTitle): \(wateringIntervalText(days))"
            }
            sections.append(
                "\(AppLocalization.string("Seasonal watering intervals"))\n\(intervalLines.joined(separator: "\n"))"
            )
        }

        return sections.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    private func formattedTaxonomy(
        _ taxonomy: PlantAITaxonomy,
        species: String
    ) -> String {
        let fields = [
            (AppLocalization.string("Major group"), taxonomy.majorGroup),
            (AppLocalization.string("Order"), taxonomy.order),
            (AppLocalization.string("Family"), taxonomy.family),
            (AppLocalization.string("Genus"), taxonomy.genus),
            (AppLocalization.string("Species"), species)
        ]
        let lines = fields.compactMap { label, value -> String? in
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? nil : "• \(label): \(trimmedValue)"
        }
        guard !lines.isEmpty else { return "" }
        return "\(AppLocalization.string("Taxonomy"))\n\(lines.joined(separator: "\n"))"
    }

    private func wateringIntervalText(_ days: Int) -> String {
        days == 1
            ? AppLocalization.string("Every day")
            : AppLocalization.string("Every %lld days", Int64(days))
    }

    @MainActor
    private func importPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            selectedItems = []
        }

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let resized = image.resizedForStorage(maxDimension: 1800) else { continue }
            let creationDate = PhotoMetadata.creationDate(from: data) ?? .now
            let newPhotoIndex = photos.count
            photos.append(resized)
            if cardPhotoIndex == nil {
                cardPhotoIndex = newPhotoIndex
            }
            photoDates.append(min(creationDate, .now))
            photoNotes.append("")
            photoEventTags.append(nil)
            photoCustomEventTitles.append("")
        }
    }

    private var normalizedPhotoNotes: [String] {
        photoNotes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private var normalizedPhotoCustomEventTitles: [String] {
        photoCustomEventTitles.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var normalizedFertilizingMonths: [Int]? {
        normalizedMonths(fertilizingMonths)
    }

    private var normalizedPruningMonths: [Int]? {
        normalizedMonths(pruningMonths)
    }

    private func normalizedMonths(_ selection: Set<Int>) -> [Int]? {
        let months = selection.sorted()
        return months.isEmpty ? nil : months
    }

    private var normalizedOtherName: String? {
        let value = otherName.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var normalizedLocation: String? {
        cleanedLocation(location)
    }

    private var existingLocationOptions: [String] {
        var locationsByKey: [String: String] = [:]

        for plant in store.plants {
            guard let location = cleanedLocation(plant.location) else { continue }
            let key = locationKey(location)
            if locationsByKey[key] == nil {
                locationsByKey[key] = location
            }
        }

        return locationsByKey.values.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    private func locationMatches(_ option: String) -> Bool {
        guard let normalizedLocation else { return false }
        return locationKey(normalizedLocation) == locationKey(option)
    }

    private func cleanedLocation(_ location: String?) -> String? {
        guard let location else { return nil }
        let value = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func locationKey(_ location: String) -> String {
        location.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
    }
}

private extension View {
    func plantFormInput(
        _ input: PlantFormInput,
        focus: FocusState<PlantFormInput?>.Binding
    ) -> some View {
        focused(focus, equals: input)
    }
}

private struct PlantFormKeyboardDismissInstaller: UIViewRepresentable {
    let focus: FocusState<PlantFormInput?>.Binding

    func makeCoordinator() -> Coordinator {
        Coordinator(focus: focus)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.focus = focus
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: uiView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var focus: FocusState<PlantFormInput?>.Binding
        private let tapGesture = UITapGestureRecognizer()

        init(focus: FocusState<PlantFormInput?>.Binding) {
            self.focus = focus
            super.init()
            tapGesture.addTarget(self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            tapGesture.delaysTouchesBegan = false
            tapGesture.delaysTouchesEnded = false
            tapGesture.delegate = self
        }

        func installIfNeeded(from view: UIView) {
            guard let window = view.window, tapGesture.view !== window else { return }
            uninstall()
            window.addGestureRecognizer(tapGesture)
        }

        func uninstall() {
            tapGesture.view?.removeGestureRecognizer(tapGesture)
        }

        @objc private func dismissKeyboard() {
            focus.wrappedValue = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            var view = touch.view
            while let currentView = view {
                if currentView is UITextField || currentView is UITextView {
                    return false
                }
                view = currentView.superview
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

private struct TimelineEventMenu: View {
    @Binding var selection: PlantPhotoEventTag?

    private var selectedTitle: LocalizedStringKey {
        selection?.title ?? "A new moment"
    }

    private var selectedIcon: String {
        selection?.icon ?? "camera.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("Timeline event")
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            Menu {
                Button {
                    selection = nil
                } label: {
                    Label(
                        "A new moment",
                        systemImage: selection == nil ? "checkmark" : "camera.fill"
                    )
                }

                ForEach(PlantPhotoEventTag.allCases) { eventTag in
                    Button {
                        selection = eventTag
                    } label: {
                        Label(
                            eventTag.title,
                            systemImage: selection == eventTag ? "checkmark" : eventTag.icon
                        )
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 11, height: 14)

                    Text(selectedTitle)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.tint)
            }
            .accessibilityLabel("Timeline event")
            .accessibilityValue(selectedTitle)
        }
    }
}

private struct MonthSelectionGrid: View {
    @Binding var selection: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...12, id: \.self) { month in
                let isSelected = selection.contains(month)
                Button {
                    if isSelected {
                        selection.remove(month)
                    } else {
                        selection.insert(month)
                    }
                } label: {
                    Text(monthName(for: month))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(monthName(for: month))
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
            }
        }
        .padding(.vertical, 4)
    }

    private func monthName(for month: Int) -> String {
        var calendar = Calendar.current
        calendar.locale = AppLocalization.currentLocale
        return calendar.monthSymbols[month - 1]
    }
}

private extension UIImage {
    func resizedForStorage(maxDimension: CGFloat) -> Data? {
        let longest = max(size.width, size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}
