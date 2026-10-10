"""Minotaur anatomy rebuilt against the user's October 6 creature sheet.

The hero shot, side and rear views govern silhouette and dress. This module is
only the Minotaur's Godot presentation: joint pivots are sampled by the existing
fixed-topology exporter, with no native model, collision or movement changes.
Blender +Y is forward. Run only in a disposable background Blender process.
"""
import math
import bpy
from mathutils import Vector
from godot_hydra import linear, spline, smooth

DESIGN_REVISION = 'minotaur_reference_v2'


def pose_segment(node, start, end):
    node.location = start
    node.rotation_mode = 'QUATERNION'
    node.rotation_quaternion = Vector((0, 0, -1)).rotation_difference(end - start)


def knee_between(start, end, first, second, pole):
    delta = end - start
    length = max(.001, min(delta.length, first + second - .002))
    axis = delta.normalized()
    along = (first * first - second * second + length * length) / (2 * length)
    across = math.sqrt(max(.001, first * first - along * along))
    direction = Vector(pole) - axis * Vector(pole).dot(axis)
    return start + axis * along + direction.normalized() * across


def collar(s, parent, z0, z1, rx, ry, name, material='cloth'):
    verts = []
    for z in [z0, z1]:
        for i in range(20):
            a = math.tau * i / 20
            verts.append((rx * math.cos(a), ry * math.sin(a), z))
    return s.K.mesh(name, verts, [(i, (i + 1) % 20, (i + 1) % 20 + 20, i + 20)
                                  for i in range(20)], s.mats[material], parent, True)


def lock(s, parent, points, radius, name='Minotaur flowing mane lock', material='fur'):
    count = 16
    radii = [(radius * (.65 + .36 * math.sin(math.pi * i / (count - 1))) *
              (1 - i / count) ** .65 + .001) for i in range(count)]
    strand = s.tube(name, spline(points, count), radii, material, parent, 8)
    # Sculpt a shallow longitudinal fold into each lock, instead of smooth ropes.
    for j, center in enumerate(strand.points):
        for k in range(8):
            vertex = strand.ob.data.vertices[j * 8 + k]
            vertex.co = center + (vertex.co - center) * (1.08 if k % 2 else .82)
    strand.ob.data.update()
    return strand


def bull_head(s, actor):
    h = s.K.empty('Minotaur angular bull head', actor, (0, .015, 1.90))
    flesh = []
    def e(name, pos, size, mat='skin', parent=None, sub=2):
        ob = s.ell('Minotaur ' + name, pos, size, mat, parent or h, sub)
        if mat == 'skin' and parent is None:
            flesh.append(ob)
        return ob
    e('forehead', (0, -.025, .035), (.245, .165, .265), sub=3)
    e('long nasal bridge', (0, .14, -.005), (.135, .205, .17))
    for side in [-1, 1]:
        e('raised cheek plane', (side * .175, .095, -.075), (.115, .14, .14))
        brow = e('heavy slanted brow', (side * .138, .171, .112), (.145, .074, .052))
        brow.rotation_euler.y = -side * .37
        e('upper muzzle lip', (side * .10, .31, -.10), (.115, .12, .041))
    e('broad bovine muzzle', (0, .30, -.095), (.205, .13, .105))
    s.fuse(h, flesh, .018)
    # A dark heart-shaped nose and recessed nostrils, separate from the long face.
    e('charcoal nose', (0, .395, -.06), (.135, .055, .073), 'horn')
    for side in [-1, 1]:
        nostril = e('recessed nostril', (side * .066, .440, -.042), (.031, .013, .027), 'nostril')
        nostril.rotation_euler.y = side * .40
        e('golden eye', (side * .153, .202, .079), (.061, .024, .027), 'eyes')
        e('black eye pupil', (side * .157, .224, .078), (.014, .006, .021), 'horn', sub=1)
        # Broad pointed ears, with the pink inner plane recessed into the leaf.
        p = [(side * .22, .015, .11), (side * .33, .035, .165),
             (side * .46, -.015, .145), (side * .37, .03, .025)]
        verts = p + [(x, y - .045, z) for x, y, z in p]
        faces = [(0, 1, 2, 3), (7, 6, 5, 4)] + [(i, (i + 1) % 4, (i + 1) % 4 + 4, i + 4) for i in range(4)]
        s.K.mesh('Minotaur pointed ear', verts, faces, s.mats['skin'], h, True)
        s.K.mesh('Minotaur pink inner ear', [(x * .98, y + .007, z * .95) for x, y, z in p],
                 [(0, 1, 2, 3)], s.mats['mouth'], h, True)
        # Massive outward hooks. The taper turns inward at the end, like the sheet.
        points = [(side * .205, -.045, .175), (side * .38, -.11, .16),
                  (side * .65, -.085, .23), (side * .76, .005, .36),
                  (side * .66, .085, .425), (side * .49, .13, .405),
                  (side * .44, .15, .38)]
        n = 28
        radii = [(.125 * (1 - i / (n - 1)) ** .68 + .001) for i in range(n)]
        s.tube('Minotaur massive swept horn', spline(points, n), radii, 'horn', h, 14)

    jaw = s.K.empty('Minotaur jaw hinge', h, (0, .095, -.175))
    e('lower jaw', (0, .145, -.012), (.17, .155, .068), 'skin', jaw)
    e('dark grinning mouth', (0, .214, -.002), (.182, .126, .021), 'nostril', jaw)
    oral = []
    for row in range(2):
        for i in range(17):
            x = (i - 8) * .023
            oral.append((x, .305 + .145 * math.sqrt(max(.08, 1 - (x / .212) ** 2)),
                         -.127 + .060 * (abs(x) / .19) ** 1.2 - row * .065))
    s.K.mesh('Minotaur curved snarl cavity', oral,
             [(i, i + 1, i + 18, i + 17) for i in range(16)], s.mats['nostril'], h, True)
    # The teeth follow the curved muzzle, rather than a row across a flat face.
    for i in range(9):
        x = (i - 4) * .036
        y = .314 + .146 * math.sqrt(max(.08, 1 - (x / .212) ** 2))
        z = -.131 + .060 * (abs(x) / .19) ** 1.2
        w = .015
        depth = .043 if i in [1, 7] else .033
        verts = [(x - w, y, z), (x + w, y, z), (x + w * .68, y + .004, z - depth), (x - w * .68, y + .004, z - depth),
                 (x - w, y - .018, z), (x + w, y - .018, z), (x + w * .68, y - .014, z - depth), (x - w * .68, y - .014, z - depth)]
        s.K.mesh('Minotaur ivory upper tooth', verts, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], s.mats['teeth'], h, True)
    for i in range(7):
        x = (i - 3) * .036
        y = .212 + .143 * math.sqrt(max(.08, 1 - (x / .20) ** 2))
        z = -.026 + .040 * (abs(x) / .17) ** 1.2
        s.ell('Minotaur lower tooth', (x, y, z + .010), (.014, .012, .021), 'teeth', jaw, 1)
    # Dark mane mass carries overlapping, wavy locks down the front and back.
    e('rear mane volume', (0, -.15, -.13), (.29, .17, .34), 'fur')
    for side in [-1, 1]:
        for i in range(7):
            y = -.16 + i * .048
            z = .18 - .027 * i
            x = side * (.225 + .015 * i)
            front = max(0, (i - 2) / 4)
            drop = .055 * (i % 3)
            lock(s, h, [(x, y, z), (side * (.34 + .017 * i), y + .035, z - .11),
                        (side * (.25 + .013 * i), y + .065 + .08 * front, z - .22),
                        (side * (.40 + .004 * i), y + .07 + .10 * front, -.29 - drop),
                        (side * (.28 + .018 * i), y + .085 + .12 * front, -.36 - drop),
                        (side * (.31 + .015 * i), y + .075 + .11 * front, -.40 - drop)], .048 + .004 * (i % 3))
        for i in range(3):
            x = side * (.275 + .058 * i)
            y = .155 + .037 * i
            lock(s, h, [(x, y, -.10), (x + side * .062, y + .020, -.18),
                        (x - side * .034, y + .033, -.30), (x + side * .032, y + .065, -.38),
                        (x - side * .025, y + .042, -.44 - .040 * i)], .042, 'Minotaur chest mane curl')
    for i in range(11):
        x = (i - 5) * .045
        stagger = .038 * (i % 3)
        lock(s, h, [(x, -.11, .215), (x * 1.25 + .05 * math.sin(i), -.245, .13),
                    (x * 1.42 - .058 * math.sin(i), -.29, -.02 - stagger),
                    (x * 1.43 + .060 * math.cos(i), -.31, -.18 - stagger),
                    (x * 1.40 - .051 * math.cos(i), -.30, -.35 - stagger),
                    (x * 1.42, -.28, -.44 - stagger)], .067)
    for i in range(7):
        x = (i - 3) * .064
        lock(s, h, [(x, -.10, .20), (x * 1.1 + .044, -.24, .13),
                    (x * 1.18 - .044, -.30, .00), (x * 1.25 + .028, -.30, -.14),
                    (x * 1.16, -.29, -.21)], .060, 'Minotaur layered upper mane curl')
    for i in range(5):
        x = (i - 2) * .066
        lock(s, h, [(x, -.07, .25), (x * 1.10, .005, .31),
                    (x * 1.20, .10, .28), (x * 1.08, .115, .205)], .045, 'Minotaur swept crown forelock')
    for i in range(3):
        x = (i - 1) * .038
        lock(s, jaw, [(x, .17, -.035), (x * 1.6, .18, -.065), (x, .17, -.080)], .029, 'Minotaur chin beard')
    s.heads.append((h, jaw, Vector((0, .43, -.19))))
    return h


def muscular_segment(s, parent, name, length, widths, voxel, biceps=False, joint=False):
    pts = [(0, 0, -length * i / (len(widths) - 1)) for i in range(len(widths))]
    skin = s.tube(name, pts, widths, 'skin', parent, 16).ob
    meshes = [skin]
    if biceps:
        meshes.append(s.ell(name + ' flexor', (0, .043, -length * .48),
                            (.154, .112, length * .43), parent=parent))
        meshes.append(s.ell(name + ' triceps', (0, -.055, -length * .40),
                            (.145, .115, length * .44), parent=parent))
        meshes.append(s.ell(name + ' deltoid', (0, -.012, -.055), (.231, .186, .216), parent=parent, subdiv=3))
    if joint:
        meshes.append(s.ell(name + ' rounded joint', (0, 0, -.013),
                            (widths[0][0] * 1.12, widths[0][1] * 1.12, .13), parent=parent))
    s.fuse(parent, meshes, voxel)


def large_hand(s, parent, length):
    hand = s.K.empty('Minotaur large hand', parent, (0, 0, -length))
    s.ell('Minotaur palm', (0, .015, -.035), (.117, .079, .13), parent=hand)
    for i in range(4):
        x = (i - 1.5) * .055
        pts = [(x, .026, -.105), (x, .075, -.16), (x, .087, -.22 + .01 * abs(i - 1.5)),
               (x, .020, -.24 + .015 * abs(i - 1.5)), (x, -.007, -.195)]
        s.tube('Minotaur curled finger', spline(pts, 12), [.031, .033, .032, .032, .031, .030, .029, .027, .024, .022, .020, .018], parent=hand, ring=8)
        s.ell('Minotaur finger knuckle', (x, .061, -.142), (.035, .043, .043), parent=hand, subdiv=1)
        s.ell('Minotaur dark fingernail', (x, .010, -.222), (.020, .012, .030), 'horn', hand, 1)
    s.tube('Minotaur opposed thumb', spline([(.09, .018, -.02), (.155, .05, -.08), (.145, .09, -.13), (.105, .105, -.14)], 12), [.043 * (1 - i / 24) for i in range(12)], parent=hand, ring=8)
    s.ell('Minotaur thumbnail', (.109, .116, -.145), (.029, .014, .023), 'horn', hand, 1)
    return hand


def hoof(s, foot, side):
    # Two distinct wedge-shaped hoof halves, with a real cleft and flat sole.
    for digit in [-1, 1]:
        x = digit * .074
        verts = [(x - .057, -.09, -.079), (x + .057, -.09, -.079),
                 (x + .067, .19, -.079), (x - .067, .19, -.079),
                 (x - .044, -.08, .105), (x + .044, -.08, .105),
                 (x + .048, .135, .074), (x - .048, .135, .074)]
        ob = s.K.mesh('Minotaur cloven hoof', verts, [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
                   (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], s.mats['horn'], foot, True)
        bpy.context.view_layer.objects.active = ob
        bevel = ob.modifiers.new('Soft keratin hoof edges', 'BEVEL')
        bevel.width = .012
        bevel.segments = 2
        bpy.ops.object.modifier_apply(modifier=bevel.name)
    s.ell('Minotaur fetlock fur', (0, -.005, .112), (.14, .118, .10), 'skin', foot)
    for i in range(7):
        a = math.tau * i / 7
        lock(s, foot, [(.118 * math.cos(a), .098 * math.sin(a), .15),
                       (.135 * math.cos(a), .123 * math.sin(a), .083),
                       (.126 * math.cos(a), .14 * math.sin(a), .034)], .028, 'Minotaur shaggy fetlock point', 'skin')


def loincloth(s, actor):
    collar(s, actor, 1.075, 1.155, .31, .212, 'Minotaur leather waist belt')
    for back in [False, True]:
        vs = []
        for row in range(7):
            u = row / 6
            z = 1.142 - .465 * u
            width = .275 * (1 - .80 * u)
            for col in range(13):
                x = (col / 12 - .5) * 2 * width
                y = .218 + .028 * u + .025 * math.sin(col * .92 + u * .5)
                zz = z + .032 * u * abs(x / width) - .042 * u * math.cos(col * .65)
                vs.append((x, -y if back else y, zz))
        s.K.mesh('Minotaur back leather fall' if back else 'Minotaur pointed front loincloth', vs,
                   [(r * 13 + j, r * 13 + j + 1, (r + 1) * 13 + j + 1, (r + 1) * 13 + j)
                    for r in range(6) for j in range(12)], s.mats['cloth'], actor, True)
    for side in [-1, 1]:
        buckle = s.K.empty('Minotaur silver hip clasp', actor, (side * .255, .184, 1.123))
        s.ell('Minotaur clasp rim', (0, 0, 0), (.070, .021, .073), 'metal', buckle)
        s.ell('Minotaur clasp inset', (0, .020, 0), (.048, .010, .049), 'horn', buckle)
        s.ell('Minotaur clasp boss', (0, .030, 0), (.025, .011, .026), 'metal', buckle)


def build_anatomy(s):
    for label, rgb in [('skin', (.70, .395, .185)), ('belly', (.72, .42, .20)),
                       ('fur', (.19, .087, .044)), ('horn', (.095, .088, .078)),
                       ('cloth', (.235, .103, .066)), ('mouth', (.54, .245, .18)),
                       ('metal', (.43, .45, .43))]:
        s.mats[label].diffuse_color = (*linear(rgb), 1)
        node = next(n for n in s.mats[label].node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        node.inputs['Base Color'].default_value = (*linear(rgb), 1)
    s.mats['nostril'] = s.K.material('Monster horn recessed minotaur nostril', linear((.023, .021, .019)), rough=.72)
    s.mats['eyes'] = s.K.material('Monster belly natural golden minotaur eyes', linear((.85, .56, .12)), rough=.38)
    s.design = 'sheet-matched broad muscular bull, hooked black horns, long brown mane, cloven hooves, leather loincloth and bracers'
    actor = s.K.empty('Minotaur anatomical torso', s.root)
    s.actors.append((actor, Vector((0, 0, 0)), 'minotaur'))
    body = [s.tube('Minotaur tapered trunk', [(0, 0, .95), (0, 0, 1.11), (0, 0, 1.27), (0, -.012, 1.48), (0, -.025, 1.63), (0, -.035, 1.72)],
                   [(.29, .17), (.27, .17), (.32, .19), (.44, .235), (.48, .215), (.31, .17)], parent=actor, ring=28).ob]
    body.append(s.ell('Minotaur thick neck', (0, -.015, 1.76), (.195, .155, .20), parent=actor))
    body.append(s.ell('Minotaur pelvis', (0, -.01, 1.006), (.33, .20, .20), parent=actor))
    for side in [-1, 1]:
        chest = s.ell('Minotaur pectoral', (side * .237, .178, 1.528), (.255, .163, .176), parent=actor, subdiv=3)
        chest.rotation_euler.y = side * .14
        body.append(chest)
        trap = s.ell('Minotaur trapezius', (side * .25, -.03, 1.67), (.24, .17, .11), parent=actor)
        trap.rotation_euler.y = side * .25
        body.append(trap)
        body.append(s.ell('Minotaur latissimus', (side * .28, -.125, 1.43), (.20, .115, .29), parent=actor))
        for z, rx in [(1.347, .11), (1.221, .101), (1.106, .09)]:
            body.append(s.ell('Minotaur abdominal plane', (side * .102, .182, z), (rx, .080, .079), parent=actor))
        oblique = s.ell('Minotaur oblique', (side * .263, .09, 1.227), (.095, .105, .186), parent=actor)
        oblique.rotation_euler.y = side * -.34
        body.append(oblique)
    s.fuse(actor, body, .026)
    bull_head(s, actor)
    loincloth(s, actor)
    s.minotaur_arms = []
    s.minotaur_legs = []
    for side in [-1, 1]:
        shoulder = Vector((side * .51, -.012, 1.605))
        upper = s.K.empty('Minotaur upper arm joint', actor)
        lower = s.K.empty('Minotaur forearm joint', actor)
        muscular_segment(s, upper, 'Minotaur shoulder and biceps', .37,
                          [(.197, .164), (.223, .183), (.199, .156), (.172, .146), (.125, .122)], .025, True)
        muscular_segment(s, lower, 'Minotaur heavy forearm', .345,
                          [(.125, .12), (.168, .14), (.168, .133), (.126, .11), (.098, .082)], .025, joint=True)
        for j in range(3):
            collar(s, lower, -.19 - j * .050, -.245 - j * .050,
                   .163 - j * .016, .139 - j * .012, 'Minotaur layered leather wrist wrap')
        large_hand(s, lower, .345)
        s.minotaur_arms.append((side, upper, lower, shoulder))
        hip = Vector((side * .255, -.015, 1.05))
        base = Vector((side * .354, .015, .08))
        thigh = s.K.empty('Minotaur thigh joint', s.root)
        shank = s.K.empty('Minotaur hock joint', s.root)
        muscular_segment(s, thigh, 'Minotaur massive thigh', .47,
                          [(.185, .155), (.205, .174), (.209, .178), (.173, .147), (.11, .103)], .026)
        muscular_segment(s, shank, 'Minotaur bovine calf', .435,
                          [(.112, .108), (.143, .133), (.135, .12), (.09, .093), (.082, .085)], .026, joint=True)
        for j in range(3):
            a = math.pi + j * .75
            x, y = .084 * math.cos(a), .087 * math.sin(a)
            lock(s, shank, [(x, y, -.235), (x * 1.48, y * 1.48, -.32),
                           (x * 1.28, y * 1.28, -.385)], .031, 'Minotaur calf coat point', 'skin')
        foot = s.K.empty('Minotaur planted split hoof', s.root, base)
        hoof(s, foot, side)
        s.legs.append((None, foot, hip, base, False))
        s.minotaur_legs.append((side, thigh, shank, hip, base, foot))
    pts = [(0, -.16, 1.007), (.24, -.37, .905), (.57, -.43, .94), (.85, -.38, .85), (.91, -.32, .75)]
    tail = s.tube('Minotaur long bovine tail', spline(pts, 26), [.039 * (1 - i / 32) + .008 for i in range(26)], parent=actor, ring=10)
    s.tails.append((tail, pts, 'tail', 0))
    tuft = s.K.empty('Minotaur tail tuft anchor', actor)
    s.ell('Minotaur dark tail tuft mass', (0, 0, -.07), (.094, .066, .135), 'fur', tuft)
    for i in range(7):
        a = math.tau * i / 7
        lock(s, tuft, [(.055 * math.cos(a), .04 * math.sin(a), .035),
                       (.102 * math.cos(a), .063 * math.sin(a), -.08),
                       (.072 * math.cos(a) + .025, .058 * math.sin(a), -.22)], .040, 'Minotaur tail tuft lock')
    s.minotaur_tail = (tail, tuft)


def animate_anatomy(s, f, clip):
    phase = f / 24
    actor = s.actors[0][0]
    for side, upper, lower, shoulder in s.minotaur_arms:
        swing = .15 * side * math.sin(math.tau * phase) if clip == 'walk' else 0
        if clip == 'fight':
            pulse = max(0, math.sin(math.tau * phase))
            end = Vector((side * (.63 if side > 0 else .50), .19 + (.40 if side > 0 else .12) * pulse, 1.20 + .15 * pulse))
        elif clip == 'fight2':
            pulse = max(0, math.sin(math.tau * phase))
            end = Vector((side * .56, .15 + .13 * pulse, 1.28 + .54 * pulse))
        else:
            end = Vector((side * .747, .025 + swing, 1.012))
        elbow = knee_between(shoulder, end, .37, .345, (side, -.13, -.08))
        pose_segment(upper, shoulder, elbow)
        pose_segment(lower, elbow, end)
    for j, (side, thigh, shank, hip, base, foot) in enumerate(s.minotaur_legs):
        p = (phase + j * .5) % 1
        stance = .72
        if clip == 'walk':
            dy = ((.32 - .64 * p) if p < stance else
                  (.32 - .64 * stance) + .64 * stance * smooth((p - stance) / (1 - stance))) / max(s.scale, .01)
            lift = 0 if p < stance else .115 * math.sin(math.pi * (p - stance) / (1 - stance))
        else:
            dy = lift = 0
        foot.location = base + Vector((0, dy, lift))
        top = hip + actor.location
        ankle = foot.location + Vector((0, -.025, .113))
        knee = knee_between(top, ankle, .47, .435, (side * .25, 1, 0))
        pose_segment(thigh, top, knee)
        pose_segment(shank, knee, ankle)
    tail, tuft = s.minotaur_tail
    tuft.location = tail.points[-1]
