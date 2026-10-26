"""Render a saved environment draft while the production UV pass runs."""
from pathlib import Path
import bpy,sys
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from room_api import ROOMS
from environment_preview import render_previews
OUT=Path(__file__).resolve().parent.parent
draft=OUT/'work/v2-environment-draft.blend'
bpy.ops.wm.open_mainfile(filepath=str(draft if '--draft' in sys.argv and draft.exists() else OUT/'blender/living-room.blend'))
s=bpy.context.scene; s.render.engine='CYCLES'; s.cycles.samples=16;s.cycles.denoiser="OPTIX"; s.cycles.use_denoising=True
s.render.threads_mode='FIXED'; s.render.threads=2; s.view_settings.view_transform='AgX'
def area(name,loc,target,power,color,size):
    d=bpy.data.lights.new(name,'AREA'); d.energy=power; d.color=color; d.shape='DISK'; d.size=size
    o=bpy.data.objects.new(name,d); s.collection.objects.link(o); o.location=loc; o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler(); return o
def camera(name,loc,target,ortho=None):
    d=bpy.data.cameras.new(name); o=bpy.data.objects.new(name,d); s.collection.objects.link(o)
    o.location=loc; o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler(); d.type='ORTHO'; d.ortho_scale=ortho; return o
def box(name,loc,size,mat,bevel=.005):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
    if bevel:b=o.modifiers.new('Edge','BEVEL');b.width=bevel;b.segments=3
    return o
brass=bpy.data.materials['Aged brass']
try:
    prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
    for d in prefs.devices:d.use=d.type=='OPTIX'
    s.cycles.device='GPU'
except Exception:s.cycles.device='CPU'
only=next((arg.split('=',1)[1] for arg in sys.argv if arg.startswith('--only=')),None)
render_previews(globals(),only=only or ('dining' if '--draft' in sys.argv else None))



