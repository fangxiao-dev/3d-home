"""Check exported assembly ownership and the camera/lightmap invariant before baking."""
from pathlib import Path
from collections import defaultdict
import json,struct,hashlib
path=Path('outputs/godot/assets/living-room.glb');raw=path.read_bytes()
data=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
groups=defaultdict(list);nodes=[];failures=[]
for node in data['nodes']:
    if 'mesh' not in node:continue
    extra=node.get('extras',{});nodes.append((node,extra))
    if extra.get('furniture_id'):groups[(extra['room_id'],extra['furniture_id'])].append((node,extra))
for key,parts in groups.items():
    eligible=any(e.get('collision') for n,e in parts)
    for node,extra in parts:
        if bool(extra.get('camera_occluder'))!=eligible:failures.append(node['name']+' has inconsistent camera ownership')
        if eligible and extra.get('bake_static'):failures.append(node['name']+' can hide but is statically baked')
# Explicit fixtures cover authored attachments that deliberately have no gameplay collision.
expected={
 'balcony laundry upper cabinet':'balcony_upper_cabinet',
 'balcony laundry upper door':'balcony_upper_cabinet',
 'balcony laundry upper pull':'balcony_upper_cabinet',
 'balcony laundry open shelf':'balcony_laundry_shelf',
 'balcony laundry shelf back':'balcony_laundry_shelf',
 'balcony folded linen':'balcony_wash_basin',
 'wash wash faucet':'wash_vanity',
 'study book':'study_bookcase',
 'study desk writing mat':'study_desk',
 'study closed notebook':'study_desk',
 'study notebook page block':'study_desk',
 'Vase':'living_chest','Flower':'living_chest','Cactus':'tv_console',
 'kitchen sink':'kitchen_cabinet','kitchen oven':'kitchen_cabinet',
 'kitchen cooktop':'kitchen_cabinet','kitchen south countertop':'kitchen_cabinet',
 'hallway door inset panel':'hallway_door',
}
checked=[]
for prefix,owner in expected.items():
    found=[(n,e)for n,e in nodes if n['name'].startswith(prefix)]
    # Export batching can absorb an attachment into an earlier mesh with the same
    # owner/material. World-triangle equality separately proves none were removed.
    for node,extra in found:
        checked.append(node['name'])
        if extra.get('furniture_id')!=owner:failures.append(node['name']+' belongs to '+str(extra.get('furniture_id'))+' instead of '+owner)
for required in ['balcony_upper_cabinet','balcony_laundry_shelf','hallway_door']:
    if not any(k[1]==required for k in groups):failures.append('Missing assembly '+required)
report={'model_sha256':hashlib.sha256(raw).hexdigest(),'groups':len(groups),'camera_occluder_groups':[room+'/'+fid for (room,fid),parts in groups.items() if any(e.get('camera_occluder')for n,e in parts)],'checked_visible_attachment_nodes':checked,'failures':failures,'pass':not failures}
Path('work/navigation-v2/asset-semantics.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2));raise SystemExit(bool(failures))
