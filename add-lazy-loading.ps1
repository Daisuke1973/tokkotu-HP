# Add loading="lazy" to all img tags except header logos
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html" | Where-Object { $_.Name -ne "test-accordion.html" }

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Add loading="lazy" to img tags that don't already have it and are not header logos
    # Match img tags that:
    # 1. Don't already have loading attribute
    # 2. Are not class="header-logo"
    $pattern = '<img\s+(?![^>]*loading=)(?![^>]*class="header-logo")([^>]*?)>'
    $replacement = '<img loading="lazy" $1>'

    $newContent = $content -replace $pattern, $replacement

    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($file.Name)"
    } else {
        Write-Host "No changes needed: $($file.Name)"
    }
}

Write-Host "`nCompleted adding lazy loading to images."
