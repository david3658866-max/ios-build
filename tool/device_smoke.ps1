# Device smoke test via USB adb (no Flutter integration_test VM channel)
# Usage: .\tool\device_smoke.ps1 [-DeviceId TWQYD23630026330] [-WaitSeconds 45]

param(
    [string]$DeviceId = "",
    [int]$WaitSeconds = 45
)

$ErrorActionPreference = "Stop"
$Adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
if (-not (Test-Path $Adb)) { $Adb = "adb" }

$Pkg = "com.cyberis.vortek"
$Activity = "$Pkg/.MainActivity"
$OutDir = (Join-Path $PSScriptRoot "..\build\device_smoke")
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$LogFile = Join-Path $OutDir "logcat.txt"
$ShotFile = Join-Path $OutDir "screenshot.png"

function Wait-AdbOnline {
    param([int]$MaxSec = 60)
    $deadline = (Get-Date).AddSeconds($MaxSec)
    while ((Get-Date) -lt $deadline) {
        & $Adb kill-server 2>$null | Out-Null
        Start-Sleep -Milliseconds 500
        & $Adb start-server 2>$null | Out-Null
        Start-Sleep -Milliseconds 500
        & $Adb reconnect 2>$null | Out-Null
        Start-Sleep -Seconds 2
        $lines = & $Adb devices 2>&1
        foreach ($line in $lines) {
            if ($line -match "^\s*(\S+)\s+device\s*$") { return $Matches[1] }
        }
        Write-Host "[device_smoke] waiting for device..."
        Start-Sleep -Seconds 3
    }
    return $null
}

$id = if ($DeviceId) { $DeviceId } else { Wait-AdbOnline }
if (-not $id) {
    Write-Error "No online device. Replug USB, allow debugging, disable Huawei ADB install monitor."
}

Write-Host "[device_smoke] device: $id"

function Invoke-Adb {
    param([string[]]$Args)
    & $Adb -s $id @Args
}

Invoke-Adb @("logcat", "-c") | Out-Null
Start-Sleep -Seconds 1
Invoke-Adb @("shell", "am", "force-stop", $Pkg) | Out-Null
Start-Sleep -Seconds 1
Invoke-Adb @("shell", "am", "start", "-n", $Activity) | Out-Null
Write-Host "[device_smoke] cold start, waiting ${WaitSeconds}s..."

Start-Sleep -Seconds $WaitSeconds

$logLines = & $Adb -s $id logcat -d -v time -s flutter 2>&1
$log = ($logLines | Out-String)
if ($log.Length -lt 20) {
    $logLines = & $Adb -s $id logcat -d -v time 2>&1
    $log = ($logLines | Out-String)
}
Set-Content -Path $LogFile -Value $log -Encoding UTF8

$procAlive = (& $Adb -s $id shell pidof $Pkg 2>&1 | Out-String).Trim()

$started = $log -match "Vortek IM|flutter"
$mainOk = $log -match "\[Smoke\] bootstrap done -> main|\[Smoke\] login ok -> main|\[Http\] token refreshed"
$loginPage = $log -match "\[Smoke\] bootstrap done -> login"
$crashed = $log -match "FATAL EXCEPTION|AndroidRuntime.*FATAL"

try {
    $bytes = Invoke-Adb @("exec-out", "screencap", "-p")
    [IO.File]::WriteAllBytes($ShotFile, $bytes)
} catch {}

Write-Host ""
Write-Host "=== device_smoke result ==="
Write-Host "  process:    $(if ($procAlive) { $procAlive } else { 'not running' })"
Write-Host "  main:       $mainOk"
Write-Host "  login_page: $loginPage"
Write-Host "  crashed:    $crashed"
Write-Host "  log:        $LogFile"
Write-Host "  screenshot: $ShotFile"

if ($crashed) { exit 2 }
if ($mainOk -or $loginPage) { exit 0 }
if ($started -or $procAlive) { exit 0 }
exit 1
