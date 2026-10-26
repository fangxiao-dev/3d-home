"""Shared scene-v2 surface treatment, asset semantics and measured seat contract."""
import bpy, math, json, random
from mathutils import Vector
from pathlib import Path


def surfaces(env):
    """Small deterministic PBR images survive glTF export, unlike shader-only noise."""
    out=env['OUT']; folder=out/'godot/assets/environment-textures'; folder.mkdir(exist_ok=True)
    recipes={
        'wood':((.23,.14,.085),'wood',.42), 'tablewood':((.33,.19,.105),'wood',.36),
        'cream':((.79,.75,.65),'fabric',.82),'throw':((.91,.87,.77),'fabric',.87),
        'cushion':((.40,.48,.31),'fabric',.9),'curtain':((.52,.45,.36),'fabric',.95),
        'wall':((.80,.78,.70),'plaster',.86),'trim':((.94,.90,.80),'plaster',.55),
    }
    for key,(color,kind,rough) in recipes.items():
        mat=env[key]; p=mat.node_tree.nodes.get('Principled BSDF'); p.inputs['Roughness'].default_value=rough
        mat.diffuse_color=(*color,1); p.inputs['Base Color'].default_value=(*color,1)
        image=bpy.data.images.new('v2_'+key,256,256); pixels=[]
        rng=random.Random(41)
        for y in range(256):
            for x in range(256):
                if kind=='fabric': v=((x%3==0)+(y%3==0)-.66)*.012+rng.uniform(-.006,.006)
                else: v=0.0
                pixels.extend([max(0,min(1,c+v)) for c in color]+[1])
        image.pixels=pixels; image.filepath_raw=str(folder/(key+'.png')); image.file_format='PNG'; image.save()
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image
        mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    stone=bpy.data.images.new('v2 limestone',256,256); pixels=[]
    for y in range(256):
        for x in range(256):
            pixels.extend([.57,.56,.52,1])
    stone.pixels=pixels; stone.filepath_raw=str(folder/'limestone.png'); stone.file_format='PNG'; stone.save()
    for i,mat in enumerate(env['tilemats']):
        c=(.56+i*.008,.55+i*.008,.50+i*.008)
        mat.diffuse_color=(*c,1); p=mat.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*c,1); p.inputs['Roughness'].default_value=.43
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=stone
        mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    # Four 0.8 m tiles per repeat; grout is color, never a lightmap chart boundary.
    image=bpy.data.images.new('v2 floor finish',1024,1024);pixels=[]
    for y in range(1024):
        for x in range(1024):
            v=-.035 if x%256<2 or y%256<2 else 0.0
            pixels.extend([.57+v,.56+v,.52+v,1])
    image.pixels=pixels;image.filepath_raw=str(folder/'floor-finish.png');image.file_format='PNG';image.save()
    mat=bpy.data.materials.new('Continuous limestone floor');mat.use_nodes=True
    p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.52
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.extension='REPEAT'
    mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color']);env['floor_finish']=mat
    # Exported non-metal black appliances remain readable under diffuse light.
    for key,c in [('black',(.055,.060,.057)),('screen',(.095,.115,.11)),('frame',(.13,.15,.14)),('window',(.57,.72,.73))]:
        mat=env[key]; mat.diffuse_color=(*c,1); mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*c,1)


def finish_assets(env):
    scene=bpy.context.scene; api_class=env['RoomBuilder']
    print('V2_GEOMETRY_BUILT', len(scene.objects), flush=True)
    # Unify existing living furniture to the adult character, preserving layout.
    for o in list(scene.objects):
        if o.type!='MESH': continue
        n=o.name; room=o.get('room_id','living'); o['room_id']=room
        if room=='living':
            cat=o.get('category',''); side=''
            if cat=='Ceiling' or n.startswith('Chandelier'): side='top'
            elif cat=='Wall_Sofa' or n.startswith(('Entrance door','Door casing','Door centre','Door handle')): side='west'
            elif cat=='Wall_TV' or n.startswith('Sconce'): side='east'
            elif n.startswith(('Balcony opening','Balcony lintel','Curtain fold')): side='north'
            elif n.startswith(('Baseboard','Crown moulding','Wall panel')): side='west' if o.location.x<0 else 'east'
            o['cutaway']=side
            o['collision']=cat in ('Wall_Sofa','Wall_TV','Sofa','TVConsole','Dresser','SideTables','PetBed','TeaTable') or n=='Floor foundation'
            if n.startswith(('Sofa seat cushion','Sofa return seat')):
                o.location.z=.39; o.dimensions.z=.12
            elif n.startswith('Sofa plinth'): o.location.z=.205; o.dimensions.z=.29
            elif n.startswith('Sofa return base'): o.location.z=.195; o.dimensions.z=.27
            elif n.startswith(('Sofa back','Sofa arm','Oat pillow')): o.location.z*=.83; o.dimensions.z*=.83
            if cat=='TeaTable': o.location.x+=.48; o.location.z*=.72; o.dimensions.z*=.72
            ids={'Sofa':'sofa','TeaTable':'coffee_table','TVConsole':'tv_console','TV':'television','Dresser':'living_chest','SideTables':'living_side_cabinet','PetBed':'pet_bed'}
            if cat in ids: o['furniture_id']=ids[cat]
            if n.startswith('Sofa return'): o['furniture_id']='entry_stool'
        if 'collision' not in o: o['collision']=False
        if 'cutaway' not in o: o['cutaway']=''
        # Architectural cutaway objects need consistent wall-height and stay out of static GI.
        if o.get('cutaway') and not o.get('wall_mounted') and (room!='dining' or n.startswith(('dining wall','dining crown','dining ceiling'))):
            o.location.z*=env['SPEC']['wall_height']/3.3; o.scale.z*=env['SPEC']['wall_height']/3.3
        for mod in o.modifiers:
            if mod.type=='BEVEL': mod.segments=3
    # Replace the rough study seating rather than scaling a child-sized chair.
    for o in list(scene.objects):
        if o.name.startswith('study chair'): bpy.data.objects.remove(o,do_unlink=True)
    from rooms.dining import chair
    api=api_class(env,'study'); api.furniture_id='study_chair'; chair(api,7.78,-4.76)
    for o in list(scene.objects):
        if o.name.startswith(('study desk top','study desk pedestal','study desk drawer')):
            o.location.z*=.75/.94; o.scale.z*=.75/.94; o['furniture_id']='study_desk'
        elif o.name.startswith('study desk lamp'): o.location.z-=.19
        elif o.name.startswith('study bookcase'): o['furniture_id']='study_bookcase'
        elif o.name.startswith('study guzheng'): o['furniture_id']='guzheng'
    # Inset panel and thin bevel details make cabinet joinery read at close range.
    for o in list(scene.objects):
        if o.type!='MESH': continue
        n=o.name.lower(); room=o.get('room_id')
        if room in ('balcony','kitchen','wash') and ('cabinet door' in n or 'upper door' in n):
            a=api_class(env,room); a.furniture_id=o.get('furniture_id',room+'_cabinet')
            size=list(o.dimensions); loc=list(o.location)
            if size[0]<size[1]: size[1]*=.79; size[2]*=.75; size[0]=.012; loc[0]+=.02 if loc[0]<0 else -.02
            else: size[0]*=.79; size[2]*=.75; size[1]=.012; loc[1]+=.02
            field=a.box('recessed cabinet field',loc,size,'cream',.007,False,o.get('cutaway',''))
            if o.get('wall_mounted'): field['wall_mounted']=True
    # Small functional accents; no new story content.
    api=api_class(env,'study'); api.furniture_id='study_desk'
    api.box('desk writing mat',(8.80,-4.55,.755),(.60,.78,.008),'cushion',.035,False)
    api.box('closed notebook',(8.72,-4.55,.779),(.34,.44,.035),'wood',.018,False)
    api.box('notebook page block',(8.716,-4.55,.798),(.32,.42,.012),'throw',.01,False)
    api=api_class(env,'balcony'); api.furniture_id='balcony_wash_basin'
    for i in range(3): api.box('folded linen',(-2.42,7.27,1.075+i*.045),(.34,.34,.045),'throw' if i!=1 else 'cushion',.025,False)
    from environment_details import add_details
    add_details(env)
    # Upper cupboards should hide with their wall while bases remain grounded.
    for o in scene.objects:
        if o.type!='MESH': continue
        n=o.name.lower(); room=o.get('room_id','living')
        if not o.get('furniture_id'):
            keys=('washing machine','wash basin','vanity','mirror','guzheng','bookcase','desk','cabinet','countertop','oven','cooktop','sink','door')
            key=next((k for k in keys if k in n),'')
            if key: o['furniture_id']=room+'_'+key.replace(' ','_')
    # Any furniture assembly that may be hidden by the camera must not leave
    # shadows in static lightmaps. Visual attachments inherit the same owner.
    occluders={(o.get('room_id'),o.get('furniture_id')) for o in scene.objects
               if o.type=='MESH' and o.get('furniture_id') and o.get('collision')}
    for o in scene.objects:
        if o.type!='MESH': continue
        o['camera_occluder']=(o.get('room_id'),o.get('furniture_id')) in occluders
        o['bake_static']=bool(not o['camera_occluder'] and not o.get('cutaway') and not o.get('movable') and o.get('collision'))
    bpy.context.view_layer.update()
    write_contract(env)
    bpy.ops.wm.save_as_mainfile(filepath=str(env['OUT'].parent/'work/v2-environment-draft.blend'))
    print('V2_DRAFT_READY',flush=True)
    # Multi-object edit mode unfolds independent mesh datablocks in one pass.
    # Each object's islands occupy disjoint atlas regions, hence no local overlap.
    bpy.ops.object.select_all(action='DESELECT')
    meshes=[x for x in scene.objects if x.type=='MESH']
    for i,o in enumerate(meshes):
        bpy.context.view_layer.objects.active=o; o.select_set(True)
        for mod in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=mod.name)
        if len(o.data.uv_layers)==0: o.data.uv_layers.new(name='UVMap')
        uv=o.data.uv_layers.new(name='LightmapUV'); o.data.uv_layers.active=uv
        o.select_set(False)
        if i%100==0: print('V2_BEVEL',i,len(meshes),flush=True)
    from environment_lightmap import finish_uv
    finish_uv(meshes)
    print('V2_UV_READY',flush=True)


def write_contract(env):
    def gd(v): return [round(v[0],5),round(v[2],5),round(-v[1],5)]
    defs=[('sofa_middle','living','长沙发','sofa',(-2.215,3.35),(-1.45,3.35)),('window_seat','living','窗边坐位','sofa',(-2.215,4.21),(-1.35,4.35)),('entry_stool','living','入口软墩','entry_stool',(-1.335,1.67),(-.65,1.50)),('dining_chair','dining','餐椅','dining_chair',(-2.45,-4.18),(-1.98,-3.4)),('study_chair','study','书房椅','study_chair',(7.78,-4.76),(8.16,-4.0))]
    seats=[]
    for sid,room,label,fid,(x,y),(ax,ay) in defs:
        seats.append(dict(id=sid,room_id=room,label=label,furniture_id=fid,approach=gd((ax,ay,0)),root=gd((x,y,0)),exit=gd((ax,ay,0)),yaw=math.pi/2,surface_height=.45,camera_position=gd((x+2.7,y-2.6,2.25)),camera_target=gd((x+.18,y,.85))))
    groups={}
    for o in bpy.context.scene.objects:
        if o.type=='MESH' and o.get('furniture_id'):
            groups.setdefault((o['furniture_id'],o['room_id']),[]).extend(gd(o.matrix_world@Vector(c)) for c in o.bound_box)
    furniture=[dict(id=k[0],room_id=k[1],kind=k[0],bounds_min=[min(v[i] for v in vals) for i in range(3)],bounds_max=[max(v[i] for v in vals) for i in range(3)]) for k,vals in groups.items()]
    targets={k:gd(((b[0]+b[1])/2,(b[2]+b[3])/2,.6)) for k,b in env['ROOMS'].items()}
    data=dict(version=2,seats=seats,furniture=furniture,room_targets=targets)
    (env['OUT']/'godot/assets/scene-v2-data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')










