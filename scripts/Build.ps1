param([switch]$RebuildModel, [switch]$RebuildCharacter, [switch]$RebuildProps, [switch]$RebuildCake, [switch]$RebuildPhone, [switch]$RebuildAll, [switch]$BakeLighting, [switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/godot-setup.json') -Raw | ConvertFrom-Json
$godotExe = Join-Path $projectRoot $godotInfo.release.console_executable
if ($RebuildAll) { $RebuildModel = $true; $RebuildCharacter = $true; $RebuildProps = $true; $RebuildCake = $true; $RebuildPhone = $true; $BakeLighting = $true }
if ($RebuildModel) {
    $BakeLighting = $true
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python-exit-code 1 --python (Join-Path $projectRoot 'blender/build_living_room.py')
    if ($LASTEXITCODE -ne 0) { throw 'Blender model build failed.' }
}
if ($RebuildCharacter) {
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python-exit-code 1 --python (Join-Path $projectRoot 'blender/build_character.py')
    if ($LASTEXITCODE -ne 0) { throw 'Blender character build failed.' }
}
$gamePath = Join-Path $projectRoot 'godot'
if ($RebuildProps) {
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python-exit-code 1 --python (Join-Path $projectRoot 'blender/build_stage1.py')
    if ($LASTEXITCODE -ne 0) { throw 'Stage 1 prop build failed.' }
}
if ($RebuildCake) {
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python-exit-code 1 --python (Join-Path $projectRoot 'blender/build_stage2.py')
    if ($LASTEXITCODE -ne 0) { throw 'Stage 2 cake build failed.' }
}
if ($RebuildPhone) {
    $blenderInfo = Get-Content -LiteralPath (Join-Path $projectRoot 'work/blender-setup.json') -Raw | ConvertFrom-Json
    & $blenderInfo.executable --background --python-exit-code 1 --python (Join-Path $projectRoot 'blender/build_phone.py')
    if ($LASTEXITCODE -ne 0) { throw 'Phone build failed.' }
}
$webPath = Join-Path $projectRoot 'outputs/web'
New-Item -ItemType Directory -Path $webPath -Force | Out-Null
& $godotExe --headless --path $gamePath --editor --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
if ($BakeLighting) { & (Join-Path $PSScriptRoot 'Bake.ps1') }
$manifestPath = Join-Path $gamePath 'baked/bake-manifest.json'
if (-not (Test-Path $manifestPath)) { throw 'Scene v2 requires actual baked lighting. Run with -BakeLighting.' }
$bake = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($bake.model_sha256 -ne (Get-FileHash (Join-Path $gamePath 'assets/living-room.glb') -Algorithm SHA256).Hash.ToLowerInvariant()) { throw 'Environment changed since lighting bake. Run with -BakeLighting.' }
if ($bake.environment_sha256 -ne (Get-FileHash (Join-Path $gamePath 'scene_environment.gd') -Algorithm SHA256).Hash.ToLowerInvariant()) { throw 'Lighting settings changed since bake. Run with -BakeLighting.' }
if (-not $SkipChecks) {
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Scene.gd')
if ($LASTEXITCODE -ne 0) { throw 'Imported scene verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Playroom.gd')
if ($LASTEXITCODE -ne 0) { throw 'Playroom verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-House.gd')
if ($LASTEXITCODE -ne 0) { throw 'Connected house verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Camera.gd')
if ($LASTEXITCODE -ne 0) { throw 'Navigation camera verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Letters.gd')
if ($LASTEXITCODE -ne 0) { throw 'Letter collection verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Study-Access.gd')
if ($LASTEXITCODE -ne 0) { throw 'Study interaction access verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-Birthday.gd')
if ($LASTEXITCODE -ne 0) { throw 'Birthday preparation and ceremony verification failed.' }
& $godotExe --headless --fixed-fps 60 --path $gamePath --script (Join-Path $projectRoot 'tests/Verify-2048.gd')
if ($LASTEXITCODE -ne 0) { throw 'Phone 2048 verification failed.' }
}
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


$receipt = @{
    pack = $packName
    sha256 = $packHash
    model = (Get-FileHash (Join-Path $gamePath 'assets/living-room.glb') -Algorithm SHA256).Hash.ToLowerInvariant()
    character = (Get-FileHash (Join-Path $gamePath 'assets/character.glb') -Algorithm SHA256).Hash.ToLowerInvariant()
    runtime = (Get-FileHash (Join-Path $gamePath 'playroom.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
    seats = (Get-FileHash (Join-Path $gamePath 'assets/scene-v2-data.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    exported_at = (Get-Date).ToString('o')
    checks_run = -not $SkipChecks
}
$receipt | ConvertTo-Json | Set-Content (Join-Path $projectRoot 'work/scene-v2-build-receipt.json') -Encoding utf8


