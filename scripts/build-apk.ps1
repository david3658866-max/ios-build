# Build APK. Default: release + arm64-only (smaller sideload package).
# Examples:
#   .\scripts\build-apk.ps1
#   .\scripts\build-apk.ps1 -AppEnv test
#   .\scripts\build-apk.ps1 -BuildMode debug -AppEnv test
param(
    [ValidateSet('release', 'debug')]
    [string]$BuildMode = 'release',
    [ValidateSet('test', 'prod')]
    [string]$AppEnv = 'test',
    [switch]$FatApk
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\dev-env.ps1"

$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot

flutter pub get

$argsList = @('build', 'apk', "--$BuildMode", "--dart-define=APP_ENV=$AppEnv")
if (-not $FatApk) {
    # Keep single ABI. Do not combine with --split-per-abi when gradle abiFilters is set.
    $argsList += @('--target-platform=android-arm64')
}

Write-Host "flutter $($argsList -join ' ')"
flutter @argsList

if ($LASTEXITCODE -ne 0) {
    throw "flutter build failed: $LASTEXITCODE"
}

$outDir = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
# Prefer the APK just built for this mode (avoid reporting stale arm64-split artifacts).
$candidates = @(
    (Join-Path $outDir "app-$BuildMode.apk"),
    (Join-Path $outDir "app-arm64-v8a-$BuildMode.apk")
)
$apk = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $apk) {
    throw "APK not found under $outDir"
}
Write-Host "Built: $apk ($([math]::Round((Get-Item $apk).Length/1MB, 1)) MB)"
