# Local Android device debug entry: restore adb reverse before flutter run.
# This keeps media URLs like 127.0.0.1:9001 reachable from the phone.
param(
    [string]$DeviceId = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\dev-env.ps1"

$projectRoot = Split-Path $PSScriptRoot -Parent
$repoRoot = Split-Path $projectRoot -Parent
$reverseScript = Join-Path $repoRoot 'deploy\local\flutter-adb-reverse.js'

if (-not (Test-Path $reverseScript)) {
    throw "adb reverse script not found: $reverseScript"
}

Set-Location $projectRoot

Write-Host 'Restoring adb reverse ports for local device debug...'
node $reverseScript

$argsList = @('run')
if ($DeviceId) {
    $argsList += @('-d', $DeviceId)
}
if ($FlutterArgs) {
    $argsList += $FlutterArgs
}

Write-Host "flutter $($argsList -join ' ')"
flutter @argsList
