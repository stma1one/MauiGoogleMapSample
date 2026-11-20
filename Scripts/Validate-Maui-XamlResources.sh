#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ ! -d "$PROJECT_ROOT" ]; then
    echo -e "\033[0;31mProject root not found: $PROJECT_ROOT\033[0m"
    exit 2
fi

PYTHON_CMD=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON_CMD="$candidate"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "Python 3 is required to run scoped XAML resource validation." >&2
    exit 2
fi

"$PYTHON_CMD" - "$PROJECT_ROOT" << 'PYEOF'
import os
import re
import sys
from pathlib import Path

project_root = Path(sys.argv[1]).resolve()
xaml_files = [
    p for p in sorted(project_root.rglob("*.xaml"))
    if "/bin/" not in p.as_posix() and "/obj/" not in p.as_posix()
]

if not xaml_files:
    print("\033[0;31mNo XAML files found.\033[0m")
    sys.exit(2)

def is_global_resource_file(path: Path) -> bool:
    posix = path.as_posix()
    return path.name.lower() == "app.xaml" or "/Resources/" in posix or "/resources/" in posix

global_defined: dict[str, str] = {}
local_defined: dict[str, dict[str, str]] = {}
duplicates: list[tuple[str, str, str]] = []
references: list[tuple[str, str]] = []

ref_patterns = [
    re.compile(r"\{StaticResource\s+([^\s\}]+)\}"),
    re.compile(r"\{DynamicResource\s+([^\s\}]+)\}"),
]

for file_path in xaml_files:
    raw = file_path.read_text(encoding="utf-8", errors="ignore")
    cleaned = re.sub(r"<!--[\s\S]*?-->", "", raw)
    f_str = str(file_path)
    is_global = is_global_resource_file(file_path)
    local_defined[f_str] = {}

    for m in re.finditer(r'x:Key\s*=\s*"([^"]+)"', cleaned):
        key = m.group(1).strip()
        if is_global:
            if key in global_defined:
                duplicates.append((key, global_defined[key], f_str))
            else:
                global_defined[key] = f_str
        else:
            if key in local_defined[f_str]:
                duplicates.append((key, f_str, f_str))
            else:
                local_defined[f_str][key] = f_str

    for pat in ref_patterns:
        for m in pat.finditer(cleaned):
            references.append((m.group(1).strip(), f_str))

missing = sorted(
    {
        (key, f_str)
        for key, f_str in references
        if key not in global_defined and key not in local_defined.get(f_str, {})
    }
)

print("\033[0;36m=================================================\033[0m")
print("\033[0;36m .NET MAUI XAML STYLE/RESOURCE AUDIT (SCOPED)\033[0m")
print("\033[0;36m=================================================\033[0m")
print(f"XAML files scanned: {len(xaml_files)}")
print(f"Global resource keys found: {len(global_defined)}")
print(f"References found: {len(references)}")
print("")

if missing:
    print("\033[0;31mMISSING OR OUT-OF-SCOPE RESOURCE REFERENCES\033[0m")
    for key, f_str in missing:
        print(f"\033[0;31m[{key}]\033[0m")
        print(f"    {f_str}")
    print("")

if duplicates:
    print("\033[0;33mDUPLICATE RESOURCE KEYS IN SAME SCOPE\033[0m")
    for key, first, dup in duplicates:
        print(f"\033[0;33m[{key}]\033[0m")
        print(f"    first:     {first}")
        print(f"    duplicate: {dup}")
    print("")

if not missing and not duplicates:
    print("\033[0;32mRESULT: PASS\033[0m")
    sys.exit(0)

print("\033[0;33mRESULT: CHECK REQUIRED\033[0m")
sys.exit(1)
PYEOF
