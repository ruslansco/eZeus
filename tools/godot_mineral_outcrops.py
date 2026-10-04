"""Mineral outcrop models for the Godot terrain details (revision 1).

Each native resource kind gets its own silhouette and baked vertex palette, so the
deposits read apart at city distance: rounded limestone, a tall crag, rust-red copper
gossan with verdigris, dark host rock with silver galena cubes, dark basalt with gold
orichalcum crystals, and sawn white/black marble ledges. One object per kind:variant.

Vertex colour RGB is linear albedo; A is the ore mask (metallic/emission in
outcrop.gdshader). Units are native tiles; Blender -Y is Godot +Z, the quarry
boundary side of marble ledges. Every vertex stays inside the cell budget below.

Export (disposable background Blender, from eZeus/):
  blender -b --factory-startup --python-exit-code 1 -P tools/godot_mineral_outcrops.py -- \
      --out godot/assets/terrain/mineral_outcrops.glb
Inside a live Blender, exec the file and call build() to preview in a new scene.
"""
import math
import random
import sys

import bmesh
import bpy
from mathutils import Vector, noise

REVISION = 1
KINDS = ('stone', 'tall_stone', 'copper', 'silver', 'orichalcum', 'marble', 'black_marble')
VARIANTS = 2
REACH = .40          # Horizontal extent of every non-quarry model, in tiles.
QUARRY = (.22, .44)  # Marble ledges stay between these distances from the cell centre.
VERTEX_BUDGET = 400  # Godot vertices per mesh, after flat-shading splits.


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def clamp(x, lo=0.0, hi=1.0):
    return max(lo, min(hi, x))


class Model:
    """A bmesh with a point colour layer; flat parts are emitted as separate vertices."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        # A bmesh layer, not a dict of vertices: later icosphere ops invalidate those keys.
        self.layer = self.bm.verts.layers.float_color.new('Col')

    def paint(self, vert, rgb, mask=0.0):
        vert[self.layer] = (rgb[0], rgb[1], rgb[2], mask)


def neighbours_concavity(vert):
    linked = [e.other_vert(vert).co for e in vert.link_edges]
    if not linked:
        return 0.0
    mean = sum(linked, Vector()) / len(linked)
    return (mean - vert.co).dot(vert.normal)


def rock(m, centre, size, seed, subdivisions=3, roughness=.13, cuts=0, palette=None, strata=0.0):
    """Noise-displaced boulder, optionally faceted by plane cuts; bottom sinks below ground."""
    rng = random.Random(seed)
    made = bmesh.ops.create_icosphere(m.bm, subdivisions=subdivisions, radius=1.0)['verts']
    offset = Vector((rng.uniform(0, 50), rng.uniform(0, 50), rng.uniform(0, 50)))
    planes = []
    for _ in range(cuts):
        normal = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-.2, 1))).normalized()
        planes.append((normal, rng.uniform(.62, .82)))
    for v in made:
        p = v.co.normalized()
        p *= 1 + roughness * noise.fractal(p * 1.7 + offset, .55, 2.0, 3)
        if strata:
            p.z += strata * math.sin(p.z * 9.0 + noise.noise(p * 2 + offset) * 1.5) * .5
        for normal, distance in planes:
            over = p.dot(normal) - distance
            if over > 0:
                p -= normal * over * .9
        p = Vector((p.x * size[0], p.y * size[1], p.z * size[2]))
        if p.z < 0:
            p.z *= .35
        v.co = Vector(centre) + p
    bm = m.bm
    bm.normal_update()
    for f in {f for v in made for f in v.link_faces}:
        f.smooth = True
    if palette:
        for v in made:
            local = v.co - Vector(centre)
            up = clamp(v.normal.z)
            cav = clamp(neighbours_concavity(v) * 18.0, -1.0, 1.0)
            n = noise.noise(local * 6.0 + offset) * .5 + .5
            rgb, mask = palette(local, up, cav, n, rng)
            m.paint(v, rgb, mask)
    return made


def flat_faces(m, polygons, rgb, mask=0.0):
    """Flat facets with their own vertices (crisp crystal and sawn-block edges)."""
    for points in polygons:
        verts = [m.bm.verts.new(p) for p in points]
        face = m.bm.faces.new(verts)
        face.smooth = False
        for v in verts:
            m.paint(v, rgb, mask)


def crystal(m, base, direction, length, radius, rng, rgb, sides=6):
    direction = Vector(direction).normalized()
    across = direction.cross(Vector((0, 0, 1)) if abs(direction.z) < .95 else Vector((1, 0, 0))).normalized()
    other = direction.cross(across)
    twist = rng.uniform(0, math.tau)
    ring = lambda height, r: [Vector(base) + direction * height + (across * math.cos(twist + i * math.tau / sides)
                              + other * math.sin(twist + i * math.tau / sides)) * r for i in range(sides)]
    low = ring(-.04, radius)
    high = ring(length * .74, radius * .92)
    tip = Vector(base) + direction * length
    polygons = []
    for i in range(sides):
        j = (i + 1) % sides
        polygons.append((low[i], low[j], high[j], high[i]))
        polygons.append((high[i], high[j], tip))
    for index, polygon in enumerate(polygons):
        light = (1.0, .86, 1.08, .92, 1.0, .8, 1.1, .9, 1.0, .84, 1.06, .95)[index % 12]
        flat_faces(m, [polygon], tuple(min(1.0, x * light) for x in rgb), 1.0)


def block(m, lo, hi, rgb, bevel=.018, mask=0.0, shade=None):
    """A sawn block with bevelled edges, every face flat."""
    bm = bmesh.new()
    made = bmesh.ops.create_cube(bm, size=1.0)['verts']
    lo, hi = Vector(lo), Vector(hi)
    for v in made:
        v.co = Vector((lo.x if v.co.x < 0 else hi.x, lo.y if v.co.y < 0 else hi.y, lo.z if v.co.z < 0 else hi.z))
    if bevel:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1, affect='EDGES', profile=.5)
    bm.normal_update()
    polygons = []
    for f in bm.faces:
        if f.normal.z < -.5:
            continue  # Buried bottom.
        polygons.append([v.co.copy() for v in f.verts])
    bm.free()
    for points in polygons:
        normal = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
        light = 1.0 + .06 * normal.z - .03 * abs(normal.x)
        tint = tuple(min(1.0, c * light) for c in rgb)
        if shade:
            tint = shade(tint, normal)
        flat_faces(m, [points], tint, mask)


# Palettes: (local position, upness, concavity, noise, rng) -> (linear rgb, ore mask)

def limestone(local, up, cav, n, rng):
    # Weathered grey limestone: darker flanks and crevices, lichen on the tops.
    rgb = mix((.21, .20, .18), (.36, .345, .31), n)
    rgb = mix(rgb, (.40, .39, .35), clamp(up - .3) * .6)
    if cav > .08:
        rgb = mix(rgb, (.11, .105, .095), clamp(cav * 1.4))
    if up > .6 and n > .76:
        rgb = mix(rgb, (.42, .36, .17), .45)  # Ochre lichen.
    elif up > .45 and n < .26:
        rgb = mix(rgb, (.22, .26, .15), .55)  # Grey-green lichen.
    return rgb, 0.0


def crag(local, up, cav, n, rng):
    band = .5 + .5 * math.sin(local.z * 26.0 + n * 2.0)
    rgb = mix((.22, .21, .18), (.38, .36, .31), band * .6 + n * .4)
    if cav > .08:
        rgb = mix(rgb, (.11, .105, .095), clamp(cav * 1.4))
    return rgb, 0.0


def gossan(local, up, cav, n, rng):
    # Weathered copper ore: iron-stained rust, bright verdigris/malachite crusts.
    rgb = mix((.27, .11, .05), (.46, .22, .085), n)
    mask = 0.0
    if cav > .02 or (up > .4 and n > .55):
        rgb = mix(rgb, (.05, .34, .25), clamp(.7 + cav))
    elif n < .2:
        rgb = mix(rgb, (.62, .30, .14), .7)  # Native copper glints.
        mask = .7
    return rgb, mask


def galena_host(local, up, cav, n, rng):
    rgb = mix((.105, .11, .12), (.20, .21, .23), n)
    mask = 0.0
    if n > .78:
        rgb = (.55, .57, .60)  # Silver streaks.
        mask = .9
    if cav > .15:
        rgb = mix(rgb, (.06, .06, .07), .6)
    return rgb, mask


def basalt(local, up, cav, n, rng):
    rgb = mix((.055, .06, .075), (.12, .125, .15), n)
    mask = 0.0
    if cav > .12 or n > .84:
        rgb = (.75, .42, .10)  # Gold seams running into the crystals.
        mask = 1.0
    return rgb, mask


def build_kind(kind, variant):
    m = Model('%s_%d' % (kind, variant))
    seed = KINDS.index(kind) * 97 + variant * 13 + REVISION
    rng = random.Random(seed)
    if kind == 'stone':
        # Rounded, lichened limestone boulders in a loose pile.
        if variant == 0:
            rock(m, (-.08, .05, .02), (.24, .21, .20), seed, 3, .24, 4, limestone)
            rock(m, (.20, -.16, .01), (.13, .12, .11), seed + 1, 2, .2, 2, limestone)
            rock(m, (.17, .22, .0), (.08, .075, .06), seed + 2, 2, .18, 1, limestone)
        else:
            rock(m, (.06, -.04, .02), (.28, .19, .17), seed, 3, .22, 4, limestone)
            rock(m, (-.24, .17, .01), (.12, .14, .12), seed + 1, 2, .2, 2, limestone)
            rock(m, (-.22, -.24, .0), (.07, .07, .055), seed + 2, 2, .18, 1, limestone)
    elif kind == 'tall_stone':
        rock(m, (-.03, .02, .0), (.25, .22, .95 + .15 * variant), seed, 3, .12, 3, crag, strata=.04)
        rock(m, (.24, -.17, .0), (.12, .11, .14), seed + 1, 2, .12, 1, crag)
    elif kind == 'copper':
        # Jagged, upright gossan with sharp plane-cut facets.
        rock(m, (-.05, .03, .0), (.22, .2, .40 + .06 * variant), seed, 3, .22, 5, gossan)
        rock(m, (.22, -.15, .0), (.12, .11, .19), seed + 1, 2, .2, 2, gossan)
        rock(m, (-.24, -.2, .0), (.08, .08, .10), seed + 2, 2, .2, 1, gossan)
    elif kind == 'silver':
        # Dark host rock studded with bright cubic galena.
        rock(m, (-.04, .03, .0), (.26, .23, .30 + .05 * variant), seed, 3, .14, 3, galena_host)
        rock(m, (.24, -.14, .0), (.11, .10, .12), seed + 1, 2, .12, 1, galena_host)
        for i in range(4):
            angle = rng.uniform(0, math.tau)
            c = Vector((math.cos(angle) * .17 - .04, math.sin(angle) * .15 + .03, rng.uniform(.08, .2)))
            s = rng.uniform(.03, .05)
            block(m, c - Vector((s, s, s)), c + Vector((s, s, s)), (.70, .72, .75), bevel=0, mask=1.0)
    elif kind == 'orichalcum':
        # Dark basalt host broken open by a gold-orange crystal druse.
        rock(m, (-.02, .04, .0), (.27, .24, .20 + .03 * variant), seed, 3, .16, 2, basalt)
        rock(m, (.24, -.18, .0), (.11, .10, .10), seed + 1, 1, .15, 0, basalt)
        count = 5
        for i in range(count):
            angle = i * math.tau / count + rng.uniform(-.3, .3) + variant
            spread = 0 if i == 0 else .07 + .05 * (i % 2)
            base = Vector((math.cos(angle) * spread - .02, math.sin(angle) * spread + .04, .12))
            lean = Vector((math.cos(angle) * .6, math.sin(angle) * .6, 1.0))
            length = rng.uniform(.21, .32) * (1.35 if i == 0 else 1.0)
            crystal(m, base, lean if i else Vector((.1, -.1, 1)), length, rng.uniform(.03, .045), rng,
                    (.92, .56, .14) if i % 2 else (.98, .70, .24))
    elif kind in ('marble', 'black_marble'):
        white = kind == 'marble'
        base = (.80, .79, .74) if white else (.075, .085, .085)

        def tint(rgb, normal, k=[0]):
            k[0] += 1
            v = 1.0 + .035 * math.sin(k[0] * 2.3)
            return tuple(min(1.0, c * v) for c in rgb)
        # Blender -Y faces the quarry boundary; loose chips lie on the inner side.
        y0, y1, inner = -QUARRY[1], -QUARRY[0] - .05, -QUARRY[0]
        if variant == 0:
            block(m, (-.40, y0, 0), (-.02, y1 - .01, .20), base, shade=tint)
            block(m, (.02, y0 + .02, 0), (.38, y1 - .03, .13), mix(base, (1, 1, 1), .05) if white else base, shade=tint)
            block(m, (-.34, y0 + .03, .20), (-.10, y1 - .05, .31), base, shade=tint)
        else:
            block(m, (-.38, y0 + .01, 0), (.10, y1, .16), base, shade=tint)
            block(m, (.14, y0, 0), (.40, y1 - .02, .24), mix(base, (1, 1, 1), .04) if white else base, shade=tint)
            block(m, (-.16, y0 + .02, .16), (.08, y1 - .04, .25), base, shade=tint)
        for i in range(2):
            x = rng.uniform(-.3, .3)
            s = rng.uniform(.012, .018)
            c = Vector((x, inner - .025, .0))
            block(m, c - Vector((s, s, .02)), c + Vector((s, s, s)), base, bevel=.003)
    return finish(m)


def finish(m):
    mesh = bpy.data.meshes.new(m.name)
    m.bm.to_mesh(mesh)
    mesh.color_attributes.active_color = mesh.color_attributes['Col']
    m.bm.free()
    obj = bpy.data.objects.new(m.name, mesh)
    return obj


def godot_vertices(obj):
    """Vertices after splitting flat faces, as glTF/Godot will count them."""
    mesh = obj.data
    keys = set()
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            vi = mesh.loops[li].vertex_index
            keys.add(vi if poly.use_smooth else (vi, poly.index))
    return len(keys)


def build(scene=None):
    scene = scene or bpy.data.scenes.new('Mineral Outcrops')
    collection = bpy.data.collections.new('Mineral Outcrops r%d' % REVISION)
    scene.collection.children.link(collection)
    objects = []
    for row, kind in enumerate(KINDS):
        for variant in range(VARIANTS):
            obj = build_kind(kind, variant)
            collection.objects.link(obj)
            count = godot_vertices(obj)
            xs = [v.co.x for v in obj.data.vertices]
            ys = [v.co.y for v in obj.data.vertices]
            reach = max(max(map(abs, xs)), max(map(abs, ys)))
            assert count <= VERTEX_BUDGET, (obj.name, count)
            if kind in ('marble', 'black_marble'):
                assert all(-QUARRY[1] - 1e-4 <= y <= -QUARRY[0] + 1e-4 for y in ys), obj.name
                assert max(map(abs, xs)) <= QUARRY[1], obj.name
            else:
                assert reach <= REACH + 1e-4, (obj.name, reach)
            objects.append((obj, row, variant, count))
    return scene, collection, objects


def export(path):
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj)
    scene, collection, objects = build(bpy.context.scene)
    bpy.ops.object.select_all(action='DESELECT')
    for obj, *_ in objects:
        obj.select_set(True)
        print('MINERAL', obj.name, 'vertices', _[2])
    available = set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())
    options = dict(filepath=path, export_format='GLB', use_selection=True, export_animations=False,
                   export_morph=False, export_cameras=False, export_lights=False, export_yup=True,
                   export_apply=False, export_materials='NONE', export_texcoords=False)
    if 'export_vertex_color' in available:
        options['export_vertex_color'] = 'ACTIVE'
    if 'export_active_vertex_color_when_no_material' in available:
        options['export_active_vertex_color_when_no_material'] = True
    if 'export_colors' in available:
        options['export_colors'] = True
    options = {k: v for k, v in options.items() if k in available or k == 'filepath'}
    bpy.ops.export_scene.gltf(**options)
    print('MINERAL_EXPORT', path)


if __name__ == '__main__' and '--out' in sys.argv:
    export(sys.argv[sys.argv.index('--out') + 1])
