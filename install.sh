#!/usr/bin/env bash
# cc-chat installer for macOS and Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | bash
#
# Optional environment variables:
#   CC_CHAT_NAME   command name to install (default: chat)
#   CC_CHAT_HOME   data folder (default: ~/.cc-chat)
#   CC_CHAT_BIN    folder for the command (default: ~/.local/bin)
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Practical-creater/cc-chat/main"
NAME="${CC_CHAT_NAME:-chat}"
APP_HOME="${CC_CHAT_HOME:-$HOME/.cc-chat}"
BIN_DIR="${CC_CHAT_BIN:-$HOME/.local/bin}"
MARK_BEGIN="# >>> cc-chat >>>"
MARK_END="# <<< cc-chat <<<"

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

# 2. System prompt. Keep the user's edited copy if one exists.
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/prompt.md" ]; then
  cp "$SCRIPT_DIR/prompt.md" "$APP_HOME/prompt.default.md"
else
  curl -fsSL "$REPO_RAW/prompt.md" -o "$APP_HOME/prompt.default.md" \
    || die "Could not download prompt.md from GitHub. Check your network or proxy."
fi
if [ -f "$APP_HOME/prompt.md" ]; then
  info "Keeping your existing prompt: $APP_HOME/prompt.md"
else
  cp "$APP_HOME/prompt.default.md" "$APP_HOME/prompt.md"
fi

# 3. The launcher command.
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
{ cat "\$PROMPT"; printf '\n\nToday'"'"'s date is %s.\n' "\$(date +%Y-%m-%d)"; } > "\$SESSION"
cd "\$APP_HOME/workspace"
exec claude \\
  --system-prompt-file "\$SESSION" \\
  --tools "WebSearch,WebFetch" \\
  --strict-mcp-config \\
  "\$@"
EOF
chmod +x "$LAUNCHER"
info "Installed command: $LAUNCHER"

# 4. Put BIN_DIR first on PATH (macOS ships an unrelated /usr/sbin/chat).
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

# 5. Warn about an existing alias or function with the same name.
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
