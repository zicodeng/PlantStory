import SwiftUI
import UIKit

@main
struct PlantStoryApp: App {
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode = AppLanguage.english.rawValue
    @StateObject private var store = PlantStore()
    @StateObject private var wildFindStore = WildFindStore()
    @StateObject private var openAIKeyStore = OpenAIKeyStore()

    init() {
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
                .environment(\.locale, selectedLanguage.locale)
                .tint(Color("LeafGreen"))
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageCode) ?? .english
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
    case settings
}

final class AppNavigationStore: ObservableObject {
    @Published var selectedTab: AppTab = .garden

    func showSettings() {
        selectedTab = .settings
    }
}

private struct AppRootView: View {
    @StateObject private var navigation = AppNavigationStore()

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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(Color(red: 0.36, green: 0.82, blue: 0.12))
        .fontDesign(.rounded)
        .environmentObject(navigation)
    }
}
