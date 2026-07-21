---
name: start-xano-with-template
description: >-
  Import or add a certified xano-community template, module, or third-party
  integration into a user's Xano workspace, from any local MCP-capable coding agent.
  Use when a user wants to spin up, scaffold, import, install, or "start a Xano
  build/app/backend from a template," add a module, or wire in a supported integration.
  It owns the whole path from a fresh agent session: installs (and updates) the Xano
  CLI, registers the Xano Developer MCP with whatever MCP-capable agent is running
  (Claude Code, Cursor, Windsurf, Cline, VS Code/Copilot, Codex, and any other via the
  standard mcpServers config), and helps authenticate the CLI (including creating a
  brand-new Xano account) — then, because MCP servers only load at startup, has the
  user restart the agent once so the Xano tools come live. After the restart it detects
  Free vs paid, always pulls the target workspace first, merges the template into a copy
  of it (so the import only ever *adds*), previews with a dry-run, pushes only after
  explicit approval — Free straight to the workspace, paid staged in the sandbox and
  promoted — verifies the push landed, and for full apps deploys the frontend to Xano
  static hosting. Every state change goes through the Xano CLI; it never calls the Xano
  Metadata REST API directly. Requires a local agent with shell access. The catalog of
  supported items is pulled live from the xano-community org on every run — never from
  an embedded list.
---

# Start a Xano build from a xano-community template

This skill takes a user from a fresh agent session to a working Xano backend built from
a supported **[xano-community](https://github.com/orgs/xano-community/repositories)**
item — a full app, a module, or a third-party integration. It is **agent-agnostic**
(Claude Code, Cursor, Windsurf, Cline, VS Code/Copilot, Codex, and others). Run the
phases **in order** — each one gates the next. Don't skip a phase because it "looks"
done; verify it.

The run has **two acts**, split by one unavoidable restart:

- **Act 1 — Setup (this session):** greet + capture intent, install/update the Xano
  CLI, register the Xano Developer MCP with the agent, and authenticate the CLI. Then
  have the user **restart the agent once**, because MCP servers only load at startup.
- **Act 2 — Build (the resumed session):** verify the tools are live, detect the plan,
  pull the target workspace, pick an item from the **live catalog**, merge + preview,
  push after approval, verify, deploy the frontend, then orient the user on how to keep
  building and ask what's next.

**The restart is always required** the first time through — even for an import-only
build — because the whole workflow relies on the Xano tools being loaded. The **one
exception:** if the Xano MCP tools are *already* present in this session (a warm session,
or you're resuming after the restart), skip registration and the restart and go on.

**Principle — transparency and trust.** This is the user's real Xano account and
machine. Narrate each step in plain terms (what and why) before you do it, show what
you're about to install, pull, change, or push, and never touch their account silently.

## Two rules that define this skill

1. **CLI only — never the Metadata REST API.** Every change to the user's Xano account
   goes through the `xano` CLI. Never hand-roll HTTP calls to `https://<host>/api:meta/...`,
   and never scrape the access token out of `~/.xano/credentials.yaml` to authenticate a
   raw request. The Xano Developer MCP is expected (docs + XanoScript validation); its
   `xano_meta_api_docs` tool is *documentation about* the Meta API, not a way to call it.
2. **Agent-agnostic.** Register the MCP with the standard `mcpServers` config block, and
   phrase the restart as "restart your agent," not "restart Claude."

## Prerequisite — a local agent with shell + filesystem access

**This only works from a coding agent on the user's *own* machine** — real terminal, local
filesystem, editable config. Every phase needs it (installs, `xano` commands, writing the MCP
config, restarting to load, cloning, pushing/pulling code, deploying a frontend).

**A shell alone isn't enough — confirm it's *their* machine.** A server-side/cloud sandbox
that happens to run `npm` (Claude web, ChatGPT web) does **not** qualify: it wipes after the
task, has no local agent config to register into, and can't open the user's browser or reach
their Xano instance. Tells you're not on their machine: nothing persists, the home dir/config
isn't theirs, or the network reaches npm/GitHub but not the open web or xano.com. If any hold
— **even if `npm` works** — **stop and hand them local-agent options** (installing here only
helps inspect `xano --help`/versions, never real setup), and **lead with the option closest
to where they are** (name their context in "from here"):

- **From ChatGPT** → lead with the ChatGPT desktop app, then Codex CLI ("…from here in ChatGPT").
- **From Claude (web)** → lead with Claude Code.
- **From Gemini (web)** → lead with the Gemini CLI (or Gemini Code Assist in VS Code).
- **An unrecognized web/hosted agent** → if it has a known local or desktop version, lead
  with that (name it); otherwise offer the general local options below.
- **Otherwise** → any local agent; use the order below.

**Don't hardcode install links — they go stale.** Name the options; if you can look up the
current official download/install page (e.g. a quick web search), add fresh links inline
then. Otherwise just name each and, if useful, tell the user what to search for.

**Defined message** (reorder the bullets so the most relevant is first; drop in current
links where you have them):

> Setting up Xano has to run on your own computer, from a local coding agent — I can't do
> it from here. Open one of these on your machine and run the setup there:
>
> • **ChatGPT desktop app** — run Codex in **Local mode** with your project folder open (so
>   it works on your computer, not the cloud) and let it run commands + write files; then
>   paste the skill in and run it
> • **Codex CLI** — OpenAI's terminal coding agent (`npm i -g @openai/codex`)
> • **Gemini CLI** — Google's terminal coding agent (`npm i -g @google/gemini-cli`)
> • **OpenCode** — open-source terminal agent that works with any model (`npm i -g opencode-ai`)
> • **Claude Code, Cursor, or VS Code** (with an agent extension)
>
> Once you've got one open, paste in the skill and run it there.

## Guardrails

- **The user's own machine — check first.** Not on the user's machine → stop (see
  *Prerequisite*). A shell alone isn't enough — a server-side sandbox that can run `npm`
  still doesn't qualify; it needs *their* terminal, filesystem, agent config, and browser.
- **This skill owns setup, but installs quietly.** Installing/updating the CLI,
  registering the MCP, and authenticating are its job — run them **silently** (redirect
  install output to `/dev/null`). Never dump npm's log into the chat.
- **The restart is a hard gate.** Once the MCP is registered, its tools can't be used
  until the agent restarts. Don't attempt the Xano workflow (Act 2) until the tools are
  present, and **never restart the agent yourself** — only the human can.
- **Confirm before anything outward-facing or destructive.** Installing tools,
  authenticating, pushing code, setting env vars, deploying, and seeding data touch the
  user's machine or account. Say what you're about to do and get a clear go-ahead.
- **Confirm database changes twice.** A template import *is* a DB change (creates tables,
  fields, indexes). Get the user's explicit OK before you build the change locally and again
  at the dry-run before you push/promote — the preview → approve → push flow is how. Never a
  schema change or push unprompted.
- **Every push is preview → approve → push.** Run `--dry-run` first and show the planned
  changes. Get an explicit "yes" in chat. Only then run the real push (with `--force`,
  needed for the non-interactive shell, and only after approval). **Never push unprompted.**
- **Review & Push is manual, in the Xano browser UI — you never do it.** Promoting the
  sandbox into the workspace is a button the *user* clicks on the sandbox review page; there's
  no CLI command and you can't do it for them. Any time a change is staged in the sandbox
  (import or a follow-on edit), **open a fresh review right then** — run `xano sandbox review`
  (no `--url-only`), which opens the review in their browser on their own machine; the session
  token expires, so always run it fresh, never reuse an old link. Tell them plainly it's a
  manual step in their browser, have them click **Review & Push** themselves, then verify it
  landed.
- **Validate before pushing.** Validate every XanoScript change with
  `xano_validate_xanoscript`; treat the `--dry-run` as the final gate.
- **Auth: the user runs `xano auth` in their own real terminal — you never run it.** The
  interactive picker needs a TTY the agent shell lacks, so it hangs if you run/background it
  (via Bash tool or `!`). Point them to a separate terminal window (or their editor's built-in
  terminal), then poll `xano profile me` until it lands. (Can't open one? Fall back to the
  agent-run `--code` flow — Phase 1.)
- **Run commands in the IDE terminal, in the right folder.** Everything but `xano auth`
  uses relative paths (`-d ./<workspace>-<template>`, etc.), so run it from the working
  folder you have open, in the IDE's integrated terminal — not an unrelated directory, or the
  paths won't resolve. If you surface a command for the *user*, point them to their IDE
  terminal at that folder (and open it there if your software can).
- **Be plan-aware.** Detect Free vs paid (Phase 4). The **Free plan is named `build`**
  internally (`package.name: "build"`); treat `build` (or workspace entitlement `1`) as
  Free. Paid uses the sandbox; the paid direct workspace push is off by default (below).
- **Never push the template alone.** Always push a combined tree (existing workspace +
  template) so a sync/promotion can't delete the user's work (Phase 6).
- **The live catalog is the source of truth.** Fetch it from GitHub each run with a
  **deterministic** command — never a summarizing web fetch, which fabricates repos.
  Verify a repo exists (HTTP 200) before cloning.
- **Don't maintain plan-gated feature lists.** If a push is rejected for a missing
  feature, read the error, exclude what it names with `-e`, retry, and say what was
  skipped. On Free, pre-exclude the gaps `rolePermissions` shows (commonly
  `workspace:workflow_test`).
- **Never invent IDs or instance URLs.** Read them from `xano workspace list`,
  `xano profile me`, or command output.
- **Prefer the MCP docs tools over memory.** For exact CLI flags or XanoScript syntax,
  call `xano_cli_docs` and `xano_xanoscript_docs` (and `xano_meta_api_docs` only to
  *read* about the Meta API, never to call it). Or `xano <cmd> --help`.
- **Say the same thing every run.** Every question/notice below has **defined wording** —
  use it verbatim (fill in values, keep structure).
- **Always tell the user which local folder you're pushing from**, by its real name.
- **Never guess or construct a browser link — the API host is not the dashboard host.** The
  instance's API/data host (`extras.instance.xano_domain`/`host`, e.g. `x8ki-...xano.io`) is
  **not** where the workspace UI lives (that's a different domain, e.g. `fast.dev123.io`), so
  **never build `https://<api-host>/workspace`** — it's wrong. No CLI command returns the
  workspace's browser URL, so **don't fabricate one.** You *can* give the **API base URL**
  (built from the API host — clearly an endpoint, not the dashboard) and the Xano **dashboard
  root** (`app.xano.com`). For the **sandbox**, the real browser link comes only from `xano
  sandbox review` — never guessed.
- **After a change reaches the workspace, tell them where to find it — no guessed link.** For
  the import and any follow-on change, never stop at "done." Point them to **`app.xano.com`**
  and name **which instance** (from `xano profile me`), **which workspace** (`<name> (<id>)`),
  and **where the change lives** — the exact spot to check, e.g. "Functions → create_event_log",
  "the `applicant` table", or "the Onboarding API group". Add the affected endpoint's live
  **API URL** when relevant. Give a clear path to check it, never a fabricated URL.

## Output discipline — explain the plan, not the plumbing

The user should always understand **what is happening and why** — most are not
developers. Narrate the *intent* of each step in one or two plain sentences before you do
it, and say the plain-language *outcome* after. Suppress the mechanics: never paste
install logs or raw JSON, never narrate individual tool calls ("Now I'll run…"), no
filler. A non-technical user reading only your prose should always know what just
happened, what's happening now, and what (if anything) they need to do.

---

## Phase 0 — Greet, introduce the flow, capture intent

Open with a short, friendly greeting that **previews the flow** (connect the Xano tools →
pull in the chosen template → merge it into their workspace without overwriting anything →
build on it together) and settles intent — the **template** and whether to **import as-is or
modify**. **Skip any question the user already answered in their prompt** (a named template,
"just import it"). Intent survives the restart via the transcript; don't expand this into a
questionnaire.

**If nothing's specified yet — defined greeting:**

```
Hi! I'll build a Xano backend for you from a community template and set it up right in your
workspace. Here's how it'll go: I'll connect the Xano tools to this agent, pull in the
template you pick, merge it into your workspace (nothing of yours gets overwritten), and then
we can build on it together.

Two quick things first:

  1. What do you want to build? Name a xano-community template, or describe the goal
     (e.g. "a CRM", "accept payments", "send emails") and I'll match it to one.
  2. Import it as-is, or make changes after it's in? Either's fine.

Heads up: a one-time restart of your agent happens partway through to load the Xano tools —
nothing to prep, I'll walk you through it.
```

**If the template (or more) is already in their prompt** — don't re-ask; acknowledge it, give
the same quick flow preview, and ask only what's still open:

```
Got it — I'll set you up with "<template>". Here's how it'll go: I'll connect the Xano tools
to this agent, pull in <template>, merge it into your workspace (nothing of yours gets
overwritten), and then we can build on it together. One quick agent restart happens partway
through — I'll walk you through it.

[Only if they didn't already say:] Want it imported as-is, or should we make changes after
it's in?
```

If both the template and as-is/modify are already given, drop the trailing question and go
straight to setup.

You confirm the exact repo against the live catalog in Phase 5 (so a named template is
verified, never cloned blindly). **Where it lands** is derived from the plan (Phase 4), not
asked here.

---

## Phase 1 — Set up the tools (install/update quietly, then authenticate)

**First, confirm you're a local agent with shell access** (*Prerequisite*).

**Then check what's here** — presence **and** version; don't reinstall what's present,
but update what's behind (a stale CLI/MCP is how you end up on wrong docs). If the Xano
MCP tools (`xano_validate_xanoscript`, `xano_cli_docs`, `xano_xanoscript_docs`) are
already available **and** `xano profile me` succeeds **and** both are current, Act 1 is
done — skip to Phase 3.

```sh
node --version        # need >= 20.12.0
xano --version        # is the CLI installed?
xano profile me       # is it authenticated?
xano update --check   # is the CLI outdated? (checks npm; doesn't install)
```

Check the MCP version too (its `xano_version` tool, or `npm view @xano/developer-mcp
version` vs `npx -y @xano/developer-mcp@latest --version`).

### Install confirmation (defined wording)

Present only what's **missing or outdated**, labeling each *install* or *update*, and get
**one** go-ahead (swap "install"→"update" for a piece that's just behind):

```
To build this I need to set up a couple of things first:

  • Node.js ≥ 20.12.0     — runtime for the Xano CLI                       (install)
  • Xano CLI (@xano/cli)  — pushes the template into your Xano account      (update — yours is behind)
  • Xano Developer MCP    — validates changes and loads Xano's docs         (install)

I'll install/update these quietly and register the MCP with your agent. Okay to go
ahead? (yes / no)
```

On "yes", do it **silently**:

```sh
npm install -g @xano/cli >/dev/null 2>&1        # install the CLI (if missing)
xano update >/dev/null 2>&1                      # update the CLI (if outdated)
```

### Register the Xano Developer MCP (agent-agnostic)

Standard MCP server: `npx -y @xano/developer-mcp`. Detect the running agent (or ask), then
register the server named `xano-developer` the native way. If it already exists, leave it
— **unless outdated**: re-register with `@xano/developer-mcp@latest`.

```json
{ "mcpServers": { "xano-developer": { "command": "npx", "args": ["-y", "@xano/developer-mcp"] } } }
```

| Agent / client        | How to register                                                            |
|-----------------------|----------------------------------------------------------------------------|
| **Claude Code**       | `claude mcp add --scope user xano-developer -- npx -y @xano/developer-mcp`  |
| **Cursor**            | `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project)               |
| **Windsurf**          | `~/.codeium/windsurf/mcp_config.json`                                       |
| **Cline**             | Cline `cline_mcp_settings.json`                                             |
| **VS Code / Copilot** | `.vscode/mcp.json`                                                          |
| **Codex**             | `[mcp_servers.xano-developer]` table in `~/.codex/config.toml` (**TOML**, not JSON) |
| **Gemini CLI**        | `~/.gemini/settings.json` (global) or `.gemini/settings.json` (project)     |
| **OpenCode**          | the `mcp` object in `opencode.json` (**different schema** — below)          |
| **Claude Desktop**    | `claude_desktop_config.json`                                               |
| **Any other**         | that client's MCP config file                                              |

Codex TOML (`~/.codex/config.toml`):
```toml
[mcp_servers.xano-developer]
command = "npx"
args = ["-y", "@xano/developer-mcp"]
```

OpenCode (`opencode.json` — `mcp` object, `type: "local"`, `command` array):
```json
{ "mcp": { "xano-developer": { "type": "local", "command": ["npx", "-y", "@xano/developer-mcp"], "enabled": true } } }
```

**Unrecognized agent?** Most MCP clients take the standard `mcpServers` block, but some use
their own schema (Codex is TOML, OpenCode is `mcp` / `type: "local"`) — so **check the
agent's own MCP docs** for the config file and format rather than assuming. If you still
can't place it, show the user the standard block, name the two exceptions, and ask them to
add it per their agent's docs.

### Authenticate the CLI (defined wording)

Skip only if `xano profile me` already succeeded above (a pre-existing profile). Otherwise
have the **user run `xano auth` in their own real terminal — never through you** (not Claude
Code's `!`, not your Bash tool): the interactive picker needs a TTY and will hang in the
agent's shell. **Tell them which terminal, matched to the running agent:**

- **Terminal agents** (Claude Code, Codex CLI, Gemini CLI, OpenCode) → a **new terminal
  tab/window** (their current one is running you).
- **IDE agents** (VS Code, Cursor, Windsurf) → the editor's **built-in terminal** (View →
  Terminal).
- **Anything else** → any terminal on their machine.

**Send this verbatim** — substitute only the `<terminal>` phrase, and **include the literal
`xano auth` command in the message you send** (never paraphrase it or reference it as "the
command above" / "as shown above" — the user must see the command right there):

```
Let's sign you in to Xano. Open <a new terminal tab / your editor's built-in terminal>, make
sure you're in this project folder, and run:

    xano auth

Finish the browser login (choose **Sign up** if you're new), then pick your instance and
create a profile when it prompts. Tell me when you're done and I'll verify.
```

Then **poll** `xano profile me` until it succeeds or the ~5-minute window elapses.

> **Can't open a separate terminal (or prefer not to)?** One-shot `--code` flow, which *you*
> run non-interactively: send the user to `https://app.xano.com/login?dest=cli&display=code`,
> they paste back the code, and you run `xano auth --code "<code>" --json` (one instance
> auto-selects; several → the `--json` error lists them, retry `-i <instance>`). No browser
> (SSH/CI): `xano profile create <name> -i <origin> -t <token> -w <id> --default`.

---

## Phase 2 — Restart the agent to load the Xano tools

**Skip if the Xano MCP tools are already present** (warm/resumed session) — go to Phase 3.

Otherwise the MCP was just registered and its tools aren't loaded. **Only the human can
relaunch the agent.** **Defined instruction:**

```
Setup's done. One quick restart loads the Xano tools, then I'll build — no need to re-run
anything.

Restart your agent so it picks up the Xano MCP server, then come back to this
conversation and I'll pick up automatically.
```

Add the matching restart line:
- **Claude Code:** `Quit, and from this same folder run:  claude --resume ${CLAUDE_SESSION_ID}` (not `--continue`).
- **Cursor / Windsurf / VS Code / Cline:** `Reload the window (or toggle the MCP server off/on) so the Xano server starts.`
- **Codex:** `Exit and start a new codex session (it loads MCP servers at startup).`
- **Gemini CLI:** `Exit and start a new gemini session (it loads MCP servers from settings.json at startup).`
- **OpenCode:** `Exit and start a new opencode session (it loads MCP servers from opencode.json at startup).`
- **Other agents:** `Fully restart the agent so it loads the new MCP server.`

Credentials persist in `~/.xano/credentials.yaml` across the restart. Stop here — next is
Phase 3, in the resumed session.

---

## Phase 3 — Verify the Xano tools are live

First step after the resume. Confirm the MCP tools are present and `xano profile me` still
succeeds.

- **Present + authenticated** → continue to Phase 4.
- **Still missing** → the restart didn't take. Confirm the MCP is registered (Claude Code:
  `claude mcp list`; others: check the config file), re-add if missing, re-issue the Phase
  2 instruction, and stop.

---

## Phase 4 — Detect the plan and choose the target

**Checking your plan…** Read the profile once:

```sh
xano profile me -o json
```

Use the **authoritative fields** under `extras.instance`:
- **Plan** — `package.name` (display it; **`build` = Free**, surface as "Free (build plan)").
- **Workspace entitlement** — `k8s.additional.workspaces`: **`1` → Free, `> 1` → paid** (decisive).
- **Feature permissions** — `membership.rolePermissions` / `access_token.scope`: per-feature
  keys like `workspace:workflow_test`; missing means the plan lacks it.

Fallback if absent: count `xano workspace list`, and/or `xano sandbox get` (provisions on
paid, errors on Free — sandbox is paid-only). If unsure, ask.

**Route the target:**

- **Paid → ask which workspace first, *then* connect and pull.** Paid users can build into
  an existing workspace **or** a new one (creating one uses a slot). List them
  (`xano workspace list`) and count them.
  - **Has more than one workspace → recommend a *new* one**, but make clear it's their call
    (they can merge into an existing workspace instead). Lead with the recommendation —
    **defined question:**
    ```
    You're on a paid plan with a few workspaces. I'd recommend building this into a **new
    workspace** — it keeps the template cleanly isolated, with no chance of touching your
    existing work. But it's your call. Where should it go?

      • A new workspace (recommended) — give me a name and I'll create it.
      • An existing workspace — I'll merge it in alongside what's already there:
          <name> (<id>)
          <name> (<id>)
    ```
  - **Has just one workspace → skip the recommendation**, simply ask new vs. that one:
    ```
    You're on a paid plan. I can build this into a new workspace (kept separate) or into
    your existing "<name>". Which would you prefer?
    ```
  Then route the answer:
  - **New** → `xano workspace create "<name>"` (paid only); capture the new id. Empty, so
    no collisions — you'll skip the Phase 6 collision check.
  - **Existing** → that id is the destination (the Phase 6 merge + collision handling
    protects their existing work either way).

  Either way the template is **staged in the sandbox and promoted into the chosen
  workspace** (Phase 7): `xano sandbox get`. **Note:** a paid direct `xano workspace push`
  is **off by default** (safety); the sandbox → **Review & Push** promotion is the path,
  and it doesn't need that setting. (If a paid user insists on direct push, it's rejected
  until they enable "allow CLI push" in workspace settings / `xano workspace edit -w <id>
  --allow-push` — recommend the sandbox instead.)
- **Free → their one existing workspace.** Free can't create workspaces or use the sandbox;
  direct push works for Free. `xano workspace list` → take the id.

**Pre-flag gated features** the plan lacks (commonly `workspace:workflow_test` on Free);
carry them as `-e` excludes into both the dry-run and the real push in Phase 6/7.

### Always pull the target workspace first (every plan tier, every time)

**Pull a snapshot of the target workspace to disk before importing anything — on *every*
plan tier: Free, Essential, Scale, Pro.** Plan tier only changes where the push goes, never
whether you pull first. Even a brand-new/empty workspace gets pulled. Tell the user why
("downloading what's already in your Xano so the import only adds the template and never
overwrites your work").

```sh
xano workspace pull -d ./workspace -w <id> --env   # --env captures env vars too
```

`--env` pulls env vars into the snapshot so they ride along in the combined push and a
mirror-promotion can't wipe them. **These files now hold secret values** — treat
`./workspace` and the combined folder as sensitive: don't commit them, clean up after.
New/empty workspace → the pull confirms there's nothing there → skip the Phase 6 collision
check.

This snapshot is (1) the **base of the combined push** (Phase 6 merges the template into a
copy of it — pushing the template alone would let a promotion/sync **delete** the user's
work), (2) the source of the workspace's **API base URLs** (canonical slugs in
`api/<group>/api_group.xs`), and (3) confirmation you're on the right account (surface the
name/id). Note the **destination workspace** id — Phases 6–7 use it.

---

## Phase 5 — Pull the live catalog and pick an item

**Picking a template…** **Fetch the catalog from GitHub every run — no embedded list.** Use
a **deterministic** command; never a summarizing web fetch (it fabricates repos).

1. **List the org's repos.** Templates live in **xano-community**:
   ```sh
   gh repo list xano-community --limit 200                       # preferred
   curl -fsSL "https://api.github.com/orgs/xano-community/repos?per_page=100" | jq -r '.[].name'   # no gh
   ```
   > **Proxy hook:** if `XANO_CATALOG_URL` is set, fetch that instead (same shape).
2. **Match intent → repo.** `integration-*` repos are third-party integrations; the rest are
   full apps / modules. Hints (confirm against the live list; names can change): todo →
   `todo-app`; tickets → `support-ticketing`; intake → `client-intake`; approvals →
   `purchase-approvals`; asset tracking → `asset-tracking`; payments →
   `integration-stripe-payments` / `-square-payments` / `-paypal-payments`; email →
   `integration-resend-email` / `-mailchimp-email`; SMS → `integration-twilio-sms`; Slack/
   Discord → `integration-slack-messaging` / `-discord-messaging`; CRM →
   `integration-hubspot-crm` / `-salesforce-crm`; AI → `integration-openai-ai` /
   `-gemini-ai`. If several fit, show a numbered shortlist and let the user pick. If nothing
   fits, say so and show what the org actually has — don't guess.
3. **Verify the repo exists (HTTP 200) before cloning:**
   ```sh
   gh api repos/xano-community/<repo> >/dev/null   # or:
   curl -s -o /dev/null -w '%{http_code}\n' https://github.com/xano-community/<repo>
   ```
4. **Read the repo's `README.md`** — its **Install** section is the source of truth for
   which directory to push, required env vars, whether there's a frontend, and any seed
   endpoint.

---

## Phase 6 — Merge the template into the workspace, then preview

Get the code on disk:

```sh
git clone https://github.com/xano-community/<repo>.git && cd <repo>
# or: xano workspace git pull -r https://github.com/xano-community/<repo>.git -d ./<repo>
```

**Two layouts** (README's Install section is authoritative): **full apps** push `backend/`
(and ship a `frontend/index.html` with an `API_BASE` constant, plus a `multidoc/` bundle);
**integrations** push the repo root (`functions/`, `tables/`, `.env.example`).

### Build the combined push (existing workspace + template) — never push the template alone

**Read this — it prevents data loss.** Both push paths *replace*, not append: paid's
**Review & Push** makes the workspace **mirror the sandbox** (anything not in the sandbox is
deleted), and a Free full/sync push of the template alone would drop existing objects. So
you push a **merged tree — the user's existing objects *plus* the template — in its own
folder**, separate from the workspace baseline and the template clone.

Build it from `./workspace` (Phase 4) and the template (`./backend` for apps, repo root for
integrations):

1. **Find collisions.** For each object type (`table/`, `function/`, `api/<group>/`,
   `task/`, `ai/…`), compare the template's object names against `./workspace`. A collision
   is the **same type + same name** in both (API groups by folder; endpoints by group +
   endpoint).
2. **Rename the template's colliding copies to `<name>_template`** so the merge keeps
   *both*. A rename is **three coordinated changes** — do all or the template breaks: the
   file (`table/users.xs`→`table/users_template.xs`), the declared name inside the `.xs`
   (`table: users`→`table: users_template`), and **every in-template reference** (grep the
   template tree: functions querying it, APIs, `function.run` calls, triggers, addons, agent
   tools). Bump to `_template_2`, … if needed. **Validate** every touched file with
   `xano_validate_xanoscript`; if an object is too entangled to rename cleanly, exclude it
   (`-e`) or ask the user.
3. **Assemble the working folder.** Name it after the target **workspace + template**,
   slugified — e.g. workspace "Acme CRM" + `todo-app` → **`./acme-crm-todo-app`** (written
   `./<workspace>-<template>` below; use the real slug on disk). Copy the entire `./workspace`
   baseline into it, then overlay the (renamed) template files on top → *everything the user
   had* **plus** the template. New/empty workspace → it's just the template. Env vars pulled
   with `--env` carry in; table records survive in place as long as their table object is
   preserved (it is).
4. **Tell the user, plainly** — defined wording:
   ```
   Your workspace already has things in it, so I merged the template *into* a copy of your
   existing setup — nothing of yours is removed or replaced. A couple of template pieces
   shared a name with yours, so I kept both by renaming the template's copies:

     • table "users"       → "users_template"
     • function "send_mail" → "send_mail_template"

   I validated the merged version; your originals stay exactly as they are.
   ```
   No collisions → drop the rename list, keep the reassurance. Empty workspace → "Fresh
   workspace — importing the template as-is."

**From here on, `./<workspace>-<template>` is the working folder** for every CLI `push` and
`pull`. **Always tell the user which local folder you're pushing from** by its real name.
**Never `--sync --delete` against a live workspace.**

### Plan-gated notice (defined wording)

If the item uses a gated feature (e.g. a `workflow_test/` dir on a plan without
`workspace:workflow_test`), say **before** the dry-run:

```
Heads up on your plan (Free / build):

  ✓ Everything that makes this template work will import and run.
  ✗ Skipping: workflow tests — your plan doesn't include them.

This won't affect the running app; you'd only use workflow tests for automated checks. You
can enable them later by upgrading in the Xano dashboard (Billing).

I'll exclude that and push the rest now.
```

No gated features → "Your plan covers everything in this template."

### Preview → approve → push

This is also the **database-change confirmation**: the dry-run shows exactly what tables/
objects will be created before anything is written. Show it as a **defined summary**:

```
Dry run — nothing has been pushed yet. This previews what the real push will do.

Target: your workspace <name> (<id>)     # paid: staged in your sandbox first, then promoted here
Keeps your existing: <M> objects
Adds from the template: <N> objects
Renamed to avoid conflicts: users → users_template   # omit if none
Excluded (plan-gated): workflow tests                # omit if none
Deletes: none                                        # must be none

Reply "yes" to push for real, or tell me what to change.
```

**Safety check: the dry-run must show `Deletes: none` and your existing object count
intact.** If it shows any delete, the combined tree is missing something — stop and rebuild
it. Apply the same `-e` excludes to both dry-run and real push.

**Free — direct push of the combined tree:**
```sh
xano workspace push -d ./<workspace>-<template> -w <id> --env [-e 'workflow_test/**'] --dry-run
# NEVER --sync --delete on a live workspace.
```
**Paid — stage the combined tree in the sandbox (reset it first so it mirrors the tree exactly):**
```sh
xano sandbox reset        # confirm first — wipes the disposable sandbox to a clean slate
xano sandbox get
xano sandbox push -d ./<workspace>-<template> --env [-e 'workflow_test/**'] --dry-run
```
`--env` carries the env vars so the promotion preserves them.

---

## Phase 7 — Push after approval, verify, promote, deploy, hand off

Only after the user replies "yes", run the real push with `--force` (only after approval):

```sh
xano workspace push -d ./<workspace>-<template> -w <id> --env [-e 'workflow_test/**'] --force   # Free
xano sandbox push   -d ./<workspace>-<template>       --env [-e 'workflow_test/**'] --force      # Paid
```
Always push **`./<workspace>-<template>`**, never the template clone alone.

### Free — the push goes live (no draft/staging on this plan)

The **direct workspace push** (Free) has no draft or staging step, so be clear the user
understands everything goes **live immediately** — fold this into the Phase 6 approval,
don't add a second gate. Free plans have **no branches and no sandbox**, and `xano workspace
push` has **no draft/publish flag**, so there's no CLI way to stage a Free import for review;
it publishes live. **Defined heads-up** (say it with the dry-run preview, before the "yes"):

```
Heads-up: on your plan this publishes **live** to your workspace right away — there's no
draft or staging step. Database changes especially (new tables, fields, indexes) always
apply live. The preview above is exactly what will land.
```

If the user wants to **review changes before they go live**, that's a paid capability — the
sandbox (push → review → **Review & Push**) or branches. Mention it as an option, don't push
it. (Paid users already get this: the sandbox *is* their review stage, and schema applies to
the workspace only when they promote.)

### Plan-gated content (error-driven)

If rejected for a missing feature (e.g. `Please upgrade to access workflow tests`), exclude
the named files, retry, and say what was skipped:
```sh
xano workspace push -d ./<workspace>-<template> -w <id> --env -e 'workflow_test/**' --force   # Free
xano sandbox push   -d ./<workspace>-<template>       --env -e 'workflow_test/**' --force      # Paid
```
Cap at a few retries; otherwise stop and report the raw error.

### Confirm the push actually landed

A push can be rejected and leave nothing imported — **verify:**
```sh
xano workspace get -w <id>   # Free — object counts > 0
xano sandbox get             # paid — the sandbox has the pushed objects
```
If the real push returned non-zero, a 4xx/5xx, or 0 objects, it did **not** succeed —
surface the raw error, retry with the right exclude if plan-gated, and don't hand off until
a verified push exists.

### Free — share the workspace URL after the push

Give Free the same closure paid gets from the sandbox review. Resolve the **API base URL**
with the CLI-only lookup below ("Look up the API base URL") and hand it over — "your APIs are
live here now" — and tell them where to see it in the builder: **go to `app.xano.com`**, open
the **<instance>** instance and **<workspace> (<id>)** workspace, and look under **<where the
imported objects live — e.g. the API group / tables / functions>**. **Don't build a
`https://<host>/workspace` link — the API host isn't the dashboard host (see guardrails).**
(Paid uses `xano sandbox review` — opens the real review in the browser — instead.)

### Modifications (optional)

If the user wants changes: edit the `.xs` files in **`./<workspace>-<template>`** (not the
raw clone), organized by type (`api/<group>/`, `function/`, `table/`, `task/`, `ai/…`;
snake_case; API endpoints carry a verb suffix). **Validate** each with
`xano_validate_xanoscript`, then preview → approve → push. **Confirm database changes with
the user before making and before pushing them.**

- **Free** → push the folder to the workspace (`--force`), then re-verify.
- **Paid** → reset + push the folder to the sandbox, then **hand the promotion back to the
  user**: it's not done until *they* manually **Review & Push** in the Xano browser UI. Give
  open the review in their browser with `xano sandbox review` (fresh each time), say plainly it's a manual step in
  their browser, and have them click it — you can't do it and there's no CLI for it (same as
  the promote step above). Verify it reached the workspace afterward.

### Paid accounts: promote the sandbox into the workspace

**The sandbox is staging, not live** — nothing depending on it works until promoted, and
there's **no CLI promote command** (it's the browser review flow). **Open the review in their
browser now:** run `xano sandbox review` (no `--url-only`) — it opens a **fresh review session
every time** on their machine (the token is per-session and expires, so always run it fresh,
never reuse an old one). Fill step 2 with the **actual objects**: the new ones being added
(from the dry-run) and the user's key existing ones you're preserving, so the review is
concrete. Then walk them through it:

```
Your build is staged in your Xano sandbox — a *combined* copy: everything your workspace
already had, plus the <template> template. One manual step makes it live:

  1. Your sandbox review just opened in your browser (if it didn't, tell me and I'll reopen it).

  2. Look it over — the changes should be only *additions*: <the new tables / API groups /
     functions from the dry-run>. Your existing <their key existing objects — e.g. the user
     table, auth group, accounts> are all still there, untouched.

  3. Click **Review & Push** in the top right, and pick your workspace "<name> (<id>)".

If the review shows anything of yours being *removed*, stop and tell me — don't push.
Otherwise, tell me once you've clicked Review & Push and I'll confirm it landed, then wire up
the frontend and env vars.
```

After they push, **verify it reached the workspace** (refresh the working folder):
```sh
xano workspace pull -d ./<workspace>-<template> -w <id>   # confirm the template's objects are present
xano workspace get -w <id>
```
If the objects aren't there, the promotion didn't go through — re-share the steps and don't
proceed to the frontend. Free users skip this — their push went straight to the workspace.

### Configure and hand off

Use the repo's README (Install/Configure) as the checklist. Narrate each briefly.

- **Environment variables** — existing vars were preserved (pulled + pushed with `--env`).
  What still needs values are the **new** keys the template requires (e.g. `STRIPE_API_KEY`
  from `.env.example`). Set those in the Xano dashboard. Never hardcode secrets into `.xs`.
- **Seed / demo data** — if the README documents a seed endpoint, offer to call it.
- **Frontend (full apps)** — take it all the way to a live URL; *where* depends on the plan.
  1. **Wire it to the workspace API base URL** (resolved CLI-only below — for paid, the
     workspace just promoted into). Edit the file yourself; never the Meta API.
  2. **Deploy, by plan:**
     - **Free → local only.** Free can't use static hosting. Hand over the wired
       `frontend/index.html` (open locally / host anywhere); a paid plan unlocks a public URL.
     - **Paid → publish to Xano static hosting via the CLI**, three steps: **create a host →
       push the folder as a build → deploy to dev, then prod.** The CLI zips the folder for
       you. Prefer a **new** host; never replace an existing host's build. Tiers set how many
       hosts are allowed — **Essential** = one, **Scale / Pro+** = several.
       ```sh
       xano static_host list -w <id>                 # what hosts exist, how many
       ```
       - **Room for a new host** (Scale/Pro+, or Essential with none) → create one. **The host
         name becomes the public subdomain, so it can't contain hyphens** — use a clean
         lowercase, hyphen-free name derived from the template (e.g. `todo-app` → `todoapp`),
         unique against the list:
         `xano static_host create <new_host_name> -w <id>` ; `HOST=<new_host_name>`.
       - **Essential at its one-host limit** → check if the existing host is empty
         (`xano static_host build list <existing-host> -w <id>` → empty = no builds); if empty,
         with the user's OK reuse it (`HOST=<existing-host>`); if it has builds, never replace
         them → fall back to the local file and explain they'd need Scale/Pro+.
       Then push the build and deploy it — **dev first for a test link, then prod for live:**
       ```sh
       BUILD_ID=$(xano static_host build push "$HOST" -d ./frontend -n v1 -w <id> -o json | jq -r '.id')
       xano static_host deploy "$HOST" --build_id "$BUILD_ID" --env dev  -w <id>   # test link — have the user try it
       xano static_host deploy "$HOST" --build_id "$BUILD_ID" --env prod -w <id>   # live link — after they're happy
       ```
       Give the user the dev URL to test, then the prod URL once they confirm.
  Always **say explicitly where the frontend ended up and how to open it** — never end on a
  silent, unwired file.
- **Tests** — `xano unit_test run_all -w <id>` if present. Workflow tests are paid-gated.

#### Look up the API base URL — CLI only, no Metadata API

`https://<instance-host>/api:<canonical>`, `<canonical>` server-assigned — read it from the
working folder, not the template clone:
```sh
HOST=$(xano profile me -o json | jq -r '.extras.instance.xano_domain // .extras.instance.host')
xano workspace pull -d ./<workspace>-<template> -w <id>            # reuse the refreshed working folder
grep -Ri 'canonical' ./<workspace>-<template>/api/<group>/api_group.xs
```
Match the README's API group to its folder, read the canonical, join `https://$HOST/api:<canonical>`.
If the slug is genuinely absent, **don't** fall back to the Meta API — ask the user to paste
the `api:XXXX` from the group's page in the dashboard.

### Summarize (plain language, no browser)

- the plan and **where the backend lives now** — for paid, "your workspace <name> (<id>),
  promoted from the sandbox" (only once the promotion is verified);
- **what was added**, and **anything skipped** for plan reasons (the result still works);
- the **live API base URL** — `https://<host>/api:<canonical>`, "your APIs are live here now";
- **where the frontend ended up** — the live static-host (prod) URL, or the local file path;
- any **env vars** still needing real values;
- **where to see it** — **`app.xano.com`**, the **<instance>** instance, the **<workspace>
  (<id>)** workspace, and where the imported objects live (never a guessed `<host>/workspace`
  link); for paid, re-open the review via `xano sandbox review` (fresh session) to re-review.

---

## Phase 8 — Orient the user, then hand off to building

The import is done — now leave the user *understanding* how to keep working, and invite them
to. **Speak to *this* import, not a generic Xano tour:** name the template they chose, that
their existing work was preserved and the template merged in alongside it, any objects you
renamed to `_template` on a collision, and the deployed frontend if there was one. You know
their plan from Phase 4; send the matching message and **fill in the bracketed parts (or drop
a bracket when it doesn't apply** — no frontend, no collisions, etc.).

**Optional — put the imported build under version control.** Offer it; don't force it. The
working folder `./<workspace>-<template>` was pulled with `--env`, so it holds secret
values — **don't git-init it as-is.** For a git-safe copy, pull without `--env` and init
there:

```sh
xano workspace pull -d ./<workspace>-git -w <id>     # no --env → no secrets on disk
cd ./<workspace>-git && git init -q && git add . && git commit -q -m "Import <template>"
```

**Optional — VS Code extension.** *Only if the agent is running in VS Code* (or a VS
Code-based editor); in a terminal agent, skip it and don't mention it.
- **Detect if it's installed by checking the extensions folder on disk** (reliable; **don't
  use `code --list-extensions`** — it needs `code` on PATH and can point at a different VS Code
  instance): `ls -d ~/.vscode*/extensions/xano.xanoscript-language-server-* ~/.cursor/extensions/xano.xanoscript-language-server-* ~/.windsurf/extensions/xano.xanoscript-language-server-* 2>/dev/null`.
  Any path printed → installed; don't offer.
- **Not installed → offer, confirm**, then install: `code` on PATH →
  `code --install-extension xano.xanoscript-language-server`; no `code` → manual (Extensions
  panel → search "XanoScript" → Install).

**Optional — tidy up.** The baseline snapshot (`./workspace`) and any verify/temp pulls hold
`--env` secrets and aren't needed anymore — offer to delete them. Keep the working folder
`./<workspace>-<template>` for future edits.

**Then send the message below** — it's meant to be **high-level and inspiring**, not a how-to:
frame what building in Xano *means* for them and where they could take it, not the mechanics of
`.xs` files. Adjust the **go-live line** to their plan (Free vs paid). Fill or drop each
`[bracket]`. If they're in an IDE, you may add in passing that they're welcome to edit the
`.xs` files directly (you'll validate + push) — but don't lead with it.

**Defined message:**

```
Done — <template> is imported and live in "<workspace>". Your existing work is untouched; the
template was merged in alongside it[, and where names clashed I kept both by renaming the
template's copies (<list>)]. [Your frontend is live at <URL>.]

You've now got a real, production backend running on Xano — your data, APIs, and business
logic, with no servers to manage and room to scale. From here you can grow it into whatever you
need, and the way we do that is the fun part: you tell me what you want in plain language — a
new field, an endpoint, a whole feature, an integration — and I build it in XanoScript,
validate it, preview it with you, and push it. You stay in the ideas; Xano runs them in
production.

A few directions people take from here:

  • **Build on <template>** — extend what it gave you with new fields, endpoints, or logic.
  • **Add capabilities** — authentication, scheduled/background tasks, file uploads, search,
    notifications, even an AI agent.
  • **Plug in a service** — payments, email, SMS, CRM, or AI, from the xano-community catalog
    or wired up custom.
  • **Connect a front end** — anything can call your API[; your site's already live].

However we go, I'll confirm any database change with you first, and <go-live line — Free: show
you a dry-run before anything goes live; Paid: stage each change in your sandbox for you to
Review & Push>.

What would you like to build? Even a rough goal is enough — tell me and we'll start.
```

Then follow the user's lead, holding to the guardrails (confirm database changes before making
and before pushing; on paid, work through the sandbox; and after each change reaches the
workspace, give them a link to open it — never stop at "done").

---

## Appendix — Xano CLI quick reference

Space-separated commands (`xano workspace push`), not colon-separated. Full ref: `xano <cmd>
--help` or the `xano_cli_docs` MCP tool.

```sh
# Install / update / version
npm install -g @xano/cli              # requires Node >= 20.12.0
xano --version
xano update [--check]

# Auth — user runs `xano auth` in their OWN real terminal (never via the agent's shell — it hangs)
xano auth                             # user runs in a separate terminal window / editor's built-in terminal
xano profile me [-o json]             # verify (poll this) + plan detection (extras.instance)
xano auth --code "<code>" --json      # fallback: agent-run one-shot (code from <origin>/login?dest=cli&display=code)
xano profile create <name> -i <origin> -t <token> -w <id> --default   # token, no browser

# Workspaces (Free pushes here; paid promotes here)
xano workspace list
xano workspace get -w <id>
xano workspace create "<name>"        # paid only
xano workspace edit -w <id> --allow-push   # paid: enable direct CLI push (off by default)
xano workspace pull -d ./code -w <id> --env
xano workspace push -d ./code -w <id> --env [-e 'glob'] --dry-run | --force

# Sandbox (paid staging; Free can't use it)
xano sandbox get
xano sandbox reset                    # clean slate (destructive — confirm)
xano sandbox push -d ./code --env --dry-run | --force
xano sandbox review                   # opens the review in the browser to Review & Push (fresh each run; --url-only just prints the link)

# Static hosting (paid) — create → build push → deploy dev/prod
xano static_host list -w <id>
xano static_host create <name> -w <id>          # host name: NO hyphens (letters/digits/underscores)
xano static_host build push <host> -d ./frontend -n v1 -w <id> -o json   # returns build id
xano static_host build list <host> -w <id>                               # empty = no builds
xano static_host deploy <host> --build_id <id> --env dev|prod -w <id>

# Import from git
xano workspace git pull -r https://github.com/xano-community/<repo>.git -d ./code

# Tests
xano unit_test run_all -w <id>
xano workflow_test run_all -w <id>    # paid-gated
```

**On-disk layout after a pull** (snake_case; API endpoints carry a verb suffix):
```
api/<group>/api_group.xs           # API group def (holds the canonical slug)
api/<group>/<endpoint>_<verb>.xs   function/<name>.xs   table/<name>.xs (+ table/trigger/*)
task/<name>.xs   ai/agent/<name>.xs, ai/mcp_server/*, ai/tool/*   realtime/channel/*
workspace/<name>.xs                # workspace config + workspace/trigger/*
```

### Codex MCP config (`~/.codex/config.toml`)
```toml
[mcp_servers.xano-developer]
command = "npx"
args = ["-y", "@xano/developer-mcp"]
```
