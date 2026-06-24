# start-xano-build

An **agent skill** that takes you from zero to a working Xano backend built from
a [xano-community](https://github.com/orgs/xano-community/repositories) template
— without leaving your AI coding tool.

Point your agent at this skill and it will:

1. **Preflight** — check Node.js, install/verify the
   [Xano CLI](https://www.npmjs.com/package/@xano/cli), make sure the
   [Xano Developer MCP](https://www.npmjs.com/package/@xano/developer-mcp) is
   enabled in your tool, and authenticate the CLI — **including creating a Xano
   account for you** if you don't have one yet (it happens right inside
   `xano auth`).
2. **Workspace** — create or pick the workspace to build in.
3. **Template** — choose a xano-community repo and import it.
4. **Modify** — apply any changes you ask for, validating the XanoScript before
   it's pushed.
5. **Configure & verify** — env vars, frontend wiring, seed data, and tests.

Works in **Claude Code, Codex, GitHub Copilot, and OpenCode**.

---

## Install the skill

Clone this repo into your agent's skills directory, then start a fresh session.

### Claude Code

```sh
# all projects:
git clone https://github.com/xano-community/start-xano-build.git \
  ~/.claude/skills/start-xano-build

# …or just this project:
git clone https://github.com/xano-community/start-xano-build.git \
  .claude/skills/start-xano-build
```

### Codex / OpenCode / other agents

Clone into that tool's skills directory (e.g. `~/.codex/skills/`,
`~/.config/opencode/skills/`, or the project-local equivalent):

```sh
git clone https://github.com/xano-community/start-xano-build.git start-xano-build
```

Then move/symlink the `start-xano-build/` folder into wherever your agent loads
skills from, and restart the session so the skill is picked up.

> The skill itself depends on the **Xano Developer MCP** (`@xano/developer-mcp`)
> being enabled in your tool — it needs that MCP to write XanoScript correctly.
> If it isn't enabled yet, the skill detects this and walks you through adding it
> for your specific tool (Claude Code, Codex, Copilot, or OpenCode). See
> [`references/mcp-setup.md`](references/mcp-setup.md).

---

## Use it

Just describe what you want. The skill triggers on requests like:

- *"Start a Xano build from the `todo-app` template."*
- *"Import the support-ticketing template into a new Xano workspace."*
- *"Build me a Xano backend that accepts Stripe payments, based on the community
  template."*
- *"Spin up a Xano app from a template and add a `priority` field to the items
  table."*

…or invoke it by name: **`start-xano-build`**.

You don't need anything set up in advance — the skill handles installing the
CLI, enabling the MCP, and even creating your Xano account on first run.

---

## What's in here

```
SKILL.md                      # the skill — six gated phases the agent follows
references/
  mcp-setup.md                # enable the Xano Developer MCP per tool
  cli-cheatsheet.md           # the Xano CLI commands used, with a headless fallback
  templates.md                # the xano-community catalog + template layouts
```

## Requirements

- Node.js ≥ 20.12.0
- `@xano/cli` — installed for you if missing
- `@xano/developer-mcp` enabled in your tool — **required**; the skill helps you
  enable it
- A Xano account — created for you during `xano auth` if you don't have one

## Browse the templates

All templates live in the **xano-community** org:
https://github.com/orgs/xano-community/repositories — full apps (e.g.
`todo-app`, `support-ticketing`) and integrations (e.g.
`integration-stripe-payments`, `integration-resend-email`).
