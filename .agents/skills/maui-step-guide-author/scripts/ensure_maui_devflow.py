#!/usr/bin/env python3
"""Ensure Microsoft.Maui.DevFlow.Agent is configured in Debug-only mode in an existing .NET 10 / .NET 11 MAUI project.

Capabilities:
1. Checks that the target .NET MAUI .csproj targets net10.0 or net11.0 exclusively (skips net9.0 and older
   targets such as net9.0-android because Microsoft.Maui.DevFlow.Agent requires .NET 10+).
2. Supports opting out (`--skip` / `--no-devflow` or `MAUI_SKIP_DEVFLOW=1`) and removing an existing
   DevFlow injection (`--remove` / `--disable`).
3. On initial installation (without `--upgrade`), always injects the pinned classroom baseline version
   `0.1.0-preview.14.26531.2` under `<ItemGroup Condition="'$(Configuration)' == 'Debug'">` even when online,
   so students installing on different days receive the exact same package version.
4. When `--upgrade` is passed, upgrades the PackageReference to the latest stable or preview version on NuGet
   (or prints an upgrade suggestion during check runs).
5. Finds MauiProgram.cs and injects `#if DEBUG` `using Microsoft.Maui.DevFlow.Agent;` and
   `builder.AddMauiDevFlowAgent();` before `return builder.Build();` only when a compatible net10.0/net11.0
   MAUI project has DevFlow enabled.
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

DEFAULT_DEVFLOW_VERSION = "0.1.0-preview.14.26531.2"
NUGET_INDEX_URL = "https://api.nuget.org/v3-flatcontainer/microsoft.maui.devflow.agent/index.json"

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


def version_sort_key(ver: str) -> tuple[int, int, int, int, str]:
    """Parse semver with optional -preview.N.M into a comparable tuple where stable > preview."""
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$", ver.strip())
    if not m:
        return (0, 0, 0, 0, ver)
    major, minor, patch, prerelease = int(m.group(1)), int(m.group(2)), int(m.group(3)), m.group(4)
    if not prerelease:
        return (major, minor, patch, 1, "")
    nums = [int(x) for x in re.findall(r"\d+", prerelease)]
    padded = tuple(nums + [0] * (4 - len(nums)))
    return (major, minor, patch, 0, ":".join(f"{n:08d}" for n in padded))


def resolve_latest_devflow_version(
    fallback_version: str = DEFAULT_DEVFLOW_VERSION, check_online: bool = True
) -> tuple[str, bool, str]:
    """Return (recommended_version, is_stable_available, source_label)."""
    candidates = [fallback_version]
    source_label = "bundled-baseline"
    if check_online:
        try:
            req = urllib.request.Request(
                NUGET_INDEX_URL, headers={"User-Agent": "maui-k12-baton-workflow/1.4.1"}
            )
            with urllib.request.urlopen(req, timeout=2.5) as resp:
                data = json.loads(resp.read().decode("utf-8", errors="ignore"))
                versions = data.get("versions", [])
                if isinstance(versions, list) and versions:
                    candidates.extend(str(v) for v in versions if isinstance(v, str))
                    source_label = "nuget.org"
        except Exception:
            pass

    stable_versions = [v for v in candidates if "-" not in v and "*" not in v]
    if stable_versions:
        best_stable = max(stable_versions, key=version_sort_key)
        return best_stable, True, source_label

    concrete_previews = [v for v in candidates if "*" not in v]
    best_preview = max(concrete_previews, key=version_sort_key) if concrete_previews else fallback_version
    return best_preview, False, source_label


def find_maui_csproj_files(root: pathlib.Path) -> list[pathlib.Path]:
    results: list[pathlib.Path] = []
    for csproj in sorted(root.rglob("*.csproj")):
        if is_excluded(csproj, root):
            continue
        try:
            text = csproj.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if re.search(r"<UseMaui>\s*true\s*</UseMaui>", text, re.IGNORECASE) or "Microsoft.Maui.Controls" in text:
            results.append(csproj)
    return results


def get_csproj_target_frameworks(csproj_text: str) -> list[str]:
    """Extract all concrete TargetFramework / TargetFrameworks tokens from .csproj XML text."""
    tfms: list[str] = []
    for m in re.finditer(r"<TargetFrameworks?\b[^>]*>([^<]+)</TargetFrameworks?>", csproj_text, re.IGNORECASE):
        raw_val = m.group(1)
        for token in raw_val.split(";"):
            cleaned = token.strip()
            if not cleaned or cleaned.startswith("$("):
                continue
            if cleaned not in tfms:
                tfms.append(cleaned)
    return tfms


def check_devflow_tfm_compatibility(csproj_text: str) -> tuple[bool, str]:
    """Verify that .csproj targets net10.0 or net11.0 and does not include older unsupported TFMs (e.g. net9.0-android)."""
    tfms = get_csproj_target_frameworks(csproj_text)
    if not tfms:
        return False, "unspecified TargetFramework"

    supported: list[str] = []
    unsupported: list[str] = []
    for tfm in tfms:
        if re.match(r"^net1[01]\.0(?:$|[-.])", tfm, re.IGNORECASE):
            supported.append(tfm)
        else:
            unsupported.append(tfm)

    if unsupported or not supported:
        return False, ";".join(tfms)
    return True, ";".join(tfms)


PKG_REF_RE = re.compile(
    r'(<PackageReference\s+[^>]*Include\s*=\s*"Microsoft\.Maui\.DevFlow\.Agent"[^>]*Version\s*=\s*")([^"]+)("[^>]*/>)',
    re.IGNORECASE,
)

DEVFLOW_ITEMGROUP_RE = re.compile(
    r'\n?[ \t]*<ItemGroup\s+Condition="\'?\$\(Configuration\)\'?\s*==\s*\'?Debug\'?"\s*>\s*'
    r'<PackageReference\s+Include="Microsoft\.Maui\.DevFlow\.Agent"[^/>]*/>\s*</ItemGroup>[ \t]*\n?',
    re.IGNORECASE,
)

DEVFLOW_PKGREF_LINE_RE = re.compile(
    r'^[ \t]*<PackageReference\s+[^>]*Include="Microsoft\.Maui\.DevFlow\.Agent"[^/>]*/>[ \t]*\r?\n?',
    re.IGNORECASE | re.MULTILINE,
)


def remove_csproj_devflow(csproj_path: pathlib.Path, dry_run: bool = False) -> str:
    text = csproj_path.read_text(encoding="utf-8")
    if "Microsoft.Maui.DevFlow.Agent" not in text:
        return f"[OK] Microsoft.Maui.DevFlow.Agent is not present in {csproj_path.name}"

    updated = DEVFLOW_ITEMGROUP_RE.sub("\n", text)
    if "Microsoft.Maui.DevFlow.Agent" in updated:
        updated = DEVFLOW_PKGREF_LINE_RE.sub("", updated)
    if not dry_run:
        csproj_path.write_text(updated, encoding="utf-8", newline="\n")
    return f"[REMOVED] Removed Microsoft.Maui.DevFlow.Agent from {csproj_path.name}"


def ensure_csproj_devflow(
    csproj_path: pathlib.Path,
    pinned_version: str,
    latest_version: str,
    is_stable: bool,
    source_label: str,
    upgrade: bool = False,
    dry_run: bool = False,
) -> tuple[bool, str]:
    """Return (is_devflow_active_in_csproj, status_message)."""
    text = csproj_path.read_text(encoding="utf-8")
    is_compatible, tfm_summary = check_devflow_tfm_compatibility(text)
    if not is_compatible:
        return (
            False,
            f"[SKIP] {csproj_path.name} targets '{tfm_summary}'; Microsoft.Maui.DevFlow.Agent requires net10.0 or net11.0. Skipping DevFlow injection.",
        )

    if "Microsoft.Maui.DevFlow.Agent" in text:
        m = PKG_REF_RE.search(text)
        if not m:
            return True, f"[OK] DevFlow PackageReference already present in {csproj_path.name}"
        current_ver = m.group(2).strip()
        is_current_preview = "-" in current_ver or "*" in current_ver
        needs_upgrade = (
            current_ver != latest_version
            and ("*" in current_ver or version_sort_key(current_ver) < version_sort_key(latest_version))
        )
        if needs_upgrade:
            if upgrade:
                updated = PKG_REF_RE.sub(
                    lambda match: f"{match.group(1)}{latest_version}{match.group(3)}", text, count=1
                )
                if not dry_run:
                    csproj_path.write_text(updated, encoding="utf-8", newline="\n")
                return (
                    True,
                    f"[UPGRADED] Updated Microsoft.Maui.DevFlow.Agent in {csproj_path.name} "
                    f"from '{current_ver}' to '{latest_version}' ({'stable' if is_stable else 'latest preview'} via {source_label}).",
                )
            release_note = (
                f"A stable release ('{latest_version}') is now available!"
                if is_stable
                else f"A newer preview version ('{latest_version}') is available ({source_label})."
            )
            return (
                True,
                f"[UPGRADE SUGGESTION] {csproj_path.name} references Microsoft.Maui.DevFlow.Agent '{current_ver}' (pinned preview). "
                f"{release_note} Run `Ensure-Maui-DevFlow --upgrade` (or `Install-Skill --upgrade` / `-Upgrade`) to update.",
            )
        if is_current_preview:
            return (
                True,
                f"[OK] DevFlow PackageReference in {csproj_path.name} is at '{current_ver}' ({source_label}). "
                f"Note: package is currently in preview; re-run with `--upgrade` periodically to check for newer or stable releases.",
            )
        return True, f"[OK] DevFlow PackageReference in {csproj_path.name} is up to date ('{current_ver}')."

    # Initial installation: use pinned_version unless --upgrade was explicitly requested
    install_version = latest_version if upgrade else pinned_version
    snippet = (
        f"\n  <ItemGroup Condition=\"'$(Configuration)' == 'Debug'\">\n"
        f"    <PackageReference Include=\"Microsoft.Maui.DevFlow.Agent\" Version=\"{install_version}\" />\n"
        f"  </ItemGroup>\n"
    )
    close_tag = "</Project>"
    idx = text.rfind(close_tag)
    if idx == -1:
        return False, f"[WARN] Could not locate </Project> in {csproj_path.name}; skipped."

    updated = text[:idx].rstrip() + "\n" + snippet + close_tag + "\n"
    if not dry_run:
        csproj_path.write_text(updated, encoding="utf-8", newline="\n")

    if not upgrade and latest_version != install_version and version_sort_key(latest_version) > version_sort_key(install_version):
        upgrade_hint = f" (pinned classroom baseline; newer '{latest_version}' available via --upgrade)"
    elif "-" in install_version:
        upgrade_hint = " (pinned preview — run with --upgrade later to check for newer/stable versions)"
    else:
        upgrade_hint = ""
    return (
        True,
        f"[INJECTED] Added Debug-only Microsoft.Maui.DevFlow.Agent ({install_version}{upgrade_hint}) to {csproj_path.name}",
    )


def find_maui_program_files(root: pathlib.Path) -> list[pathlib.Path]:
    results: list[pathlib.Path] = []
    for cs_file in sorted(root.rglob("MauiProgram.cs")):
        if is_excluded(cs_file, root):
            continue
        results.append(cs_file)
    return results


def remove_maui_program_devflow(cs_path: pathlib.Path, dry_run: bool = False) -> str:
    text = cs_path.read_text(encoding="utf-8")
    if "AddMauiDevFlowAgent" not in text and "Microsoft.Maui.DevFlow.Agent" not in text:
        return f"[OK] DevFlow registration is not present in {cs_path.name}"

    updated = re.sub(
        r"#if\s+DEBUG\s*\r?\n[ \t]*using\s+Microsoft\.Maui\.DevFlow\.Agent;\s*\r?\n#endif\s*\r?\n?",
        "",
        text,
    )
    updated = re.sub(
        r"#if\s+DEBUG\s*\r?\n[ \t]*builder\.AddMauiDevFlowAgent\(\s*\);\s*\r?\n#endif\s*\r?\n?",
        "",
        updated,
    )
    if not dry_run:
        cs_path.write_text(updated, encoding="utf-8", newline="\n")
    return f"[REMOVED] Removed DevFlow registration from {cs_path.name}"


def ensure_maui_program_devflow(cs_path: pathlib.Path, dry_run: bool = False) -> str:
    text = cs_path.read_text(encoding="utf-8")
    if "AddMauiDevFlowAgent" in text:
        return f"[OK] AddMauiDevFlowAgent() already present in {cs_path.name}"

    updated = text
    if "Microsoft.Maui.DevFlow.Agent" not in updated:
        using_block = "#if DEBUG\nusing Microsoft.Maui.DevFlow.Agent;\n#endif\n"
        using_matches = list(re.finditer(r"^(?:global\s+)?using\s+[^;]+;\s*$", updated, re.MULTILINE))
        if using_matches:
            last_using = using_matches[-1]
            insert_pos = last_using.end()
            updated = updated[:insert_pos] + "\n" + using_block.rstrip("\n") + updated[insert_pos:]
        else:
            updated = using_block + updated

    build_match = re.search(r"^(?P<indent>[ \t]*)return\s+builder\.Build\(\s*\)\s*;", updated, re.MULTILINE)
    if not build_match:
        return f"[WARN] Could not locate 'return builder.Build();' in {cs_path.name}; skipped."

    indent = build_match.group("indent")
    call_block = (
        f"#if DEBUG\n"
        f"{indent}builder.AddMauiDevFlowAgent();\n"
        f"#endif\n"
    )
    start = build_match.start()
    updated = updated[:start] + call_block + updated[start:]

    if not dry_run:
        cs_path.write_text(updated, encoding="utf-8", newline="\n")
    return f"[INJECTED] Added #if DEBUG builder.AddMauiDevFlowAgent() to {cs_path.name}"


def ensure_devflow_cli(
    upgrade: bool = False,
    skip_cli: bool = False,
    dry_run: bool = False,
    offline: bool = False,
) -> str:
    """Ensure the global .NET MAUI DevFlow CLI (`Microsoft.Maui.Cli` -> `maui`) is installed on the machine."""
    if (
        skip_cli
        or dry_run
        or offline
        or os.environ.get("MAUI_SKIP_DEVFLOW_CLI", "").strip().lower() in {"1", "true", "yes"}
    ):
        return "[SKIP] Global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli) check skipped (--skip-cli / offline / dry-run)."

    has_cli = shutil.which("maui") is not None
    if not has_cli:
        if shutil.which("dotnet") is None:
            return "[WARN] 'dotnet' CLI not found in PATH; skipping global Microsoft.Maui.Cli installation."
        print("[INFO] Installing global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)...")
        proc = subprocess.run(
            ["dotnet", "tool", "install", "-g", "Microsoft.Maui.Cli", "--prerelease"],
            check=False,
        )
        if proc.returncode == 0:
            return "[INSTALLED] Installed global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)."
        return (
            "[WARN] Global Microsoft.Maui.Cli installation returned non-zero "
            "(pass --skip-cli / -SkipCli if working without global tool permissions)."
        )

    if upgrade:
        if shutil.which("dotnet") is None:
            return "[WARN] 'dotnet' CLI not found in PATH; skipping global Microsoft.Maui.Cli update."
        print("[INFO] Updating global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)...")
        proc = subprocess.run(
            ["dotnet", "tool", "update", "-g", "Microsoft.Maui.Cli", "--prerelease"],
            check=False,
        )
        if proc.returncode == 0:
            return "[UPGRADED] Updated global .NET MAUI DevFlow CLI (Microsoft.Maui.Cli)."
        return "[WARN] Global Microsoft.Maui.Cli update returned non-zero."

    return "[OK] Global .NET MAUI DevFlow CLI ('maui') is already installed."


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inject, upgrade, skip, or remove Debug-only Microsoft.Maui.DevFlow.Agent and global Microsoft.Maui.Cli in a .NET 10 / .NET 11 MAUI project."
    )
    parser.add_argument("--project-root", default=".", help="Path to the .NET MAUI project root directory.")
    parser.add_argument("--version", default=None, help="Explicit NuGet version override for Microsoft.Maui.DevFlow.Agent.")
    parser.add_argument(
        "--upgrade",
        action="store_true",
        help="Upgrade or install the latest available NuGet version and update global Microsoft.Maui.Cli.",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Skip online NuGet version lookup and global CLI installation, using the bundled baseline version.",
    )
    parser.add_argument(
        "--skip",
        "--skip-devflow",
        "--no-devflow",
        dest="skip",
        action="store_true",
        help="Opt out of automatic Microsoft.Maui.DevFlow.Agent and CLI installation.",
    )
    parser.add_argument(
        "--skip-cli",
        "--no-cli",
        "--skip-devflow-cli",
        dest="skip_cli",
        action="store_true",
        help="Skip global Microsoft.Maui.Cli installation (for environments without global tool permissions).",
    )
    parser.add_argument(
        "--remove",
        "--disable",
        dest="remove",
        action="store_true",
        help="Remove Microsoft.Maui.DevFlow.Agent from .csproj and MauiProgram.cs.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Inspect without writing changes.")
    args = parser.parse_args()

    if args.skip or os.environ.get("MAUI_SKIP_DEVFLOW", "").strip().lower() in {"1", "true", "yes"}:
        print("[SKIP] MAUI DevFlow automatic injection skipped by user option (--skip-devflow / MAUI_SKIP_DEVFLOW).")
        return 0

    root = pathlib.Path(args.project_root).resolve()
    if not root.exists():
        print(f"[ERROR] Project root does not exist: {root}", file=sys.stderr)
        return 1

    csproj_files = find_maui_csproj_files(root)
    if not csproj_files:
        print(f"[INFO] No .NET MAUI .csproj detected under {root}; skipping DevFlow project injection.")
        return 0

    maui_programs = find_maui_program_files(root)

    if args.remove:
        for csproj in csproj_files:
            print(remove_csproj_devflow(csproj, dry_run=args.dry_run))
        for mp in maui_programs:
            print(remove_maui_program_devflow(mp, dry_run=args.dry_run))
        return 0

    if args.version:
        pinned_version = args.version
        latest_version = args.version
        is_stable = "-" not in latest_version and "*" not in latest_version
        source_label = "explicit-override"
    else:
        pinned_version = DEFAULT_DEVFLOW_VERSION
        latest_version, is_stable, source_label = resolve_latest_devflow_version(
            DEFAULT_DEVFLOW_VERSION, check_online=not args.offline
        )

    any_active_csproj = False
    for csproj in csproj_files:
        active, msg = ensure_csproj_devflow(
            csproj,
            pinned_version=pinned_version,
            latest_version=latest_version,
            is_stable=is_stable,
            source_label=source_label,
            upgrade=args.upgrade,
            dry_run=args.dry_run,
        )
        print(msg)
        if active:
            any_active_csproj = True

    if not any_active_csproj:
        return 0

    cli_msg = ensure_devflow_cli(
        upgrade=args.upgrade,
        skip_cli=args.skip_cli,
        dry_run=args.dry_run,
        offline=args.offline,
    )
    print(cli_msg)

    if not maui_programs:
        print(f"[INFO] No MauiProgram.cs found under {root}; skipped MauiProgram.cs injection.")
    else:
        for mp in maui_programs:
            print(ensure_maui_program_devflow(mp, dry_run=args.dry_run))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
