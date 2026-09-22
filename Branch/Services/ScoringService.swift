import Foundation

// MARK: - Judge protocol

protocol PromptJudge {
    func score(promptText: String, category: MetaCategory, subcategory: String) async throws -> PromptScore
}

enum ScoringError: LocalizedError {
    case missingAPIKey
    case badResponse(String)
    case refused(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "No Claude API key configured."
        case .badResponse(let detail): return "Scoring failed: \(detail)"
        case .refused(let detail): return "The judge declined this prompt: \(detail)"
        }
    }
}

// MARK: - Engine (picks Claude when a key exists, heuristic otherwise)

struct ScoringEngine {
    static func makeJudge() -> PromptJudge {
        if let key = ClaudeJudge.resolveAPIKey(), !key.isEmpty {
            return ClaudeJudge(apiKey: key)
        }
        return HeuristicJudge()
    }

    static var isLive: Bool {
        ClaudeJudge.resolveAPIKey()?.isEmpty == false
    }
}

// MARK: - Claude LLM-as-judge (raw Messages API over HTTPS)

struct ClaudeJudge: PromptJudge {
    let apiKey: String

    /// Key resolution: scheme environment variable first, then optional
    /// Secrets.plist bundled next to the app sources (gitignore it).
    static func resolveAPIKey() -> String? {
        if let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !env.isEmpty {
            return env
        }
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = plist["ANTHROPIC_API_KEY"] as? String {
            return key
        }
        return nil
    }

    private static let rubric = """
    You are the scoring judge for PromptStrava, an app where people submit the LLM prompts \
    they use in daily life. Score the submitted prompt on three axes, each 0-100:

    1. clarity — unambiguous instructions, well structured, minimal room for misinterpretation.
    2. functionality — would it reliably produce the intended output; does it specify the \
    output format, constraints, and handle edge cases for its stated purpose.
    3. efficiency — token economy: no redundancy or filler, gets to the result with minimal \
    back-and-forth needed.

    Calibration: 40 = a bare one-line ask, 60 = decent but underspecified, 75 = clearly \
    structured with format and constraints, 90+ = exceptional and rare. Be a tough but fair \
    grader; most everyday prompts land between 45 and 75.

    For each axis also write ONE punchy sentence of rationale (max 140 chars) that teaches \
    the author how to improve — this is shown in the app.
    """

    private static let outputSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "clarity": ["type": "integer"],
            "clarity_rationale": ["type": "string"],
            "functionality": ["type": "integer"],
            "functionality_rationale": ["type": "string"],
            "efficiency": ["type": "integer"],
            "efficiency_rationale": ["type": "string"],
        ],
        "required": [
            "clarity", "clarity_rationale",
            "functionality", "functionality_rationale",
            "efficiency", "efficiency_rationale",
        ],
        "additionalProperties": false,
    ]

    func score(promptText: String, category: MetaCategory, subcategory: String) async throws -> PromptScore {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": "claude-opus-4-8",
            "max_tokens": 16000,
            "system": Self.rubric,
            "output_config": ["format": ["type": "json_schema", "schema": Self.outputSchema]],
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Category: \(category.displayName) → \(subcategory)

                    Prompt to score:
                    <prompt>
                    \(promptText)
                    </prompt>
                    """,
                ]
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ScoringError.badResponse("no HTTP response")
        }
        guard http.statusCode == 200 else {
            let detail = String(data: data, encoding: .utf8) ?? "status \(http.statusCode)"
            throw ScoringError.badResponse(detail)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScoringError.badResponse("unparseable JSON")
        }

        // Safety classifiers can decline with HTTP 200 + stop_reason "refusal".
        if json["stop_reason"] as? String == "refusal" {
            let detail = ((json["stop_details"] as? [String: Any])?["explanation"] as? String) ?? "content declined"
            throw ScoringError.refused(detail)
        }

        guard let content = json["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String,
              let scoreData = text.data(using: .utf8),
              let fields = try JSONSerialization.jsonObject(with: scoreData) as? [String: Any]
        else {
            throw ScoringError.badResponse("missing text content")
        }

        func axis(_ key: String) throws -> AxisScore {
            guard let value = fields[key] as? Int,
                  let rationale = fields["\(key)_rationale"] as? String
            else { throw ScoringError.badResponse("missing field \(key)") }
            return AxisScore(value: min(100, max(0, value)), rationale: rationale)
        }

        return PromptScore(
            clarity: try axis("clarity"),
            functionality: try axis("functionality"),
            efficiency: try axis("efficiency")
        )
    }
}

// MARK: - Offline heuristic judge (deterministic, keeps the app fully usable with no key)

struct HeuristicJudge: PromptJudge {
    func score(promptText: String, category: MetaCategory, subcategory: String) async throws -> PromptScore {
        // Small pause so the reveal animation still feels like an evaluation.
        try? await Task.sleep(nanoseconds: 1_400_000_000)

        let text = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        let words = lower.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).map(String.init)
        let wordCount = words.count

        // --- Feature detection ---
        let hasRole = ["you are", "act as", "your role"].contains(where: lower.contains)
        let hasFormat = ["format", "bullet", "table", "json", "markdown", "numbered", "sections", "output"].contains(where: lower.contains)
        let hasConstraints = ["must", "only", "never", "always", "limit", "no more than", "at most", "avoid", "don't"].contains(where: lower.contains)
        let hasStructure = text.contains("\n") &&
            (text.contains("1.") || text.contains("- ") || text.contains("#") || text.contains(":") || text.contains("<"))
        let hasContextSlot = text.contains("[") || text.contains("{") || lower.contains("i will provide") || lower.contains("i'll paste")
        let hasExamples = ["for example", "e.g.", "example:", "such as"].contains(where: lower.contains)
        let hasAudience = ["for a", "aimed at", "audience", "my "].contains(where: lower.contains)
        let asksQuestionsFirst = ["ask me", "clarifying question", "before you start"].contains(where: lower.contains)
        let politeFiller = ["please", "kindly", "if you don't mind", "i was wondering"].filter(lower.contains).count
        let hedging = ["maybe", "perhaps", "kind of", "sort of", "somewhat", "i guess"].filter(lower.contains).count

        // Redundancy: unique-word ratio penalizes copy-pasted repetition.
        let uniqueRatio = wordCount == 0 ? 0 : Double(Set(words).count) / Double(wordCount)

        // --- Clarity ---
        var clarity = 42.0
        if hasRole { clarity += 10 }
        if hasStructure { clarity += 12 }
        if hasFormat { clarity += 10 }
        if hasAudience { clarity += 5 }
        clarity -= Double(hedging) * 5
        if wordCount < 8 { clarity -= 12 }
        if wordCount > 350 { clarity -= 8 }

        // --- Functionality ---
        var functionality = 40.0
        if hasFormat { functionality += 12 }
        if hasConstraints { functionality += 10 }
        if hasContextSlot { functionality += 8 }
        if hasExamples { functionality += 8 }
        if asksQuestionsFirst { functionality += 6 }
        if hasRole { functionality += 4 }
        if wordCount < 8 { functionality -= 14 }

        // --- Efficiency ---
        var efficiency = 55.0
        switch wordCount {
        case ..<8: efficiency += 6            // terse, but clarity/functionality already paid
        case 8..<60: efficiency += 18
        case 60..<150: efficiency += 10
        case 150..<300: efficiency -= 2
        default: efficiency -= 14
        }
        efficiency += (uniqueRatio - 0.6) * 40
        efficiency -= Double(politeFiller) * 4
        efficiency -= Double(hedging) * 3

        // Deterministic per-text jitter so equal-feature prompts don't tie.
        let jitter = Double((text.hashValue & 0x7FFF_FFFF) % 7) - 3

        func clamp(_ v: Double) -> Int { Int(min(98, max(15, v + jitter))) }

        let clarityRationale = hasStructure
            ? "Clear structure helps — tighten any ambiguous verbs to lock in interpretation."
            : "Add structure (numbered steps or sections) so the model can't misread intent."
        let functionalityRationale = hasFormat
            ? (hasConstraints ? "Format and constraints are specified — solid, repeatable output." : "Output format is set; add hard constraints to handle edge cases.")
            : "Specify the exact output format you want — that's the #1 reliability booster."
        let efficiencyRationale = wordCount > 300
            ? "Trim it down — long preambles burn tokens without changing the output."
            : (politeFiller > 1 ? "Cut the pleasantries; the model doesn't need them and they cost tokens." : "Good token economy — every line is pulling weight.")

        return PromptScore(
            clarity: AxisScore(value: clamp(clarity), rationale: clarityRationale),
            functionality: AxisScore(value: clamp(functionality), rationale: functionalityRationale),
            efficiency: AxisScore(value: clamp(efficiency), rationale: efficiencyRationale)
        )
    }
}

// MARK: - Category auto-detection ("AI-assisted" — keyword classifier for v1)

enum CategoryDetector {
    static func detect(_ text: String) -> (category: MetaCategory, subcategory: String, confidence: Double) {
        let lower = text.lowercased()

        let keywords: [(MetaCategory, [String])] = [
            (.work, ["resume", "cv", "interview", "email", "slack", "meeting", "standup", "code review", "pull request", "boss", "coworker", "presentation", "jira"]),
            (.health, ["workout", "diet", "meal plan", "calorie", "protein", "sleep", "gym", "run", "fitness", "stretch", "habit"]),
            (.finance, ["budget", "invest", "stock", "expense", "savings", "salary", "negotiat", "tax", "portfolio", "debt"]),
            (.social, ["dating", "tinder", "hinge", "gift", "conflict", "apolog", "toast", "wedding speech", "friend", "text back"]),
            (.learning, ["explain", "teach", "learn", "study", "flashcard", "language", "vocab", "summarize this book", "concept", "quiz me"]),
            (.creativity, ["story", "song", "lyric", "poem", "brand name", "logo", "midjourney", "image prompt", "character", "world"]),
            (.lifeAdmin, ["travel", "itinerary", "packing", "grocery", "moving", "appointment", "errand", "declutter", "schedule my"]),
        ]

        var best: (MetaCategory, Int) = (.work, 0)
        for (category, terms) in keywords {
            let hits = terms.filter(lower.contains).count
            if hits > best.1 { best = (category, hits) }
        }

        let category = best.1 > 0 ? best.0 : .work
        let confidence = best.1 == 0 ? 0.3 : min(0.95, 0.55 + Double(best.1) * 0.13)

        // Pick the subcategory whose name shares the most words with the prompt.
        let sub = category.subcategories.max { a, b in
            subScore(a, in: lower) < subScore(b, in: lower)
        } ?? category.subcategories[0]

        return (category, sub, confidence)
    }

    private static func subScore(_ name: String, in text: String) -> Int {
        name.lowercased()
            .split(separator: " ")
            .filter { $0.count > 3 && text.contains($0) }
            .count
    }
}
