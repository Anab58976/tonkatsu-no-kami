"""Cuts the Rei Porco dub (assets/audio/voice/source/rei_porco_intro.mp3) into
one clip per dialogue page of resources/cutscenes/intro_speech.json.

The timings in rei_porco_alignment.json were found by matching the speech
chunks of the recording (silence detection + syllable peaks) to the 28 lines
of the official speech; the region names in scene 7 (six short words in a row)
anchor the middle of the alignment. Re-run after editing the timings:
    python3 tools/audio_gen/split_king_voice.py
"""
import json, os, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "audio", "voice", "source", "rei_porco_intro.mp3")
OUT = os.path.join(ROOT, "assets", "audio", "voice", "rei_porco")
SPEECH = os.path.join(ROOT, "resources", "cutscenes", "intro_speech.json")
ALIGN = os.path.join(os.path.dirname(__file__), "rei_porco_alignment.json")
PRE, POST = 0.12, 0.28

os.makedirs(OUT, exist_ok=True)
al = json.load(open(ALIGN))
norm = os.path.join(OUT, "_norm.wav")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", SRC, "-af", "highpass=f=70,loudnorm=I=-16:TP=-1.5:LRA=9",
                "-ar", "44100", "-ac", "1", norm], check=True)
sp = json.load(open(SPEECH))
by_id = {s["id"]: s for s in sp["segments"]}
for i, a in enumerate(al):
    lo = a["start"] - PRE
    hi = a["end"] + POST
    if i > 0:
        lo = max(lo, (al[i - 1]["end"] + a["start"]) / 2)
    if i + 1 < len(al):
        hi = min(hi, (a["end"] + al[i + 1]["start"]) / 2)
    lo = max(0.0, lo)
    d = hi - lo
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{lo:.3f}", "-t", f"{d:.3f}", "-i", norm,
                    "-af", f"afade=t=in:d=0.04,afade=t=out:st={max(0, d - 0.12):.3f}:d=0.12",
                    "-c:a", "libvorbis", "-q:a", "5", os.path.join(OUT, a["id"] + ".ogg")], check=True)
    s = by_id[a["id"]]
    s["start"], s["end"] = round(a["start"], 2), round(a["end"], 2)
    s["voice"] = "res://assets/audio/voice/rei_porco/%s.ogg" % a["id"]
os.remove(norm)
sp["voice_file"] = "assets/audio/voice/source/rei_porco_intro.mp3"
sp["_doc"] = sp["_doc"].split(" voice_file/start/end")[0] + \
    " voice_file = dublagem da equipe; start/end = trecho de cada fala na gravação; voice = clipe recortado (tools/audio_gen/split_king_voice.py)."
txt = json.dumps(sp, ensure_ascii=False, indent=2)
open(SPEECH, "w").write(txt + "\n")
print("clips:", len(al))
