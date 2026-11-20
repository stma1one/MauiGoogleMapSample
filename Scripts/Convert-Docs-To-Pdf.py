#!/usr/bin/env python3
"""
Convert-Docs-To-Pdf.py
Converts all Markdown files in MauiGoogleMapSample/Docs (including Assignments/)
into clean, Hebrew RTL styled PDFs using Playwright Chromium.
"""
import sys
import html
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
@page { size: A4; margin: 18mm 16mm; }
body {
    font-family: 'Segoe UI', 'Arial', sans-serif;
    direction: rtl;
    text-align: right;
    color: #1e293b;
    line-height: 1.65;
    font-size: 11pt;
}
h1 {
    color: #3e2723;
    border-bottom: 3px solid #6d4c41;
    padding-bottom: 8px;
    font-size: 20pt;
    margin-top: 0;
}
h2 {
    color: #4e342e;
    border-bottom: 1px solid #cbd5e1;
    padding-bottom: 4px;
    margin-top: 22px;
    font-size: 14pt;
}
h3 { color: #5d4037; font-size: 12pt; margin-top: 16px; }
blockquote {
    background: #fef3c7;
    border-right: 4px solid #d97706;
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
    font-size: 9.5pt;
}
pre {
    background: #0f172a;
    color: #f8fafc;
    padding: 12px 14px;
    border-radius: 8px;
    direction: ltr;
    text-align: left;
    white-space: pre-wrap;
    word-break: break-word;
    font-size: 9pt;
    line-height: 1.45;
}
pre code {
    background: transparent;
    color: inherit;
    padding: 0;
}
table {
    width: 100%;
    border-collapse: collapse;
    margin: 14px 0;
    font-size: 10pt;
}
th, td {
    border: 1px solid #cbd5e1;
    padding: 8px 10px;
    text-align: right;
}
th {
    background: #5d4037;
    color: #ffffff;
}
tr:nth-child(even) { background: #f8fafc; }
a { color: #1d4ed8; }
"""

def convert_all(docs_root: Path) -> None:
    md_files = sorted(docs_root.rglob("*.md"))
    if not md_files:
        print(f"No .md files found under {docs_root}")
        return

    md_renderer = markdown_it.MarkdownIt("commonmark").enable("table")
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        for md_path in md_files:
            raw_md = md_path.read_text(encoding="utf-8")
            body_html = md_renderer.render(raw_md)
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
            pdf_path = md_path.with_suffix(".pdf")
            page.set_content(full_html, wait_until="networkidle")
            page.pdf(path=str(pdf_path), format="A4", print_background=True)
            print(f"[PDF] Generated {pdf_path}")
        browser.close()

if __name__ == "__main__":
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path("MauiGoogleMapSample/Docs").resolve()
    convert_all(root)
