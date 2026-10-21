"""Lulu's traditional Japanese kitchen for the intro cutscene (640x360 set).

Outputs to assets/sprites/generated/kitchen/:
  bg.png          back wall + floor (static layer)
  counter.png     wooden counter drawn in front of Lulu (foreground layer)
  door.png        shoji sliding door panel (engine slides it)
  stove.png       kamado stove (2 frames of fire, horizontal strip 96x80)
  pot.png         iron pot with lid, 32x24
  lantern.png     paper lantern (andon) 16x24
  scroll_wall.png hanging scroll with an ink painting 28x64
"""
from __future__ import annotations

import os
import random

from PIL import Image

from rig import Canvas, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "generated", "kitchen")
os.makedirs(OUT, exist_ok=True)

K = {
    "out": (40, 20, 19, 255),
    "plaster": (226, 208, 178, 255), "plaster_d": (204, 184, 152, 255),
    "beam": (92, 58, 40, 255), "beam_d": (64, 38, 28, 255), "beam_l": (124, 82, 56, 255),
    "floor": (150, 98, 62, 255), "floor_d": (122, 78, 48, 255), "floor_l": (172, 118, 76, 255),
    "paper": (246, 238, 214, 255), "paper_glow": (255, 246, 210, 255), "lattice": (110, 72, 46, 255),
    "stone": (128, 120, 112, 255), "stone_d": (96, 90, 84, 255), "stone_l": (156, 148, 138, 255),
    "iron": (58, 56, 62, 255), "iron_l": (88, 86, 96, 255), "fire": (250, 160, 50, 255), "fire_l": (255, 230, 120, 255),
    "fire_d": (210, 80, 30, 255), "wood": (176, 120, 72, 255), "wood_d": (140, 92, 54, 255), "wood_l": (200, 148, 96, 255),
    "jar": (120, 80, 60, 255), "bowl_w": (236, 232, 220, 255), "bowl_b": (60, 90, 140, 255), "red": (180, 50, 50, 255),
    "green": (110, 150, 70, 255), "noren": (40, 60, 110, 255), "noren_l": (60, 84, 140, 255),
}
WALL_BOTTOM = 156


def bg():
    c = Canvas(640, 360)
    rnd = random.Random(7)
    # wall plaster with subtle speckle
    c.rect(0, 0, 639, WALL_BOTTOM, K["plaster"])
    for _ in range(900):
        c.px(rnd.randrange(640), rnd.randrange(WALL_BOTTOM), K["plaster_d"])
    # ceiling beam + floor skirting
    c.rect(0, 0, 639, 14, K["beam"]); c.rect(0, 14, 639, 16, K["beam_d"]); c.rect(0, 2, 639, 3, K["beam_l"])
    c.rect(0, WALL_BOTTOM - 10, 639, WALL_BOTTOM, K["beam"]); c.rect(0, WALL_BOTTOM - 10, 639, WALL_BOTTOM - 9, K["beam_l"])
    c.rect(0, 70, 639, 74, K["beam"]); c.rect(0, 74, 639, 75, K["beam_d"])
    # posts
    for x in (0, 140, 300, 456, 600):
        c.rect(x, 0, x + 10, WALL_BOTTOM, K["beam"]); c.rect(x + 1, 0, x + 2, WALL_BOTTOM, K["beam_l"]); c.rect(x + 9, 0, x + 10, WALL_BOTTOM, K["beam_d"])
    # shoji windows (glowing)
    for x0 in (160, 220):
        win(c, x0, 22, 48, 44)
    # shelves with bowls and jars (left)
    for sy in (34, 60):
        pass
    shelf(c, 18, 44, 112)
    shelf(c, 18, 98, 112)
    items_on_shelf(c, 22, 44, rnd)
    items_on_shelf(c, 22, 98, rnd)
    # hanging utensils on the wall above the counter
    for i, x in enumerate(range(318, 438, 20)):
        c.rect(x, 82, x + 1, 84, K["beam_d"])
        if i % 3 == 0:          # ladle
            c.rect(x, 84, x + 1, 108, K["wood"]); c.ellipse(x, 112, 4, 3, K["iron"])
        elif i % 3 == 1:        # strainer
            c.rect(x, 84, x + 1, 100, K["wood"]); c.ellipse(x, 106, 6, 6, K["wood_d"]); c.ellipse(x, 106, 4, 4, K["wood_l"])
        else:                   # knife
            c.rect(x, 84, x + 1, 94, K["wood_d"]); c.rect(x - 1, 94, x + 2, 116, K["stone_l"])
    # door opening on the right wall (the panel itself is a separate sprite)
    c.rect(466, 18, 594, WALL_BOTTOM - 10, K["beam_d"])
    c.rect(470, 22, 590, WALL_BOTTOM - 10, (36, 28, 30, 255))   # dark corridor behind
    for y in range(22, WALL_BOTTOM - 10, 8):
        c.rect(470, y, 590, y, (46, 36, 36, 255))
    # noren curtain over the door frame
    for i in range(4):
        x = 472 + i * 30
        c.rect(x, 22, x + 27, 44, K["noren"]); c.rect(x, 22, x + 27, 24, K["noren_l"])
    c.ellipse(531, 34, 6, 6, K["paper"]); c.ellipse(531, 34, 4, 4, K["noren"])   # family crest (mon): a simple circle
    # floor: planks running left-right with staggered joints
    for y in range(WALL_BOTTOM + 1, 360):
        band = (y - WALL_BOTTOM) // 12
        col = K["floor"] if band % 2 == 0 else shade(K["floor"], 0.95)
        c.rect(0, y, 639, y, col)
    for band in range(0, 18):
        y = WALL_BOTTOM + 1 + band * 12
        c.rect(0, y, 639, y, K["floor_d"])
        c.rect(0, y + 1, 639, y + 1, K["floor_l"])
        off = (band * 97) % 160
        for x in range(off, 640, 160):
            c.rect(x, y, x, y + 11, K["floor_d"])
    for _ in range(500):
        x, y = rnd.randrange(640), rnd.randrange(WALL_BOTTOM + 2, 360)
        c.px(x, y, K["floor_d"])
    # tatami mat area near the bottom right (sitting corner)
    c.rect(470, 280, 630, 350, (184, 176, 112, 255))
    for y in range(282, 350, 3):
        c.rect(471, y, 629, y, (170, 162, 100, 255))
    c.rect(470, 280, 630, 283, (60, 80, 60, 255)); c.rect(470, 347, 630, 350, (60, 80, 60, 255))
    c.img.save(os.path.join(OUT, "bg.png"))


def win(c, x0, y0, w, h):
    c.rect(x0 - 3, y0 - 3, x0 + w + 3, y0 + h + 3, K["beam"])
    c.rect(x0, y0, x0 + w, y0 + h, K["paper_glow"])
    for x in range(x0, x0 + w + 1, 12):
        c.rect(x, y0, x, y0 + h, K["lattice"])
    for y in range(y0, y0 + h + 1, 11):
        c.rect(x0, y, x0 + w, y, K["lattice"])


def shelf(c, x, y, w):
    c.rect(x, y, x + w, y + 3, K["wood"]); c.rect(x, y + 3, x + w, y + 4, K["wood_d"])
    c.rect(x + 4, y + 4, x + 6, y + 9, K["wood_d"]); c.rect(x + w - 6, y + 4, x + w - 4, y + 9, K["wood_d"])


def items_on_shelf(c, x, y, rnd):
    cx = x
    while cx < x + 100:
        kind = rnd.choice(["bowl", "jar", "stack", "bottle"])
        if kind == "bowl":
            col = rnd.choice([K["bowl_w"], K["bowl_b"]])
            c.ellipse(cx + 6, y - 3, 6, 3, shade(col, 0.8)); c.rect(cx, y - 6, cx + 12, y - 3, col); c.rect(cx + 2, y - 7, cx + 10, y - 6, shade(col, 1.1))
            cx += 15
        elif kind == "jar":
            c.ellipse(cx + 6, y - 8, 6, 8, K["jar"]); c.rect(cx + 3, y - 18, cx + 9, y - 15, shade(K["jar"], 0.8))
            c.rect(cx + 2, y - 10, cx + 10, y - 7, K["paper"]); cx += 15
        elif kind == "stack":
            for i in range(3):
                c.rect(cx, y - 3 - i * 3, cx + 12, y - 1 - i * 3, K["bowl_w"]); c.rect(cx, y - 1 - i * 3, cx + 12, y - 1 - i * 3, K["stone_l"])
            cx += 15
        else:
            c.rect(cx + 2, y - 16, cx + 6, y, K["green"]); c.rect(cx + 3, y - 20, cx + 5, y - 16, K["wood_d"]); cx += 10


def counter():
    c = Canvas(220, 56)
    c.rect(0, 0, 219, 8, K["wood_l"]); c.rect(0, 8, 219, 10, K["wood_d"])
    c.rect(2, 10, 217, 55, K["wood"])
    for x in range(2, 218, 36):
        c.rect(x, 10, x + 1, 55, K["wood_d"])
    c.rect(2, 30, 217, 31, K["wood_d"])
    for x in range(20, 218, 36):
        c.rect(x, 18, x + 2, 20, K["iron"]); c.rect(x, 40, x + 2, 42, K["iron"])
    # cutting board, knife, vegetables on top
    c.rect(140, 1, 190, 6, (214, 176, 120, 255)); c.rect(140, 6, 190, 7, (170, 130, 86, 255))
    c.rect(150, 3, 170, 4, K["stone_l"]); c.rect(170, 3, 176, 4, K["wood_d"])
    c.ellipse(184, 2, 3, 2, K["green"]); c.ellipse(178, 3, 2, 2, (236, 120, 40, 255))
    c.rect(10, 1, 30, 6, K["bowl_w"]); c.ellipse(20, 1, 9, 2, (250, 248, 240, 255))   # rice bowl
    c.outline(color=K["out"], selective=False)
    c.img.save(os.path.join(OUT, "counter.png"))


def door():
    c = Canvas(62, 126)
    c.rect(0, 0, 61, 125, K["beam"])
    c.rect(4, 4, 57, 121, K["paper"])
    for x in range(4, 58, 9):
        c.rect(x, 4, x, 121, K["lattice"])
    for y in range(4, 122, 12):
        c.rect(4, y, 57, y, K["lattice"])
    c.rect(48, 60, 52, 66, K["beam_d"])     # recessed handle
    c.img.save(os.path.join(OUT, "door.png"))


def stove():
    frames = []
    for f in range(4):
        c = Canvas(96, 80)
        # kamado: plastered stone stove with two openings
        c.rect(4, 26, 91, 76, K["stone"]); c.rect(4, 26, 91, 30, K["stone_l"]); c.rect(4, 72, 91, 76, K["stone_d"])
        c.rect(2, 22, 93, 27, K["plaster"]); c.rect(2, 27, 93, 28, K["plaster_d"])
        for ox in (14, 54):
            c.ellipse(ox + 14, 58, 12, 10, (30, 20, 20, 255))
            fl = [(0, 0), (1, -1), (0, -2), (-1, -1)][f]
            c.ellipse(ox + 14 + fl[0], 62, 9, 5, K["fire_d"])
            c.ellipse(ox + 14 + fl[0], 60 + fl[1], 6, 6, K["fire"])
            c.ellipse(ox + 14 - fl[0], 61 + fl[1], 3, 3, K["fire_l"])
            c.rect(ox + 4, 66, ox + 24, 68, K["wood_d"])
        c.outline(color=K["out"], selective=False)
        frames.append(c)
    img = Image.new("RGBA", (96 * 4, 80), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        img.alpha_composite(fr.img, (96 * i, 0))
    img.save(os.path.join(OUT, "stove.png"))


def pot():
    c = Canvas(32, 24)
    c.ellipse(16, 16, 13, 7, K["iron"]); c.rect(3, 8, 29, 16, K["iron"]); c.ellipse(16, 8, 13, 4, K["iron_l"])
    c.ellipse(16, 7, 10, 3, K["wood"]); c.rect(14, 2, 18, 5, K["wood_d"])
    c.rect(0, 10, 3, 12, K["iron"]); c.rect(29, 10, 31, 12, K["iron"])
    c.outline(color=K["out"], selective=False)
    c.img.save(os.path.join(OUT, "pot.png"))


def lantern():
    c = Canvas(16, 26)
    c.rect(3, 0, 12, 2, K["beam"])
    c.rect(2, 3, 13, 21, K["paper_glow"])
    for y in (7, 12, 17):
        c.rect(2, y, 13, y, K["lattice"])
    c.rect(1, 22, 14, 25, K["beam"])
    c.outline(color=K["out"], selective=False)
    c.img.save(os.path.join(OUT, "lantern.png"))


def scroll_wall():
    c = Canvas(28, 66)
    c.rect(1, 0, 26, 3, K["beam"])
    c.rect(3, 3, 24, 60, (238, 228, 200, 255))
    c.rect(3, 3, 24, 8, (120, 60, 50, 255)); c.rect(3, 55, 24, 60, (120, 60, 50, 255))
    # ink mountain + sun painting (sumi-e)
    c.poly([(5, 46), (11, 28), (16, 38), (19, 33), (23, 46)], (70, 70, 74, 255))
    c.poly([(9, 46), (12, 36), (15, 46)], (110, 110, 116, 255))
    c.ellipse(19, 18, 3, 3, (200, 50, 50, 255))
    c.rect(2, 60, 25, 62, K["beam"])
    c.outline(color=K["out"], selective=False)
    c.img.save(os.path.join(OUT, "scroll_wall.png"))


if __name__ == "__main__":
    bg(); counter(); door(); stove(); pot(); lantern(); scroll_wall()
    print("kitchen ok")
