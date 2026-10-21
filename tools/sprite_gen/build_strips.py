"""Converts the artist's per-animation strips (from the .docx sprite documents
and loose PNG strips) into engine sprite folders with anims.json.

Each source image is one animation: frames are found as connected blobs,
ordered left-to-right (or row-major for grids), pixelated to the game grid at
a per-character scale so every animation of a character shares one size.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

from build_from_refs import best_offset, pixelate, drop_specks, kmeans_palette, apply_palette, contact
from rig import Canvas, SheetWriter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source")
DOCX = os.path.join(SRC, "docx")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
PREV = os.path.join(os.path.dirname(__file__), "_preview")


def D(char, n):
    return os.path.join(DOCX, char, f"image{n}.png")


# id: (target height of the reference frame, cell, origin, palette size, [(anim, path, fps, loop, opts)])
CHARS = {
    # boss scale (the Floresta Mágica guardian), like the Pégaso and the Golem
    "cisne_dourado": (92, 144, (72, 136), 24, [
        ("idle", D("Cisne_Dourado", 1), 6, True, {}), ("walk", D("Cisne_Dourado", 2), 8, True, {}),
        ("move", D("Cisne_Dourado", 3), 8, True, {"pairs": True}), ("jump", D("Cisne_Dourado", 4), 8, False, {}),
        ("attack", D("Cisne_Dourado", 5), 10, False, {}), ("hurt", D("Cisne_Dourado", 6), 10, False, {}),
        ("die", D("Cisne_Dourado", 7), 6, False, {}), ("special", D("Cisne_Dourado", 8), 8, False, {})]),
    "chama_azul": (28, 48, (24, 44), 16, [
        ("idle", D("Espirito_Chama_Azul", 1), 8, True, {}), ("walk", D("Espirito_Chama_Azul", 2), 10, True, {}),
        ("jump", D("Espirito_Chama_Azul", 3), 8, False, {}), ("fall", D("Espirito_Chama_Azul", 4), 8, False, {}),
        ("attack", D("Espirito_Chama_Azul", 5), 10, False, {"no_split": True}), ("hurt", D("Espirito_Chama_Azul", 6), 10, False, {}),
        ("die", D("Espirito_Chama_Azul", 7), 8, False, {}), ("move", D("Espirito_Chama_Azul", 8), 10, True, {})]),
    "lobo_infernal": (40, 64, (32, 60), 20, [
        ("idle", D("Lobo_Infernal", 1), 6, True, {}), ("walk", D("Lobo_Infernal", 2), 8, True, {}),
        ("run", D("Lobo_Infernal", 3), 12, True, {}), ("jump", D("Lobo_Infernal", 4), 8, False, {}),
        ("fall", D("Lobo_Infernal", 5), 8, False, {}), ("attack", D("Lobo_Infernal", 6), 12, False, {}),
        ("hurt", D("Lobo_Infernal", 7), 10, False, {}), ("die", D("Lobo_Infernal", 8), 8, False, {})]),
    "rei_pimenta": (58, 96, (48, 90), 24, [
        ("idle", D("Monstro_Pimenta_Coroado", 1), 6, True, {}),
        ("walk", D("Monstro_Pimenta_Coroado", 2), 8, True, {"grid_dirs": 4, "dil": 2, "rescale": 0.92}),
        ("run", D("Monstro_Pimenta_Coroado", 3), 12, True, {"grid_dirs": 4, "dil": 2, "rescale": 0.92}),
        ("jump", D("Monstro_Pimenta_Coroado", 4), 8, False, {}), ("fall", D("Monstro_Pimenta_Coroado", 5), 8, False, {}),
        ("attack", D("Monstro_Pimenta_Coroado", 6), 10, False, {}), ("hurt", D("Monstro_Pimenta_Coroado", 7), 10, False, {}),
        ("die", D("Monstro_Pimenta_Coroado", 8), 6, False, {})]),
    # "pimentinhas" of the Reino dos Temperos: the Monstro Pimenta Coroado at enemy size
    "pimentinha": (36, 48, (24, 45), 18, [
        ("idle", D("Monstro_Pimenta_Coroado", 1), 6, True, {}),
        ("walk", D("Monstro_Pimenta_Coroado", 2), 8, True, {"grid_dirs": 4, "dil": 2, "rescale": 0.92}),
        ("jump", D("Monstro_Pimenta_Coroado", 4), 8, False, {}),
        ("attack", D("Monstro_Pimenta_Coroado", 6), 10, False, {}), ("hurt", D("Monstro_Pimenta_Coroado", 7), 10, False, {}),
        ("die", D("Monstro_Pimenta_Coroado", 8), 6, False, {})]),
    "pegaso_dourado": (84, 128, (64, 122), 24, [
        ("idle", D("Pegaso_Dourado", 1), 6, True, {}), ("walk", D("Pegaso_Dourado", 2), 8, True, {}),
        ("run", D("Pegaso_Dourado", 3), 12, True, {}), ("fly", D("Pegaso_Dourado", 4), 10, True, {}),
        ("jump", D("Pegaso_Dourado", 5), 8, False, {}), ("attack", D("Pegaso_Dourado", 6), 10, False, {}),
        ("hurt", D("Pegaso_Dourado", 7), 10, False, {}), ("die", D("Pegaso_Dourado", 8), 6, False, {})]),
    "lobo_fantasma": (100, 144, (72, 138), 20, [
        ("idle", D("Lobo_Infernal", 1), 6, True, {}), ("walk", D("Lobo_Infernal", 2), 8, True, {}),
        ("run", D("Lobo_Infernal", 3), 12, True, {}), ("jump", D("Lobo_Infernal", 4), 8, False, {}),
        ("fall", D("Lobo_Infernal", 5), 8, False, {}), ("attack", D("Lobo_Infernal", 6), 12, False, {}),
        ("hurt", D("Lobo_Infernal", 7), 10, False, {}), ("die", D("Lobo_Infernal", 8), 8, False, {})]),
    "tronquinho": (24, 48, (24, 44), 16, [
        ("idle", D("Tronquinho_Magico", 1), 6, True, {"dil": 1, "no_split": True}), ("walk_right", D("Tronquinho_Magico", 2), 8, True, {"dil": 1, "no_split": True}),
        ("walk_left", D("Tronquinho_Magico", 3), 8, True, {"dil": 1, "no_split": True}), ("walk_up", D("Tronquinho_Magico", 4), 8, True, {"dil": 1, "no_split": True}),
        ("walk_down", D("Tronquinho_Magico", 5), 8, True, {"dil": 1, "no_split": True}), ("run_right", D("Tronquinho_Magico", 6), 12, True, {"dil": 1, "no_split": True}),
        ("run_left", D("Tronquinho_Magico", 7), 12, True, {"dil": 1, "no_split": True}), ("run_up", D("Tronquinho_Magico", 8), 12, True, {"dil": 1, "no_split": True}),
        ("run_down", D("Tronquinho_Magico", 9), 12, True, {"dil": 1, "no_split": True}), ("jump", D("Tronquinho_Magico", 10), 8, False, {"dil": 1, "no_split": True}),
        ("attack", D("Tronquinho_Magico", 11), 10, False, {"dil": 1, "no_split": True}), ("hurt", D("Tronquinho_Magico", 12), 10, False, {"dil": 1, "no_split": True}),
        ("die", D("Tronquinho_Magico", 13), 8, False, {"dil": 1, "no_split": True})]),
    "ovo_dourado": (18, 32, (16, 28), 14, [
        ("float", os.path.join(SRC, "item_golden_egg_float.png"), 8, True, {"checker": True}),
        ("spin", os.path.join(SRC, "item_golden_egg_spin.png"), 10, True, {"checker": True}),
        ("collect", os.path.join(SRC, "item_golden_egg_collect.png"), 8, False, {"checker": True})]),
    "saco_farinha": (16, 32, (16, 28), 14, [
        ("idle", os.path.join(SRC, "item_flour_sack_v2.png"), 4, True, {})]),
}


def load_alpha(path, opts):
    a = np.array(Image.open(path).convert("RGBA")).astype(np.int16)
    if opts.get("checker"):
        rgb = a[:, :, :3]
        sat = rgb.max(axis=2) - rgb.min(axis=2)
        lum = rgb.mean(axis=2)
        bg = ((sat < 40) & (lum > 120)) | (a[:, :, 3] < 60)
        bg |= (sat < 25) & (lum > 60) & (lum < 160)          # baked drop shadow
        a[:, :, 3] = np.where(bg, 0, 255)
    else:
        a[:, :, 3] = np.where(a[:, :, 3] < 128, 0, 255)
    return a


def find_frames(alpha, opts, ref_aspect=None):
    m = alpha > 0
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=opts.get("dil", 3 if opts.get("checker") else 6)))
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        area = int((m[sl] & (lab[sl] == i)).sum())
        if area < 150:
            continue
        boxes.append((sl[0].start, sl[0].stop, sl[1].start, sl[1].stop, i, area))
    if not boxes:
        return [], lab
    big = max(b[5] for b in boxes)
    boxes = [b for b in boxes if b[5] > big * 0.12]      # drop loose sparkles
    # Two neighbouring frames whose wings/tails touch get merged by the dilation:
    # split any blob much wider than the typical frame at its emptiest columns.
    if not opts.get("grid_dirs") and not opts.get("no_split") and (len(boxes) >= 2 or opts.get("pairs")):
        asp = sorted((b[3] - b[2]) / float(b[1] - b[0]) for b in boxes)
        # default: compare with this strip's own median frame; "pairs": every
        # frame of the strip is a merged pair, so compare with the idle frames
        ref = ref_aspect if (ref_aspect and opts.get("pairs")) else asp[len(asp) // 2]
        split = []
        for b in boxes:
            y0, y1, x0, x1, li, area = b
            a_ = (x1 - x0) / float(y1 - y0)
            n = min(8, int(round(a_ / ref)))
            if n >= 2 and a_ > 1.6 * ref:
                col = ((lab[y0:y1, x0:x1] == li) & m[y0:y1, x0:x1]).sum(axis=0).astype(float)
                w = x1 - x0
                cuts = []
                for k in range(1, n):
                    c = int(w * k / n)
                    lo, hi = max(1, c - w // (4 * n)), min(w - 1, c + w // (4 * n))
                    cuts.append(x0 + (lo + int(np.argmin(col[lo:hi])) if hi > lo else c))
                edges = [x0] + cuts + [x1]
                for i in range(n):
                    split.append((y0, y1, edges[i], edges[i + 1], li, area // n))
            else:
                split.append(b)
        boxes = split
    if opts.get("grid_dirs"):
        rowh = max(b[1] - b[0] for b in boxes)
        boxes.sort(key=lambda b: (round(b[0] / rowh), b[2]))
    else:
        boxes.sort(key=lambda b: b[2])
    return boxes, lab


def main(only=None):
    os.makedirs(PREV, exist_ok=True)
    for cid, (target, cell_sz, origin, k, anims) in CHARS.items():
        if only and cid not in only:
            continue
        frames = {}
        block = None
        ref_aspect = None
        for anim, path, fps, loop, opts in anims:
            if not os.path.exists(path):
                print("missing", path)
                continue
            a = load_alpha(path, opts)
            rgb = np.clip(a[:, :, :3], 0, 255).astype(np.uint8)
            alpha = a[:, :, 3]
            boxes, lab = find_frames(alpha, opts, ref_aspect)
            if ref_aspect is None and boxes:
                asp = sorted((b[3] - b[2]) / float(b[1] - b[0]) for b in boxes)
                ref_aspect = asp[len(asp) // 2]
            if block is None:   # the first animation (idle) fixes the scale for the whole character
                hs = sorted(b[1] - b[0] for b in boxes)
                block = hs[len(hs) // 2] / float(target)
            blk = block
            if opts.get("rescale"):   # drawn at a different scale in the source: match the idle size
                hs2 = sorted(b[1] - b[0] for b in boxes)
                blk = hs2[len(hs2) // 2] / (float(target) * opts["rescale"])
            out = []
            for (y0, y1, x0, x1, li, _) in boxes:
                sub = alpha[y0:y1, x0:x1].copy()
                sub[lab[y0:y1, x0:x1] != li] = 0
                ox, oy = best_offset(rgb[y0:y1, x0:x1], sub, blk)
                px = drop_specks(pixelate(rgb[y0:y1, x0:x1], sub, blk, ox, oy))
                out.append(px)
            frames[anim] = (out, fps, loop, opts)
        allc = np.concatenate([p[:, :, :3][p[:, :, 3] > 0] for (fr, *_r) in frames.values() for p in fr])
        pal = kmeans_palette(allc, k)
        W = SheetWriter(GEN, cid, cell_sz, cell_sz, origin=origin)
        prev = []
        for anim, (fr, fps, loop, opts) in frames.items():
            fr = [apply_palette(p, pal) for p in fr]
            prev.extend(fr[:4])
            cells = []
            for p in fr:
                c = Canvas(cell_sz, cell_sz)
                h, w = p.shape[:2]
                img = Image.fromarray(p)
                if h > cell_sz or w > cell_sz:
                    img.thumbnail((cell_sz, cell_sz), Image.NEAREST)
                    w, h = img.size
                c.img.paste(img, (origin[0] - w // 2, origin[1] - h), img)
                cells.append(c)
            if opts.get("grid_dirs"):
                per = max(1, len(cells) // opts["grid_dirs"])
                for di, dname in enumerate(("down", "left", "right", "up")):
                    part = cells[di * per:(di + 1) * per]
                    if part:
                        W.add(f"{anim}_{dname}", part, fps=fps, loop=loop)
                W.add(anim, cells[:per], fps=fps, loop=loop)
            else:
                W.add(anim, cells, fps=fps, loop=loop)
        W.meta["source"] = "artist"
        W.meta["generated"] = False
        W.close()
        contact(prev[:24], scale=3).save(os.path.join(PREV, f"strip_{cid}.png"))
        print(cid, {a: len(v[0]) for a, v in frames.items()}, "block=%.2f" % block)


if __name__ == "__main__":
    import sys
    main(sys.argv[1:] or None)
