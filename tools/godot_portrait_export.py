"""Background Blender: export a walker's portrait model for the character window, or preview it.

blender -b --factory-startup --python-exit-code 1 -P tools/godot_portrait_export.py -- --asset walker_trader [--out DIR]
    [--preview DIR --views front,three,side,full]

The walker is built exactly as tools/export_godot_pilot.py builds it (its source is loaded, not edited), then each grown
man gets a Greek portrait face (tools/godot_portrait_faces.py). The export is one held pose with no walk/idle samples and
a larger geometry allowance, written to godot/assets/portraits/<asset>.glb with its manifest. The city keeps the crowd
model; only ui/character_panel.gd shows this one. Never saves a .blend or touches the crowd models.
"""
import sys, os, math, json, argparse
from pathlib import Path
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
ap = argparse.ArgumentParser()
ap.add_argument('--asset', required=True)
ap.add_argument('--out', type=Path)
ap.add_argument('--preview', type=Path)
ap.add_argument('--views', default='front,three,side')
ap.add_argument('--size', type=int, default=720)
ap.add_argument('--budget', type=int, default=36000, help='vertices for everything but the protected face parts')
args = ap.parse_args(argv)

REPO = Path(__file__).resolve().parents[1]
path = REPO / 'tools/export_godot_pilot.py'
src = path.read_text()
src = src[:src.index('parser = argparse.ArgumentParser()')]
# A held portrait: no walk/idle/clip samples, no shape keys, and room for the face parts on top of the body's share.
patches = [
    ("        budget = 32000 if name == 'settlers1' or name in MOUNTED else 15000\n",
     "        budget = PORTRAIT_BUDGET + sum(len(g['vertices']) for g in groups.values() if any(n.startswith(god_face.PROTECTED) for n, _, _ in g['sources']))\n"),
    ("        if name == 'walker_hades':\n            # The designed face",
     "        if name == 'walker_hades' and False:\n            # The designed face"),
    ("        if pose or moving:\n            mappings.append(", "        if (pose or moving) and not PORTRAIT:\n            mappings.append("),
    ("    if pose:\n        for label, count, fn in [('walk', 24, pose), ('idle', 12, idle)] + EXTRA_CLIPS:",
     "    if pose and not PORTRAIT:\n        for label, count, fn in [('walk', 24, pose), ('idle', 12, idle)] + EXTRA_CLIPS:"),
    ("        for label, count, fn in [('walk', 24, pose)] + EXTRA_CLIPS:\n            for frame in range(count):\n                fn(frame)",
     "        for label, count, fn in ([] if PORTRAIT else [('walk', 24, pose)] + EXTRA_CLIPS):\n            for frame in range(count):\n                fn(frame)"),
]
for old, new in patches:
    if old not in src:
        raise SystemExit('exporter changed; portrait patch not found: ' + old[:60])
    src = src.replace(old, new, 1)
sys.argv = ['blender', '--', '--asset', args.asset]
ns = {'__file__': str(path), '__name__': '__godot_portrait__', 'PORTRAIT': True, 'PORTRAIT_BUDGET': args.budget}
exec(compile(src, str(path), 'exec'), ns)
K = ns['K']
character_art = ns['character_art']
god_face = ns['god_face']
sys.path.insert(0, str(REPO / 'tools'))
import godot_portrait_faces as portrait
god_face.PROTECTED = tuple(god_face.PROTECTED) + portrait.PROTECTED

# Every grown man gets the portrait face instead of the crowd's skin paint and groom.
original_prepare = character_art.prepare
def prepare(K_):
    paint_skin, groom = character_art.paint_skin, character_art.groom
    alone = len(character_art.HUMANS) == 1
    def paint_or_portrait(h):
        if not portrait.applies(h):
            paint_skin(h)
    def groom_or_portrait(h, K__):
        if portrait.applies(h):
            portrait.adapt(h, K__, groom, alone)
        else:
            groom(h, K__)
    character_art.paint_skin, character_art.groom = paint_or_portrait, groom_or_portrait
    try:
        return original_prepare(K_)
    finally:
        character_art.paint_skin, character_art.groom = paint_skin, groom
character_art.prepare = prepare

if args.preview is None:
    out = args.out or (REPO / 'godot/assets/portraits')
    out.mkdir(parents=True, exist_ok=True)
    ns['OUT'] = out
    ns['export'](args.asset)
    manifest = out / (args.asset + '.json')
    report = json.loads(manifest.read_text())
    if not any(h.godot_identity.get('portrait') for h in character_art.HUMANS):
        # No grown Greek man in this walker: no portrait (the window shows the crowd model).
        for suffix in ('.glb', '.json'):
            (out / (args.asset + suffix)).unlink(missing_ok=True)
        print('PORTRAIT_SKIPPED', args.asset, flush=True)
        os._exit(3)
    report.update(walk_samples=0, idle_samples=0, idle_mode=None, stride_tiles=None,
                  portrait={'revision': portrait.REVISION, 'adapter': 'eZeus/tools/godot_portrait_faces.py',
                            'use': 'character window only (ui/character_panel.gd); the city keeps the crowd model',
                            'people': [h.godot_identity.get('portrait') for h in character_art.HUMANS if h.godot_identity.get('portrait')],
                            'reference': "user's stylised philosopher (curly beard and hair, laurel); original geometry, no pixels used"})
    # Where the first man's eyes are (Godot's Y is Blender's Z): the character window frames his head and shoulders there.
    man = next((h for h in character_art.HUMANS if h.godot_identity.get('portrait')), None)
    if man is not None:
        eye = man.root.matrix_world @ Vector((0, float(man.J['head'][1]), float(man.eye_z)))
        report['portrait']['eye'] = [round(eye.x, 4), round(eye.z, 4), round(-eye.y, 4)]
        report['portrait']['head_height'] = round(.13 * man.root.matrix_world.to_scale().x, 4)
    manifest.write_text(json.dumps(report, indent=2) + '\n')
    print('PORTRAIT_EXPORT', args.asset, report['vertices'], report['bytes'], flush=True)
    raise SystemExit(0)

# ---- preview: build as the export does, render close-ups with the palette as base colour
human_asset = args.asset in character_art.ASSETS
if human_asset:
    character_art.install()
source, pose, idle = ns['construct'](args.asset)
if pose:
    pose(0)
character_art.prepare(K)
if pose:
    pose(0)
bpy.context.view_layer.update()

def preview_material(ob):
    old = ob.data.materials[0] if ob.data.materials else None
    m = bpy.data.materials.new('preview ' + ob.name)
    m.use_nodes = True
    nt = m.node_tree
    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    if old is not None:
        bs.inputs['Base Color'].default_value = tuple(old.diffuse_color)
    lower = ob.name.lower()
    bs.inputs['Roughness'].default_value = .2 if 'eyeball' in lower else .65
    if ob.data.attributes.get('GodotPalette') is not None:
        a = nt.nodes.new('ShaderNodeAttribute'); a.attribute_type = 'GEOMETRY'; a.attribute_name = 'GodotPalette'
        nt.links.new(a.outputs['Color'], bs.inputs['Base Color'])
    return m

for ob in list(bpy.context.scene.objects):
    if ob.type == 'MESH' and not ob.hide_render:
        m = preview_material(ob)
        ob.data.materials.clear(); ob.data.materials.append(m)
sc = bpy.context.scene
for o in list(sc.objects):
    if o.type in {'LIGHT', 'CAMERA'}:
        bpy.data.objects.remove(o, do_unlink=True)
try:
    sc.render.engine = 'BLENDER_EEVEE'
except TypeError:
    pass
sc.render.resolution_x = sc.render.resolution_y = args.size
sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
bg.inputs['Color'].default_value = (.10, .13, .17, 1); bg.inputs['Strength'].default_value = 1.0
sc.world = w
def sun(name, energy, rot, color=(1, 1, 1)):
    d = bpy.data.lights.new(name, 'SUN'); d.energy = energy; d.color = color
    o = bpy.data.objects.new(name, d); sc.collection.objects.link(o); o.rotation_euler = rot
sun('key', 3.4, (math.radians(55), 0, math.radians(-35)), (1, .95, .88))
sun('fill', .9, (math.radians(70), 0, math.radians(120)), (.6, .7, 1))
sun('rim', 1.6, (math.radians(70), 0, math.radians(190)), (1, .85, .6))
hh = next((h for h in character_art.HUMANS if portrait.applies(h)), character_art.HUMANS[0])
ez = float(hh.eye_z)
M = hh.root.matrix_world.copy()
scale = M.to_scale().x
cam_d = bpy.data.cameras.new('cam'); cam_d.lens = 85
cam = bpy.data.objects.new('cam', cam_d); sc.collection.objects.link(cam); sc.camera = cam
args.preview.mkdir(parents=True, exist_ok=True)
views = {'front': 0, 'three': 35, 'side': 88, 'threeL': -35, 'full': 25}
for v in args.views.split(','):
    yaw = math.radians(views[v])
    full = v == 'full'
    target = M @ Vector((0, .02, .48 if full else ez - .018))
    dist = (1.6 if full else .36) * scale
    off = M.to_3x3() @ Vector((math.sin(yaw), math.cos(yaw), .06))
    cam.location = target + off * dist
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = str(args.preview / f'{args.asset}_{v}.png')
    bpy.ops.render.render(write_still=True)
print('PORTRAIT_PREVIEW_DONE', args.asset, flush=True)
