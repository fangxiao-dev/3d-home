"""Rebuild the deliberately simple, photo-led living room. Run with Blender -b -P.

Coordinates: X sofa -> TV, Y hall -> balcony, Z up. All dimensions approximate.
Source observations: ../LIVING_ROOM.md. No original photographs are embedded.
"""
from pathlib import Path
import bpy
import math
import json
import random
from mathutils import Vector

OUT = Path(__file__).resolve().parents[1]
random.seed(19)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for material in list(bpy.data.materials):
    bpy.data.materials.remove(material)

W, D, H = 4.3, 5.8, 2.85
category = 'Architecture'

def material(name, rgb, rough=0.6, metallic=0.0, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metallic
    if emission:
        p.inputs['Emission Color'].default_value = (*rgb, 1)
        p.inputs['Emission Strength'].default_value = emission
    return m

wall = material('Warm greige walls', (.53, .50, .45))
trim = material('Ivory mouldings', (.79, .76, .68))
cream = material('Cream sofa fabric', (.71, .68, .59), .92)
throw = material('Off white sofa cover', (.82, .80, .72), 1)
cushion = material('Muted oat cushion', (.48, .43, .34), .95)
wood = material('Dark espresso wood', (.055, .040, .029), .36)
tablewood = material('Reddish tea table', (.25, .105, .045), .38)
black = material('Screen bezel', (.008, .009, .011), .25)
screen = material('TV dark glass', (.018, .027, .031), .13, .15)
brass = material('Aged brass', (.43, .28, .10), .3, .7)
curtain = material('Taupe curtains', (.32, .26, .20), .95)
window = material('Window daylight', (.51, .68, .74), .65, emission=.25)
frame = material('Window charcoal frame', (.052, .063, .064), .4)
green = material('Muted plant green', (.14, .22, .09), .9)
yellow = material('Chicken beak', (.66, .40, .10))
red = material('Chicken comb', (.34, .045, .025))
bulb = material('Warm lamp diffuser', (.95, .73, .41), .65, emission=1.2)
tilemats = [material(f'Grey stone tile {i}', (.235+i*.006, .226+i*.006, .208+i*.006), .32) for i in range(5)]

def finish(obj, name, mat):
    obj.name = name
    obj['category'] = category
    if mat:
        obj.data.materials.append(mat)
    return obj

def box(name, loc, size, mat, bevel=0.015):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        b = o.modifiers.new('Soft edges', 'BEVEL')
        b.width = bevel
        b.segments = 2
        o.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    return finish(o, name, mat)

def ellipsoid(name, loc, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=1, location=loc)
    o = bpy.context.object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for poly in o.data.polygons:
        poly.use_smooth = True
    return finish(o, name, mat)

def cylinder(name, loc, radius, depth, mat, r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius,
        radius2=radius if r2 is None else r2, depth=depth, location=loc)
    o = bpy.context.object
    for poly in o.data.polygons:
        poly.use_smooth = len(poly.vertices) == 4
    return finish(o, name, mat)

def rod(name, start, end, radius, mat):
    start, end = Vector(start), Vector(end)
    o = cylinder(name, (start + end) / 2, radius, (end-start).length, mat)
    o.rotation_euler = (end-start).to_track_quat('Z', 'Y').to_euler()
    return o

def area(name, loc, target, power, color, size):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy, data.color, data.shape, data.size = power, color, 'DISK', size
    o = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (Vector(target)-o.location).to_track_quat('-Z', 'Y').to_euler()
    return o

def panel(side, yc, width, bottom, top):
    x = side * 2.055
    for y in (yc-width/2, yc+width/2):
        box('Wall panel vertical', (x,y,(top+bottom)/2), (.025,.025,top-bottom), trim, .005)
    for z in (bottom, top):
        box('Wall panel horizontal', (x,yc,z), (.025,width,.025), trim, .005)

# Open at the hallway; balcony is only a boundary opening, not a new room.
box('Floor foundation', (0,D/2,-.12), (W+.22,D+.22,.20), tilemats[2])
for ix in range(6):
    for iy in range(8):
        x0, x1 = -W/2+ix*.8, min(-W/2+(ix+1)*.8, W/2)
        y0, y1 = iy*.8, min((iy+1)*.8,D)
        if x1>x0 and y1>y0:
            box('Stone floor tile', ((x0+x1)/2,(y0+y1)/2,-.012),
                (x1-x0-.006,y1-y0-.006,.025), random.choice(tilemats), .002)
category = 'Wall_Sofa'
box('Sofa side wall', (-2.23,D/2,H/2), (.16,D,H), wall)
category = 'Wall_TV'
box('TV side wall', (2.23,D/2,H/2), (.16,D,H), wall)
category = 'Architecture'
for side in (-1,1):
    box('Baseboard', (side*2.135,D/2,.075), (.035,D,.15), trim, .005)
    for z,thick in ((2.62,.06),(2.68,.035),(2.73,.025)):
        box('Crown moulding', (side*2.10,D/2,z), (.10,D,thick), trim, .006)
    for yc, wid in ((1.2,.65),(3.25,2.9),(5.25,.55)):
        if side == -1 and yc == 1.2:
            continue
        panel(side,yc,wid,.92,2.48)
    if side == 1:
        panel(side,.75,.65,.17,.78)

# Entrance door visible on sofa wall near the hallway.
box('Entrance door', (-2.13,.72,1.12), (.045,1.0,2.24), wood)
for y in (.18,1.26):
    box('Door casing', (-2.09,y,1.16), (.08,.085,2.32), trim)
box('Door casing lintel', (-2.09,.72,2.30), (.08,1.16,.09), trim)
box('Door centre seam', (-2.095,.78,1.10), (.01,.014,2.18), black, 0)
box('Door handle', (-2.055,.94,1.0), (.05,.025,.16), brass)

# Balcony-facing opening and distant glazing, kept shallow.
for x in (-1.98,1.98):
    box('Balcony opening pier', (x,5.8,1.4), (.34,.20,2.8), wall)
box('Balcony lintel', (0,5.8,2.66), (4.3,.30,.38), wall)
box('Window daylight backing', (0,5.91,1.32), (3.55,.025,2.57), window, 0)
for x in (-1.78,-.60,.60,1.78):
    box('Window vertical frame', (x,5.87,1.32), (.045,.045,2.6), frame, .002)
for z in (.04,.96,2.6):
    box('Window horizontal frame', (0,5.87,z), (3.6,.045,.045), frame, .002)
box('Balcony threshold', (0,5.77,.035), (3.7,.24,.07), wood)
for side in (-1,1):
    for i in range(13):
        x = side*(1.52+i*.043)
        cylinder('Curtain fold', (x,5.60,1.33), .037, 2.58, curtain)

# Photo-led seating: long sofa along left wall, short return at hallway end.
category = 'Sofa'
box('Sofa plinth', (-1.64,3.37,.24), (.91,2.96,.32), cream, .08)
box('Sofa back', (-1.98,3.37,.77), (.22,2.95,.82), cream, .085)
for y in (2.02,4.72):
    box('Sofa arm', (-1.63,y,.61), (.91,.22,.68), cream, .09)
for y in (2.48,3.35,4.21):
    box('Sofa seat cushion', (-1.52,y,.48), (.72,.82,.20), throw, .075)
    o = box('Sofa back cushion', (-1.84,y,.88), (.25,.84,.64), throw, .09)
    o.rotation_euler.y = -.12
box('Sofa return base', (-1.17,1.64,.28), (1.72,.87,.38), cream, .09)
box('Sofa return back', (-1.17,1.27,.74), (1.72,.22,.77), cream, .10)
box('Sofa return seat', (-1.12,1.67,.50), (1.40,.69,.17), cream, .07)
box('Sofa return outer arm', (-.39,1.66,.67), (.18,.85,.64), cream, .07)
o = box('Oat pillow', (-1.80,3.16,1.18), (.22,.50,.50), cushion, .07)
o.rotation_euler.x = -.12

category = 'TeaTable'
box('Tea table top', (-.65,2.65,.70), (1.03,1.12,.075), tablewood)
box('Tea table lower shelf', (-.65,2.65,.15), (.95,1.04,.05), tablewood)
for x in (-1.09,-.21):
    for y in (2.16,3.14):
        box('Tea table leg', (x,y,.37), (.055,.055,.66), tablewood)
for i in range(4):
    box('Tea shelf slat', (-.98+i*.22,2.65,.20), (.025,.94,.025), tablewood, .003)
box('Tissue packet', (-.73,2.77,.77), (.22,.16,.07), window, .02)
box('Remote control', (-.48,2.5,.754), (.16,.05,.018), black, .006)

category = 'Chairs'
for yc in (3.56,4.26):
    box('Chair seat', (-.88,yc,.46), (.47,.49,.065), wood, .025)
    for x in (-1.07,-.69):
        for y in (yc-.20,yc+.20):
            cylinder('Chair leg', (x,y,.23), .025,.46,wood)
    for y in (yc-.22,yc+.22):
        rod('Chair back post', (-1.09,y,.43),(-1.09,y,1.12),.022,wood)
        ellipsoid('Chair finial',(-1.09,y,1.14),(.033,.033,.045),wood)
    for i in range(4):
        rod('Chair spindle',(-1.09,yc-.14+i*.093,.53),(-1.09,yc-.14+i*.093,1.02),.011,wood)
    box('Chair top rail',(-1.09,yc,1.04),(.05,.47,.09),wood,.02)

def cabinet(name, x, y, depth, length, height, front, drawers):
    box(name+' body', (x,y,height/2+.06), (depth,length,height),wood)
    box(name+' top', (x,y,height+.09), (depth+.07,length+.07,.07),wood)
    for yy in (y-length/2+.06,y+length/2-.06):
        for xx in (x-depth/2+.05,x+depth/2-.05):
            box(name+' foot',(xx,yy,.08),(.07,.07,.16),wood)
    for i in range(drawers):
        z = .12+(i+.5)*(height-.08)/drawers
        box(name+' drawer', (x+front*(depth/2+.012),y,z),(.025,length-.08,(height-.12)/drawers-.015),wood,.007)
        for yy in (y-length*.23,y+length*.23):
            ellipsoid(name+' brass pull',(x+front*(depth/2+.045),yy,z),(.022,.023,.023),brass)

category = 'TVConsole'
cabinet('TV console',1.84,2.97,.56,2.36,.56,-1,2)
# Front glass-like double doors on the central cabinet section.
for y in (2.70,3.24):
    box('Console glass door',(1.541,y,.36),(.015,.49,.35),screen,.003)
    ellipsoid('Console door pull',(1.515,y+(.18 if y<3 else -.18),.38),(.022,.022,.022),brass)
category = 'TV'
box('Television bezel',(2.07,3.02,1.40),(.075,2.04,1.17),black,.012)
box('Television screen',(2.026,3.02,1.41),(.012,1.97,1.10),screen,.004)
category = 'Dresser'
cabinet('Tall chest',1.79,4.89,.66,1.10,1.31,-1,5)
category = 'SideTables'
cabinet('Balcony side cabinet',-1.48,5.18,1.1,.63,.48,1,1)
box('Entrance side table',(-1.73,1.08,.62),(.71,.53,.055),wood)

category = 'Decor'
# A few simple observed accents, without adding story content.
cylinder('Vase',(1.80,4.95,1.57),.105,.35,throw,r2=.075)
for i in range(7):
    a=i*2.4
    end=(1.80+math.cos(a)*.13,4.95+math.sin(a)*.13,1.88+(i%3)*.04)
    rod('Flower stem',(1.80,4.95,1.70),end,.008,green)
    ellipsoid('Flower',end,(.055,.055,.042),cushion if i%2 else throw)
for yy,hh in ((2.32,.18),(2.50,.26)):
    ellipsoid('Cactus',(1.80,yy,.68+hh/2),(.055,.06,hh/2),green)

# Simplified chicken-shaped pet bed beside TV, visible in IMG_0449.
category = 'PetBed'
ellipsoid('Pet mat',(1.73,.79,.035),(.42,.48,.035),green)
ellipsoid('Pet bed base',(1.73,.79,.12),(.32,.35,.12),tablewood)
ellipsoid('Chicken bed body',(1.73,.79,.38),(.32,.32,.32),throw)
ellipsoid('Pet bed opening',(1.431,.79,.35),(.015,.19,.19),wood)
ellipsoid('Chicken beak',(1.43,.79,.57),(.085,.055,.045),yellow)
for y in (.69,.89):
    ellipsoid('Chicken eye',(1.46,y,.64),(.014,.014,.014),black)
for y in (.73,.79,.85):
    ellipsoid('Chicken comb',(1.73,y,.71),(.04,.04,.07),red)

category = 'Lamps'
def shade(name,loc,radius,height):
    return cylinder(name,loc,radius,height,trim,r2=radius*.66)
cylinder('Floor lamp foot',(-1.83,4.93,.035),.15,.07,brass)
rod('Floor lamp stem',(-1.83,4.93,.07),(-1.83,4.93,1.65),.018,brass)
shade('Floor lampshade',(-1.83,4.93,1.74),.24,.30)
for y in (1.22,4.77):
    o=cylinder('Sconce wall plate',(2.10,y,1.92),.085,.025,brass)
    o.rotation_euler.y=math.pi/2
    rod('Sconce arm',(2.10,y,1.92),(1.92,y,1.98),.014,brass)
    rod('Sconce stem',(1.92,y,1.81),(1.92,y,2.16),.012,brass)
    shade('Sconce shade',(1.92,y,2.22),.115,.19)

# Chandelier; ceiling is a separate hideable category for overview views.
rod('Chandelier suspension',(0,3.03,2.76),(0,3.03,2.20),.014,brass)
cylinder('Chandelier ceiling rose',(0,3.03,2.76),.08,.06,brass)
bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=(0,3.03,2.18),major_radius=.31,minor_radius=.013)
finish(bpy.context.object,'Chandelier ring',brass)
for i in range(5):
    a=i*2*math.pi/5
    x,y=math.cos(a)*.38,3.03+math.sin(a)*.38
    rod('Chandelier spoke',(0,3.03,2.20),(x,y,2.20),.013,brass)
    rod('Chandelier candle',(x,y,2.20),(x,y,2.35),.012,brass)
    shade('Chandelier shade',(x,y,2.41),.10,.19)

category='Ceiling'
box('Ceiling plane',(0,D/2,2.91),(W+.3,D+.3,.12),trim)
for side in (-1,1):
    box('Ceiling border',(side*1.96,D/2,2.69),(.38,D,.19),trim)
    box('Warm cove strip',(side*1.75,D/2,2.79),(.035,D-.28,.025),bulb,.002)
for y in (.18,5.61):
    box('Ceiling end border',(0,y,2.69),(W,.36,.19),trim)
    box('Warm end cove strip',(0,y+(.19 if y<1 else -.19),2.79),(W-.72,.025,.025),bulb,.002)

# Blender-only lights are intentionally not exported; Godot owns runtime light.
area('Window soft daylight',(0,5.55,2.1),(0,1.5,.8),400,(.78,.88,1.0),3)
area('Ceiling warm bounce',(0,3,2.67),(0,3,0),170,(1.0,.80,.58),3.3)
area('Hallway fill',(0,-1.0,2.1),(0,3,1),180,(1.0,.94,.82),3)
for side in (-1,1):
    for y in (1.5,3,4.6):
        area('Wall wash',(side*1.75,y,2.52),(side*2.1,y,1.5),12,(1.0,.86,.68),.32)

scene=bpy.context.scene
scene.world.color=(.16,.16,.16)
scene.unit_settings.system='METRIC'
scene.render.engine='CYCLES'
scene.cycles.samples=32
scene.cycles.use_denoising=True
try:
    prefs=bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type='OPTIX'
    prefs.get_devices()
    gpu=False
    for device in prefs.devices:
        device.use=device.type=='OPTIX'
        gpu=gpu or device.use
    if gpu:
        scene.cycles.device='GPU'
except Exception as error:
    print('CPU render fallback:',error)
scene.render.resolution_x=1400
scene.render.resolution_y=1050
scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'

def camera(name,loc,target,lens=26,ortho=None):
    data=bpy.data.cameras.new(name)
    obj=bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.location=loc
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    data.lens=lens
    if ortho:
        data.type='ORTHO'
        data.ortho_scale=ortho
    return obj

entry=camera('View from hallway',(0,-.72,1.88),(0,3.2,1.24),23)
overview=camera('Cutaway overview',(0,-8,11),(0,2.9,.7),ortho=9.1)
scene.camera=entry
for space in [a.spaces.active for s in bpy.data.screens for a in s.areas if a.type=='VIEW_3D']:
    space.region_3d.view_perspective='CAMERA'

(OUT/'godot/assets').mkdir(parents=True,exist_ok=True)
(OUT/'previews').mkdir(parents=True,exist_ok=True)
meshes=[o for o in scene.objects if o.type=='MESH']
assert len(meshes)>50
assert all(all(math.isfinite(v) for v in o.location) for o in meshes)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'blender/living-room.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'godot/assets/living-room.glb'),
    export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,
    export_animations=False,export_extras=True)
manifest={'source_photos':['IMG_0447.HEIC','IMG_0448.HEIC','IMG_0449.HEIC','IMG_0450.HEIC'],
    'dimensions_are_estimates':True,'width':W,'depth':D,'height':H,
    'mesh_count':len(meshes),'categories':sorted(set(o['category'] for o in meshes))}
(OUT/'blender/model-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
scene.render.filepath=str(OUT/'previews/living-room-entry.png')
bpy.ops.render.render(write_still=True)
for obj in scene.objects:
    if obj.get('category') == 'Ceiling':
        obj.hide_render=True
scene.camera=overview
area('Overview fill',(2,-2,7),(0,3,0),650,(1,.93,.83),5)
scene.render.filepath=str(OUT/'previews/living-room-overview.png')
bpy.ops.render.render(write_still=True)
print('LIVING_ROOM_BUILD_OK',json.dumps(manifest))
