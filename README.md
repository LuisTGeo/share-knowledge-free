# PromptStrava 🔥

Strava for prompting: log the LLM prompts you use in daily life, get them scored by an AI judge on **Clarity / Functionality / Efficiency**, and see how you rank.

## Run it

**iOS app**
1. Open `PromptStrava.xcodeproj` in **Xcode 16 or newer**.
2. Pick an iOS 17+ simulator and hit **Run**.

No dependencies, no packages — pure SwiftUI.

**Web companion**

`web/index.html` is the full app as a single self-contained page — same palette, same core loop (onboarding → submit → animated score reveal → leaderboards), same on-device judge ported to JS, persisted in `localStorage`. Open it directly in a browser or host it anywhere; on phones it renders as the app, on desktop it gains a nav rail. No build step, no dependencies.

## The v1 core loop

**Submit → Score → Rank**, wrapped in a Strava-confident dark UI:

- **Onboarding** — swipeable 3-page intro with a live scoring-ring demo and interest picker.
- **Home feed** — tappable weekly challenge banner (deep-links into a pre-categorized submission), trending prompts (ranked by real usage), and a **"For you" feed filter** powered by the onboarding interests.
- **Submit flow** — write/paste a prompt → AI-assisted category detection → confirm → **animated score reveal** (staggered rings, count-up numbers, haptics) with the full payoff: XP + streak, **personal best / level-up / badge-unlock celebrations**, your weekly category rank, and a share button.
- **Prompt detail** — full text with copy, score rings + per-axis rationale (the teaching moment), like / "I used this" / fork / save. Forks track lineage back to the original author. Cards also support long-press quick actions (copy / like / save).
- **Leaderboards** — global + per-category, week/month/all-time, your rank pinned at the bottom.
- **Profile** — level ring, avg score, streak flame, weekly activity bars, badges, and a **Mine / Saved** prompt library.
- **Explore** — category grid → subcategory drill-down, plus **search** across titles, prompt text, categories, and authors.
- **Persistence** — your prompts, XP, streak, badges, likes, saves, and interests survive relaunch (JSON in Documents; seed content uses stable IDs so references stay valid). Streaks are recomputed honestly from actual submission days on every launch.

## Scoring judge

Two judges, picked automatically at submit time:

| Judge | When | How |
|---|---|---|
| **Claude (LLM-as-judge)** | An Anthropic API key is configured | Raw HTTPS call to `POST /v1/messages` (`claude-opus-4-8`) with a fixed rubric and a JSON-schema-constrained output — three 0–100 scores plus a one-line teaching rationale per axis. Handles `stop_reason: "refusal"`. |
| **On-device heuristic** | No key / offline / API error | Deterministic feature analysis (structure, format spec, constraints, token economy, redundancy) so the app is fully usable with zero setup. |

The Submit screen shows which judge is active (`Judge: Claude` / `Judge: on-device`).

### Configuring the Claude judge (optional)

Either:

- **Scheme env var** — Edit Scheme → Run → Environment Variables → add `ANTHROPIC_API_KEY`, or
- **Secrets.plist** — add a `Secrets.plist` file inside the `PromptStrava/` source folder with a string entry `ANTHROPIC_API_KEY`. Don't commit it.

## Architecture notes

- `AppStore` (`@MainActor ObservableObject`) holds all state with realistic seed data and persists everything the user creates or touches to `Documents/promptstrava-state.json`.
- `SubmitSeed` / `pendingSubmit` let any surface (tab bar, challenge banner, empty states) open the submit flow with a prefilled starting point; `SubmitOutcome` carries the celebration data (new badges, level-up, personal best, weekly rank) to the reveal screen.
- `ScoringService.swift` — judge protocol + Claude client + heuristic fallback + keyword-based category detector.
- Everything compiles for macOS too (via tiny shims in `Support/Platform.swift`) so the whole app can be typechecked headlessly in CI: `swiftc -typecheck -parse-as-library -swift-version 5 $(find PromptStrava -name '*.swift')`.

## Deferred to v2 (by design)

Comments, follows/friends-only boards, community output-testing, real rank-delta history, server backend, push/streak reminders.
