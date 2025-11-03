# Remove broken structured data and add correct UTF-8 encoded data
$htmlFiles = Get-ChildItem -Path "C:\code" -Filter "*.html"

foreach ($file in $htmlFiles) {
    Write-Host "Processing: $($file.Name)"

    # Read file as UTF-8
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Remove existing broken structured data
    $content = $content -replace '(?s)  <!-- Structured Data: Organization -->.*?</script>\r?\n', ''

    # Prepare new structured data based on page type
    if ($file.Name -eq 'index.html') {
        $structuredData = @'
  <!-- Structured Data: Organization & WebSite -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "name": "旭川東高等学校同窓会 札幌突兀会",
        "alternateName": "札幌突兀会",
        "url": "https://yourdomain.jp",
        "logo": "https://yourdomain.jp/photo/mark1.gif",
        "foundingDate": "1960",
        "description": "旭川東高等学校同窓会の札幌支部。札幌市および近郊に住む旭川中学・旭川東高校の卒業生で構成される同窓会組織。",
        "address": {
          "@type": "PostalAddress",
          "addressLocality": "札幌市",
          "addressRegion": "北海道",
          "addressCountry": "JP"
        }
      },
      {
        "@type": "WebSite",
        "name": "旭川東高等学校同窓会 札幌突兀会",
        "url": "https://yourdomain.jp",
        "description": "同窓会の公式サイト。最新情報やイベントの案内を掲載しています。"
      }
    ]
  }
  </script>
'@
    }
    elseif ($file.Name -eq 'kaihou.html') {
        $structuredData = @'
  <!-- Structured Data: Organization & CollectionPage -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "name": "旭川東高等学校同窓会 札幌突兀会",
        "url": "https://yourdomain.jp",
        "logo": "https://yourdomain.jp/photo/mark1.gif"
      },
      {
        "@type": "CollectionPage",
        "name": "会報",
        "description": "旭川東高等学校同窓会札幌突兀会の会報アーカイブ。総会や懇親会の報告を掲載しています。",
        "url": "https://yourdomain.jp/kaihou.html"
      }
    ]
  }
  </script>
'@
    }
    elseif ($file.Name -eq 'gaiyo.html') {
        $structuredData = @'
  <!-- Structured Data: Organization & AboutPage -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "name": "旭川東高等学校同窓会 札幌突兀会",
        "url": "https://yourdomain.jp",
        "logo": "https://yourdomain.jp/photo/mark1.gif",
        "foundingDate": "1960",
        "numberOfMembers": 4000
      },
      {
        "@type": "AboutPage",
        "name": "概要",
        "description": "札幌突兀会の名前の由来、設立年、会員数などの概要情報。",
        "url": "https://yourdomain.jp/gaiyo.html"
      }
    ]
  }
  </script>
'@
    }
    else {
        # Default: Simple Organization schema
        $structuredData = @'
  <!-- Structured Data: Organization -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "旭川東高等学校同窓会 札幌突兀会",
    "url": "https://yourdomain.jp",
    "logo": "https://yourdomain.jp/photo/mark1.gif",
    "foundingDate": "1960"
  }
  </script>
'@
    }

    # Insert before </head>
    $content = $content -replace '</head>', ($structuredData + "`r`n</head>")

    # Write back as UTF-8 with BOM
    [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($true))

    Write-Host "  -> Fixed and added structured data"
}

Write-Host "`nAll files processed successfully!"
