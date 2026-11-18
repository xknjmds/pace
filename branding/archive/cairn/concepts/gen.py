import math
S = 28

def svg(title, w, body, h=256):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-labelledby="t">\n'
            f'  <title id="t">{title}</title>\n{body}</svg>\n')
def stroke(d, sw=S, c="#111"):
    return f'  <path fill="none" stroke="{c}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" d="{d}"/>\n'

# ---------- A: Cairn (three stacked stones) ----------
stones = [(40,180,176,52),(66,116,124,52),(94,52,68,52)]   # x,y,w,h ; gap 12
A_sym = "".join(f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h//2}" fill="#111"/>\n' for x,y,w,h in stones)
open("a-symbol.svg","w").write(svg("PACE concept A: cairn", 256, A_sym))

# ---------- B: Steps and a landing inside a circle (rounded corners r=14) ----------
cx, cy, r = 128, 128, 108
def xint(y): return cx + math.sqrt(r*r - (y-cy)**2)
yl, yr = 176, 80
xl = 2*cx - xint(yl); xr = xint(yr); k = 14
B_d = (f"M{xl:.2f} {yl} H{72-k} A{k} {k} 0 0 0 72 {yl-k} V{128+k} A{k} {k} 0 0 1 {72+k} 128 "
       f"H{184-k} A{k} {k} 0 0 0 184 {128-k} V{yr+k} A{k} {k} 0 0 1 {184+k} {yr} H{xr:.2f} "
       f"A{r} {r} 0 0 1 {xl:.2f} {yl} Z")
B_up = (f"M{xl:.2f} {yl} H{72-k} A{k} {k} 0 0 0 72 {yl-k} V{128+k} A{k} {k} 0 0 1 {72+k} 128 "
       f"H{184-k} A{k} {k} 0 0 0 184 {128-k} V{yr+k} A{k} {k} 0 0 1 {184+k} {yr} H{xr:.2f} "
       f"A{r} {r} 0 0 0 {xl:.2f} {yl} Z")
B_sym = f'  <path fill="#C9C9C9" d="{B_up}"/>\n  <path fill="#111" d="{B_d}"/>\n'
open("b-symbol.svg","w").write(svg("PACE concept B: steps and a landing", 256, B_sym))

# ---------- C: Still a P (one gap in the stem) ----------
C_sym = stroke("M72 148 V44 H128 A52 52 0 0 1 128 148 Z") + stroke("M72 190 V212")
open("c-symbol.svg","w").write(svg("PACE concept C: still a P", 256, C_sym))

# ---------- Wordmark PACE (monoline, constructed) ----------
sw = 22; top, base = 75, 192; mid = (top+base)/2
def P(x):  return stroke(f"M{x+11} {base} V{top} H{x+60} A33 33 0 0 1 {x+60} {top+66} H{x+11}", sw)
def Pgap(x):  # lockup version of concept C at wordmark scale
    return stroke(f"M{x+11} {top+56} V{top} H{x+56} A28 28 0 0 1 {x+56} {top+56} Z", sw) + stroke(f"M{x+11} {top+86} V{base}", sw)
def A(x):
    dx = (base-top)/math.tan(math.radians(67.5)); ax = x+11+dx
    cb = base-42; t=(cb-top)/(base-top)
    return stroke(f"M{x+11} {base} L{ax:.2f} {top} L{ax+dx:.2f} {base} M{ax-dx*t:.2f} {cb} H{ax+dx*t:.2f}", sw)
def C(x):
    rr = (base-top)/2; cxx = x+11+rr; kk = rr*math.cos(math.radians(45))
    return stroke(f"M{cxx+kk:.2f} {mid-kk:.2f} A{rr} {rr} 0 1 0 {cxx+kk:.2f} {mid+kk:.2f}", sw)
def E(x):  return stroke(f"M{x+11+66} {top} H{x+11} V{base} H{x+11+66} M{x+11} {mid} H{x+11+54}", sw)
Pw, Aw, Cw, Ew, gap = 104, 2*((base-top)/math.tan(math.radians(67.5)))+22, (base-top)+22, 99, 34
def wordmark(x0, first=P):
    x = x0; out = first(x); x += Pw+gap+4
    out += A(x); x += Aw+gap
    out += C(x); x += Cw+gap
    out += E(x); x += Ew
    return out, x
wm, wmw = wordmark(0)
open("wordmark.svg","w").write(svg("PACE wordmark", math.ceil(wmw), wm))

def lockup(name, sym_body, sym_box, space=52):
    bx,by,bw,bh = sym_box; sc = 139/bh
    g = f'  <g transform="translate({-bx*sc:.2f} {(top-11)-by*sc:.2f}) scale({sc:.4f})">\n{sym_body}  </g>\n'
    body, w = wordmark(bw*sc + space)
    open(f"{name}-lockup.svg","w").write(svg(f"PACE lockup {name}", math.ceil(w), g+body))
lockup("a", A_sym, (40, 52, 176, 180))
lockup("b", B_sym, (20, 20, 216, 216))
cl, clw = wordmark(0, first=Pgap)
open("c-lockup.svg","w").write(svg("PACE lockup c", math.ceil(clw), cl))
print("ok")
