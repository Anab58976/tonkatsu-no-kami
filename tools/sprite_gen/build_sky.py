"""Reino dos Céus art.

Ground tiles are recoloured from the seamless tiles already derived from the
artist's day tileset (same pixel texture, celestial palette):
  sky_grass  <- grass  (fresh mint meadow)
  sky_marble <- stone  (white marble)
  sky_gold   <- path   (golden cobbles)
  sky_cloud  <- procedural cloud-floor puffs (for DIRT tiles)
Enemies (rig, in the team's style: dark outline, chunky shading):
  passaro_eletrico, espirito_tempestade, guerreiro_nuvens, harpia,
  sentinela_celeste, dragao_vento (mini-boss)
Objects: wind bell, sky crystal (off/on), cloud ferry, lotus elevator,
feather item icon.
"""
from __future__ import annotations

import colorsys
import math
import os

import numpy as np
from PIL import Image

from rig import Canvas, SheetWriter, shade
from build_enemies import _fade, H, INK

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GROUND = os.path.join(ROOT, "assets", "sprites", "tiles", "ground")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
PROPS = os.path.join(ROOT, "assets", "sprites", "props")
ICONS = os.path.join(GEN, "icons")


# ------------------------------------------------------------------ tiles
def recolor(src, dst, fn):
    for v in range(4):
        a = np.array(Image.open(os.path.join(GROUND, f"{src}_{v}.png")).convert("RGBA")).astype(np.float32) / 255.0
        out = a.copy()
        h, w = a.shape[:2]
        for y in range(h):
            for x in range(w):
                r, g, b = a[y, x, :3]
                hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
                out[y, x, :3] = fn(hh, ll, ss)
        Image.fromarray((out.clip(0, 1) * 255).astype(np.uint8)).save(os.path.join(GROUND, f"{dst}_{v}.png"))


def _hls(h, l, s):
    return colorsys.hls_to_rgb(h % 1.0, min(1.0, max(0.0, l)), min(1.0, max(0.0, s)))


def sky_tiles():
    # meadow: shift toward mint/teal, lighter, a bit less saturated
    recolor("grass", "sky_grass", lambda h, l, s: _hls(h + 0.13, 0.26 + l * 0.8, s * 0.55))
    # marble: nearly white with cool shadows
    recolor("stone", "sky_marble", lambda h, l, s: _hls(0.6, 0.55 + l * 0.42, 0.18 * s + 0.05))
    # golden cobbles
    recolor("path", "sky_gold", lambda h, l, s: _hls(0.12, 0.25 + l * 0.75, 0.55 + s * 0.3))
    # cloud floor: soft puffs on a pale blue base
    rng = np.random.default_rng(11)
    for v in range(4):
        c = Canvas(32, 32)
        c.rect(0, 0, 31, 31, H("dfeaf6"))
        for _ in range(9):
            x, y = rng.integers(0, 32), rng.integers(0, 32)
            r = int(rng.integers(4, 9))
            for dx in (-32, 0, 32):           # wrap horizontally/vertically -> seamless
                for dy in (-32, 0, 32):
                    c.ellipse(x + dx, y + dy + 1, r, r - 1, H("c6d6ec"))
                    c.ellipse(x + dx, y + dy, r - 1, r - 2, H("f4f8fd"))
                    c.ellipse(x + dx - 1, y + dy - 1, max(1, r - 4), max(1, r - 5), H("ffffff"))
        c.img.save(os.path.join(GROUND, f"sky_cloud_{v}.png"))


# ------------------------------------------------------------------ enemies
def bird(phase=0, attack=0, hurt=False):
    """Pássaro elétrico: round yellow bird crackling with sparks."""
    c = Canvas(40, 40)
    y = 18 + [0, -2, -3, -1][phase % 4]
    flap = phase % 2
    yel, yd, yl = H("f2c933"), H("c08a1a"), H("fff09a")
    for s in (-1, 1):
        if flap:
            c.poly([(20 + s * 4, y - 2), (20 + s * 15, y - 10), (20 + s * 12, y + 1)], yd)
        else:
            c.poly([(20 + s * 4, y), (20 + s * 15, y + 4), (20 + s * 10, y + 6)], yd)
    c.ellipse(20, y, 8, 7, yd); c.ellipse(20, y - 1, 7, 6, yel); c.ellipse(18, y - 3, 3, 2, yl)
    c.poly([(27, y - 1), (31 + attack * 2, y + 1), (27, y + 2)], H("e8862a"))   # beak
    c.rect(23, y - 3, 24, y - 2, INK); c.px(24, y - 3, (255, 255, 255, 255))
    c.poly([(17, y - 7), (20, y - 12), (21, y - 7)], yd)                        # crest bolt
    c.poly([(19, y - 9), (23, y - 13), (22, y - 8)], yel)
    c.outline(color=INK, selective=False)
    # sparks (outside the outline, bright)
    for k in range(2 + attack * 2):
        a = (phase * 1.7 + k * 2.1)
        sx, sy = 20 + int(math.cos(a) * 12), y + int(math.sin(a) * 9)
        c.px(sx, sy, H("bff4ff")); c.px(sx + 1, sy, H("ffffff"))
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def storm_spirit(phase=0, attack=0, hurt=False):
    """Espírito da tempestade: dark cloud with glowing eyes and a bolt core."""
    c = Canvas(48, 48)
    y = 26 + [0, -1, -2, -1][phase % 4]
    dk, md, lt = H("4a4f6e"), H("6b7194"), H("9097b8")
    for (dx, dy, r) in ((-9, 2, 7), (9, 2, 7), (-4, -4, 8), (5, -5, 8), (0, 3, 9)):
        c.ellipse(24 + dx, y + dy, r, r - 1, dk)
    for (dx, dy, r) in ((-9, 1, 6), (9, 1, 6), (-4, -5, 7), (5, -6, 7), (0, 2, 8)):
        c.ellipse(24 + dx, y + dy, r - 1, r - 2, md)
    c.ellipse(20, y - 8, 4, 2, lt)
    eye = H("fff36b") if attack == 0 else H("ffffff")
    c.rect(19, y - 1, 21, y + 1, eye); c.rect(27, y - 1, 29, y + 1, eye)
    # rain streaks underneath
    for k in range(5):
        x = 16 + k * 4
        c.line(x, y + 9 + (phase + k) % 3, x - 1, y + 13 + (phase + k) % 3, H("8fb4e8"))
    c.outline(color=INK, selective=False)
    if attack:
        c.poly([(24, y + 6), (20, y + 16), (24, y + 15), (21, y + 24), (29, y + 12), (25, y + 13), (27, y + 6)], H("fff6a8"))
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def cloud_warrior(phase=0, attack=0, hurt=False):
    """Guerreiro das nuvens: white-armoured ashigaru on a cloud, naginata."""
    c = Canvas(48, 48)
    by = 36 + [0, -1, 0, -1][phase % 4]
    wh, whd, bl, gd = H("eef2f8"), H("b8c4d8"), H("4a6fb0"), H("e2b33c")
    c.ellipse(24, by + 6, 12, 4, whd); c.ellipse(24, by + 5, 11, 3, wh)          # cloud base
    c.rect(18, by - 14, 30, by + 2, bl); c.rect(18, by - 14, 30, by - 12, H("6a8fd0"))
    for k in range(3):
        c.rect(18, by - 9 + k * 4, 30, by - 8 + k * 4, whd)                       # lamellar plates
    c.ellipse(24, by - 19, 6, 6, H("f0d0b0"))                                    # face
    c.poly([(16, by - 21), (24, by - 29), (32, by - 21)], wh)                    # kabuto
    c.rect(16, by - 22, 32, by - 20, whd)
    c.poly([(21, by - 27), (24, by - 33), (27, by - 27)], gd)                    # crest
    c.rect(21, by - 19, 22, by - 18, INK); c.rect(26, by - 19, 27, by - 18, INK)
    # naginata
    tip_x = 37 + attack * 5
    tip_y = by - 24 + attack * 10
    c.line(tip_x - 10, by + 6, tip_x, tip_y, H("8a5a2a"))
    c.poly([(tip_x, tip_y), (tip_x + 3, tip_y - 7 + attack * 3), (tip_x + 2, tip_y + 1)], H("e8eef8"))
    c.ellipse(32, by - 8, 3, 3, wh)
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def harpy(phase=0, attack=0, hurt=False):
    """Harpia: tengu-like bird woman with grey-violet wings and talons."""
    c = Canvas(48, 48)
    y = 22 + [0, -2, -3, -1][phase % 4]
    wing, wingd = H("7a6c9a"), H("564a74")
    up = phase % 2 == 0
    for s in (-1, 1):
        pts = [(24 + s * 4, y - 2), (24 + s * 20, y - (12 if up else 0)), (24 + s * 18, y + (0 if up else 8)), (24 + s * 8, y + 4)]
        c.poly(pts, wingd)
        c.poly([(24 + s * 5, y - 1), (24 + s * 17, y - (9 if up else 1)), (24 + s * 9, y + 3)], wing)
    c.ellipse(24, y + 3, 6, 8, H("c8b6d8")); c.ellipse(24, y + 4, 4, 6, H("e8dcf0"))
    c.ellipse(24, y - 8, 5, 5, H("f0c8a8"))
    c.rect(19, y - 14, 29, y - 11, H("2a2030"))                                 # hair
    c.poly([(24, y - 7), (27 + attack, y - 5), (24, y - 4)], H("e8862a"))        # beak-nose
    c.px(22, y - 9, INK); c.px(26, y - 9, INK)
    talon = 4 + attack * 3
    for s in (-1, 1):
        c.line(24 + s * 2, y + 11, 24 + s * 3, y + 11 + talon, H("e2b33c"))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def sentinel(phase=0, attack=0, hurt=False):
    """Sentinela celestial: floating marble lantern-guardian with a single eye."""
    c = Canvas(48, 56)
    y = 40 + [0, -1, -1, 0][phase % 4]
    m, md, ml, gd = H("e8ecf2"), H("a8b0c4"), H("ffffff"), H("e2b33c")
    c.rect(16, y - 4, 32, y, md)                                                 # base
    c.rect(18, y - 22, 30, y - 4, m); c.rect(18, y - 22, 19, y - 4, ml); c.rect(29, y - 22, 30, y - 4, md)
    c.poly([(13, y - 22), (24, y - 31), (35, y - 22)], md); c.poly([(15, y - 23), (24, y - 30), (33, y - 23)], m)
    c.rect(22, y - 35, 26, y - 31, gd)
    eye_col = H("8fe3ff") if attack == 0 else H("ffffff")
    c.ellipse(24, y - 14, 4, 4, H("2a3a5a")); c.ellipse(24, y - 14, 2 + attack, 2 + attack, eye_col)
    for s in (-1, 1):
        c.rect(24 + s * 9, y - 18, 24 + s * 10, y - 8, gd)
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def wind_dragon(phase=0, attack=0, hurt=False):
    """Dragão de vento: jade-white serpent dragon coiled in the air (mini-boss)."""
    c = Canvas(96, 96)
    body, bodyd, belly, mane = H("8fd8c0"), H("4f9a88"), H("f0f4e0"), H("f4f8ff")
    t = phase * 0.6
    pts = []
    for i in range(22):
        k = i / 21.0
        x = 20 + k * 56
        y = 60 + math.sin(k * 6.0 + t) * 10 - k * 18
        pts.append((x, y))
    for i, (x, y) in enumerate(pts):
        r = 7 - i * 0.18
        c.ellipse(x, y + 1, r, r, bodyd)
    for i, (x, y) in enumerate(pts):
        r = 6 - i * 0.18
        c.ellipse(x, y, r, r - 1, body)
        if i % 2 == 0:
            c.ellipse(x, y + 2, max(1, r - 3), max(1, r - 4), belly)
    # head at the start of the body
    hx, hy = pts[0][0] - 4, pts[0][1] - 6 - attack * 3
    c.ellipse(hx, hy, 11, 8, bodyd); c.ellipse(hx, hy - 1, 10, 7, body)
    c.poly([(hx - 10, hy), (hx - 18 - attack * 3, hy + 2), (hx - 10, hy + 5)], body)     # snout
    if attack:
        c.poly([(hx - 10, hy + 3), (hx - 19, hy + 8), (hx - 10, hy + 6)], H("c03a3a"))
    c.rect(hx - 5, hy - 3, hx - 3, hy - 2, H("ffe35a")); c.px(hx - 3, hy - 3, INK)
    for s in (-1, 1):                                                                 # antlers
        c.line(hx + 2, hy - 6, hx + 6 + s * 2, hy - 15, H("e2b33c"))
        c.line(hx + 5 + s, hy - 11, hx + 9 + s * 3, hy - 13, H("e2b33c"))
    for i in range(0, 20, 3):                                                         # mane tufts
        x, y = pts[i]
        c.poly([(x - 2, y - 5), (x + 2 - 6, y - 12 - (i % 2) * 3), (x + 3, y - 5)], mane)
    tx, ty = pts[-1]
    c.poly([(tx, ty - 4), (tx + 12, ty - 10), (tx + 9, ty + 2)], mane)
    for s in (-1, 1):                                                                 # small claws
        x, y = pts[6]
        c.line(x + s * 3, y + 5, x + s * 6, y + 11, bodyd)
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_enemies():
    specs = [
        ("passaro_eletrico", bird, 40, (20, 36), (14, 16)),
        ("espirito_tempestade", storm_spirit, 48, (24, 44), (5, 8)),
        ("guerreiro_nuvens", cloud_warrior, 48, (24, 46), (5, 9)),
        ("harpia", harpy, 48, (24, 44), (8, 10)),
        ("sentinela_celeste", sentinel, (48, 56), (24, 52), (3, 6)),
        ("dragao_vento", wind_dragon, 96, (48, 88), (6, 8)),
    ]
    for cid, fn, cell, origin, (fps_idle, fps_walk) in specs:
        cw, ch = (cell, cell) if isinstance(cell, int) else cell
        W = SheetWriter(GEN, cid, cw, ch, origin=origin)
        W.add("idle", [fn(i) for i in range(4)], fps=fps_idle)
        W.add("walk", [fn(i) for i in range(4)], fps=fps_walk)
        W.add("attack", [fn(0, 0), fn(1, 1), fn(2, 1), fn(3, 0)], fps=10, loop=False)
        W.add("hurt", [fn(0, hurt=True), fn(1)], fps=12, loop=False)
        W.add("die", [_fade(fn(0), k, cid not in ("passaro_eletrico", "harpia")) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
        W.meta["generated"] = True
        W.close()


# ------------------------------------------------------------------ objects
def save_prop(name, c):
    c.img.save(os.path.join(PROPS, f"{name}.png"))


def objects():
    gd, gdd, wood, woodd = H("e2b33c"), H("a87a20"), H("8a5a2a"), H("5c3a1a")
    # wind bell on a small wooden frame (fūrin-style chime, large)
    for state in (0, 1):
        c = Canvas(28, 44)
        c.rect(3, 4, 5, 43, woodd); c.rect(22, 4, 24, 43, woodd); c.rect(1, 2, 26, 6, wood); c.rect(1, 2, 26, 3, H("b07a3a"))
        sw = 2 if state else 0
        c.line(14, 6, 14 + sw, 12, H("2a1a1a"))
        c.ellipse(14 + sw, 17, 6, 6, gd); c.rect(8 + sw, 17, 20 + sw, 23, gd); c.rect(8 + sw, 22, 20 + sw, 23, gdd)
        c.ellipse(12 + sw, 15, 2, 2, H("fff0a0"))
        c.rect(13 + sw * 2, 24, 15 + sw * 2, 31, H("f4f8ff")); c.rect(12 + sw * 2, 31, 16 + sw * 2, 34, H("8fd8ff"))   # wind strip
        c.outline(color=INK, selective=False)
        save_prop("sky_bell" + ("_ring" if state else ""), c)
    # sky crystal: off (pale) / on (bright)
    for state in (0, 1):
        c = Canvas(24, 40)
        base = H("8fa8d8") if state == 0 else H("8fe3ff")
        light = H("c8d6f0") if state == 0 else H("ffffff")
        dark = H("5a6f9a") if state == 0 else H("3fa8e8")
        c.rect(5, 33, 18, 38, H("c8ccd8")); c.rect(5, 33, 18, 34, H("eef0f6"))
        c.poly([(12, 2), (19, 14), (16, 32), (8, 32), (5, 14)], dark)
        c.poly([(12, 4), (17, 14), (14, 30), (9, 30), (7, 14)], base)
        c.poly([(12, 5), (14, 14), (11, 28), (9, 14)], light)
        c.outline(color=INK, selective=False)
        save_prop("sky_crystal" + ("_on" if state else ""), c)
    # cloud ferry (top-down platform, 3x2 tiles)
    c = Canvas(100, 60)
    for (x, y, r) in ((20, 34, 16), (48, 28, 22), (78, 34, 16), (34, 42, 15), (64, 42, 15)):
        c.ellipse(x, y + 2, r, r - 3, H("b8c8e2"))
    for (x, y, r) in ((20, 32, 15), (48, 26, 21), (78, 32, 15), (34, 40, 14), (64, 40, 14)):
        c.ellipse(x, y, r, r - 3, H("f4f8fd"))
    for (x, y, r) in ((40, 20, 8), (24, 27, 6), (60, 22, 6)):
        c.ellipse(x, y, r, r - 2, H("ffffff"))
    c.rect(30, 26, 68, 30, H("e2b33c")); c.rect(30, 26, 68, 26, H("fff0a0"))        # golden rim (standing deck)
    c.outline(color=H("8a9ab8"), selective=False)
    save_prop("sky_ferry", c)
    # lotus elevator
    c = Canvas(72, 44)
    for i in range(8):
        a = i / 8 * math.tau
        x, y = 36 + math.cos(a) * 22, 26 + math.sin(a) * 10
        c.ellipse(x, y, 10, 6, H("e99ab8"))
    for i in range(8):
        a = (i + 0.5) / 8 * math.tau
        x, y = 36 + math.cos(a) * 15, 24 + math.sin(a) * 7
        c.ellipse(x, y, 8, 5, H("f8c8d8"))
    c.ellipse(36, 24, 14, 6, H("f4e070")); c.ellipse(36, 23, 11, 4, H("fff0a0"))
    c.outline(color=H("8a3a5a"), selective=False)
    save_prop("sky_lotus", c)
    # celestial feather (quest item icon) + pedestal for the rice
    os.makedirs(ICONS, exist_ok=True)
    c = Canvas(20, 20)
    c.line(4, 17, 15, 3, H("a8b0c4"))
    c.poly([(6, 14), (13, 2), (17, 4), (10, 15)], H("f4f8ff")); c.poly([(8, 13), (14, 4), (16, 5), (10, 14)], H("8fe3ff"))
    c.outline(color=INK, selective=False)
    c.img.save(os.path.join(ICONS, "pena_celeste.png"))


def register_props():
    import json
    p = os.path.join(PROPS, "props.json")
    d = json.load(open(p))
    for name, kind, solid, fp in (("sky_bell", "object", True, [14, 6]), ("sky_bell_ring", "object", True, [14, 6]),
                                  ("sky_crystal", "object", True, [10, 6]), ("sky_crystal_on", "object", True, [10, 6]),
                                  ("sky_ferry", "decal", False, [0, 0]), ("sky_lotus", "decal", False, [0, 0])):
        im = Image.open(os.path.join(PROPS, name + ".png"))
        d[name] = {"file": name + ".png", "w": im.width, "h": im.height, "kind": kind, "solid": solid, "fp": fp}
    json.dump(d, open(p, "w"), indent=1)


if __name__ == "__main__":
    sky_tiles()
    build_enemies()
    objects()
    register_props()
    print("sky art ok")
