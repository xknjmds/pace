# PACE branding — handover notes

**Chosen direction:** A, "Cairn" (round 1 concepts are kept in `concepts/`).

## What is here
- `final/` masters: `pace-symbol.svg`, `pace-symbol-small.svg` (icon cut), `pace-wordmark.svg`, `pace-horizontal.svg`, `pace-stacked.svg`, plus `pace-symbol-on-tile.svg` (app icon) and `pace-horizontal-on-dark.svg`.
- `final/board/` presentation board (`pace-presentation.html`, slides as PNG in `slides/`).
- `final/preview.html` test sheet: size ladder, 16/32/48 px pixel test, backgrounds, one-colour, reversed, blur, mirror, rotate, shelf test against 11 productivity marks.
- `export/digital/` black, white and Moss variants of each lockup (SVG + 1200 px PNG).
- `export/web/` favicon.ico, favicon.svg, PNG icon set, `site.webmanifest`, `head-snippet.html`.
- `export/android/` adaptive launcher icon (foreground, background, monochrome) at mdpi–xxxhdpi, legacy `ic_launcher.png`, `mipmap-anydpi-v26/ic_launcher.xml`, notification icon `ic_stat_pace` at every density, 512 px Play Store icon.
- `GUIDELINES.md` one-page usage guide. `gen_kit.py` regenerates all masters and Android SVGs.

## Tests run
- SVG audit: 98–99/100 on symbol and lockups. Remaining notes are informational: the wordmark and lockups keep strokes (round caps and joins), which is intentional for screen use.
- Rendered and inspected at 16, 48, 512 and 1000 px. The small cut keeps three separate stones at 16 px; the regular symbol starts to merge below 24 px.
- One-colour, reversed, blur, mirror and 180° rotation checked on the test sheet. No unintended readings found.

## Open items
- Strokes in the wordmark and lockups should be expanded to outlines (Inkscape: Stroke to Path, then Union) before any cutting, embroidery or print vendor use. Screen use is fine as is.
- Trademark: not checked. Run a trademark database search and a reverse image search before any public release. Stacked-stone marks exist in the wellness category, so check that space in particular.
- Pantone values are approximations.
