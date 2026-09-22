import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import http from "node:http";
import { spawn } from "node:child_process";

const document =
  "<!doctype html><html><head><title>Test app</title></head><body><h1>My first version</h1></body></html>";
let agentReply = document.replace("My first version", "Agent improvement");
const mock = http.createServer((req, res) => {
  res.setHeader("Content-Type", "application/json");
  if (req.url === "/api/tags")
    res.end(JSON.stringify({ models: [{ name: "test-model" }] }));
  else {
    req.resume();
    req.on("end", () =>
      res.end(JSON.stringify({ message: { content: agentReply } })),
    );
  }
});
await new Promise((resolve) => mock.listen(0, "127.0.0.1", resolve));
const temporary = await fs.mkdtemp(path.join(os.tmpdir(), "branch-test-"));
const reservation = http.createServer();
await new Promise((r) => reservation.listen(0, "127.0.0.1", r));
const port = reservation.address().port;
await new Promise((r) => reservation.close(r));
let child;
async function start() {
  child = spawn(process.execPath, ["server.mjs"], {
    env: {
      ...process.env,
      PORT: String(port),
      BRANCH_DATA_DIR: temporary,
      BRANCH_AGENT_URL: `http://127.0.0.1:${mock.address().port}`,
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  await new Promise((resolve, reject) => {
    child.stdout.once("data", resolve);
    child.once("error", reject);
    child.once("exit", (code) => reject(Error("Server exited: " + code)));
  });
}
async function stop() {
  const c = child;
  await new Promise((resolve) => {
    c.once("exit", resolve);
    c.kill();
  });
}
const request = async (route, method = "GET", data, headers = {}) => {
  let r = await fetch(`http://127.0.0.1:${port}${route}`, {
    method,
    headers: { "Content-Type": "application/json", ...headers },
    body: data === undefined ? undefined : JSON.stringify(data),
  });
  let text = await r.text();
  return {
    status: r.status,
    headers: r.headers,
    data: r.headers.get("content-type")?.includes("json")
      ? JSON.parse(text)
      : text,
  };
};
await start();
test("Branch project lifecycle, persistence, isolation, and agent failure handling", async (t) => {
  try {
    let forkId;
    await t.test(
      "serves six working starters and isolates previews",
      async () => {
        let r = await request("/api/projects");
        assert.equal(r.data.projects.length, 6);
        for (const p of r.data.projects) {
          const preview = await request("/preview/" + p.id);
          assert.equal(preview.status, 200);
          assert.match(preview.data, /<html/);
          assert.match(
            preview.headers.get("content-security-policy"),
            /sandbox allow-scripts/,
          );
          assert.match(
            preview.headers.get("content-security-policy"),
            /connect-src 'none'/,
          );
        }
      },
    );
    await t.test("forks independently and preserves attribution", async () => {
      let r = await request("/api/projects/nourish/fork", "POST", {
        name: "My Nourish",
      });
      assert.equal(r.status, 201);
      forkId = r.data.id;
      assert.equal(r.data.parentId, "nourish");
      assert.equal(r.data.published, false);
      assert.equal(
        (await request("/api/projects/nourish", "PATCH", { html: document }))
          .status,
        403,
      );
    });
    await t.test(
      "edits, restores, and rejects malformed HTML without losing content",
      async () => {
        let original = (await request("/api/projects/" + forkId)).data.html;
        let r = await request("/api/projects/" + forkId, "PATCH", {
          html: document,
        });
        assert.equal(r.data.revisionCount, 1);
        assert.equal(
          (
            await request("/api/projects/" + forkId, "PATCH", {
              html: "broken",
            })
          ).status,
          400,
        );
        assert.equal(
          (await request("/api/projects/" + forkId)).data.html,
          document,
        );
        assert.equal(
          (await request("/api/projects/" + forkId + "/restore", "POST", {}))
            .data.html,
          original,
        );
      },
    );
    await t.test(
      "uses agent output and preserves last version on invalid model output",
      async () => {
        assert.equal(
          (await request("/api/agent")).data.models[0],
          "test-model",
        );
        let r = await request(`/api/projects/${forkId}/agent`, "POST", {
          prompt: "Improve the heading",
          model: "test-model",
        });
        assert.equal(r.status, 200);
        assert.match(r.data.html, /Agent improvement/);
        agentReply = "Sorry, I cannot return HTML";
        r = await request(`/api/projects/${forkId}/agent`, "POST", {
          prompt: "Improve it",
          model: "test-model",
        });
        assert.equal(r.status, 400);
        assert.match(
          (await request("/api/projects/" + forkId)).data.html,
          /Agent improvement/,
        );
      },
    );
    await t.test(
      "publishes, bookmarks, exports, and proposes a snapshot",
      async () => {
        assert.equal(
          (await request(`/api/projects/${forkId}/publish`, "POST", {})).data
            .published,
          true,
        );
        assert.equal(
          (await request(`/api/projects/${forkId}/save`, "POST", {})).data
            .saved,
          true,
        );
        let r = await request(`/api/projects/${forkId}/contribute`, "POST", {
          title: "Improved heading",
        });
        assert.equal(r.status, 201);
        assert.equal(r.data.parentId, "nourish");
        assert.equal(r.data.status, "proposed");
        const proposalId = r.data.id;
        await request(`/api/projects/${forkId}`, "PATCH", { html: document });
        const snapshot = await request(`/proposal/${proposalId}`);
        assert.equal(snapshot.status, 200);
        assert.match(snapshot.data, /Agent improvement/);
        assert.match(
          snapshot.headers.get("content-security-policy"),
          /sandbox allow-scripts/,
        );
        assert.equal(
          (await request("/api/projects")).data.contributions[0].html,
          undefined,
        );
        await request(`/api/projects/${forkId}/restore`, "POST", {});
        assert.match(
          (await request(`/api/projects/${forkId}/export`)).data,
          /Agent improvement/,
        );
      },
    );
    await t.test(
      "rejects cross-origin mutations and oversized input",
      async () => {
        assert.equal(
          (
            await request(
              `/api/projects/${forkId}/publish`,
              "POST",
              {},
              { Origin: "https://untrusted.example" },
            )
          ).status,
          403,
        );
        assert.equal(
          (
            await request("/api/projects", "POST", {
              name: "Huge",
              description: "Huge",
              html: "x".repeat(1_200_000),
            })
          ).status,
          413,
        );
      },
    );
    await t.test("imports a complete HTML project", async () => {
      let r = await request("/api/projects", "POST", {
        name: "Imported app",
        description: "A functional HTML import",
        category: "Productivity",
        html: document,
      });
      assert.equal(r.status, 201);
      assert.equal(r.data.published, true);
      assert.equal(r.data.category, "Productivity");
    });
    await t.test("likes are idempotent and can be removed", async () => {
      let r = await request("/api/projects/nourish/like", "POST", {
        liked: true,
      });
      assert.equal(r.data.likes, 1);
      assert.equal(r.data.liked, true);
      r = await request("/api/projects/nourish/like", "POST", { liked: true });
      assert.equal(r.data.likes, 1);
      r = await request("/api/projects/nourish/like", "POST", { liked: false });
      assert.equal(r.data.likes, 0);
      assert.equal(
        (await request("/api/projects/nourish/like", "POST", { liked: "yes" }))
          .status,
        400,
      );
      await request("/api/projects/nourish/like", "POST", { liked: true });
    });
    await t.test(
      "star ratings replace instead of accumulate and reject invalid values",
      async () => {
        assert.equal(
          (await request("/api/projects/nourish/rating", "POST", { rating: 5 }))
            .data.rating,
          5,
        );
        let r = await request("/api/projects/nourish/rating", "POST", {
          rating: 3,
        });
        assert.equal(r.data.rating, 3);
        assert.equal(r.data.ratingCount, 1);
        assert.equal(
          (await request("/api/projects/nourish/rating", "POST", { rating: 0 }))
            .data.ratingCount,
          0,
        );
        for (const rating of [-1, 6, 2.5, "5"])
          assert.equal(
            (await request("/api/projects/nourish/rating", "POST", { rating }))
              .status,
            400,
          );
        await request("/api/projects/nourish/rating", "POST", { rating: 5 });
      },
    );
    await t.test(
      "comments persist as plain text, count correctly, and reject empty or oversized input",
      async () => {
        let r = await request("/api/projects/nourish/comments", "POST", {
          text: "A useful start — <b>keep this text literal</b> 🌱",
        });
        assert.equal(r.status, 201);
        assert.equal(r.data.project.commentCount, 1);
        assert.equal(r.data.comment.author, "You");
        const comments = (await request("/api/projects/nourish/comments")).data
          .comments;
        assert.equal(comments.length, 1);
        assert.match(comments[0].text, /<b>/);
        for (const text of ["", "   ", "a".repeat(1001)])
          assert.equal(
            (await request("/api/projects/nourish/comments", "POST", { text }))
              .status,
            400,
          );
      },
    );
    await t.test(
      "follows and interests validate creator and category identities",
      async () => {
        let r = await request("/api/follow", "POST", {
          author: "Sophie Chen",
          following: true,
        });
        assert.deepEqual(r.data.following, ["Sophie Chen"]);
        r = await request("/api/follow", "POST", {
          author: "Sophie Chen",
          following: true,
        });
        assert.equal(r.data.following.length, 1);
        assert.equal(
          (await request("/api/projects/nourish")).data.following,
          true,
        );
        await request("/api/follow", "POST", {
          author: "Sophie Chen",
          following: false,
        });
        assert.equal(
          (await request("/api/projects/nourish")).data.following,
          false,
        );
        assert.equal(
          (
            await request("/api/follow", "POST", {
              author: "Unknown creator",
              following: true,
            })
          ).status,
          400,
        );
        assert.equal(
          (
            await request("/api/follow", "POST", {
              author: "You",
              following: true,
            })
          ).status,
          400,
        );
        assert.equal(
          (
            await request("/api/preferences", "POST", {
              interests: ["Not a category"],
            })
          ).status,
          400,
        );
        r = await request("/api/preferences", "POST", {
          interests: ["Productivity", "Productivity", "Finance"],
        });
        assert.deepEqual(r.data.interests, ["Productivity", "Finance"]);
        await request("/api/follow", "POST", {
          author: "Sophie Chen",
          following: true,
        });
      },
    );
    await t.test("survives a server restart", async () => {
      await stop();
      await start();
      let r = await request("/api/projects");
      assert.equal(r.data.projects.length, 8);
      const social = r.data.projects.find((p) => p.id === "nourish");
      assert.equal(social.liked, true);
      assert.equal(social.rating, 5);
      assert.equal(social.commentCount, 1);
      assert.deepEqual(r.data.following, ["Sophie Chen"]);
      assert.deepEqual(r.data.interests, ["Productivity", "Finance"]);
      assert.ok(r.data.projects.find((p) => p.id === forkId).saved);
      assert.equal(r.data.contributions.length, 1);
      assert.ok(r.data.activity.length >= 5);
    });
  } finally {
    await stop();
    await new Promise((resolve) => mock.close(resolve));
    await fs.rm(temporary, { recursive: true, force: true });
  }
});
