#if os(iOS)
import SwiftUI

struct BranchSheetHost: View {
    @EnvironmentObject var store: BranchStore
    let sheet: BranchSheet
    @State private var confirmDiscard = false
    var body: some View {
        NavigationStack {
            Group {
                switch sheet {
                case .preview(let id): BranchDetailSheet(id: id)
                case .comments(let id): BranchCommentsSheet(id: id)
                case .rating(let id): BranchRatingSheet(id: id)
                case .creator(let author): BranchCreatorSheet(author: author)
                case .interests: BranchInterestsSheet()
                case .settings: BranchSettingsSheet()
                case .workspace(let id): BranchWorkspaceSheet(id: id)
                }
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") {
                    if store.workspaceBusy { store.notify("Let the current change finish first.") }
                    else if store.workspaceHasUnsavedChanges { confirmDiscard = true }
                    else { store.sheet = nil }
                }.font(.subheadline.weight(.medium)) } }
            .confirmationDialog("Leave unsaved changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { store.workspaceHasUnsavedChanges = false; store.sheet = nil }
                Button("Keep editing", role: .cancel) {}
            } message: { Text("Save your source changes before leaving, or discard them.") }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BranchStyle.background, for: .navigationBar)
            .alert("A little help needed", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }.tint(BranchStyle.green).preferredColorScheme(.light)
    }
}

struct BranchCommentsSheet: View {
    @EnvironmentObject var store: BranchStore
    let id: String
    @State private var comments: [BranchComment] = []
    @State private var text = ""
    @State private var loading = true
    @State private var posting = false
    @State private var failure: String?
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 0) {
            if let p = store.project(id) {
                HStack(spacing: 11) { BranchAvatar(project: p); VStack(alignment: .leading, spacing: 4) { Text(p.name).font(.subheadline.weight(.semibold)); Text(p.tagline).font(.system(size: 11)).foregroundStyle(BranchStyle.secondary) }; Spacer() }.padding(20)
            }
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    if loading { ProgressView().frame(maxWidth: .infinity).padding(40) }
                    else if comments.isEmpty { BranchEmpty(icon: "bubble.left.and.bubble.right", title: "Start something good.", message: "Share what you like, ask a question,\nor suggest a fresh direction.") }
                    ForEach(comments) { c in
                        HStack(alignment: .top, spacing: 11) {
                            Text(String(c.author.prefix(2)).uppercased()).font(.system(size: 10)).frame(width: 32, height: 32).background(BranchStyle.pale, in: Circle()).foregroundStyle(BranchStyle.green)
                            VStack(alignment: .leading, spacing: 6) { Text(c.author).font(.system(size: 12, weight: .semibold)); Text(c.text).font(.system(size: 14)).foregroundStyle(BranchStyle.secondary).lineSpacing(4).textSelection(.enabled) }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(20)
            }.scrollDismissesKeyboard(.interactively)
            if let failure { Text(failure).font(.caption).foregroundStyle(.red).padding(.horizontal, 20) }
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    suggestion("Suggest an idea", prefix: "I’d love to see ")
                    suggestion("Give feedback", prefix: "What I like about this is ")
                    Spacer()
                }
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("A little feedback goes a long way…", text: $text, axis: .vertical).font(.subheadline).lineLimit(2...5).padding(12).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(BranchStyle.line)).focused($focused).accessibilityLabel("Your comment")
                    Button { Task { await submit() } } label: { Group { if posting { ProgressView().tint(.white) } else { Image(systemName: "paperplane.fill") } }.frame(width: 45, height: 45).background(BranchStyle.ink, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white) }.disabled(posting || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > 1000).accessibilityLabel("Post comment")
                }
                HStack { Text("Keep it kind. Make it useful."); Spacer(); Text("\(text.count) / 1000").foregroundStyle(text.count > 1000 ? .red : BranchStyle.secondary) }.font(.system(size: 10)).foregroundStyle(BranchStyle.secondary)
            }.padding(20).background(BranchStyle.background)
        }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("The conversation")
            .task { await load() }
    }
    func suggestion(_ title: String, prefix: String) -> some View { Button { text = prefix; focused = true } label: { Text(title).font(.system(size: 10)).padding(.horizontal, 10).frame(height: 32).background(BranchStyle.pale, in: Capsule()) } }
    func load() async { do { comments = try await store.comments(id) } catch { failure = "Connect to your Branch server to load comments." }; loading = false }
    func submit() async {
        posting = true; failure = nil
        defer { posting = false }
        do { try await store.comment(id, text: text); text = ""; focused = false; await load(); store.notify("Comment posted. Thanks for adding to the idea.") }
        catch { failure = error.localizedDescription }
    }
}

struct BranchRatingSheet: View {
    @EnvironmentObject var store: BranchStore
    let id: String
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "sparkles").font(.system(size: 34, weight: .light)).foregroundStyle(BranchStyle.green)
            Text("A few stars.\nA little encouragement.").font(.system(size: 27, weight: .semibold)).tracking(-0.8).multilineTextAlignment(.center)
            Text("How useful is \(store.project(id)?.name ?? "this project")\nas a starting point?").font(.subheadline).foregroundStyle(BranchStyle.secondary).multilineTextAlignment(.center)
            HStack(spacing: 13) {
                ForEach(1...5, id: \.self) { n in
                    Button { Task { await store.mutate(id, action: "rating", body: ["rating": n]) } } label: { Image(systemName: (store.project(id)?.stars ?? 0) >= n ? "star.fill" : "star").font(.system(size: 34, weight: .light)).foregroundStyle(Color(hex: 0xB39A58)).frame(width: 44, height: 48) }.accessibilityLabel("\(n) \(n == 1 ? "star" : "stars")").accessibilityAddTraits(store.project(id)?.stars == n ? [.isSelected] : [])
                }
            }
            if let p = store.project(id), p.stars > 0 {
                Text("Your rating: \(p.stars) out of 5").font(.caption).foregroundStyle(BranchStyle.secondary)
                Button("Remove rating") { Task { await store.mutate(id, action: "rating", body: ["rating": 0]) } }.font(.caption)
            } else { Text("Tap a star to leave your rating.").font(.caption).foregroundStyle(BranchStyle.secondary) }
            Text("Try the app before rating it.\nYou can change your rating any time.").font(.system(size: 11)).foregroundStyle(BranchStyle.secondary).multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
        }.frame(maxWidth: .infinity).padding(20).background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("Give a little love")
    }
}

struct BranchCreatorSheet: View {
    @EnvironmentObject var store: BranchStore
    let author: String
    var projects: [BranchProject] { store.projects.filter { $0.author == author && $0.published } }
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let p = projects.first {
                    BranchAvatar(project: p, size: 84).padding(.top, 25)
                    Text(author).font(.title2.weight(.semibold)).tracking(-0.5)
                    Text("Exploring \(p.category.lowercased()),\none useful project at a time.").font(.subheadline).foregroundStyle(BranchStyle.secondary).multilineTextAlignment(.center)
                    Text("\(p.seed ? "Example creator" : "Local creator") · \(projects.count) \(projects.count == 1 ? "project" : "projects")").font(.caption).foregroundStyle(BranchStyle.secondary)
                    if author != "You" {
                        Button { Task { await store.follow(author) } } label: { Text(store.following.contains(author) ? "Following" : "+ Follow creator").font(.subheadline.weight(.medium)).frame(width: 190, height: 45).background(BranchStyle.ink, in: Capsule()).foregroundStyle(.white) }.padding(.bottom, 14)
                    }
                    ForEach(projects) { p in BranchPostCard(project: p) }
                }
            }.padding(.horizontal, 18).padding(.bottom, 30)
        }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("Meet the maker")
    }
}

struct BranchInterestsSheet: View {
    @EnvironmentObject var store: BranchStore
    @State private var selected: Set<String> = []
    @State private var saving = false
    let symbols = ["bolt", "heart", "paintpalette", "creditcard", "curlybraces"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A feed that feels like you.").font(.system(size: 28, weight: .semibold)).tracking(-0.7)
                Text("What are you curious about? Pick a few interests. Change them whenever you like.").font(.subheadline).foregroundStyle(BranchStyle.secondary).lineSpacing(4)
                ForEach(Array(store.categories.enumerated()), id: \.element) { i, item in
                    Button { if selected.contains(item) { selected.remove(item) } else { selected.insert(item) } } label: {
                        HStack(spacing: 14) { Image(systemName: symbols[i]).frame(width: 24); Text(item).font(.subheadline); Spacer(); Image(systemName: selected.contains(item) ? "checkmark.circle.fill" : "circle").foregroundStyle(selected.contains(item) ? BranchStyle.green : BranchStyle.line) }
                            .padding(18).background(selected.contains(item) ? BranchStyle.pale : .white, in: RoundedRectangle(cornerRadius: 11)).overlay(RoundedRectangle(cornerRadius: 11).stroke(BranchStyle.line))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected.contains(item) ? [.isSelected] : [])
                }
                Text("For you puts your interests and followed creators first, with room for unexpected ideas.").font(.caption).foregroundStyle(BranchStyle.secondary).lineSpacing(4)
                Button { saving = true; Task { if await store.saveInterests(selected) { store.sheet = nil }; saving = false } } label: { HStack { Spacer(); if saving { ProgressView().tint(.white) } else { Text("Make it mine"); Image(systemName: "arrow.right") }; Spacer() }.font(.subheadline.weight(.medium)).frame(height: 49).background(BranchStyle.ink, in: RoundedRectangle(cornerRadius: 11)).foregroundStyle(.white) }.disabled(saving)
            }.padding(25)
        }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("Your interests").onAppear { selected = Set(store.interests) }
    }
}

struct BranchSettingsSheet: View {
    @EnvironmentObject var store: BranchStore
    @State private var address = ""
    @State private var checking = false
    var body: some View {
        Form {
            Section {
                HStack { Circle().fill(store.connected ? BranchStyle.green : .orange).frame(width: 8, height: 8); Text(store.connected ? "Connected to your Branch workspace" : "Browsing your offline library").font(.subheadline) }
            }
            Section {
                TextField("http://localhost:4173", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).accessibilityLabel("Server address")
                Button { checking = true; store.address = address.trimmingCharacters(in: .whitespacesAndNewlines); UserDefaults.standard.set(store.address, forKey: "branch-server"); Task { await store.refresh(showError: true); checking = false } } label: { HStack { Text("Connect and refresh"); Spacer(); if checking { ProgressView() } else { Image(systemName: "arrow.clockwise") } } }.disabled(checking)
            } header: { Text("Your server") } footer: { Text("In the iOS Simulator, start the web server on your Mac with npm start, then connect to localhost. A physical iPhone needs a reachable HTTPS backend; this local server is not publicly hosted.") }
            Section("Your data") { Text("Web and iOS share the same local profile on the connected server. Likes, comments, ratings, follows and remixes persist there. The offline library is read-only.").font(.subheadline).foregroundStyle(BranchStyle.secondary) }
            Section("A good place to start") { Text("Branch helps people discover working apps, share useful feedback, and build on each other’s ideas. Example creators are clearly labelled. There are no fabricated likes or comments.").font(.subheadline).foregroundStyle(BranchStyle.secondary) }
        }.scrollContentBackground(.hidden).background(BranchStyle.background).navigationTitle("Connection settings").onAppear { address = store.address }
    }
}

struct BranchDetailSheet: View {
    @EnvironmentObject var store: BranchStore
    let id: String
    @State private var html = ""
    @State private var showFork = false
    @State private var name = ""
    var body: some View {
        ScrollView {
            if let p = store.project(id) {
                VStack(alignment: .leading, spacing: 17) {
                    HStack { BranchAvatar(project: p); VStack(alignment: .leading, spacing: 4) { Text(p.name).font(.title2.weight(.semibold)).tracking(-0.5); Text("by \(p.author)").font(.caption).foregroundStyle(BranchStyle.secondary) }; Spacer() }
                    Text(p.description).font(.subheadline).foregroundStyle(BranchStyle.secondary).lineSpacing(4)
                    BranchReactions(project: p)
                    HStack { Image(systemName: "circle.fill").font(.system(size: 6)); Text("LIVE PREVIEW · SAMPLE DATA").font(.system(size: 9, weight: .medium)).tracking(1); Spacer(); Image(systemName: "hand.tap") }.foregroundStyle(BranchStyle.green)
                    if html.isEmpty { ProgressView().frame(maxWidth: .infinity, minHeight: 380) }
                    else { BranchWebPreview(html: html).frame(height: 480).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(BranchStyle.line)) }
                    Button { if p.seed { name = "\(p.name) remix"; showFork = true } else { store.sheet = .workspace(p.id) } } label: { HStack { Spacer(); Image(systemName: "arrow.triangle.branch"); Text(p.seed ? "Make it yours" : "Open in your studio"); Spacer() }.font(.subheadline.weight(.semibold)).frame(height: 49).background(BranchStyle.ink, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white) }.disabled(store.pending.contains("fork"))
                    Text("A working app, ready for your ideas. Your remix is an independent copy with attribution to the original.").font(.caption).foregroundStyle(BranchStyle.secondary).lineSpacing(4)
                }.padding(22)
            }
        }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("Try something good")
            .task { html = await store.html(id) }
            .alert("A fresh branch. All yours.", isPresented: $showFork) {
                TextField("Project name", text: $name)
                Button("Cancel", role: .cancel) {}
                Button("Create remix") { Task { if let p = store.project(id), let copy = await store.fork(p, name: name) { store.sheet = .workspace(copy.id) } } }
            } message: { Text("Give your version a name. The working app and sample data come with it.") }
    }
}

struct BranchWorkspaceSheet: View {
    @EnvironmentObject var store: BranchStore
    let id: String
    @State private var source = ""
    @State private var savedSource = ""
    @State private var tab = "Preview"
    @State private var working = false
    @State private var prompt = ""
    @State private var agent: BranchAgent?
    @State private var model = ""
    @State private var status = ""
    @State private var exportURL: URL?
    var body: some View {
        VStack(spacing: 13) {
            if let p = store.project(id) {
                VStack(alignment: .leading, spacing: 6) { Text(p.name).font(.title2.weight(.semibold)).tracking(-0.6); Text(p.published ? "Published to your local gallery" : "Your own independent remix").font(.caption).foregroundStyle(BranchStyle.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 12)
                Picker("Workspace view", selection: $tab) { Text("Preview").tag("Preview"); Text("Code").tag("Code"); Text("AI edit").tag("AI edit") }.pickerStyle(.segmented).padding(.horizontal, 20)
                if tab == "Preview" {
                    if savedSource.isEmpty { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
                    else { BranchWebPreview(html: savedSource).clipShape(RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 14) }
                } else if tab == "Code" {
                    TextEditor(text: $source).font(.system(size: 11, design: .monospaced)).autocorrectionDisabled().textInputAutocapitalization(.never).padding(10).background(.white, in: RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 14).disabled(working).accessibilityLabel("Project HTML source")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Label("Make it your own", systemImage: "sparkles").font(.headline)
                            Text("Describe what you want to change. Your local Ollama model edits the working app, with a previous version kept for review.").font(.subheadline).foregroundStyle(BranchStyle.secondary)
                            if let agent, agent.connected, !agent.models.isEmpty {
                                Picker("Local model", selection: $model) { ForEach(agent.models, id: \.self) { Text($0).tag($0) } }
                                TextField("What would you like to change?", text: $prompt, axis: .vertical).lineLimit(4...8).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 10)).accessibilityLabel("Describe a project change")
                                Button { Task { await buildChange() } } label: { Label(working ? "Building your change…" : "Build this change", systemImage: "sparkles").frame(maxWidth: .infinity, minHeight: 45).background(BranchStyle.ink, in: RoundedRectangle(cornerRadius: 9)).foregroundStyle(.white) }.disabled(working || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || source != savedSource)
                            } else {
                                Text("No local model connected. Start Ollama on your Mac and download a coding model, then reconnect.").font(.subheadline).foregroundStyle(BranchStyle.secondary)
                                Text("ollama pull qwen2.5-coder:7b").font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                                Button("Check connection") { Task { await loadAgent() } }.buttonStyle(.bordered)
                            }
                        }.padding(22)
                    }
                }
                if !status.isEmpty { Text(status).font(.caption).foregroundStyle(BranchStyle.secondary).padding(.horizontal, 20).accessibilityAddTraits(.updatesFrequently) }
                HStack {
                    Text(source == savedSource ? "Saved locally" : "Unsaved changes").font(.system(size: 10)).foregroundStyle(BranchStyle.secondary)
                    Spacer()
                    Button("Restore") { Task { await restore() } }.font(.caption).disabled(working || (p.revisionCount ?? 0) == 0 || source != savedSource)
                    Button("Save changes") { Task { await save() } }.font(.caption.weight(.medium)).buttonStyle(.borderedProminent).disabled(working || source == savedSource)
                }.padding(.horizontal, 20)
                HStack {
                    if let exportURL { ShareLink(item: exportURL) { Label("Export HTML", systemImage: "square.and.arrow.up").font(.caption) }.disabled(source != savedSource) }
                    Spacer()
                    Button { Task { await store.mutate(id, action: "publish"); if store.error == nil { status = "Published to the local gallery" } } } label: { Label("Publish locally", systemImage: "arrow.up.right").font(.caption) }.disabled(working || source != savedSource)
                }.padding(.horizontal, 20).padding(.bottom, 12)
            }
        }.background(BranchStyle.background).foregroundStyle(BranchStyle.ink).navigationTitle("Your studio")
            .interactiveDismissDisabled(source != savedSource || working)
            .onChange(of: source) { _, _ in store.workspaceHasUnsavedChanges = source != savedSource }
            .onChange(of: savedSource) { _, _ in store.workspaceHasUnsavedChanges = source != savedSource }
            .onChange(of: working) { _, value in store.workspaceBusy = value }
            .onDisappear { store.workspaceHasUnsavedChanges = false; store.workspaceBusy = false }
            .task { source = await store.html(id); savedSource = source; makeExport(); await loadAgent() }
    }
    func makeExport() { let url = FileManager.default.temporaryDirectory.appending(path: "branch-\(id).html"); do { try savedSource.write(to: url, atomically: true, encoding: .utf8); exportURL = url } catch { exportURL = nil } }
    func loadAgent() async { agent = try? await store.request("/agent"); model = agent?.models.first ?? "" }
    func save() async { working = true; defer { working = false }; do { try await store.saveSource(id, html: source); savedSource = source; status = "Changes saved. Try your preview."; makeExport() } catch { status = error.localizedDescription } }
    func restore() async { working = true; defer { working = false }; do { let p: BranchProject = try await store.request("/projects/\(id)/restore", method: "POST", body: [:]); store.replace(p); source = p.html ?? source; savedSource = source; makeExport(); status = "Previous version restored" } catch { status = error.localizedDescription } }
    func buildChange() async { working = true; defer { working = false }; do { let p: BranchProject = try await store.request("/projects/\(id)/agent", method: "POST", body: ["prompt": prompt, "model": model]); store.replace(p); source = p.html ?? source; savedSource = source; makeExport(); tab = "Preview"; status = "Your new version is ready to review." } catch { status = error.localizedDescription } }
}
#endif
