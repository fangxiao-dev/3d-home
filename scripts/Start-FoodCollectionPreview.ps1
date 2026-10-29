$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$url = 'http://127.0.0.1:8769/'
$listener = Get-NetTCPConnection -LocalPort 8769 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    try { $health = (Invoke-WebRequest -UseBasicParsing ($url + 'health') -TimeoutSec 2).Content } catch { throw '端口 8769 已被其他服务占用。' }
    if ($health -ne 'food-collection-preview-v1') { throw '端口 8769 已被其他服务占用。' }
} else {
    $python = (Get-Command python -ErrorAction Stop).Source
    $script = Join-Path $PSScriptRoot 'food_collection_preview.py'
    Start-Process -FilePath $python -ArgumentList @('"' + $script + '"') -WorkingDirectory $root -WindowStyle Hidden | Out-Null
    $ok = $false
    for ($i=0; $i -lt 30; $i++) { try { if ((Invoke-WebRequest -UseBasicParsing ($url + 'health') -TimeoutSec 1).Content -eq 'food-collection-preview-v1') { $ok=$true; break } } catch {}; Start-Sleep -Milliseconds 200 }
    if (-not $ok) { throw '图鉴预览服务未能启动，请检查端口 8769。' }
}
Write-Output "图鉴预览：$url"
