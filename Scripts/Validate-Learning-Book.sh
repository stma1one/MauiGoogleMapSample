#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/Validate-Learning-Book.py"

if [ ! -f "$SCRIPT_PATH" ]; then
    SCRIPT_PATH="$PROJECT_ROOT/.agents/skills/maui-step-guide-author/scripts/validate_learning_book.py"
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Could not find validate_learning_book.py." >&2
    exit 1
fi

PYTHON_CMD=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON_CMD="$candidate"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Python 3 is required to validate the learning book." >&2
    exit 1
fi

"$PYTHON_CMD" "$SCRIPT_PATH" \
    --html "$PROJECT_ROOT/Learning/MAUI-Learning-Book.html" \
    --pdf "$PROJECT_ROOT/Learning/MAUI-Learning-Book.pdf" \
    --report "$PROJECT_ROOT/Learning/MAUI-Learning-Book.validation.json" \
    --project-root "$PROJECT_ROOT" \
    "${@:2}"
