# Starts the Bro Protocol backend without Docker: Node + your local Ollama.
#   powershell -ExecutionPolicy Bypass -File .\start-backend.ps1
# Settings come from server\.env; OLLAMA_URL is overridden for running outside Docker.
# Your phone can reach it on the same Wi-Fi at http://<this PC's IP>:8080.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot 'server')

if (-not (Test-Path 'node_modules')) { npm install --no-audit --no-fund }
npm run build | Out-Null

$env:OLLAMA_URL = 'http://localhost:11434'
$env:RATE_LIMIT_FILE = (Join-Path $PSScriptRoot 'server\data\rate-limits.json')

$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
Write-Host "Backend: http://localhost:8080   Phone on the same Wi-Fi: http://${ip}:8080" -ForegroundColor Green

node --env-file=.env lib/server.js
