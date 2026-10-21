"""Gameplay + cutscene animations for pig Lulu, built from the artist's frames.

Cell 48x48, feet anchored at (24, 45).
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

from rig import Canvas, SheetWriter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXT = os.path.join(ROOT, "assets", "sprites", "extracted", "lulu_pig")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
CELL = 48
FOOT = (24, 45)


def load(n):
    return np.array(Image.open(os.path.join(EXT, f"{n}.png")).convert("RGBA"))


def cell(a, dx=0, dy=0):
    c = Canvas(CELL, CELL)
    img = Image.fromarray(a)
    c.img.paste(img, (FOOT[0] - a.shape[1] // 2 + dx, FOOT[1] - a.shape[0] + dy), img)
    c.d = ImageDraw.Draw(c.img)
    return c


def feet_step(a, phase, start_frac=0.8):
    """Alternating feet: roll the bottom rows left/right by one pixel."""
    a = a.copy()
    h = a.shape[0]
    y0 = int(h * start_frac)
    w = a.shape[1]
    half = w // 2
    lower = a[y0:].copy()
    a[y0:] = 0
    left, right = lower[:, :half], lower[:, half:]
    dl, dr = ((0, 0), (0, 1), (0, 0), (1, 0))[phase]
    a[y0:, :half] = np.roll(left, -dl, axis=0) if dl else left
    a[y0:, half:] = np.roll(right, -dr, axis=0) if dr else right
    return a


def squash(a, sx=1.0, sy=1.0):
    h, w = a.shape[:2]
    img = Image.fromarray(a).resize((max(1, round(w * sx)), max(1, round(h * sy))), Image.NEAREST)
    return np.array(img)


SHEET = os.path.join(ROOT, "assets", "sprites", "extracted", "sheet_%s")


def sheet_frames(who, anim, d):
    out, i = [], 0
    while os.path.exists(os.path.join(SHEET % who, f"{anim}_{d}_{i}.png")):
        out.append(np.array(Image.open(os.path.join(SHEET % who, f"{anim}_{d}_{i}.png")).convert("RGBA")))
        i += 1
    return out


def cycle(fr):
    """3 frames -> 0,1,2,1 ; 2 frames -> 0,1 (walk cycles)."""
    return fr + fr[1:-1][::-1] if len(fr) >= 3 else fr


# The artist's sheet groups frames loosely under its DOWN/LEFT/RIGHT/UP labels;
# after inspection the real facing of each extracted frame is:
FACING = {
    "walk": {"left": [("walk", "down", 1), ("walk", "down", 2), ("walk", "left", 0)],
             "right": "mirror"},
    "run": {"left": [("run", "down", 1), ("run", "down", 2), ("run", "left", 0)],
            "right": "mirror"},
}


def frame(who, anim, d, i):
    return np.array(Image.open(os.path.join(SHEET % who, f"{anim}_{d}_{i}.png")).convert("RGBA"))


def steps(base):
    return [cell(base), cell(feet_step(base, 1), 0, -1), cell(base), cell(feet_step(base, 3), 0, -1)]


def build_game_set(W, who):
    """Gameplay animations in four real directions from the artist's sheet."""
    idle = {d: frame(who, "idle", d, 0) for d in ("down", "left", "right", "up")}
    for d in ("down", "left", "right", "up"):
        b = idle[d]
        W.add(f"idle_{d}", [cell(b), cell(b), cell(squash(b, 1.05, 0.96)), cell(squash(b, 1.05, 0.96))], fps=4)
        for anim, fps in (("walk", 8), ("run", 12)):
            if d in ("down", "up"):
                W.add(f"{anim}_{d}", steps(frame(who, anim, d, 0)), fps=fps)
            else:
                if FACING[anim][d] == "mirror":   # right-facing frames are mirrored left ones (consistent facing)
                    fr = [np.ascontiguousarray(frame(who, *k)[:, ::-1]) for k in FACING[anim]["left"]]
                else:
                    fr = [frame(who, *k) for k in FACING[anim][d]]
                W.add(f"{anim}_{d}", [cell(f, 0, -1 if i % 2 else 0) for i, f in enumerate(cycle(fr))], fps=fps)
        jd = {"down": ("down", 0), "up": ("up", 0), "left": ("left", 0), "right": ("right", 0)}[d]
        j = frame(who, "jump", *jd)
        W.add(f"dodge_{d}", [cell(squash(b, 1.12, 0.88)), cell(j, 0, -4), cell(j, 0, -2), cell(squash(b, 1.1, 0.9))],
              fps=14, loop=False)
        atk = frame(who, "attack", d, 0)
        W.add(f"attack_{d}", [cell(squash(atk, 0.95, 1.04)), cell(atk), cell(atk), cell(b)], fps=12, loop=False)
        hurt = frame(who, "hurt", d, 0)
        W.add(f"hurt_{d}", [cell(hurt), cell(hurt, 0, -1)], fps=10, loop=False)
    return idle["down"], idle["right"], idle["up"], idle["left"]


def main():
    W = SheetWriter(GEN, "lulu_pig_v1_small", CELL, CELL, origin=FOOT)   # superseded by build_lulu_pig_v2.py
    down, right, up, left = build_game_set(W, "pig")
    W.add("die", [cell(squash(down, 1.1, 0.9)), cell(np.rot90(down, -1).copy()), cell(np.rot90(down, -1).copy(), 0, 1)],
          fps=6, loop=False)
    # cutscene: fall, land, look around, spin, surprised hop, celebrate
    W.add("fall", [cell(squash(down, 0.9, 1.1)), cell(squash(down, 0.92, 1.08))], fps=6)
    W.add("land", [cell(squash(down, 1.25, 0.75)), cell(squash(down, 1.1, 0.9)), cell(squash(down, 0.95, 1.05)), cell(down)],
          fps=10, loop=False)
    W.add("look_paws", [cell(squash(down, 1.0, 0.94)), cell(squash(down, 1.0, 0.94)),
                        cell(squash(down, 1.0, 0.94), 1, 0), cell(squash(down, 1.0, 0.94), -1, 0)], fps=3)
    W.add("spin", [cell(down), cell(right), cell(up), cell(left), cell(down)], fps=8, loop=False)
    W.add("surprised", [cell(squash(down, 1.1, 0.9)), cell(squash(down, 0.9, 1.1), 0, -5), cell(down, 0, -3),
                        cell(squash(down, 1.1, 0.9)), cell(down)], fps=10, loop=False)
    W.add("celebrate", [cell(down), cell(squash(down, 0.9, 1.1), 0, -4), cell(down, 0, -2), cell(down)], fps=6)
    W.close()
    H = SheetWriter(GEN, "lulu_human_game", CELL, CELL, origin=FOOT)
    build_game_set(H, "human")
    H.close()
    print("lulu_pig anims:", list(W.meta["animations"].keys()))


if __name__ == "__main__":
    main()
