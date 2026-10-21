"""Imports the team's audio (music + Freesound effects) into the game ids.

Usage: python3 import_team_audio.py <MUSICAS dir> <EFEITOS dir (with x_* subfolders unzipped)>

The team's notes (AMBIENTE.txt, CHEFES.txt, COLETA.txt, INIMIGOS.txt, LULU.txt)
say what each file is; MAP below follows them. Everything is converted to
.ogg (Vorbis), loudness-normalised so music, ambience and effects sit
together, trimmed of leading silence, and short effects get a tiny fade-out.
"""
import glob, os, subprocess, sys, unicodedata

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MUS = os.path.join(ROOT, "assets", "music")
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
AMB = os.path.join(ROOT, "assets", "audio", "ambience")

MUSIC = {  # file name start (accents removed, lower case) -> music id
    "tela inicial": "title",
    "level pantano": "swamp",
    "level cidade fantasma": "ghost_city",
    "level ceu": "sky",
    "level floresta magica": "spirit_forest",
    "level reino dos temperos": "spice_kingdom",
    "level arena final": "arena",
    "extra tema de chefe": "boss",
    "extra vitoria": "victory",
    "extra derrota": "defeat",
    "receita final": "final_recipe",
}

# (folder, freesound id prefix, game id, target, opts)
EFFECTS = [
    # LULU.txt
    ("x_Lulu", "170163", "jump", SFX, {}),
    ("x_Lulu", "442907", "swing", SFX, {"lufs": -15}),            # ATAQUE (grunhido)
    ("x_Lulu", "510974", "oink", SFX, {}),                        # SOM DA LULU
    ("x_Lulu", "521589", "steps_src", None, {}),                  # ANDAR -> sliced below
    ("x_Lulu", "770339", "hurt_squeal", None, {}),                # DANO (kept out: too big for Lulu — see lulu_hurt.py)
    ("x_Lulu", "810736", "dodge", SFX, {"lufs": -17}),            # DASH
    # COLETA.txt
    ("x_Coleta", "220173", "pickup", SFX, {"lufs": -18}),         # INGREDIENTE
    ("x_Coleta", "518888", "heart", SFX, {"lufs": -18}),          # VIDA EXTRA
    ("x_Coleta", "735168", "legendary", SFX, {"lufs": -15}),      # INGREDIENTE PRINCIPAL
    # CHEFES.txt
    ("x_Chefes", "213839", "boss_touro", SFX, {}),
    ("x_Chefes", "377254", "boss_cisne", SFX, {}),
    ("x_Chefes", "419231", "boss_pegaso", SFX, {}),
    ("x_Chefes", "488036", "boss_golem", SFX, {"lufs": -13}),
    ("x_Chefes", "506826", "boss_rei_quente", SFX, {}),
    ("x_Chefes", "547368", "boss_lobo", SFX, {}),
    # INIMIGOS.txt
    ("x_Inimigos", "352175", "enemy_arvorezinha", SFX, {"lufs": -19}),
    ("x_Inimigos", "363194", "enemy_pimentinha", SFX, {"lufs": -20}),
    ("x_Inimigos", "670185", "enemy_fantasminha", SFX, {"lufs": -19}),
    ("x_Inimigos", "680696", "enemy_espirito_ceu", SFX, {"lufs": -19}),
    ("x_Inimigos", "791346", "enemy_cogumelo", SFX, {"lufs": -19}),
    # AMBIENTE.txt
    ("x_Ambiente", "424792", "town_bells", SFX, {"lufs": -20}),    # SINO (full peal, HUB)
    ("x_Ambiente", "481148", "high_wind", AMB, {"lufs": -24, "loop": True}),           # VENTANIA
    ("x_Ambiente", "502204", "swamp", AMB, {"lufs": -24, "loop": True}),               # SAPOS
    ("x_Ambiente", "735062", "portal_enter", SFX, {"lufs": -17}),                     # PORTAL
]


def norm(s):
    s = unicodedata.normalize("NFD", s.replace("#U00e1", "á").replace("#U00e2", "â").replace("#U00e9", "é").replace("#U00f3", "ó"))
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower()


def run(args):
    subprocess.run(["ffmpeg", "-v", "error", "-y"] + args, check=True)


def music(src_dir):
    os.makedirs(MUS, exist_ok=True)
    found = {}
    for f in sorted(os.listdir(src_dir)):
        n = norm(f)
        for k, mid in MUSIC.items():
            if n.startswith(k):
                found[mid] = f
    missing = set(MUSIC.values()) - set(found)
    assert not missing, missing
    for mid, f in found.items():
        out = os.path.join(MUS, mid + ".ogg")
        run(["-i", os.path.join(src_dir, f), "-af", "loudnorm=I=-17:TP=-1.5:LRA=11", "-ar", "44100",
             "-c:a", "libvorbis", "-q:a", "5", out])
        print("music", mid, "<-", f)


def effects(src_dir):
    os.makedirs(SFX, exist_ok=True)
    os.makedirs(AMB, exist_ok=True)
    for folder, fid, gid, target, o in EFFECTS:
        src = glob.glob(os.path.join(src_dir, folder, fid + "__*"))[0]
        if target is None:
            continue
        lufs = o.get("lufs", -16)
        if o.get("loop"):
            # ambience: stereo, gentle 1.5 s fades so the loop seam is soft
            dur = float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", src]))
            af = f"loudnorm=I={lufs}:TP=-3,afade=t=in:d=1.5,afade=t=out:st={dur - 1.5:.2f}:d=1.5"
            run(["-i", src, "-af", af, "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", os.path.join(target, gid + ".ogg")])
        else:
            af = (f"silenceremove=start_periods=1:start_threshold=-45dB,loudnorm=I={lufs}:TP=-1.0,"
                  "areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse")
            run(["-i", src, "-af", af, "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5",
                 os.path.join(target, gid + ".ogg")])
        print("sfx ", gid, "<-", os.path.basename(src))
    steps(glob.glob(os.path.join(src_dir, "x_Lulu", "521589__*"))[0])
    # SINO, short: first strikes only (shrines, save, sky temple)
    run(["-t", "4.0", "-i", os.path.join(SFX, "town_bells.ogg"), "-af", "afade=t=out:st=2.4:d=1.6",
         "-c:a", "libvorbis", "-q:a", "5", os.path.join(SFX, "bell.ogg")])


def steps(src):
    """ANDAR: the file is a run of footsteps; cut each step into step_1..n.
    'step' itself is the first one (Player.gd varies pitch every step)."""
    import numpy as np
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", src, "-ac", "1", "-ar", "22050", "-f", "s16le", "-"])
    x = np.frombuffer(raw, np.int16).astype(np.float32) / 32768
    hop = 220
    env = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2)) for i in range(0, len(x) - hop, hop)])
    thr = env.max() * 0.25
    onsets, last = [], -99
    for i in range(1, len(env)):
        if env[i] > thr and env[i - 1] <= thr and i - last > 15:
            onsets.append(i)
            last = i
    print("steps onsets (s):", [round(i * hop / 22050, 2) for i in onsets])
    n = 0
    for i in onsets[:4]:
        t0 = max(0, i * hop / 22050 - 0.01)
        n += 1
        out = os.path.join(SFX, "step.ogg" if n == 1 else f"step_{n}.ogg")
        run(["-ss", f"{t0:.3f}", "-t", "0.22", "-i", src, "-af",
             "highpass=f=180,loudnorm=I=-20:TP=-2,afade=t=out:st=0.12:d=0.1", "-ac", "1", "-ar", "44100",
             "-c:a", "libvorbis", "-q:a", "4", out])


if __name__ == "__main__":
    music(sys.argv[1])
    effects(sys.argv[2])
