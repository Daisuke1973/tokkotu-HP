# Optimize Google Fonts loading in all HTML files
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

# Optimized font loading code
$fontCode = @'
  <!-- Preconnect to Google Fonts for faster loading -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <!-- Load Google Fonts asynchronously -->
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Montserrat:wght@700&family=Noto+Sans+JP:wght@400;500;700&display=swap" media="print" onload="this.media='all'">
  <noscript><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Montserrat:wght@700&family=Noto+Sans+JP:wght@400;500;700&display=swap"></noscript>
'@

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Check if already optimized
    if ($content -match 'rel="preconnect".*fonts\.googleapis\.com') {
        Write-Host "Already optimized: $($file.Name)"
        continue
    }

    # Insert before <link rel="stylesheet" href="style.css">
    $pattern = '  <link rel="stylesheet" href="style.css">'

    if ($content -match [regex]::Escape($pattern)) {
        $newContent = $content -replace [regex]::Escape($pattern), ($fontCode + "`r`n" + $pattern)
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Optimized: $($file.Name)"
    } else {
        Write-Host "Pattern not found in: $($file.Name)"
    }
}

Write-Host "`nGoogle Fonts optimization completed!"
