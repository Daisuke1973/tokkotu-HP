param(
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Normalize-Slug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $slug = $Value.ToLowerInvariant()
    $slug = $slug -replace '[ _]+', '-'
    $slug = $slug -replace '[()]', ''
    $slug = $slug -replace '[^a-z0-9\-]+', '-'
    $slug = $slug -replace '-{2,}', '-'
    $slug = $slug.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "Could not normalize slug from '$Value'."
    }

    return $slug
}

function Register-TargetGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HtmlFileName,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [hashtable]$GroupInfoMap
    )

    if (-not $RelativePath.StartsWith("photo/")) {
        return $null
    }

    $parts = $RelativePath -split "/"
    if ($parts.Count -lt 2) {
        return $null
    }

    $sourceGroup = $null
    $sourceKey = $null
    $targetBaseDir = $null
    $targetType = "gallery"

    switch ($HtmlFileName.ToLowerInvariant()) {
        "yakuinkai2.html" {
            if ($parts.Count -lt 4 -or $parts[1] -ne "yakuinkai" -or $parts[2] -ne "img") {
                return $null
            }
            $sourceGroup = $parts[3]
            $sourceKey = "yakuinkai2.html|$sourceGroup"
            $targetBaseDir = "assets/images/events/yakuinkai/$(Normalize-Slug $sourceGroup)"
        }
        "soukai.html" {
            if ($parts.Count -lt 3) {
                return $null
            }

            if ($parts[1] -eq "yakuinkai" -and $parts.Count -ge 5 -and $parts[2] -eq "img") {
                $sourceGroup = $parts[3]
                $sourceKey = "soukai.html|$sourceGroup"
                $targetBaseDir = "assets/images/events/soukai/$(Normalize-Slug $sourceGroup)"
            }
            else {
                $sourceGroup = $parts[1]
                $sourceKey = "soukai.html|$sourceGroup"
                $targetBaseDir = "assets/images/events/soukai/legacy/$(Normalize-Slug $sourceGroup)"
            }
        }
        "golf.html" {
            if ($parts.Count -lt 3) {
                return $null
            }

            if ($parts[1] -eq "golf_bukai" -and $parts.Count -ge 4 -and $parts[2] -eq "img") {
                $sourceGroup = $parts[1]
                $sourceKey = "golf.html|$sourceGroup"
                $targetBaseDir = "assets/images/events/golf/$(Normalize-Slug $sourceGroup)"
            }
            elseif ($parts.Count -ge 3 -and $parts[2] -eq "img") {
                $sourceGroup = $parts[1]
                $sourceKey = "golf.html|$sourceGroup"
                $targetBaseDir = "assets/images/events/golf/legacy/$(Normalize-Slug $sourceGroup)"
            }
            else {
                return $null
            }
        }
        "kaihou.html" {
            if ($parts.Count -lt 3) {
                return $null
            }

            $sourceGroup = $parts[1]
            $sourceKey = "kaihou.html|$sourceGroup"

            if ($sourceGroup -match '^kaiho(\d+)$') {
                $issueNumber = [int]$Matches[1]
                $targetBaseDir = "assets/images/archives/kaiho/$('{0:D2}' -f $issueNumber)"
                $targetType = "page"
            }
            elseif ($parts.Count -ge 3 -and $parts[2] -eq "img") {
                $targetBaseDir = "assets/images/archives/legacy/$(Normalize-Slug $sourceGroup)"
            }
            else {
                $targetBaseDir = "assets/images/archives/legacy/$(Normalize-Slug $sourceGroup)"
            }
        }
        default {
            return $null
        }
    }

    if (-not $GroupInfoMap.ContainsKey($sourceKey)) {
        $GroupInfoMap[$sourceKey] = @{
            TargetBaseDir = $targetBaseDir
            TargetType = $targetType
            Items = @{}
        }
    }

    $group = $GroupInfoMap[$sourceKey]
    if (-not $group.Items.ContainsKey($RelativePath)) {
        $group.Items[$RelativePath] = $group.Items.Count + 1
    }

    return [pscustomobject]@{
        SourceKey = $sourceKey
    }
}

$rootPath = (Resolve-Path $Root).Path
$htmlFiles = Get-ChildItem -Path $rootPath -Filter *.html -File
$pattern = '(?<attr>(?:src|href))="(?<path>photo/[^"]+\.(?:jpg|jpeg|png|gif|webp|bmp|svg|JPG|JPEG|PNG|GIF))"'
$groupInfoMap = @{}
$plannedCopies = [ordered]@{}

foreach ($htmlFile in $htmlFiles) {
    $content = Get-Content -LiteralPath $htmlFile.FullName -Raw
    $matches = [regex]::Matches($content, $pattern)

    foreach ($match in $matches) {
        $relativePath = $match.Groups["path"].Value
        $targetInfo = Register-TargetGroup -HtmlFileName $htmlFile.Name -RelativePath $relativePath -GroupInfoMap $groupInfoMap

        if ($null -eq $targetInfo) {
            continue
        }
    }
}

if ($groupInfoMap.Count -eq 0) {
    Write-Host "No legacy photo references found."
    return
}

foreach ($group in $groupInfoMap.GetEnumerator()) {
    $groupValue = $group.Value
    $width = [Math]::Max(2, $groupValue.Items.Count.ToString().Length)

    foreach ($item in $groupValue.Items.GetEnumerator()) {
        $relativePath = $item.Key
        $index = $item.Value
        $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($extension)) {
            $extension = ".jpg"
        }

        $targetFileName = "{0}-{1}{2}" -f $groupValue.TargetType, $index.ToString("D$width"), $extension
        $plannedCopies[$relativePath] = "$($groupValue.TargetBaseDir)/$targetFileName"
    }
}

foreach ($htmlFile in $htmlFiles) {
    $content = Get-Content -LiteralPath $htmlFile.FullName -Raw
    $updatedContent = [regex]::Replace(
        $content,
        $pattern,
        {
            param($match)

            $relativePath = $match.Groups["path"].Value
            if (-not $plannedCopies.Contains($relativePath)) {
                return $match.Value
            }

            $newPath = $plannedCopies[$relativePath]
            return '{0}="{1}"' -f $match.Groups["attr"].Value, $newPath
        }
    )

    if ($updatedContent -ne $content) {
        Set-Content -LiteralPath $htmlFile.FullName -Value $updatedContent -NoNewline
    }
}

$copyCount = 0

foreach ($entry in $plannedCopies.GetEnumerator()) {
    $sourceRelativePath = $entry.Key
    $targetRelativePath = $entry.Value
    $sourcePath = Join-Path $rootPath $sourceRelativePath.Replace('/', '\')
    $targetPath = Join-Path $rootPath $targetRelativePath.Replace('/', '\')
    $targetDirectory = Split-Path -Parent $targetPath

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing source image: $sourceRelativePath"
    }

    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    $copyCount++
}

Write-Host "Updated references:" $plannedCopies.Count
Write-Host "Copied assets:" $copyCount
