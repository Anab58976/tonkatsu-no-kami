"""Forest-sheet props in two grades: f_* (original spirit-forest look) and
s_* (swamp grade: teal/blue shifted toward murky olive, a bit darker).
Also builds seamless swamp/forest ground tiles. Appends to props.json."""
import json, os
import numpy as np
from PIL import Image
from build_props import trim
from build_ground import seamless, variants, OUT as GROUND_OUT

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
B = os.path.join(ROOT, "assets", "sprites", "tiles", "forest_b")
PROPS = os.path.join(ROOT, "assets", "sprites", "props")
SRC = os.path.join(ROOT, "assets", "sprites", "source", "tiles_spirit_forest_b.png")

NAMES = {  # name: (index, kind, solid, fp)
    "tree_a": (50, "tree", True, (0.2, 0.08)), "tree_glow": (51, "tree", True, (0.2, 0.08)), "tree_b": (52, "tree", True, (0.2, 0.08)),
    "tree_c": (53, "tree", True, (0.2, 0.08)), "tree_glow_b": (54, "tree", True, (0.2, 0.08)), "tree_d": (55, "tree", True, (0.2, 0.08)),
    "tree_e": (56, "tree", True, (0.2, 0.08)), "dead_tree": (57, "tree", True, (0.2, 0.08)), "dead_tree_b": (58, "tree", True, (0.2, 0.08)),
    "dead_tree_c": (59, "tree", True, (0.2, 0.08)), "cliff_a": (60, "cliff", True, (0.95, 0.6)), "cliff_b": (61, "cliff", True, (0.95, 0.6)),
    "pillar_rock": (63, "cliff", True, (0.9, 0.3)), "bush_a": (66, "bush", True, (0.8, 0.4)), "bush_flowers": (67, "bush", True, (0.8, 0.4)),
    "bush_b": (69, "bush", True, (0.8, 0.4)), "bush_c": (70, "bush", True, (0.8, 0.4)), "bush_flowers_b": (71, "bush", True, (0.8, 0.4)),
    "fern": (74, "flora", False, (0, 0)), "fern_b": (75, "flora", False, (0, 0)), "bush_big": (76, "bush", True, (0.85, 0.4)),
    "rock_a": (79, "rock", True, (0.85, 0.5)), "rock_s": (80, "rock", True, (0.8, 0.5)), "rock_b": (81, "rock", True, (0.85, 0.5)),
    "block_moss": (83, "rock", True, (0.95, 0.5)), "block_moss_b": (84, "rock", True, (0.95, 0.5)), "reeds": (100, "flora", False, (0, 0)),
    "lilies": (101, "flora", False, (0, 0)), "reeds_b": (102, "flora", False, (0, 0)), "rocks_pile": (105, "rock", True, (0.85, 0.4)),
    "ruin_wall": (108, "ruin", True, (0.95, 0.5)), "log": (109, "decor", True, (0.9, 0.3)), "roots": (110, "decor", False, (0, 0)),
    "mushrooms_glow": (115, "flora", False, (0, 0)), "log_big": (116, "decor", True, (0.7, 0.2)), "reeds_tall": (117, "flora", False, (0, 0)),
    "mushroom_s": (119, "flora", False, (0, 0)), "mushroom_t": (121, "flora", False, (0, 0)), "stump": (130, "decor", True, (0.7, 0.3)),
    "log_moss": (136, "decor", True, (0.9, 0.3)), "fog_big": (147, "fog", False, (0, 0)), "fog_a": (148, "fog", False, (0, 0)),
    "fog_b": (149, "fog", False, (0, 0)), "rune_stone": (150, "ruin", True, (0.7, 0.2)), "ruin_pillar": (151, "ruin", True, (0.7, 0.2)),
    "ruin_pillars": (152, "ruin", True, (0.85, 0.2)), "rune_stone_b": (153, "ruin", True, (0.7, 0.2)), "lamp_post": (154, "lantern", True, (0.3, 0.06)),
    "ruin_low": (155, "ruin", True, (0.95, 0.3)), "great_tree": (156, "tree", True, (0.25, 0.1)), "moon_arch": (157, "ruin", False, (0, 0)),
    "ruin_arch_b": (158, "ruin", True, (0.9, 0.2)), "ruin_block": (159, "ruin", True, (0.85, 0.3)), "lamp_post_b": (160, "lantern", True, (0.3, 0.06)),
    "pond_big": (163, "decor", False, (0, 0)), "ruin_bits": (164, "ruin", True, (0.85, 0.3)), "stepping_stones": (179, "decor", False, (0, 0)),
}


def swamp_grade(a):
    a = a.astype(np.float32)
    rgb = a[:, :, :3] / 255.0
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    lum = rgb.mean(axis=2)
    glow = (b > 0.75) & (lum > 0.6)                     # keep magical highlights, shift them to pale green
    nr = g * 0.75 + r * 0.35
    ng = g * 0.85 + b * 0.25
    nb = b * 0.35 + r * 0.15
    out = np.stack([nr, ng, nb], axis=2) * 0.92
    out[glow] = np.stack([lum, lum * 1.05, lum * 0.6], axis=1)[glow.reshape(-1)[glow.reshape(-1)].nonzero()[0] * 0] if False else out[glow]
    a[:, :, :3] = out.clip(0, 1) * 255
    return a.astype(np.uint8)


def main():
    db = json.load(open(os.path.join(PROPS, "props.json")))
    for name, (i, kind, solid, fp) in NAMES.items():
        raw = trim(np.array(Image.open(os.path.join(B, f"piece_{i}.png"))))
        for prefix, arr in (("f_", raw), ("s_", swamp_grade(raw))):
            Image.fromarray(arr).save(os.path.join(PROPS, f"{prefix}{name}.png"))
            h, w = arr.shape[:2]
            db[prefix + name] = {"file": f"{prefix}{name}.png", "w": int(w), "h": int(h), "kind": kind, "solid": solid,
                                 "fp": [max(4, int(w * fp[0])), max(4, int(h * fp[1]))] if solid else [0, 0]}
    json.dump(db, open(os.path.join(PROPS, "props.json"), "w"), indent=1)
    # ground tiles from forest_b squares
    meta = {m["i"]: m for m in json.load(open(os.path.join(B, "pieces.json")))}
    src = np.array(Image.open(SRC).convert("RGBA"))
    def crop(i, inset=10):
        x0, y0, x1, y1 = meta[i]["bbox"]
        sub = src[y0 + inset:y1 - inset, x0 + inset:x1 - inset].copy(); sub[:, :, 3] = 255
        return np.array(Image.fromarray(sub).resize((32, 32), Image.BOX))
    spec = {"forest_floor": (4, False), "forest_moss": (2, False), "forest_stone": (20, False), "forest_water": (9, False),
            "swamp_grass": (4, True), "swamp_mud": (1, True), "swamp_stone": (21, True), "swamp_water": (9, True)}
    for name, (idx, sw) in spec.items():
        t = crop(idx)
        if sw:
            t = swamp_grade(t)
            if name == "swamp_water":
                t[:, :, :3] = (t[:, :, :3] * np.array([0.8, 0.98, 0.85])).clip(0, 255).astype(np.uint8)
        t = seamless(t, 12)
        for k, v in enumerate(variants(t)):
            Image.fromarray(v).save(os.path.join(GROUND_OUT, f"{name}_{k}.png"))
    print(len(NAMES) * 2, "biome props; ground ok")


if __name__ == "__main__":
    main()
