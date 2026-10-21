import json, os, sys
from PIL import Image, ImageDraw
def preview(char_dir, out, scale=4):
    meta=json.load(open(os.path.join(char_dir,'anims.json')))
    cw,ch=meta['cell_w'],meta['cell_h']
    rows=list(meta['animations'].items())
    maxf=max(a['frames'] for _,a in rows)
    img=Image.new('RGBA',(110+maxf*cw*scale,len(rows)*ch*scale),(58,62,74,255))
    d=ImageDraw.Draw(img)
    for r,(name,a) in enumerate(rows):
        s=Image.open(os.path.join(char_dir,a['file']))
        s=s.resize((s.width*scale,s.height*scale),Image.NEAREST)
        img.alpha_composite(s,(110,r*ch*scale))
        d.text((4,r*ch*scale+8),name,fill=(255,255,255,255))
        for f in range(a['frames']+1):
            d.line([(110+f*cw*scale,r*ch*scale),(110+f*cw*scale,(r+1)*ch*scale-1)],fill=(80,85,100,255))
    img.save(out)
if __name__=='__main__': preview(sys.argv[1],sys.argv[2], int(sys.argv[3]) if len(sys.argv)>3 else 4)
