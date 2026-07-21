# 主机 parity 总验收（约 1～3min，无需真机）
# Continue：dart/flutter 会把 build hooks 写到 stderr，Stop 会误中断。
$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent

Set-Location $root



Write-Host "[host] feature registry coverage..."

flutter test test/feature_coverage_test.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] layout + parity scan..."

flutter test test/parity_layout_scan_test.dart test/m3_chat_panel_layout_test.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] full test suite..."

flutter test 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] parity layout static scan..."

dart run tool/parity_layout_scan.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] readonly API probe (m4)..."

flutter test test/m4_api_readonly_test.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] send API probe..."

dart run tool/probe_group_send.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] generate acceptance reports..."

dart run tool/generate_acceptance_report.dart 2>&1 | Out-Host

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }



Write-Host "[host] all passed — see docs/human-only-acceptance.md for manual items" -ForegroundColor Green

