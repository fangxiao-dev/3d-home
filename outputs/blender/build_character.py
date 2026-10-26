"""Independent, reproducible skinned miniature character. Blender -b -P this_file.

Native Blender meters, front -Y. No private references or external textures.
The root stays fixed; articulated hips and two-bone limbs create the seated pose.
"""
from pathlib import Path
import bpy
import math
import json
import struct
import hashlib
from mathutils import Vector, Matrix

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
ASSETS = OUT / 'godot' / 'assets'
PREVIEWS = OUT / 'previews'
SPEC = json.loads((HERE / 'scene-v2-spec.json').read_text())
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
scene = bpy.context.scene
scene.render.fps = 30
parts = []

def material(name, color, roughness=.65):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    return mat

skin = material('Warm peach porcelain', (.68, .39, .235), .62)
blush = material('Soft cheek warmth', (.69, .31, .225))
hair = material('Cocoa hair', (.065, .032, .021), .57)
hairlight = material('Chestnut hair accents', (.10, .052, .033), .6)
eye = material('Chocolate eyes', (.035, .021, .015), .38)
white = material('Warm eye white', (.91, .85, .71))
mouth = material('Muted rose lips', (.27, .09, .063))
blue = material('Soft lagoon cardigan', (.18, .38, .365), .88)
trim = material('Lagoon ribbed hems', (.13, .29, .28), .9)
cream = material('Oatmilk cotton', (.78, .71, .56), .92)
sole = material('Ivory rubber soles', (.88, .82, .67), .82)
shoe = material('Sand suede sneakers', (.43, .30, .19), .83)
button = material('Coconut buttons', (.27, .16, .083), .65)

def mesh(name, verts, faces, mat, weights):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    data.materials.append(mat)
    for p in data.polygons:
        p.use_smooth = True
    groups = {}
    for i, co in enumerate(verts):
        weighted = weights(Vector(co)) if callable(weights) else {weights: 1.0}
        for bone, weight in weighted.items():
            if weight > .00001:
                if bone not in groups:
                    groups[bone] = obj.vertex_groups.new(name=bone)
                groups[bone].add([i], weight, 'REPLACE')
    parts.append(obj)
    return obj

def ellipsoid(name, center, scale, mat, bone, segments=24, rings=16):
    verts, faces = [], []
    for j in range(rings+1):
        phi = math.pi*j/rings
        for i in range(segments):
            a = math.tau*i/segments
            verts.append((center[0]+scale[0]*math.sin(phi)*math.cos(a),
                          center[1]+scale[1]*math.sin(phi)*math.sin(a),
                          center[2]+scale[2]*math.cos(phi)))
    for j in range(rings):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    return mesh(name,verts,faces,mat,bone)

def loft(name, rings, mat, weights, n=24):
    # Rings: center x,y,z and horizontal x/y radii. Rounded clothing silhouette.
    if callable(weights):
        rings=[tuple(a[i]*(1-t/4)+b[i]*(t/4) for i in range(5))
               for a,b in zip(rings,rings[1:]) for t in range(4)]+[rings[-1]]
    verts=[]; faces=[]
    for x,y,z,rx,ry in rings:
        for i in range(n):
            a=math.tau*i/n
            verts.append((x+rx*math.cos(a),y+ry*math.sin(a),z))
    for j in range(len(rings)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    faces += [tuple(range(n-1,-1,-1)),tuple((len(rings)-1)*n+i for i in range(n))]
    return mesh(name,verts,faces,mat,weights)

def tube(name, points, radius, mat, bone, n=10):
    if len(points)>2:
        source=[Vector(p) for p in points]
        radii=radius if isinstance(radius,list) else [radius]*len(points)
        points=[];radius=[]
        for k in range(len(source)-1):
            a,b,c,d=source[max(0,k-1)],source[k],source[k+1],source[min(k+2,len(source)-1)]
            for step in range(5):
                t=step/5
                points.append((.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))[:])
                radius.append(radii[k]*(1-t)+radii[k+1]*t)
        points.append(source[-1][:]);radius.append(radii[-1])
    verts=[];faces=[]
    for k,p in enumerate(points):
        p=Vector(p)
        tangent=Vector(points[min(k+1,len(points)-1)])-Vector(points[max(k-1,0)])
        tangent.normalize()
        side=tangent.cross(Vector((0,1,0)))
        if side.length < .001: side=tangent.cross(Vector((1,0,0)))
        side.normalize();up=tangent.cross(side).normalized()
        r=radius[k] if isinstance(radius,list) else radius
        for i in range(n):
            q=p+r*(math.cos(math.tau*i/n)*side+math.sin(math.tau*i/n)*up)
            verts.append(q[:])
    for k in range(len(points)-1):
        for i in range(n):
            a=k*n+i;b=k*n+(i+1)%n;faces.append((a,b,b+n,a+n))
    faces += [tuple(range(n-1,-1,-1)),tuple((len(points)-1)*n+i for i in range(n))]
    return mesh(name,verts,faces,mat,bone)

def blend_at(z, joint, upper, lower, width=.08):
    t=max(0,min(1,(z-joint)/width+.5))
    t=t*t*(3-2*t)
    return {upper:t,lower:1-t}

# Armature rest pose: relaxed A pose, cloth is tailored to this actual anatomy.
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object
rig.name='CharacterRig'
rig.data.name='CharacterSkeleton'
rig.data.edit_bones.remove(rig.data.edit_bones[0])
rest={}
def bone(name,head,tail,parent=None):
    b=rig.data.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=rig.data.edit_bones[parent]
    rest[name]=(Vector(head),Vector(tail),parent)

bone('Root',(0,0,0),(0,0,.15))
bone('Hips',(0,0,.87),(0,0,.99),'Root')
bone('Spine',(0,0,.99),(0,0,1.25),'Hips')
bone('Neck',(0,0,1.25),(0,0,1.37),'Spine')
bone('Head',(0,0,1.37),(0,0,1.60),'Neck')
for s,side in [(-1,'L'),(1,'R')]:
    bone('Thigh.'+side,(s*.095,0,.87),(s*.095,-.015,.48),'Hips')
    bone('Shin.'+side,(s*.095,-.015,.48),(s*.095,0,.085),'Thigh.'+side)
    bone('Foot.'+side,(s*.095,0,.085),(s*.095,-.16,.06),'Shin.'+side)
    bone('UpperArm.'+side,(s*.17,0,1.23),(s*.255,0,1.005),'Spine')
    bone('Forearm.'+side,(s*.255,0,1.005),(s*.29,-.015,.805),'UpperArm.'+side)
    bone('Hand.'+side,(s*.29,-.015,.805),(s*.30,-.025,.72),'Forearm.'+side)
bpy.ops.object.mode_set(mode='OBJECT')

# Pants have shaped hips, tapered continuous leg meshes and sewn cuffs.
hip_mesh=ellipsoid('Tailored trouser hips',(0,.012,.87),(.173,.105,.105),cream,'Hips')
hip_mesh.vertex_groups.new(name='_MeasureSeat').add(list(range(len(hip_mesh.data.vertices))),1,'REPLACE')
for s,side in [(-1,'L'),(1,'R')]:
    x=s*.095
    weights=lambda p,side=side:blend_at(p.z,.48,'Thigh.'+side,'Shin.'+side,.14)
    loft('Tapered trouser '+side,[(x,0,.88,.080,.090),(x,0,.79,.084,.09),(x,-.006,.65,.072,.078),
        (x,-.015,.52,.062,.066),(x,-.015,.48,.061,.066),(x,-.01,.43,.059,.064),
        (x,0,.25,.052,.055),(x,0,.12,.049,.052)],cream,weights)
    loft('Trouser cuff '+side,[(x,0,.12,.051,.054),(x,0,.16,.053,.056)],sole,'Shin.'+side)
    loft('Cotton sock '+side,[(x,0,.075,.039,.042),(x,0,.15,.039,.042)],cream,'Shin.'+side)
    # Flattened sole on z=0; shaped uppers separate rubber from suede.
    sole_mesh=loft('Sneaker sole '+side,[(x,-.062,0,.06,.115),(x,-.062,.012,.066,.12),
        (x,-.062,.035,.066,.12),(x,-.060,.042,.060,.113)],sole,'Foot.'+side)
    sole_mesh.vertex_groups.new(name='_MeasureSole.'+side).add(list(range(len(sole_mesh.data.vertices))),1,'REPLACE')
    ellipsoid('Sneaker upper '+side,(x,-.055,.066),(.061,.108,.055),shoe,'Foot.'+side)
    for y in [-.025,-.049,-.073]:
        tube('Cotton shoelace '+side,[(x-.032,y,.112),(x,y-.003,.119),(x+.032,y,.112)],.004,cream,'Foot.'+side)

def torso_weights(p):return blend_at(p.z,1.005,'Spine','Hips',.18)
loft('Tailored cardigan body',[(0,0,.865,.155,.103),(0,0,.89,.174,.114),(0,0,1.00,.173,.119),
    (0,0,1.12,.175,.112),(0,0,1.22,.169,.094),(0,0,1.255,.13,.079),
    (0,0,1.28,.070,.061)],blue,torso_weights)
loft('Rib knit waistband',[(0,0,.865,.158,.106),(0,0,.895,.174,.116)],trim,'Hips')
loft('Soft neck',[(0,0,1.245,.055,.052),(0,0,1.38,.053,.05)],skin,'Neck')
# Front tee inset and open cardigan neckline, sculpted surface ribbons.
mesh('Cream tee inset',[(-.061,-.086,1.255),(.061,-.086,1.255),(.035,-.12,1.13),(-.035,-.12,1.13)],[(0,1,2,3)],cream,'Spine')
for s in [-1,1]:
    tube('V neckline',[(s*.064,-.083,1.267),(s*.053,-.11,1.20),(0,-.126,1.10)],.009,trim,'Spine')
tube('Cardigan placket',[(0,-.127,1.10),(0,-.125,1.00),(0,-.119,.90)],.008,trim,torso_weights)
for z in [.93,1.00,1.07]:ellipsoid('Coconut button',(0,-.135,z),(.009,.004,.009),button,torso_weights,16,10)
for s,side in [(-1,'L'),(1,'R')]:
    def arm_weight(p,side=side):return blend_at(p.z,1.005,'UpperArm.'+side,'Forearm.'+side,.13)
    ellipsoid('Rounded shoulder seam '+side,(s*.17,0,1.225),(.069,.074,.063),blue,'UpperArm.'+side)
    loft('Soft sleeve '+side,[(s*.165,0,1.25,.067,.075),(s*.204,0,1.18,.072,.077),
        (s*.238,0,1.09,.065,.068),(s*.255,0,1.01,.06,.064),
        (s*.27,-.006,.93,.054,.057),(s*.283,-.012,.85,.047,.052)],blue,arm_weight)
    loft('Sleeve rib '+side,[(s*.283,-.012,.85,.049,.054),(s*.289,-.014,.815,.047,.051)],trim,'Forearm.'+side)
    ellipsoid('Palm '+side,(s*.295,-.017,.766),(.039,.032,.058),skin,'Hand.'+side)
    ellipsoid('Thumb '+side,(s*.267,-.040,.778),(.019,.020,.032),skin,'Hand.'+side)
    # Delicate finger divisions, rounded mitt silhouette at miniature scale.
    for j in range(3):
        ellipsoid('Finger '+side,(s*(.275+j*.017),-.020,.727),(.011,.023,.022),skin,'Hand.'+side,16,10)
    # Small welt pocket, follows garment instead of floating patch geometry.
    tube('Pocket welt '+side,[(s*.075,-.119,.99),(s*.135,-.093,1.01)],.006,trim,torso_weights)

# Sculpted oval face, full ears, tiny nose and warm almond eyes.
ellipsoid('Sculpted face',(0,-.002,1.483),(.122,.105,.15),skin,'Head',40,28)
for s in [-1,1]:
    ellipsoid('Ear',(s*.121,.002,1.475),(.027,.021,.040),skin,'Head')
    ellipsoid('Ear concha',(s*.132,-.014,1.477),(.012,.006,.022),blush,'Head',16,12)
    ellipsoid('Cheek warmth',(s*.071,-.086,1.451),(.023,.005,.011),blush,'Head',20,12)
    ellipsoid('Eye white',(s*.044,-.099,1.499),(.026,.008,.016),white,'Head')
    ellipsoid('Dark iris',(s*.043,-.106,1.499),(.012,.0045,.014),eye,'Head')
    ellipsoid('Eye glint',(s*.043-.004,-.110,1.505),(.0035,.002,.0035),white,'Head',12,8)
    tube('Upper eyelid',[(s*.020,-.105,1.501),(s*.042,-.108,1.515),(s*.067,-.095,1.505)],.0028,hair,'Head')
    tube('Soft brow',[(s*.020,-.096,1.533),(s*.043,-.102,1.538),(s*.067,-.090,1.532)],[.003,.005,.002],hair,'Head')
ellipsoid('Rounded nose',(0,-.109,1.469),(.017,.021,.020),skin,'Head')
tube('Small smile',[(-.023,-.098,1.432),(0,-.105,1.427),(.023,-.098,1.432)],.003,mouth,'Head')

# A fitted hair shell with varied hairline; swept tapered locks give a designed
# silhouette, rather than assembling spherical hair lumps.
verts=[];faces=[];n=48;nr=16
for j in range(nr+1):
    for i in range(n):
        a=math.tau*i/n
        front=max(0,-math.sin(a))
        end=1.91-.66*front + .06*math.cos(3*a)
        phi=.001+(end-.001)*j/nr
        verts.append((.129*math.sin(phi)*math.cos(a),.008+.112*math.sin(phi)*math.sin(a),1.494+.156*math.cos(phi)))
for j in range(nr):
    for i in range(n):
        a=j*n+i;b=j*n+(i+1)%n;faces.append((a,b,b+n,a+n))
mesh('Sculpted side-part hair cap',verts,faces,hair,'Head')
for k in range(7):
    x=.085-k*.025
    points=[(x,.004,1.628),(x-.016,-.060,1.615),(x-.035,-.101,1.579),(x-.044,-.108,1.543 + .007*abs(k-4))]
    tube('Swept fringe lock',points,[.021,.025,.022,.0015],hair if k%3 else hairlight,'Head',12)
for s in [-1,1]:
    tube('Tapered sideburn',[(s*.118,-.025,1.55),(s*.121,-.034,1.50),(s*.117,-.032,1.477)], [.019,.015,.003],hair,'Head',12)

# One render mesh, one skin, native material slots. Weights survive joining.
bpy.ops.object.select_all(action='DESELECT')
for obj in parts:obj.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join()
body=bpy.context.object;body.name='CharacterMesh'
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
body.parent=rig
modifier=body.modifiers.new('Character skin','ARMATURE');modifier.object=rig
rig['asset_version']=2
rig['forward']='-Y'
rig['generic_character']=True
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'

def ik_joint(a,c,l1,l2,pole):
    axis=c-a;d=axis.length;axis.normalize()
    along=(l1*l1-l2*l2+d*d)/(2*d)
    offset=max(0,l1*l1-along*along)**.5
    bend=Vector(pole)-a
    bend=(bend-axis*bend.dot(axis)).normalized()
    return a+axis*along+bend*offset

def posed_bone(name,head,tail):
    h,t,_=rest[name]
    rot=(t-h).rotation_difference(Vector(tail)-Vector(head)).to_matrix().to_4x4()
    mat=rot @ rig.data.bones[name].matrix_local
    mat.translation=Vector(head)
    rig.pose.bones[name].matrix=mat
    bpy.context.view_layer.update()

def pose(sit=0,phase=0,walking=False,breathe=0):
    # Root is fixed. Hips are the first moving bone; dimensions never change.
    stride_drop=.075*math.cos(phase)**2 if walking else 0
    hip=Vector((0,0,.87-.315*sit + breathe*.002 - stride_drop))
    lean=.025*sit
    spine=hip+Vector((0,-lean,.12))
    neck=spine+Vector((0,-lean,.26))
    head=neck+Vector((0,0,.12))
    posed_bone('Root',*rest['Root'][:2]);posed_bone('Hips',hip,spine)
    posed_bone('Spine',spine,neck);posed_bone('Neck',neck,head)
    posed_bone('Head',head,head+Vector((0,0,.23)))
    for s,side in [(-1,'L'),(1,'R')]:
        a=hip+Vector((s*.095,0,0))
        # Constant-speed planted half-cycle matches 0.66m / 0.4s = 1.65m/s.
        cycle=(phase/math.tau+(0 if s<0 else .5))%1
        swing=(4*cycle-1 if cycle<.5 else math.cos(math.tau*(cycle-.5))) if walking else 0
        lift=(math.sin(math.tau*(cycle-.5))*.085 if cycle>=.5 else 0) if walking else 0
        ankle=Vector((s*.095,-.38*sit + .33*swing*(1-sit),.085+lift*(1-sit)))
        knee=ik_joint(a,ankle,(rest['Thigh.'+side][1]-rest['Thigh.'+side][0]).length,
                      (rest['Shin.'+side][1]-rest['Shin.'+side][0]).length,(s*.095,-1,.48))
        posed_bone('Thigh.'+side,a,knee);posed_bone('Shin.'+side,knee,ankle)
        posed_bone('Foot.'+side,ankle,ankle+Vector((0,-.16,-.025)))
        shoulder=neck+Vector((s*.17,0,-.02))
        wrist=Vector((s*(.29-.17*sit),-.015-.235*sit-.065*swing*(1-sit),.805-.195*sit-stride_drop))
        elbow=ik_joint(shoulder,wrist,(rest['UpperArm.'+side][1]-rest['UpperArm.'+side][0]).length,
                      (rest['Forearm.'+side][1]-rest['Forearm.'+side][0]).length,(s*.6,.10,.8-.20*sit))
        posed_bone('UpperArm.'+side,shoulder,elbow);posed_bone('Forearm.'+side,elbow,wrist)
        handdir=Vector((s*.01,-.01-.075*sit,-.085+.07*sit)).normalized()*.086
        posed_bone('Hand.'+side,wrist,wrist+handdir)

clips={'Idle':(90,True),'Walk':(24,True),'SitDown':(36,False),'SitIdle':(90,True),'StandUp':(36,False)}
actions={}
for name,(frames,loop) in clips.items():
    action=bpy.data.actions.new(name);action.use_fake_user=True
    rig.animation_data_create();rig.animation_data.action=action
    for f in range(frames+1):
        t=f/frames
        smooth=t*t*(3-2*t)
        sit=smooth if name=='SitDown' else 1-smooth if name=='StandUp' else float(name=='SitIdle')
        pose(sit,math.tau*t, name=='Walk',math.sin(math.tau*t) if name in ('Idle','SitIdle') else 0)
        for pb in rig.pose.bones:
            pb.keyframe_insert('location',frame=f)
            pb.keyframe_insert('rotation_quaternion',frame=f)
    actions[name]=action
rig.animation_data.action=actions['Idle'];scene.frame_set(0)
scene.frame_start=0;scene.frame_end=90

# Save the authored rig before adding presentation-only stage and lights.
bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'character.blend'))
bpy.ops.export_scene.gltf(filepath=str(ASSETS/'character.glb'),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,
    export_force_sampling=True,export_anim_slide_to_zero=True,export_skins=True,export_extras=True,
    export_yup=True,export_materials='EXPORT')

measure_indices={name:[v.index for v in body.data.vertices
                     if any(g.group==body.vertex_groups[name].index for g in v.groups)]
                 for name in ['_MeasureSeat','_MeasureSole.L','_MeasureSole.R']}
def bounds(group=None):
    deps=bpy.context.evaluated_depsgraph_get()
    evaluated=body.evaluated_get(deps);data=evaluated.to_mesh()
    points=[evaluated.matrix_world @ data.vertices[i].co
            for i in (measure_indices[group] if group else range(len(data.vertices)))]
    result={'min':[min(p[i] for p in points) for i in range(3)],'max':[max(p[i] for p in points) for i in range(3)]}
    evaluated.to_mesh_clear();return result

measurements={}
for name in ('Idle','SitIdle'):
    rig.animation_data.action=actions[name];scene.frame_set(0);bpy.context.view_layer.update()
    measurements[name]={'blender_bounds':bounds(),'seat_bottom':bounds('_MeasureSeat')['min'][2],
        'sole_min_y':{side:bounds('_MeasureSole.'+side)['min'][2] for side in ['L','R']},
        'godot_bone_heads':{pb.name:[pb.head.x,pb.head.z,-pb.head.y] for pb in rig.pose.bones}}
assert abs(measurements['SitIdle']['seat_bottom']-.45)<.005
for name,measurement in measurements.items():
    assert all(abs(v)<.002 for v in measurement['sole_min_y'].values())
animation_checks={}
for name,(frames,loop) in clips.items():
    rig.animation_data.action=actions[name]
    min_sole=10.0;max_root=0.0
    for f in range(frames+1):
        scene.frame_set(f);bpy.context.view_layer.update()
        min_sole=min(min_sole,*[bounds('_MeasureSole.'+side)['min'][2] for side in ['L','R']])
        max_root=max(max_root,rig.pose.bones['Root'].location.length)
    assert min_sole>-.002,(name,min_sole)
    assert max_root<.00001,(name,max_root)
    animation_checks[name]={'minimum_sole_y':min_sole,'maximum_root_translation':max_root}
raw=(ASSETS/'character.glb').read_bytes()
length,kind=struct.unpack_from('<II',raw,12)
gltf=json.loads(raw[20:20+length])
assert len(gltf.get('skins',[]))==1
assert set(a['name'] for a in gltf['animations'])==set(clips),[a['name'] for a in gltf['animations']]
assert abs(measurements['Idle']['blender_bounds']['min'][2])<.002
assert abs(measurements['Idle']['blender_bounds']['max'][2]-1.65)<.01
contract={'version':2,'asset':'character.glb','rig':'CharacterRig','mesh':'CharacterMesh','root_bone':'Root',
    'forward':'+Z','units':'meters','height':1.65,'head_ratio':5.5,'scale':[1,1,1],
    'root_motion':False,'seat_surface_height':.45,'walk_reference_speed':SPEC['character']['walk_speed'],
    'clips':{name:{'duration':frames/30,'loop':loop} for name,(frames,loop) in clips.items()},
    'measurements':measurements,'animation_checks':animation_checks,
    'walk_stance_distance':.66,'walk_stance_duration':.4,
    'skin_count':len(gltf['skins']),'joint_count':len(gltf['skins'][0]['joints']),
    'sha256':hashlib.sha256(raw).hexdigest()}
(ASSETS/'character-contract.json').write_text(json.dumps(contract,indent=2),encoding='utf-8')

# Product presentation in a warm, neutral studio. Not exported into the game.
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.55,.55,.55)
scene.view_settings.view_transform='AgX'
stage=material('Studio cream',(.64,.59,.49))
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005))
bpy.context.object.data.materials.append(stage)
for location,power,size in [((2,-3,4),350,4),((-3,-1,2),180,3),((0,3,3),250,3)]:
    bpy.ops.object.light_add(type='AREA',location=location)
    light=bpy.context.object;light.data.energy=power;light.data.shape='DISK';light.data.size=size
    light.rotation_euler=(Vector((0,0,.9))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add()
camera=bpy.context.object;scene.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=2.05
def render(name,location,target=(0,0,.83)):
    camera.location=location;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(PREVIEWS/('v2-character-'+name+'.png'))
    bpy.ops.render.render(write_still=True)
rig.animation_data.action=actions['Idle'];scene.frame_set(0)
render('standing',(2,-4,2.4))
render('front',(0,-5,.83))
render('side',(5,0,.83))
rig.animation_data.action=actions['Walk'];scene.frame_set(6)
render('walk',(2,-4,2.4))
rig.animation_data.action=actions['SitIdle'];scene.frame_set(0)
# Visual seat reference, exactly at 0.45m, with rear edge behind hips.
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,.04,.425))
seat=bpy.context.object;seat.name='Preview seat at 45cm';seat.dimensions=(.48,.45,.05)
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
seat.data.materials.append(material('Seat reference',(.34,.24,.13)))
bevel=seat.modifiers.new('Seat edge','BEVEL');bevel.width=.02;bevel.segments=3
render('seated',(2.4,-4,2),(0,-.1,.66))
render('seated-side',(5,0,.7),(0,-.1,.66))
print('CHARACTER_CONTRACT '+json.dumps(contract))
