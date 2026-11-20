#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

CSPROJ=$(find "$PROJECT_ROOT" -type f -name "*.csproj" -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/Tests/*" -not -path "*.Tests/*" | head -n 1)

if [ -z "$CSPROJ" ]; then
    echo -e "\033[0;31mNo MAUI app .csproj found.\033[0m"
    exit 2
fi

TFM=$(grep -o -E '<TargetFrameworks?>[^<]+' "$CSPROJ" | sed -E 's/<TargetFrameworks?>[[:space:]]*//' | head -n 1 || true)

echo "Project: $CSPROJ"
echo "Target framework: $TFM"

if [[ ! "$TFM" =~ net(8|9|10|11)\.0 ]]; then
    echo -e "\033[0;31mERROR: TargetFramework '$TFM' is not a supported modern .NET MAUI target (net8.0, net9.0, net10.0, or net11.0).\033[0m"
    echo -e "\033[0;33mRESULT: CHECK REQUIRED\033[0m"
    exit 1
fi

if [[ "$TFM" =~ net11\.0 ]]; then
    echo -e "\033[0;33mNOTICE: .NET 11 MAUI is preview. Avoid preview-only APIs unless required.\033[0m"
else
    echo -e "\033[0;32mTarget framework verified ($TFM).\033[0m"
fi

# Verify NuGet PackageReferences across all .csproj files (enforce xunit.v3 and latest Stable versions)
PYTHON_BIN=""
for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        cpath="$(command -v "$candidate")"
        if "$cpath" -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
            PYTHON_BIN="$cpath"
            break
        fi
    fi
done

if [ -n "$PYTHON_BIN" ]; then
    if ! "$PYTHON_BIN" - "$PROJECT_ROOT" <<'PY'
import json, pathlib, re, sys, urllib.request

root = pathlib.Path(sys.argv[1]).resolve()
excluded = {".git", ".vs", "bin", "obj", ".agents", "project-template", "companion-skills", "skills"}
baselines = {
    "google.genai": "2.2.0",
    "xunit.v3": "4.0.3",
    "xunit.runner.visualstudio": "4.0.1",
    "microsoft.net.test.sdk": "18.12.0",
    "coverlet.collector": "10.1.1",
    "sqlite-net-pcl": "1.11.285",
    "sqlitepclraw.bundle_green": "2.1.11",
    "sqlitenetextensions": "2.1.0",
    "sqlitenetextensions.async": "2.1.0",
}
preview_allowed = {"microsoft.maui.devflow.agent", "microsoft.maui.devflow"}

def ver_key(v: str):
    clean = v.split("-")[0].strip()
    nums = [int(x) for x in re.findall(r"\d+", clean)]
    return tuple(nums + [0] * (4 - len(nums)))

def get_latest_stable(pkg_id: str) -> str:
    low = pkg_id.lower()
    fb = baselines.get(low, "")
    try:
        req = urllib.request.Request(
            f"https://api.nuget.org/v3-flatcontainer/{low}/index.json",
            headers={"User-Agent": "maui-k12-baton-workflow/1.4.1"},
        )
        with urllib.request.urlopen(req, timeout=2.5) as resp:
            data = json.loads(resp.read().decode("utf-8", errors="ignore"))
            stable = [str(v) for v in data.get("versions", []) if isinstance(v, str) and "-" not in v and "*" not in v]
            if stable:
                return stable[-1]
    except Exception:
        pass
    return fb

issues = 0
for csproj in sorted(root.rglob("*.csproj")):
    if any(p in excluded for p in csproj.relative_to(root).parts):
        continue
    text = csproj.read_text(encoding="utf-8", errors="ignore")
    for m in re.finditer(r'<PackageReference\s+[^>]*Include\s*=\s*"([^"]+)"[^>]*Version\s*=\s*"([^"]+)"', text, re.IGNORECASE):
        pkg_id, pkg_ver = m.group(1).strip(), m.group(2).strip()
        if pkg_ver.startswith("$("):
            continue
        low = pkg_id.lower()
        if low == "xunit":
            latest_xv3 = get_latest_stable("xunit.v3")
            print(f"\033[0;31m[LEGACY NUGET] {csproj.name}: Package 'xunit' ({pkg_ver}) is legacy xUnit v2. Must use 'xunit.v3' (latest stable: {latest_xv3}).\033[0m")
            issues += 1
            continue
        if low in preview_allowed:
            continue
        latest_stable = get_latest_stable(pkg_id)
        if "-" in pkg_ver and latest_stable:
            print(f"\033[0;31m[NON-STABLE NUGET] {csproj.name}: Package '{pkg_id}' uses prerelease '{pkg_ver}'. Must use latest stable '{latest_stable}'.\033[0m")
            issues += 1
            continue
        if latest_stable and ver_key(pkg_ver) < ver_key(latest_stable):
            print(f"\033[0;31m[OUTDATED NUGET] {csproj.name}: Package '{pkg_id}' is at '{pkg_ver}', older than latest stable '{latest_stable}'.\033[0m")
            issues += 1
        else:
            print(f"\033[0;32m[OK] {csproj.name}: Package '{pkg_id}' is at latest stable version ({pkg_ver}).\033[0m")

sys.exit(1 if issues else 0)
PY
    then
        echo -e "\033[0;33mRESULT: CHECK REQUIRED (All NuGet packages must use the latest Stable release and xunit.v3 for unit tests).\033[0m"
        exit 1
    fi
fi

echo -e "\033[0;32mRESULT: PASS\033[0m"
exit 0
