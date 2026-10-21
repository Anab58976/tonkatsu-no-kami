"""Unified re-pixelizer (Tonkatsu Reborn, Marco 1).

One method for every piece of team art that becomes a game sprite:
  1. crop the piece from the team's original sheet (alpha = sheet alpha)
  2. rebuild it on a pixel grid at the TARGET size (block = source/target),
     taking the median colour of the centre of each block (no area averaging)
  3. snap colours to the region palette (shared core + region ramp)
  4. selective inner outline: the silhouette's edge pixels are darkened toward
     ink, so every object reads with a clean contour like the characters
Hard alpha only (0/255).

Used by build_props (Marco 1/3). `python3 repixel.py --proof` writes a
side-by-side comparison of a few HUB props to docs/img/repixel_proof.png.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from build_from_refs import best_offset, pixelate, drop_specks

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PAL = json.load(open(os.path.join(ROOT, "resources", "palettes", "palettes.json")))
INK = np.array([0x2a, 0x16, 0x13], np.float32)


def palette(region: str) -> np.ndarray:
    cols = PAL["shared"]["colors"] + PAL[region]["colors"]
    return np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in cols], np.float32)


def snap(px: np.ndarray, pal: np.ndarray) -> np.ndarray:
    """Nearest palette colour in a perceptual-ish space (weighted RGB)."""
    out = px.copy()
    m = px[:, :, 3] > 0
    c = px[:, :, :3][m].astype(np.float32)
    w = np.array([0.3, 0.59, 0.11], np.float32) * 3
    d = (((c[:, None, :] - pal[None, :, :]) ** 2) * w).sum(axis=2)
    out[:, :, :3][m] = pal[d.argmin(axis=1)].astype(np.uint8)
    return out


def inner_outline(px: np.ndarray, strength=0.62) -> np.ndarray:
    a = px[:, :, 3] > 0
    pad = np.pad(a, 1)
    inner = pad[1:-1, 1:-1] & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    edge = a & ~inner
    out = px.copy()
    c = out[:, :, :3].astype(np.float32)
    c[edge] = c[edge] * (1 - strength) + INK * strength
    out[:, :, :3] = c.clip(0, 255).astype(np.uint8)
    return out


def repixel(sheet: np.ndarray, bbox, target_h: int, region: str, outline=True) -> np.ndarray:
    x0, y0, x1, y1 = bbox
    sub = sheet[y0:y1, x0:x1]
    alpha = (sub[:, :, 3] > 128).astype(np.uint8) * 255
    # keep only the main piece: neighbours on the sheet often poke into the bbox
    from scipy import ndimage
    lab, n = ndimage.label(ndimage.binary_dilation(alpha > 0, iterations=2))
    if n > 1:
        sizes = ndimage.sum(alpha > 0, lab, range(1, n + 1))
        alpha[lab != 1 + int(np.argmax(sizes))] = 0
    rgb = sub[:, :, :3]
    ys, xs = np.where(alpha > 0)
    h_src = ys.max() - ys.min() + 1
    s = h_src / float(target_h)
    ox, oy = best_offset(rgb, alpha, s)
    px = drop_specks(pixelate(rgb, alpha, s, ox, oy))
    px = snap(px, palette(region))
    if outline:
        px = inner_outline(px)
    return px


def noise(a: np.ndarray) -> float:
    m = a[:, :, 3] > 0
    rgb = a[:, :, :3].astype(np.int32)
    h, w = m.shape
    c = rgb[1:-1, 1:-1]
    diff = np.ones(c.shape[:2], bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        diff &= np.abs(c - rgb[1 + dy:h - 1 + dy, 1 + dx:w - 1 + dx]).sum(axis=2) > 24
    mm = m[1:-1, 1:-1]
    return float(diff[mm].mean())


def proof():
    sheet = np.array(Image.open(os.path.join(ROOT, "assets", "sprites", "source", "tiles_village_day.png")).convert("RGBA"))
    pieces = {p["i"]: p for p in json.load(open(os.path.join(ROOT, "assets", "sprites", "tiles", "village_day", "pieces.json")))}
    props = json.load(open(os.path.join(ROOT, "assets", "sprites", "props", "props.json")))
    picks = [("sakura_mid", 6), ("bush_flower", 10), ("torii", 99), ("bench", 102), ("stone_lantern", 108)]
    rows = []
    for name, i in picks:
        old = np.array(Image.open(os.path.join(ROOT, "assets", "sprites", "props", props[name]["file"])).convert("RGBA"))
        new = repixel(sheet, pieces[i]["bbox"], old.shape[0], "hub")
        rows.append((name, old, new))
    # the protagonist at the current and at the target scale, for proportion reference
    lulu = np.array(Image.open(os.path.join(ROOT, "assets", "sprites", "extracted", "lulu_pig", "turn_0.png")).convert("RGBA"))
    sc = 3
    pad = 10
    colw = max(max(o.shape[1], n.shape[1]) for _, o, n in rows) * sc + pad
    W = pad + len(rows) * (2 * colw) + 120
    H = max(max(o.shape[0], n.shape[0]) for _, o, n in rows) * sc + 70
    img = Image.new("RGBA", (W, H), (78, 104, 92, 255))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "PixelifySans-Medium.ttf"), 14)
    x = pad
    stats = []
    for name, old, new in rows:
        for tag, arr in (("atual", old), ("novo", new)):
            im = Image.fromarray(arr).resize((arr.shape[1] * sc, arr.shape[0] * sc), Image.NEAREST)
            img.alpha_composite(im, (x, H - 40 - im.height))
            d.text((x, H - 34), f"{name}", fill=(255, 255, 255), font=font)
            d.text((x, H - 18), f"{tag} · ruído {noise(arr):.0%}", fill=(255, 240, 160) if tag == "novo" else (220, 220, 220), font=font)
            x += colw
        stats.append((name, noise(old), noise(new)))
    os.makedirs(os.path.join(ROOT, "docs", "img"), exist_ok=True)
    img.save(os.path.join(ROOT, "docs", "img", "repixel_proof.png"))
    for s in stats:
        print("%-14s ruído atual %.0f%% -> novo %.0f%%" % (s[0], s[1] * 100, s[2] * 100))


if __name__ == "__main__":
    if "--proof" in sys.argv:
        proof()
