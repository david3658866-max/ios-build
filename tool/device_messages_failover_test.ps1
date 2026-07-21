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
Start-Sleep -Seconds 1
Close-Panel
Go-Messages
Shot "messages_home"
$results = @()
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
$results | ConvertTo-Json | Set-Content -Encoding UTF8 "$dir\messages_summary.json"
if (-not $okAll) { exit 1 }
Write-Host "ALL OK"
exit 0
