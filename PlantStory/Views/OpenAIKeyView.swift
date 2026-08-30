import SwiftUI

struct OpenAIKeyView: View {
    @EnvironmentObject private var keyStore: OpenAIKeyStore
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var acknowledgesBilling = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    private let modelDetailsURL = URL(string: "https://developers.openai.com/api/docs/models/gpt-5.4-nano")!

    var body: some View {
        Form {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(keyStore.hasAPIKey ? "AI suggestions are on" : "AI suggestions are off")
                            .font(.headline)
                        if let keyPreview = keyStore.keyPreview {
                            Text("Saved key \(keyPreview)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: keyStore.hasAPIKey ? "checkmark.shield.fill" : "sparkles")
                        .foregroundStyle(keyStore.hasAPIKey ? .green : .secondary)
                }
            }

            Section {
                aiUsageRow(
                    icon: "hand.tap.fill",
                    title: "You stay in control",
                    detail: "A request is sent only after you tap Suggest with AI. Tapping it again sends another request and may create another charge."
                )

                aiUsageRow(
                    icon: "arrow.up.doc.fill",
                    title: "What is shared",
                    detail: "PlantStory sends the plant name, any species text you entered, and your device region when relevant. Photos, notes, and plant history are not sent."
                )

                aiUsageRow(
                    icon: "cpu.fill",
                    title: "Model",
                    detail: "Suggestions use OpenAI’s GPT-5.4 nano model through the Responses API. Responses are requested with storage turned off."
                )

                aiUsageRow(
                    icon: "dollarsign.circle.fill",
                    title: "Rough cost",
                    detail: "About $0.001 per suggestion, often less. Actual cost depends on token usage and OpenAI’s current pricing, and is billed to your API account."
                )

                Link("View GPT-5.4 nano pricing", destination: modelDetailsURL)
                    .font(.subheadline.weight(.medium))
            } header: {
                Text("How AI suggestions work")
            } footer: {
                Text("OpenAI API billing is separate from a ChatGPT subscription. Your API key stays in this device’s Keychain and is used only to authenticate requests to OpenAI.")
            }

            Section {
                SecureField("Paste your OpenAI API key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .privacySensitive()

                Toggle(isOn: $acknowledgesBilling) {
                    Text("I understand API requests are billed to my OpenAI API account.")
                        .font(.subheadline)
                }

                Button(keyStore.hasAPIKey ? "Replace API key" : "Save API key") {
                    saveKey()
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !acknowledgesBilling)

                Link(
                    "Create an OpenAI API key",
                    destination: URL(string: "https://platform.openai.com/api-keys")!
                )
            } header: {
                Text(keyStore.hasAPIKey ? "Use a different key" : "Your API key")
            } footer: {
                Text("The key is stored in this device’s Keychain and is never saved with your plants. PlantStory sends a plant name to OpenAI only after you tap Suggest with AI.")
            }

            if keyStore.hasAPIKey {
                Section {
                    Button("Remove API key", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } footer: {
                    Text("Removing the key immediately turns off AI suggestions. Everything else in PlantStory keeps working.")
                }
            }
        }
        .navigationTitle("AI Suggestions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .alert("Couldn’t update API key", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .confirmationDialog(
            "Remove your API key?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove API key", role: .destructive) { deleteKey() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("AI suggestions will be turned off on this device.")
        }
    }

    private func saveKey() {
        do {
            try keyStore.save(apiKey)
            apiKey = ""
            acknowledgesBilling = false
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteKey() {
        do {
            try keyStore.delete()
            apiKey = ""
            acknowledgesBilling = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func aiUsageRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct PlantAISuggestionReviewView: View {
    let suggestion: PlantAISuggestion
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Suggested identity") {
                    suggestionRow("Common name", value: suggestion.commonName)
                    suggestionRow("Species", value: suggestion.scientificName)
                    suggestionRow("Other name", value: suggestion.otherName)
                }

                Section("Care calendar") {
                    suggestionRow("Fertilize", value: monthNames(suggestion.fertilizingMonths))
                    suggestionRow("Prune", value: monthNames(suggestion.pruningMonths))
                }

                if !suggestion.careSummary.isEmpty {
                    Section("Care note") {
                        Text(suggestion.careSummary)
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
                    Text("AI suggestions can be wrong, especially when a common name refers to several species. Review these values before applying them.")
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

    private func monthNames(_ months: [Int]) -> String {
        let names = Calendar.current.shortMonthSymbols
        let values = Array(Set(months))
            .filter { (1...12).contains($0) }
            .sorted()
            .map { names[$0 - 1] }
        return values.isEmpty ? "Not suggested" : values.joined(separator: ", ")
    }
}
