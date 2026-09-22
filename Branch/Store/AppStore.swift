import SwiftUI

/// Everything the user creates or touches, saved between launches.
private struct PersistedState: Codable {
    var currentUser: UserProfile
    var myPrompts: [Prompt]
    var likedPromptIDs: Set<UUID>
    var usedPromptIDs: Set<UUID>
    var savedPromptIDs: Set<UUID>
    var selectedInterests: Set<MetaCategory>
    var submissionDays: Set<Date>
}

@MainActor
final class AppStore: ObservableObject {
    @Published var currentUser: UserProfile
    @Published var users: [UserProfile]
    @Published var prompts: [Prompt]
    @Published var likedPromptIDs: Set<UUID> = []
    @Published var usedPromptIDs: Set<UUID> = []
    @Published var savedPromptIDs: Set<UUID> = []
    @Published var selectedInterests: Set<MetaCategory> = []
    @Published var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "hasOnboarded") }
    }
    /// Days (as start-of-day dates) on which the current user submitted.
    @Published var submissionDays: Set<Date> = []
    /// Set to open the submit flow from anywhere (tab bar, challenge banner, empty states).
    @Published var pendingSubmit: SubmitSeed?

    let weeklyChallenge = (
        title: "Weekly Challenge",
        theme: "Best budgeting prompt",
        category: MetaCategory.finance,
        endsInDays: 3
    )

    init() {
        self.hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
        let seed = Self.seed()

        var me = seed.me
        var allPrompts = seed.prompts
        var days = seed.submissionDays

        if let loaded = Self.loadState() {
            me = loaded.currentUser
            days = loaded.submissionDays

            // My persisted prompts replace any seed copies of themselves, newest first.
            let mineIDs = Set(loaded.myPrompts.map(\.id))
            allPrompts = loaded.myPrompts + allPrompts.filter { !mineIDs.contains($0.id) }

            // Re-apply my engagement to the freshly seeded community prompts.
            for id in loaded.likedPromptIDs where !mineIDs.contains(id) {
                if let index = allPrompts.firstIndex(where: { $0.id == id }) { allPrompts[index].likes += 1 }
            }
            for id in loaded.usedPromptIDs where !mineIDs.contains(id) {
                if let index = allPrompts.firstIndex(where: { $0.id == id }) { allPrompts[index].usedCount += 1 }
            }
            for prompt in loaded.myPrompts {
                if let originalID = prompt.forkedFromID, !mineIDs.contains(originalID),
                   let index = allPrompts.firstIndex(where: { $0.id == originalID }) {
                    allPrompts[index].forkCount += 1
                }
            }

            self.likedPromptIDs = loaded.likedPromptIDs
            self.usedPromptIDs = loaded.usedPromptIDs
            self.savedPromptIDs = loaded.savedPromptIDs
            self.selectedInterests = loaded.selectedInterests
        }

        // Streaks must decay honestly: recompute from actual submission days.
        me.streakDays = Self.computeStreak(days: days)

        self.currentUser = me
        self.users = seed.users
        self.prompts = allPrompts
        self.submissionDays = days
    }

    // MARK: - Persistence

    private static var stateURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("promptstrava-state.json")
    }

    private static func loadState() -> PersistedState? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(PersistedState.self, from: data)
    }

    private func persist() {
        let state = PersistedState(
            currentUser: currentUser,
            myPrompts: myPrompts,
            likedPromptIDs: likedPromptIDs,
            usedPromptIDs: usedPromptIDs,
            savedPromptIDs: savedPromptIDs,
            selectedInterests: selectedInterests,
            submissionDays: submissionDays
        )
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: Self.stateURL, options: .atomic)
        }
    }

    /// Consecutive days with a submission, ending today or yesterday.
    private static func computeStreak(days: Set<Date>) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    // MARK: - Lookup

    func user(_ id: UUID) -> UserProfile {
        if id == currentUser.id { return currentUser }
        return users.first { $0.id == id } ?? currentUser
    }

    func prompt(_ id: UUID) -> Prompt? {
        prompts.first { $0.id == id }
    }

    var myPrompts: [Prompt] {
        prompts.filter { $0.authorID == currentUser.id }.sorted { $0.createdAt > $1.createdAt }
    }

    var savedPrompts: [Prompt] {
        prompts.filter { savedPromptIDs.contains($0.id) }.sorted { $0.createdAt > $1.createdAt }
    }

    var trending: [Prompt] {
        prompts.sorted { ($0.usedCount * 3 + $0.likes) > ($1.usedCount * 3 + $1.likes) }.prefix(6).map { $0 }
    }

    var feed: [Prompt] {
        prompts.sorted { $0.createdAt > $1.createdAt }
    }

    /// Feed narrowed to onboarding interests (my own prompts always included).
    var personalizedFeed: [Prompt] {
        guard !selectedInterests.isEmpty else { return feed }
        let filtered = feed.filter { selectedInterests.contains($0.category) || $0.authorID == currentUser.id }
        return filtered.isEmpty ? feed : filtered
    }

    func prompts(in category: MetaCategory, subcategory: String? = nil) -> [Prompt] {
        prompts
            .filter { $0.category == category && (subcategory == nil || $0.subcategory == subcategory) }
            .sorted { ($0.score?.composite ?? 0) > ($1.score?.composite ?? 0) }
    }

    func search(_ query: String) -> [Prompt] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return prompts
            .filter { prompt in
                prompt.title.lowercased().contains(q)
                    || prompt.text.lowercased().contains(q)
                    || prompt.subcategory.lowercased().contains(q)
                    || prompt.category.displayName.lowercased().contains(q)
                    || user(prompt.authorID).handle.lowercased().contains(q)
            }
            .sorted { ($0.score?.composite ?? 0) > ($1.score?.composite ?? 0) }
    }

    // MARK: - Actions

    func requestSubmit(_ seed: SubmitSeed = SubmitSeed()) {
        pendingSubmit = seed
    }

    func toggleLike(_ prompt: Prompt) {
        guard let index = prompts.firstIndex(of: prompt) else { return }
        if likedPromptIDs.contains(prompt.id) {
            likedPromptIDs.remove(prompt.id)
            prompts[index].likes -= 1
        } else {
            likedPromptIDs.insert(prompt.id)
            prompts[index].likes += 1
            Haptics.tap()
        }
        persist()
    }

    func markUsed(_ prompt: Prompt) {
        guard let index = prompts.firstIndex(of: prompt), !usedPromptIDs.contains(prompt.id) else { return }
        usedPromptIDs.insert(prompt.id)
        prompts[index].usedCount += 1
        Haptics.success()
        persist()
    }

    func toggleSave(_ prompt: Prompt) {
        if savedPromptIDs.contains(prompt.id) {
            savedPromptIDs.remove(prompt.id)
        } else {
            savedPromptIDs.insert(prompt.id)
            Haptics.tap()
        }
        persist()
    }

    func setInterests(_ interests: Set<MetaCategory>) {
        selectedInterests = interests
        persist()
    }

    /// Runs the judge, inserts the prompt, and applies XP / streak / badges.
    /// Returns everything the reveal screen needs to celebrate properly.
    func submit(title: String, text: String, category: MetaCategory, subcategory: String, forkedFrom: Prompt? = nil) async -> SubmitOutcome {
        let judge = ScoringEngine.makeJudge()
        let score: PromptScore
        do {
            score = try await judge.score(promptText: text, category: category, subcategory: subcategory)
        } catch {
            // Judge unavailable (network, refusal, etc.) — fall back so submission never dies.
            score = (try? await HeuristicJudge().score(promptText: text, category: category, subcategory: subcategory))
                ?? PromptScore(
                    clarity: AxisScore(value: 50, rationale: "Scored offline."),
                    functionality: AxisScore(value: 50, rationale: "Scored offline."),
                    efficiency: AxisScore(value: 50, rationale: "Scored offline.")
                )
        }

        let previousBest = myPrompts.compactMap { $0.score?.composite }.max()
        let levelBefore = currentUser.level
        let badgeNamesBefore = Set(currentUser.badges.map(\.name))

        var prompt = Prompt(
            title: title,
            text: text,
            authorID: currentUser.id,
            category: category,
            subcategory: subcategory,
            createdAt: .now,
            forkedFromID: forkedFrom?.id,
            score: score
        )
        prompt.compatibleModels = ["Claude", "ChatGPT", "Gemini"]
        prompts.insert(prompt, at: 0)

        if let original = forkedFrom, let index = prompts.firstIndex(where: { $0.id == original.id }) {
            prompts[index].forkCount += 1
        }

        applyProgress(for: score)
        persist()

        return SubmitOutcome(
            prompt: prompt,
            newBadges: currentUser.badges.filter { !badgeNamesBefore.contains($0.name) },
            didLevelUp: currentUser.level > levelBefore,
            isPersonalBest: score.composite > (previousBest ?? Int.min),
            weeklyRank: myRank(category: category, timeframe: .week)
        )
    }

    private func applyProgress(for score: PromptScore) {
        currentUser.xp += score.composite

        submissionDays.insert(Calendar.current.startOfDay(for: .now))
        currentUser.streakDays = Self.computeStreak(days: submissionDays)

        if score.composite >= 85, !currentUser.badges.contains(where: { $0.name == "Elite Prompt" }) {
            currentUser.badges.append(Badge(name: "Elite Prompt", icon: "crown.fill", colorHex: 0xFBBF24))
        }
        if myPrompts.count >= 5, !currentUser.badges.contains(where: { $0.name == "Prolific" }) {
            currentUser.badges.append(Badge(name: "Prolific", icon: "square.stack.3d.up.fill", colorHex: 0x8B5CF6))
        }
        if score.efficiency.value >= 90, !currentUser.badges.contains(where: { $0.name == "Token Miser" }) {
            currentUser.badges.append(Badge(name: "Token Miser", icon: "bolt.fill", colorHex: 0x38BDF8))
        }
        if currentUser.streakDays >= 7, !currentUser.badges.contains(where: { $0.name == "Week Warrior" }) {
            currentUser.badges.append(Badge(name: "Week Warrior", icon: "flame.fill", colorHex: 0xFC5200))
        }
    }

    // MARK: - Leaderboards

    func leaderboard(category: MetaCategory?, timeframe: Timeframe) -> [LeaderboardEntry] {
        let cutoff: Date? = {
            switch timeframe {
            case .week: return Calendar.current.date(byAdding: .day, value: -7, to: .now)
            case .month: return Calendar.current.date(byAdding: .month, value: -1, to: .now)
            case .allTime: return nil
            }
        }()

        let pool = prompts.filter { prompt in
            (category == nil || prompt.category == category)
                && (cutoff == nil || prompt.createdAt >= cutoff!)
        }

        var best: [UUID: (score: Int, count: Int)] = [:]
        for prompt in pool {
            guard let composite = prompt.score?.composite else { continue }
            let existing = best[prompt.authorID] ?? (0, 0)
            best[prompt.authorID] = (max(existing.score, composite), existing.count + 1)
        }

        let ranked = best
            .sorted { lhs, rhs in
                lhs.value.score != rhs.value.score ? lhs.value.score > rhs.value.score : lhs.value.count > rhs.value.count
            }
            .enumerated()
            .map { offset, element in
                LeaderboardEntry(
                    rank: offset + 1,
                    user: user(element.key),
                    bestScore: element.value.score,
                    promptCount: element.value.count,
                    // Deterministic pseudo-movement for v1 (no historical snapshots yet).
                    delta: ((element.key.hashValue & 0x7FFF_FFFF) % 5) - 2
                )
            }
        return ranked
    }

    func myRank(category: MetaCategory?, timeframe: Timeframe) -> Int? {
        leaderboard(category: category, timeframe: timeframe).first { $0.user.id == currentUser.id }?.rank
    }

    // MARK: - Stats

    var averageComposite: Int {
        let scores = myPrompts.compactMap { $0.score?.composite }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }

    /// Submissions per day for the last 7 days, oldest first.
    var weeklyActivity: [Int] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset in
            let day = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: .now)!)
            return myPrompts.filter { calendar.startOfDay(for: $0.createdAt) == day }.count
        }
    }

    // MARK: - Seed data

    /// Stable IDs so persisted likes/saves/forks still point at the right
    /// seed content after a relaunch (seed data is rebuilt every init).
    private static func seedID(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }

    private static func seed() -> (me: UserProfile, users: [UserProfile], prompts: [Prompt], submissionDays: Set<Date>) {
        var me = UserProfile(id: seedID(1), handle: "you", displayName: "You", avatarEmoji: "🔥", xp: 940, streakDays: 4)
        me.badges = [Badge(name: "Early Adopter", icon: "sparkles", colorHex: 0xFC5200)]

        let maya = UserProfile(id: seedID(2), handle: "mayaprompts", displayName: "Maya Chen", avatarEmoji: "🧠", xp: 4210, streakDays: 23)
        let dev = UserProfile(id: seedID(3), handle: "devrelDan", displayName: "Dan Okafor", avatarEmoji: "⚡️", xp: 3390, streakDays: 11)
        let june = UserProfile(id: seedID(4), handle: "junebug", displayName: "June Park", avatarEmoji: "🌱", xp: 2875, streakDays: 17)
        let rio = UserProfile(id: seedID(5), handle: "rio_runs", displayName: "Rio Alvarez", avatarEmoji: "🏃", xp: 2140, streakDays: 8)
        let sam = UserProfile(id: seedID(6), handle: "frugalsam", displayName: "Sam Whitfield", avatarEmoji: "💸", xp: 1980, streakDays: 5)
        let ada = UserProfile(id: seedID(7), handle: "adawrites", displayName: "Ada Lindqvist", avatarEmoji: "✍️", xp: 1720, streakDays: 14)
        let ken = UserProfile(id: seedID(8), handle: "kenzo", displayName: "Kenzo Tanaka", avatarEmoji: "🎯", xp: 1510, streakDays: 2)

        func score(_ c: Int, _ cr: String, _ f: Int, _ fr: String, _ e: Int, _ er: String) -> PromptScore {
            PromptScore(
                clarity: AxisScore(value: c, rationale: cr),
                functionality: AxisScore(value: f, rationale: fr),
                efficiency: AxisScore(value: e, rationale: er)
            )
        }

        func daysAgo(_ d: Int, hours: Int = 0) -> Date {
            Calendar.current.date(byAdding: .hour, value: -(d * 24 + hours), to: .now)!
        }

        var prompts: [Prompt] = [
            Prompt(
                id: seedID(101),
                title: "Bullet-proof resume tailoring",
                text: "You are an expert technical recruiter. I will paste a job description and my current resume.\n\n1. List the top 5 requirements from the JD.\n2. For each, rewrite one of my bullets to prove it, keeping metrics.\n3. Flag anything on my resume that hurts my case.\n\nFormat: markdown table with columns Requirement | Rewritten Bullet | Why it works. Keep bullets under 25 words.",
                authorID: maya.id, category: .work, subcategory: "Resume Builder",
                createdAt: daysAgo(1, hours: 3), likes: 214, usedCount: 891, forkCount: 37, commentCount: 24,
                score: score(88, "Numbered steps and a strict table format leave almost zero ambiguity.",
                             91, "Requirement-to-bullet mapping with metrics guarantees usable output.",
                             84, "Tight — only the 25-word cap phrasing could be leaner.")
            ),
            Prompt(
                id: seedID(102),
                title: "The 3-question budget autopsy",
                text: "Act as a blunt financial coach. Here are my last 30 days of transactions: [paste CSV].\n\nAnswer exactly three questions:\n1. What single category should I cut first, and by how much?\n2. What recurring charge am I probably forgetting about?\n3. If I keep this up, what does my year look like in one sentence?\n\nNo generic advice. Use my numbers.",
                authorID: sam.id, category: .finance, subcategory: "Budgeter",
                createdAt: daysAgo(0, hours: 6), likes: 187, usedCount: 640, forkCount: 22, commentCount: 18,
                score: score(90, "Exactly three questions, exact input slot — nothing left to guess.",
                             86, "'Use my numbers' plus the CSV slot forces grounded answers.",
                             92, "Ruthless token economy; every line changes the output.")
            ),
            Prompt(
                id: seedID(103),
                title: "Meeting → decisions extractor",
                text: "Summarize this meeting transcript. Output three sections: DECISIONS (what was agreed, who owns it, by when), OPEN QUESTIONS, and RISKS. Max 5 bullets per section. If a decision has no owner, write ⚠️ NO OWNER. Transcript: [paste]",
                authorID: dev.id, category: .work, subcategory: "Meeting Summarizer",
                createdAt: daysAgo(2), likes: 156, usedCount: 720, forkCount: 41, commentCount: 12,
                score: score(85, "Fixed sections and bullet caps make the output shape predictable.",
                             88, "The NO OWNER flag is a smart edge-case handler most people miss.",
                             90, "One paragraph, zero filler. Strava-grade efficiency.")
            ),
            Prompt(
                id: seedID(104),
                title: "Hypertrophy coach with progression",
                text: "You are a strength coach. Build me a 4-day upper/lower split.\n\nContext: [experience level], [available equipment], [injuries].\nRules: sessions under 60 min, progressive overload plan for 8 weeks, include RPE targets.\nOutput: week-by-week table, then a one-paragraph deload explanation.",
                authorID: rio.id, category: .health, subcategory: "Workout Coach",
                createdAt: daysAgo(1, hours: 9), likes: 132, usedCount: 445, forkCount: 19, commentCount: 9,
                score: score(82, "Context slots are clear; 'upper/lower split' assumes some jargon knowledge.",
                             87, "Rules + RPE + deload handling covers the edge cases that break generic plans.",
                             80, "Could merge the context lines, but nothing is wasted.")
            ),
            Prompt(
                id: seedID(105),
                title: "Explain like I'm smart but new",
                text: "Explain [concept] to someone who is intelligent but has zero background in this field. Use one everyday analogy, then the precise technical definition, then the single most common misconception. End with a one-line test I can use to check if I actually got it.",
                authorID: june.id, category: .learning, subcategory: "Concept Explainer",
                createdAt: daysAgo(3), likes: 241, usedCount: 1102, forkCount: 63, commentCount: 31,
                score: score(89, "The analogy→definition→misconception arc is unambiguous and ordered.",
                             85, "Self-test ending makes the output verifiable — rare and valuable.",
                             93, "Four sentences, endlessly reusable. Peak efficiency.")
            ),
            Prompt(
                id: seedID(106),
                title: "Dating profile, but actually me",
                text: "I'll give you 5 boring facts about me and 2 stories my friends always tell about me. Turn them into a dating profile that sounds like a human wrote it: no clichés (ban 'love to laugh', 'partner in crime', 'fluent in sarcasm'), max 90 words, first person, ends with a question that's easy to reply to.\n\nFacts: [paste]",
                authorID: ada.id, category: .social, subcategory: "Dating Profile Writer",
                createdAt: daysAgo(2, hours: 14), likes: 178, usedCount: 530, forkCount: 28, commentCount: 22,
                score: score(84, "The banned-cliché list is doing serious disambiguation work.",
                             83, "Word cap + reply-hook ending shapes genuinely usable output.",
                             86, "Lean for how much steering it packs in.")
            ),
            Prompt(
                id: seedID(107),
                title: "Trip planner that respects my energy",
                text: "Plan a [N]-day trip to [city]. Constraints: one 'anchor' activity per day max, nothing before 9am, every day includes one no-plan block of 3+ hours, walking distances under 30 min between stops. Output as a day-by-day list with a backup rainy-day option per day.",
                authorID: june.id, category: .lifeAdmin, subcategory: "Travel Planner",
                createdAt: daysAgo(4), likes: 121, usedCount: 388, forkCount: 15, commentCount: 7,
                score: score(86, "Concrete constraints (9am, 30 min, 3+ hrs) eliminate vague outputs.",
                             84, "Rainy-day fallback per day handles the classic trip-plan failure mode.",
                             85, "Dense constraint packing — nothing to trim.")
            ),
            Prompt(
                id: seedID(108),
                title: "Naming machine (with taste)",
                text: "Generate 20 names for [thing]. Process: first list 5 relevant metaphors, then derive 4 names from each. Rules: pronounceable on first read, no puns, .com-plausible, nothing that sounds like a pharmaceutical. Then pick your top 3 and defend each in one sentence.",
                authorID: ken.id, category: .creativity, subcategory: "Naming & Branding",
                createdAt: daysAgo(5), likes: 98, usedCount: 305, forkCount: 12, commentCount: 8,
                score: score(83, "Metaphor-first process is clever and clearly sequenced.",
                             81, "Selection + defense step turns a list into a decision.",
                             82, "The pharma joke earns its tokens by banning a real failure mode.")
            ),
            Prompt(
                id: seedID(109),
                title: "Slack message de-escalator",
                text: "Rewrite this Slack message so it keeps the substance but reads as calm and collaborative. Keep it under 4 sentences. Do not add exclamation marks or corporate praise. Message: [paste]",
                authorID: dev.id, category: .work, subcategory: "Email & Slack Drafting",
                createdAt: daysAgo(0, hours: 11), likes: 143, usedCount: 812, forkCount: 9, commentCount: 5,
                score: score(87, "Single transformation, hard length cap — impossible to misread.",
                             80, "Covers tone traps (exclamation, praise) but not threading context.",
                             94, "Two sentences of instruction for a daily-use tool. Elite.")
            ),
            Prompt(
                id: seedID(110),
                title: "Sleep debt negotiator",
                text: "You are a sleep scientist who hates wellness fluff. My situation: [sleep schedule, wake time, caffeine habits]. Give me the three highest-leverage changes ranked by effect size, each with the specific study-backed mechanism in one sentence. Then a realistic 2-week adoption plan. No melatonin unless the evidence is strong for my case.",
                authorID: rio.id, category: .health, subcategory: "Sleep Optimizer",
                createdAt: daysAgo(6), likes: 89, usedCount: 260, forkCount: 7, commentCount: 6,
                score: score(81, "Persona plus ranked-output request is clear; input slot is broad.",
                             82, "Effect-size ranking and the melatonin guard show real edge-case thinking.",
                             79, "A touch of persona flourish, but it steers tone effectively.")
            ),
            Prompt(
                id: seedID(111),
                title: "Investment thesis stress-tester",
                text: "I believe [investment thesis]. Argue the bear case as a skeptical analyst: 3 strongest counterarguments with the data you'd want to verify each. Then tell me what evidence would change your mind. Do not soften conclusions.",
                authorID: sam.id, category: .finance, subcategory: "Investment Research",
                createdAt: daysAgo(3, hours: 8), likes: 167, usedCount: 490, forkCount: 25, commentCount: 19,
                score: score(85, "Role, count, and no-softening rule set expectations precisely.",
                             84, "Falsifiability ask ('what would change your mind') is the killer feature.",
                             88, "Compact for a research-grade prompt.")
            ),
            Prompt(
                id: seedID(112),
                title: "Flashcards that fight back",
                text: "Turn these notes into 15 Anki-style flashcards. Mix: 8 recall, 4 application ('what would happen if…'), 3 reversed. Front under 20 words. Output as CSV: front,back. Notes: [paste]",
                authorID: june.id, category: .learning, subcategory: "Flashcard Generator",
                createdAt: daysAgo(1, hours: 20), likes: 110, usedCount: 601, forkCount: 33, commentCount: 10,
                score: score(88, "Exact mix, exact format, exact caps. Machine-readable spec.",
                             87, "Card-type mix targets real learning, not just recall.",
                             91, "CSV output kills all formatting waste.")
            ),
            Prompt(
                id: seedID(113),
                title: "Gift ideas from tiny clues",
                text: "Suggest gifts for someone based only on these clues: [3 things they mentioned recently]. Budget [X]. Give 5 ideas: each with why it maps to a clue, where to buy, and a risk ('might already own one'). No candles, no mugs, no gift cards.",
                authorID: ada.id, category: .social, subcategory: "Gift Ideas",
                createdAt: daysAgo(7), likes: 76, usedCount: 214, forkCount: 5, commentCount: 4,
                score: score(80, "Clue-mapping requirement is clear; 'recently' does light lifting.",
                             79, "Risk field and the banned-defaults list prevent lazy outputs.",
                             83, "Trim the parenthetical example and it's near-perfect.")
            ),
            Prompt(
                id: seedID(114),
                title: "Code review, severity-sorted",
                text: "Review this diff. Report every issue you find, sorted by severity (correctness > security > performance > style). For each: file:line, one-sentence issue, one-sentence fix. If you're uncertain, say so and report it anyway. End with the single change you'd block the merge on. Diff: [paste]",
                authorID: maya.id, category: .work, subcategory: "Code Review",
                createdAt: daysAgo(0, hours: 20), likes: 198, usedCount: 705, forkCount: 46, commentCount: 27,
                score: score(90, "Severity order and per-issue format are fully specified.",
                             92, "'Report even if uncertain' prevents the silent-filtering failure mode.",
                             87, "Dense, surgical, reusable on any diff.")
            ),
            Prompt(
                id: seedID(115),
                title: "Meal prep for people who won't",
                text: "Make me a 5-day lunch prep plan: one 90-minute Sunday cook session, max 8 ingredients total, no recipe repeated from last week ([paste last week]), every meal survives 4 days in a fridge. Output: shopping list grouped by store aisle, then the cook-order timeline.",
                authorID: rio.id, category: .lifeAdmin, subcategory: "Meal Prep",
                createdAt: daysAgo(2, hours: 5), likes: 104, usedCount: 350, forkCount: 11, commentCount: 8,
                score: score(84, "Hard numeric constraints do the disambiguation.",
                             85, "Fridge-survival and repeat-avoidance handle real-world failure modes.",
                             86, "Aisle-grouped list shows output-shape thinking.")
            ),
            Prompt(
                id: seedID(116),
                title: "Song sketch from a feeling",
                text: "I'll describe a feeling and a memory. Write: a title, a 4-line chorus with a singable melody note (syllable stress marked), and two verse directions I could take. Genre: [genre]. Avoid rhyming 'fire/desire' and 'heart/apart'. Feeling: [paste]",
                authorID: ken.id, category: .creativity, subcategory: "Songwriting Partner",
                createdAt: daysAgo(4, hours: 12), likes: 67, usedCount: 150, forkCount: 6, commentCount: 5,
                score: score(78, "Output pieces are enumerated; 'melody note' is slightly fuzzy.",
                             76, "Banned rhymes are a nice touch; syllable marking may vary run to run.",
                             81, "Compact given the creative surface area.")
            ),
        ]

        // One of my own submissions so the profile isn't empty.
        prompts.append(
            Prompt(
                id: seedID(117),
                title: "Interview story polisher",
                text: "Take this rough story from my work history and shape it into a STAR answer under 90 seconds spoken. Keep my voice, cut filler, end on measurable impact. Story: [paste]",
                authorID: me.id, category: .work, subcategory: "Interview Prep",
                createdAt: daysAgo(1, hours: 2), likes: 12, usedCount: 31, forkCount: 1, commentCount: 2,
                score: score(82, "STAR + time cap is a crisp, testable spec.",
                             78, "Good constraints; could specify what counts as 'impact'.",
                             88, "Two sentences, zero waste.")
            )
        )

        // Fork lineage example: June forked Maya's resume prompt.
        var forked = Prompt(
            id: seedID(118),
            title: "Resume tailoring — PM edition",
            text: "You are a product management recruiter. I will paste a JD and my resume.\n\n1. Extract the 5 outcomes this role is hired to deliver.\n2. Rewrite my bullets to prove I've delivered similar outcomes, keeping metrics.\n3. Kill any bullet that describes activity instead of outcome.\n\nFormat: markdown table Requirement | Rewritten Bullet | Evidence strength (1-5).",
            authorID: june.id, category: .work, subcategory: "Resume Builder",
            createdAt: daysAgo(0, hours: 15), likes: 54, usedCount: 130, forkCount: 3, commentCount: 6,
            forkedFromID: prompts[0].id,
            score: score(87, "Outcome-vs-activity distinction sharpens the original.",
                         89, "Evidence-strength column adds a self-audit the original lacked.",
                         83, "Slightly longer than the original for similar output.")
        )
        forked.compatibleModels = ["Claude", "ChatGPT"]
        prompts.append(forked)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let submissionDays: Set<Date> = Set((1...4).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        })

        return (me, [maya, dev, june, rio, sam, ada, ken], prompts, submissionDays)
    }
}
