$ErrorActionPreference = "Stop"
$historyRoot = Join-Path $env:APPDATA "Cursor\User\History"
$projectRoot = "E:\0000IM\00code\my-im\im-flutter"
$corruptCutoff = [int64]1783448416949
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-ResourcePath([string]$resource) {
  if ($resource -notmatch "^file:///(.+)$") { return $null }
  return ([Uri]::UnescapeDataString($matches[1]) -replace "\\", "/")
}

function Pick-Entry($entries) {
  if (-not $entries -or $entries.Count -eq 0) { return $null }
  $pre = @($entries | Where-Object { [int64]$_.timestamp -lt $corruptCutoff })
  if ($pre.Count -gt 0) {
    return ($pre | Sort-Object { [int64]$_.timestamp } -Descending | Select-Object -First 1)
  }
  return ($entries | Sort-Object { [int64]$_.timestamp } -Descending | Select-Object -First 1)
}

$restored = 0; $missing = 0; $failed = @()
Get-ChildItem $historyRoot -Directory | ForEach-Object {
  $entriesFile = Join-Path $_.FullName "entries.json"
  if (-not (Test-Path $entriesFile)) { return }
  try { $meta = Get-Content $entriesFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return }
  $resourcePath = Get-ResourcePath $meta.resource
  if (-not $resourcePath) { return }
  if ($resourcePath -notmatch "/my-im/im-flutter/lib/.+\.dart$") { return }
  $rel = ($resourcePath -split "/my-im/im-flutter/", 2)[1] -replace "/", "\\"
  $target = Join-Path $projectRoot $rel
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $entry = Pick-Entry $meta.entries
  if (-not $entry) { $missing++; $failed += "no entry: $rel"; return }
  $snapshot = Join-Path $_.FullName $entry.id
  if (-not (Test-Path $snapshot)) { $missing++; $failed += "missing snapshot: $rel"; return }
  $text = [System.IO.File]::ReadAllText($snapshot, [System.Text.Encoding]::UTF8)
  [System.IO.File]::WriteAllText($target, $text, $utf8NoBom)
  $restored++
  Write-Host "[ok] $rel <= $($entry.id)"
}
Write-Host "restored=$restored missing=$missing"
if ($failed.Count -gt 0) { $failed | Select-Object -First 20 | ForEach-Object { Write-Host "issue: $_" } }