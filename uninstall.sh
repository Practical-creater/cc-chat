#!/usr/bin/env bash
# cc-chat uninstaller for macOS and Linux.
#   curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.sh | bash
set -euo pipefail

NAME="${CC_CHAT_NAME:-chat}"
APP_HOME="${CC_CHAT_HOME:-$HOME/.cc-chat}"
BIN_DIR="${CC_CHAT_BIN:-$HOME/.local/bin}"
MARK_BEGIN="# >>> cc-chat >>>"
MARK_END="# <<< cc-chat <<<"

LAUNCHER="$BIN_DIR/$NAME"
if [ -f "$LAUNCHER" ] && grep -q "cc-chat launcher" "$LAUNCHER"; then
  rm -f "$LAUNCHER"
  echo "Removed $LAUNCHER"
fi

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.config/fish/config.fish"; do
  [ -f "$rc" ] || continue
  if grep -qF "$MARK_BEGIN" "$rc"; then
    tmp="$(mktemp)"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1;next} $0==e{skip=0;next} !skip' "$rc" > "$tmp"
    cat "$tmp" > "$rc" && rm -f "$tmp"
    echo "Removed PATH entry from $rc"
  fi
done

if [ -d "$APP_HOME" ]; then
  rm -rf "$APP_HOME"
  echo "Removed $APP_HOME"
fi

echo "cc-chat has been uninstalled. Claude Code itself was not touched."
