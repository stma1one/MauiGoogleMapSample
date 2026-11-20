param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = "Stop"

$program = Get-ChildItem $ProjectRoot -Filter "MauiProgram.cs" -Recurse -File |
    Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\" } |
    Select-Object -First 1

if (-not $program) {
    Write-Host "MauiProgram.cs not found." -ForegroundColor Red
    exit 2
}

function Strip-CSharpComments([string]$Code) {
    $noBlock = [regex]::Replace($Code, '/\*[\s\S]*?\*/', '')
    return [regex]::Replace($noBlock, '//.*$', '', [System.Text.RegularExpressions.RegexOptions]::Multiline)
}

$programCode = Strip-CSharpComments (Get-Content $program.FullName -Raw)
$files = Get-ChildItem $ProjectRoot -Filter "*.cs" -Recurse -File |
    Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\|\\Tests\\|\\.Tests\\" }

$issuesFound = $false

foreach ($file in $files | Where-Object {
    $_.FullName -match "[\\/]Services[\\/]" -or $_.FullName -match "[\\/]ViewModels[\\/]"
}) {
    $name = [IO.Path]::GetFileNameWithoutExtension($file.Name)

    if ($name -match "^I[A-Z]" -or $name -match "BaseViewModel") {
        continue
    }

    $regPattern = "Services\s*\.\s*Add(Singleton|Transient|Scoped)\s*(<[^>]*\b$([regex]::Escape($name))\b[^>]*>|\([^)]*\b$([regex]::Escape($name))\b)"
    if ($programCode -match $regPattern) {
        Write-Host "[OK] $name is registered in MauiProgram.cs" -ForegroundColor Green
    }
    else {
        $issuesFound = $true
        Write-Host "[MISSING DI] $name is not registered via builder.Services.Add* in MauiProgram.cs" -ForegroundColor Yellow
    }

    if ($file.FullName -match "[\\/]ViewModels[\\/]") {
        $vmCode = Strip-CSharpComments (Get-Content $file.FullName -Raw)
        foreach ($m in [regex]::Matches($vmCode, '\bnew\s+([A-Za-z0-9_]*Service)\s*\(')) {
            $issuesFound = $true
            $svcName = $m.Groups[1].Value
            Write-Host "[DI VIOLATION] $($file.Name) directly instantiates 'new $svcName()'. Inject via constructor instead." -ForegroundColor Red
        }
    }
}

if ($issuesFound) {
    Write-Host "RESULT: CHECK REQUIRED" -ForegroundColor Yellow
    exit 1
}

Write-Host "RESULT: PASS" -ForegroundColor Green
exit 0
