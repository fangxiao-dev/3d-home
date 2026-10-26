"""Review-only character/furniture scale scene; never saves either source asset."""
import bpy,math,sys
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent.parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'blender/living-room.blend'))
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=16;s.cycles.denoiser="OPTIX";s.cycles.use_denoising=True
s.render.threads_mode='FIXED';s.render.threads=2;s.render.resolution_x=1440;s.render.resolution_y=1080
try:
    prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
    for d in prefs.devices:d.use=d.type=='OPTIX'
    s.cycles.device='GPU'
except Exception:s.cycles.device='CPU'
s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs[0].default_value=(.72,.77,.80,1);s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
for o in s.objects:
    if o.type=='MESH':o.hide_render=o.get('room_id')!='dining' or bool(o.get('cutaway'))
def area(loc,power,size):
    d=bpy.data.lights.new('Scale softbox','AREA');d.energy=power;d.size=size;d.color=(1,.92,.82)
    o=bpy.data.objects.new('Scale softbox',d);s.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((-.5,-4,0))-o.location).to_track_quat('-Z','Y').to_euler()
area((0,-3,8),1300,7);area((-4,-7,5),500,5)
with bpy.data.libraries.load(str(OUT/'blender/character.blend'),link=False) as (src,dst):
    dst.objects=[n for n in src.objects if n in ('CharacterRig','CharacterMesh')]
    dst.actions=[n for n in src.actions if n in ('Idle','SitIdle')]
for o in dst.objects:
    if o:o.hide_render=False;s.collection.objects.link(o)
rig=bpy.data.objects.get('CharacterRig');rig.animation_data.action=bpy.data.actions.get('Idle');s.frame_set(0)
rig.location=(-.05,-4.18,0);rig.rotation_euler.z=-math.pi/4
cam=bpy.data.cameras.new('Scale camera');obj=bpy.data.objects.new('Scale camera',cam);s.collection.objects.link(obj);s.camera=obj;cam.type='ORTHO';cam.ortho_scale=5.5
obj.location=(-5,-10,3.6);obj.rotation_euler=(Vector((-.25,-4.5,.85))-obj.location).to_track_quat('-Z','Y').to_euler()
s.render.filepath=str(OUT/'previews/v2-environment-character-scale.png');bpy.ops.render.render(write_still=True)
rig.animation_data.action=bpy.data.actions.get('SitIdle');s.frame_set(0);rig.location=(-2.45,-4.18,0);rig.rotation_euler.z=math.pi/2
obj.location=(-.3,-8,2.9);obj.rotation_euler=(Vector((-1.9,-4.18,.75))-obj.location).to_track_quat('-Z','Y').to_euler();cam.ortho_scale=3.2
s.render.filepath=str(OUT/'previews/v2-environment-character-seated.png');bpy.ops.render.render(write_still=True)
for sid,x,y in [('entry_stool',-1.335,1.67),('sofa_middle',-2.215,3.35),('window_seat',-2.215,4.21),('study_chair',7.78,-4.76)]:
    for o in s.objects:
        if o.type=='MESH' and o.name!='CharacterMesh':o.hide_render=o.get('room_id')!=('study' if sid=='study_chair' else 'living') or bool(o.get('cutaway'))
    rig.location=(x,y,0);rig.rotation_euler.z=math.pi/2;s.frame_set(0)
    obj.location=(x+3,y-2.5,2.25);obj.rotation_euler=(Vector((x+.2,y,.65))-obj.location).to_track_quat('-Z','Y').to_euler();cam.ortho_scale=2.9
    if sid=='study_chair':
        obj.location=(6,-7.8,2.6);obj.rotation_euler=(Vector((8.1,-4.76,.65))-obj.location).to_track_quat('-Z','Y').to_euler();cam.ortho_scale=3.7
    elif sid=='sofa_middle':
        obj.location=(x+2.7,y+1.8,1.9);obj.rotation_euler=(Vector((x+.2,y,.65))-obj.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath=str(OUT/('previews/v2-environment-character-'+sid+'.png'));bpy.ops.render.render(write_still=True)



