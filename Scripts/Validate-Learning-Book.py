#!/usr/bin/env python3
"""Validate the HTML and PDF learning-book outputs before publication."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


DEFAULT_PLACEHOLDERS = (
    "<ScreenName>",
    "<AppNamespace>",
    "<Feature or Screen>",
    "<student-facing title>",
    "<observable result>",
    "<actual files, project names, and existing behavior>",
    "<connection to the agreed end goal>",
    "<fact>",
    "<small outcome>",
    "<concept>",
    "<hero/list/action/state>",
    "<actual path>",
    "<actual file path>",
    "<why it belongs here>",
    "<snapshot, test, or manual behavior>",
    "<small, meaningful name>",
    "<One student-facing sentence.>",
    "<View, ViewModel, Model, or Service rationale>",
    "<name>",
    "<One prediction, explanation, or small student-owned extension.>",
    "<Focused expected behavior, test, build, or validation command.>",
    "<next small change>",
    "<Repeat the same contract only for material blocks.>",
    "<a real trade-off in this project>",
    "<why this layer/layout/command owns the behavior>",
    "<a safe extension with a verification criterion>",
    "<official documentation used for a high-friction API or code/control>",
    "TODO: replace",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate MAUI learning-book HTML and PDF artifacts.")
    parser.add_argument("--html", required=True, help="Generated MAUI-Learning-Book.html")
    parser.add_argument("--pdf", required=True, help="Generated MAUI-Learning-Book.pdf")
    parser.add_argument("--report", required=True, help="JSON validation report destination")
    parser.add_argument("--project-root", default="", help="Optional project root for screen-image and PDF freshness checks")
    parser.add_argument("--placeholder", action="append", default=[], help="Additional token that must not appear in final output")
    return parser.parse_args()


def validate_screens_and_pdf_freshness(project_root: Path, pdf_path: Path) -> list[dict[str, object]]:
    issues: list[dict[str, object]] = []
    if not project_root.is_dir():
        return issues

    learning_dir = project_root / "Learning"
    images_dir = learning_dir / "Images"
    guides_dir = learning_dir / "Guides"

    # 1. Check PDF freshness against Markdown sources
    if pdf_path.is_file() and pdf_path.stat().st_size > 0:
        pdf_mtime = pdf_path.stat().st_mtime
        md_sources: list[Path] = []
        book_md = learning_dir / "MAUI-Learning-Book.md"
        if book_md.is_file():
            md_sources.append(book_md)
        if guides_dir.is_dir():
            md_sources.extend(sorted(guides_dir.glob("*.md")))
        for md_file in md_sources:
            if md_file.stat().st_mtime > pdf_mtime + 2.0:
                rel_md = md_file.relative_to(project_root).as_posix()
                issues.append(
                    {
                        "kind": "stale-pdf",
                        "message": f"Learning/MAUI-Learning-Book.pdf is older than '{rel_md}'; re-run Generate-Learning-Book-Pdf.py.",
                    }
                )

    # 2. Discover project screens from Views/*.xaml, *Page.xaml, and Learning/Guides/*-Guide.md
    excluded_parts = {".git", ".vs", "bin", "obj", "Scripts", ".agents", "Resources", "Platforms"}
    screens: dict[str, set[str]] = {}

    if guides_dir.is_dir():
        for guide in sorted(guides_dir.glob("*-Guide.md")):
            screen_key = guide.stem[: -len("-Guide")].strip()
            if screen_key and screen_key != "<ScreenName>":
                base_stem = re.sub(r"(Page|View)$", "", screen_key, flags=re.IGNORECASE) or screen_key
                screens.setdefault(screen_key, {screen_key.lower(), base_stem.lower()})

    for xaml in sorted(project_root.rglob("*.xaml")):
        try:
            rel_parts = xaml.relative_to(project_root).parts
        except ValueError:
            continue
        if any(p in excluded_parts for p in rel_parts):
            continue
        if xaml.name.lower() in {"app.xaml", "appshell.xaml", "styles.xaml", "colors.xaml"}:
            continue
        in_views = any(p.lower() == "views" for p in rel_parts[:-1])
        is_page = xaml.stem.lower().endswith("page")
        if in_views or is_page:
            screen_key = xaml.stem
            base_stem = re.sub(r"(Page|View)$", "", screen_key, flags=re.IGNORECASE) or screen_key
            # Avoid duplicate entries if e.g. both Habit and HabitPage exist
            matched_existing = None
            for existing_key, tokens in screens.items():
                if screen_key.lower() in tokens or base_stem.lower() in tokens:
                    matched_existing = existing_key
                    break
            if matched_existing:
                screens[matched_existing].update({screen_key.lower(), base_stem.lower()})
            else:
                screens[screen_key] = {screen_key.lower(), base_stem.lower()}

    image_exts = {".png", ".jpg", ".jpeg", ".webp", ".svg"}
    image_files: list[Path] = []
    if images_dir.is_dir():
        image_files = [p for p in sorted(images_dir.rglob("*")) if p.is_file() and p.suffix.lower() in image_exts and p.stat().st_size > 0]

    if screens:
        if not image_files:
            screen_list = ", ".join(sorted(screens.keys()))
            issues.append(
                {
                    "kind": "missing-images",
                    "message": f"No images found in Learning/Images/ for project screens ({screen_list}). Capture via MAUI DevFlow or HTML mockup + Capture-Mockup-Blocks.py.",
                }
            )
        else:
            for screen_key, candidate_tokens in screens.items():
                matched_imgs: list[Path] = []
                for img in image_files:
                    img_stem_low = img.stem.lower()
                    parent_low = img.parent.name.lower()
                    if any(
                        img_stem_low == tok
                        or img_stem_low.startswith(tok + "-")
                        or img_stem_low.startswith(tok + "_")
                        or tok in img_stem_low
                        or parent_low == tok
                        for tok in candidate_tokens
                    ):
                        matched_imgs.append(img)
                if not matched_imgs:
                    issues.append(
                        {
                            "kind": "missing-screen-image",
                            "message": f"No image found in Learning/Images/ for screen '{screen_key}' (capture live via MAUI DevFlow or fallback HTML mockup + Capture-Mockup-Blocks.py).",
                        }
                    )
                else:
                    # Verify that the screen does not ONLY have Windows desktop screenshots without an Android/mobile screenshot
                    non_windows_imgs = [
                        img for img in matched_imgs if "windows" not in img.stem.lower() and "desktop" not in img.stem.lower()
                    ]
                    if not non_windows_imgs:
                        issues.append(
                            {
                                "kind": "missing-android-screenshot",
                                "message": f"Screen '{screen_key}' only has Windows/desktop screenshot(s) in Learning/Images/. Bagrut 883589 requires Android smartphone visual evidence ('{screen_key}-android.png' via Android emulator/ADB/DevFlow or Capture-Mockup-Blocks.py).",
                            }
                        )

    # 3. Verify that if Architecture/UML Mermaid files exist in Learning/Diagrams/, visual PNG images also exist in Learning/Images/
    diagrams_dir = learning_dir / "Diagrams"
    if diagrams_dir.is_dir():
        if (diagrams_dir / "Screen-Flow.mmd").is_file() and not (images_dir / "Screen-Flow.png").is_file():
            issues.append(
                {
                    "kind": "missing-diagram-image",
                    "message": "Learning/Diagrams/Screen-Flow.mmd exists, but visual PNG 'Learning/Images/Screen-Flow.png' is missing. Run python Scripts/Generate-Architecture-Diagrams.py.",
                }
            )
        if (diagrams_dir / "Architecture-UML.mmd").is_file() and not (images_dir / "Architecture-UML.png").is_file():
            issues.append(
                {
                    "kind": "missing-diagram-image",
                    "message": "Learning/Diagrams/Architecture-UML.mmd exists, but visual PNG 'Learning/Images/Architecture-UML.png' is missing. Run python Scripts/Generate-Architecture-Diagrams.py.",
                }
            )

    return issues


def validate_html(html_path: Path) -> list[dict[str, object]]:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as error:
        raise RuntimeError("Playwright is required. Run: python -m pip install -r Scripts/Learning-Book-Requirements.txt; python -m playwright install chromium") from error

    if not html_path.is_file():
        return [{"kind": "missing-html", "message": f"Generated HTML was not found: {html_path}"}]

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1280, "height": 1800}, device_scale_factor=1)
        page.goto(html_path.resolve().as_uri(), wait_until="networkidle")
        page.emulate_media(media="print")
        issues = page.evaluate(
            """() => {
                const issues = [];
                for (const image of document.querySelectorAll('img')) {
                    if (!image.complete || image.naturalWidth === 0 || image.naturalHeight === 0) {
                        issues.push({ kind: 'image-not-rendered', message: image.getAttribute('src') || '(missing src)' });
                    }
                }
                for (const element of document.querySelectorAll('table, pre, .code-block, .embedded-img')) {
                    const style = getComputedStyle(element);
                    if (element.scrollWidth > element.clientWidth + 2) {
                        issues.push({ kind: 'horizontal-overflow', message: element.tagName.toLowerCase(), className: element.className });
                    }
                    if (style.overflowY !== 'visible' && element.scrollHeight > element.clientHeight + 2) {
                        issues.push({ kind: 'vertical-clipping', message: element.tagName.toLowerCase(), className: element.className });
                    }
                }
                if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 2) {
                    issues.push({ kind: 'document-overflow', message: 'The generated book is wider than the print viewport.' });
                }
                return issues;
            }"""
        )
        browser.close()
    return issues


def validate_pdf(pdf_path: Path, placeholders: tuple[str, ...]) -> list[dict[str, object]]:
    try:
        try:
            import pymupdf as fitz
        except ImportError:
            import fitz
    except ImportError as error:
        raise RuntimeError("PyMuPDF is required. Run: python -m pip install -r Scripts/Learning-Book-Requirements.txt") from error

    if not pdf_path.is_file() or pdf_path.stat().st_size == 0:
        return [{"kind": "missing-pdf", "message": f"Generated PDF was not found or is empty: {pdf_path}"}]

    issues: list[dict[str, object]] = []
    document = fitz.open(pdf_path)
    if document.page_count == 0:
        issues.append({"kind": "empty-pdf", "message": "The PDF has no pages."})

    for index, page in enumerate(document, start=1):
        page_text = page.get_text("text")
        blocks = page.get_text("blocks")
        has_images = bool(page.get_images(full=True))
        if not page_text.strip() and not has_images:
            issues.append({"kind": "blank-page", "page": index, "message": "The page has no text or images."})

        for block in blocks:
            x0, y0, x1, y1, text, *_ = block
            if text.strip() and (x0 < -1 or y0 < -1 or x1 > page.rect.width + 1 or y1 > page.rect.height + 1):
                issues.append({"kind": "text-outside-page", "page": index, "message": text.strip()[:80]})

        for placeholder in placeholders:
            if placeholder and placeholder in page_text:
                issues.append({"kind": "placeholder", "page": index, "message": placeholder})

    document.close()
    return issues


def main() -> int:
    args = parse_args()
    html_path = Path(args.html).resolve()
    pdf_path = Path(args.pdf).resolve()
    report_path = Path(args.report).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)

    if args.project_root:
        project_root = Path(args.project_root).resolve()
    elif pdf_path.parent.name.lower() == "learning":
        project_root = pdf_path.parent.parent.resolve()
    else:
        project_root = Path.cwd().resolve()

    report: dict[str, object] = {"html": str(html_path), "pdf": str(pdf_path), "issues": []}
    report["issues"].extend(validate_screens_and_pdf_freshness(project_root, pdf_path))
    try:
        report["issues"].extend(validate_html(html_path))
        report["issues"].extend(validate_pdf(pdf_path, tuple(DEFAULT_PLACEHOLDERS) + tuple(args.placeholder)))
    except RuntimeError as error:
        report["issues"].append({"kind": "dependency", "message": str(error)})

    report["passed"] = not report["issues"]
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if report["passed"]:
        print(f"PASS: learning-book validation report written to {report_path}")
        return 0

    print(f"FAIL: {len(report['issues'])} validation issue(s); see {report_path}", file=sys.stderr)
    for issue in report["issues"]:
        print(f"- {issue['kind']}: {issue['message']}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
