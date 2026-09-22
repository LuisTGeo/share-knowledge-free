export function createCommunity(ctx) {
  const {
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
  } = ctx;
  let data = { projects: [], following: [], interests: [] },
    mode = "for-you",
    limit = 3,
    observer = null,
    commentProject = null;
  const pending = new Set();
  const formatCount = (n) => (n > 999 ? `${(n / 1000).toFixed(1)}k` : n);
  const creatorProjects = (author) =>
    data.projects.filter((p) => p.author === author && p.published);
  const categories = [
    "Productivity",
    "Health & wellness",
    "Design & creative",
    "Finance",
    "Developer tools",
  ];
  function setData(value) {
    data = value;
  }
  function updateProject(p) {
    const i = data.projects.findIndex((x) => x.id === p.id);
    if (i >= 0) data.projects[i] = { ...data.projects[i], ...p };
    ctx.replaceProject(p);
  }
  function ordered() {
    const search = ctx.query().toLowerCase();
    return data.projects
      .filter(
        (p) =>
          p.published &&
          (mode !== "following" || data.following.includes(p.author)) &&
          `${p.name} ${p.description} ${p.category} ${p.author}`
            .toLowerCase()
            .includes(search),
      )
      .sort((a, b) =>
        mode === "latest"
          ? new Date(b.createdAt) - new Date(a.createdAt)
          : score(b) - score(a),
      );
  }
  function score(p) {
    return (
      (data.interests.includes(p.category) ? 10 : 0) +
      (data.following.includes(p.author) ? 5 : 0) +
      (p.liked ? 1 : 0)
    );
  }
  function reason(p) {
    return mode === "following"
      ? "From a creator you follow"
      : mode === "latest"
        ? "Recently added"
        : data.interests.includes(p.category)
          ? `Because you like ${p.category.toLowerCase()}`
          : data.following.includes(p.author)
            ? "From a creator you follow"
            : "A fresh starting point for you";
  }
  function socialBar(p) {
    return `<div class="social-actions" data-social-id="${p.id}"><div class="reaction-group"><button class="reaction ${p.liked ? "is-liked" : ""}" data-action="social-like" data-id="${p.id}" aria-label="${p.liked ? "Unlike" : "Like"} ${esc(p.name)}" aria-pressed="${!!p.liked}">${icon("heart")}<span>${formatCount(p.likes || 0)}</span></button><button class="reaction" data-action="social-comments" data-id="${p.id}" aria-label="Comments on ${esc(p.name)}">${icon("comment")}<span>${p.commentCount || 0}</span></button><button class="reaction ${p.rating ? "is-rated" : ""}" data-action="social-rate" data-id="${p.id}" aria-label="Rate ${esc(p.name)}${p.rating ? `, your rating ${p.rating} out of 5` : ""}">${icon("star")}<span>${p.rating ? `${p.rating}.0` : "Rate"}</span></button><button class="reaction share-reaction" data-action="social-share" data-id="${p.id}" aria-label="Share ${esc(p.name)}">${icon("share")}</button></div><button class="reaction ${p.saved ? "is-saved" : ""}" data-action="social-save" data-id="${p.id}" aria-label="${p.saved ? "Unsave" : "Save"} ${esc(p.name)}" aria-pressed="${!!p.saved}">${icon("bookmark")}</button></div>`;
  }
  function feedPost(p) {
    return `<article class="feed-post" data-post-id="${p.id}"><header class="post-header"><button class="creator-identity" data-action="social-creator" data-author="${esc(p.author)}"><span class="creator-avatar" style="--avatar-bg:${esc(p.color)}">${esc(p.initials)}</span><span><strong>${esc(p.author)}</strong><small>${esc(reason(p))}</small></span></button>${p.author !== "You" ? `<button class="follow-button ${p.following ? "following" : ""}" data-action="social-follow" data-author="${esc(p.author)}">${p.following ? "Following" : "+ Follow"}</button>` : '<span class="own-post">Your project</span>'}</header><div class="feed-visual" style="--preview-bg:${esc(p.color)}" data-id="${p.id}"><span class="project-kind">${icon("spark")}${esc(p.category)}</span><div class="feed-window" inert aria-hidden="true"><div class="windowbar"><i></i><i></i><i></i><span>${esc(p.name.toLowerCase())}.branch</span></div><iframe src="/preview/${p.id}" sandbox="allow-scripts" title="${esc(p.name)} visual preview" tabindex="-1" loading="lazy"></iframe></div><button class="try-floating" data-action="detail" data-id="${p.id}">${icon("play")}Try the app</button><span class="like-burst" aria-hidden="true">${icon("heart")}</span></div><div class="post-body">${socialBar(p)}<div class="post-copy"><button class="post-title" data-action="detail" data-id="${p.id}">${esc(p.name)}</button><p>${esc(p.tagline)}</p><div class="post-tags">${p.tags.map((t) => `<span>#${esc(t.replace(/\s+/g, ""))}</span>`).join("")}</div></div><div class="post-bottom"><button class="comment-invite" data-action="social-comments" data-id="${p.id}">${p.commentCount ? `Join ${p.commentCount === 1 ? "the conversation" : `${p.commentCount} comments`}` : "What would you build with this?"}</button><button class="remix-pill" data-action="fork" data-id="${p.id}">${icon("fork")}Remix</button></div></div></article>`;
  }
  function creators() {
    return [
      ...new Map(
        data.projects.filter((p) => p.seed).map((p) => [p.author, p]),
      ).values(),
    ];
  }
  function suggestions() {
    return `<aside class="community-rail"><div class="rail-welcome"><span class="tiny-label">A PLACE FOR YOUR CURIOSITY</span><h2>Less blank canvas.<br>More possibilities.</h2><p>Try something. Leave a little love.<br>Make something of your own.</p><button data-action="social-interests">Make this feed yours ${icon("arrow")}</button><div class="abstract-sprout" aria-hidden="true"><i></i><i></i><i></i><span>↗</span></div></div><div class="creators-panel"><div class="rail-heading"><h3>Meet the makers</h3><span>Starter creators</span></div>${creators()
      .slice(0, 4)
      .map(
        (p) =>
          `<div class="suggested-creator"><button class="creator-identity" data-action="social-creator" data-author="${esc(p.author)}"><span class="creator-avatar" style="--avatar-bg:${esc(p.color)}">${esc(p.initials)}</span><span><strong>${esc(p.author)}</strong><small>${esc(p.category)}</small></span></button><button class="mini-follow" data-action="social-follow" data-author="${esc(p.author)}" aria-label="${p.following ? "Unfollow" : "Follow"} ${esc(p.author)}">${p.following ? icon("check") : icon("plus")}</button></div>`,
      )
      .join(
        "",
      )}</div><div class="build-prompt"><span>${icon("fork")}</span><h3>Your version could be next.</h3><p>Find an app you like, hit Remix, and take it somewhere new.</p>${button("Explore starting points", "explore", "", "arrow")}</div><p class="community-footnote">Local community preview · Example creators.<br>Likes, ratings and comments are your real local interactions.</p></aside>`;
  }
  function home() {
    return `<div class="community-layout"><section class="feed-column"><div class="feed-heading"><div><div class="eyebrow">${icon("spark")}GOOD IDEAS TRAVEL TOGETHER</div><h1>A little scroll.<br><span>A world of possibilities.</span></h1></div><button class="interests-icon" data-action="social-interests" aria-label="Personalize your feed">${icon("sliders")}</button></div><div class="creator-strip" aria-label="Discover creators">${creators()
      .map(
        (p) =>
          `<button data-action="social-creator" data-author="${esc(p.author)}" class="creator-story"><span class="story-ring"><span style="background:${esc(p.color)}">${esc(p.initials)}</span></span><span>${esc(p.author.split(" ")[0])}</span></button>`,
      )
      .join(
        "",
      )}</div><div class="feed-tabs" role="tablist" aria-label="Choose your feed">${[
      ["for-you", "For you"],
      ["following", "Following"],
      ["latest", "Latest"],
    ]
      .map(
        ([id, label]) =>
          `<button role="tab" tabindex="${mode === id ? 0 : -1}" aria-selected="${mode === id}" data-action="social-mode" data-mode="${id}" class="${mode === id ? "selected" : ""}">${label}${mode === id ? "<i></i>" : ""}</button>`,
      )
      .join(
        "",
      )}<span>${icon("leaf")}Made to inspire</span></div><div id="social-feed">${feedContent()}</div></section>${suggestions()}</div>`;
  }
  function feedContent() {
    const list = ordered();
    if (!list.length)
      return `<div class="feed-empty">${icon(mode === "following" ? "people" : "search")}<h2>${mode === "following" ? "Your people. Your kind of ideas." : "No projects found."}</h2><p>${mode === "following" ? "Follow a maker from a project or the creator strip.<br>Their projects will appear here." : "Try a different project name or interest."}</p>${button("Explore For you", "social-mode", "dark", "compass", 'data-mode="for-you"')}</div>`;
    return list.slice(0, limit).map(feedPost).join("") + ending(list.length);
  }
  function ending(total) {
    return limit < total
      ? `<div class="feed-sentinel">${button("More inspiration", "social-more", "", "arrow")}</div>`
      : `<div class="feed-end">${icon("check")}<h3>You’re all caught up.</h3><p>${total} ${total === 1 ? "project" : "projects"} to spark something new.<br>Save a favorite or give one your own twist.</p>${button("Explore all projects", "explore", "", "compass")}</div>`;
  }
  function observe() {
    observer?.disconnect();
    const el = document.querySelector(".feed-sentinel");
    if (el) {
      observer = new IntersectionObserver(
        (entries) => {
          if (entries.some((e) => e.isIntersecting)) {
            observer.disconnect();
            more();
          }
        },
        { rootMargin: "150px" },
      );
      observer.observe(el);
    }
  }
  function more() {
    const feed = document.getElementById("social-feed");
    if (!feed) return;
    const list = ordered(),
      start = limit;
    limit += 3;
    feed.querySelector(".feed-sentinel")?.remove();
    feed.insertAdjacentHTML(
      "beforeend",
      list.slice(start, limit).map(feedPost).join("") + ending(list.length),
    );
    observe();
  }
  function refresh() {
    const feed = document.getElementById("social-feed");
    if (feed) {
      feed.innerHTML = feedContent();
      observe();
    }
  }
  function refreshReactions(p) {
    document.querySelectorAll(`[data-social-id="${p.id}"]`).forEach((el) => {
      el.outerHTML = socialBar(p);
    });
    const invite = document.querySelector(
      `[data-post-id="${p.id}"] .comment-invite`,
    );
    if (invite)
      invite.textContent = p.commentCount
        ? `Join ${p.commentCount === 1 ? "the conversation" : `${p.commentCount} comments`}`
        : "What would you build with this?";
  }
  async function like(p, force = false) {
    if (pending.has(p.id + "like") || (force && p.liked)) return;
    pending.add(p.id + "like");
    const previous = { ...p };
    updateProject({
      ...p,
      liked: force || !p.liked,
      likes: force || !p.liked ? 1 : 0,
    });
    refreshReactions(data.projects.find((x) => x.id === p.id));
    try {
      const updated = await post(`/projects/${p.id}/like`, {
        liked: force || !previous.liked,
      });
      updateProject(updated);
      refreshReactions(updated);
    } catch (e) {
      updateProject(previous);
      refreshReactions(previous);
      toast(e.message);
    } finally {
      pending.delete(p.id + "like");
    }
  }
  async function comments(p) {
    commentProject = p.id;
    openModal(
      `The conversation · ${esc(p.name)}`,
      `<div class="comments-context"><span class="creator-avatar" style="--avatar-bg:${esc(p.color)}">${esc(p.initials)}</span><div><b>${esc(p.name)}</b><p>${esc(p.tagline)}</p></div></div><div class="comments-list" id="comments-list" aria-live="polite"><p>Loading the conversation…</p></div><form id="comment-form"><label class="sr-only" for="comment-text">Your comment</label><div class="comment-suggestions"><button type="button" data-action="social-comment-prompt" data-text="I’d love to see ">Suggest an idea</button><button type="button" data-action="social-comment-prompt" data-text="What I like about this is ">Give feedback</button></div><div class="comment-composer"><textarea id="comment-text" name="text" required maxlength="1000" placeholder="A little feedback goes a long way…" rows="2"></textarea><button class="btn dark" type="submit" aria-label="Post comment">${icon("send")}</button></div><div class="composer-hint"><span>Keep it kind. Make it useful.</span><span id="comment-count">0 / 1000</span></div><div class="form-error" role="alert"></div></form>`,
    );
    const renderComments = (items) => {
      const list = document.getElementById("comments-list");
      if (!list || commentProject !== p.id) return;
      list.innerHTML = items.length
        ? items
            .map(
              (c) =>
                `<article class="comment-row"><span class="avatar">${esc(c.author.slice(0, 2).toUpperCase())}</span><div><b>${esc(c.author)}</b><time>${new Date(c.createdAt).toLocaleDateString(undefined, { month: "short", day: "numeric" })}</time><p>${esc(c.text)}</p></div></article>`,
            )
            .join("")
        : `<div class="comment-empty">${icon("comment")}<h3>Be the first to start something.</h3><p>Share what you like, ask a question,<br>or suggest a fresh direction.</p></div>`;
    };
    try {
      renderComments((await api(`/projects/${p.id}/comments`)).comments);
    } catch (e) {
      const list = document.getElementById("comments-list");
      if (list) list.textContent = e.message;
    }
    const form = document.getElementById("comment-form");
    if (!form) return;
    form.onsubmit = async (e) => {
      e.preventDefault();
      const field = form.querySelector("textarea"),
        submit = form.querySelector("[type=submit]"),
        error = form.querySelector(".form-error");
      if (!field.value.trim()) {
        error.textContent = "Write a comment before posting.";
        return;
      }
      submit.disabled = true;
      error.textContent = "";
      try {
        const result = await post(`/projects/${p.id}/comments`, {
          text: field.value,
        });
        updateProject(result.project);
        refreshReactions(result.project);
        field.value = "";
        document.getElementById("comment-count").textContent = "0 / 1000";
        renderComments((await api(`/projects/${p.id}/comments`)).comments);
        toast("Comment posted. Thanks for adding to the idea.");
      } catch (e) {
        error.textContent = e.message;
      } finally {
        submit.disabled = false;
      }
    };
  }
  function rating(p) {
    openModal(
      "A few stars. A little encouragement.",
      `<p>How useful is <strong>${esc(p.name)}</strong> as a starting point?</p><div class="rating-picker" role="group" aria-label="Rate ${esc(p.name)}">${[1, 2, 3, 4, 5].map((n) => `<button data-action="social-set-rating" data-id="${p.id}" data-rating="${n}" aria-label="${n} ${n === 1 ? "star" : "stars"}" aria-pressed="${n === p.rating}" class="${n <= p.rating ? "selected" : ""}">${icon("star")}</button>`).join("")}</div><p class="rating-caption">${p.rating ? `Your rating: ${p.rating} out of 5` : "Tap a star to leave your rating."}</p><p class="notice">Your rating is saved locally and can be changed any time. Try the app before rating it.</p><div class="dialog-footer">${p.rating ? button("Remove rating", "social-set-rating", "", "", `data-id="${p.id}" data-rating="0"`) : ""}${button("Done", "close", "dark")}</div>`,
    );
  }
  function interests() {
    openModal(
      "A feed that feels like you.",
      `<p>What are you curious about? Pick a few interests. You can change them whenever you like.</p><form id="interests-form"><div class="interest-options">${categories.map((c, i) => `<label><input type="checkbox" name="interest" value="${esc(c)}" ${data.interests.includes(c) ? "checked" : ""}><span>${icon(["bolt", "health", "palette", "wallet", "code"][i])}${c}</span></label>`).join("")}</div><p class="notice">For you puts selected interests and followed creators first, while keeping other ideas in the mix.</p><div class="form-error" role="alert"></div><div class="dialog-footer">${button("Maybe later", "close")}<button type="submit" class="btn dark">Make it mine ${icon("arrow")}</button></div></form>`,
    );
    document.getElementById("interests-form").onsubmit = async (e) => {
      e.preventDefault();
      const form = e.target,
        submit = form.querySelector("[type=submit]");
      submit.disabled = true;
      try {
        await post("/preferences", {
          interests: new FormData(form).getAll("interest"),
        });
        await reload();
        closeModal();
        refresh();
        toast("Your feed, with a little more you.");
      } catch (e) {
        form.querySelector(".form-error").textContent = e.message;
      } finally {
        submit.disabled = false;
      }
    };
  }
  function creator(author) {
    const list = creatorProjects(author),
      p = list[0];
    if (!p) return;
    openModal(
      `${esc(author)}`,
      `<div class="creator-profile"><span class="creator-avatar large" style="--avatar-bg:${esc(p.color)}">${esc(p.initials)}</span><h3>${esc(author)}</h3><p>${author === "You" ? "Making good ideas my own." : `Exploring ${esc(p.category.toLowerCase())}, one useful project at a time.`}</p><span class="example-label">${p.seed ? "Example creator" : "Local creator"} · ${list.length} ${list.length === 1 ? "project" : "projects"}</span>${author !== "You" ? `<button class="btn ${p.following ? "" : "dark"}" data-action="social-follow" data-author="${esc(author)}">${p.following ? "Following" : "+ Follow creator"}</button>` : ""}</div><div class="creator-projects">${list.map((p) => `<button data-action="social-open" data-id="${p.id}"><span style="background:${esc(p.color)}">${icon("grid")}</span><div><strong>${esc(p.name)}</strong><small>${esc(p.tagline)}</small></div>${icon("arrow")}</button>`).join("")}</div>`,
    );
  }
  async function action(a, el) {
    const id = el.dataset.id,
      p = data.projects.find((p) => p.id === id);
    switch (a) {
      case "social-like":
        await like(p);
        break;
      case "social-save": {
        if (pending.has(id + "save")) return;
        pending.add(id + "save");
        try {
          const updated = await post(`/projects/${id}/save`);
          updateProject(updated);
          refreshReactions(updated);
          ctx.savedChanged();
          toast(
            updated.saved
              ? "Saved to your collection."
              : "Removed from saved projects.",
          );
        } finally {
          pending.delete(id + "save");
        }
        break;
      }
      case "social-comments":
        await comments(p);
        break;
      case "social-comment-prompt":
        document.getElementById("comment-text").value = el.dataset.text;
        document.getElementById("comment-text").focus();
        document.getElementById("comment-count").textContent =
          `${el.dataset.text.length} / 1000`;
        break;
      case "social-rate":
        rating(p);
        break;
      case "social-set-rating": {
        const updated = await post(`/projects/${id}/rating`, {
          rating: Number(el.dataset.rating),
        });
        updateProject(updated);
        refreshReactions(updated);
        rating(updated);
        toast(
          updated.rating
            ? `${updated.rating} stars — a little encouragement goes a long way.`
            : "Rating removed.",
        );
        break;
      }
      case "social-mode":
        mode = el.dataset.mode;
        limit = 3;
        document.querySelectorAll(".feed-tabs [role=tab]").forEach((t) => {
          const selected = t.dataset.mode === mode;
          t.classList.toggle("selected", selected);
          t.setAttribute("aria-selected", selected);
          t.tabIndex = selected ? 0 : -1;
          t.querySelector("i")?.remove();
          if (selected) t.insertAdjacentHTML("beforeend", "<i></i>");
        });
        refresh();
        break;
      case "social-more":
        more();
        break;
      case "social-interests":
        interests();
        break;
      case "social-creator":
        creator(el.dataset.author);
        break;
      case "social-open":
        closeModal();
        navigate("project/" + id);
        break;
      case "social-follow": {
        const author = el.dataset.author;
        if (pending.has(author)) return;
        pending.add(author);
        try {
          await post("/follow", {
            author,
            following: !data.following.includes(author),
          });
          await reload();
          document
            .querySelectorAll('[data-action="social-follow"]')
            .forEach((btn) => {
              if (btn.dataset.author !== author) return;
              const followed = data.following.includes(author);
              btn.innerHTML = btn.classList.contains("mini-follow")
                ? icon(followed ? "check" : "plus")
                : followed
                  ? "Following"
                  : "+ Follow";
              btn.setAttribute(
                "aria-label",
                `${followed ? "Unfollow" : "Follow"} ${author}`,
              );
              btn.classList.toggle("following", followed);
            });
          toast(
            data.following.includes(author)
              ? `Following ${author}. Find their work in Following.`
              : `Unfollowed ${author}.`,
          );
          if (mode === "following") refresh();
        } finally {
          pending.delete(author);
        }
        break;
      }
      case "social-share": {
        const url = location.origin + "/#project/" + id;
        try {
          await navigator.clipboard.writeText(url);
          toast("Local project link copied. It works on this computer.");
        } catch {
          openModal(
            "Share this starting point",
            `<p>This local link works on this computer. Export the HTML from a workspace to share the app elsewhere.</p><label class="field">Project link<input readonly value="${esc(url)}"></label>`,
          );
        }
        break;
      }
    }
  }
  function doubleLike(id) {
    const p = data.projects.find((p) => p.id === id);
    if (!p) return;
    like(p, true).catch((e) => toast(e.message));
    const visual = document.querySelector(`.feed-visual[data-id="${id}"]`);
    visual?.classList.remove("burst");
    requestAnimationFrame(() => visual?.classList.add("burst"));
  }
  document.addEventListener("keydown", (e) => {
    const current = e.target.closest(".feed-tabs [role=tab]");
    if (!current || !["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key))
      return;
    e.preventDefault();
    const tabs = [...document.querySelectorAll(".feed-tabs [role=tab]")],
      index = tabs.indexOf(current);
    const next =
      e.key === "Home"
        ? 0
        : e.key === "End"
          ? tabs.length - 1
          : (index + (e.key === "ArrowRight" ? 1 : -1) + tabs.length) %
            tabs.length;
    tabs[next].focus();
    tabs[next].click();
  });
  return {
    setData,
    home,
    socialBar,
    observe,
    refresh,
    action,
    doubleLike,
    refreshReactions,
  };
}
