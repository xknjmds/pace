#!/usr/bin/env python3
"""Combine every pitch-*.md file into one PDF: pitch/pitch-pack.pdf.

Uses a small built-in Markdown converter (headings, paragraphs, quotes,
lists, tables, bold/italic/code/links) so no extra packages are needed,
then prints with headless Chrome in the same style as the presenter notes.

    python3 pitch/tool/build_pack.py
"""
import html
import json
import re
import shutil
import subprocess
from pathlib import Path

PITCH = Path(__file__).resolve().parent.parent
OUT_HTML = PITCH / "build" / "pitch-pack.html"
OUT_PDF = PITCH / "pitch-pack.pdf"

# Reading order: the deck script first, then shorter versions, prep and reference.
ORDER = [
    ("pitch-5min.md", "5-minute pitch (deck script)", "p-leave", "view_timeline"),
    ("pitch-2min.md", "2-minute pitch", "p-morning", "timer"),
    ("pitch-1min.md", "1-minute pitch", "p-focus", "timer"),
    ("pitch-deck-outline.md", "Deck outline", "p-calm", "grid_view"),
    ("pitch-appendix.md", "Q&A preparation", "p-evening", "lightbulb"),
    ("pitch-email.md", "Note to the panel", "p-deadline", "edit_note"),
    ("pitch-scorecard.md", "Scorecard", "p-morning", "trending_up"),
]

CHROME = next((c for c in ("google-chrome", "chromium", "chromium-browser", "google-chrome-stable") if shutil.which(c)), None)

src = (PITCH / "deck.html").read_text(encoding="utf-8")
team = json.loads(re.search(r'<script id="team" type="application/json">(.*?)</script>', src, re.S).group(1))


# ---------- tiny Markdown → HTML ----------
def inline(s: str) -> str:
    codes = []
    s = re.sub(r"`([^`]+)`", lambda m: codes.append(m.group(1)) or f"\x00{len(codes) - 1}\x00", s)
    s = html.escape(s, quote=False)
    s = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"(?<![\"'>=])(https?://[^\s<)]+)", r'<a href="\1">\1</a>', s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"<em>\1</em>", s)
    s = re.sub(r"\x00(\d+)\x00", lambda m: f"<code>{html.escape(codes[int(m.group(1))])}</code>", s)
    # [placeholders] → dashed chips (but not link text, already converted)
    s = re.sub(r"\[([^\]<>]{1,40})\]", r'<span class="placeholder">[\1]</span>', s)
    return s


def md_to_html(md: str) -> str:
    lines = md.splitlines()
    out, i = [], 0

    def para(buf):
        if buf:
            out.append(f"<p>{inline(' '.join(x.strip() for x in buf))}</p>")

    buf = []
    while i < len(lines):
        ln = lines[i]
        if not ln.strip():
            para(buf); buf = []; i += 1; continue
        m = re.match(r"^(#{1,4})\s+(.*)", ln)
        if m:
            para(buf); buf = []
            lvl = len(m.group(1))
            out.append(f"<h{lvl + 1}>{inline(m.group(2))}</h{lvl + 1}>"); i += 1; continue
        if re.match(r"^-{3,}\s*$", ln):
            para(buf); buf = []; out.append("<hr>"); i += 1; continue
        if ln.startswith(">"):
            para(buf); buf = []
            q = []
            while i < len(lines) and lines[i].startswith(">"):
                q.append(lines[i][1:].lstrip()); i += 1
            out.append(f"<blockquote>{md_to_html(chr(10).join(q))}</blockquote>"); continue
        if ln.startswith("|"):
            para(buf); buf = []
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            head, body = rows[0], [r for r in rows[1:] if not all(re.match(r"^:?-+:?$", c) for c in r)]
            t = "<table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
            t += "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body)
            out.append(t + "</tbody></table>"); continue
        m = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)", ln)
        if m:
            para(buf); buf = []
            tag = "ol" if m.group(2)[0].isdigit() else "ul"
            items = []
            while i < len(lines):
                mm = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)", lines[i])
                if mm:
                    items.append(mm.group(3)); i += 1
                elif lines[i].startswith("  ") and lines[i].strip() and items:
                    items[-1] += " " + lines[i].strip(); i += 1
                else:
                    break
            out.append(f"<{tag}>" + "".join(f"<li>{inline(x)}</li>" for x in items) + f"</{tag}>"); continue
        buf.append(ln); i += 1
    para(buf)
    return "\n".join(out)


# ---------- assemble ----------
sections, toc = [], []
for n, (fname, label, pastel, icon) in enumerate(ORDER, 1):
    md = (PITCH / fname).read_text(encoding="utf-8")
    md = re.sub(r"^# .*\n", "", md, count=1)                      # file title → section header
    md = re.sub(r"^\*Skill: startup-pitch \| Generated: [^*]+\*\n", "", md, flags=re.M)
    sections.append(f"""
<section class="doc break" id="s{n}">
  <header class="sh"><span class="chip {pastel}"><span class="ms">{icon}</span></span>
    <div><div class="lbl">Part {n} · {fname}</div><h1>{html.escape(label)}</h1></div></header>
  {md_to_html(md)}
</section>""")
    toc.append(f'<li><a href="#s{n}"><span class="chip {pastel}"><span class="ms">{icon}</span></span>'
               f'<span>{html.escape(label)}</span><span class="f">{fname}</span></a></li>')

ph = lambda s: re.sub(r"\[([^\]]+)\]", r'<span class="placeholder">[\1]</span>', html.escape(s))

page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PACE Pitch Pack</title>
<style>
@font-face {{ font-family: Figtree; src: url(../assets/fonts/Figtree-Regular.ttf); font-weight: 400; }}
@font-face {{ font-family: Figtree; src: url(../assets/fonts/Figtree-Medium.ttf); font-weight: 500; }}
@font-face {{ font-family: Figtree; src: url(../assets/fonts/Figtree-SemiBold.ttf); font-weight: 600; }}
@font-face {{ font-family: Figtree; src: url(../assets/fonts/Figtree-Bold.ttf); font-weight: 700; }}
@font-face {{ font-family: "Material Symbols Rounded"; src: url(../assets/fonts/MaterialSymbolsRounded-subset.woff2) format("woff2"); font-weight: 400 600; font-display: block; }}
:root {{ --page: #FAF8F5; --card: #FFFFFF; --sunken: #F1EEE9; --text: #26282C; --soft: #64666C; --line: #86898F; --line-soft: #E6E2DC; --mint: #DCEAE3; --accent: #35665A; }}
.p-morning  {{ --fill: #F7E8CC; --ink: #8A5E14; }}
.p-leave    {{ --fill: #DCEAE3; --ink: #2B5A4E; }}
.p-deadline {{ --fill: #F0E4D2; --ink: #7A5634; }}
.p-focus    {{ --fill: #DCE8EF; --ink: #365D73; }}
.p-evening  {{ --fill: #E7E2F0; --ink: #55497A; }}
.p-calm     {{ --fill: #E4EAE3; --ink: #465C52; }}
@page {{ size: A4; margin: 16mm 16mm 18mm; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
body {{ background: #FFFFFF; color: var(--text); font: 400 10.5pt/1.55 Figtree, system-ui, sans-serif; letter-spacing: .1px; }}
@media screen {{ body {{ background: var(--page); max-width: 820px; margin: 0 auto; padding: 32px 16px 64px; }} }}
.ms {{ font-family: "Material Symbols Rounded"; font-weight: normal; font-style: normal; line-height: 1; display: inline-block; font-feature-settings: "liga"; font-variation-settings: "FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24; }}
.chip {{ width: 30px; height: 30px; flex: none; border-radius: 9.3px; background: var(--fill); color: var(--ink); display: grid; place-items: center; }}
.chip .ms {{ font-size: 17px; }}
.break {{ break-before: page; }}
.cover {{ min-height: 240mm; display: flex; flex-direction: column; justify-content: center; }}
.cover img {{ width: 120px; height: 120px; }}
.cover h1 {{ font-size: 34pt; font-weight: 700; letter-spacing: -0.016em; line-height: 1.05; margin-top: 12px; }}
.cover .tag {{ font-size: 14pt; margin-top: 6px; }}
.cover .sub {{ color: var(--soft); font-size: 11pt; margin-top: 6px; }}
.toc {{ list-style: none; margin-top: 28px; display: grid; gap: 6px; }}
.toc a {{ display: flex; align-items: center; gap: 12px; padding: 8px 12px; border-radius: 14px; background: var(--card); border: 1px solid var(--line-soft); color: inherit; text-decoration: none; font-weight: 600; }}
.toc .f {{ margin-left: auto; color: var(--soft); font-weight: 400; font-size: 9pt; }}
.sh {{ display: flex; align-items: center; gap: 12px; padding-bottom: 12px; margin-bottom: 14px; border-bottom: 1px solid var(--line-soft); }}
.sh .chip {{ width: 40px; height: 40px; border-radius: 12.4px; }}
.sh .chip .ms {{ font-size: 22px; }}
.lbl {{ font-size: 8.5pt; font-weight: 600; letter-spacing: .3px; color: var(--soft); }}
.sh h1 {{ font-size: 20pt; font-weight: 700; letter-spacing: -0.014em; line-height: 1.15; }}
h2 {{ font-size: 13.5pt; font-weight: 700; letter-spacing: -0.01em; margin: 18px 0 6px; break-after: avoid; }}
h3 {{ font-size: 11.5pt; font-weight: 600; margin: 14px 0 4px; break-after: avoid; }}
h4, h5 {{ font-size: 10.5pt; font-weight: 600; margin: 10px 0 4px; break-after: avoid; }}
p {{ margin: 0 0 7px; }}
strong {{ font-weight: 600; }}
ul, ol {{ margin: 0 0 8px 18px; }}
li {{ margin-bottom: 3px; }}
blockquote {{ background: var(--sunken); border-radius: 14px; padding: 10px 14px 4px; margin: 6px 0 10px; break-inside: avoid; }}
blockquote p {{ margin-bottom: 6px; }}
hr {{ border: 0; border-top: 1px solid var(--line-soft); margin: 14px 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 6px 0 12px; font-size: 9.5pt; break-inside: auto; }}
th {{ text-align: left; font-size: 8pt; font-weight: 600; letter-spacing: .3px; text-transform: uppercase; color: var(--soft); padding: 5px 7px; border-bottom: 1px solid var(--line-soft); }}
td {{ padding: 5px 7px; border-bottom: 1px solid var(--line-soft); vertical-align: top; }}
tr {{ break-inside: avoid; }}
code {{ font: 9pt/1.4 ui-monospace, "DejaVu Sans Mono", monospace; background: var(--sunken); padding: 0 4px; border-radius: 4px; }}
a {{ color: var(--accent); text-decoration: none; word-break: break-word; }}
.placeholder {{ display: inline-block; padding: 0 .4em; border: 1.5px dashed var(--line); border-radius: .8em; color: var(--soft); line-height: 1.3; white-space: nowrap; }}
</style></head>
<body>
<section class="cover">
  <img src="../assets/tuck/tuck_default.png" alt="">
  <h1>PACE: pitch pack</h1>
  <p class="tag">Progress Always Comes Eventually</p>
  <p class="sub">{ph(team.get('teamName', '[Team name]'))} · {ph(team.get('event', ''))}</p>
  <p class="sub">Every script, the Q&amp;A prep, the outline and the scorecard in one place. Slides are in deck.html; slide-by-slide notes are in presenter-notes.pdf.</p>
  <ul class="toc">{''.join(toc)}</ul>
</section>
{''.join(sections)}
</body></html>"""

OUT_HTML.parent.mkdir(parents=True, exist_ok=True)
OUT_HTML.write_text(page, encoding="utf-8")
if not CHROME:
    raise SystemExit(f"Chrome/Chromium not found: open {OUT_HTML} and print to PDF.")
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--virtual-time-budget=3000",
                f"--print-to-pdf={OUT_PDF}", OUT_HTML.as_uri()], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"wrote {OUT_PDF.relative_to(PITCH.parent)}")
