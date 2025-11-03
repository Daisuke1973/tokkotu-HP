# Add mobile menu toggle button to all HTML files
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

$buttonHtml = @'
  <button class="mobile-menu-toggle" aria-label="メニューを開く" aria-expanded="false">
    <span class="hamburger-icon"></span>
    <span style="margin-left: 10px;">メニュー</span>
  </button>
  <nav
'@

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Check if mobile menu toggle already exists
    if ($content -match 'mobile-menu-toggle') {
        Write-Host "Already has mobile menu: $($file.Name)"
        continue
    }

    # Add button before nav tag (replace <nav with button + <nav)
    $pattern = '  <nav'
    $newContent = $content -replace $pattern, $buttonHtml

    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Updated: $($file.Name)"
    } else {
        Write-Host "No nav tag found: $($file.Name)"
    }
}

Write-Host "`nCompleted adding mobile menu buttons."
