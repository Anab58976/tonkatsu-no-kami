#!/bin/bash
# Usage: tools/capture.sh <scene> <outdir> <every> <timescale> <quit_after> [extra args...]
cd "$(dirname "$0")/.."
SCENE=$1; OUT=$2; EVERY=$3; TS=$4; QUIT=$5; shift 5
rm -rf "$OUT"; mkdir -p "$OUT"
timeout $((${QUIT%.*} / ${TS%.*} + 90)) xvfb-run -a -s "-screen 0 1280x720x24" ../tools/godot --path . --rendering-driver opengl3 --resolution 640x360 --audio-driver Dummy -- \
  --scene=$SCENE --newgame --capture=$OUT --every=$EVERY --timescale=$TS --quit-after=$QUIT "$@" 2>&1 \
  | grep -v -E "^\s*$|ALSA|V-Sync|set_use_vsync|harness\] t=.*shot|OpenGL API|Godot Engine v" 
python3 - "$OUT" <<'PY'
import sys, glob
from PIL import Image, ImageDraw
out=sys.argv[1]; fs=sorted(glob.glob(out+'/shot_*.png')); cols=4; w,h=320,180
for part in range(0,len(fs),16):
    sub=fs[part:part+16]; s=Image.new('RGB',(cols*w,((len(sub)+cols-1)//cols)*h)); d=ImageDraw.Draw(s)
    for i,f in enumerate(sub):
        s.paste(Image.open(f).convert('RGB').resize((w,h)),((i%cols)*w,(i//cols)*h)); d.text(((i%cols)*w+3,(i//cols)*h+3),f[-7:-4],fill='yellow')
    s.save(f'{out}/contact_{part//16}.png')
print(len(fs),'shots')
PY
