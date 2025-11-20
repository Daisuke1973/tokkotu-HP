# 文字化け修正スクリプト
$files = @('kaihou.html', 'soukai.html', 'golf.html', 'yakuinkai2.html')

foreach ($file in $files) {
    $path = "C:\code\$file"
    if (Test-Path $path) {
        Write-Host "修正中: $file"
        $enc = New-Object System.Text.UTF8Encoding $false
        $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        
        # 文字化けを修正
        $content = $content.Replace('逕ｻ蜒乗僑螟ｧ陦ｨ遉ｺ', '画像拡大表示')
        $content = $content.Replace('繝｢繝ｼ繝繝ｫ繧帝哩縺倥ｋ', 'モーダルを閉じる')
        
        [System.IO.File]::WriteAllText($path, $content, $enc)
        Write-Host "完了: $file"
    }
}

Write-Host "全ファイルの修正が完了しました"
