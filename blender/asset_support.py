"""Read actual horizontal support geometry from the saved environment source."""
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import bpy

def support_height(root:Path, godot_x:float, godot_z:float, ceiling:float, name_prefix:str)->float:
    with bpy.data.libraries.load(str(root/'blender/living-room.blend'),link=False) as (source,target):
        target.objects=[name for name in source.objects if name.lower().startswith(name_prefix.lower())]
    for obj in target.objects:
        if obj:bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    heights=[]
    for obj in target.objects:
        if obj is None or obj.type!='MESH':continue
        tree=BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],[list(p.vertices) for p in obj.data.polygons])
        point,normal,_,_=tree.ray_cast(Vector((godot_x,-godot_z,ceiling)),Vector((0,0,-1)),ceiling)
        if point is not None and normal.z>.9:heights.append(point.z)
    for obj in target.objects:
        if obj:bpy.data.objects.remove(obj,do_unlink=True)
    if not heights:raise RuntimeError(f'No support surface {name_prefix} at {godot_x},{godot_z}')
    return max(heights)
