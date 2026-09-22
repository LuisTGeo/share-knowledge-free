#if os(iOS)
import SwiftUI
import WebKit

struct BranchProject: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var tagline: String
    var description: String
    var category: String
    var author: String
    var initials: String
    var color: String
    var tags: [String]
    var seed: Bool
    var published: Bool
    var parentId: String?
    var createdAt: String
    var html: String?
    var liked: Bool?
    var likes: Int?
    var rating: Int?
    var commentCount: Int?
    var saved: Bool?
    var following: Bool?
    var revisionCount: Int?
    var localForks: Int?
    var tint: Color { Color(hex: UInt32(color.replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0xE7EBDD) }
    var isLiked: Bool { liked ?? false }
    var isSaved: Bool { saved ?? false }
    var stars: Int { rating ?? 0 }
}
struct BranchComment: Identifiable, Codable {
    var id: String
    var projectId: String
    var author: String
    var text: String
    var createdAt: String
}
struct BranchActivity: Identifiable, Codable {
    var id: String
    var text: String
    var projectId: String
    var createdAt: String
}
struct BranchEnvelope: Codable {
    var projects: [BranchProject]
    var activity: [BranchActivity]
    var following: [String]
    var interests: [String]
}
struct BranchCommentsResponse: Decodable { var comments: [BranchComment] }
struct BranchCommentResponse: Decodable { var comment: BranchComment; var project: BranchProject }
struct BranchFollowingResponse: Decodable { var following: [String] }
struct BranchInterestsResponse: Decodable { var interests: [String] }
struct BranchAPIError: Decodable { var error: String }
struct BranchAgent: Decodable { var connected: Bool; var models: [String] }
enum BranchFeed: String, CaseIterable { case forYou = "For you", following = "Following", latest = "Latest" }
enum BranchSheet: Identifiable {
    case preview(String), comments(String), rating(String), creator(String), interests, settings, workspace(String)
    var id: String {
        switch self {
        case .preview(let id): return "preview-" + id
        case .comments(let id): return "comments-" + id
        case .rating(let id): return "rating-" + id
        case .creator(let id): return "creator-" + id
        case .workspace(let id): return "workspace-" + id
        case .interests: return "interests"
        case .settings: return "settings"
        }
    }
}

@MainActor final class BranchStore: ObservableObject {
    @Published var projects: [BranchProject] = []
    @Published var following: [String] = []
    @Published var interests: [String] = []
    @Published var activity: [BranchActivity] = []
    @Published var workspaceHasUnsavedChanges = false
    @Published var workspaceBusy = false
    @Published var connected = false
    @Published var loading = false
    @Published var error: String?
    @Published var message: String?
    @Published var sheet: BranchSheet?
    @Published var pending: Set<String> = []
    @Published var address = UserDefaults.standard.string(forKey: "branch-server") ?? "http://localhost:4173"
    let categories = ["Productivity", "Health & wellness", "Design & creative", "Finance", "Developer tools"]
    private var bundled: [BranchProject] = []
    private let cacheURL = URL.documentsDirectory.appending(path: "branch-library.json")
    private var toastTask: Task<Void, Never>?

    init() {
        if let url = Bundle.main.url(forResource: "BranchSeeds", withExtension: "json"), let data = try? Data(contentsOf: url) {
            bundled = (try? JSONDecoder().decode([BranchProject].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: cacheURL), let cached = try? JSONDecoder().decode(BranchEnvelope.self, from: data) {
            projects = cached.projects; following = cached.following; interests = cached.interests; activity = cached.activity
        } else { projects = bundled }
    }
    func project(_ id: String) -> BranchProject? { projects.first { $0.id == id } }
    var creators: [BranchProject] {
        var seen = Set<String>()
        return projects.filter { $0.seed && seen.insert($0.author).inserted }
    }
    func feed(_ mode: BranchFeed, search: String = "", category: String = "All") -> [BranchProject] {
        let filtered = projects.filter { p in
            p.published && (mode != .following || following.contains(p.author)) && (category == "All" || p.category == category) && (search.isEmpty || "\(p.name) \(p.description) \(p.author) \(p.category)".localizedCaseInsensitiveContains(search))
        }
        if mode == .latest { return filtered.sorted { $0.createdAt > $1.createdAt } }
        return filtered.enumerated().sorted { a,b in
            let left = (interests.contains(a.element.category) ? 10 : 0) + (following.contains(a.element.author) ? 5 : 0)
            let right = (interests.contains(b.element.category) ? 10 : 0) + (following.contains(b.element.author) ? 5 : 0)
            return left == right ? a.offset < b.offset : left > right
        }.map(\.element)
    }
    func request<T: Decodable>(_ route: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        guard let base = URL(string: address), ["http", "https"].contains(base.scheme), let host = base.host,
              base.scheme == "https" || ["localhost", "127.0.0.1"].contains(host),
              let url = URL(string: address.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/api" + route)
        else { throw NSError(domain: "Branch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Use localhost in the simulator or a trusted HTTPS server address."]) }
        var req = URLRequest(url: url); req.httpMethod = method; req.timeoutInterval = route.hasSuffix("/agent") ? 190 : 8
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            throw NSError(domain: "Branch", code: 2, userInfo: [NSLocalizedDescriptionKey: (try? JSONDecoder().decode(BranchAPIError.self, from: data).error) ?? "The server could not complete that action."])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func refresh(showError: Bool = false) async {
        guard !loading else { return }; loading = true; defer { loading = false }
        do {
            let value: BranchEnvelope = try await request("/projects")
            projects = value.projects; following = value.following; interests = value.interests; activity = value.activity; connected = true
            cache()
        } catch {
            connected = false
            if showError { self.error = "Couldn’t connect. Start Branch on your Mac with npm start. You can still browse the downloaded library." }
        }
    }
    private func cache() {
        let value = BranchEnvelope(projects: projects, activity: activity, following: following, interests: interests)
        if let data = try? JSONEncoder().encode(value) { try? data.write(to: cacheURL, options: .atomic) }
    }
    func replace(_ p: BranchProject) {
        if let i = projects.firstIndex(where: { $0.id == p.id }) { projects[i] = p } else { projects.append(p) }
        cache()
    }
    func notify(_ text: String) {
        toastTask?.cancel(); message = text
        toastTask = Task { try? await Task.sleep(for: .seconds(3)); if !Task.isCancelled { message = nil } }
    }
    func mutate(_ id: String, action: String, body: [String: Any] = [:]) async {
        let key = "\(id)-\(action)"; guard !pending.contains(key) else { return }
        guard connected else { error = "Connect to your Branch server in Settings to save reactions and changes."; return }
        pending.insert(key); defer { pending.remove(key) }
        do {
            let updated: BranchProject = try await request("/projects/\(id)/\(action)", method: "POST", body: body)
            replace(updated)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } catch { self.error = error.localizedDescription }
    }
    func toggleLike(_ p: BranchProject) async { await mutate(p.id, action: "like", body: ["liked": !p.isLiked]) }
    func toggleSave(_ p: BranchProject) async { await mutate(p.id, action: "save"); if error == nil { notify(project(p.id)?.isSaved == true ? "Saved to your collection" : "Removed from saved") } }
    func follow(_ author: String) async {
        guard !pending.contains(author), connected else { if !connected { error = "Connect to Branch in Settings to follow a creator." }; return }
        pending.insert(author); defer { pending.remove(author) }
        do {
            let result: BranchFollowingResponse = try await request("/follow", method: "POST", body: ["author": author, "following": !following.contains(author)])
            following = result.following
            for i in projects.indices { projects[i].following = following.contains(projects[i].author) }
            cache()
        } catch { self.error = error.localizedDescription }
    }
    func saveInterests(_ selected: Set<String>) async -> Bool {
        do {
            let result: BranchInterestsResponse = try await request("/preferences", method: "POST", body: ["interests": Array(selected)])
            interests = result.interests; cache(); notify("Your feed, with a little more you"); return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func comments(_ id: String) async throws -> [BranchComment] {
        let result: BranchCommentsResponse = try await request("/projects/\(id)/comments"); return result.comments
    }
    func comment(_ id: String, text: String) async throws {
        let result: BranchCommentResponse = try await request("/projects/\(id)/comments", method: "POST", body: ["text": text]); replace(result.project)
    }
    func html(_ id: String) async -> String {
        if connected, let p: BranchProject = try? await request("/projects/\(id)"), let html = p.html { return html }
        return project(id)?.html ?? bundled.first { $0.id == id }?.html ?? "<html><body><p>Connect to the server to load this project.</p></body></html>"
    }
    func thumbnailHTML(_ id: String) -> String? { bundled.first { $0.id == id }?.html }
    func fork(_ p: BranchProject, name: String) async -> BranchProject? {
        guard !pending.contains("fork") else { return nil }; pending.insert("fork"); defer { pending.remove("fork") }
        do {
            let copy: BranchProject = try await request("/projects/\(p.id)/fork", method: "POST", body: ["name": name]); replace(copy); notify("Your remix is ready"); return copy
        } catch { self.error = error.localizedDescription; return nil }
    }
    func saveSource(_ id: String, html: String) async throws {
        var result: BranchProject = try await request("/projects/\(id)", method: "PATCH", body: ["html": html]); result.html = html; replace(result); notify("Changes saved")
    }
}

enum BranchStyle {
    static let background = Color(hex: 0xF8F9F5)
    static let ink = Color(hex: 0x293525)
    static let secondary = Color(hex: 0x606E56)
    static let green = Color(hex: 0x647E49)
    static let pale = Color(hex: 0xE8EFDD)
    static let line = Color(hex: 0xE2E8D8)
    static let pink = Color(hex: 0xC66F73)
}

struct BranchWebPreview: UIViewRepresentable {
    let html: String
    var interactive = true
    var desktop = false
    final class Coordinator: NSObject, WKNavigationDelegate {
        var source = ""
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let scheme = navigationAction.request.url?.scheme
            decisionHandler(scheme == "about" || scheme == nil ? .allow : .cancel)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration(); config.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false; web.backgroundColor = .clear; web.scrollView.backgroundColor = .clear
        web.navigationDelegate = context.coordinator; web.isUserInteractionEnabled = interactive
        web.scrollView.isScrollEnabled = interactive
        return web
    }
    func updateUIView(_ web: WKWebView, context: Context) {
        guard context.coordinator.source != html else { return }; context.coordinator.source = html
        let policy = "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data:; connect-src 'none'; form-action 'none'; base-uri 'none'\">"
        var source = policy + html
        if desktop { source = source.replacingOccurrences(of: "width=device-width,initial-scale=1", with: "width=850") }
        web.loadHTMLString(source, baseURL: nil)
    }
}
#endif
