"""Pixel-art audit of every sprite in the project (Tonkatsu Reborn, Marco 0).

Checks, per animated sprite folder (anims.json):
  * semi-transparent pixels (anti-aliased edges / fake transparency)
  * opaque cell backgrounds (corners not transparent)
  * feet drift: bottom row of the visible pixels must be identical in every
    frame of idle/walk (otherwise the character bobs or "slides")
  * horizontal centre drift in idle animations (> 2 px = sliding)
  * frames touching the cell border (cut-off frames)
  * visible height vs the size standard (docs/ART_DIRECTION.md)
  * outline presence (share of edge pixels that are dark)
Per prop / tile PNG:
  * semi-transparent pixels, opaque background, size, colour count,
    outline presence, "noise" (share of isolated single pixels)

Usage: python3 tools/audit_pixels.py [--json out.json]
"""
from __future__ import annotations

import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
PROPS = os.path.join(ROOT, "assets", "sprites", "props")
TILES = os.path.join(ROOT, "assets", "sprites", "tiles", "ground")

# Size standard (visible height in px) — see docs/ART_DIRECTION.md
STANDARD = {
    "protagonist": (36, 44),
    "npc": (36, 52),
    "enemy_small": (16, 40),
    "enemy_medium": (36, 64),
    "boss": (64, 140),
}
# floating / flying creatures: vertical bobbing in idle is intended
FLOATERS = {"mosquito", "corvo_espectral", "passaro_eletrico", "harpia", "espirito_tempestade", "espirito_errante",
            "chama_azul", "pegaso_dourado", "cisne_dourado", "dragao_vento", "sentinela_celeste", "ovo_dourado"}
# built from the team's sheets (re-gridded / re-animated), not drawn from scratch
DERIVED = {"lulu_pig", "lulu_human", "lulu_human_game", "lulu_transform", "cogumelo", "golem_musgo"}
ROLE = {
    "lulu_pig": "protagonist", "lulu_human_game": "protagonist",
    "rei_porco": "npc",
}


def role_of(cid: str, meta: dict) -> str:
    if cid in ROLE:
        return ROLE[cid]
    if cid.startswith("npc_"):
        return "npc"
    if meta.get("cell_w", 0) >= 96:
        return "boss"
    if meta.get("cell_w", 0) >= 64:
        return "enemy_medium"
    return "enemy_small"


def alpha_stats(a: np.ndarray):
    al = a[:, :, 3]
    semi = int(((al > 0) & (al < 255)).sum())
    opaque = int((al == 255).sum())
    return semi, opaque


def bbox(a: np.ndarray):
    ys, xs = np.where(a[:, :, 3] > 0)
    if len(ys) == 0:
        return None
    return xs.min(), ys.min(), xs.max(), ys.max()


def outline_ratio(a: np.ndarray) -> float:
    """Share of the silhouette's edge pixels that are dark (lum < 70)."""
    m = a[:, :, 3] > 0
    if m.sum() == 0:
        return 0.0
    pad = np.pad(m, 1)
    inner = pad[1:-1, 1:-1] & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
    edge = m & ~inner
    lum = a[:, :, :3].astype(np.float32).mean(axis=2)
    return float((lum[edge] < 70).mean()) if edge.sum() else 0.0


def noise_ratio(a: np.ndarray) -> float:
    """Share of opaque pixels whose colour differs from all 4 neighbours
    (lots of isolated pixels = resampling noise rather than drawn clusters)."""
    m = a[:, :, 3] > 0
    rgb = a[:, :, :3].astype(np.int32)
    h, w = m.shape
    if h < 3 or w < 3:
        return 0.0
    c = rgb[1:-1, 1:-1]
    diff = np.ones(c.shape[:2], bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        n = rgb[1 + dy:h - 1 + dy, 1 + dx:w - 1 + dx]
        diff &= np.abs(c - n).sum(axis=2) > 24
    mm = m[1:-1, 1:-1]
    return float(diff[mm].mean()) if mm.sum() else 0.0


def audit_animated():
    rows = []
    for meta_path in sorted(glob.glob(os.path.join(GEN, "*", "anims.json"))):
        cid = os.path.basename(os.path.dirname(meta_path))
        meta = json.load(open(meta_path))
        cw, ch = meta["cell_w"], meta["cell_h"]
        role = role_of(cid, meta)
        issues = []
        heights = []
        semi_total = 0
        for anim, a in meta["animations"].items():
            img = np.array(Image.open(os.path.join(os.path.dirname(meta_path), a["file"])).convert("RGBA"))
            if img.shape[1] < cw * a["frames"] or img.shape[0] < ch:
                issues.append(("alta", f"{anim}: folha menor que {a['frames']} quadros de {cw}x{ch}"))
                continue
            feet, centers = [], []
            for i in range(a["frames"]):
                fr = img[:ch, i * cw:(i + 1) * cw]
                semi, _ = alpha_stats(fr)
                if not anim.startswith(("die", "collect", "morph")):   # fades are intentional there
                    semi_total += semi
                if fr[0, 0, 3] == 255 and fr[-1, -1, 3] == 255:
                    issues.append(("alta", f"{anim}[{i}]: fundo opaco"))
                b = bbox(fr)
                if b is None:
                    continue
                x0, y0, x1, y1 = b
                # the feet may rest on the bottom row; top/side contact means clipping
                if x0 == 0 or y0 == 0 or x1 == cw - 1:
                    issues.append(("média", f"{anim}[{i}]: quadro encosta na borda da célula (possível corte)"))
                feet.append(y1)
                centers.append((x0 + x1) / 2.0)
                if anim.startswith("idle"):
                    heights.append(y1 - y0 + 1)
            if anim.startswith("idle") and cid not in FLOATERS and len(feet) > 1 and max(feet) - min(feet) > 1:
                issues.append(("média", f"{anim}: pés variam {max(feet) - min(feet)} px entre quadros"))
            if anim.startswith("idle") and len(centers) > 1 and max(centers) - min(centers) > 2:
                issues.append(("média", f"{anim}: personagem desliza {max(centers) - min(centers):.0f} px no idle"))
        if semi_total:
            issues.append(("alta", f"{semi_total} pixels semitransparentes (borda suavizada)"))
        h = int(np.median(heights)) if heights else 0
        lo, hi = STANDARD[role]
        if h and not (lo <= h <= hi):
            issues.append(("alta" if role == "protagonist" else "média", f"altura {h}px fora do padrão {role} ({lo}–{hi}px)"))
        origin = "equipe (derivado)" if cid in DERIVED else ("gerado" if meta.get("generated", True) else "equipe")
        rows.append({"id": cid, "role": role, "cell": f"{cw}x{ch}", "height": h,
                     "generated": bool(meta.get("generated", True)), "origin": origin, "issues": issues})
    return rows


def audit_static(folder: str, kind: str):
    rows = []
    for p in sorted(glob.glob(os.path.join(folder, "*.png"))):
        a = np.array(Image.open(p).convert("RGBA"))
        semi, opaque = alpha_stats(a)
        issues = []
        if kind == "prop":
            if semi:
                issues.append(("alta", f"{semi} pixels semitransparentes"))
            corners = [a[0, 0, 3], a[0, -1, 3], a[-1, 0, 3], a[-1, -1, 3]]
            if all(c == 255 for c in corners) and a.shape[0] > 40:
                issues.append(("alta", "fundo opaco"))
            o = outline_ratio(a)
            nz = noise_ratio(a)
            if o < 0.25:
                issues.append(("baixa", f"contorno fraco ({o:.0%} da borda escura)"))
            if nz > 0.22:
                issues.append(("média", f"textura ruidosa ({nz:.0%} pixels isolados — reamostragem)"))
        colors = len(np.unique(a[a[:, :, 3] > 0][:, :3], axis=0)) if (a[:, :, 3] > 0).any() else 0
        rows.append({"id": os.path.basename(p)[:-4], "size": f"{a.shape[1]}x{a.shape[0]}", "colors": colors, "issues": issues})
    return rows


def main():
    anim = audit_animated()
    props = audit_static(PROPS, "prop")
    tiles = audit_static(TILES, "tile")
    out = {"animated": anim, "props": props, "tiles": tiles}
    if "--json" in sys.argv:
        json.dump(out, open(sys.argv[sys.argv.index("--json") + 1], "w"), ensure_ascii=False, indent=1)
    sev = {"alta": 0, "média": 0, "baixa": 0}
    for group in (anim, props):
        for r in group:
            for s, _ in r["issues"]:
                sev[s] += 1
    print("animated:", len(anim), "props:", len(props), "tiles:", len(tiles), "issues:", sev)
    return out


if __name__ == "__main__" and "--md" not in sys.argv:
    main()


def write_inventory_md(out: dict, path: str) -> None:
    """docs/ASSET_INVENTORY.md — regenerated from the audit (do not edit by hand)."""
    L = ["# ASSET_INVENTORY — Tonkatsu no Kami", "",
         "Gerado por `python3 tools/audit_pixels.py --md docs/ASSET_INVENTORY.md`. Não editar à mão.", "",
         "Origem: **equipe** = arte enviada pela equipe, convertida para a grade do jogo; "
         "**gerado** = desenhado pelo pipeline (provisório até existir arte da equipe).", "",
         "## Personagens e criaturas animadas", "",
         "| id | papel | célula | altura visível | origem | problemas |", "|---|---|---|---|---|---|"]
    for r in out["animated"]:
        probs = "; ".join(t for _, t in r["issues"][:3]) + (f" (+{len(r['issues']) - 3})" if len(r["issues"]) > 3 else "")
        L.append(f"| {r['id']} | {r['role']} | {r['cell']} | {r['height']} px | {r['origin']} | {probs or '—'} |")
    L += ["", "## Objetos de cenário (props)", "",
          f"{len(out['props'])} arquivos em `assets/sprites/props/`.", ""]
    noisy = [r for r in out["props"] if any("ruidosa" in t for _, t in r["issues"])]
    weak = [r for r in out["props"] if any("contorno" in t for _, t in r["issues"])]
    L += [f"- Textura ruidosa de reamostragem: **{len(noisy)}**", f"- Contorno fraco: **{len(weak)}**", "",
          "| id | tamanho | cores | problemas |", "|---|---|---|---|"]
    for r in out["props"]:
        L.append(f"| {r['id']} | {r['size']} | {r['colors']} | {'; '.join(t for _, t in r['issues']) or '—'} |")
    L += ["", "## Tiles de chão", "", "| id | tamanho | cores |", "|---|---|---|"]
    for r in out["tiles"]:
        L.append(f"| {r['id']} | {r['size']} | {r['colors']} |")
    open(path, "w").write("\n".join(L) + "\n")


if "--md" in sys.argv:
    write_inventory_md(main(), sys.argv[sys.argv.index("--md") + 1])
