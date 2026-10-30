"""Six independently editable food props. Blender Z-up, each asset base rests at Z=0.
Run via Build.ps1 -RebuildFoodProps; source owns geometry and placement JSON.
"""
from pathlib import Path
import bpy, math, random, json, sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from asset_support import support_height
from mathutils import Vector
ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'godot/assets/food-world';OUT.mkdir(parents=True,exist_ok=True)
PREVIEW=ROOT/'outputs/previews';PREVIEW.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(31)
assets={};parts=[]

def mat(name,color,rough=.55):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
 return m
cream=mat('warm porcelain',(.82,.77,.65),.32);white=mat('milk and egg white',(.88,.84,.70));blue=mat('deep cobalt',(.025,.12,.42));red=mat('Pocky red',(.65,.025,.015));gold=mat('baked wheat',(.55,.27,.055));lightgold=mat('golden crumb',(.72,.40,.09));dark=mat('roasted edges',(.19,.065,.018));green=mat('basil green',(.045,.21,.025));lettuce=mat('fresh lettuce',(.18,.42,.035));yellow=mat('egg yolk',(.95,.43,.012),.3);milk=mat('coconut milk',(.79,.68,.48));coffee=mat('coffee layer',(.29,.115,.035));palegreen=mat('coconut pouch green',(.40,.56,.29));paper=mat('package ivory',(.86,.80,.62));ink=mat('package dark ink',(.12,.18,.09));sesame=mat('sesame',(.87,.70,.41));noodle=mat('sesame sauce noodles',(.60,.29,.055),.42);sauce=mat('sesame sauce shadow',(.31,.13,.025));mince=mat('basil chicken',(.42,.19,.055));rice=mat('warm rice',(.86,.82,.67));clear=mat('cup rim pale plastic',(.77,.73,.62),.2)
font=bpy.data.fonts.load(str(ROOT/'godot/assets/NotoSansSC-Reading.ttf'))

def add(o,name,m):
 o.name=name;o.data.materials.append(m);parts.append(o);return o

def box(name,loc,scale,m,bevel=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=add(bpy.context.object,name,m);o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mod=o.modifiers.new('soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=3;o.modifiers.new('weighted face normals','WEIGHTED_NORMAL');return o

def sphere(name,loc,scale,m,segments=16,rings=8):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=loc);o=add(bpy.context.object,name,m);o.scale=scale
 for f in o.data.polygons:f.use_smooth=True
 return o

def cyl(name,loc,r,depth,m,vertices=32,r2=None):
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r if r2 is None else r2,radius2=r,depth=depth,location=loc);o=add(bpy.context.object,name,m)
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 mod=o.modifiers.new('soft rim','BEVEL');mod.width=min(.0015,depth*.18);mod.segments=2;o.modifiers.new('weighted normals','WEIGHTED_NORMAL');return o

def tube(name,points,r,m,res=2):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=2;curve.bevel_depth=r;curve.bevel_resolution=res
 spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
 for p,co in zip(spline.points,points):p.co=(*co,1)
 o=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(o);o.data.materials.append(m);parts.append(o);return o

def lathe(name,profile,m,segments=48):
 verts=[(r*math.cos(j*math.tau/segments),r*math.sin(j*math.tau/segments),z) for r,z in profile for j in range(segments)]
 faces=[]
 for i in range(len(profile)-1):
  for j in range(segments):faces.append((i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);add(o,name,m)
 for f in mesh.polygons:f.use_smooth=True
 return o

def text(name,body,loc,size,m,rotation=(math.pi/2,0,0)):
 data=bpy.data.curves.new(name,'FONT');data.body=body;data.font=font;data.size=size;data.align_x='CENTER';data.extrude=.00015;data.resolution_u=3
 o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.location=loc;o.rotation_euler=rotation;o.data.materials.append(m);parts.append(o);return o

def leaf(name,center,length,width,m,angle):
 x,y,z=center;verts=[(-length/2,0,0),(-length*.2,-width*.5,.002),(length*.25,-width*.3,.004),(length*.5,0,.008),(length*.25,width*.3,.004),(-length*.2,width*.5,.002),(0,0,.009)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(6,i,(i+1)%6) for i in range(6)]);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.location=center;o.rotation_euler.z=angle;add(o,name,m)
 solid=o.modifiers.new('leaf thickness','SOLIDIFY');solid.thickness=.001
 return o

def finish(id):
 global parts
 assets[id]=list(parts)
 for o in parts:o['food_id']=id
 parts=[]

# Pocky: a solid carton with printed/embossed front and spine, no billboard.
box('Pocky carton',(0,0,.16),(.19,.07,.32),paper,.008)
box('red bottom band',(0,-.0355,.045),(.182,.001,.043),red,.0005)
text('Pocky title','Pocky',(0,-.037,.126),.088,red)
text('Pocky Chinese','百奇',(0,-.037,.079),.053,red)
text('milk subtitle','牛奶味',(0,-.037,.018),.017,white)
text('top brand','Glico',(0,-.037,.283),.026,red)
for i in range(7):
 x=(i-3)*.016;angle=(i-3)*.075
 pts=[(x*.45,-.038,.17),(x,-.038,.25)]
 tube('printed milk biscuit',pts,.0045,lightgold,1)
 tube('printed white coating',[pts[0],(x*.8,-.039,.215)],.0049,white,1)
# Side stripe, folded top and openable flap are actual volume.
box('carton top fold',(0,0,.318),(.17,.057,.003),white,.001)
box('red side stripe',(.095,0,.16),(.001,.065,.27),red,.0002)
finish('pocky')

# Coconut rolls: sealed pillow pouch, green ends and wafer illustration.
profiles=[(.002,.075,.025),(.025,.10,.035),(.13,.112,.045),(.245,.103,.035),(.285,.09,.018)]
verts=[];faces=[];n=24
for z,w,d in profiles:
 for j in range(n):
  a=j*math.tau/n;verts.append((w*math.copysign(abs(math.cos(a))**.35,math.cos(a)),d*math.copysign(abs(math.sin(a))**.35,math.sin(a)),z))
for i in range(len(profiles)-1):
 for j in range(n):faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
faces+=[tuple(reversed(range(n))),tuple((len(profiles)-1)*n+j for j in range(n))]
mesh=bpy.data.meshes.new('pillow pouch');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Coconut roll pouch',mesh);bpy.context.collection.objects.link(o);add(o,o.name,palegreen)
for f in mesh.polygons:f.use_smooth=True
box('ivory product label',(0,-.046,.145),(.19,.003,.19),paper,.009)
text('roll title','椰子卷',(0,-.049,.211),.061,ink)
text('roll caption','COCONUT ROLLS',(0,-.049,.181),.010,ink)
for i in range(3):
 x=-.055+i*.049
 tube('wafer printed roll',[(x,-.052,.065),(x+.024,-.052,.147)],.012,lightgold,2)
 for j in range(7):tube('wafer bake stripe',[(x+j*.003,-.064,.07+j*.010),(x+j*.003+.020,-.064,.067+j*.010)],.0011,gold,0)
for z in [.007,.279]:
 box('sealed pouch edge',(0,0,z),(.19,.042,.012),palegreen,.001)
 for i in range(12):box('seal crease',(-.083+i*.015,-.023,z),(.003,.002,.010),paper,.0005)
finish('coconut-rolls')

# Hot dry noodles: hollow porcelain bowl and separate flowing noodle strands.
lathe('noodle bowl',[(.001,.003),(.065,.003),(.075,.012),(.10,.032),(.145,.079),(.148,.087),(.14,.089),(.135,.080),(.095,.035),(.067,.018),(.001,.018)],cream)
lathe('blue bowl band',[(.131,.064),(.139,.074),(.14,.077),(.134,.069)],blue)
cyl('sauce under noodles',(0,0,.062),.118,.012,sauce)
for i in range(24):
 r=.032+(i%8)*.011;phase=i*.83
 pts=[]
 for j in range(36):
  a=j*math.tau/35+phase;rr=r+.008*math.sin(a*3+i);pts.append((rr*math.cos(a),rr*math.sin(a),.073+(i//8)*.009+.006*math.sin(a*2+i)))
 tube('sesame noodle strand',pts,.0048,noodle,1)
for i in range(22):
 a=random.random()*math.tau;r=random.random()*.10;x,y=r*math.cos(a),r*math.sin(a)
 o=lathe('cut spring onion',[(.006,.0),(.007,.008),(.004,.009),(.003,.0)],lettuce,12);o.location=(x,y,.101)
for i in range(16):
 x,y=random.uniform(-.08,.08),random.uniform(-.07,.07);sphere('sesame sprinkle',(x,y,.10),(.0035,.0018,.0013),sesame,8,4)
for offset in [-.012,.012]:tube('resting chopstick',[(-.15,offset+.08,.091),(.15,offset+.12,.098)],.004,gold,1)
finish('hot-dry-noodles')

# Basil rice: rice grains, coarse mince, basil/chilli and an irregular fried egg.
lathe('rice plate',[(.001,.002),(.11,.002),(.15,.012),(.165,.024),(.163,.03),(.15,.026),(.12,.014),(.001,.014)],cream)
sphere('rice mound',(-.045,.025,.043),(.09,.104,.033),rice)
for i in range(120):
 x=random.uniform(-.125,.025);y=random.uniform(-.07,.115)
 if ((x+.045)/.09)**2+((y-.025)/.104)**2>1:continue
 z=.046+.033*math.sqrt(max(0,1-((x+.045)/.09)**2-((y-.025)/.104)**2))
 o=sphere('rice grain',(x,y,z),(.009,.0035,.003),rice,8,4);o.rotation_euler.z=random.random()*math.tau
sphere('minced basil chicken base',(.046,-.028,.032),(.092,.083,.019),mince)
for i in range(100):
 x=random.uniform(-.045,.13);y=random.uniform(-.12,.095)
 if ((x-.046)/.092)**2+((y+.028)/.083)**2>1:continue
 surface=.032+.019*math.sqrt(max(0,1-((x-.046)/.092)**2-((y+.028)/.083)**2))
 sphere('basil chicken piece',(x,y,surface+.002),(.012,.009,.008),mince if i%3 else gold,8,4)
for i in range(13):
 a=random.random()*math.tau;r=random.uniform(.035,.11);leaf('basil leaf',(r*math.cos(a),r*math.sin(a),.059),.035,.018,green,a)
for i in range(7):
 a=random.random()*math.tau;r=random.uniform(.04,.11);tube('red chilli',[(r*math.cos(a),r*math.sin(a),.065),(r*math.cos(a)+.016,r*math.sin(a)+.008,.067)],.003,red,1)
# radial organic egg mesh, same geometry two offset layers gives browned thin edge.
def egg(name,radius,z,material):
 verts=[(0,0,z)]+[(radius*(1+.10*math.sin(i*1.7))*math.cos(i*math.tau/40),radius*.82*(1+.08*math.sin(i*2.4))*math.sin(i*math.tau/40),z+.002*math.sin(i)) for i in range(40)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[(0,i+1,(i+1)%40+1) for i in range(40)]);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.location=(-.025,.032,0);add(o,name,material);solid=o.modifiers.new('egg thickness','SOLIDIFY');solid.thickness=.003
 return o
egg('crisp egg edge',.069,.078,gold);egg('fried egg white',.064,.081,white);sphere('golden egg yolk',(-.024,.031,.087),(.027,.026,.013),yellow,24,12)
finish('pad-krapao')

# Crispy chicken burger: four separate readable layers and grainy edge.
box('burger paper',(0,0,.002),(.265,.25,.004),paper,.012)
sphere('bottom bun',(0,0,.032),(.105,.10,.029),lightgold,32,16)
cyl('chicken fillet core',(0,0,.068),.105,.036,gold,32)
for i in range(36):
 a=i*math.tau/36;r=.100+random.uniform(-.004,.006);sphere('crisp chicken edge',(r*math.cos(a),r*math.sin(a),.07+random.uniform(-.007,.007)),(.014,.012,.012),lightgold if i%2 else gold,8,6)
verts=[(0,0,.099)]+[(.12*(1+.06*math.sin(i*2.1))*math.cos(i*math.tau/48),.113*(1+.06*math.sin(i*2.1))*math.sin(i*math.tau/48),.099+.009*math.sin(i*1.6)) for i in range(48)]
mesh=bpy.data.meshes.new('ruffled lettuce');mesh.from_pydata(verts,[],[(0,i+1,(i+1)%48+1) for i in range(48)]);mesh.update();o=bpy.data.objects.new('ruffled lettuce',mesh);bpy.context.collection.objects.link(o);add(o,o.name,lettuce);mod=o.modifiers.new('leaf thickness','SOLIDIFY');mod.thickness=.003
sphere('mayonnaise',(0,0,.111),(.098,.094,.010),white,24,10)
sphere('sesame top bun',(0,0,.144),(.107,.103,.039),lightgold,32,16)
for i in range(33):
 a=random.random()*math.tau;r=random.random()*.09;x,y=r*math.cos(a),r*math.sin(a);z=.144+.039*math.sqrt(max(0,1-(r/.107)**2));o=sphere('bun sesame seed',(x,y,z+.001),(.004,.0017,.0012),sesame,8,4);o.rotation_euler.z=random.random()*math.tau
finish('mcspicy-burger')

# Coconut latte: tapered full cup with milk/coffee separation, molded lid and blue mark.
lathe('coconut latte cup',[(.001,.002),(.052,.002),(.055,.012),(.070,.218),(.073,.225),(.068,.23),(.001,.23)],milk)
lathe('coffee top band',[(.065,.164),(.07,.216),(.069,.219),(.065,.168)],coffee)
lathe('molded clear lid',[(.001,.232),(.069,.232),(.076,.228),(.077,.236),(.072,.243),(.001,.243)],clear)
cyl('coffee visible through lid',(0,0,.244),.065,.002,coffee)
for i in range(7):
 a=i*math.tau/7;o=box('ice cube',(.039*math.cos(a),.039*math.sin(a),.248),(.025,.025,.01),milk,.004);o.rotation_euler.z=a
lathe('lid raised lip',[(.069,.236),(.073,.237),(.073,.246),(.069,.247)],clear)
# Front blue brand medallion and stylized antlers are shallow relief on a 3D cup.
o=cyl('blue cup mark',(0,-.063,.112),.028,.0015,blue,32);o.rotation_euler.x=math.pi/2
text('latte label','luckin',(0,-.065,.065),.019,blue)
text('latte label small','COFFEE',(0,-.064,.047),.011,blue)
for sign in [-1,1]:
 tube('white antler',[(sign*.003,-.065,.105),(sign*.014,-.065,.125),(sign*.019,-.065,.139)],.0019,white,1)
 tube('antler twig',[(sign*.012,-.066,.122),(sign*.025,-.066,.125)],.0015,white,1)
sphere('deer head',(0,-.065,.108),(.008,.001,.011),white,12,6)
finish('coconut-latte')

# Save editable components before joining each material batch for Web draw-call economy.
for id,objects in assets.items():
 collection=bpy.data.collections.new(id);bpy.context.scene.collection.children.link(collection)
 for o in objects:
  for old in list(o.users_collection):old.objects.unlink(o)
  collection.objects.link(o)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'blender/food-world-props.blend'))
counts={}
for id,objects in assets.items():
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.convert(target='MESH');converted=list(bpy.context.selected_objects)
 # Joining by material retains geometric shading and keeps six assets under ~50 draw calls.
 groups={}
 for o in converted:groups.setdefault(o.data.materials[0].name,[]).append(o)
 merged=[]
 for material,items in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for o in items:o.select_set(True)
  bpy.context.view_layer.objects.active=items[0];bpy.ops.object.join();merged.append(bpy.context.object)
 bpy.ops.object.select_all(action='DESELECT')
 for o in merged:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(id+'.glb')),export_format='GLB',use_selection=True,export_extras=True)
 counts[id]={'meshes':len(merged),'triangles':sum(len(o.data.loop_triangles) for o in merged)}
 assets[id]=merged
# Surface heights and locations are shared with runtime; no environment rebuild needed.
regions=json.loads((ROOT/'godot/content/food-collection/closeup-regions.json').read_text())
anchors={r['id']:r['anchor'] for r in regions}
placements=[
 {'id':'mcspicy-burger','region':'coffee','offset':[-.19,.002,.25],'yaw':0},
 {'id':'coconut-latte','region':'coffee','offset':[.22,.002,.22],'yaw':.15},
 {'id':'hot-dry-noodles','region':'kitchen','offset':[-.12,.002,-.02],'yaw':0},
 {'id':'pad-krapao','region':'kitchen','offset':[.25,.002,-.02],'yaw':0},
 {'id':'pocky','region':'cabinet','offset':[.18,.002,-.24],'yaw':-math.pi/2},
 {'id':'coconut-rolls','region':'cabinet','offset':[.18,.002,.22],'yaw':-math.pi/2},
]
for item in placements:
 item['position']=[round(anchors[item['region']][i]+item['offset'][i],5) for i in range(3)]
 prefix={'coffee':'Tea table top','kitchen':'kitchen','cabinet':'dining sideboard stone counter'}[item['region']]
 item['support_height']=round(support_height(ROOT,item['position'][0],item['position'][2],1.3,prefix),5)
 item['position'][1]=round(item['support_height']+.001,5)
(OUT/'placement.json').write_text(json.dumps({'props':placements,'assets':counts},ensure_ascii=False,indent=2),encoding='utf8')
# Contact-lit triptych of the actual meshes, at their own scales.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.5,.47,.41,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
scene.view_settings.view_transform='AgX';scene.render.resolution_x=1400;scene.render.resolution_y=900;scene.render.resolution_percentage=100
bpy.ops.object.light_add(type='AREA',location=(-1,-1,2));bpy.context.object.data.energy=100;bpy.context.object.data.size=2
bpy.ops.object.camera_add(location=(.55,-.8,.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.10))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.85;scene.camera=cam
floor_mat=mat('review warm tabletop',(.32,.26,.19),.8);box('review ground',(0,0,-.012),(3,3,.02),floor_mat,.001)
for region,ids in [('cabinet',['pocky','coconut-rolls']),('kitchen',['hot-dry-noodles','pad-krapao']),('coffee',['mcspicy-burger','coconut-latte'])]:
 for id,objects in assets.items():
  for o in objects:o.hide_render=id not in ids
 for i,id in enumerate(ids):
  for o in assets[id]:o.location.x+=(-.19 if i==0 else .19)
 scene.render.filepath=str(PREVIEW/('food-world-'+region+'.png'));bpy.ops.render.render(write_still=True)
 for i,id in enumerate(ids):
  for o in assets[id]:o.location.x-=(-.19 if i==0 else .19)
print('FOOD_WORLD_PROPS_OK',json.dumps(counts))
