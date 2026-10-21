"""Turns the artist's high-resolution reference sheets into engine-ready pixel sprites.

Steps per source image:
 1. Background removal: flood-fill from the image border with a colour tolerance
    (interior light colours such as the white kimono are protected by the dark
    outline, so only the connected background disappears).
 2. Connected components on the remaining alpha -> one component per figure.
    Text labels and palette swatches are filtered out by size/shape/colour.
 3. Pixel-grid recovery: the references are drawn with "big pixels" (~6-12 px).
    For each figure we search the block size + offset that best explains the
    image, then sample the median colour of every block -> true 1:1 pixel art.
 4. Palette clean-up: colours are snapped to a small palette (k-means) so JPEG
    noise does not leak into the sprite.

The originals in assets/sprites/source/ are never modified.
"""
from __future__ import annotations

import sys
from collections import deque

import numpy as np
from PIL import Image


def load_rgba(path):
    return np.array(Image.open(path).convert("RGBA")).astype(np.int16)


def remove_background(a, tol=38, extra_seeds=()):
    """Flood fill from border pixels similar to the dominant border colour."""
    h, w = a.shape[:2]
    out = a.copy()
    if (a[:, :, 3] < 250).mean() > 0.2:   # already has transparency
        out[:, :, 3] = np.where(a[:, :, 3] < 128, 0, 255)
        return out
    border = np.concatenate([a[0, :, :3], a[-1, :, :3], a[:, 0, :3], a[:, -1, :3]])
    bg = np.median(border, axis=0)
    diff = np.abs(a[:, :, :3] - bg).sum(axis=2)
    cand = diff < tol
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if cand[y, x]:
                q.append((y, x)); seen[y, x] = True
    for y in range(h):
        for x in (0, w - 1):
            if cand[y, x] and not seen[y, x]:
                q.append((y, x)); seen[y, x] = True
    for (y, x) in extra_seeds:
        q.append((y, x)); seen[y, x] = True
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and cand[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    out[:, :, 3] = np.where(seen, 0, 255)
    return out


def components(alpha, min_area=400, merge_gap=6):
    """Bounding boxes of connected opaque regions (dilated by merge_gap so a
    figure split by thin gaps stays one piece)."""
    from scipy import ndimage
    m = alpha > 0
    if merge_gap:
        m2 = ndimage.binary_dilation(m, iterations=merge_gap)
    else:
        m2 = m
    lab, n = ndimage.label(m2)
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        area = int((m[sl] & (lab[sl] == i)).sum())
        if area < min_area:
            continue
        y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        boxes.append({"x0": x0, "y0": y0, "x1": x1, "y1": y1, "area": area, "label": i})
    boxes.sort(key=lambda b: (b["y0"] // 120, b["x0"]))
    return boxes, lab


def estimate_block(rgb, alpha, lo=4, hi=16):
    """Find the big-pixel size and offset that best reconstruct the region."""
    best = None
    g = rgb.astype(np.float32)
    for s in np.arange(lo, hi + 0.01, 0.25):
        for ox in np.arange(0, s, max(1.0, s / 4)):
            for oy in np.arange(0, s, max(1.0, s / 4)):
                err = _recon_error(g, alpha, s, ox, oy)
                if best is None or err < best[0]:
                    best = (err, s, ox, oy)
    return best


def _grid(n, s, o):
    edges = np.arange(o, n + s, s)
    return [(int(round(edges[i])), int(round(edges[i + 1]))) for i in range(len(edges) - 1)
            if int(round(edges[i + 1])) > int(round(edges[i]))]


def _recon_error(g, alpha, s, ox, oy):
    h, w = alpha.shape
    err = 0.0
    cnt = 0
    # sample a subset of cells for speed: interior variance of each block
    for (y0, y1) in _grid(h, s, oy)[::2]:
        for (x0, x1) in _grid(w, s, ox)[::2]:
            y0c, y1c, x0c, x1c = max(0, y0), min(h, y1), max(0, x0), min(w, x1)
            if y1c - y0c < 2 or x1c - x0c < 2:
                continue
            blk = g[y0c:y1c, x0c:x1c]
            am = alpha[y0c:y1c, x0c:x1c] > 0
            if am.mean() < 0.5:
                continue
            err += float(blk[am].std(axis=0).sum())
            cnt += 1
    # penalise tiny blocks a little (they always fit better)
    return (err / max(1, cnt)) - s * 0.9


def pixelate(rgb, alpha, s, ox, oy):
    h, w = alpha.shape
    rows = _grid(h, s, oy - s)
    cols = _grid(w, s, ox - s)
    out = np.zeros((len(rows), len(cols), 4), np.uint8)
    for j, (y0, y1) in enumerate(rows):
        for i, (x0, x1) in enumerate(cols):
            # sample the centre 50% of the block to avoid edge bleeding
            cy0 = max(0, int(y0 + (y1 - y0) * 0.25)); cy1 = min(h, max(cy0 + 1, int(y0 + (y1 - y0) * 0.75)))
            cx0 = max(0, int(x0 + (x1 - x0) * 0.25)); cx1 = min(w, max(cx0 + 1, int(x0 + (x1 - x0) * 0.75)))
            if cy0 >= h or cx0 >= w:
                continue
            am = alpha[cy0:cy1, cx0:cx1] > 0
            if am.size == 0 or am.mean() < 0.5:
                continue
            blk = rgb[cy0:cy1, cx0:cx1][am]
            out[j, i, :3] = np.median(blk, axis=0)
            out[j, i, 3] = 255
    # trim empty borders
    ys, xs = np.where(out[:, :, 3] > 0)
    if len(ys) == 0:
        return out
    return out[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def quantize(px, k=16, iters=12, seed=1):
    """Small k-means palette snap on opaque pixels."""
    m = px[:, :, 3] > 0
    cols = px[:, :, :3][m].astype(np.float32)
    if len(cols) <= k:
        return px
    rng = np.random.default_rng(seed)
    cent = cols[rng.choice(len(cols), k, replace=False)]
    for _ in range(iters):
        d = ((cols[:, None, :] - cent[None, :, :]) ** 2).sum(axis=2)
        lab = d.argmin(axis=1)
        for c in range(k):
            sel = cols[lab == c]
            if len(sel):
                cent[c] = sel.mean(axis=0)
    d = ((cols[:, None, :] - cent[None, :, :]) ** 2).sum(axis=2)
    lab = d.argmin(axis=1)
    out = px.copy()
    out[:, :, :3][m] = cent[lab].round().astype(np.uint8)
    return out


if __name__ == "__main__":
    path = sys.argv[1]
    a = load_rgba(path)
    a = remove_background(a)
    boxes, _ = components(a[:, :, 3])
    for b in boxes:
        print(b)
