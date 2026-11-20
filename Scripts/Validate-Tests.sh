#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_PATH="$SCRIPT_DIR/Validate-Tests.py"

if [ ! -f "$SCRIPT_PATH" ]; then
  SCRIPT_PATH="$PROJECT_ROOT/.agents/skills/maui-step-guide-author/scripts/validate_tests.py"
fi

for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1 && [ -f "$SCRIPT_PATH" ]; then
    cpath="$(command -v "$candidate")"
    if "$cpath" -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
      "$cpath" "$SCRIPT_PATH" --project-root "$PROJECT_ROOT" "${@:2}"
      exit $?
    fi
  fi
done

MODE_FILE="$PROJECT_ROOT/.agents/MAUI-Agent-Mode.json"
if [ -f "$MODE_FILE" ] && grep -q -i '"includeTests"[[:space:]]*:[[:space:]]*false' "$MODE_FILE" 2>/dev/null; then
  echo "[SKIP] includeTests=false in .agents/MAUI-Agent-Mode.json — unit tests are disabled."
  echo "RESULT: PASS (TESTS DISABLED)"
  exit 0
fi

TEST_CSPROJ="$(find "$PROJECT_ROOT" -type f -name "*.Tests.csproj" -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/.git/*" | head -n 1 || true)"
if [ -z "$TEST_CSPROJ" ]; then
  echo "[FAIL] No *.Tests.csproj found under $PROJECT_ROOT." >&2
  exit 1
fi

if [ ! -s "$PROJECT_ROOT/Learning/Test-Documentation.md" ]; then
  echo "[FAIL] Missing or empty Learning/Test-Documentation.md." >&2
  exit 1
fi

if grep -q -E '<PackageReference[[:space:]]+[^>]*Include="xunit"' "$TEST_CSPROJ" 2>/dev/null; then
  echo "[FAIL] $(basename "$TEST_CSPROJ") references legacy 'xunit' (v2). Must use 'xunit.v3' (latest stable)." >&2
  exit 1
fi

OUT="$(dotnet run --project "$TEST_CSPROJ" 2>&1)" || {
  echo "$OUT" >&2
  echo "[FAIL] xunit.v3 test execution failed." >&2
  exit 1
}

if echo "$OUT" | grep -q -E 'Total:[[:space:]]*[0-9]+,[[:space:]]*Errors:[[:space:]]*[0-9]+,[[:space:]]*Failed:[[:space:]]*[0-9]+'; then
  TOTAL="$(echo "$OUT" | grep -o -E 'Total:[[:space:]]*[0-9]+' | grep -o -E '[0-9]+' | tail -n 1 || echo 0)"
  ERRS="$(echo "$OUT" | grep -o -E 'Errors:[[:space:]]*[0-9]+' | grep -o -E '[0-9]+' | tail -n 1 || echo 0)"
  FAILS="$(echo "$OUT" | grep -o -E 'Failed:[[:space:]]*[0-9]+' | grep -o -E '[0-9]+' | tail -n 1 || echo 0)"
  FAILED=$((ERRS + FAILS))
  PASSED=$((TOTAL - FAILED))
else
  PASSED="$(echo "$OUT" | grep -o -E '(Passed|succeeded):[[:space:]]*[0-9]+' | grep -o -E '[0-9]+' | tail -n 1 || echo 0)"
  FAILED="$(echo "$OUT" | grep -o -E '(Failed|failed):[[:space:]]*[0-9]+' | grep -o -E '[0-9]+' | tail -n 1 || echo 0)"
fi

if [ "${FAILED:-0}" -ne 0 ] || [ "${PASSED:-0}" -lt 1 ]; then
  echo "[FAIL] Unit test gate requires Failed == 0 and Passed >= 1 (Passed: ${PASSED:-0}, Failed: ${FAILED:-0})." >&2
  exit 1
fi

echo "RESULT: PASS (Passed: $PASSED, Failed: $FAILED)"
exit 0
