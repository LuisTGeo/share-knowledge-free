# Branch UX verification

Verified on 18 September 2026 using Computer Use in the Codex browser, the Node integration suite, and an Xcode simulator build.

## Completed checks

| Check | Result |
| --- | --- |
| Desktop feed | Visually inspected rendered project previews, creator rail and reaction controls. |
| Phone layout | Visually inspected at 390 × 844; document width matched viewport, with no horizontal overflow. Bottom navigation and comment composer stayed visible. |
| Likes, stars and comments | Liked Nourish, rated it five stars, posted a test comment, and reloaded. All three persisted. |
| Following | Followed Sophie Chen; Following showed only her published project. |
| Personalization | Selecting Productivity moved Orbit and Still ahead of other categories. |
| Saves | Saved Orbit, opened Saved, then removed it; collection immediately showed its empty state. |
| Feed continuity | Navigation away and back restored scrollY 794.5 exactly. Progressive loading produced six distinct projects and a caught-up footer. |
| Keyboard | ArrowRight moved from For you to Following, including selected state and focus. |
| Remix regression | Created a named test fork from the mobile feed, changed its heading, saved, and verified the new heading in the live preview. |
| API integration suite | `npm test`: 13 tests passed, including the parent suite. Covers social validation/persistence and the earlier editing, preview isolation and project lifecycle. |
| iOS compilation | Debug simulator build succeeded for iPhone 17 Pro, iOS 26.5. |
| iOS launch and data | Installed and launched Branch. Its generated cache contained six projects and the same shared project data used by the browser. |
| Native iOS feed | Inspected the iPhone 17 Pro simulator visually and through accessibility: warm Branch header, creator strip, feed tabs, live preview card and five-item tab bar rendered correctly. The title is centered and no longer clipped. |
| Native iOS interactions | Opened the rating sheet, selected five stars and verified the selected state; opened comments, entered and posted a comment, and verified it rendered in the conversation; opened a live project preview and created a remix into Studio. |

The test-only remix and social actions were removed after verification. Screenshots show intermediate test state.

## Screenshots

These are actual browser captures, not design mockups. The phone image is the responsive web app, not the native iOS app.

![Desktop feed](desktop-feed.png)

![Phone web feed](mobile-feed.png)

![Native iOS comments](ios-comments.png)

## Remaining checks and scope

VoiceOver was not enabled for this pass, so a dedicated spoken-navigation audit remains future work. The native checks above used simulator accessibility labels and visual screenshots.

No live Ollama model was installed or downloaded for this verification; automated tests exercise model output and failures through a mock model server. Public accounts, multi-user moderation, public hosting, distributed compute and App Store delivery remain outside the implemented local prototype.

Functional verification does not establish improved retention or prove that the experience is engaging to real people. The pilot tasks and outcome measures in [UX research](../UX-RESEARCH.md) are the next validation step.
