"""Background Blender only: reproducible anatomical leader busts and lit UI renders.
Original profiles over the retained CC0 human base; never edits native/walker assets.
blender -b --factory-startup -P tools/build_envoy_portraits.py -- --start 0 --count 99
"""
import argparse, copy, hashlib, json, math, sys
from pathlib import Path
import bpy, bmesh, numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
for directory in ['art/_kit','art/characters/identities','art/characters/roman','eZeus/tools']:
    sys.path.insert(0,str(ROOT/directory))
import ezkit as K, human, identity, wardrobe
import godot_god_face as face
import godot_character_realism as natural
ap=argparse.ArgumentParser();ap.add_argument('--start',type=int,default=0);ap.add_argument('--count',type=int,default=99)
a=ap.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
OUT=ROOT/'eZeus/godot/assets/envoys';OUT.mkdir(parents=True,exist_ok=True)
CLOTH=[(.20,.36,.46),(.48,.20,.19),(.38,.33,.20),(.31,.25,.42),(.20,.37,.31),(.63,.43,.22)]
HAIR=[(.025,.015,.009),(.085,.040,.017),(.19,.11,.045),(.32,.29,.24),(.48,.45,.39),(.012,.012,.014)]
for index in range(a.start,a.start+a.count):
    K.setup('envoy',1,8700+index,OUT,exposure=0,world_strength=.25)
    name=f'Envoy {index:03d}'
    rng=np.random.default_rng(8700+index)
    age=27+(index*17)%48
    p=dict(age=age,skin=tuple(v*.65 for v in natural.SKINS[index%6]),jaw=.87+float(rng.random())*.29,cheek=.92+float(rng.random())*.17,
           nose=-.002+float(rng.random())*.009,chin=-.002+float(rng.random())*.008,eye=.97+float(rng.random())*.05,
           hair=(HAIR[index%6],HAIR[index%6]),hair_length=.01,beard_length=[0,.008,.019,.031,0][index%5],grey=0,seed=8700+index)
    identity.PROFILES[name]=p
    original=human.load_body
    human.load_body=lambda sex:identity.body(sex,name,original)
    try:
        h=human.Human(K,{},name,K.material('Ivory linen',(.72,.66,.53)),garment='chiton',skin=p['skin'],hair=p['hair'][0],beard=False,seed=p['seed'])
    finally:human.load_body=original
    # Remove coarse hair/eyes before sculpting; fit new geometry to the resulting face.
    for part in h.parts[1:]:
        if any(term in part.ob.name for term in ['hair','eye','beard','chiton','girdle']):part.ob.hide_render=True
    spec=copy.deepcopy(face.HADES)
    spec['sculpt']={key:value*float(rng.uniform(.3,1.05)) for key,value in spec['sculpt'].items()}
    spec['sculpt']['lines']=.00012 if age<40 else .0003
    face.sculpt(h,spec)
    h.godot_identity=p
    natural.paint_skin(h)
    # Sculpted folds get soft cavity shading without painting god-like pallor.
    col=h.parts[0].ob.data.color_attributes['GodotPalette']
    colors=np.empty(len(col.data)*4);col.data.foreach_get('color',colors);colors=colors.reshape(-1,4)
    ids=np.flatnonzero(h.body_rest[:,2]>h.eye_z-.09)
    ao=face.occlusion(h,h.body_rest[ids],h.normals[ids],rays=10)
    colors[ids,:3]*=(1-np.clip(ao-.12,0,.7)*.48)[:,None]
    col.data.foreach_set('color',colors.ravel())
    spec['eyes'].update(iris_inner=(.22,.12,.045),iris_mid=[(.32,.22,.10),(.19,.30,.30),(.27,.32,.17)][index%3],iris_outer=(.10,.10,.07),pupil=.0018,iris=.0030)
    face.eyes(h,K,spec)
    beard_length=p['beard_length'];p['beard_length']=0
    natural.groom(h,K)
    p['beard_length']=beard_length
    if beard_length:
        spec['beard'].update(root=tuple(v**(1/2.2) for v in p['hair'][0]),tip=tuple(min(1,v**(1/2.2)*1.4) for v in p['hair'][0]),drop=beard_length*.5,length=beard_length*.6,lift=.0018,width=.00045,cards=280,stache_cards=80,stache=.005,seed=p['seed'])
        face.beard(h,K,spec)
    for ob in list(bpy.context.scene.objects):
        if 'anatomical eyebrow' in ob.name:ob.hide_render=True
    browmat=K.material('Fine eyebrows',p['hair'][0],rough=.75)
    front=np.flatnonzero((h.body_rest[:,1]>.02)&(h.normals[:,1]>.25))
    for side in [-1,1]:
        pts=[]
        for t in np.linspace(0,1,18):
            x=side*(.010+.024*t);z=h.eye_z+.013+.002*math.sin(t*math.pi)
            nearest=front[np.argmin((h.body_rest[front,0]-x)**2+(h.body_rest[front,2]-z)**2)]
            pts.append(tuple(h.body_rest[nearest]+h.normals[nearest]*.001))
        K.curve('Fine eyebrow',pts,.0012,browmat,h.root)
    # Scalp-following swept strands break the smooth cap silhouette.
    co=h.body_rest; mask=h._hair_mask(co,'male')
    candidates=np.flatnonzero(mask & (co[:,2]>h.eye_z+.013))
    hairmat=K.material('Swept hair strands',p['hair'][0],rough=.67)
    if len(candidates):
        for idx in rng.choice(candidates,min(220,len(candidates)),replace=False):
            root=co[idx];normal=h.normals[idx]
            pts=[]
            for t in np.linspace(0,1,10):
                target=root+np.array([.010*t,-.018*t,-.004*t])
                near=h._kd.find(Vector(target))[1]
                pts.append(tuple(co[near]+h.normals[near]*(.0025+.0015*math.sin(t*math.pi))))
            K.curve('Swept lock',pts,.00055,hairmat,h.root)
    wardrobe.PROFILES[name]=((.91,.86,.73),CLOTH[index%6],.46,.1)
    # Continuous folded wool mantle, cropped at the bust bottom.
    wool=K.material('Dyed wool mantle',tuple(v**2.2 for v in CLOTH[index%6]),rough=.86,noise=.05,scale=240,bump=.06)
    verts=[];faces=[]
    for j in range(22):
        t=j/21
        for k in range(128):
            angle=math.tau*k/128
            radius=.061+.125*t+.003*math.sin(angle*18+t*8)*math.sin(t*math.pi)
            verts.append((math.cos(angle)*radius,math.sin(angle)*radius*.58,h.eye_z-.082-.132*t+.007*math.cos(angle)))
    for j in range(21):
        for k in range(128):
            n=j*128+k;next=j*128+(k+1)%128
            faces.append((n,next,next+128,n+128))
    K.mesh('Folded shoulder mantle',verts,faces,wool,parent=h.root,smooth=True)
    bronze=K.material('Bronze clasp',(.35,.20,.07),rough=.3,metal=.75)
    K.ell('Shoulder clasp',(-.083,.049,h.eye_z-.132),(.011,.004,.011),bronze,parent=h.root)
    # Apply the rest pose, leaving anatomy in the same coordinates as clothing.
    for part in h.parts:
        part.ob.data.vertices.foreach_set('co',part.rest.ravel())
    for ob in list(bpy.context.scene.objects):
        if ob.type in {'LIGHT','CAMERA'} or ob.hide_render:
            bpy.data.objects.remove(ob,do_unlink=True)
    bpy.context.view_layer.update()
    # Export only a bust, not an invisible full walker below the card.
    for ob in list(bpy.context.scene.objects):
        if ob.type=='CURVE':
            bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH')
        if ob.type!='MESH':continue
        cutoff=h.eye_z-(.084 if 'body' in ob.name else .185)
        bm=bmesh.new();bm.from_mesh(ob.data)
        if 'body' in ob.name:
            bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(0,0,cutoff),plane_no=(0,0,1),clear_inner=True)
        else:
            bmesh.ops.delete(bm,geom=[v for v in bm.verts if (ob.matrix_world@v.co).z<cutoff],context='VERTS')
        bm.to_mesh(ob.data);bm.free()
        if not len(ob.data.vertices):bpy.data.objects.remove(ob,do_unlink=True);continue
        # Vertex palette is baked appearance, shared by GLB and render.
        if ob.data.color_attributes.get('GodotPalette'):
            m=K.material(ob.name+' painted',(.5,.4,.3),rough=.48)
            bs=m.node_tree.nodes.get('Principled BSDF');v=m.node_tree.nodes.new('ShaderNodeVertexColor');v.layer_name='GodotPalette'
            m.node_tree.links.new(v.outputs['Color'],bs.inputs['Base Color'])
            if 'body' in ob.name:bs.inputs['Subsurface Weight'].default_value=.08
            ob.data.materials.clear();ob.data.materials.append(m)
    bpy.ops.object.select_all(action='SELECT')
    stem=f'envoy_{index:03d}'
    bpy.ops.export_scene.gltf(filepath=str(OUT/(stem+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_apply=True)
    sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=16;sc.cycles.use_denoising=True
    sc.render.resolution_x=384;sc.render.resolution_y=448;sc.render.resolution_percentage=100
    def light(name,pos,power,size,color):
        d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
        ob=bpy.data.objects.new(name,d);sc.collection.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,h.eye_z-.03))-ob.location).to_track_quat('-Z','Y').to_euler()
    light('Warm window',(-.32,.48,1.12),3,.35,(1,.86,.72))
    light('Cool fill',(.35,.2,.84),.45,.28,(.65,.79,1))
    light('Rim',(.12,-.3,1.03),3,.23,(1,.76,.45))
    d=bpy.data.cameras.new('Portrait');d.type='ORTHO';d.ortho_scale=.235
    camera=bpy.data.objects.new('Portrait',d);sc.collection.objects.link(camera)
    target=Vector((0,.015,h.eye_z-.022));camera.location=target+Vector((.055,.65,.035));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();sc.camera=camera
    sc.render.filepath=str(OUT/(stem+'.png'));bpy.ops.render.render(write_still=True)
    triangles=sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in sc.objects if ob.type=='MESH')
    (OUT/(stem+'.json')).write_text(json.dumps(dict(id=stem,profile=p,triangles=triangles,body_sha256=hashlib.sha256(h.body_rest.tobytes()).hexdigest(),source='art/_kit/assets/human-base-meshes-bundle-v1.4.1',provenance='needs_evidence',generator='tools/build_envoy_portraits.py',revision=1),indent=2))
    print('ENVOY_DONE',index,triangles,flush=True)
