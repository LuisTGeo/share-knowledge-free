# Branch: discovery and community UX

## Sources reviewed

- TikTok, [How TikTok recommends videos #ForYou](https://newsroom.tiktok.com/how-tiktok-recommends-videos-for-you?lang=en): interests, likes, comments and follows inform relevance; discovery includes diverse content; duplicate content should not be used to pad a feed.
- Meta, [Two New Ways to Control Your Instagram Feed](https://about.fb.com/news/2022/03/two-new-ways-to-control-your-instagram-feed/): Following and Favorites give people intentional alternatives to a recommended feed.
- Meta, [Instagram Feed Ranking System Card](https://ai.meta.com/tools/system-cards/instagram-feed-ranking/): recommendations and explanations are part of the feed experience.

Instagram's main ranking blog returned HTTP 429 during research; the Meta sources above were used instead. These sources describe product mechanisms, not evidence that copying their interface will improve Branch retention.

## Product decisions

1. Open directly into useful content. A compact welcome replaces the large promotional hero on Home.
2. Show a project visually before requiring technical reading. Each post has a recognizable creator, an app preview, one-line purpose, tags and an obvious Try app button.
3. Keep familiar actions in consistent positions: like, comment, rate, save and remix. Likes and ratings have distinct accessible names and pressed states.
4. Use For you, Following and Latest feeds. Explain that For you ranks by explicitly chosen interests and followed creators; this edition uses deterministic ranking, not an ML recommendation system.
5. Keep comments next to the project in a sheet. Include quick prompts to help people write useful feedback. Escape user content and preserve failed drafts.
6. Make discovery continuous without manufacturing content: progressively reveal real projects, preserve scroll during reactions, and show a clear end-of-feed state.
7. Give people mobile bottom navigation, comfortable touch targets, reduced-motion support and labelled controls.
8. Make creator profiles and saved work useful destinations. Following changes the feed; it is not a decorative button.
9. Keep demo creators labelled. Social counts reflect actual local actions, not invented popularity.

## Validation boundaries

Automated tests and computer-use checks can establish that actions work, state persists, feeds filter correctly, the interface fits phone screens, and the native app launches. They cannot prove that people find the app engaging or that retention has improved.

For a real pilot, recruit 5–8 target users and ask them to find a relevant app, try it, like it, leave feedback, follow its creator, and create a remix. Observe completion rate, time to first useful project, comment quality, meaningful return visits and published remixes. Ask participants to explain why a recommendation appeared. Treat long sessions alone as an ambiguous signal.
