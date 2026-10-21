"""Minimal pixel-art rig used to generate TEMPORARY sprites for Tonkatsu no Kami.

Everything here draws hard-edged pixels (no anti-aliasing) on an RGBA canvas,
then applies a selective outline so the result reads as hand-made pixel art.
The generated sheets are replaced automatically when the artist's own sprites
are dropped into res://assets/sprites/characters/<id>/ (see SpriteLibrary.gd).
"""
from __future__ import annotations

import json
import math
import os
from PIL import Image, ImageDraw
import numpy as np

CELL = 64


def hexc(h: str, a: int = 255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def shade(c, f):
    """Multiply rgb by f (f<1 darker, f>1 lighter)."""
    return tuple(max(0, min(255, int(round(v * f)))) for v in c[:3]) + (c[3] if len(c) > 3 else 255,)


class Canvas:
    def __init__(self, w=CELL, h=CELL):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.w, self.h = w, h

    # ---- primitives -------------------------------------------------------
    def px(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), c)

    def rect(self, x0, y0, x1, y1, c):
        x0, x1 = min(x0, x1), max(x0, x1)
        y0, y1 = min(y0, y1), max(y0, y1)
        self.d.rectangle([int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))], fill=c)

    def ellipse(self, cx, cy, rx, ry, c):
        self.d.ellipse([int(round(cx - rx)), int(round(cy - ry)), int(round(cx + rx)), int(round(cy + ry))], fill=c)

    def poly(self, pts, c):
        self.d.polygon([(int(round(x)), int(round(y))) for x, y in pts], fill=c)

    def line(self, x0, y0, x1, y1, c, w=1):
        self.d.line([int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))], fill=c, width=w)

    def limb(self, x0, y0, x1, y1, c, w=3):
        """Thick limb with rounded ends."""
        self.line(x0, y0, x1, y1, c, w)
        r = (w - 1) / 2
        self.ellipse(x0, y0, r, r, c)
        self.ellipse(x1, y1, r, r, c)

    def shaded_ellipse(self, cx, cy, rx, ry, c, light=(-1, -1)):
        """Base ellipse + darker crescent on the side opposite the light + highlight."""
        self.ellipse(cx, cy, rx, ry, shade(c, 0.78))
        self.ellipse(cx + light[0] * 0.8, cy + light[1] * 0.8, rx - 0.8, ry - 0.8, c)
        if rx > 3 and ry > 3:
            self.ellipse(cx + light[0] * rx * 0.45, cy + light[1] * ry * 0.45, max(1, rx * 0.25), max(1, ry * 0.2), shade(c, 1.12))

    # ---- post ------------------------------------------------------------
    def outline(self, color=None, selective=True):
        a = np.array(self.img)
        alpha = a[:, :, 3] > 0
        out = a.copy()
        h, w = alpha.shape
        for y in range(h):
            for x in range(w):
                if alpha[y, x]:
                    continue
                nb = []
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and alpha[ny, nx]:
                        nb.append(a[ny, nx])
                if nb:
                    if color is not None and not selective:
                        out[y, x] = color
                    else:
                        base = nb[0]
                        col = shade(tuple(int(v) for v in base), 0.35)
                        if color is not None:
                            col = color
                        out[y, x] = (col[0], col[1], col[2], 255)
        self.img = Image.fromarray(out)
        self.d = ImageDraw.Draw(self.img)

    def paste(self, other: "Canvas", ox=0, oy=0):
        self.img.alpha_composite(other.img, (ox, oy))
        self.d = ImageDraw.Draw(self.img)

    def flipped(self):
        c = Canvas(self.w, self.h)
        c.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        c.d = ImageDraw.Draw(c.img)
        return c

    def tint_silhouette(self, col, amount=1.0):
        """Mix every opaque pixel toward `col` (used for magic glow frames)."""
        a = np.array(self.img).astype(np.float32)
        m = a[:, :, 3] > 0
        for i in range(3):
            a[:, :, i][m] = a[:, :, i][m] * (1 - amount) + col[i] * amount
        self.img = Image.fromarray(a.clip(0, 255).astype(np.uint8))
        self.d = ImageDraw.Draw(self.img)


def sheet(frames: list[Canvas], cell_w=CELL, cell_h=CELL) -> Image.Image:
    img = Image.new("RGBA", (cell_w * len(frames), cell_h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        img.alpha_composite(f.img, (i * cell_w, 0))
    return img


class SheetWriter:
    """Writes one PNG strip per animation + an anims.json manifest the engine reads."""

    def __init__(self, out_dir: str, char_id: str, cell_w=CELL, cell_h=CELL, origin=(32, 60)):
        self.dir = os.path.join(out_dir, char_id)
        os.makedirs(self.dir, exist_ok=True)
        self.meta = {"id": char_id, "cell_w": cell_w, "cell_h": cell_h,
                     "origin": list(origin), "generated": True, "animations": {}}
        self.cell_w, self.cell_h = cell_w, cell_h

    def add(self, name: str, frames: list[Canvas], fps: float = 8, loop: bool = True):
        path = os.path.join(self.dir, f"{name}.png")
        sheet(frames, self.cell_w, self.cell_h).save(path)
        self.meta["animations"][name] = {"file": f"{name}.png", "frames": len(frames), "fps": fps, "loop": loop}

    def close(self):
        with open(os.path.join(self.dir, "anims.json"), "w") as f:
            json.dump(self.meta, f, indent=2)


def lerp(a, b, t):
    return a + (b - a) * t


def wave(i, n, amp=1.0, phase=0.0):
    return math.sin((i / n) * math.tau + phase) * amp
