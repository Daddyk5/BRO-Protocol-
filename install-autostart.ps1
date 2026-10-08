# One-time setup: builds the backend and web app, makes Bro Protocol start
# by itself at every Windows login (no IDE needed), and starts it now.
#   powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1
# Undo: powershell -ExecutionPolicy Bypass -File .\stop-bro.ps1 -Uninstall
#
# Run it again after you change the code, to rebuild.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

Write-Host 'Building the backend...' -ForegroundColor Cyan
Push-Location (Join-Path $root 'server')
if (-not (Test-Path 'node_modules')) { npm install --no-audit --no-fund }
npm run build
Pop-Location

Write-Host 'Building the web app...' -ForegroundColor Cyan
Push-Location (Join-Path $root 'web-next')
if (-not (Test-Path 'node_modules')) { npm install --no-audit --no-fund }
npm run build
Pop-Location

# A shortcut in the Startup folder runs the launcher hidden at each login.
# (No admin rights needed.)
$startup = [Environment]::GetFolderPath('Startup')
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $startup 'Bro Protocol.lnk'))
$shortcut.TargetPath = (Get-Command powershell).Source
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$(Join-Path $root 'run-bro.ps1')`""
$shortcut.WorkingDirectory = $root
$shortcut.Description = 'Starts the Bro Protocol backend and web app'
$shortcut.Save()
Write-Host "Autostart installed: $startup\Bro Protocol.lnk" -ForegroundColor Green

# Restart so the fresh build is what's served.
& (Join-Path $root 'stop-bro.ps1')
& (Join-Path $root 'run-bro.ps1')
