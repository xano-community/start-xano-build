# start-xano-build

Two agent skills that get you from **no Xano tooling** to **building on Xano** — in
any local, MCP-capable coding agent (Claude Code, Cursor, Windsurf, Cline, VS
Code/Copilot, Codex, Gemini CLI, OpenCode, and others).

Each skill is a single self-contained `SKILL.md`. They're meant to be **linked by
raw URL** — point your agent at the file and let it run the flow. Nothing here is
baked into a specific client.

---

## The two skills

### 1. `start-xano` — set up the Xano developer tools

Takes a user from "no Xano tooling" to "CLI installed and signed in, the Xano
Developer MCP live in my agent, my workspace pulled locally under git, and a clear
idea of how to work." It installs (and updates) the Xano CLI, registers the Xano
Developer MCP with whatever agent is running, signs the CLI in, restarts the agent
once so the tools load, then pulls your workspace to local files and orients you on
how everyday Xano development works.

**It reads (pulls) but never pushes or deploys anything to Xano** — changing your
workspace is your next move, on your terms.

Raw URL:

```
https://raw.githubusercontent.com/xano-community/start-xano-build/refs/heads/main/start-xano/SKILL.md
```

### 2. `start-xano-with-template` — build from a xano-community template

Owns the whole path from a fresh agent session to a working Xano backend built from
a certified **[xano-community](https://github.com/orgs/xano-community/repositories)**
item — a full app, a module, or a third-party integration. It does everything
`start-xano` does for setup, then detects Free vs paid, **always pulls the target
workspace first**, merges the template into a copy of it (so the import only ever
*adds* — nothing of yours is overwritten), previews with a dry-run, pushes only
after you approve, verifies the push landed, and for full apps deploys the frontend
to Xano static hosting.

Raw URL:

```
https://raw.githubusercontent.com/xano-community/start-xano-build/refs/heads/main/start-xano-with-template/SKILL.md
```

---

## Which one do I want?

- **Just getting set up, or want to work on your *existing* workspace?** →
  `start-xano`. It gets the tools live and pulls your workspace locally, then hands
  off to you.
- **Want to spin up something new from a community template?** →
  `start-xano-with-template`. It includes the same setup, then imports the template
  into your workspace.

You don't need both — `start-xano-with-template` covers setup on its own.

---

## Using a skill by URL

Both skills are agent-agnostic and self-contained. To run one, give your agent the
raw URL above and ask it to fetch and follow the skill, e.g.:

> Fetch and run this skill:
> https://raw.githubusercontent.com/xano-community/start-xano-build/refs/heads/main/start-xano/SKILL.md

Or install it into your agent's skills directory. For Claude Code:

```sh
mkdir -p ~/.claude/skills/start-xano
curl -fsSL \
  https://raw.githubusercontent.com/xano-community/start-xano-build/refs/heads/main/start-xano/SKILL.md \
  -o ~/.claude/skills/start-xano/SKILL.md
```

(Swap in `start-xano-with-template` for the other skill.) Other agents load skills
their own way — drop the `SKILL.md` wherever that agent reads skills from.

---

## Requirements

- **A local coding agent with shell + filesystem access**, running on *your own*
  machine — real terminal, local filesystem, editable config. A server-side/cloud
  sandbox that only runs `npm` (Claude web, ChatGPT web) does **not** qualify; each
  skill detects this and hands you local-agent options.
- **Node.js ≥ 20.12.0** — the runtime for the Xano CLI. The skill installs the CLI
  with it and helps you get Node if it's missing.
- **A Xano account** — create one during `xano auth` (choose *sign up*) if you
  don't have one.

The Xano CLI installs globally via npm; the Xano Developer MCP runs on demand via
`npx`. Because MCP servers only load at startup, both skills have you **restart your
agent once** so the Xano tools come live — that's a normal part of the first run.

---

## What's in here

```
start-xano/
  SKILL.md                     # set up the Xano dev tools; pull the workspace; orient
start-xano-with-template/
  SKILL.md                     # setup + import a xano-community template into a workspace
```
