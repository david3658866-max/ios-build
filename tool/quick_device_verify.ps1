# 快速真机验收：adb 装包 → 冷启动审计 → API 发送探测（约 1 分钟，不走 integration_test）。
param(
    [string]$DeviceId = "TWQYD23630026330",
    [int]$WaitDeviceSec = 60,
    [int]$WatchSec = 12,
    [switch]$SkipBuild,
    [switch]$SkipProbe
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "adb_util.ps1")

$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$id = Wait-AdbDevice -DeviceId $DeviceId -MaxSec $WaitDeviceSec
if (-not $id) { Write-Error "device offline"; exit 1 }

if (-not $SkipBuild) {
    Write-Host "[verify] build debug apk..."
    flutter build apk --debug | Out-Host
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$apk = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "[verify] install..."
Invoke-AdbDevice -DeviceId $id install -r $apk | Out-Host

Write-Host "[verify] cold start audit..."
& (Join-Path $PSScriptRoot "device_log_audit.ps1") -DeviceId $id -WatchSec $WatchSec
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $SkipProbe) {
    Write-Host "[verify] API probe..."
    dart run tool/probe_group_send.dart | Out-Host
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "[verify] all passed" -ForegroundColor Green
