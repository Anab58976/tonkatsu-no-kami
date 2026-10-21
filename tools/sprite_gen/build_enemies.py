"""Swamp enemies. Cogumelo agressivo comes from the artist's mushroom (single
frame -> derived squash/lean/flash animations). The others are drawn with the
rig in the artist's style (dark outline, chunky shading) until art arrives.
Anims for every enemy: idle, walk, attack (non-loop), hurt, die (non-loop)."""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image

from rig import Canvas, SheetWriter, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
INK = (40, 20, 19, 255)


def H(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def cell_from(arr, cell, foot, sx=1.0, sy=1.0, dx=0, dy=0, rot=0, tint=None, alpha=1.0):
    img = Image.fromarray(arr)
    if sx != 1.0 or sy != 1.0:
        img = img.resize((max(1, round(img.width * sx)), max(1, round(img.height * sy))), Image.NEAREST)
    if rot:
        img = img.rotate(rot, Image.NEAREST, expand=True)
    a = np.array(img)
    if tint is not None:
        m = a[:, :, 3] > 0
        for i in range(3):
            a[:, :, i][m] = (a[:, :, i][m] * (1 - tint[3]) + tint[i] * tint[3]).astype(np.uint8)
    if alpha < 1.0:
        a[:, :, 3] = (a[:, :, 3] * alpha).astype(np.uint8)
    img = Image.fromarray(a)
    c = Canvas(cell, cell)
    c.img.paste(img, (foot[0] - img.width // 2 + dx, foot[1] - img.height + dy), img)
    return c


def mushroom():
    src = np.array(Image.open(os.path.join(GEN, "mushroom", "idle.png")).convert("RGBA"))
    # first cell holds the artist frame (96 cell from build_strips? no: 'mushroom' came from build_from_refs)
    return src


def build_mushroom():
    path = os.path.join(ROOT, "assets", "sprites", "extracted", "mushroom", "idle_0.png")
    a = np.array(Image.open(path).convert("RGBA"))
    # shrink to gameplay size (~40 px tall)
    img = Image.fromarray(a)
    k = 40 / img.height
    a = np.array(img.resize((round(img.width * k), 40), Image.NEAREST))
    C, F = 64, (32, 60)
    W = SheetWriter(GEN, "cogumelo", C, C, origin=F)
    W.add("idle", [cell_from(a, C, F), cell_from(a, C, F, 1.04, 0.97), cell_from(a, C, F, 1.06, 0.95), cell_from(a, C, F, 1.03, 0.98)], fps=5)
    W.add("walk", [cell_from(a, C, F, rot=r, dy=-abs(r) // 3) for r in (0, 4, 0, -4)], fps=8)
    W.add("attack", [cell_from(a, C, F, 0.9, 1.08, dx=-2), cell_from(a, C, F, 1.15, 0.85, dx=4, rot=-10), cell_from(a, C, F, 1.1, 0.9, dx=3, rot=-6), cell_from(a, C, F)], fps=10, loop=False)
    W.add("hurt", [cell_from(a, C, F, tint=(255, 255, 255, 0.8)), cell_from(a, C, F, 1.05, 0.95)], fps=12, loop=False)
    W.add("die", [cell_from(a, C, F, 1.1, 0.8), cell_from(a, C, F, 1.2, 0.5, alpha=0.8), cell_from(a, C, F, 1.3, 0.25, alpha=0.5), cell_from(a, C, F, 1.3, 0.1, alpha=0.2)], fps=8, loop=False)
    W.close()


# ---------------------------------------------------------------- frog warrior
def frog(phase=0, attack=0, hurt=False):
    c = Canvas(48, 48)
    g, gd, gl, belly = H("5f9a3a"), H("3f6a2a"), H("8ac060"), H("e8d8a0")
    bob = [0, -1, 0, 1][phase % 4]
    by = 34 + bob
    # legs
    for s in (-1, 1):
        c.ellipse(24 + s * 7, 41, 5, 3, gd); c.ellipse(24 + s * 9, 43, 4, 2, g)
    # body + belly
    c.ellipse(24, by, 10, 8, gd); c.ellipse(24, by - 1, 9, 7, g); c.ellipse(24, by + 1, 6, 5, belly)
    # straw armour vest
    c.rect(15, by - 3, 33, by + 1, H("b88a3a")); c.rect(15, by - 3, 33, by - 3, H("d8aa5a"))
    # head with big eyes
    hy = by - 10
    c.ellipse(24, hy, 9, 6, g); c.ellipse(18, hy - 5, 3, 3, g); c.ellipse(30, hy - 5, 3, 3, g)
    c.rect(17, hy - 6, 18, hy - 4, INK); c.rect(29, hy - 6, 30, hy - 4, INK)
    c.px(17, hy - 6, (255, 255, 255, 255)); c.px(29, hy - 6, (255, 255, 255, 255))
    c.rect(19, hy + 2, 29, hy + 2, gd)
    c.rect(17, hy - 9, 31, hy - 8, H("c0392b"))                                   # headband
    # spear
    sx = 36 + attack * 4
    sy = by - 14 + attack * 2
    c.line(sx - 6, sy + 22, sx + 2, sy - 6 + attack * 6, H("8a5a2a"))
    c.poly([(sx + 1, sy - 7 + attack * 6), (sx + 5, sy - 12 + attack * 8), (sx + 3, sy - 4 + attack * 6)], H("d0d4dc"))
    c.ellipse(33, by - 2, 3, 3, gl)
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_frog():
    W = SheetWriter(GEN, "sapo_guerreiro", 48, 48, origin=(24, 45))
    W.add("idle", [frog(0), frog(1), frog(2), frog(3)], fps=4)
    W.add("walk", [frog(i) for i in range(4)], fps=8)
    W.add("attack", [frog(0, -1), frog(0, 2), frog(0, 3), frog(0, 0)], fps=10, loop=False)
    W.add("hurt", [frog(0, hurt=True), frog(1)], fps=12, loop=False)
    W.add("die", [_fade(frog(0), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


def _fade(c, k, squash=True):
    a = np.array(c.img)
    out = Canvas(c.w, c.h)
    img = Image.fromarray(a)
    if squash:
        img = img.resize((img.width, max(1, round(img.height * (0.4 + 0.6 * k)))), Image.NEAREST)
    arr = np.array(img)
    arr[:, :, 3] = (arr[:, :, 3] * k).astype(np.uint8)
    img = Image.fromarray(arr)
    out.img.paste(img, (0, c.h - img.height), img)
    return out


# ---------------------------------------------------------------- giant mosquito
def mosquito(phase=0, attack=0, hurt=False):
    c = Canvas(40, 40)
    y = 18 + [0, -1, -2, -1][phase % 4]
    wing = phase % 2
    for s in (-1, 1):
        if wing:
            c.ellipse(20 + s * 8, y - 6, 7, 3, (210, 230, 240, 200))
        else:
            c.ellipse(20 + s * 7, y - 2, 6, 4, (210, 230, 240, 200))
    c.ellipse(20, y, 5, 4, H("4a3a3a")); c.ellipse(14, y + 3, 7, 4, H("6a2a2a")); c.ellipse(13, y + 3, 5, 2, H("a03a3a"))
    c.ellipse(26, y - 1, 3, 3, H("3a2a2a")); c.px(27, y - 2, H("ff4040"))
    c.line(28, y, 34 + attack * 3, y + 3 + attack * 2, H("2a1a1a"))
    for i in range(3):
        c.line(18 + i * 3, y + 3, 16 + i * 3, y + 9, H("2a1a1a"))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    # shadow drawn by the engine
    return c


def build_mosquito():
    W = SheetWriter(GEN, "mosquito", 40, 40, origin=(20, 36))
    W.add("idle", [mosquito(i) for i in range(4)], fps=14)
    W.add("walk", [mosquito(i) for i in range(4)], fps=16)
    W.add("attack", [mosquito(0, 1), mosquito(1, 2), mosquito(2, 2), mosquito(3, 0)], fps=12, loop=False)
    W.add("hurt", [mosquito(0, hurt=True), mosquito(1)], fps=12, loop=False)
    W.add("die", [_fade(mosquito(0), k, False) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


# ---------------------------------------------------------------- carnivorous plant
def plant(open_=0.2, sway=0, hurt=False):
    c = Canvas(48, 48)
    stem = H("4a7a2a")
    hx, hy = 24 + sway, 18
    c.line(24, 44, hx, hy + 6, stem, 3)
    for s in (-1, 1):
        c.poly([(24, 42), (24 + s * 12, 36), (24 + s * 6, 44)], H("5f9a3a"))
    # head: two jaws
    gap = int(2 + open_ * 8)
    c.ellipse(hx, hy - gap // 2, 9, 5, H("b03a5a")); c.ellipse(hx, hy + gap // 2 + 2, 9, 5, H("8a2a4a"))
    c.rect(hx - 8, hy - gap // 2 + 2, hx + 8, hy + gap // 2, H("4a1020"))
    for i in range(-7, 8, 3):
        c.px(hx + i, hy - gap // 2 + 3, (250, 245, 230, 255)); c.px(hx + i + 1, hy + gap // 2 - 1, (250, 245, 230, 255))
    for (dx, dy) in ((-5, -4), (2, -5), (6, -2)):
        c.px(hx + dx, hy - gap // 2 + dy, H("f0d040"))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_plant():
    W = SheetWriter(GEN, "planta_carnivora", 48, 48, origin=(24, 45))
    W.add("idle", [plant(0.2, s) for s in (0, 1, 0, -1)], fps=4)
    W.add("walk", [plant(0.3, s) for s in (0, 1, 0, -1)], fps=6)
    W.add("attack", [plant(0.0, -2), plant(1.0, 3), plant(0.9, 3), plant(0.2, 0)], fps=10, loop=False)
    W.add("hurt", [plant(0.5, 0, True), plant(0.3, -1)], fps=12, loop=False)
    W.add("die", [_fade(plant(0.6), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


# ---------------------------------------------------------------- mud spirit (slime)
def slime(phase=0, attack=0, hurt=False):
    c = Canvas(40, 40)
    sq = [0, 1, 2, 1][phase % 4] + attack * 3
    w, h = 11 + sq, 9 - sq // 2
    base = 35
    c.ellipse(20, base - h, w, h, H("4a4a2a")); c.ellipse(20, base - h - 1, w - 1, h - 1, H("6a6a3a"))
    c.ellipse(16, base - h - 3, 3, 2, H("9a9a5a"))
    c.rect(15, base - h - 1, 16, base - h, (220, 255, 160, 255)); c.rect(23, base - h - 1, 24, base - h, (220, 255, 160, 255))
    for i in range(3):
        c.px(10 + i * 9, base - 1, H("3a3a1a"))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_slime():
    W = SheetWriter(GEN, "espirito_lodo", 40, 40, origin=(20, 37))
    W.add("idle", [slime(i) for i in range(4)], fps=5)
    W.add("walk", [slime(i) for i in range(4)], fps=8)
    W.add("attack", [slime(0, 1), slime(2, 2), slime(1, 0)], fps=8, loop=False)
    W.add("hurt", [slime(0, hurt=True), slime(1)], fps=12, loop=False)
    W.add("die", [_fade(slime(0), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


# ---------------------------------------------------------------- swamp crab
def crab(phase=0, attack=0, hurt=False):
    c = Canvas(40, 40)
    by = 30 + (phase % 2)
    for s in (-1, 1):
        for i in range(3):
            c.line(20 + s * (6 + i * 2), by + 1, 20 + s * (10 + i * 2), by + 6 - (phase + i) % 2, H("7a2a1a"))
    c.ellipse(20, by - 3, 11, 6, H("9a3a22")); c.ellipse(20, by - 4, 9, 4, H("c05a32")); c.ellipse(17, by - 6, 3, 1, H("e08a5a"))
    for s in (-1, 1):
        cx = 20 + s * (13 + attack * 2)
        c.ellipse(cx, by - 8 - attack * 2, 4, 4, H("b04a2a")); c.rect(cx - 1, by - 12 - attack * 3, cx + 1, by - 10 - attack * 2, H("4a1a10"))
        c.line(20 + s * 4, by - 8, 20 + s * 4, by - 11, H("4a1a10")); c.px(20 + s * 4, by - 12, (250, 250, 250, 255))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_crab():
    W = SheetWriter(GEN, "caranguejo", 40, 40, origin=(20, 37))
    W.add("idle", [crab(0), crab(0), crab(1), crab(1)], fps=4)
    W.add("walk", [crab(i) for i in range(4)], fps=10)
    W.add("attack", [crab(0, 1), crab(0, 2), crab(1, 0)], fps=10, loop=False)
    W.add("hurt", [crab(0, hurt=True), crab(1)], fps=12, loop=False)
    W.add("die", [_fade(crab(0), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


# ---------------------------------------------------------------- moss golem (artist) — mini-boss
def build_golem():
    path = os.path.join(ROOT, "assets", "sprites", "extracted", "moss_golem", "idle_0.png")
    a = np.array(Image.open(path).convert("RGBA"))
    C, F = 96, (48, 92)
    W = SheetWriter(GEN, "golem_musgo", C, C, origin=F)
    W.add("idle", [cell_from(a, C, F), cell_from(a, C, F, 1.02, 0.98), cell_from(a, C, F, 1.03, 0.97), cell_from(a, C, F, 1.01, 0.99)], fps=4)
    W.add("walk", [cell_from(a, C, F, rot=r, dy=-1 if r else 0) for r in (0, 2, 0, -2)], fps=5)
    W.add("attack", [cell_from(a, C, F, 0.95, 1.06), cell_from(a, C, F, 1.12, 0.88, dy=2), cell_from(a, C, F, 1.1, 0.9, dy=2), cell_from(a, C, F)], fps=6, loop=False)
    W.add("hurt", [cell_from(a, C, F, tint=(255, 255, 255, 0.75)), cell_from(a, C, F)], fps=12, loop=False)
    W.add("die", [cell_from(a, C, F, 1.05, 0.9), cell_from(a, C, F, 1.15, 0.6, alpha=0.8), cell_from(a, C, F, 1.25, 0.3, alpha=0.5), cell_from(a, C, F, 1.3, 0.1, alpha=0.2)], fps=6, loop=False)
    W.close()


if __name__ == "__main__":
    build_mushroom(); build_frog(); build_mosquito(); build_plant(); build_slime(); build_crab(); build_golem()
    print("enemies ok")


# ---------------------------------------------------------------- Golem de Pedra (swamp boss, team art)
def build_golem_boss():
    """Boss-scale golem (~96 px) from the team's moss/stone golem figure."""
    from build_from_refs import best_offset, pixelate, drop_specks, kmeans_palette, apply_palette
    from import_refs import load_rgba, remove_background
    from scipy import ndimage
    src = os.path.join(ROOT, "assets", "sprites", "source", "enemy_mushroom_golem.png")
    a = remove_background(load_rgba(src))
    x0, y0, x1, y1 = 822, 48, 1695, 857
    rgb = np.clip(a[y0:y1, x0:x1, :3], 0, 255).astype(np.uint8)
    al = a[y0:y1, x0:x1, 3].copy()
    lab, n = ndimage.label(ndimage.binary_dilation(al > 0, iterations=3))
    if n > 1:
        sizes = ndimage.sum(al > 0, lab, range(1, n + 1))
        al[lab != 1 + int(np.argmax(sizes))] = 0
    ys, xs = np.where(al > 0)
    s = (ys.max() - ys.min() + 1) / 96.0
    ox, oy = best_offset(rgb, al, s)
    g = drop_specks(pixelate(rgb, al, s, ox, oy))
    g = apply_palette(g, kmeans_palette(g[:, :, :3][g[:, :, 3] > 0], 20))
    C, F = 128, (64, 122)
    W = SheetWriter(GEN, "golem_pedra", C, C, origin=F)
    W.add("idle", [cell_from(g, C, F), cell_from(g, C, F, 1.02, 0.985), cell_from(g, C, F, 1.03, 0.975), cell_from(g, C, F, 1.01, 0.99)], fps=4)
    W.add("walk", [cell_from(g, C, F, rot=r, dx=r // 2, dy=-abs(r) // 2) for r in (0, 3, 0, -3)], fps=5)
    W.add("attack", [cell_from(g, C, F, 0.94, 1.06, dy=-4, rot=4), cell_from(g, C, F, 0.92, 1.08, dy=-8, rot=6),
                     cell_from(g, C, F, 1.14, 0.86, rot=-4), cell_from(g, C, F, 1.08, 0.92), cell_from(g, C, F)], fps=8, loop=False)
    W.add("hurt", [cell_from(g, C, F, tint=(255, 255, 255, 0.8)), cell_from(g, C, F, 1.03, 0.97)], fps=10, loop=False)
    W.add("die", [cell_from(g, C, F, 1.05, 0.95), cell_from(g, C, F, 1.1, 0.8, rot=-6), cell_from(g, C, F, 1.15, 0.55, alpha=0.8, rot=-6),
                  cell_from(g, C, F, 1.18, 0.3, alpha=0.5), cell_from(g, C, F, 1.2, 0.12, alpha=0.2)], fps=6, loop=False)
    W.meta["generated"] = False
    W.meta["source"] = "equipe (enemy_mushroom_golem.png), animações derivadas"
    W.close()
    print("golem_pedra", g.shape[:2])


if __name__ == "__main__" and "golem_boss" in __import__("sys").argv:
    build_golem_boss()
