import sys
from PIL import Image, ImageDraw, ImageChops
out=sys.argv[1]
S=4096
def gradient(w,h, top, bottom):
    g=Image.new('RGB',(1,h))
    for y in range(h):
        t=y/(h-1); g.putpixel((0,y),tuple(int(a+(b-a)*t) for a,b in zip(top,bottom)))
    return g.resize((w,h))
def glyph(size, scale=1.0, brackets=True):
    im=Image.new('RGBA',(size,size),(0,0,0,0))
    c=size/2; R=size*0.30*scale; w=size*0.04*scale
    face=Image.new('L',(size,size),0); fd=ImageDraw.Draw(face)
    hr=R*0.36; hy=c-R*0.18
    fd.ellipse([c-hr,hy-hr*1.12,c+hr,hy+hr*1.12],fill=255)
    fd.pieslice([c-R*0.78,c+R*0.22,c+R*0.78,c+R*1.5],180,360,fill=255)
    lens=Image.new('L',(size,size),0); ImageDraw.Draw(lens).ellipse([c-R+w,c-R+w,c+R-w,c+R-w],fill=255)
    face=ImageChops.multiply(face,lens)
    left=Image.new('L',(size,size),0); ImageDraw.Draw(left).rectangle([0,0,c,size],fill=255)
    im.paste((255,176,32,255),(0,0),ImageChops.multiply(face,left))
    im.paste((46,196,182,255),(0,0),ImageChops.multiply(face,ImageChops.invert(left)))
    d=ImageDraw.Draw(im)
    d.ellipse([c-R,c-R,c+R,c+R],outline=(255,255,255,255),width=int(w))
    if brackets:
        L=R*0.38; o=R*1.30; t=int(w*0.75)
        for sx in(-1,1):
            for sy in(-1,1):
                x=c+sx*o; y=c+sy*o
                d.line([(x-sx*L,y),(x,y),(x,y-sy*L)],fill=(255,255,255,230),width=t,joint='curve')
                for px,py in ((x-sx*L,y),(x,y-sy*L)):
                    d.ellipse([px-t/2,py-t/2,px+t/2,py+t/2],fill=(255,255,255,230))
    return im
bg=gradient(S,S,(91,95,239),(48,36,140)).convert('RGBA')
Image.alpha_composite(bg,glyph(S)).convert('RGB').resize((1024,1024),Image.LANCZOS).save(f'{out}/icon_1024.png')
glyph(S,scale=0.80).resize((1024,1024),Image.LANCZOS).save(f'{out}/icon_foreground.png')
Image.new('RGB',(1024,1024),(70,62,200)).save(f'{out}/icon_background.png')
fg=gradient(2048,1000,(91,95,239),(48,36,140)).convert('RGBA'); fg.alpha_composite(glyph(1000),(524,0))
fg.convert('RGB').resize((1024,500),Image.LANCZOS).save(f'{out}/feature_graphic.png')
