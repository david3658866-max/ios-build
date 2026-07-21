# Capture device logs: file log pull + logcat + optional cold start.
# Usage:
#   .\tool\capture_logs.ps1                    # pull existing logs
#   .\tool\capture_logs.ps1 -WatchSec 60       # wait 60s then pull (reproduce issue during wait)
#   .\tool\capture_logs.ps1 -ColdStart         # restart app, wait, pull

param(
    [string]$DeviceId = "",
    [int]$WatchSec = 0,
    [switch]$ColdStart
)

. (Join-Path $PSScriptRoot "adb_util.ps1")

$Pkg = "com.cyberis.vortek"
$Activity = "$Pkg/.MainActivity"

$id = Wait-AdbDevice -DeviceId $DeviceId
if (-not $id) { Write-Error "No online device." }

Write-Host "[capture] device: $id"

if ($ColdStart) {
    Invoke-AdbDevice -DeviceId $id am force-stop $Pkg | Out-Null
    Start-Sleep -Seconds 1
    Invoke-AdbDevice -DeviceId $id shell am start -n $Activity | Out-Null
    Write-Host "[capture] cold started app"
}

if ($WatchSec -gt 0) {
    Write-Host "[capture] waiting ${WatchSec}s — reproduce issue on phone now..."
    Start-Sleep -Seconds $WatchSec
}

& (Join-Path $PSScriptRoot "pull_device_logs.ps1") -DeviceId $id
exit $LASTEXITCODE
