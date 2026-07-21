# Flutter / Android 构建环境：所有下载缓存指向 D 盘
$ErrorActionPreference = 'Stop'

$DevCacheRoot = 'D:\dev-cache'
$dirs = @(
    "$DevCacheRoot\gradle",
    "$DevCacheRoot\pub",
    "$DevCacheRoot\android",
    "$DevCacheRoot\temp"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

$env:GRADLE_USER_HOME = "$DevCacheRoot\gradle"
$env:PUB_CACHE = "$DevCacheRoot\pub"
$env:ANDROID_SDK_HOME = "$DevCacheRoot\android"
$env:TEMP = "$DevCacheRoot\temp"
$env:TMP = "$DevCacheRoot\temp"

Write-Host "GRADLE_USER_HOME=$($env:GRADLE_USER_HOME)"
Write-Host "PUB_CACHE=$($env:PUB_CACHE)"
Write-Host "ANDROID_SDK_HOME=$($env:ANDROID_SDK_HOME)"
Write-Host "TEMP/TMP=$($env:TEMP)"
