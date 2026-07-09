import SwiftUI

struct PromptDetailView: View {
    @EnvironmentObject var store: AppStore
    let promptID: UUID

    @State private var showFork = false
    @State private var copied = false

    private var prompt: Prompt? { store.prompt(promptID) }

    var body: some View {
        ZStack {
            AppBackground()
            if let prompt {
                content(prompt)
            } else {
                ContentUnavailableView("Prompt not found", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle("")
        .inlineNavTitle()
        .sheet(isPresented: $showFork) {
            SubmitFlowView(forkOf: prompt)
                .environmentObject(store)
        }
    }

    private func content(_ prompt: Prompt) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    CategoryChip(category: prompt.category, subcategory: prompt.subcategory)
                    Text(prompt.title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 8) {
                        UserAvatar(user: store.user(prompt.authorID), size: 26)
                        Text("@\(store.user(prompt.authorID).handle)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text("·")
                            .foregroundStyle(Theme.textTertiary)
                        Text(prompt.createdAt, style: .relative)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                // Fork lineage
                if let originalID = prompt.forkedFromID, let original = store.prompt(originalID) {
                    NavigationLink(value: original) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.branch")
                            Text("Forked from “\(original.title)” by @\(store.user(original.authorID).handle)")
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.clarity)
                        .padding(12)
                        .background(Theme.clarity.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                // Scores
                if let score = prompt.score {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            ScoreRing(score: score.composite, label: Theme.tierName(score.composite),
                                      color: Theme.compositeColor(score.composite), size: 110, lineWidth: 11, animated: false)
                            VStack(alignment: .leading, spacing: 10) {
                                axisBar("Clarity", score.clarity.value, Theme.clarity)
                                axisBar("Function", score.functionality.value, Theme.functionality)
                                axisBar("Efficiency", score.efficiency.value, Theme.efficiency)
                            }
                        }
                        Divider().overlay(Theme.stroke)
                        VStack(alignment: .leading, spacing: 12) {
                            RationaleRow(color: Theme.clarity, title: "Clarity", text: score.clarity.rationale)
                            RationaleRow(color: Theme.functionality, title: "Functionality", text: score.functionality.rationale)
                            RationaleRow(color: Theme.efficiency, title: "Efficiency", text: score.efficiency.rationale)
                        }
                    }
                    .cardStyle()
                }

                // Prompt text
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("THE PROMPT")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(Theme.textTertiary)
                        Spacer()
                        Button {
                            copyToPasteboard(prompt.text)
                            Haptics.success()
                            withAnimation { copied = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 1_600_000_000)
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(copied ? Theme.functionality : Theme.flame)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(prompt.text)
                        .font(.system(size: 13.5, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardStyle()

                // Meta row
                HStack(spacing: 10) {
                    ForEach(prompt.compatibleModels, id: \.self) { model in
                        Text(model)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.elevated, in: Capsule())
                    }
                    Spacer()
                    Text("~\(prompt.estimatedTokens) tokens")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }

                actionBar(prompt)
                    .padding(.bottom, 24)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private func axisBar(_ name: String, _ value: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * Double(value) / 100)
                }
            }
            .frame(height: 6)
        }
    }

    private func actionBar(_ prompt: Prompt) -> some View {
        HStack(spacing: 10) {
            actionButton(
                icon: store.likedPromptIDs.contains(prompt.id) ? "heart.fill" : "heart",
                label: "\(prompt.likes)",
                tint: store.likedPromptIDs.contains(prompt.id) ? Theme.ember : Theme.textSecondary
            ) { store.toggleLike(prompt) }

            actionButton(
                icon: "bolt.fill",
                label: store.usedPromptIDs.contains(prompt.id) ? "Used ✓" : "I used this",
                tint: store.usedPromptIDs.contains(prompt.id) ? Theme.efficiency : Theme.textSecondary
            ) { store.markUsed(prompt) }

            actionButton(icon: "arrow.triangle.branch", label: "Fork", tint: Theme.clarity) {
                showFork = true
            }

            actionButton(
                icon: store.savedPromptIDs.contains(prompt.id) ? "bookmark.fill" : "bookmark",
                label: "Save",
                tint: store.savedPromptIDs.contains(prompt.id) ? Theme.flame : Theme.textSecondary
            ) { store.toggleSave(prompt) }
        }
    }

    private func actionButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(tint)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
