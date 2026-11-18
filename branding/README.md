# PACE branding: handover notes

**Current brand:** Tuck the turtle (2026-11-18). It replaces the cairn logo, which is kept in `archive/cairn/`.
The cairn lives on as the three stones on Tuck's shell, and in the app's routine progress (`CairnProgress`).
Usage rules: `GUIDELINES.md`.

## How the assets are made
1. The poses were generated with an image-gen AI: one master first, then each pose in a fresh chat with the master attached.
   Originals: `mascot/source/tuck_<pose>.jpeg` (white background).
2. `python3 branding/mascot/build_mascot.py` (Pillow, numpy, ImageMagick) then:
   - removes the background by flood-filling from the edges (Tuck's sand body is nearly white, so a colour key would eat it)
   - crops every pose to one shared square frame, so Tuck keeps its size and place across poses
   - builds `tuck_blink` from the default pose with only the eyes taken from the blink image, so blinking doesn't jitter
   - writes the in-app assets (`pace_app/assets/mascot/`, 1x/2x/3x), the Android launcher icon (adaptive, with a themed-icon
     monochrome layer), notification icon `ic_stat_pace`, splash and widget icons, web favicon/PWA icons/splash, Windows `.ico`,
     the Play Store icon, and `mascot/preview.png`.

## Replacing a pose
Regenerate it with the master attached, save it as `mascot/source/tuck_<pose>.jpeg`, rerun the script, and check `preview.png`.

## Open items
- Notification icon and themed launcher icon: check on a real phone (status bar, Android 13+ themed icons).
- Trademark and reverse image search before any public release.
- Image-gen terms: check the generator's terms allow commercial use of the output before the SaaS version (M11).
