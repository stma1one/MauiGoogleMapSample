param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$HtmlPath = "",
    [string]$PdfPath = "",
    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
$scriptPath = Join-Path $PSScriptRoot "Validate-Learning-Book.py"
if (-not (Test-Path $scriptPath)) {
    $scriptPath = Join-Path $ProjectRoot ".agents\skills\maui-step-guide-author\scripts\validate_learning_book.py"
}
if (-not (Test-Path $scriptPath)) {
    Write-Error "Could not find validate_learning_book.py."
    exit 1
}

if (-not $HtmlPath) { $HtmlPath = Join-Path $ProjectRoot "Learning\MAUI-Learning-Book.html" }
if (-not $PdfPath) { $PdfPath = Join-Path $ProjectRoot "Learning\MAUI-Learning-Book.pdf" }
if (-not $ReportPath) { $ReportPath = Join-Path $ProjectRoot "Learning\MAUI-Learning-Book.validation.json" }

$preFlightFailed = $false
$learningDir = Join-Path $ProjectRoot "Learning"
$imagesDir = Join-Path $learningDir "Images"
$guidesDir = Join-Path $learningDir "Guides"

# 1. Verify Learning/MAUI-Learning-Book.pdf exists, is non-empty, and is up to date
if (-not (Test-Path -LiteralPath $PdfPath) -or ((Get-Item -LiteralPath $PdfPath).Length -eq 0)) {
    Write-Host "[MISSING PDF] $PdfPath does not exist or is empty. Run python .\Scripts\Generate-Learning-Book-Pdf.py before claiming Status: COMPLETE." -ForegroundColor Red
    $preFlightFailed = $true
} else {
    $pdfTime = (Get-Item -LiteralPath $PdfPath).LastWriteTimeUtc
    $mdSources = @()
    $bookMd = Join-Path $learningDir "MAUI-Learning-Book.md"
    if (Test-Path -LiteralPath $bookMd) { $mdSources += (Get-Item -LiteralPath $bookMd) }
    if (Test-Path -LiteralPath $guidesDir) {
        $mdSources += Get-ChildItem -LiteralPath $guidesDir -Filter "*.md" -File -ErrorAction SilentlyContinue
    }
    foreach ($md in $mdSources) {
        if ($md.LastWriteTimeUtc -gt $pdfTime.AddSeconds(2)) {
            Write-Host "[STALE PDF] $PdfPath is older than $($md.FullName). Re-run python .\Scripts\Generate-Learning-Book-Pdf.py." -ForegroundColor Red
            $preFlightFailed = $true
        }
    }
}

# 2. Verify at least one image exists in Learning/Images/ for every screen (Views/*.xaml, *Page.xaml, and Learning/Guides/*-Guide.md)
$screens = @{}
if (Test-Path -LiteralPath $guidesDir) {
    foreach ($g in (Get-ChildItem -LiteralPath $guidesDir -Filter "*-Guide.md" -File -ErrorAction SilentlyContinue)) {
        $sName = $g.BaseName -replace '-Guide$', ''
        if ($sName -and $sName -ne '<ScreenName>') {
            $stem = $sName -replace '(?i)(Page|View)$', ''
            if (-not $stem) { $stem = $sName }
            $screens[$sName] = @($sName.ToLowerInvariant(), $stem.ToLowerInvariant())
        }
    }
}

$xamlPages = Get-ChildItem -Path $ProjectRoot -Filter "*.xaml" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '[\\/](bin|obj|Scripts|\.git|\.vs|\.agents|Resources|Platforms)[\\/]' -and
        $_.Name -notmatch '^(?i)(App|AppShell|Styles|Colors)\.xaml$' -and
        ($_.FullName -match '[\\/]Views[\\/]' -or $_.BaseName -match '(?i)Page$')
    }

foreach ($xp in $xamlPages) {
    $sName = $xp.BaseName
    $stem = $sName -replace '(?i)(Page|View)$', ''
    if (-not $stem) { $stem = $sName }
    $existingKey = $null
    foreach ($k in $screens.Keys) {
        if ($screens[$k] -contains $sName.ToLowerInvariant() -or $screens[$k] -contains $stem.ToLowerInvariant()) {
            $existingKey = $k
            break
        }
    }
    if ($existingKey) {
        $screens[$existingKey] += @($sName.ToLowerInvariant(), $stem.ToLowerInvariant())
    } else {
        $screens[$sName] = @($sName.ToLowerInvariant(), $stem.ToLowerInvariant())
    }
}

$imageFiles = @()
if (Test-Path -LiteralPath $imagesDir) {
    $imageFiles = @(Get-ChildItem -LiteralPath $imagesDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^(?i)\.(png|jpg|jpeg|webp|svg)$' -and $_.Length -gt 0 })
}

if ($screens.Count -gt 0) {
    if ($imageFiles.Count -eq 0) {
        Write-Host "[MISSING IMAGES] No images found in $imagesDir for project screens ($($screens.Keys -join ', ')). Capture via MAUI DevFlow or HTML mockup + Capture-Mockup-Blocks.py." -ForegroundColor Red
        $preFlightFailed = $true
    } else {
        foreach ($sKey in $screens.Keys) {
            $tokens = $screens[$sKey]
            $matched = $false
            foreach ($img in $imageFiles) {
                $imgStem = $img.BaseName.ToLowerInvariant()
                $parentName = $img.Directory.Name.ToLowerInvariant()
                foreach ($tok in $tokens) {
                    if ($imgStem -eq $tok -or $imgStem.StartsWith("$tok-") -or $imgStem.StartsWith("${tok}_") -or $imgStem.Contains($tok) -or $parentName -eq $tok) {
                        $matched = $true
                        break
                    }
                }
                if ($matched) { break }
            }
            if (-not $matched) {
                Write-Host "[MISSING SCREEN IMAGE] No image found in Learning/Images/ for screen '$sKey'." -ForegroundColor Red
                $preFlightFailed = $true
            }
        }
    }
}

# 3. Verify that if Learning/Diagrams/*.mmd exist, visual PNG images (Screen-Flow.png & Architecture-UML.png) also exist in Learning/Images/
$diagramsDir = Join-Path $learningDir "Diagrams"
if (Test-Path -LiteralPath $diagramsDir) {
    if ((Test-Path -LiteralPath (Join-Path $diagramsDir "Screen-Flow.mmd")) -and -not (Test-Path -LiteralPath (Join-Path $imagesDir "Screen-Flow.png"))) {
        Write-Host "[MISSING DIAGRAM IMAGE] Learning/Images/Screen-Flow.png is missing. Run .\Scripts\Generate-Architecture-Diagrams.ps1." -ForegroundColor Red
        $preFlightFailed = $true
    }
    if ((Test-Path -LiteralPath (Join-Path $diagramsDir "Architecture-UML.mmd")) -and -not (Test-Path -LiteralPath (Join-Path $imagesDir "Architecture-UML.png"))) {
        Write-Host "[MISSING DIAGRAM IMAGE] Learning/Images/Architecture-UML.png is missing. Run .\Scripts\Generate-Architecture-Diagrams.ps1." -ForegroundColor Red
        $preFlightFailed = $true
    }
}

python $scriptPath --html $HtmlPath --pdf $PdfPath --report $ReportPath --project-root $ProjectRoot
if ($LASTEXITCODE -ne 0 -or $preFlightFailed) {
    exit 1
}
exit 0
