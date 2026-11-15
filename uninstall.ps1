# cc-chat uninstaller for Windows.
#   irm https://raw.githubusercontent.com/Practical-creater/cc-chat/main/uninstall.ps1 | iex

$ErrorActionPreference = 'Stop'
$AppHome = if ($env:CC_CHAT_HOME) { $env:CC_CHAT_HOME } else { Join-Path $env:USERPROFILE '.cc-chat' }
$BinDir  = Join-Path $AppHome 'bin'

$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($UserPath) {
    $Kept = ($UserPath -split ';') | Where-Object { $_ -and ($_ -ne $BinDir) }
    [Environment]::SetEnvironmentVariable('Path', ($Kept -join ';'), 'User')
    Write-Host "Removed $BinDir from your user PATH"
}

if (Test-Path $AppHome) {
    Remove-Item -Recurse -Force $AppHome
    Write-Host "Removed $AppHome"
}

Write-Host 'cc-chat has been uninstalled. Claude Code itself was not touched.'
