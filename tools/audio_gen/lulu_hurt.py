"""Lulu's damage sound: a small, cute "oinc!" that fits a piglet.

The team's pig squeal (DANO) felt too big for Lulu, so the hurt sound is built
from the first grunt of the team's own oink (SOM DA LULU), pitched up to a
piglet's voice and shortened, over a soft little impact thump and a tiny
retro "hit" blip like the rest of the game's effects.
    python3 tools/audio_gen/lulu_hurt.py <path to 510974__krzpia__oink.wav>
Output: assets/audio/sfx/hurt.ogg
"""
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import game_sfx as G  # noqa: E402

SR = G.SR
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def load_oink(src, pitch=1.4):
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-t", "0.2", "-i", src,
                                   "-af", f"highpass=f=150,asetrate=44100*{pitch},aresample={SR}",
                                   "-ac", "1", "-f", "s16le", "-"])
    x = np.frombuffer(raw, np.int16).astype(np.float32) / 32768
    f = int(0.03 * SR)
    x[-f:] *= np.linspace(1, 0, f)
    x[:int(0.004 * SR)] *= np.linspace(0, 1, int(0.004 * SR))
    return x / (np.abs(x).max() + 1e-9)


def main(src):
    oink = load_oink(src)
    thump = G.sine(190, 0.09, 90, 38)
    tick = G.noise(0.05, 300, 2500, 60, seed=51)
    blip = G.sq(G.m(84), 0.05, G.m(76), duty=0.25, decay=40)
    x = G.mix([(0, thump, 0.55), (0, tick, 0.25), (0.0, blip, 0.18), (0.025, oink, 0.85)], 0.24)
    x = G.norm(x, 0.55)
    out = os.path.join(ROOT, "assets", "audio", "sfx", "hurt.ogg")
    G.write(out, x)
    print("hurt.ogg", round(len(x) / SR, 2), "s")


if __name__ == "__main__":
    main(sys.argv[1])
