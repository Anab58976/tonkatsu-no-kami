import sys
from PIL import Image, ImageDraw
def grid(path, out, s=14):
    im=Image.open(path).convert('RGBA'); w,h=im.size
    bg=Image.new('RGBA',(w*s+30,h*s+30),(70,70,80,255))
    big=im.resize((w*s,h*s),Image.NEAREST); bg.alpha_composite(big,(30,30))
    d=ImageDraw.Draw(bg)
    for x in range(w+1): d.line([(30+x*s,30),(30+x*s,30+h*s)],fill=(90,90,100,255) if x%5 else (200,200,60,255))
    for y in range(h+1): d.line([(30,30+y*s),(30+w*s,30+y*s)],fill=(90,90,100,255) if y%5 else (200,200,60,255))
    for x in range(0,w,5): d.text((30+x*s+2,5),str(x),fill=(255,255,255,255))
    for y in range(0,h,5): d.text((2,30+y*s+2),str(y),fill=(255,255,255,255))
    bg.save(out)
if __name__=='__main__': grid(sys.argv[1],sys.argv[2])
