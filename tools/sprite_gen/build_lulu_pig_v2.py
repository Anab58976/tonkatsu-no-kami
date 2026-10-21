"""Pig Lulu v2 — gameplay sprite at the size standard (~40 px), rebuilt from the
team's high-resolution sheet (assets/sprites/source/lulu_pig_sheet.jpg).

Why v2: v1 used the small 4-direction sheet (≈22 px, too small next to the
world) and one of its frames (attack right) contained TWO pigs, which showed up
in game as Lulu "duplicating" during attacks.

Facing in the team's sheet (verified by eye):
  turnaround: 1 = front (down) · 2 = facing LEFT · 3 = back (up) · 4 = facing RIGHT
  walk cycle (6 frames): facing RIGHT  -> left walk = horizontal mirror
Every animation name ends in its real facing: *_down, *_left, *_right, *_up.
The spatula is drawn as part of the attack frames (always in the front hand).

Output: assets/sprites/generated/lulu_pig/ (cell 64x64, feet at (32, 60))
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

from build_from_refs import best_offset, pixelate, drop_specks, kmeans_palette, apply_palette
from import_refs import load_rgba, remove_background
from rig import Canvas, SheetWriter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source", "lulu_pig_sheet.jpg")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
EXT = os.path.join(ROOT, "assets", "sprites", "extracted", "lulu_pig_v2")
CELL = 64
FOOT = (32, 60)
H = 40          # visible height standard for the protagonist

BOXES = {
    "front": (371, 518, 542, 807), "left": (552, 523, 700, 807), "back": (714, 523, 877, 807), "right": (895, 523, 1038, 807),
    **{f"walk{i}": b for i, b in enumerate([(215, 895, 329, 1104), (362, 894, 475, 1103), (515, 895, 626, 1104),
                                            (660, 896, 771, 1104), (802, 896, 913, 1104), (935, 896, 1049, 1104)])},
    "heart": (1069, 894, 1203, 1104),
    "spatula": (1150, 623, 1211, 725),
}
TARGET = {"spatula": 15}


def extract():
    a = remove_background(load_rgba(SRC))
    rgb = np.clip(a[:, :, :3], 0, 255).astype(np.uint8)
    alpha = a[:, :, 3]
    out = {}
    from scipy import ndimage
    for name, (x0, y0, x1, y1) in BOXES.items():
        sub = alpha[y0:y1, x0:x1].copy()
        lab, n = ndimage.label(ndimage.binary_dilation(sub > 0, iterations=3))
        if n > 1:   # keep the main figure (drops the floating heart, neighbours' slivers)
            sizes = ndimage.sum(sub > 0, lab, range(1, n + 1))
            sub[lab != 1 + int(np.argmax(sizes))] = 0
        ys, xs = np.where(sub > 0)
        h_src = ys.max() - ys.min() + 1
        s = h_src / float(TARGET.get(name, H))
        ox, oy = best_offset(rgb[y0:y1, x0:x1], sub, s)
        out[name] = drop_specks(pixelate(rgb[y0:y1, x0:x1], sub, s, ox, oy))
    pal = kmeans_palette(np.concatenate([p[:, :, :3][p[:, :, 3] > 0] for p in out.values()]), 22)
    os.makedirs(EXT, exist_ok=True)
    for k in out:
        out[k] = apply_palette(out[k], pal)
        Image.fromarray(out[k]).save(os.path.join(EXT, f"{k}.png"))
    return out


# ------------------------------------------------------------------ helpers
def cell(a, dx=0, dy=0, layers=()):
    c = Canvas(CELL, CELL)
    img = Image.fromarray(a)
    x = FOOT[0] - a.shape[1] // 2 + dx
    y = FOOT[1] - a.shape[0] + dy
    for (lay, lx, ly, behind) in layers:
        if behind:
            li = Image.fromarray(lay)
            c.img.paste(li, (x + lx, y + ly), li)
    c.img.paste(img, (x, y), img)
    for (lay, lx, ly, behind) in layers:
        if not behind:
            li = Image.fromarray(lay)
            c.img.paste(li, (x + lx, y + ly), li)
    c.d = ImageDraw.Draw(c.img)
    return c


def mirror(a):
    return np.ascontiguousarray(a[:, ::-1])


def squash(a, sx=1.0, sy=1.0):
    h, w = a.shape[:2]
    return np.array(Image.fromarray(a).resize((max(1, round(w * sx)), max(1, round(h * sy))), Image.NEAREST))


def feet_step(a, phase, lift=2):
    """Front/back walk: lift one foot (bottom rows of one half) by `lift` pixels."""
    a = a.copy()
    h, w = a.shape[:2]
    y0 = int(h * 0.86)
    half = w // 2
    lower = a[y0:].copy()
    cols = slice(0, half) if phase == 1 else slice(half, w) if phase == 3 else None
    if cols is None:
        return a
    a[y0:, cols] = 0
    a[y0 - lift:h - lift, cols] = np.where(lower[:, cols, 3:4] > 0, lower[:, cols], a[y0 - lift:h - lift, cols])
    return a


def side_cycle(base, walks, split=31):
    """Side walk with a steady body: the head, hat and apron come from the clean
    side view (`base`) in every frame and only the legs (rows >= split) come
    from the team's walk frames. Each walk frame was pixelated on its own, so
    using them whole made the hat and face flicker frame to frame (Lulu looked
    like she was "melting" while walking)."""
    def centre(a, r0, r1):
        xs = np.where(a[r0:r1, :, 3] > 0)[1]
        return xs.mean()
    hb = base.shape[0]
    out = []
    for w in walks:
        hw = w.shape[0]
        width = max(base.shape[1], w.shape[1]) + 4
        f = np.zeros((hb, width, 4), np.uint8)
        bx = (width - base.shape[1]) // 2
        f[:split, bx:bx + base.shape[1]] = base[:split]
        # legs: align the walk frame's body centre with the base body centre
        dx = int(round(centre(base, 8, split) + bx - centre(w, 8, split)))
        legs = w[split - (hb - hw):] if hw != hb else w[split:]
        for yy in range(legs.shape[0]):
            ty = split + yy
            if ty >= hb:
                break
            for xx in range(legs.shape[1]):
                tx = xx + dx
                if 0 <= tx < width and legs[yy, xx, 3] > 0:
                    f[ty, tx] = legs[yy, xx]
        # keep the base's own pixels in the leg rows where the walk frame has none
        # next to the body (apron hem), so the outline stays closed
        for ty in range(split, hb):
            for xx in range(base.shape[1]):
                if f[ty, bx + xx, 3] == 0 and base[ty, xx, 3] > 0 and ty < split + 2:
                    f[ty, bx + xx] = base[ty, xx]
        xs = np.where(f[:, :, 3] > 0)[1]
        x1 = xs.max() + 1
        if (x1 - xs.min()) % 2:      # even width: the mirrored (left) frame lands on the same pixels
            x1 += 1
        out.append(np.ascontiguousarray(f[:, xs.min():x1]))
    return out


def tint(a, col=(255, 255, 255), k=0.7):
    out = a.copy().astype(np.float32)
    m = out[:, :, 3] > 0
    for i in range(3):
        out[:, :, i][m] = out[:, :, i][m] * (1 - k) + col[i] * k
    return out.astype(np.uint8)


def rot(a, deg):
    return np.array(Image.fromarray(a).rotate(deg, Image.NEAREST, expand=True))


# ------------------------------------------------------------------ build
def main():
    f = extract()
    front, left, back, right = f["front"], f["left"], f["back"], f["right"]
    walk_r = side_cycle(right, [f[f"walk{i}"] for i in range(6)])
    walk_l = [mirror(w) for w in walk_r]
    spat = f["spatula"]
    views = {"down": front, "left": left, "up": back, "right": right}
    W = SheetWriter(GEN, "lulu_pig", CELL, CELL, origin=FOOT)

    for d, base in views.items():
        W.add(f"idle_{d}", [cell(base), cell(base), cell(squash(base, 1.04, 0.975)), cell(squash(base, 1.04, 0.975))], fps=4)
    # walking: real side cycle (right) + mirror (left); stepping for front/back
    W.add("walk_right", [cell(w, 0, -1 if i in (1, 4) else 0) for i, w in enumerate(walk_r)], fps=12)
    W.add("walk_left", [cell(w, 0, -1 if i in (1, 4) else 0) for i, w in enumerate(walk_l)], fps=12)
    for d in ("down", "up"):
        b = views[d]
        W.add(f"walk_{d}", [cell(b), cell(feet_step(b, 1), 0, -1), cell(b), cell(feet_step(b, 3), 0, -1)], fps=9)
    # running: same cycles, faster, a forward lean (1 px) and bigger bob
    W.add("run_right", [cell(w, 1, -2 if i in (1, 4) else 0) for i, w in enumerate(walk_r)], fps=16)
    W.add("run_left", [cell(w, -1, -2 if i in (1, 4) else 0) for i, w in enumerate(walk_l)], fps=16)
    for d in ("down", "up"):
        b = views[d]
        W.add(f"run_{d}", [cell(b), cell(feet_step(b, 1), 0, -2), cell(b), cell(feet_step(b, 3), 0, -2)], fps=12)

    # attack: the spatula is held in the FRONT hand and swung (raise -> strike -> follow -> rest)
    sw, sh = spat.shape[1], spat.shape[0]

    def attack_frames(base, d):
        bw, bh = base.shape[1], base.shape[0]
        hand = {"down": (bw - 6, bh // 2 + 2), "right": (bw - 5, bh // 2 + 2), "left": (2, bh // 2 + 2), "up": (bw - 7, bh // 2)}[d]
        poses = {  # (rotation, dx, dy, body lean dx, dy, behind?)
            "down": [(150, -2, -14, 0, 0, False), (60, 0, -4, 0, 1, False), (-20, -2, 4, 0, 1, False), (90, -4, -8, 0, 0, False)],
            "right": [(150, -6, -14, -1, 0, True), (60, 2, -6, 1, 0, False), (-30, 4, 2, 2, 0, False), (90, -2, -8, 0, 0, False)],
            "left": [(-150, -6, -14, 1, 0, True), (-60, -10, -6, -1, 0, False), (30, -12, 2, -2, 0, False), (-90, -6, -8, 0, 0, False)],
            "up": [(150, -2, -16, 0, 0, True), (60, 0, -10, 0, -1, True), (-20, -2, -6, 0, -1, True), (90, -4, -10, 0, 0, True)],
        }[d]
        out = []
        for (r, dx, dy, lx, ly, behind) in poses:
            sp = rot(spat if d != "left" else mirror(spat), r)
            ox = hand[0] + dx - sp.shape[1] // 2 + sp.shape[1] // 3
            oy = hand[1] + dy - sp.shape[0] // 2 + sp.shape[0] // 3
            out.append(cell(base, lx, ly, layers=[(sp, ox, oy, behind)]))
        return out

    for d, base in views.items():
        W.add(f"attack_{d}", attack_frames(base, d), fps=14, loop=False)
        W.add(f"dodge_{d}", [cell(squash(base, 1.12, 0.88)), cell(squash(base, 0.92, 1.06), 0, -6), cell(base, 0, -4),
                             cell(squash(base, 1.1, 0.9))], fps=14, loop=False)
        W.add(f"hurt_{d}", [cell(tint(base, (255, 255, 255), 0.75)), cell(base, 0, -1)], fps=10, loop=False)
        W.add(f"interact_{d}", [cell(base), cell(squash(base, 1.0, 0.96)), cell(base)], fps=8, loop=False)

    W.add("die", [cell(squash(front, 1.1, 0.9)), cell(rot(front, -90)), cell(rot(front, -90), 0, 1)], fps=6, loop=False)
    W.add("victory", [cell(front), cell(squash(front, 0.92, 1.08), 0, -6), cell(f["heart"], 0, -3), cell(front)], fps=6)
    W.add("portal_enter", [cell(front), cell(squash(front, 0.85, 1.12), 0, -2), cell(squash(front, 0.6, 1.2), 0, -6),
                           cell(squash(front, 0.3, 1.25), 0, -6)], fps=10, loop=False)
    # cutscene set (names used by the intro / HUB arrival)
    W.add("fall", [cell(squash(front, 0.9, 1.1)), cell(squash(front, 0.92, 1.08))], fps=6)
    W.add("land", [cell(squash(front, 1.25, 0.75)), cell(squash(front, 1.1, 0.9)), cell(squash(front, 0.95, 1.05)), cell(front)],
          fps=10, loop=False)
    W.add("look_paws", [cell(squash(front, 1.0, 0.95)), cell(squash(front, 1.0, 0.95)), cell(squash(front, 1.0, 0.95), 1, 0),
                        cell(squash(front, 1.0, 0.95), -1, 0)], fps=3)
    W.add("spin", [cell(front), cell(right), cell(back), cell(left), cell(front)], fps=8, loop=False)
    W.add("surprised", [cell(squash(front, 1.1, 0.9)), cell(squash(front, 0.9, 1.1), 0, -6), cell(front, 0, -3),
                        cell(squash(front, 1.1, 0.9)), cell(front)], fps=10, loop=False)
    W.add("celebrate", [cell(front), cell(squash(front, 0.9, 1.1), 0, -5), cell(f["heart"], 0, -2), cell(front)], fps=6)
    W.meta["source"] = "equipe (lulu_pig_sheet.jpg), re-pixelizada"
    W.close()
    print("lulu_pig v2:", {k: v.shape[:2] for k, v in f.items()})


if __name__ == "__main__":
    main()
