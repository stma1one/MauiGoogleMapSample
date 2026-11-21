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
    break-inside: avoid;
    page-break-inside: avoid;
}
.alert-important {
    background: #eff6ff;
    border-right: 4px solid #2563eb;
    margin: 12px 0;
    padding: 10px 14px;
    border-radius: 6px;
    break-inside: avoid;
    page-break-inside: avoid;
}
.alert-security {
    background: #fef2f2;
    border-right: 4px solid #dc2626;
    margin: 12px 0;
    padding: 10px 14px;
    border-radius: 6px;
    break-inside: avoid;
    page-break-inside: avoid;
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
    table-layout: fixed;
    border-collapse: collapse;
    margin: 12px 0;
    font-size: 9.2pt;
    page-break-inside: avoid;
}
th, td {
    border: 1px solid #cbd5e1;
    padding: 7px 8px;
    text-align: right;
    vertical-align: top;
    overflow-wrap: anywhere;
    word-break: break-word;
}
th {
    background: #5d4037;
    color: #ffffff;
}
th code {
    background: rgba(255, 255, 255, 0.22);
    color: #ffffff;
    white-space: normal;
}
td code {
    white-space: normal;
    overflow-wrap: anywhere;
    word-break: break-word;
}
tr:nth-child(even) { background: #f8fafc; }
a { color: #1d4ed8; }
img {
    max-width: 100%;
    max-height: 135mm;
    width: auto;
    height: auto;
    display: block;
    margin: 12px auto;
    border: 1px solid #cbd5e1;
    border-radius: 10px;
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
    """Exports true horizontal (wide Landscape A4) Architecture, UML, and Screen Flow PDFs in Docs/."""
    base_css = """
@page { size: A4 landscape; margin: 10mm 12mm; }
* { box-sizing: border-box; }
body {
    font-family: 'Segoe UI', 'Arial', sans-serif;
    direction: rtl;
    margin: 0;
    color: #0f172a;
    background: #ffffff;
}
h1 {
    color: #3e2723;
    border-bottom: 3px solid #6d4c41;
    padding-bottom: 6px;
    margin: 0 0 12px 0;
    font-size: 16pt;
    text-align: center;
}
.subtitle {
    text-align: center;
    font-size: 9.5pt;
    color: #475569;
    margin: -6px 0 12px 0;
}
code {
    font-family: Consolas, 'Courier New', monospace;
    direction: ltr;
    unicode-bidi: embed;
    font-size: 8.5pt;
}
.cols-4 {
    display: grid;
    grid-template-columns: 1fr 22px 1fr 22px 1fr 22px 1fr;
    align-items: stretch;
    gap: 6px;
}
.col-arrow {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18pt;
    font-weight: 800;
    color: #64748b;
}
.layer-col {
    border-radius: 10px;
    padding: 10px;
    border: 2px solid #cbd5e1;
    display: flex;
    flex-direction: column;
    gap: 8px;
}
.layer-header {
    font-weight: 800;
    font-size: 11pt;
    text-align: center;
    padding-bottom: 6px;
    border-bottom: 1px solid rgba(0,0,0,0.12);
}
.card {
    background: rgba(255,255,255,0.92);
    border: 1px solid rgba(0,0,0,0.15);
    border-radius: 7px;
    padding: 7px 9px;
    font-size: 8.5pt;
    line-height: 1.4;
}
.card-title {
    font-weight: 700;
    font-family: Consolas, monospace;
    direction: ltr;
    text-align: left;
    font-size: 8.8pt;
    color: #1e293b;
    margin-bottom: 3px;
}
.c-view { background: #eff6ff; border-color: #2563eb; }
.c-vm { background: #fffbeb; border-color: #d97706; }
.c-svc { background: #f0fdf4; border-color: #16a34a; }
.c-mod { background: #faf5ff; border-color: #9333ea; }
.uml-grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 8px;
    margin-bottom: 10px;
}
.uml-card {
    border: 1.5px solid #475569;
    border-radius: 7px;
    overflow: hidden;
    background: #fff;
    font-size: 7.8pt;
    direction: ltr;
    text-align: left;
}
.uml-head {
    padding: 5px 7px;
    font-weight: 800;
    font-family: Consolas, monospace;
    color: #fff;
    font-size: 8pt;
}
.uml-sec {
    padding: 4px 7px;
    border-top: 1px solid #cbd5e1;
    font-family: Consolas, monospace;
    line-height: 1.38;
}
.flow-wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 14px;
    margin-top: 12px;
}
.shell-root {
    background: #5d4037;
    color: #fff;
    padding: 12px 28px;
    border-radius: 12px;
    font-size: 12pt;
    font-weight: 800;
    text-align: center;
    box-shadow: 0 4px 10px rgba(0,0,0,0.12);
}
.flow-row {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 10px;
    width: 100%;
}
.stage-card {
    border: 2px solid #6d4c41;
    border-radius: 10px;
    padding: 10px;
    background: #f8fafc;
    text-align: center;
    display: flex;
    flex-direction: column;
    gap: 6px;
}
.stage-badge {
    background: #6d4c41;
    color: #fff;
    border-radius: 14px;
    padding: 3px 10px;
    font-size: 8.5pt;
    font-weight: 700;
    align-self: center;
}
.stage-page {
    font-family: Consolas, monospace;
    font-weight: 800;
    font-size: 9.5pt;
    color: #1e3a8a;
    direction: ltr;
}
.stage-desc { font-size: 8.5pt; color: #334155; line-height: 1.45; }
.stage-branch {
    font-family: Consolas, monospace;
    font-size: 7.5pt;
    background: #e2e8f0;
    padding: 3px 5px;
    border-radius: 4px;
    direction: ltr;
    color: #0f172a;
    margin-top: auto;
}
"""

    arch_html = f"""<!DOCTYPE html><html lang="he" dir="rtl"><head><meta charset="UTF-8" /><style>{base_css}</style></head><body>
<h1>דיאגרמת ארכיטקטורה כללית — CoffeeMap (.NET MAUI Vanilla MVVM)</h1>
<div class="subtitle">זרימה אופקית בין השכבות (מוזרק דרך <code>MauiProgram.cs</code> באמצעות Fluent Builder: <code>RegisterServices</code> / <code>RegisterViewModels</code> / <code>RegisterViews</code>)</div>
<div class="cols-4">
  <div class="layer-col c-view">
    <div class="layer-header">1. Views (תצוגה — XAML)</div>
    <div class="card"><div class="card-title">AppShell.xaml</div>תפריט <code>Flyout</code> עם 5 מסכים ואייקונים</div>
    <div class="card"><div class="card-title">MainPage.xaml</div>שלב 1: רשימת בדיקה ואימות מפתח</div>
    <div class="card"><div class="card-title">MapDisplayPage.xaml</div>שלב 2: <code>&lt;maps:Map&gt;</code>, סוגי מפה וזום</div>
    <div class="card"><div class="card-title">CoffeePinsPage.xaml</div>שלב 3: סיכות <code>&lt;maps:Pin&gt;</code> וסינון חי</div>
    <div class="card"><div class="card-title">UserLocationPage.xaml</div>שלב 4: <code>IsShowingUser</code> ו-GPS</div>
    <div class="card"><div class="card-title">CoffeeRoutesPage.xaml</div>שלב 5: <code>Polyline</code> + <code>Circle</code></div>
  </div>
  <div class="col-arrow">⇄</div>
  <div class="layer-col c-vm">
    <div class="layer-header">2. ViewModels (מצב ופקודות)</div>
    <div class="card"><div class="card-title">BaseViewModel</div>מממש <code>INotifyPropertyChanged</code> + <code>IsLoading</code></div>
    <div class="card"><div class="card-title">SetupStatusViewModel</div>בדיקת פורמט מפתח + <code>CanExecute</code></div>
    <div class="card"><div class="card-title">MapDisplayViewModel</div>סוג מפה, זום + <code>MoveToRegionRequested</code></div>
    <div class="card"><div class="card-title">CoffeePinsViewModel</div><code>ObservableCollection</code> + חיפוש וסינון</div>
    <div class="card"><div class="card-title">UserLocationViewModel</div><code>async</code> GPS + תחנה קרובה</div>
    <div class="card"><div class="card-title">CoffeeRoutesViewModel</div>שכבות מסלול + <code>MapElementsChanged</code></div>
  </div>
  <div class="col-arrow">←</div>
  <div class="layer-col c-svc">
    <div class="layer-header">3. Services (לוגיקה ושירותים)</div>
    <div class="card"><div class="card-title">MapConfigurationValidator</div>אימות מפתח API (ריק / Placeholder / אורך)</div>
    <div class="card"><div class="card-title">CoffeeRegionService</div>אזורי קפה + <code>MapSpan.FromCenterAndRadius</code></div>
    <div class="card"><div class="card-title">CoffeeStationService</div>מאגר תחנות קפה וסינון לפי התמחות</div>
    <div class="card"><div class="card-title">LocationService</div>הרשאות זמן ריצה, <code>Geolocation</code> ומרחקים</div>
    <div class="card"><div class="card-title">CoffeeRouteService</div>בניית <code>Polyline</code>, <code>Circle</code> וחישוב מרחק</div>
  </div>
  <div class="col-arrow">←</div>
  <div class="layer-col c-mod">
    <div class="layer-header">4. Models, Platform &amp; Tests</div>
    <div class="card"><div class="card-title">Models/</div><code>CoffeeRegion</code>, <code>CoffeeStation</code></div>
    <div class="card"><div class="card-title">Platforms/Android/</div><code>AndroidManifest.xml</code> (הרשאות + <code>${{GoogleMapsApiKey}}</code>)</div>
    <div class="card"><div class="card-title">Secrets.props (.gitignore)</div>הזרקת API Key בזמן Build דרך <code>.csproj</code></div>
    <div class="card"><div class="card-title">MauiGoogleMapSample.Tests</div>31 בדיקות יחידה ב-<code>xunit.v3</code> (AAA)</div>
  </div>
</div>
</body></html>"""

    uml_html = f"""<!DOCTYPE html><html lang="he" dir="rtl"><head><meta charset="UTF-8" /><style>{base_css}</style></head><body>
<h1>דיאגרמת מחלקות (UML Class Diagram) — CoffeeMap</h1>
<div class="subtitle">מבנה אופקי מלא: ViewModels (שורה עליונה) → Services &amp; Interfaces (שורה אמצעית) → Models (שורה תחתונה)</div>

<div class="uml-grid">
  <div class="uml-card">
    <div class="uml-head" style="background:#b45309;">SetupStatusViewModel : BaseViewModel</div>
    <div class="uml-sec">+ ApiKeyInput : string<br/>+ StatusTitle : string<br/>+ IsConfigured : bool</div>
    <div class="uml-sec">+ ValidateKeyCommand : ICommand<br/>+ ResetToPlaceholderCommand : ICommand</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#b45309;">MapDisplayViewModel : BaseViewModel</div>
    <div class="uml-sec">+ Regions : ObservableCollection<br/>+ SelectedMapType : MapType<br/>+ ZoomRadiusKm : double</div>
    <div class="uml-sec">+ SetMapTypeCommand<br/>+ ZoomIn/OutCommand<br/>+ event MoveToRegionRequested</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#b45309;">CoffeePinsViewModel : BaseViewModel</div>
    <div class="uml-sec">+ Stations : ObservableCollection<br/>+ SearchQuery : string<br/>+ SelectedStation : CoffeeStation?</div>
    <div class="uml-sec">+ FilterCommand<br/>+ ClearFilterCommand<br/>+ SelectStationByNameCommand</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#b45309;">UserLocationViewModel : BaseViewModel</div>
    <div class="uml-sec">+ IsShowingUser : bool<br/>+ LocationStatus : string<br/>+ NearestStationSummary : string</div>
    <div class="uml-sec">+ LocateMeCommand : ICommand<br/>+ ExecuteLocateMeAsync()<br/>+ event MoveToRegionRequested</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#b45309;">CoffeeRoutesViewModel : BaseViewModel</div>
    <div class="uml-sec">+ ShowRoute : bool<br/>+ ShowDeliveryZone : bool<br/>+ TotalTourDistanceKm : double</div>
    <div class="uml-sec">+ ToggleRoute/ZoneCommand<br/>+ BuildActiveMapElements()<br/>+ event MapElementsChanged</div>
  </div>
</div>

<div class="uml-grid">
  <div class="uml-card">
    <div class="uml-head" style="background:#15803d;">«interface» IMapConfigurationValidator</div>
    <div class="uml-sec">+ PlaceholderKey : string</div>
    <div class="uml-sec">+ ValidateApiKey(string?) : MapConfigCheckResult</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#15803d;">«interface» ICoffeeRegionService</div>
    <div class="uml-sec">Impl: CoffeeRegionService</div>
    <div class="uml-sec">+ GetDefaultRegions()<br/>+ BuildMapSpan(region, radius?)</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#15803d;">«interface» ICoffeeStationService</div>
    <div class="uml-sec">Impl: CoffeeStationService</div>
    <div class="uml-sec">+ GetStations()<br/>+ FilterStations(string? query)</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#15803d;">«interface» ILocationService</div>
    <div class="uml-sec">Impl: LocationService</div>
    <div class="uml-sec">+ GetCurrentLocationAsync()<br/>+ CalculateDistanceKm(a, b)<br/>+ FindNearestStation(loc, list)</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#15803d;">«interface» ICoffeeRouteService</div>
    <div class="uml-sec">Impl: CoffeeRouteService</div>
    <div class="uml-sec">+ BuildCoffeeTourPolyline()<br/>+ BuildDeliveryZoneCircle()<br/>+ CalculateTotalTourDistanceKm()</div>
  </div>
</div>

<div class="uml-grid" style="grid-template-columns: repeat(3, 1fr);">
  <div class="uml-card">
    <div class="uml-head" style="background:#7e22ce;">BaseViewModel : INotifyPropertyChanged</div>
    <div class="uml-sec">+ IsLoading : bool<br/>+ Title : string<br/>+ event PropertyChanged</div>
    <div class="uml-sec"># OnPropertyChanged([CallerMemberName])</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#7e22ce;">CoffeeRegion (Model)</div>
    <div class="uml-sec">+ Name : string<br/>+ Description : string<br/>+ Latitude / Longitude : double<br/>+ DefaultRadiusKm : double</div>
  </div>
  <div class="uml-card">
    <div class="uml-head" style="background:#7e22ce;">CoffeeStation (Model)</div>
    <div class="uml-sec">+ Id, Name, Address, Specialty : string<br/>+ Rating, Latitude, Longitude : double<br/>+ Location : Location (computed)</div>
  </div>
</div>
</body></html>"""

    flow_html = f"""<!DOCTYPE html><html lang="he" dir="rtl"><head><meta charset="UTF-8" /><style>{base_css}</style></head><body>
<h1>תרשים זרימת מסכים (Screen Flow) — CoffeeMap</h1>
<div class="subtitle">ניווט באמצעות <code>AppShell</code> (תפריט <code>Flyout</code> צדדי בעברית עם אייקונים וקטוריים לכל שלב)</div>
<div class="flow-wrap">
  <div class="shell-root">☕ AppShell.xaml — תפריט Flyout ראשי (FlowDirection="RightToLeft")</div>
  <div style="font-size:18pt; color:#6d4c41; font-weight:800; line-height:1;">↙ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↓ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↓ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↓ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↘</div>
  <div class="flow-row">
    <div class="stage-card">
      <div class="stage-badge">שלב 1 • הגדרות</div>
      <div class="stage-page">MainPage</div>
      <div class="stage-desc">התקנת <code>Maps</code>, הרשאות <code>AndroidManifest</code>, הזרקת <code>Secrets.props</code> ואימות מפתח API</div>
      <div class="stage-branch">stage/01-setup-and-permissions</div>
    </div>
    <div class="stage-card">
      <div class="stage-badge">שלב 2 • מפה</div>
      <div class="stage-page">MapDisplayPage</div>
      <div class="stage-desc">הצגת <code>&lt;maps:Map&gt;</code>, סוגי מפה (<code>Street</code>/<code>Satellite</code>/<code>Hybrid</code>), זום ובחירת עיר (<code>MapSpan</code>)</div>
      <div class="stage-branch">stage/02-map-display-and-types</div>
    </div>
    <div class="stage-card">
      <div class="stage-badge">שלב 3 • סיכות</div>
      <div class="stage-page">CoffeePinsPage</div>
      <div class="stage-desc">קישור <code>ItemsSource</code> + <code>&lt;maps:Pin&gt;</code>, סינון חי, ואירועי <code>MarkerClicked</code> / <code>InfoWindowClicked</code></div>
      <div class="stage-branch">stage/03-pins-and-callouts</div>
    </div>
    <div class="stage-card">
      <div class="stage-badge">שלב 4 • GPS</div>
      <div class="stage-page">UserLocationPage</div>
      <div class="stage-desc">הרשאות זמן ריצה, <code>Geolocation</code>, נקודה כחולה (<code>IsShowingUser</code>) וחישוב התחנה הקרובה</div>
      <div class="stage-branch">stage/04-gps-and-user-location</div>
    </div>
    <div class="stage-card">
      <div class="stage-badge">שלב 5 • מסלולים</div>
      <div class="stage-page">CoffeeRoutesPage</div>
      <div class="stage-desc">שכבות <code>MapElements</code>: מסלול קפה (<code>Polyline</code>), אזור משלוחים (<code>Circle</code>) ואורך מסלול</div>
      <div class="stage-branch">stage/05-shapes-and-routes</div>
    </div>
  </div>
</div>
</body></html>"""

    outputs = [
        ("Architecture-Overview.pdf", arch_html),
        ("Architecture-UML.pdf", uml_html),
        ("Screen-Flow.pdf", flow_html),
    ]
    for pdf_name, doc_html in outputs:
        pdf_path = output_pdf_root / pdf_name
        page.set_content(doc_html, wait_until="networkidle")
        page.pdf(path=str(pdf_path), format="A4", landscape=True, print_background=True)
        print(f"[PDF] Generated Horizontal Landscape Diagram {pdf_path}")

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
