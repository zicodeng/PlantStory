import PhotosUI
import SwiftUI
import UIKit

private enum WildFindFormAIAlert: Identifiable {
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

struct WildFindFormView: View {
    @EnvironmentObject private var store: WildFindStore
    @EnvironmentObject private var openAIKeyStore: OpenAIKeyStore
    @EnvironmentObject private var appNavigation: AppNavigationStore
    @Environment(\.dismiss) private var dismiss

    private let existingFind: WildFind?
    @State private var name: String
    @State private var otherName: String
    @State private var species: String
    @State private var notes: String
    @State private var discoveredDate: Date
    @State private var photos: [Data]
    @State private var photoDates: [Date]
    @State private var photoNotes: [String]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var isRequestingAISuggestion = false
    @State private var hasGeneratedAISuggestion = false
    @State private var aiSuggestion: WildFindAISuggestion?
    @State private var aiAlert: WildFindFormAIAlert?

    private let aiService = PlantAIService()

    init(find: WildFind? = nil) {
        existingFind = find
        let existingPhotos = find?.photos ?? []
        let savedDates = find?.photoDates ?? []
        let normalizedDates = existingPhotos.indices.map { index in
            savedDates.indices.contains(index) ? savedDates[index] : (find?.discoveredDate ?? .now)
        }
        let savedNotes = find?.photoNotes ?? []
        let normalizedNotes = existingPhotos.indices.map { index in
            savedNotes.indices.contains(index) ? savedNotes[index] : ""
        }

        _name = State(initialValue: find?.name ?? "")
        _otherName = State(initialValue: find?.otherName ?? "")
        _species = State(initialValue: find?.species ?? "")
        _notes = State(initialValue: find?.notes ?? "")
        _hasGeneratedAISuggestion = State(initialValue: find?.hasGeneratedAISuggestion ?? false)
        _discoveredDate = State(initialValue: find?.discoveredDate ?? .now)
        _photos = State(initialValue: existingPhotos)
        _photoDates = State(initialValue: normalizedDates)
        _photoNotes = State(initialValue: normalizedNotes)
    }

    var body: some View {
        Form {
            Section("Wild plant") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Other name (optional)", text: $otherName)
                    .textInputAutocapitalization(.words)
                TextField("Species (optional)", text: $species)
                    .textInputAutocapitalization(.words)
                DatePicker(
                    "Discovered",
                    selection: $discoveredDate,
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
                    Text("AI can suggest a species and short botanical description—not a care guide. Each request uses your OpenAI API credits, and you’ll review the result before applying it.")
                } else {
                    Text("AI is optional. Add your own OpenAI API key in Settings to unlock Wild Find suggestions.")
                }
            }

            Section("Notes") {
                TextField("Appearance, habitat, location, or observations…", text: $notes, axis: .vertical)
                    .lineLimit(4...9)
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
        }
        .navigationTitle(existingFind == nil ? "New wild find" : "Edit wild find")
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
            WildFindAISuggestionReviewView(suggestion: suggestion) {
                apply(suggestion)
            }
        }
        .alert(item: $aiAlert) { alert in
            switch alert {
            case .repeatRequest:
                return Alert(
                    title: Text("Generate another suggestion?"),
                    message: Text("This sends another request and uses additional OpenAI API credits. If the name and species have not changed, the new description will likely be similar."),
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

    private var normalizedOtherName: String? {
        let value = otherName.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var normalizedPhotoNotes: [String] {
        photoNotes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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
        if photoDates.indices.contains(index) { photoDates.remove(at: index) }
        if photoNotes.indices.contains(index) { photoNotes.remove(at: index) }
    }

    private func save() {
        if var find = existingFind {
            find.name = trimmedName
            find.otherName = normalizedOtherName
            find.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
            find.notes = normalizedNotes
            find.hasGeneratedAISuggestion = hasGeneratedAISuggestion
            find.discoveredDate = discoveredDate
            find.photos = photos
            find.photoDates = photoDates
            find.photoNotes = normalizedPhotoNotes
            store.update(find)
        } else {
            store.add(WildFind(
                name: trimmedName,
                otherName: normalizedOtherName,
                species: species.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: normalizedNotes,
                hasGeneratedAISuggestion: hasGeneratedAISuggestion,
                discoveredDate: discoveredDate,
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
            let suggestion = try await aiService.suggestWildFindDetails(
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

    private func apply(_ suggestion: WildFindAISuggestion) {
        let suggestedSpecies = suggestion.scientificName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !suggestedSpecies.isEmpty {
            species = suggestedSpecies
        }

        let description = suggestion.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty, !notes.localizedCaseInsensitiveContains(description) {
            let prefix = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n"
            notes += "\(prefix)\(description)"
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
                  let resized = image.resizedForWildFindStorage(maxDimension: 1800) else { continue }
            let creationDate = PhotoMetadata.creationDate(from: data) ?? .now
            photos.append(resized)
            photoDates.append(min(creationDate, .now))
            photoNotes.append("")
        }
    }

    private var normalizedNotes: String? {
        let value = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

private struct WildFindAISuggestionReviewView: View {
    let suggestion: WildFindAISuggestion
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Suggested identity") {
                    suggestionRow("Species", value: suggestion.scientificName)
                }

                if !suggestion.description.isEmpty {
                    Section("Plant description") {
                        Text(suggestion.description)
                    }
                }

                Section {
                    HStack {
                        Text("Confidence")
                        Spacer()
                        Text(suggestion.confidence, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                    }
                    if !suggestion.caveat.isEmpty {
                        Text(suggestion.caveat)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("AI can confuse plants with similar common names. No photo was analyzed, so review the species and description before applying them.")
                }
            }
            .navigationTitle("Review suggestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func suggestionRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "Not suggested" : value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private extension UIImage {
    func resizedForWildFindStorage(maxDimension: CGFloat) -> Data? {
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
