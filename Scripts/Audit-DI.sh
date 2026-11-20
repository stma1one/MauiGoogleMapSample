#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

PYTHON_CMD=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON_CMD="$candidate"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Python 3 is required to run Audit-DI." >&2
    exit 2
fi

"$PYTHON_CMD" - "$PROJECT_ROOT" << 'PYEOF'
import re
import sys
from pathlib import Path

project_root = Path(sys.argv[1]).resolve()
programs = [
    p for p in project_root.rglob("MauiProgram.cs")
    if "/bin/" not in p.as_posix() and "/obj/" not in p.as_posix()
]

if not programs:
    print("\033[0;31mMauiProgram.cs not found.\033[0m")
    sys.exit(2)

def strip_comments(code: str) -> str:
    code = re.sub(r"/\*[\s\S]*?\*/", "", code)
    return re.sub(r"//.*$", "", code, flags=re.MULTILINE)

program_code = strip_comments(programs[0].read_text(encoding="utf-8", errors="ignore"))

cs_files = [
    p for p in sorted(project_root.rglob("*.cs"))
    if "/bin/" not in p.as_posix()
    and "/obj/" not in p.as_posix()
    and "/Tests/" not in p.as_posix()
    and ".Tests/" not in p.as_posix()
]

issues_found = False

for file_path in cs_files:
    posix = file_path.as_posix()
    is_service = "/Services/" in posix
    is_vm = "/ViewModels/" in posix
    if not (is_service or is_vm):
        continue

    name = file_path.stem
    if re.match(r"^I[A-Z]", name) or "BaseViewModel" in name:
        continue

    reg_pattern = rf"Services\s*\.\s*Add(?:Singleton|Transient|Scoped)\s*(?:<[^>]*\b{re.escape(name)}\b[^>]*>|\([^)]*\b{re.escape(name)}\b)"
    if re.search(reg_pattern, program_code):
        print(f"\033[0;32m[OK] {name} is registered in MauiProgram.cs\033[0m")
    else:
        issues_found = True
        print(f"\033[0;33m[MISSING DI] {name} is not registered via builder.Services.Add* in MauiProgram.cs\033[0m")

    if is_vm:
        vm_code = strip_comments(file_path.read_text(encoding="utf-8", errors="ignore"))
        for m in re.finditer(r"\bnew\s+([A-Za-z0-9_]*Service)\s*\(", vm_code):
            issues_found = True
            svc = m.group(1)
            print(f"\033[0;31m[DI VIOLATION] {file_path.name} directly instantiates 'new {svc}()'. Inject via constructor instead.\033[0m")

if issues_found:
    print("\033[0;33mRESULT: CHECK REQUIRED\033[0m")
    sys.exit(1)

print("\033[0;32mRESULT: PASS\033[0m")
sys.exit(0)
PYEOF
