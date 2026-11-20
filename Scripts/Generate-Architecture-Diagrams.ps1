param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "Generate-Architecture-Diagrams.py"
$pyCmd = $null
foreach ($candidate in @("python", "python3")) {
    $cmd = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $pyCmd = $cmd.Source; break }
}
if (-not $pyCmd) {
    Write-Error "Python 3 is required to run Generate-Architecture-Diagrams.py"
    exit 2
}

& $pyCmd $scriptPath --project-root $ProjectRoot
exit $LASTEXITCODE
