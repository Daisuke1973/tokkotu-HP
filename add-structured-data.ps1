# Add JSON-LD structured data to all HTML files
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

# Base Organization Schema (for all pages)
$organizationSchema = @'

  <!-- Structured Data: Organization -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "旭川東高等学校同窓会 札幌突兀会",
    "alternateName": "札幌突兀会",
    "url": "https://tokkotu.jp",
    "logo": "https://tokkotu.jp/assets/images/shared/branding/logo-mark1.gif",
    "foundingDate": "1960",
    "description": "旭川東高等学校同窓会の札幌支部。札幌市および近郊に住む旭川中学・旭川東高校の卒業生・在籍者で構成される同窓会組織。",
    "address": {
      "@type": "PostalAddress",
      "addressLocality": "札幌市",
      "addressRegion": "北海道",
      "addressCountry": "JP"
    },
    "memberOf": {
      "@type": "Organization",
      "name": "旭川東高等学校同窓会"
    }
  }
  </script>
'@

foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Check if structured data already exists
    if ($content -match '@type.*Organization') {
        Write-Host "Already has structured data: $($file.Name)"
        continue
    }

    # Insert before </head>
    $pattern = '</head>'

    if ($content -match [regex]::Escape($pattern)) {
        $newContent = $content -replace [regex]::Escape($pattern), ($organizationSchema + "`r`n" + $pattern)
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "Added structured data: $($file.Name)"
    } else {
        Write-Host "</head> not found in: $($file.Name)"
    }
}

Write-Host "`nStructured data addition completed!"
