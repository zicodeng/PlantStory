import SwiftUI
import UIKit

@main
struct PlantStoryApp: App {
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
                .tint(Color("LeafGreen"))
        }
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
