# Shared adb helpers for device scripts.

function Get-AdbPath {
    $p = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
    if (Test-Path $p) { return $p }
    return "adb"
}

function Wait-AdbDevice {
    param(
        [string]$DeviceId = "",
        [int]$MaxSec = 90
    )
    $adb = Get-AdbPath
    $deadline = (Get-Date).AddSeconds($MaxSec)
    while ((Get-Date) -lt $deadline) {
        & $adb start-server 2>$null | Out-Null
        & $adb reconnect 2>$null | Out-Null
        Start-Sleep -Seconds 2
        $lines = & $adb devices 2>&1
        foreach ($line in $lines) {
            if ($line -match "^\s*(\S+)\s+device\s*$") {
                $found = $Matches[1]
                if (-not $DeviceId -or $found -eq $DeviceId) { return $found }
            }
        }
        Write-Host "[adb] waiting for device..."
        Start-Sleep -Seconds 2
    }
    return $null
}

function Invoke-AdbDevice {
    param(
        [string]$DeviceId,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$AdbArgs
    )
    $adb = Get-AdbPath
    & $adb -s $DeviceId @AdbArgs
}
