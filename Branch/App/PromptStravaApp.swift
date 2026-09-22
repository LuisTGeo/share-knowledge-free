import SwiftUI

@main
struct BranchApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            BranchRootView()
            #else
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.flame)
            #endif
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        if store.hasOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

enum Tab: Hashable {
    case home, explore, submit, leaderboards, profile
}

struct MainTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var showSubmit = false

    var body: some View {
        TabView(selection: $selection) {
            HomeFeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            CategoryBrowseView()
                .tabItem { Label("Explore", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.explore)

            Color.clear
                .tabItem { Label("Submit", systemImage: "plus.circle.fill") }
                .tag(Tab.submit)

            LeaderboardView()
                .tabItem { Label("Ranks", systemImage: "trophy.fill") }
                .tag(Tab.leaderboards)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
        .onChange(of: selection) { _, newValue in
            if newValue == .submit {
                selection = previousTab
                store.requestSubmit()
            } else {
                previousTab = newValue
            }
        }
        .onChange(of: store.pendingSubmit) { _, seed in
            showSubmit = seed != nil
        }
        .onChange(of: showSubmit) { _, shown in
            if !shown { store.pendingSubmit = nil }
        }
        .coverScreen(isPresented: $showSubmit) {
            SubmitFlowView(seed: store.pendingSubmit ?? SubmitSeed())
                .environmentObject(store)
        }
    }
}
