"""Gameplay sound effects the team's pack didn't cover (original, made from code).

Style: matches the team's Freesound picks — punchy, a little retro (square /
triangle waves like the 8-bit jump and 1-up), with wooden and bell touches for
the Japanese setting. Each id is a file the game already asks for.
Output: assets/audio/sfx/<id>.ogg and assets/audio/ambience/<id>.ogg
    python3 tools/audio_gen/game_sfx.py            # all
    python3 tools/audio_gen/game_sfx.py coin hit   # some
"""
from __future__ import annotations

import os
import subprocess
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synth as S  # noqa: E402

SR = S.SR
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
AMB = os.path.join(ROOT, "assets", "audio", "ambience")
RNG = np.random.default_rng(7)


# ------------------------------------------------------------------ building blocks
def T(d):
    return np.arange(int(d * SR), dtype=np.float32) / SR


def env(d, a=0.003, decay=8.0):
    t = T(d)
    e = np.exp(-t * decay)
    na = max(1, int(a * SR))
    e[:na] *= np.linspace(0, 1, na)
    return e.astype(np.float32)


def sweep_phase(f0, f1, d, curve=1.0):
    t = T(d)
    k = (t / d) ** curve
    f = f0 + (f1 - f0) * k
    return 2 * np.pi * np.cumsum(f) / SR


def sq(f0, d, f1=None, duty=0.5, decay=6.0):
    ph = sweep_phase(f0, f1 if f1 else f0, d)
    w = np.where((ph / (2 * np.pi)) % 1.0 < duty, 1.0, -1.0).astype(np.float32)
    w = signal.sosfilt(signal.butter(2, 7000, "lowpass", fs=SR, output="sos"), w).astype(np.float32)
    return w * env(d, 0.002, decay) * 0.35


def tri(f0, d, f1=None, decay=6.0):
    ph = sweep_phase(f0, f1 if f1 else f0, d)
    x = (ph / (2 * np.pi)) % 1.0
    w = (4 * np.abs(x - 0.5) - 1).astype(np.float32)
    return w * env(d, 0.002, decay) * 0.5


def sine(f0, d, f1=None, decay=6.0, curve=1.0):
    return (np.sin(sweep_phase(f0, f1 if f1 else f0, d, curve)) * env(d, 0.002, decay)).astype(np.float32)


def noise(d, lo=None, hi=None, decay=10.0, a=0.002, seed=None):
    r = np.random.default_rng(seed) if seed is not None else RNG
    x = r.standard_normal(int(d * SR)).astype(np.float32)
    if lo and hi:
        x = signal.sosfilt(signal.butter(2, [lo, hi], "bandpass", fs=SR, output="sos"), x)
    elif hi:
        x = signal.sosfilt(signal.butter(2, hi, "lowpass", fs=SR, output="sos"), x)
    elif lo:
        x = signal.sosfilt(signal.butter(2, lo, "highpass", fs=SR, output="sos"), x)
    return (x * env(d, a, decay)).astype(np.float32)


def sweep_noise(d, f0, f1, q=3.0, seed=None):
    """Noise through a moving band-pass (whooshes, wind, water)."""
    r = np.random.default_rng(seed) if seed is not None else RNG
    x = r.standard_normal(int(d * SR)).astype(np.float32)
    out = np.zeros_like(x)
    blk = 256
    for i in range(0, len(x), blk):
        f = f0 + (f1 - f0) * (i / len(x))
        bw = f / q
        sos = signal.butter(2, [max(40, f - bw), min(SR / 2 - 100, f + bw)], "bandpass", fs=SR, output="sos")
        out[i:i + blk] = signal.sosfilt(sos, x[max(0, i - 512):i + blk])[-len(x[i:i + blk]):]
    return out


def mix(parts, d):
    out = np.zeros(int(d * SR), np.float32)
    for st, s, g in parts:
        i = int(st * SR)
        e = min(len(out), i + len(s))
        if e > i:
            out[i:e] += s[:e - i] * g
    f = min(len(out), int(0.012 * SR))
    out[-f:] *= np.linspace(1, 0, f)
    return out


def norm(x, peak=0.8):
    return (x / (np.abs(x).max() + 1e-9) * peak).astype(np.float32)


def verb(x, mix_=0.18, size=0.6):
    x = np.concatenate([x, np.zeros(int(0.35 * SR), np.float32)])
    st = S.reverb(np.stack([x, x], axis=1), size=size, mix=mix_)
    y = st.mean(axis=1).astype(np.float32)
    f = int(0.25 * SR)
    y[-f:] *= np.linspace(1, 0, f)
    return y


def m(n):
    return S.midi_hz(n)


def arp(notes, step, d_each, inst="sq", vel=1.0, duty=0.5):
    parts = []
    for i, n in enumerate(notes):
        f = m(n)
        s = sq(f, d_each, duty=duty, decay=7) if inst == "sq" else tri(f, d_each, decay=6) if inst == "tri" else S.kalimba(f, d_each, 1.0)
        parts.append((i * step, s, vel))
    return parts


# ------------------------------------------------------------------ the sounds
def hit():          # spatula on a small enemy: soft thwack + squish
    return norm(mix([(0, noise(0.09, 300, 3000, 40, seed=1), 0.9), (0, sine(220, 0.12, 70, 30), 1.0),
                     (0.01, sq(520, 0.05, 260, duty=0.25, decay=40), 0.4)], 0.18), 0.85)


def hit_boss():     # heavier: low thump + metallic ring
    return norm(mix([(0, noise(0.12, 150, 2500, 30, seed=2), 1.0), (0, sine(140, 0.25, 45, 14), 1.2),
                     (0.005, S.bell(m(76), 0.2, 0.6, ratio=2.7, index=1.5)[:int(0.4 * SR)], 0.5)], 0.45), 0.9)


def hit_straw():    # training dummy: straw rustle + dull thump
    return norm(mix([(0, noise(0.16, 2000, 8000, 22, seed=3), 0.8), (0, sine(160, 0.1, 80, 30), 0.8),
                     (0.03, noise(0.08, 3000, 9000, 40, seed=4), 0.4)], 0.22), 0.7)


def clank():        # blocked by armour
    return norm(verb(mix([(0, noise(0.03, 2000, 9000, 120, seed=5), 0.8), (0, sine(1250, 0.35, 1210, 10), 0.6),
                          (0, sine(1870, 0.25, 1850, 14), 0.4), (0, sine(3100, 0.15, 3080, 20), 0.3)], 0.45), 0.15), 0.75)


def deflect():      # bright parry ting
    return norm(verb(mix([(0, noise(0.02, 3000, 10000, 150, seed=6), 0.7), (0, sine(1980, 0.45, 2010, 7), 0.8),
                          (0.01, sine(2970, 0.3, 3000, 10), 0.4), (0, sq(990, 0.06, 1500, decay=40), 0.25)], 0.55), 0.2), 0.75)


def iai():          # the wolf's lunge: whoosh + steel shing
    return norm(verb(mix([(0, sweep_noise(0.22, 600, 4000, 2.5, seed=7) * env(0.22, 0.05, 6), 1.0),
                          (0.16, sine(2600, 0.5, 2550, 8), 0.5), (0.16, noise(0.05, 4000, 10000, 60, seed=8), 0.5)], 0.7), 0.2), 0.8)


def throw():
    return norm(mix([(0, sweep_noise(0.2, 400, 2200, 2.0, seed=9) * env(0.2, 0.03, 9), 1.0),
                     (0, tri(330, 0.12, 520, decay=14), 0.3)], 0.24), 0.6)


def spit():         # wet blob
    return norm(mix([(0, sine(500, 0.12, 140, 20), 0.9), (0, noise(0.08, 300, 1800, 35, seed=10), 0.6),
                     (0.04, sine(900, 0.05, 300, 40), 0.3)], 0.18), 0.7)


def roots():        # roots bursting from the ground: creak + earthy rumble
    rumble = noise(0.7, None, 220, 4, a=0.05, seed=11)
    creak = np.sin(sweep_phase(140, 90, 0.5) + 3 * np.sin(sweep_phase(23, 17, 0.5))).astype(np.float32) * env(0.5, 0.05, 4)
    return norm(mix([(0, rumble, 1.0), (0.05, creak, 0.5), (0.1, noise(0.3, 400, 2000, 12, seed=12), 0.4)], 0.8), 0.85)


def thunder():
    crack = noise(0.12, 1500, 9000, 35, seed=13)
    roll = noise(1.6, None, 300, 2.0, a=0.05, seed=14)
    lfo = (0.6 + 0.4 * np.sin(2 * np.pi * 3.5 * T(1.6))).astype(np.float32)
    return norm(verb(mix([(0, crack, 1.0), (0.03, roll * lfo, 1.2), (0, sine(70, 0.6, 40, 5), 0.6)], 1.8), 0.25, 0.9), 0.9)


def defeat():       # Lulu falls: sad descending squares
    return norm(mix(arp([72, 67, 63, 60], 0.14, 0.2, "sq", duty=0.5) + [(0.56, tri(m(48), 0.6, decay=3), 0.8)], 1.3), 0.6)


def chest():        # wooden lid creak + sparkle arpeggio
    creak = np.sin(sweep_phase(260, 380, 0.25) + 2.5 * np.sin(sweep_phase(31, 40, 0.25))).astype(np.float32) * env(0.25, 0.04, 5)
    return norm(verb(mix([(0, creak, 0.45), (0.2, S.woodblock(0.8, 400), 0.8)] + [(0.26 + p[0], p[1], 0.7) for p in arp([79, 83, 86, 91], 0.06, 0.25, "sq", duty=0.25)], 0.9), 0.2), 0.55)


def coin():         # classic two-tone coin
    return norm(mix([(0, sq(m(83), 0.07, decay=4, duty=0.5), 0.8), (0.07, sq(m(88), 0.35, decay=8, duty=0.5), 0.8)], 0.42), 0.34)


def buy():          # coins into the till + shop chime
    return norm(verb(mix([(0, coin(), 0.8), (0.12, coin()[: int(0.3 * SR)], 0.5),
                          (0.18, S.bell(m(91), 0.4, 0.5, ratio=4.0, index=1.0)[: int(0.7 * SR)], 0.6)], 0.9), 0.15), 0.6)


def shop_bell():    # door bell (furin-like)
    return norm(verb(mix([(0, S.bell(m(96), 0.6, 0.8, ratio=4.2, index=1.2)[: int(1.0 * SR)], 1.0),
                          (0.11, S.bell(m(100), 0.5, 0.6, ratio=4.2, index=1.2)[: int(0.9 * SR)], 0.7)], 1.2), 0.25), 0.55)


def equip():        # cloth swish + small clink
    return norm(mix([(0, sweep_noise(0.16, 1500, 5000, 2.0, seed=15) * env(0.16, 0.03, 10), 0.7),
                     (0.1, sine(2300, 0.15, 2280, 25), 0.35), (0.1, sine(3400, 0.1, 3400, 30), 0.2)], 0.3), 0.55)


def use_item():     # drinking a potion: bubbly gulp + up-chime
    bubbles = [(i * 0.05, sine(600 + 120 * i, 0.05, 900 + 140 * i, 40), 0.6) for i in range(4)]
    return norm(mix(bubbles + [(0.22, tri(m(84), 0.25, decay=8), 0.6), (0.28, tri(m(91), 0.25, decay=8), 0.5)], 0.6), 0.6)


def blip():         # dialogue letters: tiny soft square tick (pitch varied by the game)
    return norm(mix([(0, sq(m(79), 0.035, duty=0.25, decay=50), 1.0), (0, S.woodblock(0.3, 1700)[: int(0.03 * SR)], 0.3)], 0.05), 0.35)


def tap():
    return norm(mix([(0, S.woodblock(0.9, 1100), 1.0)], 0.12), 0.4)


def soft_chime():
    return norm(verb(mix([(0, S.bell(m(88), 0.5, 0.6, ratio=3.0, index=0.8)[: int(1.0 * SR)], 1.0)], 1.1), 0.2), 0.45)


def scroll_open():
    return norm(mix([(0, sweep_noise(0.3, 2500, 6000, 2.5, seed=16) * env(0.3, 0.08, 4), 0.7),
                     (0.24, S.woodblock(0.6, 700), 0.6)], 0.45), 0.5)


def level_up():     # rising fanfare
    return norm(verb(mix(arp([72, 76, 79, 84], 0.08, 0.18, "sq", duty=0.5)
                         + [(0.32, sq(m(88), 0.6, decay=3, duty=0.5), 0.8), (0.32, tri(m(76), 0.6, decay=3), 0.6),
                            (0.32, S.bell(m(100), 0.6, 0.3)[: int(0.9 * SR)], 0.5)], 1.2), 0.2), 0.65)


def door_slide():   # shoji sliding: paper + wooden runner rumble
    return norm(mix([(0, noise(0.45, 200, 900, 2.5, a=0.06, seed=17), 0.8),
                     (0, sweep_noise(0.45, 1800, 2800, 3.0, seed=18) * env(0.45, 0.06, 3), 0.5),
                     (0.42, S.woodblock(0.8, 500), 0.7)], 0.6), 0.6)


def lever():
    return norm(mix([(0, S.woodblock(1.0, 300), 1.0), (0.06, noise(0.05, 800, 4000, 50, seed=19), 0.6),
                     (0.12, sine(180, 0.2, 90, 18), 0.9), (0.12, S.woodblock(0.8, 220), 0.8)], 0.4), 0.75)


def wheel():        # ratchet
    return norm(mix([(i * 0.07, S.woodblock(0.8 - i * 0.05, 500 - i * 20), 1.0) for i in range(6)]
                    + [(0, noise(0.45, None, 300, 3, a=0.05, seed=20), 0.5)], 0.6), 0.65)


def water_flow():
    x = sweep_noise(1.6, 600, 900, 1.5, seed=21) + noise(1.6, None, 400, 0.8, a=0.2, seed=22) * 0.8
    e = np.minimum(1, T(1.6) * 3) * np.minimum(1, (1.6 - T(1.6)) * 2)
    return norm(x * e.astype(np.float32), 0.6)


def secret():       # discovery jingle
    return norm(verb(mix(arp([79, 78, 75, 69, 68, 76, 80, 84], 0.09, 0.14, "sq", duty=0.5), 1.1), 0.18), 0.55)


def save():         # prayer chime (two soft bells)
    return norm(verb(mix([(0, S.bell(m(81), 0.8, 0.8, ratio=3.0, index=0.9)[: int(1.4 * SR)], 1.0),
                          (0.18, S.bell(m(88), 0.8, 0.6, ratio=3.0, index=0.9)[: int(1.3 * SR)], 0.8)], 1.6), 0.3), 0.55)


def region_enter():
    return norm(verb(mix([(i * 0.11, S.koto(m(n), 0.25, 0.8), 1.0) for i, n in enumerate([69, 72, 76, 81])]
                         + [(0.44, S.bell(m(81), 1.0, 0.5)[: int(1.4 * SR)], 0.7)], 1.9), 0.25), 0.6)


def wind_gust():
    x = sweep_noise(1.0, 300, 1400, 2.0, seed=23)
    e = np.sin(np.pi * T(1.0) / 1.0).astype(np.float32) ** 1.5
    return norm(x * e, 0.7)


def crystal_on():
    return norm(verb(mix([(0, sine(m(96), 0.8, decay=4), 0.6), (0, sine(m(103), 0.6, decay=5), 0.4),
                          (0.06, sine(m(100), 0.7, decay=4), 0.5), (0, noise(0.04, 5000, 12000, 80, seed=24), 0.3)], 1.0), 0.35, 0.8), 0.55)


def shimmer(notes, step, d=1.2, rev=0.35):
    parts = [(i * step, sine(m(n), 0.5, decay=5) + 0.3 * sine(m(n + 12), 0.5, decay=7), 0.7) for i, n in enumerate(notes)]
    parts.append((0, noise(d * 0.8, 4000, 11000, 2.5, a=0.1, seed=25), 0.15))
    return norm(verb(mix(parts, d), rev, 0.9), 0.55)


def magic_rise():
    return shimmer([72, 76, 79, 83, 86, 91], 0.07)


def magic_fade():
    return shimmer([91, 86, 83, 79, 76], 0.08)


def magic_soft():
    return shimmer([84, 88], 0.12, 0.9)


def magic_bridge():
    return shimmer([67, 71, 74, 79, 83, 86, 91, 95], 0.06, 1.4)


def magic_circle():
    return shimmer([76, 83, 79, 86, 83, 91], 0.09, 1.4)


def enemy_oniguerreiro():   # rice warrior: soft "puff" + tiny wooden clack
    return norm(mix([(0, noise(0.12, 400, 2500, 25, seed=40), 0.7), (0, sine(330, 0.1, 180, 30), 0.6),
                     (0.03, S.woodblock(0.6, 1200), 0.5)], 0.18), 0.6)


def chop():         # knife on a wooden board
    return norm(mix([(0, S.woodblock(1.0, 650), 1.0), (0, noise(0.04, 2500, 9000, 70, seed=26), 0.7),
                     (0, sine(190, 0.08, 120, 40), 0.6)], 0.15), 0.7)


def cook_good():    # sizzle + success chime
    sizzle = noise(0.7, 3000, 9000, 3, a=0.02, seed=27) * (0.7 + 0.3 * np.sin(2 * np.pi * 13 * T(0.7))).astype(np.float32)
    return norm(verb(mix([(0, sizzle, 0.6)] + [(0.3 + p[0], p[1], 0.7) for p in arp([76, 79, 84], 0.07, 0.25, "tri")], 1.0), 0.15), 0.6)


def plate():        # ceramic clink
    return norm(verb(mix([(0, sine(2350, 0.3, 2340, 14), 0.7), (0, sine(3520, 0.2, 3500, 20), 0.4),
                          (0, noise(0.02, 3000, 10000, 150, seed=28), 0.5)], 0.4), 0.12), 0.55)


def title_hit():
    return norm(verb(mix([(0, S.taiko(1.0, 1.3), 1.0), (0, S.bell(m(62), 1.4, 0.7)[: int(2.0 * SR)], 0.8),
                          (0, S.cymbal(0.6, 1.5), 0.5)], 2.0), 0.3, 1.0), 0.85)


def transform_charge():
    hum = sine(110, 2.2, 440, decay=0.0, curve=1.6) * np.minimum(1, T(2.2) * 1.5).astype(np.float32)
    return norm(verb(mix([(0, hum, 0.5), (0, sweep_noise(2.2, 800, 6000, 3.0, seed=29) * np.linspace(0, 1, int(2.2 * SR)).astype(np.float32), 0.4)]
                         + [(0.2 + i * 0.22, sine(m(76 + i * 2), 0.3, decay=6), 0.3) for i in range(8)], 2.4), 0.3), 0.7)


def transform_burst():
    return norm(verb(mix([(0, noise(0.6, 600, 9000, 5, seed=30), 0.8), (0, S.taiko(0.8, 0.9), 0.8)]
                         + [(0.05 + i * 0.04, sq(m(n), 0.25, duty=0.25, decay=8), 0.4) for i, n in enumerate([84, 88, 91, 96, 100])], 1.4), 0.3, 0.9), 0.85)


# ------------------------------------------------------------------ ambience loops
def village():      # birds + light breeze (seamless 24 s)
    d = 24.0
    n = int(d * SR)
    breeze = noise(d, None, 900, 0.0, a=0.0, seed=31) * 0.25
    lfo = (0.6 + 0.4 * np.sin(2 * np.pi * T(d) / 8.0)).astype(np.float32)
    out = breeze * lfo
    r = np.random.default_rng(32)
    for _ in range(16):
        st = r.uniform(0.5, d - 1.5)
        base = r.uniform(2800, 4200)
        for k in range(r.integers(2, 5)):
            chirp = sine(base * r.uniform(0.95, 1.1), 0.09, base * r.uniform(1.15, 1.35), decay=18) * 0.25
            i = int((st + k * 0.12) * SR)
            out[i:i + len(chirp)] += chirp[: n - i]
    return _loopable(out, 0.65)


def kitchen():      # crackling fire + bubbling pot (seamless 20 s)
    d = 20.0
    n = int(d * SR)
    out = noise(d, None, 500, 0.0, a=0.0, seed=33) * 0.18
    r = np.random.default_rng(34)
    for _ in range(260):
        i = int(r.uniform(0, d - 0.05) * SR)
        c = noise(0.02, 1500, 7000, 120, seed=int(r.integers(1e6))) * r.uniform(0.1, 0.5)
        out[i:i + len(c)] += c
    for _ in range(90):
        i = int(r.uniform(0, d - 0.1) * SR)
        f = r.uniform(250, 600)
        b = sine(f, 0.06, f * 1.8, decay=40) * r.uniform(0.08, 0.2)
        out[i:i + len(b)] += b
    return _loopable(out, 0.6)


def _loopable(x, peak):
    f = int(1.0 * SR)
    head = x[:f].copy()
    x = x[f:]
    x[-f:] = x[-f:] * np.linspace(1, 0, f) + head * np.linspace(0, 1, f)
    return norm(x, peak)


ALL = {k: v for k, v in globals().items() if callable(v) and k in [
    "hit", "hit_boss", "hit_straw", "clank", "deflect", "iai", "throw", "spit", "roots", "thunder", "defeat",
    "chest", "coin", "buy", "shop_bell", "equip", "use_item", "blip", "tap", "soft_chime", "scroll_open", "level_up",
    "door_slide", "lever", "wheel", "water_flow", "secret", "save", "region_enter", "wind_gust", "crystal_on",
    "magic_rise", "magic_fade", "magic_soft", "magic_bridge", "magic_circle", "chop", "cook_good", "plate",
    "title_hit", "transform_charge", "transform_burst", "enemy_oniguerreiro"]}
LOOPS = {"village": village, "kitchen": kitchen}


def write(path, x):
    raw = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=raw, check=True)


if __name__ == "__main__":
    os.makedirs(SFX, exist_ok=True)
    os.makedirs(AMB, exist_ok=True)
    want = sys.argv[1:]
    for k, fn in ALL.items():
        if want and k not in want:
            continue
        x = fn()
        write(os.path.join(SFX, k + ".ogg"), x)
        print(f"sfx {k:16s} {len(x) / SR:.2f}s")
    for k, fn in LOOPS.items():
        if want and k not in want:
            continue
        x = fn()
        write(os.path.join(AMB, k + ".ogg"), x)
        print(f"amb {k:16s} {len(x) / SR:.2f}s")
