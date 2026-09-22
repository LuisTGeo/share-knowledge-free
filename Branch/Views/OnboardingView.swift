import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var page = 0

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    pitchPage.tag(0)
                    scoringPage.tag(1)
                    interestsPage.tag(2)
                }
                .pagedTabView()

                Spacer(minLength: 16)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Theme.flame : Theme.elevated)
                            .frame(width: index == page ? 24 : 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                Button(action: advance) {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canAdvance ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.elevated))
                        .foregroundStyle(canAdvance ? .white : Theme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(!canAdvance)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: page)
    }

    private var buttonTitle: String {
        switch page {
        case 0: return "How it works"
        case 1: return "Pick your arenas"
        default: return "Start logging prompts"
        }
    }

    private var canAdvance: Bool {
        page < 2 || !store.selectedInterests.isEmpty
    }

    private func advance() {
        Haptics.tap()
        if page < 2 {
            page += 1
        } else {
            store.hasOnboarded = true
        }
    }

    // MARK: Page 1 — pitch

    private var pitchPage: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.brandGradient)
                    .frame(width: 108, height: 108)
                    .blur(radius: 40)
                    .opacity(0.6)
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.brandGradient)
            }
            Text("PromptStrava")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("The prompts you use every day are a skill.\nLog them. Score them. Compete.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: Page 2 — scoring explainer

    private var scoringPage: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Every prompt gets judged")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                ScoreRing(score: 86, label: "Clarity", color: Theme.clarity, size: 88, delay: 0.1)
                ScoreRing(score: 91, label: "Function", color: Theme.functionality, size: 88, delay: 0.35)
                ScoreRing(score: 78, label: "Efficiency", color: Theme.efficiency, size: 88, delay: 0.6)
            }

            VStack(alignment: .leading, spacing: 14) {
                explainerRow(color: Theme.clarity, title: "Clarity", detail: "Zero ambiguity. The model can't misread you.")
                explainerRow(color: Theme.functionality, title: "Functionality", detail: "Reliably produces the output you actually wanted.")
                explainerRow(color: Theme.efficiency, title: "Efficiency", detail: "No wasted tokens. Result in one shot.")
            }
            .cardStyle()
            .padding(.horizontal, 24)

            Text("An AI judge scores each axis 0–100 and tells you exactly how to improve.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func explainerRow(color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10).padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: Page 3 — interests

    private var interestsPage: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)
            Text("Where do you prompt?")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Pick at least one. This shapes your feed and leaderboards.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MetaCategory.allCases) { category in
                    let selected = store.selectedInterests.contains(category)
                    Button {
                        Haptics.tap()
                        var interests = store.selectedInterests
                        if selected {
                            interests.remove(category)
                        } else {
                            interests.insert(category)
                        }
                        store.setInterests(interests)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 22, weight: .semibold))
                            Text(category.displayName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .foregroundStyle(selected ? category.color : Theme.textSecondary)
                        .background(
                            selected ? category.color.opacity(0.15) : Theme.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(selected ? category.color : Theme.stroke, lineWidth: selected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}
