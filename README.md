# start-xano-build

**A Claude Code skill that imports a certified
[xano-community](https://github.com/orgs/xano-community/repositories) template,
module, or third-party integration into Xano — installing the Xano CLI,
registering the Xano Developer MCP, signing you in, and building, all from one
conversation.**

You install the skill once. From then on, just tell Claude what you want to build
("start a Xano CRM", "add Stripe payments") and the skill handles the rest: it sets
up the Xano tools, has you sign in, restarts Claude once so the tools load, then
picks the right template from the live catalog and pushes it into your account.

> **Claude Code only.** Support for other tools may come later.

---

## Install the skill

Clone it into your Claude Code skills directory:

```sh
git clone https://github.com/xano-community/start-xano-build.git \
  ~/.claude/skills/start-xano-build
```

That's the whole install. The **first time you run it**, the skill installs the
Xano CLI and registers the Xano Developer MCP for you — so a one-time Claude
restart is part of that first run (Claude only loads MCP tools at startup). The
skill hands you the exact `claude --resume …` command and picks up right where it
left off.

---

## Using it

In Claude Code, just say what you want:

> start a Xano build from a template — a support ticketing app

Claude invokes the skill and walks the two acts:

**Act 1 — setup (first run):**

1. **Asks what you want to build** and whether you'll want changes after.
2. **Installs the Xano CLI** (`@xano/cli`) quietly, and **registers the Xano
   Developer MCP** with Claude Code — only whatever's actually missing.
3. **Signs you in** — you run `xano auth` in your terminal (choose *sign up* if
   you're brand new); Claude waits until it lands.
4. **Has you restart Claude once** with `claude --resume <id>` so the Xano tools
   load. (Skipped if the tools are already live.)

**Act 2 — build (resumed run):**

5. **Detects your plan** (Free vs paid) and routes the push to the right target:
   your existing **workspace** on Free, a disposable **sandbox** on paid, or a
   **fresh build**.
6. **Picks an item** from the **live xano-community catalog** (pulled from GitHub
   that run) — a full app, a module, or a third-party integration.
7. **Previews the import** with a dry-run and shows you exactly what will change.
8. **Pushes only after you say yes**, **verifies the objects actually landed**, then
   **configures and hands off** — env vars, frontend API base URL, seed data, and
   next-step links.

---

## What you'll need

- **Claude Code**, already installed and signed in.
- **A terminal** (macOS or Linux) — the sign-in step (`xano auth`) opens a browser
  and a terminal picker.
- **Node.js ≥ 20.12.0** — the skill installs the Xano CLI with it; if Node is
  missing it'll help you get it.
- **A Xano account** — create one during `xano auth` (choose *sign up*) if you
  don't have one.

The Xano CLI installs globally via npm; the Xano Developer MCP runs on demand via
`npx`. To remove them later: `claude mcp remove xano`, `npm uninstall -g @xano/cli`,
and delete `~/.claude/skills/start-xano-build`.

---

## What's supported

Whatever the **xano-community** org publishes. The skill pulls the catalog from
GitHub on **every run** (deterministically — not by summarizing a web page, which
can invent repos), so new templates and integrations show up the moment they land
in the org. Nothing is baked into the skill.

Browse everything in the org:
https://github.com/orgs/xano-community/repositories

> If GitHub's unauthenticated rate limits or curation ever become an issue, the
> skill can fetch the catalog from a proxy endpoint instead (via a
> `XANO_CATALOG_URL` set in the session) — no credentials embedded. Until then, the
> direct org listing is the source of truth.

---

## What's in here

```
SKILL.md                      # the skill — two acts, gated phases the agent follows
references/
  cli-cheatsheet.md           # the Xano CLI commands used, with a headless fallback
  templates.md                # deterministic org listing, goal→repo hints, the two layouts
```
</content>
