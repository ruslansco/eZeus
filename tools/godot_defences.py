"""Godot-only city defences in white marble (6 October 2026): the 16 wall pieces, the 2x2 tower and the 5x2 gatehouse.

blender -b --factory-startup --python-exit-code 1 -P eZeus/tools/godot_defences.py -- --piece wall --mask 10 [--preview out.png]
blender ... -- --piece tower | --piece gatehouse

After the original game's sprites (DATA gatehouseAndTower, wall): white marble ashlar laid in courses of slightly different
whites, a restrained blue frieze with a red Greek key under a projecting cornice, crenellations. The gatehouse is a Greek propylon fit for
Olympus: two marble pylons fronted by paired Ionic columns around carved marble laurel panels, each crowned by a pediment with a gilded disc
and gilded acroteria, and between them a portal of Ionic columns under its own pediment, bronze doors standing open.

The walls are taller than the SDL pieces (walk 2.0 tiles instead of .80), so they are built here and not in art/walls, whose
sprites bake the SDL archers' height. Godot lifts its archers to WALL_WALK / TOWER_PLATFORM (scripts/defence_perch.gd keeps
the same numbers). Model axes: +X/+Y are tile x/y; a wall's mask bits are 1 x-1, 2 x+1, 4 y-1, 8 y+1; the gatehouse's passage
runs along +Y between pylons at x = +-1.5. Geometry only, no random numbers; nothing is written to art/.
"""
import json
import math
import sys
import tempfile
from pathlib import Path

from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'art/_kit'))
import ezkit as K  # noqa: E402
import roman as R  # noqa: E402

ART = json.loads((ROOT / 'eZeus/godot/data/defence_art.json').read_text())
REVISION = ART['revision']
WALL_WALK = ART['wall_walk']
TOWER_PLATFORM = ART['tower_platform']

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
PIECE = argv[argv.index('--piece') + 1] if '--piece' in argv else 'wall'
MASK = int(argv[argv.index('--mask') + 1]) if '--mask' in argv else 3
PREVIEW = argv[argv.index('--preview') + 1] if '--preview' in argv else None

K.setup({'wall': f'wall_{MASK}', 'tower': 'tower', 'gatehouse': 'gatehouse', 'scene': 'defences'}[PIECE], {'wall': 1, 'tower': 2, 'gatehouse': 3, 'scene': 6}[PIECE],
        seed=61, out_dir=Path(tempfile.gettempdir()) / 'godot_defences', exposure=.28, world_strength=.8, fill_energy=190)
M = R.mats(K)
WHITES = [K.material('Pentelic marble course %d' % i, c, rough=.34, noise=.04, scale=20, bump=.04)
          for i, c in enumerate([(.89, .89, .86), (.82, .84, .82), (.94, .94, .91), (.87, .88, .85)])]
PLINTH = K.material('Marble plinth', (.73, .76, .73), rough=.45, noise=.05, scale=20)
JOINT = K.material('Ashlar joint', (.55, .58, .57), rough=.8)
BLUE = K.material('Aegean blue frieze', (.05, .13, .40), rough=.5)
RED = K.material('Cinnabar key', (.55, .07, .04), rough=.5)
PANEL = K.material('Cinnabar panel', (.46, .06, .04), rough=.55)
BLACK = K.material('Black band', (.05, .05, .07), rough=.6)
SHADOW = K.material('Arrow recess', (.02, .02, .025), rough=.9)


def batches(name):
    B = R.Batches(name)
    for i, m in enumerate(WHITES):
        B.mat(f'w{i}', m, smooth=True)
    for key, m in [('plinth', PLINTH), ('joint', JOINT), ('blue', BLUE), ('red', RED), ('panel', PANEL), ('black', BLACK),
                   ('shadow', SHADOW)]:
        B.mat(key, m)
    return B


def run_x(B, key, x0, x1, y, z, depth, height):
    """A box along x from x0 to x1."""
    B[key].box(((x0 + x1) / 2, y, z), (x1 - x0, depth, height))


def segment(a, b, width):
    """Centre and size of a box from 2D point a to b (axis aligned) of the given width."""
    c = (a + b) / 2
    along_x = abs(b.x - a.x) > abs(b.y - a.y)
    length = abs(b.x - a.x) if along_x else abs(b.y - a.y)
    return c, along_x, length


def ashlar(B, a, b, width, z0, z1, courses, seed):
    """Coursed marble between 2D points a and b: each course two blocks of different whites, a joint line between courses."""
    c, along_x, length = segment(a, b, width)
    h = (z1 - z0) / courses
    for k in range(courses):
        z = z0 + h * (k + .5)
        split = .35 + .3 * ((seed * 7 + k * 5) % 10) / 10
        for part, (u0, u1) in enumerate([(0, split), (split, 1)]):
            p = a.lerp(b, (u0 + u1) / 2)
            l = length * (u1 - u0)
            key = f'w{(seed + k * 3 + part) % 4}'
            B[key].box((p.x, p.y, z), (l + .001, width, h - .006) if along_x else (width, l + .001, h - .006))
        if k:
            B['joint'].box((c.x, c.y, z0 + h * k), (length, width - .004, .008) if along_x else (width - .004, length, .008))


def key_band(B, a, b, width, z, height, outward):
    """A blue frieze with a red Greek key on the faces either side of the line a-b (outward: list of 2D normals)."""
    c, along_x, length = segment(a, b, width)
    B['blue'].box((c.x, c.y, z), (length, width + .012, height) if along_x else (width + .012, length, height))
    n = max(1, int(length / .14))
    for normal in outward:
        face = normal * (width / 2 + .008)
        for i in range(n):
            p = a.lerp(b, (i + .5) / n) + face
            unit = length / n
            t = Vector((1, 0)) if along_x else Vector((0, 1))
            # a key: the vertical stroke, the top bar running on, and the hook coming back down
            for (du, dz, w, hgt) in [(-.30, 0, .16, .72), (.0, .30, .76, .16), (.30, .08, .16, .56), (.12, -.14, .36, .16)]:
                q = p + t * (du * unit)
                B['red'].box((q.x, q.y, z + dz * height), ((w * unit, .006, hgt * height) if along_x else (.006, w * unit, hgt * height)))
    return z + height / 2


def merlons(B, a, b, z, spacing=.25, size=(.15, .09, .22)):
    """Merlons along a line (2D points), every other slot."""
    c, along_x, length = segment(a, b, 0)
    n = max(1, int(round(length / spacing)))
    for i in range(n):
        if i % 2:
            continue
        p = a.lerp(b, (i + .5) / n)
        sx, sy, sz = (size[0], size[1], size[2]) if along_x else (size[1], size[0], size[2])
        B['w2'].box((p.x, p.y, z + sz / 2), (sx, sy, sz))
        B['w0'].box((p.x, p.y, z + sz + .01), (sx + .02, sy + .02, .02))


# ------------------------------------------------------------------ walls
WT, PW = .58, .68          # curtain thickness, pier width
DIRS = {1: Vector((-1, 0)), 2: Vector((1, 0)), 4: Vector((0, -1)), 8: Vector((0, 1))}


def wall(mask):
    B = batches(f'Wall {mask}')
    arms = [d for bit, d in DIRS.items() if mask & bit]
    straight = len(arms) == 2 and (arms[0] + arms[1]).length < 1e-6
    O = Vector((0, 0))
    lines = []                                           # (a, b, width, outward normals)
    if straight:
        a, b = arms[0] * .5, arms[1] * .5
        n = Vector((-arms[0].y, arms[0].x))
        lines.append((a, b, WT, [n, -n]))
    else:
        for d in arms:
            n = Vector((-d.y, d.x))
            lines.append((d * (PW / 2), d * .5, WT, [n, -n]))
    top = WALL_WALK
    for a, b, w, normals in lines:
        c, along_x, length = segment(a, b, w)
        B['plinth'].box((c.x, c.y, .05), (length + .001, w + .08, .10) if along_x else (w + .08, length + .001, .10))
        ashlar(B, a, b, w, .10, top - .26, 6, int(abs(a.x * 10) + abs(a.y * 20) + mask))
        key_band(B, a, b, w, top - .20, .12, normals)
        B['w2'].box((c.x, c.y, top - .07), (length, w + .10, .06) if along_x else (w + .10, length, .06))   # cornice
        B['w0'].box((c.x, c.y, top - .02), (length, w + .04, .04) if along_x else (w + .04, length, .04))   # walk paving
        for nrm in normals:                                                                             # crenellations
            off = nrm * (w / 2 - .015)
            merlons(B, a + off, b + off, top)
    if not straight:
        ph = top                                   # the pier, a little taller, where the wall ends, turns or branches
        free = [Vector((-1, 0)), Vector((1, 0)), Vector((0, -1)), Vector((0, 1))]
        B['plinth'].box((0, 0, .05), (PW + .1, PW + .1, .10))
        ashlar(B, Vector((-PW / 2, 0)), Vector((PW / 2, 0)), PW, .10, top - .26, 6, mask)
        B['blue'].box((0, 0, top - .20), (PW + .012, PW + .012, .12))
        for d in free:
            if any((d - a_).length < 1e-6 for a_ in arms):
                continue
            n = Vector((-d.y, d.x))
            key_band(B, d * (PW / 2) - n * PW / 2, d * (PW / 2) + n * PW / 2, .002, top - .20, .12, [d])
        B['w2'].box((0, 0, ph - .07), (PW + .12, PW + .12, .06))
        B['w0'].box((0, 0, ph - .02), (PW + .05, PW + .05, .04))
        for d in free:
            if any((d - a_).length < 1e-6 for a_ in arms):
                continue
            n = Vector((-d.y, d.x))
            e = d * (PW / 2 - .02)
            merlons(B, e - n * PW / 2, e + n * PW / 2, ph, spacing=.19)
    B.done()


# ------------------------------------------------------------------ tower
def frustum(B, key, half0, half1, z0, z1):
    vs = [(sx * half0, sy * half0, z0) for sx, sy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]] + \
         [(sx * half1, sy * half1, z1) for sx, sy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]
    fs = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    B[key].poly(vs, fs)


def square_ring(half):
    return [Vector((-half, -half)), Vector((half, -half)), Vector((half, half)), Vector((-half, half))]


def tower_body(B, cx, cy, half, z0, z1, courses, seed):
    """Ashlar on the four faces of a square shaft (a box per course, two whites per face via the course seed)."""
    h = (z1 - z0) / courses
    for k in range(courses):
        z = z0 + h * (k + .5)
        B[f'w{(seed + k) % 4}'].box((cx, cy, z), (2 * half, 2 * half, h - .008))
        if k:
            B['joint'].box((cx, cy, z0 + h * k), (2 * half - .004, 2 * half - .004, .010))
        # a vertical joint on each face, staggered course by course
        for face in [Vector((1, 0)), Vector((-1, 0)), Vector((0, 1)), Vector((0, -1))]:
            side = Vector((-face.y, face.x))
            p = Vector((cx, cy)) + face * (half + .002) + side * (half * (.35 if k % 2 else -.25))
            B['joint'].box((p.x, p.y, z), (.006, .012, h) if face.x else (.012, .006, h))


def tower():
    B = batches('Tower')
    H0, H1 = .96, .86                       # half widths: battered foot, shaft
    for i in range(4):                      # paving under the footprint
        for j in range(4):
            B['plinth'].box((-.75 + .5 * i, -.75 + .5 * j, .01), (.494, .494, .02))
    frustum(B, 'w1', H0, H0 - .02, .02, .14)
    frustum(B, 'w0', H0 - .02, H1 + .02, .14, .62)                      # battered foot
    B['joint'].box((0, 0, .38), (2 * H1 + .12, 2 * H1 + .12, .01))
    B['w2'].box((0, 0, .68), (2 * H1 + .07, 2 * H1 + .07, .10))
    B['blue'].box((0, 0, .755), (2 * H1 + .035, 2 * H1 + .035, .025))
    B['w2'].box((0, 0, .80), (2 * H1 + .07, 2 * H1 + .07, .04))
    tower_body(B, 0, 0, H1, .82, TOWER_PLATFORM - .34, 9, 1)
    for x in (-H1 + .045, H1 - .045):
        for y in (-H1 + .045, H1 - .045):
            B['w2'].box((x, y, 1.73), (.12, .12, 1.78))
            B['w0'].box((x, y, 2.65), (.17, .17, .08))
    for face in [Vector((1, 0)), Vector((-1, 0)), Vector((0, 1)), Vector((0, -1))]:              # arrow slits
        side = Vector((-face.y, face.x))
        for u in (-.32, .32):
            p = face * (H1 + .004) + side * u
            B['shadow'].box((p.x, p.y, 1.94), (.008, .07, .38) if face.x else (.07, .008, .38))
            B['w2'].box((p.x, p.y, 1.73), (.02, .14, .03) if face.x else (.14, .02, .03))
    ring = square_ring(H1)
    for k in range(4):
        a, b = ring[k], ring[(k + 1) % 4]
        normal = Vector(((b - a).y, -(b - a).x)).normalized()
        key_band(B, a, b, .002, TOWER_PLATFORM - .27, .14, [normal])
    B['blue'].box((0, 0, TOWER_PLATFORM - .27), (2 * H1 + .01, 2 * H1 + .01, .14))
    for k in range(10):                                                    # corbels under the cornice
        for face in [Vector((1, 0)), Vector((-1, 0)), Vector((0, 1)), Vector((0, -1))]:
            side = Vector((-face.y, face.x))
            p = face * (H1 + .04) + side * (-H1 + (k + .5) * 2 * H1 / 10)
            B['w3'].box((p.x, p.y, TOWER_PLATFORM - .15), (.06, .06, .06))
    B['w2'].box((0, 0, TOWER_PLATFORM - .08), (2 * H1 + .18, 2 * H1 + .18, .08))     # cornice
    B['w0'].box((0, 0, TOWER_PLATFORM - .02), (2 * H1 + .12, 2 * H1 + .12, .04))     # platform paving
    edge = H1 + .03
    for k in range(4):
        a, b = square_ring(edge)[k], square_ring(edge)[(k + 1) % 4]
        merlons(B, a, b, TOWER_PLATFORM, spacing=.27, size=(.18, .12, .25))
    B.done()


# ------------------------------------------------------------------ gatehouse
def wreath(B, x, y, z, normal):
    # Original low-relief laurel carving; white leaves catch the light above the panel.
    for side in (-1, 1):
        for k in range(7):
            angle = -.9 + k * .24
            px = x + side * .21 * math.cos(angle)
            pz = z + .27 * math.sin(angle)
            B['w0'].ico((px, y + normal * .012, pz), (.057, .023, .035), 1)
    B['w1'].cyl((x, y, z), .13, .035, 16, rx=math.pi / 2)
    for dx, dz, w, h in [(-.045, .045, .08, .024), (.015, 0, .08, .024), (-.025, -.045, .08, .024)]:
        B['gold'].box((x + dx, y + normal * .027, z + dz), (w, .012, h))


def ionic(B, x, y, z, h, r):
    # Low-cost fluted shaft and two scrolls facing the front/back of the gate.
    B['w1'].box((x, y, z + .045), (r * 2.8, r * 2.8, .09))
    B['w0'].lathe((x, y, z + .09), [(r * 1.25, 0), (r * 1.3, .025), (r, .065)], 16)
    shaft = h - .24
    B['w2'].lathe((x, y, z + .15), [(r, 0), (r * 1.02, shaft * .35), (r * .88, shaft)], 24)
    for k in range(12):
        angle = k * math.tau / 12
        B['w0'].cyl((x + r * .90 * math.cos(angle), y + r * .90 * math.sin(angle), z + .15 + shaft / 2), r * .075, shaft, 5)
    zc = z + h - .09
    B['w0'].box((x, y, zc), (r * 2.8, r * 2.3, .09))
    for side in (-1, 1):
        B['w0'].cyl((x + side * r, y, zc - .018), r * .46, r * 2.4, 12, rx=math.pi / 2)
    B['w2'].box((x, y, z + h - .015), (r * 3.0, r * 2.6, .03))


def pediment(B, x0, x1, y0, y1, z, rise, ridge_along_y=True):
    """A gabled roof over x0..x1 x y0..y1 with its triangular fronts toward -Y and +Y: blue tympanum, marble frame, gilded disc
    and acroteria. Returns nothing."""
    cx, w = (x0 + x1) / 2, x1 - x0
    for yy, nrm in [(y0, -1), (y1, 1)]:
        tri = [(x0, z), (x1, z), (cx, z + rise)]
        vs = [(px, yy + nrm * .001, pz) for px, pz in tri] + [(px, yy - nrm * .05, pz) for px, pz in tri]
        B['blue'].poly(vs, [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)])
        # raking cornices
        slope = math.atan2(rise, w / 2)
        length = math.hypot(w / 2, rise) + .06
        for s in (-1, 1):
            B['w2'].box((cx + s * w / 4, yy + nrm * .01, z + rise / 2 + .025), (length, .08, .05), ry=s * slope)
        B['w2'].box((cx, yy + nrm * .01, z + .025), (w + .06, .08, .05))
        B['gold'].cyl((cx, yy + nrm * .012, z + rise * .42), rise * .26, .02, 24, rx=math.pi / 2)        # gilded disc
        B['gold'].cyl((cx, yy + nrm * .022, z + rise * .42), rise * .13, .02, 16, rx=math.pi / 2)
        B['gold'].ico((cx, yy, z + rise + .07), (.05, .025, .08), 1)                                    # acroteria
        for s in (-1, 1):
            B['gold'].ico((cx + s * w / 2, yy, z + .07), (.04, .02, .06), 1)
    # the roof itself: two sloping slabs of marble tiles from front to back
    slope = math.atan2(rise, w / 2)
    length = math.hypot(w / 2, rise)
    for s in (-1, 1):
        B['w3'].box((cx + s * w / 4, (y0 + y1) / 2, z + rise / 2 + .03), (length + .03, y1 - y0 + .04, .05), ry=s * slope)


def pylon(B, cx, seed):
    half_x, half_y = .92, .90
    top = 3.10
    B['plinth'].box((cx, 0, .06), (2 * half_x + .1, 2 * half_y + .1, .12))
    B['w1'].box((cx, 0, .17), (2 * half_x + .04, 2 * half_y + .04, .10))
    # ashlar body
    h = (top - .32 - .22) / 6
    for k in range(6):
        z = .22 + h * (k + .5)
        B[f'w{(seed + k) % 4}'].box((cx, 0, z), (2 * half_x, 2 * half_y, h - .008))
        if k:
            B['joint'].box((cx, 0, .22 + h * k), (2 * half_x - .004, 2 * half_y - .004, .010))
    # blue frieze with red keys on all four faces, cornice
    zf = top - .26
    B['blue'].box((cx, 0, zf), (2 * half_x + .012, 2 * half_y + .012, .14))
    corners = [Vector((cx - half_x, -half_y)), Vector((cx + half_x, -half_y)), Vector((cx + half_x, half_y)), Vector((cx - half_x, half_y))]
    for k in range(4):
        a, b = corners[k], corners[(k + 1) % 4]
        normal = Vector(((b - a).y, -(b - a).x)).normalized()
        key_band(B, a, b, .002, zf, .14, [normal])
    B['w2'].box((cx, 0, top - .14), (2 * half_x + .16, 2 * half_y + .16, .10))
    B['w0'].box((cx, 0, top - .06), (2 * half_x + .08, 2 * half_y + .08, .06))
    # the front and back: paired Ionic columns around a framed cinnabar panel, an architrave over them
    for y, n in [(-half_y, -1), (half_y, 1)]:
        for u in (-.58, .58):
            ionic(B, cx + u, y + n * .09, .22, 2.46, .11)
        B['w1'].box((cx, y + n * .012, 1.50), (.76, .045, 1.95))                       # panel frame
        B['w2'].box((cx, y + n * .035, 1.50), (.62, .04, 1.79))
        wreath(B, cx, y + n * .075, 1.65, n)                     # cinnabar panel
        B['w0'].box((cx, y + n * .065, .74), (.42, .014, .05))                     # gilded fillets
        B['w0'].box((cx, y + n * .065, 2.26), (.42, .014, .05))
        B['w2'].box((cx, y + n * .07, 2.76), (1.57, .20, .10))                         # architrave over the columns
    pediment(B, cx - half_x - .04, cx + half_x + .04, -half_y - .04, half_y + .04, top - .03, .42)


def gatehouse():
    B = batches('Gatehouse')
    for i in range(10):                                                             # paving under both pylons
        for j in range(4):
            x = -2.25 + .5 * i
            if abs(x) < .5:
                continue
            B['plinth'].box((x, -.75 + .5 * j, .01), (.494, .494, .02))
    pylon(B, -1.5, 0)
    pylon(B, 1.5, 2)
    # the portal: Ionic columns at the front and back of the passage, an entablature and a pediment across them
    half_y = .90
    for y, n in [(-half_y, -1), (half_y, 1)]:
        for x in (-.64, .64):
            ionic(B, x, y + n * .06, 0, 2.30, .09)
        B['w1'].box((0, y + n * .06, 2.36), (1.55, .22, .10))                         # architrave
        key_band(B, Vector((-.78, y + n * .06)), Vector((.78, y + n * .06)), .22, 2.47, .12, [Vector((0, n))])
        B['w2'].box((0, y + n * .06, 2.57), (1.68, .30, .08))                         # cornice
    B['w0'].box((0, 0, 2.48), (1.16, 2 * half_y, .22))                                 # the passage's lintel block
    for k in range(4):                                                              # coffered ceiling over the road
        B['joint'].box((0, -.7 + k * .47, 2.365), (1.0, .05, .01))
    pediment(B, -.89, .89, -half_y - .12, half_y + .12, 2.61, .36)
    # bronze doors standing open against the passage walls
    for s in (-1, 1):
        B['gold_dim'].box((s * .55, -.45, .90), (.03, .46, 1.76))
        for z in (.40, .90, 1.40):
            B['gold'].box((s * .535, -.45, z), (.006, .40, .03))
    B.done()


def scene():
    """Preview only: the gatehouse with walls running out to a tower and round a corner."""
    def at(fn, x, y):
        before = set(K.root.children)
        fn()
        for ob in set(K.root.children) - before:
            ob.location.x += x
            ob.location.y += y
    at(gatehouse, 0, 0)
    for x in (3, 4, 5):
        at(lambda: wall(3), x, 0)
        at(lambda: wall(3), -x, 0)
    at(tower, 6.5, .5)
    at(lambda: wall(6), -6, 0)
    for y in (1, 2):
        at(lambda: wall(12), -6, y)


{'wall': lambda: wall(MASK), 'tower': tower, 'gatehouse': gatehouse, 'scene': scene}[PIECE]()
if PREVIEW and __name__ == '__main__':
    import bpy
    K.scene.camera.data.ortho_scale *= {'wall': 1.6, 'tower': 1.3, 'gatehouse': 1.0, 'scene': 1.0}[PIECE]
    K.render(Path(PREVIEW), 900, 32)
