"""Greek portrait faces for the character window. Godot-only: runs inside a disposable background export.

The crowd walkers keep their budgeted heads. A portrait export (tools/godot_portrait_export.py) rebuilds a male walker
with a designed face instead: a classical Greek profile (a straight nose that carries the line of the forehead, a firm
brow, full lips, a strong chin), fair warm skin with baked occlusion, real eyes, raised brows, and the hair and beard of
Greek sculpture: rows of snail-shell curls over the scalp and the cheeks, corkscrew locks hanging from the jaw and a
moustache that sweeps into the beard. Beard colours are black, dark brown, grey or white by age.

It reuses the god-face kit (tools/godot_god_face.py: sculpt, occlusion, eyes, brows). Nothing here touches the
simulation, the native art kit, the shared body cache or the crowd models. Unit: 1 = 2 m; head frame faces +Y, z up.
"""
import hashlib
import math
import re

import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

import godot_god_face as gf

REVISION = 'greek_portrait_faces_v1'
# Names the exporter keeps whole (its simplifier would erase curls, iris rings and leaves).
PROTECTED = ('Portrait ', 'Hades eyeball')
HEADWEAR = ('helmet', 'hat', 'petasos', 'pilos', 'cap', 'hood', 'crown', 'diadem', 'wreath', 'kausia', 'turban', 'veil')

# Hair colours (sRGB): root, tip. Beard colours by age; a few roles have their own.
BLACK = ((.035, .028, .024), (.13, .10, .085))
BROWN = ((.07, .045, .028), (.24, .16, .10))
GREY = ((.30, .29, .28), (.62, .61, .59))
WHITE = ((.62, .61, .60), (.92, .91, .89))
ROLE_HAIR = {'Philosopher': GREY, 'Scholar': WHITE, 'Astronomer': WHITE, 'Inventor': GREY, 'Curator': GREY,
             'Shepherd': GREY, 'Peddler': GREY, 'Sick': GREY, 'Tax collector': BROWN, 'Zeus': WHITE,
             'Poseidon': GREY, 'Hephaestus': BLACK, 'Ares': BLACK, 'Atlas': GREY}
LAUREL = {'Philosopher', 'Scholar', 'Astronomer', 'Zeus', 'Apollo', 'Competitor'}
# Natural, fair Mediterranean complexions (sRGB): pale, fair, warm fair, light olive.
SKINS = [(.87, .69, .57), (.84, .66, .53), (.82, .64, .50), (.80, .62, .48)]


def lin(rgb):
    return tuple(float(c) ** 2.2 for c in rgb)


def stable(name, salt=''):
    return int.from_bytes(hashlib.sha256((name + salt).encode()).digest()[:4], 'little')


def applies(h):
    """Grown men only; designed gods (Hades) and creatures keep their own faces."""
    if getattr(h, 'sex', 'male') != 'male' or h.name in ('Hades', 'Cyclops', 'Talos', 'Minotaur', 'Satyr'):
        return False
    return h.godot_identity.get('age', 30) >= 16


def spec_for(h):
    p = h.godot_identity
    age = int(p.get('age', 35))
    if h.name == 'Philosopher':
        age = 75
    seed = stable(h.name)
    hair = ROLE_HAIR.get(h.name) or (WHITE if age >= 66 else GREY if age >= 52 else BROWN if seed % 3 == 0 else BLACK)
    if h.name == 'Philosopher':
        hair = WHITE
    old = max(0.0, min(1.0, (age - 30) / 40))
    # Each man his own face: stable per-role variation of the sculpt (nose, brow, cheekbones, jaw, chin).
    rng = np.random.default_rng(seed)
    vary = lambda value: value * float(rng.uniform(.70, 1.35))
    # Beard styles: young men a short close beard, older men a full one, the rest by role.
    style = 'short' if age < 30 else 'full' if age >= 50 else ('full', 'pointed', 'short')[seed % 3]
    length = {'short': .009, 'pointed': .026, 'full': .024 + .012 * old}[style]
    return dict(
        style=style,
        age=age, seed=seed, hair=hair, skin=lin(SKINS[seed % len(SKINS)]), laurel=h.name in LAUREL,
        sculpt=dict(brow=vary(.0030), frown=.0006 + .0010 * old, lines=.0002 + .0004 * old, socket=vary(.0011), cheekbone=vary(.0020),
                    hollow=.0006 + .0012 * old, temple=.0006, bridge=vary(.0036), tip=vary(.0014), tip_drop=vary(.0006), narrow=vary(.0004),
                    seam=.0008, upper_lip=-.0004, lower_lip=vary(.0012), downturn=.0002, chin=vary(.0030), chin_drop=vary(.0012),
                    jaw=vary(.0030), fold=.0010 + .0018 * old),
        brow_hair=dict(color=hair[1] if hair in (GREY, WHITE) else hair[0], thick=.0026, lift=.0012),
        eyes=dict(sclera=(.86, .84, .80), pupil=.0016, iris=.0033, cornea=.045, lid_shade=.95,
                  pupil_colour=(.015, .012, .01), iris_inner=(.34, .20, .08), iris_mid=(.26, .15, .06),
                  iris_outer=(.15, .085, .035), limbus=(.05, .035, .025)),
        # Beard: length of the hanging locks (units), how far it drops below the jaw.
        beard=dict(length=length, drop=.004 if style == 'short' else .014 + .010 * old, curl=.0011 if style == 'short' else .0013,
                   point=style == 'pointed'),
        hair_curl=.0014,
    )


# ------------------------------------------------------------------------------------------------- face
def sculpt(h, s):
    gf.sculpt(h, s)
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    face = gf.smooth(y, .04, .062) * gf.smooth(z, ez - .068, ez - .058)
    # The Greek profile: the nasion is filled, so the bridge continues the forehead in one straight line.
    dy = .0030 * gf.g(x, 0, .0060) * gf.g(z, ez + .0035, .0060) * face
    # A rounder, fuller lower lip and a firm, cleft-less chin; a slightly broader, squarer jaw.
    dy += .0006 * gf.g(x, 0, .0090) * gf.g(z, ez - .0545, .0025) * face
    co[:, 1] += dy
    h.parts[0].rest[:] = co
    gf.refresh(h)


def beard_zone(h):
    """Cheeks below the cheekbones, sideburns, jaw and chin, a moustache band; the lips stay clear."""
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    yc = float(h.J['head'][1])
    v = (y - yc) / .065
    cheek_top = ez - .028 - .004 * gf.smooth(ax, .018, .036)
    w = gf.smooth(cheek_top - z, -.001, .004) * gf.smooth(z, ez - .095, ez - .085) * gf.smooth(v, -.10, .15) * gf.smooth(.054 - ax, 0, .005)
    burns = gf.smooth(ax, .030, .035) * gf.smooth(.041 - ax, 0, .003) * gf.smooth(z, ez - .040, ez - .030) \
        * gf.smooth(ez + .004 - z, 0, .006) * gf.smooth(v, .05, .25)
    w = np.maximum(w, burns)
    mouth = gf.g(x, 0, .0200) * gf.g(z, ez - .0490, .0052) * gf.smooth(v, .45, .75)
    throat = gf.smooth(ez - .075 - z, 0, .006) * gf.smooth(.3 - v, 0, .3)
    return np.clip(w * (1 - np.clip(mouth * 3.0, 0, 1)) * (1 - throat), 0, 1)


def scalp_zone(h):
    """A full head of hair with a low, straight classical hairline; the ears stay clear."""
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    yc = float(h.J['head'][1])
    v = np.clip((y - yc) / .065, -1, 1)
    front = ez + .026 + .004 * gf.smooth(ax, .010, .030)
    side = ez + .010
    back = ez - .050
    zb = np.where(v > .45, front, np.where(v > 0, side + (front - side) * (np.clip(v, 0, 1) / .45) ** 2,
                                          side + (back - side) * np.clip(-v, 0, 1) ** 1.2))
    ears = (ax > .034) & (z < ez + .020) & (v > -.50) & (v < .50)
    return gf.smooth(z - zb, -.001, .002) * (~ears) * (z > ez - .080)


def paint(h, s, beard_w, scalp_w):
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    n = h.normals
    colors = np.tile([*s['skin'], 1.0], (len(co), 1))
    rgb = colors[:, :3]
    head = gf.smooth(z, ez - .095, ez - .080)
    face = gf.smooth(y, .03, .06) * head

    def mul(mask, color):
        rgb[:] = rgb * (1 - mask[:, None] * (1 - np.asarray(color)[None]))

    def tint(mask, color, k=1.0):
        m = np.clip(mask * k, 0, 1)[:, None]
        rgb[:] = rgb * (1 - m) + np.asarray(color)[None] * m

    rgb *= (1 + .03 * np.sin(x * 61 + z * 47) * np.sin(z * 73 - y * 39))[:, None]
    idx = np.flatnonzero(z > ez - .10)
    ao = np.zeros(len(co))
    ao[idx] = gf.occlusion(h, co[idx], n[idx])
    cavity = np.clip((ao - .08) / .55, 0, 1) ** .9
    mul(cavity * head * .85, (.36, .22, .17))
    # Warm blood: cheeks, nose tip, ears and lips a little rosier; sun on the forehead and nose bridge.
    for side in (-1, 1):
        mul(gf.g(x, side * .027, .012) * gf.g(z, ez - .022, .012) * face * .30, (1.0, .80, .76))
        mul(gf.g(x, side * .0185, .0100) * gf.g(z, ez - .0105, .0036) * face * .30, (.86, .78, .80))
    mul(gf.g(z, ez - .0235, .0060) * gf.g(x, 0, .0090) * face * .35, (1.0, .78, .72))
    mul(gf.smooth(ax, .040, .048) * gf.g(z, ez - .006, .022) * .30, (1.0, .80, .74))
    seam = ez - .0485
    lips = gf.g(x, 0, .0150) * gf.g(z, seam, .0058) * gf.smooth(y, .05, .07) * head
    tint(lips, lin((.66, .38, .34)), .70)
    mul(gf.g(x, 0, .0150) * gf.g(z, seam, .0009) * face, (.45, .30, .28))
    for side in (-1, 1):
        mul(gf.g(x, side * .0058, .0030) * gf.g(z, ez - .0295, .0017) * face, (.25, .15, .12))
    if s['age'] >= 45:
        for level in (.027, .036, .045):
            mul(gf.g(z, ez + level, .0011) * gf.g(x, 0, .026) * face * .35, (.72, .58, .52))
    for e in h.A['eye_co']:
        c = np.asarray(e).mean(axis=0)
        r = float(np.linalg.norm(np.asarray(e) - c, axis=1).mean())
        d = np.linalg.norm(co - c[None], axis=1) - r
        rim = np.exp(-(np.clip(d, 0, None) / .0011) ** 2) * (y > c[1] - .004) * (d > -.002)
        upper = gf.smooth(z - c[2], -.0015, .0030)
        mul(rim * (.55 + .45 * upper) * .9, (.22, .15, .12))
    # Hair roots: the skin under the beard and the scalp takes the hair's dark root colour, so no skin shows between curls.
    root = lin(s['hair'][0])
    lip_band = gf.smooth(.026 - ax, 0, .004) * gf.smooth(z, ez - .047, ez - .044)
    tint(np.clip(beard_w * 1.4, 0, 1) * (1 - lip_band), root, .92)
    mul(lip_band * beard_w * .45, (.70, .58, .52))
    tint(np.clip(scalp_w * 1.4, 0, 1), root, .95)
    mul(gf.brow_weight(h, s) * face * .55, (.40, .32, .28))
    return colors


# ------------------------------------------------------------------------------------------------ curls
def frame(normal):
    n = Vector(normal).normalized()
    up = Vector((0, 0, 1)) if abs(n.z) < .9 else Vector((1, 0, 0))
    t = n.cross(up).normalized()
    return t, n.cross(t).normalized(), n


class Strands:
    """Accumulates curl tubes into one mesh with a per-point palette."""

    def __init__(self):
        self.v, self.f, self.c = [], [], []

    def tube(self, path, radii, colours, sides=6):
        path = [np.asarray(p, dtype=float) for p in path]
        start = len(self.v)
        prev = None
        for i, p in enumerate(path):
            d = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)])
            d /= max(np.linalg.norm(d), 1e-9)
            if prev is None:
                a = np.cross(d, [0, 0, 1]) if abs(d[2]) < .9 else np.cross(d, [1, 0, 0])
            else:
                a = prev - d * np.dot(prev, d)          # parallel transport keeps the tube from twisting
            a /= max(np.linalg.norm(a), 1e-9)
            b = np.cross(d, a)
            prev = a
            for k in range(sides):
                ang = math.tau * k / sides
                self.v.append(tuple(p + radii[i] * (math.cos(ang) * a + math.sin(ang) * b)))
                self.c.append([*colours[i], 1.0])
        rows = len(path)
        for i in range(rows - 1):
            for k in range(sides):
                a0 = start + i * sides + k
                self.f.append((a0, start + i * sides + (k + 1) % sides, start + (i + 1) * sides + (k + 1) % sides, start + (i + 1) * sides + k))
        self.f.append(tuple(start + k for k in range(sides - 1, -1, -1)))
        self.f.append(tuple(start + (rows - 1) * sides + k for k in range(sides)))

    def emit(self, h, K, name, material):
        if not self.v:
            return None
        v = np.array(self.v)
        ob = h._mesh(name, v, self.f, material)
        gf.set_palette(ob, np.array(self.c))
        h._add(ob, v, gf.rigid_head(h, len(v)))
        for poly in ob.data.polygons:
            poly.use_smooth = True
        return ob


def shade(hair, t, light):
    """Hair colour from root (t=0) to tip, brighter where the curl faces up (light 0..1)."""
    root, tip = np.asarray(lin(hair[0])), np.asarray(lin(hair[1]))
    c = root * (1 - t) + tip * t
    return np.clip(c * (.80 + .45 * light), 0, 1)


def snail(strands, p, normal, radius, hair, rng, turns=2.1, lift=.0009):
    tone = .82 + .36 * rng.random()
    """A classical snail-shell curl lying on the surface: a tightening spiral that rises toward its centre."""
    t, b, n = frame(normal)
    t, b, n = np.array(t), np.array(b), np.array(n)
    phase = rng.random() * math.tau
    hand = 1 if rng.random() < .5 else -1
    steps = 12
    path, radii, cols = [], [], []
    for i in range(steps):
        u = i / (steps - 1)
        a = phase + hand * u * turns * math.tau
        r = radius * (1 - .82 * u)
        path.append(p + n * (lift + radius * .55 * u) + r * (math.cos(a) * t + math.sin(a) * b))
        radii.append(radius * (.36 - .20 * u) + .0002)
        cols.append(shade(hair, .25 + .55 * u, .4 + .6 * u * max(0, n[2])) * tone)
    strands.tube(path, radii, cols)


def corkscrew(strands, p, normal, length, radius, hair, rng, down=(0, 0, -1), turns=2.0):
    """A hanging lock: a corkscrew that narrows toward its tip, leaning out from the face."""
    n = np.asarray(normal, dtype=float)
    n /= np.linalg.norm(n)
    axis = np.asarray(down, dtype=float) * .82 + n * .38
    axis /= np.linalg.norm(axis)
    a0 = np.cross(axis, [1, 0, 0]) if abs(axis[0]) < .9 else np.cross(axis, [0, 1, 0])
    a0 /= np.linalg.norm(a0)
    b0 = np.cross(axis, a0)
    phase = rng.random() * math.tau
    tone = .82 + .36 * rng.random()
    steps = 14
    path, radii, cols = [], [], []
    for i in range(steps):
        u = i / (steps - 1)
        a = phase + u * turns * math.tau
        r = radius * (1 - .55 * u)
        path.append(p + axis * length * u + r * (math.cos(a) * a0 + math.sin(a) * b0) + n * .0006 * math.sin(u * math.pi))
        radii.append(radius * (.62 - .40 * u) + .00025)
        cols.append(shade(hair, .15 + .8 * u, .35 + .4 * (1 - u)) * tone)
    strands.tube(path, radii, cols)


def scatter(points, candidates, spacing, rng, limit):
    """Poisson-like sampling of candidate indices at a minimum spacing."""
    order = rng.permutation(candidates)
    kept = []
    tree = KDTree(len(order))
    count = 0
    for idx in order:
        p = Vector(points[idx])
        if count:
            tree.balance()
            if tree.find(p)[2] < spacing:
                continue
        tree.insert(p, count)
        count += 1
        kept.append(idx)
        if count >= limit:
            break
    return np.array(kept, dtype=int)


def scatter_fast(points, candidates, spacing, rng, limit):
    """Grid-hashed Poisson sampling (rebalancing a KD tree per insert is slow for thousands of candidates)."""
    cell = spacing
    grid = {}
    kept = []
    for idx in rng.permutation(candidates):
        p = points[idx]
        key = tuple((p / cell).astype(int))
        near = False
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for q in grid.get((key[0] + dx, key[1] + dy, key[2] + dz), ()):
                        if np.sum((points[q] - p) ** 2) < spacing * spacing:
                            near = True
                            break
                    if near:
                        break
                if near:
                    break
            if near:
                break
        if near:
            continue
        grid.setdefault(key, []).append(idx)
        kept.append(idx)
        if len(kept) >= limit:
            break
    return np.array(kept, dtype=int)


def hair(h, K, s, scalp_w):
    rng = np.random.default_rng(s['seed'] + 11)
    co, n = h.body_rest, h.normals
    hair_c = s['hair']
    mat = K.material('Portrait hair curls', lin(hair_c[1]), rough=.7)
    under = np.zeros((len(co), 4)); under[:, 3] = 1
    under[:, :3] = np.asarray(lin(hair_c[0]))[None] * (1 + .15 * np.sin(co[:, 0] * 900 + co[:, 2] * 400))[:, None]
    gf.shell_mesh(h, 'Portrait hair cap', scalp_w, .0016, mat, under, threshold=.35, scale_offset=False, target=2600)
    lifted = co + n * .0016
    cand = np.flatnonzero(scalp_w > .5)
    r = s['hair_curl']
    picks = scatter_fast(lifted, cand, r * 0.8, rng, 1400)
    strands = Strands()
    for idx in picks:
        snail(strands, lifted[idx], n[idx], r * (.85 + .3 * rng.random()), hair_c, rng)
    # A fringe of smaller curls along the hairline over the forehead, as on the statues.
    ez = h.eye_z
    edge = np.flatnonzero((scalp_w > .2) & (scalp_w < .7) & (co[:, 1] > .035) & (co[:, 2] > ez + .018))
    for idx in scatter_fast(lifted, edge, r * 1.15, rng, 60):
        snail(strands, lifted[idx] + n[idx] * .0006, n[idx], r * .75, hair_c, rng, turns=1.8)
    strands.emit(h, K, 'Portrait hair curls', mat)


def beard(h, K, s, beard_w):
    rng = np.random.default_rng(s['seed'] + 23)
    co, n = h.body_rest, h.normals
    ez = h.eye_z
    x, y, z = co.T
    b = s['beard']
    hair_c = s['hair']
    mat = K.material('Portrait beard curls', lin(hair_c[1]), rough=.72)
    # The beard's body: a shell over the jaw, dragged down, in and forward under the chin.
    low = gf.smooth(ez - .050 - z, 0, .018)
    drag = np.zeros_like(co)
    drag[:, 2] = -b['drop'] * low
    drag[:, 0] = -x * .22 * low
    drag[:, 1] = .006 * low
    under = np.zeros((len(co), 4)); under[:, 3] = 1
    under[:, :3] = np.asarray(lin(hair_c[0]))[None]
    lip_band = gf.smooth(.026 - np.abs(x), 0, .004) * gf.smooth(z, ez - .047, ez - .044)
    gf.shell_mesh(h, 'Portrait beard body', beard_w * (1 - lip_band), .0035, mat, under, threshold=.30, extra=drag, target=2200)
    surface = co + n * (.0035 * beard_w)[:, None] + drag
    strands = Strands()
    r = b['curl']
    # Snail curls on the cheeks and sideburns, corkscrew locks from the jaw line down.
    stache_band = (np.abs(x) < .024) & (z > ez - .046)
    cheeks = np.flatnonzero((beard_w > .5) & (z > ez - .052) & ~stache_band)
    for idx in scatter_fast(surface, cheeks, r * 0.7, rng, 800):
        snail(strands, surface[idx], n[idx], r * (.8 + .3 * rng.random()), hair_c, rng, turns=1.9)
    jaw = np.flatnonzero((beard_w > .45) & (z <= ez - .052))
    for idx in scatter_fast(surface, jaw, r * 0.6, rng, 1200):
        centre = math.exp(-(x[idx] / .022) ** 2)
        length = b['length'] * (.45 + .45 * rng.random()) * ((.35 + 1.1 * centre ** 2) if b['point'] else (.65 + .55 * centre))
        corkscrew(strands, surface[idx], n[idx] + np.array([0, .3, 0]), length, r * (.85 + .3 * rng.random()), hair_c, rng)
    # A moustache: locks from under the nose over the upper lip, sweeping out and drooping at the corners into the beard.
    for side in (-1, 1):
        for k in range(30):
            u = k / 29
            rx, rz = side * (.0010 + .0115 * u), ez - .0372 - .0032 * u + (rng.random() - .5) * .0026
            idx = int(np.argmin((x - rx) ** 2 + (z - rz) ** 2 + (y < .045) * 1.0))
            p = co[idx] + n[idx] * (.0006 + .0010 * rng.random())
            tone = .85 + .3 * rng.random()
            reach = .003 + .0045 * u + .0015 * rng.random()
            path, radii, cols = [], [], []
            for j in range(12):
                t = j / 11
                path.append(p + np.array([side * reach * t, .0012 * math.sin(t * math.pi), -.0030 * t - (.004 + .009 * u) * t * t]))
                radii.append(.0015 * (1 - .65 * t) + .0002)
                cols.append(shade(hair_c, .2 + .7 * t, .55 - .2 * t) * tone)
            strands.tube(path, radii, cols, sides=5)
    strands.emit(h, K, 'Portrait beard curls', mat)


def laurel(h, K, s):
    """A laurel wreath resting on the curls: a thin twig band with paired leaves pointing forward."""
    co = h.body_rest
    ez = h.eye_z
    yc = float(h.J['head'][1])
    leaf_m = K.material('Portrait laurel leaf', lin((.28, .42, .16)), rough=.55)
    rng = np.random.default_rng(s['seed'] + 41)
    level = ez + .030
    ring = co[np.abs(co[:, 2] - level) < .004]
    if len(ring) < 8:
        return
    rx = float(np.abs(ring[:, 0]).max()) + .0058
    front = float(ring[:, 1].max()) + .0058
    back = float(ring[:, 1].min()) - .0040
    cy = (front + back) / 2
    ry = (front - back) / 2
    verts, faces, cols = [], [], []
    for side in (-1, 1):
        for k in range(22):
            u = k / 21
            a = math.pi * .5 + side * (math.pi * .95) * (1 - u)       # from the back round to the forehead on each side
            centre = np.array([rx * math.cos(a), cy + ry * math.sin(a), level + .006 * (1 - u) - .004 * u])
            out = np.array([math.cos(a) / rx, math.sin(a) / ry, 0])
            out /= np.linalg.norm(out)
            tang = np.array([-math.sin(a) * rx, math.cos(a) * ry, 0]) * side
            tang /= np.linalg.norm(tang)
            for pair in (-1, 1):
                start = len(verts)
                length = .0115 * (.8 + .3 * rng.random())
                width = .0024
                d = tang * .92 + np.array([0, 0, pair * .36]) + out * .12
                d /= np.linalg.norm(d)
                wv = np.cross(d, out)
                wv /= np.linalg.norm(wv)
                fold = out * .0007
                outline = [(0, 0), (.18, .55), (.45, 1.0), (.75, .75), (1.0, 0), (.75, -.75), (.45, -1.0), (.18, -.55)]
                for a_, b_ in outline:
                    verts.append(tuple(centre + d * length * a_ + wv * width * b_ + fold * (1 - abs(b_))))
                verts.append(tuple(centre + d * length * .45 + fold * 1.3))
                mid = start + len(outline)
                for k_ in range(len(outline)):
                    faces.append((start + k_, start + (k_ + 1) % len(outline), mid))
                g = .80 + .35 * rng.random()
                cols += [[*np.clip(np.array(lin((.22, .36, .12))) * g, 0, 1), 1]] * (len(outline) + 1)
    v = np.array(verts)
    ob = h._mesh('Portrait laurel leaves', v, faces, leaf_m)
    gf.set_palette(ob, np.array(cols))
    h._add(ob, v, gf.rigid_head(h, len(v)))
    solid = ob.modifiers.new('leaf thickness', 'SOLIDIFY')
    solid.thickness = .0007


def brows(h, K, s):
    """Eyebrows of short tapered hairs following each brow ridge: thick at the nose, thinning out, combed outward."""
    rng = np.random.default_rng(s['seed'] + 7)
    co, n = h.body_rest, h.normals
    x, y, z = co.T
    ez = h.eye_z
    colour = s['brow_hair']['color']
    mat = K.material('Portrait brow hairs', lin(colour), rough=.7)
    strands = Strands()
    for side in (-1, 1):
        for k in range(150):
            t = rng.random() ** .85
            bx = side * (.0060 + .034 * t)
            bz = ez + .0098 + .0058 * math.sin(min(t, .78) / .78 * math.pi * .5) - .0032 * max(0, (t - .78) / .22) \
                + (rng.random() - .5) * .0036 * (1 - .65 * t)
            idx = int(np.argmin((x - bx) ** 2 + (z - bz) ** 2 + (y < .040) * 1.0))
            p = co[idx] - n[idx] * .0002
            d = np.array([side * (.8 + .2 * t), 0, .30 - .6 * t + (rng.random() - .5) * .3])
            d /= np.linalg.norm(d)
            length = .0036 * (1 - .40 * t) * (.8 + .4 * rng.random())
            d = d - n[idx] * np.dot(d, n[idx]) * .8
            d /= np.linalg.norm(d)
            path = [p + d * length * u + n[idx] * .0006 * math.sin(u * math.pi * .8) for u in (0, .33, .66, 1)]
            radii = [.00060 * (1 - .4 * t), .00050, .00036, .00014]
            tone = np.asarray(lin(colour)) * (.8 + .4 * rng.random())
            strands.tube(path, radii, [tone] * 4, sides=3)
    strands.emit(h, K, 'Portrait brow hairs', mat)


# --------------------------------------------------------------------------------------------- adapter
def headwear(h, K, alone):
    """Does this man wear a helmet, hat or crown? (`alone`: the asset has one person, so every object is his.)"""
    for ob in K.scene.objects:
        if ob.type in {'MESH', 'CURVE'} and not ob.hide_render and any(w in ob.name.lower() for w in HEADWEAR):
            if alone or ob.name.startswith(h.name):
                return True
    return False


def adapt(h, K, groom, alone=True):
    """Rebuild one man's head for the portrait: `groom` is the natural-people groom, used for the scalp when he wears
    a helmet or a hat (curls would push through it)."""
    s = spec_for(h)
    covered = headwear(h, K, alone)
    if covered:
        groom(h, K)
    kept = []
    for part in h.parts:
        name = part.ob.name.lower()
        scalp = any(t in name for t in ('strand groom', 'fitted scalp', 'scalp', 'hair', 'curl', 'braid'))
        drop = any(t in name for t in ('beard', 'stubble', 'eyebrow', 'brow', 'iris', 'pupil', 'sclera')) \
            or re.fullmatch(r'.* eye(\.\d+)?', name) or (scalp and not covered)
        if drop:
            part.ob.hide_render = True
        else:
            kept.append(part)
    h.parts = kept
    for ob in list(K.scene.objects):
        if ob.type == 'CURVE' and ob.name.startswith(h.name) and any(t in ob.name.lower() for t in ('beard lock', 'eyebrow')):
            ob.hide_render = True
    if h.name == 'Curator':
        import godot_curator_portrait
        godot_curator_portrait.adapt(__import__(__name__), h, K)
        return
    sculpt(h, s)
    beard_w = beard_zone(h)
    scalp_w = scalp_zone(h) if not covered else np.zeros(len(h.body_rest))
    colors = paint(h, s, beard_w, scalp_w)
    gf.set_palette(h.parts[0].ob, colors)
    gf.eyes(h, K, s)
    brows(h, K, s)
    if not covered:
        hair(h, K, s, scalp_w)
        if s['laurel']:
            laurel(h, K, s)
    beard(h, K, s, beard_w)
    h.godot_identity['portrait'] = dict(revision=REVISION, hair=s['hair'][1], age=s['age'], laurel=s['laurel'] and not covered,
                                        headwear=covered)
