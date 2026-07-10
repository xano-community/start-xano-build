---
name: start-xano-build
description: >-
  Import or add a certified xano-community template, module, or third-party
  integration into Xano. Use when a user wants to spin up, scaffold, import,
  install, or "start a Xano build/app/backend from a template," add a module, or
  wire in a supported integration. This skill owns the whole path from a fresh
  Claude Code session: it installs the Xano CLI, registers the Xano Developer MCP
  with Claude Code, and helps authenticate the CLI (including creating a brand-new
  Xano account) — then, because MCP tools only load at startup, it has the user
  restart Claude once so the Xano tools come live before the build. After the
  restart it detects whether the account is Free or paid, routes the push to the
  right target (existing workspace, paid sandbox, or a fresh build), previews with
  a dry-run, pushes only after explicit approval, and verifies the push actually
  landed. The catalog of supported items is pulled live from the xano-community
  org on every run — never from an embedded list. Claude Code only.
---

# Start a Xano build from a xano-community template

This skill takes a user from a fresh Claude Code session to a working Xano backend
built from a supported **[xano-community](https://github.com/orgs/xano-community/repositories)**
item — a full app, a module, or a third-party integration. Run the phases **in
order** — each one gates the next. Do not skip a phase because it "looks" done;
verify it.

The run has **two acts**, split by one unavoidable restart:

- **Act 1 — Setup (this session):** capture intent, install the Xano CLI, register
  the Xano Developer MCP with Claude Code, and authenticate the CLI. Then have the
  user **restart Claude once**, because MCP tools only load at startup — there is
  no way to load them mid-session.
- **Act 2 — Build (the resumed session):** verify the Xano tools are live, detect
  the plan, pick an item from the **live catalog** (Phase 5), preview, push after
  approval, verify, and hand off.

**The restart is always required** the first time through — even for an
import-only build with no modifications — because the whole workflow relies on the
Xano tools being loaded. The **one exception:** if the Xano MCP tools are *already*
present in this session (a warm session, or you're resuming after the restart),
skip registration and the restart and go straight on.

**The catalog is pulled live from GitHub on every run** (Phase 5) — this skill
carries no embedded list of items. What the org publishes is what's on offer.

## Guardrails

- **This skill owns setup, but installs quietly.** Installing the CLI, registering
  the MCP, and authenticating are this skill's job — but run them **silently**
  (redirect install output to `/dev/null`; see *Output discipline*). Never dump
  npm's install log into the chat.
- **The restart is a hard gate, not optional.** Once the MCP is registered, its
  tools cannot be used until Claude restarts. Do not try to work around it, and do
  not attempt the Xano workflow (Act 2) until the tools are actually present.
  **Never try to restart Claude yourself** (no `kill`/`pkill`, no
  `claude --resume` from a Bash call) — only the human can relaunch the terminal.
- **Confirm before anything outward-facing or destructive.** Installing tools,
  authenticating, pushing code, setting environment variables, and seeding data
  all touch the user's machine or their real Xano account. Say what you're about
  to do and get a clear go-ahead.
- **Every push is preview → approve → push.** Run `--dry-run` first and show the
  planned changes. Get an explicit "yes" in chat. Only then run the real push.
  Because the agent's shell is non-interactive, the real push needs `--force` to
  get past the CLI's own confirmation prompt — that is fine **after** the user
  approved the previewed change. **Never push unprompted.**
- **Never background `xano auth`.** It needs an interactive browser + terminal
  picker; backgrounding it cancels the flow and writes no credentials. Have the
  **user** run it in their terminal, then poll `xano profile me` until it lands.
- **Be plan-aware.** Detect Free vs paid in Phase 4 and route accordingly. The
  **Free plan is named `build`** internally (`package.name: "build"`); treat
  `build` (or any plan whose workspace entitlement is `1`) as Free.
- **The live catalog is the source of truth.** Fetch it from GitHub each run
  (Phase 5) with a **deterministic** command — never a summarizing web fetch,
  which fabricates repos that don't exist. Offer only names that come back from
  that fetch, and verify the repo exists (HTTP 200) before cloning.
- **Don't maintain a list of plan-gated features.** If a push is rejected because
  the plan lacks a feature, read the error, exclude what it names with `-e`,
  retry, and tell the user that feature was skipped. On Free, pre-exclude the
  gaps you can see in `rolePermissions` (commonly `workspace:workflow_test`).
- **Never invent IDs or instance URLs.** Read them from `xano workspace list`,
  `xano profile me`, or command output. Never guess.
- **Prefer the MCP docs tools over memory.** For exact CLI flags or XanoScript
  syntax, call `xano_cli_docs`, `xano_meta_api_docs`, and `xano_xanoscript_docs`.
- **Say the same thing every run.** Every question and notice below has **defined
  wording** — use it verbatim (fill in the values, keep the structure) so the run
  looks identical each time. Do not improvise your own phrasing for a step that
  has a script.
- **Keep the channel quiet.** Between the defined blocks, narrate as little as
  possible — see *Output discipline* below. Routine tool calls speak for
  themselves; don't wrap them in prose.

---

## Output discipline — quiet by default

The run is hard to follow when routine narration crowds out the messages that
matter. Between the defined blocks, **say as little as possible.** Someone
scanning the transcript should see only: which phase we're in, the defined
questions/blocks, and real errors — nothing in between.

**Only emit:**

1. **One short phase marker** when a phase begins — a single bold line, nothing
   more (e.g. `**Setting up the Xano tools…**`, `**Checking your plan…**`). Not a
   paragraph about what the phase is going to do.
2. **The defined blocks**, verbatim in structure: the intent questions (Phase 0),
   the install confirmation and auth/restart instructions (Phases 1–2), the
   plan-gated notice and dry-run preview (Phase 6), and the final summary (Phase 7).
3. **Real errors** — the raw error plus the single next step. No padding.

**Never emit:**

- **Install logs.** Run every install with output redirected
  (`npm install -g @xano/cli >/dev/null 2>&1`). Never paste npm/download chatter
  into the chat — it's pure noise.
- Narration of tool calls — no "Now I'll run…", "Let me check…", "Great, that
  worked!". The harness already shows the command; don't restate it.
- Recaps of what a command returned, unless it's a decision the user must act on.
- Preambles before, or summaries after, routine steps that simply succeeded —
  go straight to the next phase marker.
- Thinking out loud, option surveys, or reassurance filler.

If a step succeeds and nothing is required of the user, advance **silently** to
the next phase marker.

---

## Phase 0 — Capture intent up front

Settle intent in **one** short exchange before any setup, so it's on record and
survives the restart (the resumed session reads it from the transcript). Skip
whatever the user already told you — don't re-ask. **Defined question:**

```
Two quick things before I set this up:

  1. What do you want to build? Name a xano-community template, or describe the
     goal (e.g. "a CRM", "accept payments", "send emails") and I'll match it to one.
  2. Import it as-is, or make changes after it's in? Either's fine — I just like to
     know up front.

Heads up: a one-time Claude restart happens partway through to load the Xano
tools. I'll walk you through it — nothing to prep.
```

You confirm the exact repo against the live catalog in Phase 5 — don't commit to a
repo name yet. **Where it lands** is derived from the plan (Phase 4), not asked
here; only confirm it later. Don't expand this into a questionnaire.

---

## Phase 1 — Set up the tools (install quietly, then authenticate)

**First, check what's already here** — don't reinstall or re-ask for anything
present. If the Xano MCP tools (`xano_validate_xanoscript`, `xano_cli_docs`,
`xano_xanoscript_docs`) are already available in this session **and**
`xano profile me` succeeds, all of Act 1 is done — skip straight to Phase 3.

Otherwise, check each piece and collect what's missing:

```sh
node --version        # need >= 20.12.0
xano --version        # is the Xano CLI installed?
xano profile me       # is the CLI authenticated?
```

Also note whether the Xano MCP tools are present in this session (if they are, you
won't need to register the MCP or restart).

### Install confirmation (defined wording)

Present only the pieces that are actually missing, then get **one** go-ahead.
**Defined question** (drop any line that isn't needed):

```
To build this I need to set up a couple of things first:

  • Node.js ≥ 20.12.0     — runtime for the Xano CLI
  • Xano CLI (@xano/cli)  — pushes the template into your Xano account
  • Xano Developer MCP    — validates changes and loads Xano's docs into Claude

I'll install these quietly and register the MCP with Claude Code. Okay to go
ahead? (yes / no)
```

If **nothing** is missing, say one line — `Everything's already installed — let's
get you signed in.` — and go to auth.

On "yes", install the missing pieces **silently** (never print install output):

```sh
# Node, only if missing/too old — prefer an existing version manager, else nvm:
#   (install quietly; if you use nvm this session, later shells need it sourced)
npm install -g @xano/cli >/dev/null 2>&1        # the CLI
claude mcp add --scope user xano -- npx -y @xano/developer-mcp   # register the MCP
```

- Register the MCP at **user scope** so it's available in every project, and use
  `npx -y @xano/developer-mcp` (no separate global install needed). If an MCP
  named `xano` already exists, leave it — don't clobber it.
- Re-check `xano --version` after installing the CLI. If any install fails, stop
  and show the raw error with the one command the user can run to fix it.

### Authenticate the CLI (defined wording)

`xano profile me` prints the logged-in user when a valid profile exists. If it
already succeeded above, skip this. Otherwise **the user runs `xano auth`** — never
background it. **Defined instruction:**

```
Now sign in to Xano. In your terminal, run:

    xano auth

Finish the browser login — choose **Sign up** if you don't have an account yet —
then pick your instance when the terminal shows the list. I'll wait and check.
```

If you installed Node via nvm this session, add: `Open a fresh terminal tab first
so xano and node are on your PATH.`

Then **poll**: run `xano profile me` and, if it isn't ready, wait and re-check in a
loop until it succeeds or the ~5-minute auth window elapses. Do not proceed until
`xano profile me` succeeds.

> Headless / SSH (no browser)? Use `xano profile wizard` and paste an access token
> instead — see `references/cli-cheatsheet.md`.

---

## Phase 2 — Restart Claude to load the Xano tools

**Skip this phase entirely if the Xano MCP tools are already present in this
session** (warm session, or you're already resuming) — go to Phase 3.

Otherwise the MCP was just registered and its tools are **not** loaded yet. MCP
servers load only at startup; nothing reloads them mid-session (not `/mcp`, no
hook). **Only the human can relaunch the terminal** — never attempt it from a Bash
call. Hand them the exact resume command. **Defined instruction:**

```
Setup's done. One quick restart loads the Xano tools, then I'll build — no need to
re-run the skill or repeat anything.

Quit Claude Code, and from this same folder run:

    claude --resume ${CLAUDE_SESSION_ID}

That drops you right back into this conversation with the Xano tools live, and I'll
pick up automatically from here.
```

Use `claude --resume ${CLAUDE_SESSION_ID}` (not `--continue`, which grabs the most
recent session in the directory and may be the wrong one). Stop here — the next
thing you do is Phase 3, in the resumed session.

---

## Phase 3 — Verify the Xano tools are live

First step after the resume. Confirm the Xano MCP tools
(`xano_validate_xanoscript`, `xano_cli_docs`, `xano_xanoscript_docs`) are present
and that `xano profile me` still succeeds.

- If the tools **are** present and the CLI is authenticated → continue to Phase 4.
- If the tools are **still not** present → the restart didn't take. Re-issue the
  Phase 2 restart instruction (confirm the MCP is registered with
  `claude mcp list` first; re-add it if missing), and stop.

---

## Phase 4 — Detect the plan and choose the target

**Checking your plan…**

Read the authenticated profile once — it carries the plan, entitlements, and
feature permissions:

```sh
xano profile me -o json
```

Use the **authoritative fields** under `extras.instance` — not the instance name
or host:

- **Plan** — `package.name` (e.g. `pro-2x`). Display it. **`build` is the Free
  plan** — surface it as "Free (build plan)" so the user recognizes it.
- **Workspace entitlement** — `k8s.additional.workspaces`: the number of
  workspaces the plan allows. **`1` → Free, `> 1` → paid.** Decisive; trust it
  over `package.name` if they disagree.
- **Feature permissions** — `membership.rolePermissions` (mirrored in
  `access_token.scope`): per-feature keys such as `workspace:workflow_test`. A
  missing/zero key means the plan doesn't include that feature.

If those fields aren't present, fall back: count `xano workspace list`, and/or run
`xano sandbox get` (provisions on paid, **errors on Free** — sandbox is
paid-only). If still unsure, ask.

**Route the target:**

- **Paid → the sandbox** by default — safe, disposable, doesn't consume a
  workspace slot (so it also covers a paid user out of workspaces):
  ```sh
  xano sandbox get         # provisions the sandbox on first call
  ```
  If a paid user explicitly wants an **existing workspace**, push there with
  `xano workspace push -w <id>` instead, same confirm rules.
- **Free → their one existing workspace.** Free can't create workspaces and can't
  use the sandbox, so use the one they have:
  ```sh
  xano workspace list      # take the existing workspace id
  ```
  If a Free user asked for a **sandbox** or a **fresh build**, explain plainly that
  their plan pushes into their existing workspace instead, and continue there.

**Pre-flag gated features.** Note whatever `rolePermissions` shows the plan lacks
(most commonly `workspace:workflow_test` on Free). Once you know which of those the
chosen item actually contains (Phase 6, after reading the repo), carry them as
`-e` excludes into **both** the dry-run and the real push so the preview matches
exactly what pushes.

Note the target (workspace id, or "sandbox") and the plan gaps — Phase 6 uses
them. Deliver the gated *notice* in Phase 6, once you know which gated features the
chosen item actually touches.

---

## Phase 5 — Pull the live catalog and pick an item

**Picking a template…**

**Fetch the catalog from GitHub every run — there is no embedded list.** Use a
**deterministic** command (parse names directly); never read repo names out of a
summarizing web fetch, which fabricates repos that don't exist.

1. **List the org's repos deterministically.**
   ```sh
   gh repo list xano-community --limit 200                       # preferred
   # no gh? parse the API yourself — do NOT summarize it:
   curl -fsSL "https://api.github.com/orgs/xano-community/repos?per_page=100" \
     | jq -r '.[].name'
   ```
   > **Catalog source / proxy hook.** If a catalog proxy is configured — env
   > `XANO_CATALOG_URL` set in this session — fetch that URL instead; it returns
   > the same shape (a list of repo names, or `{name,...}` objects). A proxy lets
   > the org curate the list and avoids GitHub's unauthenticated rate limits
   > without embedding credentials. When it's unset, the GitHub listing above is
   > the source of truth.

2. **Match intent → repo.** Map the user's Phase 0 intent to a name from the list.
   Convention: **`integration-*`** repos are third-party integrations; the rest
   are full apps / modules. `references/templates.md` has a goal→repo hint map and
   the two on-disk layouts — treat it as a *hint*, not the source: the real name
   **must appear in the fetched list**. If several fit, show the shortlist with the
   **defined wording** and let the user pick:

   ```
   A few in the catalog fit "<what they asked for>":

     1. <repo> — <one-line description>
     2. <repo> — <one-line description>
     3. <repo> — <one-line description>

   Which one? (reply with a number, or tell me more about what you need.)
   ```

   If nothing fits, say so and show what the org actually has — don't guess a name.

3. **Verify the repo exists before cloning** (HTTP 200):
   ```sh
   gh api repos/xano-community/<repo> >/dev/null   # or:
   curl -s -o /dev/null -w '%{http_code}\n' https://github.com/xano-community/<repo>
   ```
   If it's not 200, re-list and correct — never push ahead on a name that doesn't
   resolve.

4. **Read the repo's `README.md` — it's the per-item fine print.** Its **Install**
   section is the source of truth for *which directory to push* (`push_dir`), any
   *required env vars*, whether there's a *frontend* to wire up, and any *seed
   endpoint*. Read it before importing; don't assume from the name.

---

## Phase 6 — Preview the import with a dry-run

Get the code on disk:

```sh
git clone https://github.com/xano-community/<repo>.git && cd <repo>
```

The push directory comes from the repo's README: **full apps → `backend/`**,
**integrations → the repo root (`.`)**.

### Plan-gated notice (defined wording)

Check what the item contains (from the clone) against the plan gaps from Phase 4
(what `rolePermissions` lacks). If the item uses a gated feature (e.g. a
`workflow_test/` directory on a plan without `workspace:workflow_test`), say this
**before** the dry-run — keep the structure:

```
Heads up on your plan (Free / build):

  ✓ Everything that makes this template work will import and run.
  ✗ Skipping: workflow tests — your plan doesn't include them.

This won't affect the running app; you'd only use workflow tests for automated
end-to-end checks. You can enable them later by upgrading your plan in the Xano
dashboard (Billing).

I'll exclude that and push the rest now.
```

Lead with the reassurance that the result still works, name exactly what's skipped
and why, and point to upgrading in the dashboard (link `app.xano.com` or say
"Billing in your account settings" — don't invent a billing path). If the item
uses **no** gated features, say one line — "Your plan covers everything in this
template" — and go straight to the preview.

### Preview → approve → push

Show the `--dry-run` output as a **defined summary** (same shape every run):

```
Dry run — nothing has been pushed yet. This previews what the real push will do.

Target: <workspace name (id)>  ·  or: sandbox
Will create/update: <N> objects  (<e.g. 12 APIs, 4 tables, 3 functions>)
Excluded (plan-gated): workflow tests        # omit this line if nothing excluded

Reply "yes" to push for real, or tell me what to change.
```

Apply the same `-e <glob>` excludes to **both** the dry-run and the real push so
the preview is honest.

**Free — direct workspace push:**
```sh
xano workspace push -d ./backend -w <id> [-e 'workflow_test/**'] --dry-run
```

**Paid — sandbox push:**
```sh
xano sandbox get
xano sandbox push -d ./backend --dry-run
```

> Don't use `xano sandbox push --review` — it auto-opens the browser. We summarize
> with links at the end (Phase 7).

---

## Phase 7 — Push after approval, verify, configure, and hand off

Only after the user replies "yes" in chat, run the real push with `--force`
(required for the non-interactive shell; used **only** after approval). Carry the
same excludes as the dry-run.

**Free:**
```sh
xano workspace push -d ./backend -w <id> [-e 'workflow_test/**'] --force
```

**Paid:**
```sh
xano sandbox push -d ./backend [-e 'workflow_test/**'] --force
```

### Plan-gated content (error-driven — no maintained list)

If the push is rejected because the plan doesn't support a feature — e.g.
`Push failed (400): … Please upgrade to access workflow tests` — identify the
files ("workflow tests" → the `workflow_test/` directory), exclude them, retry,
and tell the user that feature was skipped:

```sh
xano workspace push -d ./backend -w <id> -e 'workflow_test/**' --force   # Free
xano sandbox push   -d ./backend         -e 'workflow_test/**' --force   # Paid
```

`-e/--exclude` takes globs relative to the push dir and is repeatable — **use it
instead of deleting files from the clone.** Read each error and exclude only what
it names. Cap at a few retries; if it still fails for another reason, stop and
report the raw error.

### Confirm the push actually landed — don't assume

A push can be **rejected and leave nothing imported**. Never report success off
the absence of an error or a dry-run alone — **verify the objects are really
there:**

```sh
xano workspace get -w <id>   # Free — confirm object counts > 0
xano sandbox get             # paid — confirm the sandbox has the pushed objects
```

Check the count of created/updated objects matches what the dry-run promised
(minus intentional excludes). If the real push returned non-zero, a `4xx/5xx`, or
`0` objects landed, the import did **not** succeed — surface the raw error, retry
with the right exclude if plan-gated, and do **not** hand off until a verified push
exists.

### Modifications (optional)

If the user asked to modify the item (rename things, add fields/endpoints, change
logic), the Xano Developer MCP is already loaded (Phase 3 verified it) — no further
restart:

1. The clone in Phase 6 gives you the code on disk (otherwise
   `xano workspace pull -d ./code -w <id>` or `xano sandbox pull -d ./code`).
2. Edit the relevant `.xs` files — organized by type (`api/<group>/`, `function/`,
   `table/`, `task/`, `ai/agent/`, …). Use `xano_xanoscript_docs` for syntax and
   `xano_cli_docs` for structure.
3. **Validate every change** with `xano_validate_xanoscript` before pushing.
4. Push to the same target, preview → approve → `--force`, then re-verify.

### Configure and hand off

**Do not auto-open anything** — finish by summarizing with links and next steps.
Use the repo's README (Install/Configure section) as the checklist:

- **Environment variables** — integrations need keys (e.g. `STRIPE_API_KEY`,
  named in the README's `.env.example`). Set them in the Xano dashboard, or
  `xano sandbox env set` for a sandbox. Never hardcode secrets into `.xs` files.
  Walk the user through obtaining each key.
- **Seed / demo data** — if the README documents a seed endpoint, offer to call it
  (e.g. `curl -X POST https://<instance>.xano.io/api:<group>/seed`).
- **Frontend** — full-app templates often ship a single-file `frontend/index.html`
  with an `API_BASE` constant near the top. **Get the base URL yourself and fill it
  in — never tell the user to open Xano and copy it.** See "Look up the API base
  URL" below, then edit the file directly.
- **Tests** — run unit tests if present: `xano unit_test run_all -w <id>`. Workflow
  tests are paid-gated; only run `xano workflow_test run_all` if the plan supports
  them.

#### Look up the API base URL (automatic — no user intervention)

The base URL is `https://<instance-host>/api:<canonical>`, where `<canonical>` is
the API group's slug. Resolve it from the Meta API after the push:

```sh
HOST=$(xano profile me -o json | jq -r '.extras.instance.xano_domain // .extras.instance.host')
TOKEN=$(grep -A20 'default' ~/.xano/credentials.yaml | grep -m1 'access_token' | awk '{print $2}')
curl -s "https://$HOST/api:meta/workspace/<id>/apigroup" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.items[] | "\(.name): \(.canonical)"'
```

Read each group's `canonical` and join it to the host. Field names can vary —
inspect the raw JSON if needed (`xano_meta_api_docs topic=apigroup`). **Never ask
the user to open Xano and copy the base URL.** Match the API group named in the
repo's README to its base URL.

Then summarize, without opening a browser:

- the plan (shown as "Free (build plan)" when applicable) and **where it landed** —
  workspace name + id, or the sandbox;
- **what was pushed**, and **anything skipped** for plan reasons (and why) — same
  framing as the Phase 6 notice: the result still works;
- the **API group base URL** — resolved above, never asked of the user;
- any **env vars** still needing real values;
- **next steps and links** — the Xano dashboard URL, and for paid the sandbox
  review URL via `xano sandbox review --url-only` (printed, not opened).

---

## Reference files

- `references/templates.md` — how to list the org **deterministically** (the live
  catalog source of truth), the goal→repo hint map, and the two on-disk layouts.
- `references/cli-cheatsheet.md` — the Xano CLI commands this skill relies on:
  install, auth, plan detection, sandbox, selective push, and the base-URL lookup.
</content>
</invoke>
