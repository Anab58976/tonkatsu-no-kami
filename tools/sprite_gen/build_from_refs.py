"""Extracts every figure we use from the artist's reference sheets.

Output: assets/sprites/extracted/<char>/<name>.png  (true 1:1 pixel art, transparent)
        tools/sprite_gen/_preview/<char>.png        (x5 contact sheet for review)

Run:  python3 build_from_refs.py
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

from import_refs import load_rgba, remove_background

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source")
OUT = os.path.join(ROOT, "assets", "sprites", "extracted")
PREV = os.path.join(os.path.dirname(__file__), "_preview")

# (name, (x0, y0, x1, y1), target_height_px)
FIGURES = {
    "lulu_human": ("lulu_human_sheet.jpg", 22, [
        ("ref_large", (25, 71, 466, 967), None),
        ("front", (532, 76, 769, 536), 52),
        ("side", (818, 76, 1023, 536), 52),
        ("back", (1060, 76, 1295, 536), 52),
        ("walk_0", (647, 638, 804, 925), 34),
        ("walk_1", (889, 638, 1054, 925), 34),
        ("walk_2", (1161, 638, 1331, 926), 34),
    ]),
    "lulu_pig": ("lulu_pig_sheet.jpg", 22, [
        ("portrait_neutral", (358, 221, 567, 429), 34),
        ("portrait_wink", (570, 221, 771, 430), 34),
        ("portrait_happy", (772, 221, 969, 431), 34),
        ("portrait_annoyed", (975, 224, 1175, 432), 34),
        ("ref_large", (14, 244, 356, 835), None),
        ("turn_0", (371, 518, 542, 807), 31),
        ("turn_1", (552, 523, 700, 807), 31),
        ("turn_2", (714, 523, 877, 807), 31),
        ("turn_3", (895, 523, 1038, 807), 31),
        ("walk_0", (215, 895, 329, 1104), 31),
        ("walk_1", (362, 894, 475, 1103), 31),
        ("walk_2", (515, 895, 626, 1104), 31),
        ("walk_3", (660, 896, 771, 1104), 31),
        ("walk_4", (802, 896, 913, 1104), 31),
        ("walk_5", (935, 896, 1049, 1104), 31),
        ("back_heart", (1069, 894, 1203, 1104), 31),
        ("prop_pan", (1129, 518, 1245, 616), 14),
        ("prop_spatula", (1150, 623, 1211, 725), 14),
        ("prop_bow", (1145, 731, 1213, 794), 9),
    ]),
    "ghost": ("enemy_ghost_sheet.png", 14, [
        ("idle_0", (13, 79, 163, 242), 30), ("idle_1", (186, 75, 333, 242), 30),
        ("idle_2", (353, 78, 508, 235), 30), ("idle_3", (535, 72, 692, 238), 30),
        ("walk_l_0", (813, 72, 958, 251), 30), ("walk_l_1", (990, 78, 1153, 251), 30),
        ("walk_l_2", (1165, 79, 1312, 251), 30), ("walk_l_3", (1329, 77, 1494, 251), 30),
        ("walk_r_0", (9, 324, 153, 510), 30), ("walk_r_1", (165, 327, 338, 510), 30),
        ("walk_r_2", (359, 320, 523, 510), 30), ("walk_r_3", (535, 317, 697, 510), 30),
        ("hurt_0", (16, 853, 171, 1002), 28), ("hurt_1", (179, 853, 330, 1002), 28),
        ("hurt_2", (340, 849, 509, 1002), 28), ("hurt_3", (521, 853, 693, 1002), 28),
        ("attack_0", (747, 598, 914, 753), 28), ("attack_3", (1359, 596, 1518, 764), 28),
        ("attack_1", (933, 602, 1149, 769), 28), ("orb", (1208, 634, 1333, 718), 12),
        ("die_0", (750, 853, 890, 1004), 28), ("die_1", (911, 856, 1049, 1003), 28),
        ("die_2", (1082, 856, 1199, 1004), 28),
    ]),
    "shadow_wolf": ("enemy_shadow_wolf.png", 12, [("idle_0", (33, 26, 1234, 1235), 78)]),
    "mushroom": ("enemy_mushroom_golem.png", 14, [("idle_0", (151, 19, 732, 867), 56)]),
    "moss_golem": ("enemy_mushroom_golem.png", 14, [("idle_0", (822, 48, 1695, 857), 64)]),
}


def best_offset(rgb, alpha, s):
    best = None
    h, w = alpha.shape
    g = rgb.astype(np.float32)
    for ox in np.arange(0, s, 1.0):
        for oy in np.arange(0, s, 1.0):
            err, cnt = 0.0, 0
            ys = np.arange(oy, h - s, s)
            xs = np.arange(ox, w - s, s)
            for y in ys[::2]:
                for x in xs[::2]:
                    y0, x0 = int(y), int(x)
                    y1, x1 = int(y + s), int(x + s)
                    am = alpha[y0:y1, x0:x1] > 0
                    if am.mean() < 0.9:
                        continue
                    err += float(g[y0:y1, x0:x1][am].std(axis=0).sum())
                    cnt += 1
            e = err / max(cnt, 1)
            if best is None or e < best[0]:
                best = (e, ox, oy)
    return best[1], best[2]


def pixelate(rgb, alpha, s, ox, oy):
    h, w = alpha.shape
    ys = np.arange(oy - s, h, s)
    xs = np.arange(ox - s, w, s)
    out = np.zeros((len(ys), len(xs), 4), np.uint8)
    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            y0 = int(round(y + s * 0.25)); y1 = int(round(y + s * 0.75))
            x0 = int(round(x + s * 0.25)); x1 = int(round(x + s * 0.75))
            y0, x0 = max(0, y0), max(0, x0)
            y1, x1 = min(h, max(y1, y0 + 1)), min(w, max(x1, x0 + 1))
            if y0 >= h or x0 >= w or y1 <= 0 or x1 <= 0:
                continue
            # coverage judged on the whole block, colour from the centre
            fy0, fy1 = max(0, int(y)), min(h, int(y + s))
            fx0, fx1 = max(0, int(x)), min(w, int(x + s))
            if fy1 <= fy0 or fx1 <= fx0:
                continue
            if (alpha[fy0:fy1, fx0:fx1] > 0).mean() < 0.5:
                continue
            am = alpha[y0:y1, x0:x1] > 0
            if not am.any():
                am = alpha[fy0:fy1, fx0:fx1] > 0
                blk = rgb[fy0:fy1, fx0:fx1][am]
            else:
                blk = rgb[y0:y1, x0:x1][am]
            # darkest-biased median keeps 1px outlines from vanishing
            lum = blk.sum(axis=1)
            if lum.min() < 200 and (lum < 200).mean() > 0.3:
                blk = blk[lum < 200]
            out[j, i, :3] = np.median(blk, axis=0)
            out[j, i, 3] = 255
    ys_, xs_ = np.where(out[:, :, 3] > 0)
    if len(ys_) == 0:
        return out
    return out[ys_.min():ys_.max() + 1, xs_.min():xs_.max() + 1]


def drop_specks(px, min_neighbors=1):
    a = px[:, :, 3] > 0
    h, w = a.shape
    out = px.copy()
    for y in range(h):
        for x in range(w):
            if not a[y, x]:
                continue
            n = 0
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if (dy or dx) and 0 <= y + dy < h and 0 <= x + dx < w and a[y + dy, x + dx]:
                        n += 1
            if n < min_neighbors:
                out[y, x, 3] = 0
    return out


def kmeans_palette(cols, k, iters=20, seed=3):
    rng = np.random.default_rng(seed)
    cols = cols.astype(np.float32)
    # k-means++ init
    cent = [cols[rng.integers(len(cols))]]
    for _ in range(1, k):
        d = np.min(((cols[:, None] - np.array(cent)[None]) ** 2).sum(2), axis=1)
        cent.append(cols[rng.choice(len(cols), p=d / d.sum())])
    cent = np.array(cent)
    for _ in range(iters):
        lab = ((cols[:, None] - cent[None]) ** 2).sum(2).argmin(1)
        for c in range(k):
            sel = cols[lab == c]
            if len(sel):
                cent[c] = sel.mean(0)
    return cent.round().astype(np.uint8)


def apply_palette(px, pal):
    out = px.copy()
    m = px[:, :, 3] > 0
    cols = px[:, :, :3][m].astype(np.float32)
    lab = ((cols[:, None] - pal[None].astype(np.float32)) ** 2).sum(2).argmin(1)
    out[:, :, :3][m] = pal[lab]
    return out


def contact(images, scale=5, pad=6, bg=(60, 60, 70, 255)):
    h = max(i.shape[0] for i in images) * scale + pad * 2
    w = sum(i.shape[1] * scale + pad for i in images) + pad
    sheet = Image.new("RGBA", (w, h), bg)
    x = pad
    for im in images:
        p = Image.fromarray(im).resize((im.shape[1] * scale, im.shape[0] * scale), Image.NEAREST)
        sheet.alpha_composite(p, (x, pad))
        x += im.shape[1] * scale + pad
    return sheet


def main(only=None):
    os.makedirs(PREV, exist_ok=True)
    for char, (src, k, figs) in FIGURES.items():
        if only and char not in only:
            continue
        a = remove_background(load_rgba(os.path.join(SRC, src)))
        rgb = np.clip(a[:, :, :3], 0, 255).astype(np.uint8)
        alpha = a[:, :, 3]
        results = []
        for name, (x0, y0, x1, y1), target in figs:
            if target is None:
                continue
            sub_a = alpha[y0:y1, x0:x1].copy()
            # keep only rows/cols that actually contain the figure
            ys, xs = np.where(sub_a > 0)
            hgt = ys.max() - ys.min() + 1
            s = hgt / float(target)
            ox, oy = best_offset(rgb[y0:y1, x0:x1], sub_a, s)
            px = pixelate(rgb[y0:y1, x0:x1], sub_a, s, ox, oy)
            px = drop_specks(px)
            results.append((name, px))
        allcols = np.concatenate([p[:, :, :3][p[:, :, 3] > 0] for _, p in results])
        pal = kmeans_palette(allcols, k)
        os.makedirs(os.path.join(OUT, char), exist_ok=True)
        imgs = []
        for name, px in results:
            px = apply_palette(px, pal)
            Image.fromarray(px).save(os.path.join(OUT, char, f"{name}.png"))
            imgs.append(px)
        contact(imgs).save(os.path.join(PREV, f"{char}.png"))
        print(char, [(n, p.shape[1], p.shape[0]) for (n, p) in results])


if __name__ == "__main__":
    import sys
    main(sys.argv[1:] or None)
