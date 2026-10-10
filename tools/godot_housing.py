"""Godot-only common housing art; background export, native sprite sources stay intact.

The first two levels have original compact Greek dwellings instead of a white
cone and a shorter box. Later levels retain their authored architecture. The
whole family uses neutral yards and increasing architectural heights, while
household residents retain their anatomy and their local floor anchors.
"""
import json
import math
import random
import sys
import tempfile
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ART = json.loads((ROOT / 'eZeus/godot/data/housing_art.json').read_text())
ASSETS = tuple(f'common_house_{i}a' for i in range(7))
MEASUREMENTS = {}


def tint(material, colour):
    # The exporter reads the diffuse/base value, not a procedural node output.
    material.diffuse_color = (*colour, 1)
    shader = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*colour, 1)


def yard(K, G, P, kind='earth', n=2):
    if kind != 'earth':
        return ORIGINAL_YARD(K, P, kind, n)
    # Irregular thin earth patches leave native terrain visible around the lot.
    # No rectangular golden mat or opaque bottom slab.
    M = G.materials(K)
    outline = [(-.94, -.85), (-.54, -.96), (.24, -.91), (.86, -.70),
               (.93, -.16), (.86, .62), (.45, .92), (-.21, .95),
               (-.79, .69), (-.96, .12)]
    K.mesh('Weathered house yard', [(0, 0, .008)] + [(x, y, .008) for x, y in outline],
           [(0, i + 1, (i + 1) % len(outline) + 1) for i in range(len(outline))], M.earth)
    for i in range(4):
        K.box('Door approach stone', (.31 + .10 * i, .14 + .14 * i, .012),
              (.18, .19, .018), M.flag[i % len(M.flag)], .008)
    for x, y in [(.74, .71), (-.79, .62), (.82, -.67)]:
        K.ell('Yard fieldstone', (x, y, .024), (.04, .026, .026), M.fieldstone[1], subdiv=1)


def starter(K, G, L, P, level):
    M = G.materials(K)
    G.yard(K, P, 'earth')
    # Ground-level doors/windows remain proportioned to citizens. The upgraded
    # dwelling has taller masonry, a framed window and a shaded working porch.
    x0, x1, y0, y1 = -.84, .35, -.82, .20
    wall_h = .49 if level == 0 else .73
    socle = .07 if level == 0 else .10
    door_h = .43 if level == 0 else .62
    zb = L.room(P, x0, x1, y0, y1, wall_h, M.daub if level == 0 else M.mudbrick,
                t=.075, socle=socle,
                openings={'y1': [(.55, .81, 0, door_h)], 'x1': [(.36, .56, .26, .40 if level == 0 else .48)]})
    eave, ridge = zb + wall_h, (.86 if level == 0 else 1.06)
    G.thatch_roof(K, x0, x1, y0, y1, ridge, eave, overhang=.07, thickness=.038, seed=92 + level)
    for y in (y0, y1):
        G.gable(K, x0, x1, y, eave, ridge, M.daub if level == 0 else M.mudbrick)
    L.eave_course(x0, x1, y0, y1, eave - .025, M.timber_dark)
    G.door(K, (x0, y1), (x1, y1), .68, .26, door_h, .075,
           z0=zb, open_angle=.5, side=1)
    G.window(K, (x1, y0), (x1, y1), .46, .20, .14 if level == 0 else .22, zb + .26, .075)
    for x in (x0, x1):
        for y in (y0, y1):
            K.box('Exposed oak upright', (x, y, zb + wall_h / 2), (.045, .045, wall_h), M.timber_dark, .004)
    # Visible reed courses and tied sheaves give thatch a silhouette and tone
    # even before procedural texture baking. They are geometry, not flat paint.
    for side in (-1, 1):
        for k in range(1, 6):
            t = k / 6
            x = (x0 + x1) / 2 + side * ((x1 - x0) / 2 + .07) * t
            z = ridge - t * (ridge - eave) + .042
            K.rod('Layered reed course', (x, y0 - .07, z), (x, y1 + .07, z), .010,
                  M.thatch if k % 2 else M.straw, n=6)
    if level == 0:
        for z in [.20, .33, .46]:
            K.box('Wattle binding', ((x0 + x1) / 2, y0 - .042, z), (x1 - x0, .018, .018), M.timber, .002)
        L.wattle_fence((-.87, .56), (-.87, .88), h=.23, posts=3)
        L.firewood(-.56, .72, 5, .4)
    else:
        # Coarse stone courses, lime repairs and the modest lean-to clearly
        # distinguish the first upgrade without turning it into a mansion.
        for k in range(4):
            K.box('Limewash repair', (x0 + .12 + k * .14, y0 - .041, .32 + .09 * (k % 2)),
                  (.13, .014, .16), M.plaster_warm, .012)
        for y in (y0 + .04, y1 - .04):
            K.rod('Porch post', (.75, y, .014), (.75, y, .67), .025, M.timber, n=8)
        K.box('Reed porch shade', (.54, (y0 + y1) / 2, .75), (.46, .98, .035), M.thatch, .006).rotation_euler.y = .25
        for k in range(7):
            K.box('Porch reed lath', (.54, y0 + k * .15, .772), (.46, .015, .012), M.timber, .001)
        G.pithos(K, .61, -.57, .6)
        L.potted_plant(-.62, .67, s=.65)
    G.pithos(K, -.63, .38, .65)
    K.basket(P, .58, .72, .06, .09, fill=True, fill_mat=M.straw)
    resident = K.Worker(P, 'Household resident', P.cloth['rose'], loc=(.36, .62, .018),
                        facing=-math.pi / 2, garment='chiton', sex='female', seed=11 + level)
    resident.pose((0, 0, resident.pelvis_height), .02,
                  {1: (.08, .03, 0), -1: (-.08, -.03, 0)},
                  {1: Vector((.13, .18, .43)), -1: Vector((-.12, .16, .43))})


ORIGINAL_YARD = None


def build(K, name, execute):
    global ORIGINAL_YARD
    sys.path.insert(0, str(ROOT / 'art/common_house'))
    import levels as L
    G = L.G
    level = int(name.removeprefix('common_house_')[0])
    original_materials, ORIGINAL_YARD, original_worker = G.materials, G.yard, K.Worker
    residents = []
    painted = set()

    def paint(material, colour):
        if material.as_pointer() not in painted:
            tint(material, colour)
            painted.add(material.as_pointer())

    def palette(kit):
        M = original_materials(kit)
        for field, colour in [('earth', (.21, .225, .17)), ('daub', (.46, .40, .30)),
                              ('mudbrick', (.43, .34, .25)), ('thatch', (.34, .28, .16)),
                              ('straw', (.43, .37, .23)), ('plaster_warm', (.68, .64, .53))]:
            paint(getattr(M, field), colour)
        for i, material in enumerate(M.flag): paint(material, (.44 + i * .018, .45 + i * .017, .40 + i * .014))
        return M

    def worker(*args, **kwargs):
        person = original_worker(*args, **kwargs)
        residents.append(person.root)
        return person

    G.materials = palette
    G.yard = lambda kit, p, kind='earth', n=2: yard(kit, G, p, kind, n)
    K.Worker = worker
    try:
        if level < 2:
            P = L.setup(f'{level}a', Path(tempfile.gettempdir()) / 'godot-housing-source')
            G.M = None
            starter(K, G, L, P, level)
        else:
            execute(ROOT / f'art/{name}/build_sprites.py', [])
        # Sprite smoke is a held sphere cloud, not part of the house silhouette.
        # Original native sprite recipes and their working loops are untouched.
        for ob in K.root.children_recursive:
            if ob.name.startswith('Smoke puff'): ob.hide_render = True
        bpy.context.view_layer.update()
        def resident_height(root):
            points = [(ob.matrix_world @ Vector(c)).z for ob in root.children_recursive
                      if ob.type in {'MESH', 'CURVE'} and not ob.hide_render for c in ob.bound_box]
            return max(points) - min(points)
        before_people = [resident_height(root) for root in residents]
        people = {ob for root in residents for ob in [root, *root.children_recursive]}
        architecture = [ob for ob in K.root.children_recursive if ob.type in {'MESH', 'CURVE'} and not ob.hide_render and ob not in people]
        top = max((ob.matrix_world @ Vector(c)).z for ob in architecture for c in ob.bound_box)
        factor = ART['architecture_heights'][level] / top
        K.root.scale.z *= factor
        # Move a resident's floor anchor with the architecture, while retaining
        # body dimensions. All current household roots are children of K.root.
        for root in residents: root.scale.z /= factor
        K.root.rotation_euler.z = 0
        bpy.context.view_layer.update()
        K.root['housing_height'] = ART['architecture_heights'][level]
        MEASUREMENTS[name] = {
            'resident_heights_before': before_people,
            'resident_heights_after': [resident_height(root) for root in residents],
            'measured_architecture_height': max((ob.matrix_world @ Vector(c)).z for ob in architecture for c in ob.bound_box)
        }
    finally:
        G.materials, G.yard, K.Worker = original_materials, ORIGINAL_YARD, original_worker


def manifest(name):
    return {**ART, **MEASUREMENTS[name], 'level': int(name.removeprefix('common_house_')[0]),
            'architecture_height': ART['architecture_heights'][int(name.removeprefix('common_house_')[0])],
            'resident_dimensions': 'preserved; floor anchor follows authored architecture',
            'native_sources': 'art/common_house/levels.py retained for levels 2-6; original starter designs for 0-1',
            'seed': 'local source seed only; no native RNG'}
