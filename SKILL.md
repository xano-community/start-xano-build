---
name: start-xano-build
description: >-
  Start a new Xano backend build from a xano-community GitHub template. Use when
  a user wants to spin up, scaffold, import, install, or "start a Xano build/app/
  backend from a template," fork a xano-community repo into a Xano workspace, or
  build on top of one of the Xano community templates. Handles the full path:
  verifying the Xano CLI is installed, the Xano Developer MCP is enabled in the
  current tool (Claude Code, Codex, GitHub Copilot, or OpenCode), and the CLI is
  authenticated (including helping a brand-new user create a Xano account), then
  creating a workspace and importing the template — applying any modifications
  the user asks for.
---

# Start a Xano build from a template

This skill takes a user from zero to a working Xano backend built from a
[xano-community](https://github.com/orgs/xano-community/repositories) GitHub
template. Run the phases **in order** — each one gates the next. Do not skip a
phase because it "looks" done; verify it.

The end state: the user has an authenticated Xano CLI, a target workspace, and
the chosen template pushed into that workspace — plus any modifications they
asked for.

## Guardrails

- **Confirm before anything outward-facing or destructive.** Creating a
  workspace, pushing code, setting environment variables, and running `xano
  auth` all touch the user's real Xano account. Tell the user what you're about
  to do and get a clear go-ahead the first time in each phase.
- **Respect CLI safety markers.** Xano CLI help text prefixes risky commands
  with `[CRITICAL]` (never run without explicit confirmation in the same turn)
  and `[IMPORTANT]` (run `--dry-run` first and show the output). Honor them.
- **Never invent IDs or instance URLs.** Read them from `xano workspace list`,
  `xano profile me`, or the command output. If you don't have a value, get it
  from the user or a command — don't guess.
- **Prefer the MCP docs tools over memory.** When you need exact CLI flags or
  XanoScript syntax, call `xano_cli_docs`, `xano_meta_api_docs`, and
  `xano_xanoscript_docs` rather than recalling them.

---

## Phase 1 — Preflight: tools and authentication

Work through these checks top to bottom. Each `→` is the fix if the check fails.

### 1a. Node.js ≥ 20.12.0

```sh
node --version
```
→ If missing or older, point the user to https://nodejs.org (or `nvm install 20`).
The Xano CLI requires Node 20.12.0+.

### 1b. Xano CLI installed

```sh
xano --version
```
→ If "command not found": `npm install -g @xano/cli`
(npm: https://www.npmjs.com/package/@xano/cli). Re-check after installing.

### 1c. Xano Developer MCP enabled in the current tool

The Xano Developer MCP (`@xano/developer-mcp`) gives you XanoScript validation
and live CLI / Meta API docs — needed to validate any modifications and to look
up exact syntax.

**First, check whether you already have it.** If Xano MCP tools (e.g.
`xano_validate_xanoscript`, `xano_cli_docs`, `xano_xanoscript_docs`,
`xano_version`) are available to you in this session, the MCP is already
enabled — say so and move on.

→ If the tools are **not** available, the MCP isn't enabled. Determine which
tool you're running inside (Claude Code, Codex, GitHub Copilot, or OpenCode) and
give the user the matching setup from **`references/mcp-setup.md`**. Adding an
MCP server requires **restarting the session/agent** before the tools load — so
after the user adds it, ask them to restart their tool and re-invoke this skill.
You cannot use the new MCP tools in the same session they were added.

### 1d. CLI authenticated with a Xano account

```sh
xano profile me
```
This prints the logged-in user (id, name, email, instance) when a profile
exists and is valid.

→ If it errors, prints nothing useful, or no profile exists, authenticate with
browser login:

```sh
xano auth
```

This opens the browser, the user logs in, and Xano redirects back to the CLI,
which saves a profile to `~/.xano/credentials.yaml`. The flow times out after
5 minutes.

**Brand-new user with no Xano account?** That's fine — `xano auth` opens the
Xano login page, which has a **sign-up** option. They create the account in the
browser, finish onboarding, and the same flow redirects straight back to the CLI
with a working profile. Tell them: "Run `xano auth`; on the page that opens,
choose sign up, create your account, and you'll be sent right back to the CLI
authenticated." No separate account-creation step is needed.

After `xano auth`, confirm success with `xano profile me`.

> Headless / SSH (no browser)? Use `xano profile wizard` and paste an access
> token instead. See `references/cli-cheatsheet.md`.

**Do not proceed to Phase 2 until `xano profile me` succeeds.**

---

## Phase 2 — Choose or create the target workspace

A workspace is the container the template gets pushed into.

1. List what exists:
   ```sh
   xano workspace list
   ```
2. Ask the user whether to **use an existing workspace** or **create a fresh
   one** for this build. A fresh one is usually cleaner for a template.
3. To create one (confirm the name first):
   ```sh
   xano workspace create "<name>" --description "<short description>"
   ```
   Capture the returned workspace **id**. (`workspace create` uses the Meta API;
   if the user's plan has hit its workspace limit this will error — fall back to
   an existing workspace from the list.)
4. Make it the default for subsequent commands so you don't repeat `-w`:
   ```sh
   xano profile workspace set      # interactive picker
   # or, non-interactively, with the id from step 3:
   xano profile edit -w <workspace-id>
   ```
5. Verify the active workspace:
   ```sh
   xano profile workspace
   ```

Note the **workspace id** — every push in Phase 4 uses it (explicitly via `-w`
or implicitly via the profile default).

---

## Phase 3 — Pick the template and understand its layout

Templates live in the **xano-community** GitHub org. Browse them at
https://github.com/orgs/xano-community/repositories. There are two broad shapes
(see `references/templates.md` for the catalog and conventions):

- **Full apps** (e.g. `todo-app`, `support-ticketing`, `client-intake`) — a
  `backend/` directory (the pushable XanoScript), often a `frontend/index.html`,
  and a `multidoc/` bundle.
- **Integrations** (e.g. `integration-stripe-payments`, `integration-resend-email`)
  — `functions/` and `tables/` at the repo root, and usually environment
  variables to configure (`.env.example`).

If the user named a template, use it. If they described a goal ("a CRM", "send
emails", "accept payments"), match it to a repo from `references/templates.md`
or by listing the org, and confirm your pick with the user before importing.

**Always read the chosen repo's `README.md` first** (`gh api
repos/xano-community/<repo>/readme --jq '.content' | base64 -d`, or just fetch
it). The README's **Install** section is the source of truth for *which
directory* to push and *what env vars / frontend config* the template needs.

---

## Phase 4 — Import the template into the workspace

You have two equivalent ways to get the code in. Pick based on whether the user
wants the files on disk (for edits / version control) or just wants it imported.

### Path A — Clone, then push (best when modifications are likely)

```sh
git clone https://github.com/xano-community/<repo>.git
cd <repo>
```

Then push the directory the README points to. For a **full app** that's usually
`backend/`; for an **integration** it's usually the repo root:

```sh
# full app:
xano workspace push -d ./backend -w <workspace-id>
# integration (functions/ + tables/ at root):
xano workspace push -d . -w <workspace-id>
```

`workspace push` is an `[IMPORTANT]` command — **run it with `--dry-run` first**,
show the user the planned changes, then run it for real once they confirm:

```sh
xano workspace push -d ./backend -w <workspace-id> --dry-run
```

### Path B — Pull straight from git into a working dir, then push

```sh
xano workspace git pull -r https://github.com/xano-community/<repo>.git -d ./code
# inspect ./code, then:
xano workspace push -d ./code -w <workspace-id> --dry-run
xano workspace push -d ./code -w <workspace-id>
```

After pushing, confirm it landed: `xano workspace get -w <workspace-id>` and/or
check the API group in the Xano dashboard.

---

## Phase 5 — Apply the user's build instructions

If the user only wanted the template imported as-is, skip to Phase 6.

If they asked for modifications (rename things, add fields/endpoints, change
logic, wire in another integration):

1. Make sure the code is on disk (Path A or B above gives you a local copy; if
   you imported a different way, `xano workspace pull -d ./code -w <id>` first).
2. Edit the relevant `.xs` files. They're organized by type —
   `api/<group>/`, `function/`, `table/`, `task/`, `ai/agent/`, etc. Use
   `xano_xanoscript_docs` for syntax and `xano_cli_docs` for structure.
3. **Validate every change** with the `xano_validate_xanoscript` MCP tool before
   pushing — catch syntax errors locally, not on the server.
4. Push with a `--dry-run` preview first, then for real:
   ```sh
   xano workspace push -d ./code -w <workspace-id> --dry-run
   xano workspace push -d ./code -w <workspace-id>
   ```

---

## Phase 6 — Configure, verify, and hand off

Depending on the template (the README spells out which apply):

- **Environment variables** — integrations need keys (e.g. `STRIPE_API_KEY`).
  Set them in the Xano dashboard under the workspace's environment variables, or
  via the CLI / Meta API. Never hardcode secrets into `.xs` files. Walk the user
  through obtaining each key from the provider.
- **Frontend** — full-app templates often ship `frontend/index.html` with an
  `API_BASE` constant near the top. Point it at the workspace's API group URL,
  then open the file in a browser.
- **Seed / demo data** — many apps expose a `POST /seed` endpoint. Offer to call
  it (e.g. `curl -X POST https://<instance>.xano.io/api:<group>/seed`).
- **Tests** — if the template includes them, run:
  ```sh
  xano unit_test run_all -w <workspace-id>
  xano workflow_test run_all -w <workspace-id>
  ```

Finish by summarizing for the user: the workspace name + id, what was pushed,
any env vars still needing real values, the API group base URL, and the next
action they can take (open the dashboard, hit an endpoint, open the frontend).

---

## Reference files

- `references/mcp-setup.md` — how to enable the Xano Developer MCP in Claude
  Code, Codex, GitHub Copilot, and OpenCode.
- `references/cli-cheatsheet.md` — the CLI commands this skill relies on, with
  flags and the headless auth fallback.
- `references/templates.md` — the xano-community catalog and the two template
  layouts (full app vs integration).
