#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
INSTALL_MISSING="${2:-}"

if [ -n "$INSTALL_MISSING" ] && [ "$INSTALL_MISSING" != "--install-missing" ]; then
    echo "Usage: ./Scripts/Setup-Learning-Book.sh [project-root] [--install-missing]" >&2
    exit 1
fi

find_working_python() {
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            local candidate_path
            candidate_path="$(command -v "$candidate")"
            if "$candidate_path" -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
                echo "$candidate_path"
                return 0
            fi
        fi
    done
    return 1
}

try_install_python() {
    if [[ "${MAUI_NO_PYTHON_INSTALL:-}" =~ ^(1|true|yes|TRUE|YES)$ ]]; then
        return 1
    fi
    echo "[INFO] Python 3 not found. Attempting automatic installation..." >&2
    if command -v brew >/dev/null 2>&1; then
        brew install python3 >/dev/null 2>&1 || true
    elif command -v apt-get >/dev/null 2>&1 && { [[ "${EUID:-$(id -u)}" -eq 0 ]] || sudo -n true 2>/dev/null; }; then
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
            (apt-get update -qq && apt-get install -y -qq python3) >/dev/null 2>&1 || true
        else
            (sudo -n apt-get update -qq && sudo -n apt-get install -y -qq python3) >/dev/null 2>&1 || true
        fi
    elif command -v dnf >/dev/null 2>&1 && { [[ "${EUID:-$(id -u)}" -eq 0 ]] || sudo -n true 2>/dev/null; }; then
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
            dnf install -y -q python3 >/dev/null 2>&1 || true
        else
            sudo -n dnf install -y -q python3 >/dev/null 2>&1 || true
        fi
    elif command -v apk >/dev/null 2>&1 && [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        apk add --no-cache python3 >/dev/null 2>&1 || true
    elif command -v winget.exe >/dev/null 2>&1; then
        winget.exe install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent >/dev/null 2>&1 || true
    fi
    find_working_python
}

PYTHON_COMMAND=""
if PYTHON_COMMAND="$(find_working_python)"; then
    :
elif PYTHON_COMMAND="$(try_install_python)"; then
    :
else
    PYTHON_COMMAND=""
fi

probe_prerequisites() {
    "$PYTHON_COMMAND" "$SCRIPT_DIR/Check-Learning-Book-Prerequisites.py"
}

READY=false
if [ -n "$PYTHON_COMMAND" ]; then
    if PROBE_OUTPUT="$(probe_prerequisites 2>&1)"; then
        READY=true
    else
        printf '%s\n' "$PROBE_OUTPUT"
    fi
else
    echo "[WARN] Python 3 is not installed and could not be auto-installed. MAUI project setup will continue without Python."
fi

if [ "$READY" = true ]; then
    echo "Learning-book prerequisites are already available. No downloads were performed."
    exit 0
fi

echo "Learning-book generation needs the declared Python packages and the Playwright Chromium runtime."
echo "Installing them may download browser binaries, use disk space, and change the selected Python environment."

if [ "$INSTALL_MISSING" != "--install-missing" ]; then
    echo "No downloads were performed. Run ./Scripts/Setup-Learning-Book.sh \"$PROJECT_ROOT\" --install-missing when you are ready."
    exit 0
fi

if [ -z "$PYTHON_COMMAND" ]; then
    echo "[WARN] Python 3 is still unavailable; skipping optional learning-book dependency installation so MAUI project setup succeeds."
    exit 0
fi

REQUIREMENTS_FILE="$PROJECT_ROOT/Scripts/Learning-Book-Requirements.txt"
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "[WARN] Cannot find the learning-book requirements file: $REQUIREMENTS_FILE"
    exit 0
fi

echo "Installing missing learning-book prerequisites..."
if ! "$PYTHON_COMMAND" -m pip install -r "$REQUIREMENTS_FILE"; then
    echo "[WARN] Python dependency installation did not complete; continuing."
    exit 0
fi

if ! "$PYTHON_COMMAND" -m playwright install chromium; then
    echo "[WARN] Playwright Chromium installation did not complete; continuing."
    exit 0
fi

if ! PROBE_OUTPUT="$(probe_prerequisites 2>&1)"; then
    printf '%s\n' "$PROBE_OUTPUT"
    echo "[WARN] Learning-book prerequisites are still incomplete after installation."
    exit 0
fi

echo "Learning-book prerequisites are ready."
