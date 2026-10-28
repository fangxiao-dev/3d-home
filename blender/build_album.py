"""Editable cloth-bound album; placement derived from the television cabinet."""
from pathlib import Path
import bpy, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'godot/assets/album'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
parts=[]
def material(name,color,roughness=.7,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=roughness;p.inputs['Metallic'].default_value=metal
    return m
cloth=material('sage linen cover',(.24,.35,.30))
paper=material('ivory paper edges',(.83,.77,.63))
gold=material('muted brass foil',(.65,.48,.25),.4,.35)
ribbon=material('rose ribbon',(.57,.29,.32))
def box(name,loc,size,mat,bevel=.003):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat);m=o.modifiers.new('soft bound edges','BEVEL');m.width=bevel;m.segments=3;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');o['prop_id']='time_album';parts.append(o)
box('bottom cover',(0,0,.004),(.32,.25,.008),cloth)
box('page block',(.004,0,.025),(.303,.234,.035),paper)
for z in [.014,.020,.026,.032,.038]:box('page edge',(0.009,-.117,z),(.29,.0008,.0006),gold,.0002)
box('top cover',(0,0,.048),(.32,.25,.009),cloth)
box('cloth spine',(-.156,0,.026),(.009,.249,.047),cloth)
box('ribbon bookmark',(.10,-.045,.044),(.016,.20,.001),ribbon,.0005)
for x in [-.126,.126]:box('cover frame',(x,0,.053),(.0015,.19,.0008),gold,.0003)
for y in [-.095,.095]:box('cover frame',(0,y,.053),(.253,.0015,.0008),gold,.0003)
# Two fine paths meet on the cover, matching the album's dual-life motif.
for x in [-.018,.018]:box('two tracks',(x,0,.054),(.002,.075,.001),gold,.0003)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.007,location=(0,0,.054));o=bpy.context.object;o.name='meeting star';o.scale=(1,1,.15);o.data.materials.append(gold);parts.append(o)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/album.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'album.glb'),export_format='GLB',use_selection=True)
data=json.loads((ROOT/'godot/assets/scene-v2-data.json').read_text())
cabinet=next(f for f in data['furniture'] if f['id']=='tv_console')
low,high=cabinet['bounds_min'],cabinet['bounds_max']
# Furniture bounds include the cacti: read the actual supporting top from its source.
with bpy.data.libraries.load(str(ROOT/'blender/living-room.blend'),link=False) as (source,target):
    target.objects=[name for name in source.objects if name=='TV console body']
if not target.objects: raise RuntimeError('TV console wooden body missing from source model')
top=target.objects[0]
bpy.context.collection.objects.link(top);bpy.context.view_layer.update()
surface=max((top.matrix_world @ Vector(corner)).z for corner in top.bound_box)
bpy.data.objects.remove(top)
# Keep the book forward of the television screen, within the cabinet footprint.
(OUT/'placement.json').write_text(json.dumps({'furniture_id':'tv_console','position':[low[0]+.22,surface+.003,(low[2]+high[2])/2],'yaw':0.0},indent=2))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(-.3,-.4,.8));bpy.context.object.data.energy=22;bpy.context.object.data.size=.7
bpy.ops.object.camera_add(location=(.35,-.45,.55));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.025))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.46;scene.camera=cam
scene.render.resolution_x=800;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=str(ROOT/'outputs/previews/album.png');bpy.ops.render.render(write_still=True)
print('ALBUM_ASSET_OK')
