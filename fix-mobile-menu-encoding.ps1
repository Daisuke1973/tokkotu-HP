# Fix encoding issues in mobile menu buttons
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

foreach ($file in $htmlFiles) {
    if ($file.Name -eq "index.html") {
        Write-Host "Skipping (already fixed): $($file.Name)"
        continue
    }

    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Fix the garbled text
    $pattern = '  <button class="mobile-menu-toggle" aria-label=".*?" aria-expanded="false">\s*<span class="hamburger-icon"></span>\s*<span style="margin-left: 10px;">.*?</span>\s*</button>'
    $replacement = '  <button class="mobile-menu-toggle" aria-label="メニューを開く" aria-expanded="false">' + "`r`n" +
                   '    <span class="hamburger-icon"></span>' + "`r`n" +
                   '    <span style="margin-left: 10px;">メニュー</span>' + "`r`n" +
                   '  </button>'

    $newContent = $content -replace $pattern, $replacement

    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Fixed: $($file.Name)"
    } else {
        Write-Host "No changes needed: $($file.Name)"
    }
}

Write-Host "`nCompleted fixing mobile menu encoding."
