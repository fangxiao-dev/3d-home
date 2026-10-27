"""Editable, independently rebuilt tabletop phone; placement follows the coffee table."""
from pathlib import Path
import bpy, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'godot/assets/phone'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
parts=[]
def material(name,color,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.35
    return m
frame=material('soft graphite metal',(.11,.15,.16),.65)
screen=material('warm screen',(.68,.59,.42))
tile=material('2048 ivory tiles',(.94,.86,.68))
def box(name,location,size,mat,bevel):
    bpy.ops.mesh.primitive_cube_add(size=1,location=location);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat);m=o.modifiers.new('rounded edges','BEVEL');m.width=bevel;m.segments=4;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');parts.append(o)
box('phone body',(0,0,.006),(.105,.205,.012),frame,.009)
box('screen',(0,0,.0125),(.092,.185,.002),screen,.007)
for row in range(4):
    for col in range(4):box('screen tile',((col-1.5)*.020,(row-1.5)*.020,.014),(.017,.017,.001),tile,.002)
box('speaker',(0,.086,.014),(.028,.002,.001),frame,.001)
box('home indicator',(0,-.084,.014),(.028,.002,.001),tile,.001)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/phone.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'phone.glb'),export_format='GLB',use_selection=True)
data=json.loads((ROOT/'godot/assets/scene-v2-data.json').read_text())
table=next(f for f in data['furniture'] if f['id']=='coffee_table')
low,high=table['bounds_min'],table['bounds_max']
(OUT/'placement.json').write_text(json.dumps({'position':[(low[0]+high[0])/2,high[1]+.002,(low[2]+high[2])/2],'yaw':-.15},indent=2))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(-.3,-.4,.7));bpy.context.object.data.energy=15;bpy.context.object.data.size=.6
bpy.ops.object.camera_add(location=(.2,-.3,.4));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.01))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.28;scene.camera=cam
scene.render.resolution_x=700;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=str(ROOT/'outputs/previews/phone.png');bpy.ops.render.render(write_still=True)
print('PHONE_ASSET_OK')
