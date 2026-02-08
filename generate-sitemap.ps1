param(
    [string]$SiteRoot = "C:\code",
    [string]$BaseUrl = "https://tokkotu.jp",
    [string]$OutputPath = "C:\code\sitemap.xml"
)

$ErrorActionPreference = "Stop"

# Page priority and change frequency configuration
$pageConfig = @{
    'index.html'       = @{ priority = '1.0'; changefreq = 'weekly' }
    'gaiyo.html'       = @{ priority = '0.9'; changefreq = 'yearly' }
    'soukai.html'      = @{ priority = '0.9'; changefreq = 'monthly' }
    'kaihou.html'      = @{ priority = '0.9'; changefreq = 'monthly' }
    'yakuinkai2.html'  = @{ priority = '0.8'; changefreq = 'monthly' }
    'golf.html'        = @{ priority = '0.8'; changefreq = 'monthly' }
    'ayumi.html'       = @{ priority = '0.8'; changefreq = 'yearly' }
    'kaihou-list.html' = @{ priority = '0.8'; changefreq = 'yearly' }
    'yakuin.html'      = @{ priority = '0.7'; changefreq = 'yearly' }
    'kaisoku.html'     = @{ priority = '0.7'; changefreq = 'yearly' }
    'sotsugyo.html'    = @{ priority = '0.7'; changefreq = 'yearly' }
    'kouka.html'       = @{ priority = '0.7'; changefreq = 'yearly' }
    'links.html'       = @{ priority = '0.6'; changefreq = 'yearly' }
    'backnumber.html'  = @{ priority = '0.6'; changefreq = 'yearly' }
}

function Get-PageLoc {
    param([string]$FileName)

    if ($FileName -eq "index.html") {
        return "$BaseUrl/"
    }

    return "$BaseUrl/$FileName"
}

$htmlFiles = Get-ChildItem -Path $SiteRoot -Filter "*.html" |
    Where-Object { $_.Name -notmatch '^google[0-9a-z]+\.html$' } |
    Sort-Object @{ Expression = { if ($_.Name -eq "index.html") { 0 } else { 1 } } }, Name

if (-not $htmlFiles) {
    throw "No HTML files found in $SiteRoot"
}

$sitemap = @'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
        http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">

'@

foreach ($file in $htmlFiles) {
    $fileName = $file.Name
    $lastMod = $file.LastWriteTime.ToString("yyyy-MM-dd")

    $config = $pageConfig[$fileName]
    if (-not $config) {
        $config = @{ priority = '0.5'; changefreq = 'yearly' }
    }

    $loc = Get-PageLoc -FileName $fileName
    $priority = $config.priority
    $changefreq = $config.changefreq

    $sitemap += @"
  <url>
    <loc>$loc</loc>
    <lastmod>$lastMod</lastmod>
    <changefreq>$changefreq</changefreq>
    <priority>$priority</priority>
  </url>

"@
}

$sitemap += "</urlset>`r`n"
[System.IO.File]::WriteAllText($OutputPath, $sitemap, [System.Text.UTF8Encoding]::new($false))

Write-Host "Sitemap generated: $OutputPath"
Write-Host "Total URLs: $($htmlFiles.Count)"
