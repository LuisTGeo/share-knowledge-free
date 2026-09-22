import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        challengeBanner
                        trendingSection
                        feedSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .hideNavBar()
            .navigationDestination(for: Prompt.self) { prompt in
                PromptDetailView(promptID: prompt.id)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PromptStrava")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("Level \(store.currentUser.level) · \(store.currentUser.xp) XP")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            StreakFlame(days: store.currentUser.streakDays)
        }
        .padding(.top, 8)
    }

    private var challengeBanner: some View {
        Button {
            Haptics.rigid()
            store.requestSubmit(SubmitSeed(category: store.weeklyChallenge.category, isChallengeEntry: true))
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(store.weeklyChallenge.title.uppercased(), systemImage: "bolt.badge.clock.fill")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("ends in \(store.weeklyChallenge.endsInDays)d")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Text(store.weeklyChallenge.theme)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Image(systemName: store.weeklyChallenge.category.icon)
                    Text("\(store.weeklyChallenge.category.displayName) · tap to enter")
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Theme.flame, Theme.ember], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trending", accessory: "most used")
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(store.trending) { prompt in
                        NavigationLink(value: prompt) {
                            TrendingCard(prompt: prompt)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if !store.selectedInterests.isEmpty {
                    feedToggle
                }
            }
            ForEach(feedPrompts) { prompt in
                NavigationLink(value: prompt) {
                    PromptCard(prompt: prompt)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Puts the onboarding interest picks to work: "For you" narrows the
    /// feed to the categories the user said they prompt in.
    private var feedPrompts: [Prompt] {
        showAllFeed ? store.feed : store.personalizedFeed
    }

    @State private var showAllFeed = false

    private var feedToggle: some View {
        HStack(spacing: 4) {
            feedToggleChip("For you", isOn: !showAllFeed) { showAllFeed = false }
            feedToggleChip("All", isOn: showAllFeed) { showAllFeed = true }
        }
    }

    private func feedToggleChip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { action() }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .foregroundStyle(isOn ? Theme.flame : Theme.textSecondary)
                .background(isOn ? Theme.flame.opacity(0.15) : Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(isOn ? Theme.flame : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct TrendingCard: View {
    @EnvironmentObject var store: AppStore
    let prompt: Prompt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryChip(category: prompt.category)
                Spacer()
                if let score = prompt.score {
                    Text("\(score.composite)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.compositeColor(score.composite))
                }
            }
            Text(prompt.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            HStack {
                StatPill(icon: "bolt.fill", value: "\(prompt.usedCount) uses", tint: Theme.efficiency)
                Spacer()
                Text("@\(store.user(prompt.authorID).handle)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: 230, height: 128)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        )
    }
}
