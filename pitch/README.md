# PACE pitch

The pitch deck and everything around it, for the GEE2102 startup pitch. Rebuilt to follow the professor's Topic 08 guide: Promise, Problem, Solution, Market, Business model, Validation, Go-to-market, Alternatives, Team, Ask.

| File | What it is |
|---|---|
| `deck.html` | The deck. Open in Chrome. The window shows only the slides: no buttons, no hints. ← → / Space / click / swipe to move, **F** full screen, **T** light/dark. Press **P** to open the separate presenter window (see below) |
| `presenter-notes.pdf` | Run-of-show, who presents what, and each slide with its thumbnail, notes and timing |
| `pitch-5min.md` | **The deck script** (5-minute slot, 4:45 planned), who presents what, signposts |
| `pitch-2min.md` · `pitch-1min.md` | Shorter verbal versions |
| `pitch-appendix.md` | Judge Q&A, objections, weaknesses, backup numbers |
| `pitch-email.md` | One-page summary for the panel, follow-up |
| `pitch-deck-outline.md` | Slide-by-slide outline |
| `pitch-scorecard.md` · `verification-report.md` | Self-review and fact checks |
| `pitch-pack.pdf` | All pitch-*.md files in one PDF. Rebuild with `python3 pitch/tool/build_pack.py` |
| `intake.md` · `raw/` | Inputs and research notes with sources (`raw/ph-costs.md`: wage, peso rate, Play fee) |
| `GROUP-8-Pitching-Startup-Ideas-FINAL (1).pptx` | The professor's guide (Topic 08). The deck follows its 10-section order |
| `archive/` | The first 8-minute version of the deck, notes and scripts |

## Presenting
1. Open `deck.html` and press **P**. A second window opens: the presenter window.
2. Drag the presenter window to your laptop screen and the **deck window to the projector**, then press **F** in the deck window.
3. Use the presenter window's buttons, or ← → / Space in either window. Both stay in step.

The presenter window has the current slide, your speaker notes, and these controls (press **?** for the list):

| Control | Key | What it does |
|---|---|---|
| A− / A+ | − / + / 0 | Notes text size (14–48 px; 0 resets) |
| Line spacing | S | Tight, normal or roomy |
| Highlight | H | Turn on, then select text in the notes to highlight it. Click a highlight to remove it. Saved per slide |
| Clear highlights | Shift+H | Remove all highlights on this slide |
| Reading focus | L, then ↑ ↓ | Dims everything but one line so you don't lose your place; click a line to jump to it |
| Light / dark | T | Switches both windows together, from either one |
| Blank audience screen | B | Covers the whole projector with Tuck idling (breathing, swaying, blinking; still under reduced motion). Also works from the deck window. A banner reminds you it's on |
| Pause / restart timers | P / R | Pauses or restarts the slide and total timers |
| Shortcuts | ? | The full list |

The window also shows who is presenting, a **hand-off** line when the next slide belongs to someone else, the next slide's title, a **per-slide timer** against its planned time (the bar turns warm, never red, when over), and a **total timer** that says whether you are ahead of or behind the plan.

Text size, spacing, reading focus and highlights are remembered in your browser, so use the same browser on the day. The presenter window is never visible in the audience window.

## Fill in your team
1. Edit the `TEAM` block near the top of `deck.html` (team name, event, school, members, and which slides each member presents).
2. Rebuild the notes: `python3 pitch/tool/build_notes.py` (needs Chrome or Chromium; it re-takes slide thumbnails into `build/thumbs/` and re-prints the PDF).

Anything still in `[square brackets]` shows as a dashed chip, so nothing unfinished goes on stage by accident.

## Design
The deck uses the app's own design tokens (`pace_app/lib/core/theme/`), Figtree font files and Tuck artwork, so it looks like PACE. Icons are a small offline subset of Material Symbols Rounded (Apache 2.0). Everything works offline.
