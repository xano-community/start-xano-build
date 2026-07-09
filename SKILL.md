---
name: start-xano-build
description: >-
  Import or add a certified xano-community template, module, or third-party
  integration into Xano. Use when a user wants to spin up, scaffold, import,
  install, or "start a Xano build/app/backend from a template," add a module, or
  wire in a supported integration. Assumes the terminal bootstrap (start.sh) has
  already installed and authenticated the Xano CLI and registered the Xano
  Developer MCP before this session started — this skill owns the Xano workflow,
  not dependency setup. It verifies that bootstrap state, detects whether the
  account is Free or paid, routes the push to the right target (existing
  workspace, paid sandbox, or a fresh build), previews with a dry-run, pushes
  only after explicit approval, and verifies the push actually landed. The catalog
  of supported items is pulled live from the xano-community org on every run —
  never from an embedded list.
---

# Start a Xano build from a xano-community template

This skill takes a user from an authenticated terminal to a working Xano backend
built from a supported **[xano-community](https://github.com/orgs/xano-community/repositories)**
item — a full app, a module, or a third-party integration. Run the phases **in
order** — each one gates the next. Do not skip a phase because it "looks" done;
verify it.

**The catalog is pulled live from GitHub on every run** (Phase 3) — this skill
carries no embedded list of items. What the org publishes is what's on offer.

**The bootstrap (`start.sh`) already ran before this session.** It installed and
authenticated the Xano CLI and registered the Xano Developer MCP with Claude Code
at startup. This skill therefore **owns the Xano workflow, not dependency
setup**: it never installs or registers tools. If a prerequisite is missing, it
**stops and tells the user to rerun the bootstrap** — it does not try to repair
the environment from inside the session.

The end state: the chosen item is imported into the right target for the user's
plan — the **sandbox** for paid accounts, their **existing workspace** for Free
accounts (or a **fresh build** they asked for) — and verified to have actually
landed.

## Guardrails

- **This skill does not do setup.** Never run `claude mcp add`, `npm install`,
  `xano auth`, or any install/register step from inside the session. Those belong
  to `start.sh` and run *before* Claude starts. If something is missing, Phase 0
  stops and points the user back to the bootstrap command.
- **No restart/resume dance.** The MCP is already loaded at startup, so there is
  never a "restart your tool and come back" step. If the MCP tools aren't present,
  that means the bootstrap didn't finish — stop, don't work around it.
- **Confirm before anything outward-facing or destructive.** Pushing code,
  setting environment variables, and seeding data all touch the user's real Xano
  account. Say what you're about to do and get a clear go-ahead.
- **Every push is preview → approve → push.** Run `--dry-run` first and show the
  planned changes. Get an explicit "yes" in chat. Only then run the real push.
  Because the agent's shell is non-interactive, the real push needs `--force` to
  get past the CLI's own confirmation prompt — that is fine **after** the user
  approved the previewed change. **Never push unprompted.**
- **Be plan-aware.** Detect Free vs paid in Phase 2 and route accordingly. The
  **Free plan is named `build`** internally (`package.name: "build"`); treat
  `build` (or any plan whose workspace entitlement is `1`) as Free.
- **The live catalog is the source of truth.** Fetch it from GitHub each run
  (Phase 3) with a **deterministic** command — never a summarizing web fetch,
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
- **Keep the channel quiet.** Between the defined blocks, narrate as little as
  possible — see *Output discipline* below. Routine tool calls speak for
  themselves; don't wrap them in prose.

---

## Output discipline — quiet by default

The run is hard to follow when routine narration crowds out the messages that
matter. Between the defined blocks, **say as little as possible.** Someone
scanning the transcript should see only: which phase we're in, the defined
blocks, questions to them, and real errors — nothing in between.

**Only emit:**

1. **One short phase marker** when a phase begins — a single bold line, nothing
   more (e.g. `**Checking your plan…**`, `**Picking a template…**`). Not a
   paragraph about what the phase is going to do.
2. **The defined blocks**, with their set structure: the plan-gated notice and
   the dry-run preview (Phase 4), and the final summary (Phase 6).
3. **Questions and approval requests** — clearly, on their own line.
4. **Real errors** — the raw error plus the single next step. No padding.

**Never emit:**

- Narration of tool calls — no "Now I'll run…", "Let me check…", "I'm going
  to…", "Great, that worked!". The harness already shows the command and its
  output; don't restate them.
- Recaps of what a command returned, unless it's a decision the user must act on.
- Preambles before, or summaries after, routine steps that simply succeeded —
  go straight to the next phase marker.
- Thinking out loud, option surveys, or reassurance filler.

If a step succeeds and nothing is required of the user, advance **silently** to
the next phase marker. Prose is the exception, not the connective tissue between
every tool call.

---

## Phase 0 — Verify bootstrap state

Confirm the environment the bootstrap was supposed to leave you. **If any check
fails, stop and tell the user to rerun the bootstrap command — do not try to fix
it here.**

1. **Xano MCP tools are available.** Confirm tools like
   `xano_validate_xanoscript`, `xano_cli_docs`, and `xano_xanoscript_docs` are
   present in this session. If they are **not**, stop:

   > The Xano Developer MCP isn't loaded in this session, so I can't safely run
   > the Xano workflow. Please rerun the setup command from your terminal, which
   > registers the MCP before Claude starts:
   >
   > ```sh
   > tmp="$(mktemp)" && curl -fsSL https://raw.githubusercontent.com/xano-community/start-xano-build/main/start.sh -o "$tmp" && bash "$tmp"; rm -f "$tmp"
   > ```

   Do **not** attempt `claude mcp add` or otherwise register the MCP yourself.

2. **Xano CLI is available and authenticated.**
   ```sh
   xano --version
   xano profile me
   ```
   `xano profile me` prints the logged-in user when a valid profile exists. If
   `xano` is missing, or `profile me` errors / shows no profile, stop with the
   same message: **rerun the bootstrap command.** Do **not** run `xano auth` from
   inside the session — the bootstrap handles auth in a real foreground terminal.

Only when all three hold — MCP tools present, CLI present, CLI authenticated —
continue to Phase 1.

---

## Phase 1 — Identify intent

Settle two things in **one** short exchange (skip whatever the user already told
you — don't re-ask):

1. **What are we adding?** A **full app** (template), a **module**, or a
   **third-party integration** from the xano-community org. Take a specific name,
   or a goal to match against the live catalog ("a CRM", "send emails", "accept
   payments"). You fetch the catalog and confirm the exact item in Phase 3 — don't
   commit to a repo name yet.
2. **Where should it land?** One of three **target modes**:
   - **existing workspace** — add into work the user already has,
   - **paid sandbox** — a disposable staging area (paid plans only),
   - **fresh build** — start clean.

   The user's plan constrains this (Phase 2). If they don't have a preference,
   don't force the question here — Phase 2 picks the sensible default for their
   plan and you confirm it.

Don't expand this into a questionnaire — settle these two, then move on.

---

## Phase 2 — Detect the plan and choose the target

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

**Route the target** (reconcile with the mode the user asked for in Phase 1):

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
  If a Free user asked for **sandbox** or **fresh build**, explain plainly that
  their plan pushes into their existing workspace instead, and continue there.

**Pre-flag gated features.** Note whatever `rolePermissions` shows the plan lacks
(most commonly `workspace:workflow_test` on Free). Once you know which of those the
chosen item actually contains (Phase 4, after reading the repo), carry them as
`-e` excludes into **both** the dry-run and the real push so the preview matches
exactly what pushes.

Note the target (workspace id, or "sandbox") and the plan gaps — Phase 4 uses
them. Deliver the gated *notice* in Phase 4, once you know which gated features
the chosen item actually touches.

---

## Phase 3 — Pull the live catalog and pick an item

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
   > without embedding credentials in a public script. When it's unset, the
   > GitHub listing above is the source of truth.

2. **Match intent → repo.** Map the user's Phase 1 intent to a name from the list.
   Convention: **`integration-*`** repos are third-party integrations; the rest
   are full apps / modules. `references/templates.md` has a goal→repo hint map and
   the two on-disk layouts — treat it as a *hint*, not the source: the real name
   **must appear in the fetched list**. If several fit, show the shortlist and let
   the user pick. If nothing fits, say so and show what the org actually has —
   don't guess a name.

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

## Phase 4 — Preview the import with a dry-run

Get the code on disk:

```sh
git clone https://github.com/xano-community/<repo>.git && cd <repo>
```

The push directory comes from the repo's README: **full apps → `backend/`**,
**integrations → the repo root (`.`)**.

### Plan-gated notice (defined wording)

Check what the item contains (from the clone) against the plan gaps from Phase 2
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

> Don't use `xano sandbox push --review` — it auto-opens the browser. We
> summarize with links at the end (Phase 6).

---

## Phase 5 — Push after explicit approval

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
with the right exclude if plan-gated, and do **not** advance to Phase 6 until a
verified push exists.

### Modifications (optional)

If the user asked to modify the item (rename things, add fields/endpoints, change
logic), the Xano Developer MCP is already loaded (Phase 0 verified it) — no
restart:

1. The clone in Phase 4 gives you the code on disk (otherwise
   `xano workspace pull -d ./code -w <id>` or `xano sandbox pull -d ./code`).
2. Edit the relevant `.xs` files — organized by type (`api/<group>/`,
   `function/`, `table/`, `task/`, `ai/agent/`, …). Use `xano_xanoscript_docs`
   for syntax and `xano_cli_docs` for structure.
3. **Validate every change** with `xano_validate_xanoscript` before pushing.
4. Push to the same target, preview → approve → `--force`, then re-verify.

---

## Phase 6 — Configure, verify, and hand off

**Do not auto-open anything** — finish by summarizing with links and next steps.
Use the repo's README (Install/Configure section) as the checklist:

- **Environment variables** — integrations need keys (e.g. `STRIPE_API_KEY`,
  named in the README's `.env.example`). Set them in the Xano dashboard, or
  `xano sandbox env set` for a sandbox. Never hardcode secrets into `.xs` files.
  Walk the user through obtaining each key.
- **Seed / demo data** — if the README documents a seed endpoint, offer to call it
  (e.g. `curl -X POST https://<instance>.xano.io/api:<group>/seed`).
- **Frontend** — full-app templates often ship a single-file `frontend/index.html`
  with an `API_BASE` constant near the top. **Get the base URL yourself and fill
  it in — never tell the user to open Xano and copy it.** See "Look up the API
  base URL" below, then edit the file directly.
- **Tests** — run unit tests if present: `xano unit_test run_all -w <id>`.
  Workflow tests are paid-gated; only run `xano workflow_test run_all` if the plan
  supports them.

### Look up the API base URL (automatic — no user intervention)

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

- the plan (shown as "Free (build plan)" when applicable) and **where it landed**
  — workspace name + id, or the sandbox;
- **what was pushed**, and **anything skipped** for plan reasons (and why) — same
  framing as the Phase 4 notice: the result still works;
- the **API group base URL** — resolved above, never asked of the user;
- any **env vars** still needing real values;
- **next steps and links** — the Xano dashboard URL, and for paid the sandbox
  review URL via `xano sandbox review --url-only` (printed, not opened).

---

## Reference files

- `references/templates.md` — how to list the org **deterministically** (the live
  catalog source of truth), the goal→repo hint map, and the two on-disk layouts.
- `references/cli-cheatsheet.md` — the Xano CLI commands this skill relies on:
  plan detection, sandbox, selective push, and the base-URL lookup.
