"""Extracts the artist's full 4-direction Lulu sheet (pig + human):
idle / walk / run / jump / attack / hurt, for down/left/right/up.

All frames share one block size (the sheet is drawn at a single scale), so
pig and human keep correct relative proportions. Shadow ellipses drawn under
the feet are removed (the engine draws its own shadow).
Output: assets/sprites/extracted/sheet_<who>/<anim>_<dir>_<i>.png
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

from build_from_refs import best_offset, pixelate, drop_specks, kmeans_palette, apply_palette, contact
from import_refs import load_rgba, remove_background

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source", "lulu_full_sheet.png")
OUT = os.path.join(ROOT, "assets", "sprites", "extracted")
PREV = os.path.join(os.path.dirname(__file__), "_preview")
BLOCK = 4.4

# rows: (anim, y0, y1); per half: list of (dir, [x ranges]) — merged figures are
# given as one range with a count, and split at the emptiest columns.
ROWS = {
    "pig": [
        ("idle", 70, 220, [("down", [(118, 224)]), ("left", [(259, 345)]), ("right", [(396, 482)]), ("up", [(528, 631)])]),
        ("walk", 276, 402, [("down", [(17, 98), (103, 164), (178, 242)]), ("left", [(250, 310), (319, 382)]),
                            ("right", [(397, 458), (469, 530)]), ("up", [(538, 607), (612, 676), (680, 752)])]),
        ("run", 474, 598, [("down", [(17, 94), (100, 161), (174, 236)]), ("left", [(245, 308), (322, 384)]),
                           ("right", [(400, 461), (470, 532)]), ("up", [(540, 607), (610, 674), (680, 751)])]),
        ("jump", 660, 796, [("down", [(20, 99), (103, 164), (173, 237)]), ("left", [(252, 319), (320, 382)]),
                            ("right", [(400, 462), (470, 533)]), ("up", [(544, 610), (614, 675), (681, 752)])]),
        ("attack", 878, 996, [("down", [(15, 104)]), ("left", [(102, 169)]), ("right", [(174, 299)]), ("up", [(304, 383)])]),
        ("hurt", 878, 996, [("down", [(389, 471)]), ("left", [(485, 572)]), ("right", [(584, 655)]), ("up", [(671, 748)])]),
    ],
    "human": [
        ("idle", 70, 220, [("down", [(891, 990)]), ("left", [(1037, 1134)]), ("right", [(1177, 1273)]), ("up", [(1307, 1406)])]),
        ("walk", 276, 404, [("down", [("split", 793, 1005, 3)]), ("left", [(1007, 1072), (1081, 1154)]),
                            ("right", [(1162, 1236), (1246, 1313)]), ("up", [("split", 1317, 1516, 3)])]),
        ("run", 474, 598, [("down", [("split", 790, 1077, 3)]), ("left", [(1081, 1160), (1161, 1239)]),
                           ("right", [(1247, 1315), ("split", 1318, 1395, 1)]), ("up", [("split", 1395, 1520, 2)])]),
        ("jump", 660, 796, [("down", [("split", 793, 1079, 3)]), ("left", [(1086, 1159), (1160, 1239)]),
                            ("right", [(1242, 1317), ("split", 1317, 1394, 1)]), ("up", [("split", 1394, 1516, 2)])]),
        ("attack", 878, 998, [("down", [(792, 867)]), ("left", [(891, 967)]), ("right", [(972, 1055)]), ("up", [(1074, 1148)])]),
        ("hurt", 878, 998, [("down", [(1169, 1246)]), ("left", [("split", 1260, 1345, 1)]), ("right", [("split", 1345, 1430, 1)]),
                            ("up", [(1447, 1522)])]),
    ],
}


def split_range(alpha, y0, y1, x0, x1, n):
    if n == 1:
        return [(x0, x1)]
    col = (alpha[y0:y1, x0:x1] > 0).sum(axis=0).astype(float)
    cuts = []
    w = x1 - x0
    for k in range(1, n):
        c = int(w * k / n)
        lo, hi = max(1, c - w // (3 * n)), min(w - 1, c + w // (3 * n))
        cuts.append(x0 + lo + int(np.argmin(col[lo:hi])))
    edges = [x0] + cuts + [x1]
    return [(edges[i], edges[i + 1]) for i in range(n)]


def remove_shadow(px):
    """Drop greyish low-saturation pixels in the bottom rows (drawn shadow)."""
    h = px.shape[0]
    out = px.copy()
    for y in range(max(0, h - 6), h):
        for x in range(px.shape[1]):
            r, g, b, a = [int(v) for v in px[y, x]]
            if a and max(r, g, b) - min(r, g, b) < 28 and 90 < r < 220:
                out[y, x, 3] = 0
    ys, xs = np.where(out[:, :, 3] > 0)
    return out[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def main():
    a = remove_background(load_rgba(SRC))
    rgb = np.clip(a[:, :, :3], 0, 255).astype(np.uint8)
    alpha = a[:, :, 3]
    for who, rows in ROWS.items():
        frames = []
        for anim, y0, y1, dirs in rows:
            for d, ranges in dirs:
                idx = 0
                for r in ranges:
                    if r[0] == "split":
                        parts = split_range(alpha, y0, y1, r[1], r[2], r[3])
                    else:
                        parts = [r]
                    for (x0, x1) in parts:
                        sub_a = alpha[y0:y1, x0:x1].copy()
                        # keep the biggest blob only (drops neighbours' slivers)
                        from scipy import ndimage
                        lab, n = ndimage.label(ndimage.binary_dilation(sub_a > 0, iterations=3))
                        if n > 1:
                            sizes = ndimage.sum(sub_a > 0, lab, range(1, n + 1))
                            keep = 1 + int(np.argmax(sizes))
                            sub_a[lab != keep] = 0
                        blk = BLOCK * (1.3 if anim == "idle" else 1.0)
                        ox, oy = best_offset(rgb[y0:y1, x0:x1], sub_a, blk)
                        px = drop_specks(pixelate(rgb[y0:y1, x0:x1], sub_a, blk, ox, oy))
                        px = remove_shadow(px)
                        frames.append((f"{anim}_{d}_{idx}", px))
                        idx += 1
        pal = kmeans_palette(np.concatenate([p[:, :, :3][p[:, :, 3] > 0] for _, p in frames]), 24)
        od = os.path.join(OUT, f"sheet_{who}")
        os.makedirs(od, exist_ok=True)
        imgs = []
        for name, px in frames:
            px = apply_palette(px, pal)
            Image.fromarray(px).save(os.path.join(od, name + ".png"))
            imgs.append(px)
        contact(imgs, scale=4).save(os.path.join(PREV, f"sheet_{who}.png"))
        print(who, len(frames), "frames; heights", sorted({p.shape[0] for _, p in frames}))


if __name__ == "__main__":
    main()
