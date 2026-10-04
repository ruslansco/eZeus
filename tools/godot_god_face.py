"""Sculpted, painted faces for the gods. Godot-only: runs inside the disposable background export.

The shared body's head is a smooth, generic base mesh and the people kit only nudges it with a few
Gaussian bumps, which is why every god looked like the same doll. Here each god gets a designed face:

  * `sculpt`   displaces the head's vertices (brow ridge, cheekbones, hollow cheeks, nose, lips, chin,
               frown, nasolabial folds) from a spec of millimetre-scale amplitudes;
  * `occlusion` bakes ambient occlusion into the vertex palette by ray casting the sculpted skin, so the
               eye sockets, nostrils, lip seam and folds stay dark after the exporter's simplifier;
  * `paint`    colours skin, lips, lids, under-eye shadow and the beard's undercoat on top of that;
  * `eyes`     real eyeballs (sclera, amber iris, pupil, limbal ring) coloured per ring, shaded by the lids;
  * `brows`, `beard`, `hairline` replace the pasted-on shells with raised brows, layered strand cards and a
               hairline cap with an irregular edge.

Nothing here touches the simulation, the native art kit or the shared body cache. Unit: 1 = 2 m, so
0.001 is 2 mm and an eyeball is 0.012 across. Local frame: facing +Y, figure's right +X, z up.
"""
import math

import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

REVISION = 'god_faces_v1'
# Objects the exporter's simplifier must keep whole (iris rings, brows, strands, the hairline edge).
PROTECTED = ('Hades eyeball', 'Hades brow hair', 'Hades beard hair', 'Hades hairline')


def g(v, c, s):
    return np.exp(-((v - c) / s) ** 2)


def smooth(v, a, b):
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def lin(rgb):
    return tuple(c ** 2.2 for c in rgb)


# --------------------------------------------------------------------------------------------- sculpt
def refresh(h):
    """Normals, nearest-vertex tree and surface tree follow the displaced head."""
    co = h.body_rest
    mesh = bpy.data.meshes.new('god face normals')
    mesh.from_pydata([tuple(v) for v in co], [], h.polys)
    mesh.update()
    n = np.empty(len(co) * 3)
    mesh.vertices.foreach_get('normal', n)
    bpy.data.meshes.remove(mesh)
    h.normals = n.reshape(-1, 3)
    h._kd = KDTree(len(co))
    for i, p in enumerate(co):
        h._kd.insert(p, i)
    h._kd.balance()
    h._bvh = BVHTree.FromPolygons([tuple(v) for v in co], h.polys)


def sculpt(h, spec):
    """Displace the head in place. Amplitudes in spec['sculpt'] are in units (0.001 = 2 mm)."""
    s = spec['sculpt']
    co = h.body_rest
    ez = h.eye_z
    x, y, z = co.T.copy()
    ax, sx = np.abs(x), np.where(x < 0, -1.0, 1.0)
    # The face: forward-looking skin between the chin and the hairline, never the neck or the skull's back.
    face = smooth(y, .04, .062) * smooth(z, ez - .068, ez - .058)
    dx = np.zeros(len(co)); dy = np.zeros(len(co)); dz = np.zeros(len(co))

    # Brow ridge: a heavy bar over the eyes that overhangs the sockets, with a dip between the brows.
    ridge = g(z, ez + .0125, .0050) * smooth(.050 - ax, 0, .020) * face
    dy += s['brow'] * ridge
    dz += .0008 * s['brow'] / .004 * ridge * smooth(ax, .004, .02)
    dy -= s['frown'] * g(x, 0, .0032) * g(z, ez + .0105, .0058) * face
    for side in (-1, 1):                      # two vertical frown lines
        dy -= .55 * s['frown'] * g(x, side * .0058, .0015) * g(z, ez + .0200, .0080) * face
    # Forehead lines, faint: the painted occlusion carries them after simplification.
    for level in (.027, .036, .045):
        dy -= s['lines'] * g(z, ez + level, .0012) * g(x, 0, .028) * face
    # Deep-set eyes: the skin around the lids is pushed forward, the lids themselves stay on the ball.
    socket = g(z, ez - .003, .0075) * g(ax, .017, .015)
    dy += s['socket'] * (g(z, ez + .0045, .0035) * g(ax, .018, .016) * face)       # heavy upper lids
    dy -= .5 * s['socket'] * socket * face
    # Cheekbones forward and out, cheeks below them hollowed and pulled in: a gaunt face.
    bone = g(ax, .036, .010) * g(z, ez - .020, .0085) * face
    dy += s['cheekbone'] * bone; dx += sx * .55 * s['cheekbone'] * bone
    hollow = g(ax, .034, .0125) * g(z, ez - .042, .0135) * face
    dy -= s['hollow'] * hollow; dx -= sx * .55 * s['hollow'] * hollow
    temple = g(ax, .041, .008) * g(z, ez + .020, .014) * face
    dx -= sx * s['temple'] * temple
    # Nose: raised bridge, longer and lower tip, narrower wings.
    dy += s['bridge'] * g(x, 0, .0048) * g(z, ez - .010, .0125) * face
    tip = g(x, 0, .0080) * g(z, ez - .0225, .0065) * face
    dy += s['tip'] * tip
    dz -= s['tip_drop'] * tip
    wings = smooth(.016 - ax, -.003, .003) * g(z, ez - .0255, .0070) * face
    dx -= sx * s['narrow'] * wings * ax / .012
    # Mouth: thin, downturned lips over a firm seam; a longer, pointed chin; folds from nose to mouth.
    seam = ez - .0485
    dy -= s['seam'] * g(x, 0, .0140) * g(z, seam, .0011) * face
    dy -= s['upper_lip'] * g(x, 0, .0125) * g(z, seam + .0045, .0030) * face
    dy += s['lower_lip'] * g(x, 0, .0100) * g(z, seam - .0055, .0030) * face
    dz -= s['downturn'] * g(ax, .0150, .0050) * g(z, seam, .0050) * face
    dy += s['chin'] * g(x, 0, .0120) * g(z, ez - .0630, .0085) * face
    dz -= s['chin_drop'] * g(x, 0, .0120) * g(z, ez - .0630, .0085) * face
    dy += s['jaw'] * g(ax, .030, .010) * g(z, ez - .068, .008) * face * .6
    for t in np.linspace(0, 1, 9):            # nasolabial fold: nostril wing to mouth corner
        fx, fz = .0125 + .0075 * t, ez - .030 - .0195 * t
        dy -= s['fold'] * .35 * g(ax, fx, .0020) * g(z, fz, .0022) * face
    co[:, 0] += dx; co[:, 1] += dy; co[:, 2] += dz
    # Ears: smaller and set closer, a little pointed.
    h.parts[0].rest[:] = co
    refresh(h)


# ------------------------------------------------------------------------------------------ occlusion
def hemisphere(count):
    """Cosine-weighted directions on the +Z hemisphere."""
    pts = []
    golden = math.pi * (3 - math.sqrt(5))
    for i in range(count):
        r = math.sqrt((i + .5) / count)
        a = i * golden
        pts.append((r * math.cos(a), r * math.sin(a), math.sqrt(max(0, 1 - r * r))))
    return pts


def occlusion(h, points, normals, rays=22, reach=.026, bias=.0005, bvh=None):
    """0 = open, 1 = buried, from the sculpted skin. `points`/`normals` are in the head's local frame."""
    bvh = bvh or h._bvh
    dirs = hemisphere(rays)
    out = np.zeros(len(points))
    for i, (p, n) in enumerate(zip(points, normals)):
        n = Vector(n)
        if n.length < 1e-6:
            continue
        n.normalize()
        up = Vector((0, 0, 1)) if abs(n.z) < .9 else Vector((1, 0, 0))
        t = n.cross(up); t.normalize()
        b = n.cross(t)
        origin = Vector(p) + n * bias
        hit = 0.0
        for dx, dy, dz in dirs:
            d = t * dx + b * dy + n * dz
            result = bvh.ray_cast(origin, d, reach)
            if result[0] is not None:
                hit += 1.0 - result[3] / reach * .55
        out[i] = hit / rays
    return out


# ------------------------------------------------------------------------------------------------ paint
def set_palette(ob, colors):
    attr = ob.data.color_attributes.get('GodotPalette') or ob.data.color_attributes.new(
        name='GodotPalette', type='FLOAT_COLOR', domain='POINT')
    attr.data.foreach_set('color', np.asarray(colors, dtype=float).ravel())


def paint(h, spec):
    """Whole-body palette: the god's skin colour with the face's anatomy painted into it."""
    p = spec['paint']
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    n = h.normals
    colors = np.tile([*spec['skin'], 1.0], (len(co), 1))
    rgb = colors[:, :3]
    head = smooth(z, ez - .085, ez - .070)
    # Gentle, low-frequency variation: the shader adds the fine grain.
    rgb *= (1 + .035 * np.sin(x * 61 + z * 47) * np.sin(z * 73 - y * 39))[:, None]

    def tint(mask, color, k):
        m = np.clip(mask * k, 0, 1)[:, None]
        rgb[:] = rgb * (1 - m) + np.asarray(color)[None] * m

    def mul(mask, color):
        rgb[:] = rgb * (1 - mask[:, None] * (1 - np.asarray(color)[None]))

    face = smooth(y, .03, .06) * head
    # Occlusion of the head, baked from the sculpted skin (the body below keeps its own shading).
    idx = np.flatnonzero(z > ez - .095)
    ao = np.zeros(len(co))
    ao[idx] = occlusion(h, co[idx], n[idx])
    cavity = np.clip((ao - .08) / .55, 0, 1) ** .9
    mul(cavity * head * p['occlusion'], (.15, .13, .22))
    # Under-eye shadow: a cool violet half moon, deeper with age.
    for side in (-1, 1):
        mul(g(x, side * .0185, .0105) * g(z, ez - .0105, .0038) * face * p['under_eye'], (.52, .50, .70))
    # Blood in the extremities: ears, nose tip and wings, a trace of colour in the cheeks.
    mul(g(z, ez - .0235, .0055) * g(x, 0, .0085) * face * .5, (.80, .70, .86))
    mul(smooth(ax, .040, .048) * g(z, ez - .006, .022) * smooth(.04, -.01, y) * .45, (.78, .66, .84))
    # Lips: dark blue-violet, a firm dark seam, the lower one a little fuller than the upper.
    seam = ez - .0485
    lips = g(x, 0, .0150) * g(z, seam, .0058) * smooth(y, .05, .07) * head
    tint(lips, p['lips'], .95)
    mul(g(x, 0, .0150) * g(z, seam, .0009) * face, (.42, .38, .50))
    # Forehead creases and crow's feet: lines a little darker than the skin, drawn where the sculpt has them.
    for level in (.027, .036, .045):
        mul(g(z, ez + level, .0011) * g(x, 0, .026) * face * .55, (.62, .60, .72))
    for side in (-1, 1):
        for k, (dx_, dz_) in enumerate(((.012, .003), (.014, 0), (.012, -.003))):
            mul(g(ax, .043 + .004 * k, .0022) * g(z, ez + dz_ * (1 - side * 0), .0016) * face * .4, (.64, .62, .74))
    # Cool and warm mottling over the whole face, so the skin is not one flat colour.
    blot = np.sin(x * 190 + z * 130) * np.sin(z * 210 - y * 150) + .5 * np.sin(x * 380 - z * 310)
    rgb *= (1 + .05 * blot * head)[:, None] * np.array([1.0, 1.0, 1.0])[None]
    # Veins at the temples: a few thin cold lines, the underworld's pallor.
    for side in (-1, 1):
        for k, (x0, z0, x1, z1) in enumerate(((.044, .034, .036, .014), (.046, .026, .039, .010), (.043, .040, .030, .028))):
            for t in np.linspace(0, 1, 12):
                vx = side * (x0 + (x1 - x0) * t + .002 * math.sin(t * 5 + k))
                vz = ez + z0 + (z1 - z0) * t
                mul(g(x, vx, .0013) * g(z, vz, .0013) * smooth(y, .0, .03) * head * .55, (.62, .70, .82))
    # Nostrils.
    for side in (-1, 1):
        mul(g(x, side * .0058, .0030) * g(z, ez - .0295, .0017) * face, (.18, .16, .22))
    # Lid margins and lashes: dark where the skin touches the eyeball.
    for e in h.A['eye_co']:
        c = np.asarray(e).mean(axis=0)
        r = float(np.linalg.norm(np.asarray(e) - c, axis=1).mean())
        d = np.linalg.norm(co - c[None], axis=1) - r
        rim = np.exp(-(np.clip(d, 0, None) / .0011) ** 2) * (y > c[1] - .004) * (d > -.002)
        upper = smooth(z - c[2], -.0015, .0030)
        mul(rim * (.55 + .45 * upper) * p['lids'], (.26, .25, .32))
    # Brow bed and the beard's undercoat (the strand cards sit over it).
    mul(brow_weight(h, spec) * face * .65, (.30, .30, .36))
    under = beard_weight(h, spec)
    tint(under, p['undercoat'], .92)
    return colors


# -------------------------------------------------------------------------------------------- features
def brow_weight(h, spec):
    """Weight of each head vertex under the eyebrows: thick and level at the nose, arched, thinning out."""
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    t = np.clip((ax - .006) / .038, 0, 1)
    centre = ez + .0128 + .0072 * np.sin(np.clip(t, 0, .78) / .78 * math.pi * .5) - .0035 * np.clip((t - .78) / .22, 0, 1)
    half = spec['brow_hair']['thick'] * (1 - .78 * t ** 1.4) * np.where(t < .02, 0, 1)
    w = np.clip(1 - np.abs(z - centre) / np.maximum(half, 1e-4), 0, 1) * (ax > .0045) * (ax < .047) * (y > .045)
    return w ** .6


def beard_weight(h, spec):
    """Where the beard grows: cheeks below the cheekbone, sideburns, the jaw to the chin and a moustache band;
    the lips stay clear."""
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    cheek = smooth(ez - .034 - z, 0, .007) * (1 - smooth(ez - .066 - z, 0, .007)) * smooth(y, .012, .030) * smooth(.050 - ax, 0, .006)
    burn = smooth(ax, .034, .038) * smooth(.051 - ax, 0, .004) * smooth(z, ez - .040, ez - .030) * smooth(ez + .003 - z, 0, .008) \
        * smooth(y, 0, .012) * smooth(.045 - y, 0, .010)
    stache = smooth(z, ez - .046, ez - .041) * smooth(ez - .030 - z, 0, .004) * smooth(.030 - ax, 0, .006) * smooth(y, .05, .066)
    w = np.maximum(cheek, stache)
    mouth = g(x, 0, .0165) * g(z, ez - .0485, .0044)
    return np.clip(w * (1 - np.clip(mouth * 2.4, 0, 1)), 0, 1)


def beard_drag(h, spec):
    """The beard hangs: below the mouth the shell is pulled down, in and forward into a chin sock."""
    b = spec['beard']
    co = h.body_rest
    x, y, z = co.T
    low = smooth(h.eye_z - .050 - z, 0, .018)
    d = np.zeros_like(co)
    d[:, 2] = -b['drop'] * low
    d[:, 0] = -x * b['taper'] * low
    d[:, 1] = b['forward'] * low
    return d


def hairline_weight(h, spec):
    """Scalp area: above a receding, widow's-peaked hairline in front, above the ears at the sides and low at the nape."""
    co = h.body_rest
    x, y, z = co.T
    ez = h.eye_z
    ax = np.abs(x)
    front = ez + .039 - .0085 * g(x, 0, .0095) + .010 * smooth(ax, .022, .040)
    back = ez - .040
    sides = ez + .006
    z_cut = np.where(y > .028, front, np.where(y > -.012, np.where(ax > .032, sides, front), back))
    z_cut = np.where(y > .0, z_cut, np.where(ax > .034, sides, back))
    return smooth(z - z_cut, -.0005, .0015) * (z > ez + .004)


def rigid_head(h, count):
    return np.repeat(h._rigid('head')[None], count, axis=0)


def thin(v, faces, colors, target):
    """Decimate a shell to about `target` vertices (the source body is 169K vertices, far more than a shell needs);
    each kept vertex takes the colour of the nearest source vertex."""
    if len(v) <= target:
        return np.asarray(v), faces, colors
    me = bpy.data.meshes.new('god face thin')
    me.from_pydata([tuple(p) for p in v], [], faces)
    me.update()
    ob = bpy.data.objects.new('god face thin', me)
    bpy.context.scene.collection.objects.link(ob)
    mod = ob.modifiers.new('thin', 'DECIMATE')
    mod.ratio = max(.005, min(1.0, target / len(v)))
    eo = ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
    out = eo.to_mesh()
    nv = np.array([tuple(p.co) for p in out.vertices])
    nf = [tuple(p.vertices) for p in out.polygons]
    eo.to_mesh_clear()
    bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.meshes.remove(me)
    tree = KDTree(len(v))
    for i, p in enumerate(v):
        tree.insert(p, i)
    tree.balance()
    nc = np.array([colors[tree.find(Vector(p))[1]] for p in nv])
    return nv, nf, nc


def shell_mesh(h, name, weight, offset, material, colors, threshold=.2, scale_offset=True, extra=None, target=1200):
    """The part of the head surface with weight above `threshold`, lifted along the normal by `offset * weight`,
    thinned to about `target` vertices."""
    co, n = h.body_rest, h.normals
    keep = weight > threshold
    faces = [f for f in h.polys if all(keep[i] for i in f)]
    if not faces:
        return None
    used = sorted({i for f in faces for i in f})
    remap = {old: new for new, old in enumerate(used)}
    lift = offset * (weight[used] if scale_offset else 1.0)
    v = co[used] + n[used] * (np.asarray(lift)[:, None] if np.ndim(lift) else lift)
    if extra is not None:
        v = v + extra[used]
    faces = [tuple(remap[i] for i in f) for f in faces]
    v, faces, c = thin(v, faces, colors[used], target)
    ob = h._mesh(name, v, faces, material)
    set_palette(ob, c)
    h._add(ob, v, rigid_head(h, len(v)))
    return ob


def brows(h, K, spec):
    b = spec['brow_hair']
    mat = K.material('Hades brow hair', lin(b['color']), rough=.7)
    w = brow_weight(h, spec)
    co = h.body_rest
    x, z = co[:, 0], co[:, 2]
    grain = 1 + .16 * np.sin(x * 1100 + z * 260) + .08 * np.sin(x * 2300 - z * 540)
    colors = np.zeros((len(co), 4)); colors[:, 3] = 1
    colors[:, :3] = np.asarray(lin(b['color']))[None] * grain[:, None]
    return shell_mesh(h, 'Hades brow hair', w, b['lift'], mat, colors, threshold=.12, target=320)


def hairline(h, K, spec):
    flame = K.material('Hades hairline cap', lin((.35, .02, .004)), rough=.5)
    w = hairline_weight(h, spec)
    colors = np.zeros((len(h.body_rest), 4)); colors[:, 3] = 1
    z = h.body_rest[:, 2]
    top = np.clip((z - (h.eye_z + .036)) / .028, 0, 1)
    colors[:, :3] = (np.array([.06, .003, .002])[None] * (1 - top[:, None]) + np.array([.42, .05, .005])[None] * top[:, None])
    return shell_mesh(h, 'Hades hairline scalp', w, .0042, flame, colors, threshold=.35, scale_offset=False, target=1000)


def beard(h, K, spec):
    """A shell over the jaw with a dragged chin sock, strand cards for its fringe, a moustache of cards."""
    b = spec['beard']
    rng = np.random.default_rng(b['seed'])
    co, n = h.body_rest, h.normals
    ez = h.eye_z
    x, y, z = co.T
    w = beard_weight(h, spec)
    drag = beard_drag(h, spec)
    mat = K.material('Hades beard hair', lin(b['tip']), rough=.7)
    # Shell colours: dark at the roots, silver toward the tip, vertical streaks like combed strands.
    t = np.clip((ez - .040 - z) / .050, 0, 1)
    streak = 1 + .20 * np.sin(x * 760 + np.sin(z * 90) * 1.5) + .10 * np.sin(x * 1710)
    shell = np.zeros((len(co), 4)); shell[:, 3] = 1
    for c in range(3):
        shell[:, c] = (b['root'][c] * (1 - t) + b['tip'][c] * t) * streak
    shell[:, :3] = np.array([lin(tuple(np.clip(row, 0, 1))) for row in shell[:, :3]])
    ob = shell_mesh(h, 'Hades beard hair shell', w, b['lift'], mat, shell, threshold=.30, extra=drag, target=1500)
    # Cards: roots on the dragged shell, hanging and gathering toward the chin; the moustache sweeps out.
    surface = co + n * (b['lift'] * w)[:, None] + drag
    verts, faces, colors = [], [], []

    def card(root, length, width, lean_x, lean_y, tint, drop=1.0):
        """A tapering ribbon with a slow S curve, turned about the vertical so it shows its width from the side too."""
        start = len(verts)
        turn = (rng.random() - .5) * 2.1
        tangent = np.array([math.cos(turn), math.sin(turn), 0.0])
        sway = (rng.random() - .5) * .35 * length
        for j in range(5):
            u = j / 4
            pos = root + np.array([lean_x * length * u + sway * math.sin(u * math.pi * 1.4), lean_y * length * u * u,
                                   -length * u * drop])
            half = width * (1 - u) ** .85 + .0004
            for side in (-1, 1):
                verts.append(tuple(pos + tangent * side * half))
                k = np.clip(np.array(b['root']) * (1 - u) + np.array(b['tip']) * u * tint, 0, 1)
                colors.append([*lin(tuple(k)), 1])
        for j in range(4):
            a_ = start + 2 * j
            faces.append((a_, a_ + 1, a_ + 3, a_ + 2))

    low = np.flatnonzero((w > .5) & (z < ez - .050))
    for idx in rng.choice(low, min(b['cards'], len(low)), replace=False):
        length = b['length'] * (.55 + .75 * rng.random()) * (1 + b['chin_extra'] * g(x[idx], 0, .02))
        card(surface[idx], length, b['width'] * (.7 + .6 * rng.random()), -np.sign(x[idx]) * .25 * rng.random(),
             .25 * rng.random(), .85 + .3 * rng.random())
    mous = np.flatnonzero((w > .4) & (z > ez - .046) & (z < ez - .030) & (np.abs(x) < .029) & (y > .05))
    for idx in rng.choice(mous, min(b['stache_cards'], len(mous)), replace=False):
        card(surface[idx], b['stache'] * (.7 + .6 * rng.random()), b['width'] * .8, np.sign(x[idx]) * .55, .05, .8, drop=.45)
    v = np.array(verts)
    mesh = h._mesh('Hades beard hair cards', v, faces, mat)
    set_palette(mesh, np.array(colors))
    h._add(mesh, v, rigid_head(h, len(v)))
    return ob, mesh


# ------------------------------------------------------------------------------------------------ eyes
def eyes(h, K, spec):
    """Eyeball, iris, pupil and limbal ring on one mesh per eye, rings sharp enough to survive as colour."""
    e = spec['eyes']
    mat = K.material('Hades eyeball', lin(e['sclera']), rough=.16)
    # Colour rings by angle from the gaze axis (+Y): (start angle, colour at that angle) -> sharp bands.
    pupil_a = math.asin(e['pupil'] / .006)
    iris_a = math.asin(e['iris'] / .006)
    bands = [(0, e['pupil_colour']), (pupil_a, e['pupil_colour']),
             (pupil_a * 1.02, e['iris_inner']), (pupil_a + (iris_a - pupil_a) * .35, e['iris_mid']),
             (iris_a * .86, e['iris_outer']), (iris_a * .98, e['limbus']), (iris_a * 1.12, e['limbus']),
             (iris_a * 1.28, e['sclera']), (math.pi, e['sclera'])]

    def ring_color(a):
        for (a0, c0), (a1, c1) in zip(bands, bands[1:]):
            if a0 <= a <= a1:
                t = 0 if a1 == a0 else (a - a0) / (a1 - a0)
                return np.asarray(c0) * (1 - t) + np.asarray(c1) * t
        return np.asarray(bands[-1][1])

    angles = sorted(set([0, pupil_a * .5, pupil_a, pupil_a * 1.02, pupil_a + (iris_a - pupil_a) * .35, iris_a * .86,
                         iris_a * .98, iris_a * 1.12, iris_a * 1.28, .75, 1.0, 1.35, 1.75, 2.1, 2.5, 2.9, math.pi]))
    segs = 32
    skin_bvh = h._bvh
    made = []
    for source in h.A['eye_co']:
        centre = np.asarray(source).mean(axis=0)
        radius = float(np.linalg.norm(np.asarray(source) - centre, axis=1).mean()) * e.get('scale', 1.0)
        verts, cols, faces = [], [], []
        for a in angles:
            for k in range(segs if 0 < a < math.pi else 1):
                b = math.tau * k / segs
                d = np.array([math.sin(a) * math.cos(b), math.cos(a), math.sin(a) * math.sin(b)])
                bulge = 1 + e['cornea'] * smooth(iris_a * 1.05 - a, 0, iris_a * .9)
                verts.append(centre + d * radius * bulge)
                cols.append(ring_color(a))
        rows = []
        pos = 0
        for a in angles:
            n_ = segs if 0 < a < math.pi else 1
            rows.append(list(range(pos, pos + n_)))
            pos += n_
        for r0, r1 in zip(rows, rows[1:]):
            if len(r0) == 1:
                faces += [(r0[0], r1[(k + 1) % segs], r1[k]) for k in range(segs)]
            elif len(r1) == 1:
                faces += [(r0[k], r0[(k + 1) % segs], r1[0]) for k in range(segs)]
            else:
                faces += [(r0[k], r0[(k + 1) % segs], r1[(k + 1) % segs], r1[k]) for k in range(segs)]
        v = np.array(verts)
        cols = np.array(cols)
        # The lids shade the ball: occlusion from the sculpted skin, rays leaving the ball's surface.
        nrm = (v - centre)
        nrm /= np.linalg.norm(nrm, axis=1, keepdims=True)
        ao = occlusion(h, v, nrm, rays=16, reach=.012, bias=.0003, bvh=skin_bvh)
        shade = 1 - np.clip(ao * e['lid_shade'], 0, .92)
        rgb = np.array([lin(tuple(c)) for c in cols]) * shade[:, None]
        palette = np.concatenate([rgb, np.ones((len(v), 1))], axis=1)
        ob = h._mesh('Hades eyeball', v, faces, mat)
        set_palette(ob, palette)
        h._add(ob, v, rigid_head(h, len(v)))
        made.append(ob)
    return made


# ---------------------------------------------------------------------------------------------- specs
HADES = dict(
    skin=lin((.43, .56, .66)),
    sculpt=dict(brow=.0046, frown=.0020, lines=.0004, socket=.0014, cheekbone=.0030, hollow=.0036, temple=.0016,
                bridge=.0030, tip=.0028, tip_drop=.0030, narrow=.0012, seam=.0011, upper_lip=.0010, lower_lip=.0013,
                downturn=.0025, chin=.0046, chin_drop=.0034, jaw=.0020, fold=.0034),
    paint=dict(occlusion=.95, under_eye=.80, lids=.9, lips=lin((.30, .32, .48)), undercoat=lin((.10, .11, .13))),
    brow_hair=dict(color=(.30, .31, .35), thick=.0029, lift=.0014),
    beard=dict(seed=61303, lift=.0050, drop=.019, taper=.30, forward=.007, cards=70, stache_cards=24, length=.021,
               chin_extra=.40, stache=.012, width=.0056, root=(.50, .51, .55), tip=(.70, .72, .76)),
    eyes=dict(sclera=(.78, .80, .80), pupil=.0016, iris=.0034, cornea=.045, lid_shade=.9,
              pupil_colour=(.02, .02, .03), iris_inner=(.62, .26, .02), iris_mid=(.95, .50, .05),
              iris_outer=(.62, .27, .03), limbus=(.08, .05, .03)),
)
SPECS = {'Hades': HADES}
