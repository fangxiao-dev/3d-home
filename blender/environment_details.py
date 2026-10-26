"""Joinery and utility detailing shared by the seven room assemblies."""
import bpy, math


def add_details(env):
    A=env['RoomBuilder']
    # Seat welt follows a rounded rectangular cushion rather than a box outline.
    a=A(env,'living'); a.furniture_id='sofa'
    for cy in (2.48,3.35,4.21):
        pts=[]; cx=-2.27; hx,hy,r=.345,.395,.065
        for sx,sy,base in ((1,1,0),(-1,1,90),(-1,-1,180),(1,-1,270)):
            for i in range(7):
                ang=math.radians(base+i*15)
                pts.append((cx+sx*(hx-r)+r*math.cos(ang),cy+sy*(hy-r)+r*math.sin(ang),.421))
        curve=bpy.data.curves.new('Upholstery seam','CURVE'); curve.dimensions='3D'; curve.bevel_depth=.004; curve.bevel_resolution=2
        sp=curve.splines.new('POLY'); sp.points.add(len(pts)-1)
        for p,co in zip(sp.points,pts): p.co=(*co,1)
        sp.use_cyclic_u=True
        obj=bpy.data.objects.new('Sofa cushion welt',curve); bpy.context.collection.objects.link(obj)
        curve.materials.append(env['cream']); a.tag(obj,False,'')
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj; bpy.ops.object.convert(target='MESH')
    # Sofa sits on short recessed timber feet and gains a visible lower shadow line.
    for yy in (2.13,4.58):
        for xx in (-2.63,-2.03): a.cylinder('sofa timber foot',(xx,yy,.055),.035,.11,'wood')
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH': continue
        room=o.get('room_id'); n=o.name
        if room in ('kitchen','balcony') and not o.get('cutaway') and o.location.z>.03 and o.location.z<1.6:
            o.location.z*=.88; o.scale.z*=.88
    # Wash station height is adult-scaled; build a hollow basin from rim walls.
    for o in list(bpy.context.scene.objects):
        if o.name=='wash wash basin': bpy.data.objects.remove(o,do_unlink=True)
        elif o.name.startswith(('wash vanity','wash wash faucet')):
            o.location.z*=.78; o.scale.z*=.78
    a=A(env,'wash'); a.furniture_id='wash_vanity'
    for dy in (-.30,.30): a.box('basin rim side',(2.45,-3.17+dy,1.01),(.55,.055,.13),'throw',.025,False)
    for dx in (-.25,.25): a.box('basin rim end',(2.45+dx,-3.17,1.01),(.055,.57,.13),'throw',.025,False)
    a.box('basin hollow floor',(2.45,-3.17,.956),(.46,.53,.025),'throw',.025,False)
    a.cylinder('basin drain',(2.45,-3.17,.973),.025,.004,'brass')
    a.box('folded hand towel',(2.45,-2.66,.989),(.30,.20,.035),'cushion',.018,False)
    # Door fields are recessed timber joinery, not extra wall decorations.
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH' or 'door' not in o.name or o.get('room_id')!='hallway': continue
        if 'casing' in o.name or 'handle' in o.name or 'lintel' in o.name: continue
        if o.dimensions.z<1: continue
        a=A(env,'hallway'); a.furniture_id=o['furniture_id']; side=o.get('cutaway','')
        if side in ('north','south'):
            yy=o.location.y+(-.04 if side=='north' else .04)
            for zz,hh in ((.48,.48),(1.25,.76)):
                a.box('door inset panel',(o.location.x,yy,zz),(.73,.015,hh),'tablewood',.008,False,side)
    # Guzheng bridge rhythm plus finer strings gives a recognizable instrument.
    a=A(env,'study'); a.furniture_id='guzheng'
    for i in range(12):
        x=5.18+i*.018; y=-4.9+i*.035
        a.box('guzheng bridge',(x,y,1.137),(.014,.035,.035),'wood',.004,False)
        a.rod('guzheng fine string',(x,-5.40,1.16),(x,-3.84,1.16),.0018,'brass')

