# cc-chat

**中文** | [English](README.en.md)

在终端里用 Claude Code 获得接近 claude.ai 网页版的纯聊天体验。一行命令安装，支持 macOS、Linux 和 Windows。

直接运行 `claude` 时，Claude Code 是一个编程助手：系统提示词以写代码为目标，回答偏简短、偏任务式；它会加载你配置的所有 MCP 服务器、插件和 skills，还会读取当前目录的 CLAUDE.md。拿它来聊天，回答风格和上下文都和网页版不一样。

cc-chat 安装一个 `chat` 命令，启动一个专门用来聊天的 Claude Code 会话：

| | 直接运行 `claude` | 运行 `chat` |
|---|---|---|
| 系统提示词 | Claude Code 默认的编程向提示词 | **替换**为参照官方公开的 claude.ai 提示词编写的对话提示词 |
| 工具 | 读写文件、执行命令等全部工具 | 只保留联网搜索（WebSearch、WebFetch） |
| 你配置的 MCP 服务器 | 全部加载 | 不加载 |
| 运行目录 | 当前所在目录，会读取那里的 CLAUDE.md | 固定在独立的空目录，不受项目文件影响 |
| 聊天记录 | 和编程会话混在一起 | 单独存放，`chat -c` / `chat -r` 只找聊天记录 |

## 前提条件

1. **已安装 Claude Code 并登录。** 在终端里输入 `claude` 能正常进入对话即可。还没装的话：
   - macOS / Linux：`curl -fsSL https://claude.ai/install.sh | bash`
   - Windows（PowerShell）：`irm https://claude.ai/install.ps1 | iex`
   - 装好后打开新终端，运行一次 `claude`，按提示登录（需要 Claude Pro / Max 等订阅，或 API Key）。
   - 官方文档：https://docs.claude.com/en/docs/claude-code/setup
2. **能访问 GitHub。** 安装脚本要从 `raw.githubusercontent.com` 下载文件。如果下载失败，请先配置好代理，或者用下面"方式二"手动安装。

## 安装

### macOS / Linux

打开"终端"（Terminal），粘贴下面这一行并回车：

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | bash
```

看到 `Done.` 后，**关闭当前终端窗口，重新打开一个**，然后输入：

```bash
chat
```

### Windows

1. 按 `Win` 键，搜索 **PowerShell** 并打开（推荐在 Windows Terminal 里使用）。
2. 粘贴下面这一行并回车：

   ```powershell
   irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.ps1 | iex
   ```

3. 看到 `Done.` 后，**关闭当前窗口，重新打开一个 PowerShell**，然后输入：

   ```powershell
   chat
   ```

### 方式二：克隆仓库后安装

适合不方便直接执行网络脚本，或者想先看看脚本内容的情况：

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

## 使用

| 命令 | 作用 |
|---|---|
| `chat` | 开始一段新对话（在任何目录下输入都可以） |
| `chat "你的问题"` | 带着第一个问题直接开始 |
| `chat -c` | 接着上一次的聊天继续 |
| `chat -r` | 从历史聊天里选一段恢复 |
| 对话中输入 `/clear` | 清空上下文，相当于网页版的"新对话" |
| 对话中输入 `/model` | 切换模型或调整思考强度 |
| 对话中输入 `/exit`，或连按两次 `Ctrl+C` | 退出 |

第一次运行时，Claude Code 可能会问你是否信任这个文件夹，选 **Yes** 即可。那是 cc-chat 自己的空目录，里面没有任何文件。

`chat` 后面可以接任何 `claude` 支持的参数，例如 `chat --model sonnet`。

## 自定义聊天风格

聊天风格完全由一个提示词文件决定，改完保存，下次运行 `chat` 就生效：

- macOS / Linux：`~/.cc-chat/prompt.md`
- Windows：`%USERPROFILE%\.cc-chat\prompt.md`

比如嫌回答太长，就在文件里加一句"回答尽量简短"。想恢复默认，把同目录下的 `prompt.default.md` 复制一份覆盖 `prompt.md`。

**换一个命令名**：如果 `chat` 和你已有的命令冲突，可以安装成别的名字，例如 `cchat`：

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.sh | CC_CHAT_NAME=cchat bash
```

```powershell
$env:CC_CHAT_NAME='cchat'; irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.ps1 | iex
```

## 更新

重新运行一次安装命令即可。你修改过的 `prompt.md` 会保留，新版默认提示词会放在 `prompt.default.md`。

## 卸载

macOS / Linux：

```bash
curl -fsSL https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.sh | bash
```

Windows：

```powershell
irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.ps1 | iex
```

卸载会删除 `chat` 命令、PATH 设置和 `~/.cc-chat` 文件夹（包括你改过的提示词），不会动 Claude Code 本身。如果安装时用了自定义命令名，卸载时也要带上同样的 `CC_CHAT_NAME`。

## 常见问题

**输入 `chat` 提示找不到命令，或者没反应？**
安装后要打开一个新的终端窗口才会生效。macOS 自带一个不相关的系统命令 `/usr/sbin/chat`，如果输入 `chat` 后终端卡住不动，说明运行的是那个系统命令：按 `Ctrl+C` 退出，确认已经开了新窗口；还不行就检查 `~/.zshrc` 里 cc-chat 的那一段是否存在。

**安装时提示 `already defines 'chat'`？**
你的 shell 配置文件里已经有一个叫 `chat` 的别名或函数，它会覆盖 cc-chat。删掉那一行，或者用上面的方法换个命令名安装。

**状态栏显示有好几个 MCP，是不是没屏蔽掉？**
一些状态栏插件（比如 claude-hud）是读取配置文件来统计 MCP 数量的，并不知道 cc-chat 用了 `--strict-mcp-config`，所以显示的数字不准。实际加载了什么，在对话里输入 `/mcp` 查看：你自己配置的 MCP 服务器不会出现。能看到的只有 Claude Code 内置的几个（标注 "Built-in"），这些无法通过参数关闭，对上下文的影响很小。

**和网页版完全一样吗？**
不完全一样。提示词是参照官方公开的 claude.ai 系统提示词（https://platform.claude.com/docs/en/release-notes/system-prompts ）里讲语气和格式的部分改写的，风格很接近；但网页版的记忆、Artifacts、上传文件和图片等功能，终端里没有。另外终端显示 Markdown 表格和数学公式不如网页清楚。

**Windows 上用 cmd 输入中文问题出现乱码？**
请在 PowerShell 或 Windows Terminal 里使用；或者先输入 `chat` 进入对话，再输入中文。

**会不会读取我电脑上的文件？**
不会。cc-chat 关闭了所有读写文件和执行命令的工具，并且在一个空目录里运行。

## 原理

`chat` 只是一个启动脚本，做了这几件事：

1. 读取 `prompt.md`，在末尾加上今天的日期，生成本次会话的系统提示词文件；
2. 切换到独立的空目录 `~/.cc-chat/workspace`；
3. 运行：

   ```bash
   claude --system-prompt-file <提示词文件> \
          --tools "WebSearch,WebFetch" \
          --strict-mcp-config
   ```

   - `--system-prompt-file`：替换 Claude Code 默认的编程向系统提示词。
   - `--tools "WebSearch,WebFetch"`：只保留联网搜索，不能读写文件、执行命令。
   - `--strict-mcp-config`：不加载你配置的 MCP 服务器。

所有文件都在 `~/.cc-chat`（Windows 为 `%USERPROFILE%\.cc-chat`）。聊天记录由 Claude Code 自己保存在 `~/.claude/projects/` 下。

## 许可证

[MIT](LICENSE)
