"""Names the extracted tileset pieces and writes res://assets/sprites/props/
<name>.png + props.json with collision footprints used by the world builder.

props.json entry: {"file": "...png", "w":, "h":, "solid": bool,
                   "fp": [width_px, height_px]   # collision rect at the base, centred
                   "kind": "tree|building|decor|..."}
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DAY = os.path.join(ROOT, "assets", "sprites", "tiles", "village_day")
NIGHT = os.path.join(ROOT, "assets", "sprites", "tiles", "village_night")
OUT = os.path.join(ROOT, "assets", "sprites", "props")
os.makedirs(OUT, exist_ok=True)

# name: (set, index, kind, solid, fp=(w_frac, h_frac) of sprite)
DAY_NAMES = {
    "sakura_big": (0, "tree", True, (0.16, 0.08)), "sakura_big_b": (1, "tree", True, (0.16, 0.08)),
    "tree_big_bush": (2, "tree", True, (0.2, 0.08)), "tree_big": (3, "tree", True, (0.2, 0.08)),
    "tree_big_b": (4, "tree", True, (0.2, 0.08)), "tree_big_c": (5, "tree", True, (0.2, 0.08)),
    "sakura_mid": (6, "tree", True, (0.2, 0.1)), "tree_mid": (7, "tree", True, (0.25, 0.1)),
    "sakura_small": (8, "tree", True, (0.25, 0.12)), "tree_small": (9, "tree", True, (0.25, 0.12)),
    "bush_flower": (10, "bush", True, (0.8, 0.4)), "bush_sakura": (11, "bush", True, (0.8, 0.4)),
    "bush_white": (12, "bush", True, (0.8, 0.4)), "hedge_long": (13, "bush", True, (0.95, 0.45)),
    "hedge_long_b": (14, "bush", True, (0.95, 0.45)), "bush_small": (15, "bush", True, (0.8, 0.4)),
    "bush_tall": (16, "bush", True, (0.7, 0.3)),
    "rock_big": (33, "rock", True, (0.8, 0.45)), "rock_s": (34, "rock", True, (0.8, 0.5)),
    "rock_mid": (36, "rock", True, (0.8, 0.45)), "rock_b": (51, "rock", True, (0.8, 0.45)),
    "cliff_a": (37, "cliff", True, (0.95, 0.7)), "cliff_b": (38, "cliff", True, (0.95, 0.7)),
    "cliff_long": (39, "cliff", True, (0.95, 0.7)),
    "waterfall": (75, "water", True, (0.95, 0.5)), "waterfall_b": (76, "water", True, (0.95, 0.5)),
    "bush_flower_big": (85, "bush", True, (0.8, 0.4)), "bridge_arch": (86, "bridge", False, (0, 0)),
    "fence_long": (87, "fence", True, (1.0, 0.3)), "fence_mid": (88, "fence", True, (1.0, 0.3)),
    "tree_tiny": (94, "tree", True, (0.3, 0.15)), "lantern_post": (95, "lantern", True, (0.5, 0.15)),
    "notice_board": (96, "decor", True, (0.9, 0.2)), "dock": (97, "decor", False, (0, 0)),
    "boat": (98, "decor", True, (0.9, 0.5)), "torii": (99, "torii", False, (0, 0)),
    "tree_small_c": (101, "tree", True, (0.3, 0.12)), "bench": (102, "decor", True, (0.95, 0.4)),
    "well_roofed": (103, "decor", True, (0.85, 0.35)), "stairs": (104, "stairs", False, (0, 0)),
    "stone_lantern": (108, "lantern", True, (0.7, 0.2)), "fence_low": (109, "fence", True, (1.0, 0.35)),
    "stone_lantern_b": (110, "lantern", True, (0.7, 0.2)), "bench_b": (114, "decor", True, (0.95, 0.4)),
    "stone_lantern_c": (117, "lantern", True, (0.7, 0.2)), "potted_tree": (118, "decor", True, (0.7, 0.3)),
    "crate": (119, "decor", True, (0.9, 0.5)), "sign": (120, "decor", True, (0.5, 0.2)),
    "signpost": (121, "decor", True, (0.4, 0.15)), "flower_planter": (122, "decor", True, (0.9, 0.3)),
    "stone_lantern_d": (123, "lantern", True, (0.7, 0.2)), "stone_lantern_e": (124, "lantern", True, (0.7, 0.2)),
    "flower_pot": (125, "decor", True, (0.8, 0.4)), "potted_bush": (126, "decor", True, (0.8, 0.4)),
    "flower_pot_b": (127, "decor", True, (0.8, 0.4)), "crop_field": (128, "field", False, (0, 0)),
    "crop_fenced": (129, "field", True, (1.0, 0.25)), "crop_small": (130, "field", False, (0, 0)),
    "hay_bales": (131, "decor", True, (0.9, 0.4)), "crop_fenced_small": (132, "field", True, (1.0, 0.25)),
    "fence_gate": (133, "fence", True, (1.0, 0.3)), "flower_basket": (134, "decor", True, (0.8, 0.4)),
    "fuji_mural": (135, "backdrop", False, (0, 0)), "crop_plot": (136, "field", False, (0, 0)),
    "jizo": (137, "decor", True, (0.7, 0.25)), "flower_stand": (138, "decor", True, (0.7, 0.3)),
    "flower_stand_b": (139, "decor", True, (0.7, 0.3)), "radish_field": (140, "field", False, (0, 0)),
    "cabbage_field": (141, "field", False, (0, 0)), "sprout_field": (142, "field", False, (0, 0)),
    "wheat_bundle": (143, "decor", True, (0.9, 0.4)), "hay": (144, "decor", True, (0.9, 0.4)),
    "well_stone": (145, "decor", True, (0.6, 0.35)), "notice_board_b": (146, "decor", True, (0.9, 0.2)),
    "stone_marker": (147, "decor", True, (0.6, 0.2)),
}
for i in range(17, 33):
    DAY_NAMES[f"flora_{i}"] = (i, "flora", False, (0, 0))

NIGHT_NAMES = {   # (index, kind, solid, fp) — also exported "daylit" for the HUB
    "shrine_stairs": (98, "building", True, (0.6, 0.18)), "house_tree": (99, "building", True, (0.62, 0.22)),
    "house_tall": (114, "building", True, (0.9, 0.22)), "house_small": (115, "building", True, (0.9, 0.22)),
    "hall_red": (116, "building", True, (0.92, 0.22)), "bridge_red": (55, "bridge", False, (0, 0)),
    "torii_red": (65, "torii", False, (0, 0)), "wall_a": (48, "wall", True, (1.0, 0.45)),
    "wall_b": (49, "wall", True, (1.0, 0.45)), "wall_c": (50, "wall", True, (1.0, 0.45)),
    "wall_d": (51, "wall", True, (1.0, 0.45)), "gate_shrine": (66, "building", True, (0.9, 0.3)),
    "small_shrine": (83, "decor", True, (0.8, 0.3)), "stone_tablet": (86, "decor", True, (0.7, 0.2)),
    "lantern_red": (64, "lantern", True, (0.4, 0.1)), "banner_red": (61, "decor", True, (0.3, 0.06)),
    "komainu": (89, "decor", True, (0.8, 0.3)), "komainu_b": (93, "decor", True, (0.8, 0.3)),
    "cart": (105, "decor", True, (0.9, 0.35)), "crate_n": (106, "decor", True, (0.9, 0.4)),
    "barrels": (125, "decor", True, (0.9, 0.4)), "barrel": (126, "decor", True, (0.8, 0.4)),
    "maple_red": (117, "tree", True, (0.2, 0.1)), "sakura_bonsai": (119, "tree", True, (0.2, 0.1)),
    "maple_red_b": (120, "tree", True, (0.2, 0.1)), "pine": (121, "tree", True, (0.25, 0.1)),
    "pine_big": (122, "tree", True, (0.25, 0.1)), "well_night": (58, "decor", True, (0.8, 0.35)),
    "lantern_tall": (77, "lantern", True, (0.5, 0.1)), "dock_n": (57, "decor", False, (0, 0)),
    "pond_dock": (136, "decor", False, (0, 0)), "fuji_red": (133, "backdrop", False, (0, 0)),
}


def daylit(a: np.ndarray) -> np.ndarray:
    a = a.astype(np.float32)
    rgb = a[:, :, :3] / 255.0
    warm = (rgb[:, :, 0:1] > 0.55) & (rgb[:, :, 1:2] > 0.35) & (rgb[:, :, 2:3] < 0.35)
    lifted = np.power(rgb, 0.62) * 1.08
    out = np.where(warm, rgb * 0.85 + 0.1, lifted)
    a[:, :, :3] = out.clip(0, 1) * 255
    return a.astype(np.uint8)


def split_houses(a: np.ndarray):
    """Day piece 69 holds two buildings side by side: cut at the emptiest column near the middle."""
    col = (a[:, :, 3] > 0).sum(axis=0)
    w = a.shape[1]
    lo, hi = int(w * 0.33), int(w * 0.5)
    cut = lo + int(np.argmin(col[lo:hi]))
    return a[:, :cut], a[:, cut:]


def trim(a):
    ys, xs = np.where(a[:, :, 3] > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def main():
    props = {}

    def put(name, arr, kind, solid, fp):
        arr = trim(arr)
        Image.fromarray(arr).save(os.path.join(OUT, f"{name}.png"))
        h, w = arr.shape[:2]
        props[name] = {"file": f"{name}.png", "w": int(w), "h": int(h), "kind": kind, "solid": solid,
                       "fp": [max(4, int(w * fp[0])), max(4, int(h * fp[1]))] if solid else [0, 0]}

    for name, (i, kind, solid, fp) in DAY_NAMES.items():
        put(name, np.array(Image.open(os.path.join(DAY, f"piece_{i}.png"))), kind, solid, fp)
    shop, house = split_houses(np.array(Image.open(os.path.join(DAY, "piece_69.png"))))
    put("shop_day", shop, "building", True, (0.8, 0.22))
    put("house_day", house, "building", True, (0.8, 0.2))
    for name, (i, kind, solid, fp) in NIGHT_NAMES.items():
        raw = np.array(Image.open(os.path.join(NIGHT, f"piece_{i}.png")))
        put("n_" + name, raw, kind, solid, fp)
        put("d_" + name, daylit(raw), kind, solid, fp)
    json.dump(props, open(os.path.join(OUT, "props.json"), "w"), indent=1)
    print(len(props), "props;", {k: (v["w"], v["h"]) for k, v in props.items() if k in ("shop_day", "house_day", "d_hall_red", "torii", "sakura_big")})


if __name__ == "__main__":
    main()
