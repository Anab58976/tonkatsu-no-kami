"""16x16 item icons generated from templates (kind + colours) for every item in
resources/items/items.json that does not define its own "icon".
Output: assets/sprites/generated/icons/<item_id>.png
"""
from __future__ import annotations

import json
import os

from rig import Canvas, shade

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "generated", "icons")
os.makedirs(OUT, exist_ok=True)
INK = (40, 20, 19, 255)


def H(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def sword(c, blade="d8dce4", hilt="8a3a2a", guard="f0be3c", glow=None):
    b = H(blade)
    for i in range(10):
        c.px(4 + i, 11 - i, b); c.px(5 + i, 11 - i, shade(b, 0.8))
    c.px(14, 1, H("ffffff"))
    c.rect(2, 11, 6, 12, H(guard)); c.rect(1, 13, 3, 14, H(hilt)); c.px(4, 12, H(hilt))
    if glow:
        c.px(9, 4, H(glow)); c.px(12, 2, H(glow)); c.px(7, 8, H(glow))


def spear(c, head="7ad0a0", shaft="8a5a2a"):
    for i in range(12):
        c.px(2 + i, 14 - i, H(shaft))
    c.poly([(12, 4), (15, 0), (11, 3)], H(head)); c.rect(12, 2, 14, 4, H(head)); c.px(13, 1, H("ffffff"))


def hammer(c):
    for i in range(9):
        c.px(3 + i, 14 - i, H("7a5236"))
    c.rect(9, 1, 15, 6, H("7a7a86")); c.rect(9, 1, 15, 2, H("a0a0ae")); c.px(12, 4, H("6aaa3a"))


def daggers(c):
    for off in (0, 4):
        for i in range(7):
            c.px(2 + i + off, 12 - i, H("c8e8f8"))
        c.rect(1 + off, 12, 3 + off, 14, H("3a6a8a"))


def armor(c, body="8a5a3a", trim="f0be3c"):
    b = H(body)
    c.poly([(2, 3), (6, 1), (10, 1), (14, 3), (13, 7), (11, 6), (11, 14), (5, 14), (5, 6), (3, 7)], b)
    c.rect(6, 2, 10, 3, H(trim)); c.rect(5, 9, 11, 10, H(trim)); c.px(6, 5, shade(b, 1.25))


def sash(c):
    c.rect(1, 6, 14, 9, H("c0392b")); c.rect(1, 6, 14, 6, H("e35a4a")); c.poly([(10, 9), (13, 14), (11, 14), (9, 10)], H("c0392b"))


def potion(c, liquid="e23a4e", cap="8a5a2a"):
    l = H(liquid)
    c.rect(6, 1, 9, 3, H(cap)); c.rect(6, 4, 9, 5, H("d8e8f0"))
    c.ellipse(7.5, 10, 5, 5, H("d8e8f0")); c.ellipse(7.5, 11, 4, 3.5, l); c.px(5, 8, H("ffffff")); c.px(6, 7, H("ffffff"))


def herb(c, col="7ad0a0"):
    c.line(8, 14, 8, 5, H("4a8a3a"))
    for (x, y) in ((5, 6), (11, 7), (6, 10), (10, 11)):
        c.ellipse(x, y, 2, 1, H(col))


def ore(c):
    c.poly([(2, 12), (5, 4), (11, 3), (14, 9), (11, 14), (4, 14)], H("6a6a76"))
    for (x, y) in ((6, 7), (9, 9), (10, 5)):
        c.rect(x, y, x + 1, y + 1, H("f0e070"))


def feather(c):
    c.line(3, 14, 12, 2, H("4a4a5a"))
    c.poly([(4, 11), (10, 1), (14, 2), (8, 12)], H("a8d8ff")); c.px(12, 3, H("f0f060"))


def goo(c):
    c.ellipse(8, 10, 6, 4, H("6a8a3a")); c.ellipse(7, 8, 3, 3, H("8aaa4a")); c.px(6, 7, H("c0e080"))


def mushroom(c, cap="5ab0f0"):
    c.rect(7, 8, 9, 14, H("e8e0d0")); c.ellipse(8, 7, 6, 4, H(cap)); c.px(6, 5, H("ffffff")); c.px(10, 6, H("ffffff"))


def food(c, kind):
    if kind == "cabbage":
        c.ellipse(8, 9, 6, 5, H("8ac060")); c.line(8, 5, 8, 13, H("5a8a3a"))
    elif kind == "rice":
        c.poly([(1, 8), (15, 8), (12, 14), (4, 14)], H("4a7ab0")); c.ellipse(8, 7, 6, 3, H("f8f8f0"))
    elif kind == "meat":
        c.ellipse(8, 9, 6, 4, H("e08a8a")); c.ellipse(11, 8, 2, 3, H("fff0e8"))
    elif kind == "panko":
        c.rect(3, 4, 12, 14, H("d8b070")); c.rect(3, 4, 12, 6, H("b88a3a"))
        for (x, y) in ((5, 9), (8, 11), (10, 8)):
            c.px(x, y, H("f0d090"))
    elif kind == "egg":
        c.ellipse(8, 9, 4, 5, H("f8f0e0")); c.px(6, 6, H("ffffff"))
    elif kind == "sauce":
        c.rect(5, 2, 10, 14, H("5a2a1a")); c.rect(6, 1, 9, 2, H("c0392b")); c.rect(5, 7, 10, 10, H("f0d090"))
    elif kind == "salt":
        c.ellipse(8, 10, 6, 4, H("e8e8f0")); c.rect(4, 4, 12, 9, H("6a8ab0"))
    elif kind == "sesame":
        for (x, y) in ((4, 8), (7, 10), (10, 7), (12, 11), (6, 6), (9, 12)):
            c.px(x, y, H("f0e0b0")); c.px(x + 1, y, H("c8b080"))
    elif kind == "onigiri":
        c.poly([(8, 2), (14, 13), (2, 13)], H("f8f8f0")); c.rect(5, 10, 11, 13, H("2a3a2a"))
    elif kind == "soup":
        c.poly([(1, 7), (15, 7), (12, 14), (4, 14)], H("8a2a2a")); c.ellipse(8, 7, 6, 2, H("c89a5a")); c.px(6, 6, H("6aaa3a"))
    elif kind == "katsu":
        c.rect(2, 6, 13, 11, H("d89a4a")); c.rect(2, 6, 13, 7, H("f0c070"))
        for x in (5, 8, 11):
            c.rect(x, 6, x, 11, H("a86a2a"))
    elif kind == "bento":
        c.rect(1, 4, 14, 13, H("c0392b")); c.rect(2, 5, 7, 12, H("f8f8f0")); c.rect(8, 5, 13, 8, H("d89a4a")); c.rect(8, 9, 13, 12, H("8ac060"))
    elif kind == "pot":
        c.ellipse(8, 10, 6, 4, H("3a3a44")); c.rect(2, 7, 13, 10, H("3a3a44")); c.rect(5, 4, 10, 6, H("6a6a76"))
    elif kind == "hashi":
        c.line(2, 14, 13, 1, H("f0be3c")); c.line(4, 14, 14, 3, H("d8a030"))


def scroll(c, ribbon="c0392b"):
    c.rect(3, 3, 12, 12, H("f3e3bf")); c.rect(2, 2, 13, 3, H("8a5a2a")); c.rect(2, 12, 13, 13, H("8a5a2a"))
    c.rect(5, 6, 10, 6, H("6a5a4a")); c.rect(5, 8, 9, 8, H("6a5a4a")); c.rect(7, 3, 8, 12, H(ribbon))


def amulet(c, gem="e23a4e"):
    c.line(4, 2, 8, 8, H("f0be3c")); c.line(12, 2, 8, 8, H("f0be3c"))
    c.ellipse(8, 10, 4, 4, H("f0be3c")); c.ellipse(8, 10, 2, 2, H(gem)); c.px(7, 9, H("ffffff"))


def talisman(c, col="f8f0d0"):
    c.rect(4, 1, 11, 14, H(col)); c.rect(4, 1, 11, 2, H("c0392b")); c.rect(6, 5, 9, 5, H("c0392b")); c.rect(7, 4, 8, 11, H("c0392b"))


def lantern(c):
    c.rect(6, 1, 9, 2, H("3a2a2a")); c.rect(4, 3, 11, 12, H("aee8ff")); c.rect(4, 6, 11, 6, H("6a8aa0")); c.rect(4, 9, 11, 9, H("6a8aa0")); c.rect(5, 13, 10, 14, H("3a2a2a"))


def bow(c, col="f0be3c"):
    c.poly([(8, 8), (2, 3), (2, 13)], H(col)); c.poly([(8, 8), (14, 3), (14, 13)], H(col)); c.rect(7, 6, 9, 10, shade(H(col), 0.8))


def hat(c):
    c.ellipse(8, 10, 7, 3, H("e8c878")); c.ellipse(8, 7, 4, 3, H("e35a4a"))


def cloud_candy(c):
    c.line(8, 9, 8, 15, H("c89a5a"))
    c.ellipse(8, 6, 6, 4, H("e8c8e8")); c.ellipse(6, 5, 3, 3, H("f8e8f8")); c.ellipse(10, 6, 3, 3, H("ffffff"))


TEMPLATES = {
    "espada_bambu": lambda c: sword(c, "a8d878", "6a8a3a", "8ab060"),
    "katana_enferrujada": lambda c: sword(c, "b89a7a", "5a3a2a", "8a6a4a"),
    "katana_aco": lambda c: sword(c, "e0e4ec", "2a2a3a", "f0be3c"),
    "katana_espiritual": lambda c: sword(c, "aee8ff", "4a3a6e", "b896ff", glow="ffffff"),
    "lanca_jade": lambda c: spear(c), "martelo_ogro": hammer, "adagas_vento": daggers,
    "espada_celestial": lambda c: sword(c, "fff6c8", "3a5a9a", "f0be3c", glow="8fd3ff"),
    "faixa_aprendiz": sash, "armadura_couro": lambda c: armor(c, "8a5a3a", "c89a5a"),
    "colete_samurai": lambda c: armor(c, "a3252e", "f0be3c"), "armadura_musgo": lambda c: armor(c, "5a8a3a", "a0c060"),
    "manto_espiritual": lambda c: armor(c, "6a8ac0", "e0f0ff"), "armadura_celestial": lambda c: armor(c, "e8e8f0", "8fd3ff"),
    "protecao_real": lambda c: armor(c, "701820", "f0be3c"),
    "pocao_cura": lambda c: potion(c, "e23a4e"), "pocao_cura_grande": lambda c: potion(c, "ff6a8a", "f0be3c"),
    "pocao_energia": lambda c: potion(c, "4ab0e8"), "antidoto": lambda c: potion(c, "7ad04a"),
    "elixir": lambda c: potion(c, "f0be3c", "c0392b"), "resist_fogo": lambda c: potion(c, "f08a2a"),
    "resist_choque": lambda c: potion(c, "f0f060"),
    "erva_lunar": herb, "minerio_brilhante": ore, "pena_tempestade": feather, "gosma_lodo": goo, "cogumelo_azul": mushroom,
    "repolho_comum": lambda c: food(c, "cabbage"), "arroz_comum": lambda c: food(c, "rice"), "carne_porco": lambda c: food(c, "meat"),
    "farinha_panko": lambda c: food(c, "panko"), "ovo_comum": lambda c: food(c, "egg"), "molho_tonkatsu": lambda c: food(c, "sauce"),
    "sal_marinho": lambda c: food(c, "salt"), "gergelim": lambda c: food(c, "sesame"), "hashi_ouro": lambda c: food(c, "hashi"),
    "panela_ferro": lambda c: food(c, "pot"), "onigiri": lambda c: food(c, "onigiri"), "missoshiru": lambda c: food(c, "soup"),
    "katsu_treino": lambda c: food(c, "katsu"), "bento_especial": lambda c: food(c, "bento"),
    "receita_onigiri": lambda c: scroll(c, "6aaa3a"), "receita_missoshiru": lambda c: scroll(c, "8a2a2a"),
    "receita_katsu_treino": lambda c: scroll(c, "d89a4a"), "receita_perdida": lambda c: scroll(c, "6a5a8a"),
    "amuleto_sorte": amulet, "talisma_vida": talisman, "pergaminho_vento": lambda c: scroll(c, "8fd3ff"),
    "reliquia_kitsune": lambda c: amulet(c, "f08a2a"), "lanterna_espiritual": lantern,
    "laco_dourado": bow, "chapeu_festival": hat,
    "amuleto_vento": lambda c: amulet(c, "8fe3ff"), "nuvem_doce": cloud_candy,
}


def main():
    items = json.load(open(os.path.join(ROOT, "resources", "items", "items.json")))
    made = 0
    for iid, d in items.items():
        if d.get("icon"):
            continue
        fn = TEMPLATES.get(iid)
        c = Canvas(16, 16)
        if fn:
            fn(c)
        else:
            scroll(c)
        c.outline(color=INK, selective=False)
        c.img.save(os.path.join(OUT, f"{iid}.png"))
        made += 1
    print(made, "icons")


if __name__ == "__main__":
    main()
