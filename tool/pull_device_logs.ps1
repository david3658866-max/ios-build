# Pull in-app debug log from device (works when logcat buffer is empty / adb flaky).
# Usage: .\tool\pull_device_logs.ps1 [-DeviceId TWQYD23630026330]

param([string]$DeviceId = "")

. (Join-Path $PSScriptRoot "adb_util.ps1")

$Pkg = "com.cyberis.vortek"
$RelLog = "app_flutter/vortek_debug.log"
$OutDir = Join-Path $PSScriptRoot "..\build\device_logs"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutFile = Join-Path $OutDir "vortek_debug.log"
$OldFile = Join-Path $OutDir "vortek_debug.old.log"

$id = Wait-AdbDevice -DeviceId $DeviceId
if (-not $id) {
    Write-Error "No online device. Replug USB and allow debugging."
}

Write-Host "[pull] device: $id"
$adb = Get-AdbPath

function Pull-RunAsFile {
    param([string]$RemotePath, [string]$LocalPath)
    $args = @("-s", $id, "exec-out", "run-as", $Pkg, "cat", $RemotePath)
    $p = Start-Process -FilePath $adb -ArgumentList $args `
        -RedirectStandardOutput $LocalPath -RedirectStandardError "$LocalPath.err" `
        -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) { return $false }
    if (-not (Test-Path $LocalPath)) { return $false }
    $head = Get-Content -Path $LocalPath -TotalCount 1 -ErrorAction SilentlyContinue
    if ($head -match "^Android Debug Bridge") { return $false }
    return (Get-Item $LocalPath).Length -gt 0
}

$ok = Pull-RunAsFile -RemotePath $RelLog -LocalPath $OutFile
if (-not $ok) {
    $ok = Pull-RunAsFile -RemotePath "files/$RelLog" -LocalPath $OutFile
}

if ($ok) {
    Write-Host "[pull] saved -> $OutFile ($((Get-Item $OutFile).Length) bytes)"
    if (Pull-RunAsFile -RemotePath "app_flutter/vortek_debug.old.log" -LocalPath $OldFile) {
        Write-Host "[pull] old    -> $OldFile"
    }
} else {
    Write-Host "[pull] file log missing. fallback logcat..."
    $logcatFile = Join-Path $OutDir "logcat_extract.txt"
    & $adb -s $id logcat -d -v time -t 800 2>$null | Out-File -FilePath $logcatFile -Encoding utf8
    $filtered = Get-Content $logcatFile -ErrorAction SilentlyContinue | Where-Object {
        $_ -match "flutter|Vortek|\[Chat\]|\[Http\]|\[Line\]|\[WS\]|\[Smoke\]|\[Auth\]|cyberis"
    }
    if ($filtered) {
        $filtered | Set-Content -Path $OutFile -Encoding UTF8
        Write-Host "[pull] saved logcat extract -> $OutFile"
    } else {
        Write-Error "No logs. Install debug APK, open app, reproduce issue, retry."
    }
}

Write-Host ""
Write-Host "=== last 30 lines ==="
Get-Content $OutFile -Tail 30 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_ }
