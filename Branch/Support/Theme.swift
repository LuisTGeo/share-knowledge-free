import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Dark-first visual system. Bold, athletic, data-forward — closer to a
/// fitness tracker than a notes app.
enum Theme {
    // Brand
    static let flame = Color(hex: 0xFC5200)          // primary brand (Strava-confidence orange)
    static let flameSoft = Color(hex: 0xFF7A3D)
    static let ember = Color(hex: 0xFF3B6B)

    // Surfaces
    static let background = Color(hex: 0x0C0E13)
    static let card = Color(hex: 0x151922)
    static let elevated = Color(hex: 0x1E2430)
    static let stroke = Color.white.opacity(0.07)

    // Text
    static let textPrimary = Color(hex: 0xF2F4F8)
    static let textSecondary = Color(hex: 0x8B94A6)
    static let textTertiary = Color(hex: 0x5A6274)

    // Scoring axes
    static let clarity = Color(hex: 0x38BDF8)        // sky
    static let functionality = Color(hex: 0x4ADE80)  // green
    static let efficiency = Color(hex: 0xFBBF24)     // amber

    static let brandGradient = LinearGradient(
        colors: [flame, ember],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func compositeColor(_ score: Int) -> Color {
        switch score {
        case ..<40: return Color(hex: 0xF87171)
        case ..<60: return efficiency
        case ..<80: return flameSoft
        default: return functionality
        }
    }

    static func tierName(_ score: Int) -> String {
        switch score {
        case ..<40: return "Rough Draft"
        case ..<60: return "Solid"
        case ..<75: return "Sharp"
        case ..<90: return "Elite"
        default: return "Legendary"
        }
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}
