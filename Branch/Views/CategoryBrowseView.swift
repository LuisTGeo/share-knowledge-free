import SwiftUI

struct CategoryBrowseView: View {
    @EnvironmentObject var store: AppStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    if searchText.isEmpty {
                        categoryGrid
                    } else {
                        searchResults
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Explore")
            .largeNavTitle()
            .searchable(text: $searchText, prompt: "Prompts, categories, authors")
            .navigationDestination(for: MetaCategory.self) { category in
                SubcategoryListView(category: category)
            }
            .navigationDestination(for: Prompt.self) { prompt in
                PromptDetailView(promptID: prompt.id)
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(MetaCategory.allCases) { category in
                NavigationLink(value: category) {
                    CategoryTile(category: category, count: store.prompts(in: category).count)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }

    private var searchResults: some View {
        let results = store.search(searchText)
        return VStack(alignment: .leading, spacing: 12) {
            if results.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .padding(.top, 60)
            } else {
                Text("\(results.count) result\(results.count == 1 ? "" : "s"), best score first")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                ForEach(results) { prompt in
                    NavigationLink(value: prompt) {
                        PromptCard(prompt: prompt)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }
}

struct CategoryTile: View {
    let category: MetaCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(category.color)
            Spacer(minLength: 0)
            Text(category.displayName)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.leading)
            Text("\(count) prompt\(count == 1 ? "" : "s")")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132)
        .padding(16)
        .background(
            LinearGradient(
                colors: [category.color.opacity(0.22), Theme.card],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SubcategoryListView: View {
    @EnvironmentObject var store: AppStore
    let category: MetaCategory
    @State private var selectedSub: String? = nil

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Subcategory filter
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            subChip(nil, label: "All")
                            ForEach(category.subcategories, id: \.self) { sub in
                                subChip(sub, label: sub)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollIndicators(.hidden)

                    let filtered = store.prompts(in: category, subcategory: selectedSub)
                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "No prompts yet",
                            systemImage: category.icon,
                            description: Text("Be the first to claim this subcategory — instant 'First to submit' cred.")
                        )
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filtered) { prompt in
                                NavigationLink(value: prompt) {
                                    PromptCard(prompt: prompt)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(category.displayName)
        .inlineNavTitle()
    }

    private func subChip(_ value: String?, label: String) -> some View {
        let selected = value == selectedSub
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { selectedSub = value }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? category.color : Theme.textSecondary)
                .background(selected ? category.color.opacity(0.15) : Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? category.color : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
