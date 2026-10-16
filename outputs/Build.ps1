param([switch]$RebuildModel)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/godot-setup.json') -Raw | ConvertFrom-Json
$godotExe = Join-Path $projectRoot $godotInfo.release.console_executable
if ($RebuildModel) {
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python (Join-Path $PSScriptRoot 'blender/build_living_room.py')
    if ($LASTEXITCODE -ne 0) { throw 'Blender model build failed.' }
}
$gamePath = Join-Path $PSScriptRoot 'godot'
$webPath = Join-Path $PSScriptRoot 'web'
New-Item -ItemType Directory -Path $webPath -Force | Out-Null
& $godotExe --headless --path $gamePath --editor --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $godotExe --headless --path $gamePath --script (Join-Path $PSScriptRoot 'Verify-Scene.gd')
if ($LASTEXITCODE -ne 0) { throw 'Imported scene verification failed.' }
& $godotExe --headless --path $gamePath --script (Join-Path $PSScriptRoot 'Verify-Playroom.gd')
if ($LASTEXITCODE -ne 0) { throw 'Playroom verification failed.' }
& $godotExe --headless --path $gamePath --export-release Web (Join-Path $webPath 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'Godot Web export failed.' }
Write-Output '[OK] Web preview exported to outputs/web/index.html'
