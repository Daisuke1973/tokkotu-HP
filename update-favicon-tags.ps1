# Update favicon tags in all HTML files
# This script implements Method B (Quick Implementation) by default
# For Method A (Full Optimization), replace $newFaviconCode with generated code from RealFaviconGenerator

$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

# Method B: Quick implementation using existing GIF
$newFaviconCode = @'
<link rel="icon" href="/photo/mark1.gif" type="image/gif">
  <link rel="apple-touch-icon" href="/photo/mark1.gif">
  <link rel="shortcut icon" href="/photo/mark1.gif">
  <meta name="msapplication-TileImage" content="/photo/mark1.gif">
  <meta name="msapplication-TileColor" content="#2c3e50">
  <meta name="theme-color" content="#2c3e50">
'@

# Method A: Full optimization (uncomment and modify after generating favicons)
# $newFaviconCode = @'
#   <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
#   <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
#   <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
#   <link rel="manifest" href="/site.webmanifest">
#   <meta name="msapplication-TileColor" content="#2c3e50">
#   <meta name="theme-color" content="#2c3e50">
# '@

foreach ($file in $htmlFiles) {
    Write-Host "Processing: $($file.Name)"

    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Remove old favicon tag
    $content = $content -replace '<link rel="icon"[^>]*?/?>', ''
    $content = $content -replace '<link rel="apple-touch-icon"[^>]*?/?>', ''
    $content = $content -replace '<link rel="shortcut icon"[^>]*?/?>', ''
    $content = $content -replace '<meta name="msapplication-TileImage"[^>]*?/?>', ''
    $content = $content -replace '<meta name="msapplication-TileColor"[^>]*?/?>', ''
    $content = $content -replace '<meta name="theme-color"[^>]*?/?>', ''
    $content = $content -replace '<link rel="manifest"[^>]*?/?>', ''

    # Clean up multiple blank lines
    $content = $content -replace '(\r?\n){3,}', "`r`n`r`n"

    # Insert new favicon code before </head>
    if ($content -match '</head>') {
        $content = $content -replace '</head>', ($newFaviconCode + "`r`n</head>")

        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($true))
        Write-Host "  -> Updated"
    }
    else {
        Write-Host "  -> </head> not found, skipped"
    }
}

Write-Host "`nFavicon tags update completed!"
Write-Host "Total files updated: $($htmlFiles.Count)"
