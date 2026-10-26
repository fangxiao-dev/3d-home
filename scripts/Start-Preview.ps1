param([int]$Port = 8767)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$webPath = Join-Path $projectRoot 'outputs/web'
if (-not (Test-Path -LiteralPath (Join-Path $webPath 'index.html'))) {
    throw 'Web export missing. Run scripts/Build.ps1 first.'
}
$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listener) { throw "Port $Port is already in use. Choose a different -Port, or use the existing preview." }
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'work') -Force | Out-Null
$pythonExe = (Get-Command python -ErrorAction Stop).Source
$server = Start-Process -FilePath $pythonExe -ArgumentList @('-m','http.server',"$Port",'--bind','127.0.0.1') -WorkingDirectory $webPath -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $projectRoot 'work/preview-server.log') -RedirectStandardError (Join-Path $projectRoot 'work/preview-server-error.log')
@{ pid = $server.Id; port = $Port; root = $webPath } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'work/preview-server.json')
Write-Output "Preview: http://127.0.0.1:$Port/"
Write-Output "Server process: $($server.Id)"
