#if os(iOS)
import SwiftUI

struct BranchRootView: View {
    @StateObject private var store = BranchStore()
    @State private var selected = 0
    @Environment(\.scenePhase) private var phase
    var body: some View {
        TabView(selection: $selected) {
            BranchFeedView().tabItem { Label("Home", systemImage: "house") }.tag(0)
            BranchExploreView().tabItem { Label("Explore", systemImage: "safari") }.tag(1)
            BranchLibraryView(kind: .workspace).tabItem { Label("Studio", systemImage: "plus.square") }.tag(2)
            BranchLibraryView(kind: .saved).tabItem { Label("Saved", systemImage: "bookmark") }.tag(3)
            BranchProfileView().tabItem { Label("You", systemImage: "person.crop.circle") }.tag(4)
        }
        .tint(BranchStyle.green)
        .environmentObject(store)
        .preferredColorScheme(.light)
        .sheet(item: $store.sheet) { sheet in
            BranchSheetHost(sheet: sheet).environmentObject(store)
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let message = store.message {
                Text(message).font(.caption.weight(.medium)).padding(.horizontal, 20).padding(.vertical, 12)
                    .background(BranchStyle.ink, in: Capsule()).foregroundStyle(.white)
                    .padding(.top, 55).allowsHitTesting(false).transition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .alert("A little help needed", isPresented: Binding(get: { store.error != nil && store.sheet == nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .task { await store.refresh() }
        .onChange(of: phase) { _, value in if value == .active { Task { await store.refresh() } } }
    }
}

struct BranchBrandToolbar: ToolbarContent {
    @EnvironmentObject var store: BranchStore
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 7) { Image(systemName: "arrow.triangle.branch").foregroundStyle(BranchStyle.green); Text("branch").font(.system(size: 24, weight: .semibold, design: .rounded)).tracking(-1) }
                .fixedSize().foregroundStyle(BranchStyle.ink).accessibilityLabel("Branch")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { store.sheet = .interests } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Personalize your feed")
            Button { store.sheet = .settings } label: { Image(systemName: "gearshape") }.accessibilityLabel("Connection settings")
        }
    }
}

struct BranchFeedView: View {
    @EnvironmentObject var store: BranchStore
    @State private var mode: BranchFeed = .forYou
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOOD IDEAS TRAVEL TOGETHER").font(.system(size: 9, weight: .medium)).tracking(1.5).foregroundStyle(BranchStyle.secondary)
                        (Text("A little scroll.\n").foregroundColor(BranchStyle.ink) + Text("A world of possibilities.").foregroundColor(BranchStyle.secondary))
                            .font(.system(size: 29, weight: .semibold)).tracking(-1)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.top, 12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 19) {
                            ForEach(store.creators) { p in
                                Button { store.sheet = .creator(p.author) } label: {
                                    VStack(spacing: 7) {
                                        BranchAvatar(project: p, size: 48).padding(4).overlay(Circle().stroke(BranchStyle.green.opacity(0.35), lineWidth: 1))
                                        Text(p.author.components(separatedBy: " ").first ?? p.author).font(.system(size: 10)).foregroundStyle(BranchStyle.secondary)
                                    }
                                }.buttonStyle(.plain).accessibilityLabel("Meet \(p.author)")
                            }
                        }.padding(.horizontal, 22).padding(.vertical, 3)
                    }
                    HStack(spacing: 25) {
                        ForEach(BranchFeed.allCases, id: \.self) { item in
                            Button { mode = item } label: {
                                VStack(spacing: 12) {
                                    Text(item.rawValue).font(.system(size: 14, weight: mode == item ? .semibold : .regular))
                                    Capsule().fill(mode == item ? BranchStyle.green : .clear).frame(height: 2)
                                }.foregroundStyle(mode == item ? BranchStyle.ink : BranchStyle.secondary)
                            }.accessibilityAddTraits(mode == item ? [.isSelected] : [])
                        }
                        Spacer(minLength: 0)
                    }.padding(.horizontal, 24)
                    if !store.connected { BranchConnectionBanner() }
                    let feed = store.feed(mode)
                    if feed.isEmpty {
                        BranchEmpty(icon: "person.2", title: "Your people. Your kind of ideas.", message: "Follow a maker to see their projects here.")
                    }
                    ForEach(feed) { p in BranchPostCard(project: p).padding(.horizontal, 16) }
                    if !feed.isEmpty { BranchFeedEnd(count: feed.count) }
                }.padding(.bottom, 20)
            }
            .background(BranchStyle.background)
            .toolbar { BranchBrandToolbar() }
            .toolbarBackground(BranchStyle.background, for: .navigationBar)
            .refreshable { await store.refresh(showError: true) }
        }
    }
}

struct BranchAvatar: View {
    let project: BranchProject
    var size: CGFloat = 37
    var body: some View {
        Text(project.initials).font(.system(size: size * 0.34, design: .serif)).foregroundStyle(BranchStyle.green)
            .frame(width: size, height: size).background(project.tint, in: Circle())
            .accessibilityHidden(true)
    }
}

struct BranchPostCard: View {
    @EnvironmentObject var store: BranchStore
    let project: BranchProject
    @State private var showHeart = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var p: BranchProject { store.project(project.id) ?? project }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { store.sheet = .creator(p.author) } label: {
                    HStack(spacing: 9) {
                        BranchAvatar(project: p)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.author).font(.system(size: 14, weight: .semibold)).foregroundStyle(BranchStyle.ink)
                            Text(store.interests.contains(p.category) ? "Because you like \(p.category.lowercased())" : "A fresh starting point for you")
                                .font(.system(size: 11)).foregroundStyle(BranchStyle.secondary).lineLimit(2)
                        }
                    }
                }.buttonStyle(.plain).accessibilityLabel("Meet \(p.author)")
                Spacer(minLength: 3)
                if p.author != "You" {
                    Button { Task { await store.follow(p.author) } } label: {
                        Text(store.following.contains(p.author) ? "Following" : "+ Follow").font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 10).frame(minHeight: 44).background(BranchStyle.pale, in: RoundedRectangle(cornerRadius: 6))
                    }.accessibilityLabel("\(store.following.contains(p.author) ? "Unfollow" : "Follow") \(p.author)")
                }
            }.padding(14)
            ZStack(alignment: .bottomTrailing) {
                BranchProjectVisual(project: p)
                    .onTapGesture(count: 2) {
                        if !p.isLiked { Task { await store.toggleLike(p) } }
                        if !reduceMotion { withAnimation(.spring(duration: 0.25)) { showHeart = true }; Task { try? await Task.sleep(for: .seconds(0.7)); withAnimation { showHeart = false } } }
                    }
                if showHeart { Image(systemName: "heart.fill").font(.system(size: 75)).foregroundStyle(.white).shadow(radius: 8).frame(maxWidth: .infinity, maxHeight: .infinity).allowsHitTesting(false) }
                Button { store.sheet = .preview(p.id) } label: {
                    Label("Try the app", systemImage: "play.fill").font(.system(size: 11, weight: .medium)).padding(.horizontal, 13).frame(height: 44)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8)).shadow(color: .black.opacity(0.05), radius: 8)
                }.padding(14).accessibilityLabel("Try \(p.name)")
            }
            VStack(alignment: .leading, spacing: 7) {
                BranchReactions(project: p)
                Button { store.sheet = .preview(p.id) } label: { Text(p.name).font(.system(size: 19, weight: .semibold)).tracking(-0.4).foregroundStyle(BranchStyle.ink) }
                Text(p.tagline).font(.system(size: 14)).foregroundStyle(BranchStyle.secondary).lineSpacing(3)
                HStack(spacing: 10) { ForEach(p.tags, id: \.self) { Text("#" + $0.replacingOccurrences(of: " ", with: "")).font(.system(size: 10)).foregroundStyle(BranchStyle.green.opacity(0.85)) } }
                Divider().overlay(BranchStyle.line).padding(.top, 7)
                HStack {
                    Button { store.sheet = .comments(p.id) } label: { Text((p.commentCount ?? 0) > 0 ? "Join the conversation · \(p.commentCount ?? 0)" : "What would you build with this?").font(.system(size: 10)).foregroundStyle(BranchStyle.secondary).frame(minHeight: 44) }
                    Spacer()
                    Button { store.sheet = .preview(p.id) } label: { Label("Remix", systemImage: "arrow.triangle.branch").font(.system(size: 10, weight: .medium)).padding(.horizontal, 10).frame(height: 44).background(BranchStyle.pale, in: RoundedRectangle(cornerRadius: 6)) }
                }
            }.padding(.horizontal, 14).padding(.bottom, 9)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(BranchStyle.line, lineWidth: 1))
    }
}

struct BranchProjectVisual: View {
    @EnvironmentObject var store: BranchStore
    let project: BranchProject
    var body: some View {
        ZStack(alignment: .topLeading) {
            project.tint
            VStack(alignment: .leading, spacing: 13) {
                Label(project.category, systemImage: "sparkle").font(.system(size: 9)).foregroundStyle(BranchStyle.green)
                VStack(spacing: 0) {
                    HStack(spacing: 3) { ForEach(0..<3) { _ in Circle().fill(BranchStyle.line).frame(width: 3, height: 3) }; Spacer(); Text("\(project.name.lowercased()).branch").font(.system(size: 6)).foregroundStyle(BranchStyle.secondary); Spacer() }.padding(8).background(.white)
                    if let html = store.thumbnailHTML(project.parentId ?? project.id) {
                        BranchWebPreview(html: html, interactive: false, desktop: true).frame(height: 250).allowsHitTesting(false)
                    } else {
                        VStack(alignment: .leading, spacing: 16) { Text(project.name).font(.title3.weight(.medium)); Text(project.tagline).font(.caption); RoundedRectangle(cornerRadius: 8).fill(project.tint).frame(height: 70) }.padding(20).frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading).background(.white)
                    }
                }.clipShape(UnevenRoundedRectangle(topLeadingRadius: 7, topTrailingRadius: 7)).shadow(color: .black.opacity(0.05), radius: 10)
            }.padding(.horizontal, 19).padding(.top, 15)
        }.frame(height: 244).clipped().accessibilityHidden(true)
    }
}

struct BranchReactions: View {
    @EnvironmentObject var store: BranchStore
    let project: BranchProject
    var p: BranchProject { store.project(project.id) ?? project }
    var body: some View {
        HStack(spacing: 10) {
            Button { Task { await store.toggleLike(p) } } label: { HStack(spacing: 5) { Image(systemName: p.isLiked ? "heart.fill" : "heart"); Text("\(p.likes ?? 0)").font(.system(size: 11)) }.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()).foregroundStyle(p.isLiked ? BranchStyle.pink : BranchStyle.green) }
                .accessibilityLabel("\(p.isLiked ? "Unlike" : "Like") \(p.name)").accessibilityValue("\(p.likes ?? 0) likes")
            Button { store.sheet = .comments(p.id) } label: { HStack(spacing: 5) { Image(systemName: "bubble.right"); Text("\(p.commentCount ?? 0)").font(.system(size: 11)) }.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }.accessibilityLabel("Comments on \(p.name)")
            Button { store.sheet = .rating(p.id) } label: { HStack(spacing: 5) { Image(systemName: p.stars > 0 ? "star.fill" : "star"); Text(p.stars > 0 ? "\(p.stars).0" : "Rate").font(.system(size: 11)) }.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()).foregroundStyle(p.stars > 0 ? Color(hex: 0xAD914C) : BranchStyle.green) }.accessibilityLabel("Rate \(p.name)").accessibilityValue("\(p.stars) out of 5")
            Spacer(minLength: 0)
            Button { Task { await store.toggleSave(p) } } label: { Image(systemName: p.isSaved ? "bookmark.fill" : "bookmark").frame(width: 44, height: 44).contentShape(Rectangle()) }.accessibilityLabel("\(p.isSaved ? "Unsave" : "Save") \(p.name)")
        }.font(.system(size: 19, weight: .regular)).foregroundStyle(BranchStyle.green).buttonStyle(.plain).frame(minHeight: 48)
    }
}

struct BranchExploreView: View {
    @EnvironmentObject var store: BranchStore
    @State private var search = ""
    @State private var category = "All"
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Find your next starting point.").font(.system(size: 28, weight: .semibold)).tracking(-0.8).foregroundStyle(BranchStyle.ink).padding(.horizontal, 22)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) { ForEach(["All"] + store.categories, id: \.self) { item in Button { category = item } label: { Text(item).font(.system(size: 11)).padding(.horizontal, 13).frame(height: 37).background(category == item ? BranchStyle.ink : .white, in: Capsule()).foregroundStyle(category == item ? .white : BranchStyle.secondary) } } }.padding(.horizontal, 22)
                    }
                    let items = store.feed(.forYou, search: search, category: category)
                    LazyVStack(spacing: 18) { ForEach(items) { p in BranchPostCard(project: p) } }.padding(.horizontal, 16)
                    if items.isEmpty { BranchEmpty(icon: "magnifyingglass", title: "No projects found", message: "Try a different search or category.") }
                }.padding(.top, 16).padding(.bottom, 25)
            }.background(BranchStyle.background).navigationTitle("Explore").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Apps, ideas, makers…")
                .refreshable { await store.refresh(showError: true) }
        }
    }
}

enum BranchLibraryKind { case saved, workspace }
struct BranchLibraryView: View {
    @EnvironmentObject var store: BranchStore
    let kind: BranchLibraryKind
    var items: [BranchProject] { store.projects.filter { kind == .saved ? $0.isSaved : !$0.seed } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(kind == .saved ? "Good ideas, kept close." : "Your ideas, taking shape.").font(.system(size: 28, weight: .semibold)).tracking(-0.8).padding(.horizontal, 22)
                    Text(kind == .saved ? "The starting points you want to come back to." : "Remix a project and make it a little more you.").font(.system(size: 12)).foregroundStyle(BranchStyle.secondary).padding(.horizontal, 22)
                    if items.isEmpty { BranchEmpty(icon: kind == .saved ? "bookmark" : "arrow.triangle.branch", title: kind == .saved ? "A place for your favorites" : "Start with something good", message: kind == .saved ? "Tap the bookmark on any project to keep it here." : "Open an app from Home, then tap Make it yours.") }
                    LazyVStack(spacing: 18) {
                        ForEach(items) { p in
                            if kind == .workspace {
                                Button { store.sheet = .workspace(p.id) } label: {
                                    HStack(spacing: 14) { BranchAvatar(project: p, size: 48); VStack(alignment: .leading, spacing: 6) { Text(p.name).font(.headline); Text(p.published ? "Published locally" : "Your private draft").font(.caption).foregroundStyle(BranchStyle.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption) }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 12))
                                }.buttonStyle(.plain)
                            } else { BranchPostCard(project: p) }
                        }
                    }.padding(.horizontal, 16)
                }.padding(.top, 18).padding(.bottom, 30)
            }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle(kind == .saved ? "Saved" : "Your studio").navigationBarTitleDisplayMode(.inline)
                .refreshable { await store.refresh(showError: true) }
        }
    }
}

struct BranchProfileView: View {
    @EnvironmentObject var store: BranchStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Text("YO").font(.system(size: 27, design: .serif)).foregroundStyle(BranchStyle.green).frame(width: 82, height: 82).background(BranchStyle.pale, in: Circle())
                        Text("Your creative space").font(.title2.weight(.semibold)).tracking(-0.6)
                        Text("A little curiosity goes a long way.").font(.caption).foregroundStyle(BranchStyle.secondary)
                        HStack(spacing: 35) { stat("\(store.projects.filter { !$0.seed }.count)", "Remixes"); stat("\(store.following.count)", "Following"); stat("\(store.projects.filter { $0.isSaved }.count)", "Saved") }.padding(.top, 8)
                    }.padding(.vertical, 20)
                    VStack(spacing: 0) {
                        profileButton("Your interests", "slider.horizontal.3") { store.sheet = .interests }
                        Divider()
                        profileButton("Connection settings", "network") { store.sheet = .settings }
                    }.padding(.horizontal, 18).background(.white, in: RoundedRectangle(cornerRadius: 12))
                    if !store.following.isEmpty {
                        VStack(alignment: .leading, spacing: 17) {
                            Text("Makers you follow").font(.headline)
                            ForEach(store.creators.filter { store.following.contains($0.author) }) { p in
                                Button { store.sheet = .creator(p.author) } label: { HStack { BranchAvatar(project: p); Text(p.author).font(.subheadline); Spacer(); Image(systemName: "chevron.right").font(.caption) } }.buttonStyle(.plain)
                            }
                        }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 12))
                    }
                    if !store.activity.isEmpty {
                        VStack(alignment: .leading, spacing: 16) { Text("Your recent activity").font(.headline); ForEach(store.activity.prefix(8)) { a in HStack(alignment: .top, spacing: 12) { Image(systemName: "arrow.triangle.branch").foregroundStyle(BranchStyle.green); Text(a.text).font(.caption).foregroundStyle(BranchStyle.secondary); Spacer() } } }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Text("Local community preview · Example creators\nYour reactions and projects are saved on your connected server.").font(.system(size: 10)).foregroundStyle(BranchStyle.secondary).multilineTextAlignment(.center).lineSpacing(5)
                }.padding(.horizontal, 22).padding(.bottom, 30)
            }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("You").navigationBarTitleDisplayMode(.inline).refreshable { await store.refresh() }
        }
    }
    func stat(_ value: String, _ label: String) -> some View { VStack(spacing: 5) { Text(value).font(.title3.weight(.semibold)); Text(label).font(.system(size: 10)).foregroundStyle(BranchStyle.secondary) } }
    func profileButton(_ title: String, _ image: String, action: @escaping () -> Void) -> some View { Button(action: action) { HStack { Label(title, systemImage: image).font(.subheadline); Spacer(); Image(systemName: "chevron.right").font(.caption) }.frame(minHeight: 56) }.buttonStyle(.plain) }
}

struct BranchEmpty: View {
    let icon: String; let title: String; let message: String
    var body: some View { VStack(spacing: 14) { Image(systemName: icon).font(.system(size: 27, weight: .light)).foregroundStyle(BranchStyle.green).padding(18).background(BranchStyle.pale, in: Circle()); Text(title).font(.headline).foregroundStyle(BranchStyle.ink); Text(message).font(.caption).foregroundStyle(BranchStyle.secondary).multilineTextAlignment(.center).lineSpacing(4) }.padding(35).frame(maxWidth: .infinity) }
}
struct BranchFeedEnd: View {
    let count: Int
    var body: some View { VStack(spacing: 10) { Image(systemName: "checkmark.circle").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(BranchStyle.green); Text("You’re all caught up.").font(.system(size: 17, weight: .medium)); Text("\(count) projects to spark something new.\nSave a favorite or give one your own twist.").font(.system(size: 11)).multilineTextAlignment(.center).foregroundStyle(BranchStyle.secondary).lineSpacing(4) }.padding(.vertical, 30).frame(maxWidth: .infinity).foregroundStyle(BranchStyle.ink) }
}
struct BranchConnectionBanner: View {
    @EnvironmentObject var store: BranchStore
    var body: some View { Button { store.sheet = .settings } label: { HStack(spacing: 9) { Image(systemName: "wifi.slash"); Text("Offline library · Connect to save your activity").font(.system(size: 10)); Spacer(); Image(systemName: "chevron.right").font(.caption2) }.padding(12).background(BranchStyle.pale, in: RoundedRectangle(cornerRadius: 8)).padding(.horizontal, 18) }.buttonStyle(.plain).foregroundStyle(BranchStyle.green) }
}
#endif
