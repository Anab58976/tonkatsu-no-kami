"""Hi-res 'illustration then re-pixelate' renderer for characters without team art.

The team's sprites are detailed illustrations reduced to pixel art (chunky
cel-shading, dark outline, limited palette). To match that look, new characters
are painted here as shaded volumes at S x the final resolution, then reduced
to the game grid with the same palette + outline steps used for the team art.

Coordinates are given in FINAL pixels (floats); S only sets the paint quality.
"""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

INK = np.array([38, 18, 20], np.float32)


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)], np.float32)


def rot(pts, ang, pivot):
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    px, py = pivot
    return [(px + (x - px) * ca - (y - py) * sa, py + (x - px) * sa + (y - py) * ca) for x, y in pts]


def ellipse_pts(cx, cy, rx, ry, n=48, a0=0.0, a1=360.0):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
            for i in range(n + 1)]


class Illu:
    def __init__(self, w, h, S=6, light=(-0.55, -0.75, 0.75)):
        self.w, self.h, self.S = w, h, S
        self.rgb = np.zeros((h * S, w * S, 3), np.float32)
        self.a = np.zeros((h * S, w * S), np.float32)
        l = np.array(light, np.float32)
        self.light = l / np.linalg.norm(l)

    # ---------------------------------------------------------------- masks
    def _mask(self, kind, *args, width=1.0):
        m = Image.new("L", (self.w * self.S, self.h * self.S), 0)
        d = ImageDraw.Draw(m)
        S = self.S
        if kind == "poly":
            d.polygon([(x * S, y * S) for x, y in args[0]], fill=255)
        elif kind == "ellipse":
            cx, cy, rx, ry = args
            d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=255)
        elif kind == "line":
            pts = [(x * S, y * S) for x, y in args[0]]
            d.line(pts, fill=255, width=max(1, int(width * S)), joint="curve")
            r = width * S / 2
            for x, y in (pts[0], pts[-1]):
                d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        return np.array(m, np.float32) / 255.0

    # ---------------------------------------------------------------- paint
    def part(self, kind, *args, color="#ffffff", width=1.0, shade=1.0, bands=4, glow=0.0, flat=False, clip=None, rim=0.8,
             edge=0.7, tex=0.12, spec=True):
        """Paints one shaded volume. kind: poly / ellipse / line.
        edge: width (final px) of the dark coloured contour drawn at the part's
        border, so overlapping parts keep their shapes (team-art look);
        tex: organic variation of the shading bands; spec: small highlight."""
        m = self._mask(kind, *args, width=width)
        if clip is not None:
            m = m * clip
        if m.max() <= 0:
            return m
        base = hexc(color) if isinstance(color, str) else np.array(color, np.float32)
        if flat:
            tone = np.ones_like(m)
        else:
            ys, xs = np.nonzero(m > 0.5)
            if len(xs) == 0:
                return m
            x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            yy, xx = np.mgrid[0:m.shape[0], 0:m.shape[1]].astype(np.float32)
            u = (xx - (x0 + x1) / 2) / max(1.0, (x1 - x0) / 2)
            v = (yy - (y0 + y1) / 2) / max(1.0, (y1 - y0) / 2)
            nz = np.sqrt(np.clip(1 - u * u * 0.8 - v * v * 0.8, 0.05, 1))
            lam = np.clip(u * self.light[0] + v * self.light[1] + nz * self.light[2], 0, 1)
            if tex > 0:
                if not hasattr(self, "_noise"):
                    r = np.random.default_rng(11).standard_normal((m.shape[0] // self.S + 2, m.shape[1] // self.S + 2))
                    r = ndimage.gaussian_filter(r, 0.9)
                    self._noise = np.kron(r, np.ones((self.S, self.S)))[:m.shape[0], :m.shape[1]].astype(np.float32)
                lam = np.clip(lam + self._noise * tex, 0, 1)
            # cel bands
            lam = np.floor(lam * bands + 0.35) / bands
            tone = 0.52 + 0.66 * lam * shade + (1 - shade) * 0.3
            if spec:
                tone = np.where(lam >= 0.999, tone * 1.08, tone)
            # darker rim (one final pixel inside the edge) + coloured contour line
            dist = ndimage.distance_transform_edt(m > 0.5)
            tone = np.where(dist < self.S * 1.1, tone * rim, tone)
            if edge > 0:
                tone = np.where(dist < self.S * edge, 0.42, tone)
        col = np.clip(base[None, None, :] * tone[:, :, None] + glow * 60, 0, 255)
        self.rgb = self.rgb * (1 - m[:, :, None]) + col * m[:, :, None]
        self.a = np.maximum(self.a, m)
        return m

    def poly(self, pts, color, **k):
        return self.part("poly", pts, color=color, **k)

    def ellipse(self, cx, cy, rx, ry, color, **k):
        return self.part("ellipse", cx, cy, rx, ry, color=color, **k)

    def line(self, pts, color, width=1.0, **k):
        return self.part("line", pts, color=color, width=width, **k)

    def detail(self, kind, *args, color="#000000", width=1.0):
        """Flat detail (eyes, stripes, highlights)."""
        return self.part(kind, *args, color=color, width=width, flat=True)

    # ---------------------------------------------------------------- reduce
    def pixels(self, palette=None, outline=True):
        S = self.S
        h, w = self.h, self.w
        a = self.a.reshape(h, S, w, S).mean(axis=(1, 3))
        rgb = (self.rgb * self.a[:, :, None]).reshape(h, S, w, S, 3).sum(axis=(1, 3))
        rgb = rgb / np.maximum(1e-6, self.a.reshape(h, S, w, S).sum(axis=(1, 3)))[:, :, None]
        on = a > 0.45
        out = np.zeros((h, w, 4), np.uint8)
        out[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
        out[:, :, 3] = np.where(on, 255, 0)
        if palette is not None:
            out = apply_pal(out, palette)
        if outline:
            out = ink_outline(out)
        return out


def ink_outline(px):
    a = px[:, :, 3] > 0
    ring = ndimage.binary_dilation(a, structure=np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]])) & ~a
    out = px.copy()
    out[ring, :3] = INK.astype(np.uint8)
    out[ring, 3] = 255
    # darken the inner edge where it borders the outline (chunky team look)
    return out


def apply_pal(px, pal):
    out = px.copy()
    m = px[:, :, 3] > 0
    c = px[:, :, :3][m].astype(np.float32)
    d = ((c[:, None, :] - pal[None, :, :]) ** 2).sum(axis=2)
    out[:, :, :3][m] = pal[np.argmin(d, axis=1)].astype(np.uint8)
    return out


def palette_from(frames, k=22):
    from build_from_refs import kmeans_palette
    cols = np.concatenate([f[:, :, :3][f[:, :, 3] > 0] for f in frames])
    return kmeans_palette(cols, k).astype(np.float32)
