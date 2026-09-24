import SwiftUI

@main
struct BranchApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            BranchRootView()
            #else
            ContentUnavailableView("Branch", systemImage: "arrow.triangle.branch")
            #endif
        }
    }
}
