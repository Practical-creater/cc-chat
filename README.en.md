# cc-chat

[中文](README.md) | **English**

A clean, claude.ai-style chat in your terminal, built on Claude Code. One-line install for macOS, Linux and Windows.

When you run `claude` directly, Claude Code acts as a coding assistant. Its system prompt is built for writing code, so answers come out short and task-oriented. It also loads every MCP server, plugin and skill you have configured, and reads any CLAUDE.md in the current folder. For plain conversation, both the style and the context differ from the claude.ai website.

cc-chat installs a `chat` command that starts a Claude Code session set up for conversation:

| | Running `claude` | Running `chat` |
|---|---|---|
| System prompt | Claude Code's default, coding-focused prompt | **Replaced** by a conversation prompt modeled on the published claude.ai prompt |
| Tools | All tools, including file editing and shell commands | Web search only (WebSearch, WebFetch) |
| Your MCP servers | All loaded | None loaded |
| Working folder | Wherever you are, including that folder's CLAUDE.md | A dedicated empty folder, unaffected by your projects |
| History | Mixed with your coding sessions | Kept separate, so `chat -c` / `chat -r` only see chats |

## Requirements

1. **Claude Code installed and logged in.** Typing `claude` in a terminal should open a session. If it doesn't:
   - macOS / Linux: `curl -fsSL https://claude.ai/install.sh | bash`
   - Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`
   - Then open a new terminal, run `claude` once and follow the login prompts (a Claude Pro / Max subscription or an API key is required).
   - Official docs: https://docs.claude.com/en/docs/claude-code/setup
2. **Access to GitHub.** The installer downloads files from `raw.githubusercontent.com`. If that fails, set up your proxy first, or use the manual install below.

## Install

### macOS / Linux

Open Terminal, paste this line and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | bash
```

When you see `Done.`, **close the terminal window and open a new one**, then type:

```bash
chat
```

### Windows

1. Press the `Win` key, search for **PowerShell** and open it (Windows Terminal is recommended).
2. Paste this line and press Enter:

   ```powershell
   irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.ps1 | iex
   ```

3. When you see `Done.`, **close the window and open a new PowerShell**, then type:

   ```powershell
   chat
   ```

### Manual install from a clone

Use this if you prefer not to pipe a script from the network, or want to read it first:

```bash
git clone https://github.com/Practical-creater/cc-chat.git
cd cc-chat
bash install.sh          # macOS / Linux
```

```powershell
git clone https://github.com/Practical-creater/cc-chat.git
cd cc-chat
powershell -ExecutionPolicy Bypass -File .\install.ps1    # Windows
```

## Usage

| Command | What it does |
|---|---|
| `chat` | Start a new conversation (from any folder) |
| `chat "your question"` | Start with a first question |
| `chat -c` | Continue your last chat |
| `chat -r` | Pick an earlier chat to resume |
| `/clear` inside a chat | Clear the context, like "New chat" on the website |
| `/model` inside a chat | Switch model or reasoning effort |
| `/exit` or `Ctrl+C` twice | Quit |

On first run, Claude Code may ask whether you trust the folder. Choose **Yes**: it is cc-chat's own empty folder.

`chat` accepts any `claude` flag, e.g. `chat --model sonnet`.

## Customizing the style

The chat style comes entirely from one prompt file. Edit and save it, and the next `chat` uses it:

- macOS / Linux: `~/.cc-chat/prompt.md`
- Windows: `%USERPROFILE%\.cc-chat\prompt.md`

For example, add "Keep answers brief." if replies feel too long. To restore the default, copy `prompt.default.md` from the same folder over `prompt.md`.

**Use a different command name** if `chat` clashes with something you already have, e.g. `cchat`:

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | CC_CHAT_NAME=cchat bash
```

```powershell
$env:CC_CHAT_NAME='cchat'; irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.ps1 | iex
```

## Update

Run the install command again. Your edited `prompt.md` is kept; the new default prompt goes to `prompt.default.md`.

## Uninstall

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.sh | bash
```

Windows:

```powershell
irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.ps1 | iex
```

This removes the `chat` command, the PATH entry and the `~/.cc-chat` folder (including your edited prompt). Claude Code itself is not touched. If you installed under a custom name, set the same `CC_CHAT_NAME` when uninstalling.

## FAQ

**`chat` says "command not found", or does nothing?**
Open a new terminal window after installing. macOS also ships an unrelated system command, `/usr/sbin/chat`. If typing `chat` just hangs, that one is running: press `Ctrl+C`, make sure you opened a new window, and check that the cc-chat block exists in `~/.zshrc`.

**The installer says `already defines 'chat'`?**
Your shell config already has an alias or function named `chat`, which would override cc-chat. Remove that line, or install under another name as shown above.

**My status bar still shows several MCPs. Are they loaded?**
Some status bar plugins (such as claude-hud) count MCP servers by reading your config files, so they don't know cc-chat passed `--strict-mcp-config`. To see what is actually loaded, type `/mcp` in the chat. Your own MCP servers won't be listed. Only Claude Code's built-in ones (marked "Built-in") remain; they can't be turned off by flags and add very little to the context.

**Is it identical to claude.ai?**
Not quite. The prompt is adapted from the tone and formatting sections of the published claude.ai system prompt (https://platform.claude.com/docs/en/release-notes/system-prompts), so the style is close. Website features such as memory, Artifacts and file or image uploads are not available in the terminal, and terminals render Markdown tables and math less clearly.

**Non-English input is garbled in Windows cmd?**
Use PowerShell or Windows Terminal, or type `chat` first and enter your question inside the session.

**Can it read files on my computer?**
No. cc-chat disables all file and shell tools and runs in an empty folder.

## How it works

`chat` is a small launcher that:

1. reads `prompt.md`, appends today's date, and writes the session's system prompt file;
2. switches to the empty folder `~/.cc-chat/workspace`;
3. runs:

   ```bash
   claude --system-prompt-file <prompt file> \
          --tools "WebSearch,WebFetch" \
          --strict-mcp-config
   ```

   - `--system-prompt-file` replaces Claude Code's default coding prompt.
   - `--tools "WebSearch,WebFetch"` keeps web search only; no file access or shell.
   - `--strict-mcp-config` skips your configured MCP servers.

Everything lives in `~/.cc-chat` (`%USERPROFILE%\.cc-chat` on Windows). Claude Code stores the chat history itself under `~/.claude/projects/`.

## License

[MIT](LICENSE)
