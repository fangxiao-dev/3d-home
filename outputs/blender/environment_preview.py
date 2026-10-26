"""Environment-only review cameras; never modifies saved source/GLB assets."""
import bpy, math
from mathutils import Vector


def render_previews(e, only=None):
    scene=bpy.context.scene; out=e['OUT']; area=e['area']; camera=e['camera']
    scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.72,.77,.80,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
    scene.render.resolution_x=1440; scene.render.resolution_y=1080
    # Large source gives readable contact shadows without miniature harshness.
    area('V2 large softbox',(0,-1,12),(1,-1,0),1800,(1,.89,.75),10)
    for rid,b in e['ROOMS'].items():
        cx,cy=(b[0]+b[1])/2,(b[2]+b[3])/2
        area('V2 fill '+rid,(cx,cy,5),(cx,cy,0),180,(1,.95,.86),4)
    meshes=[o for o in scene.objects if o.type=='MESH']
    def shot(name,rooms,loc,target,scale,hide):
        if only and name!=only: return
        for o in meshes:
            o.hide_render=(o.get('room_id') not in rooms or o.get('cutaway','') in hide)
        scene.camera=camera(name,loc,target,ortho=scale)
        scene.render.filepath=str(out/'previews'/('v2-environment-'+name+'.png'))
        bpy.ops.render.render(write_still=True)
    shot('dining',{'dining'},(-6,-10,6),(-.3,-4.25,.7),6.5,{'top','south','west'})
    shot('living',{'living','balcony'},(9,-8,10),(-.1,3.65,.65),10.5,{'top','south','east'})
    shot('study',{'study'},(1,-10,6),(7.2,-4.3,.7),6.7,{'top','south','west'})
    shot('balcony',{'balcony'},(5,3,5),(0,6.9,.8),6.4,{'top','south','east'})
    shot('wash',{'wash'},(7,0,4),(3.2,-3.2,.7),4.2,{'top','north','east'})
    shot('kitchen',{'kitchen'},(6,-3,6),(-.4,-8,.8),6.5,{'top','north','east'})
    shot('hallway',{'hallway'},(17,-13,12),(5,-1,.7),16,{'top','south','east'})
    shot('whole-house',set(e['ROOMS']),(22,-24,25),(3.7,-.7,.4),24,{'top','south','east'})
    if only: return
    # Scale pole is review-only, outside exported source.
    for o in meshes: o.hide_render=o.get('room_id')!='dining' or bool(o.get('cutaway'))
    pole=e['box']('165 cm scale pole',(.1,-4.0,.825),(.045,.045,1.65),e['brass'],.005)
    for z in (0,.45,.75,1.65):
        e['box']('Scale tick',(.1,-4,z),(.28,.045,.015),e['brass'],.002)
        data=bpy.data.curves.new('Scale label','FONT'); data.body=f'{z:.2f} m'; data.size=.12
        obj=bpy.data.objects.new('Scale label',data); scene.collection.objects.link(obj)
        obj.location=(.28,-4,z); obj.rotation_euler=(math.pi/2,0,0)
    scene.camera=camera('Furniture scale',(-5,-10,3.6),(-.3,-4.5,.85),ortho=5.5)
    scene.render.filepath=str(out/'previews/v2-environment-proportions.png'); bpy.ops.render.render(write_still=True)


