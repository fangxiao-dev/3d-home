$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$receipt = Get-Content work/scene-v2-build-receipt.json -Raw | ConvertFrom-Json
if ($receipt.pack -ne 'scene-8f68e808fcb8.pck') { throw 'Unexpected campaign build' }
$node = (Get-Command node).Source
$status = @{ pid=$PID; started_at=(Get-Date).ToString('o'); build=$receipt; phase='1920'; logs=@('work/v2-final-1366.log','work/v2-final-1920.log') }
$status | ConvertTo-Json -Depth 10 | Set-Content work/scene-v2-final-campaign.json -Encoding utf8
foreach ($width in @(1920,1366)) {
 $height = if ($width -eq 1366) {768} else {1080}
 $runArgs = @('work/scene-v2-browser-check.cjs',"$width","$height")
 if ($width -eq 1920) {$runArgs += 'soak'}
 $status.phase = "$width"
 $status | ConvertTo-Json -Depth 10 | Set-Content work/scene-v2-final-campaign.json -Encoding utf8
 & $node @runArgs *> "work/v2-final-$width.log"
 if ($LASTEXITCODE -ne 0) { throw "Campaign process failed $width" }
 $result = Get-Content "work/v2-chrome-$width-verification.json" -Raw | ConvertFrom-Json
 if (-not $result.pass) { throw "Campaign assertions failed $width : $($result.failure)" }
 if ($result.build.pack -ne $receipt.pack -or $result.ending_build.pack -ne $receipt.pack) { throw 'Campaign pack changed' }
}
$status.phase = 'complete'
$status.finished_at = (Get-Date).ToString('o')
$status | ConvertTo-Json -Depth 10 | Set-Content work/scene-v2-final-campaign.json -Encoding utf8
