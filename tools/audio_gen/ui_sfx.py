"""Menu / interface sound effects (original, generated from code).

Soft wooden and bell tones that fit the Japanese theme:
  ui_hover    cursor moves over an option (tiny wood tick + high pluck)
  ui_select   option clicked (koto pluck)
  ui_confirm  action confirmed (two-note koto + small bell)
  ui_back     back / close (descending soft pluck)
  ui_open     opening a panel (paper slide + chime)
  ui_error    unavailable option (muted low double tick)
  game_start  starting the game (rising koto run + temple bell)
Output: assets/audio/sfx/<id>.wav (short, 16-bit, peak-normalised).
"""
from __future__ import annotations

import os
import sys

import numpy as np
from scipy import signal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synth as S  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "sfx")


def mix(parts, length):
    n = int(length * S.SR)
    out = np.zeros(n, np.float32)
    for start, snd in parts:
        s = int(start * S.SR)
        e = min(n, s + len(snd))
        out[s:e] += snd[:e - s]
    # fade the very end to avoid a click
    f = min(len(out), int(0.02 * S.SR))
    out[-f:] *= np.linspace(1, 0, f)
    return out


def norm(x, peak):
    return x / (np.abs(x).max() + 1e-9) * peak


def paper(dur=0.18):
    n = int(dur * S.SR)
    t = S.t_axis(n)
    nz = np.random.default_rng(2).standard_normal(n).astype(np.float32)
    nz = signal.sosfilt(signal.butter(2, [1500, 6000], "bandpass", fs=S.SR, output="sos"), nz)
    return (nz * S.env_adsr(n, 0.04, 0.05, 0.5, 0.08) * 0.25).astype(np.float32)


def m(n):
    return S.midi_hz(n)


SFX = {
    "ui_hover": lambda: norm(mix([(0, S.woodblock(0.6, 1500)), (0.005, S.kalimba(m(91), 0.05, 0.25))], 0.22), 0.32),
    "ui_select": lambda: norm(mix([(0, S.koto(m(79), 0.1, 0.9, bright=0.9))], 0.45), 0.55),
    "ui_confirm": lambda: norm(mix([(0, S.koto(m(74), 0.1, 0.8)), (0.07, S.koto(m(81), 0.2, 0.9)),
                                    (0.07, S.bell(m(93), 0.3, 0.25))], 0.9), 0.6),
    "ui_back": lambda: norm(mix([(0, S.koto(m(76), 0.08, 0.7, bright=0.7)), (0.06, S.koto(m(69), 0.15, 0.6, bright=0.6))], 0.6), 0.5),
    "ui_open": lambda: norm(mix([(0, paper()), (0.08, S.bell(m(88), 0.4, 0.3, ratio=4.0, index=1.2))], 0.8), 0.5),
    "ui_error": lambda: norm(mix([(0, S.woodblock(0.7, 300)), (0.09, S.woodblock(0.6, 260))], 0.3), 0.45),
    "game_start": lambda: norm(mix([(i * 0.06, S.koto(m(n), 0.2, 0.7 + 0.05 * i)) for i, n in enumerate([62, 65, 67, 69, 72, 74, 77])]
                                   + [(0.45, S.bell(m(74), 1.6, 0.6)), (0.45, S.taiko(0.5, 1.2))], 2.2), 0.7),
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SFX.items():
        x = fn()
        S.write_wav(os.path.join(OUT, f"{name}.wav"), x)
        print(f"{name:12s} {len(x) / S.SR:.2f}s")
