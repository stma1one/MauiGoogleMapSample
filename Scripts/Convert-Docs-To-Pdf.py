#!/usr/bin/env python3
"""
Convert-Docs-To-Pdf.py
1. Converts all Markdown files in Learning/Docs (including Assignments/)
   into clean, Hebrew RTL styled PDFs in MauiGoogleMapSample/Docs/ using Playwright Chromium.
2. Highlights lines to add inside code blocks (lines starting with '+ ' or containing '◄ הוסף').
3. Embeds local images as base64 and supports inline SVG/HTML diagrams.
4. Exports Architecture-Overview.png, Architecture-UML.png, and Screen-Flow.png from
   Learning/Images/ as crisp Landscape A4 PDFs directly in MauiGoogleMapSample/Docs/.
"""
import sys
import re
import html
import base64
from pathlib import Path
import markdown_it
from playwright.sync_api import sync_playwright

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

CSS = """
@page { size: A4; margin: 16mm 15mm; }
body {
    font-family: 'Segoe UI', 'Arial', sans-serif;
    direction: rtl;
    text-align: right;
    color: #1e293b;
    line-height: 1.65;
    font-size: 10.5pt;
}
h1 {
    color: #3e2723;
    border-bottom: 3px solid #6d4c41;
    padding-bottom: 8px;
    font-size: 19pt;
    margin-top: 0;
}
h2 {
    color: #4e342e;
    border-bottom: 1px solid #cbd5e1;
    padding-bottom: 4px;
    margin-top: 20px;
    font-size: 13.5pt;
}
h3 { color: #5d4037; font-size: 11.5pt; margin-top: 14px; }
blockquote {
    background: #fef3c7;
    border-right: 4px solid #d97706;
    margin: 12px 0;
    padding: 10px 14px;
    border-radius: 6px;
}
.alert-important {
    background: #eff6ff;
    border-right: 4px solid #2563eb;
    margin: 12px 0;
    padding: 10px 14px;
    border-radius: 6px;
}
.alert-security {
    background: #fef2f2;
    border-right: 4px solid #dc2626;
    margin: 12px 0;
    padding: 10px 14px;
    border-radius: 6px;
}
code {
    font-family: Consolas, 'Courier New', monospace;
    background: #f1f5f9;
    padding: 1px 5px;
    border-radius: 4px;
    direction: ltr;
    unicode-bidi: embed;
    font-size: 9.2pt;
}
pre {
    background: #0f172a;
    color: #e2e8f0;
    padding: 12px 14px;
    border-radius: 8px;
    direction: ltr;
    text-align: left;
    white-space: pre-wrap;
    word-break: break-word;
    font-size: 8.8pt;
    line-height: 1.5;
    page-break-inside: avoid;
}
pre code {
    background: transparent;
    color: inherit;
    padding: 0;
    display: block;
}
.code-add-line {
    display: block;
    background: rgba(34, 197, 94, 0.28);
    border-left: 4px solid #4ade80;
    color: #fef08a;
    font-weight: 700;
    padding: 1px 6px;
    margin: 1px -6px;
    border-radius: 3px;
}
table {
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0;
    font-size: 9.8pt;
    page-break-inside: avoid;
}
th, td {
    border: 1px solid #cbd5e1;
    padding: 7px 10px;
    text-align: right;
}
th {
    background: #5d4037;
    color: #ffffff;
}
tr:nth-child(even) { background: #f8fafc; }
a { color: #1d4ed8; }
img {
    max-width: 100%;
    height: auto;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    margin: 10px 0;
}
.mvvm-box {
    background: #f8fafc;
    border: 1px solid #cbd5e1;
    border-radius: 10px;
    padding: 12px 14px;
    margin: 14px 0;
    page-break-inside: avoid;
    overflow: hidden;
}
.mvvm-flow {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    gap: 4px;
    margin-top: 10px;
}
.mvvm-layer {
    width: 100%;
    box-sizing: border-box;
    border-radius: 8px;
    padding: 8px 12px;
    text-align: right;
    font-size: 9.5pt;
    line-height: 1.45;
    border: 2px solid #cbd5e1;
    overflow-wrap: anywhere;
}
.mvvm-view { background: #dbeafe; border-color: #2563eb; }
.mvvm-vm { background: #fef3c7; border-color: #d97706; }
.mvvm-svc { background: #dcfce7; border-color: #16a34a; }
.mvvm-plat { background: #f3e8ff; border-color: #9333ea; }
.mvvm-arrow {
    text-align: center;
    font-size: 13pt;
    font-weight: 800;
    color: #475569;
    line-height: 1;
    padding: 1px 0;
}
"""

CODE_BLOCK_RE = re.compile(r"(<pre><code[^>]*>)(.*?)(</code></pre>)", re.DOTALL)
IMG_RE = re.compile(r'<img\s+src="([^"]+)"([^>]*)>')

def highlight_added_lines(html_body: str) -> str:
    """Highlights added lines inside <pre><code> ONLY when mixed with existing context lines."""
    def repl(match: re.Match) -> str:
        open_tag, inner, close_tag = match.groups()
        lines = inner.split("\n")
        non_empty = [l for l in lines if l.strip()]
        marked = [l for l in non_empty if "◄ הוסף" in l or l.startswith("+ ")]
        all_lines_are_new = len(non_empty) > 0 and len(marked) == len(non_empty)

        processed = []
        for line in lines:
            is_marked = "◄ הוסף" in line or line.startswith("+ ")
            clean_line = line[2:] if line.startswith("+ ") else line
            if is_marked and not all_lines_are_new:
                processed.append(f'<span class="code-add-line">{clean_line}</span>')
            else:
                processed.append(clean_line)
        return open_tag + "\n".join(processed) + close_tag

    return CODE_BLOCK_RE.sub(repl, html_body)

def embed_local_images(html_body: str, md_dir: Path, project_root: Path) -> str:
    """Embeds local images as base64 data URIs."""
    def repl(match: re.Match) -> str:
        src, rest = match.groups()
        if src.startswith(("http://", "https://", "data:")):
            return match.group(0)
        candidates = [
            (md_dir / src).resolve(),
            (project_root / "Learning" / "Images" / Path(src).name).resolve(),
        ]
        for cand in candidates:
            if cand.is_file():
                ext = cand.suffix.lstrip(".").lower()
                if ext == "jpg":
                    ext = "jpeg"
                b64 = base64.b64encode(cand.read_bytes()).decode("ascii")
                return f'<img src="data:image/{ext};base64,{b64}"{rest}>'
        return match.group(0)

    return IMG_RE.sub(repl, html_body)

def export_diagram_pdfs(page, project_root: Path, output_pdf_root: Path) -> None:
    """Exports key architecture/UML/screen-flow PNGs as dedicated Landscape A4 PDFs in Docs/."""
    diagrams = [
        ("Architecture-Overview.png", "Architecture-Overview.pdf", "דיאגרמת ארכיטקטורה כללית — CoffeeMap (.NET MAUI)"),
        ("Architecture-UML.png", "Architecture-UML.pdf", "דיאגרמת מחלקות (UML) — CoffeeMap (.NET MAUI)"),
        ("Screen-Flow.png", "Screen-Flow.pdf", "תרשים זרימת מסכים (Screen Flow) — CoffeeMap (.NET MAUI)"),
    ]
    images_dir = project_root / "Learning" / "Images"
    for png_name, pdf_name, title in diagrams:
        png_path = images_dir / png_name
        if not png_path.is_file():
            continue
        b64 = base64.b64encode(png_path.read_bytes()).decode("ascii")
        diagram_html = f"""<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
<meta charset="UTF-8" />
<title>{html.escape(title)}</title>
<style>
@page {{ size: A4 landscape; margin: 12mm; }}
body {{
    font-family: 'Segoe UI', 'Arial', sans-serif;
    direction: rtl;
    text-align: center;
    margin: 0;
    color: #1e293b;
}}
h1 {{
    color: #3e2723;
    border-bottom: 2px solid #6d4c41;
    padding-bottom: 6px;
    margin: 0 0 12px 0;
    font-size: 16pt;
}}
img {{
    max-width: 100%;
    max-height: 168mm;
    object-fit: contain;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
}}
</style>
</head>
<body>
<h1>{html.escape(title)}</h1>
<img src="data:image/png;base64,{b64}" alt="{html.escape(title)}" />
</body>
</html>"""
        pdf_path = output_pdf_root / pdf_name
        page.set_content(diagram_html, wait_until="networkidle")
        page.pdf(path=str(pdf_path), format="A4", landscape=True, print_background=True)
        print(f"[PDF] Generated Diagram {pdf_path}")

def convert_all(source_md_root: Path, output_pdf_root: Path) -> None:
    project_root = Path.cwd().resolve()
    md_files = sorted(source_md_root.rglob("*.md"))
    if not md_files:
        print(f"No .md files found under {source_md_root}")
        return

    md_renderer = markdown_it.MarkdownIt("commonmark", {"html": True}).enable("table")
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        for md_path in md_files:
            rel_path = md_path.relative_to(source_md_root)
            pdf_path = (output_pdf_root / rel_path).with_suffix(".pdf")
            pdf_path.parent.mkdir(parents=True, exist_ok=True)

            raw_md = md_path.read_text(encoding="utf-8")
            body_html = md_renderer.render(raw_md)
            body_html = highlight_added_lines(body_html)
            body_html = embed_local_images(body_html, md_path.parent, project_root)

            full_html = f"""<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
<meta charset="UTF-8" />
<title>{html.escape(md_path.stem)}</title>
<style>{CSS}</style>
</head>
<body>
{body_html}
</body>
</html>"""
            page.set_content(full_html, wait_until="networkidle")
            page.pdf(path=str(pdf_path), format="A4", print_background=True)
            print(f"[PDF] Generated {pdf_path}")

        export_diagram_pdfs(page, project_root, output_pdf_root)
        browser.close()

if __name__ == "__main__":
    src = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path("Learning/Docs").resolve()
    dst = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path("MauiGoogleMapSample/Docs").resolve()
    convert_all(src, dst)
