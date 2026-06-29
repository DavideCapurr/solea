#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

# Run from anywhere; paths are resolved relative to the repo root (4 levels up).
HERE=os.path.dirname(os.path.abspath(__file__))
REPO=os.path.abspath(os.path.join(HERE,"..","..","..",".."))
OUT=HERE  # write panels/mockups next to this script
os.makedirs(OUT, exist_ok=True)
SHOTS=os.path.join(REPO,"AppStore/Screenshots/iPhone-6.9")
ICON=os.path.join(REPO,"App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
FB="/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
FR="/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"

# meme geometry
FRAME_W, FRAME_H = 1060, 2298
BAND_TOP, BAND_BOT = 367, 1677
PW, PH = FRAME_W, BAND_BOT-BAND_TOP  # 1060 x 1310 panel slot

# brand colors
CREAM_TOP=(255,244,222)
ORANGE=(255,158,26)
DEEP=(233,108,30)

def font(path,size): return ImageFont.truetype(path,size)

def warm_bg(w,h):
    """Vertical warm gradient cream->orange with a soft radial sun glow top-center."""
    bg=Image.new("RGB",(w,h))
    px=bg.load()
    for y in range(h):
        t=y/(h-1)
        # ease
        t2=t**1.15
        r=int(CREAM_TOP[0]*(1-t2)+ORANGE[0]*t2)
        g=int(CREAM_TOP[1]*(1-t2)+ORANGE[1]*t2)
        b=int(CREAM_TOP[2]*(1-t2)+ORANGE[2]*t2)
        for x in range(w):
            px[x,y]=(r,g,b)
    # sun glow
    glow=Image.new("L",(w,h),0); gd=ImageDraw.Draw(glow)
    cx,cy=w//2,int(h*0.30); R=int(w*0.62)
    gd.ellipse([cx-R,cy-R,cx+R,cy+R],fill=120)
    glow=glow.filter(ImageFilter.GaussianBlur(R//3))
    sun=Image.new("RGB",(w,h),(255,236,190))
    bg=Image.composite(sun,bg,glow)
    return bg

def rounded(im,rad):
    im=im.convert("RGBA")
    m=Image.new("L",im.size,0); d=ImageDraw.Draw(m)
    d.rounded_rectangle([0,0,im.size[0],im.size[1]],radius=rad,fill=255)
    im.putalpha(m); return im

def crop_status(shot):
    """Trim the very top status-bar strip for a cleaner phone look."""
    w,h=shot.size
    return shot.crop((0,int(h*0.038),w,h))

def phone(path,target_h,corner=70,border=10):
    s=Image.open(path).convert("RGB")
    s=crop_status(s)
    scale=target_h/s.size[1]
    s=s.resize((int(s.size[0]*scale),target_h),Image.LANCZOS)
    s=rounded(s,corner)
    # white bezel
    bw=border
    bez=Image.new("RGBA",(s.size[0]+2*bw,s.size[1]+2*bw),(0,0,0,0))
    bm=rounded(Image.new("RGB",bez.size,(255,255,255)),corner+bw)
    bez=bm
    bez.alpha_composite(s,(bw,bw))
    return bez

def paste_shadow(base,obj,xy,blur=45,alpha=150,off=(0,28)):
    sh=Image.new("RGBA",base.size,(0,0,0,0))
    a=obj.split()[-1]
    solid=Image.new("RGBA",obj.size,(40,20,0,alpha))
    solid.putalpha(a)
    sh.alpha_composite(solid,(xy[0]+off[0],xy[1]+off[1]))
    sh=sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh)
    base.alpha_composite(obj,xy)

def wordmark(draw,cx,y,text="Solea",sub=None,col=(60,30,5)):
    f=font(FB,96)
    bb=draw.textbbox((0,0),text,font=f); w=bb[2]-bb[0]
    draw.text((cx-w//2,y),text,font=f,fill=col)
    yy=y+ (bb[3]-bb[1]) + 30
    if sub:
        fs=font(FR,40)
        bb2=draw.textbbox((0,0),sub,font=fs); w2=bb2[2]-bb2[0]
        draw.text((cx-w2//2,yy),sub,font=fs,fill=(110,70,30))

# ---------- Panel A: single app hero ----------
def panel_A():
    p=warm_bg(PW,PH).convert("RGBA")
    d=ImageDraw.Draw(p)
    ph=phone(os.path.join(SHOTS,"01-solea-check.png"),target_h=1080)
    x=(PW-ph.size[0])//2; y=70
    paste_shadow(p,ph,(x,y))
    p.convert("RGB").save(os.path.join(OUT,"panel_A_app.png"))
    return p

# ---------- Panel B: three screens fan ----------
def panel_B():
    p=warm_bg(PW,PH).convert("RGBA")
    files=["02-live-session.png","01-solea-check.png","05-progress-diary.png"]
    hs=[860,980,860]
    phones=[phone(os.path.join(SHOTS,f),target_h=h) for f,h in zip(files,hs)]
    # positions: left, center(front), right
    cyc=PH//2 - 30
    # center
    c=phones[1]; cx=(PW-c.size[0])//2; cy=cyc-c.size[1]//2
    l=phones[0]; lx=cx-int(l.size[0]*0.78); ly=cyc-l.size[1]//2+10
    r=phones[2]; rx=cx+c.size[0]-int(r.size[0]*0.22); ry=cyc-r.size[1]//2+10
    paste_shadow(p,l,(lx,ly),blur=40,alpha=120)
    paste_shadow(p,r,(rx,ry),blur=40,alpha=120)
    paste_shadow(p,c,(cx,cy),blur=55,alpha=160)
    p.convert("RGB").save(os.path.join(OUT,"panel_B_three.png"))
    return p

# ---------- Panel C: brand tile ----------
def panel_C():
    p=warm_bg(PW,PH).convert("RGBA")
    d=ImageDraw.Draw(p)
    ic=Image.open(ICON).convert("RGB")
    isz=560; ic=ic.resize((isz,isz),Image.LANCZOS); ic=rounded(ic,120)
    x=(PW-isz)//2; y=300
    paste_shadow(p,ic,(x,y),blur=50,alpha=130)
    wordmark(d,PW//2,y+isz+70,"Solea",sub="tan smart. don't burn.")
    p.convert("RGB").save(os.path.join(OUT,"panel_C_brand.png"))
    return p

# ---------- Full meme mockup ----------
def mockup(panel,name,caption="Niche mfs:"):
    frame=Image.new("RGB",(FRAME_W,FRAME_H),(0,0,0))
    # red accent line at very top center (like source)
    dr=ImageDraw.Draw(frame)
    dr.rectangle([FRAME_W//2-130,0,FRAME_W//2+130,6],fill=(150,20,20))
    # caption
    f=font(FB,58)
    bb=dr.textbbox((0,0),caption,font=f); w=bb[2]-bb[0]
    dr.text((FRAME_W//2-w//2,225),caption,font=f,fill=(255,255,255))
    # panel into band
    pr=panel.convert("RGB").resize((PW,PH),Image.LANCZOS)
    frame.paste(pr,(0,BAND_TOP))
    frame.save(os.path.join(OUT,name))

A=panel_A(); B=panel_B(); C=panel_C()
mockup(A,"mockup_A.png"); mockup(B,"mockup_B.png"); mockup(C,"mockup_C.png")
print("done", os.listdir(OUT))
