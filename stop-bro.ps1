# Stops the Bro Protocol backend (:8080) and web app (:3000).
#   powershell -ExecutionPolicy Bypass -File .\stop-bro.ps1
# Add -Uninstall to also stop it starting at login.
param([switch]$Uninstall)

foreach ($port in 3000, 8080) {
  Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}
Write-Host 'Stopped the backend and web app.'

if ($Uninstall) {
  $link = Join-Path ([Environment]::GetFolderPath('Startup')) 'Bro Protocol.lnk'
  if (Test-Path $link) { Remove-Item $link; Write-Host 'Autostart removed.' } else { Write-Host 'Autostart was not installed.' }
}
