---
name: start-xano-build
description: >-
  Start a new Xano backend build from a xano-community GitHub template. Use when
  a user wants to spin up, scaffold, import, install, or "start a Xano build/app/
  backend from a template," fork a xano-community repo into Xano, or build on top
  of one of the Xano community templates. Handles the full path: verifying the
  Xano CLI is installed, the Xano Developer MCP is enabled in the current tool
  (Claude Code, Cursor, Codex, GitHub Copilot, or OpenCode), and the CLI is
  authenticated (including helping a brand-new user create a Xano account), then
  detecting whether the account is Free or paid, importing the template into the
  right target (a paid sandbox or a Free workspace), and applying any
  modifications the user asks for.
---

# Start a Xano build from a template

This skill takes a user from zero to a working Xano backend built from a
[xano-community](https://github.com/orgs/xano-community/repositories) GitHub
template. Run the phases **in order** — each one gates the next. Do not skip a
phase because it "looks" done; verify it.

The end state: the user has an authenticated Xano CLI and the chosen template
imported into the right place for their plan — the **sandbox** for paid
accounts, their **existing workspace** for Free accounts — plus any
modifications they asked for.

## Guardrails

- **Confirm before anything outward-facing or destructive.** Authenticating,
  pushing code, setting environment variables, and seeding data all touch the
  user's real Xano account. Say what you're about to do and get a clear
  go-ahead.
- **Every push is preview → approve → push.** Run `--dry-run` first and show the
  user the planned changes. Get an explicit "yes" in chat. Only then run the real
  push. Because the agent's shell is non-interactive, the real push needs
  `--force` to get past the CLI's own terminal confirmation prompt — that is fine
  **after** the user approved the previewed change. **Never push unprompted.**
- **Be plan-aware.** Detect Free vs paid in Phase 2 and route the push
  accordingly: Free → the user's one existing workspace; paid → the sandbox. The
  **Free plan is named `build`** internally (`package.name: "build"`) — it's no
  longer called "Build" publicly, but the profile still reports it that way, so
  treat `build` (or any plan whose workspace entitlement is `1`) as Free.
- **Say the same thing every run.** The user should not see different wording or
  a different flow each time. Four touchpoints have **defined scripts** you must
  follow rather than improvising: the install menu (Phase 1), the dry-run preview
  (Phase 4), the plan-gated notice (Phase 4), and the final summary (Phase 6).
  Fill in the values, keep the structure.
- **Don't maintain a list of plan-gated features.** If a push is rejected because
  the plan doesn't support something (e.g. workflow tests), read the error,
  exclude what it names with `-e`, retry, and tell the user that feature was
  skipped because their plan doesn't support it.
- **Read template names from a deterministic source — never a summarizing web
  fetch.** Use `gh` or `curl` + parsing. Summaries can fabricate repos that don't
  exist. Verify a repo exists (HTTP 200) before cloning.
- **Never background `xano auth`.** It needs an interactive picker; backgrounding
  it cancels the flow. Have the user run it and poll for completion (Phase 1d).
- **Respect CLI safety markers.** Xano CLI help text prefixes risky commands with
  `[CRITICAL]` (never run without explicit confirmation in the same turn) and
  `[IMPORTANT]` (run `--dry-run` first and show the output). Honor them.
- **Never invent IDs or instance URLs.** Read them from `xano workspace list`,
  `xano profile me`, or command output. If you don't have a value, get it from a
  command or the user — don't guess.
- **Prefer the MCP docs tools over memory.** For exact CLI flags or XanoScript
  syntax, call `xano_cli_docs`, `xano_meta_api_docs`, and `xano_xanoscript_docs`
  rather than recalling them.

---

## Phase 0 — Capture intent up front

Before any preflight, settle two things in **one** short exchange (skip whatever
the user already told you — don't re-ask):

1. **What are we building?** A specific template name, or a goal to match to one
   ("a CRM", "send emails"). You confirm the real repo against the live list in
   Phase 3 — here you just need the intent.
2. **Any modifications, or import the template as-is?** Ask this **now**, not
   after the import. It changes the run: modifications require the Xano Developer
   MCP, which only loads after a tool restart (Phase 1c / Phase 5), so the user
   should know up front that a restart is coming.

If they want changes, tell them plainly: *"I'll install the Xano MCP now so it's
ready, import the template, then you'll restart once before I make your edits."*
That sets expectations so the restart later isn't a surprise.

Don't expand this into a questionnaire — two questions, then move on.

---

## Phase 1 — Preflight: tools and authentication

Check everything first, then act. Run checks 1a–1c and **collect what's
missing**, present a single consolidated plan, get **one** go-ahead, then install
it all hands-off. Do not ask which install method to use and do not prompt per
tool. Authentication (1d) is the one unavoidable interactive step and comes after
the tools are in place.

### 1a. Node.js ≥ 20.12.0

```sh
node --version
```
Most users already have this. If it's missing or older, plan to install it the
standard way for their machine **without asking how** — prefer an existing
version manager, otherwise nvm (`nvm install 20`) or nodejs.org.

> If you install Node via nvm **in this session**, it won't be on `PATH` for new
> shells you spawn until sourced — prefix later commands with
> `export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"`. New terminals the *user*
> opens pick it up automatically (this matters for the `xano auth` step).

### 1b. Xano CLI installed

```sh
xano --version
```
→ If "command not found", plan: `npm install -g @xano/cli`
(https://www.npmjs.com/package/@xano/cli). Re-check after installing.

### 1c. Xano Developer MCP enabled in the current tool

The Xano Developer MCP (`@xano/developer-mcp`) gives you XanoScript validation
and live docs. **It's only required to *modify* XanoScript (Phase 5).** An
import-only build (Phases 1–4, 6) runs fine without it.

**First, check whether you already have it.** If Xano MCP tools (e.g.
`xano_validate_xanoscript`, `xano_cli_docs`, `xano_xanoscript_docs`) are
available in this session, it's enabled — say so and move on.

→ If not available, **always plan to register it** (don't skip it just because
this run is import-only) using the matching block in **`references/mcp-setup.md`**
for the tool you're in. Registering it now means it's ready the moment the user
wants changes, with no second setup trip. Adding an MCP server requires
**restarting the session before its tools load** — you cannot use them in the
same session they were added. The registration is cheap; only the restart has a
cost, and you only pay it when modifications are actually requested:

- **Import-only run** → register the MCP, but no restart is needed now. Just note
  it's installed and ready if they later want changes.
- **Modifications requested** (known from Phase 0) → register it, then before
  Phase 5 have the user restart. See "Restarting back into this same session"
  below — give them an exact resume command so they land right back here mid-run,
  not in a fresh skill invocation.

#### Restarting back into this same session

A real restart is unavoidable (MCP servers load only at startup; nothing reloads
them mid-session — not `/mcp`, no hook), and **only the human can do it.**

> **Never try to restart the host yourself** — no `kill`/`pkill` of the `claude`
> process, no `kill <pid> && claude --resume …` one-liner. Your Bash commands run
> as a *descendant* of the interactive host, so killing it also kills the shell
> mid-relaunch, and any process you spawn has no terminal to attach to — you'd
> leave the user with a dead prompt and an orphaned headless session. Re-attaching
> to the terminal can only be done by its own foreground shell, i.e. the human.

So hand them the precise command to relaunch **this exact conversation** with the
MCP live: 

- **Claude Code** → you know this session's ID from the `${CLAUDE_SESSION_ID}`
  skill substitution. Tell the user to quit Claude Code and, **from this project
  directory** (resume lookup is dir-scoped), run:
  ```sh
  claude --resume ${CLAUDE_SESSION_ID}
  ```
  This drops them back into the current transcript — they do **not** re-invoke
  the skill; we just continue from Phase 5. Prefer `--resume <id>` over
  `--continue`: `--continue` grabs the *most recent* session in the directory,
  which is the wrong one if they have others open.
- **Other tools** (Cursor, Codex, Copilot, OpenCode) → no equivalent
  resume-by-id; tell them to restart the tool and re-invoke the skill, and we
  pick up at Phase 5.

### Consolidated install step

After 1a–1c, present what's missing as a **fixed menu** (same shape every run —
this is one of the four defined touchpoints). List each missing item as a numbered
line, then offer the same three choices. Only list items that are actually
missing:

```
Here's what's needed before we build. I found these missing:

  1. Node.js ≥ 20.12.0      — runtime for the CLI
  2. Xano CLI (@xano/cli)   — pushes the template to your account
  3. Xano Developer MCP     — validates XanoScript (needed if you customize)

How do you want to proceed?
  • Install all  — I set up everything above, hands-off (recommended)
  • Pick some    — tell me which numbers to install
  • Cancel
```

Get one answer, then install the chosen items non-interactively — no per-tool
prompts, no asking which install method. If nothing is missing, say so in one
line and skip straight to 1d.

### 1d. CLI authenticated with a Xano account

```sh
xano profile me
```
This prints the logged-in user (id, name, email, instance) when a valid profile
exists. If it succeeds, Phase 1 is done.

→ If it errors or no profile exists, authenticate with browser login — but
**have the user run it; never background it.** `xano auth` opens the browser and
then drops to an **interactive instance/workspace/branch picker** in the
terminal. There is no flag to preselect the instance, and a backgrounded run
can't answer the picker (it cancels and writes no credentials).

Tell the user:

> Run `xano auth` in your terminal, finish the browser login, and pick your
> instance when the list appears.

If you just installed Node via nvm this session, tell them to **open a new
terminal tab** first so `xano`/`node` are on `PATH`.

Then **poll** until it lands — run `xano profile me` and, if it isn't ready,
wait and re-check (loop) until it succeeds or the 5-minute auth window elapses.
Do not proceed until `xano profile me` succeeds.

**Brand-new user with no Xano account?** Same flow — the page `xano auth` opens
has a **sign-up** option. Tell them: "Choose sign up, create your account, and
you'll be sent right back to the CLI authenticated." No separate step needed.

> Headless / SSH (no browser)? Use `xano profile wizard` and paste an access
> token instead. See `references/cli-cheatsheet.md`.

**Do not proceed to Phase 2 until `xano profile me` succeeds.**

---

## Phase 2 — Detect the plan and choose the push target

Read the authenticated profile once — it carries the plan, entitlements, and
feature permissions, which together decide where the template goes:

```sh
xano profile me -o json
```

Use the **authoritative fields** under `extras.instance` — not the instance name
or host:

- **Plan** — `package.name` (e.g. `pro-2x`). Display it to the user. **`build`
  is the Free plan** (its public name changed but the profile still says
  `build`) — surface it as "Free (build plan)" so the user recognizes it.
- **Workspace entitlement** — `k8s.additional.workspaces`: the number of
  workspaces the plan allows. This is the **decisive** Free/paid signal:
  **`1` → Free, `> 1` → paid.** `package.name: "build"` corroborates Free; if the
  two ever disagree, trust the entitlement count.
- **Feature permissions** — `membership.rolePermissions` (mirrored in
  `access_token.scope`): per-feature keys such as `workspace:workflow_test`. A
  missing/zero key means the plan doesn't include that feature.

If those fields aren't present (profile shape can vary by plan/version), fall
back: count `xano workspace list`, and/or run `xano sandbox get` — it provisions
on paid and **errors on Free** (sandbox is paid-only), a definitive probe. If
still unsure, ask the user.

**Set the target:**

- **Paid → the sandbox.** A safe, disposable staging area the user promotes from
  in the browser. Because it doesn't consume a workspace slot, this also cleanly
  handles a paid user who is **out of workspaces**.
  ```sh
  xano sandbox get         # provisions the sandbox on first call
  ```
  Exception: if a paid user explicitly wants to build **into a specific existing
  workspace** (integrating into work they already have), push there with
  `xano workspace push -w <id>` instead, same confirm rules.

- **Free → their one existing workspace.** Free accounts can't create extra
  workspaces and can't use the sandbox, so use the workspace they have:
  ```sh
  xano workspace list      # take the existing workspace id
  ```
  Don't offer to create one. The experience is intentionally a little less
  seamless here — every push is confirmed (Phase 4).

**Pre-flag gated features (so the push never gets surprised).** If
`rolePermissions` lacks a feature key — most commonly `workspace:workflow_test` on
Free — you already know the plan can't import it. **Exclude it from the start** (in
both the dry-run and the real push, Phase 4) instead of letting the push fail and
reacting. This is what keeps the run consistent: a Free user gets the same clean
push every time, not a reject-then-retry on one run and a smooth push on another.
The error-driven exclude in Phase 4 stays as the safety net for anything you
didn't anticipate.

Deliver the gated notice **after the user picks a template** (Phase 3), once you
know which gated features that template actually touches — not as an abstract
warning here. Hold this finding for then. The wording is defined in Phase 4.

Note the target (workspace id, or "sandbox") and any pre-excludes — Phase 4 uses
them.

---

## Phase 3 — Pick the template and understand its layout

Templates live in the **xano-community** GitHub org. There are two broad shapes
(see `references/templates.md` for the catalog and conventions):

- **Full apps** (e.g. `todo-app`, `support-ticketing`, `client-intake`) — a
  `backend/` directory (the pushable XanoScript), often a `frontend/index.html`,
  and a `multidoc/` bundle.
- **Integrations** (e.g. `integration-stripe-payments`, `integration-resend-email`)
  — `functions/` and `tables/` at the repo root, plus environment variables.

**Get the catalog deterministically — do not read repo names out of a
summarizing web fetch.** Summaries can invent templates that don't exist.

```sh
gh repo list xano-community --limit 200            # preferred
# no gh? parse the API yourself — don't summarize it:
curl -s "https://api.github.com/orgs/xano-community/repos?per_page=100" | jq -r '.[].name'
# (or: ... | grep '"name"')
```

If the user named a template, use it. If they described a goal ("a CRM", "send
emails", "accept payments"), match it to a repo via `references/templates.md` —
but treat that as a hint: **the real repo name must appear in the live list.**

**Verify the repo exists before cloning** (HTTP 200):

```sh
gh api repos/xano-community/<repo> >/dev/null   # or:
curl -s -o /dev/null -w '%{http_code}\n' https://github.com/xano-community/<repo>
```

If it's not 200, re-list and correct — never push ahead on a guessed name.

**Then read the chosen repo's `README.md`.** Its **Install** section is the
source of truth for *which directory* to push and *what env vars / frontend
config* the template needs.

---

## Phase 4 — Import the template into the target

Get the code on disk (clone is best when modifications are likely):

```sh
git clone https://github.com/xano-community/<repo>.git && cd <repo>
```

The README names the push directory: **full apps → `backend/`**, **integrations
→ the repo root (`.`)**.

### Plan-gated notice (defined wording)

Now that the template is chosen, check what it contains against the plan gaps you
found in Phase 2. If the template uses a feature the plan doesn't include (e.g.
the `backend/` has a `workflow_test/` directory and the plan lacks
`workspace:workflow_test`), say this **before** the dry-run — defined touchpoint,
keep the structure:

```
Heads up on your plan (Free / build):

  ✓ Everything that makes this template work will import and run.
  ✗ Skipping: workflow tests — your plan doesn't include them.

This won't affect the running app; you'd only use workflow tests for automated
end-to-end checks. You can enable them later by upgrading your plan in the Xano
dashboard (Billing).

I'll exclude that and push the rest now.
```

Lead with the reassurance that the result still works, name exactly what's
skipped and why, and point them to upgrading in the dashboard. Don't paste a
guessed billing URL — link the dashboard you already know (`app.xano.com`) or say
"Billing in your account settings" rather than inventing a path. If the template uses **no** gated
features, say one line — "Your plan covers everything in this template" — and
skip straight to the preview. List only features the template actually contains;
don't warn about gates that don't apply here.

Carry the corresponding `-e` excludes into **both** the dry-run and the real push
below, so the preview matches exactly what gets pushed.

### Preview → approve → push

Every push is **preview → approve → push**. Show the `--dry-run` output, get an
explicit "yes" in chat, then run the real push with `--force` (required for the
non-interactive shell, used only after approval).

Present the dry-run as a **defined summary** (don't free-form a different shape
each run):

```
Dry run — nothing has been pushed yet. This previews what the real push will do.

Target: <workspace name (id)>  ·  or: sandbox
Will create/update: <N> objects  (<e.g. 12 APIs, 4 tables, 3 functions>)
Excluded (plan-gated): workflow tests        # omit this line if nothing excluded

Reply "yes" to push for real, or tell me what to change.
```

Apply the same `-e <glob>` excludes (from the plan-gated notice) to **both** the
dry-run and the real push so the preview is honest.

**Free — direct workspace push:**

```sh
# pre-exclude known plan gaps from the start, e.g. -e 'workflow_test/**' on Free:
xano workspace push -d ./backend -w <id> [-e 'workflow_test/**'] --dry-run   # preview
# → user approves, then (same excludes):
xano workspace push -d ./backend -w <id> [-e 'workflow_test/**'] --force
```

**Paid — sandbox push:**

```sh
xano sandbox get                          # ensure the sandbox exists
xano sandbox push -d ./backend --dry-run  # show this preview
# → user approves, then:
xano sandbox push -d ./backend --force
```

> Don't use `xano sandbox push --review` — it auto-opens the browser. We
> summarize with links at the end instead (Phase 6).

### Plan-gated content (error-driven — no maintained list)

If a push is rejected because the plan doesn't support a feature — e.g.
`Push failed (400): … Please upgrade to access workflow tests` — identify the
matching files (**"workflow tests" → the `workflow_test/` directory**), exclude
them, retry, and tell the user that feature was skipped because their plan
doesn't support it:

```sh
xano workspace push -d ./backend -w <id> -e 'workflow_test/**' --force   # Free
xano sandbox push   -d ./backend         -e 'workflow_test/**' --force   # Paid
```

`-e/--exclude` takes globs relative to the push dir and is repeatable — **use it
instead of deleting files from the clone.** Read each error and exclude only what
it names. Cap this at a few retries; if it still fails for a different reason,
stop and report the raw error.

### Confirm the push actually landed — don't assume

A push can be **rejected and leave nothing imported** (this is how a run silently
"completes" with an empty workspace). Never report success off the absence of an
error or a dry-run alone — **verify the objects are really there:**

```sh
xano workspace get -w <id>   # Free   — confirm object counts > 0
xano sandbox get             # paid   — confirm the sandbox has the pushed objects
```

Check that the count of created/updated objects matches what the dry-run
promised (minus anything intentionally excluded). If the real push returned a
non-zero exit, a `4xx/5xx`, or `0` objects landed, the import did **not** succeed
— treat it as a failure: surface the raw error, retry with the right exclude if
it was plan-gated, and do **not** advance to Phase 5/6 until a verified push
exists. A rejected `workflow_test` push that you didn't pre-exclude is the
classic cause — exclude it and re-push, then re-verify.

---

## Phase 5 — Apply the user's build instructions

If the user only wanted the template imported as-is, skip to Phase 6.

If they asked for modifications (rename things, add fields/endpoints, change
logic, wire in another integration):

1. **The Xano Developer MCP must be loaded** for this phase (it validates
   XanoScript). If you added it in Phase 1 and its tools still aren't available,
   the user must restart first — hand them the exact resume command from
   **"Restarting back into this same session"** (Phase 1c). On Claude Code that's
   `claude --resume ${CLAUDE_SESSION_ID}` from this directory, which lands them
   back here so we continue straight into this phase (no skill re-invoke).
2. Make sure the code is on disk (the clone in Phase 4 gives you this; otherwise
   `xano workspace pull -d ./code -w <id>` or `xano sandbox pull -d ./code`).
3. Edit the relevant `.xs` files — organized by type (`api/<group>/`,
   `function/`, `table/`, `task/`, `ai/agent/`, …). Use `xano_xanoscript_docs`
   for syntax and `xano_cli_docs` for structure.
4. **Validate every change** with `xano_validate_xanoscript` before pushing.
5. Push to the same target as Phase 4, preview → approve → `--force`.

---

## Phase 6 — Configure, verify, and hand off

**Do not auto-open anything** — finish by summarizing with links and next steps.

Depending on the template (the README spells out which apply):

- **Environment variables** — integrations need keys (e.g. `STRIPE_API_KEY`). Set
  them in the Xano dashboard, or `xano sandbox env set` for a sandbox. Never
  hardcode secrets into `.xs` files. Walk the user through obtaining each key.
- **Seed / demo data** — many apps expose a `POST /seed` endpoint. Offer to call
  it (e.g. `curl -X POST https://<instance>.xano.io/api:<group>/seed`).
- **Frontend** — full-app templates often ship `frontend/index.html` with an
  `API_BASE` constant near the top. **Get the base URL yourself and fill it in —
  never tell the user to open Xano and copy it.** You have everything needed: the
  instance host (from `xano profile me -o json`) and the token (from
  `~/.xano/credentials.yaml`). See "Look up the API base URL" below, then edit
  `API_BASE` in the file directly.
- **Tests** — run unit tests if present: `xano unit_test run_all -w <id>`.
  Workflow tests are paid-gated; only run `xano workflow_test run_all` if the
  plan supports them.

### Look up the API base URL (automatic — no user intervention)

The base URL is `https://<instance-host>/api:<canonical>`, where `<canonical>` is
the API group's slug. **Resolve it from the Meta API after the push** — there's no
reason to ask the user to fetch it:

```sh
# instance host from the authenticated profile:
HOST=$(xano profile me -o json | jq -r '.extras.instance.xano_domain // .extras.instance.host')
# access token the CLI already stored:
TOKEN=$(grep -A20 'default' ~/.xano/credentials.yaml | grep -m1 'access_token' | awk '{print $2}')
# list the workspace's API groups; read each group's canonical/base URL:
curl -s "https://$HOST/api:meta/workspace/<id>/apigroup" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.items[] | "\(.name): \(.canonical)"'
```

The `listApiGroups` response carries each group's `canonical` (and a full base
URL field) — join it to the host. If the exact field names differ on the account,
read the raw JSON and pick the base URL out of it; **don't fall back to asking the
user.** (Field shapes can vary — `xano_meta_api_docs topic=apigroup` is the
reference.) Match the API group named in the template's README to its base URL.

Then summarize, without opening a browser:

- the plan (Free/paid, shown as "Free (build plan)" when applicable) and **where
  it landed** — workspace name + id, or the sandbox;
- **what was pushed**, and **anything skipped** for plan reasons (and why) — same
  framing as the Phase 4 gated notice: the result still works;
- the **API group base URL** — resolved above, never asked of the user;
- any **env vars** still needing real values;
- **next steps and links** — the Xano dashboard URL, and for paid the sandbox
  review URL via `xano sandbox review --url-only` (printed, not opened).

---

## Reference files

- `references/mcp-setup.md` — how to enable the Xano Developer MCP in Claude
  Code, Cursor, Codex, GitHub Copilot, and OpenCode.
- `references/cli-cheatsheet.md` — the CLI commands this skill relies on,
  including plan detection, sandbox, selective push, and the headless auth
  fallback.
- `references/templates.md` — the xano-community catalog, the two template
  layouts, and the deterministic-listing guardrail.
