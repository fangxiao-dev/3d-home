"""Semantic batching, floor datum, and per-mesh lightmap UV for Web delivery."""
import bpy,json,sys
from pathlib import Path
from mathutils import Vector


def finish_uv(meshes):
    painted=bpy.data.materials.get('Warm painted cabinetry')
    if not painted:
        painted=bpy.data.materials.new('Warm painted cabinetry');painted.use_nodes=True
        p=painted.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(.81,.79,.71,1);p.inputs['Roughness'].default_value=.52
    bpy.context.view_layer.update()
    for o in meshes:
        name=o.name.lower()
        if any(s in name for s in ('crown','lintel','ceiling','cove strip')):
            o['cutaway']='top';o['bake_static']=False
        if o.get('floor_role'):
            o['bake_static']=True
            top=max((o.matrix_world@Vector(c)).z for c in o.bound_box)
            o.location.z+=(.001 if o['floor_role']=='finish' else 0)-top
        if any(s in name for s in ('cabinet','sideboard','desk','bookcase','vanity','washing machine','basin')):
            for slot in o.material_slots:
                if slot.material and slot.material.name=='Cream sofa fabric':slot.material=painted
    # Joining retains source vertex positions and UV0; independent hinged parts stay independent.
    groups={}
    for o in meshes:
        if o.parent or o.get('movable') or o.get('floor_role'):continue
        key=(o.get('room_id',''),o.get('furniture_id',''),tuple(m.name for m in o.data.materials),bool(o.get('collision')),o.get('cutaway',''),bool(o.get('bake_static')))
        groups.setdefault(key,[]).append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for objects in groups.values():
        if len(objects)<2:continue
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.ops.object.select_all(action='DESELECT')
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    print('V2_BATCHED_MESHES',len(meshes),flush=True)
    for i,o in enumerate(meshes):
        bpy.context.view_layer.objects.active=o;o.select_set(True)
        uv=o.data.uv_layers.get('LightmapUV') or o.data.uv_layers.new(name='LightmapUV')
        if o.get('floor_role')=='finish':
            coords=[v.co for v in o.data.vertices]
            x0,x1=min(p.x for p in coords),max(p.x for p in coords)
            y0,y1=min(p.y for p in coords),max(p.y for p in coords)
            for loop in o.data.loops:
                p=o.data.vertices[loop.vertex_index].co
                uv.data[loop.index].uv=((p.x-x0)/(x1-x0),(p.y-y0)/(y1-y0))
            o.data.uv_layers.active_index=0;o.select_set(False);continue
        if not o.get('bake_static'):
            for source,target in zip(o.data.uv_layers[0].data,uv.data):target.uv=source.uv
            o.data.uv_layers.active_index=0;o.select_set(False);continue
        o.data.uv_layers.active=uv
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=1.15192,island_margin=.015)
        bpy.ops.object.mode_set(mode='OBJECT');o.data.uv_layers.active_index=0;o.select_set(False)
        if i%20==0:print('V2_LOCAL_UV',i,len(meshes),flush=True)
    return meshes


if __name__=='__main__':
    out=Path(__file__).resolve().parent.parent
    bpy.ops.wm.open_mainfile(filepath=str(out/'blender/living-room.blend'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    if '--floor-datum-only' in sys.argv:
        bpy.context.view_layer.update()
        for o in meshes:
            if o.get('floor_role')=='finish':
                top=max((o.matrix_world@Vector(c)).z for c in o.bound_box);o.location.z+=.001-top
    else:meshes=finish_uv(meshes)
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'blender/living-room.blend'))
    bpy.ops.export_scene.gltf(filepath=str(out/'godot/assets/living-room.glb'),export_format='GLB',export_apply=True,export_cameras=False,export_lights=False,export_animations=False,export_extras=True)
    manifest=json.loads((out/'blender/model-manifest.json').read_text(encoding='utf-8'))
    manifest['total_mesh_count']=len(meshes);manifest['mesh_count']=sum(o.get('room_id')=='living' for o in meshes)
    for room,entry in manifest['rooms'].items():entry['mesh_count']=sum(o.get('room_id')==room for o in meshes)
    (out/'blender/model-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('V2_FINAL_UV_EXPORTED',flush=True)

