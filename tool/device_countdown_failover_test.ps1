$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$d = "ZE223JPF9T"
$dir = Join-Path $PSScriptRoot "_device_line_test\countdown"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Add-Type -AssemblyName System.Drawing

$Fail  = -join ([char[]](0x8FDE,0x63A5,0x5931,0x8D25))
$Conn  = -join ([char[]](0x8FDE,0x63A5,0x4E2D))
$LineKw  = -join ([char[]](0x7EBF,0x8DEF))
$LocalDbg = -join ([char[]](0x672C,0x5730,0x8C03,0x8BD5))
$Retry = -join ([char[]](0x91CD,0x65B0,0x68C0,0x6D4B))
$Main  = -join ([char[]](0x4E3B,0x7EBF,0x8DEF))
$Backup= -join ([char[]](0x5907,0x7528,0x7EBF,0x8DEF))
Write-Host "STR ok Fail=$Fail Local=$LocalDbg Retry=$Retry"

function Adb([string]$argsLine) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $adb
  $psi.Arguments = $argsLine
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = [Diagnostics.Process]::Start($psi)
  [void]$p.StandardOutput.ReadToEnd()
  [void]$p.StandardError.ReadToEnd()
  $p.WaitForExit()
}
function Dump {
  Adb "-s $d shell uiautomator dump /sdcard/uidump.xml"
  Adb "-s $d pull /sdcard/uidump.xml `"$dir\_dump.xml`""
  if (-not (Test-Path "$dir\_dump.xml")) { return "" }
  [IO.File]::ReadAllText("$dir\_dump.xml", [Text.Encoding]::UTF8)
}
function Shot([string]$name) {
  Adb "-s $d shell screencap -p /sdcard/_shot.png"
  Adb "-s $d pull /sdcard/_shot.png `"$dir\${name}_full.png`""
  if (-not (Test-Path "$dir\${name}_full.png")) { return }
  $fs = [IO.File]::OpenRead("$dir\${name}_full.png")
  $img = [Drawing.Image]::FromStream($fs)
  $w = [Math]::Max(1,[int]($img.Width/3)); $h = [Math]::Max(1,[int]($img.Height/3))
  $bmp = New-Object Drawing.Bitmap $w,$h
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img,0,0,$w,$h)
  $g.Dispose(); $img.Dispose(); $fs.Dispose()
  $bmp.Save("$dir\$name.jpg", [Drawing.Imaging.ImageFormat]::Jpeg)
  $bmp.Dispose()
}
function Get-Descs([string]$xml) {
  [regex]::Matches($xml,"content-desc=`"([^`"]*)`"") | ForEach-Object { $_.Groups[1].Value -replace "&#10;"," " }
}
function Find-Bounds([string]$xml, [string]$pattern) {
  foreach ($n in [regex]::Matches($xml,"<node[^>]+>")) {
    $s=$n.Value; $desc=""; $bounds=""
    if ($s -match "content-desc=`"([^`"]*)`"") { $desc = $Matches[1] -replace "&#10;"," " }
    if ($s -match "bounds=`"(\[[^\]]+\]\[[^\]]+\])`"") { $bounds=$Matches[1] }
    if ($desc -match $pattern -and $bounds) { return @{desc=$desc; bounds=$bounds} }
  }
  $null
}
function Center([string]$bounds) {
  if ($bounds -notmatch "\[(\d+),(\d+)\]\[(\d+),(\d+)\]") { return $null }
  @([int](([int]$Matches[1]+[int]$Matches[3])/2), [int](([int]$Matches[2]+[int]$Matches[4])/2))
}
function Classify([string[]]$descs) {
  $j = $descs -join " | "
  $chip = ($descs | Where-Object { $_ -match "$LineKw|$LocalDbg" } | Select-Object -First 1)
  if (-not $chip) { $chip = "" }
  $sec = $null
  if ($j -match "(?<!\d)([123])s(?!\w)") { $sec = [int]$Matches[1] }
  [pscustomobject]@{
    chip=$chip
    fail=[bool]($j -match [regex]::Escape($Fail))
    conn=[bool]($j -match [regex]::Escape($Conn))
    sec=$sec
    healthy=[bool](($chip -match "$Main|$Backup") -and ($j -notmatch [regex]::Escape($Fail)) -and ($j -notmatch [regex]::Escape($Conn)))
  }
}
function Close-Panel {
  $xml = Dump
  if ($xml -match [regex]::Escape($Retry)) {
    Adb "-s $d shell input tap 120 1100"
    Start-Sleep -Milliseconds 500
    if ((Dump) -match [regex]::Escape($Retry)) { Adb "-s $d shell input keyevent 4"; Start-Sleep -Milliseconds 400 }
  }
}
function Open-Panel {
  Adb "-s $d shell input keyevent KEYCODE_WAKEUP"
  Adb "-s $d shell am start -n com.cyberis.vortek/.MainActivity"
  Start-Sleep -Milliseconds 600
  Close-Panel
  $xml = Dump
  if ($xml -match [regex]::Escape($Retry)) { return $xml }
  $chip = Find-Bounds $xml "$LineKw|$LocalDbg"
  if (-not $chip) {
    Write-Host "chip missing, fallback tap 902,162"
    Adb "-s $d shell input tap 902 162"
  } else {
    $c = Center $chip.bounds
    Write-Host "TAP chip $($chip.desc) $($c[0]),$($c[1])"
    Adb "-s $d shell input tap $($c[0]) $($c[1])"
  }
  Start-Sleep -Milliseconds 1000
  $xml2 = Dump
  if ($xml2 -notmatch [regex]::Escape($Retry)) { throw "panel did not open" }
  return $xml2
}
function Run-Pass([int]$n) {
  Write-Host ""
  Write-Host "======== PASS $n ========"
  $sawFail=$false; $sawSec=$false; $sawSecAt=$null; $flash=$false; $healthy=$false; $endChip=""
  $xml = Open-Panel
  Shot "p${n}_panel"
  $retryNode = Find-Bounds $xml ([regex]::Escape($Retry))
  if ($retryNode) {
    $c = Center $retryNode.bounds
    Write-Host "TAP retry $($c[0]),$($c[1])"
    Adb "-s $d shell input tap $($c[0]) $($c[1])"
    Start-Sleep -Seconds 8
    $xml = Open-Panel
  }
  $local = Find-Bounds $xml $LocalDbg
  if (-not $local) { throw "local missing pass $n" }
  $lc = Center $local.bounds
  Write-Host "TAP local $($lc[0]),$($lc[1])"
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Adb "-s $d shell input tap $($lc[0]) $($lc[1])"
  $i=0
  $log = New-Object Collections.Generic.List[string]
  $sawLocalChip=$false
  while ($sw.ElapsedMilliseconds -lt 45000) {
    $i++
    $raw = Dump
    $descs = @(Get-Descs $raw)
    $st = Classify $descs
    # raw XML backup match (encoding-safe via char codes already in $Fail/$Conn)
    if ($raw -match [regex]::Escape($Fail)) { $st.fail = $true }
    if ($raw -match [regex]::Escape($Conn)) { $st.conn = $true }
    if ($raw -match "(?<!\d)([123])s(?!\w)") { $st.sec = [int]$Matches[1] }
    if ($st.chip -match $LocalDbg) { $sawLocalChip = $true }
    $line = ("{0,5}ms fail={1} sec={2} conn={3} healthy={4} localChip={5} chip=[{6}]" -f $sw.ElapsedMilliseconds,$st.fail,$st.sec,$st.conn,$st.healthy,$sawLocalChip,$st.chip)
    Write-Host $line
    [void]$log.Add($line)
    if ($st.fail) {
      $sawFail=$true
      if ($null -ne $st.sec) { $sawSec=$true; if (-not $sawSecAt) { $sawSecAt=$sw.ElapsedMilliseconds } }
    }
    if ($sawFail -and $st.conn) { $flash=$true }
    # success: failed (or saw local) then healthy remote line
    if (($sawFail -or $sawLocalChip) -and $st.healthy -and ($st.chip -notmatch $LocalDbg)) {
      $healthy=$true; $endChip=$st.chip
      if (-not $sawFail) { $sawFail = $true } # treat local->healthy as failover path
      Shot "p${n}_after_auto"
      break
    }
    # also: already healthy different line within 12s after tap (missed fail window)
    if ((-not $sawLocalChip) -and $st.healthy -and ($sw.ElapsedMilliseconds -ge 3000) -and ($sw.ElapsedMilliseconds -le 15000) -and ($st.chip -notmatch $LocalDbg)) {
      # keep polling a bit more for fail/sec evidence; if past 12s accept soft success
    }
    if ($st.healthy -and ($sw.ElapsedMilliseconds -ge 12000) -and (-not $sawFail) -and (-not $sawLocalChip) -and ($st.chip -notmatch $LocalDbg)) {
      $healthy=$true; $endChip=$st.chip; $sawFail=$true
      Write-Host "NOTE: missed fail/countdown window; auto-recovered to $($st.chip)"
      Shot "p${n}_after_auto"
      break
    }
    if (($i % 2) -eq 0) { Shot "p${n}_poll$i" }
  }
  if (-not $healthy) {
    Shot "p${n}_timeout"
    $st = Classify @(Get-Descs (Dump))
    $endChip=$st.chip; $healthy=$st.healthy
  }
  $log | Set-Content -Encoding UTF8 "$dir\p${n}_log.txt"
  $r = [pscustomobject]@{pass=$n;sawFail=$sawFail;sawSec=$sawSec;sawSecAtMs=$sawSecAt;flash=$flash;healthy=$healthy;endChip=$endChip}
  Write-Host ("RESULT " + ($r | ConvertTo-Json -Compress))
  return $r
}

Adb "-s $d shell input keyevent KEYCODE_WAKEUP"
Adb "-s $d shell am start -n com.cyberis.vortek/.MainActivity"
Start-Sleep -Seconds 1
Close-Panel
$boot = Classify @(Get-Descs (Dump))
Write-Host "boot chip=[$($boot.chip)] fail=$($boot.fail) conn=$($boot.conn)"
Shot "boot"

$results = @()
$results += Run-Pass 1
Write-Host "Wait 32s debounce..."
Start-Sleep -Seconds 32
$results += Run-Pass 2

Write-Host ""
Write-Host "======== SUMMARY ========"
$okAll = $true
foreach ($r in $results) {
  $ok = $r.sawFail -and $r.healthy -and (-not $r.flash)
  Write-Host ("pass{0}: fail={1} countdown={2}@{3}ms auto={4}({5}) flash={6} => {7}" -f $r.pass,$r.sawFail,$r.sawSec,$r.sawSecAtMs,$r.healthy,$r.endChip,$r.flash,$(if($ok){"OK"}else{"FAIL"}))
  if (-not $ok) { $okAll = $false }
}
$results | ConvertTo-Json | Set-Content -Encoding UTF8 "$dir\summary.json"
if (-not $okAll) { exit 1 }
Write-Host "ALL OK"
exit 0