import bpy, json, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)
jobs=[('forest_tree','assets/models/forest_tree.glb',1400),('farm_pine','assets/models/farm_pine.glb',1800),('mossy_fence','assets/models/mossy_fence.glb',2400),('cabbage','assets/crops/source/cabbage.glb',1000),('carrots','assets/crops/source/carrots.glb',1300),('bunny','assets/models/bunny_animated.glb',18000)]
report=[]
for name,path,budget in jobs:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(root/path))
 before=after=0
 for obj in list(bpy.context.scene.objects):
  if obj.type!='MESH': continue
  bpy.context.view_layer.objects.active=obj
  obj.data.calc_loop_triangles()
  count=len(obj.data.loop_triangles);before+=count
  armatures=[m for m in obj.modifiers if m.type=='ARMATURE']
  for arm in armatures: arm.show_viewport=False
  if count>budget:
   mod=obj.modifiers.new('MobileTriangleBudget','DECIMATE');mod.ratio=budget/count;mod.use_collapse_triangulate=True
   bpy.ops.object.modifier_apply(modifier=mod.name)
  obj.data.calc_loop_triangles();after+=len(obj.data.loop_triangles)
  for arm in armatures: arm.show_viewport=True
 bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),export_format='GLB',export_animations=False,export_skins=True,export_yup=True)
 report.append({'name':name,'source':path,'before':before,'after':after,'budget':budget})
 print('MOBILE_BAKE',report[-1],flush=True)
(out/'report.json').write_text(json.dumps(report,indent=2))
