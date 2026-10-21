"""Builds human Lulu's cutscene animations from the artist's extracted views.

Only pixel edits on top of the artist's art: expressions (eyes/mouth/blush),
sleeve/arm offsets, held props, bob/breathing. Writes
assets/sprites/generated/lulu_human/<anim>.png + anims.json (64x64 cells).
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

from rig import Canvas, SheetWriter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXT = os.path.join(ROOT, "assets", "sprites", "extracted", "lulu_human")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")

C = {
    "out": (40, 20, 19, 255), "out2": (30, 12, 7, 255), "hair": (71, 45, 39, 255),
    "skin": (218, 152, 112, 255), "skin_d": (170, 104, 95, 255), "blush": (209, 123, 125, 255),
    "mouth": (150, 65, 77, 255), "white": (241, 223, 207, 255), "white_d": (236, 207, 190, 255),
    "hakama": (131, 55, 66, 255), "hakama_d": (98, 40, 49, 255), "eye_hi": (255, 245, 235, 255),
    "wood": (139, 90, 52, 255), "wood_d": (96, 58, 33, 255), "steel": (120, 120, 130, 255),
    "sweat": (150, 200, 240, 255), "plate": (238, 236, 228, 255), "food": (196, 120, 50, 255),
    "food_d": (120, 60, 30, 255),
}
SLEEVE_COLS = {(241, 223, 207), (236, 207, 190), (209, 123, 125), (237, 177, 170),
               (234, 153, 152), (212, 185, 170), (185, 158, 148)}

# coordinates are in the 26x52 front sprite space
L_EYE = (10, 11)
R_EYE = (17, 18)
EYE_ROWS = (14, 17)
MOUTH = (14, 19)


def load(name):
    return np.array(Image.open(os.path.join(EXT, f"{name}.png")).convert("RGBA"))


def to_cell(arr, dx=0, dy=0, cell=64, foot=(32, 60)):
    """Places a sprite array in a 64x64 cell with its feet on the anchor."""
    h, w = arr.shape[:2]
    c = Canvas(cell, cell)
    img = Image.fromarray(arr)
    x = foot[0] - w // 2 + dx
    y = foot[1] - h + dy
    c.img.paste(img, (x, y), img)
    c.d = ImageDraw.Draw(c.img)
    return c


def put(a, x, y, col):
    if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
        a[y, x] = col


# ---------------------------------------------------------------- faces
def eyes(a, kind="open"):
    y0, y1 = EYE_ROWS
    for ex in (L_EYE, R_EYE):
        for y in range(y0, y1 + 1):
            for x in ex:
                put(a, x, y, C["skin"])
        x0, x1 = ex
        if kind == "open":
            for y in range(y0, y1 + 1):
                put(a, x0, y, C["out"]); put(a, x1, y, C["out"])
            put(a, x1, y0, C["eye_hi"])
        elif kind == "wide":
            for y in range(y0 - 1, y1 + 1):
                put(a, x0, y, C["out"]); put(a, x1, y, C["out"])
            put(a, x1, y0 - 1, C["eye_hi"]); put(a, x0, y0, C["eye_hi"])
        elif kind == "closed":
            put(a, x0, y0 + 2, C["out"]); put(a, x1, y0 + 2, C["out"])
        elif kind == "happy":       # ^ ^
            put(a, x0, y0 + 2, C["out"]); put(a, x1, y0 + 1, C["out"])
            if ex is R_EYE:
                put(a, x0, y0 + 1, C["out"]); put(a, x1, y0 + 2, C["out"]); put(a, x1, y0 + 1, C["skin"])
        elif kind == "sad":         # droopy half eyes
            put(a, x0, y0 + 2, C["out"]); put(a, x1, y0 + 2, C["out"])
            put(a, x0, y0 + 3, C["out"]); put(a, x1, y0 + 3, C["out"])
            put(a, x0 if ex is L_EYE else x1, y0 + 1, C["out2"])
        elif kind == "down":        # looking down
            for y in (y0 + 2, y0 + 3):
                put(a, x0, y, C["out"]); put(a, x1, y, C["out"])
        elif kind == "determined":
            for y in range(y0 + 1, y1 + 1):
                put(a, x0, y, C["out"]); put(a, x1, y, C["out"])
            put(a, x1, y0 + 1, C["eye_hi"])
            # brows slanting toward the centre
            if ex is L_EYE:
                put(a, x0, y0 - 1, C["out2"]); put(a, x1, y0, C["out2"])
            else:
                put(a, x0, y0, C["out2"]); put(a, x1, y0 - 1, C["out2"])
        elif kind == "sparkle":
            for y in range(y0, y1 + 1):
                put(a, x0, y, C["out"]); put(a, x1, y, C["out"])
            put(a, x1, y0, C["eye_hi"]); put(a, x0, y1 - 1, C["eye_hi"])


def mouth(a, kind="neutral"):
    mx, my = MOUTH
    for x in range(mx - 1, mx + 2):
        for y in range(my, my + 2):
            put(a, x, y, C["skin"])
    if kind == "neutral":
        put(a, mx, my, C["mouth"])
    elif kind == "smile":
        put(a, mx - 1, my, C["mouth"]); put(a, mx, my + 1, C["mouth"]); put(a, mx + 1, my, C["mouth"])
    elif kind == "open":
        put(a, mx, my, C["out"]); put(a, mx, my + 1, C["mouth"])
    elif kind == "frown":
        put(a, mx - 1, my + 1, C["mouth"]); put(a, mx, my, C["mouth"]); put(a, mx + 1, my + 1, C["mouth"])
    elif kind == "flat":
        put(a, mx - 1, my, C["mouth"]); put(a, mx, my, C["mouth"]); put(a, mx + 1, my, C["mouth"])
    elif kind == "wavy":
        put(a, mx - 1, my, C["mouth"]); put(a, mx, my + 1, C["mouth"]); put(a, mx + 1, my, C["mouth"])
        put(a, mx + 2, my + 1, C["mouth"])
    elif kind == "chew":
        put(a, mx, my, C["mouth"]); put(a, mx - 1, my, C["mouth"])


def blush(a, strong=False):
    for x in (9, 10) if strong else (9,):
        put(a, x, 18, C["blush"])
    for x in (18, 19) if strong else (19,):
        put(a, x, 18, C["blush"])


def sweat(a, phase=0):
    x, y = 21, 11 + phase
    put(a, x, y, C["sweat"]); put(a, x, y + 1, C["sweat"]); put(a, x - 1, y + 1, C["sweat"])


# ---------------------------------------------------------------- body edits
def sleeve_mask(a, side):
    h, w = a.shape[:2]
    m = np.zeros((h, w), bool)
    xr = range(2, 10) if side == "L" else range(17, 25)
    for y in range(24, 42):
        for x in xr:
            if a[y, x, 3] and tuple(a[y, x, :3]) in SLEEVE_COLS:
                m[y, x] = True
    # include the outline ring around the sleeve
    ring = np.zeros_like(m)
    for y in range(h):
        for x in range(w):
            if m[y, x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and m[ny, nx] and a[y, x, 3] and sum(a[y, x, :3]) < 200:
                    if (side == "L" and x <= 10) or (side == "R" and x >= 16):
                        ring[y, x] = True
    return m | ring


def move_region(a, mask, dx, dy):
    """Lifts masked pixels, fills the hole from horizontal neighbours, pastes shifted."""
    h, w = a.shape[:2]
    layer = np.zeros_like(a)
    layer[mask] = a[mask]
    base = a.copy()
    for y in range(h):
        for x in range(w):
            if not mask[y, x]:
                continue
            fill = None
            for k in range(1, 8):
                for nx in (x - k, x + k):
                    if 0 <= nx < w and not mask[y, nx]:
                        fill = a[y, nx]
                        break
                if fill is not None:
                    break
            base[y, x] = fill if fill is not None else (0, 0, 0, 0)
    out = base.copy()
    ys, xs = np.where(mask)
    for y, x in zip(ys, xs):
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w:
            out[ny, nx] = layer[y, x]
    return out


def pad(a, l=8, r=8, t=6, b=0):
    h, w = a.shape[:2]
    out = np.zeros((h + t + b, w + l + r, 4), np.uint8)
    out[t:t + h, l:l + w] = a
    return out, l, t


def hand(a, x, y):
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
        put(a, x + dx, y + dy, C["skin"])
    for dx, dy in ((-1, 0), (-1, 1), (2, 0), (2, 1), (0, 2), (1, 2), (0, -1), (1, -1)):
        if a[y + dy, x + dx, 3] == 0 or tuple(a[y + dy, x + dx, :3]) in SLEEVE_COLS and False:
            put(a, x + dx, y + dy, C["out"])


def ladle(a, x, y):
    """Handle going up-right from the hand, bowl at the bottom-left."""
    for i in range(6):
        put(a, x + 2 + i, y - 1 - i // 2, C["wood"])
    put(a, x - 1, y + 2, C["steel"]); put(a, x, y + 2, C["steel"]); put(a, x - 1, y + 3, C["out"]); put(a, x, y + 3, C["out"])


def spoon(a, x, y):
    put(a, x, y, C["steel"]); put(a, x + 1, y, C["steel"])
    for i in range(1, 4):
        put(a, x + 1 + i, y + i, C["wood"])


def plate(a, cx, y, full=True):
    for x in range(cx - 4, cx + 5):
        put(a, x, y, C["plate"]); put(a, x, y + 1, C["out"] if abs(x - cx) == 4 else C["plate"])
    for x in range(cx - 3, cx + 4):
        put(a, x, y + 2, C["out"])
    put(a, cx - 5, y, C["out"]); put(a, cx + 5, y, C["out"])
    if full:
        for x in range(cx - 2, cx + 3):
            put(a, x, y - 1, C["food"])
        for x in range(cx - 1, cx + 2):
            put(a, x, y - 2, C["food_d"])


def shift_rows(a, y_end, dy):
    """Shift rows [0, y_end) by dy (breathing / nod)."""
    out = a.copy()
    if dy > 0:
        out[dy:y_end] = a[0:y_end - dy]
        out[0:dy] = 0
    return out


# ---------------------------------------------------------------- build
def main():
    front = load("front")
    side = load("side")
    back = load("back")
    W = SheetWriter(GEN, "lulu_human", origin=(32, 60))

    def F(e="open", m="neutral", bl=False, bls=False, sw=None, arr=None):
        a = (arr if arr is not None else front).copy()
        eyes(a, e); mouth(a, m)
        if bl or bls:
            blush(a, bls)
        if sw is not None:
            sweat(a, sw)
        return a

    def cell(a, dx=0, dy=0, padded=None):
        if padded is not None:
            a, l, t = padded
        return to_cell(a, dx, dy)

    # idle (breathing + blink)
    idle = [F(), F(), shift_rows(F(), 41, 1), shift_rows(F(), 41, 1), F(), F("closed")]
    W.add("idle", [cell(a) for a in idle], fps=5)

    # stirring the pot (right sleeve circles, ladle in hand)
    stir = []
    for (dx, dy) in ((1, 0), (2, 1), (1, 2), (0, 1)):
        a = F("open", "neutral")
        a = move_region(a, sleeve_mask(a, "R"), dx, dy)
        p, l, t = pad(a)
        hand(p, l + 22 + dx, t + 40 + dy)
        ladle(p, l + 22 + dx, t + 40 + dy)
        stir.append(to_cell(p, 0, 0))
    W.add("stir", stir, fps=6)

    # serving the plate (both sleeves forward, plate appears)
    serve = []
    for i, (dy, full) in enumerate(((0, False), (1, True), (2, True))):
        a = F("open", "smile")
        a = move_region(a, sleeve_mask(a, "L"), 2, dy)
        a = move_region(a, sleeve_mask(a, "R"), -2, dy)
        p, l, t = pad(a)
        plate(p, l + 13, t + 40 + dy, full)
        hand(p, l + 7, t + 40 + dy); hand(p, l + 18, t + 40 + dy)
        serve.append(to_cell(p))
    W.add("serve", serve, fps=5, loop=False)

    # tasting: spoon goes to the mouth, eyes close, chew
    taste = []
    for i, (dx, dy, e, m) in enumerate(((0, 0, "open", "neutral"), (-2, -4, "open", "open"),
                                        (-3, -8, "closed", "chew"), (-3, -8, "closed", "neutral"),
                                        (-3, -8, "closed", "chew"))):
        a = F(e, m)
        a = move_region(a, sleeve_mask(a, "R"), dx, dy)
        p, l, t = pad(a)
        hand(p, l + 20 + dx, t + 40 + dy)
        spoon(p, l + 18 + dx, t + 39 + dy)
        taste.append(to_cell(p))
    W.add("taste", taste, fps=4, loop=False)

    W.add("disappointed", [to_cell(shift_rows(F("sad", "frown", sw=0), 23, 1)),
                           to_cell(shift_rows(F("sad", "frown", sw=1), 23, 1))], fps=3)
    W.add("embarrassed", [to_cell(F("down", "wavy", bls=True, sw=0)),
                          to_cell(F("down", "wavy", bls=True, sw=1)),
                          to_cell(F("closed", "wavy", bls=True, sw=2))], fps=4)
    W.add("hopeful", [to_cell(F("sparkle", "smile", bl=True)), to_cell(F("sparkle", "smile", bl=True)),
                      to_cell(F("open", "smile", bl=True))], fps=3)
    W.add("surprised", [to_cell(F("wide", "open"), 0, -1), to_cell(F("wide", "open")),
                        to_cell(F("wide", "open"))], fps=6, loop=False)
    W.add("determined", [to_cell(F("determined", "smile")), to_cell(shift_rows(F("determined", "smile"), 23, 1)),
                         to_cell(F("determined", "smile"))], fps=4)
    W.add("happy", [to_cell(F("happy", "smile", bl=True)), to_cell(F("happy", "smile", bl=True), 0, -1)], fps=4)

    # looking at her hands (sleeves raised, hands showing)
    lh = []
    for i, tremble in enumerate((0, 1, 0, -1)):
        a = F("down", "open")
        a = move_region(a, sleeve_mask(a, "L"), 2, -5)
        a = move_region(a, sleeve_mask(a, "R"), -2, -5)
        p, l, t = pad(a)
        hand(p, l + 8 + tremble, t + 35); hand(p, l + 17 - tremble, t + 35)
        lh.append(to_cell(p))
    W.add("look_hands", lh, fps=6)

    # floating / arms open (magic space)
    fl = []
    for dy in (0, -1, -2, -1):
        a = F("closed", "neutral")
        a = move_region(a, sleeve_mask(a, "L"), -2, -3)
        a = move_region(a, sleeve_mask(a, "R"), 2, -3)
        fl.append(to_cell(a, 0, dy))
    W.add("float", fl, fps=4)

    # side view (artist faces left): walk + idle
    W.add("side_idle", [to_cell(side), to_cell(shift_rows(side, 30, 1))], fps=2)
    walk = []
    for i in range(4):
        a = side.copy()
        h = a.shape[0]
        # hakama sway + alternating feet
        sway = (0, 1, 0, -1)[i]
        lower = a[40:h].copy()
        a[40:h] = 0
        a[40:h] = np.roll(lower, sway, axis=1)
        if i in (1, 3):
            a = shift_rows(a, h, 0)
        walk.append(to_cell(a, 0, -1 if i in (1, 3) else 0))
    W.add("side_walk", walk, fps=8)
    W.add("side_look_back", [to_cell(side), to_cell(side, 0, -1)], fps=2)

    # back view (walking into the portal)
    bw = []
    for i in range(4):
        a = back.copy()
        h = a.shape[0]
        lower = a[42:h].copy(); a[42:h] = 0; a[42:h] = np.roll(lower, (0, 1, 0, -1)[i], axis=1)
        bw.append(to_cell(a, 0, -1 if i in (1, 3) else 0))
    W.add("back_walk", bw, fps=8)
    W.add("back_idle", [to_cell(back)], fps=1)
    W.close()
    print("lulu_human anims:", list(W.meta["animations"].keys()))


if __name__ == "__main__":
    main()
