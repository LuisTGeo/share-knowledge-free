import SwiftUI

// MARK: - Categories

enum MetaCategory: String, CaseIterable, Codable, Identifiable {
    case work, social, health, finance, learning, creativity, lifeAdmin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .social: return "Social"
        case .health: return "Health & Fitness"
        case .finance: return "Personal Finance"
        case .learning: return "Learning & Skills"
        case .creativity: return "Creativity"
        case .lifeAdmin: return "Life Admin"
        }
    }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .social: return "person.2.fill"
        case .health: return "figure.run"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .learning: return "graduationcap.fill"
        case .creativity: return "paintbrush.pointed.fill"
        case .lifeAdmin: return "checklist"
        }
    }

    var color: Color {
        switch self {
        case .work: return Color(hex: 0x3B82F6)
        case .social: return Color(hex: 0xEC4899)
        case .health: return Color(hex: 0x22C55E)
        case .finance: return Color(hex: 0x14B8A6)
        case .learning: return Color(hex: 0x8B5CF6)
        case .creativity: return Color(hex: 0xF97316)
        case .lifeAdmin: return Color(hex: 0x6366F1)
        }
    }

    var subcategories: [String] {
        switch self {
        case .work:
            return ["Resume Builder", "Interview Prep", "Email & Slack Drafting", "Meeting Summarizer", "Code Review", "Presentation Builder"]
        case .social:
            return ["Dating Profile Writer", "Conflict Mediator", "Gift Ideas", "Toasts & Speeches", "Small Talk Coach"]
        case .health:
            return ["Diet Planner", "Workout Coach", "Sleep Optimizer", "Habit Builder", "Mental Reset"]
        case .finance:
            return ["Budgeter", "Investment Research", "Expense Categorizer", "Negotiation Scripts", "Tax Prep Helper"]
        case .learning:
            return ["Language Tutor", "Concept Explainer", "Study Planner", "Flashcard Generator", "Book Distiller"]
        case .creativity:
            return ["Story Starter", "Songwriting Partner", "Naming & Branding", "Image Prompting", "World Builder"]
        case .lifeAdmin:
            return ["Travel Planner", "Meal Prep", "Email Triage", "Moving Checklist", "Appointment Scripts"]
        }
    }
}

// MARK: - Scoring

struct AxisScore: Codable, Hashable {
    var value: Int
    var rationale: String
}

struct PromptScore: Codable, Hashable {
    var clarity: AxisScore
    var functionality: AxisScore
    var efficiency: AxisScore

    /// Functionality weighs heaviest — it's what makes a prompt actually useful.
    var composite: Int {
        let weighted = Double(clarity.value) * 0.35
            + Double(functionality.value) * 0.40
            + Double(efficiency.value) * 0.25
        return Int(weighted.rounded())
    }
}

// MARK: - Prompt

struct Prompt: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var text: String
    var authorID: UUID
    var category: MetaCategory
    var subcategory: String
    var compatibleModels: [String] = ["Claude", "ChatGPT", "Gemini"]
    var createdAt: Date
    var likes: Int = 0
    var usedCount: Int = 0
    var forkCount: Int = 0
    var commentCount: Int = 0
    var forkedFromID: UUID?
    var score: PromptScore?

    var snippet: String {
        text.replacingOccurrences(of: "\n", with: " ")
    }

    var estimatedTokens: Int {
        max(1, text.count / 4)
    }
}

// MARK: - User

struct Badge: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: UInt32

    var color: Color { Color(hex: colorHex) }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var handle: String
    var displayName: String
    var avatarEmoji: String
    var xp: Int
    var streakDays: Int
    var badges: [Badge] = []

    var level: Int { max(1, Int(Double(xp).squareRoot() / 10) + 1) }
    var xpIntoLevel: Int { xp - xpFloor(for: level) }
    var xpForNextLevel: Int { xpFloor(for: level + 1) - xpFloor(for: level) }

    private func xpFloor(for level: Int) -> Int {
        let l = Double(level - 1) * 10
        return Int(l * l)
    }
}

// MARK: - Submitting

/// Prefill for the submit flow — lets the challenge banner, empty states,
/// and the tab bar all open the same flow with different starting points.
struct SubmitSeed: Identifiable, Equatable {
    var id = UUID()
    var category: MetaCategory?
    var subcategory: String?
    var isChallengeEntry = false
}

/// Everything the score-reveal screen needs to celebrate a submission.
struct SubmitOutcome {
    var prompt: Prompt
    var newBadges: [Badge]
    var didLevelUp: Bool
    var isPersonalBest: Bool
    var weeklyRank: Int?
}

// MARK: - Leaderboard

enum Timeframe: String, CaseIterable, Identifiable {
    case week = "This Week"
    case month = "This Month"
    case allTime = "All Time"
    var id: String { rawValue }
}

struct LeaderboardEntry: Identifiable {
    var id: UUID { user.id }
    var rank: Int
    var user: UserProfile
    var bestScore: Int
    var promptCount: Int
    var delta: Int    // rank movement vs previous period
}
