"""Original underworld-lord design, applied only to disposable Godot exports.

The user's reference supplies the fire/dark-drape mood, not facial geometry.
Keeps the native Hades rig, hands, bident and every native animation callback.
"""
import math
import re
import numpy as np

REVISION = 'underworld_lord_v2'


def profile(p):
    p.update(age=72, skin=(.215, .35, .42), jaw=1.05, cheek=.91,
             nose=.006, chin=.006, eye=.95, beard_length=.046, grey=.94,
             hair=((.35, .38, .42), (.57, .60, .65)), hair_length=.006)
    return p


def palette(ob, colors):
    attr = ob.data.color_attributes.get('GodotPalette') or ob.data.color_attributes.new(
        name='GodotPalette', type='FLOAT_COLOR', domain='POINT')
    attr.data.foreach_set('color', np.asarray(colors, dtype=float).ravel())


def adapt(h, K):
    # Remove replaced parts from the pose list: native show() must not resurrect
    # a hidden Roman tunic, beard, crown or groom during fight/appear clips.
    import godot_god_face as gf
    kept = []
    for part in h.parts:
        name = part.ob.name.lower()
        if any(s in name for s in ('hair', 'beard', 'groom', 'stubble', 'curl',
                                  'scalp', 'chiton', 'roman', 'fibula', 'girdle', 'crown')) \
                or re.fullmatch(r'.* eye(\.\d+)?', name) or any(s in name for s in ('iris', 'pupil', 'sclera')):
            part.ob.hide_render = True
        else:
            kept.append(part)
    h.parts = kept
    # A designed face: the generic sculpt is reshaped, then painted, before anything is fitted to it.
    gf.sculpt(h, gf.HADES)
    # The long garment hides legs without fighting the native stride beneath it.
    body = h.parts[0]
    arm = sum(body.W[:, h.bi[b]] for b in h.bones if b.startswith(('upper', 'fore', 'hand')))
    covered = (body.rest[:, 2] > .025) & (body.rest[:, 2] < .60) & (arm < .35)
    polys = [p for p in h.polys if not all(covered[i] for i in p)]
    body.ob.data.clear_geometry()
    body.ob.data.from_pydata(body.rest.tolist(), [], polys)
    body.ob.data.update()
    for face in body.ob.data.polygons:
        face.use_smooth = True
    # Cool skin with the face's anatomy painted in: baked occlusion, shadowed lids, dark lips, no human blush.
    palette(body.ob, gf.paint(h, gf.HADES))
    gf.eyes(h, K, gf.HADES)

    navy = K.material('Hades midnight woven cloth', (.014, .022, .043), rough=.86)
    mantle = K.material('Hades charcoal mantle cloth', (.022, .027, .037), rough=.84)
    bronze = K.material('Hades ancient bronze metal', (.34, .19, .068), rough=.36, metal=.8)
    flame = K.material('Hades red flame hair', (.88, .035, .004), rough=.45)
    brow = K.material('Hades angular eyebrow hair', (.19, .21, .24), rough=.7)
    yc = float(h.J['pelvis'][1])
    exclude = [b for b in h.bones if b.startswith(('upper', 'fore', 'hand', 'neck', 'head'))]

    def cloth(name, v, faces, mat):
        v = np.asarray(v)
        weights = h._transfer(v, exclude=exclude)
        # Long folds float over the stride; thigh influence is intentionally weak.
        lower = np.clip((.47-v[:, 2])/.22, 0, 1)*.88
        weights = weights*(1-lower[:, None])+h._rigid('pelvis')[None]*lower[:, None]
        ob = h._mesh('Hades '+name+' cloth', v, faces, mat)
        h._add(ob, v, weights)
        h.parts[-1].floor = .009
        return ob

    # One-shoulder drape: long, narrow torso above a generous fluted smoky skirt.
    cols, rows = 96, 38
    verts, faces = [], []
    for j in range(rows):
        t = j/(rows-1)
        for i in range(cols):
            a = math.tau*i/cols
            top = .657+.065*max(0, -math.cos(a))
            z = top*(1-t)+.013*t
            rx = np.interp(z, [.013, .15, .43, .55, .65, .74], [.225, .174, .103, .094, .145, .11])
            ry = np.interp(z, [.013, .15, .43, .55, .65, .74], [.188, .13, .095, .078, .098, .07])
            fold = (.005+.013*t*t)*math.cos(a*13+1.9*t)
            fold += .005*math.cos(a*7-t*4)*math.sin(math.pi*t)
            verts.append(((rx+fold)*math.cos(a), yc+(ry+fold)*math.sin(a), z))
    for j in range(rows-1):
        for i in range(cols):
            faces.append((j*cols+i, j*cols+(i+1)%cols, (j+1)*cols+(i+1)%cols, (j+1)*cols+i))
    robe = cloth('long folded chiton', verts, faces, navy)
    # Bronze hem is mesh-authored, so the statues retain its relief in stone.
    robe.data.materials.append(bronze)
    for f in robe.data.polygons:
        f.material_index = int(f.index//cols in (rows-3, rows-2))

    # Asymmetric wrapped mantle, with diagonal cowl folds across the chest and
    # a dark, trailing panel. Leaves the staff arm free through all fight poses.
    verts, faces = [], []
    cols, rows = 80, 25
    for j in range(rows):
        t = j/(rows-1)
        for i in range(cols):
            a = math.tau*i/cols
            top = .658+.070*max(0, -math.cos(a))
            bottom = .12+.30*max(0, math.sin(a))+.075*math.cos(a)
            z = top*(1-t)+bottom*t
            rx = np.interp(z, [.04, .2, .43, .55, .64, .74], [.235, .17, .12, .117, .159, .108])
            ry = np.interp(z, [.04, .2, .43, .55, .64, .74], [.24, .17, .117, .11, .12, .085])
            r = .008*math.sin(a*10+t*9)+.009*math.sin(t*math.pi*5)
            verts.append(((rx+r)*math.cos(a), yc+(ry+r)*math.sin(a), z))
    for j in range(rows-1):
        for i in range(cols):
            faces.append((j*cols+i, j*cols+(i+1)%cols, (j+1)*cols+(i+1)%cols, (j+1)*cols+i))
    cape = cloth('wrapped shadow mantle', verts, faces, mantle)
    cape.data.materials.append(bronze)
    for f in cape.data.polygons:
        f.material_index = int(f.index//cols in (0, rows-2))

    def tube(name, points, radius, mat, bone):
        return h._tube('Hades '+name, points, radius, mat,
                       weights=lambda pts: np.repeat(h._rigid(bone)[None], len(pts), axis=0))

    # A fitted shoulder wrap uses the actual anatomical surface, with generous
    # overlap on both sides. It stays attached through raised-arm fight poses.
    co = h.body_rest
    shoulder = (co[:, 0] < -.025) & (co[:, 0] > -.185) & (co[:, 2] > .605) & (co[:, 2] < .74)
    shoulder_faces = [p for p in h.polys if all(shoulder[i] for i in p)]
    v = co+h.normals*.009
    ob = h._mesh('Hades folded shoulder mantle cloth', v, shoulder_faces, mantle)
    # Follow the shoulder's native weights rather than hovering on a rigid chest.
    h._add(ob, v, h.A['weights'].copy())

    # Curled hem echoes drifting underworld smoke. Tapered, swept volumes have
    # no physics or navigation and are grounded even during a lunge.
    for index, (side, rear) in enumerate([(-1, -.04), (1, -.11), (-1, -.17)]):
        v, f = [], []
        for j in range(31):
            t = j/30
            a = t*math.pi*1.65
            cx = side*(.16+.12*math.sin(a))
            cy = yc+rear-.04*t
            cz = .038+.15*t+.052*math.sin(a-.3)
            r = .041*(1-t)**.7+.001
            for i in range(12):
                b = math.tau*i/12
                v.append((cx+r*math.cos(b), cy+r*math.sin(b), max(.010, cz+r*.48*math.sin(b))))
        for j in range(30):
            for i in range(12):
                f.append((j*12+i, j*12+(i+1)%12, (j+1)*12+(i+1)%12, (j+1)*12+i))
        cloth('smoke train %d' % index, v, f, mantle)

    # Scalp-fitted flame base. Faceted S-shaped tongues grow from the actual
    # skull, with distinct heights and a swept tip, not a spiked helmet.
    co = h.body_rest
    gf.hairline(h, K, gf.HADES)
    ez = h.eye_z
    hy = float(h.J['head'][1])
    for index, (x0, y0, height, width, lean) in enumerate([
            (0, .005, .169, .030, -.015), (-.024, -.012, .142, .026, -.028),
            (.025, -.017, .125, .025, .025), (-.042, .002, .095, .019, -.018),
            (.043, .003, .105, .020, .027), (-.012, .036, .105, .023, .015),
            (.016, .037, .130, .024, -.020), (0, -.037, .132, .026, .018)]):
        verts, faces, colors = [], [], []
        for j in range(19):
            t = j/18
            r = width*(1-t)**.85*(.8+.25*math.sin(t*math.pi))+.0003
            cx = x0+lean*t*t+.012*math.sin(t*math.tau)*t
            cy = hy+y0-.034*t+.018*math.sin(t*math.pi*1.6)
            cz = ez+.024+height*t
            for i in range(12):
                a = math.tau*i/12+t*.8
                verts.append((cx+r*math.cos(a), cy+r*.7*math.sin(a), cz))
                color = np.array([.48, .007, .002])*(1-t)+np.array([1.0, .19, .008])*t
                colors.append([*color, 1])
        for j in range(18):
            for i in range(12):
                faces.append((j*12+i, j*12+(i+1)%12, (j+1)*12+(i+1)%12, (j+1)*12+i))
        faces += [tuple(range(11, -1, -1)), tuple(18*12+i for i in range(12))]
        v = np.array(verts)
        ob = h._mesh('Hades red flame hair %d' % index, v, faces, flame)
        palette(ob, colors)
        h._add(ob, v, np.repeat(h._rigid('head')[None], len(v), axis=0))

    # A full silver beard of layered strand cards over a dark undercoat, a moustache over a firm mouth, and
    # raised, angular brows (tools/godot_god_face.py). They follow every native pose through the head.
    gf.beard(h, K, gf.HADES)
    gf.brows(h, K, gf.HADES)

    # The existing bident stays attached to the native grip; richer bronze reads
    # cleanly at gameplay distance and matches the new robe fittings.
    for ob in K.scene.objects:
        if ob.type == 'MESH' and ob.name.startswith('Bident'):
            ob.data.materials.clear()
            ob.data.materials.append(bronze)
        elif ob.type == 'MESH' and ob.name.startswith('Divine'):
            ob.data.materials.clear()
            ob.data.materials.append(flame)
            if ob.name == 'Divine light':
                # Native Aura.show() still controls the exact visibility, rise
                # and scale. Sparse red spiral fire replaces the opaque export of
                # the SDL renderer's translucent column; no event is invented.
                vertices, faces = [], []
                for strand in range(6):
                    start = len(vertices)
                    for j in range(41):
                        t = j/40
                        a = strand*math.tau/6+t*math.tau*1.25
                        r = .14*(1-.65*t)
                        for i in range(6):
                            b = math.tau*i/6
                            w = .004*(.4+math.sin(math.pi*t))
                            vertices.append((r*math.cos(a)+w*math.cos(b),
                                             r*math.sin(a)+w*math.sin(b), 1.02*t))
                    for j in range(40):
                        for i in range(6):
                            faces.append((start+j*6+i, start+j*6+(i+1)%6,
                                          start+(j+1)*6+(i+1)%6, start+(j+1)*6+i))
                ob.data.clear_geometry()
                ob.data.from_pydata(vertices, [], faces)
                ob.data.update()
                for face in ob.data.polygons:
                    face.use_smooth = True
