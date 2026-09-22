import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        statsRow
                        activityCard
                        badgesSection
                        myPromptsSection
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profile")
            .largeNavTitle()
            .navigationDestination(for: Prompt.self) { prompt in
                PromptDetailView(promptID: prompt.id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .trim(from: 0, to: levelProgress)
                    .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 76, height: 76)
                Circle()
                    .stroke(Theme.elevated, lineWidth: 5)
                    .frame(width: 76, height: 76)
                    .zIndex(-1)
                UserAvatar(user: store.currentUser, size: 60)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(store.currentUser.displayName)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(store.currentUser.handle)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Text("LEVEL \(store.currentUser.level) · \(store.currentUser.xpIntoLevel)/\(store.currentUser.xpForNextLevel) XP")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Theme.flame)
            }
            Spacer()
        }
    }

    private var levelProgress: Double {
        let next = store.currentUser.xpForNextLevel
        guard next > 0 else { return 0 }
        return min(1, Double(store.currentUser.xpIntoLevel) / Double(next))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(store.averageComposite)", label: "Avg Score", color: Theme.compositeColor(store.averageComposite))
            statCard(value: "\(store.currentUser.streakDays)", label: "Day Streak", color: Theme.flame, icon: "flame.fill")
            statCard(value: "\(store.myPrompts.count)", label: "Prompts", color: Theme.clarity)
        }
    }

    private func statCard(value: String, label: String, color: Color, icon: String? = nil) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                }
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(color)
            }
            Text(label.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Theme.textTertiary)
            HStack(alignment: .bottom, spacing: 10) {
                let activity = store.weeklyActivity
                let peak = max(1, activity.max() ?? 1)
                ForEach(Array(activity.enumerated()), id: \.offset) { index, count in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(count > 0 ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.elevated))
                            .frame(height: max(8, 52 * Double(count) / Double(peak)))
                        Text(dayLetter(offsetFromToday: 6 - index))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(index == 6 ? Theme.flame : Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 76, alignment: .bottom)
        }
        .cardStyle()
    }

    private func dayLetter(offsetFromToday: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -offsetFromToday, to: .now)!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Badges")
            if store.currentUser.badges.isEmpty {
                Text("Submit prompts to earn badges.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(store.currentUser.badges) { badge in
                            VStack(spacing: 8) {
                                Image(systemName: badge.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(badge.color)
                                Text(badge.name)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 104)
                            .padding(.vertical, 16)
                            .background(badge.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(badge.color.opacity(0.35), lineWidth: 1)
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    @State private var promptsTab: PromptsTab = .mine

    private enum PromptsTab: String, CaseIterable, Identifiable {
        case mine = "Mine"
        case saved = "Saved"
        var id: String { rawValue }
    }

    private var myPromptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Prompts",
                accessory: promptsTab == .mine ? "\(store.myPrompts.count)" : "\(store.savedPrompts.count)"
            )

            Picker("Prompts", selection: $promptsTab) {
                ForEach(PromptsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch promptsTab {
            case .mine:
                if store.myPrompts.isEmpty {
                    emptyState(
                        icon: "gauge.with.needle",
                        message: "Nothing logged yet. Your first score is one paste away."
                    ) {
                        Button {
                            Haptics.tap()
                            store.requestSubmit()
                        } label: {
                            Text("Log your first prompt")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(Theme.brandGradient, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    promptList(store.myPrompts)
                }
            case .saved:
                if store.savedPrompts.isEmpty {
                    emptyState(
                        icon: "bookmark",
                        message: "Tap the bookmark on any prompt to keep it here for quick reuse."
                    ) { EmptyView() }
                } else {
                    promptList(store.savedPrompts)
                }
            }
        }
    }

    private func promptList(_ prompts: [Prompt]) -> some View {
        ForEach(prompts) { prompt in
            NavigationLink(value: prompt) {
                PromptCard(prompt: prompt)
            }
            .buttonStyle(.plain)
        }
    }

    private func emptyState<Action: View>(icon: String, message: String, @ViewBuilder action: () -> Action) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(Theme.textTertiary)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle()
    }
}
