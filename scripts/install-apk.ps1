# Install APK to connected device. Prefers app-release.apk / arm64 artifacts.
# Examples:
#   .\scripts\install-apk.ps1
#   .\scripts\install-apk.ps1 -ApkPath .\build\app\outputs\flutter-apk\app-release.apk
param(
    [string]$ApkPath = '',
    [switch]$SkipAdbReverse
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\dev-env.ps1"

$adb = if ($env:ADB) { $env:ADB } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
$projectRoot = Split-Path $PSScriptRoot -Parent
$repoRoot = Split-Path $projectRoot -Parent
$outDir = Join-Path $projectRoot 'build\app\outputs\flutter-apk'

if ($ApkPath) {
    $apk = $ApkPath
} else {
    $candidates = @(
        (Join-Path $outDir 'app-release.apk'),
        (Join-Path $outDir 'app-arm64-v8a-release.apk'),
        (Join-Path $outDir 'app-debug.apk'),
        (Join-Path $outDir 'app-arm64-v8a-debug.apk')
    )
    $apk = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $apk -or -not (Test-Path $apk)) {
    throw "APK not found, run build-apk.ps1 first: $outDir"
}

$devices = & $adb devices
$devices | ForEach-Object { Write-Host $_ }

$ready = @($devices | Where-Object { $_ -match '^\S+\s+device(\s|$)' })
if ($ready.Count -eq 0) {
    throw 'No device in "device" state. Enable USB debugging and reconnect.'
}

Write-Host "Installing $apk ($([math]::Round((Get-Item $apk).Length/1MB, 1)) MB)"
& $adb install -r $apk
if ($LASTEXITCODE -ne 0) {
    Write-Host 'install -r failed, uninstall then install...'
    & $adb uninstall com.cyberis.vortek | Out-Null
    & $adb install $apk
    if ($LASTEXITCODE -ne 0) { throw "adb install failed: $LASTEXITCODE" }
}
Write-Host 'Install done.'

if (-not $SkipAdbReverse) {
    $reverseScript = Join-Path $repoRoot 'deploy\local\flutter-adb-reverse.js'
    if (Test-Path $reverseScript) {
        Write-Host 'Restoring adb reverse...'
        node $reverseScript
    }
}
