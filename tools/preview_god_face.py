"""Background Blender: build a god exactly as the Godot export does, then render head close-ups.

blender -b --factory-startup -P tools/preview_god_face.py -- --god hades --out DIR [--tag NAME] [--views front,three,side]
FACE_DIST (default .26) is the camera distance in head-heights of the god's world scale.
About 20 seconds. Never saves a .blend and never touches the project's assets. The palette is the base colour
(as in the game); the Godot shader's finishes (gloss, glow, rim) are not reproduced, so judge the final look in
Godot with `run_godot_pilot.py --character-review after --character-subjects walker_<god>`.
"""
import sys, os, math, argparse
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
ap = argparse.ArgumentParser()
ap.add_argument('--god', default='hades')
ap.add_argument('--out', required=True)
ap.add_argument('--tag', default='head')
ap.add_argument('--size', type=int, default=720)
ap.add_argument('--views', default='front,three,side')
args = ap.parse_args(argv)

REPO = Path(__file__).resolve().parents[1]
src = (REPO / 'tools/export_godot_pilot.py').read_text()
src = src[:src.index('parser = argparse.ArgumentParser()')]
sys.argv = ['blender', '--', '--asset', 'walker_' + args.god]
ns = {'__file__': str(REPO / 'tools/export_godot_pilot.py'), '__name__': '__godot_export__'}
exec(compile(src, str(REPO / 'tools/export_godot_pilot.py'), 'exec'), ns)
K = ns['K']
character_art = ns['character_art']
character_art.install()
source, pose, idle = ns['construct']('walker_' + args.god)
if pose:
    pose(0)
character_art.prepare(K)
if pose:
    pose(0)
bpy.context.view_layer.update()
for o in sorted(bpy.context.scene.objects, key=lambda o: o.name):
    if o.type == 'MESH' and not o.hide_render:
        print('PART', o.name, len(o.data.vertices), flush=True)

# ---- preview materials: the palette is the base colour; kind decides the finish like character.gdshader
def preview_material(ob, src_mat):
    m = bpy.data.materials.new('preview ' + ob.name)
    m.use_nodes = True
    nt = m.node_tree
    bs = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
    base = None
    if src_mat and src_mat.use_nodes:
        p = next((n for n in src_mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if p:
            base = tuple(p.inputs['Base Color'].default_value)
            bs.inputs['Roughness'].default_value = p.inputs['Roughness'].default_value
            bs.inputs['Metallic'].default_value = p.inputs['Metallic'].default_value
            em = p.inputs['Emission Color'].default_value
            st = p.inputs['Emission Strength'].default_value
            if st > 0:
                bs.inputs['Emission Color'].default_value = em
                bs.inputs['Emission Strength'].default_value = st
    if base:
        bs.inputs['Base Color'].default_value = base
    if ob.data.attributes.get('GodotPalette') is not None:
        a = nt.nodes.new('ShaderNodeAttribute')
        a.attribute_type = 'GEOMETRY'
        a.attribute_name = 'GodotPalette'
        nt.links.new(a.outputs['Color'], bs.inputs['Base Color'])
        bs.inputs['Roughness'].default_value = .62
    return m

for ob in list(bpy.context.scene.objects):
    if ob.type == 'MESH' and not ob.hide_render:
        old = ob.data.materials[0] if ob.data.materials else None
        if len(ob.data.materials) <= 1:
            ob.data.materials.clear()
            ob.data.materials.append(preview_material(ob, old))
        else:
            mats = [preview_material(ob, m) for m in ob.data.materials]
            ob.data.materials.clear()
            for m in mats:
                ob.data.materials.append(m)

# ---- scene, lights, world
sc = bpy.context.scene
for o in list(sc.objects):
    if o.type in {'LIGHT', 'CAMERA'}:
        bpy.data.objects.remove(o, do_unlink=True)
try:
    sc.render.engine = 'BLENDER_EEVEE'
except TypeError:
    pass
sc.render.resolution_x = sc.render.resolution_y = args.size
sc.render.film_transparent = False
sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND')
bg.inputs['Color'].default_value = (.045, .06, .09, 1); bg.inputs['Strength'].default_value = 1.2
sc.world = w

def sun(name, energy, rot, color=(1, 1, 1)):
    d = bpy.data.lights.new(name, 'SUN'); d.energy = energy; d.color = color
    o = bpy.data.objects.new(name, d); sc.collection.objects.link(o)
    o.rotation_euler = rot
sun('key', 3.2, (math.radians(55), 0, math.radians(-35)), (1, .95, .88))
sun('fill', .8, (math.radians(70), 0, math.radians(120)), (.6, .7, 1))

# head frame: z of the eyes, face looks +Y (local), figure root is at the origin after pose(0)
hh = character_art.HUMANS[0]
ez = float(hh.eye_z)
M = hh.root.matrix_world.copy()
scale = M.to_scale().x
print('ROOT', M.translation, scale, flush=True)
cam_d = bpy.data.cameras.new('cam'); cam_d.lens = 105
cam = bpy.data.objects.new('cam', cam_d); sc.collection.objects.link(cam); sc.camera = cam
Path(args.out).mkdir(parents=True, exist_ok=True)
views = {'front': 0, 'three': 38, 'side': 88, 'threeL': -38, 'full': 20, 'fullside': 88}
for v in args.views.split(','):
    yaw = math.radians(views[v])
    full = v.startswith('full')
    target = M @ Vector((0, .035, (.45 if full else ez - .01)))
    dist = float(os.environ.get("FACE_DIST", "1.15" if full else ".26")) * scale
    off = M.to_3x3() @ Vector((math.sin(yaw), math.cos(yaw), .04))
    cam.location = target + off * dist
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = str(Path(args.out) / f'{args.tag}_{v}.png')
    bpy.ops.render.render(write_still=True)
print('PREVIEW_DONE', args.tag, flush=True)
