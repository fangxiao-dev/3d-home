"""Editable, independently rebuilt tabletop phone; placement follows the coffee table."""
from pathlib import Path
import bpy, json, sys, math
sys.path.insert(0,str(Path(__file__).resolve().parent))
from asset_support import support_height
from mathutils import Vector
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'godot/assets/phone'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
parts=[]
def material(name,color,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.35
    return m
frame=material('warm ivory protective case',(.87,.82,.71))
black=material('polished black glass',(.012,.018,.025),.12)
metal=material('side buttons',(.55,.49,.41),.5)
def box(name,location,size,mat,bevel):
    bpy.ops.mesh.primitive_cube_add(size=1,location=location);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat);m=o.modifiers.new('rounded edges','BEVEL');m.width=bevel;m.segments=5;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');parts.append(o)
def rounded_slab(name,w,h,z0,z1,r,mat):
    points=[]
    for cx,cy,start in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),(-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
        for i in range(9):
            angle=math.radians(start+i*90/8);points.append((cx+r*math.cos(angle),cy+r*math.sin(angle)))
    n=len(points);verts=[(x,y,z0) for x,y in points]+[(x,y,z1) for x,y in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(mat)
    bevel=o.modifiers.new('soft edge','BEVEL');bevel.width=.0008;bevel.segments=3;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');parts.append(o)
rounded_slab('protective case',.105,.205,0,.013,.012,frame)
rounded_slab('black glass bezel',.096,.196,.013,.015,.010,black)
box('volume up',(-.053,.043,.006),(.003,.020,.004),metal,.001)
box('volume down',(-.053,.014,.006),(.003,.020,.004),metal,.001)
box('power button',(.053,.032,.006),(.003,.028,.004),metal,.001)
# A real textured screen surface, within the independently modeled case and glass.
rounded_slab('unlocked home screen',.087,.183,.015,.0152,.009,black)
display=parts[-1]
uv=display.data.uv_layers.new(name='UVMap')
for poly in display.data.polygons:
    for li in poly.loop_indices:
        v=display.data.vertices[display.data.loops[li].vertex_index].co
        uv.data[li].uv=(v.x/.087+.5,v.y/.183+.5)

mat=bpy.data.materials.new('home screen texture');mat.use_nodes=True
nodes=mat.node_tree.nodes; shader=nodes.get('Principled BSDF');tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'home-screen-v3.png'));tex.image.pack();mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color']);shader.inputs['Roughness'].default_value=.35
display.data.materials.clear();display.data.materials.append(mat)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/phone.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'phone.glb'),export_format='GLB',use_selection=True,export_apply=True)
data=json.loads((ROOT/'godot/assets/scene-v2-data.json').read_text())
table=next(f for f in data['furniture'] if f['id']=='coffee_table')
low,high=table['bounds_min'],table['bounds_max']
phone_x,phone_z=(low[0]+high[0])/2,(low[2]+high[2])/2
support=support_height(ROOT,phone_x,phone_z,1.0,'Tea table top')
(OUT/'placement.json').write_text(json.dumps({'position':[phone_x,support+.002,phone_z],'yaw':-.15},indent=2))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(-.3,-.4,.7));bpy.context.object.data.energy=15;bpy.context.object.data.size=.6
bpy.ops.object.camera_add(location=(.2,-.3,.4));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.01))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.28;scene.camera=cam
scene.render.resolution_x=700;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.filepath=str(ROOT/'outputs/previews/phone.png');bpy.ops.render.render(write_still=True)
print('PHONE_ASSET_OK')
