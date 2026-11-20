param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Offline,
    [switch]$Fix
)
$ErrorActionPreference = "Stop"

$allCsprojs = Get-ChildItem $ProjectRoot -Filter "*.csproj" -Recurse -File |
    Where-Object { $_.FullName -notmatch "[\\/](bin|obj|\.git|\.vs|\.agents|project-template|companion-skills|skills)[\\/]" }

$csproj = $allCsprojs |
    Where-Object { $_.FullName -notmatch "\\Tests\\|\.Tests\\" -and $_.Name -notmatch '(?i)\.Tests\.csproj$' } |
    Select-Object -First 1

if (-not $csproj) {
    Write-Host "No MAUI app .csproj found." -ForegroundColor Red
    exit 2
}

$text = Get-Content $csproj.FullName -Raw
$match = [regex]::Match($text, '<TargetFrameworks?>\s*([^<]+)')
$tfm = if ($match.Success) { $match.Groups[1].Value.Trim() } else { "" }

Write-Host "Project: $($csproj.FullName)"
Write-Host "Target framework: $tfm"

if (-not $tfm -or $tfm -notmatch '\bnet(8|9|10|11)\.0') {
    Write-Host "ERROR: TargetFramework '$tfm' is not a supported modern .NET MAUI target (net8.0, net9.0, net10.0, or net11.0)." -ForegroundColor Red
    Write-Host "RESULT: CHECK REQUIRED" -ForegroundColor Yellow
    exit 1
}

if ($tfm -match 'net11\.0') {
    Write-Host "NOTICE: .NET 11 MAUI is preview. Avoid preview-only APIs unless required." -ForegroundColor Yellow
}
else {
    Write-Host "Target framework verified ($tfm)." -ForegroundColor Green
}

function Compare-SemVer([string]$A, [string]$B) {
    $cleanA = ($A -split '-')[0].Trim()
    $cleanB = ($B -split '-')[0].Trim()
    try {
        $vA = [version]$cleanA
        $vB = [version]$cleanB
        return $vA.CompareTo($vB)
    } catch {
        return [string]::Compare($cleanA, $cleanB, $true)
    }
}

$minStableBaselines = @{
    "google.genai"              = "2.2.0"
    "xunit.v3"                  = "4.0.3"
    "xunit.runner.visualstudio" = "4.0.1"
    "microsoft.net.test.sdk"    = "18.12.0"
    "coverlet.collector"        = "10.1.1"
    "sqlite-net-pcl"            = "1.11.285"
    "sqlitepclraw.bundle_green" = "2.1.11"
    "sqlitenetextensions"       = "2.1.0"
    "sqlitenetextensions.async" = "2.1.0"
}

$previewAllowedPackages = @("microsoft.maui.devflow.agent", "microsoft.maui.devflow")

function Get-LatestStableNuGetVersion([string]$PackageId) {
    $pkgLow = $PackageId.ToLowerInvariant()
    $fallback = if ($minStableBaselines.ContainsKey($pkgLow)) { $minStableBaselines[$pkgLow] } else { "" }
    if ($Offline) { return $fallback }
    try {
        $resp = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/$pkgLow/index.json" -TimeoutSec 3
        $stableList = @($resp.versions | Where-Object { $_ -notmatch '-' -and $_ -notmatch '\*' })
        if ($stableList.Count -gt 0) {
            return [string]$stableList[-1]
        }
    } catch {}
    return $fallback
}

$hasNuGetIssue = $false

foreach ($proj in $allCsprojs) {
    $projText = Get-Content -LiteralPath $proj.FullName -Raw
    $updatedText = $projText
    $pkgMatches = [regex]::Matches($projText, '<PackageReference\s+[^>]*Include\s*=\s*"([^"]+)"[^>]*Version\s*=\s*"([^"]+)"[^/>]*/?>')
    foreach ($pm in $pkgMatches) {
        $pkgId = $pm.Groups[1].Value.Trim()
        $pkgVer = $pm.Groups[2].Value.Trim()
        $pkgLow = $pkgId.ToLowerInvariant()

        if ($pkgVar = $pkgVer.StartsWith('$(')) { continue }

        if ($pkgLow -eq "xunit") {
            $latestXunitV3 = Get-LatestStableNuGetVersion "xunit.v3"
            if ($Fix) {
                $updatedText = $updatedText.Replace($pm.Value, ($pm.Value -replace 'Include\s*=\s*"xunit"', 'Include="xunit.v3"' -replace "Version\s*=\s*`"$([regex]::Escape($pkgVer))`"", "Version=`"$latestXunitV3`""))
                Write-Host "[FIXED] $($proj.Name): Replaced legacy 'xunit' ($pkgVer) with 'xunit.v3' ($latestXunitV3)." -ForegroundColor Cyan
                continue
            }
            Write-Host "[LEGACY NUGET] $($proj.Name): Package 'xunit' ($pkgVer) is legacy xUnit v2. Must use 'xunit.v3' (latest stable: $latestXunitV3)." -ForegroundColor Red
            $hasNuGetIssue = $true
            continue
        }

        if ($previewAllowedPackages -contains $pkgLow) {
            continue
        }

        if ($pkgVer -match '-') {
            $latestStable = Get-LatestStableNuGetVersion $pkgId
            if ($latestStable) {
                if ($Fix) {
                    $updatedText = $updatedText.Replace($pm.Value, ($pm.Value -replace "Version\s*=\s*`"$([regex]::Escape($pkgVer))`"", "Version=`"$latestStable`""))
                    Write-Host "[FIXED] $($proj.Name): Replaced prerelease '$pkgId' ($pkgVer) with latest stable '$latestStable'." -ForegroundColor Cyan
                    continue
                }
                Write-Host "[NON-STABLE NUGET] $($proj.Name): Package '$pkgId' uses prerelease version '$pkgVer'. Must use latest stable version '$latestStable'." -ForegroundColor Red
                $hasNuGetIssue = $true
                continue
            }
        }

        $latestStable = Get-LatestStableNuGetVersion $pkgId
        if ($latestStable -and (Compare-SemVer $pkgVer $latestStable) -lt 0) {
            if ($Fix) {
                $updatedText = $updatedText.Replace($pm.Value, ($pm.Value -replace "Version\s*=\s*`"$([regex]::Escape($pkgVer))`"", "Version=`"$latestStable`""))
                Write-Host "[FIXED] $($proj.Name): Upgraded '$pkgId' from '$pkgVer' to latest stable '$latestStable'." -ForegroundColor Cyan
                continue
            }
            Write-Host "[OUTDATED NUGET] $($proj.Name): Package '$pkgId' is at '$pkgVer', which is older than the latest stable version '$latestStable'. Install/update with: dotnet add `"$($proj.FullName)`" package $pkgId --version $latestStable" -ForegroundColor Red
            $hasNuGetIssue = $true
        } else {
            Write-Host "[OK] $($proj.Name): Package '$pkgId' is at latest stable version ($pkgVer)." -ForegroundColor Green
        }
    }

    if ($Fix -and ($updatedText -ne $projText)) {
        [IO.File]::WriteAllText($proj.FullName, ($updatedText -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    }
}

if ($hasNuGetIssue) {
    Write-Host "RESULT: CHECK REQUIRED (All NuGet packages must use the latest Stable release and xunit.v3 for unit tests)." -ForegroundColor Yellow
    exit 1
}

Write-Host "RESULT: PASS" -ForegroundColor Green
exit 0
