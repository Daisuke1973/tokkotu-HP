# Generate sitemap.xml for SEO
$baseUrl = "https://tokkotu.jp"
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html" | Sort-Object Name

# Page priority and change frequency configuration
$pageConfig = @{
    'index.html' = @{ priority = '1.0'; changefreq = 'weekly' }
    'gaiyo.html' = @{ priority = '0.9'; changefreq = 'yearly' }
    'soukai.html' = @{ priority = '0.9'; changefreq = 'monthly' }
    'kaihou.html' = @{ priority = '0.9'; changefreq = 'monthly' }
    'yakuinkai2.html' = @{ priority = '0.8'; changefreq = 'monthly' }
    'golf.html' = @{ priority = '0.8'; changefreq = 'monthly' }
    'ayumi.html' = @{ priority = '0.8'; changefreq = 'yearly' }
    'yakuin.html' = @{ priority = '0.7'; changefreq = 'yearly' }
    'kaisoku.html' = @{ priority = '0.7'; changefreq = 'yearly' }
    'sotsugyo.html' = @{ priority = '0.7'; changefreq = 'yearly' }
    'kouka.html' = @{ priority = '0.7'; changefreq = 'yearly' }
    'links.html' = @{ priority = '0.6'; changefreq = 'yearly' }
    'backnumber.html' = @{ priority = '0.6'; changefreq = 'yearly' }
}

# Start sitemap XML
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

    # Get priority and changefreq from config
    $config = $pageConfig[$fileName]
    if (-not $config) {
        $config = @{ priority = '0.5'; changefreq = 'yearly' }
    }

    $priority = $config.priority
    $changefreq = $config.changefreq

    # Add URL entry
    $sitemap += @"
  <url>
    <loc>$baseUrl/$fileName</loc>
    <lastmod>$lastMod</lastmod>
    <changefreq>$changefreq</changefreq>
    <priority>$priority</priority>
  </url>

"@
}

# Close sitemap
$sitemap += "</urlset>`r`n"

# Write sitemap.xml
$sitemapPath = "C:\code\sitemap.xml"
[System.IO.File]::WriteAllText($sitemapPath, $sitemap, [System.Text.UTF8Encoding]::new($false))

Write-Host "Sitemap generated: $sitemapPath"
Write-Host "Total URLs: $($htmlFiles.Count)"
