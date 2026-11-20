#!/usr/bin/env python3
"""
Generate-Architecture-Diagrams.py
---------------------------------
Cross-platform (Windows / macOS / Linux) architecture diagram and prompt generator for .NET MAUI projects.
Scans the project's C# and XAML files to automatically produce:
1. `Learning/Diagrams/Screen-Flow.mmd` (Mermaid Screen Flow Diagram from AppShell & GoToAsync routes)
2. `Learning/Diagrams/Architecture-UML.mmd` (Mermaid UML Class Diagram with properties, methods, inheritance, composition & DI)
3. `Learning/Diagrams/Architecture-Diagram-Prompts.md` (Ready-to-paste prompts + Mermaid sources for the student's Project Portfolio)
4. `Learning/Diagrams/Architecture-Preview.html` (Self-contained visual SVG preview of both diagrams)
5. Optional PNG snapshots (`Learning/Images/Screen-Flow.png` and `Learning/Images/Architecture-UML.png`) if Playwright Chromium is available.
"""

from __future__ import annotations

import argparse
import html
import importlib.util
import os
import re
import subprocess
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass


def strip_comments(code: str) -> str:
    code = re.sub(r"/\*[\s\S]*?\*/", "", code)
    return re.sub(r"//.*$", "", code, flags=re.MULTILINE)


def scan_classes(project_root: Path) -> list[dict[str, object]]:
    classes: list[dict[str, object]] = []
    cs_files = [
        p for p in sorted(project_root.rglob("*.cs"))
        if "/bin/" not in p.as_posix()
        and "/obj/" not in p.as_posix()
        and "/Scripts/" not in p.as_posix()
        and "/Platforms/" not in p.as_posix()
    ]

    class_re = re.compile(
        r"\b(public|internal)\s+(?:partial\s+|abstract\s+|sealed\s+|static\s+)*(class|interface)\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*([^{]+))?"
    )
    prop_re = re.compile(
        r"\bpublic\s+(?:virtual\s+|override\s+|static\s+)?([A-Za-z0-9_<>,\.\?\[\]]+)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{\s*get;"
    )
    method_re = re.compile(
        r"\bpublic\s+(?:async\s+|virtual\s+|override\s+|static\s+)*([A-Za-z0-9_<>,\.\?\[\]]+)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)"
    )

    for cs_file in cs_files:
        text = strip_comments(cs_file.read_text(encoding="utf-8", errors="ignore"))
        posix = cs_file.as_posix()
        layer = "Other"
        for candidate_layer in ("Models", "ViewModels", "Services", "Views", "Converters", "Drawables"):
            if f"/{candidate_layer}/" in posix:
                layer = candidate_layer
                break

        for m in class_re.finditer(text):
            _, kind, name, base_list = m.groups()
            if name in {"App", "MauiProgram", "Resource"}:
                continue
            bases = []
            if base_list:
                bases = [b.strip().split("<")[0].split(".")[-1] for b in base_list.split(",") if b.strip()]

            props = []
            for pm in prop_re.finditer(text):
                ptype, pname = pm.groups()
                props.append((pname, ptype.replace("<", "~").replace(">", "~")))

            methods = []
            deps = []
            for mm in method_re.finditer(text):
                ret_type, mname, params = mm.groups()
                if mname == name:
                    # Constructor dependencies
                    for param in params.split(","):
                        parts = param.strip().split()
                        if len(parts) >= 2:
                            dep_type = parts[0].split(".")[-1].replace("<", "~").replace(">", "~")
                            deps.append(dep_type)
                    continue
                methods.append((mname, ret_type.replace("<", "~").replace(">", "~")))

            # Also check primary constructor or field injections
            ctor_re = re.compile(rf"\bpublic\s+{re.escape(name)}\s*\(([^)]*)\)")
            for cm in ctor_re.finditer(text):
                for param in cm.group(1).split(","):
                    parts = param.strip().split()
                    if len(parts) >= 2:
                        dep_type = parts[0].split(".")[-1]
                        if dep_type not in deps:
                            deps.append(dep_type)

            classes.append(
                {
                    "name": name,
                    "kind": kind,
                    "layer": layer,
                    "file": str(cs_file.relative_to(project_root)),
                    "bases": bases,
                    "props": props[:8],
                    "methods": methods[:8],
                    "deps": deps,
                }
            )

    return classes


def scan_screen_flow(project_root: Path) -> tuple[list[str], list[tuple[str, str, str]]]:
    screens: set[str] = set()
    edges: list[tuple[str, str, str]] = []

    for xaml_file in sorted(project_root.rglob("*.xaml")):
        if "/bin/" in xaml_file.as_posix() or "/obj/" in xaml_file.as_posix():
            continue
        raw = xaml_file.read_text(encoding="utf-8", errors="ignore")
        if "<ContentPage" in raw:
            screens.add(xaml_file.stem)
        if xaml_file.name.lower() == "appshell.xaml":
            for m in re.finditer(r'ContentTemplate\s*=\s*"\{DataTemplate\s+(?:[A-Za-z0-9_]+:)?([A-Za-z0-9_]+)\}"', raw):
                target = m.group(1)
                screens.add(target)
                edges.append(("AppShell", target, "Shell Tab / Flyout"))

    for cs_file in sorted(project_root.rglob("*.cs")):
        if "/bin/" in cs_file.as_posix() or "/obj/" in cs_file.as_posix():
            continue
        text = strip_comments(cs_file.read_text(encoding="utf-8", errors="ignore"))
        src_name = cs_file.stem.replace("ViewModel", "Page")
        for m in re.finditer(r'GoToAsync\s*\(\s*(?:\$?"([^"]+)"|nameof\s*\(\s*([A-Za-z0-9_]+)\s*\))', text):
            route_lit, nameof_target = m.groups()
            target = nameof_target or route_lit or ""
            target = target.strip("/").split("?")[0]
            if target == "..":
                edges.append((src_name, "PreviousScreen", "Back (..)"))
            elif target:
                screens.add(target)
                edges.append((src_name, target, "GoToAsync"))

    if not screens:
        screens.add("MainPage")
    if not edges:
        for s in sorted(screens):
            edges.append(("AppShell", s, "Start Route"))

    return sorted(screens), edges


def build_uml_mermaid(classes: list[dict[str, object]]) -> str:
    lines = ["classDiagram", "  direction TB"]
    known_names = {str(c["name"]) for c in classes}

    if not classes:
        lines.append("  class MainPage {")
        lines.append("  }")
        lines.append("  class MainViewModel {")
        lines.append("    +bool IsLoading")
        lines.append("    +InitializeAsync() Task")
        lines.append("  }")
        lines.append("  MainPage --> MainViewModel : BindingContext")
        return "\n".join(lines) + "\n"

    for c in classes:
        cname = str(c["name"])
        lines.append(f"  class {cname} {{")
        if c["kind"] == "interface":
            lines.append("    <<interface>>")
        for pname, ptype in c["props"]:
            lines.append(f"    +{ptype} {pname}")
        for mname, rtype in c["methods"]:
            lines.append(f"    +{mname}() {rtype}")
        lines.append("  }")

    seen_rel: set[str] = set()
    for c in classes:
        cname = str(c["name"])
        for base in c["bases"]:
            if base in known_names or base in {"INotifyPropertyChanged", "ContentPage", "IDrawable"}:
                rel = f"  {base} <|-- {cname}"
                if rel not in seen_rel:
                    lines.append(rel)
                    seen_rel.add(rel)
        for dep in c["deps"]:
            if dep in known_names and dep != cname:
                rel = f"  {cname} ..> {dep} : DI"
                if rel not in seen_rel:
                    lines.append(rel)
                    seen_rel.add(rel)

    return "\n".join(lines) + "\n"


def build_screen_flow_mermaid(screens: list[str], edges: list[tuple[str, str, str]]) -> str:
    lines = ["flowchart TD", "  AppShell([\"AppShell (נקודת פתיחה וניווט)\"])"]
    seen_edges: set[tuple[str, str, str]] = set()
    for src, dst, label in edges:
        key = (src, dst, label)
        if key in seen_edges:
            continue
        seen_edges.add(key)
        lines.append(f"  {src} -->|\"{label}\"| {dst}")
    return "\n".join(lines) + "\n"


def build_visual_flow_html(screens: list[str], edges: list[tuple[str, str, str]]) -> str:
    """Build a self-contained visual flowchart (HTML/SVG) that renders cleanly offline without external CDNs."""
    edge_items = []
    for src, dst, label in edges:
        edge_items.append(
            f'<div class="flow-edge">'
            f'<span class="flow-node">{html.escape(src)}</span>'
            f'<span class="flow-arrow"><span class="flow-label">{html.escape(label)}</span>&#8594;</span>'
            f'<span class="flow-node flow-target">{html.escape(dst)}</span>'
            f"</div>"
        )
    screen_badges = "".join(f'<span class="screen-chip">{html.escape(s)}</span>' for s in screens)
    return (
        f'<div class="diagram-visual" dir="ltr">'
        f'<div class="chips-row"><strong>Screens ({len(screens)}):</strong> {screen_badges}</div>'
        f'<div class="flow-grid">{"".join(edge_items)}</div>'
        f"</div>"
    )


def build_visual_uml_html(classes: list[dict[str, object]]) -> str:
    """Build a self-contained visual UML class diagram (boxes with attributes, methods, and relationships)."""
    if not classes:
        classes = [
            {
                "name": "MainPage",
                "kind": "class",
                "layer": "Views",
                "bases": ["ContentPage"],
                "props": [],
                "methods": [("InitializeComponent", "void")],
                "deps": ["MainViewModel"],
            },
            {
                "name": "MainViewModel",
                "kind": "class",
                "layer": "ViewModels",
                "bases": ["INotifyPropertyChanged"],
                "props": [("IsLoading", "bool")],
                "methods": [("InitializeAsync", "Task")],
                "deps": [],
            },
        ]

    cards = []
    relations = []
    for c in classes:
        cname = html.escape(str(c["name"]))
        layer = html.escape(str(c.get("layer", "Other")))
        stereotype = "&lt;&lt;interface&gt;&gt; " if c.get("kind") == "interface" else ""
        props_html = "".join(
            f'<div class="uml-member">+ {html.escape(ptype)} <strong>{html.escape(pname)}</strong></div>'
            for pname, ptype in c.get("props", [])
        ) or '<div class="uml-empty">(no public properties)</div>'
        methods_html = "".join(
            f'<div class="uml-member">+ <strong>{html.escape(mname)}()</strong> : {html.escape(rtype)}</div>'
            for mname, rtype in c.get("methods", [])
        ) or '<div class="uml-empty">(no public methods)</div>'

        cards.append(
            f'<div class="uml-class-box">'
            f'<div class="uml-header"><span class="uml-layer">{layer}</span><div class="uml-title">{stereotype}{cname}</div></div>'
            f'<div class="uml-section">{props_html}</div>'
            f'<div class="uml-section">{methods_html}</div>'
            f"</div>"
        )
        for b in c.get("bases", []):
            relations.append(f'<span class="rel-badge">{cname} &#9651;&#8212; inherits/implements <strong>{html.escape(str(b))}</strong></span>')
        for d in c.get("deps", []):
            relations.append(f'<span class="rel-badge">{cname} &#8230;&gt; injects (DI) <strong>{html.escape(str(d))}</strong></span>')

    rel_block = f'<div class="uml-relations"><strong>Relationships &amp; DI Wiring:</strong> {"".join(relations)}</div>' if relations else ""
    return f'<div class="diagram-visual" dir="ltr"><div class="uml-grid">{"".join(cards)}</div>{rel_block}</div>'


def capture_diagram_images(html_path: Path, images_dir: Path) -> list[Path]:
    """Render Architecture-Preview.html to visual PNG files in Learning/Images/."""
    saved: list[Path] = []
    flow_png = images_dir / "Screen-Flow.png"
    uml_png = images_dir / "Architecture-UML.png"
    overview_png = images_dir / "Architecture-Overview.png"

    if importlib.util.find_spec("playwright") is not None:
        try:
            from playwright.sync_api import sync_playwright

            with sync_playwright() as pw:
                browser = pw.chromium.launch(headless=True)
                page = browser.new_page(viewport={"width": 1100, "height": 900}, device_scale_factor=2)
                page.goto(html_path.resolve().as_uri(), wait_until="networkidle")

                overview_loc = page.locator("[data-guide-overview]")
                if overview_loc.count() == 1:
                    overview_loc.screenshot(path=str(overview_png))
                    saved.append(overview_png)

                flow_loc = page.locator('[data-guide-block="screen-flow"]')
                if flow_loc.count() == 1:
                    flow_loc.screenshot(path=str(flow_png))
                    saved.append(flow_png)

                uml_loc = page.locator('[data-guide-block="uml-diagram"]')
                if uml_loc.count() == 1:
                    uml_loc.screenshot(path=str(uml_png))
                    saved.append(uml_png)

                browser.close()
                if flow_png.is_file() and uml_png.is_file():
                    return saved
        except Exception as exc:
            print(f"[INFO] Playwright diagram snapshot fallback ({exc}); trying browser CLI...")

    # Fallback: use system Chrome / Edge headless --screenshot if Playwright is not installed
    chrome_candidates = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/usr/bin/google-chrome",
        "/usr/bin/chromium-browser",
        "/usr/bin/chromium",
    ]
    chrome_bin = next((c for c in chrome_candidates if os.path.exists(c)), None)
    if chrome_bin:
        for target_png in (flow_png, uml_png):
            subprocess.run(
                [
                    chrome_bin,
                    "--headless=new",
                    "--disable-gpu",
                    "--window-size=1100,900",
                    f"--screenshot={target_png}",
                    html_path.resolve().as_uri(),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            if target_png.is_file() and target_png.stat().st_size > 0:
                saved.append(target_png)

    return saved


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate UML and Screen Flow diagrams, visual PNGs, and prompts for a MAUI project.")
    parser.add_argument("--project-root", default=str(Path(__file__).resolve().parent.parent), help="Project root path")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    diagrams_dir = project_root / "Learning/Diagrams"
    images_dir = project_root / "Learning/Images"
    diagrams_dir.mkdir(parents=True, exist_ok=True)
    images_dir.mkdir(parents=True, exist_ok=True)

    classes = scan_classes(project_root)
    screens, edges = scan_screen_flow(project_root)

    uml_mmd = build_uml_mermaid(classes)
    flow_mmd = build_screen_flow_mermaid(screens, edges)
    visual_flow = build_visual_flow_html(screens, edges)
    visual_uml = build_visual_uml_html(classes)

    uml_path = diagrams_dir / "Architecture-UML.mmd"
    flow_path = diagrams_dir / "Screen-Flow.mmd"
    prompts_path = diagrams_dir / "Architecture-Diagram-Prompts.md"
    html_path = diagrams_dir / "Architecture-Preview.html"

    uml_path.write_text(uml_mmd, encoding="utf-8")
    flow_path.write_text(flow_mmd, encoding="utf-8")

    html_content = f"""<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>תרשימי ארכיטקטורה — תיק פרויקט .NET MAUI</title>
  <style>
    body {{ font-family: 'Segoe UI', Tahoma, sans-serif; background: #f8fafc; color: #0f172a; margin: 24px; }}
    .card {{ background: white; border: 2px solid #cbd5e1; border-radius: 14px; padding: 22px; margin-bottom: 24px; box-shadow: 0 4px 10px rgba(15,23,42,0.05); }}
    h1, h2 {{ color: #0369a1; margin-top: 0; }}
    .diagram-visual {{ background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px; margin: 14px 0; }}
    .chips-row {{ margin-bottom: 14px; font-size: 13px; color: #334155; }}
    .screen-chip {{ display: inline-block; background: #e0f2fe; color: #0369a1; border: 1px solid #7dd3fc; border-radius: 999px; padding: 3px 12px; margin: 3px 4px; font-weight: 600; font-size: 12px; }}
    .flow-grid {{ display: flex; flex-direction: column; gap: 10px; }}
    .flow-edge {{ display: flex; align-items: center; gap: 12px; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 10px; padding: 10px 14px; }}
    .flow-node {{ background: #0284c7; color: white; font-weight: 700; padding: 6px 14px; border-radius: 8px; font-size: 13px; }}
    .flow-target {{ background: #0f172a; }}
    .flow-arrow {{ display: flex; flex-direction: column; align-items: center; color: #475569; font-weight: 600; font-size: 12px; min-width: 110px; }}
    .flow-label {{ background: #fef3c7; color: #92400e; border: 1px solid #fde68a; border-radius: 6px; padding: 1px 8px; font-size: 11px; margin-bottom: 2px; }}
    .uml-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 14px; }}
    .uml-class-box {{ border: 2px solid #0284c7; border-radius: 10px; background: #ffffff; overflow: hidden; }}
    .uml-header {{ background: #e0f2fe; padding: 8px 12px; border-bottom: 2px solid #0284c7; }}
    .uml-layer {{ font-size: 10px; text-transform: uppercase; font-weight: 700; color: #0369a1; background: #bae6fd; padding: 1px 6px; border-radius: 4px; }}
    .uml-title {{ font-size: 14px; font-weight: 800; color: #0c4a6e; margin-top: 4px; }}
    .uml-section {{ padding: 8px 12px; border-bottom: 1px solid #e2e8f0; font-family: Consolas, monospace; font-size: 11.5px; color: #1e293b; }}
    .uml-section:last-child {{ border-bottom: none; }}
    .uml-member {{ margin: 3px 0; }}
    .uml-empty {{ color: #94a3b8; font-style: italic; font-size: 11px; }}
    .uml-relations {{ margin-top: 14px; padding-top: 10px; border-top: 1px dashed #cbd5e1; display: flex; flex-wrap: wrap; gap: 8px; align-items: center; font-size: 12px; }}
    .rel-badge {{ background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 6px; padding: 4px 10px; color: #334155; }}
    pre {{ direction: ltr; text-align: left; background: #f1f5f9; padding: 12px; border-radius: 8px; overflow-x: auto; font-size: 12px; color: #334155; }}
  </style>
</head>
<body>
  <main data-guide-overview>
    <section class="card" data-guide-block="screen-flow">
      <h2>1. תרשים זרימת מסכים (Screen Flow Diagram)</h2>
      {visual_flow}
      <pre>{html.escape(flow_mmd)}</pre>
    </section>
    <section class="card" data-guide-block="uml-diagram">
      <h2>2. תרשים מחלקות (UML Class Diagram)</h2>
      {visual_uml}
      <pre>{html.escape(uml_mmd)}</pre>
    </section>
  </main>
</body>
</html>
"""
    html_path.write_text(html_content, encoding="utf-8")

    captured_pngs = capture_diagram_images(html_path, images_dir)

    flow_img_md = "\n![תרשים זרימת מסכים (Screen Flow)](../Images/Screen-Flow.png)\n" if (images_dir / "Screen-Flow.png").is_file() else ""
    uml_img_md = "\n![תרשים מחלקות (UML Class Diagram)](../Images/Architecture-UML.png)\n" if (images_dir / "Architecture-UML.png").is_file() else ""

    prompts_md = f"""# תרשימי ארכיטקטורה ופרומפטים לתיק הפרויקט (883589)

קובץ זה נוצר אוטומטית מתוך קוד הפרויקט על ידי `Generate-Architecture-Diagrams.py`.
הוא מכיל את **תרשים זרימת המסכים (Screen Flow Diagram)** ואת **תרשים המחלקות (UML Class Diagram)** — כולל **תמונות PNG ויזואליות מוכנות** (`Learning/Images/Screen-Flow.png` ו-`Learning/Images/Architecture-UML.png`) — לשילוב בפרק **"מבנה / ארכיטקטורה של הפרויקט"** בתיק הפרויקט ובספר הלמידה (`MAUI-Learning-Book.pdf`).

---

## 1. תרשים זרימת מסכים (Screen Flow Diagram)
{flow_img_md}
```mermaid
{flow_mmd.strip()}
```

### פרומפט שמור ליצירת תרשים זרימת המסכים בעיצוב גרפי:
> צור תרשים זרימת מסכים (Screen Flow Diagram) נקי וברור עבור אפליקציית .NET MAUI. מסך הפתיחה וההיררכיה הראשיים מנוהלים ב-`AppShell`, והמסכים בפרויקט הם: `{', '.join(screens)}`. הצג חיצים ברורים למעברי הניווט (`Shell.Current.GoToAsync`) בין המסכים לפי מבנה ה-Mermaid שלעיל.

---

## 2. תרשים מחלקות (UML Class Diagram)
{uml_img_md}
```mermaid
{uml_mmd.strip()}
```

### פרומפט שמור ליצירת תרשים ה-UML בעיצוב גרפי:
> צור תרשים מחלקות UML תקני (UML Class Diagram) המחולק לשכבות MVVM (`Models`, `Services`, `ViewModels`, `Views`) עבור פרויקט ה-.NET MAUI, כולל קשרי ירושה (`<|--`), הכלה, והזרקת תלויות בבנאי (`..> DI`), בהתבסס על הגדרת ה-Mermaid שלעיל.
"""
    prompts_path.write_text(prompts_md, encoding="utf-8")

    print(f"Generated Screen Flow Diagram: {flow_path}")
    print(f"Generated UML Class Diagram:   {uml_path}")
    print(f"Generated Saved Prompts:       {prompts_path}")
    print(f"Generated HTML Preview:        {html_path}")
    for png in captured_pngs:
        print(f"Generated Visual PNG Image:    {png}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
