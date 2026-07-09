import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Small cross-platform shims so the app source also typechecks on macOS
/// (used for CI-style verification); the shipping target is iOS.
enum Haptics {
    static func tap() {
        #if canImport(UIKit) && !os(watchOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func rigid() {
        #if canImport(UIKit) && !os(watchOS)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
    }

    static func success() {
        #if canImport(UIKit) && !os(watchOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

func copyToPasteboard(_ string: String) {
    #if canImport(UIKit)
    UIPasteboard.general.string = string
    #elseif canImport(AppKit)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(string, forType: .string)
    #endif
}

extension View {
    @ViewBuilder
    func inlineNavTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func largeNavTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    @ViewBuilder
    func hideNavBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// Swipeable page-style TabView on iOS (dots hidden — we draw our own).
    @ViewBuilder
    func pagedTabView() -> some View {
        #if os(iOS)
        self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self
        #endif
    }

    /// Full-screen cover on iOS, plain sheet elsewhere.
    @ViewBuilder
    func coverScreen<C: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> C) -> some View {
        #if os(iOS)
        self.fullScreenCover(isPresented: isPresented, content: content)
        #else
        self.sheet(isPresented: isPresented, content: content)
        #endif
    }
}
