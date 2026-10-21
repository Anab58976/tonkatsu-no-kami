"""Cuts an artist tileset sheet into individual props + ground tiles.

The sheets are not on a strict grid, so every connected piece becomes its own
sprite. Scale: the ground tile size in the sheet (TILE_SRC) maps to 32 px.
Down-sampling uses an area average + alpha threshold, then a shared palette
(k-means) keeps every piece in the same colour family.

Usage: python3 build_tileset.py <sheet.png> <out_id> <tile_src_px> [k]
Outputs assets/sprites/tiles/<out_id>/piece_<n>.png + pieces.json (bbox, size)
and _preview/<out_id>_atlas.png (indexed contact sheet for naming).
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

from build_from_refs import kmeans_palette, apply_palette

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PREV = os.path.join(os.path.dirname(__file__), "_preview")


def downsample(rgba: np.ndarray, f: float) -> np.ndarray:
    h, w = rgba.shape[:2]
    nw, nh = max(1, round(w / f)), max(1, round(h / f))
    a = rgba[:, :, 3:4].astype(np.float32) / 255.0
    prem = np.concatenate([rgba[:, :, :3].astype(np.float32) * a, a * 255.0], axis=2)
    small = np.array(Image.fromarray(prem.clip(0, 255).astype(np.uint8)).resize((nw, nh), Image.BOX)).astype(np.float32)
    al = small[:, :, 3] / 255.0
    out = np.zeros((nh, nw, 4), np.uint8)
    keep = al > 0.5
    out[:, :, :3][keep] = (small[:, :, :3][keep] / al[keep][:, None]).clip(0, 255).astype(np.uint8)
    out[:, :, 3][keep] = 255
    return out


def main(sheet, out_id, tile_src, k=48, min_area=250, opaque_bg=False):
    src = np.array(Image.open(sheet).convert("RGBA"))
    if opaque_bg:
        # dark uniform background (no alpha): treat near-background colour as transparent
        border = np.concatenate([src[0, :, :3], src[-1, :, :3], src[:, 0, :3], src[:, -1, :3]]).astype(int)
        bg = np.median(border, axis=0)
        diff = np.abs(src[:, :, :3].astype(int) - bg).sum(axis=2)
        src[:, :, 3] = np.where(diff < 40, 0, 255)
    m = src[:, :, 3] > 128
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=1))
    f = tile_src / 32.0
    pieces = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        area = int((m[sl] & (lab[sl] == i)).sum())
        if area < min_area:
            continue
        y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        sub = src[y0:y1, x0:x1].copy()
        sub[:, :, 3] = np.where((lab[y0:y1, x0:x1] == i) & m[y0:y1, x0:x1], 255, 0)
        px = downsample(sub, f)
        if px[:, :, 3].sum() == 0:
            continue
        pieces.append({"bbox": [int(x0), int(y0), int(x1), int(y1)], "px": px})
    pieces.sort(key=lambda p: (p["bbox"][1] // 60, p["bbox"][0]))
    allc = np.concatenate([p["px"][:, :, :3][p["px"][:, :, 3] > 0] for p in pieces])
    pal = kmeans_palette(allc[:: max(1, len(allc) // 60000)], k)
    od = os.path.join(ROOT, "assets", "sprites", "tiles", out_id)
    os.makedirs(od, exist_ok=True)
    meta = []
    for idx, p in enumerate(pieces):
        px = apply_palette(p["px"], pal)
        Image.fromarray(px).save(os.path.join(od, f"piece_{idx}.png"))
        meta.append({"i": idx, "bbox": p["bbox"], "w": int(px.shape[1]), "h": int(px.shape[0])})
        p["px"] = px
    json.dump(meta, open(os.path.join(od, "pieces.json"), "w"), indent=1)
    # indexed atlas for naming
    sc = 2
    W = 1800
    x = y = 0
    rowh = 0
    placed = []
    for p in pieces:
        w, h = p["px"].shape[1] * sc + 4, p["px"].shape[0] * sc + 14
        if x + w > W:
            x, y, rowh = 0, y + rowh, 0
        placed.append((x, y))
        x += w
        rowh = max(rowh, h)
    img = Image.new("RGBA", (W, y + rowh), (58, 62, 74, 255))
    d = ImageDraw.Draw(img)
    for idx, (p, (px_, py_)) in enumerate(zip(pieces, placed)):
        im = Image.fromarray(p["px"]).resize((p["px"].shape[1] * sc, p["px"].shape[0] * sc), Image.NEAREST)
        img.alpha_composite(im, (px_, py_ + 12))
        d.text((px_, py_), str(idx), fill=(255, 255, 0, 255))
    img.save(os.path.join(PREV, f"{out_id}_atlas.png"))
    print(out_id, len(pieces), "pieces")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4]) if len(sys.argv) > 4 else 48,
         opaque_bg=len(sys.argv) > 5 and sys.argv[5] == "opaque")
