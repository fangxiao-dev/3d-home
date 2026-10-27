param([switch]$Check)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repo 'references/love-letters'
$manifestPath = Join-Path $sourceRoot 'manifest.json'
$outputRoot = Join-Path $repo 'godot/content/letters'
$imageRoot = Join-Path $outputRoot 'images'
$reportRoot = Join-Path $repo 'work/stage1'
$catalogPath = Join-Path $outputRoot 'catalog.json'
$integrityPath = Join-Path $reportRoot 'letters-integrity.json'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$ids = @{
  '01-和叶莹子的二三事（长期更新）.md' = 'relationship-notes'
  '02-时间-260910X.md' = 'time-260910x'
  '03-汉堡王 - 260729.md' = 'burger-king-260729'
  '04-做自己 - 260728X.md' = 'be-yourself-260728x'
  '05-好像并没有那么担心 - 260707X.md' = 'less-worried-260707x'
  '06-日常留言：未来的路 - 260702.md' = 'future-road-260702'
  '07-日常留言（想你了） - 260630X.md' = 'miss-you-260630x'
  '08-来自莹仔的生日祝福 - 260624Y.md' = 'birthday-wishes-260624y'
  '09-于XY的第一个520-2026520Y.md' = 'first-520-2026520y'
  '10-措手不及，但好在有的是时间-260513X.md' = 'time-enough-260513x'
  '11-理想主义与王冠-260423X.md' = 'idealism-crown'
  '12-怀旧之旅 2017-2021(多蒙篇).md' = 'nostalgia-2017-2021'
  '13-于情人节 - 260214X.md' = 'valentines-day-260214x'
  '14-写给我的狗狗01 - 260209Y.md' = 'letter-to-dog-260209y'
  '15-Day One - 260101X.md' = 'day-one-260101x'
}

function Get-Sha256([byte[]]$bytes) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { ([Convert]::ToHexString($sha.ComputeHash($bytes))).ToLowerInvariant() }
  finally { $sha.Dispose() }
}

function Normalize-Inline([string]$text) {
  $text = [System.Net.WebUtility]::HtmlDecode($text)
  $text = [regex]::Replace($text, '\*\*(.+?)\*\*|__(.+?)__', '$1$2')
  $text = [regex]::Replace($text, '(?<!\*)\*([^*\r\n]+)\*(?!\*)|(?<!_)_([^_\r\n]+)_(?!_)', '$1$2')
  $text = [regex]::Replace($text, '\[([^\]]+)\]\(([^)]+)\)', '$1 ($2)')
  $text = [regex]::Replace($text, '\\([^\p{L}\p{N}\s])', '$1')
  return $text
}

function Get-ArticleBlocks([string]$markdown, [hashtable]$assetPaths) {
  $markdown = $markdown.TrimStart([char]0xFEFF).Replace("`r`n", "`n").Replace("`r", "`n")
  $lines = [System.Collections.Generic.List[string]]::new()
  $pendingEmoji = ''
  foreach ($line in ($markdown -split "`n")) {
    if ($line -match '^<callout\s+emoji="([^"]+)"\s*>$') { $pendingEmoji = $Matches[1]; continue }
    if ($line -match '^</callout\s*>$') { continue }
    if ($line -match '^\s*#\s+(.+?)\s*$' -and $lines.Count -eq 0) { continue }
    if ($line -match '^\s*#{1,6}\s+(.+?)\s*$') { $line = $Matches[1] }
    $line = [regex]::Replace($line, '<br\s*/?>', "`n", 'IgnoreCase')
    $line = [regex]::Replace($line, '^\s*>\s?', '> ')
    $line = [regex]::Replace($line, '^(\s*)([-*+])\s+', '$1• ')
    $line = [regex]::Replace($line, '^(\s*)(\d+)\.\s+', '$1$2. ')
    if ($pendingEmoji -ne '' -and $line.Trim() -ne '') { $line = "$pendingEmoji $line"; $pendingEmoji = '' }
    $lines.Add($line)
  }

  $blocks = [System.Collections.Generic.List[object]]::new()
  $paragraph = [System.Collections.Generic.List[string]]::new()
  $flush = { if ($paragraph.Count -gt 0) { $value = ($paragraph -join "`n").Trim(); if ($value) { $blocks.Add([ordered]@{ type = 'text'; text = $value }) }; $paragraph.Clear() } }
  foreach ($line in $lines) {
    $imageMatches = [regex]::Matches($line, '!\[([^\]]*)\]\(([^)]+)\)')
    if ($imageMatches.Count -eq 0) {
      $line = Normalize-Inline $line
      if ([string]::IsNullOrWhiteSpace($line)) { & $flush } else { $paragraph.Add($line) }
      continue
    }
    $cursor = 0
    foreach ($match in $imageMatches) {
      $before = Normalize-Inline $line.Substring($cursor, $match.Index - $cursor).Trim()
      if ($before) { $paragraph.Add($before) }
      & $flush
      $sourcePath = [Uri]::UnescapeDataString($match.Groups[2].Value)
      $assetName = [IO.Path]::GetFileName($sourcePath)
      if (-not $assetPaths.ContainsKey($assetName)) { throw "Image is not listed in manifest: $sourcePath" }
      $blocks.Add([ordered]@{ type = 'image'; path = $assetPaths[$assetName]; alt = $match.Groups[1].Value })
      $cursor = $match.Index + $match.Length
    }
    $after = Normalize-Inline $line.Substring($cursor).Trim()
    if ($after) { $paragraph.Add($after) }
    & $flush
  }
  & $flush
  return ,$blocks.ToArray()
}

$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
$nodeByRelative = @{}
foreach ($node in $manifest.nodes) { $nodeByRelative[$node.relative.Replace('\', '/')] = $node }
$assetPaths = @{}
foreach ($asset in $manifest.assets) {
  $assetPaths[[IO.Path]::GetFileName($asset.relative)] = "res://content/letters/images/$([IO.Path]::GetFileName($asset.relative))"
}

$sourceFiles = Get-ChildItem (Join-Path $sourceRoot '子文档') -File -Filter '*.md' | Sort-Object Name
$articles = [System.Collections.Generic.List[object]]::new()
$articleRecords = [System.Collections.Generic.List[object]]::new()
foreach ($file in $sourceFiles) {
  if (-not $ids.ContainsKey($file.Name)) { continue }
  $relative = "子文档/$($file.Name)"
  $node = $nodeByRelative[$relative]
  if (-not $node) { throw "Source is missing from manifest: $relative" }
  $bytes = [IO.File]::ReadAllBytes($file.FullName)
  $rawHash = Get-Sha256 $bytes
  if ($rawHash -ne $node.sha256) { throw "Source hash differs from manifest: $relative" }
  $markdown = $utf8.GetString($bytes)
  $titleMatch = [regex]::Match($markdown, '(?m)^#\s+(.+?)\s*$')
  if (-not $titleMatch.Success) { throw "Article has no title heading: $relative" }
  $title = Normalize-Inline $titleMatch.Groups[1].Value.Trim()
  $blocks = Get-ArticleBlocks $markdown $assetPaths
  $articles.Add([ordered]@{ id = $ids[$file.Name]; title = $title; blocks = @($blocks) })
  $displayText = ($blocks | Where-Object type -eq 'text' | ForEach-Object text) -join "`n"
  $articleRecords.Add([ordered]@{ id = $ids[$file.Name]; source = $relative; source_sha256 = $rawHash; normalized_display_sha256 = Get-Sha256 $utf8.GetBytes($displayText); text_blocks = @($blocks | Where-Object type -eq 'text').Count; image_blocks = @($blocks | Where-Object type -eq 'image').Count })
}
if ($articles.Count -ne 15) { throw "Expected 15 published articles, found $($articles.Count)" }
if (@($articles | Where-Object { $_.id -eq 'idealism-crown' }).Count -ne 1) { throw 'The crown article id must occur exactly once.' }
if ($manifest.assets.Count -ne 7) { throw "Expected 7 source images, found $($manifest.assets.Count)" }

$catalog = [ordered]@{ version = 1; crown_article_id = 'idealism-crown'; articles = @($articles.ToArray()) }
$catalogJson = ConvertTo-Json -InputObject $catalog -Depth 12
$reportAssets = [System.Collections.Generic.List[object]]::new()
foreach ($asset in $manifest.assets) {
  $sourceAsset = Join-Path $sourceRoot $asset.relative
  $outputName = [IO.Path]::GetFileName($asset.relative)
  $imageBytes = [IO.File]::ReadAllBytes($sourceAsset)
  $reportAssets.Add([ordered]@{ source = $asset.relative; output = "godot/content/letters/images/$outputName"; sha256 = Get-Sha256 $imageBytes })
}
$report = [ordered]@{ snapshot = $manifest.exported_at; catalog_sha256 = Get-Sha256 $utf8.GetBytes($catalogJson); articles = @($articleRecords.ToArray()); assets = @($reportAssets.ToArray()) }
$reportJson = ConvertTo-Json -InputObject $report -Depth 10

if ($Check) {
  if (-not (Test-Path $catalogPath) -or [IO.File]::ReadAllText($catalogPath, $utf8) -ne $catalogJson) { throw 'Catalog differs from the normalized source articles.' }
  if (-not (Test-Path $integrityPath) -or [IO.File]::ReadAllText($integrityPath, $utf8) -ne $reportJson) { throw 'Integrity report differs from the current source snapshot.' }
  foreach ($asset in $report.assets) {
    $target = Join-Path $repo $asset.output
    if (-not (Test-Path $target) -or (Get-Sha256 ([IO.File]::ReadAllBytes($target))) -ne $asset.sha256) { throw "Prepared image differs from source: $($asset.source)" }
  }
  Write-Output 'Letter content check passed: 15 articles, 7 source-matched images, normalized display text.'
  exit 0
}

New-Item -ItemType Directory -Force $imageRoot, $reportRoot | Out-Null
[IO.File]::WriteAllText($catalogPath, $catalogJson, $utf8)
[IO.File]::WriteAllText($integrityPath, $reportJson, $utf8)
foreach ($asset in $report.assets) {
  [IO.File]::Copy((Join-Path $sourceRoot $asset.source), (Join-Path $repo $asset.output), $true)
}
Write-Output "Prepared $($articles.Count) articles and $($report.assets.Count) images."
