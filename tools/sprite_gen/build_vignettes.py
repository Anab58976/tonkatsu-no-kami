"""Backdrops for the intro's region vignettes + the Cabbage Ogre (no artist art yet).
Ghost City and Spirit Forest backdrops are pixelated crops of the artist's maps."""
import os
import numpy as np
from PIL import Image
from rig import Canvas, SheetWriter, shade
from build_from_refs import kmeans_palette, apply_palette

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source")
OUT = os.path.join(ROOT, "assets", "sprites", "generated", "vignettes")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
os.makedirs(OUT, exist_ok=True)


def pixel_crop(src, box, size=(300, 168), k=40):
    im = Image.open(os.path.join(SRC, src)).convert("RGB").crop(box)
    small = im.resize(size, Image.BOX)
    a = np.array(small.convert("RGBA"))
    pal = kmeans_palette(a[:, :, :3].reshape(-1, 3), k)
    a = apply_palette(a, pal)
    Image.fromarray(a).save(os.path.join(OUT, os.path.splitext(src)[0] + ".png"))


pixel_crop("ref_map_village_night.png", (0, 0, 1448, 814))
pixel_crop("ref_map_spirit_forest.png", (0, 150, 1448, 964))


def ogre(frame=0, attack=False):
    c = Canvas(96, 96)
    by = 1 if frame % 2 else 0
    G, Gd, Gl = (126, 150, 84, 255), (86, 108, 58, 255), (160, 184, 110, 255)
    C, Cd, Cl = (146, 196, 96, 255), (92, 140, 64, 255), (196, 228, 150, 255)
    # legs
    c.rect(30, 70, 42, 90, Gd); c.rect(54, 70, 66, 90, Gd); c.rect(28, 86, 44, 91, (80, 56, 40, 255)); c.rect(52, 86, 68, 91, (80, 56, 40, 255))
    # belly/body + loincloth
    c.ellipse(48, 58 + by, 26, 20, Gd); c.ellipse(47, 57 + by, 24, 18, G); c.ellipse(42, 52 + by, 9, 6, Gl)
    c.rect(30, 70 + by, 66, 76 + by, (140, 70, 50, 255)); c.rect(44, 70 + by, 52, 82 + by, (160, 84, 60, 255))
    # arms (club in right hand)
    arm_y = 40 if attack else 52
    c.limb(24, 48 + by, 14, 66 + by, Gd, 9); c.limb(24, 48 + by, 14, 66 + by, G, 7)
    c.limb(72, 48 + by, 82, arm_y + by, Gd, 9); c.limb(72, 48 + by, 82, arm_y + by, G, 7)
    c.limb(84, arm_y + by, 90, arm_y - 26 + by, (110, 74, 44, 255), 6); c.ellipse(90, arm_y - 26 + by, 5, 6, (130, 90, 54, 255))
    # cabbage head: layered leaves
    hy = 26 + by
    c.ellipse(48, hy, 19, 17, Cd); c.ellipse(48, hy - 1, 17, 15, C)
    for (dx, dy, r) in ((-9, -4, 8), (9, -4, 8), (0, -9, 9), (-12, 5, 6), (12, 5, 6)):
        c.ellipse(48 + dx, hy + dy, r, r - 1, shade(C, 1.06)); c.line(48 + dx, hy + dy - r + 2, 48 + dx, hy + dy + r - 2, Cd)
    c.ellipse(44, hy - 8, 4, 3, Cl)
    # face: angry eyes + tusks
    for sx in (-6, 6):
        c.rect(48 + sx - 2, hy + 2, 48 + sx + 1, hy + 4, (40, 20, 19, 255)); c.px(48 + sx - (1 if sx < 0 else -1), hy + 2, (255, 230, 120, 255))
    c.rect(41, hy - 1, 45, hy, (40, 20, 19, 255)); c.rect(51, hy - 1, 55, hy, (40, 20, 19, 255))
    c.rect(42, hy + 8, 54, hy + 10, (90, 30, 30, 255)); c.rect(43, hy + 6, 44, hy + 8, (250, 248, 230, 255)); c.rect(52, hy + 6, 53, hy + 8, (250, 248, 230, 255))
    c.outline(color=(40, 20, 19, 255), selective=False)
    return c


W = SheetWriter(GEN, "ogro_repolho", 96, 96, origin=(48, 91))
W.add("idle", [ogre(0), ogre(0), ogre(1), ogre(1)], fps=4)
W.add("attack", [ogre(0, True), ogre(1, True), ogre(0)], fps=6, loop=False)
W.close()
print("vignettes ok")
