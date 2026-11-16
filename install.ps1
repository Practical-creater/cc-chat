# cc-chat installer for Windows (PowerShell 5.1+).
#
#   irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/install.ps1 | iex
#
# Optional environment variables:
#   CC_CHAT_NAME   command name to install (default: chat)
#   CC_CHAT_HOME   data folder (default: %USERPROFILE%\.cc-chat)
#   CC_CHAT_NO_OFFICE=1  skip Word/Excel/PPT support (no uv, no MarkItDown)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$RepoRaw = 'https://raw.githubusercontent.com/Practical-creater/cc-chat/main'
$Name    = if ($env:CC_CHAT_NAME) { $env:CC_CHAT_NAME } else { 'chat' }
$AppHome = if ($env:CC_CHAT_HOME) { $env:CC_CHAT_HOME } else { Join-Path $env:USERPROFILE '.cc-chat' }
$BinDir  = Join-Path $AppHome 'bin'
$MarkItDownPkg = 'markitdown-mcp==0.0.1a8'

function Info($m) { Write-Host "==> $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!] $m" -ForegroundColor Yellow }

if ($Name -notmatch '^[A-Za-z0-9._-]+$') { throw "CC_CHAT_NAME may only contain letters, digits, '.', '_' and '-'." }

# 1. Claude Code must be installed.
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Warn "Claude Code (the 'claude' command) was not found."
    Warn "Install it first:  irm https://claude.ai/install.ps1 | iex"
    Warn "Then open a new terminal, run 'claude' once to log in, and run this installer again."
    throw 'Aborted.'
}

New-Item -ItemType Directory -Force -Path (Join-Path $AppHome 'workspace'), $BinDir | Out-Null

# 2. Prompt files. prompt.md (style) is the user's to edit and is kept;
#    tools.md (file handling) is always refreshed.
function Fetch($File, $Dest) {
    $Local = if ($PSScriptRoot) { Join-Path $PSScriptRoot $File } else { $null }
    if ($Local -and (Test-Path $Local)) {
        Copy-Item $Local $Dest -Force
    } else {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "$RepoRaw/$File" -OutFile $Dest
        } catch {
            throw "Could not download $File from GitHub. Check your network or proxy. $_"
        }
    }
}
$DefaultPrompt = Join-Path $AppHome 'prompt.default.md'
$UserPrompt    = Join-Path $AppHome 'prompt.md'
Fetch 'prompt.md' $DefaultPrompt
Fetch 'tools.md'  (Join-Path $AppHome 'tools.md')
if (Test-Path $UserPrompt) {
    Info "Keeping your existing prompt: $UserPrompt"
} else {
    Copy-Item $DefaultPrompt $UserPrompt
}

# 3. Word/Excel/PPT support: uv + Microsoft MarkItDown as a local MCP server.
$McpJson = Join-Path $AppHome 'mcp.json'
Remove-Item $McpJson -ErrorAction SilentlyContinue
if ($env:CC_CHAT_NO_OFFICE -ne '1') {
    $ErrorActionPreference = 'Continue'   # native tools write progress to stderr
    $Uv = (Get-Command uv -ErrorAction SilentlyContinue).Source
    $UvDefault = Join-Path $env:USERPROFILE '.local\bin\uv.exe'
    if (-not $Uv -and (Test-Path $UvDefault)) { $Uv = $UvDefault }
    if (-not $Uv) {
        Info 'Installing uv (needed for Word/Excel/PPT support)...'
        powershell -NoProfile -ExecutionPolicy Bypass -Command "`$env:UV_NO_MODIFY_PATH='1'; irm https://astral.sh/uv/install.ps1 | iex" *> $null
        if (Test-Path $UvDefault) { $Uv = $UvDefault }
    }
    $Md = $null
    if ($Uv) {
        Info 'Installing the Word/Excel/PPT converter (first time may take a minute)...'
        & $Uv tool install --force $MarkItDownPkg *> $null
        $ToolBin = (& $Uv tool dir --bin 2> $null | Select-Object -First 1)
        if ($ToolBin) {
            $Candidate = Join-Path $ToolBin.Trim() 'markitdown-mcp.exe'
            if (Test-Path $Candidate) { $Md = $Candidate }
        }
    }
    $ErrorActionPreference = 'Stop'
    if ($Md) {
        $Config = @{ mcpServers = @{ markitdown = @{ command = $Md; args = @() } } } | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($McpJson, $Config, (New-Object System.Text.UTF8Encoding($false)))
        Info 'Word/Excel/PPT support is ready.'
    } else {
        Warn 'Could not set up Word/Excel/PPT support. Plain chat, PDF and images still work.'
        Warn 'Check your network or proxy, then run this installer again.'
    }
}

# 4. The launcher: cc-chat.ps1 does the work, <name>.cmd makes it callable
#    from both PowerShell and cmd.exe regardless of execution policy.
$Ps1 = @'
# cc-chat launcher: a clean, claude.ai-style chat on top of Claude Code.
$ErrorActionPreference = 'Stop'
$AppHome = if ($env:CC_CHAT_HOME) { $env:CC_CHAT_HOME } else { Join-Path $env:USERPROFILE '.cc-chat' }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "cc-chat: 'claude' not found. Install Claude Code first: https://claude.com/claude-code" -ForegroundColor Red
    exit 1
}
$Workspace = Join-Path $AppHome 'workspace'
New-Item -ItemType Directory -Force -Path $Workspace | Out-Null
$Prompt = Join-Path $AppHome 'prompt.md'
if (-not (Test-Path $Prompt)) { $Prompt = Join-Path $AppHome 'prompt.default.md' }
$Session = Join-Path $AppHome '.session-prompt.md'
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Text = [IO.File]::ReadAllText($Prompt, $Utf8)
$Tools = Join-Path $AppHome 'tools.md'
if (Test-Path $Tools) { $Text += "`n`n" + [IO.File]::ReadAllText($Tools, $Utf8) }
$Text += "`n`nToday's date is $(Get-Date -Format 'yyyy-MM-dd').`n"
[IO.File]::WriteAllText($Session, $Text, $Utf8)
$Mcp = @()
$McpJson = Join-Path $AppHome 'mcp.json'
if (Test-Path $McpJson) { $Mcp = @('--mcp-config', $McpJson) }
if (-not $env:MCP_TIMEOUT) { $env:MCP_TIMEOUT = '60000' }
Set-Location $Workspace
& claude --system-prompt-file $Session --tools 'Read,WebSearch,WebFetch' @Mcp --strict-mcp-config @args
exit $LASTEXITCODE
'@
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $BinDir 'cc-chat.ps1'), $Ps1, $Utf8NoBom)

$Cmd = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0cc-chat.ps1`" %*`r`n"
[IO.File]::WriteAllText((Join-Path $BinDir "$Name.cmd"), $Cmd, (New-Object System.Text.ASCIIEncoding))
Info "Installed command: $(Join-Path $BinDir "$Name.cmd")"

# 5. Add BinDir to the user PATH.
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $UserPath) { $UserPath = '' }
if (($UserPath -split ';') -notcontains $BinDir) {
    $NewPath = if ($UserPath) { "$BinDir;$UserPath" } else { $BinDir }
    [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
    Info "Added $BinDir to your user PATH"
}
$env:Path = "$BinDir;$env:Path"

Write-Host ''
Info "Done. Open a NEW terminal window, then type:  $Name"
Info "Edit the chat style any time:  $UserPrompt"
