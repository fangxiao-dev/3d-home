param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$info = Get-Content (Join-Path $root 'work/godot-setup.json') -Raw | ConvertFrom-Json
$exe = Join-Path $root $info.release.console_executable
$game = Join-Path $root 'godot'
& $exe --headless --path $game --script (Join-Path $PSScriptRoot 'Prepare-Bake.gd')
if ($LASTEXITCODE -ne 0) { throw 'Bake scene preparation failed.' }
$log = Join-Path $root 'work/scene-v2-bake.log'
$err = Join-Path $root 'work/scene-v2-bake-error.log'
$process = Start-Process -FilePath $exe -ArgumentList @('--path', $game, '--editor', '--rendering-method', 'forward_plus', '--', '--bake-house') -WindowStyle Hidden -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
$process.WaitForExit()
if ($process.ExitCode -ne 0 -or -not (Select-String -LiteralPath $log -SimpleMatch 'BAKE_NATIVE_ACTION_OK' -Quiet)) { throw "Lightmap bake failed. See $log and $err" }
# WebGL does not expose desktop RGTC/BC4 consistently; retain the single-channel shadow mask losslessly.
$shadowImport = Join-Path $game 'baked/house_shadow.png.import'
if (Test-Path $shadowImport) {
    (Get-Content $shadowImport -Raw).Replace('compress/mode=2', 'compress/mode=0') | Set-Content $shadowImport -Encoding utf8
    & $exe --headless --path $game --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Shadowmask Web import failed.' }
}
$manifest = @{
    model_sha256 = (Get-FileHash (Join-Path $game 'assets/living-room.glb') -Algorithm SHA256).Hash.ToLowerInvariant()
    environment_sha256 = (Get-FileHash (Join-Path $game 'scene_environment.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
    baked_at = (Get-Date).ToString('o')
}
$manifest | ConvertTo-Json | Set-Content (Join-Path $game 'baked/bake-manifest.json') -Encoding utf8
Write-Output '[OK] Native LightmapGI bake completed.'




