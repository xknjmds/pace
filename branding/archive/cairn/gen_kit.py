"""Generate PACE final artwork (cairn symbol, wordmark, lockups, Android assets)."""
import math, os
MOSS, SAND, INK, WHITE = "#35665A", "#F3EEE6", "#1C2622", "#FFFFFF"
F = "final"; X = "export/android"

def svg(title, w, body, h=256, extra=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-labelledby="t"{extra}>\n'
            f'  <title id="t">{title}</title>\n{body}</svg>\n')
def stroke(d, sw, c):
    return f'  <path fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" d="{d}"/>\n'

# ---------- Symbol: cairn. Three pills, heights 56/50/44, gaps 12, gentle hand-stacked offsets ----------
def cairn(color, gap=12, offsets=(0, 6, -4), y0=None):
    hs = (44, 50, 56); ws = (72, 124, 176)           # top -> bottom
    total = sum(hs) + 2*gap
    y = y0 if y0 is not None else (256 - total)/2 - 4   # optical centre: 4 units above geometric
    out = ""
    for i,(h,w) in enumerate(zip(hs, ws)):
        cx = 128 + offsets[2-i]                        # offsets given bottom->top
        out += f'  <rect x="{cx - w/2:g}" y="{y:g}" width="{w}" height="{h}" rx="{h/2:g}" fill="{color}"/>\n'
        y += h + gap
    return out
SYM = cairn(MOSS)
SYM_SMALL = cairn(MOSS, gap=18, offsets=(0,0,0))      # small-size cut: wider gaps, no offsets
open(f"{F}/pace-symbol.svg","w").write(svg("PACE symbol", 256, SYM))
open(f"{F}/pace-symbol-small.svg","w").write(svg("PACE symbol, small-size cut", 256, SYM_SMALL))

# ---------- Wordmark (monoline, constructed letters) ----------
sw = 22; top, base = 75, 192; mid = (top+base)/2
def P(x,c):  return stroke(f"M{x+11} {base} V{top} H{x+60} A33 33 0 0 1 {x+60} {top+66} H{x+11}", sw, c)
def A(x,c):
    dx = (base-top)/math.tan(math.radians(67.5)); ax = x+11+dx
    cb = base-42; t=(cb-top)/(base-top)
    return stroke(f"M{x+11} {base} L{ax:.2f} {top} L{ax+dx:.2f} {base} M{ax-dx*t:.2f} {cb} H{ax+dx*t:.2f}", sw, c)
def C(x,c):
    rr = (base-top)/2 + 1.5; cxx = x+11+rr; kk = rr*math.cos(math.radians(45))   # +1.5 overshoot on the round letter
    return stroke(f"M{cxx+kk:.2f} {mid-kk:.2f} A{rr} {rr} 0 1 0 {cxx+kk:.2f} {mid+kk:.2f}", sw, c)
def E(x,c):  return stroke(f"M{x+11+66} {top} H{x+11} V{base} H{x+11+66} M{x+11} {mid} H{x+11+54}", sw, c)
Pw = 104; Aw = 2*((base-top)/math.tan(math.radians(67.5)))+22; Cw = (base-top)+25; Ew = 99; gap = 34
def wordmark(x0, c):
    x = x0; out = P(x,c); x += Pw+gap+4
    out += A(x,c); x += Aw+gap
    out += C(x,c); x += Cw+gap
    out += E(x,c); x += Ew
    return out, x
wm, wmw = wordmark(0, MOSS); WMW = math.ceil(wmw)
open(f"{F}/pace-wordmark.svg","w").write(svg("PACE wordmark", WMW, wm))

# ---------- Horizontal lockup: symbol scaled to cap-height ink (139), gap = 52 ----------
def horizontal(c, bg=None):
    sym_body = cairn(c); bx,by,bw,bh = 40, 37, 176, 174
    sc = 139/bh
    g = f'  <g transform="translate({-bx*sc:.2f} {(top-11)-by*sc:.2f}) scale({sc:.4f})">\n{sym_body}  </g>\n'
    body, w = wordmark(bw*sc + 52, c)
    W = math.ceil(w)
    pre = f'  <rect width="{W}" height="256" fill="{bg}"/>\n' if bg else ""
    return pre + g + body, W
hb, HW = horizontal(MOSS)
open(f"{F}/pace-horizontal.svg","w").write(svg("PACE logo, horizontal", HW, hb))

# ---------- Stacked lockup: symbol above wordmark, centred; canvas height 256 ----------
def stacked(c):
    # symbol ink height 120 at top, gap 28, wordmark cap ink 139*0.62
    ssc = 120/174; wsc = 0.62
    sym_w = 176*ssc; wm_w = WMW*wsc
    W = math.ceil(max(sym_w, wm_w) + 32)
    g = f'  <g transform="translate({(W-sym_w)/2 - 40*ssc:.2f} {16 - 37*ssc:.2f}) scale({ssc:.4f})">\n{cairn(c)}  </g>\n'
    body, _ = wordmark(0, c)
    g += f'  <g transform="translate({(W-wm_w)/2:.2f} {16+120+28 - (top-11)*wsc:.2f}) scale({wsc})">\n{body}  </g>\n'
    return g, W
sb, SW = stacked(MOSS)
open(f"{F}/pace-stacked.svg","w").write(svg("PACE logo, stacked", SW, sb))

# ---------- Presentation artwork: symbol on moss tile, lockup on dark ----------
open(f"{F}/pace-symbol-on-tile.svg","w").write(svg("PACE app icon", 256,
    f'  <rect width="256" height="256" rx="56" fill="{MOSS}"/>\n' + '  <g transform="translate(37 37) scale(0.71)">\n' + cairn(SAND, gap=18, offsets=(0,0,0)) + '  </g>\n'))
hd, _ = horizontal(SAND)
open(f"{F}/pace-horizontal-on-dark.svg","w").write(svg("PACE logo on dark", HW, hd))

# ---------- Android: adaptive icon (108dp canvas, 66dp safe zone), monochrome, notification ----------
# symbol box 176x174 -> fit in 56dp centred: scale 56/176
s = 56/176
fg = f'  <g transform="translate({54-128*s:.3f} {54-124*s:.3f}) scale({s:.4f})">\n' + cairn(SAND, gap=18, offsets=(0,0,0)) + '  </g>\n'
open(f"{X}/ic_launcher_foreground.svg","w").write(svg("PACE launcher foreground", 108, fg, 108))
open(f"{X}/ic_launcher_background.svg","w").write(svg("PACE launcher background", 108, f'  <rect width="108" height="108" fill="{MOSS}"/>\n', 108))
mono = fg.replace(SAND, "#000000")
open(f"{X}/ic_launcher_monochrome.svg","w").write(svg("PACE launcher monochrome", 108, mono, 108))
# notification small icon: white silhouette on transparent, 24dp canvas, 20dp live area
s2 = 20/176
notif = f'  <g transform="translate({12-128*s2:.3f} {12-124*s2:.3f}) scale({s2:.4f})">\n' + cairn(WHITE, gap=18, offsets=(0,0,0)) + '  </g>\n'
open(f"{X}/ic_stat_pace.svg","w").write(svg("PACE notification icon", 24, notif, 24))
print("ok", WMW, HW, SW)
