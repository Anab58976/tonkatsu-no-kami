"""Rei Porco (King Pig) — drawn with the pixel rig to match the artist's style
(thick dark outline, pink pig palette shared with pig Lulu).

TEMPORARY until the artist delivers an official Rei Porco sheet: drop it in
res://assets/sprites/characters/rei_porco/ with an anims.json and the engine
uses it instead (see SpriteLibrary.gd).

Cell 80x80, feet at (40, 76). Front-facing 3/4 view; the engine flips for left/right.
"""
from __future__ import annotations

import math
import os

from rig import Canvas, SheetWriter, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
CELL = 80

P = {
    "out": (40, 20, 19, 255),
    "skin": (238, 158, 160, 255), "skin_d": (206, 116, 124, 255), "skin_l": (250, 196, 190, 255),
    "snout": (226, 128, 138, 255), "nostril": (120, 40, 52, 255),
    "robe": (176, 40, 48, 255), "robe_d": (118, 24, 36, 255), "robe_l": (212, 72, 70, 255),
    "cape": (96, 20, 40, 255), "cape_l": (130, 30, 54, 255),
    "gold": (240, 190, 60, 255), "gold_d": (178, 118, 32, 255), "gold_l": (255, 236, 150, 255),
    "fur": (246, 240, 232, 255), "fur_d": (204, 196, 190, 255),
    "boot": (74, 42, 32, 255), "eye": (40, 20, 19, 255), "eye_hi": (255, 255, 255, 255),
    "jewel_b": (80, 160, 225, 255), "jewel_r": (225, 45, 65, 255), "mouth": (130, 40, 50, 255),
    "tongue": (230, 100, 110, 255), "stache": (250, 248, 240, 255), "stache_d": (212, 206, 200, 255),
    "blush": (232, 120, 130, 255),
}

DEFAULT = dict(dy=0, step=0, tilt=0, arm_l=("down", 0), arm_r=("down", 0), mouth="closed",
               brows="neutral", eyes="open", cape=0, crown_y=0, blush=False, look=0)


def draw(**kw):
    p = dict(DEFAULT); p.update(kw)
    c = Canvas(CELL, CELL)
    dy = p["dy"]
    cx = 40
    # ---- cape (behind) -------------------------------------------------
    flutter = p["cape"]
    c.poly([(cx - 15, 40 + dy), (cx + 15, 40 + dy), (cx + 21 + flutter, 74), (cx - 21 - flutter, 74)], P["cape"])
    c.poly([(cx - 9, 44 + dy), (cx + 9, 44 + dy), (cx + 12 + flutter, 74), (cx - 12 - flutter, 74)], P["cape_l"])
    # ---- legs ------------------------------------------------------------
    ls = [0, 1, 0, -1][p["step"] % 4]
    c.rect(cx - 9, 66 + dy - max(0, ls), cx - 3, 75 - max(0, ls), P["boot"])
    c.rect(cx + 3, 66 + dy - max(0, -ls), cx + 9, 75 - max(0, -ls), P["boot"])
    c.rect(cx - 10, 73 - max(0, ls), cx - 2, 75 - max(0, ls), shade(P["boot"], 0.8))
    c.rect(cx + 2, 73 - max(0, -ls), cx + 10, 75 - max(0, -ls), shade(P["boot"], 0.8))
    # ---- arms behind body (down poses) -----------------------------------
    arms_front = []
    for side, (pose, t) in (("L", p["arm_l"]), ("R", p["arm_r"])):
        arms_front.append((side, pose, t))
    # ---- body / robe -----------------------------------------------------
    c.ellipse(cx, 56 + dy, 18, 14, P["robe_d"])
    c.ellipse(cx - 1, 55 + dy, 17, 13, P["robe"])
    c.ellipse(cx - 6, 51 + dy, 6, 5, P["robe_l"])
    # belly peeking between robe panels
    c.ellipse(cx, 58 + dy, 8, 9, P["skin_d"])
    c.ellipse(cx - 1, 57 + dy, 7, 8, P["skin"])
    c.ellipse(cx - 3, 55 + dy, 2, 2, P["skin_l"])
    # gold trim down the robe opening + belt
    for y in range(46, 68):
        w = 9 if y > 52 else 7
        c.px(cx - w, y + dy, P["gold"]); c.px(cx + w, y + dy, P["gold_d"])
    c.rect(cx - 17, 61 + dy, cx + 17, 63 + dy, P["gold_d"])
    c.rect(cx - 17, 61 + dy, cx + 17, 61 + dy, P["gold"])
    c.rect(cx - 2, 60 + dy, cx + 2, 64 + dy, P["gold_l"])
    c.px(cx, 62 + dy, P["jewel_r"])
    # fur collar (ermine)
    c.ellipse(cx, 44 + dy, 17, 5, P["fur_d"])
    c.ellipse(cx, 43 + dy, 16, 4, P["fur"])
    for sx in (-12, -6, 0, 6, 12):
        c.px(cx + sx, 44 + dy, P["out"])
    # robe hem fur
    c.rect(cx - 15, 67 + dy, cx + 15, 69 + dy, P["fur"])
    c.rect(cx - 15, 69 + dy, cx + 15, 69 + dy, P["fur_d"])
    for sx in (-11, -4, 4, 11):
        c.px(cx + sx, 68 + dy, P["out"])
    # ---- arms ------------------------------------------------------------
    for side, pose, t in arms_front:
        draw_arm(c, side, pose, t, dy)
    # ---- head ------------------------------------------------------------
    hx = cx + p["tilt"]
    hy = 28 + dy
    # ears
    tilt = p["tilt"]
    c.poly([(hx - 15, hy - 6 + max(0, tilt)), (hx - 18, hy - 17 + tilt), (hx - 7, hy - 11)], P["skin_d"])
    c.poly([(hx - 14, hy - 7 + max(0, tilt)), (hx - 16, hy - 14 + tilt), (hx - 9, hy - 10)], P["skin"])
    c.poly([(hx + 15, hy - 6 + max(0, -tilt)), (hx + 18, hy - 17 - tilt), (hx + 7, hy - 11)], P["skin_d"])
    c.poly([(hx + 14, hy - 7 + max(0, -tilt)), (hx + 16, hy - 14 - tilt), (hx + 9, hy - 10)], P["skin"])
    c.ellipse(hx, hy, 15, 13, P["skin_d"])
    c.ellipse(hx - 1, hy - 1, 14, 12, P["skin"])
    c.ellipse(hx - 6, hy - 6, 4, 3, P["skin_l"])
    # eyes
    ex = p["look"]
    for sx in (-6, 6):
        x = hx + sx + ex
        y = hy - 2
        kind = p["eyes"]
        if kind == "open":
            c.rect(x - 1, y - 1, x, y + 1, P["eye"]); c.px(x, y - 1, P["eye_hi"])
        elif kind == "wide":
            c.rect(x - 1, y - 2, x + 1, y + 1, P["eye"]); c.px(x + 1, y - 2, P["eye_hi"]); c.px(x - 1, y, P["eye_hi"])
        elif kind == "closed":
            c.rect(x - 1, y, x + 1, y, P["eye"])
        elif kind == "happy":
            c.px(x - 1, y, P["eye"]); c.px(x, y - 1, P["eye"]); c.px(x + 1, y, P["eye"])
        elif kind == "narrow":
            c.rect(x - 1, y, x + 1, y, P["eye"]); c.px(x, y + 1, P["eye"])
        elif kind == "sparkle":
            c.rect(x - 1, y - 1, x + 1, y + 1, P["eye"]); c.px(x + 1, y - 1, P["eye_hi"]); c.px(x - 1, y + 1, P["gold_l"])
    # brows
    b = p["brows"]
    for sx, sgn in ((-6, -1), (6, 1)):
        x = hx + sx
        y = hy - 6
        if b == "neutral":
            c.rect(x - 2, y, x + 1, y, P["out"])
        elif b == "raised":
            c.rect(x - 2, y - 2, x + 1, y - 2, P["out"])
        elif b == "stern":      # inner ends down
            c.px(x - 2 * sgn, y - 1, P["out"]); c.px(x - sgn, y - 1, P["out"]); c.px(x, y, P["out"]); c.px(x + sgn, y, P["out"])
        elif b == "soft":       # inner ends up
            c.px(x - 2 * sgn, y, P["out"]); c.px(x - sgn, y, P["out"]); c.px(x, y - 1, P["out"]); c.px(x + sgn, y - 1, P["out"])
    if p["blush"]:
        c.rect(hx - 12, hy + 2, hx - 10, hy + 3, P["blush"]); c.rect(hx + 10, hy + 2, hx + 12, hy + 3, P["blush"])
    # snout
    c.ellipse(hx, hy + 4, 6, 4, shade(P["snout"], 0.85))
    c.ellipse(hx, hy + 3, 5, 3, P["snout"])
    c.rect(hx - 3, hy + 3, hx - 2, hy + 4, P["nostril"]); c.rect(hx + 2, hy + 3, hx + 3, hy + 4, P["nostril"])
    c.px(hx - 2, hy + 1, shade(P["snout"], 1.15))
    # mouth (under the moustache)
    m = p["mouth"]
    my = hy + 9
    if m == "open":
        c.rect(hx - 3, my, hx + 3, my + 2, P["mouth"]); c.rect(hx - 1, my + 2, hx + 1, my + 2, P["tongue"])
    elif m == "half":
        c.rect(hx - 2, my, hx + 2, my + 1, P["mouth"])
    elif m == "o":
        c.rect(hx - 1, my, hx + 1, my + 2, P["mouth"])
    elif m == "smile":
        c.px(hx - 3, my, P["mouth"]); c.rect(hx - 2, my + 1, hx + 2, my + 1, P["mouth"]); c.px(hx + 3, my, P["mouth"])
    elif m == "grin":
        c.rect(hx - 4, my, hx + 4, my + 1, P["mouth"]); c.rect(hx - 3, my, hx + 3, my, P["fur"])
    elif m == "frown":
        c.px(hx - 3, my + 1, P["mouth"]); c.rect(hx - 2, my, hx + 2, my, P["mouth"]); c.px(hx + 3, my + 1, P["mouth"])
    else:
        c.rect(hx - 2, my, hx + 2, my, P["mouth"])
    # royal moustache (curls)
    for sgn in (-1, 1):
        c.poly([(hx + sgn, hy + 7), (hx + sgn * 8, hy + 6), (hx + sgn * 10, hy + 4), (hx + sgn * 9, hy + 8), (hx + sgn * 2, hy + 9)],
               P["stache"])
        c.px(hx + sgn * 10, hy + 3, P["stache"]); c.px(hx + sgn * 9, hy + 8, P["stache_d"])
    # ---- crown -----------------------------------------------------------
    cy = hy - 12 + p["crown_y"]
    c.rect(hx - 9, cy, hx + 9, cy + 4, P["gold"])
    c.rect(hx - 9, cy + 4, hx + 9, cy + 4, P["gold_d"])
    for sx in (-9, -3, 3, 9):
        pass
    for sx in (-8, 0, 8):
        c.poly([(hx + sx - 3, cy), (hx + sx, cy - 6), (hx + sx + 3, cy)], P["gold"])
        c.px(hx + sx, cy - 7, P["gold_l"])
    c.poly([(hx - 5, cy), (hx - 4, cy - 3), (hx - 3, cy)], P["gold_d"])
    c.poly([(hx + 3, cy), (hx + 4, cy - 3), (hx + 5, cy)], P["gold_d"])
    c.rect(hx - 1, cy + 1, hx + 1, cy + 3, P["jewel_r"])
    c.px(hx - 6, cy + 2, P["jewel_b"]); c.px(hx + 6, cy + 2, P["jewel_b"])
    c.rect(hx - 8, cy, hx + 8, cy, P["gold_l"])
    c.outline(color=P["out"], selective=False)
    return c


def draw_arm(c, side, pose, t, dy):
    sgn = -1 if side == "L" else 1
    sx, sy = 40 + sgn * 15, 47 + dy        # shoulder
    if pose == "down":
        ex, ey = sx + sgn * 3, sy + 9
        hx, hy = ex + sgn * 0, ey + 6 + t
    elif pose == "hip":
        ex, ey = sx + sgn * 6, sy + 6
        hx, hy = sx + sgn * 2, sy + 13
    elif pose == "point":                  # straight out to the side, t = height offset
        ex, ey = sx + sgn * 7, sy - 1 + t
        hx, hy = sx + sgn * 14, sy - 3 + t * 2
    elif pose == "point_up":
        ex, ey = sx + sgn * 5, sy - 6
        hx, hy = sx + sgn * 8, sy - 14 - t
    elif pose == "open":                   # arms wide, t raises them
        ex, ey = sx + sgn * 7, sy - 2 - t
        hx, hy = sx + sgn * 14, sy - 7 - t * 2
    elif pose == "cross":                  # folded across the belly
        ex, ey = sx + sgn * 2, sy + 8
        hx, hy = 40 - sgn * 7, sy + 9
    elif pose == "chin":                   # hand to chin (thinking / tasting)
        ex, ey = sx + sgn * 3, sy + 7
        hx, hy = 40 + sgn * 6, 38 + dy + t
    elif pose == "wave":
        ex, ey = sx + sgn * 6, sy - 6
        hx, hy = sx + sgn * (9 + t), sy - 15
    elif pose == "extend":                 # forward / toward the portal, slightly down
        ex, ey = sx + sgn * 7, sy + 3
        hx, hy = sx + sgn * 15, sy + 5 + t
    else:
        ex, ey, hx, hy = sx, sy + 9, sx, sy + 14
    c.limb(sx, sy, ex, ey, P["robe_d"], 6)
    c.limb(sx, sy, ex, ey, P["robe"], 4)
    c.limb(ex, ey, hx, hy, P["robe"], 5)
    # fur cuff + hand (hoof hand with two fingers)
    c.ellipse(hx, hy, 3, 2, P["fur"])
    fx = hx + sgn * (2 if pose in ("point", "extend", "open", "wave") else 0)
    fy = hy + (0 if pose in ("point", "extend", "open", "wave", "point_up") else 2)
    if pose == "point_up":
        fy = hy - 2
    c.ellipse(fx, fy, 2, 2, P["skin_d"])
    c.ellipse(fx, fy, 1, 1, P["skin"])
    if pose == "point":
        c.rect(fx + sgn * 1, fy - 1, fx + sgn * 4, fy - 1, P["skin"]) if sgn > 0 else c.rect(fx - 4, fy - 1, fx - 1, fy - 1, P["skin"])
    if pose == "point_up":
        c.rect(fx, fy - 4, fx, fy - 1, P["skin"])


def main():
    W = SheetWriter(GEN, "rei_porco", CELL, CELL, origin=(40, 76))
    W.add("idle", [draw(), draw(), draw(dy=1, cape=1), draw(dy=1, cape=1), draw(), draw(eyes="closed")], fps=5)
    W.add("walk", [draw(step=i, dy=(0, -1, 0, -1)[i], cape=i % 2) for i in range(4)], fps=6)
    W.add("talk", [draw(mouth="open"), draw(mouth="half"), draw(mouth="closed"), draw(mouth="open", dy=1), draw(mouth="o")], fps=8)
    W.add("talk_stern", [draw(mouth="open", brows="stern", eyes="narrow"), draw(mouth="half", brows="stern", eyes="narrow"),
                         draw(mouth="closed", brows="stern", eyes="narrow")], fps=8)
    W.add("inspect", [draw(tilt=0, brows="stern", eyes="narrow", look=-1), draw(tilt=-2, brows="stern", eyes="narrow", look=-1),
                      draw(tilt=-3, brows="raised", eyes="narrow", look=-1, mouth="o")], fps=3, loop=False)
    W.add("arms_crossed", [draw(arm_l=("cross", 0), arm_r=("cross", 0), brows="stern", mouth="frown"),
                           draw(arm_l=("cross", 0), arm_r=("cross", 0), brows="stern", mouth="frown", dy=1)], fps=2)
    W.add("arms_crossed_talk", [draw(arm_l=("cross", 0), arm_r=("cross", 0), brows="stern", mouth=m)
                                for m in ("open", "half", "closed", "open")], fps=8)
    W.add("point", [draw(arm_r=("point", 2), brows="stern", mouth="open"), draw(arm_r=("point", 0), brows="stern", mouth="half"),
                    draw(arm_r=("point", 0), brows="stern", mouth="open")], fps=8)
    W.add("point_side", [draw(arm_l=("point", 0), mouth="half", brows="raised", look=-1),
                         draw(arm_l=("point", 0), mouth="open", brows="raised", look=-1)], fps=6)
    W.add("warm", [draw(brows="soft", eyes="happy", mouth="smile"), draw(brows="soft", eyes="happy", mouth="smile", dy=1)], fps=2)
    W.add("warm_talk", [draw(brows="soft", eyes="open", mouth=m) for m in ("open", "half", "smile", "open")], fps=8)
    W.add("arms_open", [draw(arm_l=("open", 0), arm_r=("open", 0), brows="raised", mouth="grin", eyes="sparkle", crown_y=0),
                        draw(arm_l=("open", 2), arm_r=("open", 2), brows="raised", mouth="open", eyes="sparkle", crown_y=-1, cape=2),
                        draw(arm_l=("open", 2), arm_r=("open", 2), brows="raised", mouth="half", eyes="sparkle", crown_y=-1, cape=2)],
          fps=6)
    W.add("grand_talk", [draw(arm_l=("open", 2), arm_r=("open", 2), brows="raised", mouth=m, eyes="sparkle", cape=i % 2 + 1)
                         for i, m in enumerate(("open", "half", "grin", "open"))], fps=8)
    W.add("point_up_talk", [draw(arm_r=("point_up", i % 2), mouth=m, brows="raised") for i, m in enumerate(("open", "half", "closed", "open"))], fps=8)
    W.add("stare", [draw(brows="stern", eyes="narrow", mouth="closed"), draw(brows="stern", eyes="narrow", mouth="half")], fps=3)
    W.add("stare_talk", [draw(brows="stern", eyes="open", mouth=m) for m in ("open", "half", "closed", "o")], fps=8)
    W.add("extend_arm", [draw(arm_r=("extend", 0), brows="soft", mouth="open"), draw(arm_r=("extend", 1), brows="soft", mouth="closed")],
          fps=4)
    W.add("wave", [draw(arm_r=("wave", 0), brows="soft", eyes="happy", mouth="smile"),
                   draw(arm_r=("wave", 3), brows="soft", eyes="happy", mouth="smile"),
                   draw(arm_r=("wave", 0), brows="soft", eyes="happy", mouth="smile"),
                   draw(arm_r=("wave", -3), brows="soft", eyes="happy", mouth="smile")], fps=6)
    # ending: taste, shock, joy
    W.add("taste", [draw(arm_r=("chin", 0), eyes="closed", mouth="closed"), draw(arm_r=("chin", 0), eyes="closed", mouth="o"),
                    draw(arm_r=("chin", 1), eyes="closed", mouth="half"), draw(arm_r=("chin", 0), eyes="closed", mouth="o")], fps=4)
    W.add("shocked", [draw(eyes="wide", brows="raised", mouth="o", crown_y=-2, dy=-1), draw(eyes="wide", brows="raised", mouth="open", crown_y=-1)],
          fps=6)
    W.add("joy", [draw(arm_l=("open", 3), arm_r=("open", 3), eyes="happy", brows="soft", mouth="grin", blush=True, dy=-2, cape=2),
                  draw(arm_l=("open", 1), arm_r=("open", 1), eyes="happy", brows="soft", mouth="grin", blush=True, dy=0, cape=1)], fps=5)
    W.add("thinking", [draw(arm_r=("chin", 0), look=1, brows="raised", mouth="closed"), draw(arm_r=("chin", 0), look=1, brows="raised", mouth="closed", dy=1)],
          fps=2)
    W.close()
    print("rei_porco anims:", list(W.meta["animations"].keys()))


if __name__ == "__main__":
    main()
