# Branch

A local working prototype of a project discovery and remix platform. Try a running app, fork it, make changes, and publish your version to the local gallery.

## Run

Requires Node.js 20 or newer. No dependencies or build step.

```sh
npm start
```

Open **http://localhost:4173**. To use another port: `PORT=4300 npm start`.

## What works

- Six runnable, self-contained starters: a meal planner, task board, portfolio, expense tracker, focus timer, and nutrition API playground.
- A visual Home feed with For you, Following, and Latest views; chosen interests influence recommendations.
- Persistent likes, comments, changeable 1–5 star ratings, creator follows, and saved projects.
- Creator profiles, continuous project discovery, scroll restoration, and phone bottom navigation.
- Search, category filters, sorting, and persistent saved projects.
- A native SwiftUI iOS app with the same feed, reactions, comments, profiles, live previews, remixes, and editing workspace.
- Independent project forks with attribution and a personal workspace.
- Source editing, live previews, HTML export, and restoration of up to 20 earlier edits.
- Import and locally publish your own HTML application, including inline CSS and JavaScript.
- Optional real AI editing through a local Ollama model. Failed requests and invalid output leave the project unchanged.
- Local improvement proposals that preserve a code snapshot, with original/proposed preview links in Activity.
- Responsive layouts, keyboard-accessible controls, modal focus handling, and reduced-motion support.

## iOS app

Open `Branch.xcodeproj`, select the **Branch** scheme and an iPhone simulator, then Run. The app appears as **Branch**. Start `npm start` on the Mac first; the simulator connects to `http://localhost:4173` automatically. Use **You → Connection settings** to change the server address.

Home, Explore, Studio, Saved, and You are native SwiftUI screens. Live project previews use isolated WKWebViews. You can like, comment, rate, follow, choose interests, fork, edit source, restore a previous edit, export HTML, publish locally, or request an Ollama edit. Web and iOS use the same local server profile. When disconnected, the cached catalog and bundled starter previews remain browsable; server changes require reconnecting.

A physical iPhone requires a reachable HTTPS backend and Apple signing configuration. Public backend hosting, authentication, TestFlight and App Store distribution are not configured in this local edition. Do not point the iPhone at its own localhost expecting to reach the Mac.

To refresh bundled starter content after editing the web templates:

```sh
node scripts/sync-ios-seeds.mjs
```

## AI editing

Run Ollama on this computer and install a coding-capable model, for example:

```sh
ollama pull qwen2.5-coder:7b
```

Choose **Connect an agent** in Branch. After it detects your installed model, fork a project and describe a change in its workspace. Review the live result and use **Restore previous** if needed.

Branch calls Ollama's `/api/tags` and `/api/chat` endpoints. The default agent URL is `http://127.0.0.1:11434`; override it using `BRANCH_AGENT_URL` when starting the server. The complete current source and your instructions are sent to that configured model endpoint. Branch does not install or download models automatically.

You can also export the HTML and use it in another coding agent, then paste the updated source into the editor or import it as a new project.

## Storage and scope

Projects, revisions, bookmarks, reactions, comments, follows, interests, activity, and proposal snapshots persist in `.branch/state.json`. This directory is gitignored. Back it up to preserve your work, or use **Export HTML** for individual projects. Tests use a separate temporary directory. `BRANCH_DATA_DIR` can point to another storage location.

This edition is deliberately **local and single-user**. The server binds to `127.0.0.1`. Publishing adds an app to this computer's gallery; it does not deploy to the public internet. Starter authors are illustrative example data. Visible reaction and remix counts reflect actual local actions. Both clients share one local profile; there are no public community accounts. Demo app interactions use in-memory sample data and reset when reloaded; project source changes persist.

Supported projects are single-file HTML apps. Preview documents are sandboxed and disallow network requests, external JavaScript, and external stylesheets. Full-stack repositories, databases, account authentication, public hosting, GitHub pull requests, arbitrary coding-agent integrations, and shared idle-compute scheduling are not implemented. Local proposals do not contact external authors or automatically merge changes.

Do not expose this local server as a public service without adding authentication, per-user authorization, quotas, durable database storage, and a dedicated preview origin.

## Verification

```sh
npm test
```

Integration tests cover likes, ratings, comments, follows, interests, social persistence, independent forks, preview isolation, editing, restoration, invalid HTML, AI output and failure handling with a mock model service, publishing, bookmarks, imports, exports, proposal snapshots, origin checks, size limits, and persistence across server restarts.

See [UX research](docs/UX-RESEARCH.md) and the [verification report](docs/verification/REPORT.md) for design rationale, screenshots, test evidence and remaining checks.

## Structure

- `server.mjs` — local HTTP API, file persistence, preview isolation, and model bridge.
- `web/index.html`, `web/app.js`, `web/community.js`, `web/styles.css` — the application.
- `web/lib/templates.mjs` — the six example projects.
- `tests/server.test.mjs` — server integration tests.

The iOS implementation is in `Branch/`.
