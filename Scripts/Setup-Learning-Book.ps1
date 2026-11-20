# Setup-Learning-Book.ps1
# Checks the local Python and Chromium prerequisites for learning-book generation.
# Attempts to install Python 3 automatically when missing, and never fails MAUI project setup if Python is unavailable.

param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$InstallMissing
)

$ErrorActionPreference = "Stop"

function Get-PythonCommand {
    foreach ($candidate in @("python3", "python", "py")) {
        $command = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            try {
                if ($candidate -eq "py") {
                    & $command.Source -3 -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" *> $null
                    if ($LASTEXITCODE -eq 0) { return $command.Source }
                } else {
                    & $command.Source -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" *> $null
                    if ($LASTEXITCODE -eq 0) { return $command.Source }
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
            if ($LASTEXITCODE -eq 0) { return $exe.FullName }
        } catch {}
    }

    return $null
}

function Try-InstallPythonCommand {
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
    return (Get-PythonCommand)
}

function Test-LearningBookPrerequisites {
    param([string]$PythonCommand)

    $probeScript = Join-Path $PSScriptRoot "Check-Learning-Book-Prerequisites.py"
    if (-not (Test-Path $probeScript)) {
        Write-Host "Missing learning-book prerequisite checker: $probeScript" -ForegroundColor Yellow
        return $false
    }

    $probeOutput = @(& $PythonCommand $probeScript 2>&1)
    $probeExitCode = $LASTEXITCODE

    foreach ($message in $probeOutput) {
        if ($message) {
            Write-Host $message -ForegroundColor Yellow
        }
    }

    return $probeExitCode -eq 0
}

$requirementsFile = Join-Path $ProjectRoot "Scripts\Learning-Book-Requirements.txt"
if (-not (Test-Path $requirementsFile)) {
    $requirementsFile = Join-Path $PSScriptRoot "Learning-Book-Requirements.txt"
}
$pythonCommand = Get-PythonCommand
if (-not $pythonCommand) {
    $pythonCommand = Try-InstallPythonCommand
}
$prerequisitesReady = $false

if ($pythonCommand) {
    $prerequisitesReady = Test-LearningBookPrerequisites -PythonCommand $pythonCommand
} else {
    Write-Host "[WARN] Python 3 is not installed and could not be auto-installed. MAUI project setup will continue without Python." -ForegroundColor Yellow
}

if ($prerequisitesReady) {
    Write-Host "Learning-book prerequisites are already available. No downloads were performed." -ForegroundColor Green
    return
}

Write-Host "Learning-book generation needs the declared Python packages and the Playwright Chromium runtime." -ForegroundColor Yellow
Write-Host "Installing them may download browser binaries, use disk space, and change the selected Python environment." -ForegroundColor Yellow

if (-not $InstallMissing) {
    Write-Host "No downloads were performed. Run .\Scripts\Setup-Learning-Book.ps1 -InstallMissing when you are ready." -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    return
}

if (-not $pythonCommand) {
    Write-Host "[WARN] Python 3 is still unavailable; skipping optional learning-book dependency installation so MAUI project setup succeeds." -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    return
}

if (-not (Test-Path $requirementsFile)) {
    Write-Host "[WARN] Cannot find the learning-book requirements file: $requirementsFile" -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    return
}

Write-Host "Installing missing learning-book prerequisites..." -ForegroundColor Cyan
& $pythonCommand -m pip install -r $requirementsFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Python dependency installation exited with code $LASTEXITCODE." -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    return
}

& $pythonCommand -m playwright install chromium
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Playwright Chromium installation exited with code $LASTEXITCODE." -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    return
}

if (-not (Test-LearningBookPrerequisites -PythonCommand $pythonCommand)) {
    Write-Host "[WARN] Learning-book prerequisites are still incomplete after installation." -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    return
}

Write-Host "Learning-book prerequisites are ready." -ForegroundColor Green
