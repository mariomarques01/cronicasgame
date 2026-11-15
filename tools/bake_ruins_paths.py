"""Bake the additional forest route without changing the existing farm mask."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
root=Path(__file__).resolve().parents[1]
layout=json.loads((root/'data/regions/ancient_ruins.json').read_text())
left,top,right,bottom=layout['mask_bounds']; size=1024
im=Image.new('L',(size,size)); d=ImageDraw.Draw(im)
def pixel(p): return ((p[0]-left)/(right-left)*size,(p[1]-top)/(bottom-top)*size)
for path in layout['paths']:
 pts=[pixel(p) for p in path['points']]; width=round(path['width']/(right-left)*size)
 d.line(pts,fill=255,width=width,joint='curve')
 for x,y in pts:d.ellipse((x-width/2,y-width/2,x+width/2,y+width/2),fill=255)
im.filter(ImageFilter.GaussianBlur(2)).save(root/'assets/ruins/paths_mask.png')
