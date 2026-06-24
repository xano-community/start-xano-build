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

Works in **Claude Code, Cursor, Codex, GitHub Copilot, and OpenCode**.

---

## Quick start — paste this to your agent

You don't need to install anything yourself. Copy one of these prompts into your
AI coding tool and it will install the skill and run the whole thing for you:

**Let it walk you through picking a template:**

```
Set up the start-xano-build agent skill from
https://github.com/xano-community/start-xano-build — clone it into my skills
directory and follow its SKILL.md now — then help me start a Xano build from a
xano-community template. Walk me through choosing one.
```

**Start from a specific template:**

```
Install and run the start-xano-build skill from
https://github.com/xano-community/start-xano-build (clone it into my skills
directory and follow its SKILL.md). Use it to import the todo-app template
into a new Xano workspace.
```

**Build toward a goal (with a tweak):**

```
Use the start-xano-build skill from
https://github.com/xano-community/start-xano-build (clone it into my skills
directory and follow its SKILL.md) to build a Xano backend that accepts Stripe
payments based on the community template — and add a `notes` field to the
customers table.
```

The agent handles the rest: installing the Xano CLI, enabling the Xano Developer
MCP, authenticating (or creating your Xano account), creating a workspace, and
importing the template.

> **First-run note:** enabling the Xano Developer MCP requires your tool to
> restart before its tools load. If the skill adds the MCP for you, it'll ask
> you to restart and paste your prompt again — then it continues from there.

### More prompt ideas

- *"…use the skill to import the support-ticketing template and rename the
  `ticket` table to `case`."*
- *"…use the skill to spin up the client-intake template in a brand-new
  workspace called `acme-intake`."*
- *"…use the skill to build a Xano backend that sends email via Resend, based on
  the community template, and add a daily digest task."*

---

## What you'll need

The skill sets these up for you — listed so you know what it's touching:

- Node.js ≥ 20.12.0
- `@xano/cli` — installed for you if missing
- `@xano/developer-mcp` enabled in your tool — **required** (the skill needs it
  to write XanoScript correctly); the skill enables it for you
- A Xano account — created for you during `xano auth` if you don't have one

---

## Manual install

Prefer to install the skill yourself instead of via a prompt? Clone this repo
into your agent's skills directory, then start a fresh session.

### Claude Code

```sh
# all projects:
git clone https://github.com/xano-community/start-xano-build.git \
  ~/.claude/skills/start-xano-build

# …or just this project:
git clone https://github.com/xano-community/start-xano-build.git \
  .claude/skills/start-xano-build
```

### Cursor / Codex / OpenCode / other agents

Clone into that tool's skills directory (e.g. `~/.cursor/skills/`,
`~/.codex/skills/`, `~/.config/opencode/skills/`, or the project-local
equivalent):

```sh
git clone https://github.com/xano-community/start-xano-build.git start-xano-build
```

Move/symlink the `start-xano-build/` folder into wherever your agent loads skills
from, restart the session, then invoke it by name (**`start-xano-build`**) or
just describe your goal.

> The skill depends on the **Xano Developer MCP** (`@xano/developer-mcp`) being
> enabled in your tool. If it isn't, the skill detects this and walks you through
> adding it for your specific tool — see
> [`references/mcp-setup.md`](references/mcp-setup.md).

---

## What's in here

```
SKILL.md                      # the skill — six gated phases the agent follows
references/
  mcp-setup.md                # enable the Xano Developer MCP per tool
  cli-cheatsheet.md           # the Xano CLI commands used, with a headless fallback
  templates.md                # the xano-community catalog + template layouts
```

## Browse the templates

All templates live in the **xano-community** org:
https://github.com/orgs/xano-community/repositories — full apps (e.g.
`todo-app`, `support-ticketing`) and integrations (e.g.
`integration-stripe-payments`, `integration-resend-email`).
