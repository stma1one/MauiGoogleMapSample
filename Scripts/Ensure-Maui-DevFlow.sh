#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DEVFLOW_VERSION="0.1.0-preview.14.26531.2"

PROJECT_ROOT=""
VERSION_OVERRIDE=""
UPGRADE=false
OFFLINE=false
SKIP=false
SKIP_CLI=false
REMOVE=false
DRY_RUN=false
FORWARD_ARGS=()

if [[ $# -ge 1 && "${1:-}" != --* ]]; then
  PROJECT_ROOT="$1"
  shift
else
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --version)
      VERSION_OVERRIDE="$2"
      FORWARD_ARGS+=("--version" "$2")
      shift 2
      ;;
    --upgrade)
      UPGRADE=true
      FORWARD_ARGS+=("--upgrade")
      shift
      ;;
    --offline)
      OFFLINE=true
      FORWARD_ARGS+=("--offline")
      shift
      ;;
    --skip|--skip-devflow|--no-devflow)
      SKIP=true
      FORWARD_ARGS+=("--skip")
      shift
      ;;
    --skip-cli|--no-cli|--skip-devflow-cli)
      SKIP_CLI=true
      FORWARD_ARGS+=("--skip-cli")
      shift
      ;;
    --remove|--disable)
      REMOVE=true
      FORWARD_ARGS+=("--remove")
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      FORWARD_ARGS+=("--dry-run")
      shift
      ;;
    *)
      FORWARD_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "$SKIP" == true ]] || [[ "${MAUI_SKIP_DEVFLOW:-}" =~ ^(1|true|yes|TRUE|YES)$ ]]; then
  echo "[SKIP] MAUI DevFlow automatic injection skipped by user option (--skip-devflow / MAUI_SKIP_DEVFLOW)."
  exit 0
fi

find_working_python() {
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      local cpath
      cpath="$(command -v "$candidate")"
      if "$cpath" -c "import sys; raise SystemExit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
        echo "$cpath"
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

PYTHON_BIN=""
if PYTHON_BIN="$(find_working_python)"; then
  :
elif PYTHON_BIN="$(try_install_python)"; then
  :
else
  PYTHON_BIN=""
fi

if [[ -n "$PYTHON_BIN" && -f "$SCRIPT_DIR/Ensure-Maui-DevFlow.py" ]]; then
  "$PYTHON_BIN" "$SCRIPT_DIR/Ensure-Maui-DevFlow.py" --project-root "$PROJECT_ROOT" "${FORWARD_ARGS[@]}"
  exit $?
fi

# Native Bash/awk fallback when Python 3 is unavailable
echo "[INFO] Running native Bash DevFlow provisioning (Python 3 not available)."
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "[ERROR] Project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi
RESOLVED_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

mapfile -t CSPROJ_CANDIDATES < <(find "$RESOLVED_ROOT" -type f -name "*.csproj" \
  -not -path "*/.git/*" -not -path "*/.vs/*" -not -path "*/.idea/*" \
  -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/node_modules/*" \
  -not -path "*/.agents/*" -not -path "*/.claude/*" \
  -not -path "*/companion-skills/*" -not -path "*/skills/*" -not -path "*/project-template/*" | sort)

MAUI_CSPROJS=()
for csproj in "${CSPROJ_CANDIDATES[@]}"; do
  if [[ -f "$csproj" ]] && grep -q -E -i '<UseMaui>[[:space:]]*true[[:space:]]*</UseMaui>|Microsoft\.Maui\.Controls' "$csproj" 2>/dev/null; then
    MAUI_CSPROJS+=("$csproj")
  fi
done

if [[ ${#MAUI_CSPROJS[@]} -eq 0 ]]; then
  echo "[INFO] No .NET MAUI .csproj detected under $RESOLVED_ROOT; skipping DevFlow project injection."
  exit 0
fi

mapfile -t MAUI_PROGRAMS < <(find "$RESOLVED_ROOT" -type f -name "MauiProgram.cs" \
  -not -path "*/.git/*" -not -path "*/.vs/*" -not -path "*/.idea/*" \
  -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/node_modules/*" \
  -not -path "*/.agents/*" -not -path "*/.claude/*" \
  -not -path "*/companion-skills/*" -not -path "*/skills/*" -not -path "*/project-template/*" | sort)

if [[ "$REMOVE" == true ]]; then
  for csproj in "${MAUI_CSPROJS[@]}"; do
    base_name="$(basename "$csproj")"
    if grep -q "Microsoft.Maui.DevFlow.Agent" "$csproj" 2>/dev/null; then
      if [[ "$DRY_RUN" == false ]]; then
        awk '
          /<ItemGroup[^>]*Condition[^>]*Debug[^>]*>/ { in_dbg=1; buf=$0; next }
          in_dbg {
            buf = buf "\n" $0
            if ($0 ~ /<\/ItemGroup>/) {
              in_dbg=0
              if (buf !~ /Microsoft\.Maui\.DevFlow\.Agent/) print buf
            }
            next
          }
          /Microsoft\.Maui\.DevFlow\.Agent/ { next }
          { print }
        ' "$csproj" > "$csproj.tmp" && mv "$csproj.tmp" "$csproj"
      fi
      echo "[REMOVED] Removed Microsoft.Maui.DevFlow.Agent from $base_name"
    else
      echo "[OK] Microsoft.Maui.DevFlow.Agent is not present in $base_name"
    fi
  done
  for mp in "${MAUI_PROGRAMS[@]}"; do
    base_name="$(basename "$mp")"
    if grep -q -E "AddMauiDevFlowAgent|Microsoft\.Maui\.DevFlow\.Agent" "$mp" 2>/dev/null; then
      if [[ "$DRY_RUN" == false ]]; then
        awk '
          /^#if[ \t]+DEBUG[ \t]*$/ { in_if=1; buf=$0; next }
          in_if {
            buf = buf "\n" $0
            if ($0 ~ /^#endif[ \t]*$/) {
              in_if=0
              if (buf !~ /Microsoft\.Maui\.DevFlow\.Agent/ && buf !~ /AddMauiDevFlowAgent/) print buf
            }
            next
          }
          { print }
        ' "$mp" > "$mp.tmp" && mv "$mp.tmp" "$mp"
      fi
      echo "[REMOVED] Removed DevFlow registration from $base_name"
    fi
  done
  exit 0
fi

TARGET_VER="${VERSION_OVERRIDE:-$DEFAULT_DEVFLOW_VERSION}"
ANY_ACTIVE=false

for csproj in "${MAUI_CSPROJS[@]}"; do
  base_name="$(basename "$csproj")"
  TFM_RAW="$(grep -o -E -i '<TargetFrameworks?[^>]*>[^<]+</TargetFrameworks?>' "$csproj" | sed -E 's/<[^>]+>//g' | tr '\n' ';' || true)"
  IFS=';' read -r -a TFM_ARR <<< "$TFM_RAW"
  TFM_LIST=()
  SUPPORTED_COUNT=0
  UNSUPPORTED_COUNT=0
  for tok in "${TFM_ARR[@]}"; do
    cleaned="$(echo "$tok" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [[ -z "$cleaned" || "$cleaned" == "\$("* ]]; then
      continue
    fi
    TFM_LIST+=("$cleaned")
    if [[ "$cleaned" =~ ^[nN][eE][tT]1[01]\.0($|[-.]) ]]; then
      SUPPORTED_COUNT=$((SUPPORTED_COUNT + 1))
    else
      UNSUPPORTED_COUNT=$((UNSUPPORTED_COUNT + 1))
    fi
  done

  TFM_SUMMARY="$(IFS=';'; echo "${TFM_LIST[*]:-unspecified TargetFramework}")"
  if [[ $UNSUPPORTED_COUNT -gt 0 || $SUPPORTED_COUNT -eq 0 ]]; then
    echo "[SKIP] $base_name targets '$TFM_SUMMARY'; Microsoft.Maui.DevFlow.Agent requires net10.0 or net11.0. Skipping DevFlow injection."
    continue
  fi

  if grep -q "Microsoft.Maui.DevFlow.Agent" "$csproj" 2>/dev/null; then
    echo "[OK] DevFlow PackageReference already present in $base_name"
    ANY_ACTIVE=true
    continue
  fi

  if ! grep -q "</Project>" "$csproj" 2>/dev/null; then
    echo "[WARN] Could not locate </Project> in $base_name; skipped."
    continue
  fi

  if [[ "$DRY_RUN" == false ]]; then
    awk -v ver="$TARGET_VER" '
      /<\/Project>/ {
        print ""
        print "  <ItemGroup Condition=\"\x27$(Configuration)\x27 == \x27Debug\x27\">"
        print "    <PackageReference Include=\"Microsoft.Maui.DevFlow.Agent\" Version=\"" ver "\" />"
        print "  </ItemGroup>"
      }
      { print }
    ' "$csproj" > "$csproj.tmp" && mv "$csproj.tmp" "$csproj"
  fi
  echo "[INJECTED] Added Debug-only Microsoft.Maui.DevFlow.Agent ($TARGET_VER) to $base_name"
  ANY_ACTIVE=true
done

if [[ "$ANY_ACTIVE" == true ]]; then
  if [[ "$SKIP_CLI" == true ]] || [[ "$DRY_RUN" == true ]] || [[ "$OFFLINE" == true ]] || [[ "${MAUI_SKIP_DEVFLOW_CLI:-}" =~ ^(1|true|yes|TRUE|YES)$ ]]; then
    echo "[SKIP] Global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli) check skipped (--skip-cli / offline / dry-run)."
  elif ! command -v maui >/dev/null 2>&1; then
    if command -v dotnet >/dev/null 2>&1; then
      echo "[INFO] Installing global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)..."
      dotnet tool install -g Microsoft.Maui.Cli --prerelease || echo "[WARN] Global Microsoft.Maui.Cli installation returned non-zero (pass --skip-cli if working without global permissions)."
    else
      echo "[WARN] 'dotnet' CLI not found; skipping global Microsoft.Maui.Cli installation."
    fi
  elif [[ "$UPGRADE" == true ]] && command -v dotnet >/dev/null 2>&1; then
    echo "[INFO] Updating global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)..."
    dotnet tool update -g Microsoft.Maui.Cli --prerelease || true
  else
    echo "[OK] Global .NET MAUI DevFlow CLI ('maui') is already installed."
  fi

  for mp in "${MAUI_PROGRAMS[@]}"; do
    base_name="$(basename "$mp")"
    if grep -q "AddMauiDevFlowAgent" "$mp" 2>/dev/null; then
      echo "[OK] AddMauiDevFlowAgent() already present in $base_name"
      continue
    fi
    if ! grep -q -E "return[[:space:]]+builder\.Build\([[:space:]]*\)[[:space:]]*;" "$mp" 2>/dev/null; then
      echo "[WARN] Could not locate '\''return builder.Build();'\'' in $base_name; skipped."
      continue
    fi
    if [[ "$DRY_RUN" == false ]]; then
      awk '
        BEGIN { added_using=0 }
        !added_using && /^(global[ \t]+)?using[ \t]+[^;]+;[ \t]*$/ {
          print
          next
        }
        !added_using && !/^(global[ \t]+)?using[ \t]+[^;]+;[ \t]*$/ {
          print "#if DEBUG"
          print "using Microsoft.Maui.DevFlow.Agent;"
          print "#endif"
          added_using=1
        }
        /^[ \t]*return[ \t]+builder\.Build\([ \t]*\)[ \t]*;/ {
          match($0, /^[ \t]*/)
          indent = substr($0, RSTART, RLENGTH)
          print "#if DEBUG"
          print indent "builder.AddMauiDevFlowAgent();"
          print "#endif"
        }
        { print }
      ' "$mp" > "$mp.tmp" && mv "$mp.tmp" "$mp"
    fi
    echo "[INJECTED] Added #if DEBUG builder.AddMauiDevFlowAgent() to $base_name"
  done
fi
exit 0
