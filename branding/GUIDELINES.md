# PACE — Logo Guidelines (compact)

## 1. The logo
- **Idea:** a cairn. Three stones stacked one at a time: a trail marker that says you are on the path.
  It marks a route; it does not measure or judge. That matches an app that nudges instead of scoring.
- **Versions:** horizontal (primary) · stacked · symbol-only · wordmark-only · small-size cut of the symbol (wider gaps, used for icons and anything under 24 px).
- **Files:** `final/*.svg` are the masters. `export/digital/` has black, white and Moss versions of every lockup with 1200 px PNGs.
  `export/web/` has favicon, PWA icons and the app-icon tile. `export/android/` has the launcher and notification assets, already at every density.

## 2. Clear space
Keep a clear zone of **1 × the top stone's height** around the logo on all sides (the top stone is about a quarter of the symbol's height).
The zone scales with the logo. Never use a fixed distance.

## 3. Minimum size
| Version | Screen | Print |
|---|---|---|
| Horizontal | 120 px wide | 30 mm wide |
| Stacked | 72 px wide | 20 mm wide |
| Symbol (regular) | 24 px | 8 mm |
| Symbol (small cut) | 16 px | 5 mm |

## 4. Colour
| Name | HEX | RGB | CMYK | Pantone (approx.) | Use |
|---|---|---|---|---|---|
| Moss | #35665A | 53 102 90 | 48 0 12 60 | 5545 C | logo, primary accent |
| Sand | #F3EEE6 | 243 238 230 | 0 2 5 5 | 7527 C at 50 % | warm light background, cairn on the app tile |
| Ink | #1C2622 | 28 38 34 | 26 0 11 85 | Black 6 C | text, dark background |
| Moss light | #9CC3B4 | 156 195 180 | 20 0 8 24 | 5575 C | logo and accent on dark UI |

Contrast: Moss on white 6.6 : 1, Moss on Sand 5.7 : 1, Moss light on Ink 8.1 : 1. Pantone matches are approximations. Verify against a physical guide before print.

**Approved pairs:** Moss on white · Moss on Sand · Sand or white on Moss · Moss light on Ink · black on white.
On photos use the white or black version on a calm area, or the Moss tile with the Sand cairn.

## 5. Typography
- The wordmark is **constructed geometry**, not a font. Never retype it.
- UI and tagline: **Figtree** (SIL Open Font License, bundled in `pace_app/assets/fonts/`). Regular for body,
  SemiBold for titles, Bold for screen headlines; times and countdowns use tabular figures. Tagline in Regular, normal tracking.
  Set the tagline "Progress Always Comes Eventually" in sentence case below the stacked lockup, one clear-space unit away, never inside the logo files.

## 6. Android
- Adaptive icon: copy `export/android/mipmap-*` folders and `mipmap-anydpi-v26/ic_launcher.xml` into `android/app/src/main/res/`.
  The foreground keeps the cairn inside the 66 dp safe zone; the monochrome layer supports themed icons on Android 13+.
- Notification small icon: `drawable-*/ic_stat_pace.png` (white on transparent, as Android requires). Reference it as `ic_stat_pace`.
- Play Store listing icon: `export/android/play-store-icon-512.png`.

## 7. Don'ts
Don't stretch or squash · don't recolour outside the palette · don't rotate · don't add shadows, outlines, gradients or effects ·
don't rearrange or resize the parts of a lockup · don't add a fourth stone · don't put the regular symbol below 24 px (use the small cut) ·
don't place on busy backgrounds without the tile.

## 8. Masters
`branding/final/`. Regenerate everything with `python3 branding/gen_kit.py`.
