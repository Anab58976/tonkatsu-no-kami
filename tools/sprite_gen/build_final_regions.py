"""Characters, props and ground for the last three regions.

Team art used directly:  Cisne Dourado, Tronquinho, Monstro Pimenta Coroado
(pimentinhas), Criaturinha Tronco com Flor (toquinho) — see build_strips.py.
Drawn here in the game's style (no team art yet): Rei Quente (sun-headed king,
boss of the Reino dos Temperos), Espadashi Touro (bull samurai with two sword
'hashi', boss of the Arena final) and the Oniguerreiros (onigiri warriors of
the arena). Plus the toquinho's animations, the tronquinho attack without the
loose projectile blobs, ground textures and props for the spice kingdom and
the arena.

    python3 build_final_regions.py [rei_quente touro onigiri toquinho tronquinho ground props]
"""
from __future__ import annotations

import json
import math
import os
import sys

import numpy as np
from PIL import Image

from illus import Illu, rot, ellipse_pts, palette_from, apply_pal, ink_outline, hexc
from rig import Canvas, SheetWriter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
SRC = os.path.join(ROOT, "assets", "sprites", "source")
PROPS = os.path.join(ROOT, "assets", "sprites", "props")
GROUND = os.path.join(ROOT, "assets", "sprites", "tiles", "ground")
PREV = os.path.join(os.path.dirname(__file__), "_preview")


def to_canvas(px, cell_w, cell_h=None):
    c = Canvas(cell_w, cell_h or cell_w)
    c.img = Image.fromarray(px)
    return c


def tint_px(px, col=(255, 255, 255), k=0.75):
    out = px.copy().astype(np.float32)
    m = out[:, :, 3] > 0
    for i in range(3):
        out[:, :, i][m] = out[:, :, i][m] * (1 - k) + col[i] * k
    return out.astype(np.uint8)


def fade_px(px, k):
    out = px.copy()
    out[:, :, 3] = (out[:, :, 3] * k).astype(np.uint8)
    return out


def write_sheet(cid, cell, origin, anims, k=22, source=""):
    """anims: {name: ([rgba frames], fps, loop)} — one shared palette."""
    allf = [f for fr, *_ in anims.values() for f in fr]
    pal = palette_from([f for f in allf if f[:, :, 3].any()], k)
    W = SheetWriter(GEN, cid, cell, cell, origin=origin)
    prev = []
    for name, (fr, fps, loop) in anims.items():
        fr = [apply_pal(f, pal) for f in fr]
        prev.extend(fr[:3])
        W.add(name, [to_canvas(f, cell) for f in fr], fps=fps, loop=loop)
    W.meta["generated"] = True
    W.meta["source"] = source
    W.close()
    os.makedirs(PREV, exist_ok=True)
    sheet = Image.new("RGBA", (cell * min(12, len(prev)), cell * ((len(prev) + 11) // 12)), (80, 96, 70, 255))
    for i, f in enumerate(prev):
        im = Image.fromarray(f)
        sheet.alpha_composite(im, ((i % 12) * cell, (i // 12) * cell))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(PREV, f"final_{cid}.png"))
    print(cid, {n: len(v[0]) for n, v in anims.items()})


# =================================================================== REI QUENTE
def rei_quente(p):
    """Sun-headed king. p: bob, rays (length k), ray_rot, arm_r (scepter arm
    angle, 0 = down), arm_l, step (-1..1), flare (0..1 white glow), dim (0..1),
    lean, squash."""
    C = 128
    I = Illu(C, C, S=5)
    cx = 64 + p.get("lean", 0)
    by = p.get("bob", 0)
    step = p.get("step", 0)
    dim = p.get("dim", 0.0)
    flare = p.get("flare", 0.0)
    sq = p.get("squash", 1.0)

    def dc(hexs, k=1.0):     # dimmed colour (death) / flared colour (special)
        c = hexc(hexs)
        grey = np.array([c.mean()] * 3)
        c = c * (1 - dim) + grey * dim * 0.7
        c = c + (255 - c) * flare * 0.3
        return np.clip(c * k, 0, 255)

    foot = 121
    head_y = 40 + by + (1 - sq) * 30
    # cape behind (gold edge)
    I.poly([(cx - 22, 58 + by), (cx + 22, 58 + by), (cx + 38, foot - 1), (cx - 38, foot - 1)], dc("#e0a42a"), shade=0.7)
    I.poly([(cx - 21, 59 + by), (cx + 21, 59 + by), (cx + 35, foot - 3), (cx - 35, foot - 3)], dc("#6e1220"), shade=0.8)
    # feet (golden curled slippers)
    for sx, st in ((-1, step), (1, -step)):
        fx = cx + sx * 11
        fy = foot - 3 - max(0, st) * 3
        I.poly([(fx - 7, fy + 3), (fx + 6, fy + 3), (fx + 9 * sx if sx > 0 else fx + 6, fy - 1), (fx, fy - 4), (fx - 7, fy - 1)], dc("#d9a21e"))
    # robe: round royal belly with folds
    robe = [(cx - 18, 60 + by), (cx + 18, 60 + by), (cx + 27, 78 + by), (cx + 30, 100 + by), (cx + 28, foot - 4),
            (cx - 28, foot - 4), (cx - 30, 100 + by), (cx - 27, 78 + by)]
    I.poly(robe, dc("#c22a2e"), tex=0.16)
    for fxo in (-18, -9, 9, 18):          # folds
        I.detail("line", [(cx + fxo * 0.9, 92 + by), (cx + fxo * 1.05, foot - 8)], color=dc("#7e1420"), width=0.9)
    # golden front panel with sun embroidery
    I.poly([(cx - 7, 62 + by), (cx + 7, 62 + by), (cx + 10, foot - 6), (cx - 10, foot - 6)], dc("#f0b42a"), shade=0.8)
    for k in range(3):
        yy = 96 + by + k * 8
        I.detail("ellipse", cx, yy, 2.4, 2.4, color=dc("#e0501a"))
        for j in range(6):
            a = math.radians(j * 60)
            I.detail("line", [(cx + math.cos(a) * 2.8, yy + math.sin(a) * 2.8), (cx + math.cos(a) * 4.2, yy + math.sin(a) * 4.2)], color=dc("#e0501a"), width=0.7)
    # hem: gold band with red flames
    I.poly([(cx - 29, foot - 10), (cx + 29, foot - 10), (cx + 30, foot - 3), (cx - 30, foot - 3)], dc("#f0b42a"), shade=0.8)
    for i in range(7):
        x = cx - 25 + i * 8.3
        I.detail("poly", [(x - 2.5, foot - 4), (x, foot - 9.5), (x + 2.5, foot - 4)], color=dc("#d8401c"))
    # belt of spice pouches + sun gem
    I.poly([(cx - 26, 82 + by), (cx + 26, 82 + by), (cx + 27, 89 + by), (cx - 27, 89 + by)], dc("#8a4a1c"))
    for k, c in enumerate(("#e8b020", "#4a9a3a", "#d8301e", "#e8b020")):
        xx = cx - 20 + k * 13.3
        if abs(xx - cx) > 5:
            I.ellipse(xx, 90 + by, 3.4, 4, dc(c))
    I.ellipse(cx, 85.5 + by, 5, 4.5, dc("#e8c040"))
    I.ellipse(cx, 85.5 + by, 3, 2.8, dc("#3fb8c8"), glow=0.3)
    # shoulder mantle: flame-shaped orange collar
    mantle = [(cx - 25, 70 + by), (cx - 22, 60 + by), (cx - 10, 55 + by), (cx + 10, 55 + by), (cx + 22, 60 + by), (cx + 25, 70 + by)]
    for k in range(7):
        x = cx - 22 + k * 7.3
        mantle.insert(6 + k, (x, 74 + by + (3 if k % 2 == 0 else 0)))
    I.poly([(cx - 25, 70 + by), (cx - 22, 60 + by), (cx - 10, 55 + by), (cx + 10, 55 + by), (cx + 22, 60 + by), (cx + 25, 70 + by),
            (cx + 18, 76 + by), (cx + 11, 72 + by), (cx + 4, 77 + by), (cx - 4, 72 + by), (cx - 11, 77 + by), (cx - 18, 72 + by)],
           dc("#ff8a1c"), glow=0.15)
    def arm(sh, ang, front=False):
        hand = rot([(sh[0] + (8 if sh[0] > cx else -8), sh[1] + 22)], ang, sh)[0]
        mid = ((sh[0] + hand[0]) / 2, (sh[1] + hand[1]) / 2)
        I.line([sh, hand], dc("#c22a2e"), width=11)                       # wide sleeve
        cuff = (sh[0] * 0.25 + hand[0] * 0.75, sh[1] * 0.25 + hand[1] * 0.75)
        I.line([cuff, hand], dc("#f0b42a"), width=10)
        I.ellipse(hand[0], hand[1], 5.2, 5, dc("#ffb43a"))                 # fist
        for k in range(3):
            I.detail("line", [(hand[0] - 3 + k * 2.4, hand[1] - 2), (hand[0] - 3 + k * 2.4, hand[1] + 1)], color=dc("#c8701a"), width=0.6)
        return hand
    # left arm
    arm((cx - 22, 64 + by), p.get("arm_l", 0))
    # head: the sun (wavy flame rays behind the face)
    rays = p.get("rays", 1.0)
    rr = p.get("ray_rot", 0.0)
    R = 18
    for i in range(14):
        a = math.radians(rr + i * 360 / 14)
        long_ = (i % 2 == 0)
        L = (R + (14 if long_ else 8) * rays) * (1 + 0.05 * math.sin(i * 1.7 + rr * 0.1))
        w = 0.26 if long_ else 0.2
        bend = 0.18 * math.sin(i + rr * 0.05)
        tip = (cx + math.cos(a + bend) * L, head_y + math.sin(a + bend) * L)
        midp = (cx + math.cos(a + bend * 0.4) * (R + (L - R) * 0.55), head_y + math.sin(a + bend * 0.4) * (R + (L - R) * 0.55))
        b1 = (cx + math.cos(a - w) * (R - 2), head_y + math.sin(a - w) * (R - 2))
        b2 = (cx + math.cos(a + w) * (R - 2), head_y + math.sin(a + w) * (R - 2))
        off = 2.6
        I.poly([b1, (midp[0] + math.cos(a - 1.57) * off, midp[1] + math.sin(a - 1.57) * off), tip,
                (midp[0] + math.cos(a + 1.57) * off * 0.6, midp[1] + math.sin(a + 1.57) * off * 0.6), b2],
               dc("#ee4a18" if long_ else "#ff8a1c"), shade=0.6, glow=0.3 + flare)
        I.detail("poly", [(b1[0] * 0.6 + b2[0] * 0.4, b1[1] * 0.6 + b2[1] * 0.4), midp, (b1[0] * 0.4 + b2[0] * 0.6, b1[1] * 0.4 + b2[1] * 0.6)],
                 color=dc("#ffd23a"))
    I.ellipse(cx, head_y, R + 1.5, R + 1.5, dc("#ff9a1c"), glow=0.2 + flare)    # corona
    I.ellipse(cx, head_y, R, R, dc("#ffc12e"), glow=0.25 + flare, tex=0.08)
    I.ellipse(cx - 6, head_y - 7, 6, 4, dc("#ffe68a"), flat=True)           # shine
    # face
    if dim < 0.6:
        for sx in (-1, 1):
            ex = cx + sx * 7
            # fierce brows: inner end LOW, outer end high
            ox_, ix_ = ex + sx * 5, ex - sx * 4.5            # outer end high, inner end low = fierce
            I.detail("poly", [(ox_, head_y - 8), (ex, head_y - 6.2), (ix_, head_y - 3.6),
                              (ix_, head_y - 1.8), (ex, head_y - 4.2), (ox_, head_y - 6.2)], color=dc("#8a2a0e"))
            I.detail("ellipse", ex, head_y + 1, 3.2, 3.4, color=(255, 252, 236))
            I.detail("ellipse", ex + sx * -0.8, head_y + 1.4, 2.0, 2.5, color=(34, 14, 12))
            I.detail("ellipse", ex + sx * -0.2, head_y + 0.2, 0.8, 0.8, color=(255, 255, 255))
            I.detail("ellipse", cx + sx * 12.5, head_y + 7, 3, 2, color=dc("#ff7a3a"))      # cheeks
        # big flame moustache curling up + confident grin with teeth
        I.poly([(cx, head_y + 6), (cx - 6, head_y + 5.5), (cx - 12, head_y + 7), (cx - 15, head_y + 3.5), (cx - 16, head_y + 7.5),
                (cx - 12, head_y + 11), (cx - 5, head_y + 9.5), (cx, head_y + 10.5), (cx + 5, head_y + 9.5), (cx + 12, head_y + 11),
                (cx + 16, head_y + 7.5), (cx + 15, head_y + 3.5), (cx + 12, head_y + 7), (cx + 6, head_y + 5.5)], dc("#d8401a"), shade=0.7)
        I.detail("poly", [(cx - 7, head_y + 11), (cx + 7, head_y + 11), (cx + 5, head_y + 15.5), (cx, head_y + 16.5), (cx - 5, head_y + 15.5)], color=(80, 16, 14))
        I.detail("poly", [(cx - 6, head_y + 11.1), (cx + 6, head_y + 11.1), (cx + 5.4, head_y + 12.6), (cx - 5.4, head_y + 12.6)], color=(252, 246, 232))
        I.detail("ellipse", cx, head_y + 15, 2.5, 1.2, color=dc("#e0506a"))
    else:
        for sx in (-1, 1):
            ex = cx + sx * 7
            I.detail("line", [(ex - 3, head_y - 1), (ex + 3, head_y + 2)], color=(60, 30, 20), width=1.2)
            I.detail("line", [(ex - 3, head_y + 2), (ex + 3, head_y - 1)], color=(60, 30, 20), width=1.2)
        I.detail("line", [(cx - 5, head_y + 11), (cx + 5, head_y + 11)], color=(60, 30, 20), width=1.0)
    # crown on the sun
    cy0 = head_y - R + 3
    I.poly([(cx - 10, cy0 + 3), (cx - 11, cy0 - 6), (cx - 5, cy0 - 1), (cx, cy0 - 9), (cx + 5, cy0 - 1), (cx + 11, cy0 - 6), (cx + 10, cy0 + 3)], dc("#f2c230"))
    for gx, gc in ((cx - 6, "#3fb8c8"), (cx, "#e0303a"), (cx + 6, "#3fb8c8")):
        I.detail("ellipse", gx, cy0 + 0.5, 1.4, 1.4, color=dc(gc))
    # right arm with the chili scepter (in front)
    hand = arm((cx + 22, 64 + by), p.get("arm_r", 0))
    ar = p.get("arm_r", 0)
    ang = math.radians(ar - 80)
    top = (hand[0] + math.cos(ang) * 32, hand[1] + math.sin(ang) * 32)
    bot = (hand[0] - math.cos(ang) * 10, hand[1] - math.sin(ang) * 10)
    I.line([bot, top], dc("#e8b23a"), width=3)
    ox, oy = top
    I.poly(rot([(ox - 4, oy), (ox + 4, oy), (ox + 3.5, oy - 10), (ox + 1, oy - 15), (ox - 3, oy - 17), (ox - 3.5, oy - 10)], ar, (ox, oy)),
           dc("#e0262a"), glow=0.3 + flare)
    I.poly(rot([(ox - 5, oy + 1.5), (ox + 5, oy + 1.5), (ox + 2, oy - 2), (ox, oy - 3), (ox - 2, oy - 2)], ar, (ox, oy)), dc("#3c9a32"))
    I.ellipse(hand[0], hand[1], 5.2, 5, dc("#ffb43a"))
    return I.pixels()


def build_rei_quente():
    P = rei_quente
    idle = [P({"ray_rot": i * 6.4, "rays": 1.0 + 0.08 * math.sin(i * 1.6), "bob": [0, 0, 1, 1][i], "arm_r": 4, "arm_l": -6}) for i in range(4)]
    walk = [P({"ray_rot": i * 8, "bob": [0, -2, 0, -2][i], "step": [1, 0, -1, 0][i], "arm_r": [8, 2, -4, 2][i], "arm_l": [-10, -4, 2, -4][i]}) for i in range(4)]
    attack = [P({"arm_r": -40, "rays": 1.1, "bob": -1}), P({"arm_r": -120, "rays": 1.3, "flare": 0.3, "bob": -2}),
              P({"arm_r": -150, "rays": 1.45, "flare": 0.6, "bob": -3}), P({"arm_r": 30, "rays": 1.2, "flare": 0.2, "lean": 2}),
              P({"arm_r": 10, "rays": 1.0})]
    special = [P({"arm_r": -60, "arm_l": 60, "rays": 1.1 + i * 0.12, "flare": i * 0.1, "ray_rot": i * 10, "bob": -i // 2}) for i in range(6)]
    hurt = [tint_px(P({"arm_r": 20, "arm_l": -20, "lean": -2})), P({"arm_r": 10, "lean": -1})]
    die = [P({"rays": 0.9, "dim": 0.2}), P({"rays": 0.6, "dim": 0.45, "bob": 2}), P({"rays": 0.35, "dim": 0.7, "bob": 4, "squash": 0.92}),
           fade_px(P({"rays": 0.15, "dim": 0.9, "bob": 6, "squash": 0.85}), 0.7), fade_px(P({"rays": 0.0, "dim": 1.0, "bob": 8, "squash": 0.8}), 0.35)]
    write_sheet("rei_quente", 128, (64, 121), {"idle": (idle, 6, True), "walk": (walk, 7, True), "attack": (attack, 9, False),
                                             "special": (special, 9, False), "hurt": (hurt, 10, False), "die": (die, 6, False)},
                k=24, source="desenhado no estilo do jogo (sem arte da equipe ainda)")


# =================================================================== ESPADASHI TOURO
def _taper(p0, p1, p2, w0, w1, n=14):
    """Tapered curved stroke (horns, blades) as a polygon along a quadratic bezier."""
    left, right = [], []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        dx = 2 * (1 - t) * (p1[0] - p0[0]) + 2 * t * (p2[0] - p1[0])
        dy = 2 * (1 - t) * (p1[1] - p0[1]) + 2 * t * (p2[1] - p1[1])
        L = math.hypot(dx, dy) or 1
        nx, ny = -dy / L, dx / L
        w = (w0 + (w1 - w0) * t) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def touro(p):
    """Espadashi Touro: bull samurai with two great sword-hashi. p: bob, step,
    sl / sr (sword arm angles, 20 = held low, 150 = raised), lean, charge
    (0..1 head lowered), dim, steam."""
    C = 144
    I = Illu(C, C, S=5)
    cx = 72 + p.get("lean", 0)
    by = p.get("bob", 0)
    step = p.get("step", 0)
    dim = p.get("dim", 0.0)
    ch = p.get("charge", 0.0)

    def dc(h):
        c = hexc(h)
        g = np.array([c.mean()] * 3)
        return np.clip(c * (1 - dim) + g * dim * 0.6, 0, 255)

    FUR, FUR_D, FUR_L = "#4c2c1c", "#2e1a10", "#6e4630"
    RED, RED_D, GOLD = "#b8222c", "#7a121c", "#e2b03a"
    foot = 137
    hy = 44 + by + ch * 12

    def sword_geo(side, ang):
        sh = (cx + side * 30, 70 + by)
        hand = rot([(cx + side * 38, 96 + by)], ang * side, sh)[0]
        a = math.radians(-90 + ang * side + side * 10)
        d = (math.cos(a), math.sin(a))
        return sh, hand, d

    def draw_sword(side, ang):
        sh, hand, d = sword_geo(side, ang)
        nx, ny = -d[1], d[0]
        butt = (hand[0] - d[0] * 14, hand[1] - d[1] * 14)
        guard = (hand[0] + d[0] * 5, hand[1] + d[1] * 5)
        tip = (hand[0] + d[0] * 58, hand[1] + d[1] * 58)
        ctrl = ((guard[0] + tip[0]) / 2 + nx * 3 * side, (guard[1] + tip[1]) / 2 + ny * 3 * side)
        I.line([butt, hand], dc("#5a3418"), width=4.2)                             # long hashi grip
        for k in (0.25, 0.6):
            q = (butt[0] * (1 - k) + hand[0] * k, butt[1] * (1 - k) + hand[1] * k)
            I.detail("ellipse", q[0], q[1], 1.8, 1.8, color=dc(RED))
        I.poly(_taper(guard, ctrl, tip, 4.6, 0.6), dc("#cfd5df"), shade=1.2)       # blade
        I.detail("poly", _taper(guard, ctrl, tip, 1.2, 0.3), color=dc("#f7f9ff"))
        I.ellipse(guard[0], guard[1], 5, 3.4, dc(GOLD))                            # tsuba

    sl, sr = p.get("sl", 20), p.get("sr", 20)
    if sl >= 100:
        draw_sword(-1, sl)
    if sr >= 100:
        draw_sword(1, sr)
    # legs: thick furred thighs, shins, split hooves
    for sx, st in ((-1, step), (1, -step)):
        lx = cx + sx * 14
        lift = max(0, st) * 4
        I.ellipse(lx, 114 + by, 10, 9, dc(FUR))
        I.poly([(lx - 8, 116 + by), (lx + 8, 116 + by), (lx + 7 + sx * 2, foot - 7 - lift), (lx - 6 + sx * 2, foot - 7 - lift)], dc(FUR))
        I.poly([(lx - 7 + sx * 2, foot - 9 - lift), (lx + 8 + sx * 2, foot - 9 - lift), (lx + 8 + sx * 2, foot - 2 - lift), (lx - 7 + sx * 2, foot - 2 - lift)], dc("#26201c"))
        I.detail("line", [(lx + sx * 2 + 0.5, foot - 8 - lift), (lx + sx * 2 + 0.5, foot - 2 - lift)], color=(10, 8, 8), width=0.8)
    # kusazuri: overlapping lacquer plates with gold lacing
    for i, off in enumerate((-24, 24, -12, 12, 0)):
        I.poly([(cx + off - 8, 96 + by), (cx + off + 8, 96 + by), (cx + off + 9 + off * 0.08, 117 + by), (cx + off - 9 + off * 0.08, 117 + by)],
               dc(RED if i % 2 == 0 else RED_D))
        for row in (101, 106, 111):
            for k in range(3):
                I.detail("ellipse", cx + off - 4 + k * 4 + off * 0.03 * (row - 96) / 5, row + by, 0.8, 0.8, color=dc(GOLD))
    # torso: bull chest (fur) + dō armour on the belly
    I.poly([(cx - 34, 66 + by), (cx - 22, 58 + by), (cx + 22, 58 + by), (cx + 34, 66 + by), (cx + 28, 84 + by), (cx + 24, 100 + by),
            (cx - 24, 100 + by), (cx - 28, 84 + by)], dc(FUR))
    for sx in (-1, 1):
        I.ellipse(cx + sx * 10, 70 + by, 11, 8, dc(FUR_L))                         # pecs
    I.poly([(cx - 25, 80 + by), (cx + 25, 80 + by), (cx + 23, 99 + by), (cx - 23, 99 + by)], dc(RED))
    for k in range(3):
        y = 85 + k * 5 + by
        I.detail("line", [(cx - 24, y), (cx + 24, y)], color=dc(RED_D), width=0.9)
        for j in range(6):
            I.detail("ellipse", cx - 20 + j * 8, y - 2.2, 0.7, 0.7, color=dc(GOLD))
    I.ellipse(cx, 89 + by, 5.5, 5.5, dc(GOLD))                                      # crest (mon)
    I.detail("ellipse", cx, 89 + by, 2.4, 2.4, color=dc(RED))
    I.poly([(cx - 25, 97 + by), (cx + 25, 97 + by), (cx + 26, 102 + by), (cx - 26, 102 + by)], dc("#2a2638"))   # obi
    I.poly([(cx + 6, 98 + by), (cx + 12, 98 + by), (cx + 15, 108 + by), (cx + 9, 107 + by)], dc("#2a2638"))
    # shoulder plates
    for sx in (-1, 1):
        I.poly([(cx + sx * 24, 58 + by), (cx + sx * 42, 62 + by), (cx + sx * 44, 78 + by), (cx + sx * 28, 76 + by)], dc(RED))
        for k, y in enumerate((65, 71)):
            I.detail("line", [(cx + sx * 27, y + by), (cx + sx * 43, y + 2 + by)], color=dc(GOLD), width=0.9)
    # arms: big upper arms, red kote gauntlets, fists (raised arms go behind the head)
    def arms(raised):
      for side, ang in ((-1, sl), (1, sr)):
        if (ang >= 100) != raised:
            continue
        sh, hand, d = sword_geo(side, ang)
        el = (sh[0] * 0.5 + hand[0] * 0.5 + side * 2, sh[1] * 0.5 + hand[1] * 0.5)
        I.line([sh, el], dc(FUR), width=14)
        I.line([el, hand], dc(RED), width=11)
        I.detail("line", [(el[0] * 0.6 + hand[0] * 0.4, el[1] * 0.6 + hand[1] * 0.4), (el[0] * 0.3 + hand[0] * 0.7, el[1] * 0.3 + hand[1] * 0.7)],
                 color=dc(GOLD), width=1.0)
        I.ellipse(hand[0], hand[1], 6.5, 6, dc(FUR_D))
    arms(True)
    # head
    for sx in (-1, 1):                                                              # ears
        I.poly([(cx + sx * 14, hy - 4), (cx + sx * 27, hy - 7), (cx + sx * 25, hy), (cx + sx * 15, hy + 2)], dc(FUR))
        I.detail("ellipse", cx + sx * 22, hy - 3.2, 2.6, 1.4, color=dc("#c88a78"))
    # horns: tapered, curving out and up, cream with dark tips
    for sx in (-1, 1):
        base = (cx + sx * 13, hy - 11)
        ctrl = (cx + sx * 34, hy - 12)
        tip = (cx + sx * 34, hy - 34)
        I.poly(_taper(base, ctrl, tip, 8, 1.2), dc("#ead2a0"), shade=1.1)
        I.poly(_taper(((base[0] + tip[0]) / 2 + sx * 9, hy - 16), (cx + sx * 35, hy - 22), tip, 3.6, 1.0), dc("#7a6a54"))
    I.ellipse(cx, hy - 3, 19, 15, dc(FUR))                                          # skull
    I.poly([(cx - 15, hy - 8), (cx + 15, hy - 8), (cx + 12, hy - 3), (cx - 12, hy - 3)], dc(FUR_D))   # brow ridge
    I.poly([(cx - 5, hy - 18), (cx, hy - 23), (cx + 5, hy - 18), (cx + 3, hy - 13), (cx - 3, hy - 13)], dc(FUR_D))  # tuft
    I.ellipse(cx, hy + 11, 13, 9, dc("#c08868"))                                    # muzzle
    I.ellipse(cx, hy + 8, 9, 3, dc("#d8a080"), flat=True)
    for sx in (-1, 1):
        I.detail("ellipse", cx + sx * 5, hy + 12, 2.2, 2.8, color=(42, 18, 16))
    # nose ring
    I.part("line", [(cx - 4, hy + 15), (cx - 3, hy + 20), (cx, hy + 21.5), (cx + 3, hy + 20), (cx + 4, hy + 15)], color=dc(GOLD), width=1.6)
    # hachimaki with flying knot tails
    I.poly([(cx - 18, hy - 14), (cx + 18, hy - 14), (cx + 19, hy - 9), (cx - 19, hy - 9)], dc("#2c3a72"))
    I.detail("ellipse", cx, hy - 11.5, 2.6, 2.2, color=dc("#f0ede4"))
    I.poly([(cx + 18, hy - 13), (cx + 30, hy - 17), (cx + 33, hy - 13), (cx + 21, hy - 9)], dc("#2c3a72"))
    # eyes: glowing under the brow
    for sx in (-1, 1):
        ex = cx + sx * 8
        I.detail("poly", [(ex + sx * 5, hy - 7), (ex - sx * 4, hy - 3.5), (ex - sx * 4, hy - 1.5), (ex + sx * 5, hy - 4.5)], color=(26, 12, 10))
        I.detail("ellipse", ex, hy - 0.5, 2.6, 1.9, color=dc("#ffd23a") if dim < 0.5 else (90, 80, 70))
        I.detail("ellipse", ex - sx * 0.6, hy - 0.8, 0.8, 0.8, color=(255, 255, 230) if dim < 0.5 else (90, 80, 70))
    st = p.get("steam", 0.0)
    if st > 0:
        for sx in (-1, 1):
            for k in range(2):
                I.ellipse(cx + sx * (9 + k * 5 + st * 4), hy + 15 + k * 2, 3.2 + k, 2.6 + k, (238, 238, 238), flat=True, edge=0)
    arms(False)
    if sl < 100:
        draw_sword(-1, sl)
    if sr < 100:
        draw_sword(1, sr)
    return I.pixels()


def build_touro():
    P = touro
    idle = [P({"bob": [0, 0, 1, 1][i], "sl": 22, "sr": 22, "steam": [0, 0.6, 1.0, 0][i]}) for i in range(4)]
    walk = [P({"bob": [0, -2, 0, -2][i], "step": [1, 0, -1, 0][i], "sl": 22 + [3, 0, -3, 0][i], "sr": 22 - [3, 0, -3, 0][i]}) for i in range(4)]
    charge = [P({"charge": 1.0, "sl": -30, "sr": -30, "lean": 0, "bob": [0, -1, 0, -1][i], "step": [1, 0, -1, 0][i], "steam": 1.0}) for i in range(4)]
    attack = [P({"sl": 60, "sr": 60, "bob": -1}), P({"sl": 120, "sr": 120, "bob": -3}), P({"sl": 150, "sr": 150, "bob": -4, "steam": 1}),
              P({"sl": -10, "sr": -10, "bob": 2, "lean": 0}), P({"sl": 10, "sr": 10, "bob": 1})]
    stomp = [P({"step": 1, "bob": -4, "sl": 30, "sr": 30}), P({"step": 1, "bob": -6, "sl": 40, "sr": 40}), P({"step": 0, "bob": 2, "sl": 15, "sr": 15, "steam": 1}),
             P({"bob": 0, "sl": 22, "sr": 22})]
    hurt = [tint_px(P({"sl": 30, "sr": 30, "lean": -3})), P({"sl": 25, "sr": 25, "lean": -1})]
    die = [P({"dim": 0.2, "sl": 40, "sr": 40}), P({"dim": 0.45, "bob": 4, "sl": 70, "sr": 70, "charge": 0.5}),
           P({"dim": 0.7, "bob": 8, "sl": 100, "sr": 100, "charge": 0.9}), fade_px(P({"dim": 0.9, "bob": 10, "sl": 110, "sr": 110, "charge": 1}), 0.6),
           fade_px(P({"dim": 1.0, "bob": 12, "sl": 115, "sr": 115, "charge": 1}), 0.3)]
    write_sheet("espadashi_touro", 144, (72, 137), {"idle": (idle, 5, True), "walk": (walk, 6, True), "charge": (charge, 12, True),
                                                  "attack": (attack, 10, False), "stomp": (stomp, 8, False), "hurt": (hurt, 10, False),
                                                  "die": (die, 6, False)}, k=24, source="desenhado no estilo do jogo (sem arte da equipe ainda)")


# =================================================================== ONIGUERREIRO
def onigiri(p):
    """Onigiri warrior. p: bob, step, sword (angle), squash, band colour."""
    C = 48
    I = Illu(C, C, S=8)
    cx = 24 + p.get("lean", 0)
    by = p.get("bob", 0)
    sq = p.get("squash", 1.0)
    step = p.get("step", 0)
    foot = 45
    band = p.get("band", "#d8202a")
    # legs
    for sx, st in ((-1, step), (1, -step)):
        I.line([(cx + sx * 4, 37 + by), (cx + sx * 5, foot - 2 - max(0, st) * 2)], (60, 40, 30), width=2.6)
    top = 6 + by + (1 - sq) * 24
    # rice triangle (rounded)
    w = 15 * (2 - sq)
    tri = [(cx, top), (cx + w * 0.55, top + 8), (cx + w, 38 + by), (cx + w * 0.7, 40 + by), (cx - w * 0.7, 40 + by), (cx - w, 38 + by), (cx - w * 0.55, top + 8)]
    I.poly(tri, "#f4f1e6", bands=3)
    for k in range(9):                    # rice grains
        gx = cx + ((k * 37) % 17 - 8) * 0.9 * (2 - sq)
        gy = top + 8 + ((k * 23) % 19) * 1.2
        I.detail("ellipse", gx, gy, 0.9, 0.6, color=(220, 214, 196))
    # nori belt
    I.poly([(cx - w * 0.85, 30 + by), (cx + w * 0.85, 30 + by), (cx + w * 0.95, 40 + by), (cx - w * 0.95, 40 + by)], "#1e3326", shade=0.6)
    I.detail("line", [(cx - w * 0.8, 33 + by), (cx + w * 0.8, 33 + by)], color=(58, 92, 64), width=0.6)
    # umeboshi badge
    I.ellipse(cx, 35 + by, 2.2, 2.2, "#d8304a")
    # hachimaki
    I.poly([(cx - w * 0.5, top + 7), (cx + w * 0.5, top + 7), (cx + w * 0.58, top + 10), (cx - w * 0.58, top + 10)], band, shade=0.8)
    I.line([(cx + w * 0.55, top + 8.5), (cx + w * 0.9, top + 6), (cx + w * 1.05, top + 8)], band, width=1.3, shade=0.8)
    # angry eyes
    for sx in (-1, 1):
        ex = cx + sx * 4
        I.detail("line", [(ex - 2 * sx, top + 14.2), (ex + 2 * sx, top + 12.2)], color=(30, 16, 14), width=1.1)
        I.detail("ellipse", ex, top + 16, 1.3, 1.5, color=(30, 16, 14))
    I.detail("line", [(cx - 2, top + 20), (cx + 2, top + 20)], color=(30, 16, 14), width=0.8)
    # katana
    sa = p.get("sword", 20)
    hand = (cx + w * 0.95, 30 + by)
    a = math.radians(-90 + sa)
    tip = (hand[0] + math.cos(a) * 15, hand[1] + math.sin(a) * 15)
    I.line([hand, tip], (214, 220, 232), width=1.6, shade=1.2)
    I.line([(hand[0] - math.cos(a) * 4, hand[1] - math.sin(a) * 4), hand], (120, 40, 30), width=1.8)
    I.ellipse(hand[0], hand[1], 1.8, 1.8, "#f4f1e6")
    return I.pixels()


def build_onigiri():
    for cid, band in (("oniguerreiro", "#d8202a"),):
        P = lambda q: onigiri(dict(q, band=band))
        idle = [P({"bob": [0, 0, 1, 1][i], "sword": 25}) for i in range(4)]
        walk = [P({"bob": [0, -1, 0, -1][i], "step": [1, 0, -1, 0][i], "sword": 25 + [4, 0, -4, 0][i]}) for i in range(4)]
        attack = [P({"sword": -40, "bob": -1}), P({"sword": -70, "bob": -2, "squash": 1.05}), P({"sword": 110, "lean": 2, "squash": 0.9}), P({"sword": 60})]
        hurt = [tint_px(P({"sword": 30, "lean": -1})), P({"sword": 30})]
        die = [P({"squash": 0.85, "sword": 80}), fade_px(P({"squash": 0.65, "sword": 100}), 0.8), fade_px(P({"squash": 0.45, "sword": 110}), 0.5),
               fade_px(P({"squash": 0.3, "sword": 120}), 0.2)]
        write_sheet(cid, 48, (24, 45), {"idle": (idle, 5, True), "walk": (walk, 9, True), "attack": (attack, 10, False),
                                         "hurt": (hurt, 12, False), "die": (die, 8, False)}, k=16,
                    source="desenhado no estilo do jogo (inimigos da arena)")


# =================================================================== TOQUINHO (team art)
def build_toquinho():
    from build_from_refs import best_offset, pixelate, drop_specks, kmeans_palette, apply_palette
    from build_enemies import cell_from
    a = np.array(Image.open(os.path.join(SRC, "enemy_stump.png")).convert("RGBA"))
    al = np.where(a[:, :, 3] > 128, 255, 0).astype(np.uint8)
    ys, xs = np.where(al > 0)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    rgb = a[y0:y1, x0:x1, :3]
    sub = al[y0:y1, x0:x1]
    s = (y1 - y0) / 34.0
    ox, oy = best_offset(rgb, sub, s)
    g = drop_specks(pixelate(rgb, sub, s, ox, oy))
    g = apply_palette(g, kmeans_palette(g[:, :, :3][g[:, :, 3] > 0], 16))
    C, F = 48, (24, 45)
    W = SheetWriter(GEN, "toquinho", C, C, origin=F)
    W.add("idle", [cell_from(g, C, F), cell_from(g, C, F, 1.03, 0.97), cell_from(g, C, F, 1.05, 0.95), cell_from(g, C, F, 1.02, 0.98)], fps=5)
    W.add("walk", [cell_from(g, C, F, rot=r, dy=-abs(r) // 3) for r in (0, 6, 0, -6)], fps=8)
    W.add("attack", [cell_from(g, C, F, 0.92, 1.08, dy=-2), cell_from(g, C, F, 0.85, 1.15, dy=-6), cell_from(g, C, F, 1.2, 0.82, dx=2),
                     cell_from(g, C, F, 1.1, 0.9), cell_from(g, C, F)], fps=10, loop=False)
    W.add("hurt", [cell_from(g, C, F, tint=(255, 255, 255, 0.8)), cell_from(g, C, F, 1.05, 0.95)], fps=12, loop=False)
    W.add("die", [cell_from(g, C, F, 1.1, 0.85), cell_from(g, C, F, 1.2, 0.55, alpha=0.8), cell_from(g, C, F, 1.3, 0.3, alpha=0.5),
                  cell_from(g, C, F, 1.3, 0.12, alpha=0.2)], fps=8, loop=False)
    W.meta["generated"] = False
    W.meta["source"] = "equipe (Criaturinha Tronco com Flor), animações derivadas"
    W.close()
    print("toquinho", g.shape[:2])


# =================================================================== TRONQUINHO attack (no loose spit blobs)
def build_tronquinho_attack():
    from build_enemies import cell_from
    d = json.load(open(os.path.join(GEN, "tronquinho", "anims.json")))
    cw, ch = d["cell_w"], d["cell_h"]
    # drop empty cells left by the strip splitter (idle had a blank first frame)
    for name, info in d["animations"].items():
        sh = np.array(Image.open(os.path.join(GEN, "tronquinho", info["file"])).convert("RGBA"))
        cells = [sh[:, i * cw:(i + 1) * cw] for i in range(sh.shape[1] // cw)]
        keep = [c for c in cells if (c[:, :, 3] > 0).sum() > 40]
        if len(keep) != len(cells) and keep:
            Image.fromarray(np.concatenate(keep, axis=1)).save(os.path.join(GEN, "tronquinho", info["file"]))
            info["frames"] = len(keep)
            print("tronquinho", name, len(cells), "->", len(keep))
    idle = np.array(Image.open(os.path.join(GEN, "tronquinho", d["animations"]["idle"]["file"])).convert("RGBA"))
    f0 = idle[:, :cw]
    ys, xs = np.where(f0[:, :, 3] > 0)
    body = f0[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    F = tuple(d["origin"])
    frames = [cell_from(body, cw, F, 0.95, 1.05, dy=-1), cell_from(body, cw, F, 0.9, 1.1, dy=-2, rot=-6),
              cell_from(body, cw, F, 1.15, 0.88, rot=8), cell_from(body, cw, F, 1.05, 0.95), cell_from(body, cw, F)]
    from rig import sheet
    sheet(frames, cw, ch).save(os.path.join(GEN, "tronquinho", "attack.png"))
    d["animations"]["attack"] = {"file": "attack.png", "frames": len(frames), "fps": 10, "loop": False}
    d["animations"]["walk"] = dict(d["animations"]["walk_down"])      # generic walk for the Enemy logic
    json.dump(d, open(os.path.join(GEN, "tronquinho", "anims.json"), "w"), indent=2)
    print("tronquinho attack fixed")


# =================================================================== GROUND TEXTURES
def _tex(name, base, specks, seed, kind="noise"):
    rng = np.random.default_rng(seed)
    for v in range(4):
        img = np.zeros((32, 32, 4), np.uint8)
        b = hexc(base)
        n = rng.normal(0, 1, (32, 32))
        from scipy import ndimage
        n = ndimage.gaussian_filter(n, 1.4)
        n = (n - n.min()) / (n.max() - n.min() + 1e-6)
        q = np.floor(n * 3) / 3
        col = b[None, None, :] * (0.88 + 0.16 * q[:, :, None])
        if kind == "tiles":           # terracotta tiles with grout
            for y in range(32):
                for x in range(32):
                    off = 8 if (y // 8) % 2 else 0
                    if y % 8 == 0 or (x + off) % 16 == 0:
                        col[y, x] = b * 0.66
                    elif y % 8 == 1:
                        col[y, x] = np.minimum(255, b * 1.1)
        elif kind == "slab":          # big stone slabs
            for y in range(32):
                for x in range(32):
                    if y % 16 == 0 or (x + (8 if (y // 16) % 2 else 0)) % 16 == 0:
                        col[y, x] = b * 0.7
        elif kind == "sauce":         # glossy chili sauce
            col = b[None, None, :] * (0.8 + 0.3 * n[:, :, None])
            for _ in range(5):
                x, y = rng.integers(2, 30, 2)
                col[y, x:x + 3] = np.minimum(255, b * 1.5)
        for _ in range(specks[1]):
            x, y = rng.integers(0, 32, 2)
            col[y, x] = hexc(specks[0])
        img[:, :, :3] = np.clip(col, 0, 255).astype(np.uint8)
        img[:, :, 3] = 255
        Image.fromarray(img).save(os.path.join(GROUND, f"{name}_{v}.png"))
    print("ground", name)


def build_ground():
    _tex("spice_sand", "#d8a25e", ("#b07a3a", 14), 1)
    _tex("spice_tile", "#c2643a", ("#e08a5a", 4), 2, "tiles")
    _tex("spice_brick", "#b08a62", ("#8a6a48", 6), 3, "slab")
    _tex("spice_sauce", "#b8261c", ("#ff6a3a", 6), 4, "sauce")
    _tex("spice_grass", "#a2a84a", ("#c8c86a", 10), 5)
    _tex("arena_sand", "#d6c08e", ("#b8a070", 16), 6)
    _tex("arena_stone", "#9a948a", ("#7a756c", 8), 7, "slab")
    _tex("arena_slab", "#b8aa90", ("#8e826a", 6), 8, "tiles")
    _tex("arena_grass", "#7ca04a", ("#9cc06a", 10), 9)
    _tex("forest_path", "#6e6448", ("#4a7a4a", 12), 10)


# =================================================================== PROPS
def _prop_canvas(w, h, draw, S=6):
    I = Illu(w, h, S=S)
    draw(I, w, h)
    return I.pixels()


def build_props():
    db_path = os.path.join(PROPS, "props.json")
    db = json.load(open(db_path))
    os.makedirs(os.path.join(PROPS, "final"), exist_ok=True)

    def save(name, px, solid=True, fp=None):
        Image.fromarray(px).save(os.path.join(PROPS, "final", name + ".png"))
        h, w = px.shape[:2]
        db[name] = {"file": f"final/{name}.png", "w": int(w), "h": int(h), "solid": solid,
                    "fp": fp if fp else [max(8, int(w * 0.7)), max(6, int(h * 0.22))]}

    # spice jars (three colours)
    for nm, col, lid in (("spice_jar_red", "#c8302a", "#e8b030"), ("spice_jar_yellow", "#e8b020", "#c8302a"), ("spice_jar_green", "#4a9a3a", "#e8b030")):
        def jar(I, w, h, col=col, lid=lid):
            I.ellipse(w / 2, h - 10, 9, 9, "#c88a52")
            I.poly([(w / 2 - 8, h - 14), (w / 2 + 8, h - 14), (w / 2 + 6, h - 22), (w / 2 - 6, h - 22)], "#c88a52")
            I.ellipse(w / 2, h - 10, 6.5, 5, col)
            I.ellipse(w / 2, h - 23, 6, 2.5, lid)
            I.detail("ellipse", w / 2 - 3, h - 13, 1.5, 2.5, color=(255, 240, 210))
        save(nm, _prop_canvas(24, 30, jar), fp=[16, 8])
    # spice sacks
    def sack(I, w, h):
        I.poly([(4, h - 2), (w - 4, h - 2), (w - 6, 10), (w / 2 + 3, 6), (w / 2 - 3, 6), (6, 10)], "#c8a06a")
        I.ellipse(w / 2, 11, 7, 3, "#e05a1a")
        I.detail("line", [(w / 2 - 4, 8), (w / 2 + 4, 8)], color=(120, 80, 40), width=1)
    save("spice_sack", _prop_canvas(22, 26, sack), fp=[16, 8])
    # great mortar (puzzle)
    def mortar(I, w, h):
        I.ellipse(w / 2, h - 10, 22, 9, "#7a6a5a")
        I.poly([(w / 2 - 20, h - 14), (w / 2 + 20, h - 14), (w / 2 + 16, h - 34), (w / 2 - 16, h - 34)], "#9a8a76")
        I.ellipse(w / 2, h - 34, 17, 6, "#6a5a4a")
        I.ellipse(w / 2, h - 34, 13, 4, "#3a2a20")
        I.line([(w / 2 + 6, h - 36), (w / 2 + 16, h - 52)], "#c8a878", width=5)
        I.ellipse(w / 2 + 16, h - 53, 4, 4, "#c8a878")
    save("great_mortar", _prop_canvas(52, 60, mortar), fp=[40, 14])
    # brazier
    def brazier(I, w, h):
        I.line([(w / 2 - 6, h - 2), (w / 2 - 3, h - 14)], "#4a3a2a", width=2)
        I.line([(w / 2 + 6, h - 2), (w / 2 + 3, h - 14)], "#4a3a2a", width=2)
        I.ellipse(w / 2, h - 16, 9, 4, "#8a5a2a")
        I.poly([(w / 2 - 7, h - 17), (w / 2 - 3, h - 30), (w / 2, h - 24), (w / 2 + 3, h - 33), (w / 2 + 7, h - 17)], "#ff8a1c", glow=0.6)
        I.poly([(w / 2 - 3, h - 18), (w / 2, h - 27), (w / 2 + 3, h - 18)], "#ffe066", flat=True)
    save("brazier", _prop_canvas(22, 36, brazier), fp=[12, 6])
    # chili-red palace tower and market stall
    def stall(I, w, h):
        I.poly([(4, h - 2), (w - 4, h - 2), (w - 4, h - 20), (4, h - 20)], "#8a5a34")
        I.poly([(0, h - 20), (w, h - 20), (w - 4, h - 34), (4, h - 34)], "#d8442a")
        for k in range(5):
            x = 4 + k * (w - 8) / 5
            I.detail("poly", [(x, h - 34), (x + (w - 8) / 10, h - 34), (x + (w - 8) / 10 + 1, h - 20), (x + 1, h - 20)], color=(250, 230, 200))
        for k, c in enumerate(("#e8b020", "#c8302a", "#4a9a3a", "#e05a1a")):
            I.ellipse(10 + k * (w - 20) / 3, h - 16, 4, 3, c)
        I.line([(5, h - 20), (5, h - 2)], "#5a3a20", width=2)
        I.line([(w - 5, h - 20), (w - 5, h - 2)], "#5a3a20", width=2)
    save("spice_stall", _prop_canvas(52, 44, stall), fp=[48, 10])
    def pepper_plant(I, w, h):
        I.ellipse(w / 2, h - 6, 8, 5, "#8a5a34")
        for k in range(6):
            a = -150 + k * 24
            x = w / 2 + math.cos(math.radians(a)) * 9
            y = h - 12 + math.sin(math.radians(a)) * 9
            I.ellipse(x, y, 4, 2.5, "#4a8a32")
        for k in range(4):
            I.poly([(w / 2 - 7 + k * 5, h - 15), (w / 2 - 5 + k * 5, h - 15), (w / 2 - 6 + k * 5, h - 9)], "#d82a20")
    save("pepper_plant", _prop_canvas(24, 26, pepper_plant), fp=[14, 6])
    def palace_gate(I, w, h):
        for sx in (8, w - 8):
            I.poly([(sx - 7, h - 2), (sx + 7, h - 2), (sx + 6, 18), (sx - 6, 18)], "#c84a2a")
            I.poly([(sx - 9, 22), (sx + 9, 22), (sx, 4)], "#e8b030")
        I.poly([(8, 26), (w - 8, 26), (w - 8, 34), (8, 34)], "#a8302a")
        I.ellipse(w / 2, 30, 8, 8, "#ffc12e", glow=0.4)
        for k in range(10):
            a = math.radians(k * 36)
            I.detail("line", [(w / 2 + math.cos(a) * 8, 30 + math.sin(a) * 8), (w / 2 + math.cos(a) * 12, 30 + math.sin(a) * 12)], color=(255, 160, 40), width=1.4)
    save("palace_gate", _prop_canvas(80, 76, palace_gate), solid=False)
    # arena: stone pillar, banner pole, spectator stand piece, gong
    def pillar(I, w, h):
        I.poly([(w / 2 - 8, h - 2), (w / 2 + 8, h - 2), (w / 2 + 7, 8), (w / 2 - 7, 8)], "#a89e8e")
        I.poly([(w / 2 - 10, 10), (w / 2 + 10, 10), (w / 2 + 9, 4), (w / 2 - 9, 4)], "#c8bca8")
        I.poly([(w / 2 - 10, h - 6), (w / 2 + 10, h - 6), (w / 2 + 10, h - 1), (w / 2 - 10, h - 1)], "#8a8072")
        for k in range(3):
            I.detail("line", [(w / 2 - 4 + k * 4, 12), (w / 2 - 4 + k * 4, h - 8)], color=(130, 122, 108), width=0.8)
    save("arena_pillar", _prop_canvas(24, 64, pillar), fp=[18, 8])
    def banner(I, w, h):
        I.line([(w / 2, h - 2), (w / 2, 4)], "#5a3a20", width=2.5)
        I.poly([(w / 2 + 1, 6), (w - 2, 6), (w - 2, 34), (w / 2 + 1 + (w / 2 - 3) / 2, 28), (w / 2 + 1, 34)], "#b0242c")
        I.ellipse(w / 2 + 1 + (w / 2 - 3) / 2, 16, 4, 4, "#e8b838")
    save("arena_banner", _prop_canvas(28, 56, banner), fp=[6, 4])
    def gong(I, w, h):
        for sx in (4, w - 4):
            I.line([(sx, h - 2), (sx, 6)], "#6a3a1e", width=3)
        I.line([(2, 7), (w - 2, 7)], "#6a3a1e", width=3)
        I.ellipse(w / 2, h / 2 + 2, 11, 11, "#d8a030")
        I.ellipse(w / 2, h / 2 + 2, 5, 5, "#b8801a")
    save("arena_gong", _prop_canvas(32, 40, gong), fp=[26, 6])
    def stands(I, w, h):
        for k in range(4):
            y = h - 6 - k * 8
            I.poly([(0, y), (w, y), (w, y - 8), (0, y - 8)], "#8a8274" if k % 2 == 0 else "#a29a8a")
        for k in range(9):        # tiny cheering spectators (piglets / spirits)
            x = 5 + k * (w - 10) / 8
            y = h - 14 - (k % 4) * 8
            I.ellipse(x, y - 3, 3, 3, ("#f2a6b8", "#e8e0d0", "#c8a06a")[k % 3])
    save("arena_stands", _prop_canvas(96, 44, stands), fp=[96, 30])
    json.dump(db, open(db_path, "w"), indent=1)
    print("props", len(db))


def build_icons():
    out = os.path.join(GEN, "icons")
    def seed(I, w, h):
        I.ellipse(16, 18, 7, 9, "#e8c040", glow=0.3)
        I.ellipse(14, 15, 3, 4, "#fff2a8", flat=True)
        I.poly([(16, 9), (19, 4), (22, 6), (18, 10)], "#4a9a3a")
    def pot(I, w, h):
        I.ellipse(16, 20, 10, 9, "#c88a52")
        I.poly([(8, 16), (24, 16), (22, 9), (10, 9)], "#c88a52")
        I.ellipse(16, 9, 7, 2.5, "#e8b030")
        I.ellipse(16, 20, 6, 4.5, "#d8301e")
        I.detail("ellipse", 12, 17, 1.5, 2.5, color=(255, 240, 210))
    for name, fn in (("semente_luz", seed), ("pote_tempero", pot)):
        Image.fromarray(_prop_canvas(32, 32, fn, S=8)).save(os.path.join(out, name + ".png"))
    print("icons ok")


if __name__ == "__main__":
    want = sys.argv[1:] or ["rei_quente", "touro", "onigiri", "toquinho", "tronquinho", "ground", "props"]
    if "rei_quente" in want:
        build_rei_quente()
    if "touro" in want:
        build_touro()
    if "onigiri" in want:
        build_onigiri()
    if "toquinho" in want:
        build_toquinho()
    if "tronquinho" in want:
        build_tronquinho_attack()
    if "ground" in want:
        build_ground()
    if "props" in want:
        build_props()
    if "icons" in want:
        build_icons()
