import SwiftUI

// MARK: - Score rings

/// Animated circular score gauge with count-up number. The reveal moment.
struct ScoreRing: View {
    let score: Int
    var label: String? = nil
    var color: Color = Theme.flame
    var size: CGFloat = 96
    var lineWidth: CGFloat = 9
    var animated: Bool = true
    var delay: Double = 0

    @State private var progress: Double = 0
    @State private var displayed: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.6), color],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * max(progress, 0.01))
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(displayed)")
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText(value: Double(displayed)))
            }
            .frame(width: size, height: size)

            if let label {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label ?? "Overall") score: \(score) out of 100")
        .task(id: score) {
            guard animated else {
                progress = Double(score) / 100
                displayed = score
                return
            }
            progress = 0
            displayed = 0
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            withAnimation(.spring(response: 1.1, dampingFraction: 0.85)) {
                progress = Double(score) / 100
            }
            // Count-up in ~22 steps synced to the ring sweep.
            let steps = 22
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: 42_000_000)
                withAnimation(.linear(duration: 0.04)) {
                    displayed = Int(Double(score) * Double(step) / Double(steps))
                }
            }
            displayed = score
        }
    }
}

/// Compact composite badge used on cards and rows.
struct ScoreBadge: View {
    let score: Int
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.compositeColor(score).opacity(0.18), lineWidth: 4)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(Theme.compositeColor(score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score: \(score) out of 100")
    }
}

// MARK: - Chips & labels

struct CategoryChip: View {
    let category: MetaCategory
    var subcategory: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.icon)
                .font(.system(size: 10, weight: .bold))
            Text(subcategory ?? category.displayName)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(category.color.opacity(0.14), in: Capsule())
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    var tint: Color = Theme.textSecondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(tint)
    }
}

struct UserAvatar: View {
    let user: UserProfile
    var size: CGFloat = 36

    var body: some View {
        Text(user.avatarEmoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Theme.elevated, in: Circle())
            .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    var accessory: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let accessory {
                Text(accessory)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.flame)
            }
        }
    }
}

struct StreakFlame: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Theme.brandGradient)
            Text("\(days)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days)-day streak")
    }
}

// MARK: - Prompt card

struct PromptCard: View {
    @EnvironmentObject var store: AppStore
    let prompt: Prompt

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    CategoryChip(category: prompt.category, subcategory: prompt.subcategory)
                    Text(prompt.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 12)
                if let score = prompt.score {
                    ScoreBadge(score: score.composite)
                }
            }

            Text(prompt.snippet)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    UserAvatar(user: store.user(prompt.authorID), size: 22)
                    Text("@\(store.user(prompt.authorID).handle)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                StatPill(icon: "bolt.fill", value: "\(prompt.usedCount)", tint: Theme.efficiency)
                StatPill(
                    icon: store.likedPromptIDs.contains(prompt.id) ? "heart.fill" : "heart",
                    value: "\(prompt.likes)",
                    tint: store.likedPromptIDs.contains(prompt.id) ? Theme.ember : Theme.textSecondary
                )
                StatPill(icon: "arrow.triangle.branch", value: "\(prompt.forkCount)")
            }
        }
        .cardStyle()
        .contextMenu {
            Button {
                copyToPasteboard(prompt.text)
                Haptics.success()
            } label: {
                Label("Copy prompt", systemImage: "doc.on.doc")
            }
            Button {
                store.toggleLike(prompt)
            } label: {
                Label(
                    store.likedPromptIDs.contains(prompt.id) ? "Unlike" : "Like",
                    systemImage: store.likedPromptIDs.contains(prompt.id) ? "heart.slash" : "heart"
                )
            }
            Button {
                store.toggleSave(prompt)
            } label: {
                Label(
                    store.savedPromptIDs.contains(prompt.id) ? "Remove from Saved" : "Save",
                    systemImage: store.savedPromptIDs.contains(prompt.id) ? "bookmark.slash" : "bookmark"
                )
            }
        }
    }
}

// MARK: - Backgrounds

struct AppBackground: View {
    var body: some View {
        Theme.background.ignoresSafeArea()
    }
}
