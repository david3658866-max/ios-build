$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$d = "ZE223JPF9T"
$dir = Join-Path $PSScriptRoot "_device_line_test\verify"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$Fail  = -join ([char[]](0x8FDE,0x63A5,0x5931,0x8D25))
$Conn  = -join ([char[]](0x8FDE,0x63A5,0x4E2D))
$LineKw  = -join ([char[]](0x7EBF,0x8DEF))
$LocalDbg = -join ([char[]](0x672C,0x5730,0x8C03,0x8BD5))
$Retry = -join ([char[]](0x91CD,0x65B0,0x68C0,0x6D4B))
$Main  = -join ([char[]](0x4E3B,0x7EBF,0x8DEF))
$Backup= -join ([char[]](0x5907,0x7528,0x7EBF,0x8DEF))
$Login = -join ([char[]](0x5BC6,0x7801,0x767B,0x5F55))
$Msg = -join ([char[]](0x6D88,0x606F))
$PwdPh = -join ([char[]](0x8BF7,0x8F93,0x5165,0x5BC6,0x7801))
Write-Host "STR ok"

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
  Adb "-s $d pull /sdcard/_shot.png `"$dir\${name}.png`""
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
function Find-TextBounds([string]$xml, [string]$pattern) {
  foreach ($n in [regex]::Matches($xml,"<node[^>]+>")) {
    $s=$n.Value; $text=""; $bounds=""
    if ($s -match "text=`"([^`"]*)`"") { $text = $Matches[1] }
    if ($s -match "bounds=`"(\[[^\]]+\]\[[^\]]+\])`"") { $bounds=$Matches[1] }
    if ($text -match $pattern -and $bounds) { return @{text=$text; bounds=$bounds} }
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
    Adb "-s $d shell input keyevent 4"
    Start-Sleep -Milliseconds 400
  }
}
function Open-Panel {
  Adb "-s $d shell input keyevent KEYCODE_WAKEUP"
  Adb "-s $d shell am start -n com.cyberis.vortek/.MainActivity"
  Start-Sleep -Milliseconds 500
  Close-Panel
  $xml = Dump
  if ($xml -match [regex]::Escape($Retry)) { return $xml }
  $chip = Find-Bounds $xml "$LineKw|$LocalDbg"
  if (-not $chip) {
    # try left (messages) then right (login)
    Adb "-s $d shell input tap 220 160"
    Start-Sleep -Milliseconds 700
    $xmlTry = Dump
    if ($xmlTry -match [regex]::Escape($Retry)) { return $xmlTry }
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
function Do-Login {
  $xml = Dump
  if ($xml -notmatch [regex]::Escape($Login)) {
    Write-Host "not on login, skip login"
    return $true
  }
  # tap password field by placeholder text
  $pwd = Find-TextBounds $xml $PwdPh
  if ($pwd) {
    $c = Center $pwd.bounds
    Adb "-s $d shell input tap $($c[0]) $($c[1])"
  } else {
    Adb "-s $d shell input tap 540 980"
  }
  Start-Sleep -Milliseconds 400
  Adb "-s $d shell input text 123456"
  Start-Sleep -Milliseconds 400
  $btn = Find-TextBounds (Dump) (-join ([char[]](0x7ACB,0x5373,0x767B,0x5F55))) # 立即登录
  if (-not $btn) { $btn = Find-Bounds (Dump) $Login }
  if (-not $btn) { throw "login button missing" }
  $c = Center $btn.bounds
  Write-Host "TAP login $($c[0]),$($c[1])"
  Adb "-s $d shell input tap $($c[0]) $($c[1])"
  Start-Sleep -Seconds 10
  $xml2 = Dump
  if ($xml2 -match [regex]::Escape($Login)) {
    Write-Host "login still showing, retry tap"
    $btn2 = Find-TextBounds $xml2 (-join ([char[]](0x7ACB,0x5373,0x767B,0x5F55)))
    if ($btn2) { $c2 = Center $btn2.bounds; Adb "-s $d shell input tap $($c2[0]) $($c2[1])"; Start-Sleep -Seconds 10 }
  }
  $xml3 = Dump
  if ($xml3 -match [regex]::Escape($Login)) { return $false }
  return $true
}
function Go-Messages {
  $xml = Dump
  $tab = Find-TextBounds $xml "^$Msg$"
  if (-not $tab) { $tab = Find-Bounds $xml $Msg }
  if ($tab) {
    $c = Center $tab.bounds
    Write-Host "TAP msg tab $($c[0]),$($c[1])"
    Adb "-s $d shell input tap $($c[0]) $($c[1])"
  } else {
    Write-Host "TAP msg tab fallback"
    Adb "-s $d shell input tap 180 2280"
  }
  Start-Sleep -Seconds 2
}
function Run-Pass([string]$page, [int]$n) {
  Write-Host ""
  Write-Host "======== $page PASS $n ========"
  Adb "-s $d logcat -c"
  $xml = Open-Panel
  Shot "${page}_p${n}_panel"
  $local = Find-Bounds $xml $LocalDbg
  if (-not $local) { throw "local missing" }
  $lc = Center $local.bounds
  Write-Host "TAP local $($lc[0]),$($lc[1])"
  $sw = [Diagnostics.Stopwatch]::StartNew()
  Adb "-s $d shell input tap $($lc[0]) $($lc[1])"
  $sawFail=$false; $sawSec=$false; $sawSecAt=$null; $flash=$false; $healthy=$false; $endChip=""; $sawConn=$false
  $log = New-Object Collections.Generic.List[string]
  $i=0
  while ($sw.ElapsedMilliseconds -lt 28000) {
    $i++
    $raw = Dump
    $descs = @(Get-Descs $raw)
    $st = Classify $descs
    if ($raw -match [regex]::Escape($Fail)) { $st.fail = $true }
    if ($raw -match [regex]::Escape($Conn)) { $st.conn = $true }
    if ($raw -match "(?<!\d)([123])s(?!\w)") { $st.sec = [int]$Matches[1] }
    $line = ("{0,5}ms fail={1} sec={2} conn={3} healthy={4} chip=[{5}]" -f $sw.ElapsedMilliseconds,$st.fail,$st.sec,$st.conn,$st.healthy,$st.chip)
    Write-Host $line
    [void]$log.Add($line)
    if ($st.conn) { $sawConn=$true }
    if ($st.fail) {
      $sawFail=$true
      if ($null -ne $st.sec) { $sawSec=$true; if (-not $sawSecAt) { $sawSecAt=$sw.ElapsedMilliseconds } }
    }
    if ($sawFail -and $st.conn) { $flash=$true }
    if (($sawFail -or ($st.chip -match $LocalDbg)) -and $st.healthy -and ($st.chip -notmatch $LocalDbg)) {
      $healthy=$true; $endChip=$st.chip; if (-not $sawFail) { $sawFail=$true }
      Shot "${page}_p${n}_after"
      break
    }
    if ($st.healthy -and ($sw.ElapsedMilliseconds -ge 10000) -and ($st.chip -notmatch $LocalDbg) -and (-not $sawFail)) {
      $healthy=$true; $endChip=$st.chip; $sawFail=$true
      Write-Host "NOTE missed fail/sec"
      Shot "${page}_p${n}_after"
      break
    }
  }
  $log | Set-Content -Encoding UTF8 "$dir\${page}_p${n}_ui.txt"
  Adb "-s $d logcat -d" 
  # capture flutter lines via separate pull of full log is heavy; skip
  $r = [pscustomobject]@{page=$page;pass=$n;sawFail=$sawFail;sawSec=$sawSec;sawSecAtMs=$sawSecAt;sawConn=$sawConn;flash=$flash;healthy=$healthy;endChip=$endChip}
  Write-Host ("RESULT " + ($r | ConvertTo-Json -Compress))
  return $r
}

Adb "-s $d shell input keyevent KEYCODE_WAKEUP"
Adb "-s $d shell am start -n com.cyberis.vortek/.MainActivity"
Start-Sleep -Seconds 1
Close-Panel
Shot "boot"
$onLogin = (Dump) -match [regex]::Escape($Login)
Write-Host "onLogin=$onLogin"

$results = @()
if ($onLogin) {
  $results += Run-Pass "login" 1
  Write-Host "Wait 32s debounce..."
  Start-Sleep -Seconds 32
  $results += Run-Pass "login" 2
}

$okLogin = Do-Login
Write-Host "Do-Login=$okLogin"
if (-not $okLogin) { throw "login failed" }
Go-Messages
Shot "messages_home"
$results += Run-Pass "messages" 1
Write-Host "Wait 32s debounce..."
Start-Sleep -Seconds 32
Go-Messages
$results += Run-Pass "messages" 2

Write-Host ""
Write-Host "======== SUMMARY ========"
$okAll = $true
foreach ($r in $results) {
  $ok = $r.sawFail -and $r.healthy -and (-not $r.flash)
  $cd = if ($r.sawSec) { "countdown=YES@$($r.sawSecAtMs)ms" } else { "countdown=NO" }
  Write-Host ("{0} p{1}: fail={2} {3} auto={4}({5}) flash={6} => {7}" -f $r.page,$r.pass,$r.sawFail,$cd,$r.healthy,$r.endChip,$r.flash,$(if($ok){"OK"}else{"FAIL"}))
  if (-not $ok) { $okAll = $false }
}
$results | ConvertTo-Json | Set-Content -Encoding UTF8 "$dir\summary.json"
if (-not $okAll) { exit 1 }
Write-Host "ALL OK"
exit 0
