"""Editable birthday cake and candles, sized for the existing dining table."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'godot/assets/stage2';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def mat(name,color,rough=.5,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    return m
cream=mat('vanilla buttercream',(.94,.86,.70),.72)
pink=mat('strawberry piping',(.76,.35,.39),.7)
plate=mat('warm porcelain',(.88,.83,.73),.26)
gold=mat('small gold accents',(.69,.43,.12),.28,.65)
wax=mat('ivory candle wax',(.98,.91,.74),.45)
wick=mat('cotton wick',(.06,.035,.02),.9)
parts=[]
def cylinder(name,location,radius,depth,material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=radius,depth=depth,location=location)
    o=bpy.context.object;o.name=name;o.data.materials.append(material)
    bevel=o.modifiers.new('soft pastry edges','BEVEL');bevel.width=min(.012,depth/4);bevel.segments=3
    o.modifiers.new('weighted normals','WEIGHTED_NORMAL');parts.append(o);return o
def sphere(name,location,scale,material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=location)
    o=bpy.context.object;o.name=name;o.scale=scale;o.data.materials.append(material)
    for p in o.data.polygons:p.use_smooth=True
    parts.append(o);return o
cylinder('porcelain cake plate',(0,0,.015),.29,.03,plate)
cylinder('gold plate rim',(0,0,.032),.278,.008,gold)
cylinder('vanilla cake',(0,0,.12),.235,.17,cream)
cylinder('smooth frosting top',(0,0,.21),.237,.025,cream)
for ring,z in [(0,.045),(1,.228)]:
    for i in range(32):
        a=i*math.tau/32
        sphere('piped rose cream',(math.cos(a)*.219,math.sin(a)*.219,z),(.021,.021,.017),pink if ring else cream)
for i in range(9):
    a=i*math.tau/9
    sphere('gold sugar pearl',(math.cos(a)*.15,math.sin(a)*.15,.233),(.007,.007,.007),gold)
candle_positions=[]
for x,y in [(-.08,-.035),(.08,-.035),(0,.085)]:
    cylinder('candle',(x,y,.29),.012,.135,wax)
    cylinder('wick',(x,y,.365),.0025,.02,wick)
    candle_positions.append([x,.382,-y])
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/stage2-cake.blend'))
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'cake.glb'),export_format='GLB',use_selection=True)
placement={'table_position':[-.95,.755,4.18],'fridge_position':[1.54,.705,5.5],'candles':candle_positions}
(OUT/'placement.json').write_text(json.dumps(placement,indent=2),encoding='utf-8')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(-1,-2,3));bpy.context.object.data.energy=250;bpy.context.object.data.size=3
bpy.ops.object.camera_add(location=(1,-1.6,1.3));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.17))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.95;scene.camera=cam
scene.render.resolution_x=900;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.render.filepath=str(ROOT/'outputs/previews/stage2-cake.png');bpy.ops.render.render(write_still=True)
print('STAGE2_CAKE_OK')
