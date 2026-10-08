# Starts Bro Protocol in the background: the backend (port 8080) and the web
# app (port 3000), using the local Ollama model. Safe to run any number of
# times: anything already running is left alone. No IDE or terminal needed;
# install-autostart.ps1 runs this at every login.
#
# Logs: %LOCALAPPDATA%\BroProtocol\logs

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$logs = Join-Path $env:LOCALAPPDATA 'BroProtocol\logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

function Write-Log([string]$message) {
  $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $message"
  Add-Content -Path (Join-Path $logs 'launcher.log') -Value $line
  Write-Host $line
}

function Test-Port([int]$port) {
  [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

$node = (Get-Command node -ErrorAction SilentlyContinue).Source
if (-not $node) { Write-Log 'ERROR: Node.js not found on PATH.'; exit 1 }

# 1. Ollama (it normally starts itself at login; start it if it didn't).
if (-not (Test-Port 11434)) {
  $ollama = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe'
  if (Test-Path $ollama) {
    Write-Log 'Starting Ollama'
    Start-Process -FilePath $ollama -WindowStyle Hidden
    foreach ($i in 1..30) { if (Test-Port 11434) { break }; Start-Sleep -Seconds 1 }
  } else {
    Write-Log 'WARNING: Ollama is not running and was not found; replies will fail until it starts.'
  }
}

# 2. Backend on :8080 (settings from server\.env, Ollama on this PC).
if (Test-Port 8080) {
  Write-Log 'Backend already running on :8080'
} else {
  $server = Join-Path $root 'server'
  if (-not (Test-Path (Join-Path $server 'lib\server.js'))) {
    Write-Log 'ERROR: backend not built. Run install-autostart.ps1 once.'; exit 1
  }
  $env:OLLAMA_URL = 'http://localhost:11434'
  $env:RATE_LIMIT_FILE = Join-Path $server 'data\rate-limits.json'
  Start-Process -FilePath $node -ArgumentList '--env-file=.env', 'lib/server.js' -WorkingDirectory $server `
    -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logs 'backend.log') -RedirectStandardError (Join-Path $logs 'backend.err.log')
  Write-Log 'Started backend on :8080'
}

# 3. Web app on :3000, reachable from phones on the same Wi-Fi.
if (Test-Port 3000) {
  Write-Log 'Web app already running on :3000'
} else {
  $web = Join-Path $root 'web-next'
  if (-not (Test-Path (Join-Path $web '.next\BUILD_ID'))) {
    Write-Log 'ERROR: web app not built. Run install-autostart.ps1 once.'; exit 1
  }
  Start-Process -FilePath $node -ArgumentList 'node_modules/next/dist/bin/next', 'start', '-H', '0.0.0.0', '-p', '3000' `
    -WorkingDirectory $web -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logs 'web.log') -RedirectStandardError (Join-Path $logs 'web.err.log')
  Write-Log 'Started web app on :3000'
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
Write-Log "Ready. This PC: http://localhost:3000   iPhone on the same Wi-Fi: http://${ip}:3000"
