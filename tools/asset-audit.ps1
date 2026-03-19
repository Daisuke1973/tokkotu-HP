param(
  [string]$Root = '.',
  [string]$OutputDir = 'work/reports/asset-audit'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$assetExtensions = @(
  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg',
  '.mp3', '.m4a', '.wav', '.ogg', '.pdf'
)

$contentExtensions = @('.html', '.css', '.js')

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$displayRoot = if ([System.IO.Path]::IsPathRooted($Root)) {
  $Root
} elseif ($Root -eq '.') {
  (Get-Location).Path
} else {
  Join-Path (Get-Location).Path $Root
}
$outputPath = Join-Path $rootPath $OutputDir

New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

function Get-RelativeUnixPath {
  param(
    [string]$BasePath,
    [string]$Path
  )

  [System.IO.Path]::GetRelativePath($BasePath, $Path).Replace('\', '/')
}

function Normalize-AssetReference {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }

  $normalized = $Value.Trim()

  if ($normalized -match '^(mailto:|tel:|javascript:|data:|#)') {
    return $null
  }

  $normalized = $normalized -replace '\\', '/'

  if ($normalized -match '^https?://[^/]+/(.+)$') {
    $normalized = $Matches[1]
  }

  $normalized = $normalized -replace '^[.]/', ''
  $normalized = $normalized.TrimStart('/')
  $normalized = $normalized -replace '[?#].*$', ''

  if ($normalized -notmatch '\.[A-Za-z0-9]+$') {
    return $null
  }

  return $normalized
}

function Get-AssetKind {
  param([string]$RelativePath)

  $extension = [System.IO.Path]::GetExtension($RelativePath).ToLowerInvariant()

  switch ($extension) {
    '.jpg' { return 'image' }
    '.jpeg' { return 'image' }
    '.png' { return 'image' }
    '.gif' { return 'image' }
    '.webp' { return 'image' }
    '.svg' { return 'image' }
    '.mp3' { return 'audio' }
    '.m4a' { return 'audio' }
    '.wav' { return 'audio' }
    '.ogg' { return 'audio' }
    '.pdf' { return 'document' }
    default { return 'other' }
  }
}

function Get-NamePolicy {
  param([string]$FileName)

  if ($FileName -cmatch '^[a-z0-9][a-z0-9._-]*$') {
    return 'ok'
  }

  return 'needs-rename'
}

function Normalize-Slug {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }

  $slug = $Value.ToLowerInvariant()
  $slug = $slug -replace '[ _]+', '-'
  $slug = $slug -replace '[()]', ''
  $slug = $slug -replace '[^a-z0-9\-]+', '-'
  $slug = $slug -replace '-{2,}', '-'
  $slug = $slug.Trim('-')

  if ([string]::IsNullOrWhiteSpace($slug)) {
    return $null
  }

  return $slug
}

function Get-ParentUnixDirectory {
  param([string]$RelativePath)

  $directory = Split-Path -Parent $RelativePath
  if ([string]::IsNullOrWhiteSpace($directory)) {
    return '.'
  }

  return $directory.Replace('\', '/')
}

function Get-SuggestedDirectory {
  param(
    [string]$RelativePath,
    [string]$SourceFile = ''
  )

  $sourceName = if ([string]::IsNullOrWhiteSpace($SourceFile)) {
    ''
  } else {
    [System.IO.Path]::GetFileName($SourceFile).ToLowerInvariant()
  }

  switch -Regex ($RelativePath) {
    '^assets/' {
      return Get-ParentUnixDirectory -RelativePath $RelativePath
    }
    '^photo/mark1\.gif$' {
      return 'assets/images/shared/branding'
    }
    '^photo/img/' {
      return 'assets/images/shared/ui'
    }
    '^photo/[^/]+\.(jpg|jpeg|png|gif|webp)$' {
      return 'assets/images/shared/backgrounds'
    }
    '^music/' {
      return 'assets/audio/songs'
    }
    '^photo/yakuinkai/img/([^/]+)/' {
      return "assets/images/events/yakuinkai/$(Normalize-Slug $Matches[1])"
    }
    '^photo/golf_bukai/img/' {
      return 'assets/images/events/golf/golf-bukai'
    }
    '^photo/kaiho(\d+)/' {
      return "assets/images/archives/kaiho/$('{0:D2}' -f [int]$Matches[1])"
    }
    '^photo/soukai(\d+)_images/' {
      return "assets/images/events/soukai/legacy/soukai$($Matches[1])-images"
    }
    '^photo/([0-9]{2}ki_[0-9]{4})/img/' {
      $slug = Normalize-Slug $Matches[1]

      switch ($sourceName) {
        'soukai.html' {
          return "assets/images/events/soukai/legacy/$slug"
        }
        'golf.html' {
          return "assets/images/events/golf/legacy/$slug"
        }
        'kaihou.html' {
          return "assets/images/archives/legacy/$slug"
        }
        default {
          return "assets/images/archives/legacy/$slug"
        }
      }
    }
    '^20\d{2}/' {
      $year = ($RelativePath -split '/')[0]
      return "assets/images/events/unclassified/$year"
    }
    '^photo/' {
      return 'assets/images/archives/legacy'
    }
    default {
      return 'assets/images/unclassified'
    }
  }
}

function Add-Reference {
  param(
    [hashtable]$Lookup,
    [string]$RelativePath,
    [string]$SourceFile
  )

  if (-not $RelativePath) {
    return
  }

  if (-not $Lookup.ContainsKey($RelativePath)) {
    $Lookup[$RelativePath] = New-Object System.Collections.Generic.List[string]
  }

  $Lookup[$RelativePath].Add($SourceFile)
}

$referenceLookup = @{}

$contentFiles = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object {
  $relative = Get-RelativeUnixPath -BasePath $rootPath -Path $_.FullName
  $extension = $_.Extension.ToLowerInvariant()
  $extension -in $contentExtensions -and
  $relative -notmatch '^(\.git|work/)'
}

foreach ($file in $contentFiles) {
  $relativeContentPath = Get-RelativeUnixPath -BasePath $rootPath -Path $file.FullName
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

  $htmlAndCssMatches = [regex]::Matches(
    $content,
    '(?is)(?:src|href|content|data-audio)\s*=\s*["'']([^"'']+\.(?:jpe?g|png|gif|webp|svg|mp3|m4a|wav|ogg|pdf)(?:\?[^"'']*)?)["'']|url\((["'']?)([^)"'']+\.(?:jpe?g|png|gif|webp|svg|mp3|m4a|wav|ogg|pdf)(?:\?[^)"'']*)?)\2\)'
  )

  foreach ($match in $htmlAndCssMatches) {
    $value = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[3].Value }
    $normalized = Normalize-AssetReference -Value $value
    Add-Reference -Lookup $referenceLookup -RelativePath $normalized -SourceFile $relativeContentPath
  }

  if ($file.Extension.ToLowerInvariant() -eq '.js') {
    $jsMatches = [regex]::Matches(
      $content,
      '(?is)["'']([^"'']+\.(?:jpe?g|png|gif|webp|svg|mp3|m4a|wav|ogg|pdf)(?:\?[^"'']*)?)["'']'
    )

    foreach ($match in $jsMatches) {
      $normalized = Normalize-AssetReference -Value $match.Groups[1].Value
      Add-Reference -Lookup $referenceLookup -RelativePath $normalized -SourceFile $relativeContentPath
    }
  }
}

$assetFiles = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object {
  $relative = Get-RelativeUnixPath -BasePath $rootPath -Path $_.FullName
  $_.Extension.ToLowerInvariant() -in $assetExtensions -and
  $relative -notmatch '^(\.git|work/)'
}

$assetRows = foreach ($file in $assetFiles) {
  $relativePath = Get-RelativeUnixPath -BasePath $rootPath -Path $file.FullName
  $referenceFiles = @()

  if ($referenceLookup.ContainsKey($relativePath)) {
    $referenceFiles = @($referenceLookup[$relativePath] | Sort-Object -Unique)
  }

  [pscustomobject]@{
    RelativePath        = $relativePath
    AssetKind           = Get-AssetKind -RelativePath $relativePath
    SizeMB              = [math]::Round($file.Length / 1MB, 2)
    Referenced          = [bool]($referenceFiles.Count -gt 0)
    ReferenceCount      = $referenceFiles.Count
    ReferencedBy        = ($referenceFiles -join '; ')
    SuggestedDirectory  = Get-SuggestedDirectory -RelativePath $relativePath
    NamePolicy          = Get-NamePolicy -FileName $file.Name
  }
}

$assetLookup = @{}
foreach ($row in $assetRows) {
  $assetLookup[$row.RelativePath] = $true
}

$missingRows = foreach ($referencePath in ($referenceLookup.Keys | Sort-Object)) {
  if ($assetLookup.ContainsKey($referencePath)) {
    continue
  }

  $missingReferenceFiles = @($referenceLookup[$referencePath] | Sort-Object -Unique)

  [pscustomobject]@{
    MissingPath         = $referencePath
    ReferenceCount      = $missingReferenceFiles.Count
    ReferencedBy        = ($missingReferenceFiles -join '; ')
    SuggestedDirectory  = Get-SuggestedDirectory -RelativePath $referencePath -SourceFile $missingReferenceFiles[0]
  }
}

$inventoryCsv = Join-Path $outputPath 'asset-inventory.csv'
$missingCsv = Join-Path $outputPath 'missing-references.csv'
$summaryMd = Join-Path $outputPath 'summary.md'

$assetRows | Sort-Object RelativePath | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $inventoryCsv
$missingRows | Sort-Object MissingPath | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $missingCsv

$totalAssets = @($assetRows).Count
$referencedAssets = @($assetRows | Where-Object Referenced).Count
$unreferencedAssets = @($assetRows | Where-Object { -not $_.Referenced }).Count
$largeAssets = @($assetRows | Where-Object { $_.SizeMB -gt 1 }).Count
$renameNeeded = @($assetRows | Where-Object { $_.NamePolicy -ne 'ok' }).Count
$missingReferences = @($missingRows).Count

$topSuggestedDirectories = @($assetRows) |
  Group-Object SuggestedDirectory |
  Sort-Object Count -Descending |
  Select-Object -First 10

$summaryLines = @()
$summaryLines += '# Asset Audit Summary'
$summaryLines += ''
$summaryLines += "- GeneratedAt: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')"
$summaryLines += "- Root: $displayRoot"
$summaryLines += "- TotalAssets: $totalAssets"
$summaryLines += "- ReferencedAssets: $referencedAssets"
$summaryLines += "- UnreferencedAssets: $unreferencedAssets"
$summaryLines += "- MissingReferences: $missingReferences"
$summaryLines += "- LargeAssetsOver1MB: $largeAssets"
$summaryLines += "- FilesNeedingRename: $renameNeeded"
$summaryLines += ''
$summaryLines += '## Top Asset Directories'
$summaryLines += ''

foreach ($entry in $topSuggestedDirectories) {
  $summaryLines += "- $($entry.Name): $($entry.Count)"
}

$summaryLines += ''
$summaryLines += '## Reports'
$summaryLines += ''
$summaryLines += "- asset-inventory.csv"
$summaryLines += "- missing-references.csv"

[System.IO.File]::WriteAllLines($summaryMd, $summaryLines, (New-Object System.Text.UTF8Encoding $false))

Write-Host "Asset inventory: $inventoryCsv"
Write-Host "Missing refs:    $missingCsv"
Write-Host "Summary:         $summaryMd"
Write-Host ''
Write-Host "Total assets:        $totalAssets"
Write-Host "Referenced assets:   $referencedAssets"
Write-Host "Unreferenced assets: $unreferencedAssets"
Write-Host "Missing refs:        $missingReferences"
Write-Host "Over 1MB:            $largeAssets"
Write-Host "Need rename:         $renameNeeded"
