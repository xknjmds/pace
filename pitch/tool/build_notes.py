#!/usr/bin/env python3
"""Build pitch/presenter-notes.html and .pdf from pitch/deck.html.

Reads each slide's headline, pastel and <aside class="notes">, plus the TEAM
block, takes a thumbnail of every slide with headless Chrome, and prints the
notes to PDF. Re-run after editing the deck or the TEAM block:

    python3 pitch/tool/build_notes.py            # thumbnails + PDF
    python3 pitch/tool/build_notes.py --no-thumbs
"""
import html
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

PITCH = Path(__file__).resolve().parent.parent
DECK = PITCH / "deck.html"
OUT_HTML = PITCH / "presenter-notes.html"
OUT_PDF = PITCH / "presenter-notes.pdf"
THUMBS = PITCH / "build" / "thumbs"

CHROME = next(
    (c for c in ("google-chrome", "chromium", "chromium-browser", "google-chrome-stable") if shutil.which(c)),
    None,
)

src = DECK.read_text(encoding="utf-8")
team = json.loads(re.search(r'<script id="team" type="application/json">(.*?)</script>', src, re.S).group(1))
members = team.get("members", [])


def text(fragment: str) -> str:
    fragment = re.sub(r"<br\s*/?>", " ", fragment)
    return html.unescape(re.sub(r"<[^>]+>", "", fragment)).strip()


def ph(s: str) -> str:
    """Escape, then show any [placeholder] as a dashed chip."""
    return re.sub(r"\[([^\]]+)\]", r'<em class="placeholder">[\1]</em>', s)


def fill_team(fragment: str) -> str:
    for key, token in (("teamName", "[Team name]"), ("school", "[Our school]")):
        val = team.get(key, token)
        fragment = fragment.replace(token, html.escape(val))
    return fragment


def secs(t: str) -> int:
    m, s = t.split(":")
    return int(m) * 60 + int(s)


def presenter_for(n: int) -> str:
    for m in members:
        for part in re.findall(r"(\d+)\s*[–-]\s*(\d+)|(\d+)", m.get("presents", "")):
            a, b, one = part
            lo, hi = (int(a), int(b)) if a else (int(one), int(one))
            if lo <= n <= hi:
                return m["name"]
    return "[Member]"


slides = []
for i, m in enumerate(re.finditer(r'<section class="slide (p-\w+)" data-label="([^"]*)" data-time="([^"]*)">(.*?)</section>', src, re.S), 1):
    pastel, label, time, body = m.groups()
    h1 = re.search(r"<h1[^>]*>(.*?)</h1>", body, re.S)
    headline = text(h1.group(1)) if h1 and text(h1.group(1)) else ""
    if not headline:
        headline = team.get("teamName", "[Team name]") if label == "Team" else "PACE: Progress Always Comes Eventually"
    notes = re.search(r'<aside class="notes"[^>]*>(.*?)</aside>', body, re.S).group(1).strip()
    icon = re.search(r'class="eyebrow[^"]*".*?<span class="ms">(\w+)</span>', body, re.S)
    slides.append(dict(n=i, pastel=pastel, label=html.unescape(label), time=time, headline=headline,
                       notes=fill_team(notes), icon=icon.group(1) if icon else "wb_sunny"))

total = sum(secs(s["time"]) for s in slides)

# ---- Thumbnails ----
want_thumbs = "--no-thumbs" not in sys.argv and CHROME
if want_thumbs:
    THUMBS.mkdir(parents=True, exist_ok=True)
    for s in slides:
        out = THUMBS / f"slide-{s['n']:02d}.png"
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--window-size=1600,900",
                        "--virtual-time-budget=3000", f"--screenshot={out}",
                        f"{DECK.as_uri()}?still&theme=light#{s['n']}"],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# ---- HTML ----
member_rows = "".join(
    f"<tr><td>{ph(html.escape(m['name']))}</td>"
    f"<td class='tab'>{html.escape(m.get('presents', ''))}</td></tr>"
    for m in members
)
run_rows = "".join(
    f"<tr><td class='tab'>{s['n']}</td><td>{html.escape(s['label'])}</td>"
    f"<td>{ph(html.escape(presenter_for(s['n'])))}</td><td class='tab'>{s['time']}</td></tr>"
    for s in slides
)


def slide_block(s):
    thumb = (f'<img class="thumb" src="build/thumbs/slide-{s["n"]:02d}.png" alt="Slide {s["n"]}">'
             if want_thumbs else f'<div class="thumb ph {s["pastel"]}"><span>{s["n"]}</span></div>')
    return f"""
<article class="card">
  <header>
    <span class="chip {s['pastel']}"><span class="ms">{s['icon']}</span></span>
    <div class="h"><div class="lbl">Slide {s['n']} · {html.escape(s['label'])}</div>
    <div class="title">{ph(html.escape(s['headline']))}</div></div>
    <span class="stadium tab">{s['time']}</span>
  </header>
  <div class="row">{thumb}<div class="notes">{ph(s['notes'])}
    <p class="who">Presents: {ph(html.escape(presenter_for(s['n'])))}</p></div></div>
</article>"""


page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PACE Presenter Notes</title>
<style>
@font-face {{ font-family: Figtree; src: url(assets/fonts/Figtree-Regular.ttf); font-weight: 400; }}
@font-face {{ font-family: Figtree; src: url(assets/fonts/Figtree-Medium.ttf); font-weight: 500; }}
@font-face {{ font-family: Figtree; src: url(assets/fonts/Figtree-SemiBold.ttf); font-weight: 600; }}
@font-face {{ font-family: Figtree; src: url(assets/fonts/Figtree-Bold.ttf); font-weight: 700; }}
@font-face {{ font-family: "Material Symbols Rounded"; src: url(assets/fonts/MaterialSymbolsRounded-subset.woff2) format("woff2"); font-weight: 400 600; font-display: block; }}
:root {{
  --page: #FAF8F5; --card: #FFFFFF; --sunken: #F1EEE9; --text: #26282C; --soft: #64666C; --line: #86898F; --line-soft: #E6E2DC;
  --mint: #DCEAE3; --accent: #35665A; --lift: 0 1px 3px #1C1D201A;
}}
.p-morning  {{ --fill: #F7E8CC; --ink: #8A5E14; }}
.p-leave    {{ --fill: #DCEAE3; --ink: #2B5A4E; }}
.p-deadline {{ --fill: #F0E4D2; --ink: #7A5634; }}
.p-focus    {{ --fill: #DCE8EF; --ink: #365D73; }}
.p-evening  {{ --fill: #E7E2F0; --ink: #55497A; }}
.p-calm     {{ --fill: #E4EAE3; --ink: #465C52; }}
@page {{ size: A4; margin: 14mm 14mm 16mm; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
body {{ background: var(--page); color: var(--text); font: 400 10.5pt/1.5 Figtree, system-ui, sans-serif; letter-spacing: .1px; padding: 0; }}
@media screen {{ body {{ max-width: 820px; margin: 0 auto; padding: 32px 16px 64px; }} }}
.ms {{ font-family: "Material Symbols Rounded"; font-weight: normal; font-style: normal; line-height: 1; display: inline-block; font-feature-settings: "liga"; font-variation-settings: "FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24; }}
.tab {{ font-variant-numeric: tabular-nums; }}
h1 {{ font-size: 24pt; font-weight: 700; letter-spacing: -0.016em; line-height: 1.1; }}
h2 {{ font-size: 13pt; font-weight: 600; margin: 0 0 8px; }}
.sub {{ color: var(--soft); font-size: 12pt; margin-top: 4px; }}
.cover {{ display: flex; align-items: center; gap: 18px; margin-bottom: 14px; }}
@media print {{ body {{ background: #FFFFFF; }} }}
.cover img {{ width: 80px; height: 80px; }}
.card {{ background: var(--card); border-radius: 18px; box-shadow: var(--lift); border: 1px solid var(--line-soft); padding: 14px 16px 16px; margin-bottom: 12px; break-inside: avoid; }}
table {{ width: 100%; border-collapse: collapse; }}
th {{ text-align: left; font-size: 8pt; font-weight: 600; letter-spacing: .4px; text-transform: uppercase; color: var(--soft); padding: 4px 8px; }}
td {{ padding: 4px 8px; border-top: 1px solid var(--line-soft); vertical-align: top; }}
.two {{ display: grid; grid-template-columns: 1.15fr 1fr; gap: 12px; break-inside: avoid; }}
.stadium {{ display: inline-flex; align-items: center; height: 24px; padding: 0 12px; border-radius: 999px; background: var(--mint); font-weight: 600; font-size: 9.5pt; white-space: nowrap; }}
.chip {{ width: 30px; height: 30px; flex: none; border-radius: 9.3px; background: var(--fill); color: var(--ink); display: grid; place-items: center; }}
.chip .ms {{ font-size: 17px; }}
article header {{ display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }}
article .h {{ flex: 1; min-width: 0; }}
article .lbl {{ font-size: 8.5pt; font-weight: 600; letter-spacing: .3px; color: var(--soft); }}
article .title {{ font-size: 12.5pt; font-weight: 600; line-height: 1.3; }}
.row {{ display: grid; grid-template-columns: 74mm 1fr; gap: 14px; align-items: start; }}
.thumb {{ width: 100%; aspect-ratio: 16 / 9; border-radius: 10px; outline: 1px solid rgb(0 0 0 / .1); outline-offset: -1px; display: block; }}
.thumb.ph {{ background: var(--fill); color: var(--ink); display: grid; place-items: center; font-size: 22pt; font-weight: 700; }}
.notes p, .notes li {{ margin-bottom: 6px; }}
.notes strong {{ font-weight: 600; }}
.notes em.cue {{ font-style: normal; font-weight: 600; color: var(--accent); }}
.notes .who {{ color: var(--soft); font-size: 9.5pt; margin-top: 8px; }}
.placeholder {{ display: inline-block; padding: 0 .45em; border: 1.5px dashed var(--line); border-radius: .8em; color: var(--soft); font-style: normal; line-height: 1.3; white-space: nowrap; }}
.keys {{ color: var(--soft); font-size: 9.5pt; }}
.break {{ break-before: page; }}
</style></head>
<body>
<section class="cover">
  <img src="assets/tuck/tuck_default.png" alt="">
  <div><h1>PACE: presenter notes</h1>
  <p class="sub">{ph(html.escape(team.get('teamName', '[Team name]')))} · {ph(html.escape(team.get('event', '')))}</p>
  <p class="sub" style="font-size:10pt">{len(slides)} slides · about {total // 60}:{total % 60:02d} spoken, guide: Technopreneurship Topic 08</p></div>
</section>

<div class="card"><h2>Team</h2>
<table><thead><tr><th>Name</th><th>Slides</th></tr></thead><tbody>{member_rows}</tbody></table></div>

<div class="two">
<div class="card"><h2>Who presents which slide</h2>
<table><thead><tr><th>#</th><th>Slide</th><th>Presenter</th><th>Time</th></tr></thead><tbody>{run_rows}</tbody></table></div>
<div class="card"><h2>Before you go on</h2>
<ul class="notes" style="padding-left:16px">
<li>Open <strong>deck.html</strong> in Chrome and press <strong>P</strong> for the presenter window. Put <strong>deck.html</strong> on the projector and press <strong>F</strong> for full screen; keep the presenter window on your laptop.</li>
<li><strong>← →</strong> or <strong>Space</strong> move the slides in either window. The audience window shows only the slides: no buttons or hints. The presenter window shows these notes, the next hand-off, and timers. It also has text size (<strong>− +</strong>), highlight (<strong>H</strong>), reading focus (<strong>L</strong>), pause (<strong>P</strong>), restart (<strong>R</strong>) and cover the projector with Tuck (<strong>B</strong>). Press <strong>?</strong> there for the full list.</li>
<li>Have the phone unlocked, PACE open on <strong>Today</strong>, low-energy mode <strong>off</strong>, screen mirroring tested.</li>
<li>Planned time 4:45 for a 5-minute slot. Seven speakers means six handoffs: rehearse them. Demo only on request: Today → tap a step → Deadlines → Just start → low-energy mode.</li>
<li>Q&amp;A prep is in <strong>pitch-appendix.md</strong>.</li>
<li>Fill in every <em class="placeholder">[dashed]</em> item: edit the TEAM block at the top of deck.html, then run <code>python3 pitch/tool/build_notes.py</code>.</li>
</ul></div>
</div>

<div class="break"></div>
{''.join(slide_block(s) for s in slides)}
</body></html>"""

OUT_HTML.write_text(page, encoding="utf-8")
print(f"wrote {OUT_HTML.relative_to(PITCH.parent)}")

if CHROME:
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--virtual-time-budget=3000",
                    f"--print-to-pdf={OUT_PDF}", OUT_HTML.as_uri()],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"wrote {OUT_PDF.relative_to(PITCH.parent)}")
else:
    print("Chrome/Chromium not found: open presenter-notes.html and print to PDF.")
