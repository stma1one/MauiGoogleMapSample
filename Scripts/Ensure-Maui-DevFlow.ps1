param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Version = "",
    [switch]$Upgrade,
    [switch]$Offline,
    [Alias("SkipDevFlow", "NoDevFlow")]
    [switch]$Skip,
    [Alias("NoCli", "SkipDevFlowCli")]
    [switch]$SkipCli,
    [Alias("Disable")]
    [switch]$Remove,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$DefaultDevFlowVersion = "0.1.0-preview.14.26531.2"

if ($Skip -or ($env:MAUI_SKIP_DEVFLOW -match '^(1|true|yes)$')) {
    Write-Host "[SKIP] MAUI DevFlow automatic injection skipped by user option (-SkipDevFlow / MAUI_SKIP_DEVFLOW)."
    exit 0
}

function Ensure-DevFlowCli([switch]$Upgrade) {
    if ($Skip -or $SkipCli -or $Remove -or $DryRun -or $Offline -or ($env:MAUI_SKIP_DEVFLOW -match '^(1|true|yes)$') -or ($env:MAUI_SKIP_DEVFLOW_CLI -match '^(1|true|yes)$')) {
        if ($SkipCli -or ($env:MAUI_SKIP_DEVFLOW_CLI -match '^(1|true|yes)$')) {
            Write-Host "[SKIP] Global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli) installation skipped (-SkipCli / MAUI_SKIP_DEVFLOW_CLI)." -ForegroundColor Yellow
        }
        return
    }

    $hasCli = Get-Command "maui" -CommandType Application -ErrorAction SilentlyContinue
    if (-not $hasCli) {
        $dotnetCmd = Get-Command "dotnet" -CommandType Application -ErrorAction SilentlyContinue
        if (-not $dotnetCmd) {
            Write-Host "[WARN] 'dotnet' CLI not found; skipping global Microsoft.Maui.Cli installation." -ForegroundColor Yellow
            return
        }
        Write-Host "[INFO] Installing global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)..." -ForegroundColor Cyan
        & dotnet tool install -g Microsoft.Maui.Cli --prerelease
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Global Microsoft.Maui.Cli installation returned non-zero (pass -SkipCli if working without global permissions)." -ForegroundColor Yellow
        }
    } elseif ($Upgrade) {
        Write-Host "[INFO] Updating global .NET MAUI DevFlow CLI..." -ForegroundColor Cyan
        & dotnet tool update -g Microsoft.Maui.Cli --prerelease
    } else {
        Write-Host "[OK] Global .NET MAUI DevFlow CLI ('maui') is already installed." -ForegroundColor Green
    }
}

Ensure-DevFlowCli -Upgrade:$Upgrade

function Find-WorkingPython3 {
    foreach ($candidate in @("python3", "python", "py")) {
        $cmd = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) {
            try {
                if ($candidate -eq "py") {
                    & $cmd.Source -3 -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" *> $null
                    if ($LASTEXITCODE -eq 0) { return @($cmd.Source, "-3") }
                } else {
                    & $cmd.Source -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" *> $null
                    if ($LASTEXITCODE -eq 0) { return @($cmd.Source) }
                }
            } catch {}
        }
    }
    $localPaths = @()
    if ($env:LocalAppData) {
        $localPaths += Get-ChildItem -Path (Join-Path $env:LocalAppData "Programs\Python\Python3*\python.exe") -ErrorAction SilentlyContinue
    }
    if ($env:ProgramFiles) {
        $localPaths += Get-ChildItem -Path (Join-Path $env:ProgramFiles "Python3*\python.exe") -ErrorAction SilentlyContinue
    }
    foreach ($exe in ($localPaths | Sort-Object FullName -Descending)) {
        try {
            & $exe.FullName -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" *> $null
            if ($LASTEXITCODE -eq 0) { return @($exe.FullName) }
        } catch {}
    }
    return $null
}

function Try-InstallPython3 {
    if ($env:MAUI_NO_PYTHON_INSTALL -match '^(1|true|yes)$') {
        return $null
    }
    $winget = Get-Command winget -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($winget) {
        Write-Host "[INFO] Python 3 not found. Attempting automatic installation via winget..." -ForegroundColor Cyan
        try {
            & $winget.Source install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent *> $null
        } catch {}
    }
    return (Find-WorkingPython3)
}

$scriptPath = Join-Path $PSScriptRoot "Ensure-Maui-DevFlow.py"
$pythonSpec = Find-WorkingPython3
if (-not $pythonSpec) {
    $pythonSpec = Try-InstallPython3
}

if ($pythonSpec -and (Test-Path $scriptPath)) {
    if ($pythonSpec -is [string]) {
        $pythonSpec = @($pythonSpec)
    }
    $pyExe = $pythonSpec[0]
    $argsList = @()
    if ($pythonSpec.Count -gt 1) {
        $argsList += $pythonSpec[1..($pythonSpec.Count - 1)]
    }
    $argsList += @($scriptPath, "--project-root", $ProjectRoot)
    if ($Version) { $argsList += @("--version", $Version) }
    if ($Upgrade) { $argsList += "--upgrade" }
    if ($Offline) { $argsList += "--offline" }
    if ($Skip) { $argsList += "--skip" }
    # Ensure-DevFlowCli already ran in PowerShell above, so pass --skip-cli to avoid duplicate CLI invocation
    $argsList += "--skip-cli"
    if ($Remove) { $argsList += "--remove" }
    if ($DryRun) { $argsList += "--dry-run" }

    & $pyExe @argsList
    exit $LASTEXITCODE
}

# Native PowerShell fallback when Python 3 is unavailable
Write-Host "[INFO] Running native PowerShell DevFlow provisioning (Python 3 not available)." -ForegroundColor Cyan
$resolvedRoot = (Resolve-Path $ProjectRoot).Path
$csprojFiles = Get-ChildItem -Path $resolvedRoot -Recurse -Filter "*.csproj" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "[\\/](bin|obj|\.git|\.vs|\.idea|node_modules|\.agents|\.claude|companion-skills|skills|project-template)[\\/]" } |
    Where-Object {
        $txt = Get-Content -LiteralPath $_.FullName -Raw
        ($txt -match '<UseMaui>\s*true\s*</UseMaui>') -or ($txt -match 'Microsoft\.Maui\.Controls')
    }

if (-not $csprojFiles) {
    Write-Host "[INFO] No .NET MAUI .csproj detected under $resolvedRoot; skipping DevFlow project injection."
    exit 0
}

$mauiPrograms = Get-ChildItem -Path $resolvedRoot -Recurse -Filter "MauiProgram.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "[\\/](bin|obj|\.git|\.vs|\.idea|node_modules|\.agents|\.claude|companion-skills|skills|project-template)[\\/]" }

if ($Remove) {
    foreach ($csproj in $csprojFiles) {
        $txt = Get-Content -LiteralPath $csproj.FullName -Raw
        if ($txt -match 'Microsoft\.Maui\.DevFlow\.Agent') {
            $updated = [regex]::Replace($txt, '(?is)\r?\n?[ \t]*<ItemGroup\s+Condition="''?\$\(Configuration\)''?\s*==\s*''?Debug''?"\s*>\s*<PackageReference\s+Include="Microsoft\.Maui\.DevFlow\.Agent"[^/>]*/>\s*</ItemGroup>[ \t]*', '')
            $updated = [regex]::Replace($updated, '(?im)^[ \t]*<PackageReference\s+[^>]*Include="Microsoft\.Maui\.DevFlow\.Agent"[^/>]*/>[ \t]*\r?\n?', '')
            if (-not $DryRun) { [IO.File]::WriteAllText($csproj.FullName, $updated, [Text.UTF8Encoding]::new($false)) }
            Write-Host "[REMOVED] Removed Microsoft.Maui.DevFlow.Agent from $($csproj.Name)"
        }
    }
    foreach ($mp in $mauiPrograms) {
        $txt = Get-Content -LiteralPath $mp.FullName -Raw
        if ($txt -match 'AddMauiDevFlowAgent|Microsoft\.Maui\.DevFlow\.Agent') {
            $updated = [regex]::Replace($txt, '(?m)#if\s+DEBUG\s*\r?\n[ \t]*using\s+Microsoft\.Maui\.DevFlow\.Agent;\s*\r?\n#endif\s*\r?\n?', '')
            $updated = [regex]::Replace($updated, '(?m)#if\s+DEBUG\s*\r?\n[ \t]*builder\.AddMauiDevFlowAgent\(\s*\);\s*\r?\n#endif\s*\r?\n?', '')
            if (-not $DryRun) { [IO.File]::WriteAllText($mp.FullName, $updated, [Text.UTF8Encoding]::new($false)) }
            Write-Host "[REMOVED] Removed DevFlow registration from $($mp.Name)"
        }
    }
    exit 0
}

$targetVer = if ($Version) { $Version } else { $DefaultDevFlowVersion }
$anyActive = $false

foreach ($csproj in $csprojFiles) {
    $txt = Get-Content -LiteralPath $csproj.FullName -Raw
    $tfms = @()
    foreach ($m in [regex]::Matches($txt, '(?i)<TargetFrameworks?\b[^>]*>([^<]+)</TargetFrameworks?>')) {
        foreach ($tok in ($m.Groups[1].Value -split ';')) {
            $c = $tok.Trim()
            if ($c -and -not $c.StartsWith('$(') -and ($tfms -notcontains $c)) {
                $tfms += $c
            }
        }
    }
    $supported = @($tfms | Where-Object { $_ -match '^(?i)net1[01]\.0($|[-.])' })
    $unsupported = @($tfms | Where-Object { $_ -notmatch '^(?i)net1[01]\.0($|[-.])' })
    $tfmSummary = if ($tfms.Count) { $tfms -join ';' } else { 'unspecified TargetFramework' }

    if ($unsupported.Count -gt 0 -or $supported.Count -eq 0) {
        Write-Host "[SKIP] $($csproj.Name) targets '$tfmSummary'; Microsoft.Maui.DevFlow.Agent requires net10.0 or net11.0. Skipping DevFlow injection."
        continue
    }

    if ($txt -match 'Microsoft\.Maui\.DevFlow\.Agent') {
        Write-Host "[OK] DevFlow PackageReference already present in $($csproj.Name)"
        $anyActive = $true
        continue
    }

    $closeIdx = $txt.LastIndexOf("</Project>")
    if ($closeIdx -lt 0) {
        Write-Host "[WARN] Could not locate </Project> in $($csproj.Name); skipped."
        continue
    }
    $snippet = "`n  <ItemGroup Condition=`"'`$(Configuration)' == 'Debug'`">`n    <PackageReference Include=`"Microsoft.Maui.DevFlow.Agent`" Version=`"$targetVer`" />`n  </ItemGroup>`n"
    $updated = $txt.Substring(0, $closeIdx).TrimEnd() + "`n" + $snippet + "</Project>`n"
    if (-not $DryRun) {
        [IO.File]::WriteAllText($csproj.FullName, ($updated -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    }
    Write-Host "[INJECTED] Added Debug-only Microsoft.Maui.DevFlow.Agent ($targetVer) to $($csproj.Name)"
    $anyActive = $true
}

if ($anyActive) {
    foreach ($mp in $mauiPrograms) {
        $mpTxt = Get-Content -LiteralPath $mp.FullName -Raw
        if ($mpTxt -match 'AddMauiDevFlowAgent') {
            Write-Host "[OK] AddMauiDevFlowAgent() already present in $($mp.Name)"
            continue
        }
        $updated = $mpTxt
        if ($updated -notmatch 'Microsoft\.Maui\.DevFlow\.Agent') {
            $usingBlock = "#if DEBUG`nusing Microsoft.Maui.DevFlow.Agent;`n#endif`n"
            $usingMatches = [regex]::Matches($updated, '(?m)^(?:global\s+)?using\s+[^;]+;\s*$')
            if ($usingMatches.Count -gt 0) {
                $lastUsing = $usingMatches[$usingMatches.Count - 1]
                $pos = $lastUsing.Index + $lastUsing.Length
                $updated = $updated.Substring(0, $pos) + "`n" + $usingBlock.TrimEnd("`n") + $updated.Substring($pos)
            } else {
                $updated = $usingBlock + $updated
            }
        }
        $buildMatch = [regex]::Match($updated, '(?m)^([ \t]*)return\s+builder\.Build\(\s*\)\s*;')
        if (-not $buildMatch.Success) {
            Write-Host "[WARN] Could not locate 'return builder.Build();' in $($mp.Name); skipped."
            continue
        }
        $indent = $buildMatch.Groups[1].Value
        $callBlock = "#if DEBUG`n${indent}builder.AddMauiDevFlowAgent();`n#endif`n"
        $updated = $updated.Substring(0, $buildMatch.Index) + $callBlock + $updated.Substring($buildMatch.Index)
        if (-not $DryRun) {
            [IO.File]::WriteAllText($mp.FullName, ($updated -replace "`r`n", "`n"), [Text.UTF8Encoding]::new($false))
        }
        Write-Host "[INJECTED] Added #if DEBUG builder.AddMauiDevFlowAgent() to $($mp.Name)"
    }
}
exit 0
