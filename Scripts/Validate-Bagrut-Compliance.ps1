param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$SubmissionReady
)
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "Validate-Bagrut-Compliance.py"
$argsList = @("--project-root", $ProjectRoot)
if ($SubmissionReady) {
    $argsList += "--submission-ready"
}

$pyCmd = $null
foreach ($candidate in @("python", "python3")) {
    $cmd = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $pyCmd = $cmd.Source; break }
}
if (-not $pyCmd) {
    Write-Error "Python 3 is required to run Validate-Bagrut-Compliance.py"
    exit 2
}

& $pyCmd $scriptPath @argsList
exit $LASTEXITCODE
