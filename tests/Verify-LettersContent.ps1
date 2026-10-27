$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $repo 'godot/content/letters/catalog.json'
$sourceRoot = Join-Path $repo 'references/love-letters'
$catalog = Get-Content -Raw $catalogPath | ConvertFrom-Json
$manifest = Get-Content -Raw (Join-Path $sourceRoot 'manifest.json') | ConvertFrom-Json

if ($catalog.version -ne 1 -or $catalog.crown_article_id -ne 'idealism-crown') { throw 'Catalog version or crown trigger id is incorrect.' }
if ($catalog.articles.Count -ne 15) { throw "Expected 15 articles, found $($catalog.articles.Count)." }
if (@($catalog.articles.id | Sort-Object -Unique).Count -ne 15) { throw 'Article ids are not unique.' }
if (@($catalog.articles | Where-Object { $_.id -eq $catalog.crown_article_id }).Count -ne 1) { throw 'Crown article is missing or duplicated.' }

$blocks = @($catalog.articles | ForEach-Object { $_.blocks })
if (@($blocks | Where-Object type -eq 'image').Count -ne 7) { throw 'Expected exactly 7 embedded image blocks.' }
if (@($blocks | Where-Object type -notin @('text', 'image')).Count -gt 0) { throw 'Catalog contains an unsupported block type.' }
foreach ($article in $catalog.articles) {
  if ([string]::IsNullOrWhiteSpace($article.title) -or $article.blocks.Count -eq 0) { throw "Article is empty: $($article.id)" }
  foreach ($block in $article.blocks) {
    if ($block.type -eq 'text' -and [string]::IsNullOrWhiteSpace($block.text)) { throw "Empty text block in $($article.id)." }
    if ($block.type -eq 'image') {
      if ($block.path -notmatch '^res://content/letters/images/[^/]+$') { throw "Invalid image resource path: $($block.path)" }
      $localPath = Join-Path $repo ($block.path -replace '^res://', 'godot/')
      if (-not (Test-Path $localPath)) { throw "Missing image resource: $localPath" }
    }
  }
}

$sourceAssets = @($manifest.assets | ForEach-Object { [IO.Path]::GetFileName($_.relative) } | Sort-Object -Unique)
$preparedAssets = @(Get-ChildItem (Join-Path $repo 'godot/content/letters/images') -File | Where-Object Extension -in @('.jpg', '.png') | ForEach-Object Name | Sort-Object -Unique)
if ($sourceAssets.Count -ne 7 -or (@(Compare-Object $sourceAssets $preparedAssets)).Count -gt 0) { throw 'Prepared image inventory differs from the source manifest.' }
$sourceQuoteLines = 0
foreach ($sourceFile in (Get-ChildItem (Join-Path $sourceRoot '子文档') -File -Filter '*.md' | Where-Object Name -match '^(0[1-9]|1[0-5])-')) {
  $sourceQuoteLines += @(Get-Content $sourceFile.FullName | Where-Object { $_ -match '^\s*>\s?' }).Count
}
$preparedQuoteLines = 0
foreach ($block in $blocks | Where-Object type -eq 'text') {
  $preparedQuoteLines += @(($block.text -split "`n") | Where-Object { $_ -match '^>\s?' }).Count
}
if ($sourceQuoteLines -ne $preparedQuoteLines) { throw "Quote markers differ from source: expected $sourceQuoteLines, found $preparedQuoteLines." }
$escapedPunctuation = @($blocks | Where-Object type -eq 'text' | ForEach-Object { [regex]::Matches($_.text, '\\[^\p{L}\p{N}\s]').Count } | Measure-Object -Sum).Sum
if ($escapedPunctuation -gt 0) { throw "Found $escapedPunctuation Markdown-escaped punctuation marks in display text." }

& (Join-Path $repo 'scripts/Prepare-Letters.ps1') -Check
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Normalized source comparison failed.' }
Write-Output 'Letter content verification passed: 15 articles, 7 images, unique crown article, normalized source match.'
