---
name: start-xano
description: >-
  Set up the Xano developer tools in any local, MCP-capable coding agent and orient
  the user. Installs the Xano CLI (@xano/cli) and registers the Xano Developer MCP
  (@xano/developer-mcp) with the agent, signs the CLI in, and updates either if it's
  installed-but-outdated — then, because MCP servers only load at startup, has the user
  restart the agent once so the tools come live and verifies them. Afterward it walks a
  first local-dev workflow (pull the workspace to local files, init git, and in VS Code
  install the XanoScript language server), explains in plain language how everyday Xano
  development works — including the paid sandbox review flow — and asks what the user
  wants to change or build next. Use when a user wants to "set up Xano", "install the
  Xano CLI", "connect the Xano MCP / developer tools", "authenticate Xano", or get the
  Xano tooling working before doing Xano work. Agent-agnostic (Claude Code, Cursor,
  Windsurf, Cline, VS Code/Copilot, Codex, and any other MCP client via the standard
  config). Requires a local agent with shell access; it reads (pulls) but never pushes
  or deploys anything to Xano.
---

# Set up the Xano developer tools in any agent

This skill takes a user from "no Xano tooling" to "CLI installed and signed in, the
Xano Developer MCP live in my agent, my workspace pulled locally under git, and a clear
idea of how to work." It is **agent-agnostic** — it works in any MCP-capable coding
agent (Claude Code, Cursor, Windsurf, Cline, VS Code/Copilot, Codex, and others) by
registering the MCP with the standard `mcpServers` config, never one client's shortcut.

The run is: **greet and lay out the plan (Step 0) → set up the tools (Steps 1–6) → get
set up for local work (Step 7) → learn how the workflow works and choose what's next
(Step 8).**

**Principle — transparency and trust.** This is the user's real Xano account and
machine. The whole point is that they always know, and trust, what's happening: narrate
each step in plain terms (what and why) before you do it, show what you're about to
install, pull, or change, and never touch their account or machine silently. Someone
who finishes this skill should understand exactly what was set up and how their Xano
workflow now works.

## Prerequisite — a local agent with shell + filesystem access

**This only works from a coding agent on the user's *own* machine** — real terminal, local
filesystem, editable config. Every step needs it (installs, `xano` commands, writing the MCP
config, restarting to load, pulling code, `git init`).

**A shell alone isn't enough — confirm it's *their* machine.** A server-side/cloud sandbox
that happens to run `npm` (Claude web, ChatGPT web) does **not** qualify: it wipes after the
task, has no local agent config to register into, and can't open the user's browser or reach
their Xano instance. Tells you're not on their machine: nothing persists, the home dir/config
isn't theirs, or the network reaches npm/GitHub but not the open web or xano.com. If any hold
— **even if `npm` works** — **stop and hand them local-agent options** (installing here only
helps inspect `xano --help`/versions, never real setup). **Lead with the option closest to
where they are**, naming their context in "from here":

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

> Setting up Xano has to run on your own computer, from a local coding agent — I can't do it
> from here. Open one of these on your machine and run the setup there:
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
  *Prerequisite*). A shell alone isn't enough: a server-side sandbox that can run `npm` still
  doesn't qualify. Everything here needs *their* terminal, filesystem, agent config, and browser.
- **Narrate each step — don't go silent, don't over-explain.** Before each step, say in
  **one plain sentence** what you're doing and why (e.g. "Pulling your workspace so you
  have a local copy to edit and version"); give a one-line result after. Every step gets
  a sentence — not a paragraph, and never a dump of logs, flags, or raw output. Installs
  run quietly (output redirected), but you still *announce* that you're installing.
- **Confirm before installing, updating, or authenticating.** These touch the user's
  machine and account. Say what you're about to do and get **one** clear go-ahead first.
- **Agent-agnostic.** Register the MCP with the standard config (Step 3); phrase the
  restart as "restart your agent," not "restart Claude."
- **Never restart the agent yourself.** Only the human relaunches their editor/terminal
  (no `kill`/`pkill`, no relaunch from a Bash call).
- **Auth: the user runs `xano auth` in their own real terminal — you never run it.** The
  interactive picker needs a TTY the agent shell lacks, so it hangs if you run/background it
  (via Bash tool or `!`). Point them to a separate terminal window (or their editor's built-in
  terminal), then poll `xano profile me` until it lands. (Can't open one? Fall back to the
  agent-run `--code` flow — Step 4.)
- **Run commands in the IDE terminal, in the open project folder.** Everything but `xano
  auth` uses relative paths, so run it from the folder open in the user's IDE / your working
  folder, in the IDE's integrated terminal — not an unrelated directory. If you surface a
  command for the *user*, point them to their IDE terminal at that folder (and open it there
  for them if your software can).
- **Confirm database changes twice.** Any DB change (create/alter/delete tables, fields,
  indexes, records) needs the user's explicit OK **before you make it locally** and again
  **before it goes to Xano**; explain what changes, and never touch schema/data unprompted.
- **Reads, never pushes.** This skill pulls and sets up; it never pushes or deploys to
  Xano. Changing the workspace is the user's next move (Step 8), on their terms.
- **Review & Push is manual, in the Xano browser UI — you never do it.** For paid users,
  promoting a sandbox change into the workspace is a button the *user* clicks on the sandbox
  review page; there's no CLI command and you can't do it for them. **Open a fresh review
  every single time a review is needed** — run `xano sandbox review` (no `--url-only`), which
  opens the review in their browser on their own machine; the session token expires, so always
  run it fresh, never reuse an old link. Say plainly it's a manual step in their browser, have them click **Review &
  Push**, then verify it landed.
- **Never guess or construct a browser link — the API host is not the dashboard host.** The
  instance's API/data host (`extras.instance.xano_domain`/`host`, e.g. `x8ki-...xano.io`) is
  **not** where the workspace UI lives (that's a different domain, e.g. `fast.dev123.io`), so
  **never build `https://<api-host>/workspace`** — that link is wrong. There is no CLI command
  that returns the workspace's browser URL, so **don't fabricate one.** What you *can* give:
  the **API base URL** (legitimately built from the API host — clearly an endpoint, not the
  dashboard), and the Xano **dashboard root** (`app.xano.com`) for them to open their
  workspace. For the **sandbox**, the real browser link comes only from `xano sandbox review`
  — never guessed.
- **After a change reaches the workspace, tell them where to find it — no guessed link.**
  Never stop at "done." Point them to **`app.xano.com`** and name **which instance** (from
  `xano profile me`), **which workspace** (`<name> (<id>)`), and **where the change lives** —
  the exact spot to check, e.g. "Functions → create_event_log", "the `applicant` table", or
  "the Onboarding API group". Add the affected endpoint's live **API URL** when relevant.
  Give a clear path to check it, never a fabricated URL.

---

## Step 0 — Greet the user and lay out the workflow

Open with a short, friendly greeting that explains, in plain language, what you're about
to do together: get Xano connected to their agent so they can build and manage their
Xano workspace right here. Preview the steps at a high level and set the expectation
that you'll talk them through each one, then move into setup. Keep it warm and brief; this
is the first thing they see, so it sets the trust for everything after.
**Defined greeting** (fill in nothing — just deliver it):

```
Hi! I'm going to get Xano wired up so you can build and iterate on your Xano backend right
here with me.

Here's the plan, and I'll walk you through each step as we go:

  1. Install the Xano CLI and connect Xano's developer MCP to this agent
  2. Sign you in to Xano
  3. One quick restart so the tools load
  4. Pull your desired Xano workspace to your computer and put it under version control
  5. Then you're ready to build — we'll iterate in your Xano workspace together
```

(If you're **not** a local agent — no shell/filesystem — don't give this greeting;
deliver the *Prerequisite* stop message instead.)

Then continue to Step 1 — no separate yes/no needed here; the real "okay to install?"
confirmation comes at Step 2.

---

## Step 1 — Check what's present and what's outdated

**First, confirm you're a local agent with shell access** (the *Prerequisite*). If you
can't run commands on the user's machine, stop and tell them to run this from a local
agent.

Then check each piece — presence **and** version — so you install only what's missing
and update only what's behind (a stale CLI or MCP is how you end up on wrong docs or
missing commands):

```sh
node --version        # need >= 20.12.0
xano --version        # is the Xano CLI installed?
xano profile me       # is the CLI authenticated?
xano update --check   # is the CLI outdated? (checks npm; doesn't install)
```

Also note whether the Xano MCP tools (`xano_validate_xanoscript`, `xano_cli_docs`,
`xano_xanoscript_docs`) are present in this session. To check the MCP version, compare
the latest to what's running (the MCP's `xano_version` tool, or
`npm view @xano/developer-mcp version` vs `npx -y @xano/developer-mcp@latest --version`).

**Shortcut:** if the MCP tools are already present **and** `xano profile me` succeeds
**and** both are current, everything's done — say `Xano tools are installed, signed in,
and up to date — you're all set.` and jump to Step 8 to orient the user.

---

## Step 2 — Confirm, then install or update quietly

Present only the pieces that are **missing or outdated**, labeling each *install* or
*update*, and get **one** go-ahead. **Defined question** (drop any line that doesn't
apply; swap "install"→"update" for a piece that's just behind):

```
To set up Xano I need to put a couple of things in place:

  • Node.js ≥ 20.12.0     — runtime for the Xano CLI                       (install)
  • Xano CLI (@xano/cli)  — the `xano` command for your terminal            (update — yours is behind)
  • Xano Developer MCP    — loads Xano's docs + validation into your agent  (install)

I'll install/update these quietly and register the MCP with your agent. Okay to go
ahead? (yes / no)
```

If **nothing** is missing or outdated, skip to auth (Step 4).

On "yes", do it **silently** — never print install output:

```sh
# Node — only if missing/too old; prefer an existing version manager, else nvm.
#   (if you install via nvm this session, later shells need it sourced / a fresh tab)
npm install -g @xano/cli >/dev/null 2>&1        # install the CLI (if missing)
xano update >/dev/null 2>&1                      # update the CLI (if outdated)
```

Re-check `xano --version` afterward. If any install fails, stop and show the raw error
plus the one command the user can run to fix it.

**A freshly installed CLI is never signed in.** If you had to *install* the CLI this run
(it wasn't already present), don't check or imply "are you already signed in" — you're
not, because a new install has no credentials. Go straight to authentication (Step 4).
The "already authenticated, skip auth" path only applies when the CLI was **already
present** with a saved profile from before.

---

## Step 3 — Register the Xano Developer MCP (agent-agnostic)

The Xano Developer MCP is a standard MCP server: `npx -y @xano/developer-mcp`. Every
MCP-capable agent runs it from the **same** server entry — only the config *file*
differs. **Detect which agent is running** (or ask if unsure), then register it the
native way for that agent. Name the server `xano-developer`. If a server by that name
already exists, leave it — **unless it's outdated** (Step 1): then re-register the same
entry with `@xano/developer-mcp@latest` so npx fetches the newest build.

The universal server entry (this is what goes into any client's `mcpServers` map):

```json
{
  "mcpServers": {
    "xano-developer": {
      "command": "npx",
      "args": ["-y", "@xano/developer-mcp"]
    }
  }
}
```

Register it per agent:

| Agent / client        | How to register                                                            |
|-----------------------|----------------------------------------------------------------------------|
| **Claude Code**       | `claude mcp add --scope user xano-developer -- npx -y @xano/developer-mcp`  |
| **Cursor**            | add the entry to `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (project) |
| **Windsurf**          | add the entry to `~/.codeium/windsurf/mcp_config.json`                      |
| **Cline**             | add the entry to the Cline `cline_mcp_settings.json`                        |
| **VS Code / Copilot** | add the entry to `.vscode/mcp.json`                                         |
| **Codex**             | add a `[mcp_servers.xano-developer]` table to `~/.codex/config.toml` (**TOML**, not JSON — below) |
| **Gemini CLI**        | add the entry to `~/.gemini/settings.json` (global) or `.gemini/settings.json` (project) |
| **OpenCode**          | add to the `mcp` object in `opencode.json` (**different schema** — see below)  |
| **Claude Desktop**    | add the entry to `claude_desktop_config.json`                              |
| **Any other**         | add the entry above to that client's MCP config file                       |

Two clients use their own schema, not the `mcpServers` block. **Codex** (`~/.codex/config.toml`):

```toml
[mcp_servers.xano-developer]
command = "npx"
args = ["-y", "@xano/developer-mcp"]
```

**OpenCode** (`opencode.json` — uses an `mcp` object with `type: "local"` and `command` as an array):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "xano-developer": { "type": "local", "command": ["npx", "-y", "@xano/developer-mcp"], "enabled": true }
  }
}
```

**Unrecognized agent?** Don't guess silently. Most MCP clients accept the standard
`mcpServers` block — but some use their own schema (Codex is TOML, OpenCode is `mcp` /
`type: "local"`), so **check the agent's own MCP docs for the config file and format**
rather than assuming. If you still can't place it, show the user the standard block, name
the two exceptions, and ask them to add it per their agent's docs. Use **user/global scope**
when supported, so the tools are available in every project.

---

## Step 4 — Authenticate the CLI

Skip only if `xano profile me` already succeeded in Step 1 (a pre-existing profile).
Otherwise have the **user run `xano auth` in their own real terminal — never through you**
(not Claude Code's `!`, not your Bash tool): the interactive picker needs a TTY and will hang
in the agent's shell. **Tell them which terminal, matched to the running agent:**

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

If you installed Node via nvm this session, add: "open a fresh terminal tab so `xano` and
`node` are on your PATH."

Then **poll** `xano profile me` until it succeeds (or the ~5-minute window elapses); don't
proceed until it does.

> **Can't open a separate terminal (or prefer not to)?** Use the one-shot `--code` flow, which
> *you* run non-interactively: send the user to
> `https://app.xano.com/login?dest=cli&display=code`, they paste back the code, and you run
> `xano auth --code "<code>" --json` (one instance auto-selects; several → the `--json` error
> lists them, retry with `-i <instance>`). No browser (SSH/CI): `xano profile create <name> -i
> <origin> -t <token> -w <id> --default` (token from the dashboard).

---

## Step 5 — Restart the agent to load the Xano tools

**Skip this if the Xano MCP tools are already present in this session** (a warm session
where you only authenticated, and the MCP was already loaded and current) — go to Step 6.

Otherwise the MCP was just registered (or updated) and its tools aren't loaded yet. MCP
servers load only at startup; nothing reloads them mid-session. **Only the human can
relaunch the agent** — never attempt it from a Bash call. **Defined instruction:**

```
Setup's done. One quick restart loads the Xano tools into your agent.

Restart your agent so it picks up the Xano MCP server, then come back to this
conversation.
```

Add the restart line that matches the running agent:

- **Claude Code:** `Quit, and from this same folder run:  claude --resume ${CLAUDE_SESSION_ID}`
  (use `--resume`, not `--continue`).
- **Cursor / Windsurf / VS Code / Cline:** `Reload the window (or toggle the MCP server
  off/on in settings) so the Xano server starts, then return here.`
- **Codex:** `Exit and start a new codex session (Codex loads MCP servers from
  config.toml at startup), then return to this conversation.`
- **Gemini CLI:** `Exit and start a new gemini session (it loads MCP servers from
  settings.json at startup), then return to this conversation.`
- **OpenCode:** `Exit and start a new opencode session (it loads MCP servers from
  opencode.json at startup), then return to this conversation.`
- **Other agents:** `Fully restart the agent so it loads the newly registered MCP
  server, then return to this conversation.`

Credentials live in `~/.xano/credentials.yaml` and persist across the restart, so the
sign-in isn't lost.

---

## Step 6 — Verify the tools are live

First thing after the restart. Confirm the Xano MCP tools (`xano_validate_xanoscript`,
`xano_cli_docs`, `xano_xanoscript_docs`) are present and `xano profile me` still succeeds.

- **Both good** → setup is done. Say so in one line — `Xano is set up: the CLI is signed
  in and the Xano tools are live in your agent.` — then offer Step 7.
- **Tools still missing** → the restart didn't take. Confirm the MCP is registered (for
  Claude Code, `claude mcp list`; for other agents, check the client's MCP config file),
  re-add it if missing, re-issue the Step 5 restart instruction, and stop.

---

## Step 7 — Get set up for local development

Set the user up for local work — **just do it**, narrating each step; **don't present a
menu or ask which they want**. Announce it briefly ("Setting you up for local development —
pulling your workspace and putting it under git"), then do both:

1. **Pull the workspace** to local files.
2. **Initialize git** in that folder.

Then — **only if the agent is actually running in VS Code** (or a VS Code-based editor) —
offer the XanoScript language server (below). In a terminal agent (OpenCode, Codex CLI,
Gemini CLI, Claude Code) there's no editor to install into, so **skip it entirely and don't
mention it**.

### Pull the workspace to local files

So they have an editable, version-controllable copy of their backend. Confirm the
workspace, pull it to a folder named after it, and say what landed:

```sh
xano workspace list                            # confirm which workspace
xano workspace pull -d ./<workspace> -w <id>   # pull code to a local folder
```

Pull **without `--env`** here — this copy is meant for git, and `--env` would write
secret values to disk. Then, e.g.: "Pulled your workspace — APIs, tables, and functions
are now in `./<workspace>` as editable files."

### Pin the profile to this workspace

So every command run in this folder targets the workspace you just pulled — not whatever the
profile's **global default** happens to be. They diverge the moment the account has more than
one workspace, and a stray command (or an API/seed call that resolves via the profile) against
the wrong one is a silent footgun. This only writes a folder-local `profile.yaml` (no global
change, no secrets), so a quick heads-up is enough — **offer it**, then pin:

```sh
( cd ./<workspace> && xano profile use "$(xano profile get)" -w <id> )   # writes a no-secrets profile.yaml
xano profile workspace                                                    # verify it prints <id>
```

`profile.yaml` holds no secrets — just the profile name and workspace id — so it's safe to
commit; it keeps this folder locked to the right workspace for the user and anyone who clones
it. (Every command then prints `Using profile '<name>' (workspace <id>) · profile.yaml`.)

### Initialize git

So they can track changes and roll back. In the pulled folder:

```sh
cd ./<workspace>
git init -q
printf 'env.yaml\n*.secret\n' > .gitignore     # keep any stray secrets out of history
git add . && git commit -q -m "Initial Xano workspace pull"
```

Then: "Set up version control and committed the current state." (Already a git repo →
just say so and skip.)

### VS Code — the XanoScript language server (only if you're in VS Code)

**Only when the agent is running in VS Code — or a VS Code-based editor (Cursor, Windsurf)
that uses the VS Code Marketplace.** In any terminal agent (OpenCode, Codex CLI, Gemini CLI,
Claude Code) **skip this entirely and don't mention it** — there's no editor to install into.

When you *are* in VS Code:

1. **Detect whether it's already installed by checking the extensions folder on disk** — this
   is reliable; **don't use `code --list-extensions`** (it needs the `code` CLI on PATH and can
   report the wrong list, since it may point at a different VS Code instance — stable vs
   Insiders vs the remote server):
   ```sh
   ls -d ~/.vscode*/extensions/xano.xanoscript-language-server-* \
         ~/.cursor/extensions/xano.xanoscript-language-server-* \
         ~/.windsurf/extensions/xano.xanoscript-language-server-* 2>/dev/null
   ```
   Any path printed → **already installed**; say so (or say nothing) and skip — don't reinstall.
2. **Nothing printed → offer to install** the **XanoScript Language Server** (syntax
   highlighting, validation, autocomplete for `.xs`); confirm first (it modifies their editor):
   - **`code` CLI on PATH** (`command -v code`) → `code --install-extension xano.xanoscript-language-server`.
   - **No `code`** → manual: open the Extensions panel (⇧⌘X / Ctrl+Shift+X), search
     **"XanoScript"**, and click Install (id `xano.xanoscript-language-server`). Don't offer a
     `code` install you can't run.

Wrap up in a line: what's now in place — "Your workspace is in `./<workspace>`, under git"
(add ", with the XanoScript extension installed" **only if you actually installed it**),
then go to Step 8.

---

## Step 8 — Explain how the Xano workflow works, then ask what's next

The user should leave *understanding* how working with Xano goes — that's the trust
payoff. Deliver **one** short, prescriptive message (below), filled in for their setup and
plan, then let them lead. Keep it tight — the goal is a confident user, not a manual.

First, know their plan — `xano profile me -o json` → `extras.instance`: workspace
entitlement `k8s.additional.workspaces > 1` (or a `package.name` other than `build`) means
**paid**; `build` / entitlement `1` means **Free**. Fill in `<folder>` (the pulled
workspace) and `<plan>` (the display name). Then send the matching message.

Fill in **one** message (below), adjusting two things: the middle bullet by plan (paid vs
Free lines), and the "edit them yourself, or" clause — keep it only in an IDE with a visible
editor; in a terminal agent drop it ("just tell me what you want and I'll change the `.xs`
files for you").

**Defined message:**

```
You're all set: your workspace is in ./<folder>, under git[, on the <plan> plan]. Here's how
everyday Xano development works now:

  • We edit locally, together. The .xs files in ./<folder> are your backend — you can edit
    them yourself, or just tell me what you want and I'll change them for you; the Xano MCP
    validates the XanoScript as we go, so mistakes surface early.

  • <how changes go live — use your plan's line:>
    – Paid: never straight to your workspace (direct `xano workspace push` is off by default,
      a safety guard). I push to your sandbox, you review it in the browser, and Review & Push
      promotes it live when you're happy — so you can try anything without touching live data.
    – Free: a push goes straight to your workspace and is live immediately (no draft/staging,
      and DB changes always apply live), so I'll preview exactly what changes and get your OK
      first. (Reviewing before it's live is a paid feature — the sandbox.)

  • Database changes get your OK twice — before I make them, and before they reach Xano.

What would you like to do first — change something in your workspace, or build something new?
Tell me and we'll do it right here.
```

Then follow the user's lead — this skill's job ends here. Hold to the guardrails as they go
(confirm DB changes before making and before pushing; after a change reaches the workspace,
tell them where to check it — `app.xano.com`, the instance, workspace, and location — never a
guessed link; see *Guardrails*).

---

## Appendix — the commands this skill uses

```sh
# Node & CLI
node --version                        # need >= 20.12.0
npm install -g @xano/cli              # install the CLI
xano --version
xano update [--check] [--beta]        # update the CLI (--check = don't install)

# MCP (standard server entry — register via your agent's config)
npx -y @xano/developer-mcp                    # what the server runs
npx -y @xano/developer-mcp@latest --version   # newest published version
npm view @xano/developer-mcp version          # latest on npm

# Auth — user runs `xano auth` in their OWN real terminal (never via the agent's shell — it hangs)
xano auth                             # user runs in a separate terminal window / editor's built-in terminal
xano profile me                       # who am I? (verifies auth — poll this)
xano auth --code "<code>" --json      # fallback: agent-run one-shot (code from <origin>/login?dest=cli&display=code)
xano profile create <name> -i <origin> -t <token> -w <id> --default   # token, no browser

# Get set up for local work (Step 7)
xano workspace list                           # find the workspace id
xano workspace pull -d ./<workspace> -w <id>  # pull code locally (no --env for a git-safe copy)
( cd ./<workspace> && xano profile use "$(xano profile get)" -w <id> )   # pin the folder to this workspace (profile.yaml, no secrets)
xano profile workspace                        # verify the pin — prints <id>
git init -q && git add . && git commit -q -m "Initial Xano workspace pull"
code --install-extension xano.xanoscript-language-server   # VS Code only, if `code` is on PATH

# The everyday loop (explained in Step 8 — not run by this skill)
xano profile me -o json                       # plan check: extras.instance (paid = entitlement > 1)
xano workspace push -d ./<workspace> -w <id> --dry-run   # Free: preview, then drop --dry-run to apply
                                                         # paid: direct push is OFF by default — use the sandbox
xano workspace edit -w <id> --allow-push      # paid: only if they choose to enable direct push
xano sandbox push -d ./<workspace> --dry-run  # paid: stage in the sandbox, review, then Review & Push
xano sandbox review                           # paid: opens the review in the browser to Review & Push (fresh each run; --url-only just prints the link)
```

### Codex MCP config (`~/.codex/config.toml`)

```toml
[mcp_servers.xano-developer]
command = "npx"
args = ["-y", "@xano/developer-mcp"]
```
