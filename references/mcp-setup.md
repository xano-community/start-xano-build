# Enabling the Xano Developer MCP

Package: **`@xano/developer-mcp`** — run with `npx -y @xano/developer-mcp`
(no API key needed; it serves docs + XanoScript validation over stdio).

> Verify at any time with: `npx @xano/developer-mcp --version`

After adding the server, the host tool must be **restarted** before the new MCP
tools become available. You (the agent) cannot call tools that were added during
the current session — have the user restart and re-run the skill.

Give the user only the block for the tool they're actually using.

---

## Claude Code

One command:

```sh
claude mcp add xano -- npx -y @xano/developer-mcp
```

Then restart Claude Code (or run `/mcp` to confirm `xano` is connected).

Confirm it's listed:

```sh
claude mcp list
```

---

## Codex (OpenAI Codex CLI)

Either run:

```sh
codex mcp add xano -- npx -y @xano/developer-mcp
```

…or add this to `~/.codex/config.toml` (global) or a project-scoped
`.codex/config.toml`:

```toml
[mcp_servers.xano]
command = "npx"
args = ["-y", "@xano/developer-mcp"]
```

Restart Codex after editing the file.

---

## GitHub Copilot

**VS Code (Copilot agent mode)** — create or edit `.vscode/mcp.json` in the
workspace (or add it globally via the Command Palette → "MCP: Add Server"):

```json
{
  "servers": {
    "xano": {
      "command": "npx",
      "args": ["-y", "@xano/developer-mcp"]
    }
  }
}
```

Reload the VS Code window, then start the server from the `mcp.json` editor or
the MCP view. Make sure you're in Copilot **Agent** mode so tools are available.

**GitHub Copilot CLI** — add the same server via its MCP config / `/mcp` command,
using `command: "npx"` and `args: ["-y", "@xano/developer-mcp"]`.

---

## OpenCode

Add to `opencode.json` (project root) or `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "xano": {
      "type": "local",
      "command": ["npx", "-y", "@xano/developer-mcp"],
      "enabled": true
    }
  }
}
```

Restart OpenCode so the server loads.

---

## Installing globally instead of via npx

If the user would rather not resolve the package on every launch:

```sh
npm install -g @xano/developer-mcp
```

Then use the `xano-developer-mcp` binary in place of `npx -y
@xano/developer-mcp` in any of the configs above (e.g. for Claude Code:
`claude mcp add xano -- xano-developer-mcp`).
