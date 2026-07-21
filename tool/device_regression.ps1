# 真机回归：等待设备 → 安装 debug 包 → 日志审计（默认）→ 可选 integration_test
param(
    [string]$DeviceId = "TWQYD23630026330",
    [int]$WaitDeviceSec = 120,
    [switch]$WithIntegrationTest
)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "adb_util.ps1")

$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "[regression] waiting for device (max ${WaitDeviceSec}s)..."
$id = Wait-AdbDevice -DeviceId $DeviceId -MaxSec $WaitDeviceSec
if (-not $id) {
    Write-Error "No online device. Plug USB, enable USB debugging, unlock phone."
}

Write-Host "[regression] device: $id"
Write-Host "[regression] building debug apk..."
flutter build apk --debug | Out-Host
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "[regression] install (adb install -r)..."
Invoke-AdbDevice -DeviceId $id install -r $apk | Out-Host

if ($WithIntegrationTest) {
    Write-Host "[regression] integration test (华为 adb 重装易掉线，默认已跳过)..."
    flutter test integration_test/device_regression_test.dart -d $id 2>&1 | Tee-Object -Variable testOut
    $testExit = $LASTEXITCODE
} else {
  $testExit = 0
}

Write-Host "[regression] cold start audit..."
& (Join-Path $PSScriptRoot "device_log_audit.ps1") -DeviceId $id -WatchSec 15
$auditExit = $LASTEXITCODE

Write-Host "[regression] API probe..."
dart run tool/probe_group_send.dart | Out-Host
$probeExit = $LASTEXITCODE

Write-Host ""
Write-Host "=== log: send ok/fail ==="
$log = Join-Path $root "build\device_logs\vortek_debug.log"
if (Test-Path $log) {
    Select-String -Path $log -Pattern "sendGroup|sendPrivate|failed|Smoke|bootstrap" | Select-Object -Last 20 | ForEach-Object { $_.Line }
}

if ($testExit -ne 0 -or $auditExit -ne 0 -or $probeExit -ne 0) {
    Write-Host "[regression] FAILED (test=$testExit audit=$auditExit probe=$probeExit)" -ForegroundColor Red
    exit 1
}
Write-Host "[regression] PASSED" -ForegroundColor Green
