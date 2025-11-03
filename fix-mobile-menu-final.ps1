# Fix mobile menu encoding issues in all HTML files (using raw bytes)
$files = @(
    'ayumi.html',
    'backnumber.html',
    'golf.html',
    'kaihou.html',
    'kaisoku.html',
    'kouka.html',
    'links.html',
    'sotsugyo.html',
    'soukai.html',
    'yakuin.html',
    'yakuinkai2.html'
)

foreach ($filename in $files) {
    $filepath = "C:\code\$filename"

    # Read as bytes to preserve encoding
    $bytes = [System.IO.File]::ReadAllBytes($filepath)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Replace the button
    $oldButton = @'
<button class="mobile-menu-toggle" aria-label="繝｡繝九Η繝ｼ繧帝幕縺・ aria-expanded="false">
    <span class="hamburger-icon"></span>
    <span style="margin-left: 10px;">繝｡繝九Η繝ｼ</span>
  </button>
'@

    $newButton = @'
<button class="mobile-menu-toggle" aria-label="メニューを開く" aria-expanded="false">
    <span class="hamburger-icon"></span>
    <span style="margin-left: 10px;">メニュー</span>
  </button>
'@

    if ($content -match [regex]::Escape($oldButton)) {
        $newContent = $content -replace [regex]::Escape($oldButton), $newButton
        $newBytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
        [System.IO.File]::WriteAllBytes($filepath, $newBytes)
        Write-Host "Fixed: $filename"
    } else {
        Write-Host "Pattern not found in: $filename"
    }
}

Write-Host "`nCompleted!"
