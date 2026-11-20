param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$SkipTests,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$modeFile = Join-Path $ProjectRoot ".agents\MAUI-Agent-Mode.json"
if (Test-Path -LiteralPath $modeFile) {
    try {
        $modeJson = Get-Content -LiteralPath $modeFile -Raw | ConvertFrom-Json
        if ($null -ne $modeJson.includeTests -and (-not [bool]$modeJson.includeTests)) {
            Write-Host "[SKIP] Unit test project provisioning skipped (includeTests=false in .agents/MAUI-Agent-Mode.json)." -ForegroundColor Yellow
            exit 0
        }
    } catch {}
}

if ($SkipTests -or ($env:MAUI_SKIP_TESTS -match '^(1|true|yes)$')) {
    Write-Host "[SKIP] Unit test project provisioning skipped (-SkipTests / MAUI_SKIP_TESTS)." -ForegroundColor Yellow
    exit 0
}

$scriptPath = Join-Path $PSScriptRoot "Ensure-Test-Project.py"
foreach ($candidate in @("python3", "python", "py")) {
    $cmd = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $pyArgs = @()
        if ($candidate -eq "py") { $pyArgs += "-3" }
        $pyArgs += @($scriptPath, "--project-root", $ProjectRoot)
        if ($SkipTests) { $pyArgs += "--skip-tests" }
        if ($DryRun) { $pyArgs += "--dry-run" }
        & $cmd.Source @pyArgs
        if ($LASTEXITCODE -eq 0) { exit 0 }
    }
}

# Native PowerShell fallback when Python is unavailable
$resolvedRoot = (Resolve-Path $ProjectRoot).Path
$mauiCsproj = Get-ChildItem -Path $resolvedRoot -Recurse -Filter "*.csproj" -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/](bin|obj|\.git|\.vs|\.agents|companion-skills|skills|project-template)[\\/]" -and
        $_.Name -notmatch '(?i)\.Tests\.csproj$'
    } |
    Where-Object {
        $txt = Get-Content -LiteralPath $_.FullName -Raw
        ($txt -match '<UseMaui>\s*true\s*</UseMaui>') -or ($txt -match 'Microsoft\.Maui\.Controls')
    } |
    Select-Object -First 1

if (-not $mauiCsproj) {
    Write-Host "[INFO] No .NET MAUI .csproj detected under $resolvedRoot yet; skipping xUnit test project creation."
    exit 0
}

$appName = $mauiCsproj.BaseName
$txt = Get-Content -LiteralPath $mauiCsproj.FullName -Raw
$baseTfm = "net10.0"
if ($txt -match '(?i)\b(net(?:8|9|10|11)\.0)\b') {
    $baseTfm = $Matches[1].ToLowerInvariant()
}

if ($txt -match '<TargetFrameworks>([^<]+)</TargetFrameworks>') {
    $tfms = $Matches[1]
    if ($tfms -notmatch "(?i)(^|;)\s*$([regex]::Escape($baseTfm))\s*(;|$)") {
        $txt = $txt -replace '<TargetFrameworks>([^<]+)</TargetFrameworks>', "<TargetFrameworks>$baseTfm;`$1</TargetFrameworks>"
    }
} elseif ($txt -match '<TargetFramework>([^<]+)</TargetFramework>') {
    $single = $Matches[1].Trim()
    if ($single -ne $baseTfm) {
        $txt = $txt -replace '<TargetFramework>([^<]+)</TargetFramework>', "<TargetFrameworks>$baseTfm;$single</TargetFrameworks>"
    }
}

$txt = $txt -replace '<OutputType>\s*Exe\s*</OutputType>', "<OutputType Condition=`"'`$(TargetFramework)' != 'net8.0' and '`$(TargetFramework)' != 'net9.0' and '`$(TargetFramework)' != 'net10.0' and '`$(TargetFramework)' != 'net11.0'`">Exe</OutputType>"
if (-not $DryRun) {
    [IO.File]::WriteAllText($mauiCsproj.FullName, ($txt -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
}

$testDir = Join-Path $resolvedRoot "$appName.Tests"
$testCsproj = Join-Path $testDir "$appName.Tests.csproj"
if (-not (Test-Path -LiteralPath $testCsproj) -and (-not $DryRun)) {
    New-Item -ItemType Directory -Force -Path $testDir | Out-Null
    $relMaui = [IO.Path]::GetRelativePath($testDir, $mauiCsproj.FullName)
    $xunitVer = "4.0.3"
    $runnerVer = "4.0.1"
    $sdkVer = "18.12.0"
    $covVer = "10.1.1"
    try {
        $r = Invoke-RestMethod -Uri "https://api.nuget.org/v3-flatcontainer/xunit.v3/index.json" -TimeoutSec 3
        $s = @($r.versions | Where-Object { $_ -notmatch '-' })
        if ($s.Count -gt 0) { $xunitVer = $s[-1] }
    } catch {}
    $xml = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>$baseTfm</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <OutputType>Exe</OutputType>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="coverlet.collector" Version="$covVer" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="$sdkVer" />
    <PackageReference Include="xunit.v3" Version="$xunitVer" />
    <PackageReference Include="xunit.runner.visualstudio" Version="$runnerVer" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="$relMaui" />
  </ItemGroup>

</Project>
"@
    [IO.File]::WriteAllText($testCsproj, ($xml -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    $globalJson = Join-Path $resolvedRoot "global.json"
    if (-not (Test-Path -LiteralPath $globalJson)) {
        [IO.File]::WriteAllText($globalJson, "{`n  `"test`": {`n    `"runner`": `"Microsoft.Testing.Platform`"`n  }`n}`n", [Text.UTF8Encoding]::new($false))
    }
    $smokeFile = Join-Path $testDir "ArchitectureSmokeTests.cs"
    if (-not (Test-Path -LiteralPath $smokeFile)) {
        $smokeCs = @"
using Xunit;

namespace $appName.Tests;

public class ArchitectureSmokeTests
{
    [Fact]
    public void TestHarness_WhenInitialized_PassesSanityCheck()
    {
        Assert.True(true);
    }
}
"@
        [IO.File]::WriteAllText($smokeFile, ($smokeCs -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    }
    Write-Host "[CREATED] Provisioned xUnit test project: $testCsproj" -ForegroundColor Green
}
exit 0
