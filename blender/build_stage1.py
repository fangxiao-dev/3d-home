"""Editable Stage 1 props, separate from the house and character rigs."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'godot/assets/stage1'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def material(name, color, metallic=0, rough=.5):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metallic; p.inputs['Roughness'].default_value=rough
    return m

cloth=material('forest linen',(.12,.23,.19),rough=.85)
paper=material('warm paper',(.87,.81,.66),rough=.9)
gold=material('brushed old gold',(.70,.43,.12),.65,.28)
ribbon=material('wine ribbon',(.38,.075,.10),rough=.7)
gem=material('quiet jade',(.08,.35,.25),.25,.2)

def box(name, loc, scale, mat, bevel=.005):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o=bpy.context.object; o.name=name
    o.dimensions=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    if bevel:
        m=o.modifiers.new('soft edges','BEVEL'); m.width=bevel; m.segments=3
        o.modifiers.new('weighted normals','WEIGHTED_NORMAL')
    return o

def export(name, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True)

book=[]
book.append(box('lower linen cover',(0,0,.008),(.37,.46,.016),cloth))
book.append(box('paper block',(0,0,.029),(.35,.44,.028),paper))
book.append(box('upper linen cover',(0,0,.049),(.37,.46,.012),cloth))
book.append(box('rounded spine',(-.179,0,.029),(.022,.46,.052),cloth,.01))
for x in [-.145,.145]:book.append(box('gold border',(x,0,.056),(.002,.388,.001),gold,.0004))
for y in [-.194,.194]:book.append(box('gold border',(0,y,.056),(.29,.002,.001),gold,.0004))
book.append(box('ribbon bookmark',(.10,-.21,.057),(.035,.15,.003),ribbon,.002))
for x,z in [(-.035,.02),(0,.032),(.035,.02)]:
    book.append(box('cover crown point',(x,0,.058),(.018,.045+z,.002),gold,.002))
book.append(box('cover crown band',(0,-.037,.058),(.10,.015,.002),gold,.002))
export('letters-book',book)
for o in book:o.hide_render=True

crown=[]
count=96; verts=[]; faces=[]
for i in range(count):
    a=i*math.tau/count
    # eight softly pointed peaks, thick open band
    top=.055+.050*(max(0,math.cos(a*8))**4)
    for r,z in [(.155,0),(.155,top),(.144,top),(.144,0)]:verts.append((r*math.cos(a),r*math.sin(a),z))
for i in range(count):
    j=(i+1)%count
    for k in range(4):faces.append((i*4+k,j*4+k,j*4+(k+1)%4,i*4+(k+1)%4))
mesh=bpy.data.meshes.new('crown band');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Crown',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(gold)
m=o.modifiers.new('polished rims','BEVEL');m.width=.002;m.segments=3;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');crown.append(o)
for i in range(8):
    a=i*math.tau/8
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.011,location=(.155*math.cos(a),.155*math.sin(a),.034))
    o=bpy.context.object;o.name='jade accent';o.data.materials.append(gem);crown.append(o)
export('crown',crown)
for o in book:o.hide_render=False
for o in crown:o.location.x+=.48
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/stage1-props.blend'))
# A compact studio render to verify editable assets before engine integration.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.world.color=(.4,.4,.4)
bpy.ops.object.light_add(type='AREA',location=(0,-2,3));bpy.context.object.data.energy=250;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=3
bpy.ops.object.camera_add(location=(1,-1.7,1.65));cam=bpy.context.object;cam.rotation_euler=(Vector((.2,0,.02))-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=1.25
scene.render.resolution_x=900;scene.render.resolution_y=600;scene.render.resolution_percentage=100
scene.render.filepath=str(ROOT/'outputs/previews/stage1-props.png');bpy.ops.render.render(write_still=True)
(OUT/'placement.json').write_text(json.dumps({'book_position':[8.72,.762,4.55],'book_yaw':0,'approach':[8.255,0,4.55],'camera_position':[6.7,3.3,3.6],'camera_target':[8.4,.6,4.8],'crown_offset':[0,.19,0]},indent=2))
print('STAGE1_PROPS_OK')
