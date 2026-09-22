import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var timeframe: Timeframe = .week
    @State private var category: MetaCategory? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 0) {
                    controls
                    board
                }
            }
            .navigationTitle("Leaderboards")
            .largeNavTitle()
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Timeframe", selection: $timeframe) {
                ForEach(Timeframe.allCases) { frame in
                    Text(frame.rawValue).tag(frame)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    categoryFilterChip(nil)
                    ForEach(MetaCategory.allCases) { candidate in
                        categoryFilterChip(candidate)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 12)
    }

    private func categoryFilterChip(_ candidate: MetaCategory?) -> some View {
        let selected = candidate == category
        let tint = candidate?.color ?? Theme.flame
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { category = candidate }
        } label: {
            HStack(spacing: 5) {
                if let candidate {
                    Image(systemName: candidate.icon).font(.system(size: 10, weight: .bold))
                }
                Text(candidate?.displayName ?? "Global")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? tint : Theme.textSecondary)
            .background(selected ? tint.opacity(0.15) : Theme.card, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? tint : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var board: some View {
        let entries = store.leaderboard(category: category, timeframe: timeframe)
        return Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No entries yet",
                    systemImage: "trophy",
                    description: Text("Be the first to submit a \(category?.displayName ?? "") prompt this period.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(entries) { entry in
                            LeaderboardRow(entry: entry, isMe: entry.user.id == store.currentUser.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 90)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    if let rank = store.myRank(category: category, timeframe: timeframe) {
                        myRankBar(rank: rank, total: entries.count)
                    }
                }
            }
        }
    }

    private func myRankBar(rank: Int, total: Int) -> some View {
        HStack {
            Text("Your rank")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text("#\(rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("of \(total)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Theme.brandGradient, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: Theme.flame.opacity(0.4), radius: 16, y: 4)
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isMe: Bool

    private var medal: Color? {
        switch entry.rank {
        case 1: return Color(hex: 0xFFD700)
        case 2: return Color(hex: 0xC0C0C0)
        case 3: return Color(hex: 0xCD7F32)
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let medal {
                    Circle().fill(medal.opacity(0.18)).frame(width: 34, height: 34)
                }
                Text("\(entry.rank)")
                    .font(.system(size: entry.rank < 100 ? 15 : 12, weight: .black, design: .rounded))
                    .foregroundStyle(medal ?? Theme.textSecondary)
            }
            .frame(width: 34)

            UserAvatar(user: entry.user, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.user.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(entry.user.handle) · \(entry.promptCount) prompt\(entry.promptCount == 1 ? "" : "s")")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            // Rank movement
            if entry.delta != 0 {
                HStack(spacing: 2) {
                    Image(systemName: entry.delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .heavy))
                    Text("\(abs(entry.delta))")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(entry.delta > 0 ? Theme.functionality : Theme.ember)
            }

            Text("\(entry.bestScore)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Theme.compositeColor(entry.bestScore))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isMe ? Theme.flame.opacity(0.12) : Theme.card,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isMe ? Theme.flame.opacity(0.6) : Theme.stroke, lineWidth: 1)
        )
    }
}
