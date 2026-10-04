"""Export 3D goods models for warehouse, trade post, and granary storage bays.
Run with Blender:
  /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 -P tools/export_goods_models.py
"""
import ast
import json
import os
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
PARENT = ROOT.parent
OUT = ROOT / 'godot/assets/models'
OUT.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(PARENT / 'art/_kit'))
sys.path.insert(0, str(ROOT / 'tools'))
from optimize_godot_models import batch_materials

# 1. Storage Goods (Warehouse & Trade Post)
STORAGE_SOURCE = PARENT / 'art/storage_goods/build_sprites.py'
tree = ast.parse(STORAGE_SOURCE.read_text())
stop_idx = next(i for i, n in enumerate(tree.body) if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'ov' for t in n.targets))
tree.body = tree.body[:stop_idx]
ns_storage = {'__file__': str(STORAGE_SOURCE), '__name__': '__main__'}
sys.path.insert(0, str(STORAGE_SOURCE.parent))
exec(compile(tree, str(STORAGE_SOURCE), 'exec'), ns_storage)

K_storage = ns_storage['K']
pile_fn = ns_storage['pile']
spots = ns_storage['SPOTS']
goods_list = ns_storage['GOODS']

print(f"Loaded storage goods source: {len(goods_list)} goods")

for good in goods_list:
    out_path = OUT / f'good_{good}.glb'
    if out_path.exists() and not '--force' in sys.argv:
        print(f"Skipping good_{good}, already exists")
        continue

    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    sys.modules['ezkit'].root = None
    root_empty = K_storage.empty('Root')
    sys.modules['ezkit'].root = root_empty

    if good == 'sculpture':
        piles = pile_fn(good, (0, 0), 0)
    else:
        piles = [pile_fn(good, c, i) for i, c in enumerate(spots)]

    bpy.context.view_layer.update()
    mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
    if not mesh_objs:
        print(f"Warning: No mesh objects for {good}")
        continue

    exported = batch_materials(mesh_objs)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in exported:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = exported[0]

    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format='GLB',
        use_selection=True,
        export_yup=True
    )

    coordinates = [v.co[:] for ob in exported for v in ob.data.vertices]
    report = {
        'asset': f'good_{good}',
        'file': out_path.name,
        'bytes': out_path.stat().st_size,
        'vertices': sum(len(ob.data.vertices) for ob in exported),
        'surfaces': len(exported),
        'bounds_blender': [np.min(coordinates, axis=0).tolist(), np.max(coordinates, axis=0).tolist()],
        'draw_batching': 'vertex_palette_compatible_PBR',
        'rights_status': 'needs_evidence'
    }
    (OUT / f'good_{good}.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"Exported good_{good}: {report['vertices']} vertices, {report['bytes']} bytes")

# 2. Granary Food Bins
GRANARY_SOURCE = PARENT / 'art/granary/build_sprites.py'
tree_g = ast.parse(GRANARY_SOURCE.read_text())
stop_idx_g = next(i for i, n in enumerate(tree_g.body) if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'ov' for t in n.targets))
tree_g.body = tree_g.body[:stop_idx_g]
ns_granary = {'__file__': str(GRANARY_SOURCE), '__name__': '__main__'}
sys.path.insert(0, str(GRANARY_SOURCE.parent))
exec(compile(tree_g, str(GRANARY_SOURCE), 'exec'), ns_granary)

K_granary = ns_granary['K']
goods_fn = ns_granary['goods']
foods_list = ns_granary['FOODS']
GX = ns_granary['GX']
GY = ns_granary['GY']
DRUM_TOP = ns_granary['DRUM_TOP']

print(f"Loaded granary food source: {len(foods_list)} foods")

for food in foods_list:
    out_path = OUT / f'granary_food_{food}.glb'
    if out_path.exists() and not '--force' in sys.argv:
        print(f"Skipping granary_food_{food}, already exists")
        continue

    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    sys.modules['ezkit'].root = None
    root_empty = K_granary.empty('Root')
    sys.modules['ezkit'].root = root_empty

    g = goods_fn(food, 0)
    bpy.context.view_layer.update()
    mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
    if not mesh_objs:
        print(f"Warning: No mesh objects for granary food {food}")
        continue

    # Shift objects so origin (0,0,0) is at (GX, GY, DRUM_TOP) of the drum,
    # so the wedge sits exactly on the bin floor at drum center.
    for ob in mesh_objs:
        world_mat = ob.matrix_world.copy()
        ob.parent = None
        ob.matrix_world = Matrix.Translation((-GX, -GY, -DRUM_TOP)) @ world_mat

    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action='DESELECT')
    for ob in mesh_objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objs[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    exported = batch_materials(mesh_objs)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in exported:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = exported[0]

    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format='GLB',
        use_selection=True,
        export_yup=True
    )

    coordinates = [v.co[:] for ob in exported for v in ob.data.vertices]
    report = {
        'asset': f'granary_food_{food}',
        'file': out_path.name,
        'bytes': out_path.stat().st_size,
        'vertices': sum(len(ob.data.vertices) for ob in exported),
        'surfaces': len(exported),
        'bounds_blender': [np.min(coordinates, axis=0).tolist(), np.max(coordinates, axis=0).tolist()],
        'draw_batching': 'vertex_palette_compatible_PBR',
        'rights_status': 'needs_evidence'
    }
    (OUT / f'granary_food_{food}.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"Exported granary_food_{food}: {report['vertices']} vertices, {report['bytes']} bytes")

print("All goods exported successfully!")
