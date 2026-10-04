"""Isolated MPFB/Blender source build for the physician benchmark.
Run with Blender -b --factory-startup -P tools/build_citizen_benchmark.py.
No live Blender scene, native art recipe, or simulation data is changed.
Dependencies are pinned by prepare_citizen_sources.py in the local art workspace.
"""
import bpy, bmesh, sys, math, json, hashlib, os
from pathlib import Path
from mathutils import Vector, Matrix, Euler
import numpy as np

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO/'tools'))
import citizen_gait as gait
ROOT = REPO.parent/'art/characters/citizen_v2'
VENDOR = ROOT/'vendor'
ASSETS = VENDOR/'makehuman_system_assets_cc0'
# CITIZEN_OUT redirects the export (and the .blend) to a scratch directory for experiments.
OUT = Path(os.environ['CITIZEN_OUT']) if os.environ.get('CITIZEN_OUT') else REPO/'godot/assets/characters/physician_v2'
OUT.mkdir(parents=True, exist_ok=True)
# Procedural detail maps are written here and packed into the GLB; they are not Godot assets.
WORK = ROOT/'work'
WORK.mkdir(parents=True, exist_ok=True)
sys.path.insert(0,str(VENDOR/'mpfb-v2.0.17/mpfb2-2.0.17/src'))
import mpfb
# Keep MPFB's preferences/cache local to this disposable background process.
bpy.utils.extension_path_user = lambda *a,**k: str(ROOT/'mpfb-work')
addon=bpy.context.preferences.addons.new(); addon.module='mpfb'
mpfb.register()
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
macro=TargetService.get_default_macro_info_dict()
macro.update(gender=1.0, age=.4, muscle=.45, weight=.48)
macro['race']={'caucasian':1.0,'asian':0.0,'african':0.0}
body=HumanService.create_human(scale=.05,macro_detail_dict=macro)
rig=HumanService.add_builtin_rig(body,'default_no_toes')
rig.name='PhysicianSkeleton'
loaded={}
for key,asset,typ in [('eyes','eyes/high-poly/high-poly.mhclo','Eyes'),('brows','eyebrows/eyebrow001/eyebrow001.mhclo','Eyebrows'),('lashes','eyelashes/eyelashes01/eyelashes01.mhclo','Eyelashes'),('hair','hair/short01/short01.mhclo','Hair'),('tunic','clothes/male_casualsuit06/male_casualsuit06.mhclo','Clothes')]:
    loaded[key]=HumanService.add_mhclo_asset(str(ASSETS/asset),body,asset_type=typ,subdiv_levels=0)
bpy.context.view_layer.update()

def activate(ob):
    bpy.ops.object.select_all(action='DESELECT'); ob.select_set(True); bpy.context.view_layer.objects.active=ob

def material(name, color, rough=.7, metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    return m

def image_node(mat,path,socket,noncolor=False):
    n=mat.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(path),check_existing=True)
    if noncolor:n.image.colorspace_settings.name='Non-Color'
    bs=mat.node_tree.nodes.get('Principled BSDF');mat.node_tree.links.new(n.outputs['Color'],bs.inputs[socket]);return n

def save_texture(name, rgb):
    h,w=rgb.shape[:2];im=bpy.data.images.new(name,width=w,height=h,alpha=True);im.colorspace_settings.name='Non-Color'
    rgba=np.ones((h,w,4),dtype=np.float32);rgba[:,:,:3]=rgb
    im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(WORK/(name+'.png'));im.file_format='PNG';im.save();return im

def noise_maps(prefix,kind):
    n=512;y,x=np.mgrid[:n,:n];rng=np.random.default_rng(742)
    if kind=='skin':
        h=rng.normal(0,.13,(n,n))+np.sin(x*2.2)*np.sin(y*2.7)*.1;strength=.08;rough=.57+np.clip(h,-.3,.3)*.10
    else:
        h=np.sin(x*math.pi/2)*np.sin(y*math.pi/2)*.35+rng.normal(0,.045,(n,n));strength=.08;rough=.88+h*.08
    dy,dx=np.gradient(h);v=np.stack([-dx*strength,-dy*strength,np.ones_like(h)],axis=-1);v/=np.linalg.norm(v,axis=-1,keepdims=True)
    normal=save_texture(prefix+'_normal',v*.5+.5)
    roughness=save_texture(prefix+'_roughness',np.repeat(rough[:,:,None],3,axis=2))
    return normal,roughness

def detail_maps(mat,kind):
    normal,rough=noise_maps(kind,kind);nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF')
    t=nodes.new('ShaderNodeTexImage');t.image=normal;normal.colorspace_settings.name='Non-Color'
    nm=nodes.new('ShaderNodeNormalMap');links.new(t.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
    t=nodes.new('ShaderNodeTexImage');t.image=rough;rough.colorspace_settings.name='Non-Color';links.new(t.outputs['Color'],bs.inputs['Roughness'])

skin=material('Skin_PBR',(.8,.7,.6),.57)
image_node(skin,ASSETS/'skins/middleage_caucasian_male/middleage_lightskinned_male_diffuse.png','Base Color')
detail_maps(skin,'skin')
body.data.materials.clear();body.data.materials.append(skin)
linen=material('Warm_linen',(.72,.65,.51),.89);detail_maps(linen,'linen')
wool=linen.copy();wool.name='Aegean_wool';wool.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.027,.13,.24,1)
trim=material('Woven_ochre_border',(.4,.24,.065),.85)
leather=material('Worn_leather',(.12,.052,.023),.76)
bronze=material('Bronze_clasp',(.39,.21,.075),.4,.75)
# Standard glTF materials with explicit textures; no unsupported Blender node groups.
for key,rel in [('hair','hair/short01/short01_diffuse.png'),('brows','eyebrows/eyebrow001/eyebrow001.png'),('lashes','eyelashes/eyelashes01/eyelashes01.png'),('eyes','eyes/materials/brown_eye.png')]:
    ob=loaded[key];mat=material('Eyes_cornea' if key=='eyes' else key.title(),(1,1,1),.18 if key=='eyes' else .73)
    tex=image_node(mat,ASSETS/rel,'Base Color')
    if key!='eyes':
        bs=mat.node_tree.nodes.get('Principled BSDF');mat.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);mat.surface_render_method='DITHERED';mat.use_transparency_overlap=False
    ob.data.materials.clear();ob.data.materials.append(mat)

# The high-poly eye has an outer cornea UV island, marked blue by the source.
# Give that shell a clear finish rather than painting the blue marker over the iris.
eye=loaded['eyes'];cornea=material('Clear_cornea',(1,1,1),.09)
cornea.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.025
cornea.surface_render_method='DITHERED';eye.data.materials.append(cornea)
uv=eye.data.uv_layers.active.data
for poly in eye.data.polygons:
    coords=[uv[i].uv for i in poly.loop_indices]
    if all(c.x>.84 and c.y<.17 for c in coords):poly.material_index=1

# Freeze macro target shapes before applying helper/clothes masks. Preserve the rig.
activate(body)
if body.data.shape_keys:bpy.ops.object.shape_key_remove(all=True,apply_mix=True)
for mod in list(body.modifiers):
    if mod.type=='MASK' and mod.name.startswith('Delete.'):body.modifiers.remove(mod)
for mod in list(body.modifiers):
    if mod.type=='MASK':bpy.ops.object.modifier_apply(modifier=mod.name)
weight_mesh=body.data.copy()
# Hide only body surfaces fully enclosed by the garment, not arms/neck.
bm=bmesh.new();bm.from_mesh(body.data)
covered=[f for f in bm.faces if all(.28<v.co.z<.663 and abs(v.co.x)<.097 for v in f.verts)]
bmesh.ops.delete(bm,geom=covered,context='FACES');bm.to_mesh(body.data);bm.free()
# One subdivision smooths the face/knuckles; covered torso removal limits the cost.
BODY_SUBDIV=int(os.environ.get('CITIZEN_BODY_SUBDIV','0'))   # 1 = smooth the whole body once (48K vertices); 0 = MPFB base mesh (identical at portrait range)
CLOTH_SUBDIV=int(os.environ.get('CITIZEN_CLOTH_SUBDIV','0'))
if BODY_SUBDIV:
    activate(body);sub=body.modifiers.new('Face_and_hands','SUBSURF');sub.levels=BODY_SUBDIV
    bpy.ops.object.modifier_move_up(modifier=sub.name);bpy.ops.object.modifier_apply(modifier=sub.name)
body.name='Physician_skin'
# Facial-only shapes keep blinks independent from locomotion.
body.shape_key_add(name='Basis')
for sign,label in [(1,'Blink_L'),(-1,'Blink_R')]:
    shape=body.shape_key_add(name=label)
    for v,sv in zip(body.data.vertices,shape.data):
        x,y,z=v.co;dx=(x-sign*.015)/.013
        if abs(dx)<1 and y<-.067 and .754<z<.770:
            edge=max(0,1-dx*dx)**.55
            if z>.758:sv.co.z-=min(.008,z-.7575)*edge
            else:sv.co.z+=.0015*edge
# Shirt component supplies a properly fitted neckline/shoulders; remove its trousers.
tunic=loaded['tunic'];activate(tunic)
bm=bmesh.new();bm.from_mesh(tunic.data)
seen=set();components=[]
for v in bm.verts:
    if v in seen:continue
    todo=[v];seen.add(v);group=[]
    while todo:
        t=todo.pop();group.append(t)
        for e in t.link_edges:
            o=e.other_vert(t)
            if o not in seen:seen.add(o);todo.append(o)
    components.append(group)
remove=[v for g in components if max(v.co.z for v in g)<.5 for v in g]
bmesh.ops.delete(bm,geom=remove,context='VERTS')
# Add a continuous draped skirt from the shirt's lower boundary, retaining its fitted top.
bottom=[e for e in bm.edges if e.is_boundary and all(v.co.z<.45 for v in e.verts)]
ring=list({v for e in bottom for v in e.verts})
ring.sort(key=lambda v:math.atan2(v.co.y,v.co.x))
weights=bm.verts.layers.deform.active
previous=ring
for row in range(1,13):
    t=row/12;new=[]
    for v in ring:
        ang=math.atan2(v.co.y,v.co.x);fold=(.0032*math.sin(ang*18)+.0014*math.sin(ang*31))*math.sin(t*math.pi*.75)
        p=v.co.copy();p.x*=1+.18*t;p.y*=1+.18*t;p.x+=math.cos(ang)*fold;p.y+=math.sin(ang)*fold;p.z=v.co.z*(1-t)+.265*t
        nv=bm.verts.new(p)
        if weights:
            for k,val in v[weights].items():nv[weights][k]=val
        new.append(nv)
    for i in range(len(ring)):
        j=(i+1)%len(ring);bm.faces.new((previous[i],previous[j],new[j],new[i]))
    previous=new
bm.normal_update();bm.to_mesh(tunic.data);bm.free();tunic.name='Linen_chiton'
tunic.data.materials.clear();tunic.data.materials.append(linen);tunic.data.materials.append(trim)
for p in tunic.data.polygons:
    z=sum(tunic.data.vertices[i].co.z for i in p.vertices)/len(p.vertices)
    p.material_index=1 if z<.28 else 0
activate(tunic);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
# Smooth garment and give the hem/openings actual thickness.
for typ,name in [('SUBSURF','Draped_linen'),('SOLIDIFY','Cloth_thickness')]:
    if typ=='SUBSURF' and not CLOTH_SUBDIV:continue
    mod=tunic.modifiers.new(name,typ)
    if typ=='SUBSURF':mod.levels=CLOTH_SUBDIV
    else:mod.thickness=.0015
    bpy.ops.object.modifier_move_up(modifier=mod.name);bpy.ops.object.modifier_apply(modifier=mod.name)

# Weighted source positions are reusable for newly authored costume pieces.
from mathutils.kdtree import KDTree
kd=KDTree(len(weight_mesh.vertices))
for v in weight_mesh.vertices:kd.insert(v.co,v.index)
kd.balance()
bone_names=set(rig.data.bones.keys())
def bind(ob,bone=None):
    ob.parent=rig
    if bone:
        g=ob.vertex_groups.new(name=bone);g.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    else:
        groups={g.index:g.name for g in body.vertex_groups if g.name in bone_names}
        dest={name:ob.vertex_groups.new(name=name) for name in groups.values()}
        for v in ob.data.vertices:
            _,idx,_=kd.find(v.co)
            for item in weight_mesh.vertices[idx].groups:
                if item.group in groups:dest[groups[item.group]].add([v.index],item.weight,'REPLACE')
    mod=ob.modifiers.new('Skinning','ARMATURE');mod.object=rig

def mesh(name,verts,faces,mat,bone=None):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);data.materials.append(mat)
    for p in data.polygons:p.use_smooth=True
    uv=data.uv_layers.new(name='UVMap')
    for p in data.polygons:
        for li in p.loop_indices:
            co=data.vertices[data.loops[li].vertex_index].co;uv.data[li].uv=(co.x*8,co.z*8)
    bind(ob,bone);return ob

# The himation. CITIZEN_MANTLE=cloth (default): a rectangle of wool dropped onto the shoulders in a
# Blender cloth simulation, so the folds, hem and shoulder drape are physically plausible and the
# garment is baked at rest and skinned like the tunic. 'plate' is the original flat back panel with
# a diagonal front sash (kept for comparison), 'none' leaves the tunic bare.
MANTLE=os.environ.get('CITIZEN_MANTLE','cloth')
def drape_himation():
    nx,ny=40,56
    width,length=float(os.environ.get('CITIZEN_CLOTH_WIDTH','.36')),float(os.environ.get('CITIZEN_CLOTH_LENGTH','.74'))
    centre=(float(os.environ.get('CITIZEN_CLOTH_X','.12')),-.01,float(os.environ.get('CITIZEN_CLOTH_Z','.668')))
    # The neck passes through a hole in the middle of the piece, so it falls onto the shoulders
    # instead of over the head; the offset centre leaves more cloth over the left arm.
    neck=rig.data.bones['neck01'].head_local if 'neck01' in rig.data.bones else Vector((0,0,.7))
    hole=(neck.x,neck.y);hole_radius=.058
    verts=[];faces=[];face_rows=[]
    for j in range(ny+1):
        for i in range(nx+1):
            verts.append((centre[0]-width/2+width*i/nx,centre[1]-length/2+length*j/ny,centre[2]))
    for j in range(ny):
        for i in range(nx):
            k=j*(nx+1)+i
            mx=sum(verts[v][0] for v in (k,k+1,k+nx+2,k+nx+1))/4;my=sum(verts[v][1] for v in (k,k+1,k+nx+2,k+nx+1))/4
            if (mx-hole[0])**2+(my-hole[1])**2<hole_radius**2:continue
            faces.append((k,k+1,k+nx+2,k+nx+1));face_rows.append(j)
    data=bpy.data.meshes.new('Himation_sim');data.from_pydata(verts,[],faces);data.update()
    cloth_ob=bpy.data.objects.new('Himation_sim',data);bpy.context.collection.objects.link(cloth_ob)
    colliders=[body,tunic]+[bpy.data.objects[n] for n in ('Medicine_satchel','Leather_belt','Belt_buckle','Bronze_pin') if n in bpy.data.objects]
    for ob in colliders:
        ob.modifiers.new('Collision','COLLISION')
        ob.collision.thickness_outer=.004;ob.collision.cloth_friction=6.0;ob.collision.use_culling=False
    # The strip lying on the left shoulder is held in place, as the wearer's arm holds a real himation;
    # the rest of the piece falls in front, behind and over the upper arm.
    pin=cloth_ob.vertex_groups.new(name='Pin')
    pin.add([i for i,v in enumerate(verts) if .05<=v[0]<=.115 and abs(v[1]-centre[1])<=.045 and (v[0]-hole[0])**2+(v[1]-hole[1])**2>=hole_radius**2],1.0,'REPLACE')
    cloth=cloth_ob.modifiers.new('Cloth','CLOTH')
    cloth.settings.vertex_group_mass='Pin'
    s=cloth.settings;s.quality=12;s.mass=.35;s.tension_stiffness=40;s.compression_stiffness=40;s.shear_stiffness=20;s.bending_stiffness=9.0;s.air_damping=1.5
    c=cloth.collision_settings;c.use_collision=True;c.distance_min=.006;c.collision_quality=5;c.use_self_collision=False
    frames=int(os.environ.get('CITIZEN_CLOTH_FRAMES','150'))
    sc=bpy.context.scene;sc.frame_start=1;sc.frame_end=frames;cloth.point_cache.frame_start=1;cloth.point_cache.frame_end=frames
    for f in range(1,frames+1):sc.frame_set(f)
    depsgraph=bpy.context.evaluated_depsgraph_get();settled=cloth_ob.evaluated_get(depsgraph)
    final=bpy.data.meshes.new_from_object(settled,depsgraph=depsgraph)
    sc.frame_set(1)
    ob=bpy.data.objects.new('Blue_wool_mantle',final);bpy.context.collection.objects.link(ob)
    bpy.data.objects.remove(cloth_ob)
    for victim in colliders:
        for m in list(victim.modifiers):
            if m.type=='COLLISION':victim.modifiers.remove(m)
    relax=ob.modifiers.new('Relax','SMOOTH');relax.factor=.5;relax.iterations=4
    activate(ob);bpy.ops.object.modifier_apply(modifier=relax.name)
    final=ob.data
    final.materials.clear();final.materials.append(wool);final.materials.append(trim)
    uv=final.uv_layers.new(name='UVMap')
    for p in final.polygons:
        p.use_smooth=True
        row=face_rows[p.index]
        p.material_index=1 if row<2 or row>=ny-2 else 0
        for li in p.loop_indices:
            co=final.vertices[final.loops[li].vertex_index].co;uv.data[li].uv=(co.x*8,co.z*8)
    bind(ob)
    return ob
if MANTLE=='plate':
    # A wool mantle over the left shoulder, across the back and down the opposite hip.
    verts=[];faces=[];rows=28;cols=28
    for row in range(rows+1):
        t=row/rows
        for col in range(cols+1):
            u=col/cols
            # Back mantle hangs naturally; front return runs across the chest.
            x=-.115+.23*u;z=.652-.27*t+.026*math.sin(math.pi*u)
            y=.065+.018*math.sin(math.pi*u)+.014*math.sin(t*math.pi)+.004*math.sin(u*math.pi*14)*(t+.2)
            verts.append((x,y,z))
    for r in range(rows):
        for c in range(cols):
            i=r*(cols+1)+c;faces.append((i,i+1,i+cols+2,i+cols+1))
    mantle=mesh('Blue_wool_mantle',verts,faces,wool)
    mantle.data.materials.append(trim)
    for p in mantle.data.polygons:
        ids=list(p.vertices);p.material_index=1 if any(i%(cols+1)<2 or i%(cols+1)>cols-2 or i//(cols+1)>rows-2 for i in ids) else 0
    activate(mantle);solid=mantle.modifiers.new('Wool_thickness','SOLIDIFY');solid.thickness=.002;bpy.ops.object.modifier_move_up(modifier=solid.name);bpy.ops.object.modifier_apply(modifier=solid.name)
    # Diagonal front sash, fitted clear of chest; separated from the moving arms.
    verts=[];faces=[]
    for r in range(33):
        t=r/32;cx=.077-.145*t;cz=.656-.205*t
        for c in range(9):
            w=(c/8-.5)*.066
            verts.append((cx+w,-.079-.006*math.sin(t*math.pi)-.002*math.sin(c*math.pi/2),cz+w*.65))
    for r in range(32):
        for c in range(8):
            i=r*9+c;faces.append((i,i+1,i+10,i+9))
    sash=mesh('Front_himation_fold',verts,faces,wool);sash.data.materials.append(trim)
    for p in sash.data.polygons:
        p.material_index=1 if p.index%8 in [0,7] else 0

    # Continuous shoulder return connects the mantle to its front fold.
    verts=[];faces=[]
    for r in range(25):
        t=r/24
        for c in range(9):
            x=.077+(c/8-.5)*.078
            verts.append((x,.078-.16*t,.66+.04*math.sin(math.pi*t)+.002*math.sin(c*math.pi/2)))
    for r in range(24):
        for c in range(8):
            i=r*9+c;faces.append((i,i+1,i+10,i+9))
    mesh('Shoulder_return',verts,faces,wool)

def ellipsoid(name,center,scale,mat,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=10,location=center);ob=bpy.context.object;ob.name=name;ob.scale=scale;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);ob.data.materials.append(mat)
    for p in ob.data.polygons:p.use_smooth=True
    bind(ob,bone);return ob
# Leather sandals follow the feet, with soles and two fitted straps each.
for side,sign in [('L',1),('R',-1)]:
    foot=rig.data.bones['foot.'+side];cx=foot.head_local.x
    ellipsoid('Sandal_sole_'+side,(cx,-.045,.006),(.027,.058,.006),leather,'foot.'+side)
    for cy,z in [(-.070,.020),(-.027,.031)]:
        vv=[];ff=[]
        for i in range(17):
            a=math.pi*i/16
            for d in [-.004,.004]:vv.append((cx+.027*math.cos(a),cy+d,z+.012*math.sin(a)))
        for i in range(16):ff.append((i*2,i*2+1,i*2+3,i*2+2))
        mesh('Sandal_strap_'+side,vv,ff,leather,'foot.'+side)
ellipsoid('Bronze_pin',(.072,-.087,.65),(.009,.003,.009),bronze,'spine01')
tan=material('Tanned_leather',(.30,.17,.072),.74)
front_points=[v for v in tunic.data.vertices if v.co.y<.0]
front_tree=KDTree(len(front_points))
for i,v in enumerate(front_points):front_tree.insert((v.co.x,v.co.z,0.0),i)
front_tree.balance()
def front_surface(x,z):
    """Frontmost tunic surface y near a point, from the nearest few vertices."""
    return min(front_points[i].co.y for _,i,_ in front_tree.find_n((x,z,0.0),6))
# The satchel stands clear of the tunic so it reads as an object, not a stain, at game zoom.
ellipsoid('Medicine_satchel',(-.108,front_surface(-.108,.446)-.004,.446),(.034,.027,.045),tan,'spine05')
# (A strap lying on the tunic read as a dark crack at game zoom, so the satchel hangs without a visible one.)
# Thin belt with a small bronze buckle.
verts=[];faces=[]
for i in range(65):
    a=i/64*2*math.pi
    for z in [.464,.471]:verts.append((.091*math.cos(a),.068*math.sin(a),z))
for i in range(64):faces.append((i*2,i*2+1,i*2+3,i*2+2))
mesh('Leather_belt',verts,faces,leather,'spine05')
ellipsoid('Belt_buckle',(0,-.071,.468),(.009,.002,.007),bronze,'spine05')
if MANTLE=='cloth':
    mantle=drape_himation()
# Smooth all source assets and bake skinning-friendly transforms.
for ob in list(bpy.data.objects):
    if ob.type=='MESH':
        for p in ob.data.polygons:p.use_smooth=True
        # Export only four highest bone influences, normalized, to match Godot.
        activate(ob)
        valid={g.index for g in ob.vertex_groups if g.name in bone_names}
        for v in ob.data.vertices:
            influences=sorted([(g.group,g.weight) for g in v.groups if g.group in valid],key=lambda x:-x[1])[:4]
            total=sum(w for _,w in influences)
            for group in list(v.groups):
                if group.group in valid:ob.vertex_groups[group.group].remove([v.index])
            if total:
                for idx,w in influences:ob.vertex_groups[idx].add([v.index],w/total,'REPLACE')
# Author body clips using a planted-foot two-bone solve. Bones, not whole-mesh poses.
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
for p in rig.pose.bones:p.rotation_mode='QUATERNION'

def reset():
    for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)

def orient(name,origin,oldvec,newvec):
    delta=oldvec.rotation_difference(newvec).to_matrix().to_4x4()
    m=delta@rest[name];m.translation=origin;rig.pose.bones[name].matrix=m
    bpy.context.view_layer.update()

def limb(upper,lower,end,target,bend):
    a=rig.pose.bones[upper].head.copy();b=rig.data.bones[lower].head_local.copy();c=rig.data.bones[end].head_local.copy();ar=rig.data.bones[upper].head_local.copy()
    l1=(b-ar).length;l2=(c-b).length;direction=target-a;dist=max(.001,min(direction.length,l1+l2-.0001));axis=direction.normalized()
    plane=Vector(bend)-axis*Vector(bend).dot(axis);plane.normalize()
    along=(l1*l1-l2*l2+dist*dist)/(2*dist);height=math.sqrt(max(0,l1*l1-along*along));elbow=a+axis*along+plane*height
    orient(upper,a,b-ar,elbow-a);orient(lower,elbow,c-b,target-elbow)

def pose(t,walking):
    reset();cycle=t/gait.CYCLE if walking else t/3.0;phase=cycle*math.tau
    root=rest['root'].copy()
    if walking:
        shift,drop,twist,roll=gait.body(cycle)
        origin=root.translation.copy()+Vector((shift,0,drop))
        root=Euler((.018,roll,twist),'XYZ').to_matrix().to_4x4()@root
        root.translation=origin
    else:root.translation+=Vector((.001*math.sin(phase),0,-.002))
    rig.pose.bones['root'].matrix=root;bpy.context.view_layer.update()
    if walking:
        # Shoulders counter-rotate the pelvis; keep the head quieter than the torso.
        rig.pose.bones['spine05'].rotation_quaternion=Euler((0,-.008*math.sin(phase),.045*math.cos(phase)),'XYZ').to_quaternion()
        bpy.context.view_layer.update()
    for side,sign in [('L',1),('R',-1)]:
        p=(cycle+(0 if side=='L' else .5))%1
        foot_name='foot.'+side
        foot_rest=rig.data.bones[foot_name].head_local
        if walking:
            y,lift,pitch=gait.foot(p)
            contact_y,contact_z=gait.sole_contact(pitch,foot_rest.y,foot_rest.z)
            flat_y,_=gait.sole_contact(0,foot_rest.y,foot_rest.z)
            y-=contact_y-flat_y
            height=-contact_z+.0005+lift
        else:y=-.009;height=foot_rest.z+.0005;pitch=0
        target=Vector((.077*sign,y,height))
        limb('upperleg01.'+side,'lowerleg01.'+side,foot_name,target,(0,-1,0))
        m=Matrix.Rotation(pitch,4,'X')@rest[foot_name];m.translation=target;rig.pose.bones[foot_name].matrix=m
        sway=.065*math.cos(phase+(0 if side=='L' else math.pi)) if walking else .003*math.sin(phase+sign)
        hand=Vector((.128*sign,-.025+sway,.418+(.006*math.cos(phase*2) if walking else 0)))
        limb('upperarm01.'+side,'lowerarm01.'+side,'wrist.'+side,hand,(sign*.3,1,0))
    rig.pose.bones['head'].rotation_quaternion=Euler((.003*math.sin(phase*2),-.006*math.sin(phase),-.012*math.cos(phase)),'XYZ').to_quaternion()
    for side in ['L','R']:
        p=rig.pose.bones['eye.'+side];p.rotation_mode='XYZ';p.rotation_euler.z=.01*math.sin(phase)
    if not walking:
        rig.pose.bones['spine01'].scale=(1+.003*math.sin(t*2*math.pi/3),1,1+.002*math.sin(t*2*math.pi/3))
    bpy.context.view_layer.update()

scene=bpy.context.scene;scene.render.fps=100
rig.animation_data_create()
for name,duration in [('Idle',3.0),('Walk',.64)]:
    action=bpy.data.actions.new(name);rig.animation_data.action=action
    frames=round(duration*scene.render.fps)
    for i in range(frames+1):
        scene.frame_set(i+1);pose(i/scene.render.fps,name=='Walk')
        for p in rig.pose.bones:
            p.keyframe_insert('location',frame=i+1,group=p.name)
            p.keyframe_insert('rotation_euler' if p.rotation_mode=='XYZ' else 'rotation_quaternion',frame=i+1,group=p.name)
            p.keyframe_insert('scale',frame=i+1,group=p.name)
    track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action)
    rig.animation_data.action=None;track.mute=True
reset();scene.frame_set(1)
# Native convention is +Y forward in Blender; MPFB is -Y forward.
rig.rotation_euler.z=math.pi
rig.scale=(gait.RIG_SCALE,)*3
bpy.context.view_layer.update()
# Right-sized textures: the skin carries the face at maximum zoom; everything else is small.
TEXTURE_LIMIT=[('diffuse',2048),('short01',1024),('brown_eye',512),('eyebrow',256),('eyelashes',256)]
for im in bpy.data.images:
    if im.source=='FILE':
        limit=next((n for key,n in TEXTURE_LIMIT if key in im.name.lower()),512)
        if max(im.size)>limit:im.scale(limit,limit)
        im.pack()
activate(rig)
for ob in rig.children_recursive:
    if ob.type=='MESH':ob.select_set(True)
scene.frame_start=1;scene.frame_end=round(3*scene.render.fps)+1
# Experimental builds keep their .blend outside the Godot project (Godot would try to import it).
blend_path=ROOT/'physician_v2.blend'
if os.environ.get('CITIZEN_OUT'):
    (ROOT/'experiments').mkdir(exist_ok=True);blend_path=ROOT/'experiments'/(OUT.name+'.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
# Optional Workbench previews of the costume (CITIZEN_PREVIEW=directory): front, rear and three-quarter
# views at rest and mid-stride. CITIZEN_PREVIEW_ONLY=1 stops before any export.
if os.environ.get('CITIZEN_PREVIEW'):
    PREVIEW=Path(os.environ['CITIZEN_PREVIEW']);PREVIEW.mkdir(parents=True,exist_ok=True)
    scene.render.engine='BLENDER_WORKBENCH';scene.render.resolution_x=700;scene.render.resolution_y=1000
    scene.display.shading.light='STUDIO';scene.display.shading.color_type='MATERIAL'
    cam_data=bpy.data.cameras.new('PreviewCam');cam_data.lens=70;cam=bpy.data.objects.new('PreviewCam',cam_data);bpy.context.collection.objects.link(cam);scene.camera=cam
    for label,walking,t,angle in [('front-rest',False,0,0),('rear-rest',False,0,180),('side-rest',False,0,90),('front-walk',True,.16,0),('rear-walk',True,.16,180)]:
        pose(t,walking)
        a=math.radians(angle)
        # The armature is rotated by pi about Z, so the citizen faces world +Y (angle 0 = front).
        centre=Vector((0,0,.47));direction=Vector((math.sin(a),math.cos(a),0.0))
        cam.location=centre+direction*2.2
        cam.rotation_euler=(centre-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(PREVIEW/(label+'.png'));bpy.ops.render.render(write_still=True)
    reset()
    if os.environ.get('CITIZEN_PREVIEW_ONLY'):
        print('PREVIEW_DONE',PREVIEW,flush=True);sys.exit(0)
bpy.ops.export_scene.gltf(filepath=str(OUT/'physician.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_morph=True,export_morph_normal=True,export_skins=True,export_all_influences=False,export_apply=False,export_yup=True)
# ---------------------------------------------------------------------------------------
# Crowd level of detail: the same citizen as ~4.5K vertices with colours baked from the
# textures, and its Idle/Walk poses stored as morph targets (24 walk + 12 idle samples,
# the format of every other walker). tools/bake_walker_vat.py turns it into pose textures.
# Skeletal evaluation and per-instance skinning buffers are far too heavy for a crowd.
# ---------------------------------------------------------------------------------------
CROWD_VERTICES=int(os.environ.get('CITIZEN_CROWD_VERTICES','4500'))
CROWD_OUT=Path(os.environ['CITIZEN_OUT']) if os.environ.get('CITIZEN_OUT') else REPO/'godot/assets/models'
CROWD_NAME='physician_crowd'

def image_array(im):
    px=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(px);return px.reshape(-1,4)

def vertex_colours(ob):
    """Average colour of each vertex: the base-colour texture at its UV, or the material colour."""
    me=ob.data;n=len(me.vertices)
    loops=np.empty(len(me.loops),dtype=np.int32);me.loops.foreach_get('vertex_index',loops)
    totals=np.empty(len(me.polygons),dtype=np.int32);me.polygons.foreach_get('loop_total',totals)
    mats=np.empty(len(me.polygons),dtype=np.int32);me.polygons.foreach_get('material_index',mats)
    loop_mat=np.repeat(mats,totals)
    uv=np.zeros(len(me.loops)*2,dtype=np.float32)
    if me.uv_layers.active:me.uv_layers.active.data.foreach_get('uv',uv)
    uv=uv.reshape(-1,2)
    colour=np.ones((len(me.loops),3),dtype=np.float32)
    for index,material in enumerate(me.materials):
        mask=loop_mat==index
        if not mask.any() or material is None:continue
        shader=next((nd for nd in material.node_tree.nodes if nd.type=='BSDF_PRINCIPLED'),None)
        base=tuple(shader.inputs['Base Color'].default_value)[:3] if shader else (.5,.5,.5)
        link=next((l for l in material.node_tree.links if l.to_node==shader and l.to_socket.name=='Base Color'),None) if shader else None
        if link is not None and link.from_node.type=='TEX_IMAGE' and link.from_node.image is not None and me.uv_layers.active:
            im=link.from_node.image;w,h=im.size;px=image_array(im)
            if 'hair' in material.name.lower():
                opaque=px[px[:,3]>.5];colour[mask]=opaque[:,:3].mean(axis=0) if len(opaque) else base
            else:
                x=np.clip((uv[mask,0]%1.0*w).astype(np.int32),0,w-1);y=np.clip((uv[mask,1]%1.0*h).astype(np.int32),0,h-1)
                colour[mask]=px[y*w+x,:3]
        else:colour[mask]=base
    total=np.zeros((n,3),dtype=np.float64);count=np.zeros(n,dtype=np.float64)
    np.add.at(total,loops,colour);np.add.at(count,loops,1)
    return (total/np.maximum(count,1)[:,None]).astype(np.float32)

SKIP_FOR_CROWD={'Human_high-poly','Human_eyebrow001','Human_eyelashes01'}
sources=[ob for ob in rig.children_recursive if ob.type=='MESH' and ob.name not in SKIP_FOR_CROWD]
copies=[]
for ob in sources:
    colour=vertex_colours(ob)
    copy=ob.copy();copy.data=ob.data.copy();bpy.context.collection.objects.link(copy)
    for mod in list(copy.modifiers):
        if mod.type=='ARMATURE':copy.modifiers.remove(mod)
    if copy.data.shape_keys:                 # blink shapes belong to the close-up model only
        copy.shape_key_clear()
    layer=copy.data.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='POINT')
    rgba=np.ones((len(colour),4),dtype=np.float32);rgba[:,:3]=colour
    layer.data.foreach_set('color',rgba.ravel())
    copies.append(copy)
for ob in bpy.context.scene.objects:ob.select_set(False)
for copy in copies:copy.select_set(True)
bpy.context.view_layer.objects.active=copies[0]
bpy.ops.object.join()
crowd=bpy.context.view_layer.objects.active;crowd.name=CROWD_NAME;crowd.data.name=CROWD_NAME
for ob in bpy.data.objects:
    if ob is not crowd:ob.select_set(False)
crowd.parent=None;crowd.matrix_world=Matrix.Identity(4)
decimate=crowd.modifiers.new('Crowd_LOD','DECIMATE');decimate.ratio=min(1.0,CROWD_VERTICES/len(crowd.data.vertices))
bpy.ops.object.modifier_apply(modifier=decimate.name)
cmat=bpy.data.materials.new('Crowd_cloth');cmat.use_nodes=True
bsdf=next(nd for nd in cmat.node_tree.nodes if nd.type=='BSDF_PRINCIPLED');bsdf.inputs['Roughness'].default_value=.8
vcol=cmat.node_tree.nodes.new('ShaderNodeVertexColor');vcol.layer_name='Col';cmat.node_tree.links.new(vcol.outputs['Color'],bsdf.inputs['Base Color'])
crowd.data.materials.clear();crowd.data.materials.append(cmat)
for p in crowd.data.polygons:p.use_smooth=True;p.material_index=0
bind(crowd)                      # skin weights from the nearest source vertex, as for the tunic
# Evaluate the animated mesh in world space for every sample, then keep them as morph targets.
M=np.array(rig.matrix_world)
def evaluate():
    bpy.context.view_layer.update()
    evaluated=crowd.evaluated_get(bpy.context.evaluated_depsgraph_get());me=evaluated.to_mesh()
    co=np.empty(len(me.vertices)*3,dtype=np.float32);me.vertices.foreach_get('co',co);evaluated.to_mesh_clear()
    co=co.reshape(-1,3);return (co@M[:3,:3].T+M[:3,3]).astype(np.float32)
walk_frames=[];idle_frames=[]
for frame in range(24):
    pose(frame/24*.64,True);walk_frames.append(evaluate())
for frame in range(12):
    pose(frame/12*3.0,False);idle_frames.append(evaluate())
reset()
crowd.modifiers.remove(next(m for m in crowd.modifiers if m.type=='ARMATURE'))
for group in list(crowd.vertex_groups):crowd.vertex_groups.remove(group)
crowd.parent=None;crowd.matrix_world=Matrix.Identity(4)   # the samples are already in world space
crowd.data.vertices.foreach_set('co',walk_frames[0].ravel());crowd.data.update()
crowd.shape_key_add(name='Basis')
for label,frames,first in [('walk',walk_frames,1),('idle',idle_frames,0)]:
    for index in range(first,len(frames)):
        key=crowd.shape_key_add(name=f'{label}_{index:02}');key.data.foreach_set('co',frames[index].ravel())
box=np.array([v.co[:] for v in crowd.data.vertices]);low,high=box.min(axis=0),box.max(axis=0)
for ob in bpy.context.scene.objects:ob.select_set(False)
crowd.select_set(True);bpy.context.view_layer.objects.active=crowd
CROWD_OUT.mkdir(parents=True,exist_ok=True)
available=set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())
options=dict(filepath=str(CROWD_OUT/(CROWD_NAME+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_skins=False,export_morph=True,export_morph_normal=False,export_cameras=False,export_lights=False,export_yup=True,export_apply=False)
if 'export_vertex_color' in available:options['export_vertex_color']='ACTIVE'
if 'export_active_vertex_color_when_no_material' in available:options['export_active_vertex_color_when_no_material']=True
bpy.ops.export_scene.gltf(**options)
crowd_path=CROWD_OUT/(CROWD_NAME+'.glb')
crowd_manifest={'asset':CROWD_NAME,'source':'art/characters/citizen_v2/physician_v2.blend','file':CROWD_NAME+'.glb','bytes':crowd_path.stat().st_size,
 'vertices':len(crowd.data.vertices),'surfaces':1,'bounds_blender':[[float(x) for x in low],[float(x) for x in high]],'walk_samples':24,'idle_samples':12,'stride_tiles':.64,
 'rights_status':'needs_evidence','material_mode':'vertex_colours_baked_from_citizen_textures','idle_mode':'breathing','generator':'tools/build_citizen_benchmark.py',
 'lod_of':'physician_v2','native_asset':'physician','gait_revision':'contact_roll_v1','stance_fraction':gait.STANCE}
(CROWD_OUT/(CROWD_NAME+'.json')).write_text(json.dumps(crowd_manifest,indent=2)+'\n')
print('CROWD_EXPORT',crowd_path,crowd_path.stat().st_size,len(crowd.data.vertices),'vertices',flush=True)

path=OUT/'physician.glb'
manifest={'revision':'textured_skeletal_citizen_v2','native_asset':'physician','file':'physician.glb','bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source':'art/characters/citizen_v2/physician_v2.blend','generator':'tools/build_citizen_benchmark.py','source_libraries':json.loads((VENDOR/'downloads.json').read_text()),'source_asset_license':'CC0-1.0','project_authored':['Greek clothing adaptation','mantle','sandals','satchel','PBR detail maps','Idle and Walk clips'],'animation':{'type':'skeletal','clips':['Idle','Walk'],'stride_tiles':.64,'walk_seconds':.64,'gait_revision':'contact_roll_v1','stance_fraction':gait.STANCE,'source_rig_stride':gait.STRIDE/gait.RIG_SCALE,'bone_sample_hz':100,'facial_shapes':['Blink_L','Blink_R']},'visual_acceptance':'pending_user_review','scope':'single physician benchmark; other roles retain their current assets'}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
print('CITIZEN_EXPORT',path,path.stat().st_size,flush=True)
