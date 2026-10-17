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

W, D, H = 5.8, 5.8, 3.30
LEFT_SHIFT, RIGHT_SHIFT = -.75, .75
category = 'Architecture'

def left_x(x):
    return x + LEFT_SHIFT

def right_x(x):
    return x + RIGHT_SHIFT

# Structural heights derive from the single room height above. Window bottoms
# and the middle transom stay fixed while the upper edges follow the taller room.
WINDOW_BOTTOM = .035
WINDOW_MIDDLE = .96
WINDOW_BACK_TOP = H - .245
WINDOW_FRAME_TOP = H - .23
BALCONY_OPENING_TOP = H - .05
RETURN_ANCHOR_X = -.31
RETURN_SCALE_X = .5
TEA_TABLE_CENTER_X, TEA_TABLE_CENTER_Y = -.65, 2.65
TEA_TABLE_SCALE_XY = .85

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
    x = side * (W/2-.095)
    for y in (yc-width/2, yc+width/2):
        box('Wall panel vertical', (x,y,(top+bottom)/2), (.025,.025,top-bottom), trim, .005)
    for z in (bottom, top):
        box('Wall panel horizontal', (x,yc,z), (.025,width,.025), trim, .005)

# Open at the hallway; balcony is only a boundary opening, not a new room.
box('Floor foundation', (0,D/2,-.12), (W+.22,D+.22,.20), tilemats[2])
for ix in range(math.ceil(W/.8)):
    for iy in range(8):
        x0, x1 = -W/2+ix*.8, min(-W/2+(ix+1)*.8, W/2)
        y0, y1 = iy*.8, min((iy+1)*.8,D)
        if x1>x0 and y1>y0:
            box('Stone floor tile', ((x0+x1)/2,(y0+y1)/2,-.012),
                (x1-x0-.006,y1-y0-.006,.025), random.choice(tilemats), .002)
category = 'Wall_Sofa'
box('Sofa side wall', (-W/2-.08,D/2,H/2), (.16,D,H), wall)
category = 'Wall_TV'
box('TV side wall', (W/2+.08,D/2,H/2), (.16,D,H), wall)
category = 'Architecture'
for side in (-1,1):
    box('Baseboard', (side*(W/2-.015),D/2,.075), (.035,D,.15), trim, .005)
    for z,thick in ((H-.23,.06),(H-.17,.035),(H-.12,.025)):
        box('Crown moulding', (side*(W/2-.05),D/2,z), (.10,D,thick), trim, .006)
    for yc, wid in ((1.2,.65),(3.25,2.9),(5.25,.55)):
        if side == -1 and yc == 1.2:
            continue
        panel(side,yc,wid,.92,H-.37)
    if side == 1:
        panel(side,.75,.65,.17,.78)

# Entrance door visible on sofa wall near the hallway.
box('Entrance door', (left_x(-2.13),.72,1.12), (.045,1.0,2.24), wood)
for y in (.18,1.26):
    box('Door casing', (left_x(-2.09),y,1.16), (.08,.085,2.32), trim)
box('Door casing lintel', (left_x(-2.09),.72,2.30), (.08,1.16,.09), trim)
box('Door centre seam', (left_x(-2.095),.78,1.10), (.01,.014,2.18), black, 0)
box('Door handle', (left_x(-2.055),.94,1.0), (.05,.025,.16), brass)

# Balcony-facing opening and distant glazing, kept shallow.
balcony_pier_x = W/2-.17
window_half_width = W/2-.37
for x in (-balcony_pier_x,balcony_pier_x):
    box('Balcony opening pier', (x,5.8,BALCONY_OPENING_TOP/2), (.34,.20,BALCONY_OPENING_TOP), wall)
box('Balcony lintel', (0,5.8,H-.19), (W,.30,.38), wall)
window_back_height = WINDOW_BACK_TOP - WINDOW_BOTTOM
box('Window daylight backing', (0,5.91,(WINDOW_BACK_TOP+WINDOW_BOTTOM)/2), (W-.75,.025,window_back_height), window, 0)
for x in (-window_half_width,-window_half_width/3,window_half_width/3,window_half_width):
    frame_height = WINDOW_FRAME_TOP - .02
    box('Window vertical frame', (x,5.87,(WINDOW_FRAME_TOP+.02)/2), (.045,.045,frame_height), frame, .002)
for z in (.04,WINDOW_MIDDLE,H-.25):
    box('Window horizontal frame', (0,5.87,z), (W-.70,.045,.045), frame, .002)
box('Balcony threshold', (0,5.77,.035), (W-.60,.24,.07), wood)
curtain_bottom = .04
curtain_top = WINDOW_FRAME_TOP
curtain_height = curtain_top - curtain_bottom
for side in (-1,1):
    for i in range(13):
        x = side*(W/2-.63+i*.043)
        cylinder('Curtain fold', (x,5.60,(curtain_top+curtain_bottom)/2), .037, curtain_height, curtain)

# Photo-led seating: long sofa along left wall, short return at hallway end.
category = 'Sofa'
box('Sofa plinth', (left_x(-1.64),3.37,.24), (.91,2.96,.32), cream, .08)
box('Sofa back', (left_x(-1.98),3.37,.77), (.22,2.95,.82), cream, .085)
for y in (2.02,4.72):
    box('Sofa arm', (left_x(-1.63),y,.61), (.91,.22,.68), cream, .09)
for y in (2.48,3.35,4.21):
    box('Sofa seat cushion', (left_x(-1.52),y,.48), (.72,.82,.20), throw, .075)
    o = box('Sofa back cushion', (left_x(-1.84),y,.88), (.25,.84,.64), throw, .09)
    o.rotation_euler.y = -.12
def return_x(original_center):
    return RETURN_ANCHOR_X + (original_center - RETURN_ANCHOR_X) * RETURN_SCALE_X + LEFT_SHIFT

box('Sofa return base', (return_x(-1.17),1.64,.28), (1.72*RETURN_SCALE_X,.87,.38), cream, .13)
# The hallway-facing return is a single rounded cream ottoman. Its seat keeps
# the retained half-width, depth, and original sitting height.
box('Sofa return seat', (return_x(-1.12),1.67,.50), (1.40*RETURN_SCALE_X,.69,.17), cream, .09)
o = box('Oat pillow', (left_x(-1.80),3.16,1.18), (.22,.50,.50), cushion, .07)
o.rotation_euler.x = -.12

category = 'TeaTable'
def tea_pos(original_x, original_y):
    return (TEA_TABLE_CENTER_X + (original_x-TEA_TABLE_CENTER_X)*TEA_TABLE_SCALE_XY + LEFT_SHIFT,
            TEA_TABLE_CENTER_Y + (original_y-TEA_TABLE_CENTER_Y)*TEA_TABLE_SCALE_XY)

def tea_size(original_x, original_y):
    return (original_x*TEA_TABLE_SCALE_XY, original_y*TEA_TABLE_SCALE_XY)

box('Tea table top', tea_pos(-.65,2.65)+(0.70,), tea_size(1.03,1.12)+(0.075,), tablewood)
box('Tea table lower shelf', tea_pos(-.65,2.65)+(0.15,), tea_size(.95,1.04)+(0.05,), tablewood)
for x in (-1.09,-.21):
    for y in (2.16,3.14):
        box('Tea table leg', tea_pos(x,y)+(0.37,), tea_size(.055,.055)+(0.66,), tablewood)
for i in range(4):
    box('Tea shelf slat', tea_pos(-.98+i*.22,2.65)+(0.20,), tea_size(.025,.94)+(0.025,), tablewood, .003)
box('Tissue packet', tea_pos(-.73,2.77)+(0.77,), tea_size(.22,.16)+(0.07,), window, .02)
box('Remote control', tea_pos(-.48,2.5)+(0.754,), tea_size(.16,.05)+(0.018,), black, .006)

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
cabinet('TV console',right_x(1.84),2.97,.56,2.36,.56,-1,2)
# Front glass-like double doors on the central cabinet section.
for y in (2.70,3.24):
    box('Console glass door',(right_x(1.541),y,.36),(.015,.49,.35),screen,.003)
    ellipsoid('Console door pull',(right_x(1.515),y+(.18 if y<3 else -.18),.38),(.022,.022,.022),brass)
category = 'TV'
box('Television bezel',(right_x(2.00),3.02,1.40),(.075,2.04,1.17),black,.012)
box('Television screen',(right_x(1.956),3.02,1.41),(.012,1.97,1.10),screen,.004)
category = 'Dresser'
cabinet('Tall chest',right_x(1.79),4.89,.66,1.10,1.31,-1,5)
category = 'SideTables'
cabinet('Balcony side cabinet',left_x(-1.48),5.18,1.1,.63,.48,1,1)

category = 'Decor'
# A few simple observed accents, without adding story content.
cylinder('Vase',(right_x(1.80),4.95,1.57),.105,.35,throw,r2=.075)
for i in range(7):
    a=i*2.4
    end=(right_x(1.80)+math.cos(a)*.13,4.95+math.sin(a)*.13,1.88+(i%3)*.04)
    rod('Flower stem',(right_x(1.80),4.95,1.70),end,.008,green)
    ellipsoid('Flower',end,(.055,.055,.042),cushion if i%2 else throw)
for yy,hh in ((2.32,.18),(2.50,.26)):
    ellipsoid('Cactus',(right_x(1.80),yy,.68+hh/2),(.055,.06,hh/2),green)

# Simplified chicken-shaped pet bed beside TV, visible in IMG_0449.
category = 'PetBed'
ellipsoid('Pet mat',(right_x(1.73),.79,.035),(.42,.48,.035),green)
ellipsoid('Pet bed base',(right_x(1.73),.79,.12),(.32,.35,.12),tablewood)
ellipsoid('Chicken bed body',(right_x(1.73),.79,.38),(.32,.32,.32),throw)
ellipsoid('Pet bed opening',(right_x(1.431),.79,.35),(.015,.19,.19),wood)
ellipsoid('Chicken beak',(right_x(1.43),.79,.57),(.085,.055,.045),yellow)
for y in (.69,.89):
    ellipsoid('Chicken eye',(right_x(1.46),y,.64),(.014,.014,.014),black)
for y in (.73,.79,.85):
    ellipsoid('Chicken comb',(right_x(1.73),y,.71),(.04,.04,.07),red)

category = 'Lamps'
def shade(name,loc,radius,height):
    return cylinder(name,loc,radius,height,trim,r2=radius*.66)
cylinder('Floor lamp foot',(left_x(-1.83),4.93,.035),.15,.07,brass)
rod('Floor lamp stem',(left_x(-1.83),4.93,.07),(left_x(-1.83),4.93,1.65),.018,brass)
shade('Floor lampshade',(left_x(-1.83),4.93,1.74),.24,.30)
for y in (1.22,4.77):
    o=cylinder('Sconce wall plate',(right_x(2.10),y,1.92),.085,.025,brass)
    o.rotation_euler.y=math.pi/2
    rod('Sconce arm',(right_x(2.10),y,1.92),(right_x(1.92),y,1.98),.014,brass)
    rod('Sconce stem',(right_x(1.92),y,1.81),(right_x(1.92),y,2.16),.012,brass)
    shade('Sconce shade',(right_x(1.92),y,2.22),.115,.19)

# Chandelier; ceiling is a separate hideable category for overview views.
rod('Chandelier suspension',(0,3.03,H-.09),(0,3.03,H-.65),.014,brass)
cylinder('Chandelier ceiling rose',(0,3.03,H-.09),.08,.06,brass)
bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=(0,3.03,H-.67),major_radius=.31,minor_radius=.013)
finish(bpy.context.object,'Chandelier ring',brass)
for i in range(5):
    a=i*2*math.pi/5
    x,y=math.cos(a)*.38,3.03+math.sin(a)*.38
    rod('Chandelier spoke',(0,3.03,H-.65),(x,y,H-.65),.013,brass)
    rod('Chandelier candle',(x,y,H-.65),(x,y,H-.50),.012,brass)
    shade('Chandelier shade',(x,y,H-.44),.10,.19)

category='Ceiling'
box('Ceiling plane',(0,D/2,H+.06),(W+.3,D+.3,.12),trim)
for side in (-1,1):
    box('Ceiling border',(side*(W/2-.19),D/2,H-.16),(.38,D,.19),trim)
    box('Warm cove strip',(side*(W/2-.40),D/2,H-.06),(.035,D-.28,.025),bulb,.002)
for y in (.18,5.61):
    box('Ceiling end border',(0,y,H-.16),(W,.36,.19),trim)
    box('Warm end cove strip',(0,y+(.19 if y<1 else -.19),H-.06),(W-.72,.025,.025),bulb,.002)

# Blender-only lights are intentionally not exported; Godot owns runtime light.
area('Window soft daylight',(0,5.55,H-.75),(0,1.5,.8),400,(.78,.88,1.0),3)
area('Ceiling warm bounce',(0,3,H-.18),(0,3,0),170,(1.0,.80,.58),3.3)
area('Hallway fill',(0,-1.0,H-.75),(0,3,1),180,(1.0,.94,.82),3)
for side in (-1,1):
    for y in (1.5,3,4.6):
        area('Wall wash',(side*(W/2-.40),y,H-.33),(side*(W/2-.05),y,1.5),12,(1.0,.86,.68),.32)

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
