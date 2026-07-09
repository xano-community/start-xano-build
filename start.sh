#!/usr/bin/env bash
#
# start-xano-build — terminal bootstrap
#
# One paste in a terminal:
#
#   tmp="$(mktemp)" && curl -fsSL https://raw.githubusercontent.com/xano-community/start-xano-build/main/start.sh -o "$tmp" && bash "$tmp"; rm -f "$tmp"
#
# What it does, in order, BEFORE Claude starts (so nothing has to be installed or
# registered from inside the agent session):
#   1. Installs/updates the start-xano-build skill into ~/.claude/skills.
#   2. Ensures Claude Code is installed and notes its auth state.
#   3. Ensures Node/npm (a private copy if missing — no profile changes).
#   4. Installs the Xano CLI + Xano Developer MCP into a private prefix, behind
#      stable wrapper binaries.
#   5. Authenticates the Xano CLI (foreground `xano auth`, real terminal).
#   6. Registers the Xano Developer MCP with Claude Code at USER scope.
#   7. Launches Claude Code interactively with an initial prompt.
#
set -euo pipefail

# --------------------------------------------------------------------------- #
# Paths — everything private lives under one controlled root.
# --------------------------------------------------------------------------- #
REPO_URL="https://github.com/xano-community/start-xano-build.git"
SKILL_REPO_RAW="start-xano-build"
INSTALL_ROOT="$HOME/.xano-community/start-xano-build"
NPM_PREFIX="$INSTALL_ROOT/npm"
BIN="$INSTALL_ROOT/bin"
SKILL_DIR="$HOME/.claude/skills/$SKILL_REPO_RAW"
NODE_VERSION="v20.18.1"   # pinned LTS used only if the user has no suitable Node
NODE_BIN_DIR=""

# --------------------------------------------------------------------------- #
# Logging helpers
# --------------------------------------------------------------------------- #
if [ -t 1 ]; then
  B="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; GRN="$(printf '\033[32m')"
  YLW="$(printf '\033[33m')"; RED="$(printf '\033[31m')"; RST="$(printf '\033[0m')"
else
  B=""; DIM=""; GRN=""; YLW=""; RED=""; RST=""
fi
step() { printf '\n%s==>%s %s%s%s\n' "$B" "$RST" "$B" "$1" "$RST"; }
info() { printf '    %s\n' "$1"; }
ok()   { printf '    %s✓%s %s\n' "$GRN" "$RST" "$1"; }
warn() { printf '    %s!%s %s\n' "$YLW" "$RST" "$1" >&2; }
die()  { printf '\n%serror:%s %s\n' "$RED" "$RST" "$1" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# 0. Sanity: interactive terminal + required base tools
# --------------------------------------------------------------------------- #
step "Checking your terminal"
if [ ! -t 1 ] && [ ! -e /dev/tty ]; then
  die "This installer needs an interactive terminal (Xano auth uses a prompt).
     Download it first, then run it:
       tmp=\"\$(mktemp)\" && curl -fsSL https://raw.githubusercontent.com/xano-community/${SKILL_REPO_RAW}/main/start.sh -o \"\$tmp\" && bash \"\$tmp\"; rm -f \"\$tmp\""
fi
command -v curl >/dev/null 2>&1 || die "curl is required but not found."
command -v git  >/dev/null 2>&1 || die "git is required but not found. Install git and re-run."
ok "Interactive terminal detected"

mkdir -p "$INSTALL_ROOT" "$NPM_PREFIX" "$BIN"

# --------------------------------------------------------------------------- #
# Version compare: node_version_ok <version like v20.18.1>  -> 0 if >= 20.12.0
# (hand-rolled so we don't depend on `sort -V`, which BSD/macOS sort lacks)
# --------------------------------------------------------------------------- #
node_version_ok() {
  local v="${1#v}" major minor rest
  major="${v%%.*}"; rest="${v#*.}"; minor="${rest%%.*}"
  [ "$major" -gt 20 ] && return 0
  [ "$major" -lt 20 ] && return 1
  [ "$minor" -ge 12 ] && return 0
  return 1
}

# --------------------------------------------------------------------------- #
# 1. Install / update the skill
# --------------------------------------------------------------------------- #
step "Installing the start-xano-build skill"
mkdir -p "$HOME/.claude/skills"
if [ -d "$SKILL_DIR/.git" ]; then
  if git -C "$SKILL_DIR" pull --ff-only >/dev/null 2>&1; then
    ok "Updated existing skill at $SKILL_DIR"
  else
    warn "Could not fast-forward the skill; using the existing copy."
  fi
elif [ -e "$SKILL_DIR" ]; then
  warn "$SKILL_DIR exists but isn't a git checkout — leaving it as-is."
else
  git clone --depth 1 "$REPO_URL" "$SKILL_DIR" >/dev/null 2>&1 \
    || die "Failed to clone $REPO_URL into $SKILL_DIR"
  ok "Cloned skill into $SKILL_DIR"
fi

# --------------------------------------------------------------------------- #
# 2. Node / npm (private copy if missing or too old — no profile changes)
# --------------------------------------------------------------------------- #
step "Checking Node.js (>= 20.12.0)"
ensure_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 \
     && node_version_ok "$(node -v)"; then
    NODE_BIN_DIR="$(cd "$(dirname "$(command -v node)")" && pwd)"
    ok "Using Node $(node -v) at $NODE_BIN_DIR"
    return 0
  fi
  if command -v node >/dev/null 2>&1; then
    warn "Node $(node -v) is older than 20.12.0."
  else
    warn "Node.js/npm not found on PATH."
  fi
  info "Installing a private copy of Node ${NODE_VERSION} (nothing added to your shell profile)…"
  local os arch nodeos nodearch tarball url dir
  os="$(uname -s)"; arch="$(uname -m)"
  case "$os" in
    Darwin) nodeos="darwin";;
    Linux)  nodeos="linux";;
    *) die "Automatic Node install isn't supported on '$os'. Install Node >= 20.12.0 from https://nodejs.org and re-run.";;
  esac
  case "$arch" in
    arm64|aarch64) nodearch="arm64";;
    x86_64|amd64)  nodearch="x64";;
    *) die "Automatic Node install isn't supported on arch '$arch'. Install Node >= 20.12.0 from https://nodejs.org and re-run.";;
  esac
  tarball="node-${NODE_VERSION}-${nodeos}-${nodearch}.tar.gz"
  url="https://nodejs.org/dist/${NODE_VERSION}/${tarball}"
  dir="$INSTALL_ROOT/node"
  mkdir -p "$dir"
  curl -fsSL "$url" -o "$INSTALL_ROOT/$tarball" \
    || die "Failed to download Node from $url. Install Node >= 20.12.0 from https://nodejs.org and re-run."
  tar -xzf "$INSTALL_ROOT/$tarball" -C "$dir" || die "Failed to extract Node."
  rm -f "$INSTALL_ROOT/$tarball"
  NODE_BIN_DIR="$dir/node-${NODE_VERSION}-${nodeos}-${nodearch}/bin"
  export PATH="$NODE_BIN_DIR:$PATH"
  command -v node >/dev/null 2>&1 || die "Private Node install did not produce a usable node binary."
  node_version_ok "$(node -v)" || die "Installed Node is older than required."
  ok "Installed private Node $(node -v)"
}
ensure_node

# --------------------------------------------------------------------------- #
# 3. Xano CLI + Xano Developer MCP into a private npm prefix, behind wrappers
# --------------------------------------------------------------------------- #
step "Installing the Xano CLI and Xano Developer MCP (private, no global npm)"
npm install -g --prefix "$NPM_PREFIX" @xano/cli @xano/developer-mcp >/dev/null 2>&1 \
  || die "npm failed to install @xano/cli / @xano/developer-mcp into $NPM_PREFIX"

[ -x "$NPM_PREFIX/bin/xano" ] || die "Xano CLI binary not found at $NPM_PREFIX/bin/xano after install."

# Discover the MCP binary name (falls back to the documented default).
MCP_REAL="$(ls "$NPM_PREFIX/bin" 2>/dev/null | grep -i 'mcp' | head -1 || true)"
[ -n "$MCP_REAL" ] || MCP_REAL="xano-developer-mcp"
[ -x "$NPM_PREFIX/bin/$MCP_REAL" ] || die "Xano Developer MCP binary not found at $NPM_PREFIX/bin/$MCP_REAL after install."

# Stable wrapper binaries. These pin the private Node on PATH, so the CLI and the
# MCP work no matter what the user's shell PATH looks like — this is what we hand
# to Claude, never a random global binary.
cat > "$BIN/xano" <<EOF
#!/usr/bin/env bash
export PATH="$NODE_BIN_DIR:\$PATH"
exec "$NPM_PREFIX/bin/xano" "\$@"
EOF
cat > "$BIN/xano-developer-mcp" <<EOF
#!/usr/bin/env bash
export PATH="$NODE_BIN_DIR:\$PATH"
exec "$NPM_PREFIX/bin/$MCP_REAL" "\$@"
EOF
chmod +x "$BIN/xano" "$BIN/xano-developer-mcp"

# Use the wrappers for the rest of this script and inside the launched session.
export PATH="$BIN:$NODE_BIN_DIR:$PATH"
XANO="$BIN/xano"
"$XANO" --version >/dev/null 2>&1 || die "The Xano CLI wrapper isn't working ($BIN/xano)."
ok "Xano CLI $("$XANO" --version 2>/dev/null | head -1) ready at $BIN/xano"
ok "Xano Developer MCP wrapper ready at $BIN/xano-developer-mcp"

# --------------------------------------------------------------------------- #
# 4. Claude Code — install if missing, note auth state
# --------------------------------------------------------------------------- #
step "Checking Claude Code"
if command -v claude >/dev/null 2>&1; then
  CLAUDE_BIN="$(command -v claude)"
  ok "Found Claude Code at $CLAUDE_BIN"
else
  info "Claude Code not found — installing a private copy via npm…"
  npm install -g --prefix "$NPM_PREFIX" @anthropic-ai/claude-code >/dev/null 2>&1 \
    || die "Failed to install Claude Code. Install it from https://claude.com/claude-code and re-run."
  CLAUDE_BIN="$NPM_PREFIX/bin/claude"
  [ -x "$CLAUDE_BIN" ] || die "Claude Code install did not produce a usable 'claude' binary."
  ok "Installed Claude Code at $CLAUDE_BIN"
fi
"$CLAUDE_BIN" --version >/dev/null 2>&1 || die "Claude Code is installed but not runnable ($CLAUDE_BIN)."

# There's no non-interactive 'claude auth status'; login happens at launch.
if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] \
   || [ -n "${ANTHROPIC_AUTH_TOKEN:-}" ] || [ -f "$HOME/.claude/.credentials.json" ]; then
  ok "Claude Code appears to be authenticated"
else
  info "Claude Code will prompt you to log in when it launches (same terminal)."
fi

# --------------------------------------------------------------------------- #
# 5. Xano CLI authentication (foreground; real terminal for the picker)
# --------------------------------------------------------------------------- #
step "Authenticating the Xano CLI"
if "$XANO" profile me >/dev/null 2>&1; then
  ok "Already authenticated as $("$XANO" profile me 2>/dev/null | head -1)"
else
  cat <<'MSG'
    You're not signed in to Xano yet. The next step opens Xano auth in your
    browser and then shows an instance picker in this terminal.

      • Finish the browser login (choose "sign up" if you're brand new).
      • Come back here and pick your instance when the list appears.

MSG
  # Foreground, attached to the real terminal. Never backgrounded.
  if [ -e /dev/tty ]; then
    "$XANO" auth </dev/tty || true
  else
    "$XANO" auth || true
  fi
  if "$XANO" profile me >/dev/null 2>&1; then
    ok "Authenticated as $("$XANO" profile me 2>/dev/null | head -1)"
  else
    die "Xano auth didn't complete — no profile is present yet.
     Re-run this command and finish the browser login + instance picker."
  fi
fi

# --------------------------------------------------------------------------- #
# 6. Register the Xano Developer MCP with Claude Code (USER scope)
# --------------------------------------------------------------------------- #
step "Registering the Xano Developer MCP with Claude Code"
MCP_WRAPPER="$BIN/xano-developer-mcp"
if existing="$("$CLAUDE_BIN" mcp get xano 2>/dev/null)"; then
  if printf '%s' "$existing" | grep -q "$MCP_WRAPPER"; then
    ok "MCP 'xano' already points to $MCP_WRAPPER"
  elif printf '%s' "$existing" | grep -qi 'developer-mcp'; then
    ok "MCP 'xano' already registered (Xano Developer MCP) — leaving it as-is"
  else
    warn "An MCP server named 'xano' already exists but doesn't look like the Xano Developer MCP.
       Leaving it untouched. If Xano tools don't load, remove it with
       'claude mcp remove xano' and re-run this installer."
  fi
else
  if "$CLAUDE_BIN" mcp add --scope user xano -- "$MCP_WRAPPER" >/dev/null 2>&1; then
    ok "Registered 'xano' MCP at user scope → $MCP_WRAPPER"
  else
    die "Failed to register the Xano Developer MCP with Claude Code.
     Try manually: $CLAUDE_BIN mcp add --scope user xano -- $MCP_WRAPPER"
  fi
fi

# --------------------------------------------------------------------------- #
# 7. Launch Claude Code interactively with an initial prompt
# --------------------------------------------------------------------------- #
step "Launching Claude Code"
info "Everything's ready. Handing off to Claude Code…"
echo

PROMPT="Use the start-xano-build skill. The terminal bootstrap has already installed or verified the Xano CLI, authenticated the Xano CLI, and registered the Xano Developer MCP before this Claude session started. First verify the Xano MCP tools are available. Then help me import or add a supported xano-community template, module, or third-party integration into Xano. Ask whether I want to target an existing workspace, a paid sandbox, or a fresh build. Do not try to install or register the MCP from inside this session."

# exec so Claude inherits this terminal (and the PATH we set, so the wrapped
# `xano` CLI is available to the skill inside the session).
exec "$CLAUDE_BIN" "$PROMPT"
