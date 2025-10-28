# Restore CSS references to original style.css

$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Replace new CSS structure with original single file
    $content = $content -replace '<link rel="stylesheet" href="css/variables\.css" />[\r\n\s]*<link rel="stylesheet" href="css/base\.css" />[\r\n\s]*<link rel="stylesheet" href="css/layout\.css" />[\r\n\s]*<link rel="stylesheet" href="css/components\.css" />[\r\n\s]*<link rel="stylesheet" href="css/utilities\.css" />', '<link rel="stylesheet" href="style.css">'

    # Write with UTF8 no BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)

    Write-Host "Updated: $($file.Name)"
}

Write-Host "`nAll HTML files restored to use style.css"
