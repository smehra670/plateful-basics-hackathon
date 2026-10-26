# One-click Plateful start: server + USB tunnel + Flutter on phone.
# Run from the project root:  .\start-plateful.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$adb = Join-Path $env:LOCALAPPDATA 'Android\sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
  $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
}

Write-Host ''
Write-Host '=== Plateful startup ===' -ForegroundColor Green
Write-Host "Project: $root"

# 1) Make sure the phone is visible
if (Test-Path $adb) {
  Write-Host ''
  Write-Host '1) Checking phone USB...' -ForegroundColor Cyan
  & $adb start-server | Out-Null
  $devices = & $adb devices | Select-String -Pattern '\tdevice$'
  if (-not $devices) {
    Write-Host 'No phone found. Unlock phone, plug USB, set File transfer, allow USB debugging.' -ForegroundColor Yellow
    Write-Host 'Then run this script again.' -ForegroundColor Yellow
    exit 1
  }
  Write-Host "Phone OK: $devices"
  Write-Host 'Setting adb reverse tcp:3001...'
  & $adb reverse --remove-all 2>$null
  & $adb reverse tcp:3001 tcp:3001 | Out-Null
  & $adb reverse --list
} else {
  Write-Host 'adb.exe not found — skipping USB reverse. Use same Wi-Fi + LAN IP instead.' -ForegroundColor Yellow
}

# 2) Start API server if needed
Write-Host ''
Write-Host '2) Starting API server...' -ForegroundColor Cyan
$healthOk = $false
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:3001/api/health' -TimeoutSec 2 -UseBasicParsing
  if ($r.StatusCode -eq 200) { $healthOk = $true }
} catch {}

if ($healthOk) {
  Write-Host 'Server already running on port 3001.'
} else {
  $serverDir = Join-Path $root 'server'
  Start-Process powershell -ArgumentList @(
    '-NoExit',
    '-Command',
    "Set-Location '$serverDir'; Write-Host 'Plateful API server' -ForegroundColor Green; npm run dev"
  )
  Write-Host 'Waiting for server...'
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
      $r = Invoke-WebRequest -Uri 'http://127.0.0.1:3001/api/health' -TimeoutSec 1 -UseBasicParsing
      if ($r.StatusCode -eq 200) { $healthOk = $true; break }
    } catch {}
  }
  if (-not $healthOk) {
    Write-Host 'Server did not respond. Check server/.env and the new server window.' -ForegroundColor Red
    exit 1
  }
  Write-Host 'Server is up.'
}

# 3) Launch the app
Write-Host ''
Write-Host '3) Launching Flutter on phone...' -ForegroundColor Cyan
Set-Location $root
flutter run -d SM
