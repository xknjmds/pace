"""Build every Tuck asset from the image-gen sources in branding/mascot/source/.

Run from the repo root:  python3 branding/mascot/build_mascot.py
Needs: Python 3 with Pillow and numpy, ImageMagick (`magick`).

Output:
  pace_app/assets/mascot/          in-app poses and the splash Tuck at 1x / 2.0x / 3.0x
  pace_app/android/app/src/main/res launcher icon (adaptive + legacy), notification
                                    icon, splash icon and wordmark, home-widget icon
  pace_app/web/                     favicon, PWA icons, splash image
  pace_app/windows/runner/resources/app_icon.ico
  branding/mascot/export/           1024 px cutouts and the Play Store icon
  branding/mascot/preview.png       contact sheet to check by eye
"""
import os
import subprocess
import tempfile

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "branding/mascot/source")
EXP = os.path.join(ROOT, "branding/mascot/export")
APP = os.path.join(ROOT, "pace_app")
RES = os.path.join(APP, "android/app/src/main/res")

SAND, INK, MOSS = (243, 238, 230), (28, 38, 34), (53, 102, 90)
POSES = ["default", "morning", "leaving", "focus", "resting", "evening", "note", "proud"]
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
# The pose images were made at 2752x1536; the resting one came out at half that.
WORK_W = 2752


def cutout(name):
    """Source JPEG -> RGBA with the white background removed.

    The background is flood-filled from the edges, never colour-keyed: Tuck's
    sand body is nearly white too, and the thick outline keeps the fill out.
    """
    src = os.path.join(SRC, f"tuck_{name}.jpeg")
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as t:
        tmp = t.name
    subprocess.run(
        ["magick", src, "-bordercolor", "white", "-border", "2", "-fuzz", "10%",
         "-fill", "none", "-draw", "color 0,0 floodfill", "-shave", "2x2", tmp],
        check=True,
    )
    im = Image.open(tmp).convert("RGBA")
    os.unlink(tmp)
    if name != "icon" and im.width != WORK_W:
        im = im.resize((WORK_W, round(im.height * WORK_W / im.width)), Image.LANCZOS)
    # Pull the edge in a little and soften it, so no white JPEG fringe shows on
    # dark backgrounds. The outline is ~15 px thick, so this costs nothing.
    a = im.getchannel("A").filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(1.2))
    # Drop stray specks (JPEG noise left outside the figure).
    arr = np.array(a)
    arr[arr < 24] = 0
    im.putalpha(Image.fromarray(arr))
    return im


def bbox(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()


def blink_from(default, blink):
    """The default pose with only the eyes taken from the blink image.

    The two generations differ by a few pixels elsewhere (mouth, arm), which
    would jitter on every blink. Copying just the eye area keeps it still.
    """
    d = np.array(default.convert("L")).astype(int)
    b = np.array(blink.convert("L")).astype(int)
    diff = np.abs(d - b) > 60
    h, w = diff.shape
    # Eyes sit in the head: upper part of the figure, right of the shell.
    x0, y0, x1, y1 = bbox(default)
    region = np.zeros_like(diff)
    region[y0 : y0 + (y1 - y0) * 45 // 100, x0 + (x1 - x0) * 55 // 100 : x1] = True
    ys, xs = np.nonzero(diff & region)
    pad = 24
    ex0, ex1 = xs.min() - pad, xs.max() + pad
    ey0, ey1 = ys.min() - pad, ys.max() + pad
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((ex0, ey0, ex1, ey1), radius=40, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(10))
    out = default.copy()
    out.paste(blink, (0, 0), ImageChops.multiply(mask, blink.getchannel("A")))
    return out


def square_crop(im, box):
    return im.crop(box)


def save(im, path, size=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if size:
        im = im.resize((size, size) if isinstance(size, int) else size, Image.LANCZOS)
    im.save(path, optimize=True)
    return im


def fit(im, canvas, frac, bg=None, dy=0.0):
    """Centre the figure on a square canvas, its larger side = frac * canvas."""
    fig = im.crop(bbox(im))
    s = frac * canvas / max(fig.size)
    fig = fig.resize((max(1, round(fig.width * s)), max(1, round(fig.height * s))), Image.LANCZOS)
    out = Image.new("RGBA", (canvas, canvas), bg + (255,) if bg else (0, 0, 0, 0))
    out.alpha_composite(fig, ((canvas - fig.width) // 2, round((canvas - fig.height) / 2 + dy * canvas)))
    return out


def line_art(im):
    """Only the dark ink lines (outline, shell plates, face): for themed icons."""
    arr = np.array(im)
    lum = arr[:, :, :3].mean(axis=2)
    a = np.where((lum < 110) & (arr[:, :, 3] > 128), 255, 0).astype(np.uint8)
    out = np.zeros_like(arr)
    out[:, :, :3] = 255
    out[:, :, 3] = a
    return Image.fromarray(out).filter(ImageFilter.GaussianBlur(0.6))


def silhouette_with_face(im):
    """White silhouette with the inner ink lines cut out (notification icon)."""
    arr = np.array(im)
    solid = arr[:, :, 3] > 128
    inner = np.array(Image.fromarray((solid * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(41))) > 0
    lum = arr[:, :, :3].mean(axis=2)
    holes = inner & (lum < 110)
    a = np.where(solid & ~holes, 255, 0).astype(np.uint8)
    out = np.zeros_like(arr)
    out[:, :, :3] = 255
    out[:, :, 3] = a
    return Image.fromarray(out)


def main():
    os.makedirs(EXP, exist_ok=True)
    cut = {p: cutout(p) for p in POSES}
    cut["blink"] = blink_from(cut["default"], cutout("blink"))
    icon = cutout("icon")

    # One shared square frame for every pose, so the body keeps its size and
    # place when the pose changes (and blink lines up with default exactly).
    boxes = [bbox(cut[p]) for p in POSES]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    side = round(max(x1 - x0, y1 - y0) * 1.04)
    # Feet near the bottom edge, so Tuck stands on the line below it in the UI.
    cx = (x0 + x1) // 2
    bottom = y1 + round(side * 0.025)
    frame = (cx - side // 2, bottom - side, cx - side // 2 + side, bottom)
    print("pose frame", frame, "from", boxes)

    assets = os.path.join(APP, "assets/mascot")
    for p in POSES + ["blink"]:
        sq = cut[p].crop(frame)
        save(sq, os.path.join(EXP, f"tuck_{p}.png"), 1024)
        for folder, px in (("", 160), ("2.0x", 320), ("3.0x", 480)):
            save(sq, os.path.join(assets, folder, f"tuck_{p}.png"), px)

    # Head-and-shell mark for small brand spots (app bar, side rail): 64 logical px.
    mark = fit(icon, 1024, 0.98)
    for folder, px in (("", 64), ("2.0x", 128), ("3.0x", 192)):
        save(mark, os.path.join(assets, folder, "tuck_icon.png"), px)

    # ----- Android launcher: adaptive layers (108 dp, safe zone 66 dp) -----
    for d, k in DENSITIES.items():
        n = round(108 * k)
        fg = fit(icon, n, 0.60, dy=0.01)
        save(fg, f"{RES}/mipmap-{d}/ic_launcher_foreground.png")
        save(Image.new("RGBA", (n, n), SAND + (255,)), f"{RES}/mipmap-{d}/ic_launcher_background.png")
        save(line_art(fit(icon, n * 4, 0.60, dy=0.01)), f"{RES}/mipmap-{d}/ic_launcher_monochrome.png", n)
        # Legacy icon (pre-Android 8): Sand rounded square.
        m = round(48 * k)
        legacy = Image.new("RGBA", (m * 4, m * 4), (0, 0, 0, 0))
        ImageDraw.Draw(legacy).rounded_rectangle((8, 8, m * 4 - 8, m * 4 - 8), radius=m * 4 // 5, fill=SAND + (255,))
        legacy.alpha_composite(fit(icon, m * 4, 0.78))
        save(legacy, f"{RES}/mipmap-{d}/ic_launcher.png", m)

        # Notification small icon: white silhouette, 24 dp.
        s = round(24 * k)
        save(silhouette_with_face(fit(icon, 384, 0.92)), f"{RES}/drawable-{d}/ic_stat_pace.png", s)

        # Splash icon: 240 dp canvas, figure inside the 160 dp mask circle.
        sp = round(240 * k)
        save(fit(icon, sp, 0.56), f"{RES}/drawable-{d}/splash_tuck.png")

        # Home-screen widget mark.
        w = round(40 * k)
        save(fit(icon, w * 4, 0.96), f"{RES}/drawable-{d}/widget_tuck.png", w)

    play = fit(icon, 512, 0.72, bg=SAND)
    save(play, os.path.join(EXP, "play-store-icon-512.png"))
    save(fit(icon, 1024, 0.96), os.path.join(EXP, "tuck_icon.png"))

    # ----- Web -----
    web = os.path.join(APP, "web")
    save(fit(icon, 128, 0.98), f"{web}/favicon.png", 32)
    for n in (192, 512):
        save(fit(icon, n, 0.80, bg=SAND), f"{web}/icons/Icon-{n}.png")
        save(fit(icon, n, 0.62, bg=SAND), f"{web}/icons/Icon-maskable-{n}.png")
    save(fit(icon, 352, 1.0), f"{web}/icons/tuck-splash.png")

    # ----- Windows -----
    ico = os.path.join(APP, "windows/runner/resources/app_icon.ico")
    fit(icon, 256, 0.96).save(ico, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    splash_extras(icon)
    preview(cut, icon, frame)


# The PACE wordmark, light ink on the off-white page and mint on charcoal.
WORDMARK_SVG = os.path.join(ROOT, "branding/archive/cairn/final/pace-wordmark.svg")
WORDMARK_INK = {"": "#35665A", "night-": "#9CC3B4"}


def splash_extras(icon):
    """The splash hand-off (D11): Tuck exactly as on the native splash, for
    Flutter to animate, and the wordmark as the native branding image."""
    assets = os.path.join(APP, "assets/mascot")
    for folder, k in (("", 1), ("2.0x", 2), ("3.0x", 3)):
        save(fit(icon, round(240 * k), 0.56), os.path.join(assets, folder, "splash_tuck.png"))

    # Android 12+ branding image: 200 x 80 dp, wordmark 120 dp wide in it.
    svg = open(WORDMARK_SVG).read()
    with tempfile.TemporaryDirectory() as tmp:
        for night, colour in WORDMARK_INK.items():
            src = os.path.join(tmp, f"wordmark-{night}.svg")
            open(src, "w").write(svg.replace("#35665A", colour))
            big = os.path.join(tmp, f"wordmark-{night}.png")
            subprocess.run(["magick", "-background", "none", "-density", "600", src, "-trim", big], check=True)
            mark = Image.open(big).convert("RGBA")
            for d, k in DENSITIES.items():
                w, h = round(200 * k), round(80 * k)
                mw = round(120 * k)
                m = mark.resize((mw, round(mark.height * mw / mark.width)), Image.LANCZOS)
                out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
                out.alpha_composite(m, ((w - m.width) // 2, (h - m.height) // 2))
                save(out, f"{RES}/drawable-{night}{d}/splash_wordmark.png")


def preview(cut, icon, frame):
    cell = 260
    sheet = Image.new("RGBA", (cell * 9, cell * 3 + 200), (255, 255, 255, 255))
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(POSES + ["blink"]):
        sq = cut[p].crop(frame).resize((cell - 20, cell - 20), Image.LANCZOS)
        sheet.alpha_composite(sq, (i * cell + 10, 10))
        dark = Image.new("RGBA", (cell, cell), INK + (255,))
        dark.alpha_composite(sq, (10, 10))
        sheet.alpha_composite(dark, (i * cell, cell))
        d.text((i * cell + 10, 2 * cell - 18), p, fill=(255, 255, 255, 255))
    y = 2 * cell + 20
    x = 10
    for n in (16, 24, 48, 96, 192):
        sheet.alpha_composite(fit(icon, n, 0.96), (x, y)); x += n + 20
    for n in (24, 48, 96):
        tile = Image.new("RGBA", (n, n), INK + (255,))
        tile.alpha_composite(silhouette_with_face(fit(icon, 384, 0.92)).resize((n, n), Image.LANCZOS))
        sheet.alpha_composite(tile, (x, y)); x += n + 20
    for n in (96, 192):
        fg = fit(icon, n, 0.60, dy=0.01)
        bgc = Image.new("RGBA", (n, n), SAND + (255,)); bgc.alpha_composite(fg)
        m = Image.new("L", (n, n), 0); ImageDraw.Draw(m).ellipse((0, 0, n, n), fill=255)
        circ = Image.new("RGBA", (n, n), (0, 0, 0, 0)); circ.paste(bgc, (0, 0), m)
        sheet.alpha_composite(circ, (x, y)); x += n + 20
        mono = Image.new("RGBA", (n, n), (220, 230, 225, 255))
        mono.alpha_composite(line_art(fit(icon, n * 4, 0.60, dy=0.01)).resize((n, n), Image.LANCZOS).point(lambda v: v))
        mono_dark = Image.new("RGBA", (n, n), MOSS + (255,)); mono_dark.alpha_composite(line_art(fit(icon, n * 4, 0.60, dy=0.01)).resize((n, n), Image.LANCZOS))
        sheet.alpha_composite(mono_dark, (x, y)); x += n + 20
    save(sheet.crop((0, 0, cell * 9, y + 200)), os.path.join(ROOT, "branding/mascot/preview.png"))


if __name__ == "__main__":
    main()
