#!/usr/bin/env bash
# cc-chat installer for macOS and Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | bash
#
# Optional environment variables:
#   CC_CHAT_NAME   command name to install (default: chat)
#   CC_CHAT_HOME   data folder (default: ~/.cc-chat)
#   CC_CHAT_BIN    folder for the command (default: ~/.local/bin)
#   CC_CHAT_NO_OFFICE=1  skip Word/Excel/PPT support (no uv, no MarkItDown)
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Practical-creater/cc-chat/main"
NAME="${CC_CHAT_NAME:-chat}"
APP_HOME="${CC_CHAT_HOME:-$HOME/.cc-chat}"
BIN_DIR="${CC_CHAT_BIN:-$HOME/.local/bin}"
MARK_BEGIN="# >>> cc-chat >>>"
MARK_END="# <<< cc-chat <<<"
MARKITDOWN_PKG="markitdown-mcp==0.0.1a8"

info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

case "$NAME" in
  *[!A-Za-z0-9._-]*|"") die "CC_CHAT_NAME may only contain letters, digits, '.', '_' and '-'." ;;
esac

# 1. Claude Code must be installed.
if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code (the 'claude' command) was not found."
  warn "Install it first:  curl -fsSL https://claude.ai/install.sh | bash"
  warn "Then run 'claude' once to log in, and run this installer again."
  die  "Aborted."
fi

mkdir -p "$APP_HOME/workspace" "$BIN_DIR"

# 2. Prompt files. prompt.md (style) is the user's to edit and is kept;
#    tools.md (file handling) is always refreshed.
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
fetch() {  # fetch <repo file> <destination>
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$1" ]; then
    cp "$SCRIPT_DIR/$1" "$2"
  else
    curl -fsSL "$REPO_RAW/$1" -o "$2" \
      || die "Could not download $1 from GitHub. Check your network or proxy."
  fi
}
fetch prompt.md "$APP_HOME/prompt.default.md"
fetch tools.md  "$APP_HOME/tools.md"
if [ -f "$APP_HOME/prompt.md" ]; then
  info "Keeping your existing prompt: $APP_HOME/prompt.md"
else
  cp "$APP_HOME/prompt.default.md" "$APP_HOME/prompt.md"
fi

# 3. Word/Excel/PPT support: uv + Microsoft MarkItDown as a local MCP server.
rm -f "$APP_HOME/mcp.json"
if [ "${CC_CHAT_NO_OFFICE:-0}" != "1" ]; then
  UV="$(command -v uv 2>/dev/null || true)"
  [ -z "$UV" ] && [ -x "$HOME/.local/bin/uv" ] && UV="$HOME/.local/bin/uv"
  if [ -z "$UV" ]; then
    info "Installing uv (needed for Word/Excel/PPT support)..."
    if curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1; then
      for c in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
        [ -x "$c" ] && UV="$c" && break
      done
    fi
  fi
  MD=""
  if [ -n "$UV" ]; then
    info "Installing the Word/Excel/PPT converter (first time may take a minute)..."
    if "$UV" tool install --force "$MARKITDOWN_PKG" >/dev/null 2>&1; then
      MD="$("$UV" tool dir --bin)/markitdown-mcp"
      [ -x "$MD" ] || MD=""
    fi
  fi
  if [ -n "$MD" ]; then
    printf '{"mcpServers":{"markitdown":{"command":"%s","args":[]}}}\n' "$MD" > "$APP_HOME/mcp.json"
    info "Word/Excel/PPT support is ready."
  else
    warn "Could not set up Word/Excel/PPT support. Plain chat, PDF and images still work."
    warn "Check your network or proxy, then run this installer again."
  fi
fi

# 4. The launcher command.
LAUNCHER="$BIN_DIR/$NAME"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# cc-chat launcher: a clean, claude.ai-style chat on top of Claude Code.
set -euo pipefail
APP_HOME="\${CC_CHAT_HOME:-$APP_HOME}"
if ! command -v claude >/dev/null 2>&1; then
  echo "cc-chat: 'claude' not found. Install Claude Code first: https://claude.com/claude-code" >&2
  exit 1
fi
mkdir -p "\$APP_HOME/workspace"
PROMPT="\$APP_HOME/prompt.md"
[ -f "\$PROMPT" ] || PROMPT="\$APP_HOME/prompt.default.md"
SESSION="\$APP_HOME/.session-prompt.md"
{
  cat "\$PROMPT"
  [ -f "\$APP_HOME/tools.md" ] && { printf '\n\n'; cat "\$APP_HOME/tools.md"; }
  printf '\n\nToday'"'"'s date is %s.\n' "\$(date +%Y-%m-%d)"
} > "\$SESSION"
MCP=()
export MCP_TIMEOUT="\${MCP_TIMEOUT:-60000}"
[ -f "\$APP_HOME/mcp.json" ] && MCP=(--mcp-config "\$APP_HOME/mcp.json")
cd "\$APP_HOME/workspace"
exec claude \\
  --system-prompt-file "\$SESSION" \\
  --tools "Read,WebSearch,WebFetch" \\
  "\${MCP[@]+"\${MCP[@]}"}" \\
  --strict-mcp-config \\
  "\$@"
EOF
chmod +x "$LAUNCHER"
info "Installed command: $LAUNCHER"

# 5. Put BIN_DIR first on PATH (macOS ships an unrelated /usr/sbin/chat).
PATH_LINE="export PATH=\"$BIN_DIR:\$PATH\""
add_block() {
  local rc="$1"
  [ -f "$rc" ] || return 0
  if grep -qF "$MARK_BEGIN" "$rc"; then return 0; fi
  printf '\n%s\n%s\n%s\n' "$MARK_BEGIN" "$PATH_LINE" "$MARK_END" >> "$rc"
  info "Added $BIN_DIR to PATH in $rc"
}
touched=0
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  if [ -f "$rc" ]; then add_block "$rc"; touched=1; fi
done
if [ "$touched" = 0 ]; then
  case "${SHELL:-}" in
    */zsh) touch "$HOME/.zshrc"; add_block "$HOME/.zshrc" ;;
    *)     touch "$HOME/.bashrc"; add_block "$HOME/.bashrc" ;;
  esac
fi
if [ -d "$HOME/.config/fish" ] && ! grep -qF "$BIN_DIR" "$HOME/.config/fish/config.fish" 2>/dev/null; then
  mkdir -p "$HOME/.config/fish"
  printf '\n%s\nfish_add_path --prepend %s\n%s\n' "$MARK_BEGIN" "$BIN_DIR" "$MARK_END" >> "$HOME/.config/fish/config.fish"
  info "Added $BIN_DIR to PATH in fish config"
fi

# 6. Warn about an existing alias or function with the same name.
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  [ -f "$rc" ] || continue
  if grep -nE "^[[:space:]]*(alias[[:space:]]+$NAME=|(function[[:space:]]+)?$NAME[[:space:]]*\(\))" "$rc" >/dev/null; then
    warn "$rc already defines '$NAME' (alias or function). It will override cc-chat."
    warn "Remove that line, or reinstall with another name:  CC_CHAT_NAME=cchat bash install.sh"
  fi
done

echo
info "Done. Open a NEW terminal window, then type:  $NAME"
info "Edit the chat style any time:  $APP_HOME/prompt.md"
