"""Region palettes (Tonkatsu Reborn, Marco 1).

Each region palette = SHARED core (identical everywhere: the game's identity)
+ a region ramp sampled with k-means from the team's own art for that region
(or from the current in-game art when the team has not sent any yet).

Outputs:
  resources/palettes/palettes.json   {region: {"source": ..., "colors": [hex...]}}
  docs/img/palettes.png              preview (shared core + each region)
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from build_from_refs import kmeans_palette

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "sprites", "source")
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
TILES = os.path.join(ROOT, "assets", "sprites", "tiles", "ground")

# The identity shared by every region (UI, outlines, Lulu, gold of the quest).
SHARED = {
    "ink (contorno)": "2a1613", "ink suave": "4a2c24", "papel washi": "f3e7cf", "papel sombra": "dccaa6",
    "madeira": "5c3a28", "laca vermelha": "a3252e", "laca clara": "c94a45", "dourado": "f0be3c",
    "dourado claro": "fff0a0", "sakura": "e99a98", "Lulu rosa": "f0a6a6", "Lulu sombra": "c8706e",
}

REGIONS = {
    "hub": ("Vila do Rei Porco (dia)", [os.path.join(SRC, "tiles_village_day.png")], 20),
    "swamp": ("Pântano dos Esquecidos", [os.path.join(TILES, f"swamp_{n}_0.png") for n in ("grass", "mud", "stone", "water")]
              + [os.path.join(SRC, "enemy_mushroom_golem.png")], 16),
    "ghost_city": ("Cidade Fantasma", [os.path.join(SRC, "tiles_village_night.png"), os.path.join(SRC, "ref_map_village_night.png")], 20),
    "sky": ("Reino dos Céus", [os.path.join(TILES, f"sky_{n}_0.png") for n in ("grass", "marble", "gold", "cloud")]
            + [os.path.join(GEN, "pegaso_dourado", "idle.png")], 16),
    "spirit_forest": ("Floresta Espiritual", [os.path.join(SRC, "tiles_spirit_forest_a.png"), os.path.join(SRC, "tiles_spirit_forest_b.png")], 20),
    "spice_castle": ("Reino dos Temperos (castelo)", [os.path.join(SRC, "docx", "Monstro_Pimenta_Coroado", "image1.png")], 14),
    "arena": ("Arena dos Deuses (coliseu)", [os.path.join(GEN, "cisne_dourado", "idle.png"), os.path.join(GEN, "lobo_infernal", "idle.png")], 14),
}


def sample(paths, k):
    cols = []
    for p in paths:
        if not os.path.exists(p):
            continue
        a = np.array(Image.open(p).convert("RGBA"))
        m = a[:, :, 3] > 200
        c = a[:, :, :3][m]
        if len(c) > 60000:
            c = c[np.random.default_rng(1).choice(len(c), 60000, replace=False)]
        cols.append(c)
    allc = np.concatenate(cols)
    pal = kmeans_palette(allc, k)
    # order by luminance (dark -> light) so ramps read naturally
    lum = pal.astype(float) @ np.array([0.299, 0.587, 0.114])
    return [("%02x%02x%02x" % tuple(int(v) for v in pal[i])) for i in np.argsort(lum)]


def main():
    out = {"shared": {"source": "núcleo comum", "colors": list(SHARED.values()), "names": list(SHARED.keys())}}
    for rid, (name, paths, k) in REGIONS.items():
        out[rid] = {"name": name, "source": [os.path.relpath(p, ROOT) for p in paths if os.path.exists(p)],
                    "colors": sample(paths, k)}
    os.makedirs(os.path.join(ROOT, "resources", "palettes"), exist_ok=True)
    json.dump(out, open(os.path.join(ROOT, "resources", "palettes", "palettes.json"), "w"), ensure_ascii=False, indent=1)
    # preview
    sw = 22
    rows = list(out.items())
    W = 230 + sw * 24
    H = len(rows) * (sw + 10) + 10
    img = Image.new("RGB", (W, H), (36, 30, 32))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "PixelifySans-Medium.ttf"), 14)
    for r, (rid, p) in enumerate(rows):
        y = 10 + r * (sw + 10)
        d.text((8, y + 3), p.get("name", "Núcleo comum"), fill=(240, 230, 210), font=font)
        for i, h in enumerate(p["colors"]):
            d.rectangle([230 + i * sw, y, 230 + i * sw + sw - 2, y + sw - 2], fill="#" + h)
    os.makedirs(os.path.join(ROOT, "docs", "img"), exist_ok=True)
    img.save(os.path.join(ROOT, "docs", "img", "palettes.png"))
    print({k: len(v["colors"]) for k, v in out.items()})


if __name__ == "__main__":
    main()
