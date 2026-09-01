import SwiftUI
import StoreKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var openAIKeyStore: OpenAIKeyStore
    @Environment(\.requestReview) private var requestReview

    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let aiViolet = Color(red: 0.49, green: 0.31, blue: 0.86)
    private let storageTeal = Color(red: 0.06, green: 0.56, blue: 0.48)
    private let reviewOrange = Color(red: 0.88, green: 0.42, blue: 0.08)
    private let feedbackBlue = Color(red: 0.16, green: 0.48, blue: 0.86)
    private let githubFeedbackURL = URL(string: "https://github.com/zicodeng/PlantStory/issues")!

    var body: some View {
        NavigationStack {
            ZStack {
                forest.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Settings")
                                .font(.system(size: 36, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)
                            Text("Manage optional features and privacy.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.68))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("FEATURES")
                                .font(.caption.weight(.bold))
                                .tracking(1.8)
                                .foregroundStyle(lime)

                            NavigationLink {
                                OpenAIKeyView()
                                    .toolbar(.visible, for: .navigationBar)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "sparkles")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 46, height: 46)
                                        .background(aiViolet, in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("AI Assistant")
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text(aiStatus)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.42))
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                                .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(.white.opacity(0.08), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Configure your OpenAI API key")

                            Text("AI suggestions are optional and use your own OpenAI API account. Plant tracking works normally when this feature is off.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(.horizontal, 4)

                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATA & PRIVACY")
                                .font(.caption.weight(.bold))
                                .tracking(1.8)
                                .foregroundStyle(lime)

                            NavigationLink {
                                StorageInfoView()
                                    .toolbar(.visible, for: .navigationBar)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "externaldrive.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 46, height: 46)
                                        .background(storageTeal, in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Storage & Data")
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Local-only storage · No cloud sync")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.42))
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                                .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(.white.opacity(0.08), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Explains local storage, privacy, and moving PlantStory to another iPhone")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("FEEDBACK")
                                .font(.caption.weight(.bold))
                                .tracking(1.8)
                                .foregroundStyle(lime)

                            VStack(spacing: 0) {
                                Button {
                                    requestReview()
                                } label: {
                                    feedbackRow(
                                        icon: "star.fill",
                                        iconColor: reviewOrange,
                                        title: "Review PlantStory",
                                        description: "Share a rating or a short App Store review.",
                                        trailingIcon: "chevron.right"
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens Apple's in-app review prompt when available")

                                Divider()
                                    .overlay(.white.opacity(0.1))
                                    .padding(.leading, 76)

                                Link(destination: githubFeedbackURL) {
                                    feedbackRow(
                                        icon: "exclamationmark.bubble.fill",
                                        iconColor: feedbackBlue,
                                        title: "Comment on GitHub",
                                        description: "Report a bug, suggest an idea, or join the discussion.",
                                        trailingIcon: "arrow.up.right"
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the PlantStory GitHub issues page in your browser")
                            }
                            .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.caption.weight(.bold))
                                .tracking(1.8)
                                .foregroundStyle(lime)

                            NavigationLink {
                                CreditsView()
                                    .toolbar(.visible, for: .navigationBar)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "heart.fill")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 46, height: 46)
                                        .background(Color.pink, in: Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Credits & Contributors")
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Vibe-coded with love by Zico")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white.opacity(0.42))
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                                .background(panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(.white.opacity(0.08), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("View app credits and open-source information")
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 36)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var aiStatus: String {
        if let keyPreview = openAIKeyStore.keyPreview {
            return "On · Key \(keyPreview)"
        }
        return "Off · Add your own API key"
    }

    private func feedbackRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        trailingIcon: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(iconColor, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: trailingIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}

private struct PlantStoryBackupArchive: Codable {
    static let currentFormatVersion = 1

    let formatVersion: Int
    let createdAt: Date
    let plants: [Plant]
    let wildFinds: [WildFind]

    init(createdAt: Date = .now, plants: [Plant], wildFinds: [WildFind]) {
        formatVersion = Self.currentFormatVersion
        self.createdAt = createdAt
        self.plants = plants
        self.wildFinds = wildFinds
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(from data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(Self.self, from: data)
        guard archive.formatVersion == currentFormatVersion else {
            throw PlantStoryBackupError.unsupportedVersion(archive.formatVersion)
        }
        return archive
    }
}

private struct PlantStoryBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var archive: PlantStoryBackupArchive

    init(archive: PlantStoryBackupArchive = PlantStoryBackupArchive(plants: [], wildFinds: [])) {
        self.archive = archive
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw PlantStoryBackupError.unreadableFile
        }
        archive = try PlantStoryBackupArchive.decode(from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try archive.encoded())
    }
}

private enum PlantStoryBackupError: LocalizedError {
    case unreadableFile
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            "The selected file could not be read."
        case let .unsupportedVersion(version):
            "This backup uses unsupported format version \(version). Update PlantStory and try again."
        }
    }
}

private struct BackupNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct StorageInfoView: View {
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var wildFindStore: WildFindStore

    @State private var exportDocument = PlantStoryBackupDocument()
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var pendingBackup: PlantStoryBackupArchive?
    @State private var isConfirmingRestore = false
    @State private var backupNotice: BackupNotice?

    private let transferGuideURL = URL(string: "https://support.apple.com/119967")!

    var body: some View {
        Form {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your garden stays on this iPhone")
                            .font(.headline)
                        Text("PlantStory uses no account, cloud database, or live cloud sync.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "iphone.gen3")
                        .foregroundStyle(.teal)
                }
            }

            Section {
                storageRow(
                    icon: "leaf.fill",
                    title: "My Garden",
                    detail: "Library/Application Support/PlantStory/plants.json"
                )

                storageRow(
                    icon: "camera.macro",
                    title: "Wild Finds",
                    detail: "Library/Application Support/PlantStory/wild-finds.json"
                )

                storageRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Photos",
                    detail: "Photo data, dates, and notes are included inside those two private files."
                )

                storageRow(
                    icon: "key.fill",
                    title: "OpenAI API key",
                    detail: "Stored separately in the iOS Keychain and restricted to this device."
                )
            } header: {
                Text("Where your data is stored")
            } footer: {
                Text("These locations are inside PlantStory’s private app container and are not visible in the Files app.")
            }

            Section("Cloud & network use") {
                storageRow(
                    icon: "icloud.slash.fill",
                    title: "No cloud storage",
                    detail: "Your plants, wild finds, photos, notes, watering history, and fertilizing history are not uploaded to iCloud, CloudKit, or a PlantStory server."
                )

                storageRow(
                    icon: "sparkles",
                    title: "Optional AI exception",
                    detail: "Only when you tap Suggest with AI, limited text such as the plant name, existing species, and region when relevant is sent directly to OpenAI. Photos and plant history are not sent."
                )
            }

            Section {
                Button {
                    prepareBackup()
                } label: {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }

                Button {
                    isImportingBackup = true
                } label: {
                    Label("Restore from Backup", systemImage: "square.and.arrow.down")
                }

                LabeledContent("Current collection") {
                    Text(collectionSummary)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Manual backup & restore")
            } footer: {
                Text("The JSON backup includes My Garden, Wild Finds, photos, notes, timelines, and care history. It does not include your OpenAI API key or StoreKit purchase history. Restoring replaces the current local collection.")
            }

            Section {
                migrationStep(
                    number: 1,
                    title: "Create a PlantStory backup",
                    detail: "Export a manual backup above and save it somewhere you can open on the new iPhone."
                )

                migrationStep(
                    number: 2,
                    title: "Restore on the new iPhone",
                    detail: "Install PlantStory, open Storage & Data, and choose Restore from Backup. Apple Quick Start or a full device backup also works."
                )

                migrationStep(
                    number: 3,
                    title: "Re-enter your API key",
                    detail: "The device-only Keychain item intentionally does not migrate. Add the key again under AI Suggestions if you still want that feature."
                )

                Link("View Apple’s transfer instructions", destination: transferGuideURL)
                    .font(.subheadline.weight(.medium))
            } header: {
                Text("Move to another iPhone")
            } footer: {
                Text("Do not erase or delete the app from your old iPhone until you confirm your plants and photos appear on the new one.")
            }

            Section("Deleting the app") {
                Text("Deleting PlantStory removes its local plant files from that iPhone. Reinstalling the app by itself does not restore them; restore from a suitable device backup when available.")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Storage & Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExportingBackup,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            switch result {
            case .success:
                backupNotice = BackupNotice(
                    title: "Backup saved",
                    message: "Keep this file somewhere safe. You can restore it from Storage & Data on another iPhone."
                )
            case let .failure(error):
                presentBackupError(error)
            }
        }
        .fileImporter(
            isPresented: $isImportingBackup,
            allowedContentTypes: [.json]
        ) { result in
            do {
                let url = try result.get()
                let hasSecurityAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasSecurityAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                pendingBackup = try PlantStoryBackupArchive.decode(from: data)
                isConfirmingRestore = true
            } catch {
                presentBackupError(error)
            }
        }
        .alert(
            "Replace local PlantStory data?",
            isPresented: $isConfirmingRestore,
            presenting: pendingBackup
        ) { backup in
            Button("Restore", role: .destructive) {
                restore(backup)
            }
            Button("Cancel", role: .cancel) {}
        } message: { backup in
            Text("Backup from \(backup.createdAt.formatted(date: .abbreviated, time: .shortened)) with \(itemSummary(for: backup)). Your current plants and Wild Finds will be replaced.")
        }
        .alert(item: $backupNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var collectionSummary: String {
        "\(plantStore.plants.count) plants · \(wildFindStore.finds.count) wild finds"
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "PlantStory Backup \(formatter.string(from: .now))"
    }

    private func prepareBackup() {
        exportDocument = PlantStoryBackupDocument(
            archive: PlantStoryBackupArchive(
                plants: plantStore.plants,
                wildFinds: wildFindStore.finds
            )
        )
        isExportingBackup = true
    }

    private func restore(_ backup: PlantStoryBackupArchive) {
        let previousPlants = plantStore.plants

        do {
            try plantStore.replaceAll(with: backup.plants)
            do {
                try wildFindStore.replaceAll(with: backup.wildFinds)
            } catch {
                try? plantStore.replaceAll(with: previousPlants)
                throw error
            }

            pendingBackup = nil
            backupNotice = BackupNotice(
                title: "Backup restored",
                message: "Restored \(itemSummary(for: backup))."
            )
        } catch {
            presentBackupError(error)
        }
    }

    private func itemSummary(for backup: PlantStoryBackupArchive) -> String {
        let plantLabel = backup.plants.count == 1 ? "1 plant" : "\(backup.plants.count) plants"
        let findLabel = backup.wildFinds.count == 1 ? "1 wild find" : "\(backup.wildFinds.count) wild finds"
        return "\(plantLabel) and \(findLabel)"
    }

    private func presentBackupError(_ error: Error) {
        let error = error as NSError
        guard error.code != NSUserCancelledError else { return }
        backupNotice = BackupNotice(
            title: "Backup couldn’t be completed",
            message: error.localizedDescription
        )
    }

    private func storageRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.teal)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(detail.contains("Library/Application Support") ? .caption.monospaced() : .footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func migrationStep(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.teal, in: Circle())

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

private struct CreditsView: View {
    @StateObject private var tipJar = TipJarStore()

    private let tippingEnabled = false
    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)
    private let seedlingGreen = Color(red: 0.76, green: 0.92, blue: 0.64)
    private let sproutGreen = Color(red: 0.43, green: 0.85, blue: 0.20)
    private let gardenGreen = Color(red: 0.12, green: 0.67, blue: 0.30)
    private let cardIconSize: CGFloat = 42
    // Replace this placeholder with the final public repository URL when it is ready.
    private let sourceCodeURL = URL(string: "https://github.com/zicodeng/PlantStory")!

    private var cardIconFont: Font {
        .headline.weight(.semibold)
    }

    private var cardIconForeground: Color {
        forest
    }

    private var cardTitleFont: Font {
        .system(.headline, design: .serif, weight: .semibold)
    }

    private var cardSubtitleFont: Font {
        .subheadline
    }

    var body: some View {
        ZStack {
            forest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 16) {
                        GrowingStoryEmblem()

                        VStack(spacing: 7) {
                            Text("PlantStory")
                                .font(.system(size: 34, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)

                            Text("Vibe-coded with love by Zico")
                                .font(.system(.headline, design: .serif, weight: .medium))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 18) {
                        creditRow(
                            icon: "sparkles",
                            title: "Fully vibe-coded",
                            description: "PlantStory was brought to life through ideas, conversation, and joyful experimentation with AI."
                        )

                        Divider()
                            .overlay(.white.opacity(0.1))

                        Link(destination: sourceCodeURL) {
                            creditRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                title: "Open source",
                                description: "The complete source code is open for you to download, explore, and build upon.",
                                linkText: "github.com/zicodeng/PlantStory",
                                trailingIcon: "arrow.up.right"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens the PlantStory source code on GitHub")

                        Divider()
                            .overlay(.white.opacity(0.1))

                        creditRow(
                            icon: "slider.horizontal.3",
                            title: "Fully customizable",
                            description: "Make it yours. Change the colors, add new ideas, and start vibe coding your own version."
                        )
                    }
                    .padding(20)
                    .background(panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }

                    githubStarCard

                    supportCard

                    Text("Thank you for helping this little garden grow.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Credits & Contributors")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(forest, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(lime)
        .task {
            await tipJar.loadProducts()
        }
        .alert(item: $tipJar.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var githubStarCard: some View {
        Link(destination: sourceCodeURL) {
            HStack(spacing: 14) {
                Image(systemName: "star.fill")
                    .font(cardIconFont)
                    .foregroundStyle(cardIconForeground)
                    .frame(width: cardIconSize, height: cardIconSize)
                    .background(lime, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Star PlantStory on GitHub")
                        .font(cardTitleFont)
                        .foregroundStyle(.white)

                    Text("Enjoying the app? A star helps more plant lovers discover the project.")
                        .font(cardSubtitleFont)
                        .foregroundStyle(.white.opacity(0.66))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(20)
            .contentShape(Rectangle())
            .background(panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the PlantStory repository where you can star the project")
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "sun.max.fill")
                    .font(cardIconFont)
                    .foregroundStyle(cardIconForeground)
                    .frame(width: cardIconSize, height: cardIconSize)
                    .background(lime, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Help this garden grow")
                        .font(cardTitleFont)
                        .foregroundStyle(.white)

                    Text("Choose a little boost for future PlantStory ideas.")
                        .font(cardSubtitleFont)
                        .foregroundStyle(.white.opacity(0.66))
                }
            }

            if tipJar.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(lime)
                    Text("Loading support options…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            } else if tipJar.products.isEmpty {
                VStack(spacing: 10) {
                    Text(tipJar.loadingError ?? "Support options are not available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.66))
                        .multilineTextAlignment(.center)

                    Button("Try again") {
                        Task { await tipJar.loadProducts(force: true) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(lime)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(tipJar.products, id: \.id) { product in
                        let tierColor = supportTierColor(for: product)

                        Button {
                            Task { await tipJar.purchase(product) }
                        } label: {
                            HStack(spacing: 12) {
                                Text(product.displayName)
                                    .font(.subheadline.weight(.semibold))

                                Spacer()

                                if tipJar.purchasingProductID == product.id {
                                    ProgressView()
                                        .tint(forest)
                                } else {
                                    Text(product.displayPrice)
                                        .font(.subheadline.weight(.bold))
                                }
                            }
                            .foregroundStyle(forest)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .background(tierColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(tipJar.purchasingProductID != nil)
                        .accessibilityHint("Makes an optional in-app purchase to support the developer")
                    }
                }
            }

            Text("Completely optional. Tips do not unlock features or change how PlantStory works.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(panel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .allowsHitTesting(tippingEnabled)
        .accessibilityHidden(!tippingEnabled)
        .saturation(tippingEnabled ? 1 : 0.55)
        .blur(radius: tippingEnabled ? 0 : 0.8)
        .overlay {
            if !tippingEnabled {
                tippingDisabledOverlay
            }
        }
    }

    private var tippingDisabledOverlay: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(lime)

                Image(systemName: "heart.fill")
                    .font(cardIconFont)
                    .foregroundStyle(cardIconForeground)
            }
            .frame(width: cardIconSize, height: cardIconSize)

            Text("The tip jar is taking root")
                .font(cardTitleFont)
                .foregroundStyle(.white)

            Text("No tip needed right now. A GitHub star and a little extra love for your plants are more than enough.")
                .font(cardSubtitleFont)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(22)
        .background(
            LinearGradient(
                colors: [panel.opacity(0.74), forest.opacity(0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No tip needed right now. A GitHub star and caring for your plants are more than enough.")
    }

    private func supportTierColor(for product: Product) -> Color {
        switch product.id {
        case "com.zicodeng.PlantStory.tip.small":
            return seedlingGreen
        case "com.zicodeng.PlantStory.tip.regular":
            return sproutGreen
        default:
            return gardenGreen
        }
    }

    private func creditRow(
        icon: String,
        title: String,
        description: String,
        linkText: String? = nil,
        trailingIcon: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(cardIconFont)
                .foregroundStyle(cardIconForeground)
                .frame(width: cardIconSize, height: cardIconSize)
                .background(lime, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(cardTitleFont)
                    .foregroundStyle(.white)

                Text(description)
                    .font(cardSubtitleFont)
                    .foregroundStyle(.white.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)

                if let linkText {
                    Text(linkText)
                        .font(.caption.monospaced())
                        .foregroundStyle(lime)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.top, 3)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct GrowingStoryEmblem: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var balloonsFloating = false

    private let forest = Color(red: 0.035, green: 0.20, blue: 0.105)
    private let panel = Color(red: 0.105, green: 0.31, blue: 0.19)
    private let botanical = Color(red: 0.08, green: 0.45, blue: 0.24)
    private let lime = Color(red: 0.36, green: 0.82, blue: 0.12)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [panel.opacity(0.92), forest.opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 150, height: 150)

            Image(systemName: "leaf.fill")
                .font(.system(size: 92, weight: .bold))
                .foregroundStyle(botanical.opacity(0.28))
                .rotationEffect(.degrees(-30))
                .offset(x: -58, y: 24)

            Image(systemName: "leaf.fill")
                .font(.system(size: 78, weight: .bold))
                .foregroundStyle(lime.opacity(0.17))
                .rotationEffect(.degrees(34))
                .offset(x: 61, y: 30)

            LoveBalloon(
                color: Color(red: 0.94, green: 0.19, blue: 0.31),
                size: 50,
                stringHeight: 52,
                sway: -2.5,
                duration: 3.2,
                delay: 0.35,
                isFloating: balloonsFloating
            )
            .offset(x: -62, y: 18)

            LoveBalloon(
                color: Color(red: 0.98, green: 0.27, blue: 0.38),
                size: 72,
                stringHeight: 64,
                sway: 2,
                duration: 3.6,
                delay: 0,
                isFloating: balloonsFloating
            )
            .offset(y: 12)

            LoveBalloon(
                color: Color(red: 0.88, green: 0.12, blue: 0.25),
                size: 43,
                stringHeight: 47,
                sway: 3,
                duration: 2.9,
                delay: 0.7,
                isFloating: balloonsFloating
            )
            .offset(x: 64, y: 25)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Three heart balloons floating over botanical leaves")
        .onAppear {
            balloonsFloating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            balloonsFloating = !shouldReduceMotion
        }
    }
}

private struct LoveBalloon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let color: Color
    let size: CGFloat
    let stringHeight: CGFloat
    let sway: Double
    let duration: Double
    let delay: Double
    let isFloating: Bool

    var body: some View {
        VStack(spacing: -3) {
            Image(systemName: "heart.fill")
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(color)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.26))
                        .frame(width: size * 0.13, height: size * 0.13)
                        .offset(x: size * 0.25, y: size * 0.25)
                }
                .shadow(color: color.opacity(0.2), radius: 7, y: 5)

            BalloonString(sway: sway)
                .stroke(.white.opacity(0.42), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
                .frame(width: 25, height: stringHeight)
        }
        .offset(y: isFloating ? -8 : 5)
        .rotationEffect(.degrees(isFloating ? sway : -sway))
        .animation(
            reduceMotion
                ? nil
                : .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
            value: isFloating
        )
    }
}

private struct BalloonString: Shape {
    let sway: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let direction: CGFloat = sway < 0 ? -1 : 1

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.midX + (7 * direction), y: rect.height * 0.34),
            control2: CGPoint(x: rect.midX - (6 * direction), y: rect.height * 0.68)
        )
        return path
    }
}
