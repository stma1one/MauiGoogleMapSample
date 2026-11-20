param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectRoot)) {
    Write-Host "Project root not found." -ForegroundColor Red
    exit 2
}

$xamlFiles = Get-ChildItem $ProjectRoot -Filter "*.xaml" -Recurse -File |
    Where-Object { $_.FullName -notmatch "\\bin\\|\\obj\\" }

if (-not $xamlFiles.Count) {
    Write-Host "No XAML files found." -ForegroundColor Red
    exit 2
}

function Strip-XmlComments([string]$XmlText) {
    return [regex]::Replace($XmlText, '<!--[\s\S]*?-->', '')
}

function Is-GlobalResourceFile([string]$FilePath) {
    $name = [IO.Path]::GetFileName($FilePath)
    return ($name -ieq "App.xaml" -or $FilePath -match "[\\/]Resources[\\/]")
}

$globalDefined = @{}
$localDefined = @{}
$duplicates = @()
$references = @()

$patterns = @(
    '\{StaticResource\s+([^\s\}]+)\}',
    '\{DynamicResource\s+([^\s\}]+)\}',
    'BasedOn\s*=\s*"\{StaticResource\s+([^\s\}]+)\}"',
    'BasedOn\s*=\s*"\{DynamicResource\s+([^\s\}]+)\}"'
)

foreach ($file in $xamlFiles) {
    $rawText = Get-Content $file.FullName -Raw
    $text = Strip-XmlComments $rawText
    $isGlobal = Is-GlobalResourceFile $file.FullName
    $localDefined[$file.FullName] = @{}

    foreach ($match in [regex]::Matches($text, 'x:Key\s*=\s*"([^"]+)"')) {
        $key = $match.Groups[1].Value.Trim()
        if ($isGlobal) {
            if ($globalDefined.ContainsKey($key)) {
                $duplicates += [PSCustomObject]@{
                    Key = $key
                    First = $globalDefined[$key]
                    Duplicate = $file.FullName
                }
            }
            else {
                $globalDefined[$key] = $file.FullName
            }
        }
        else {
            if ($localDefined[$file.FullName].ContainsKey($key)) {
                $duplicates += [PSCustomObject]@{
                    Key = $key
                    First = $file.FullName
                    Duplicate = $file.FullName
                }
            }
            else {
                $localDefined[$file.FullName][$key] = $file.FullName
            }
        }
    }

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($text, $pattern)) {
            $references += [PSCustomObject]@{
                Key = $match.Groups[1].Value.Trim()
                File = $file.FullName
            }
        }
    }
}

$missing = $references |
    Where-Object {
        $k = $_.Key
        $f = $_.File
        -not ($globalDefined.ContainsKey($k) -or ($localDefined.ContainsKey($f) -and $localDefined[$f].ContainsKey($k)))
    } |
    Sort-Object Key, File -Unique

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " .NET MAUI XAML STYLE/RESOURCE AUDIT (SCOPED)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "XAML files scanned: $($xamlFiles.Count)"
Write-Host "Global resource keys found: $($globalDefined.Count)"
Write-Host "References found: $($references.Count)"
Write-Host ""

if ($missing.Count) {
    Write-Host "MISSING OR OUT-OF-SCOPE RESOURCE REFERENCES" -ForegroundColor Red
    foreach ($item in $missing) {
        Write-Host "[$($item.Key)]" -ForegroundColor Red
        Write-Host "    $($item.File)"
    }
    Write-Host ""
}

if ($duplicates.Count) {
    Write-Host "DUPLICATE RESOURCE KEYS IN SAME SCOPE" -ForegroundColor Yellow
    foreach ($item in $duplicates) {
        Write-Host "[$($item.Key)]" -ForegroundColor Yellow
        Write-Host "    first:     $($item.First)"
        Write-Host "    duplicate: $($item.Duplicate)"
    }
    Write-Host ""
}

if (-not $missing.Count -and -not $duplicates.Count) {
    Write-Host "RESULT: PASS" -ForegroundColor Green
    exit 0
}

Write-Host "RESULT: CHECK REQUIRED" -ForegroundColor Yellow
exit 1
