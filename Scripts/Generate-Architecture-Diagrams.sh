#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/Generate-Architecture-Diagrams.py"

PYTHON_CMD=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON_CMD="$candidate"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Python 3 is required to run Generate-Architecture-Diagrams.py." >&2
    exit 2
fi

"$PYTHON_CMD" "$SCRIPT_PATH" --project-root "$PROJECT_ROOT" "${@:2}"
