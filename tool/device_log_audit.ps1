# 轻量真机检查：不重装 integration 包，冷启动 + 拉日志 + 扫描异常。
param(
    [string]$DeviceId = "TWQYD23630026330",
    [int]$WaitDeviceSec = 60,
    [int]$WatchSec = 15
)

. (Join-Path $PSScriptRoot "adb_util.ps1")

$root = Split-Path $PSScriptRoot -Parent
$Pkg = "com.cyberis.vortek"
$Activity = "$Pkg/.MainActivity"

$id = Wait-AdbDevice -DeviceId $DeviceId -MaxSec $WaitDeviceSec
if (-not $id) { Write-Error "device offline"; exit 1 }

Write-Host "[audit] device: $id"
Invoke-AdbDevice -DeviceId $id shell am force-stop $Pkg | Out-Null
Start-Sleep -Seconds 1
Invoke-AdbDevice -DeviceId $id shell am start -n $Activity | Out-Null
Write-Host "[audit] cold started, watch ${WatchSec}s (可操作手机)..."
Start-Sleep -Seconds $WatchSec

& (Join-Path $PSScriptRoot "pull_device_logs.ps1") -DeviceId $id

$log = Join-Path $root "build\device_logs\vortek_debug.log"
if (-not (Test-Path $log)) { Write-Error "no log file"; exit 1 }

# 只审计最近一次冷启动之后的日志，避免历史 500 误报。
$lines = Get-Content $log -Encoding UTF8
$start = 0
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match '\[Smoke\] bootstrap done') {
        $start = $i
        break
    }
}
$slice = if ($start -gt 0) { $lines[$start..($lines.Count - 1)] } else { $lines }
$tail = $slice -join "`n"
$tmp = Join-Path $root "build\device_logs\vortek_audit_slice.log"
$tail | Set-Content -Path $tmp -Encoding UTF8

$patterns = @{
    fail = 'sendGroup failed|sendPrivate failed|code=500|bootstrap.*fail|login failed'
    ok   = 'sendGroup ok|sendPrivate ok|login ok|bootstrap done|WS.*login success'
    warn = 'network error|ensureAvailableLine|device offline'
}

Write-Host ""
Write-Host "=== audit summary (since last bootstrap) ==="
foreach ($k in $patterns.Keys) {
    $m = Select-String -Path $tmp -Pattern $patterns[$k] | Select-Object -Last 8
    if ($m) {
        Write-Host "[$k]"
        $m | ForEach-Object { $_.Line.Trim() }
    }
}

$failCount = (Select-String -Path $tmp -Pattern $patterns.fail).Count
if ($failCount -gt 0) {
    Write-Host "[audit] found $failCount failure lines" -ForegroundColor Yellow
    exit 2
}
Write-Host "[audit] no failure patterns in log" -ForegroundColor Green
