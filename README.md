# start-xano-build

**One terminal command opens Claude Code — with the Xano CLI installed and
authenticated and the Xano Developer MCP registered — ready to import or add a
certified [xano-community](https://github.com/orgs/xano-community/repositories)
template, module, or third-party integration into Xano.**

All the setup that used to be flaky (installing the CLI, logging in, wiring up
the MCP) now happens **in your terminal, before Claude starts**. By the time the
agent is running, everything it needs is already in place — so it can focus on
the Xano workflow instead of fighting its own environment.

> **v1 is Claude Code only.** Support for other tools may come later.

---

## Quick start

Paste this into your terminal:

```sh
tmp="$(mktemp)" && curl -fsSL https://raw.githubusercontent.com/xano-community/start-xano-build/main/start.sh -o "$tmp" && bash "$tmp"; rm -f "$tmp"
```

That's it. The script downloads to a temp file and runs it (rather than
`curl | bash`) so the interactive `xano auth` step gets a real terminal.

### What the command does, in order

1. **Installs the skill** into `~/.claude/skills/start-xano-build` (or updates it
   if already there).
2. **Ensures Claude Code** is installed.
3. **Ensures Node.js** ≥ 20.12.0 — installing a **private** copy if you don't
   have a suitable one, without touching your shell profile.
4. **Installs the Xano CLI and Xano Developer MCP** into a private location under
   `~/.xano-community/start-xano-build/`, behind stable wrapper commands (no
   global `npm install`).
5. **Authenticates the Xano CLI** — runs `xano auth` in the foreground and waits
   for you to finish the browser login and pick your instance. Brand new? Choose
   **sign up** on that page and you'll come back authenticated.
6. **Registers the Xano Developer MCP** with Claude Code at user scope, so it's
   available in every project — not just wherever you ran this.
7. **Launches Claude Code** with an initial prompt that starts the build.

Then Claude asks what you want to build and where it should land.

---

## What you'll need

The bootstrap sets these up for you — listed so you know what it touches:

- **A terminal** (macOS or Linux).
- **`git`** and **`curl`** already present (standard on most machines).
- **Node.js ≥ 20.12.0** — a private copy is installed if you don't have one.
- **A Xano account** — create one during `xano auth` (choose *sign up*) if you
  don't have one yet.
- **Claude Code** — installed for you if missing.

Everything Xano-related installs under `~/.xano-community/start-xano-build/` and
can be removed by deleting that directory (plus the `xano` MCP entry via
`claude mcp remove xano` and the skill at `~/.claude/skills/start-xano-build`).

---

## What Claude does once it's running

The skill (`SKILL.md`) owns the **Xano workflow**, not setup. It:

1. **Verifies the bootstrap state** — MCP tools present, Xano CLI installed and
   authenticated. If anything's missing, it stops and tells you to rerun the
   command above (it never tries to install or register things mid-session).
2. **Detects your plan** (Free vs paid) and routes the push to the right target:
   your existing **workspace** on Free, a disposable **sandbox** on paid, or a
   **fresh build**.
3. **Picks an item** from the **live xano-community catalog** (pulled from GitHub
   that run) — a full app, a module, or a third-party integration.
4. **Previews the import** with a dry-run and shows you exactly what will change.
5. **Pushes only after you say yes**, then **verifies the objects actually
   landed** — never reporting success off a dry-run alone.
6. **Configures and hands off** — env vars, frontend API base URL, seed data, and
   next-step links.

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
> `XANO_CATALOG_URL` the bootstrap sets) — no credentials embedded in the public
> script. Until then, the direct org listing is the source of truth.

---

## What's in here

```
start.sh                      # the terminal bootstrap (installs, authenticates, launches Claude)
SKILL.md                      # the skill — six gated phases the agent follows
references/
  cli-cheatsheet.md           # the Xano CLI commands used, with a headless fallback
  templates.md                # deterministic org listing, goal→repo hints, the two layouts
```

## Manual install

Prefer to set up the skill yourself? Clone it into your Claude Code skills
directory:

```sh
git clone https://github.com/xano-community/start-xano-build.git \
  ~/.claude/skills/start-xano-build
```

You'll still need the Xano CLI installed and authenticated and the Xano Developer
MCP registered before the skill can run — which is exactly what `start.sh`
automates. Running the one-paste command above is the supported path.
