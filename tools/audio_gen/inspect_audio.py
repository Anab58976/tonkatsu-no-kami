"""Objective checks for generated audio (I cannot listen, so I measure):
 - loop seam: sample jump at the wrap point vs typical sample-to-sample change
 - clipping, peak, RMS, silence gaps
 - spectral balance (energy in low / mid / high bands)
 - a spectrogram + waveform PNG for visual inspection of structure
"""
from __future__ import annotations

import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import signal

SR = 32000


def load(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "s16le", "-ac", "2", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, "<i2").reshape(-1, 2).astype(np.float32) / 32768


def report(path, png=None):
    x = load(path)
    m = x.mean(axis=1)
    d = np.abs(np.diff(m))
    seam = abs(m[0] - m[-1])
    typical = np.percentile(d, 99)
    win = SR // 10
    rms_w = np.sqrt(np.convolve(m ** 2, np.ones(win) / win, mode="valid"))
    silent = (rms_w < 0.004).mean()
    f, P = signal.welch(m, SR, nperseg=4096)
    tot = P.sum()
    bands = {"<150": P[f < 150].sum() / tot, "150-2k": P[(f >= 150) & (f < 2000)].sum() / tot,
             "2k-6k": P[(f >= 2000) & (f < 6000)].sum() / tot, ">6k": P[f >= 6000].sum() / tot}
    clip = (np.abs(x) > 0.999).mean()
    print(f"{path.split('/')[-1]:22s} {len(m) / SR:5.1f}s peak {np.abs(x).max():.2f} rms {np.sqrt((m ** 2).mean()):.3f} "
          f"seam {seam:.4f} (p99 step {typical:.4f}) silent {silent:.0%} clip {clip:.2%} "
          + " ".join(f"{k}:{v:.0%}" for k, v in bands.items()))
    if png:
        fr, tt, Z = signal.spectrogram(m, SR, nperseg=1024, noverlap=768)
        Z = 10 * np.log10(Z + 1e-10)
        sel = fr < 8000
        Z = Z[sel][::-1]
        Z = np.clip((Z - (Z.max() - 80)) / 80, 0, 1)
        img = Image.fromarray((Z * 255).astype(np.uint8)).resize((1200, 300))
        img = img.convert("RGB")
        wave = Image.new("RGB", (1200, 80), (20, 20, 30))
        dr = ImageDraw.Draw(wave)
        step = len(m) // 1200
        for i in range(1200):
            seg = m[i * step:(i + 1) * step]
            if len(seg):
                dr.line([(i, 40 - seg.max() * 38), (i, 40 - seg.min() * 38)], fill=(120, 200, 255))
        out = Image.new("RGB", (1200, 380))
        out.paste(img, (0, 0))
        out.paste(wave, (0, 300))
        out.save(png)


if __name__ == "__main__":
    for p in [a for a in sys.argv[1:] if not a.startswith("--")]:
        report(p, p.replace(".ogg", ".png") if "--png" in sys.argv else None)
