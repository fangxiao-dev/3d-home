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
$packPath = Join-Path $webPath 'index.pck'
$packHash = (Get-FileHash -LiteralPath $packPath -Algorithm SHA256).Hash.ToLowerInvariant()
$packName = "scene-$($packHash.Substring(0, 12)).pck"
$versionedPackPath = Join-Path $webPath $packName
Copy-Item -LiteralPath $packPath -Destination $versionedPackPath -Force
$indexPath = Join-Path $webPath 'index.html'
$indexHtml = Get-Content -LiteralPath $indexPath -Raw
$configMatch = [regex]::Match($indexHtml, 'const GODOT_CONFIG = (\{.*?\});', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $configMatch.Success) { throw 'Godot Web export did not contain GODOT_CONFIG.' }
$config = $configMatch.Groups[1].Value | ConvertFrom-Json
$config | Add-Member -MemberType NoteProperty -Name 'mainPack' -Value $packName -Force
$config.fileSizes | Add-Member -MemberType NoteProperty -Name $packName -Value (Get-Item -LiteralPath $versionedPackPath).Length -Force
$configJson = $config | ConvertTo-Json -Compress -Depth 20
$indexHtml = $indexHtml.Substring(0, $configMatch.Index) + "const GODOT_CONFIG = $configJson;" + $indexHtml.Substring($configMatch.Index + $configMatch.Length)
[System.IO.File]::WriteAllText($indexPath, $indexHtml, [System.Text.UTF8Encoding]::new($false))
Write-Output "[OK] Web preview exported to outputs/web/index.html mainPack=$packName sha256=$packHash"
