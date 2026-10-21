"""Ghost City assets: artist ghost -> 'espirito_errante' anims; generated
ghost-city enemies + the Samurai das Mil Almas boss; night ground tiles and
extra night prop names."""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

from rig import Canvas, SheetWriter, shade
from build_enemies import _fade, H
from build_ground import seamless, variants, OUT as GROUND_OUT
from build_props import trim

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
EXT = os.path.join(ROOT, "assets", "sprites", "extracted")
PROPS = os.path.join(ROOT, "assets", "sprites", "props")
INK = (40, 20, 19, 255)
GH = (24, 40, 64, 255)       # ghostly outline


def place(arr, cell, foot):
    c = Canvas(cell, cell)
    img = Image.fromarray(arr)
    c.img.paste(img, (foot[0] - img.width // 2, foot[1] - img.height), img)
    return c


def ghost():
    g = lambda n: np.array(Image.open(os.path.join(EXT, "ghost", n + ".png")).convert("RGBA"))
    C, F = 48, (24, 42)
    W = SheetWriter(GEN, "espirito_errante", C, C, origin=F)
    W.add("idle", [place(g(f"idle_{i}"), C, F) for i in range(4)], fps=6)
    W.add("walk", [place(g(f"walk_r_{i}"), C, F) for i in range(4)], fps=8)
    W.add("attack", [place(g("attack_0"), C, F), place(g("attack_1"), C, F), place(g("attack_3"), C, F)], fps=8, loop=False)
    W.add("hurt", [place(g(f"hurt_{i}"), C, F) for i in range(4)], fps=12, loop=False)
    W.add("die", [place(g(f"die_{i}"), C, F) for i in range(3)] + [_fade(place(g("die_2"), C, F), 0.3, False)], fps=8, loop=False)
    W.meta["generated"] = False
    W.meta["source"] = "artist"
    W.meta["faces_left"] = False
    W.close()


def samurai(c, cx, base, scale=1.0, phase=0, attack=0, hurt=False, ghostly=True, armor="3a4a7a", trim_="c0d8ff"):
    """Armoured ghost samurai (scale 1 ~ 32px tall)."""
    s = scale
    A, Ad, T = H(armor), shade(H(armor), 0.7), H(trim_)
    bob = [0, -1, 0, 1][phase % 4] * s
    y = base + bob
    # ghostly tail instead of legs
    if ghostly:
        c.poly([(cx - 7 * s, y - 10 * s), (cx + 7 * s, y - 10 * s), (cx + 3 * s, y), (cx - 1 * s, y - 3 * s), (cx - 5 * s, y)], (150, 200, 255, 180))
    else:
        c.rect(cx - 6 * s, y - 9 * s, cx - 2 * s, y, Ad); c.rect(cx + 2 * s, y - 9 * s, cx + 6 * s, y, Ad)
    # body armour (do) + skirt plates
    c.rect(cx - 9 * s, y - 22 * s, cx + 9 * s, y - 9 * s, A)
    for i in range(3):
        c.rect(cx - 9 * s, y - (18 - i * 4) * s, cx + 9 * s, y - (18 - i * 4) * s, T)
    c.rect(cx - 11 * s, y - 24 * s, cx - 6 * s, y - 18 * s, Ad); c.rect(cx + 6 * s, y - 24 * s, cx + 11 * s, y - 18 * s, Ad)   # sode
    # head: mempo mask + kabuto with crest
    c.ellipse(cx, y - 28 * s, 6 * s, 6 * s, (60, 70, 90, 255))
    c.rect(cx - 4 * s, y - 27 * s, cx + 4 * s, y - 24 * s, (180, 40, 50, 255))
    c.px(cx - 2 * s, y - 29 * s, (200, 240, 255, 255)); c.px(cx + 2 * s, y - 29 * s, (200, 240, 255, 255))
    c.ellipse(cx, y - 32 * s, 8 * s, 4 * s, Ad)
    c.poly([(cx - 6 * s, y - 34 * s), (cx - 9 * s, y - 42 * s), (cx - 3 * s, y - 35 * s)], (240, 200, 80, 255))
    c.poly([(cx + 6 * s, y - 34 * s), (cx + 9 * s, y - 42 * s), (cx + 3 * s, y - 35 * s)], (240, 200, 80, 255))
    # katana
    if attack == 0:      # sheathed / ready
        c.line(cx + 6 * s, y - 12 * s, cx + 16 * s, y - 20 * s, (210, 220, 235, 255), max(1, int(s)))
    elif attack == 1:    # raised
        c.line(cx + 8 * s, y - 22 * s, cx + 6 * s, y - 44 * s, (230, 240, 255, 255), max(1, int(s)))
    else:                # slash forward
        c.line(cx + 8 * s, y - 18 * s, cx + 28 * s, y - 12 * s, (240, 250, 255, 255), max(1, int(s * 1.2)))
        for k in range(6):
            c.px(cx + (12 + k * 3) * s, y - (26 - k * 2) * s, (180, 220, 255, 200))
    c.outline(color=GH if ghostly else INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    if ghostly:
        a = np.array(c.img)
        a[:, :, 3] = (a[:, :, 3] * 0.85).astype(np.uint8)
        c.img = Image.fromarray(a)
    return c


def ghost_samurai():
    def fr(**k):
        c = Canvas(48, 48)
        return samurai(c, 22, 44, 1.0, **k)
    W = SheetWriter(GEN, "samurai_fantasma", 48, 48, origin=(22, 44))
    W.add("idle", [fr(phase=i) for i in range(4)], fps=5)
    W.add("walk", [fr(phase=i) for i in range(4)], fps=8)
    W.add("attack", [fr(attack=1), fr(attack=2), fr(attack=2), fr(attack=0)], fps=10, loop=False)
    W.add("hurt", [fr(hurt=True), fr(phase=1)], fps=12, loop=False)
    W.add("die", [_fade(fr(), k, False) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


def possessed_armor():
    def fr(**k):
        c = Canvas(48, 48)
        return samurai(c, 22, 44, 1.0, ghostly=False, armor="6a3a2a", trim_="f0be3c", **k)
    W = SheetWriter(GEN, "armadura_possuida", 48, 48, origin=(22, 44))
    W.add("idle", [fr(phase=0), fr(phase=0), fr(phase=1), fr(phase=1)], fps=3)
    W.add("walk", [fr(phase=i) for i in range(4)], fps=6)
    W.add("attack", [fr(attack=1), fr(attack=1), fr(attack=2), fr(attack=0)], fps=7, loop=False)
    W.add("hurt", [fr(hurt=True), fr()], fps=12, loop=False)
    W.add("die", [_fade(fr(), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


def puppet(phase=0, attack=0, hurt=False):
    c = Canvas(40, 40)
    y = 34 + [0, -2, 0, -1][phase % 4]
    sw = [0, 2, 0, -2][phase % 4]
    for x in (14, 26):
        c.line(x, 0, x + sw // 2, y - 20, (200, 200, 220, 160))            # strings
    c.rect(17 + sw // 2, y - 9, 18, y, H("e8d8c0")); c.rect(22 + sw // 2, y - 9, 23, y, H("e8d8c0"))
    c.poly([(14, y - 22), (26, y - 22), (28, y - 8), (12, y - 8)], H("7a2a4a"))
    c.rect(13, y - 15, 27, y - 14, H("f0be3c"))
    c.ellipse(20, y - 27, 6, 6, H("f0e6d8"))
    c.rect(17, y - 28, 18, y - 27, INK); c.rect(22, y - 28, 23, y - 27, INK); c.rect(18, y - 24, 22, y - 24, H("c0392b"))
    c.ellipse(20, y - 33, 7, 3, INK)
    arm = 6 + attack * 6
    c.line(14, y - 20, 14 - arm, y - 16 - attack * 4, H("e8d8c0"), 2); c.line(26, y - 20, 26 + arm, y - 16 - attack * 4, H("e8d8c0"), 2)
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_puppet():
    W = SheetWriter(GEN, "marionete", 40, 40, origin=(20, 36))
    W.add("idle", [puppet(i) for i in range(4)], fps=5)
    W.add("walk", [puppet(i) for i in range(4)], fps=9)
    W.add("attack", [puppet(0, 1), puppet(1, 2), puppet(0, 0)], fps=9, loop=False)
    W.add("hurt", [puppet(0, hurt=True), puppet(1)], fps=12, loop=False)
    W.add("die", [_fade(puppet(0), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


def crow(phase=0, attack=0, hurt=False):
    c = Canvas(40, 40)
    y = 20 + [0, -2, -3, -1][phase % 4]
    wing = phase % 2
    body, wingc = H("2a2a3a"), H("3a3a5a")
    if wing:
        c.poly([(12, y), (2, y - 8), (14, y - 3)], wingc); c.poly([(26, y), (38, y - 8), (24, y - 3)], wingc)
    else:
        c.poly([(12, y), (3, y + 6), (15, y + 3)], wingc); c.poly([(26, y), (37, y + 6), (23, y + 3)], wingc)
    c.ellipse(19, y, 7, 5, body); c.ellipse(27, y - 3, 4, 4, body)
    c.poly([(30, y - 3), (36 + attack * 2, y - 1), (30, y - 1)], H("d0a030"))
    c.px(28, y - 4, H("80d0ff")); c.px(27, y - 4, H("ffffff"))
    c.poly([(12, y + 1), (6, y + 4), (12, y + 4)], body)
    for i in range(3):
        c.px(10 + i * 4, y - 7 - i % 2, (140, 200, 255, 200))
    c.outline(color=INK, selective=False)
    if hurt:
        c.tint_silhouette((255, 255, 255), 0.75)
    return c


def build_crow():
    W = SheetWriter(GEN, "corvo_espectral", 40, 40, origin=(20, 36))
    W.add("idle", [crow(i) for i in range(4)], fps=10)
    W.add("walk", [crow(i) for i in range(4)], fps=12)
    W.add("attack", [crow(0, 1), crow(1, 2), crow(2, 0)], fps=10, loop=False)
    W.add("hurt", [crow(0, hurt=True), crow(1)], fps=12, loop=False)
    W.add("die", [_fade(crow(0), k, False) for k in (1.0, 0.7, 0.4, 0.15)], fps=8, loop=False)
    W.close()


def build_graveyard_guardian():
    """A giant stone lantern brought to life (cemetery guardian)."""
    def fr(phase=0, attack=0, hurt=False, glow=1.0):
        c = Canvas(80, 80)
        y = 76 + [0, -1, 0, 1][phase % 4]
        st, std, stl = H("8a8a90"), H("5a5a64"), H("b0b0b8")
        c.rect(26, y - 10, 54, y, std); c.rect(30, y - 34, 50, y - 10, st)          # base + pillar
        c.rect(18, y - 44, 62, y - 34, std); c.rect(20, y - 44, 60, y - 42, stl)     # firebox ledge
        c.rect(26, y - 58, 54, y - 44, st)                                          # firebox
        g = (int(120 * glow + 80), int(200 * glow + 40), 255, 255)
        c.rect(32, y - 55, 48, y - 47, g)
        c.rect(36, y - 54, 37, y - 50, INK); c.rect(43, y - 54, 44, y - 50, INK)   # eyes in the window
        c.poly([(14, y - 58), (66, y - 58), (52, y - 70), (28, y - 70)], std)       # roof
        c.ellipse(40, y - 72, 4, 3, st)
        arm = attack * 10
        c.limb(18, y - 40, 8, y - 24 - arm, std, 7); c.limb(62, y - 40, 72, y - 24 - arm, std, 7)
        c.ellipse(8, y - 22 - arm, 5, 5, st); c.ellipse(72, y - 22 - arm, 5, 5, st)
        c.outline(color=INK, selective=False)
        if hurt:
            c.tint_silhouette((255, 255, 255), 0.75)
        return c
    W = SheetWriter(GEN, "guardiao_cemiterio", 80, 80, origin=(40, 77))
    W.add("idle", [fr(i, glow=0.7 + 0.1 * i) for i in range(4)], fps=4)
    W.add("walk", [fr(i) for i in range(4)], fps=5)
    W.add("attack", [fr(0, 1, glow=1.2), fr(0, 2, glow=1.3), fr(0, 2), fr(0, 0)], fps=6, loop=False)
    W.add("hurt", [fr(0, hurt=True), fr(0)], fps=12, loop=False)
    W.add("die", [_fade(fr(0), k) for k in (1.0, 0.7, 0.4, 0.15)], fps=6, loop=False)
    W.close()


def build_boss():
    """Samurai das Mil Almas — 96px, flaming spirit aura, long katana."""
    def fr(phase=0, attack=0, hurt=False, stance=False, aura=0):
        c = Canvas(112, 112)
        # aura of souls (blue flames) behind
        for i in range(7):
            a = i / 7 * 6.283 + aura * 0.5
            fx, fy = 56 + np.cos(a) * 34, 66 + np.sin(a) * 26
            c.ellipse(fx, fy, 4, 6, (110, 170, 255, 120)); c.ellipse(fx, fy - 2, 2, 3, (220, 240, 255, 160))
        samurai(c, 56, 104, 2.4, phase=phase, attack=attack, ghostly=True, armor="2a2a4a", trim_="b896ff")
        if stance:
            c.rect(30, 50, 34, 54, (255, 255, 255, 255))
        if hurt:
            c.tint_silhouette((255, 255, 255), 0.75)
        return c
    W = SheetWriter(GEN, "samurai_mil_almas", 112, 112, origin=(56, 104))
    W.add("idle", [fr(i, aura=i) for i in range(4)], fps=5)
    W.add("walk", [fr(i, aura=i) for i in range(4)], fps=7)
    W.add("attack", [fr(0, 1), fr(0, 2), fr(0, 2), fr(0, 0)], fps=9, loop=False)
    W.add("stance", [fr(0, 0, aura=i, stance=i % 2 == 0) for i in range(4)], fps=6)
    W.add("raise", [fr(0, 1, aura=i) for i in range(4)], fps=6)
    W.add("hurt", [fr(0, hurt=True), fr(1)], fps=12, loop=False)
    W.close()


def ground():
    meta = {m["i"]: m for m in json.load(open(os.path.join(ROOT, "assets", "sprites", "tiles", "village_night", "pieces.json")))}
    src = np.array(Image.open(os.path.join(ROOT, "assets", "sprites", "source", "tiles_village_night.png")).convert("RGBA"))

    def crop(i, inset=8):
        x0, y0, x1, y1 = meta[i]["bbox"]
        sub = src[y0 + inset:y1 - inset, x0 + inset:x1 - inset].copy()
        sub[:, :, 3] = 255
        return np.array(Image.fromarray(sub).resize((32, 32), Image.BOX))
    for name, idx in (("night_stone", 0), ("night_cobble", 4), ("night_slab", 3), ("night_water", 9), ("night_dirt", 18)):
        t = seamless(crop(idx), 12)
        for k, v in enumerate(variants(t)):
            Image.fromarray(v).save(os.path.join(GROUND_OUT, f"{name}_{k}.png"))
    # dark grass from a forest tile, cooled down
    fmeta = {m["i"]: m for m in json.load(open(os.path.join(ROOT, "assets", "sprites", "tiles", "forest_b", "pieces.json")))}
    fsrc = np.array(Image.open(os.path.join(ROOT, "assets", "sprites", "source", "tiles_spirit_forest_b.png")).convert("RGBA"))
    x0, y0, x1, y1 = fmeta[2]["bbox"]
    sub = fsrc[y0 + 10:y1 - 10, x0 + 10:x1 - 10].copy(); sub[:, :, 3] = 255
    t = np.array(Image.fromarray(sub).resize((32, 32), Image.BOX)).astype(np.float32)
    t[:, :, :3] *= np.array([0.8, 0.85, 1.0]); t = t.clip(0, 255).astype(np.uint8)
    t = seamless(t, 10)
    for k, v in enumerate(variants(t)):
        Image.fromarray(v).save(os.path.join(GROUND_OUT, f"night_grass_{k}.png"))


NIGHT_EXTRA = {
    "grave": (86, "decor", True, (0.7, 0.25)), "grave_board": (88, "decor", True, (0.8, 0.2)), "lantern_stone_n": (79, "lantern", True, (0.6, 0.15)),
    "lantern_stone_n2": (80, "lantern", True, (0.6, 0.15)), "lantern_paper": (68, "lantern", True, (0.5, 0.1)), "lantern_paper_b": (75, "lantern", True, (0.5, 0.1)),
    "lantern_hanging": (63, "lantern", True, (0.3, 0.06)), "fence_wood": (38, "fence", True, (1.0, 0.35)), "fence_wood_b": (41, "fence", True, (1.0, 0.35)),
    "fence_door": (45, "fence", True, (1.0, 0.35)), "rock_n": (28, "rock", True, (0.8, 0.45)), "rock_n2": (30, "rock", True, (0.8, 0.45)),
    "rocks_n": (31, "rock", True, (0.85, 0.4)), "bush_n": (100, "bush", True, (0.8, 0.4)), "bush_n2": (101, "bush", True, (0.8, 0.4)),
    "bush_n3": (104, "bush", True, (0.8, 0.4)), "crates_n": (107, "decor", True, (0.9, 0.4)), "box_n": (118, "decor", True, (0.8, 0.4)),
    "red_board": (88, "decor", True, (0.8, 0.2)), "fence_red": (95, "fence", True, (1.0, 0.3)), "post_n": (96, "decor", True, (0.4, 0.1)),
    "shrine_lantern": (84, "lantern", True, (0.7, 0.2)), "pine_dark": (128, "tree", True, (0.25, 0.1)), "bonsai_dark": (129, "tree", True, (0.25, 0.1)),
}


def props():
    db = json.load(open(os.path.join(PROPS, "props.json")))
    for name, (i, kind, solid, fp) in NIGHT_EXTRA.items():
        p = os.path.join(ROOT, "assets", "sprites", "tiles", "village_night", f"piece_{i}.png")
        if not os.path.exists(p):
            continue
        a = trim(np.array(Image.open(p)))
        Image.fromarray(a).save(os.path.join(PROPS, f"n_{name}.png"))
        h, w = a.shape[:2]
        db["n_" + name] = {"file": f"n_{name}.png", "w": int(w), "h": int(h), "kind": kind, "solid": solid,
                           "fp": [max(4, int(w * fp[0])), max(4, int(h * fp[1]))] if solid else [0, 0]}
    json.dump(db, open(os.path.join(PROPS, "props.json"), "w"), indent=1)


if __name__ == "__main__":
    ghost(); ghost_samurai(); possessed_armor(); build_puppet(); build_crow(); build_graveyard_guardian(); build_boss(); ground(); props()
    print("ghost city assets ok")
