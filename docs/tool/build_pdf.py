#!/usr/bin/env python3
"""Combine the user and developer guides into one PDF: docs/pace-docs.pdf.

A small built-in Markdown converter (headings, paragraphs, lists, tables,
code blocks, images, bold/italic/code/links), so no extra packages are
needed, then printed with headless Chrome in the app's own style.

    python3 docs/tool/build_pdf.py
"""
import datetime
import html
import re
import shutil
import subprocess
from pathlib import Path

DOCS = Path(__file__).resolve().parent.parent
ROOT = DOCS.parent
APP = ROOT / "pace_app"
OUT_HTML = DOCS / "build" / "pace-docs.html"
OUT_PDF = DOCS / "pace-docs.pdf"

# (file, part label, pastel, Tuck pose)
PARTS = [
    ("user-guide.md", "User guide", "p-morning", "tuck_morning"),
    ("developer-guide.md", "Developer guide", "p-focus", "tuck_focus"),
]

CHROME = next((c for c in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser")
               if shutil.which(c)), None)


def slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", re.sub(r"<[^>]+>", "", s).lower()).strip("-")


# ---------- tiny Markdown → HTML ----------
def inline(s: str) -> str:
    codes = []
    s = re.sub(r"`([^`]+)`", lambda m: codes.append(m.group(1)) or f"\x00{len(codes) - 1}\x00", s)
    s = html.escape(s, quote=False)
    s = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+\.md)\)", r"<em>\1</em>", s)  # cross-doc links: plain text in print
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"<em>\1</em>", s)
    s = re.sub(r"\x00(\d+)\x00", lambda m: "<code>" + html.escape(codes[int(m.group(1))]).replace("/", "/<wbr>") + "</code>", s)
    return s


def md_to_html(md: str, toc: list) -> str:
    lines = md.splitlines()
    out, buf, figs, i = [], [], [], 0

    def para():
        if buf:
            out.append(f"<p>{inline(' '.join(x.strip() for x in buf))}</p>")
            buf.clear()

    while i < len(lines):
        ln = lines[i]
        if not ln.strip():
            para(); i += 1; continue
        if ln.startswith("```"):
            para(); i += 1
            code = []
            while i < len(lines) and not lines[i].startswith("```"):
                code.append(lines[i]); i += 1
            i += 1
            out.append(f"<pre><code>{html.escape(chr(10).join(code))}</code></pre>"); continue
        m = re.match(r"^!\[([^\]]*)\]\(([^)]+)\)\s*$", ln)
        if m:
            para()
            src = (DOCS / m.group(2)).resolve().as_uri()
            where = toc[1][-1][1] if toc[1] else ""
            figs.append(f'<figure class="shot"><img src="{src}" alt="{html.escape(m.group(1))}">'
                        f"<figcaption><strong>{html.escape(m.group(1))}</strong><br>{where}</figcaption></figure>")
            i += 1; continue
        if ln.startswith("<!-- screens -->"):
            para(); out.append("\x01GALLERY\x01"); i += 1; continue
        m = re.match(r"^(#{1,4})\s+(.*)", ln)
        if m:
            para()
            lvl, text = len(m.group(1)), inline(m.group(2))
            anchor = f"{toc[0]}-{slug(text)}"
            if lvl == 2:
                toc[1].append((anchor, text))
            out.append(f'<h{lvl} id="{anchor}">{text}</h{lvl}>'); i += 1; continue
        if re.match(r"^-{3,}\s*$", ln):
            para(); out.append("<hr>"); i += 1; continue
        if ln.startswith("|"):
            para()
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            head = rows[0]
            body = [r for r in rows[1:] if not all(re.match(r"^:?-+:?$", c) for c in r)]
            t = '<div class="tw"><table><thead><tr>' +"".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>"
            t += "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body)
            out.append(t + "</tbody></table></div>"); continue
        m = re.match(r"^(\s*)([-*]|\d+\.)\s+(.*)", ln)
        if m:
            para()
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
    para()
    gallery = (f'<div class="screens"><h2>Screens at a glance</h2><div class="gallery">{"".join(figs)}</div></div>'
               if figs else "")
    return "\n".join(out).replace("\x01GALLERY\x01", gallery)


# ---------- assemble ----------
fonts = (APP / "assets" / "fonts").as_uri()
mascot = (APP / "assets" / "mascot").as_uri()

sections, cover_toc = [], []
for n, (fname, label, pastel, pose) in enumerate(PARTS, 1):
    md = (DOCS / fname).read_text(encoding="utf-8")
    title = re.match(r"^# (.*)", md).group(1)
    md = re.sub(r"^# .*\n", "", md, count=1)
    toc = (f"p{n}", [])
    body = md_to_html(md, toc)
    contents = "".join(f'<li><a href="#{a}">{t}</a></li>' for a, t in toc[1])
    sections.append(f"""
<section class="part break">
  <header class="ph {pastel}"><img src="{mascot}/{pose}.png" alt="">
    <div><div class="lbl">Part {n} · docs/{fname}</div><h1>{html.escape(label)}</h1></div></header>
  <nav class="contents"><div class="lbl">Contents</div><ol>{contents}</ol></nav>
  <div class="body">{body}</div>
</section>""")
    cover_toc.append(f'<li><a href="#p{n}-top"><span class="chip {pastel}"><img src="{mascot}/{pose}.png" alt=""></span>'
                     f'<span>{html.escape(label)}</span><span class="f">{len(toc[1])} sections</span></a></li>')
    sections[-1] = sections[-1].replace('<section class="part break">', f'<section class="part break" id="p{n}-top">', 1)

today = datetime.date.today().strftime("%-d %B %Y")

page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>PACE Documentation</title>
<style>
@font-face {{ font-family: Figtree; src: url({fonts}/Figtree-Regular.ttf); font-weight: 400; }}
@font-face {{ font-family: Figtree; src: url({fonts}/Figtree-Medium.ttf); font-weight: 500; }}
@font-face {{ font-family: Figtree; src: url({fonts}/Figtree-SemiBold.ttf); font-weight: 600; }}
@font-face {{ font-family: Figtree; src: url({fonts}/Figtree-Bold.ttf); font-weight: 700; }}
:root {{ --page: #FAF8F5; --card: #FFFFFF; --sunken: #F1EEE9; --text: #26282C; --soft: #64666C; --line-soft: #E6E2DC; --accent: #35665A; }}
.p-morning {{ --fill: #F7E8CC; --ink: #8A5E14; }}
.p-focus   {{ --fill: #DCE8EF; --ink: #365D73; }}
@page {{ size: A4; margin: 16mm 16mm 18mm; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
body {{ background: #FFFFFF; color: var(--text); font: 400 10.5pt/1.55 Figtree, system-ui, sans-serif; }}
@media screen {{ body {{ background: var(--page); max-width: 820px; margin: 0 auto; padding: 32px 16px 64px; }} }}
.break {{ break-before: page; }}
.cover {{ min-height: 245mm; display: flex; flex-direction: column; justify-content: center; }}
.cover > img {{ width: 128px; height: 128px; object-fit: contain; }}
.cover h1 {{ font-size: 34pt; font-weight: 700; letter-spacing: -0.016em; line-height: 1.05; margin-top: 14px; }}
.cover .tag {{ font-size: 14pt; margin-top: 6px; }}
.cover .sub {{ color: var(--soft); font-size: 11pt; margin-top: 6px; max-width: 135mm; }}
.toc {{ list-style: none; margin-top: 28px; display: grid; gap: 8px; }}
.toc a {{ display: flex; align-items: center; gap: 12px; padding: 10px 14px; border-radius: 16px; background: var(--card); border: 1px solid var(--line-soft); color: inherit; text-decoration: none; font-weight: 600; }}
.toc .f {{ margin-left: auto; color: var(--soft); font-weight: 400; font-size: 9pt; }}
.chip {{ width: 40px; height: 40px; flex: none; border-radius: 12px; background: var(--fill); display: grid; place-items: center; overflow: hidden; }}
.chip img {{ width: 34px; height: 34px; object-fit: contain; }}
.ph {{ display: flex; align-items: center; gap: 16px; padding: 16px 18px; border-radius: 22px; background: var(--fill); margin-bottom: 16px; }}
.ph img {{ width: 64px; height: 64px; object-fit: contain; }}
.ph h1 {{ font-size: 24pt; font-weight: 700; letter-spacing: -0.014em; line-height: 1.1; color: var(--text); }}
.ph .lbl {{ color: var(--ink); }}
.lbl {{ font-size: 8.5pt; font-weight: 600; letter-spacing: .3px; color: var(--soft); }}
.contents {{ background: var(--sunken); border-radius: 16px; padding: 12px 16px; margin-bottom: 18px; break-inside: avoid; }}
.contents ol {{ list-style: none; columns: 2; column-gap: 24px; margin: 6px 0 0 18px; font-size: 9.5pt; }}
.contents a {{ color: var(--text); }}
.body h2 {{ font-size: 14pt; font-weight: 700; letter-spacing: -0.01em; margin: 20px 0 6px; padding-top: 8px; border-top: 1px solid var(--line-soft); break-after: avoid; }}
.body h3 {{ font-size: 11.5pt; font-weight: 600; margin: 14px 0 4px; break-after: avoid; }}
.body h4 {{ font-size: 10.5pt; font-weight: 600; margin: 10px 0 4px; break-after: avoid; }}
p {{ margin: 0 0 7px; }}
strong {{ font-weight: 600; }}
ul, ol {{ margin: 0 0 8px 18px; }}
li {{ margin-bottom: 3px; }}
hr {{ border: 0; border-top: 1px solid var(--line-soft); margin: 14px 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 6px 0 12px; font-size: 9.2pt; }}
th {{ text-align: left; font-size: 8pt; font-weight: 600; letter-spacing: .3px; text-transform: uppercase; color: var(--soft); padding: 5px 7px; border-bottom: 1px solid var(--line-soft); }}
td {{ padding: 5px 7px; border-bottom: 1px solid var(--line-soft); vertical-align: top; }}
tr {{ break-inside: avoid; }}
code {{ font: 8.6pt/1.4 ui-monospace, "DejaVu Sans Mono", monospace; background: var(--sunken); padding: 0 4px; border-radius: 4px; overflow-wrap: break-word; }}
pre {{ background: var(--sunken); border-radius: 12px; padding: 10px 14px; margin: 6px 0 12px; break-inside: avoid; white-space: pre-wrap; }}
pre code {{ background: none; padding: 0; font-size: 8.4pt; }}
a {{ color: var(--accent); text-decoration: none; }}
.screens {{ break-before: page; }}
.gallery {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px 12px; margin: 8px 0 14px; }}
figure.shot {{ text-align: center; break-inside: avoid; }}
figure.shot img {{ width: 100%; border-radius: 14px; border: 1px solid var(--line-soft); }}
figure.shot figcaption {{ font-size: 8pt; color: var(--soft); margin-top: 3px; }}
.contents {{ clear: both; }}
.tw {{ display: flow-root; }}
</style></head>
<body>
<section class="cover">
  <img src="{mascot}/tuck_default.png" alt="">
  <h1>PACE documentation</h1>
  <p class="tag">Progress Always Comes Eventually</p>
  <p class="sub">A calm personal routine app. The user guide explains how to use it; the developer guide explains how it is built and how to change it.</p>
  <p class="sub">Version 1.0.0 · v2.1 · {today}</p>
  <ul class="toc">{''.join(cover_toc)}</ul>
</section>
{''.join(sections)}
</body></html>"""

OUT_HTML.parent.mkdir(parents=True, exist_ok=True)
OUT_HTML.write_text(page, encoding="utf-8")
if not CHROME:
    raise SystemExit(f"Chrome/Chromium not found: open {OUT_HTML} and print to PDF.")
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--allow-file-access-from-files",
                "--virtual-time-budget=5000", f"--print-to-pdf={OUT_PDF}", OUT_HTML.as_uri()],
               check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"wrote {OUT_PDF.relative_to(ROOT)}")
