# Fix encoding issues in HTML files

$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

foreach ($file in $htmlFiles) {
    Write-Host "Fixing: $($file.Name)"

    # Read with UTF8 encoding
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Fix common encoding issues
    $content = $content -replace '`n', "`n"
    $content = $content -replace '繝｡繧､繝ｳ繧ｳ繝ｳ繝・Φ繝・∈繧ｹ繧ｭ繝・・', 'メインコンテンツへスキップ'
    $content = $content -replace '荳ｻ隕√リ繝薙ご繝ｼ繧ｷ繝ｧ繝ｳ', '主要ナビゲーション'
    $content = $content -replace '逕ｻ蜒乗僑螟ｧ陦ｨ遉ｺ', '画像拡大表示'
    $content = $content -replace '繝｢繝ｼ繝繝ｫ繧帝哩縺倥ｋ', 'モーダルを閉じる'
    $content = $content -replace '諡｡螟ｧ逕ｻ蜒・', '拡大画像'

    # Write with UTF8 encoding (no BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
}

Write-Host "`nAll files fixed!"
