#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FOUND=0

SOURCE_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.cs" -o -name "*.xaml" \) -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/Scripts/*" -not -path "*/.git/*" || true)
if [ -z "$SOURCE_FILES" ]; then
    echo -e "\033[0;31mNo source files found.\033[0m"
    exit 2
fi

echo "Checking for obsolete MAUI APIs, disallowed MVVM shortcuts, and DevFlow Release leaks..."

check_rule() {
    local pattern="$1"
    local name="$2"
    local replacement="$3"
    local source="$4"

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            while IFS=: read -r line_num line_content; do
                if [ -n "$line_num" ]; then
                    FOUND=1
                    echo -e "\033[0;33m[REVIEW] $name -> $file:$line_num\033[0m"
                    echo "  Replacement: $replacement"
                    echo "  Reference:   $source"
                fi
            done < <(grep -n -E "$pattern" "$file" 2>/dev/null || true)
        fi
    done <<< "$SOURCE_FILES"
}

check_rule '(\bPage\.IsBusy\b|\bthis\.IsBusy[[:space:]]*=|\bIsBusy[[:space:]]*=[[:space:]]*(true|false)\b|\bIsBusy[[:space:]]*=[[:space:]]*"\{Binding)' \
    'Page.IsBusy / IsBusy' \
    'Use ViewModel IsLoading property + ActivityIndicator in XAML' \
    'https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10?view=net-maui-10.0'

check_rule '\bDisplay(Alert|ActionSheet|Prompt)[[:space:]]*\(' \
    'Synchronous-named DisplayAlert / DisplayActionSheet / DisplayPrompt' \
    'Use DisplayAlertAsync, DisplayActionSheetAsync, or DisplayPromptAsync in .NET 10 MAUI' \
    'https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10?view=net-maui-10.0'

check_rule '\b(FadeTo|ScaleTo|TranslateTo|RotateTo|RelRotateTo|RelScaleTo)[[:space:]]*\(' \
    'Legacy non-Async Animation API (FadeTo/ScaleTo/TranslateTo/RotateTo)' \
    'Use FadeToAsync, ScaleToAsync, TranslateToAsync, or RotateToAsync' \
    'https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10?view=net-maui-10.0'

check_rule '(<[[:space:]]*ListView\b|\bnew[[:space:]]+ListView\b|<[[:space:]]*TableView\b|\bnew[[:space:]]+TableView\b)' \
    'ListView / TableView' \
    'Use CollectionView or VerticalStackLayout with BindableLayout' \
    'https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10?view=net-maui-10.0'

check_rule '\bMessagingCenter\b' \
    'MessagingCenter (Obsolete)' \
    'Use direct ViewModel/Service coordination, C# events, or WeakReferenceMessenger (CommunityToolkit.Mvvm.Messaging)' \
    'https://learn.microsoft.com/en-us/dotnet/maui/whats-new/dotnet-10?view=net-maui-10.0'

check_rule '\bDevice\.(BeginInvokeOnMainThread|StartTimer)\b' \
    'Device.BeginInvokeOnMainThread / Device.StartTimer (Obsolete)' \
    'Use MainThread.BeginInvokeOnMainThread or IDispatcher' \
    'https://learn.microsoft.com/en-us/dotnet/maui/platform-integration/appmodel/main-thread'

check_rule '(\[ObservableProperty\]|\[RelayCommand\]|\[NotifyCanExecuteChangedFor|\[NotifyPropertyChangedFor|:[[:space:]]*ObservableObject\b|:[[:space:]]*ObservableValidator\b)' \
    'MVVM source generators / base classes ([ObservableProperty], [RelayCommand], ObservableObject)' \
    'Use explicit Vanilla C# INotifyPropertyChanged properties and ICommand/Command in K12 projects' \
    'MAUI Specialist Guardrails - Vanilla C# MVVM Policy'

check_rule '\bnew[[:space:]]+Client[[:space:]]*\([^)]*vertexai[[:space:]]*:[[:space:]]*true' \
    'Google.GenAI Client with vertexai: true on mobile MAUI' \
    'Use new Client(apiKey: apiKey) with Gemini Developer API on .NET MAUI Android/iOS (Vertex AI ADC is not supported on mobile devices)' \
    'https://googleapis.github.io/dotnet-genai/'

check_rule 'AIzaSy[A-Za-z0-9_-]{33}' \
    'Hardcoded Google Gemini API Key in source file' \
    'Load the API key from SecureStorage, user settings, or an uncommitted local configuration file' \
    'https://googleapis.github.io/dotnet-genai/'

# Check Microsoft.Maui.DevFlow Debug-only isolation in .csproj and MauiProgram.cs
# Uses Python when available, and a built-in POSIX awk validator when Python is absent (never skips silently!)
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
import pathlib, re, sys, xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1]).resolve()
excluded = {".git", ".vs", "bin", "obj", "Scripts", ".agents"}
leaks = []


def is_strict_debug_msbuild_cond(cond: str) -> bool:
    if not cond or not cond.strip():
        return False
    t = cond.strip()
    if "!=" in t or "!" in t or re.search(r"\bOr\b", t, re.IGNORECASE) or re.search(r"Release", t, re.IGNORECASE):
        return False
    return bool(re.search(r"""['"]?\$\(Configuration\)['"]?\s*==\s*['"]Debug['"]""", t, re.IGNORECASE))


def has_negated_or_wider_cond(cond: str) -> bool:
    if not cond or not cond.strip():
        return False
    return bool("!=" in cond or "!" in cond or re.search(r"\bOr\b", cond, re.IGNORECASE) or re.search(r"Release", cond, re.IGNORECASE))


def is_strict_debug_if_expr(expr: str) -> bool:
    clean = re.sub(r"//.*$|/\*.*?\*/", "", expr).strip()
    if not clean:
        return False
    if "!" in clean or "||" in clean or re.search(r"\b(RELEASE|false|0)\b", clean):
        return False
    parts = clean.split("&&")
    has_debug = False
    for part in parts:
        tok = part.strip()
        while tok.startswith("(") and tok.endswith(")"):
            tok = tok[1:-1].strip()
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", tok):
            return False
        if tok == "DEBUG":
            has_debug = True
    return has_debug


for csproj in sorted(root.rglob("*.csproj")):
    if any(p in excluded for p in csproj.relative_to(root).parts):
        continue
    text = csproj.read_text(encoding="utf-8", errors="ignore")
    if "Microsoft.Maui.DevFlow" not in text:
        continue
    try:
        tree = ET.fromstring(text)
        matched_nodes = 0
        for parent in tree.iter():
            parent_cond = parent.attrib.get("Condition", "")
            for child in list(parent):
                tag = child.tag.split("}")[-1]
                if tag == "PackageReference" and "Microsoft.Maui.DevFlow" in child.attrib.get("Include", ""):
                    matched_nodes += 1
                    item_cond = child.attrib.get("Condition", "")
                    valid_debug = (
                        (is_strict_debug_msbuild_cond(item_cond) or is_strict_debug_msbuild_cond(parent_cond))
                        and not has_negated_or_wider_cond(item_cond)
                        and not has_negated_or_wider_cond(parent_cond)
                    )
                    if not valid_debug:
                        leaks.append(
                            f"[RELEASE LEAK] {csproj}: Microsoft.Maui.DevFlow.Agent PackageReference must be strictly conditioned on Debug (Condition=\"'$(Configuration)' == 'Debug'\")."
                        )
        if matched_nodes == 0:
            leaks.append(
                f"[RELEASE LEAK] {csproj}: Microsoft.Maui.DevFlow reference must be a Debug-conditioned PackageReference."
            )
    except Exception:
        leaks.append(f"[RELEASE LEAK] {csproj}: Could not verify strict Debug-only Condition on Microsoft.Maui.DevFlow.Agent.")

for mp in sorted(root.rglob("MauiProgram.cs")):
    if any(p in excluded for p in mp.relative_to(root).parts):
        continue
    lines = mp.read_text(encoding="utf-8", errors="ignore").splitlines()
    if_stack: list[bool] = []
    for idx, raw in enumerate(lines, start=1):
        t = raw.strip()
        m_if = re.match(r"^#if\s+(.*)$", t)
        if m_if:
            if_stack.append(is_strict_debug_if_expr(m_if.group(1)))
            continue
        if re.match(r"^#(else|elif)\b", t):
            if if_stack:
                if_stack[-1] = False
            continue
        if re.match(r"^#endif\b", t):
            if if_stack:
                if_stack.pop()
            continue

        code_no_comment = re.sub(r"//.*$", "", t)
        if re.search(r"AddMauiDevFlowAgent\s*\(", code_no_comment) or re.search(r"\busing\s+Microsoft\.Maui\.DevFlow", code_no_comment):
            if not any(if_stack):
                leaks.append(
                    f"[RELEASE LEAK] {mp}:{idx} Microsoft.Maui.DevFlow usage (using / AddMauiDevFlowAgent()) must be wrapped strictly inside `#if DEBUG ... #endif`."
                )

if leaks:
    for item in leaks:
        print(f"\033[0;31m{item}\033[0m")
    sys.exit(1)
sys.exit(0)
PY
    then
        FOUND=1
    fi
else
    # Pure Bash + awk fallback so Release leak checks NEVER skip when Python is missing
    CSPROJ_FILES=$(find "$PROJECT_ROOT" -type f -name "*.csproj" -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/Scripts/*" -not -path "*/.git/*" -not -path "*/.agents/*" || true)
    while IFS= read -r csproj; do
        if [ -f "$csproj" ] && grep -q "Microsoft\.Maui\.DevFlow" "$csproj" 2>/dev/null; then
            if ! awk '
                function is_strict_debug(c,   lc) {
                    if (c == "") return 0
                    lc = tolower(c)
                    if (index(lc, "!=") > 0 || index(lc, "!") > 0 || lc ~ /(^|[^a-z0-9_])or([^a-z0-9_]|$)/ || index(lc, "release") > 0) return 0
                    return (lc ~ /\$\(configuration\)[ \t\x27"]*==[ \t]*[\x27"]debug[\x27"]/)
                }
                function has_bad_cond(c,   lc) {
                    if (c == "") return 0
                    lc = tolower(c)
                    return (index(lc, "!=") > 0 || index(lc, "!") > 0 || lc ~ /(^|[^a-z0-9_])or([^a-z0-9_]|$)/ || index(lc, "release") > 0)
                }
                function extract_cond(s,   m) {
                    if (match(s, /Condition[ \t]*=[ \t]*"[^"]*"/)) {
                        m = substr(s, RSTART, RLENGTH)
                        sub(/^Condition[ \t]*=[ \t]*"/, "", m)
                        sub(/"$/, "", m)
                        return m
                    }
                    if (match(s, /Condition[ \t]*=[ \t]*\x27[^\x27]*\x27/)) {
                        m = substr(s, RSTART, RLENGTH)
                        sub(/^Condition[ \t]*=[ \t]*\x27/, "", m)
                        sub(/\x27$/, "", m)
                        return m
                    }
                    return ""
                }
                BEGIN { ig_cond = ""; leak = 0; seen = 0 }
                /<ItemGroup/ {
                    ig_cond = extract_cond($0)
                }
                /<\/ItemGroup>/ {
                    ig_cond = ""
                }
                /Microsoft\.Maui\.DevFlow/ {
                    seen++
                    item_cond = extract_cond($0)
                    ok = (is_strict_debug(item_cond) || is_strict_debug(ig_cond)) && !has_bad_cond(item_cond) && !has_bad_cond(ig_cond)
                    if (!ok) leak = 1
                }
                END {
                    if (seen == 0 || leak == 1) exit 1
                    exit 0
                }
            ' "$csproj"; then
                FOUND=1
                echo -e "\033[0;31m[RELEASE LEAK] $csproj: Microsoft.Maui.DevFlow.Agent PackageReference must be strictly conditioned on Debug (Condition=\"'\$(Configuration)' == 'Debug'\").\033[0m"
            fi
        fi
    done <<< "$CSPROJ_FILES"

    MP_FILES=$(find "$PROJECT_ROOT" -type f -name "MauiProgram.cs" -not -path "*/bin/*" -not -path "*/obj/*" -not -path "*/Scripts/*" -not -path "*/.git/*" -not -path "*/.agents/*" || true)
    while IFS= read -r mp; do
        if [ -f "$mp" ]; then
            if ! awk -v mp_path="$mp" '
                function is_strict_debug_expr(expr,   clean, n, parts, i, tok, has_dbg) {
                    clean = expr
                    sub(/\/\/.*$/, "", clean)
                    gsub(/\/\*([^*]|\*+[^*\/])*\*+\//, "", clean)
                    gsub(/^[ \t]+|[ \t]+$/, "", clean)
                    if (clean == "") return 0
                    if (index(clean, "!") > 0 || index(clean, "||") > 0 || clean ~ /(^|[^A-Za-z0-9_])(RELEASE|false|0)([^A-Za-z0-9_]|$)/) return 0
                    n = split(clean, parts, "&&")
                    has_dbg = 0
                    for (i = 1; i <= n; i++) {
                        tok = parts[i]
                        gsub(/^[ \t()]+|[ \t()]+$/, "", tok)
                        if (tok !~ /^[A-Za-z_][A-Za-z0-9_]*$/) return 0
                        if (tok == "DEBUG") has_dbg = 1
                    }
                    return has_dbg
                }
                function any_stack_true(   i) {
                    for (i = 1; i <= depth; i++) {
                        if (stack[i]) return 1
                    }
                    return 0
                }
                BEGIN { depth = 0; bad = 0 }
                {
                    line = $0
                    gsub(/^[ \t]+|[ \t]+$/, "", line)
                    if (line ~ /^#if[ \t]+/) {
                        expr = line
                        sub(/^#if[ \t]+/, "", expr)
                        depth++
                        stack[depth] = is_strict_debug_expr(expr)
                        next
                    }
                    if (line ~ /^#(else|elif)([^A-Za-z0-9_]|$)/) {
                        if (depth > 0) stack[depth] = 0
                        next
                    }
                    if (line ~ /^#endif([^A-Za-z0-9_]|$)/) {
                        if (depth > 0) depth--
                        next
                    }
                    code = line
                    sub(/\/\/.*$/, "", code)
                    if (code ~ /AddMauiDevFlowAgent[ \t]*\(/ || code ~ /(^|[^A-Za-z0-9_])using[ \t]+Microsoft\.Maui\.DevFlow/) {
                        if (!any_stack_true()) {
                            printf "\033[0;31m[RELEASE LEAK] %s:%d Microsoft.Maui.DevFlow usage (using / AddMauiDevFlowAgent()) must be wrapped strictly inside `#if DEBUG ... #endif`.\033[0m\n", mp_path, NR
                            bad = 1
                        }
                    }
                }
                END { exit (bad ? 1 : 0) }
            ' "$mp"; then
                FOUND=1
            fi
        fi
    done <<< "$MP_FILES"
fi

# Soft pedagogical check for SetProperty(ref ...) in ViewModels only (skips Views/, Controls/, Platforms/)
MASTERY_FILE="$PROJECT_ROOT/Learning/Student-Mastery.md"
REF_MASTERED=0
if [ -f "$MASTERY_FILE" ]; then
    if awk '
        BEGIN { section = ""; level_ok = 0; routine_yes = 0; has_ref_evidence = 0; mastered = 0 }
        function check_section() {
            if (section ~ /^(properties|inotifypropertychanged)$/) {
                if (routine_yes || (level_ok && has_ref_evidence)) mastered = 1
            } else if (section ~ /(setproperty|(^|[^a-z0-9_])ref([^a-z0-9_]|$))/) {
                if (routine_yes || level_ok) mastered = 1
            }
        }
        /^###[ \t]+/ {
            check_section()
            s = tolower($0)
            sub(/^###[ \t]+/, "", s)
            gsub(/[ \t\r]+$/, "", s)
            section = s
            level_ok = 0; routine_yes = 0; has_ref_evidence = 0
            next
        }
        {
            line = tolower($0)
            gsub(/\r$/, "", line)
            if (line !~ /^-?[ \t]*needs practice:/ &&
                line ~ /(setproperty|(^|[^a-z0-9_])ref([^a-z0-9_]|$))/ &&
                line ~ /(routine eligibility:[ \t]*yes|(^|[^a-z0-9_])(approved|mastered)([^a-z0-9_]|$))/) {
                mastered = 1
            }
            if (line ~ /^-?[ \t]*level:[ \t]*(understands|can work independently)/) level_ok = 1
            if (line ~ /^-?[ \t]*routine eligibility:[ \t]*yes/) routine_yes = 1
            if (line ~ /^-?[ \t]*(theory evidence|applied coding evidence):/ &&
                line !~ /:[ \t]*none[ \t]*$/ &&
                line ~ /(setproperty|(^|[^a-z0-9_])ref([^a-z0-9_]|$))/) {
                has_ref_evidence = 1
            }
        }
        END {
            check_section()
            exit (mastered ? 0 : 1)
        }
    ' "$MASTERY_FILE"; then
        REF_MASTERED=1
    fi
fi

if [ "$REF_MASTERED" -eq 0 ]; then
    NORM_ROOT="${PROJECT_ROOT%/}"
    while IFS= read -r file; do
        if [ -f "$file" ] && [[ "$file" == *.cs ]]; then
            rel_path="${file#"$NORM_ROOT"/}"
            rel_path="${rel_path//\\//}"
            case "$rel_path" in
                Views/*|*/Views/*|Controls/*|*/Controls/*|Platforms/*|*/Platforms/*)
                    continue
                    ;;
            esac
            base_name="$(basename "$rel_path")"
            if [[ "$rel_path" == ViewModels/* || "$rel_path" == */ViewModels/* || "$base_name" == *ViewModel.cs ]]; then
                awk -v rel="$rel_path" '
                    {
                        code = $0
                        sub(/\r$/, "", code)
                        sub(/\/\/.*$/, "", code)
                        if (code ~ /(^|[^A-Za-z0-9_])SetProperty[ \t]*(<[^>]+>)?[ \t]*\([ \t]*ref([^A-Za-z0-9_]|$)/) {
                            printf "\033[0;36m[PEDAGOGICAL WARNING] %s:%d - SetProperty(ref...) detected.\033[0m\n", rel, NR
                            print "Notice: \x27ref\x27 and \x27SetProperty\x27 concept is not yet recorded as mastered in Learning/Student-Mastery.md."
                            print "Suggestion: Keep as-is or replace with explicit 3-line setter."
                        }
                    }
                ' "$file"
            fi
        fi
    done <<< "$SOURCE_FILES"
fi

if [ $FOUND -eq 1 ]; then
    echo -e "\033[0;33mRESULT: CHECK REQUIRED\033[0m"
    exit 1
fi

echo -e "\033[0;32mRESULT: PASS\033[0m"
exit 0
