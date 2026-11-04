"""Generate an original geometric flower icon; requires Pillow, no reference pixels."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
s = 1024
base = Image.new('RGBA', (s,s), '#3c82f6')
for i in range(8):
    petal=Image.new('RGBA',(s,s)); d=ImageDraw.Draw(petal)
    d.ellipse((340,150,684,690),fill=(30+i*9,204-i*4,226+i*3,158))
    base=Image.alpha_composite(base,petal.rotate(i*45,resample=Image.Resampling.BICUBIC))
d=ImageDraw.Draw(base)
points=[]
segments=[((512,330),(540,484),(694,512)),((694,512),(540,540),(512,694)),((512,694),(484,540),(330,512)),((330,512),(484,484),(512,330))]
for a,b,c in segments:
    for j in range(40):
        t=j/40
        points.append(((1-t)**2*a[0]+2*t*(1-t)*b[0]+t*t*c[0],(1-t)**2*a[1]+2*t*(1-t)*b[1]+t*t*c[1]))
d.polygon(points,fill='white')
base=base.convert('RGB')
icons=root/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons/'Contents.json').read_text())['images']:
    n=round(float(entry['size'].split('x')[0])*float(entry['scale'][:-1]))
    base.resize((n,n),Image.Resampling.LANCZOS).save(icons/entry['filename'])
for density,n in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    base.resize((n,n),Image.Resampling.LANCZOS).save(root/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
