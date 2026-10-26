"""Small shared geometry adapter for the independently authored room modules.

Coordinates remain Blender world coordinates (Z up); Godot maps (x,y,z)
to (x,z,-y). Bounds are composition proportions, not measured dimensions.
"""
import math
import json
import bpy
from pathlib import Path
SPEC = json.loads((Path(__file__).parent / 'scene-v2-spec.json').read_text(encoding='utf-8'))

ROOMS = {
    'living': (-2.9, 2.9, 0.0, 5.8),
    'balcony': (-2.9, 2.9, 5.8, 8.0),
    'hallway': (-2.9, 11.9, -2.0, 0.0),
    'dining': (-2.9, 2.0, -6.6, -2.0),
    'wash': (2.0, 4.6, -4.4, -2.0),
    'study': (4.6, 9.6, -6.6, -2.0),
    'kitchen': (-2.9, 2.0, -9.2, -6.6),
}
HEIGHT = 3.3  # Legacy shell source; environment_v2 normalizes to SPEC wall_height.


class RoomBuilder:
    def __init__(self, env, room_id):
        self.env = env
        self.room_id = room_id
        self.bounds = ROOMS[room_id]
        self.furniture_id = ''
        self.m = {key: env[key] for key in (
            'wall', 'trim', 'cream', 'throw', 'cushion', 'wood', 'tablewood',
            'black', 'screen', 'brass', 'curtain', 'window', 'frame', 'green',
            'yellow', 'red', 'bulb')}
        self.m['tile'] = env['tilemats'][2]

    def tag(self, obj, solid, side):
        obj['category'] = 'House'
        obj['room_id'] = self.room_id
        obj['collision'] = bool(solid)
        obj['cutaway'] = side
        if self.furniture_id: obj['furniture_id'] = self.furniture_id
        return obj

    def box(self, name, loc, size, mat='cream', bevel=.025, solid=True, side=''):
        return self.tag(self.env['box'](self.room_id+' '+name, loc, size,
            self.m[mat], bevel), solid, side)

    def cylinder(self, name, loc, radius, depth, mat='brass', r2=None, solid=False, side=''):
        return self.tag(self.env['cylinder'](self.room_id+' '+name, loc,
            radius, depth, self.m[mat], r2), solid, side)

    def ellipsoid(self, name, loc, scale, mat='cream', solid=False, side=''):
        return self.tag(self.env['ellipsoid'](self.room_id+' '+name, loc,
            scale, self.m[mat]), solid, side)

    def rod(self, name, start, end, radius, mat='brass', solid=False, side=''):
        return self.tag(self.env['rod'](self.room_id+' '+name, start, end,
            radius, self.m[mat]), solid, side)

    def floor(self):
        x0,x1,y0,y1 = self.bounds
        margin=.11 if self.room_id=='living' else 0
        base=self.box('floor', ((x0+x1)/2,(y0+y1)/2,-.10),
                      (x1-x0+2*margin,y1-y0+2*margin,.20), 'tile', .005, True)
        if self.room_id=='living': base.name='Floor foundation'
        base['floor_role']='foundation'
        # A continuous top keeps lightmap filtering away from per-tile side faces.
        mesh=bpy.data.meshes.new(self.room_id+' floor finish')
        mesh.from_pydata([(x0,y0,.001),(x1,y0,.001),(x1,y1,.001),(x0,y1,.001)],[],[(0,1,2,3)])
        obj=bpy.data.objects.new(self.room_id+' floor finish',mesh)
        bpy.context.collection.objects.link(obj)
        self.tag(obj,False,'');obj['floor_role']='finish'
        mesh.materials.append(self.env['floor_finish'])
        uv=mesh.uv_layers.new(name='UVMap')
        for loop in mesh.loops:
            p=mesh.vertices[loop.vertex_index].co
            uv.data[loop.index].uv=((p.x-x0)/3.2,(p.y-y0)/3.2)

    def wall(self, side, openings=()):
        """Openings are (start,end[,height]); normal doorways default to 2.45."""
        x0,x1,y0,y1=self.bounds
        along_x=side in ('north','south')
        start,end=(x0,x1) if along_x else (y0,y1)
        fixed={'north':y1,'south':y0,'west':x0,'east':x1}[side]
        def segment(a,b,z,h,mat='wall'):
            if b-a < .005: return
            loc=((a+b)/2,fixed,z) if along_x else (fixed,(a+b)/2,z)
            size=(b-a,.12,h) if along_x else (.12,b-a,h)
            self.box('wall '+side,loc,size,mat,.008,True,side)
        cursor=start
        for opening in sorted(openings):
            a,b=opening[:2]
            portal_height=opening[2] if len(opening)>2 else 2.45
            assert start <= a < b <= end
            segment(cursor,a,HEIGHT/2,HEIGHT)
            if portal_height < HEIGHT:
                segment(a,b,(HEIGHT+portal_height)/2,HEIGHT-portal_height)
            cursor=b
        segment(cursor,end,HEIGHT/2,HEIGHT)
        # A shallow continuous crown keeps shell style consistent.
        loc=((start+end)/2,fixed,HEIGHT-.14) if along_x else (fixed,(start+end)/2,HEIGHT-.14)
        size=(end-start,.16,.10) if along_x else (.16,end-start,.10)
        self.box('crown '+side,loc,size,'trim',.008,False,side)

    def ceiling(self):
        x0,x1,y0,y1=self.bounds
        self.box('ceiling',((x0+x1)/2,(y0+y1)/2,HEIGHT+.05),
                 (x1-x0,y1-y0,.10),'trim',.01,False,'top')

    def shell(self, sides):
        self.floor()
        for side,openings in sides.items(): self.wall(side,openings)
        self.ceiling()

    def door(self, name, center, side, width=1.0):
        """Closed decorative door on an existing wall, no interior or action."""
        x,y=center
        along_x=side in ('north','south')
        inward = {'north':(0,-1),'south':(0,1),'west':(1,0),'east':(-1,0)}[side]
        x += inward[0] * .075
        y += inward[1] * .075
        size=(width,.065,2.25) if along_x else (.065,width,2.25)
        self.box(name,(x,y,1.125),size,'wood',.025,True,side)
        for shift in (-width/2-.04,width/2+.04):
            loc=(x+shift,y,1.17) if along_x else (x,y+shift,1.17)
            dims=(.07,.10,2.34) if along_x else (.10,.07,2.34)
            self.box(name+' casing',loc,dims,'trim',.01,False,side)
        dims=(width+.15,.10,.08) if along_x else (.10,width+.15,.08)
        self.box(name+' lintel',(x,y,2.30),dims,'trim',.01,False,side)
        loc=(x+width*.30,y+inward[1]*.055,1.0) if along_x else (x+inward[0]*.055,y+width*.30,1.0)
        self.ellipsoid(name+' handle',loc,(.04,.04,.04),'brass',False,side)


