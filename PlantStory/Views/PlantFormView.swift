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

struct PlantFormView: View {
    @EnvironmentObject private var store: PlantStore
    @EnvironmentObject private var openAIKeyStore: OpenAIKeyStore
    @EnvironmentObject private var appNavigation: AppNavigationStore
    @Environment(\.dismiss) private var dismiss

    private let existingPlant: Plant?
    @State private var name: String
    @State private var otherName: String
    @State private var species: String
    @State private var acquisitionDate: Date
    @State private var fertilizingMonths: Set<Int>
    @State private var pruningMonths: Set<Int>
    @State private var notes: String
    @State private var photos: [Data]
    @State private var photoDates: [Date]
    @State private var photoNotes: [String]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var isRequestingAISuggestion = false
    @State private var hasGeneratedAISuggestion = false
    @State private var aiSuggestion: PlantAISuggestion?
    @State private var aiAlert: PlantFormAIAlert?

    private let aiService = PlantAIService()

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

        _name = State(initialValue: plant?.name ?? "")
        _otherName = State(initialValue: plant?.otherName ?? "")
        _species = State(initialValue: plant?.species ?? "")
        _acquisitionDate = State(initialValue: plant?.acquisitionDate ?? .now)
        _fertilizingMonths = State(initialValue: Set(plant?.fertilizingMonths ?? []))
        _pruningMonths = State(initialValue: Set(plant?.pruningMonths ?? []))
        _notes = State(initialValue: plant?.notes ?? "")
        let hasLegacyAISuggestion = plant?.notes.localizedCaseInsensitiveContains("AI care suggestion:") ?? false
        _hasGeneratedAISuggestion = State(
            initialValue: plant?.hasGeneratedAISuggestion ?? hasLegacyAISuggestion
        )
        _photos = State(initialValue: existingPhotos)
        _photoDates = State(initialValue: normalizedDates)
        _photoNotes = State(initialValue: normalizedNotes)
    }

    var body: some View {
        Form {
            Section("Plant") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Other name (optional)", text: $otherName)
                    .textInputAutocapitalization(.words)
                TextField("Species (optional)", text: $species)
                    .textInputAutocapitalization(.words)
                DatePicker(
                    "Acquired",
                    selection: $acquisitionDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
            }

            Section {
                if openAIKeyStore.hasAPIKey {
                    Button {
                        requestAISuggestionTapped()
                    } label: {
                        HStack {
                            Label(
                                hasGeneratedAISuggestion ? "Suggest again with AI" : "Suggest details with AI",
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
                        HStack(alignment: .center, spacing: 12) {
                            PlantPhoto(data: photos[index], cornerRadius: 12)
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Photo \(index + 1)")
                                    .font(.subheadline.weight(.semibold))
                                DatePicker(
                                    "Taken",
                                    selection: $photoDates[index],
                                    in: ...Date.now,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(role: .destructive) {
                                removePhoto(at: index)
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 38, height: 38)
                                    .background(.red.opacity(0.1), in: Circle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove photo \(index + 1)")
                        }

                        TextField("Add a note about this photo…", text: $photoNotes[index], axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
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
                    Label(isLoadingPhotos ? "Adding photos…" : "Add photos", systemImage: "photo.badge.plus")
                }
                .disabled(isLoadingPhotos)
                .onChange(of: selectedItems) { _, items in
                    Task { await importPhotos(from: items) }
                }
            } header: {
                Text("Photos")
            } footer: {
                Text("Photo dates are filled from image metadata when available. You can still adjust them and add a note.")
            }

            Section("Notes") {
                TextField("Light, location, milestones…", text: $notes, axis: .vertical)
                    .lineLimit(4...9)
            }
        }
        .navigationTitle(existingPlant == nil ? "New plant" : "Edit plant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty || isLoadingPhotos || isRequestingAISuggestion)
            }
        }
        .sheet(item: $aiSuggestion) { suggestion in
            PlantAISuggestionReviewView(suggestion: suggestion) {
                apply(suggestion)
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
        photos.remove(at: index)
        if photoDates.indices.contains(index) {
            photoDates.remove(at: index)
        }
        if photoNotes.indices.contains(index) {
            photoNotes.remove(at: index)
        }
    }

    private func save() {
        if var plant = existingPlant {
            plant.name = trimmedName
            plant.otherName = normalizedOtherName
            plant.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.acquisitionDate = acquisitionDate
            plant.fertilizingMonths = normalizedFertilizingMonths
            plant.pruningMonths = normalizedPruningMonths
            plant.hasGeneratedAISuggestion = hasGeneratedAISuggestion
            plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.photos = photos
            plant.photoDates = photoDates
            plant.photoNotes = normalizedPhotoNotes
            store.update(plant)
        } else {
            store.add(Plant(
                name: trimmedName,
                otherName: normalizedOtherName,
                species: species.trimmingCharacters(in: .whitespacesAndNewlines),
                acquisitionDate: acquisitionDate,
                fertilizingMonths: normalizedFertilizingMonths,
                pruningMonths: normalizedPruningMonths,
                hasGeneratedAISuggestion: hasGeneratedAISuggestion,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                photos: photos,
                photoDates: photoDates,
                photoNotes: normalizedPhotoNotes
            ))
        }
        dismiss()
    }

    @MainActor
    private func requestAISuggestion() async {
        guard !trimmedName.isEmpty else { return }
        guard let apiKey = openAIKeyStore.apiKey() else {
            aiAlert = .error("Your API key is no longer available. Add it again from the Settings tab.")
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

    private func apply(_ suggestion: PlantAISuggestion) {
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

        let careSummary = suggestion.careSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !careSummary.isEmpty, !notes.localizedCaseInsensitiveContains(careSummary) {
            let prefix = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n"
            notes += "\(prefix)AI care suggestion: \(careSummary)"
        }
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
            photos.append(resized)
            photoDates.append(min(creationDate, .now))
            photoNotes.append("")
        }
    }

    private var normalizedPhotoNotes: [String] {
        photoNotes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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
        Calendar.current.monthSymbols[month - 1]
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
