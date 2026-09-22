import { createCommunity } from "./community.js";
const paths = {
  heart: "M20 4c-3-2-6 0-8 3-2-3-5-5-8-3-5 4 3 12 8 16 5-4 13-12 8-16Z",
  comment: "M21 11a9 9 0 0 1-9 9H3l2-5a9 9 0 1 1 16-4Z",
  share: "m3 10 18-7-7 18-3-8-8-3Zm8 3L21 3",
  send: "m3 10 18-7-7 18-3-8-8-3Zm8 3L21 3",
  people:
    "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm9-8a4 4 0 0 1 0 8m0 4a4 4 0 0 1 4 4v2",
  sliders: "M4 7h7m4 0h5M4 17h3m4 0h9M11 4v6M7 14v6",
  home: "m3 10 9-7 9 7v11h-6v-7H9v7H3V10Z",
  branch: "M7 3v12a4 4 0 0 0 4 4h6M7 9h5a5 5 0 0 0 5-5M4 3h6M14 4h6M17 16v6",
  compass: "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM16 8l-3 5-5 3 3-5 5-3Z",
  grid: "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
  bookmark: "M6 3h12v18l-6-4-6 4V3Z",
  activity: "M3 12h4l3-8 4 16 3-8h4",
  code: "m8 7-5 5 5 5m8-10 5 5-5 5m-3-14-2 18",
  search: "M20 20l-5-5M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0Z",
  plus: "M12 5v14M5 12h14",
  arrow: "M5 12h14m-5-5 5 5-5 5",
  external: "M14 3h7v7m0-7-11 11M10 3H3v18h18v-7",
  leaf: "M20 3C8 2 2 7 4 15c2 7 15 7 16-12ZM4 20 16 8",
  star: "m12 3 3 6 6 1-4.5 4.5L18 21l-6-3-6 3 1.5-6.5L3 10l6-1 3-6Z",
  fork: "M6 3v10a5 5 0 0 0 5 5h1m6-15v5a5 5 0 0 1-5 5h-2m1 5v3M3 3h6m6 0h6",
  play: "m8 4 12 8-12 8V4Z",
  chevron: "m9 5 7 7-7 7",
  check: "m5 12 4 4L19 6",
  close: "m6 6 12 12M6 18 18 6",
  back: "M19 12H5m5-5-5 5 5 5",
  spark: "m12 2 2.5 7.5L22 12l-7.5 2.5L12 22l-2.5-7.5L2 12l7.5-2.5L12 2Z",
  health: "M20 4c-3-2-6 0-8 3-2-3-5-5-8-3-5 4 3 12 8 16 5-4 13-12 8-16Z",
  palette:
    "M12 3a9 9 0 1 0 0 18h1a2 2 0 0 0 1-4c-1-1 0-3 2-3h2c5 0 4-11-6-11ZM7 8h.01M12 6h.01M17 8h.01M6 13h.01",
  wallet: "M3 5h17v15H3V5Zm0 0 14-3v3m-3 7h7v5h-7v-5Z",
  bolt: "m13 2-9 12h7l-1 8 10-13h-7l1-7Z",
  clock: "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM12 7v5l3 2",
  download: "M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5",
  upload: "M12 16V3m-5 5 5-5 5 5M4 16v5h16v-5",
  refresh:
    "M20 7v5h-5M4 17v-5h5M5 7a8 8 0 0 1 14-1l1 6M4 12l1 6a8 8 0 0 0 14-1",
  menu: "M4 6h16M4 12h16M4 18h16",
  info: "M12 11v6m0-10v.01M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
};
const icon = (name) =>
  `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${paths[name] || paths.grid}"/></svg>`;
const esc = (s) =>
  String(s ?? "").replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
const app = document.getElementById("app"),
  overlay = document.getElementById("overlay");
let projects = [],
  activity = [],
  contributions = [],
  category = "All projects",
  sort = "popular",
  query = "",
  current = null,
  tab = "preview",
  draft = "",
  dirty = false,
  agent = { connected: false, models: [] },
  busy = false,
  renderId = 0,
  modalOrigin = null;
let screen = "home";
let activeHash = location.hash || "#home";
const scrollPositions = new Map();
const categories = [
  "All projects",
  "Productivity",
  "Health & wellness",
  "Design & creative",
  "Finance",
  "Developer tools",
];
const categoryIcons = ["grid", "bolt", "health", "palette", "wallet", "code"];
async function api(route, options = {}) {
  const res = await fetch("/api" + route, {
    ...options,
    headers: { "Content-Type": "application/json", ...options.headers },
  });
  const result = await res.json();
  if (!res.ok) throw Error(result.error || "Could not complete the request.");
  return result;
}
const post = (route, data = {}) =>
  api(route, { method: "POST", body: JSON.stringify(data) });
function toast(message) {
  const el = document.getElementById("toast");
  el.textContent = message;
  el.classList.add("visible");
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => el.classList.remove("visible"), 4300);
}
async function reload() {
  let data = await api("/projects");
  projects = data.projects;
  activity = data.activity;
  contributions = data.contributions;
  community.setData(data);
}
const button = (label, action, style = "", ic = "", extra = "") =>
  `<button class="btn ${style}" data-action="${action}" ${extra}>${ic ? icon(ic) : ""}${label}</button>`;
function sidebar() {
  return `<aside class="sidebar" id="sidebar"><a class="logo" href="#home">${icon("branch")}branch<small>BETA</small></a><div class="nav-label">YOUR NEXT GOOD IDEA</div>${[
    ["home", "home", "Home"],
    ["explore", "compass", "Explore"],
    ["workspace", "grid", "My workspace"],
    ["saved", "bookmark", "Saved projects"],
  ]
    .map(
      ([id, ic, label]) =>
        `<a href="#${id}" class="nav-button ${screen === id ? "active" : ""}">${icon(ic)}${label}${id === "workspace" && projects.filter((p) => !p.seed).length ? `<span class="count">${projects.filter((p) => !p.seed).length}</span>` : ""}</a>`,
    )
    .join(
      "",
    )}<div class="nav-label">BUILD TOGETHER</div><a href="#activity" class="nav-button ${screen === "activity" ? "active" : ""}">${icon("activity")}Activity</a><button class="nav-button" data-action="connect">${icon("code")}Connect an agent</button><div class="sidebar-bottom"><div class="sidebar-note">${icon("leaf")}<strong>Great things grow together.</strong><p>Start with something good.<br>Make it a little more you.</p><button data-action="about">The idea behind Branch ${icon("arrow")}</button></div><button class="profile" data-action="profile" style="width:100%;text-align:left"><span class="avatar">YO</span><span><b>Your creative space</b><small>Local workspace</small></span>${icon("chevron")}</button></div></aside>`;
}
function shell(content) {
  app.innerHTML = `${sidebar()}<div class="shell"><header class="topbar"><a href="#home" class="mobile-brand" style="display:none" aria-label="Branch home">${icon("branch")}</a><button class="mobile-menu" data-action="menu" aria-label="Toggle navigation">${icon("menu")}</button><label class="searchbox">${icon("search")}<input id="search" type="search" placeholder="Find a starting point for your next idea…" aria-label="Search projects" value="${esc(query)}"><kbd class="shortcut">⌘ K</kbd></label><div class="top-actions"><span class="local-status"><i class="dot"></i> Your local playground</span><button class="btn dark" data-action="publish-new" aria-label="Publish a project">${icon("plus")}<span>Publish a project</span></button></div></header><main class="content" id="main">${content}</main></div><nav class="mobile-bottom" aria-label="Main navigation">${[
    ["home", "home", "Home"],
    ["explore", "compass", "Explore"],
    ["workspace", "plus", "Create"],
    ["saved", "bookmark", "Saved"],
    ["activity", "activity", "Activity"],
  ]
    .map(
      ([id, ic, label]) =>
        `<a href="#${id}" class="${screen === id ? "active" : ""}">${icon(ic)}<span>${label}</span></a>`,
    )
    .join("")}</nav>`;
  community.observe();
}
function windowPreview(p, feature = false) {
  return `<div class="mini-window" inert aria-hidden="true"><div class="windowbar"><i></i><i></i><i></i><span>${esc(p.name.toLowerCase())}.branch</span></div><iframe title="${esc(p.name)} preview thumbnail" src="/preview/${p.id}" sandbox="allow-scripts" tabindex="-1" aria-hidden="true" loading="${feature ? "eager" : "lazy"}"></iframe></div>`;
}
function card(p) {
  return `<article class="project-card"><button class="thumbnail" style="background:${esc(p.color)}" data-action="detail" data-id="${p.id}" aria-label="Try ${esc(p.name)}">${windowPreview(p)}<span class="preview-hover"><span>${icon("play")}Try this project</span></span></button><div class="card-body"><div class="card-title"><button data-action="${screen === "workspace" ? "edit" : "detail"}" data-id="${p.id}">${esc(p.name)}</button></div><p>${esc(p.tagline)}</p><div class="tags">${p.tags.map((t) => `<span class="tag">${esc(t)}</span>`).join("")}${!p.seed ? `<span class="tag">${p.published ? "Published locally" : "Draft"}</span>` : ""}</div></div><footer class="card-footer"><span class="byline"><span class="avatar" style="background:${esc(p.color)}">${esc(p.initials)}</span>${esc(p.author)}</span><span class="card-stats"><span>${icon("fork")}${p.localForks || 0}</span></span></footer>${community.socialBar(p)}</article>`;
}
function filtered() {
  return projects
    .filter(
      (p) =>
        (screen === "workspace"
          ? !p.seed
          : screen === "saved"
            ? p.saved
            : p.published) &&
        (category === "All projects" || p.category === category) &&
        `${p.name} ${p.description} ${p.tags.join(" ")} ${p.category} ${p.author}`
          .toLowerCase()
          .includes(query.toLowerCase()),
    )
    .sort((a, b) =>
      sort === "newest"
        ? new Date(b.createdAt) - new Date(a.createdAt)
        : sort === "name"
          ? a.name.localeCompare(b.name)
          : (b.localForks || 0) - (a.localForks || 0),
    );
}
function empty(title, text, ic = "search") {
  return `<div class="empty">${icon(ic)}<h3>${title}</h3><p>${text}</p>${button("Explore projects", "explore", "dark", "compass")}</div>`;
}
function gridContent() {
  let list = filtered();
  return list.length
    ? list.map(card).join("")
    : empty(
        screen === "saved"
          ? "Keep a little inspiration close."
          : screen === "workspace"
            ? "Your next idea starts here."
            : "No projects found.",
        screen === "saved"
          ? "Save a project with the bookmark icon and find it here."
          : screen === "workspace"
            ? "Try a project, make a fork, and give it your own direction."
            : "Try a different search or select another category.",
        screen === "saved" ? "bookmark" : "branch",
      );
}
function discovery() {
  const featured = projects.find((p) => p.id === "nourish");
  let heading =
    screen === "workspace"
      ? "A space for your next big thing."
      : screen === "saved"
        ? "Good ideas, kept close."
        : "Good ideas deserve<br><span>a head start.</span>";
  let sub =
    screen === "workspace"
      ? "Your forks and published projects. Pick up where you left off."
      : screen === "saved"
        ? "A collection of starting points for whatever comes next."
        : "Discover working projects. Make them yours. Build on something good.";
  return `<div class="eyebrow">${icon("spark")}${screen === "explore" ? "LESS FROM SCRATCH. MORE POSSIBILITIES." : screen === "workspace" ? "MAKE SOMETHING YOURS" : "YOUR COLLECTION"}</div><section class="intro"><div><h1>${heading}</h1><p>${sub}</p></div>${screen === "explore" ? `<span class="intro-note">${icon("leaf")}A little reuse goes a long way.</span>` : ""}</section>${screen === "explore" ? `<section class="feature" ${query ? "hidden" : ""}><div class="feature-copy"><div class="feature-badge">${icon("star")}THE COMMUNITY STARTER KIT</div><h2>Your next project<br>is already taking root.</h2><p>Meet Nourish. A thoughtful meal planner,<br>ready for your own fresh ideas.</p><div class="feature-actions">${button("Take a look", "detail", "dark", "arrow", 'data-id="nourish"')}<small>Try it. Fork it. Make it yours.</small></div></div><div class="feature-preview">${windowPreview(featured, true)}<div class="feature-tag">${icon("check")}A working app. A fresh beginning.</div></div></section>` : ""}<section><div class="section-head"><h2><b id="results-title" style="font-weight:inherit">${screen === "workspace" ? "Your projects" : screen === "saved" ? "Saved for later" : query ? "Search results" : "Explore the possibilities"}</b> <span id="result-count">${filtered().length} project${filtered().length === 1 ? "" : "s"}</span></h2><label class="sort">Sort by: <select id="sort" aria-label="Sort projects"><option value="popular" ${sort === "popular" ? "selected" : ""}>Most forked</option><option value="newest" ${sort === "newest" ? "selected" : ""}>Recently added</option><option value="name" ${sort === "name" ? "selected" : ""}>Name A–Z</option></select></label></div><div class="filters" role="group" aria-label="Project categories">${categories.map((c, i) => `<button class="chip ${category === c ? "active" : ""}" data-action="category" data-category="${esc(c)}" aria-pressed="${category === c}">${icon(categoryIcons[i])}${c}</button>`).join("")}</div><div class="grid" id="project-grid">${gridContent()}</div></section><div class="footer-note">${icon("branch")}${screen === "explore" ? "Built to be used. Made to be remixed. · Example creators, real local reactions" : "Your work is saved on this computer."}</div>`;
}
function updateGrid() {
  if (screen === "home") {
    community.refresh();
    return;
  }
  const grid = document.getElementById("project-grid");
  if (grid) {
    grid.innerHTML = gridContent();
    document.getElementById("result-count").textContent =
      `${filtered().length} project${filtered().length === 1 ? "" : "s"}`;
    const feature = document.querySelector(".feature");
    if (feature) feature.hidden = Boolean(query);
    if (screen === "explore")
      document.getElementById("results-title").textContent = query
        ? "Search results"
        : "Explore the possibilities";
    document.querySelectorAll('[data-action="category"]').forEach((el) => {
      let active = el.dataset.category === category;
      el.classList.toggle("active", active);
      el.setAttribute("aria-pressed", active);
    });
  }
}
function details(p) {
  return `<button class="back" data-action="explore">${icon("back")}Back to discover</button><div class="detail-header"><div><div class="eyebrow">${esc(p.category.toUpperCase())}</div><h1>${esc(p.name)}</h1><p>${esc(p.description)}</p><div class="detail-meta"><span class="byline"><span class="avatar" style="background:${esc(p.color)}">${esc(p.initials)}</span>${esc(p.author)}</span><span>${esc(p.license)} license</span><span>${esc(p.stack)}</span>${p.parentId ? `<a href="#project/${p.parentId}">Forked from ${esc(projects.find((x) => x.id === p.parentId)?.name || "a project")} ↗</a>` : ""}</div><div class="detail-social">${community.socialBar(p)}</div></div><div class="detail-buttons">${!p.seed ? button("Open workspace", "edit", "dark", "code", `data-id="${p.id}"`) : button("Make it yours", "fork", "dark", "fork", `data-id="${p.id}"`)}</div></div><div class="preview-panel"><div class="preview-toolbar"><span><i class="dot"></i>Live interactive preview · sample data</span><a href="/preview/${p.id}" target="_blank" rel="noopener" aria-label="Open preview in a new tab">${icon("external")}</a></div><iframe title="Try ${esc(p.name)}" src="/preview/${p.id}" sandbox="allow-scripts allow-forms"></iframe></div><div class="detail-bottom"><div class="info-block"><h3>A working starting point</h3><p>Try the app above. Every starter is a self-contained HTML project, with styling, interactions, and sample data included.</p></div><div class="info-block"><h3>Your fork. Your direction.</h3><p>Get your own independent copy. Edit the code, connect a local AI agent, or export the project to use in your favorite editor.</p></div></div>`;
}
function agentConnection() {
  return agent.connected
    ? `<span class="dot"></span> Local agent connected<select id="model" aria-label="Agent model">${agent.models.map((m) => `<option>${esc(m)}</option>`).join("")}</select>${agent.models.length ? "" : "<p>No models installed. Download a coding model in Ollama.</p>"}`
    : `Your creative copilot awaits.<br><button data-action="connect">Connect a local AI agent →</button>`;
}
function workspace(p) {
  return `<button class="back" data-action="workspace">${icon("back")}My workspace</button><div class="workspace-top"><div><h1>${esc(p.name)}</h1><p>${p.parentId ? `Forked from ${esc(projects.find((x) => x.id === p.parentId)?.name || "a community project")} · ` : ""}${p.published ? "Published to your local gallery" : "Private local draft"}</p></div><div class="workspace-actions"><a class="btn" href="/api/projects/${p.id}/export">${icon("download")}Export HTML</a>${p.parentId ? button("Propose improvement", "contribute", "", "fork") : ""}${button("Publish version", "publish", "dark", "upload")}</div></div><div class="work-grid"><aside class="agent-panel"><div class="agent-title"><span>Make it your own</span>${icon("spark")}</div><p class="agent-description">A working project is just the beginning.<br>Describe what you want to change, then try the result.</p><div class="agent-connection" id="agent-connection">${agentConnection()}</div><div class="suggestions"><button class="suggestion" data-action="suggest" data-prompt="Add a dark mode toggle, preserving the existing design and functionality.">Add a dark mode toggle ${icon("arrow")}</button><button class="suggestion" data-action="suggest" data-prompt="Improve the mobile layout with accessible touch targets and responsive spacing.">Make it feel great on mobile ${icon("arrow")}</button></div><div class="agent-bottom"><textarea id="prompt" placeholder="What would you like to change?" aria-label="Describe a project change"></textarea><button class="btn dark" id="agent-run" data-action="run-agent">${icon("spark")}Build this change</button><small>Runs with your local Ollama model. Changes are saved with a restorable previous version.</small><div class="form-error" id="agent-error" role="alert"></div></div></aside><section class="work-main"><div class="preview-panel"><div class="preview-toolbar"><div class="tabs"><button class="tab ${tab === "preview" ? "active" : ""}" data-action="tab" data-tab="preview">Live preview</button><button class="tab ${tab === "code" ? "active" : ""}" data-action="tab" data-tab="code">Source code</button></div><button data-action="refresh-preview" aria-label="Refresh preview">${icon("refresh")}</button></div><div id="editor-content">${editorContent(p)}</div></div><div class="editor-help"><span id="save-status">${dirty ? "Unsaved changes" : "All changes saved locally"}</span><div style="display:flex;gap:7px">${button("Restore previous", "restore", "", "refresh", p.revisionCount ? "" : "disabled")}${button("Save changes", "save-code", "dark", "check")}</div></div></section></div>`;
}
function editorContent(p) {
  return tab === "code"
    ? `<textarea id="code" class="code-editor" aria-label="Project HTML source" spellcheck="false" ${busy ? "disabled" : ""}>${esc(draft)}</textarea>`
    : `<iframe id="work-preview" title="${esc(p.name)} workspace preview" src="/preview/${p.id}?v=${Date.now()}" sandbox="allow-scripts allow-forms"></iframe>`;
}
function activityView() {
  return `<div class="eyebrow">${icon("activity")}ONE GOOD THING LEADS TO ANOTHER</div><h1 class="view-title">A little progress, every day.</h1><p class="subtitle">Your forks, changes, and contributions, all in one place.</p>${activity.length ? activity.map((a) => `<article class="activity-item"><div class="activity-icon">${icon("branch")}</div><div><h3>${esc(a.text)}</h3><p>${new Date(a.createdAt).toLocaleString()}</p></div>${button("Open", "edit", "", "arrow", `data-id="${a.projectId}"`)}</article>`).join("") : empty("Your story starts with a fork.", "Explore a project and make something that matters to you.", "activity")}${contributions.length ? `<div class="section-head"><h2>Proposed improvements</h2></div>${contributions.map((c) => `<article class="activity-item"><div class="activity-icon">${icon("fork")}</div><div><h3>${esc(c.title)}</h3><p>Local proposal · ${esc(projects.find((p) => p.id === c.projectId)?.name)} → ${esc(projects.find((p) => p.id === c.parentId)?.name)}</p></div>${button("Review", "review", "", "external", `data-id="${c.id}"`)}</article>`).join("")}` : ""}`;
}
async function render() {
  activeHash = location.hash || "#home";
  let token = ++renderId;
  const parts = (location.hash.slice(1) || "home").split("/");
  screen = parts[0];
  try {
    if (screen === "project" || screen === "edit") {
      const p = await api("/projects/" + encodeURIComponent(parts[1]));
      if (token !== renderId) return;
      if (screen === "edit" && p.seed) {
        location.hash = "project/" + p.id;
        return;
      }
      current = p;
      draft = p.html;
      dirty = false;
      tab = "preview";
      shell(screen === "project" ? details(p) : workspace(p));
      if (screen === "edit") {
        api("/agent")
          .then((a) => {
            agent = a;
            const el = document.getElementById("agent-connection");
            if (el) el.innerHTML = agentConnection();
          })
          .catch(() => {});
      }
    } else {
      current = null;
      screen = ["home", "explore", "workspace", "saved", "activity"].includes(
        screen,
      )
        ? screen
        : "explore";
      shell(
        screen === "home"
          ? community.home()
          : screen === "activity"
            ? activityView()
            : discovery(),
      );
    }
  } catch (e) {
    shell(
      `<div class="error-banner">${esc(e.message)}</div>${button("Back to discover", "explore", "", "back")}`,
    );
  }
}
function navigate(hash) {
  if (dirty) {
    openModal(
      "Leave unsaved changes?",
      `<p>Your source edits have not been saved. Save them before leaving, or discard them.</p><div class="dialog-footer">${button("Keep editing", "close")}${button("Discard and leave", "discard", "dark", "", 'data-destination="' + esc(hash) + '"')}</div>`,
    );
    return;
  }
  if (location.hash === "#" + hash) {
    render();
    window.scrollTo(0, 0);
  } else location.hash = hash;
}
function openModal(title, html) {
  modalOrigin = document.activeElement;
  overlay.innerHTML = `<div class="dialog-backdrop"><section class="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title"><div class="dialog-head"><h2 id="dialog-title">${title}</h2><button class="close" data-action="close" aria-label="Close dialog">${icon("close")}</button></div>${html}</section></div>`;
  setTimeout(
    () =>
      (
        overlay.querySelector("input,textarea,select") ||
        overlay.querySelector(".dialog-footer button") ||
        overlay.querySelector(".close")
      )?.focus(),
    20,
  );
}
function closeModal() {
  overlay.innerHTML = "";
  modalOrigin?.focus();
}
function forkModal(p) {
  openModal(
    "A fresh branch. All yours.",
    `<p>Start with ${esc(p.name)} and take it somewhere new. Your copy includes the complete working app and sample data.</p><form id="fork-form"><label class="field">Project name<input name="name" value="${esc(p.name)} remix" required maxlength="70"></label><p class="notice">An independent copy will be saved to your workspace on this computer. The original project stays connected through attribution.</p><div class="form-error" role="alert"></div><div class="dialog-footer">${button("Cancel", "close")}<button class="btn dark" type="submit">${icon("fork")}Create my fork</button></div></form>`,
  );
  document.getElementById("fork-form").onsubmit = async (e) => {
    e.preventDefault();
    await formTask(e.target, async () => {
      let fork = await post(`/projects/${p.id}/fork`, {
        name: new FormData(e.target).get("name"),
      });
      await reload();
      closeModal();
      navigate("edit/" + fork.id);
      toast("Your fork is ready. Make something good.");
    });
  };
}
async function formTask(form, task) {
  let btn = form.querySelector("[type=submit]"),
    err = form.querySelector(".form-error");
  btn.disabled = true;
  err.textContent = "";
  try {
    await task();
  } catch (e) {
    err.textContent = e.message;
  } finally {
    btn.disabled = false;
  }
}
function publishModal() {
  openModal(
    "Give your project a home.",
    `<p>Share a working HTML app in your local gallery. Other people on this computer can try it and make their own fork.</p><form id="publish-form"><label class="field">Project name<input name="name" placeholder="Something worth building on" required maxlength="70"></label><label class="field">What does it do?<textarea name="description" placeholder="A useful starting point for…" required maxlength="500"></textarea></label><label class="field">Category<select name="category">${categories
      .slice(1)
      .map((c) => `<option>${c}</option>`)
      .join(
        "",
      )}</select></label><label class="field">Your complete HTML app<input type="file" name="file" accept=".html,.htm,text/html" required></label><p class="notice">Include your CSS and JavaScript in one HTML file (up to 1 MB). Previews run without external scripts or network requests. Publish only work you can share under the MIT license. This version publishes locally.</p><div class="form-error" role="alert"></div><div class="dialog-footer">${button("Cancel", "close")}<button type="submit" class="btn dark">${icon("upload")}Publish project</button></div></form>`,
  );
  document.getElementById("publish-form").onsubmit = async (e) => {
    e.preventDefault();
    await formTask(e.target, async () => {
      let data = new FormData(e.target),
        file = data.get("file");
      if (file.size > 1000000)
        throw Error("Choose an HTML file smaller than 1 MB.");
      let p = await post("/projects", {
        name: data.get("name"),
        description: data.get("description"),
        category: data.get("category"),
        html: await file.text(),
      });
      await reload();
      closeModal();
      navigate("project/" + p.id);
      toast("Your project is live in the local gallery.");
    });
  };
}
async function connectModal() {
  openModal(
    "Your agent. Your machine.",
    `<p>Branch connects to Ollama running on your computer. Your model receives the current app and your requested change, then returns an updated version.</p><div id="connection-result" class="notice"><span class="spinner"></span> Checking local agent…</div><p class="notice">Start Ollama on this machine and download a coding model. For example:<code>ollama pull qwen2.5-coder:7b</code>The default connection is <code>http://127.0.0.1:11434</code>You can also export any project as HTML and open it in your preferred coding agent.</p><div class="dialog-footer">${button("Check connection", "reconnect", "", "refresh")}${button("Done", "close", "dark")}</div>`,
  );
  await checkAgent();
}
async function checkAgent() {
  agent = await api("/agent");
  const el = document.getElementById("connection-result");
  if (el)
    el.innerHTML = agent.connected
      ? `${icon("check")} Ollama is connected. ${agent.models.length} model${agent.models.length === 1 ? "" : "s"} available.${agent.models.length ? "" : " Download a model to start editing."}`
      : "No local agent detected yet. Start Ollama, then check the connection again.";
  const panel = document.getElementById("agent-connection");
  if (panel) panel.innerHTML = agentConnection();
}
async function saveCode() {
  if (busy) throw Error("Wait for the current agent change to finish.");
  if (!dirty) {
    toast("Everything is already saved.");
    return;
  }
  current = await api(`/projects/${current.id}`, {
    method: "PATCH",
    body: JSON.stringify({ html: draft }),
  });
  current.html = draft;
  dirty = false;
  await reload();
  shell(workspace(current));
  toast("Changes saved. Your preview is ready.");
}
async function runAgent() {
  let prompt = document.getElementById("prompt").value.trim(),
    model = document.getElementById("model")?.value;
  const error = document.getElementById("agent-error");
  if (!prompt) {
    error.textContent = "Describe the change you want to make.";
    return;
  }
  if (dirty) {
    error.textContent =
      "Save your source edits before asking the agent to change them.";
    return;
  }
  if (!agent.connected || !model) {
    await connectModal();
    return;
  }
  if (busy) return;
  busy = true;
  const sourceEditor = document.getElementById("code");
  if (sourceEditor) sourceEditor.disabled = true;
  const target = current.id,
    btn = document.getElementById("agent-run");
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span> Building your change…';
  error.textContent = "";
  try {
    const updated = await post(`/projects/${target}/agent`, { prompt, model });
    await reload();
    if (current?.id === target) {
      current = updated;
      draft = updated.html;
      dirty = false;
      shell(workspace(current));
    }
    toast("The agent saved a new version. Try the preview.");
  } catch (e) {
    if (document.getElementById("agent-error"))
      document.getElementById("agent-error").textContent = e.message;
    else toast(e.message);
  } finally {
    busy = false;
    const sourceEditor = document.getElementById("code");
    if (sourceEditor) sourceEditor.disabled = false;
    if (document.getElementById("agent-run")) {
      document.getElementById("agent-run").disabled = false;
      document.getElementById("agent-run").innerHTML =
        icon("spark") + "Build this change";
    }
  }
}
function contributeModal() {
  if (dirty) {
    toast("Save your changes before proposing an improvement.");
    return;
  }
  openModal(
    "Build on the original.",
    `<p>Describe how your version improves ${esc(projects.find((p) => p.id === current.parentId)?.name || "the original")}. Branch saves a local proposal with a snapshot of your current code.</p><form id="contribute-form"><label class="field">What changed?<textarea name="title" required maxlength="250" placeholder="Added a weekly summary and improved the mobile view…"></textarea></label><p class="notice">This is a local review workflow. It does not send a message or pull request to an external author.</p><div class="form-error" role="alert"></div><div class="dialog-footer">${button("Cancel", "close")}<button type="submit" class="btn dark">${icon("fork")}Save proposal</button></div></form>`,
  );
  document.getElementById("contribute-form").onsubmit = async (e) => {
    e.preventDefault();
    await formTask(e.target, async () => {
      await post(`/projects/${current.id}/contribute`, {
        title: new FormData(e.target).get("title"),
      });
      await reload();
      closeModal();
      toast("Improvement proposed. Review it in Activity.");
    });
  };
}
function reviewModal(c) {
  openModal(
    "Review an improvement",
    `<p><strong>${esc(c.title)}</strong></p><p>Compare the original app with the proposed snapshot.</p><div class="dialog-footer" style="justify-content:start"><a class="btn" href="/preview/${c.parentId}" target="_blank" rel="noopener">Original ${icon("external")}</a>${button("Proposed version", "proposal-preview", "dark", "play", `data-id="${c.id}"`)}</div><div id="proposal-preview" style="margin-top:18px"></div><p class="notice">This proposal is saved locally. You can export the fork to share your improvement.</p>`,
  );
}

document.addEventListener("click", async (e) => {
  const el = e.target.closest("[data-action]");
  if (!el) return;
  const a = el.dataset.action,
    id = el.dataset.id,
    p = id ? projects.find((p) => p.id === id) : current;
  try {
    if (a.startsWith("social-")) {
      await community.action(a, el);
      return;
    }
    switch (a) {
      case "menu":
        document.getElementById("sidebar").classList.toggle("open");
        break;
      case "explore":
        category = "All projects";
        query = "";
        navigate("explore");
        break;
      case "workspace":
        navigate("workspace");
        break;
      case "detail":
        navigate("project/" + id);
        break;
      case "edit":
        navigate("edit/" + id);
        break;
      case "category":
        category = el.dataset.category;
        updateGrid();
        break;
      case "save": {
        await post(`/projects/${id}/save`);
        await reload();
        if (screen === "project") {
          current = await api("/projects/" + id);
          shell(details(current));
        } else updateGrid();
        toast(
          projects.find((x) => x.id === id).saved
            ? "Saved for a little inspiration later."
            : "Removed from saved projects.",
        );
        break;
      }
      case "fork":
        forkModal(p);
        break;
      case "publish-new":
        publishModal();
        break;
      case "close":
        closeModal();
        break;
      case "discard":
        dirty = false;
        closeModal();
        navigate(el.dataset.destination);
        break;
      case "connect":
        await connectModal();
        break;
      case "reconnect":
        await checkAgent();
        break;
      case "tab":
        tab = el.dataset.tab;
        document.getElementById("editor-content").innerHTML =
          editorContent(current);
        document
          .querySelectorAll('[data-action="tab"]')
          .forEach((x) => x.classList.toggle("active", x.dataset.tab === tab));
        break;
      case "save-code":
        await saveCode();
        break;
      case "refresh-preview":
        if (dirty) {
          toast("Save your source changes to update the preview.");
          break;
        }
        document.getElementById("editor-content").innerHTML =
          editorContent(current);
        break;
      case "suggest":
        document.getElementById("prompt").value = el.dataset.prompt;
        document.getElementById("prompt").focus();
        break;
      case "run-agent":
        await runAgent();
        break;
      case "publish":
        if (busy) {
          toast("Wait for the agent to finish before publishing.");
          break;
        }
        if (dirty) {
          toast("Save your edits before publishing.");
          break;
        }
        await post(`/projects/${current.id}/publish`);
        await reload();
        current = await api("/projects/" + current.id);
        shell(workspace(current));
        toast("Your version is published to the local gallery.");
        break;
      case "restore":
        if (busy) {
          toast("Wait for the agent to finish before restoring.");
          break;
        }
        if (dirty) {
          toast("Save or discard your source edits before restoring.");
          break;
        }
        current = await post(`/projects/${current.id}/restore`);
        draft = current.html;
        dirty = false;
        await reload();
        shell(workspace(current));
        toast("Previous version restored.");
        break;
      case "contribute":
        contributeModal();
        break;
      case "review":
        reviewModal(contributions.find((c) => c.id === id));
        break;
      case "proposal-preview": {
        const c = contributions.find((c) => c.id === id);
        const frame = document.createElement("iframe");
        frame.title = "Proposed improvement snapshot";
        frame.setAttribute("sandbox", "allow-scripts");
        frame.style =
          "width:100%;height:380px;border:1px solid #dfe5d6;border-radius:7px";
        frame.src = "/proposal/" + c.id;
        document.getElementById("proposal-preview").replaceChildren(frame);
        break;
      }
      case "about":
        openModal(
          "A better place to start.",
          `<p>Most ideas don’t need an empty folder. They need a working starting point and someone with a fresh perspective.</p><p>Branch is a place to discover projects by using them, create your own version, and contribute what you learn along the way.</p><p class="notice">This first edition runs on your computer. The gallery includes six curated examples. Your projects, forks, and proposals are saved locally; community accounts and shared hosting are future steps.</p><div class="dialog-footer">${button("Let’s explore", "close", "dark", "arrow")}</div>`,
        );
        break;
      case "profile":
        openModal(
          "Your local creative space",
          `<p>Your projects and activity are saved on this computer. No account is required for this edition.</p><div class="notice">${projects.filter((p) => !p.seed).length} projects · ${projects.filter((p) => p.saved).length} saved starters · ${contributions.length} proposed improvements</div><p>Use Export HTML from any project workspace to take your work with you.</p><div class="dialog-footer">${button("Keep building", "close", "dark")}</div>`,
        );
        break;
    }
  } catch (err) {
    toast(err.message);
  }
});

document.addEventListener("dblclick", (e) => {
  const visual = e.target.closest(".feed-visual");
  if (visual && !e.target.closest("button"))
    community.doubleLike(visual.dataset.id);
});
document.addEventListener("input", (e) => {
  if (e.target.id === "comment-text")
    document.getElementById("comment-count").textContent =
      `${e.target.value.length} / 1000`;
  if (e.target.id === "search") {
    query = e.target.value;
    if (!["home", "explore", "saved", "workspace"].includes(screen)) {
      if (dirty) {
        toast("Save your source changes before searching.");
        return;
      }
      location.hash = "explore";
    } else updateGrid();
  }
  if (e.target.id === "code") {
    draft = e.target.value;
    dirty = draft !== current.html;
    document.getElementById("save-status").textContent = dirty
      ? "Unsaved changes"
      : "All changes saved locally";
  }
});
document.addEventListener("change", (e) => {
  if (e.target.id === "sort") {
    sort = e.target.value;
    updateGrid();
  }
});
document.addEventListener("keydown", (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === "k") {
    e.preventDefault();
    document.getElementById("search")?.focus();
  }
  if (e.key === "Escape" && overlay.children.length) closeModal();
  if (e.key === "Tab" && overlay.children.length) {
    const items = [
      ...overlay.querySelectorAll("button,a,input,textarea,select"),
    ].filter((el) => !el.disabled);
    const first = items[0],
      last = items.at(-1);
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }
  if ((e.metaKey || e.ctrlKey) && e.key === "s" && screen === "edit") {
    e.preventDefault();
    saveCode().catch((e) => toast(e.message));
  }
});
document.addEventListener("click", (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (link) {
    e.preventDefault();
    category = "All projects";
    query = "";
    navigate(link.getAttribute("href").slice(1));
  }
});
window.addEventListener("hashchange", async () => {
  if (dirty) {
    const destination = location.hash.slice(1) || "explore";
    history.replaceState(null, "", activeHash);
    navigate(destination);
    return;
  }
  scrollPositions.set(activeHash, window.scrollY);
  closeModal();
  await render();
  requestAnimationFrame(() =>
    window.scrollTo(0, scrollPositions.get(location.hash || "#home") || 0),
  );
});
window.addEventListener("beforeunload", (e) => {
  if (dirty || busy) {
    e.preventDefault();
    e.returnValue = "";
  }
});
const community = createCommunity({
  icon,
  esc,
  button,
  api,
  post,
  reload,
  toast,
  navigate,
  openModal,
  closeModal,
  query: () => query,
  savedChanged: () => {
    if (screen === "saved") updateGrid();
  },
  replaceProject: (p) => {
    const i = projects.findIndex((x) => x.id === p.id);
    if (i >= 0) projects[i] = { ...projects[i], ...p };
    if (current?.id === p.id) current = { ...current, ...p };
  },
});
try {
  await reload();
  await render();
} catch (e) {
  shell(
    `<div class="error-banner">Could not connect to Branch. Start the server with npm start, then reload this page.</div>`,
  );
}
