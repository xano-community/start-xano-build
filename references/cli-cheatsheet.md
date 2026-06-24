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
xano profile list --details   # all profiles (masked tokens)
xano profile workspace        # print active workspace id
xano profile workspace set    # interactively choose the active workspace
xano profile edit -w <id>     # set default workspace non-interactively
```

Credentials live in `~/.xano/credentials.yaml`.

### Headless / no-browser fallback

When there's no browser (SSH, CI), skip `xano auth` and use a token:

```sh
xano profile wizard           # prompts for token, instance, workspace, branch
# or fully non-interactive:
xano profile create <name> -i <instance_origin> -t <access_token> -w <id> --default
```

Get the access token from the Xano dashboard (account settings → token / Metadata
API access).

## Workspaces

```sh
xano workspace list
xano workspace get -w <id>
xano workspace create "<name>" --description "<desc>"
```

## Importing / syncing code

```sh
# Pull a repo's XanoScript straight into a local dir:
xano workspace git pull -r https://github.com/xano-community/<repo>.git -d ./code

# Pull an existing workspace down to edit:
xano workspace pull -d ./code -w <id>

# Preview a push (do this first — push is an [IMPORTANT] op):
xano workspace push -d ./code -w <id> --dry-run

# Push for real:
xano workspace push -d ./code -w <id>
```

`-d/--directory` is a flag, not a positional argument (default: current dir).
Push is partial (changed files) by default; `--sync` does a full push and
`--sync --delete` also removes remote objects missing locally (`[CRITICAL]` —
confirm explicitly).

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
