# PACE documentation

*Progress Always Comes Eventually.* A calm personal routine app: Android first,
offline-first, single user.

| Document | For | What it covers |
|---|---|---|
| [User guide](user-guide.md) | Anyone using PACE | Setting up, each screen, reminders, widgets, low-energy mode, privacy, troubleshooting |
| [Developer guide](developer-guide.md) | Anyone changing PACE | Architecture, pure scheduling logic, data model and migrations, notifications, Android native code, testing, release |
| `pace-docs.pdf` | Printing or sharing | Both guides in one PDF |

## Rebuilding the PDF

```sh
python3 docs/tool/build_pdf.py
```

It needs Python 3 and Google Chrome or Chromium, and no extra packages. It renders both
Markdown files with the app's Figtree font and Tuck artwork, then prints `docs/pace-docs.pdf`.
Rebuild after editing either guide.

The screenshots in `images/` come from the local screenshot harness in
`pace_app/test/zz_shots/`, which is not committed. Copy fresh ones from its `out/` folder
after UI changes.
