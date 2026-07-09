import SwiftUI

struct SubmitFlowView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    enum Step { case compose, categorize, scoring }

    /// When forking, prefill from the original.
    var forkOf: Prompt? = nil
    /// Entry-point prefill (challenge banner, deep links).
    var seed: SubmitSeed = SubmitSeed()

    @State private var step: Step = .compose
    @State private var title = ""
    @State private var text = ""
    @State private var category: MetaCategory = .work
    @State private var subcategory = ""
    @State private var detectionConfidence: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                switch step {
                case .compose: composeStep
                case .categorize: categorizeStep
                case .scoring: ScoringRevealView(
                    title: title, text: text,
                    category: category, subcategory: subcategory,
                    forkOf: forkOf,
                    onDone: { dismiss() }
                )
                }
            }
            .navigationTitle(navTitle)
            .inlineNavTitle()
            .toolbar {
                if step != .scoring {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .onAppear {
                if let original = forkOf, text.isEmpty {
                    title = original.title
                    text = original.text
                    category = original.category
                    subcategory = original.subcategory
                } else if let seeded = seed.category {
                    category = seeded
                    subcategory = seed.subcategory ?? seeded.subcategories[0]
                }
            }
        }
        .interactiveDismissDisabled(step == .scoring)
    }

    private var navTitle: String {
        switch step {
        case .compose: return forkOf == nil ? "Log a Prompt" : "Fork Prompt"
        case .categorize: return "Categorize"
        case .scoring: return ""
        }
    }

    // MARK: Step 1 — compose

    private var composeStep: some View {
        VStack(spacing: 16) {
            if seed.isChallengeEntry {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.clock.fill")
                    Text("Weekly Challenge entry — \(store.weeklyChallenge.theme)")
                        .lineLimit(2)
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.flame)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.flame.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let original = forkOf {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                    Text("Forking “\(original.title)” — credit stays with the original.")
                        .lineLimit(2)
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.clarity)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.clarity.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            TextField("Give it a name", text: $title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste or write the prompt you actually use…")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 22)
                        .padding(.leading, 19)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .autocorrectionDisabled()
            }
            .frame(maxHeight: .infinity)

            HStack {
                Label("~\(max(1, text.count / 4)) tokens", systemImage: "number")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(ScoringEngine.isLive ? "Judge: Claude" : "Judge: on-device")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }

            Button {
                Haptics.tap()
                let detected = CategoryDetector.detect(text)
                // Don't override a deliberate starting category (fork or challenge entry).
                if forkOf == nil && seed.category == nil {
                    category = detected.category
                    subcategory = detected.subcategory
                }
                if subcategory.isEmpty { subcategory = category.subcategories[0] }
                detectionConfidence = detected.confidence
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { step = .categorize }
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(canContinue ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.elevated))
                    .foregroundStyle(canContinue ? .white : Theme.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .disabled(!canContinue)
        }
        .padding(16)
    }

    private var canContinue: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 12
    }

    // MARK: Step 2 — categorize

    private var categorizeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if detectionConfidence > 0.4 && forkOf == nil && seed.category == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-detected · \(Int(detectionConfidence * 100))% confident")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.flame)
                }

                SectionHeader(title: "Category")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(MetaCategory.allCases) { candidate in
                        let selected = candidate == category
                        Button {
                            Haptics.tap()
                            category = candidate
                            subcategory = candidate.subcategories[0]
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: candidate.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(candidate.displayName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 12)
                            .foregroundStyle(selected ? candidate.color : Theme.textSecondary)
                            .background(
                                selected ? candidate.color.opacity(0.15) : Theme.card,
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .strokeBorder(selected ? candidate.color : Theme.stroke, lineWidth: selected ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "Subcategory")
                FlowChips(
                    options: category.subcategories,
                    selection: $subcategory,
                    tint: category.color
                )

                Button {
                    Haptics.rigid()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { step = .scoring }
                } label: {
                    Label("Score it", systemImage: "gauge.with.needle.fill")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.brandGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }
}

/// Simple wrapping chip picker.
struct FlowChips: View {
    let options: [String]
    @Binding var selection: String
    var tint: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    Haptics.tap()
                    selection = option
                } label: {
                    Text(option)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selected ? tint : Theme.textSecondary)
                        .background(selected ? tint.opacity(0.15) : Theme.card, in: Capsule())
                        .overlay(Capsule().strokeBorder(selected ? tint : Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Step 3: the reveal

struct ScoringRevealView: View {
    @EnvironmentObject var store: AppStore
    let title: String
    let text: String
    let category: MetaCategory
    let subcategory: String
    var forkOf: Prompt?
    var onDone: () -> Void

    @State private var phase: Phase = .judging
    @State private var outcome: SubmitOutcome?
    @State private var pulse = false

    enum Phase { case judging, revealed }

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .judging: judgingView
            case .revealed:
                if let outcome, let score = outcome.prompt.score {
                    revealView(outcome: outcome, score: score)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            let result = await store.submit(
                title: title, text: text,
                category: category, subcategory: subcategory,
                forkedFrom: forkOf
            )
            outcome = result
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .revealed }
        }
    }

    private var judgingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.flame.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: 0.28)
                    .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(pulse ? 360 : 0))
                    .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: pulse)
                Image(systemName: "gauge.with.needle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.flame)
            }
            Text("Judging your prompt…")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Clarity · Functionality · Efficiency")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .onAppear { pulse = true }
    }

    private func revealView(outcome: SubmitOutcome, score: PromptScore) -> some View {
        let prompt = outcome.prompt
        return ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text(Theme.tierName(score.composite).uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Theme.compositeColor(score.composite))
                    ScoreRing(
                        score: score.composite,
                        color: Theme.compositeColor(score.composite),
                        size: 150, lineWidth: 13
                    )
                    Text(prompt.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    CategoryChip(category: prompt.category, subcategory: prompt.subcategory)
                }

                achievements(outcome)

                HStack(spacing: 18) {
                    ScoreRing(score: score.clarity.value, label: "Clarity", color: Theme.clarity, size: 82, delay: 0.5)
                    ScoreRing(score: score.functionality.value, label: "Function", color: Theme.functionality, size: 82, delay: 0.75)
                    ScoreRing(score: score.efficiency.value, label: "Efficiency", color: Theme.efficiency, size: 82, delay: 1.0)
                }

                VStack(alignment: .leading, spacing: 12) {
                    RationaleRow(color: Theme.clarity, title: "Clarity", text: score.clarity.rationale)
                    RationaleRow(color: Theme.functionality, title: "Functionality", text: score.functionality.rationale)
                    RationaleRow(color: Theme.efficiency, title: "Efficiency", text: score.efficiency.rationale)
                }
                .cardStyle()

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("+\(score.composite) XP · streak day \(store.currentUser.streakDays)")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.flame)

                    if let rank = outcome.weeklyRank {
                        Text("#\(rank) in \(prompt.category.displayName) this week")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                HStack(spacing: 10) {
                    ShareLink(item: shareText(prompt: prompt, score: score)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.elevated)
                            .foregroundStyle(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })

                    Button {
                        Haptics.tap()
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.brandGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    /// Personal best / level-up / new badges — the wins that used to happen silently.
    @ViewBuilder
    private func achievements(_ outcome: SubmitOutcome) -> some View {
        let pills: [(icon: String, label: String, color: Color)] =
            (outcome.isPersonalBest ? [("trophy.fill", "Personal best", Theme.efficiency)] : [])
            + (outcome.didLevelUp ? [("arrow.up.circle.fill", "Level \(store.currentUser.level)!", Theme.flame)] : [])
            + outcome.newBadges.map { ($0.icon, "\($0.name) unlocked", $0.color) }

        if !pills.isEmpty {
            HStack(spacing: 8) {
                ForEach(Array(pills.enumerated()), id: \.offset) { _, pill in
                    HStack(spacing: 5) {
                        Image(systemName: pill.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(pill.label)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(pill.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(pill.color.opacity(0.14), in: Capsule())
                    .overlay(Capsule().strokeBorder(pill.color.opacity(0.4), lineWidth: 1))
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func shareText(prompt: Prompt, score: PromptScore) -> String {
        "My prompt “\(prompt.title)” scored \(score.composite)/100 (\(Theme.tierName(score.composite))) on PromptStrava 🔥 Clarity \(score.clarity.value) · Function \(score.functionality.value) · Efficiency \(score.efficiency.value)"
    }
}

struct RationaleRow: View {
    let color: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(color).frame(width: 8, height: 8).padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(color)
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
