"""Original weathered limestone material; no external image or generation service."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
root=Path(__file__).resolve().parents[1];size=512
rng=np.random.default_rng(39172)
height=np.zeros((size,size),dtype=float)
for n,weight in [(8,.35),(24,.25),(64,.22),(256,.10),(512,.08)]:
 layer=Image.fromarray((rng.random((n,n))*255).astype('uint8')).resize((size,size),Image.Resampling.BICUBIC)
 height+=np.asarray(layer,dtype=float)/255*weight
height=(height-.5)*1.6
base=np.array([163,158,136],dtype=float)
color=np.clip(base[None,None,:]*(.92+height[:,:,None]*.40),0,255).astype('uint8')
Image.fromarray(color).save(root/'assets/ruins/limestone.png')
dy,dx=np.gradient(height*2.5)
normal=np.stack([-dx,np.ones_like(dx),-dy],axis=-1)
normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
# Tangent normal texture: R=x, G=y on the image, B=out of surface.
normal=normal[:,:,[0,2,1]]
Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(root/'assets/ruins/limestone_normal.png')
