"""Create original modular masonry locally. Run with Blender, output directory after --."""
import bpy, bmesh, math, random, sys
from pathlib import Path
from mathutils import Vector
out=Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)
rng=random.Random(47821)
def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);return m
stone=moss=None
def reset():
 global stone,moss
 bpy.ops.wm.read_factory_settings(use_empty=True)
 stone=material('WeatheredStone',(0.72,0.73,0.65));moss=material('Moss',(0.20,0.34,0.12))
def finish_obj(obj,mat,bevel=.035):
 obj.data.materials.append(mat)
 bpy.context.view_layer.objects.active=obj
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=obj.modifiers.new('WornEdges','BEVEL');mod.width=bevel;mod.segments=1
  bpy.ops.object.modifier_apply(modifier=mod.name)
 obj.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
 tint=rng.uniform(.78,1.05)
 for c in obj.data.color_attributes['Color'].data:c.color=(tint,tint*.99,tint*.94,1)
 return obj

def block(pos,size,mat=None,angle=0,bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
 o=bpy.context.object;o.dimensions=size;o.rotation_euler[2]=angle
 return finish_obj(o,mat or stone,bevel)

def wedge(a,b,inner=2.,outer=3.,base=3.25,depth=1.25):
 v=[]
 for y in [-depth/2,depth/2]:
  for r,t in [(inner,a),(outer,a),(outer,b),(inner,b)]:v.append((r*math.cos(t),y,base+r*math.sin(t)))
 mesh=bpy.data.meshes.new('ArchStone');mesh.from_pydata(v,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
 o=bpy.data.objects.new('ArchStone',mesh);bpy.context.collection.objects.link(o)
 for ob in bpy.context.selected_objects:ob.select_set(False)
 o.select_set(True);bpy.context.view_layer.objects.active=o
 finish_obj(o,stone,.025)

def tuft(pos):
 # Broad moss caps and tiny hanging tufts; original geometry, no alpha cards.
 for i in range(3):
  o=block((pos[0]+rng.uniform(-.2,.2),pos[1]+rng.uniform(-.25,.25),pos[2]),(rng.uniform(.2,.4),.22,.045),moss,angle=rng.random()*3.14,bevel=0)

def export(name):
 # One mesh with a small material set; no object-per-brick runtime hierarchy.
 bpy.ops.object.select_all(action='SELECT')
 bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 bpy.ops.object.join()
 obj=bpy.context.object
 bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(obj.data);bm.free()
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.cube_project(cube_size=1.7);bpy.ops.object.mode_set(mode='OBJECT')
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',export_animations=False,export_vertex_color='ACTIVE')
 print('RUINS_ASSET',name,len(obj.data.polygons),flush=True)

for broken in [False,True]:
 reset()
 for side in [-1,1]:
  block((side*2.5,0,.18),(1.65,1.7,.36))
  courses=5 if not(broken and side==1) else 3
  for j in range(courses):
   block((side*2.5+rng.uniform(-.018,.018),rng.uniform(-.015,.015),.36+.55*(j+.5)),(1.07,1.3,.52),angle=rng.uniform(-.012,.012))
  if courses==5:block((side*2.5,0,3.2),(1.45,1.55,.24))
 for i in range(15):
  if broken and i in [3,4,5,6,7,8,9]:continue
  wedge(i*math.pi/15+.009,(i+1)*math.pi/15-.009)
  if i%3==0:tuft((2.9*math.cos((i+.5)*math.pi/15),0,3.25+2.9*math.sin((i+.5)*math.pi/15)))
 if broken:
  for j in range(7):block((rng.uniform(3.4,5.5),rng.uniform(-.8,.8),rng.uniform(.13,.3)),(rng.uniform(.45,.85),.65,rng.uniform(.25,.6)),angle=rng.uniform(-1,1))
 export('broken_arch' if broken else 'arch')
reset()
for row in range(4):
 for col in range(9):
  if row==3 and col in [0,1,4,7,8]:continue
  if row==2 and col==0:continue
  block(((col-4)*.95+(row%2)*.32,0,.29+row*.57),(.92,1.05,.54),angle=rng.uniform(-.01,.01))
  if row==3 and col%2:tuft(((col-4)*.95,0,.6+row*.57))
export('wall')
reset()
for i in range(14):
 x=rng.uniform(-2,2);y=rng.uniform(-1.1,1.1);h=rng.uniform(.2,.6)
 block((x,y,h*.5),(rng.uniform(.4,.9),rng.uniform(.4,.8),h),angle=rng.uniform(-2,2))
 if i%4==0:tuft((x,y,h))
export('rubble')
