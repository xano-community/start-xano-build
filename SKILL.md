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
  accordingly: Free → the user's one existing workspace; paid → the sandbox.
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

→ If not available, plan to add it using the matching block in
**`references/mcp-setup.md`** for the tool you're in. Adding an MCP server
requires **restarting the session before its tools load** — you cannot use them
in the same session they were added. So: if the user only wants the template
imported, proceed without it (note that modifications would need a restart). If
the build includes modifications, add it, then ask the user to restart and
re-invoke the skill before Phase 5.

### Consolidated install step

After 1a–1c, tell the user exactly what's missing and what you'll do — e.g.
*"Node, the Xano CLI, and the Xano MCP aren't set up. I'll install Node, install
`@xano/cli`, and register the MCP. Proceed?"* — get one confirmation, then
install everything non-interactively. If nothing is missing, skip straight to
1d.

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

- **Plan** — `package.name` (e.g. `pro-2x`). Display it to the user.
- **Workspace entitlement** — `k8s.additional.workspaces`: the number of
  workspaces the plan allows. This is the **decisive** Free/paid signal:
  **`1` → Free, `> 1` → paid.**
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

**Pre-flag gated features.** If `rolePermissions` lacks `workspace:workflow_test`
(or another feature a template uses), you already know the plan can't import it —
plan to exclude it in Phase 4 and tell the user, rather than waiting for the push
to fail. The error-driven exclude in Phase 4 stays as the safety net regardless.

Note the target (workspace id, or "sandbox") — Phase 4 uses it.

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

Every push is **preview → approve → push**. Show the `--dry-run` output, get an
explicit "yes" in chat, then run the real push with `--force` (required for the
non-interactive shell, used only after approval).

**Free — direct workspace push:**

```sh
xano workspace push -d ./backend -w <id> --dry-run     # show this preview
# → user approves, then:
xano workspace push -d ./backend -w <id> --force
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

After it lands, confirm: `xano workspace get -w <id>` (Free) or
`xano sandbox get` (paid).

---

## Phase 5 — Apply the user's build instructions

If the user only wanted the template imported as-is, skip to Phase 6.

If they asked for modifications (rename things, add fields/endpoints, change
logic, wire in another integration):

1. **The Xano Developer MCP must be loaded** for this phase (it validates
   XanoScript). If you added it in Phase 1, the user must restart their tool and
   re-invoke the skill before you can use it.
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
  `API_BASE` constant near the top. Tell the user to point it at the API group's
  base URL, then open the file.
- **Tests** — run unit tests if present: `xano unit_test run_all -w <id>`.
  Workflow tests are paid-gated; only run `xano workflow_test run_all` if the
  plan supports them.

Then summarize, without opening a browser:

- the plan (Free/paid) and **where it landed** — workspace name + id, or the
  sandbox;
- **what was pushed**, and **anything skipped** for plan reasons (and why);
- the **API group base URL** (look it up via the Meta API if no command shows it);
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
