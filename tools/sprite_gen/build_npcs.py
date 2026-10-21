"""Animal-folk villagers for the HUB (TEMPORARY until the artist sends NPC art).

Chibi 40x44 cells, feet at (20, 42), dark outline like the artist's sprites.
Views: down (front), up (back), side (faces right; engine flips for left).
Anims: idle_<d> (2f), walk_<d> (4f), talk (2f, front).
"""
from __future__ import annotations

import os

from rig import Canvas, SheetWriter, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GEN = os.path.join(ROOT, "assets", "sprites", "generated")
OUT = (40, 20, 19, 255)


def H(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


NPCS = {
    # species, fur, fur_light, outfit, outfit_dark, accent, accessory
    "takeshi": dict(sp="boar", fur="7a5236", fl="a07250", out="5b5f6a", od="3e414a", acc="c0392b", item="hammer", extra="headband"),
    "hana": dict(sp="cat", fur="f2e6da", fl="ffffff", out="e48aa0", od="b9607a", acc="f5d36a", item="", extra="flower"),
    "mestre_sapo": dict(sp="frog", fur="6faa4a", fl="a6d47a", out="4a5f9a", od="34446e", acc="f0be3c", item="staff", extra="straw_hat"),
    "yumi": dict(sp="fox", fur="e2843a", fl="fff1e2", out="f4efe6", od="cfc6b8", acc="c0392b", item="", extra="chef_hat"),
    "tanuki": dict(sp="tanuki", fur="8a6a4a", fl="d8c0a0", out="5a3e6e", od="3e2a4e", acc="f0be3c", item="", extra="leaf"),
    "mercador": dict(sp="crow", fur="3a3a48", fl="6a6a7a", out="8a6a3a", od="5e4626", acc="d0a040", item="", extra="backpack"),
    "kenji": dict(sp="dog", fur="d89a5a", fl="fff1e2", out="2f3f6a", od="1f2a4a", acc="e0e0e0", item="bokken", extra="headband"),
    "guarda": dict(sp="pig", fur="f0a6a6", fl="ffd0cc", out="a3252e", od="701820", acc="f0be3c", item="spear", extra="kabuto"),
    "fukuro": dict(sp="owl", fur="9a7a5a", fl="e8d8b8", out="4a6a4a", od="324a32", acc="f0be3c", item="", extra="glasses"),
    "morador_porco": dict(sp="pig", fur="f0a6a6", fl="ffd0cc", out="6a8fc0", od="4a6a96", acc="ffffff", item="", extra=""),
    "moradora_porca": dict(sp="pig", fur="f5b8b0", fl="ffdcd6", out="e6b84a", od="b88a2a", acc="c0392b", item="", extra="flower"),
    "coelha": dict(sp="rabbit", fur="f4f0ea", fl="ffffff", out="8fbf7a", od="6a9a58", acc="e48aa0", item="", extra=""),
    "macaco_velho": dict(sp="monkey", fur="8a5a3a", fl="e8b898", out="7a6a5a", od="5a4a3a", acc="d0d0d0", item="cane", extra=""),
    "crianca_porco": dict(sp="pig", fur="f8b4b4", fl="ffd8d8", out="f08a3a", od="c06a2a", acc="ffffff", item="", extra="", small=True),
    "pescador": dict(sp="otter", fur="7a5a3a", fl="c8a888", out="3a6a7a", od="2a4a56", acc="f0d090", item="rod", extra="straw_hat"),
    "jardineira": dict(sp="rabbit", fur="c8a080", fl="f0e0d0", out="7a9a5a", od="5a7a3a", acc="f0be3c", item="", extra="straw_hat"),
    # the team (group members) as piglets in their own outfits
    "julia": dict(sp="pig", fur="f6b2b8", fl="ffdade", out="8a5ac8", od="643c9a", acc="f8e070", item="", extra="bow"),
    "heloisa": dict(sp="pig", fur="f2aaa4", fl="ffd4ce", out="3aa89a", od="2a7a70", acc="ffffff", item="", extra="beret"),
    "ana": dict(sp="pig", fur="f8bcb4", fl="ffe0d8", out="f07a8a", od="c0546a", acc="7ac0f0", item="", extra="flower2"),
    "leandro": dict(sp="pig", fur="eea098", fl="ffccc4", out="3a5a9a", od="26406e", acc="f0be3c", item="", extra="cap"),
    "kong": dict(sp="pig", fur="e8968e", fl="fcc4bc", out="2a2a32", od="18181e", acc="e23a3a", item="", extra="bandana"),
    "higa": dict(sp="pig", fur="f4ae9e", fl="ffd6ca", out="e8a03a", od="b8782a", acc="3a8a5a", item="", extra="headphones"),
}


def head(c, sp, d, cx, cy, fur, fl, view, blink=False, talk=False, small=False):
    """d: dict of colours; view: down/up/side."""
    r = 7 if not small else 6
    # ears behind the head
    if sp in ("pig", "boar"):
        for s in (-1, 1):
            if view == "side" and s < 0:
                continue
            ex = cx + s * 5 if view != "side" else cx - 2
            c.poly([(ex - 2, cy - 4), (ex + s * 3 if view != "side" else ex - 3, cy - 10), (ex + 3 * s if view != "side" else ex + 3, cy - 4)], shade(fur, 0.9))
    elif sp in ("fox", "cat", "dog", "tanuki"):
        tall = 9 if sp == "fox" else 7
        for s in (-1, 1):
            if view == "side" and s < 0:
                continue
            ex = cx + s * 4 if view != "side" else cx - 1
            c.poly([(ex - 3, cy - 3), (ex + (s * 1 if view != "side" else 0), cy - tall), (ex + 3, cy - 3)], fur)
            if view == "down":
                c.poly([(ex - 1, cy - 4), (ex + s * 1, cy - tall + 3), (ex + 1, cy - 4)], fl)
    elif sp == "rabbit":
        for s in (-1, 1):
            if view == "side" and s < 0:
                continue
            ex = cx + s * 3 if view != "side" else cx - 1
            c.ellipse(ex, cy - 10, 2, 6, fur)
            if view == "down":
                c.ellipse(ex, cy - 10, 1, 4, H("f4b8c0"))
    elif sp in ("monkey", "otter"):
        for s in (-1, 1):
            if view != "side" or s > 0:
                c.ellipse(cx + s * 7 if view != "side" else cx - 4, cy, 2, 2, fl if sp == "monkey" else fur)
    elif sp == "owl":
        for s in (-1, 1):
            if view != "side" or s > 0:
                c.poly([(cx + s * 5 - 2, cy - 5), (cx + s * 6, cy - 10), (cx + s * 5 + 2, cy - 5)], fur)
    # skull
    c.ellipse(cx, cy, r, r - 1, fur)
    if sp == "frog":
        for s in (-1, 1):
            if view != "side" or s > 0:
                c.ellipse(cx + s * 4 if view != "side" else cx + 2, cy - 5, 3, 3, fur)
    if view == "up":
        if sp == "tanuki":
            c.ellipse(cx, cy - 2, r - 2, 2, shade(fur, 0.8))
        return
    # face
    fx = cx + (2 if view == "side" else 0)
    eyes = [(fx - 3, cy), (fx + 3, cy)] if view == "down" else [(cx + 3, cy)]
    if sp == "frog":
        eyes = [(cx - 4, cy - 5), (cx + 4, cy - 5)] if view == "down" else [(cx + 2, cy - 5)]
    if sp == "tanuki" and view == "down":
        c.ellipse(fx - 3, cy, 3, 2, H("3a2a20")); c.ellipse(fx + 3, cy, 3, 2, H("3a2a20"))
    if sp == "owl" and view == "down":
        c.ellipse(fx - 3, cy, 3, 3, fl); c.ellipse(fx + 3, cy, 3, 3, fl)
    if sp in ("fox", "dog", "cat", "rabbit", "monkey", "otter") and view == "down":
        c.ellipse(fx, cy + 3, 4, 3, fl)
    for (ex, ey) in eyes:
        if blink:
            c.rect(ex - 1, ey, ex, ey, OUT)
        else:
            c.rect(ex - (1 if view == "down" else 0), ey - 1, ex, ey + 1, OUT if sp != "tanuki" else H("fff6e0"))
            if sp == "tanuki":
                c.px(ex, ey, OUT)
            c.px(ex, ey - 1, (255, 255, 255, 255))
    # snout / beak / mouth
    if sp in ("pig", "boar"):
        sx = fx if view == "down" else cx + 6
        c.ellipse(sx, cy + 3, 3 if view == "down" else 2, 2, shade(fur, 0.85))
        c.px(sx - 1, cy + 3, OUT); c.px(sx + 1, cy + 3, OUT)
        if sp == "boar":
            c.px(sx - 3, cy + 4, (250, 248, 232, 255)); c.px(sx + 3, cy + 4, (250, 248, 232, 255))
    elif sp in ("crow", "owl"):
        bx = fx if view == "down" else cx + 7
        c.poly([(bx - 2, cy + 2), (bx + (0 if view == "down" else 3), cy + 5), (bx + 2, cy + 2)], H("e0a030"))
    elif sp in ("fox", "dog", "cat", "otter", "monkey", "rabbit"):
        nx = fx if view == "down" else cx + 7
        c.px(nx, cy + 2, OUT)
    elif sp == "frog":
        c.rect(fx - 3, cy + 2, fx + 3, cy + 2, shade(fur, 0.6))
    if talk:
        mx = fx if view == "down" else cx + 4
        c.rect(mx - 1, cy + 5, mx + 1, cy + 6, H("8a2a3a"))
    if view == "down" and sp not in ("frog", "crow", "owl"):
        c.px(fx - 5, cy + 2, H("f08a8a")); c.px(fx + 5, cy + 2, H("f08a8a"))


def body(c, cx, top, d, view, step, small=False):
    out, od, acc = H(d["out"]), H(d["od"]), H(d["acc"])
    fur = H(d["fur"])
    bh = 10 if not small else 7
    bw = 6 if not small else 5
    # legs
    lift = [0, 1, 0, -1][step]
    for s, l in ((-1, max(0, lift)), (1, max(0, -lift))):
        c.rect(cx + s * 3 - 1, top + bh - l, cx + s * 3 + 1, top + bh + 3 - l, shade(fur, 0.7))
    # robe / kimono
    c.poly([(cx - bw, top), (cx + bw, top), (cx + bw + 2, top + bh + 1), (cx - bw - 2, top + bh + 1)], out)
    c.rect(cx - bw - 2, top + bh, cx + bw + 2, top + bh + 1, od)
    if view == "down":
        c.poly([(cx - 3, top), (cx, top + 4), (cx + 3, top)], shade(out, 1.15))   # collar
        c.rect(cx - bw - 1, top + 5, cx + bw + 1, top + 6, acc)                  # obi
    elif view == "up":
        c.rect(cx - bw - 1, top + 5, cx + bw + 1, top + 6, acc)
        c.rect(cx - 2, top + 4, cx + 2, top + 7, shade(acc, 0.8))                 # obi knot
    else:
        c.rect(cx - bw - 1, top + 5, cx + bw + 1, top + 6, acc)
    # arms swing
    sw = [0, 1, 0, -1][step]
    if view == "side":
        c.limb(cx, top + 2, cx + 2 + sw, top + 7, od, 3)
    else:
        c.limb(cx - bw, top + 2, cx - bw - 2, top + 7 + sw, od, 3)
        c.limb(cx + bw, top + 2, cx + bw + 2, top + 7 - sw, od, 3)
        c.px(cx - bw - 2, top + 8 + sw, fur); c.px(cx + bw + 2, top + 8 - sw, fur)


def accessory(c, d, cx, hy, view, small=False):
    e = d.get("extra", "")
    if e == "headband":
        c.rect(cx - 7, hy - 4, cx + 7, hy - 3, H("e8e8e8") if d["acc"] != "e0e0e0" else H("c0392b"))
        if view == "up":
            c.rect(cx - 1, hy - 3, cx + 1, hy + 1, H("e8e8e8"))
    elif e == "straw_hat":
        c.ellipse(cx, hy - 5, 10, 3, H("d8b060")); c.ellipse(cx, hy - 7, 5, 3, H("e8c878")); c.rect(cx - 9, hy - 5, cx + 9, hy - 5, H("b88a3a"))
    elif e == "chef_hat":
        c.ellipse(cx, hy - 10, 6, 4, H("ffffff")); c.rect(cx - 5, hy - 8, cx + 5, hy - 5, H("f4f0ea"))
    elif e == "leaf":
        c.poly([(cx - 1, hy - 7), (cx + 4, hy - 12), (cx + 5, hy - 7)], H("6aaa3a")); c.px(cx + 1, hy - 7, H("3a6a2a"))
    elif e == "flower":
        fx = cx + 5 if view != "up" else cx - 5
        c.ellipse(fx, hy - 5, 2, 2, H(d["acc"])); c.px(fx, hy - 5, H("ffffff"))
    elif e == "kabuto":
        c.ellipse(cx, hy - 3, 8, 5, H("3a3a48")); c.rect(cx - 8, hy - 3, cx + 8, hy - 1, H("2a2a36"))
        c.poly([(cx - 4, hy - 7), (cx, hy - 13), (cx + 4, hy - 7)], H("f0be3c"))
    elif e == "glasses" and view == "down":
        c.rect(cx - 5, hy - 1, cx - 1, hy + 1, H("f0be3c")); c.rect(cx + 1, hy - 1, cx + 5, hy + 1, H("f0be3c"))
    elif e == "bow":
        bx = cx + 5 if view != "up" else cx - 5
        c.poly([(bx - 4, hy - 9), (bx, hy - 7), (bx - 4, hy - 5)], H(d["acc"])); c.poly([(bx + 4, hy - 9), (bx, hy - 7), (bx + 4, hy - 5)], H(d["acc"]))
        c.rect(bx - 1, hy - 8, bx + 1, hy - 6, shade(H(d["acc"]), 0.75))
    elif e == "beret":
        c.ellipse(cx - 1, hy - 7, 8, 3, H("c0392b")); c.rect(cx - 7, hy - 6, cx + 6, hy - 5, H("8a2420")); c.px(cx - 1, hy - 11, H("8a2420"))
    elif e == "flower2":
        for fx in ((cx - 5, cx + 5) if view != "side" else (cx + 3,)):
            c.ellipse(fx, hy - 6, 2, 2, H(d["acc"])); c.px(fx, hy - 6, H("fff0a0"))
    elif e == "cap":
        c.ellipse(cx, hy - 6, 7, 4, H(d["acc"])); c.rect(cx - 7, hy - 5, cx + 7, hy - 4, shade(H(d["acc"]), 0.8))
        if view == "down":
            c.rect(cx - 6, hy - 4, cx + 6, hy - 3, shade(H(d["acc"]), 0.6))          # visor
        elif view == "side":
            c.rect(cx + 2, hy - 4, cx + 9, hy - 3, shade(H(d["acc"]), 0.6))
    elif e == "bandana":
        c.rect(cx - 7, hy - 6, cx + 7, hy - 4, H(d["acc"]))
        for k in range(-6, 7, 3):
            c.px(cx + k, hy - 5, H("ffffff"))
        if view != "down":
            c.poly([(cx - 8, hy - 5), (cx - 12, hy - 2), (cx - 9, hy - 1)], H(d["acc"]))
    elif e == "headphones":
        c.rect(cx - 7, hy - 10, cx + 7, hy - 9, H("2a2a32"))
        if view != "side":
            c.rect(cx - 9, hy - 4, cx - 6, hy + 1, H(d["acc"])); c.rect(cx + 6, hy - 4, cx + 9, hy + 1, H(d["acc"]))
        else:
            c.rect(cx - 2, hy - 4, cx + 1, hy + 1, H(d["acc"]))
    elif e == "backpack":
        bx = cx if view == "up" else (cx - 7 if view == "side" else None)
        if bx is not None:
            c.rect(bx - 6, hy + 6, bx + 6, hy + 18, H("8a5a2a")); c.rect(bx - 5, hy + 4, bx + 5, hy + 6, H("6a8a4a"))


def item(c, d, cx, top, view, step):
    it = d.get("item", "")
    if not it or view == "up":
        return
    hx = cx + 8 if view == "down" else cx + 3
    hy = top + 7
    if it == "hammer":
        c.rect(hx, hy - 6, hx, hy + 2, H("8a5a2a")); c.rect(hx - 2, hy - 8, hx + 2, hy - 6, H("8a8a96"))
    elif it == "staff":
        c.rect(hx, hy - 12, hx, hy + 4, H("8a5a2a")); c.ellipse(hx, hy - 13, 2, 2, H("7ad0f0"))
    elif it == "spear":
        c.rect(hx, hy - 16, hx, hy + 4, H("6a4a2a")); c.poly([(hx - 1, hy - 16), (hx, hy - 20), (hx + 1, hy - 16)], H("d0d0d8"))
    elif it == "bokken":
        c.rect(hx, hy - 10, hx, hy + 2, H("c89a5a"))
    elif it == "cane":
        c.rect(hx, hy - 2, hx, hy + 8, H("6a4a2a")); c.rect(hx - 2, hy - 2, hx, hy - 2, H("6a4a2a"))
    elif it == "rod":
        c.line(hx, hy + 2, hx + 6, hy - 12, H("8a6a3a")); c.px(hx + 7, hy - 11, H("e0e0e0"))


def draw(d, view, step=0, blink=False, talk=False, bob=0):
    small = d.get("small", False)
    # 40x44 cell: 12 px of headroom so hats, ears and helmets are never cut
    c = Canvas(40, 44)
    cx = 20
    top = (17 if not small else 19) + 12 + bob
    hy = (11 if not small else 14) + 12 + bob
    if d.get("extra") == "backpack" and view == "up":
        pass
    if view == "side" and d["sp"] in ("fox", "dog", "cat", "pig", "tanuki", "boar"):
        # tail behind
        tail = {"fox": H(d["fur"]), "dog": H(d["fur"]), "cat": H(d["fur"]), "tanuki": H("5a4030"), "pig": H(d["fur"]), "boar": H(d["fur"])}[d["sp"]]
        c.ellipse(cx - 7, top + 6, 3 if d["sp"] in ("fox", "tanuki") else 1, 2, tail)
    body(c, cx, top, d, view, step, small)
    if view == "up" and d["sp"] in ("fox", "tanuki", "cat", "dog"):
        c.ellipse(cx + 1, top + 9, 3 if d["sp"] in ("fox", "tanuki") else 2, 3, H(d["fur"]) if d["sp"] != "tanuki" else H("5a4030"))
        if d["sp"] == "fox":
            c.ellipse(cx + 1, top + 11, 2, 1, H("fff1e2"))
    head(c, d["sp"], d, cx if view != "side" else cx - 1, hy, H(d["fur"]), H(d["fl"]), view, blink, talk, small)
    accessory(c, d, cx, hy, view, small)
    item(c, d, cx, top, view, step)
    if d.get("extra") == "backpack" and view == "down":
        c.rect(cx - 9, top + 1, cx - 7, top + 8, H("8a5a2a")); c.rect(cx + 7, top + 1, cx + 9, top + 8, H("8a5a2a"))
    c.outline(color=OUT, selective=False)
    return c


def main():
    for nid, d in NPCS.items():
        W = SheetWriter(GEN, "npc_" + nid, 40, 44, origin=(20, 42))
        for view in ("down", "up", "side"):
            W.add(f"idle_{view}", [draw(d, view), draw(d, view, bob=0), draw(d, view, blink=view != "up"), draw(d, view, bob=0)], fps=3)
            W.add(f"walk_{view}", [draw(d, view, s, bob=-(s % 2)) for s in range(4)], fps=8)
        W.add("talk", [draw(d, "down", talk=True), draw(d, "down"), draw(d, "down", talk=True), draw(d, "down", blink=True)], fps=8)
        W.close()
    print(len(NPCS), "npcs")


if __name__ == "__main__":
    main()
