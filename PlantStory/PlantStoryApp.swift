import StoreKit
import SwiftUI
import UIKit

@main
struct PlantStoryApp: App {
    @UIApplicationDelegateAdaptor(PlantStoryAppDelegate.self) private var appDelegate
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue
    @AppStorage(WateringSeason.storageKey) private var activeWateringSeasonCode = WateringSeason.suggested().rawValue
    @StateObject private var store = PlantStore.shared
    @StateObject private var wildFindStore = WildFindStore()
    @StateObject private var openAIKeyStore = OpenAIKeyStore()
    @StateObject private var aiAvailabilityStore = AIAvailabilityStore()

    init() {
        if UserDefaults.standard.string(forKey: WateringSeason.storageKey) == nil {
            UserDefaults.standard.set(
                WateringSeason.suggested().rawValue,
                forKey: WateringSeason.storageKey
            )
        }

        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = UIColor(named: "Canvas")
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigation.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().tintColor = UIColor(named: "Blossom")

        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(red: 0.08, green: 0.25, blue: 0.15, alpha: 0.97)
        tabBar.shadowColor = UIColor.white.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.58)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(wildFindStore)
                .environmentObject(openAIKeyStore)
                .environment(\.aiFeaturesAvailable, aiAvailabilityStore.isAvailable)
                .environment(\.locale, selectedLanguage.locale)
                .tint(Color("LeafGreen"))
                .task {
                    await aiAvailabilityStore.monitorStorefront()
                }
                .task(id: appLanguageCode) {
                    WidgetWateringSnapshotWriter.update(plants: store.plants)
                    WateringReminderService.shared.configureNotificationCategories()
                    await WateringReminderService.shared.reconcile(plants: store.plants)
                }
                .task(id: activeWateringSeasonCode) {
                    WidgetWateringSnapshotWriter.update(plants: store.plants)
                    await WateringReminderService.shared.reconcile(plants: store.plants)
                }
                .onReceive(store.$plants) { plants in
                    Task { @MainActor in
                        await WateringReminderService.shared.reconcile(plants: plants)
                    }
                }
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageCode) ?? .english
    }
}

enum AIRegionalAvailability {
    static let restrictedStorefrontCountryCodes: Set<String> = ["CHN"]

    static func isAvailableForCurrentStorefront() async -> Bool {
        let storefront = await Storefront.current
        return isAvailable(storefrontCountryCode: storefront?.countryCode)
    }

    static func isAvailable(storefrontCountryCode: String?) -> Bool {
        let countryCode = effectiveCountryCode(storefrontCountryCode)
        guard let countryCode else {
            // App Store builds fail closed until StoreKit resolves the storefront.
            return false
        }
        return !restrictedStorefrontCountryCodes.contains(countryCode)
    }

    private static func effectiveCountryCode(_ storefrontCountryCode: String?) -> String? {
#if DEBUG
        // Set PLANTSTORY_STOREFRONT_OVERRIDE to CHN or USA in the Xcode scheme
        // to verify both regional experiences without changing Apple Accounts.
        if let override = ProcessInfo.processInfo.environment["PLANTSTORY_STOREFRONT_OVERRIDE"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return override.uppercased()
        }

        // Storefront.current can be nil for an app installed directly from Xcode.
        // This fallback is compiled out of App Store builds.
        if storefrontCountryCode == nil {
            return Locale.current.region?.identifier == "CN" ? "CHN" : "USA"
        }
#endif
        return storefrontCountryCode?.uppercased()
    }
}

@MainActor
final class AIAvailabilityStore: ObservableObject {
    @Published private(set) var isAvailable = false

    func monitorStorefront() async {
        isAvailable = await AIRegionalAvailability.isAvailableForCurrentStorefront()

        for await storefront in Storefront.updates {
            guard !Task.isCancelled else { return }
            isAvailable = AIRegionalAvailability.isAvailable(
                storefrontCountryCode: storefront.countryCode
            )
        }
    }
}

private struct AIFeaturesAvailableKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var aiFeaturesAvailable: Bool {
        get { self[AIFeaturesAvailableKey.self] }
        set { self[AIFeaturesAvailableKey.self] = newValue }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "appLanguage"

    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

enum AppLocalization {
    static var currentLanguage: AppLanguage {
        let code = UserDefaults.standard.string(forKey: AppLanguage.storageKey)
        return code.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }

    static var currentLocale: Locale {
        currentLanguage.locale
    }

    /// Resolves dynamic strings from the in-app language instead of the device language.
    /// SwiftUI handles literal localization keys through the locale environment, while
    /// strings assembled before rendering need an explicitly selected bundle.
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let format: String

        if currentLanguage == .english {
            format = key
        } else if let path = Bundle.main.path(
            forResource: currentLanguage.rawValue,
            ofType: "lproj"
        ), let languageBundle = Bundle(path: path) {
            format = languageBundle.localizedString(
                forKey: key,
                value: key,
                table: "Localizable"
            )
        } else {
            format = key
        }

        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: currentLocale, arguments: arguments)
    }

    static func dateString(
        _ date: Date,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }

    static func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = currentLocale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

enum AppTab: Hashable {
    case garden
    case wildFinds
    case plantWiki
    case settings
}

@MainActor
final class AppNavigationStore: ObservableObject {
    static let shared = AppNavigationStore()

    @Published var selectedTab: AppTab = .garden
    @Published var gardenPath: [UUID] = []

    func showSettings() {
        selectedTab = .settings
    }

    func showPlant(id: UUID) {
        selectedTab = .garden
        gardenPath = [id]
    }

    func handle(url: URL) {
        guard url.scheme == "plantstory" else { return }

        if url.host == "plant",
           let idString = url.pathComponents.dropFirst().first,
           let id = UUID(uuidString: idString) {
            showPlant(id: id)
        } else if url.host == "watering-due" {
            selectedTab = .garden
            gardenPath = []
        }
    }
}

private struct AppRootView: View {
    @StateObject private var navigation = AppNavigationStore.shared
    @StateObject private var updateChecker = AppUpdateChecker()
    @EnvironmentObject private var store: PlantStore
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            PlantListView()
                .tabItem {
                    Label("My Garden", systemImage: "house.fill")
                }
                .tag(AppTab.garden)

            WildFindsView()
                .tabItem {
                    Label("Wild Finds", systemImage: "leaf.fill")
                }
                .tag(AppTab.wildFinds)

            PlantWikiView()
                .tabItem {
                    Label("Plant Wiki", systemImage: "book.pages.fill")
                }
                .tag(AppTab.plantWiki)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(Color(red: 0.36, green: 0.82, blue: 0.12))
        .fontDesign(.rounded)
        .environmentObject(navigation)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let update = updateChecker.availableUpdate {
                AppUpdateBanner(
                    update: update,
                    updateAction: {
                        openURL(update.appStoreURL)
                        updateChecker.openedAppStore(for: update)
                    },
                    laterAction: {
                        updateChecker.remindLater(about: update)
                    }
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onOpenURL { url in
            navigation.handle(url: url)
        }
        .task {
            await updateChecker.checkIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { @MainActor in
                async let reminderRefresh: Void = WateringReminderService.shared.reconcile(
                    plants: store.plants
                )
                async let updateCheck: Void = updateChecker.checkIfNeeded()
                _ = await (reminderRefresh, updateCheck)
            }
        }
    }
}

private struct AppUpdateBanner: View {
    let update: AppUpdate
    let updateAction: () -> Void
    let laterAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color("LeafGreen"))

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.string("PlantStory %@ is available", update.version))
                        .font(.headline)
                    Text("Download the latest version from the App Store.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()

                Button("Later", action: laterAction)
                    .buttonStyle(.bordered)

                Button("Update", action: updateAction)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("LeafGreen"))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
        .accessibilityElement(children: .contain)
    }
}
