"""Tiny offline synthesizer for Tonkatsu no Kami's original soundtrack.

Everything is generated from code (no samples), so the music is original and
free of licensing issues. Instruments are additive / FM models voiced after
Japanese instruments; effects are a vectorised Schroeder reverb, filters and a
soft limiter. Tracks render as seamless loops: note tails and reverb past the
loop end wrap around to the start.
"""
from __future__ import annotations

import math
import os
import subprocess

import numpy as np
from scipy import signal

SR = 32000


def midi_hz(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env_adsr(n, a, d, s, r, sr=SR):
    a, d, r = int(a * sr), int(d * sr), int(r * sr)
    e = np.full(n, s, np.float32)
    if a > 0:
        e[:min(a, n)] = np.linspace(0, 1, a, endpoint=False)[:min(a, n)]
    if d > 0 and a < n:
        k = min(d, n - a)
        e[a:a + k] = np.linspace(1, s, d, endpoint=False)[:k]
    if r > 0:
        r = min(r, n)
        e[n - r:] *= np.linspace(1, 0, r)
    return e


def t_axis(n):
    return np.arange(n, dtype=np.float32) / SR


# ------------------------------------------------------------------ instruments
def koto(f, dur, vel=1.0, bright=1.0):
    """Plucked silk string: harmonics with faster decay up the series, a short
    pitch drop at the attack and a pick noise."""
    n = int((dur + 1.6) * SR)
    t = t_axis(n)
    bend = 1.0 + 0.012 * np.exp(-t * 40)
    ph = 2 * np.pi * f * np.cumsum(bend) / SR
    out = np.zeros(n, np.float32)
    for k in range(1, 10):
        amp = (1.0 / k ** 1.1) * (0.7 if k % 2 == 0 else 1.0) * (bright ** (k - 1) if k > 1 else 1)
        dec = 1.6 + k * 1.3
        out += amp * np.sin(k * ph * (1 + 0.0007 * k)) * np.exp(-t * dec)
    noise = np.random.default_rng(int(f)).standard_normal(n).astype(np.float32)
    noise = signal.sosfilt(signal.butter(2, [800, 4500], "bandpass", fs=SR, output="sos"), noise) * np.exp(-t * 90)
    out += noise * 0.35
    out *= env_adsr(n, 0.002, 0, 1, 0.08)
    return out * vel * 0.32


def shamisen(f, dur, vel=1.0):
    """Brighter, drier pluck with the 'sawari' buzz (soft asymmetric clip)."""
    n = int((dur + 0.6) * SR)
    t = t_axis(n)
    ph = 2 * np.pi * f * t
    out = np.zeros(n, np.float32)
    for k in range(1, 14):
        out += (1.0 / k) * np.sin(k * ph) * np.exp(-t * (5 + k * 2.2))
    out = np.tanh(out * 1.8 + 0.25 * out ** 2)
    click = np.random.default_rng(int(f * 3)).standard_normal(n).astype(np.float32) * np.exp(-t * 200) * 0.4
    out = out + click
    out *= env_adsr(n, 0.001, 0, 1, 0.05)
    return out * vel * 0.26


def flute(f, dur, vel=1.0, vib=1.0, breath=1.0):
    """Shakuhachi-like: soft fundamental, weak upper partials, breath noise,
    a scoop into the note and a delayed vibrato."""
    n = int((dur + 0.25) * SR)
    t = t_axis(n)
    vibrato = 1 + 0.006 * vib * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.25) / 0.4, 0, 1)
    scoop = 1 - 0.025 * np.exp(-t * 18)
    ph = 2 * np.pi * f * np.cumsum(vibrato * scoop) / SR
    out = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    nz = np.random.default_rng(int(f * 7)).standard_normal(n).astype(np.float32)
    nz = signal.sosfilt(signal.butter(2, [f * 0.8, min(f * 3.5, SR / 2 - 100)], "bandpass", fs=SR, output="sos"), nz)
    out = out + nz * 0.5 * breath * (0.4 + 0.6 * np.exp(-t * 6))
    out *= env_adsr(n, 0.07, 0.15, 0.82, 0.22)
    return out.astype(np.float32) * vel * 0.22


def bell(f, dur, vel=1.0, ratio=3.5, index=2.5):
    """FM temple bell / chime."""
    n = int((dur + 2.5) * SR)
    t = t_axis(n)
    mod = index * np.exp(-t * 2.0) * np.sin(2 * np.pi * f * ratio * t)
    out = np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 1.4)
    out += 0.3 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 3)
    out *= env_adsr(n, 0.001, 0, 1, 0.3)
    return out.astype(np.float32) * vel * 0.18


def kalimba(f, dur, vel=1.0):
    n = int((dur + 1.2) * SR)
    t = t_axis(n)
    out = np.sin(2 * np.pi * f * t) * np.exp(-t * 3.2) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 18)
    out *= env_adsr(n, 0.001, 0, 1, 0.1)
    return out.astype(np.float32) * vel * 0.26


def pad(f, dur, vel=1.0, bright=0.5, detune=0.004):
    """Soft string/sho pad: detuned saw stack, low-passed, slow envelope."""
    n = int((dur + 1.0) * SR)
    t = t_axis(n)
    out = np.zeros(n, np.float32)
    for dt in (-detune, 0, detune):
        ph = (f * (1 + dt) * t) % 1.0
        out += (2 * ph - 1).astype(np.float32)
    cutoff = min(SR / 2 - 200, 300 + 2800 * bright)
    out = signal.sosfilt(signal.butter(2, cutoff, "lowpass", fs=SR, output="sos"), out).astype(np.float32)
    out *= env_adsr(n, min(0.8, dur * 0.4), 0.3, 0.85, 0.9)
    return out * vel * 0.07


def bass(f, dur, vel=1.0):
    n = int((dur + 0.4) * SR)
    t = t_axis(n)
    out = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) * np.exp(-t * 4)
    out *= np.exp(-t * 1.2) * env_adsr(n, 0.005, 0, 1, 0.12)
    return out.astype(np.float32) * vel * 0.34


def taiko(vel=1.0, size=1.0):
    n = int(1.4 * SR)
    t = t_axis(n)
    f0 = 95 / size
    ph = 2 * np.pi * np.cumsum(f0 * (1 + 1.4 * np.exp(-t * 28))) / SR
    body = np.sin(ph) * np.exp(-t * 5.5 / size)
    nz = np.random.default_rng(5).standard_normal(n).astype(np.float32)
    nz = signal.sosfilt(signal.butter(2, 900, "lowpass", fs=SR, output="sos"), nz) * np.exp(-t * 30)
    return (body + nz * 0.6).astype(np.float32) * vel * 0.55


def shime(vel=1.0):
    """High tight drum (shime-daiko)."""
    n = int(0.35 * SR)
    t = t_axis(n)
    body = np.sin(2 * np.pi * 330 * t * (1 + 0.5 * np.exp(-t * 60))) * np.exp(-t * 22)
    nz = np.random.default_rng(9).standard_normal(n).astype(np.float32) * np.exp(-t * 60)
    return (body + nz * 0.5).astype(np.float32) * vel * 0.3


def woodblock(vel=1.0, f=820):
    n = int(0.18 * SR)
    t = t_axis(n)
    out = np.sin(2 * np.pi * f * t) * np.exp(-t * 45) + 0.4 * np.sin(2 * np.pi * f * 2.3 * t) * np.exp(-t * 70)
    return out.astype(np.float32) * vel * 0.28


def shaker(vel=1.0):
    n = int(0.09 * SR)
    t = t_axis(n)
    nz = np.random.default_rng().standard_normal(n).astype(np.float32)
    nz = signal.sosfilt(signal.butter(2, 6000, "highpass", fs=SR, output="sos"), nz)
    return (nz * env_adsr(n, 0.01, 0.03, 0.3, 0.04)).astype(np.float32) * vel * 0.08


def cymbal(vel=1.0, dur=2.5):
    n = int(dur * SR)
    t = t_axis(n)
    nz = np.random.default_rng(13).standard_normal(n).astype(np.float32)
    nz = signal.sosfilt(signal.butter(2, 5000, "highpass", fs=SR, output="sos"), nz)
    return (nz * np.exp(-t * 2.2) * env_adsr(n, 0.002, 0, 1, 0.2)).astype(np.float32) * vel * 0.12


# ------------------------------------------------------------------ effects
def _comb(x, d, g):
    y = x.copy()
    for s in range(d, len(y), d):
        e = min(s + d, len(y))
        y[s:e] += g * y[s - d:e - d]
    return y


def _allpass(x, d, g):
    y = np.zeros_like(x)
    xp = np.concatenate([np.zeros(d, x.dtype), x])
    y[:d] = -g * x[:d]
    for s in range(d, len(y), d):
        e = min(s + d, len(y))
        y[s:e] = -g * x[s:e] + xp[s:e] + g * y[s - d:e - d]
    return y


def reverb(x, size=1.0, damp=4500, mix=0.25, seed=0):
    """Stereo Schroeder reverb. x: (n,2)."""
    combs = [1557, 1617, 1491, 1422, 1277, 1356]
    aps = [225, 556, 441]
    out = np.zeros_like(x)
    lp = signal.butter(1, damp, "lowpass", fs=SR, output="sos")
    for ch in range(2):
        src = x[:, ch].astype(np.float32)
        acc = np.zeros_like(src)
        for i, c in enumerate(combs):
            d = int(c * size * SR / 44100) + ch * 23 + seed
            acc += _comb(signal.sosfilt(lp, src).astype(np.float32), d, 0.80)
        acc /= len(combs)
        for a in aps:
            acc = _allpass(acc, int(a * SR / 44100) + ch * 7, 0.5)
        out[:, ch] = acc
    return x * (1 - mix) + out * mix


def pan(mono, p):
    """p in [-1, 1] -> equal-power stereo."""
    a = (p + 1) * math.pi / 4
    return np.stack([mono * math.cos(a), mono * math.sin(a)], axis=1)


# ------------------------------------------------------------------ song building
class Song:
    def __init__(self, bpm, bars, beats_per_bar=4, tail=4.0):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bar = self.beat * beats_per_bar
        self.bpb = beats_per_bar
        self.length = bars * self.bar
        self.n = int(round(self.length * SR))
        self.buses = {}
        self.tail = int(tail * SR)

    def bus(self, name):
        if name not in self.buses:
            self.buses[name] = np.zeros((self.n + self.tail, 2), np.float32)
        return self.buses[name]

    def add(self, bus, sound, at_beats, p=0.0):
        b = self.bus(bus)
        s = int(round(at_beats * self.beat * SR))
        st = pan(sound, p)
        e = min(len(b), s + len(st))
        if s < len(b):
            b[s:e] += st[:e - s]

    def mix(self, levels, rev=None, master_lp=11000, target_rms=0.11, loop=True):
        rev = rev or {}
        total = np.zeros((self.n + self.tail, 2), np.float32)
        for name, b in self.buses.items():
            x = b * levels.get(name, 1.0)
            if loop:
                # wrap the tail onto the start, then reverb a doubled copy and keep the second half
                x2 = x[:self.n].copy()
                x2[:self.tail] += x[self.n:self.n + self.tail]
                if name in rev:
                    big = np.concatenate([x2, x2])
                    big = reverb(big, **rev[name])
                    x2 = big[self.n:]
                total[:self.n] += x2
            else:
                if name in rev:
                    x = reverb(x, **rev[name])
                total += x
        total = total[:self.n] if loop else total
        total = signal.sosfilt(signal.butter(2, master_lp, "lowpass", fs=SR, output="sos"), total, axis=0)
        total = signal.sosfilt(signal.butter(1, 35, "highpass", fs=SR, output="sos"), total, axis=0)
        rms = np.sqrt((total ** 2).mean()) + 1e-9
        total *= target_rms / rms
        total = np.tanh(total * 1.1) / np.tanh(1.1)          # soft limiter
        peak = np.abs(total).max()
        if peak > 0.95:
            total *= 0.95 / peak
        return total.astype(np.float32)


def write_ogg(path, stereo, quality=5):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    raw = (np.clip(stereo, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(quality), path], input=raw, check=True)


def write_wav(path, mono_or_stereo):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = mono_or_stereo
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    raw = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "pcm_s16le", path], input=raw, check=True)
