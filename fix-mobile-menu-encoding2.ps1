# Fix encoding issues in mobile menu buttons
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

foreach ($file in $htmlFiles) {
    if ($file.Name -eq "index.html") {
        Write-Host "Skipping (already fixed): $($file.Name)"
        continue
    }

    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Check if it has the garbled text
    if ($content -notmatch '繝｡繝九Η繝ｼ') {
        Write-Host "No garbled text found: $($file.Name)"
        continue
    }

    # Replace the entire button element
    $content = $content -replace '<button class="mobile-menu-toggle"[^>]*>[\s\S]*?</button>', @'
<button class="mobile-menu-toggle" aria-label="メニューを開く" aria-expanded="false">
    <span class="hamburger-icon"></span>
    <span style="margin-left: 10px;">メニュー</span>
  </button>
'@

    Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Fixed: $($file.Name)"
}

Write-Host "`nCompleted fixing mobile menu encoding."
