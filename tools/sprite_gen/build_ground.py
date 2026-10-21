"""Seamless 32x32 ground tiles (+ variants) derived from the artist's tiles.

For each tile: crop the interior (dropping the drawn border), resample to 32,
then make it wrap by cross-fading with a half-offset copy near the edges and
snapping back to the tile's own palette (keeps hard pixel-art colours).
Variants are made by offsetting/flipping the seamless texture.
Output: assets/sprites/tiles/ground/<name>_<v>.png
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

from build_from_refs import kmeans_palette, apply_palette

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "tiles", "ground")
os.makedirs(OUT, exist_ok=True)


def crop_tile(sheet, bbox, inset):
    src = np.array(Image.open(sheet).convert("RGBA"))
    x0, y0, x1, y1 = bbox
    sub = src[y0 + inset:y1 - inset, x0 + inset:x1 - inset].copy()
    sub[:, :, 3] = 255
    return np.array(Image.fromarray(sub).resize((32, 32), Image.BOX))


def seamless(t, k=10):
    t = t.astype(np.float32)
    s = np.roll(np.roll(t, 16, axis=0), 16, axis=1)
    yy, xx = np.mgrid[0:32, 0:32]
    d = np.minimum(np.minimum(xx, 31 - xx), np.minimum(yy, 31 - yy)).astype(np.float32)
    w = np.clip(d / 8.0, 0, 1)[:, :, None]
    out = t * w + s * (1 - w)
    out = out.clip(0, 255).astype(np.uint8)
    pal = kmeans_palette(t[:, :, :3].reshape(-1, 3).astype(np.uint8), k)
    out[:, :, 3] = 255
    return apply_palette(out, pal)


def variants(t, n=4):
    vs = [t]
    rng = np.random.default_rng(7)
    for i in range(1, n):
        v = np.roll(np.roll(t, int(rng.integers(4, 28)), axis=0), int(rng.integers(4, 28)), axis=1)
        if i % 2:
            v = v[:, ::-1]
        vs.append(np.ascontiguousarray(v))
    return vs


def main():
    sheet = os.path.join(ROOT, "assets", "sprites", "source", "tiles_village_day.png")
    meta = {m["i"]: m for m in json.load(open(os.path.join(ROOT, "assets", "sprites", "tiles", "village_day", "pieces.json")))}
    spec = {"grass": (42, 10, 12), "stone": (44, 4, 12), "water": (71, 8, 10), "path": (48, 4, 12)}
    manifest = {}
    for name, (idx, inset, k) in spec.items():
        t = seamless(crop_tile(sheet, meta[idx]["bbox"], inset), k)
        vs = variants(t)
        for i, v in enumerate(vs):
            Image.fromarray(v).save(os.path.join(OUT, f"{name}_{i}.png"))
        manifest[name] = len(vs)
    # dirt: sample the sandy interior of the dirt tile (avoids its grass corners)
    t = crop_tile(sheet, meta[43]["bbox"], 4)
    sand = t[10:22, 10:22]
    big = np.array(Image.fromarray(sand).resize((32, 32), Image.NEAREST))
    d = seamless(big, 8)
    rng = np.random.default_rng(3)
    for _ in range(14):                                   # pebbles for texture
        x, y = rng.integers(0, 32, 2)
        d[y, x, :3] = (d[y, x, :3] * 0.78).astype(np.uint8)
    for i, v in enumerate(variants(d)):
        Image.fromarray(v).save(os.path.join(OUT, f"dirt_{i}.png"))
    manifest["dirt"] = 4
    json.dump(manifest, open(os.path.join(OUT, "ground.json"), "w"))
    # preview: 6x6 of each
    prev = Image.new("RGBA", (len(manifest) * 200, 192))
    for k_, name in enumerate(manifest):
        for x in range(6):
            for y in range(6):
                prev.paste(Image.open(os.path.join(OUT, f"{name}_{(x * 7 + y * 3) % 4}.png")), (k_ * 200 + x * 32, y * 32))
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save(os.path.join(os.path.dirname(__file__), "_preview", "ground_tiled.png"))
    print(manifest)


if __name__ == "__main__":
    main()


def interiors():
    """Wooden planks and tatami floors for interiors (procedural, kitchen palette)."""
    rng = np.random.default_rng(11)
    base, dark, light = np.array([150, 98, 62]), np.array([118, 76, 46]), np.array([172, 118, 76])
    for v in range(4):
        t = np.zeros((32, 32, 4), np.uint8)
        t[:, :, 3] = 255
        for band in range(4):
            col = base if (band + v) % 2 == 0 else (base * 0.95).astype(int)
            t[band * 8:(band + 1) * 8, :, :3] = col
            t[band * 8, :, :3] = dark
            t[band * 8 + 1, :, :3] = light
            off = (band * 11 + v * 7) % 32
            t[band * 8:(band + 1) * 8, off, :3] = dark
        for _ in range(18):
            x, y = rng.integers(0, 32, 2)
            t[y, x, :3] = dark
        Image.fromarray(t).save(os.path.join(OUT, f"wood_{v}.png"))
        m = np.zeros((32, 32, 4), np.uint8)
        m[:, :, 3] = 255
        m[:, :, :3] = [190, 182, 118]
        for y in range(0, 32, 3):
            m[y, :, :3] = [176, 168, 106]
        m[0:2, :, :3] = [58, 80, 58]
        if v % 2:
            m[:, 0:2, :3] = [58, 80, 58]
        Image.fromarray(m).save(os.path.join(OUT, f"tatami_{v}.png"))


if __name__ == "__main__":
    interiors()
