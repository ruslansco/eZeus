"""One elder curator, panel only. Original sculpt/groom on the retained anatomical base.

All measurements are Blender units (1 = 2 m). See docs/GODOT_PORTRAIT_REFERENCE.md.
No shared identity/cache edits, global random draws, image inputs, or crowd exports.
"""
import math
import numpy as np
import godot_god_face as gf

REVISION = 'elder_curator_portrait_v2'


def spec(p, h):
    s = p.spec_for(h)
    s.update(age=68, laurel=False, skin=p.lin((.76, .59, .47)))
    s['sculpt'].update(brow=.0035, frown=.0016, lines=.00055, socket=.0016,
                      cheekbone=.0030, hollow=.0035, temple=.0018, bridge=.0028,
                      tip=.0022, tip_drop=.0015, seam=.0009, upper_lip=.0013,
                      lower_lip=-.0006, downturn=.0006, chin=.0020, jaw=.0014,
                      fold=.0025)
    s['eyes'].update(sclera=(.73, .71, .66), iris=.0030, pupil=.00125,
                     iris_inner=(.24, .16, .08), iris_mid=(.18, .13, .075))
    s['hair'] = ((.16, .145, .125), (.56, .54, .49))
    return s


def sculpt(h, s):
    co = h.body_rest
    x, y, z = co.T.copy()
    ez = h.eye_z
    face = gf.smooth(y, .042, .061)
    dy = np.zeros(len(co)); dz = np.zeros(len(co))
    # Landmarks measured on this base: mouth eye_z-.036, nose wings -.022, chin -.052.
    # The legacy statue template assumed a lower mouth and must not sculpt this face.
    ax = np.abs(x)
    dy += .0014*gf.g(z,ez+.007,.0035)*gf.g(ax,.019,.016)*face
    dy += .0018*gf.g(z,ez-.012,.006)*gf.g(ax,.029,.009)*face
    dy -= .0032*gf.g(z,ez-.028,.010)*gf.g(ax,.028,.011)*face
    dy += .0015*gf.g(x,0,.005)*gf.g(z,ez-.012,.010)*face
    dz -= .0007*gf.g(x,0,.007)*gf.g(z,ez-.021,.005)*face
    for level in (.022,.029,.037):
        crease=ez+level+.0015*np.sin(x*95+level*30)
        dy -= .0005*gf.g(z,crease,.0007)*gf.g(x,0,.032)*face
    for t in np.linspace(0,1,14):
        dy -= .00055*gf.g(ax,.010+.009*t,.0015)*gf.g(z,ez-.023-.018*t,.002)*face
    # Lower orbital pads, tear troughs, interrupted crow's feet, and slight asymmetric jowls.
    for side in (-1, 1):
        dx = x - side * .019
        bag = gf.g(dx, 0, .012) * gf.g(z, ez - .0095, .003)
        dy += .00125 * bag * face
        dy -= .0008 * gf.g(dx, 0, .013) * gf.g(z, ez - .014, .0017) * face
        for k in range(3):
            line = ez - .001 - k * .003 + (np.abs(x) - .032) * (.35 - k * .32)
            dy -= .00038 * gf.g(z, line, .00065) * gf.g(x, side * .040, .008) * face
        dz -= (.0012 if side == 1 else .0008) * gf.g(x, side * .030, .011) * gf.g(z, ez - .061, .012) * face
    # Less inflated lips. Keep their seam and surrounding anatomy, not a projecting doll pout.
    dy -= .0012 * gf.g(x, 0, .012) * gf.g(z, ez - .039, .0025) * face
    co[:, 1] += dy; co[:, 2] += dz
    h.parts[0].rest[:] = co
    gf.refresh(h)


def scalp(h):
    x, y, z = h.body_rest.T
    ez = h.eye_z
    v = np.clip((y - float(h.J['head'][1])) / .065, -1, 1)
    # Mature M-shaped recession, broken at the edge, with thinner crown hair.
    front = ez + .041 + .021 * gf.g(np.abs(x), .028, .014)
    side = ez + .012
    boundary = np.where(v > 0, side + (front - side) * np.clip(v / .5, 0, 1),
                        side - .058 * np.clip(-v, 0, 1))
    boundary += .0006 * np.sin(x * 1200 + z * 300)
    ears = (np.abs(x) > .035) & (z < ez + .020) & (v > -.5) & (v < .5)
    return gf.smooth(z - boundary, -.0005, .002) * (~ears) * (z > ez - .075)


def fibers(p, h, K, s, weights, kind):
    """Fine tapered triangular fibers, combed on the actual surface then released at tips.
    Separate darker undergrowth and silver strands avoid a uniform wire/stone appearance.
    """
    rng = np.random.default_rng(s['seed'] + (71 if kind == 'hair' else 83))
    co, norms = h.body_rest, h.normals
    x, y, z = co.T
    ez = h.eye_z
    stache = (np.abs(x) < .023) & (z > ez - .033)
    candidate = np.flatnonzero((weights > .45) & ((~stache) if kind == 'beard' else True))
    # Sample triangle area, not vertices: vertex snapping produced sparse rows and a jagged hairline.
    valid = np.zeros(len(co), dtype=bool); valid[candidate] = True
    triangles = []
    for poly in h.polys:
        if all(valid[i] for i in poly):
            triangles.extend((poly[0], poly[j], poly[j+1]) for j in range(1,len(poly)-1))
    tri = np.asarray(triangles)
    v = co[tri]
    area = np.linalg.norm(np.cross(v[:,1]-v[:,0],v[:,2]-v[:,0]),axis=1)
    count = 11000 if kind == 'hair' else 10000
    chosen = rng.choice(len(tri),count,p=area/area.sum())
    a = np.sqrt(rng.random(count)); b = rng.random(count)
    bary = np.stack((1-a,a*(1-b),a*b),axis=1)
    roots = (v[chosen]*bary[:,:,None]).sum(axis=1)
    normals = (norms[tri[chosen]]*bary[:,:,None]).sum(axis=1)
    normals /= np.linalg.norm(normals,axis=1)[:,None]
    strands = p.Strands()
    mat = K.material('Portrait elder ' + kind, p.lin(s['hair'][0]), rough=.78)
    # Skin-coloured roots beneath fibers, no solid dark shell with a cut-out edge.
    for root, n in zip(roots,normals):
        if kind == 'hair':
            direction = np.array([.30 + .40 * np.sign(root[0]), -.9, -.35])
            length = rng.uniform(.008, .016)
        else:
            direction = np.array([-root[0] * 6, .14, -1.0])
            length = rng.uniform(.003, .006) + .004 * float(gf.g(root[0], 0, .025))
        direction -= n * np.dot(direction, n)
        direction /= max(np.linalg.norm(direction), 1e-8)
        side = np.cross(n, direction)
        silver = rng.random() < (.58 if kind == 'beard' else .38)
        value = rng.uniform(.40, .67) if silver else rng.uniform(.13, .29)
        tone = np.asarray(p.lin((value, value * .96, value * .89)))
        phase = rng.uniform(0, math.tau)
        path = []
        for t in np.linspace(0, 1, 7):
            guess = root + direction * length * t
            nearest, normal, _, _ = h._bvh.find_nearest(tuple(guess))
            fitted = np.asarray(nearest) if nearest is not None else guess
            # Roots hug the scalp/jaw, fine tips lift and separate; no repetitive helical ropes.
            point = fitted * (1 - t ** 3 * .6) + guess * (t ** 3 * .6)
            point += n * (.00045 + (.0023 if kind == 'hair' else .0010) * math.sin(t * math.pi * .85))
            point += side * .00032 * math.sin(t * 5 + phase) * t
            path.append(point)
        radius = rng.uniform(.00009, .00014)
        strands.tube(path, [radius * (1 - t) ** .6 + .000012 for t in np.linspace(0, 1, 7)],
                     [tone * (.60 + .4 * t) for t in np.linspace(0, 1, 7)], sides=3)
    if kind == 'beard':
        # Fine moustache hairs from the philtrum outward, leaving the lip outline visible.
        for side in (-1, 1):
            for k in range(210):
                u = rng.random()
                bx = side * (.001 + .013 * u); bz = ez - .0275 - .003 * u + rng.uniform(-.001, .001)
                idx = int(np.argmin((x - bx) ** 2 + (z - bz) ** 2 + (y < .045)))
                root = co[idx] + norms[idx] * .00035
                reach = rng.uniform(.003, .007)
                path = [root + np.array([side * reach * t, .0009 * math.sin(t * math.pi), -.002 * t - .0010 * t*t]) for t in np.linspace(0, 1, 6)]
                v = rng.uniform(.22, .62); tone = p.lin((v, v*.96, v*.89))
                strands.tube(path, [.00012*(1-t)+.00001 for t in np.linspace(0, 1, 6)], [tone]*6, sides=3)
    strands.emit(h, K, 'Portrait elder ' + kind + ' fibers', mat)


def brows(p, h, K, s):
    # Compact, full brow masses: short outer tails, a broad body and fine individual hairs.
    rng = np.random.default_rng(791)
    co, n = h.body_rest, h.normals
    x, y, z = co.T
    strands = p.Strands()
    mat = K.material('Portrait elder brow hair', p.lin((.22,.20,.17)), rough=.8)
    for side in (-1, 1):
        for k in range(1000):
            t = rng.random()
            bx = side*(.008+.022*t)
            half_width = .0027 * (.45 + .55 * math.sin(t * math.pi) ** .5) * (1 - .45 * t)
            bz = h.eye_z+.007+.0025*math.sin(t*math.pi*.85)+rng.uniform(-half_width,half_width)
            idx = int(np.argmin((x-bx)**2+(z-bz)**2+(y<.04)))
            hit = h._bvh.ray_cast((bx, .20, bz), (0,-1,0))[0]
            root = np.asarray(hit) + n[idx]*.00015 if hit is not None else co[idx]+n[idx]*.00015
            d = np.array([side*(.45+.35*t),0,.70-.95*t]); d -= n[idx]*np.dot(d,n[idx])
            length = rng.uniform(.0018,.0030)
            path = [root+d*length*u+n[idx]*.0004*math.sin(u*math.pi) for u in (0,.33,.66,1)]
            v = rng.uniform(.38,.60) if rng.random()<.24 else rng.uniform(.12,.25)
            tone = p.lin((v,v*.93,v*.84))
            strands.tube(path,[.00013,.00010,.00007,.000015],[tone]*4,sides=3)
    strands.emit(h,K,'Portrait elder brow hair fibers',mat)


def beard_zone(h):
    x,y,z=h.body_rest.T; ez=h.eye_z; ax=np.abs(x)
    cheek_top=ez-.016-.012*(1-gf.smooth(ax,.015,.036))
    weight=gf.smooth(cheek_top-z,0,.004)*gf.smooth(z,ez-.066,ez-.056)*gf.smooth(y,.014,.038)
    burns=gf.g(ax,.038,.005)*gf.smooth(z,ez-.027,ez-.012)*gf.smooth(ez+.002-z,0,.007)*gf.smooth(y,.010,.025)
    mouth=gf.g(x,0,.020)*gf.g(z,ez-.036,.006)
    return np.clip(np.maximum(weight,burns)*(1-np.clip(mouth*1.8,0,1)),0,1) * (ax < .043)


def paint(p,h,s,bw,sw):
    co=h.body_rest; x,y,z=co.T; ez=h.eye_z
    face=gf.smooth(y,.030,.060)*gf.smooth(z,ez-.07,ez-.055)
    colors=np.ones((len(co),4)); colors[:,:3]=s['skin']; rgb=colors[:,:3]
    idx=np.flatnonzero(z>ez-.075)
    ao=np.zeros(len(co)); ao[idx]=gf.occlusion(h,co[idx],h.normals[idx])
    rgb *= (1-np.clip(ao-.06,0,.6)[:,None]*np.array([.65,.75,.8]))
    lip=gf.g(x,0,.014)*gf.g(z,ez-.036,.003)*face*.55
    rgb[:]=rgb*(1-lip[:,None])+np.array(p.lin((.57,.34,.29)))*lip[:,None]
    # Fine irregular forehead creases and the folds under the eyes have a warm cavity colour.
    for level in (.022,.029,.037):
        line=ez+level+.0015*np.sin(x*95+level*30)
        w=gf.g(z,line,.0007)*gf.g(x,0,.032)*face*.32
        rgb *= (1-w[:,None]*np.array([.35,.5,.55]))
    for side in (-1,1):
        w=gf.g(x,side*.019,.012)*gf.g(z,ez-.008,.004)*face
        rgb *= (1-w[:,None]*np.array([.08,.13,.13]))
        w=gf.g(x,side*.029,.014)*gf.g(z,ez-.018,.009)*face
        rgb *= (1-w[:,None]*np.array([0,.08,.10]))
    roots=np.maximum(bw,sw)*.30
    rgb[:]=rgb*(1-roots[:,None])+np.array(p.lin((.25,.23,.20)))*roots[:,None]
    return colors


def adapt(p, h, K):
    s = spec(p,h)
    # This is a standalone override of only the curator, after old groom parts have been hidden.
    sculpt(h,s)
    bw, sw = beard_zone(h), scalp(h)
    colors = paint(p,h,s,bw,sw)
    co = h.body_rest; x,y,z = co.T; ez=h.eye_z
    face=gf.smooth(y,.035,.06)*gf.smooth(z,ez-.074,ez-.062)
    # Sun-exposed skin variation, restrained age spots and creases; all attached to rest anatomy.
    mottling=np.sin(x*360+z*270)*np.sin(z*390-y*190)
    colors[:,:3] *= (1+.035*mottling*face)[:,None]
    for side in (-1,1):
        for k in range(3):
            line=ez-.001-k*.003+(np.abs(x)-.032)*(.35-k*.32)
            w=gf.g(z,line,.0008)*gf.g(x,side*.040,.008)*face
            colors[:,:3] *= (1-w[:,None]*np.array([.12,.17,.19]))
    gf.set_palette(h.parts[0].ob,colors)
    gf.eyes(h,K,s)
    brows(p,h,K,s)
    fibers(p,h,K,s,sw,'hair')
    fibers(p,h,K,s,bw,'beard')
    h.godot_identity['portrait']=dict(revision=REVISION, age=68, hair=s['hair'][1], laurel=False, headwear=False,
                                    finish='elder_portrait_v2', eyebrows='compact_full_v1', groom='surface_combed_tapered_fibers')
