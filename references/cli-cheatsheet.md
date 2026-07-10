# Xano CLI cheat sheet

The commands this skill leans on. Full reference: `xano <command> --help`, or
the `xano_cli_docs` MCP tool (topics: `start`, `auth`, `profile`, `workspace`).

> Commands are **space-separated** (`xano workspace push`), not colon-separated.
> Older READMEs show `xano workspace:push` — that syntax is outdated.

## Install & version

```sh
npm install -g @xano/cli      # requires Node >= 20.12.0
xano --version
```

## Auth & profiles

```sh
xano auth                     # browser login; also where a new user signs up
xano profile me               # who am I? (verifies auth)
xano profile me -o json       # same, machine-readable (use for plan detection)
xano profile list --details   # all profiles (masked tokens)
xano profile workspace        # print active workspace id
xano profile workspace set    # interactively choose the active workspace
xano profile edit -w <id>     # set default workspace non-interactively
```

Credentials live in `~/.xano/credentials.yaml` and persist across a Claude
restart — so the skill's mid-run restart never loses the sign-in.

> **`xano auth` is interactive — the *user* runs it, never the agent.** After the
> browser login it shows a terminal picker for instance/workspace/branch, with no
> flag to preselect the instance, so a backgrounded run cancels the flow and writes
> no credentials. The skill hands the user the `xano auth` instruction (Phase 1),
> then **polls `xano profile me`** until it succeeds. Never background `xano auth`
> or run it from a non-interactive agent shell.

### Detect the plan (Free vs paid)

```sh
xano profile me -o json
```

Read `extras.instance` (authoritative — don't use the instance name/host):

- `package.name` — the plan (e.g. `pro-2x`); display it. **`build` is the Free
  plan** (internal name; surface it as "Free (build plan)").
- `k8s.additional.workspaces` — workspace entitlement. **`1` → Free, `> 1` → paid.**
  Decisive signal (trust it over `package.name` if they disagree).
- `membership.rolePermissions` / `access_token.scope` — per-feature keys like
  `workspace:workflow_test`; missing/zero means the plan lacks it (pre-exclude).

Fallback if those fields are absent: count `xano workspace list`, and/or run
`xano sandbox get` (provisions on paid, errors on Free — sandbox is paid-only);
else ask. Plan decides the target: Free → existing workspace; paid → sandbox
(which also covers a paid user who's out of workspace slots).

### Headless / no-browser fallback

When there's no browser (SSH, CI), skip `xano auth` and use a token:

```sh
xano profile wizard           # prompts for token, instance, workspace, branch
# or fully non-interactive:
xano profile create <name> -i <instance_origin> -t <access_token> -w <id> --default
```

Get the access token from the Xano dashboard (account settings → token / Metadata
API access).

## Workspaces (Free accounts push here)

```sh
xano workspace list
xano workspace get -w <id>
xano workspace create "<name>" --description "<desc>"   # paid only; Free can't
```

## Sandbox (paid accounts push here)

The sandbox is a singleton, auto-provisioned personal staging area. **Paid only
— Free accounts can't use it.** Same multidoc push/pull as workspaces.

```sh
xano sandbox get                       # provision / confirm the sandbox exists
xano sandbox push -d ./code --dry-run  # preview
xano sandbox push -d ./code --force    # push (after the user approves)
xano sandbox review --url-only         # print the review URL (don't auto-open)
xano sandbox reset --force             # wipe sandbox data, keep the sandbox
xano sandbox env set -n KEY --value v  # per-sandbox env vars
```

Avoid `xano sandbox push --review` in this skill — it opens the browser; we
summarize with links instead.

## Importing / syncing code

```sh
# Pull a repo's XanoScript straight into a local dir:
xano workspace git pull -r https://github.com/xano-community/<repo>.git -d ./code

# Pull an existing workspace down to edit:
xano workspace pull -d ./code -w <id>

# Preview a push (do this first — push is an [IMPORTANT] op):
xano workspace push -d ./code -w <id> --dry-run

# Push for real, after the user approves the preview:
xano workspace push -d ./code -w <id> --force

# Exclude plan-gated files the server rejects (repeatable, globs relative to -d):
xano workspace push -d ./code -w <id> -e 'workflow_test/**' --force
```

`-d/--directory` is a flag, not a positional argument (default: current dir).
`--force` skips the CLI's own terminal confirmation — needed because the agent
shell is non-interactive, and only used **after** the user approves the
`--dry-run` preview in chat. `-i/--include` and `-e/--exclude` take globs
relative to the push dir and are repeatable — prefer `-e` over deleting files
from the clone. Push is partial (changed files) by default; `--sync` does a full
push and `--sync --delete` also removes remote objects missing locally
(`[CRITICAL]` — confirm explicitly).

## Get an API group's base URL (no user copy-paste)

There's no CLI command that prints it, so use the Meta API. Base URL is
`https://<instance-host>/api:<canonical>`:

```sh
HOST=$(xano profile me -o json | jq -r '.extras.instance.xano_domain // .extras.instance.host')
TOKEN=$(grep -A20 'default' ~/.xano/credentials.yaml | grep -m1 'access_token' | awk '{print $2}')
curl -s "https://$HOST/api:meta/workspace/<id>/apigroup" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.items[] | "\(.name): \(.canonical)"'
```

Read each group's `canonical` (the `api:xxxx` slug) and join it to the host.
Field names can vary by account — inspect the raw JSON if needed; reference is
`xano_meta_api_docs topic=apigroup`. **Never ask the user to open Xano and copy
the base URL** — resolve it here.

## Tests (if the template ships them)

```sh
xano unit_test run_all -w <id>
xano workflow_test run_all -w <id>
```

## On-disk layout after a pull

```
api/<group>/<endpoint>_<verb>.xs   # e.g. api/users/create_post.xs
function/<name>.xs
table/<name>.xs                    # + table/trigger/*.xs
task/<name>.xs
ai/agent/<name>.xs, ai/mcp_server/*.xs, ai/tool/*.xs
realtime/channel/*.xs
workspace/<name>.xs                # workspace config + workspace/trigger/*.xs
```

Folders and filenames are snake_case; API endpoints carry a verb suffix
(`_get`, `_post`, …).
