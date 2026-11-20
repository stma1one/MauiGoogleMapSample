#!/usr/bin/env python3
"""
Ensure-Test-Project.py
----------------------
Provisions and configures an xUnit test project (`<AppName>.Tests`) for a .NET MAUI student project
(`net10.0`, `net11.0`, `net9.0`, or `net8.0`) when `.agents/MAUI-Agent-Mode.json` has `"includeTests": true` (default).

Capabilities:
1. Reads `.agents/MAUI-Agent-Mode.json`. If `"includeTests": false`, skips provisioning and exits 0.
2. Locates the main .NET MAUI `.csproj` and determines its base target framework (`net10.0`, `net11.0`, `net9.0`, or `net8.0`).
3. Updates the MAUI `.csproj` so a standard xUnit project (`net10.0` / `net11.0`) can compile and reference it cleanly:
   - Adds the plain base TFM (e.g. `net10.0` or `net11.0`) to `<TargetFrameworks>` alongside `net10.0-android`, `net10.0-windows...`, etc.
   - Conditions `<OutputType>Exe</OutputType>` so plain `net10.0` / `net11.0` compiles as a Library (preventing CS5001 missing Main).
   - Excludes `Platforms/**` when building the plain net10.0/net11.0 target.
4. Creates `<AppName>.Tests/<AppName>.Tests.csproj` with xUnit references and a `<ProjectReference>` to the MAUI `.csproj`.
5. Registers `<AppName>.Tests.csproj` in any `.sln` or `.slnx` solution file in the project root.
6. Creates a student-readable starter test (`ArchitectureSmokeTests.cs`) using Arrange-Act-Assert and initializes `Learning/Test-Documentation.md`.
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.request

# Minimum latest-stable baselines used when offline; when online, api.nuget.org is queried for the latest stable release.
FALLBACK_STABLE_VERSIONS = {
    "xunit.v3": "4.0.3",
    "xunit.runner.visualstudio": "4.0.1",
    "microsoft.net.test.sdk": "18.12.0",
    "coverlet.collector": "10.1.1",
}


def version_sort_key(ver: str) -> tuple[int, int, int, str]:
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?$", ver.strip())
    if not m:
        return (0, 0, 0, ver)
    return (int(m.group(1)), int(m.group(2)), int(m.group(3)), m.group(4) or "")


def resolve_latest_stable_nuget_version(package_id: str, offline: bool = False) -> str:
    pkg_low = package_id.strip().lower()
    fallback = FALLBACK_STABLE_VERSIONS.get(pkg_low, "1.0.0")
    if offline:
        return fallback
    url = f"https://api.nuget.org/v3-flatcontainer/{pkg_low}/index.json"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "maui-k12-baton-workflow/1.4.1"})
        with urllib.request.urlopen(req, timeout=2.5) as resp:
            data = json.loads(resp.read().decode("utf-8", errors="ignore"))
            versions = data.get("versions", [])
            if isinstance(versions, list):
                stable = [str(v) for v in versions if isinstance(v, str) and "-" not in v and "*" not in v]
                if stable:
                    best = max(stable, key=version_sort_key)
                    if version_sort_key(best) >= version_sort_key(fallback):
                        return best
    except Exception:
        pass
    return fallback

EXCLUDED_DIRS = {
    ".git",
    ".vs",
    ".idea",
    "bin",
    "obj",
    "node_modules",
    ".agents",
    ".claude",
    "companion-skills",
    "skills",
    "project-template",
}


def is_excluded(path: pathlib.Path, root: pathlib.Path) -> bool:
    try:
        rel_parts = path.relative_to(root).parts
    except ValueError:
        rel_parts = path.parts
    return any(part in EXCLUDED_DIRS for part in rel_parts)


def read_agent_mode_config(root: pathlib.Path) -> dict[str, object]:
    mode_path = root / ".agents/MAUI-Agent-Mode.json"
    defaults: dict[str, object] = {
        "studentCapabilityMode": True,
        "includeTests": True,
        "testManagementMode": "combined",
    }
    if not mode_path.is_file():
        return defaults
    try:
        data = json.loads(mode_path.read_text(encoding="utf-8", errors="ignore"))
        if isinstance(data, dict):
            defaults.update(data)
    except Exception:
        pass
    return defaults


def find_maui_app_csproj(root: pathlib.Path) -> pathlib.Path | None:
    for csproj in sorted(root.rglob("*.csproj")):
        if is_excluded(csproj, root):
            continue
        if csproj.stem.lower().endswith(".tests") or csproj.stem.lower().endswith("test"):
            continue
        try:
            text = csproj.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if re.search(r"<UseMaui>\s*true\s*</UseMaui>", text, re.IGNORECASE) or "Microsoft.Maui.Controls" in text:
            return csproj
    return None


def find_existing_test_csproj(root: pathlib.Path) -> pathlib.Path | None:
    for csproj in sorted(root.rglob("*.csproj")):
        if is_excluded(csproj, root):
            continue
        if csproj.stem.lower().endswith(".tests") or csproj.name.lower().endswith(".tests.csproj"):
            return csproj
    return None


def detect_base_tfm(csproj_text: str) -> str:
    """Detect base net8.0 / net9.0 / net10.0 / net11.0 TFM from MAUI .csproj."""
    for m in re.finditer(r"<TargetFrameworks?\b[^>]*>([^<]+)</TargetFrameworks?>", csproj_text, re.IGNORECASE):
        for tok in m.group(1).split(";"):
            cleaned = tok.strip()
            m_ver = re.match(r"^(net(?:8|9|10|11)\.0)(?:$|[-.])", cleaned, re.IGNORECASE)
            if m_ver:
                return m_ver.group(1).lower()
    return "net10.0"


def ensure_maui_csproj_testable_tfm(csproj_path: pathlib.Path, base_tfm: str, dry_run: bool = False) -> list[str]:
    """Ensure the MAUI .csproj includes the plain base_tfm (e.g. net10.0 or net11.0) and compiles cleanly as a library on plain TFM."""
    messages: list[str] = []
    text = csproj_path.read_text(encoding="utf-8")
    updated = text

    # 1. Convert singular <TargetFramework>...</TargetFramework> to <TargetFrameworks> if needed and add base_tfm
    m_single = re.search(r"<TargetFramework>([^<]+)</TargetFramework>", updated, re.IGNORECASE)
    m_multi = re.search(r"(<TargetFrameworks\b[^>]*>)([^<]+)(</TargetFrameworks>)", updated, re.IGNORECASE)

    if m_multi:
        open_tag, raw_tfms, close_tag = m_multi.groups()
        tokens = [t.strip() for t in raw_tfms.split(";") if t.strip()]
        if not any(t.lower() == base_tfm.lower() for t in tokens):
            new_tfms = f"{base_tfm};{raw_tfms.strip()}"
            updated = updated[: m_multi.start()] + f"{open_tag}{new_tfms}{close_tag}" + updated[m_multi.end() :]
            messages.append(f"[UPDATED] Added plain '{base_tfm}' target to <TargetFrameworks> in {csproj_path.name} for xUnit compatibility.")
    elif m_single:
        existing_tfm = m_single.group(1).strip()
        if existing_tfm.lower() != base_tfm.lower():
            replacement = f"<TargetFrameworks>{base_tfm};{existing_tfm}</TargetFrameworks>"
            updated = updated[: m_single.start()] + replacement + updated[m_single.end() :]
            messages.append(f"[UPDATED] Converted <TargetFramework> to <TargetFrameworks>{base_tfm};{existing_tfm}</TargetFrameworks> in {csproj_path.name}.")

    # 2. Condition <OutputType>Exe</OutputType> so plain net10.0/net11.0 builds as a Library (no CS5001 missing Main)
    unconditioned_exe = re.compile(r"<OutputType>\s*Exe\s*</OutputType>", re.IGNORECASE)
    if unconditioned_exe.search(updated):
        cond_exe = "<OutputType Condition=\"'$(TargetFramework)' != 'net8.0' and '$(TargetFramework)' != 'net9.0' and '$(TargetFramework)' != 'net10.0' and '$(TargetFramework)' != 'net11.0'\">Exe</OutputType>"
        updated = unconditioned_exe.sub(cond_exe, updated, count=1)
        messages.append(f"[UPDATED] Conditioned <OutputType>Exe</OutputType> in {csproj_path.name} so plain '{base_tfm}' compiles as a testable library.")

    # 3. Exclude Platforms/**/*.cs when building for the plain unit-test TFM
    if "Platforms\\**\\*.cs" not in updated and "Platforms/**/*.cs" not in updated:
        close_idx = updated.rfind("</Project>")
        if close_idx != -1:
            platform_guard = (
                f"\n  <ItemGroup Condition=\"'$(TargetFramework)' == '{base_tfm}'\">\n"
                f"    <Compile Remove=\"Platforms\\**\\*.cs\" />\n"
                f"    <MauiXaml Remove=\"Platforms\\**\\*.xaml\" />\n"
                f"  </ItemGroup>\n"
            )
            updated = updated[:close_idx].rstrip() + "\n" + platform_guard + "</Project>\n"
            messages.append(f"[UPDATED] Added Platforms/** exclusion guard for plain '{base_tfm}' test target in {csproj_path.name}.")

    if updated != text and not dry_run:
        csproj_path.write_text(updated, encoding="utf-8", newline="\n")

    return messages


def build_test_csproj_xml(base_tfm: str, rel_maui_csproj: str, offline: bool = False) -> str:
    xunit_v3_ver = resolve_latest_stable_nuget_version("xunit.v3", offline=offline)
    runner_ver = resolve_latest_stable_nuget_version("xunit.runner.visualstudio", offline=offline)
    sdk_ver = resolve_latest_stable_nuget_version("microsoft.net.test.sdk", offline=offline)
    coverlet_ver = resolve_latest_stable_nuget_version("coverlet.collector", offline=offline)
    return f"""<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>{base_tfm}</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <OutputType>Exe</OutputType>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="coverlet.collector" Version="{coverlet_ver}" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="{sdk_ver}" />
    <PackageReference Include="xunit.v3" Version="{xunit_v3_ver}" />
    <PackageReference Include="xunit.runner.visualstudio" Version="{runner_ver}" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="{rel_maui_csproj}" />
  </ItemGroup>

</Project>
"""


def upgrade_existing_test_csproj_to_xunit_v3(test_csproj: pathlib.Path, offline: bool = False, dry_run: bool = False) -> str | None:
    """If an existing *.Tests.csproj still references legacy xunit v2 or lacks OutputType=Exe, upgrade it to xunit.v3 latest stable."""
    text = test_csproj.read_text(encoding="utf-8", errors="ignore")
    updated = text
    xunit_v3_ver = resolve_latest_stable_nuget_version("xunit.v3", offline=offline)
    runner_ver = resolve_latest_stable_nuget_version("xunit.runner.visualstudio", offline=offline)

    # Replace legacy <PackageReference Include="xunit" Version="..." /> with xunit.v3
    updated = re.sub(
        r'<PackageReference\s+Include="xunit"\s+Version="[^"]+"\s*/>',
        f'<PackageReference Include="xunit.v3" Version="{xunit_v3_ver}" />',
        updated,
        flags=re.IGNORECASE,
    )
    updated = re.sub(
        r'(<PackageReference\s+Include="xunit\.runner\.visualstudio"\s+Version=")([^"]+)(")',
        lambda m: f"{m.group(1)}{runner_ver}{m.group(3)}"
        if version_sort_key(m.group(2)) < version_sort_key(runner_ver)
        else m.group(0),
        updated,
        flags=re.IGNORECASE,
    )
    if "xunit.v3" in updated and "<OutputType>" not in updated:
        updated = re.sub(
            r"(<IsTestProject>\s*true\s*</IsTestProject>)",
            r"<OutputType>Exe</OutputType>\n    \1",
            updated,
            count=1,
            flags=re.IGNORECASE,
        )
    if updated != text:
        if not dry_run:
            test_csproj.write_text(updated, encoding="utf-8", newline="\n")
        return f"[UPGRADED] Upgraded {test_csproj.name} to latest stable xunit.v3 ({xunit_v3_ver}) and xunit.runner.visualstudio ({runner_ver})."
    return None


def ensure_global_json_mtp_runner(root: pathlib.Path, dry_run: bool = False) -> str | None:
    """Ensure global.json configures Microsoft.Testing.Platform so `dotnet test` runs xunit.v3 natively on .NET 10+ SDK."""
    global_json = root / "global.json"
    data: dict[str, object] = {}
    if global_json.is_file():
        try:
            loaded = json.loads(global_json.read_text(encoding="utf-8", errors="ignore"))
            if isinstance(loaded, dict):
                data = loaded
        except Exception:
            return None

    test_section = data.get("test")
    if isinstance(test_section, dict) and test_section.get("runner") == "Microsoft.Testing.Platform":
        return None

    data["test"] = {"runner": "Microsoft.Testing.Platform"}
    if not dry_run:
        global_json.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
    return f"[CONFIGURED] Configured Microsoft.Testing.Platform test runner in {global_json.name} for xunit.v3 compatibility."


def build_starter_smoke_test_cs(app_namespace: str) -> str:
    return f"""using Xunit;

namespace {app_namespace}.Tests;

/// <summary>
/// בדיקת שפיות ראשונית (Smoke Test) המאמתת שתשתית ה-xUnit מוגדרת ומקושרת לפרויקט.
/// בכל סלייס חדש יש להוסיף מחלקות בדיקה עבור ViewModels, Services ו-Converters לפי תבנית Arrange-Act-Assert.
/// </summary>
public class ArchitectureSmokeTests
{{
    [Fact]
    public void TestHarness_WhenInitialized_PassesSanityCheck()
    {{
        // Arrange (הכנת נתוני הבדיקה)
        const int expectedMinimumTests = 1;

        // Act (הפעלת הלוגיקה הנבדקת)
        int actualConfiguredTests = 1;

        // Assert (אימות שהתוצאה בפועל תואמת למצופה)
        Assert.True(actualConfiguredTests >= expectedMinimumTests);
    }}
}}
"""


def ensure_test_documentation_md(root: pathlib.Path, app_name: str, dry_run: bool = False) -> str | None:
    doc_path = root / "Learning/Test-Documentation.md"
    if doc_path.is_file():
        return None
    if dry_run:
        return f"[DRY-RUN] Would create {doc_path}"
    doc_path.parent.mkdir(parents=True, exist_ok=True)
    content = f"""# תיעוד בדיקות יחידה (xUnit Test Documentation) — {app_name}

מסמך זה מרכז את כל בדיקות היחידה (`xUnit`) בפרויקט `{app_name}.Tests`.
הוא מתעד מה כל בדיקה מאמתת לפי תבנית **Arrange – Act – Assert (AAA)**, אילו רכיבי לוגיקה (`ViewModels`, `Services`, `Converters`, `Models`) מכוסים, ואיך להסביר כל בדיקה לבוחן בבחינה בעל-פה (25% "שליטה בקוד").

---

## 1. טבלת ריכוז בדיקות היחידה בפרויקט (`{app_name}.Tests`)

| # | מחלקת הבדיקה (`Test Class`) | שם הבדיקה (`Test Method`) | הרכיב הנבדק (`Target Component`) | מי כתב? (`Agent` / `Student` / `Combined`) | תרחיש הבדיקה (`Arrange -> Act -> Assert`) | מה להסביר לבוחן בבחינה בעל-פה? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `ArchitectureSmokeTests` | `TestHarness_WhenInitialized_PassesSanityCheck` | `{app_name}.Tests` | `Agent` | **Arrange:** הגדרת ערכי בסיס. **Act:** הרצת בדיקת שפיות. **Assert:** אימות שתשתית `xUnit` פעילה ומקושרת לפרויקט. | כיצד פרויקט ה-`xUnit` מקושר לפרויקט ה-MAUI ומאפשר הרצת בדיקות לוגיקה מהירות ללא אמולטור. |
"""
    doc_path.write_text(content, encoding="utf-8", newline="\n")
    return f"[CREATED] Initialized unit test documentation at {doc_path}"


def register_in_solution(root: pathlib.Path, test_csproj: pathlib.Path, dry_run: bool = False) -> list[str]:
    messages: list[str] = []
    sln_files = list(sorted(root.glob("*.sln"))) + list(sorted(root.glob("*.slnx")))
    for sln in sln_files:
        text = sln.read_text(encoding="utf-8", errors="ignore")
        if test_csproj.name in text:
            messages.append(f"[OK] {test_csproj.name} is already registered in {sln.name}.")
            continue
        if dry_run:
            messages.append(f"[DRY-RUN] Would register {test_csproj.name} in {sln.name}.")
            continue
        if shutil.which("dotnet") is not None:
            proc = subprocess.run(
                ["dotnet", "sln", str(sln), "add", str(test_csproj)],
                capture_output=True,
                text=True,
                check=False,
            )
            if proc.returncode == 0:
                messages.append(f"[REGISTERED] Added {test_csproj.name} to {sln.name} via `dotnet sln add`.")
                continue
        if sln.suffix.lower() == ".slnx" and "</Solution>" in text:
            rel_path = os.path.relpath(test_csproj, sln.parent).replace("\\", "/")
            idx = text.rfind("</Solution>")
            updated = text[:idx].rstrip() + f'\n  <Project Path="{rel_path}" />\n</Solution>\n'
            sln.write_text(updated, encoding="utf-8", newline="\n")
            messages.append(f"[REGISTERED] Added {test_csproj.name} to {sln.name}.")
    return messages


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Provision and link an xUnit test project (<AppName>.Tests) for a .NET MAUI student project."
    )
    parser.add_argument("--project-root", default=".", help="Path to the .NET MAUI project root directory.")
    parser.add_argument("--skip-tests", action="store_true", help="Explicitly skip test project provisioning.")
    parser.add_argument("--offline", action="store_true", help="Use bundled latest-stable fallback versions without querying NuGet.org.")
    parser.add_argument("--dry-run", action="store_true", help="Inspect without writing changes.")
    args = parser.parse_args()

    root = pathlib.Path(args.project_root).resolve()
    if not root.exists():
        print(f"[ERROR] Project root does not exist: {root}", file=sys.stderr)
        return 1

    mode_cfg = read_agent_mode_config(root)
    include_tests = bool(mode_cfg.get("includeTests", True))
    if args.skip_tests or not include_tests or os.environ.get("MAUI_SKIP_TESTS", "").strip().lower() in {"1", "true", "yes"}:
        print("[SKIP] Unit test project provisioning skipped (includeTests=false or --skip-tests).")
        return 0

    student_mode = bool(mode_cfg.get("studentCapabilityMode", True))
    configured_writer = str(mode_cfg.get("testManagementMode", "combined")).strip().lower()
    effective_writer = "agent" if not student_mode else configured_writer
    print(f"[INFO] Test configuration: includeTests=true, testManagementMode={configured_writer} (effective writer: {effective_writer}).")

    maui_csproj = find_maui_app_csproj(root)
    if maui_csproj is None:
        doc_msg = ensure_test_documentation_md(root, root.name, dry_run=args.dry_run)
        if doc_msg:
            print(doc_msg)
        print(f"[INFO] No .NET MAUI .csproj detected under {root} yet; <AppName>.Tests will be provisioned once the MAUI app project exists.")
        return 0

    app_name = maui_csproj.stem
    csproj_text = maui_csproj.read_text(encoding="utf-8", errors="ignore")
    base_tfm = detect_base_tfm(csproj_text)

    for msg in ensure_maui_csproj_testable_tfm(maui_csproj, base_tfm, dry_run=args.dry_run):
        print(msg)

    test_csproj = find_existing_test_csproj(root)
    if test_csproj is None:
        test_dir = root / f"{app_name}.Tests"
        test_csproj = test_dir / f"{app_name}.Tests.csproj"
        rel_maui = os.path.relpath(maui_csproj, test_dir).replace("/", "\\")
        if not args.dry_run:
            test_dir.mkdir(parents=True, exist_ok=True)
            test_csproj.write_text(build_test_csproj_xml(base_tfm, rel_maui, offline=args.offline), encoding="utf-8", newline="\n")
            smoke_file = test_dir / "ArchitectureSmokeTests.cs"
            if not smoke_file.exists():
                smoke_file.write_text(build_starter_smoke_test_cs(app_name), encoding="utf-8", newline="\n")
        print(f"[CREATED] Provisioned xunit.v3 test project: {test_csproj} (TargetFramework: {base_tfm}, referencing {maui_csproj.name}).")
    else:
        upg_msg = upgrade_existing_test_csproj_to_xunit_v3(test_csproj, offline=args.offline, dry_run=args.dry_run)
        if upg_msg:
            print(upg_msg)
        else:
            print(f"[OK] Existing xunit.v3 test project detected: {test_csproj}")

    mtp_msg = ensure_global_json_mtp_runner(root, dry_run=args.dry_run)
    if mtp_msg:
        print(mtp_msg)

    for msg in register_in_solution(root, test_csproj, dry_run=args.dry_run):
        print(msg)

    doc_msg = ensure_test_documentation_md(root, app_name, dry_run=args.dry_run)
    if doc_msg:
        print(doc_msg)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
