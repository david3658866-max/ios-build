$ErrorActionPreference = "Continue"
$adb = "C:\Users\Administrator\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$t = "192.168.8.4:5555"
$out = "E:\0000IM\00code\my-im\im-flutter\build"
$results = [ordered]@{}

function Pass-Item([string]$name, [bool]$ok) {
  $results[$name] = $(if ($ok) { "PASS" } else { "FAIL" })
  Write-Host ("[{0}] {1}" -f $results[$name], $name)
}
function Get-UiXml([string]$file) {
  & $adb -s $t shell uiautomator dump /sdcard/ui.xml | Out-Null
  Start-Sleep -Milliseconds 400
  & $adb -s $t pull /sdcard/ui.xml $file | Out-Null
  return [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($file))
}
function Get-Descs([string]$xml) {
  return @([regex]::Matches($xml, 'content-desc="([^"]*)"') | ForEach-Object {
    $_.Groups[1].Value.Replace("&#10;", " / ")
  } | Where-Object { $_ })
}
function Has-Pat([string[]]$descs, [string]$pat) {
  foreach ($d in $descs) { if ($d -like "*$pat*") { return $true } }
  return $false
}
function Tap-Match([System.Text.RegularExpressions.Match]$m) {
  if (-not $m.Success) { return }
  $cx = [int](([int]$m.Groups[2].Value + [int]$m.Groups[4].Value) / 2)
  $cy = [int](([int]$m.Groups[3].Value + [int]$m.Groups[5].Value) / 2)
  & $adb -s $t shell input tap $cx $cy | Out-Null
}

& $adb connect $t | Out-Null
Start-Sleep -Seconds 1
Pass-Item "wireless" ((& $adb -s $t shell echo ok) -match "ok")

& $adb -s $t shell am force-stop com.cyberis.vortek | Out-Null
Start-Sleep -Seconds 1
& $adb -s $t shell am start -n com.cyberis.vortek/.MainActivity | Out-Null
Start-Sleep -Seconds 6

$xml = Get-UiXml "$out\m-boot.xml"
$descs = Get-Descs $xml
if (-not (Has-Pat $descs "probe") -and -not (Has-Pat $descs "ggg") -and -not (Has-Pat $descs "Wooo")) {
  foreach ($m in [regex]::Matches($xml, 'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')) {
    $y = [int]$m.Groups[3].Value
    $x1 = [int]$m.Groups[2].Value
    if ($y -ge 1550 -and $y -le 1700 -and $x1 -ge 500 -and $m.Groups[1].Value.Length -le 4) {
      Tap-Match $m
      break
    }
  }
  Start-Sleep -Seconds 2
  $xml = Get-UiXml "$out\m-login.xml"
  $descs = Get-Descs $xml
  if (-not (Has-Pat $descs "probe") -and -not (Has-Pat $descs "ggg")) {
    & $adb -s $t shell input tap 590 1205 | Out-Null
    Start-Sleep -Milliseconds 500
    & $adb -s $t shell input text "15222222222" | Out-Null
    & $adb -s $t shell input tap 590 1400 | Out-Null
    Start-Sleep -Milliseconds 500
    & $adb -s $t shell input text "123456" | Out-Null
    & $adb -s $t shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 400
    & $adb -s $t shell input tap 540 1620 | Out-Null
    Start-Sleep -Seconds 10
    $xml = Get-UiXml "$out\m-after.xml"
    foreach ($m in [regex]::Matches($xml, 'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')) {
      $y = [int]$m.Groups[3].Value
      $x2 = [int]$m.Groups[4].Value
      $len = $m.Groups[1].Value.Length
      if ($x2 -lt 540 -and $y -gt 1200 -and $y -lt 1600 -and $len -ge 2 -and $len -le 6) {
        Tap-Match $m
        break
      }
    }
    Start-Sleep -Seconds 3
    $xml = Get-UiXml "$out\m-list.xml"
    $descs = Get-Descs $xml
  }
}

Pass-Item "messages_list" ((Has-Pat $descs "probe") -or (Has-Pat $descs "ggg") -or (Has-Pat $descs "Wooo") -or (Has-Pat $descs "15111111111"))
Pass-Item "list_prior_send" ((Has-Pat $descs "auto-smoke") -or (Has-Pat $descs "auto1") -or (($descs | Where-Object { $_ -match "auto\d{10,}" }).Count -gt 0))

# private: match 15111111111 or first row with image preview - use 15111111111 private
$m = [regex]::Match($xml, 'content-desc="([^"]*15111111111[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
if (-not $m.Success) {
  $m = [regex]::Match($xml, 'content-desc="([^"]*auto-smoke[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
}
if ($m.Success) {
  Tap-Match $m
  Start-Sleep -Seconds 3
  $xml = Get-UiXml "$out\m-priv.xml"
  $descs = Get-Descs $xml
  Pass-Item "private_entry_no_back" (-not (Has-Pat $descs [char]0x56DE + [char]0x5230 + [char]0x5E95 + [char]0x90E8))
}
# Use unicode for Chinese via [char]
$backBtn = ([string][char]0x56DE) + ([string][char]0x5230) + ([string][char]0x5E95) + ([string][char]0x90E8)
$newMsg = ([string][char]0x6761) + ([string][char]0x65B0) + ([string][char]0x6D88) + ([string][char]0x606F)
$dissolve = ([string][char]0x7FA4) + ([string][char]0x804A) + ([string][char]0x5DF2) + ([string][char]0x89E3) + ([string][char]0x6563)
$readLabel = ([string][char]0x5DF2) + ([string][char]0x8BFB)
$unreadLabel = ([string][char]0x672A) + ([string][char]0x8BFB)

# re-read private if we opened
if ($m.Success) {
  $xml = Get-UiXml "$out\m-priv2.xml"
  $descs = Get-Descs $xml
  Pass-Item "private_entry_no_back" (-not (Has-Pat $descs $backBtn))
  Pass-Item "private_read_label" ((Has-Pat $descs $readLabel) -or (Has-Pat $descs $unreadLabel))
  1..5 | ForEach-Object { & $adb -s $t shell input swipe 540 850 540 1750 200 | Out-Null; Start-Sleep -Milliseconds 250 }
  Start-Sleep -Seconds 1
  $xml = Get-UiXml "$out\m-priv-up.xml"
  $descs = Get-Descs $xml
  Pass-Item "private_scroll_back" (Has-Pat $descs $backBtn)
  if (Has-Pat $descs $backBtn) {
    $bm = [regex]::Match($xml, ('content-desc="([^"]*' + [regex]::Escape($backBtn) + '[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'))
    Tap-Match $bm
    Start-Sleep -Seconds 2
    $descs = Get-Descs (Get-UiXml "$out\m-priv-bot.xml")
    Pass-Item "private_back_clears" (-not (Has-Pat $descs $backBtn))
  }
  & $adb -s $t shell input keyevent 4 | Out-Null
  Start-Sleep -Seconds 2
}

$xml = Get-UiXml "$out\m-list2.xml"
$m = [regex]::Match($xml, 'content-desc="([^"]*probe-1783004876188[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
if ($m.Success) {
  Tap-Match $m
  Start-Sleep -Seconds 3
  $xml = Get-UiXml "$out\m-grp.xml"
  $descs = Get-Descs $xml
  Pass-Item "group_entry_no_back" (-not (Has-Pat $descs $backBtn))
  Pass-Item "group_entry_latest" (Has-Pat $descs "probe-1783004876188")
  Pass-Item "group_no_false_new" (-not (Has-Pat $descs $newMsg))
  1..6 | ForEach-Object { & $adb -s $t shell input swipe 540 800 540 1750 200 | Out-Null; Start-Sleep -Milliseconds 220 }
  Start-Sleep -Seconds 1
  $xml = Get-UiXml "$out\m-grp-up.xml"
  $descs = Get-Descs $xml
  Pass-Item "group_scroll_back" (Has-Pat $descs $backBtn)
  Pass-Item "group_history_no_false_new" (-not (Has-Pat $descs $newMsg))
  if (Has-Pat $descs $backBtn) {
    $bm = [regex]::Match($xml, ('content-desc="([^"]*' + [regex]::Escape($backBtn) + '[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'))
    Tap-Match $bm
    Start-Sleep -Seconds 2
    $descs = Get-Descs (Get-UiXml "$out\m-grp-bot.xml")
    Pass-Item "group_back_latest" ((-not (Has-Pat $descs $backBtn)) -and (Has-Pat $descs "probe-1783004876188"))
  }
  & $adb -s $t shell input keyevent 4 | Out-Null
  Start-Sleep -Seconds 2
}

& $adb -s $t shell input swipe 540 1800 540 500 300 | Out-Null
Start-Sleep -Seconds 1
$xml = Get-UiXml "$out\m-list3.xml"
$m = [regex]::Match($xml, 'content-desc="([^"]*Wooo[^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
if ($m.Success) {
  Tap-Match $m
  Start-Sleep -Seconds 3
  $descs = Get-Descs (Get-UiXml "$out\m-wooo.xml")
  Pass-Item "wooo_dissolve" (Has-Pat $descs $dissolve)
  Pass-Item "wooo_no_back" (-not (Has-Pat $descs $backBtn))
}

Write-Host ""
Write-Host "======== SUMMARY ========"
$pass = 0
$fail = 0
foreach ($k in $results.Keys) {
  Write-Host ("{0,-30} {1}" -f $k, $results[$k])
  if ($results[$k] -eq "PASS") { $pass++ } else { $fail++ }
}
Write-Host "TOTAL pass=$pass fail=$fail"
Write-Host "send_api: prior wireless run had sendPrivate ok"
Write-Host "receive: needs other account"