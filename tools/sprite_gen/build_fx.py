"""Cutscene FX art: transformation morph, ingredient icons, legendary plate,
title logo, emote bubbles and magic glyphs.

The transformation morph interpolates signed distance fields between the
artist's human Lulu silhouette and pig Lulu silhouette, so ears and snout grow
out of the shrinking human shape instead of a hard sprite swap.
"""
from __future__ import annotations

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

from rig import Canvas, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXT = os.path.join(ROOT, "assets", "sprites", "extracted")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
FX = os.path.join(GEN, "fx")
os.makedirs(FX, exist_ok=True)
OUT = (40, 20, 19, 255)


def place(arr, cell=64, foot=(32, 60)):
    out = np.zeros((cell, cell, 4), np.uint8)
    h, w = arr.shape[:2]
    x, y = foot[0] - w // 2, foot[1] - h
    out[y:y + h, x:x + w] = arr
    return out


def sdf(mask):
    inside = ndimage.distance_transform_edt(mask)
    outside = ndimage.distance_transform_edt(~mask)
    return outside - inside


def morph():
    human = place(np.array(Image.open(os.path.join(EXT, "lulu_human", "front.png")).convert("RGBA")))
    pig = place(np.array(Image.open(os.path.join(EXT, "lulu_pig", "turn_0.png")).convert("RGBA")))
    hm, pm = human[:, :, 3] > 0, pig[:, :, 3] > 0
    sh, sp = sdf(hm), sdf(pm)
    frames = []
    n = 10
    yy, xx = np.mgrid[0:64, 0:64]
    for i in range(n):
        t = i / (n - 1)
        t = t * t * (3 - 2 * t)              # smoothstep easing
        d = (1 - t) * sh + t * sp
        m = d < 0
        inner = -np.where(m, d, 0)
        img = np.zeros((64, 64, 4), np.uint8)
        # core glow: white-gold in the middle, gold to the edges
        k = np.clip(inner / 6.0, 0, 1)
        r = 250 + 5 * k
        g = 190 + 60 * k
        b = 70 + 160 * k
        img[m, 0] = r[m]; img[m, 1] = g[m]; img[m, 2] = b[m]; img[m, 3] = 255
        # a sweeping energy band
        band = np.abs(((yy + i * 4) % 14) - 7) < 1
        img[m & band, :3] = (255, 255, 240)
        # outline
        ring = ndimage.binary_dilation(m) & ~m
        img[ring] = (200, 120, 40, 255)
        frames.append(img)
    # first and last frames: real art fully tinted (silhouette still readable)
    def tint(a, amount):
        a = a.copy().astype(np.float32)
        msk = a[:, :, 3] > 0
        for c, v in enumerate((255, 230, 150)):
            a[:, :, c][msk] = a[:, :, c][msk] * (1 - amount) + v * amount
        return a.clip(0, 255).astype(np.uint8)
    seq = [tint(human, 0.35), tint(human, 0.7)] + frames + [tint(pig, 0.7), tint(pig, 0.35), pig]
    strip = Image.new("RGBA", (64 * len(seq), 64))
    for i, f in enumerate(seq):
        strip.alpha_composite(Image.fromarray(f), (64 * i, 0))
    os.makedirs(os.path.join(GEN, "lulu_transform"), exist_ok=True)
    strip.save(os.path.join(GEN, "lulu_transform", "morph.png"))
    meta = {"id": "lulu_transform", "cell_w": 64, "cell_h": 64, "origin": [32, 60], "generated": True,
            "animations": {"morph": {"file": "morph.png", "frames": len(seq), "fps": 6, "loop": False}}}
    json.dump(meta, open(os.path.join(GEN, "lulu_transform", "anims.json"), "w"), indent=2)


# ------------------------------------------------------------------ ingredients
def icon(name, fn):
    c = Canvas(20, 20)
    fn(c)
    c.outline(color=OUT, selective=False)
    c.img.save(os.path.join(FX, f"ing_{name}.png"))


def cabbage(c):
    g, gd, gl = (110, 176, 80, 255), (66, 120, 54, 255), (170, 220, 120, 255)
    c.ellipse(10, 11, 8, 7, gd); c.ellipse(10, 10, 7, 6, g)
    c.ellipse(7, 9, 3, 4, gl); c.ellipse(13, 9, 3, 4, (150, 206, 104, 255))
    c.line(10, 5, 10, 16, gd); c.line(6, 8, 9, 14, gd); c.line(14, 8, 11, 14, gd)
    c.px(16, 4, (210, 150, 255, 255)); c.px(3, 15, (210, 150, 255, 255)); c.px(15, 3, (240, 210, 255, 255))


def wheat(c):
    s, sl = (190, 210, 240, 255), (235, 245, 255, 255)
    c.line(10, 18, 10, 6, (150, 170, 210, 255))
    for i, y in enumerate(range(3, 14, 3)):
        c.ellipse(8, y + 1, 2, 2, s); c.ellipse(12, y + 2, 2, 2, s); c.px(8, y, sl)
    c.ellipse(10, 2, 1, 2, sl)
    c.px(3, 8, (160, 200, 255, 255)); c.px(16, 12, (160, 200, 255, 255))


def rice(c):
    c.ellipse(10, 9, 7, 4, (250, 250, 244, 255))
    for x, y in ((6, 8), (9, 7), (12, 8), (14, 9), (8, 10)):
        c.px(x, y, (255, 230, 120, 255))
    c.poly([(2, 10), (18, 10), (15, 17), (5, 17)], (90, 150, 210, 255))
    c.rect(4, 11, 16, 11, (140, 190, 240, 255))
    c.ellipse(4, 4, 2, 1, (240, 248, 255, 255)); c.ellipse(16, 3, 2, 1, (240, 248, 255, 255))


def meat(c):
    c.ellipse(10, 11, 8, 6, (200, 90, 100, 255)); c.ellipse(10, 10, 7, 5, (236, 140, 140, 255))
    c.ellipse(14, 9, 2, 3, (250, 230, 220, 255))           # fat cap
    c.line(5, 9, 10, 12, (210, 110, 120, 255))
    c.px(3, 3, (120, 230, 140, 255)); c.px(17, 5, (120, 230, 140, 255)); c.px(16, 16, (160, 255, 170, 255))


def pepper(c):
    for x, y in ((6, 12), (11, 13), (14, 9), (8, 8), (12, 6)):
        c.ellipse(x, y, 2, 2, (50, 44, 48, 255)); c.px(x - 1, y - 1, (110, 100, 108, 255))
    c.poly([(5, 4), (7, 1), (9, 3), (11, 0), (13, 3), (15, 1), (16, 4)], (240, 190, 60, 255))
    c.rect(5, 4, 16, 5, (200, 140, 40, 255)); c.px(11, 4, (225, 45, 65, 255))


def egg(c):
    c.ellipse(10, 11, 6, 8, (200, 140, 30, 255)); c.ellipse(10, 10, 5, 7, (250, 200, 60, 255))
    c.ellipse(8, 7, 2, 3, (255, 240, 160, 255)); c.px(7, 6, (255, 255, 255, 255))
    c.px(2, 4, (255, 240, 160, 255)); c.px(17, 6, (255, 240, 160, 255))


def plate():
    c = Canvas(48, 20)
    c.ellipse(24, 12, 22, 7, (200, 150, 50, 255))
    c.ellipse(24, 11, 20, 6, (250, 248, 240, 255))
    c.ellipse(24, 11, 15, 4, (236, 232, 222, 255))
    for x in range(6, 43, 6):
        c.px(x, 15 if 10 < x < 38 else 13, (255, 230, 120, 255))
    c.outline(color=OUT, selective=False)
    c.img.save(os.path.join(FX, "legendary_plate.png"))


def plate_tonkatsu():
    """The finished Tonkatsu no Kami on the legendary plate (for the finale)."""
    c = Canvas(48, 24)
    c.ellipse(24, 16, 22, 7, (200, 150, 50, 255))
    c.ellipse(24, 15, 20, 6, (250, 248, 240, 255))
    c.ellipse(14, 12, 6, 4, (150, 210, 110, 255))   # shredded cabbage
    for i in range(4):
        x = 22 + i * 5
        c.rect(x, 8 - (i % 2), x + 4, 15, (214, 150, 60, 255)); c.rect(x, 8 - (i % 2), x + 4, 9 - (i % 2), (240, 190, 90, 255))
        c.rect(x + 4, 9, x + 4, 15, (170, 100, 40, 255))
    c.ellipse(34, 6, 3, 2, (250, 250, 244, 255))    # rice
    c.outline(color=OUT, selective=False)
    c.img.save(os.path.join(FX, "plate_tonkatsu.png"))


def kitchen_plate():
    """Lulu's failed dish (burnt cutlet) shown on the counter."""
    c = Canvas(24, 12)
    c.ellipse(12, 7, 11, 4, (238, 236, 228, 255))
    c.ellipse(12, 6, 7, 2, (110, 64, 34, 255)); c.rect(7, 4, 17, 6, (90, 52, 30, 255)); c.px(9, 4, (60, 40, 30, 255))
    c.px(14, 4, (40, 30, 26, 255)); c.px(18, 2, (120, 120, 120, 255)); c.px(19, 1, (140, 140, 140, 255))
    c.outline(color=OUT, selective=False)
    c.img.save(os.path.join(FX, "dish_burnt.png"))


# ------------------------------------------------------------------ title logo
def logo():
    font_l = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "Silkscreen-Regular.ttf"), 32)
    font_s = ImageFont.truetype("/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf", 12)
    W, H = 360, 76
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    text = "TONKATSU NO KAMI"
    tw = d.textlength(text, font=font_l)
    x0 = int((W - tw) / 2)
    y0 = 8
    # shadow, outline, gold fill with vertical gradient
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask); md.fontmode = "1"
    md.text((x0, y0), text, font=font_l, fill=255)
    m = np.array(mask) > 0
    dil = ndimage.binary_dilation(m, iterations=2)
    shadow = np.roll(np.roll(dil, 3, axis=0), 2, axis=1)
    arr = np.zeros((H, W, 4), np.uint8)
    arr[shadow] = (150, 30, 40, 255)
    arr[dil] = (40, 20, 19, 255)
    ys = np.where(m.any(axis=1))[0]
    top, bot = ys.min(), ys.max()
    for y in range(top, bot + 1):
        t = (y - top) / max(1, bot - top)
        col = (int(255), int(236 - 70 * t), int(150 - 110 * t), 255)
        arr[y][m[y]] = col
    # highlight line
    arr[top + 1][m[top + 1]] = (255, 255, 230, 255)
    img = Image.fromarray(arr)
    d = ImageDraw.Draw(img); d.fontmode = "1"
    sub = "トンカツの神"
    sw = d.textlength(sub, font=font_s)
    sx = int((W - sw) / 2)
    d.rectangle([sx - 10, 52, sx + sw + 10, 68], fill=(150, 30, 40, 255), outline=(40, 20, 19, 255))
    d.text((sx, 54), sub, font=font_s, fill=(255, 240, 220, 255))
    img.save(os.path.join(FX, "title_logo.png"))


# ------------------------------------------------------------------ emotes / glyphs
def emotes():
    kinds = ["exclaim", "question", "dots", "heart", "sweat", "anger", "note", "sparkle"]
    strip = Image.new("RGBA", (16 * len(kinds), 16))
    for i, k in enumerate(kinds):
        c = Canvas(16, 16)
        c.ellipse(8, 7, 7, 6, (255, 255, 255, 255)); c.poly([(5, 11), (8, 11), (4, 15)], (255, 255, 255, 255))
        red, blk = (220, 50, 60, 255), (40, 20, 19, 255)
        if k == "exclaim":
            c.rect(7, 3, 8, 8, red); c.rect(7, 10, 8, 10, red)
        elif k == "question":
            c.rect(6, 3, 9, 3, blk); c.px(10, 4, blk); c.px(10, 5, blk); c.rect(8, 6, 9, 6, blk); c.px(8, 7, blk); c.px(8, 9, blk)
        elif k == "dots":
            for x in (4, 7, 10):
                c.rect(x, 7, x + 1, 8, blk)
        elif k == "heart":
            c.ellipse(6, 6, 2, 2, red); c.ellipse(10, 6, 2, 2, red); c.poly([(4, 7), (12, 7), (8, 11)], red)
        elif k == "sweat":
            c.ellipse(8, 8, 2, 3, (120, 180, 240, 255)); c.px(8, 4, (120, 180, 240, 255)); c.px(8, 5, (120, 180, 240, 255))
        elif k == "anger":
            for dx, dy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
                c.rect(8 + dx * 2, 7 + dy * 2, 8 + dx * 3, 7 + dy * 2, red); c.rect(8 + dx * 2, 7 + dy * 3, 8 + dx * 2, 7 + dy * 2, red)
        elif k == "note":
            c.rect(9, 3, 9, 9, blk); c.ellipse(7, 9, 2, 1, blk); c.rect(10, 3, 11, 4, blk)
        elif k == "sparkle":
            c.rect(7, 2, 8, 12, (240, 180, 40, 255)); c.rect(3, 7, 12, 8, (240, 180, 40, 255)); c.rect(6, 6, 9, 9, (255, 236, 140, 255))
        c.outline(color=(40, 20, 19, 255), selective=False)
        strip.alpha_composite(c.img, (16 * i, 0))
    strip.save(os.path.join(FX, "emotes.png"))
    json.dump(kinds, open(os.path.join(FX, "emotes.json"), "w"))


def glyphs():
    """Magic glyphs: geometric mon-style crests (circles, hexagram, sakura,
    crescent, wave, flame). Deliberately not pseudo-kanji."""
    shapes = []
    gold, gl = (255, 214, 90, 255), (255, 246, 200, 255)
    for k in range(6):
        c = Canvas(16, 16)
        if k == 0:
            c.ellipse(8, 8, 6, 6, gold); c.ellipse(8, 8, 4, 4, (0, 0, 0, 0)); c.ellipse(8, 8, 1, 1, gl)
        elif k == 1:
            c.poly([(8, 1), (14, 12), (2, 12)], gold); c.poly([(8, 15), (14, 4), (2, 4)], gold); c.ellipse(8, 8, 2, 2, gl)
        elif k == 2:   # sakura
            for a in range(5):
                ang = a * math.tau / 5 - math.pi / 2
                c.ellipse(8 + math.cos(ang) * 4, 8 + math.sin(ang) * 4, 2, 2, gold)
            c.ellipse(8, 8, 1, 1, gl)
        elif k == 3:   # crescent
            c.ellipse(8, 8, 6, 6, gold); c.ellipse(10, 7, 5, 5, (0, 0, 0, 0))
        elif k == 4:   # wave
            for x in range(2, 15):
                y = int(8 + math.sin(x * 0.9) * 3)
                c.rect(x, y, x, y + 1, gold)
        else:          # flame
            c.poly([(8, 1), (12, 9), (10, 14), (6, 14), (4, 9)], gold); c.poly([(8, 6), (10, 11), (6, 11)], gl)
        shapes.append(c)
    strip = Image.new("RGBA", (16 * len(shapes), 16))
    for i, s in enumerate(shapes):
        strip.alpha_composite(s.img, (16 * i, 0))
    strip.save(os.path.join(FX, "glyphs.png"))


def soft_light():
    """Radial falloff used by PointLight2D (smooth light is fine on top of pixel art)."""
    n = 128
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.sqrt((xx - n / 2 + 0.5) ** 2 + (yy - n / 2 + 0.5) ** 2) / (n / 2)
    a = np.clip(1 - r, 0, 1) ** 2
    img = np.zeros((n, n, 4), np.uint8)
    img[:, :, :3] = 255
    img[:, :, 3] = (a * 255).astype(np.uint8)
    Image.fromarray(img).save(os.path.join(FX, "light_soft.png"))
    # hard pixel dot for particles
    p = Canvas(4, 4); p.rect(1, 0, 2, 3, (255, 255, 255, 255)); p.rect(0, 1, 3, 2, (255, 255, 255, 255))
    p.img.save(os.path.join(FX, "particle_px.png"))
    q = Canvas(2, 2); q.rect(0, 0, 1, 1, (255, 255, 255, 255)); q.img.save(os.path.join(FX, "particle_dot.png"))


if __name__ == "__main__":
    morph()
    for n, f in (("cabbage", cabbage), ("wheat", wheat), ("rice", rice), ("meat", meat), ("pepper", pepper), ("egg", egg)):
        icon(n, f)
    plate(); plate_tonkatsu(); kitchen_plate(); logo(); emotes(); glyphs(); soft_light()
    print("fx ok")
