# PACE: Brand guidelines

## 1. Tuck
PACE's brand is **Tuck**, a calm turtle with three stacked stones (a small cairn) on its shell.
- **The turtle** is how you move: slow, steady, and still getting there. *Progress Always Comes Eventually.*
- **The stones** are what you build along the way: one small thing done at a time, and nothing gets knocked down.
- **The shell** is a safe place to rest. Tuck tucking in is low-energy mode: resting is normal, not failing.

Tuck is the app icon, the splash, the notification icon, and a quiet companion inside the app.

## 2. Personality
Calm, patient, kind, a little sleepy. Tuck never rushes and never judges.

**Tuck is never sad, worried, disappointed or angry.** A missed thing shows Tuck in the default or resting pose, nothing else.
That's the one rule that matters most. Many app mascots use guilt; PACE never does.

## 3. Poses
Masters are in `mascot/export/` (1024 px, transparent). In the app they are `TuckPose` values (`pace_app/lib/core/mascot/tuck_pose.dart`).

| Pose | Looks like | Used for |
|---|---|---|
| `idle` (default) | standing, small wave | general, empty screens, welcome |
| `morning` | stretching, small sun | wake and eat steps |
| `leaving` | walking with a backpack | leave step, running late (never shown as worry) |
| `focus` | reading a book | focus timer |
| `resting` | legs tucked into the shell | low-energy mode |
| `evening` | in a blanket, crescent moon | wind-down, late night |
| `note` | holding a note | inbox |
| `proud` | quietly pleased, a sparkle | routine done, check-in done, focus done |
| `blink` | default with eyes closed | blink animation only |

`icon` (head and shell, facing forward) is the mark for the app icon, favicon and small brand spots.

## 4. Motion
Tuck is quietly alive. Everything is small enough to notice only if you look.
- Always: a slow breath (about 3.6 s), anchored at the feet.
- A slight sway, a blink every 3–7 s (`idle`), a soft entrance, a small hop on a pose change, a squash when tapped.
- By pose: `leaving` waddles, `focus` breathes slower, `resting`/`evening` let a "z" drift up, `proud` hops once with a few sparkles, `morning` stretches on arrival, `note` bobs.
- **Reduced motion:** a still image. **Low-energy mode:** only the slow breath.
- Never fast, flashing, or looping in a way that pulls attention from the task.

## 5. Voice
Tuck shows up in empty states and rare moments, never in notification titles, never more than one Tuck line per screen.
Notification text stays about the user. Copy is calm and forgiving: no "you missed", no "don't break your streak".

## 6. Colour
| Name | HEX | Use |
|---|---|---|
| Moss | #35665A | shell, primary accent |
| Moss light | #9CC3B4 | the shell stones, accent on dark UI |
| Sand | #F3EEE6 | Tuck's body, warm light background, icon tile |
| Ink | #1C2622 | outlines, text, dark background |

Tuck works on Sand, white and Ink. On photos or busy backgrounds, put Tuck on a Sand tile.

## 7. Don'ts
- Don't draw Tuck sad, crying, worried, angry, or shown as failing.
- Don't change the number of stones (always three).
- Don't recolour Tuck outside the palette, put it in red, or add effects (glows, shadows, gradients).
- Don't stretch, squash or rotate the artwork (motion in the app is the only exception).
- Don't use the full-body poses below 40 px. Use the `icon` mark instead.
- Don't use the notification icon (white silhouette) anywhere else.

## 8. Wordmark
The constructed PACE wordmark from the earlier kit stays (`archive/cairn/final/pace-wordmark.svg`, drawn in the app by `PaceWordmark`).
Set the tagline "Progress Always Comes Eventually" in Figtree Regular, sentence case.

## 9. Files
- `mascot/source/`: the image-gen originals (JPEG). Never edit; regenerate instead.
- `mascot/build_mascot.py`: builds every asset from the sources. Run `python3 branding/mascot/build_mascot.py` from the repo root.
- `mascot/preview.png`: contact sheet (poses on light and dark, icons at small sizes). Check it after every rebuild.
- `archive/cairn/`: the previous cairn logo kit, kept for reference.
