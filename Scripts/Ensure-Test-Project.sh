#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1; then
    cpath="$(command -v "$candidate")"
    if "$cpath" -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
      "$cpath" "$SCRIPT_DIR/Ensure-Test-Project.py" --project-root "$PROJECT_ROOT" "${@:2}"
      exit $?
    fi
  fi
done

echo "[INFO] Python 3 not available; skipping Ensure-Test-Project.py."
exit 0
