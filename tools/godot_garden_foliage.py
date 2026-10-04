"""Original procedural garden foliage for the Godot presentation (revision 1).

Executed only inside a disposable background Blender export. Native sprite recipes
and the live Blender scene are untouched. All dimensions use native tile units.
Leaves are opaque folded geometry, with back faces, so they need no alpha sorting.
"""
import ast
import math
import random
from mathutils import Vector

ASSETS = {
    'deco_fish_pond', 'deco_topiary', 'deco_hedge_maze', 'park',
    'deco_shell_garden', 'deco_sundial', 'deco_dolphin', 'deco_orrery',
}
REVISION = 1
FOOTPRINTS = {'park':1, 'deco_fish_pond':4, 'deco_topiary':3, 'deco_hedge_maze':3,
              'deco_shell_garden':2, 'deco_sundial':2, 'deco_dolphin':3, 'deco_orrery':3}
BUDGETS = {'park':16000, 'deco_fish_pond':85000, 'deco_topiary':50000,
           'deco_hedge_maze':120000, 'deco_shell_garden':35000, 'deco_sundial':35000,
           'deco_dolphin':45000, 'deco_orrery':45000}
K = R = None
PALETTE = [(.085, .17, .075), (.12, .235, .10), (.18, .29, .12),
           (.23, .34, .16), (.155, .265, .155), (.28, .37, .20)]


def batches(B):
    if 'garden_leaf_0' not in B.b:
        for i, colour in enumerate(PALETTE):
            B.mat('garden_leaf_%d' % i, K.material('Garden Leaf %d' % i, colour, rough=.84))
        B.mat('garden_core', K.material('Garden Core', (.075, .145, .065), rough=.95), smooth=True)
        B.mat('garden_bark', K.material('Garden Bark', (.23, .17, .115), rough=.94), smooth=True)
    return B


def leaf(B, center, length, width, rng, normal=None, ivy=False):
    """A bent blade with a midrib; broad pointed ivy differs from box leaves."""
    batches(B)
    normal = Vector(normal or (rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(.15, 1))).normalized()
    u = normal.cross(Vector((0, 0, 1)) if abs(normal.z) < .9 else Vector((0, 1, 0))).normalized()
    v = normal.cross(u).normalized()
    angle = rng.uniform(0, math.tau)
    axis = u * math.cos(angle) + v * math.sin(angle)
    across = normal.cross(axis)
    c = Vector(center)
    points = [c - axis * length * .5, c - across * width * .5,
              c + axis * length * .5, c + across * width * .5,
              c + normal * width * .12]
    if ivy:
        # Two lobes give vines a recognizable broad leaf, rather than pancakes.
        points[1] += axis * length * .13
        points[3] += axis * length * .13
    shade = rng.choices(range(6), weights=[1, 3, 4, 2, 3, 1])[0]
    batch = B.b['garden_leaf_%d' % shade]
    verts = [batch.bm.verts.new(p) for p in points]
    for i in range(4):
        face = (verts[i], verts[(i + 1) % 4], verts[4])
        batch.bm.faces.new(face)
        # Export materials are double-sided; no duplicate back-face geometry.


def rod(B, a, b, radius):
    batches(B)
    R._rod(B, 'garden_bark', Vector(a), Vector(b), radius, 7)


def crown(B, center, radii, rng, count, size=.035, clipped_core=False):
    """Trees have open leaf clusters; close-clipped topiary keeps a hidden core."""
    batches(B)
    c, r = Vector(center), Vector(radii)
    if clipped_core:
        B['garden_core'].ico(c,r*.88,2,.12,rng.randrange(10000))
    for _ in range(count):
        z = rng.uniform(-1, 1)
        a = rng.uniform(0, math.tau)
        d = Vector((math.sqrt(1 - z*z)*math.cos(a), math.sqrt(1 - z*z)*math.sin(a), z))
        scale = rng.uniform(.55,1.04) if rng.random() < .25 else rng.uniform(.90,1.04)
        p = c + Vector((d.x*r.x, d.y*r.y, d.z*r.z)) * scale
        leaf(B, p, size*rng.uniform(.8, 1.25), size*.58, rng, d)


def cypress(B, x, y, h=.8, r=.07, seed=0):
    rng = random.Random('garden-cypress-%s' % seed)
    h *= 1.5
    radius = min(.17, max(.095, r * 1.65))
    lean = Vector((rng.uniform(-.025, .025), rng.uniform(-.025, .025), 0))
    rod(B, (x, y, .026), Vector((x, y, h*.97)) + lean, .016)
    for level in range(9):
        t = (level + .5) / 9
        z = h * (.16 + .78*t)
        spread = radius * math.sin(math.pi*t)**.65 * (1 - .25*t)
        for side in range(3):
            angle = side*math.tau/3 + level*2.4 + rng.uniform(-.3, .3)
            end = Vector((x + math.cos(angle)*spread*.45, y + math.sin(angle)*spread*.45, z)) + lean*t
            rod(B, (x + lean.x*t, y + lean.y*t, z-h*.065), end, .0035)
            crown(B, end, (max(.017,spread*.62), max(.017,spread*.62), h*.075), rng, 70, .038)
    crown(B, Vector((x, y, h*.98))+lean, (.021, .021, h*.055), rng, 60, .027)


def umbrella_pine(B, x, y, h=1.1, seed=0):
    rng = random.Random('garden-pine-%s' % seed)
    # The single native park tile needs a full-height tree, not a shrunken tholos.
    h *= 1.45
    root = Vector((x, y, .026))
    fork = root + Vector((.04, -.02, h*.56))
    rod(B, root, fork, .024)
    for i in range(7):
        a = i * 2.39996
        rr = .20 if i < 5 else .10
        # Overlapping flattened sprays form a broad umbrella canopy, rather than
        # a row of spherical crowns. Higher inner branches close its center.
        end = Vector((x + math.cos(a)*rr, y + math.sin(a)*rr, h*((.80 if i < 5 else .86) + rng.uniform(-.025, .025))))
        rod(B, fork, end, .012)
        crown(B, end, (.15, .15, .075), rng, 350, .040)


def hedge_segment(B, center, size):
    rng = random.Random('garden-hedge-%r-%r' % (tuple(center), tuple(size)))
    batches(B)
    c, s = Vector(center), Vector(size)
    # Hidden twig lattice supports a clipped, leaf-covered hedge with soft edges.
    long_axis = 0 if s.x > s.y else 1
    a, b = c.copy(), c.copy()
    a[long_axis] -= s[long_axis]*.45
    b[long_axis] += s[long_axis]*.45
    rod(B, a, b, min(.004, s.z*.10))
    B['garden_core'].box(c, (s.x*.94, s.y*.94, s.z*.92))
    count = min(450, max(22, int((s.x*s.y+s.x*s.z+s.y*s.z)*2000)))
    for _ in range(count):
        axis = rng.choices([0, 1, 2], weights=[s.y*s.z, s.x*s.z, s.x*s.y])[0]
        p = c + Vector((rng.uniform(-.48,.48)*s.x, rng.uniform(-.48,.48)*s.y, rng.uniform(-.48,.48)*s.z))
        p[axis] = c[axis] + rng.choice([-1,1])*s[axis]*rng.uniform(.47,.51)
        normal = Vector((0,0,0)); normal[axis] = 1 if p[axis] > c[axis] else -1
        leaf(B, p, min(.038,max(.014,s.z*.25)), .024, rng, normal)


def hedge(B, x0, x1, y0, y1, h=.09):
    hedge_segment(B, ((x0+x1)*.5,(y0+y1)*.5,h*.5), (x1-x0,y1-y0,h))


def vine_patch(B, center, seed=0):
    rng = random.Random('garden-vine-%s' % seed)
    c = Vector(center)
    for j in range(3):
        start = c + Vector((rng.uniform(-.10,.10), -.22, -.02))
        end = c + Vector((rng.uniform(-.10,.10), .22, rng.uniform(-.025,.025)))
        rod(B, start, end, .0025)
        for i in range(16):
            p = start.lerp(end,i/15) + Vector((rng.uniform(-.05,.05),rng.uniform(-.015,.015),rng.uniform(0,.045)))
            leaf(B,p,.062,.050,rng,(rng.uniform(-.5,.5),rng.uniform(-.5,.5),1),ivy=True)


def flowers(B, x, y, rx, ry, rng, z, count):
    for j in range(count):
        a = rng.uniform(0, math.tau)
        radius = math.sqrt(rng.random())
        base = Vector((x+math.cos(a)*radius*rx,y+math.sin(a)*radius*ry,z))
        tip = base + Vector((rng.uniform(-.01,.01),rng.uniform(-.01,.01),rng.uniform(.055,.095)))
        rod(B,base,tip,.0015)
        for t in [.3,.55,.8]:
            p = base.lerp(tip,t)
            leaf(B,p,.027,.012,rng)
            leaf(B,p+Vector((.01,0,0)),.024,.011,rng)
        key = 'garden_flower_%d' % (j % 3)
        if key not in B.b:
            B.mat(key,R.M['flower'][j % 3])
        for k in range(5):
            angle = k*math.tau/5
            B[key].ico(tip+Vector((math.cos(angle)*.009,math.sin(angle)*.009,0)),(.007,.007,.004),1)
        B['gold_dim'].ico(tip+Vector((0,0,.003)),(.004,.004,.003),1)


def flower_bed(B, cx, cy, rx, ry, seed=0, z=0, density=380):
    flowers(B,cx,cy,rx,ry,random.Random('garden-bed-%s' % seed),z,min(70,max(8,int(rx*ry*density*1.5))))


def planter(B, x, y, r=.07, plant='oleander', seed=0):
    B['trav'].lathe((x,y,0),[(r*.7,0),(r,r*.9),(r*1.1,r),(r*.9,r),(.001,r*.9)],16)
    flowers(B,x,y,r*.68,r*.68,random.Random('garden-planter-%s' % seed),r*.9,12)


def topiary(B):
    rng = random.Random('garden-topiary-1')
    for x,y in [(-.9,-.9),(-.9,.9),(.9,-.9),(.9,.9)]:
        B['trav'].lathe((x,y,0),[(.1,0),(.12,.08),(.001,.08)],16)
        rod(B,(x,y,.03),(x,y,.91),.009)
        for j in range(36):
            t = j/35
            a = t*math.tau*2.5
            p = (x+math.cos(a)*(.11-.075*t),y+math.sin(a)*(.11-.075*t),.12+t*.75)
            crown(B,p,(.042*(1-.4*t),)*3,rng,12,.022,clipped_core=True)
    for x,y in [(0,-.9),(-.9,0),(.9,0),(0,.9)]:
        rod(B,(x,y,.026),(x,y,.75),.008)
        # Sample proportional to cone area: its base needs more leaves than its tip.
        for j in range(1200):
            t = 1 - math.sqrt(rng.random())
            a = rng.uniform(0,math.tau)
            radius = .145*(1-t)+.012
            radius *= rng.uniform(.88,1.02)
            leaf(B,(x+math.cos(a)*radius,y+math.sin(a)*radius,.04+t*.71),.030,.022,rng,(math.cos(a),math.sin(a),.4))
    B['trav'].box((0,0,.08),(.4,.4,.16))
    # Preserve the peacock identity while replacing its faceted toy silhouette.
    rod(B,(0,0,.16),(0,.1,.57),.012)
    crown(B,(0,0,.35),(.13,.18,.15),rng,360,.027,clipped_core=True)
    crown(B,(0,.16,.55),(.048,.055,.10),rng,180,.020,clipped_core=True)
    for j in range(9):
        a = math.pi*j/8
        crown(B,(math.cos(a)*.21,-.14,.41+math.sin(a)*.20),(.051,.035,.105),rng,70,.022,clipped_core=True)


def install(roman, kit):
    global R, K
    R, K = roman, kit
    R.cypress, R.umbrella_pine = cypress, umbrella_pine
    R.hedge, R.planter, R.flower_bed = hedge, planter, flower_bed


def adapt(tree, name):
    """Keep authored architecture; substitute only this export's foliage calls."""
    class Gardens(ast.NodeTransformer):
        def visit_If(self, node):
            if ast.unparse(node.test) == "KIND == 'topiary'":
                node.body = ast.parse('garden()\nG.topiary(B)').body
            return self.generic_visit(node)

        def visit_Call(self, node):
            text = ast.unparse(node)
            if name == 'deco_fish_pond' and text.startswith("B['box'].ico(") and "0.91" in text:
                return ast.copy_location(ast.parse('G.vine_patch(B, (-1.4 + k * .255, -1.4, .91), k)',mode='eval').body,node)
            if name == 'deco_hedge_maze' and text.startswith("B['box'].box(") and 'step' in text:
                node.func = ast.parse('G.hedge_segment',mode='eval').body
                node.args.insert(0,ast.Name(id='B',ctx=ast.Load()))
            return self.generic_visit(node)

    tree = Gardens().visit(tree)
    for i,node in enumerate(tree.body):
        if isinstance(node,ast.Import) and any(a.asname == 'R' for a in node.names):
            tree.body[i+1:i+1] = ast.parse('import godot_garden_foliage as G\nG.install(R, K)').body
            break
    return tree
