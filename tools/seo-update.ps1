param(
  [string]$SiteName,
  [int]$MaxTitle = 60,
  [int]$MaxDescription = 120,
  [string]$BaseUrl,
  [string]$DefaultOgImage,
  [switch]$WriteSitemap,
  [switch]$WriteRobots,
  [switch]$Recurse
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-InnerText {
  param([string]$Html)
  if (-not $Html) { return '' }
  # Remove tags and decode basic entities
  $t = [regex]::Replace($Html, '<script[\s\S]*?</script>|<style[\s\S]*?</style>', '', 'IgnoreCase')
  $t = [regex]::Replace($t, '<[^>]+>', ' ')
  $t = $t -replace '&nbsp;', ' '
  $t = $t -replace '&amp;', '&'
  $t = $t -replace '&lt;', '<'
  $t = $t -replace '&gt;', '>'
  $t = $t -replace '&quot;', '"'
  $t = $t -replace '&#39;', "'"
  $t = $t -replace '\s+', ' '
  return $t.Trim()
}

function Trunc {
  param([string]$Text, [int]$Max)
  if (-not $Text) { return $Text }
  if ($Text.Length -le $Max) { return $Text }
  return $Text.Substring(0, $Max)
}

function HtmlAttrEscape {
  param([string]$Text)
  if ($null -eq $Text) { return '' }
  ($Text -replace '&', '&amp;') -replace '"', '&quot;'
}

# Collect files
$pattern = '*.html'
$files = if ($Recurse) { Get-ChildItem -Path . -Filter $pattern -Recurse -File } else { Get-ChildItem -Path . -Filter $pattern -File }
if (-not $files) {
  Write-Host 'No HTML files found.'
  exit 0
}

# Derive SiteName from index.html title if not provided
if (-not $SiteName) {
  $index = $files | Where-Object { $_.Name -ieq 'index.html' } | Select-Object -First 1
  if ($index) {
    $html = Get-Content -LiteralPath $index.FullName -Raw -Encoding UTF8
    $m = [regex]::Match($html, '<title>([\s\S]*?)</title>', 'IgnoreCase')
    if ($m.Success) { $SiteName = (Get-InnerText $m.Groups[1].Value) }
  }
  if (-not $SiteName) { $SiteName = 'サイト名' }
}

Write-Host "Using SiteName: $SiteName"

$bar = "｜"  # Full-width vertical bar

foreach ($f in $files) {
  $path = $f.FullName
  $html = Get-Content -LiteralPath $path -Raw -Encoding UTF8

  # Work within <head>
  $headMatch = [regex]::Match($html, '(<head[^>]*>)([\s\S]*?)(</head>)', 'IgnoreCase')
  if (-not $headMatch.Success) { Write-Warning "No <head> in $($f.Name)"; continue }
  $headOpen,$headInner,$headClose = $headMatch.Groups[1].Value,$headMatch.Groups[2].Value,$headMatch.Groups[3].Value

  # Extract existing title and H1
  $titleMatch = [regex]::Match($headInner, '<title>([\s\S]*?)</title>', 'IgnoreCase')
  $existingTitle = if ($titleMatch.Success) { (Get-InnerText $titleMatch.Groups[1].Value).Trim() } else { '' }

  $bodyMatch = [regex]::Match($html, '(<body[^>]*>)([\s\S]*?)(</body>)', 'IgnoreCase')
  $bodyInner = if ($bodyMatch.Success) { $bodyMatch.Groups[2].Value } else { '' }
  $h1Match = [regex]::Match($bodyInner, '<h1[^>]*>([\s\S]*?)</h1>', 'IgnoreCase')
  $h1Text = if ($h1Match.Success) { (Get-InnerText $h1Match.Groups[1].Value) } else { '' }

  # Decide base title
  $isIndex = ($f.Name -ieq 'index.html')
  $baseTitle = if ($existingTitle) { $existingTitle } elseif ($h1Text) { $h1Text } else { [System.IO.Path]::GetFileNameWithoutExtension($f.Name) }
  $baseTitle = $baseTitle.Trim()

  # Build final title with template
  $finalTitle = $baseTitle
  $hasSite = $finalTitle.Contains($SiteName)
  $hasBarSite = $finalTitle -match [regex]::Escape($bar) + '\s*' + [regex]::Escape($SiteName)
  if (-not $isIndex) {
    if (-not $hasBarSite) {
      if ($hasSite) {
        # Already contains site name but not templated; leave as is
        $finalTitle = $finalTitle
      } else {
        $finalTitle = "$baseTitle $bar $SiteName"
      }
    }
  } else {
    # index should be just site name
    $finalTitle = if ($hasBarSite) { ($finalTitle -split [regex]::Escape($bar))[0].Trim() } else { $SiteName }
  }
  $finalTitle = Trunc $finalTitle $MaxTitle

  # Description
  $descMatch = [regex]::Match($headInner, '<meta\s+name=["'']description["'']\s+content=["'']([\s\S]*?)["'']\s*/?>', 'IgnoreCase')
  $existingDesc = if ($descMatch.Success) { ($descMatch.Groups[1].Value -replace '\s+', ' ').Trim() } else { '' }
  if (-not $existingDesc) {
    # Use first meaningful paragraph or body text
    $pMatch = [regex]::Match($bodyInner, '<p[^>]*>([\s\S]*?)</p>', 'IgnoreCase')
    $candidate = if ($pMatch.Success) { (Get-InnerText $pMatch.Groups[1].Value) } else { (Get-InnerText $bodyInner) }
    $existingDesc = $candidate
  }
  $finalDesc = Trunc $existingDesc.Trim() $MaxDescription
  $finalDescEsc = HtmlAttrEscape $finalDesc

  # OGP/Twitter values
  $ogType = if ($isIndex) { 'website' } else { 'article' }
  $ogTitle = if ($isIndex) { $SiteName } else { $baseTitle }
  $ogTitle = Trunc $ogTitle $MaxTitle
  
  # page URL
  $pageRel = if ($Recurse) {
    [System.IO.Path]::GetRelativePath((Resolve-Path ".").Path, $path).Replace('\','/')
  } else { $f.Name }
  $ogUrl = ''
  if ($BaseUrl) {
    $ogUrl = ($BaseUrl.TrimEnd('/')) + '/' + $pageRel
  }

  # og:image: first <img> in body or default
  $imgMatch = [regex]::Match($bodyInner, '<img[^>]*src=["'']([^"'']+)["'']', 'IgnoreCase')
  $imgSrc = if ($imgMatch.Success) { $imgMatch.Groups[1].Value } else { $DefaultOgImage }
  if ($imgSrc) {
    if ($imgSrc -notmatch '^https?://') {
      if ($BaseUrl) {
        if ($imgSrc.StartsWith('/')) { $imgSrc = $BaseUrl.TrimEnd('/') + $imgSrc }
        else { $imgSrc = $BaseUrl.TrimEnd('/') + '/' + $imgSrc }
      }
    }
  }

  # Rebuild head minimally and safely
  $metaCharset = ([regex]::Match($headInner, '<meta[^>]*charset[^>]*>', 'IgnoreCase')).Value
  if (-not $metaCharset) { $metaCharset = '<meta charset="UTF-8" />' }
  $metaViewport = ([regex]::Match($headInner, '<meta[^>]*name=["'']viewport["''][^>]*>', 'IgnoreCase')).Value
  if (-not $metaViewport) { $metaViewport = '<meta name="viewport" content="width=device-width, initial-scale=1" />' }
  $linkTags = [regex]::Matches($headInner, '<link[^>]*>', 'IgnoreCase') | ForEach-Object { $_.Value } | Select-Object -Unique

  $rebuilt = @()
  $rebuilt += "  $metaCharset"
  $rebuilt += "  $metaViewport"
  $rebuilt += "  <title>$finalTitle</title>"
  $rebuilt += "  <meta name=`"description`" content=`"$finalDescEsc`" />"
  # Open Graph
  $rebuilt += "  <meta property=`"og:type`" content=`"$ogType`" />"
  $rebuilt += "  <meta property=`"og:site_name`" content=`"$(HtmlAttrEscape $SiteName)`" />"
  $rebuilt += "  <meta property=`"og:title`" content=`"$(HtmlAttrEscape $ogTitle)`" />"
  $rebuilt += "  <meta property=`"og:description`" content=`"$finalDescEsc`" />"
  if ($ogUrl) { $rebuilt += "  <meta property=`"og:url`" content=`"$(HtmlAttrEscape $ogUrl)`" />" }
  if ($imgSrc) { $rebuilt += "  <meta property=`"og:image`" content=`"$(HtmlAttrEscape $imgSrc)`" />" }
  # Twitter
  $rebuilt += "  <meta name=`"twitter:card`" content=`"summary_large_image`" />"
  $rebuilt += "  <meta name=`"twitter:title`" content=`"$(HtmlAttrEscape $ogTitle)`" />"
  $rebuilt += "  <meta name=`"twitter:description`" content=`"$finalDescEsc`" />"
  if ($imgSrc) { $rebuilt += "  <meta name=`"twitter:image`" content=`"$(HtmlAttrEscape $imgSrc)`" />" }
  foreach ($l in $linkTags) { $rebuilt += "  $l" }
  $headInner = "`n" + ($rebuilt -join "`n") + "`n"

  # Reassemble HTML
  $newHead = "$headOpen$headInner$headClose"
  $newHtml = $html.Substring(0, $headMatch.Index) + $newHead + $html.Substring($headMatch.Index + $headMatch.Length)

  # Write back
  [System.IO.File]::WriteAllText($path, $newHtml, (New-Object System.Text.UTF8Encoding $false))
  Write-Host ("Updated {0}" -f $f.Name)
}

Write-Host 'Done.'

# Optionally generate robots.txt and sitemap.xml
if ($WriteRobots) {
  $robots = @()
  $robots += 'User-agent: *'
  $robots += 'Allow: /'
  if ($BaseUrl) { $robots += ('Sitemap: ' + ($BaseUrl.TrimEnd('/') + '/sitemap.xml')) }
  [System.IO.File]::WriteAllLines('robots.txt', $robots, (New-Object System.Text.UTF8Encoding $false))
  Write-Host 'Wrote robots.txt'
}

if ($WriteSitemap) {
  if (-not $BaseUrl) { Write-Warning 'BaseUrl not set; skip sitemap.xml (needs absolute URLs)'; }
  else {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    foreach ($f in $files) {
      $rel = if ($Recurse) { [System.IO.Path]::GetRelativePath((Resolve-Path ".").Path, $f.FullName).Replace('\\','/') } else { $f.Name }
      $loc = ($BaseUrl.TrimEnd('/')) + '/' + $rel
      $lm = (Get-Item $f.FullName).LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ssK')
      [void]$sb.AppendLine('  <url>')
      [void]$sb.AppendLine('    <loc>' + $loc + '</loc>')
      [void]$sb.AppendLine('    <lastmod>' + $lm + '</lastmod>')
      [void]$sb.AppendLine('  </url>')
    }
    [void]$sb.AppendLine('</urlset>')
    [System.IO.File]::WriteAllText('sitemap.xml', $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
    Write-Host 'Wrote sitemap.xml'
  }
}
