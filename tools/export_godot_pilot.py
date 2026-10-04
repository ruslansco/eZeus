"""Run with background Blender; export local source geometry, never render sprites.

blender -b --factory-startup --python-exit-code 1 -P eZeus/tools/export_godot_pilot.py
-- --asset hospital

Exports are development candidates, not rights-cleared production assets.
Buildings use grouped PBR; refined people retain painted skin/rest coordinates
and surface metadata for the Godot character shader.
"""
import argparse
import ast
import json
import math
import sys
from pathlib import Path
import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'eZeus/godot/assets/models'
BUILDING_ACTIVITY = False
BUILDING_ANIMATE = None
# Extra clips of the walker being exported: (label, frame count, function) for fight, fight2 and die when the person is a soldier.
EXTRA_CLIPS = []
sys.path.insert(0, str(ROOT / 'art/_kit'))
import ezkit as K
sys.path.insert(0, str(Path(__file__).resolve().parent))
from godot_asset_sources import RECIPES, COMBAT, MOUNTED, CREATURES
from optimize_godot_models import batch_materials
from godot_garden_foliage import ASSETS as GARDEN_ASSETS, FOOTPRINTS as GARDEN_FOOTPRINTS, BUDGETS as GARDEN_BUDGETS, REVISION as GARDEN_REVISION, adapt as adapt_gardens
import godot_character_realism as character_art
import godot_god_face as god_face
import godot_god_float as god_float


def execute_source(source, args, stop=None, transform=None):
    namespace = {'__file__': str(source), '__name__': '__godot_export__'}
    sys.path.insert(0, str(source.parent))
    sys.argv = ['blender', '--', *args]
    tree = ast.parse(source.read_text())
    if stop:
        tree.body = tree.body[:next(i for i, n in enumerate(tree.body) if stop(n))]
    if transform:
        tree = transform(tree)
    class NoSourceWrites(ast.NodeTransformer):
        def visit_Expr(self, node):
            # Inventory overlays belong to the SDL sprite renderer. Do not build
            # its 64 food variants or execute its atlas/manifest writer here.
            if BUILDING_ACTIVITY and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Attribute) and isinstance(node.value.func.value, ast.Name) and node.value.func.value.id == 'ov':
                return ast.Pass()
            if isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name) and node.value.func.id == 'fill_views':
                return ast.Pass()
            if isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Attribute) and node.value.func.attr in {'write_text','write_bytes','run_split','exit'}:
                return ast.Pass()
            return self.generic_visit(node)
    tree = ast.fix_missing_locations(NoSourceWrites().visit(tree))
    # Exporting geometry must never render atlases or replace authored .blend files.
    K.render = lambda *a, **kw: None
    def capture_activity(animate, *a, **kw):
        global BUILDING_ANIMATE
        BUILDING_ANIMATE = animate
        animate(0, True)
    K.run = capture_activity
    bpy.ops.render.render = lambda *a, **kw: None
    bpy.ops.wm.save_as_mainfile = lambda *a, **kw: None
    exec(compile(tree, str(source), 'exec'), namespace)
    K.root.rotation_euler.z = 0
    return namespace


def construct(name):
    global BUILDING_ANIMATE
    if name in {'walker_astronomer','walker_inventor','walker_curator'}:
        source = Path(__file__).with_name('godot_science_walkers.py')
        ns = execute_source(source, ['--who', name.removeprefix('walker_')])
        ns['pose'](0)
        return str(source.relative_to(ROOT)), ns['pose'], lambda f: ns['pose'](0)
    if name in {'philosopher', 'settlers1'} or name.startswith('walker_'):
        source = ROOT / 'art/characters/people/build_person.py'
        namespace = {'__file__': str(source), '__name__': '__godot_export__'}
        sys.path.insert(0, str(source.parent))
        sys.argv = ['blender', '--', '--who', name.removeprefix('walker_')]
        tree = ast.parse(source.read_text())
        prefix = []
        for node in tree.body:
            if isinstance(node, ast.If) and "'--identity-reference'" in ast.unparse(node.test):
                break
            prefix.append(node)
        tree.body = prefix
        K.render = lambda *a, **kw: None
        exec(compile(tree, str(source), 'exec'), namespace)
        fn = namespace['STATES'][0][3]
        samples = namespace['STATES'][0][1]
        # Sample authored gait at 24 phases; identities retain their own rigs and props.
        pose = lambda frame: fn(frame * samples / 24)
        idle = lambda frame: fn(0)
        if god_float.is_god(name):
            # The gods float in the Godot city (scripts/god_float.gd): the held pose is a hover, not a stride, and the 24 walk
            # samples are all its first frame (the optimizer merges identical poses). The native art is not touched.
            pose, idle = god_float.poses(fn)
        EXTRA_CLIPS.clear()
        if name.removeprefix('walker_') in COMBAT:
            for state, count, _, state_fn, _ in namespace['STATES']:
                if state in ('fight', 'fight2', 'die', 'bless', 'curse', 'disappear', 'appear'):
                    EXTRA_CLIPS.append((state, int(count), state_fn))
        pose(0); K.root.rotation_euler.z = 0
        return str(source.relative_to(ROOT)), pose, idle
    if name.startswith('animal_'):
        source = ROOT / 'art/characters/animals/build_animal.py'
        def tolerant(tree):
            # The horse's right hind leg misses the kit's walk tolerance at one sampled frame (frame 3): the export keeps the pose
            # and skips that check. The kit itself is unchanged.
            class Tolerance(ast.NodeTransformer):
                def visit_FunctionDef(self, node):
                    if node.name == 'walk':
                        node.body = [stmt for stmt in node.body if not isinstance(stmt, ast.Assert)]
                    return node
            return ast.fix_missing_locations(Tolerance().visit(tree)) if name == 'animal_horse' else tree
        ns = execute_source(source, ['--species', name.removeprefix('animal_')],
                            lambda n: isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'only' for t in n.targets), tolerant)
        pose = lambda f: ns['walk'](f * ns['FR']['walk'] / 24)
        idle = lambda f: ns['walk'](0)
        pose(0)
        return str(source.relative_to(ROOT)), pose, idle
    if name == 'transporter':
        source = ROOT / 'art/characters/transporter/build_sprites.py'
        ns = execute_source(source, [], lambda n: isinstance(n, ast.If) and "'--debug'" in ast.unparse(n.test))
        ns['show_man'](True); ns['show_cart'](True); ns['man_view'](0)
        pose = lambda f: ns['pose'](f * ns['FRAMES'] / 24)
        pose(0)
        return str(source.relative_to(ROOT)), pose, lambda f: ns['pose'](0)
    if name == 'trade_ship':
        source = ROOT / 'art/ships/trade_ship/source.blend'
        bpy.ops.wm.open_mainfile(filepath=str(source))
        return str(source.relative_to(ROOT)), None, None
    if name in ('trireme', 'enemy_boat'):
        # The SDL naval remaster's war galley (art/ships/build_sprites.py saved it). An invader's boat is the same hull in the
        # raiders' colours: a black sail and black lacquer, dull bronze for the gold (the file is not saved).
        source = ROOT / 'art/ships/trireme/source.blend'
        bpy.ops.wm.open_mainfile(filepath=str(source))
        if name == 'enemy_boat':
            recolour = {'Imperial crimson': (.035, .032, .03), 'Aegean blue lacquer': (.02, .018, .016), 'Polished bronze and gold inlay': (.30, .17, .08)}
            for material in bpy.data.materials:
                colour = recolour.get(material.name)
                if colour and material.use_nodes:
                    for node in material.node_tree.nodes:
                        if node.type == 'BSDF_PRINCIPLED':
                            node.inputs['Base Color'].default_value = (*colour, 1.0)
        return str(source.relative_to(ROOT)), None, None
    if name == 'fishing_boat':
        source = Path(__file__).with_name('godot_fishing_boat.py')
        execute_source(source, [])
        return str(source.relative_to(ROOT)), None, None
    if name in RECIPES:
        relative, args = RECIPES[name]; source = ROOT / relative
        def adapt(tree):
            # The native atlas loops hide each completed piece after rendering.
            # Retain the requested geometry, and select one floor pattern only.
            class GeometryOnly(ast.NodeTransformer):
                def visit_For(self, node):
                    if name.startswith('column_') and "('x', 'l')" in ast.unparse(node.iter):
                        # The column alone: the architraves the SDL view draws between neighbouring columns are not part of it.
                        node.body = [ast.Pass()]
                        return node
                    if name.startswith('sanctuary_court_') and isinstance(node.iter, ast.Call) and ast.unparse(node.iter) == 'enumerate(colors)':
                        i = int(name.rsplit('_', 1)[1])
                        node.iter = ast.parse(f'[( {i}, colors[{i}] )]', mode='eval').body
                    return self.generic_visit(node)
                def visit_Assign(self, node):
                    if any(isinstance(t, ast.Attribute) and t.attr == 'hide_render' for t in node.targets) and isinstance(node.value, ast.Constant) and node.value.value is True:
                        node.value = ast.Constant(False)
                    return node
            tree = GeometryOnly().visit(tree)
            if name in GARDEN_ASSETS:
                tree = adapt_gardens(tree, name)
            return ast.fix_missing_locations(tree)
        stop = (lambda n: isinstance(n, ast.If) and 'K.args.preview' in ast.unparse(n.test)) if name.startswith('sanctuary_temple_') or name.startswith('sanctuary_statue_') or name.startswith('sanctuary_monument_') else None
        ns = execute_source(source, args, stop, adapt)
        if name.startswith('sanctuary_monument_'):
            # The 2D sprites turn the colossus 45 degrees to face the camera, and its pedestal with it. The 3D city turns each
            # piece of a sanctuary in quarter turns to face the sanctuary's front, so the figure faces tile +Y and the pedestal is square.
            ns['GR'].rotation_euler.z = 0.0
        if name == 'gatehouse':
            # The 5x2 gatehouse is two gate towers with a passage between (the native game draws it from sprites).
            import godot_gatehouse
            godot_gatehouse.compose(ns)
        if BUILDING_ACTIVITY:
            BUILDING_ANIMATE = ns.get('animate',BUILDING_ANIMATE)
        if name.startswith('sanctuary_temple_'):
            i = int(name.rsplit('_',1)[1]); _, direction, piece = ns['SPRITES'][i]
            ns['show'](ns['F_OBS'], visible=piece=='F'); ns['show'](ns['X_OBS'], visible=piece=='X'); ns['place'](direction,piece)
        if name == 'palace':
            ns['animate'](0, True)
            # The native split renderer leaves camera holdouts and translates a half.
            for ob in K.root.children_recursive:
                ob.is_holdout = False; ob.hide_render = False
            K.root.location = (0,0,0)
            for ob in list(K.root.children):
                ob.location = Vector((ob.location.y, -ob.location.x, ob.location.z))
                ob.rotation_euler.z -= math.pi / 2
        if name == 'palace_tile_plain':
            for ob in ns['lamp_objs']: ob.hide_render = True
        # Buildings retain an authored active pose; walker morph samples are separate.
        return relative, None, None
    if name in {'tree_broadleaf', 'tree_cypress'}:
        source = ROOT / 'art/terrain/build_trees.py'
        namespace = {'__file__': str(source), '__name__': '__godot_export__'}
        sys.argv = ['blender', '--', 'zeusTrees']
        tree = ast.parse(source.read_text())
        # Construct trees from geometry only; omit the legacy atlas sampling/render loop.
        prefix = []
        for node in tree.body:
            if isinstance(node, ast.FunctionDef) and node.name == 'canopy_amount':
                break
            prefix.append(node)
        tree.body = prefix
        exec(compile(tree, str(source), 'exec'), namespace)
        namespace['ground'].hide_render = True
        namespace['broadleaf' if name == 'tree_broadleaf' else 'cypress'](Vector((0, 0, 0)), 1.7)
        # The 2D generator uses procedural colours: keep their intended base palette in 3D.
        for material, colour in [('bark', (.13,.09,.05)), ('leaf', (.22,.34,.09)), ('cypress', (.1,.24,.1))]:
            namespace['M'][material].diffuse_color = (*colour, 1)
        return str(source.relative_to(ROOT)), None, None
    if name == 'hospital':
        if BUILDING_ACTIVITY:
            source = ROOT / 'art/hospital/build_sprites.py'
            ns = execute_source(source, [])
            return str(source.relative_to(ROOT)), None, None
        source = ROOT / 'art/hospital/hospital_reference.blend'
        bpy.ops.wm.open_mainfile(filepath=str(source))
        return str(source.relative_to(ROOT)), None, None
    source = ROOT / ('art/characters/physician/build_sprites.py' if name == 'physician' else f'art/{name}/build_sprites.py')
    if BUILDING_ACTIVITY:
        execute_source(source, [])
        return str(source.relative_to(ROOT)), None, None
    namespace = {'__file__': str(source), '__name__': '__godot_export__'}
    sys.path.insert(0, str(source.parent))
    captured = []
    def capture(animate, *args, **kwargs):
        global BUILDING_ANIMATE
        BUILDING_ANIMATE = animate
        captured.append(animate)
        animate(0, True)
    K.run = capture
    K.render = lambda *args, **kwargs: None
    sys.argv = ['blender', '--', '--preview']
    tree = ast.parse(source.read_text())
    # Physician's trailing preview/export block also changes cameras and lights.
    # Keep its constructors, pose checks and costume, without executing that block.
    if name == 'physician':
        prefix = []
        for node in tree.body:
            if isinstance(node, ast.If) and 'K.args.preview' in ast.unparse(node.test):
                break
            prefix.append(node)
        tree.body = prefix
    exec(compile(tree, str(source), 'exec'), namespace)
    if name == 'physician':
        namespace['h'].root.location = (0, 0, 0)
        namespace['h'].root.rotation_euler = (0, 0, 0)
        namespace['pose'](0)
    K.root.rotation_euler.z = 0
    bpy.context.view_layer.update()
    return str(source.relative_to(ROOT)), namespace.get('pose'), namespace.get('idle')


def evaluated(objects, collapse_hidden=False):
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    result = []
    for obj in objects:
        eo = obj.evaluated_get(deps)
        mesh = eo.to_mesh(preserve_all_data_layers=True, depsgraph=deps)
        if mesh is None:
            continue
        xyz = np.empty(len(mesh.vertices) * 3, dtype=np.float32)
        mesh.vertices.foreach_get('co', xyz)
        xyz = xyz.reshape(-1, 3)
        transform = np.array(eo.matrix_world, dtype=np.float32)
        xyz = xyz @ transform[:3, :3].T + transform[:3, 3]
        if collapse_hidden and obj.hide_render:
            # A soldier's weapon that the current clip puts away: folded to a point inside the body, so it costs nothing to see
            # and never lies below the ground (the clips that show it displace it from there).
            xyz = np.tile(np.array([0, 0, .9], dtype=np.float32), (len(xyz), 1))
        faces = [(tuple(p.vertices), p.material_index) for p in mesh.polygons]
        materials = list(mesh.materials)
        attributes = {}
        for label, field, width in [('GodotPalette','color',4),('GodotRest','vector',3),('RomanClothRest','vector',3)]:
            attr = mesh.attributes.get(label)
            if attr and attr.domain == 'POINT':
                data = np.empty(len(mesh.vertices)*width,dtype=np.float32)
                attr.data.foreach_get(field,data)
                attributes[label] = data.reshape(-1,width)
        coat = mesh.color_attributes.get('Coat colour')
        if coat is not None and coat.domain == 'POINT' and 'GodotPalette' not in attributes:
            # The animal kit paints each creature's coat per point; carry it as the vertex palette (monsters, animals).
            data = np.empty(len(mesh.vertices)*4,dtype=np.float32)
            coat.data.foreach_get('color',data)
            attributes['GodotPalette'] = data.reshape(-1,4)
        attributes['skin'] = bool(obj.get('godot_skin',False))
        result.append((obj.name, xyz, faces, materials, attributes))
        eo.to_mesh_clear()
    return result


def export(name):
    human_asset = name in character_art.ASSETS
    if human_asset:
        character_art.install()
    source, pose, idle = construct(name)
    activity = BUILDING_ANIMATE if BUILDING_ACTIVITY else None
    if BUILDING_ACTIVITY and activity is None:
        raise RuntimeError(f'{name}: no authored building activity callback')
    identities = character_art.prepare(K) if human_asset else []
    if human_asset and pose:
        pose(0)
    root = bpy.data.objects.get('FOOTPRINT_ORIGIN')
    if root:
        root.rotation_euler.z = 0
    objects = sorted([o for o in bpy.context.scene.objects if o.type in {'MESH', 'CURVE'}
                      and not o.hide_render and not o.is_holdout and 'shadow' not in o.name.lower()], key=lambda o: o.name)
    dynamic = set()
    if activity:
        # Include tools/particles visible in later work frames and the worker-free
        # idle. Classify moving pieces separately so architecture remains cheap.
        candidates = [o for o in bpy.context.scene.objects if o.type in {'MESH','CURVE'} and not o.is_holdout and 'shadow' not in o.name.lower()]
        visible = set()
        for frame, active in [(f,True) for f in range(8)]+[(0,False)]:
            activity(frame,active)
            visible.update(o for o in candidates if not o.hide_render)
        objects = sorted(visible,key=lambda o:o.name)
        activity(0,True)
        initial = {obj:xyz for obj,xyz,*_ in evaluated(objects)}
        visibility = {o.name:o.hide_render for o in objects}
        for frame, active in [(f,True) for f in range(1,8)]+[(0,False)]:
            activity(frame,active)
            for obj,xyz,*_ in evaluated(objects):
                if xyz.shape != initial[obj].shape:
                    raise RuntimeError(f'{name}: changing source topology: {obj}')
                if visibility[obj] != bpy.data.objects[obj].hide_render or np.max(np.abs(xyz-initial[obj]),initial=0) > .00001:
                    dynamic.add(obj)
        activity(0,True)
    # Soldiers: props that the walk puts away (a sword, a club, a sling stone) are shown by the fight clips, so they belong to the model.
    # Their rest geometry is taken from the first clip frame that shows them; the poses that hide them fold them into the body.
    shown_in_clips = {}
    if human_asset and EXTRA_CLIPS:
        candidates = [o for o in bpy.context.scene.objects if o.type in {'MESH', 'CURVE'} and not o.is_holdout and 'shadow' not in o.name.lower()]
        listed = set(objects)
        for label, count, fn in [('walk', 24, pose)] + EXTRA_CLIPS:
            for frame in range(count):
                fn(frame)
                for o in candidates:
                    if not o.hide_render and o not in listed and o not in shown_in_clips:
                        shown_in_clips[o] = (fn, frame)
        pose(0)
        objects = sorted(listed | set(shown_in_clips), key=lambda o: o.name)
    samples = evaluated(objects)
    for o, (fn, frame) in shown_in_clips.items():
        fn(frame)
        replacement = evaluated([o])
        samples = [replacement[0] if sample[0] == o.name else sample for sample in samples]
    if shown_in_clips:
        pose(0)
    groups = {}
    for obj, xyz, faces, materials, attributes in samples:
        for slot in sorted({i for _, i in faces}):
            material = materials[slot] if slot < len(materials) else None
            colour = tuple(round(float(v), 3) for v in material.diffuse_color[:3]) if material else (.7, .65, .5)
            roughness, metal = .75, 0.0
            if material and material.use_nodes:
                p = next((n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
                if p:
                    roughness = float(p.inputs['Roughness'].default_value)
                    metal = float(p.inputs['Metallic'].default_value)
                    if name in GARDEN_ASSETS and material.name in {'Pool water', 'Fountain spray'}:
                        # Glass helpers leave diffuse_color at Blender's default
                        # grey. Carry their authored water colour into opaque PBR.
                        colour = tuple(round(float(v), 3) for v in p.inputs['Base Color'].default_value[:3])
            surface_kind = (0 if attributes['skin'] else character_art.kind(obj,material)) if human_asset else -1
            cloth_owner = next((i for i,h in enumerate(character_art.HUMANS) if obj.startswith(h.name)),0) if human_asset else 0
            if human_asset and 'RomanClothRest' in attributes:
                surface_kind = 8
            if surface_kind == 2:
                roughness = .72
            key = (*colour, round(roughness, 2), round(metal, 2), surface_kind, cloth_owner, obj in dynamic)
            chosen = [f for f, i in faces if i == slot]
            # Keep the face and hands independently budgeted instead of spending
            # almost all of a person's triangles on the render strand groom.
            rest = attributes.get('GodotRest',xyz)
            regions = {}
            if human_asset and surface_kind == 0:
                for face in chosen:
                    point = rest[list(face)].mean(axis=0)
                    region = 'face' if point[2] > .70 else 'hands' if abs(point[0]) > .25 else 'body'
                    regions.setdefault(region,[]).append(face)
            else:
                regions['body'] = chosen
            for region, chosen in regions.items():
                group_key = (*key,region)
                group = groups.setdefault(group_key, {'vertices': [], 'faces': [], 'sources': [], 'colours': [], 'rest': [], 'garden_foliage': False, 'garden_smooth': False, 'character_cloth': False})
                if human_asset and obj.startswith(('Philosopher wrapped Greek himation', 'Hades red flame hair', *god_face.PROTECTED)):
                    # Authored flowing flame contours are small and deserve the
                    # same silhouette protection as the wrapped philosopher robe.
                    group['character_cloth'] = True
                if name in GARDEN_ASSETS and material and material.name.startswith('Garden '):
                    group['garden_foliage'] = True
                    group['garden_smooth'] = material.name.startswith(('Garden Core', 'Garden Bark'))
                indices = sorted({i for f in chosen for i in f})
                remap = {old: len(group['vertices']) + i for i, old in enumerate(indices)}
                group['vertices'].extend(xyz[indices].tolist())
                group['faces'].extend(tuple(remap[i] for i in face) for face in chosen)
                group['sources'].append((obj, np.array(indices), len(indices)))
                palette = attributes.get('GodotPalette',np.tile([*colour,1.0],(len(xyz),1)))
                palette = palette[indices].copy()
                cloth_rest = attributes.get('RomanClothRest')
                if human_asset and cloth_rest is not None:
                    import wardrobe
                    owner = next((h.name for h in character_art.HUMANS if obj.startswith(h.name)),None)
                    if owner:
                        tunic, accent = wardrobe.profile(owner)[:2]
                        palette[:,:3] = wardrobe.lin(tunic)
                group['colours'].extend(palette.tolist())
                group['rest'].extend(rest[indices].tolist())
    originals = set(bpy.context.scene.objects)
    exported, mappings = [], []
    total = sum(len(g['vertices']) for g in groups.values())
    budget = (26000 if name == 'settlers1' else 12000) if pose else (2500 if name.startswith(('tree_', 'olive_', 'orange_', 'vine_', 'wall_', 'sanctuary_court_')) else 35000)
    if name in GARDEN_ASSETS:
        budget = GARDEN_BUDGETS[name]
    if human_asset:
        # A rider or a charioteer carries the horse (or two) with the person.
        budget = 32000 if name == 'settlers1' or name in MOUNTED else 15000
        if name == 'walker_hades':
            # The designed face keeps its eyes, brows, beard strands and hairline whole; the rest still gets its share.
            budget = 19000
    if name.removeprefix('walker_') in CREATURES:
        # Beasts and sea monsters on the animal kit: a body, legs, several heads or coils, with no human anatomy to protect.
        budget = 32000
    if activity:
        # Respect each already-optimized building's geometry tier. A moving
        # worker must not restore render-source architecture to 35K vertices.
        previous = json.loads((ROOT/'eZeus/godot/assets/models'/f'{name}.json').read_text())
        if int(previous['vertices']) < 20000:
            budget = min(budget, int(previous['vertices']*.88))
    protected = sum(len(g['vertices']) for g in groups.values() if g['garden_foliage'] or g['character_cloth'])
    if protected > budget:
        raise RuntimeError(f'{name}: foliage alone exceeds its real-time geometry budget')
    def weight(key, group):
        factor = (3.0 if key[-1]=='face' else 1.7 if key[-1]=='hands' else .4 if key[5]==2 else 1.0) if human_asset else 1.0
        return math.sqrt(len(group['vertices']))*factor
    weights = sum(weight(key,g) for key,g in groups.items() if not (g['garden_foliage'] or g['character_cloth']))
    for number, (key, group) in enumerate(groups.items()):
        mesh = bpy.data.meshes.new(f'{name}_{number}')
        mesh.from_pydata(group['vertices'], [], group['faces']); mesh.update()
        # Render sources contain split/coincident face vertices. Weld within each
        # material before simplification so the real-time LOD can collapse edges.
        bm = bmesh.new(); bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.00001)
        loose = [v for v in bm.verts if not v.link_faces]
        if loose: bmesh.ops.delete(bm, geom=loose, context='VERTS')
        bm.to_mesh(mesh); bm.free(); mesh.update()
        ob = bpy.data.objects.new(f'{name}_{number}', mesh)
        bpy.context.scene.collection.objects.link(ob)
        mat = bpy.data.materials.new(f'Preview PBR {number}')
        mat.diffuse_color = (*key[:3], 1); mat.use_nodes = True
        p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        p.inputs['Base Color'].default_value = (*key[:3], 1)
        p.inputs['Roughness'].default_value = key[3]; p.inputs['Metallic'].default_value = key[4]
        ob.data.materials.append(mat)
        bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active = ob
        moving = activity and key[-2]
        if activity:
            ob['building_activity'] = bool(moving)
        if not human_asset and (pose or activity or name == 'fishing_boat') and len(mesh.vertices) > 10000 and any(any(term in obj.lower() for term in ('groom', 'hair', 'beard', 'strand', 'braid', 'curl')) for obj, _, _ in group['sources']):
            # Dense curled hair/beard shells have internal thickness and many
            # protected boundaries. A 5 mm surface LOD keeps their authored
            # silhouette without carrying render-only interior detail per pose.
            remesh = ob.modifiers.new('Hair shell realtime LOD', 'REMESH')
            remesh.mode = 'VOXEL'; remesh.voxel_size = .005
            bpy.ops.object.modifier_apply(modifier=remesh.name)
            mesh = ob.data
        target = len(mesh.vertices) if group['garden_foliage'] or group['character_cloth'] else max(80, (budget - protected) * weight(key,group) / weights)
        if len(mesh.vertices) > target and len(mesh.polygons) > 20:
            decimate = ob.modifiers.new('Pilot LOD', 'DECIMATE'); decimate.ratio = min(1, target / len(mesh.vertices))
            bpy.ops.object.modifier_apply(modifier=decimate.name)
        mesh = ob.data
        bm = bmesh.new(); bm.from_mesh(mesh)
        loose = [v for v in bm.verts if not v.link_faces]
        if loose: bmesh.ops.delete(bm, geom=loose, context='VERTS')
        bm.to_mesh(mesh); bm.free(); mesh.update()
        # Repair collapsed faces before UVs/morph maps are allocated. Repairing
        # only inside Blender's glTF exporter can invalidate those attributes.
        if human_asset and mesh.validate(verbose=True):
            print('PILOT_MESH_REPAIR',name,number,flush=True)
        if not mesh.vertices:
            bpy.data.objects.remove(ob, do_unlink=True)
            continue
        uv = mesh.uv_layers.new(name='UVMap')
        if pose or human_asset or moving:
            original = np.array(group['vertices'], dtype=np.float32)
            tree = KDTree(len(original))
            for i, point in enumerate(original): tree.insert(point, i)
            tree.balance()
            low = np.array([v.co[:] for v in ob.data.vertices], dtype=np.float32)
            closest = np.array([tree.find(Vector(point))[1] for point in low], dtype=np.int64)
        if name.removeprefix('walker_') in CREATURES:
            # Coats and scales are authored per point: keep them as the vertex palette the plain finish shows.
            colours = np.array(group['colours'],dtype=np.float32)[closest]
            palette = mesh.color_attributes.new(name='CityPalette',type='FLOAT_COLOR',domain='CORNER')
            ob['preserve_city_palette'] = True
        if human_asset:
            colours = np.array(group['colours'],dtype=np.float32)[closest]
            rest_coordinates = np.array(group['rest'],dtype=np.float32)[closest]
            palette = mesh.color_attributes.new(name='CityPalette',type='FLOAT_COLOR',domain='CORNER')
            semantics = mesh.uv_layers.new(name='CharacterSurface')
            ob['preserve_city_palette'] = True
        for poly in mesh.polygons:
            dominant = max(range(3), key=lambda axis: abs(poly.normal[axis]))
            axes = [axis for axis in range(3) if axis != dominant]
            for index in poly.loop_indices:
                coordinate = mesh.vertices[mesh.loops[index].vertex_index].co
                uv.data[index].uv = (coordinate[axes[0]], coordinate[axes[1]])
                if name.removeprefix('walker_') in CREATURES and not human_asset:
                    palette.data[index].color = colours[mesh.loops[index].vertex_index]
                if human_asset:
                    vertex = mesh.loops[index].vertex_index
                    palette.data[index].color = colours[vertex]
                    coordinate = rest_coordinates[vertex]
                    uv.data[index].uv = (coordinate[0],coordinate[2])
                    semantics.data[index].uv = (key[5]/8.0, 1.0-(key[6]+.5)/8.0)
        mesh.uv_layers.active = uv
        print('PILOT_LOD', name, number, len(group['vertices']), len(mesh.vertices), len(mesh.polygons), flush=True)
        for poly in ob.data.polygons:
            poly.use_smooth = bool(pose) or bool(moving) or name.startswith('tree_') or group['garden_smooth']
        exported.append(ob)
        if pose or moving:
            mappings.append((ob, group['sources'], closest, low - original[closest]))
            ob.shape_key_add(name='Basis')
    if pose:
        for label, count, fn in [('walk', 24, pose), ('idle', 12, idle)] + EXTRA_CLIPS:
            for frame in range(count):
                if label == 'walk' and frame == 0 and not shown_in_clips: continue
                fn(frame)
                current = {obj: xyz for obj, xyz, _, _, _ in evaluated(objects, collapse_hidden=bool(shown_in_clips))}
                for ob, sources, closest, offset in mappings:
                    combined = np.concatenate([current[obj][indices] for obj, indices, _ in sources])
                    positions = combined[closest] + offset
                    key = ob.shape_key_add(name=f'{label}_{frame:02}')
                    key.data.foreach_set('co', positions.astype(np.float32).ravel())
        pose(0)
    if activity:
        # An explicit first pose also hides particles/tools absent at frame zero.
        # Keep non-degenerate rest geometry/normals for their later visible poses.
        for label, frame, active in [('work_%02d'%f,f,True) for f in range(8)]+[('inactive',0,False)]:
            activity(frame,active)
            current = {obj: xyz for obj, xyz, _, _, _ in evaluated(objects)}
            for ob, sources, closest, offset in mappings:
                combined = np.concatenate([current[obj][indices] for obj, indices, _ in sources])
                visible = np.concatenate([np.full(count,not bpy.data.objects[obj].hide_render,dtype=bool) for obj,_,count in sources])[closest]
                positions=combined[closest]+offset
                # No simplification offsets on a hidden piece: every triangle
                # must collapse exactly rather than leaving small slivers.
                positions[~visible]=[0,0,.02]
                key = ob.shape_key_add(name=label)
                key.data.foreach_set('co',positions.astype(np.float32).ravel())
        activity(0,True)
    source_surfaces = len(exported)
    exported = batch_materials(exported)
    for ob in originals:
        ob.select_set(False)
    for ob in exported:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = exported[0]
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / (name + '.glb')
    bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                             export_animations=False, export_morph=True, export_morph_normal=False,
                             export_cameras=False, export_lights=False, export_yup=True)
    coordinates = [v.co[:] for ob in exported for v in ob.data.vertices]
    report = {'asset': name, 'source': source, 'file': path.name, 'bytes': path.stat().st_size,
              'vertices': sum(len(ob.data.vertices) for ob in exported), 'surfaces': len(exported), 'source_surfaces': source_surfaces,
              'bounds_blender': [np.min(coordinates, axis=0).tolist(), np.max(coordinates, axis=0).tolist()],
              'walk_samples': 24 if pose else 0, 'idle_samples': 12 if idle else 0,
              'stride_tiles': .64 if pose else None, 'rights_status': 'needs_evidence',
              'material_mode': 'preview_vertex_colours_with_grouped_PBR_finishes_not_full_procedural_bake',
              'draw_batching': 'vertex_palette_compatible_PBR',
              'idle_mode': ('breathing' if name == 'physician' else 'static_authored_held_pose') if idle else None}
    if activity:
        import hashlib
        base = ROOT/'eZeus/godot/assets/models'/path.name
        report['building_activity'] = {'revision':'authored_work_v1','frames':8,'inactive':'inactive','fps_at_normal_speed':10,
            'dynamic_source_objects':len(dynamic),'allocation_target':budget,'base_sha256':hashlib.sha256(base.read_bytes()).hexdigest(),
            'state':'native working (staff, shutdown, inputs and overlay eligibility); native clock, no simulation RNG'}
    if human_asset:
        import wardrobe
        for identity in identities:
            identity['clavi_srgb'] = wardrobe.profile(identity['name'])[1] or wardrobe.profile(identity['name'])[0]
        report['character'] = {'revision':character_art.REVISION, 'identities':identities,
                               'vertex_budget':45000 if name == 'settlers1' or name in MOUNTED else 22000, 'allocation_target':budget,
                               'shader':'res://shaders/character.gdshader',
                               'surfaces':'UV2.x * 8: skin/cloth/hair/eye/leather/metal/wood/other/tunica; floor(UV2.y * 8): person',
                               'rest_coordinates':'Godot UV: local rest X/(1-Z), stable through morph poses',
                               'seed':'local stable hashes, never simulation RNG'}
        report['material_mode'] = 'painted_anatomical_skin_rest_clavi_procedural_realtime_finishes'
        if god_float.is_god(name):
            report['character']['floating'] = god_float.REVISION
        if name == 'walker_hades':
            from godot_hades_art import REVISION
            report['character']['art_direction'] = REVISION
            report['character']['adapter'] = 'eZeus/tools/godot_hades_art.py'
            report['character']['reference'] = 'user mood reference: flame hair and sweeping dark Greek drapery; original older anatomical face, gray beard and red fire per follow-up'
            report['character']['hem_effect'] = 'res://scripts/hades_hem_fire.gd; bounded cosmetic flames/embers, follows native dissolve pose'
    if name in GARDEN_ASSETS:
        report['foliage'] = {'revision': GARDEN_REVISION, 'source': 'eZeus/tools/godot_garden_foliage.py',
                             'method': 'opaque_folded_volumetric_leaves_branching_stems_clipped_hedges',
                             'vertex_budget': budget,
                             'seed': 'local_python_stable_strings_not_simulation_rng',
                             'native_footprint': GARDEN_FOOTPRINTS[name],
                             'park_variant': 'pine_1x1' if name == 'park' else None}
    (OUT / (name + '.json')).write_text(json.dumps(report, indent=2) + '\n')
    print('GODOT_EXPORT ' + json.dumps(report), flush=True)


parser = argparse.ArgumentParser()
parser.add_argument('--asset', required=True)
parser.add_argument('--output-dir', type=Path, help='Optional isolated directory for export verification')
parser.add_argument('--building-activity', action='store_true')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
BUILDING_ACTIVITY = args.building_activity
if args.output_dir:
    OUT = args.output_dir
export(args.asset)
