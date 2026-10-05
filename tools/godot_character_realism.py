"""Godot-only anatomical walker refinement. Never modify the native art kit/cache.

Installed inside disposable background Blender exports. Reuses the local CC0
male/female sculpts and their rigs; keeps child anatomy, hand targets and props.
"""
import copy
import hashlib
import math
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

REVISION = 'natural_people_v1'
ROOT = Path(__file__).resolve().parents[2]
HUMANS = []
ASSETS = {'philosopher', 'walker_philosopher', 'physician', 'transporter', 'settlers1'}
from godot_asset_sources import PEOPLE
ASSETS.update('walker_' + role for role in PEOPLE)

# Linear skin reflectances: fair, warm fair, light olive; keep natural variation.
SKINS = [( .66, .445, .345), (.58, .385, .285), (.61, .425, .315),
         (.53, .365, .255), (.69, .475, .365), (.57, .395, .285)]
AGES = {'Grower':29, 'Trader':46, 'Firefighter':32, 'Shepherd':54,
        'Hunter':37, 'Bronze miner':43, 'Orange tender':24, 'Porter':35,
        'Peddler':52, 'Tax collector':49, 'Scholar':61, 'Watchman':38,
        'Actor':27, 'Competitor':23, 'Gymnast':26, 'Water carrier A':31,
        'Water carrier B':45, 'Sick':56, 'Urchin gatherer':34,
        'Greek physician':36, 'Greek transporter':41}

def profile(name, previous=None):
    seed = int.from_bytes(hashlib.sha256(name.encode()).digest()[:4], 'little')
    p = copy.deepcopy(previous) if previous else dict(
        age=AGES.get(name, 60 + seed % 24), jaw=.94 + (seed % 19)/100,
        cheek=.95 + ((seed >> 4) % 12)/100, nose=.001 + ((seed >> 8)%6)*.001,
        chin=-.001 + ((seed >> 12)%6)*.001, eye=.97 + ((seed >> 16)%6)*.01,
        hair=((.027,.016,.009),(.095,.048,.022)), hair_length=.015,
        beard_length=.02 if not name.startswith('walker_') or 'woman' not in name.lower() else 0, grey=.65, seed=seed)
    p['skin'] = SKINS[seed % len(SKINS)]
    if name == 'Urchin gatherer':
        # Preserve the clean-shaven city identity when exporting the newly connected work clips.
        p.update(beard_length=0, grey=.08)
    if name == 'Philosopher':
        p.update(skin=SKINS[0], hair=((.28,.26,.23),(.53,.51,.47)), grey=.65)
    if name in ['Greek physician','Greek transporter']:
        p.update(beard_length=.004 if name.endswith('physician') else 0, grey=.06)
    if name == 'Hades':
        from godot_hades_art import profile as hades_profile
        p = hades_profile(p)
    if p['age'] >= 60:
        p['grey'] = max(p['grey'], .48)
    return p

def install():
    for folder in ['art/characters/people','art/characters/roman','art/characters/identities']:
        sys.path.insert(0,str(ROOT/folder))
    import identity, person_kit, human, wardrobe
    make = person_kit.make_person
    def make_person(K, P, name, *args, **kwargs):
        identity.PROFILES[name] = profile(name, identity.PROFILES.get(name))
        return make(K,P,name,*args,**kwargs)
    person_kit.make_person = make_person
    wardrobe.PROFILES['Philosopher'] = ((.93,.89,.79),(.24,.43,.64),.29,.25)
    original_init = human.Human.__init__
    def init(h,K,P,name,*args,**kwargs):
        direct = name in ['Greek physician','Greek transporter']
        old = human.load_body
        if direct:
            identity.PROFILES[name] = profile(name)
            p = identity.PROFILES[name]
            kwargs.update(skin=p['skin'], hair=p['hair'][0])
            human.load_body = lambda sex: identity.body(sex,name,old)
        try:
            original_init(h,K,P,name,*args,**kwargs)
        finally:
            human.load_body = old
        h.godot_identity = copy.deepcopy(identity.PROFILES.get(name, profile(name)))
        HUMANS.append(h)
    human.Human.__init__ = init

def paint_skin(h):
    co=h.body_rest; x,y,z=co.T; p=h.godot_identity; ez=h.eye_z
    front=np.clip((y-.012)/.025,0,1)
    def patch(cx,cz,sx,sz):
        return np.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)*front
    colors=np.tile([*p['skin'],1.0],(len(co),1))
    blush=.12*(patch(.024,ez-.022,.020,.018)+patch(-.024,ez-.022,.020,.018))
    colors[:,:3]*=1+blush[:,None]*np.array([.14,-.13,-.12])
    lips=patch(0,ez-.037,.016,.0035)*.60
    colors[:,:3]=colors[:,:3]*(1-lips[:,None])+np.array([.44,.21,.17])*lips[:,None]
    under=(.045 if p['age']<12 else .12 if p['age']<60 else .20)*(patch(.020,ez-.007,.014,.004)+patch(-.020,ez-.007,.014,.004))
    colors[:,:3]*=1-under[:,None]
    if p['age']>=60:
        creases=sum(np.exp(-((z-ez-level)/.00095)**2) for level in [.022,.030,.038])
        colors[:,:3]*=1-.075*(creases*front*np.exp(-(x/.032)**4))[:,None]
    colors[:,:3]*=1+.015*(np.sin(x*193+y*61)*np.sin(z*207-y*89))[:,None]
    mesh=h.parts[0].ob.data
    attr=mesh.color_attributes.get('GodotPalette') or mesh.color_attributes.new(name='GodotPalette',type='FLOAT_COLOR',domain='POINT')
    attr.data.foreach_set('color',colors.ravel())

def groom(h,K):
    """Scalp-fitted shells/locks instead of voxelising microscopic render strands.

    Covers gaps between locks, preserves the hairline and eyebrows. No generic
    sphere, and no internal strand mesh duplicated through 35 morph targets.
    """
    p=h.godot_identity; co=h.body_rest
    for part in h.parts:
        if any(term in part.ob.name for term in ['strand groom','beard groom','Eyebrow groom','Shaved stubble']):
            part.ob.hide_render=True
    colour=tuple(a*(1-p['grey'])+b*p['grey'] for a,b in zip(p['hair'][0],(.49,.47,.43)))
    base=K.material(h.name+' natural hair',colour,rough=.72)
    grey=K.material(h.name+' silver locks',(.49,.47,.43),rough=.72)
    def attach_curve(ob):
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True);bpy.context.view_layer.objects.active=ob
        bpy.ops.object.convert(target='MESH')
        matrix=ob.matrix_basis.copy()
        for vertex in ob.data.vertices:vertex.co=matrix@vertex.co
        ob.matrix_basis.identity();h.attach(ob,'head')
    masks=[('scalp',h._hair_mask(co,h.sex))]
    if p['beard_length']>0:
        masks.append(('beard',h._beard_mask(co)))
    for label,mask in masks:
        faces=[face for face in h.polys if all(mask[i] for i in face)]
        if not faces:continue
        v=co.copy()+h.normals*(.0018 if label=='scalp' else .0010)
        if label=='beard':
            length=p['beard_length']
            lower=np.clip((h.eye_z-.032-co[:,2])/.035,0,1)
            v[:,2]-=length*.60*lower
            v[:,1]+=length*.12*lower
        ob=h._mesh(h.name+' fitted '+label,v,faces,base)
        # A continuous cap shares normals. Cutting every grey face into a
        # separate material group creates faceted seams after simplification.
        h._add(ob,v,np.repeat(h._rigid('head')[None],len(v),axis=0))
        if label=='beard' and p['beard_length']>.009:
            candidates=np.array(sorted({i for face in faces for i in face}))
            rng=np.random.default_rng(p['seed']+37)
            for idx in rng.choice(candidates,min(70,len(candidates)),replace=False):
                root=Vector(v[idx]); normal=Vector(h.normals[idx]).normalized()
                pts=[]
                size=min(.007,p['beard_length']*.2)
                for i in range(9):
                    t=i/8; angle=t*math.tau
                    pts.append(tuple(root+normal*(.001+size*.35*math.sin(math.pi*t))+Vector((size*.22*math.sin(angle),0,-size*t))))
                lock=K.curve(h.name+' beard lock',pts,.00085,grey if rng.random()<p['grey'] else base,h.root)
                attach_curve(lock)
    # Eyebrows follow each individual orbital ridge, not oversize painted dots.
    for side in [-1,1]:
        pts=[]
        for i in range(15):
            t=i/14; x=side*(.010+.023*t)
            q=np.array([x,.055,h.eye_z+.010+.003*math.sin(math.pi*t)])
            idx=np.argmin(np.sum((co-q)**2,axis=1))
            pts.append(tuple(co[idx]+h.normals[idx]*.0013))
        brow=K.curve(h.name+' anatomical eyebrow',pts,.0009,base,h.root)
        attach_curve(brow)
    # Direct-source physician/transporter have no identity.hair_details call.
    if h.name.startswith('Greek '):
        import identity
        h.identity=p
        identity.hair_details(h,K)

def prepare(K):
    import identity
    for h in HUMANS:
        if h.name == 'Hades':
            from godot_hades_art import adapt
            adapt(h,K)
        else:
            paint_skin(h);groom(h,K)
        if h.name == 'Philosopher':
            philosopher_robe(h,K)
        for part in h.parts:
            mesh=part.ob.data
            if len(mesh.vertices)!=len(part.rest):continue
            attr=mesh.attributes.get('GodotRest') or mesh.attributes.new('GodotRest','FLOAT_VECTOR','POINT')
            attr.data.foreach_set('vector',np.asarray(part.rest,dtype=float).ravel())
            part.ob['godot_person']=h.name
        h.parts[0].ob['godot_skin']=True
    return [dict(name=h.name,sex=h.sex,profile=h.godot_identity,
                 body_height=float(np.ptp(h.body_rest[:,2])),
                 body_sha256=hashlib.sha256(h.body_rest.tobytes()).hexdigest()) for h in HUMANS]

def philosopher_robe(h,K):
    """A shoulder-wrapped blue himation, inspired by the user's clothing reference."""
    from human import _hull_ring
    if getattr(h,'roman_cloak',None):h.roman_cloak.hide_render=True
    blue=K.material('Philosopher blue woven himation',tuple(c**2.2 for c in (.24,.43,.64)),rough=.91)
    edge=K.material('Philosopher ivory woven edging',(.82,.77,.65),rough=.91)
    verts=[];faces=[];cols=48;rows=20;yc=float(h.J['pelvis'][1])
    tunic_part=next(part for part in h.parts if part.ob.name.endswith(' chiton'))
    tunic=tunic_part.rest
    for j in range(rows):
        t=j/(rows-1)
        for i in range(cols):
            a=math.tau*i/cols
            top=.565+.15*max(0,-math.cos(a));bottom=.285+.095*math.cos(a)
            z=top*(1-t)+bottom*t
            # The wrapped layer must clear the flared tunic, not just bare hips.
            # Otherwise its lower half intersects cream cloth in jagged patches.
            level=max(z,.255)
            clothed=tunic[np.abs(tunic[:,2]-level)<.018]
            section=h._slice(max(z,.47))[:,:2]
            if len(clothed):section=np.concatenate([section,clothed[:,:2]])
            ring=_hull_ring(section,cols,(0,yc))
            r=ring[i]+.023+.004*math.sin(a*14+t*1.8)+.012*math.sin(t*math.pi)
            verts.append((r*math.cos(a),yc+r*math.sin(a),z))
    for j in range(rows-1):
        for i in range(cols):faces.append((j*cols+i,j*cols+(i+1)%cols,(j+1)*cols+(i+1)%cols,(j+1)*cols+i))
    v=np.array(verts)
    # Layered garments must share the tunic's partially thigh-driven drape. A
    # pelvis-only outer skirt can be pierced by the tunic when a leg steps forward.
    tree=KDTree(len(tunic))
    for i,point in enumerate(tunic):tree.insert(point,i)
    tree.balance();weights=[]
    for point in v:
        near=tree.find_n(Vector(point),6)
        factors=np.array([1/max(distance,.0001) for _,_,distance in near]);factors/=factors.sum()
        weights.append(sum(tunic_part.W[index]*factor for (_,index,_),factor in zip(near,factors)))
    weights=np.array(weights)
    ob=h._mesh('Philosopher wrapped Greek himation',v,faces,blue);ob.data.materials.append(edge)
    for face in ob.data.polygons:
        face.material_index=int(face.index//cols in [0,rows-2])
    solid=ob.modifiers.new('Woven edge thickness','SOLIDIFY');solid.thickness=.0025
    h._add(ob,v,weights)
    h.parts[-1].floor=.006

def kind(obj,material):
    s=(obj+' '+(material.name if material else '')).lower()
    if any(t in s for t in ['iris','pupil','sclera',' eye']):return 3
    if any(t in s for t in ['hair','beard','curl','braid','eyebrow','lock','scalp']):return 2
    if any(t in s for t in ['skin',' body']):return 0
    if any(t in s for t in ['leather','sandals','sandal','girdle','strap','satchel','shoe']):return 4
    if any(t in s for t in ['bronze','gold','gilt','iron','metal']):return 5
    if any(t in s for t in ['wool','cloth','linen','tunic','chiton','exomis','cloak','himation','woven','mantle','perizoma']):return 1
    if any(t in s for t in ['wood','timber','cart','scroll rod']):return 6
    return 7
