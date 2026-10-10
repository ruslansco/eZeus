"""Anatomical monster rebuild: real CC0 humans, species lofts, CC-BY lion head.

Only Godot art and fixed-topology pose samples. Never opens the live Blender
scene, executes vendor scripts, or changes simulation/native sprite recipes.
"""
import math
import sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector, Matrix
from godot_hydra import spline, linear, paint, smooth
from godot_monster_reference import Sculpt, REVISION, VERTEX_BUDGET
import animal as AN
import human as HU

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'art/characters/animals'))
import species as SP
DESIGN_REVISION = 'monster_anatomy_v3'
HEAD_CACHE = {}


def subset(ob, keep, rest=None, weights=None):
    """Cut at anatomical boundaries while preserving source vertex/skin identity."""
    co = np.array([v.co[:] for v in ob.data.vertices]) if rest is None else rest
    faces = [tuple(p.vertices) for p in ob.data.polygons if all(keep[i] for i in p.vertices)]
    idx = sorted({i for f in faces for i in f}); lookup = {v:i for i,v in enumerate(idx)}
    materials = list(ob.data.materials)
    mesh = bpy.data.meshes.new(ob.name+' anatomical cut')
    mesh.from_pydata(co[idx], [], [tuple(lookup[i] for i in f) for f in faces])
    for m in materials: mesh.materials.append(m)
    for p in mesh.polygons:p.use_smooth=True
    ob.data = mesh
    return np.array(co[idx]), None if weights is None else weights[idx]


class Anatomy(Sculpt):
    def __init__(self, K, kind):
        super().__init__(K,kind)
        self.animals=[]; self.people=[]; self.bone_nodes=[]; self.head_motion=[]
        self.contact=[]; self.wing_rest=[]; self.dynamic=[]
        self.face_deforms=[]
        self.base_z=0

    def material(self,label,rgb,rough=.75,metal=0):
        return self.K.material('Monster '+label,linear(rgb),rough=rough,metal=metal)

    def crop_part(self, H, part, keep):
        part.rest,part.W=subset(part.ob,keep,part.rest,part.W)

    def human(self,kind=None,loc=(0,0,0),scale=1,head_only=False,torso_only=False):
        kind=kind or self.kind
        female=kind in ('medusa','maenads','harpies','sphinx','echidna','scylla')
        garment='chiton' if kind=='medusa' else 'exomis' if kind=='maenads' else 'perizoma'
        skin=self.rgb if kind not in ('sphinx','scylla','echidna') else (.65,.45,.31)
        H=HU.Human(self.K,None,'Anatomical '+kind,self.mats['cloth'],parent=self.root,
                   loc=loc,garment=garment,sex='female' if female else 'male',beard=kind=='satyr',
                   skin=linear(skin),hair=linear((.15,.068,.028)),seed=61026,fists=kind=='hector')
        H.root.scale=(scale,)*3
        H.skin_m.name='Monster '+('metal bronze body' if kind=='talos' else 'skin anatomical body')
        H.hair_m.name='Monster fur anatomical hair'
        for p in H.parts:
            mat=p.ob.active_material
            if mat and ' eye' in mat.name:mat.name='Monster eyes natural eyes'
            if mat and 'beard' in mat.name:mat.name='Monster fur beard'
            if mat and ('sandal' in mat.name.lower() or 'leather' in mat.name.lower()):mat.name='Monster horn leather'
        for p in list(H.parts):
            name=p.ob.name.lower()
            if head_only:
                self.crop_part(H,p,p.rest[:,2]>.710)
            elif torso_only:
                self.crop_part(H,p,p.rest[:,2]>.405)
                if 'perizoma' in name or 'girdle' in name:p.ob.hide_render=True
            elif kind in ('minotaur','satyr') and p is H.parts[0]:
                keep=p.rest[:,2]>.045
                if kind=='minotaur':keep &= p.rest[:,2]<.754
                self.crop_part(H,p,keep)
            if kind in ('minotaur','talos') and any(t in name for t in ('eye','hair','beard','bun')):p.ob.hide_render=True
            if kind in ('minotaur','satyr') and 'sandal' in name:p.ob.hide_render=True
            if kind=='harpies':
                if p is H.parts[0]:
                    arms=sum(p.W[:,H.bi[b]] for b in H.bones if b.startswith(('upper','fore','hand')))
                    self.crop_part(H,p,(arms<.38)&(p.rest[:,2]>.12))
                if 'perizoma' in name or 'sandal' in name:p.ob.hide_render=True
            if kind=='medusa' and 'chiton' in name:
                # Slit exposes a leg instead of a rigid cone around both legs.
                self.crop_part(H,p,~((p.rest[:,2]<.405)&(p.rest[:,0]>.014)&(p.rest[:,1]>.006)))
            if kind=='cyclops':
                if 'eye' in name:p.ob.hide_render=True
                if p is H.parts[0]:
                    co=p.rest.copy(); upper=np.clip((co[:,2]-.46)/.18,0,1)
                    co[:,0]*=1.22+.14*upper;co[:,1]*=1.12
                    p.rest=co
            if kind in ('satyr','minotaur') and p is H.parts[0]:
                co=p.rest.copy();upper=np.clip((co[:,2]-.42)/.15,0,1)
                co[:,0]*=1.16+(.26*upper if kind=='minotaur' else 0)
                co[:,1]*=1.08+(.12*upper if kind=='minotaur' else 0);p.rest=co
            if len(p.rest)==0:p.ob.hide_render=True
        self.people.append((H,kind,Vector(loc),scale))
        if not head_only and not torso_only:
            for side in (-1,1):self.contact.append(('human',H,side))
        node=self.K.empty(kind+' skull attachments',H.root)
        self.bone_nodes.append((node,H,'head'))
        # The body already has an anatomical face and modest eyeballs.
        if kind!='minotaur':
            jaw=self.K.empty('Anatomical mouth anchor',node)
            self.heads.append((node,jaw,Vector((0,.049,.762))))
        return H,node

    def joint_node(self,H,bone,name):
        node=self.K.empty(name,H.root);self.bone_nodes.append((node,H,bone));return node

    def cloven_foot(self,parent,p,label,size=1):
        # Horn hoof walls have a flat sole and a real interdigital cleft.
        for side in (-1,1):
            vertices=[];n=12
            for z,rx,ry in ((-.015,.020,.041),(-.007,.023,.043),(.025,.022,.036),(.047,.016,.026)):
                for i in range(n):
                    a=math.tau*i/n
                    vertices.append(p+Vector((size*(side*.024+rx*math.cos(a)),size*(.018+ry*math.sin(a)),size*z)))
            faces=[(row*n+i,row*n+(i+1)%n,(row+1)*n+(i+1)%n,(row+1)*n+i) for row in range(3) for i in range(n)]
            faces += [tuple(reversed(range(n))),tuple(range(3*n,4*n))]
            self.K.mesh(label+' horn hoof wall',vertices,faces,self.mats['horn'],parent,True)

    def human_attach(self,H,ob,bone):
        bpy.context.view_layer.update()
        mw=ob.matrix_basis.copy()
        for v in ob.data.vertices:v.co=mw@v.co
        ob.location=(0,0,0);ob.rotation_euler=(0,0,0);ob.scale=(1,1,1)
        H.attach(ob,bone)

    def anatomical_shell(self,H,z0,z1,mat,name,offset=.003):
        co=H.body_rest.copy()
        co=co+H.normals*offset
        ob=self.K.mesh(name,co,H.polys,mat,H.root,True)
        arms=sum(H.A['weights'][:,H.bi[b]] for b in H.bones if b.startswith(('upper','fore','hand')))
        keep=(co[:,2]>z0)&(co[:,2]<z1)&(arms<.16)
        rest,W=subset(ob,keep,co,H.A['weights'])
        H._add(ob,rest,W)
        return ob

    def feather(self,parent,start,end,width,mat):
        a,b=Vector(start),Vector(end);axis=b-a
        side=Vector((0,1,0));normal=axis.cross(side).normalized()
        if normal.length<.1:normal=Vector((0,0,1))
        verts=[];n=10
        for i in range(n):
            u=i/(n-1);c=a.lerp(b,u)+normal*(.015*math.sin(math.pi*u))
            w=width*math.sin(math.pi*(.08+.92*u))**.65
            verts.extend([c-side*w,c+normal*.004,c+side*w*.85])
        faces=[(j*3+k,j*3+k+1,(j+1)*3+k+1,(j+1)*3+k) for j in range(n-1) for k in range(2)]
        return self.K.mesh('Overlapping pennaceous feather',verts,faces,mat,parent,True)

    def eagle_wings(self,parent,level=.62,span=.66):
        shades=[self.material('fur flight feather '+str(i),(.13+i*.035,.10+i*.024,.083+i*.018),.91) for i in range(4)]
        for side in (-1,1):
            w=self.K.empty('Eagle shoulder elbow wrist',parent,(side*.14,-.03,level))
            self.horn(w,[(0,0,0),(side*span*.47,-.055,.16),(side*span*.84,-.06,.15)],.034,'fur','Feathered leading edge')
            for i in range(15):
                u=i/14
                start=(side*span*(.22+.64*u),-.04,.13+.045*math.sin(math.pi*u))
                end=(side*span*(.26+.87*u),-.23-.14*(1-u),-.09+.17*u)
                self.feather(w,start,end,.036*(1.1-.2*u),shades[i%4])
            for row in range(2):
                for i in range(12):
                    u=i/11
                    self.feather(w,(side*span*(.10+.73*u),.007-row*.033,.13-row*.045),
                                 (side*span*(.19+.76*u),-.13-row*.045,.008-row*.050),.026,shades[(i+row)%4])
            self.wings.append((w,side))

    def library_head(self,style,parent,pos,size=1):
        """Real species skull geometry, scaled around its poll; no sphere face."""
        if style in ('lion','dog'):return self.real_predator_head(style,parent,pos,size)
        if style not in HEAD_CACHE:
            if style=='lion':
                a=np.load(ROOT/'art/monsters/anatomy-v3/vendor/cave_lion_base.npz')
                co=a['co'].astype(float);co[:,1]*=-1
                faces=HU.Human._polys(a['face_len'],a['face_idx'])
            else:
                spec={'dog':SP._wolf,'goat':SP._goat,'bull':SP._cattle}[style]()
                spec['voxel']=.010
                temp=AN.Animal(self.K,spec,'Temporary '+style+' anatomical skull')
                co=temp.co.copy();polys=[tuple(p.vertices) for p in temp.body_ob.data.polygons]
                cutoff=(temp.J['neck_mid'].y+temp.J['poll'].y)*.5
                faces=[f for f in polys if all(co[i,1]>cutoff for i in f)]
                idx=sorted({i for f in faces for i in f});mp={v:i for i,v in enumerate(idx)}
                co=co[idx];faces=[tuple(mp[i] for i in f) for f in faces]
                for o in list(temp.root.children_recursive)+[temp.root]:bpy.data.objects.remove(o,do_unlink=True)
            # consistent local dimensions; the original species ratios are retained
            lo=co.min(0);hi=co.max(0);factor=.34/(hi[1]-lo[1])
            co[:,0]-=(lo[0]+hi[0])*.5;co[:,1]-=lo[1]+(hi[1]-lo[1])*.25
            co[:,2]-=(lo[2]+hi[2])*.5
            HEAD_CACHE[style]=(co*factor,faces)
        co,faces=HEAD_CACHE[style]
        h=self.K.empty('Real '+style+' skull',parent,pos);h.scale=(size,)*3
        if style=='goat':h.scale=(size*.58,)*3
        self.K.mesh('Anatomical '+style+' craniofacial surface',co,faces,self.mats['skin'],h,True)
        # Recessed dark lip line follows the muzzle; canine jaw is articulated.
        jaw=self.K.empty(style+' jaw hinge',h,(0,.05,-.067))
        self.tube(style+' mandible',[(0,0,0),(0,.085,-.018),(0,.155,-.013)],[(.053,.026),(.054,.025),(.040,.014)],parent=jaw,ring=12)
        self.tube(style+' recessed lip line',[(0,.045,-.05),(0,.12,-.077),(0,.19,-.076)],[(.054,.007),(.055,.006),(.040,.004)],'mouth',h,12)
        self.ell(style+' rhinarium',(0,.238,-.009),(.043,.022,.025),'horn',h,2)
        for side in (-1,1):
            self.ell(style+' recessed eye',(side*.074,.079,.053),(.014,.010,.011),'eyes',h,2)
            self.ell(style+' pupil',(side*.080,.085,.053),(.004,.004,.008),'horn',h,1)
            ear=[(side*.058,-.065,.057),(side*.128,-.068,.106),(side*.106,-.010,.127),(side*.052,-.012,.082)]
            self.K.mesh(style+' anatomical ear',ear,[(0,1,2,3)],self.mats['fur' if style=='lion' else 'skin'],h,True)
            if style in ('dog','lion'):
                for y in (.105,.155):
                    self.horn(h,[(side*.042,y,-.06),(side*.037,y+.008,-.104)],.010,'teeth','Carnivore canine')
                    self.horn(jaw,[(side*.040,y,-.018),(side*.037,y+.005,.010)],.007,'teeth','Mandibular tooth')
            if style in ('goat','bull'):
                if style=='bull':points=[(side*.074,-.040,.082),(side*.20,-.07,.10),(side*.29,-.015,.20),(side*.20,.08,.27)]
                else:points=[(side*.065,-.045,.09),(side*.16,-.12,.18),(side*.18,-.13,.04),(side*.085,-.07,.018)]
                self.horn(h,points,.037,'horn','Bovine swept horn' if style=='bull' else 'Caprine curled horn')
        self.heads.append((h,jaw,Vector((0,.23,-.073))))
        if style=='lion':
            for i in range(32):
                a=math.tau*i/32;x=.105*math.cos(a);z=.108*math.sin(a)
                self.feather(h,(x,-.06,z),(x*1.64,-.16,z*1.9-.025),.035,self.mats['fur'])
        return h

    def real_predator_head(self,style,parent,pos,size):
        h=self.K.empty('Library '+style+' craniofacial anatomy',parent,pos);h.scale=(size,)*3
        if style=='lion':
            a=np.load(ROOT/'art/monsters/anatomy-v3/vendor/lion_face.npz')
            source=a['Lion_low_co'];center=np.array([0,-.89,.985]);factor=.56
            def transform(co):
                out=(co-center)*factor;out[:,1]*=-1;return out
            jawpivot=transform(a['jaw_pivot'][None])[0]
            mouth=transform(np.array([[0,-1.14,.85]]))[0]
            for label,mat,opening in [('Lion_low','skin',True),('Eye.001','eyes',False),('Iris.001','horn',False),('teeth_low','teeth',True),('teeth_low.001','teeth',False),('LowerJaw_low','mouth',True),('UpperJaw_low','mouth',False)]:
                co=transform(a[label+'_co']);polys=HU.Human._polys(a[label+'_face_len'],a[label+'_face_idx'])
                if label=='Lion_low':
                    keep=a[label+'_co'][:,1]<-.805
                    polys=[f for f in polys if all(keep[i] for i in f)]
                ob=self.K.mesh('Library lion '+label,co,polys,self.mats[mat],h,True)
                if opening:
                    weights=a['jaw_weight'] if label=='Lion_low' else np.ones(len(co))
                    self.face_deforms.append((ob,co,weights,jawpivot))
            # Dense overlapping locks cover a continuous mane, rather than spokes.
            mane=self.material('fur lion mane',(.33,.16,.053),.94)
            self.K.mesh('Lion continuous mane mantle',
                *AN.loft([(0,-.12,-.03),(0,-.06,-.035),(0,.004,-.036),(0,.035,-.015)],[(.11,.14,.15,0),(.145,.155,.18,0),(.13,.14,.17,0),(.07,.075,.08,0)],n=28,per=3),mane,h,True)
            for j in range(3):
                for i in range(22):
                    ang=math.tau*i/22
                    root=Vector((.118*math.cos(ang),-.025-j*.031,.132*math.sin(ang)-.034))
                    tip=root+Vector((.015*math.cos(ang),-.036,-.031))
                    self.feather(h,root,tip,.019,mane)
        else:
            a=np.load(ROOT/'art/monsters/anatomy-v3/vendor/wolf_base.npz')
            source=a['dog2_co'];center=np.array([0,-1.23,2.45]);factor=.21
            def transform(co):
                out=(co-center)*factor;out[:,1]*=-1;out[:,0]*=1.25
                # Mastiff: wider muzzle and folded, short ears rather than wolf pinnas.
                high=out[:,2]>.05;out[high,2]=.05+(out[high,2]-.05)*.38
                out[:,1]=np.where(out[:,1]>.055,.055+(out[:,1]-.055)*.8,out[:,1])
                return out
            co=transform(source);polys=HU.Human._polys(a['dog2_face_len'],a['dog2_face_idx'])
            keep=(source[:,1]<-1.0)&(source[:,2]>2.15)
            polys=[f for f in polys if all(keep[i] for i in f)]
            ob=self.K.mesh('CC0 canine craniofacial mesh',co,polys,self.mats['skin'],h,True)
            self.face_deforms.append((ob,co,a['jaw_weight'],transform(np.array([[0,-1.355,2.43]]))[0]))
            # Source landmarks locate restrained eyes inside their real sockets.
            for side in (-1,1):
                p=transform(np.array([[side*.149,-1.588,2.653]]))[0]
                self.ell('Canine recessed red iris',p,(.007,.004,.006),'eyes',h,2)
                self.ell('Canine pupil',p+np.array([0,.003,0]),(.002,.002,.004),'horn',h,1)
            for side in (-1,1):
                self.horn(h,[(side*.026,.105,-.023),(side*.022,.115,-.041)],.0045,'teeth','Canine maxillary fang')
            mouth=np.array([0,.14,-.036])
            # Vertex colour carries natural nose/lip contrast from the original UVs.
            image=bpy.data.images.load(str(ROOT/'art/monsters/anatomy-v3/vendor/newdlc-wolf/dog2Color.png'),check_existing=True)
            width,height=image.size;pixels=np.array(image.pixels[:]).reshape(height,width,4)
            uv=a['uv'];tex=pixels[np.clip((uv[:,1]*height).astype(int),0,height-1),np.clip((uv[:,0]*width).astype(int),0,width-1),:3]
            shade=np.clip(tex.mean(1),.035,.8)
            colour=np.array(linear(self.rgb))[None]*(.38+1.4*shade[:,None])
            for label in ('b_RightEye','b_LeftEye'):
                if label+'_weight' in a:
                    mask=a[label+'_weight']>.90
                    colour[mask]=linear((.028,.019,.016))
            attr=ob.data.color_attributes.new('Coat colour','FLOAT_COLOR','POINT');attr.data.foreach_set('color',np.c_[colour,np.ones(len(co))].ravel())
        jaw=self.K.empty('Library jaw pose anchor',h)
        self.heads.append((h,jaw,Vector(mouth)))
        return h

    def crocodile_head(self,parent,pos):
        a=np.load(ROOT/'art/monsters/anatomy-v3/vendor/crocodile_base.npz')
        src=a['Crocodile_co'];polys=HU.Human._polys(a['Crocodile_face_len'],a['Crocodile_face_idx'])
        keep=src[:,1]<-1.75
        polys=[f for f in polys if all(keep[i] for i in f)]
        co=(src-np.array([0,-2.50,.70]))*.105;co[:,1]*=-1
        # The source contains one sculpted half; mirror it into a complete skull.
        mirrored=co.copy();mirrored[:,0]*=-1
        faces=polys+[tuple(len(co)+i for i in reversed(f)) for f in polys]
        h=self.K.empty('Crocodilian osteology skull',parent,pos)
        ob=self.K.mesh('CC0 crocodile cranial planes',np.vstack([co,mirrored]),faces,self.mats['skin'],h,True)
        jaw=self.K.empty('Crocodilian jaw hinge',h,(0,0,-.025))
        self.tube('Crocodilian mandible',[(0,0,0),(0,.09,-.008),(0,.21,-.004)],[(.046,.017),(.041,.014),(.024,.010)],parent=jaw,ring=14)
        for side in (-1,1):
            self.ell('Crocodilian recessed eye',(side*.043,.008,.049),(.010,.008,.005),'eyes',h,2)
            for j in range(8):
                y=.026+j*.022;x=side*(.044-.0024*j)
                self.horn(h,[(x,y,-.020),(x,y+.005,-.037)],.0035,'teeth','Crocodilian conical tooth')
            self.horn(h,[(side*.028,-.055,.065),(side*.060,-.10,.14),(side*.066,-.07,.18)],.019,'horn','Dragon temporal horn')
        self.heads.append((h,jaw,Vector((0,.22,-.025))))
        return h

    def quadruped(self,style):
        spec=SP._boar() if style=='boar' else SP._wolf()
        if style=='boar':
            spec['joints']={key:(x*1.35,y,z) for key,(x,y,z) in spec['joints'].items()}
            spec['body_radii']=[tuple(v*(1.35 if i==0 else 1) for i,v in enumerate(r)) for r in spec['body_radii']]
            for key in ('fore_leg','hind_leg'):
                spec[key]['centres']=[(x*1.35,y,z) for x,y,z in spec[key]['centres']]
                spec[key]['radii']=[tuple(v*1.48 for v in r) for r in spec[key]['radii']]
        if style!='boar':
            # Rib cage, withers and hocks remain separate anatomical landmarks.
            for key in ('fore_leg','hind_leg'):
                spec[key]['radii']=[tuple(v*(1.25 if i<3 else 1) for i,v in enumerate(r)) for r in spec[key]['radii']]
            for j,r in enumerate(spec['body_radii']):
                spec['body_radii'][j]=tuple(v*(2.15 if style=='dog' and i==0 else 1.60 if i==0 else 1.15 if i<3 else 1) for i,v in enumerate(r))
            if style in ('reptile','lion'):
                spec['body_centres']=[(x,y*1.12,z) for x,y,z in spec['body_centres']]
                spec['joints']={k:(x,y*1.12,z) for k,(x,y,z) in spec['joints'].items()}
                for key in ('fore_leg','hind_leg'):spec[key]['centres']=[(x,y*1.12,z) for x,y,z in spec[key]['centres']]
            if style=='reptile':
                spec['joints']={k:(x*1.5,y,z*.82) for k,(x,y,z) in spec['joints'].items()}
                spec['body_centres']=[(x,y,z*.82) for x,y,z in spec['body_centres']]
                for key in ('fore_leg','hind_leg'):spec[key]['centres']=[(x*1.5,y,z*.82) for x,y,z in spec[key]['centres']]
        spec['voxel']=.015
        A=AN.Animal(self.K,spec,'Anatomical '+style+' ribcage and limbs')
        A.root.parent=self.root
        # The source animal head is replaced by the intended species/hybrid.
        if style!='boar':
            cutoff=A.J['neck_base' if self.kind=='echidna' else 'neck_mid'].y
            keep=~((A.part==0)&(A.co[:,1]>cutoff))
            indices=sorted({i for p in A.body_ob.data.polygons if all(keep[j] for j in p.vertices) for i in p.vertices})
            A.co,A.Wunused=subset(A.body_ob,keep,A.co)
            A.part=A.part[indices]
            A.nrm=np.array([v.normal[:] for v in A.body_ob.data.vertices])
        base=self.rgb
        if style=='lion':base=(.66,.39,.15)
        def coat(co,nrm,a):
            c=np.tile(base,(len(co),1)); belly=np.clip(-nrm[:,2],0,1)*.45
            c=c*(1-belly[:,None])+np.array([min(.9,v*1.55+.035) for v in base])*belly[:,None]
            if self.kind=='chimera':
                reptile=np.clip((-co[:,1]-.04)/.12,0,1)
                c=c*(1-reptile[:,None])+np.array((.12,.29,.28))*reptile[:,None]
            if self.kind=='sphinx':
                bib=np.clip((co[:,1]-.02)/.09,0,1)*np.clip(-nrm[:,2]+.3,0,1)
                c=c*(1-bib[:,None])+np.array((.78,.70,.53))*bib[:,None]
            noise=.06*np.sin(co[:,0]*87+co[:,1]*53+co[:,2]*111)
            return c*(1+noise[:,None])
        A.finish(coat,self.mats['skin'])
        if self.kind=='cerberus':
            # Use the actual CC0 wolf body as well as its skull. The kit's rig
            # transfers skinning to the widened mastiff chest and real hocks.
            source=np.load(ROOT/'art/monsters/anatomy-v3/vendor/wolf_base.npz')
            raw=source['dog2_co'];co=raw.copy()
            co[:,2]*=.17;co[:,1]=-.18*raw[:,1]+.025
            width=.17+.13*np.clip((co[:,2]-.17)/.16,0,1)
            co[:,0]*=width
            polygons=HU.Human._polys(source['dog2_face_len'],source['dog2_face_idx'])
            keep=(raw[:,1]>-1.0)&(raw[:,1]<2.0)
            polygons=[p for p in polygons if all(keep[i] for i in p)]
            ob=self.K.mesh('CC0 mastiff adapted canine body',co,polygons,self.mats['skin'],A.root,True)
            A.attach(ob);A.body_ob.hide_render=True
        self.animals.append((A,style))
        for leg in AN.LEGS:self.contact.append(('animal',A,leg))
        # Individual toes/claws follow the paw bones, instead of peg feet.
        for leg in AN.LEGS:
            p=A.J[leg+'_hoof']
            if style=='boar':continue # The anatomical source supplies true cloven hoof shells.
            count=4;material='skin'
            for j in range(count):
                xx=(j-(count-1)/2)*(.019 if count==4 else .023)
                mat=self.mats[material]
                if self.kind=='chimera' and AN.FORE[leg]:self.mats[material]=self.material('skin lion paw',(.66,.39,.15))
                ob=self.ell('Cloven hoof' if style=='boar' else 'Metacarpal paw toe',p+Vector((xx,.012,.016)),(.014,.035,.016),material,A.root,2)
                self.mats[material]=mat
                A.attach(ob,leg+'_pas')
                if style!='boar':
                    t=self.horn(A.root,[p+Vector((xx,.037,.009)),p+Vector((xx,.057,.004))],.006,'horn','Retractile claw')
                    A.attach(t.ob,leg+'_pas')
        if style=='boar':
            extras=spec['extras']; before=set(bpy.data.objects);extras(A,self.K)
            for o in set(bpy.data.objects)-before:
                if o.type=='MESH' and o.active_material:
                    label=o.active_material.name.lower()
                    o.active_material.name='Monster '+('teeth tusks' if 'ivory' in label else 'eyes boar' if 'eye' in label else 'horn hooves' if 'hoof' in label else 'fur bristle')
            for side in (-1,1):
                p=A.J['muzzle'];pts=[p+Vector((side*.034,-.020,.03)),p+Vector((side*.077,.004,.055)),p+Vector((side*.072,.035,.12)),p+Vector((side*.047,.041,.146))]
                t=self.horn(A.root,pts,.016,'teeth','Calydonian grown tusk');A.attach(t.ob,'head')
            anchor=self.K.empty('Boar skull anchor',A.root);self.bone_nodes.append((anchor,A,'head'))
            jaw=self.K.empty('Boar mouth anchor',anchor);self.heads.append((anchor,jaw,A.J['muzzle']))
        if self.kind=='cerberus':
            for ob,pts,w in A.accessories:
                if ob.name.startswith(('Metacarpal paw toe','Retractile claw')):ob.hide_render=True
            pts=[(0,-.26,.33),(0,-.45,.32),(.15,-.59,.39),(.26,-.67,.49)]
            t=self.tube('Cerberus tapering whip tail',spline(pts,24),[.027*(1-i/23)**.8+.002 for i in range(24)],parent=A.root,ring=10)
            self.tails.append((t,pts,'tail',0))
        return A

    def bind_animal_head(self,A,h):
        # Head geometry is in its own local frame; empty follows the skinned head.
        self.head_motion.append((h,A,'head',h.location.copy()))

    def animal_monster(self):
        k=self.kind;style='boar' if k=='calydonianboar' else 'dog' if k=='cerberus' else 'lion' if k in ('chimera','sphinx') else 'reptile'
        A=self.quadruped(style)
        if k=='cerberus':
            for i,x in enumerate((-.145,0,.145)):
                h=self.library_head('dog',A.root,(x*.74,.28,.405),1.02 if i==1 else .92)
                h.rotation_euler.z=(-.16,0,.16)[i];self.bind_animal_head(A,h)
        elif k=='chimera':
            old=self.mats['skin'];self.mats['skin']=self.material('skin lion face',(.67,.39,.14))
            h=self.library_head('lion',A.root,(0,.29,.43),1.05);self.bind_animal_head(A,h);self.mats['skin']=old
            old=self.mats['skin'];self.mats['skin']=self.material('skin goat face',(.39,.43,.45))
            h=self.library_head('goat',A.root,(0,-.075,.62),.86);self.mats['skin']=old
            self.head_motion.append((h,A,'chest',h.location.copy()))
            neck=self.tube('Chimera continuous caprine neck',spline([(0,-.075,.33),(0,-.085,.43),(0,-.082,.52),(0,-.075,.61)],16),[tuple(.050*(1-i/15)+r*i/15 for r in (.030,.034)) for i in range(16)],'skin',A.root,14)
            A.attach(neck.ob,'chest')
            t=self.tube('Chimera serpent tail',spline([(0,-.27,.32),(.14,-.52,.40),(.20,-.56,.61),(.14,-.45,.70)],24),[.027*(1-i/30)+.008 for i in range(24)],'snake',A.root,12)
            self.tails.append((t,[(0,-.27,.32),(.14,-.52,.40),(.20,-.56,.61),(.14,-.45,.70)],'tail',0))
            h=super().head('reptile',A.root,(.14,-.45,.70),.25,math.pi)
        elif k=='sphinx':
            H,h=self.human(loc=(0,.24,-.32),scale=1.05,head_only=True)
            self.eagle_wings(A.root,.40,.62)
            self.crown_small(h)
        elif k in ('dragon','echidna'):
            if k=='dragon':
                h=self.crocodile_head(A.root,(0,.27,.36));self.bind_animal_head(A,h)
            else:
                H,h=self.human(loc=(0,.12,-.06),scale=.87,torso_only=True)
                for side in (-1,1):self.horn(h,[(side*.045,-.01,.828),(side*.13,-.045,.94),(side*.11,.00,1.08)],.028,'horn','Echidna cranial horn')
                self.anatomical_shell(H,.48,.66,self.material('fur cream mane',(.72,.68,.48)),'Echidna fitted chest mantle',.010)
                collar=self.tube('Echidna continuous pelvic junction',[(0,.16,.26),(0,.16,.30),(0,.14,.35)],[(.075,.085),(.078,.070),(.065,.049)],'skin',A.root,20)
                A.attach(collar.ob,'chest')
            for side in (-1,1):
                w=self.wing(A.root,side,False,.39)
                w.scale=(.48,)*3
                w.location=(side*.070,-.035,.32)
            for i in range(10):
                y=-.28+i*.052
                if k=='echidna' and y>.025:continue
                near=(A.part==0)&(np.abs(A.rest[:,0])<.030)&(np.abs(A.rest[:,1]-y)<.035)
                z=float(A.rest[near,2].max())-.006 if near.any() else .31
                vertices=[(x,yy,zz) for x in (-.008,.008) for yy,zz in ((y+.012,z-.008),(y-.017,z+.071),(y-.050,z-.005))]
                plate=self.K.mesh('Tapered reptilian dorsal plate',vertices,[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],self.mats['horn'],A.root,True)
                A.attach(plate,'chest' if y>0 else 'pelvis')
            pts=[(0,-.28,.32),(.13,-.54,.21),(.28,-.75,.14),(.38,-.91,.20)]
            t=self.tube('Reptilian counterbalancing tail',spline(pts,26),[.055*(1-i/25)**.7+.002 for i in range(26)],parent=A.root,ring=14)
            self.tails.append((t,pts,'tail',0))
            if k=='echidna':self.horn(A.root,[pts[-1],(.39,-1.02,.27)],.043,'horn','Echidna stinger')

    def crown_small(self,h,ivy=False):
        z=.848
        self.tube('Ivy wreath' if ivy else 'Gold diadem',[(.060*math.cos(i*math.tau/24),.010+.045*math.sin(i*math.tau/24),z) for i in range(25)],[.004]*25,'snake' if ivy else 'metal',h,8)
        for i in range(9):
            a=math.pi*i/8
            self.feather(h,(.062*math.cos(a),.011+.045*math.sin(a),z),(.069*math.cos(a),.015+.05*math.sin(a),z+.012),.008,self.mats['snake' if ivy else 'metal'])

    def humanoid_monster(self):
        k=self.kind
        count=3 if k=='maenads' else 2 if k=='harpies' else 1
        for i in range(count):
            x=(i-(count-1)/2)*(.32 if k=='maenads' else .36)
            H,h=self.human(loc=(x,(-.035 if i%2 else .035),.10 if k=='harpies' else 0),scale=.90 if count>1 else 1)
            if k in ('maenads','medusa'):self.crown_small(h,k=='maenads')
            if k=='medusa':
                for j in range(11):
                    a=j*math.tau/11
                    pts=[(.045*math.cos(a),.02+.035*math.sin(a),.840),(.09*math.cos(a),.02+.07*math.sin(a),.875),(.105*math.cos(a),.03+.065*math.sin(a),.780-(j%3)*.025)]
                    t=self.tube('Medusa living snake hair',spline(pts,16),[.009*(1-n/22) for n in range(16)],'snake',h,8)
                    self.tails.append((t,pts,'hair',j))
                    self.ell('Snake hair skull',pts[-1],(.012,.009,.009),'snake',h,1)
            if k=='cyclops':
                self.ell('Single cyclopean orbital globe',(0,.089,.819),(.039,.017,.030),'teeth',h,3)
                self.ell('Cyclops iris',(0,.109,.819),(.021,.006,.022),'eyes',h,2)
                self.ell('Cyclops pupil',(0,.115,.819),(.009,.003,.013),'horn',h,2)
                self.tube('Cyclops single supraorbital brow',[(-.037,.090,.838),(0,.084,.853),(.037,.090,.838)],[.008,.010,.008],'skin',h,12)
                for side in (-1,1):self.horn(h,[(side*.027,.044,.755),(side*.032,.055,.772)],.007,'teeth','Cyclops mandibular tusk')
            if k=='minotaur':
                from godot_minotaur import bull_head
                self.mats['nostril']=self.material('mouth recessed nostril',(.045,.022,.019))
                bull=bull_head(self,h);bull.location=(0,.012,.81);bull.scale=(.35,)*3
                for p in H.parts:
                    if 'sandal' in p.ob.name.lower():p.ob.hide_render=True
                for side in (-1,1):
                    foot=self.joint_node(H,'foot.'+('R' if side>0 else 'L'),'Minotaur hoof articulation')
                    p=Vector(H.J['heel.'+('R' if side>0 else 'L')])
                    self.cloven_foot(foot,p,'Minotaur')
            if k=='satyr':
                for side in (-1,1):
                    self.horn(h,[(side*.052,-.016,.827),(side*.09,-.055,.873),(side*.10,-.077,.827),(side*.055,-.066,.798)],.017,'horn','Ram curled horn')
                self.anatomical_shell(H,.12,.395,self.mats['fur'],'Caprine fur thigh and shank',.004)
                for side in (-1,1):
                    foot=self.joint_node(H,'foot.'+('R' if side>0 else 'L'),'Goat hoof articulation')
                    p=Vector(H.J['heel.'+('R' if side>0 else 'L')])
                    self.cloven_foot(foot,p,'Satyr',.91)
                grip=self.joint_node(H,'hand.R','Panpipes grip')
                for j in range(6):self.horn(grip,[(.045+j*.012,.017,.36),(.045+j*.012,.017,.42+j*.012)],.005,'belly','Reed panpipe')
            if k in ('talos','hector'):
                self.anatomical_shell(H,.48,.69,self.mats['metal'],'Fitted anatomical bronze cuirass',.007)
                self.anatomical_shell(H,.10,.245,self.mats['metal'],'Shaped bronze greaves',.006)
                # Helmet uses the real cranial surface; cheek pieces frame the face.
                self.anatomical_shell(H,.815,.9,self.mats['metal'],'Cranial helmet shell',.008)
                for side in (-1,1):
                    self.K.mesh('Bronze cheek plate',[(side*.041,.022,.828),(side*.063,.025,.801),(side*.044,.035,.754),(side*.030,.044,.794)],[(0,1,2,3)],self.mats['metal'],h,True)
                for j in range(13):
                    y=-.053+j*.008
                    self.feather(h,(-.005,y,.867),(.003,y,.921),.009,self.mats['metal' if k=='talos' else 'cloth'])
                if k=='talos':
                    for side in (-1,1):
                        self.ell('Talos recessed eye slit',(side*.021,.049,.804),(.012,.007,.004),'eyes',h,1)
                    foot=self.joint_node(H,'foot.R','Talos ankle seal')
                    self.ell('Talos bronze ankle seal',(.067,.026,.079),(.019,.012,.019),'metal',foot,2)
                else:
                    hand=self.joint_node(H,'hand.R','Spear grip')
                    self.horn(hand,[(.14,.045,.05),(.14,.045,.82)],.0045,'horn','Hector spear haft')
                    self.horn(hand,[(.14,.045,.78),(.14,.045,.93)],.015,'metal','Leaf spearhead')
                    hand=self.joint_node(H,'hand.L','Shield grip')
                    shield=self.ell('Hector round shield',(-.16,.074,.40),(.145,.025,.145),'metal',hand,3)
                    self.ell('Hector shield boss',(-.16,.095,.40),(.034,.023,.034),'metal',hand,2)
                    cape=self.material('cloth red cape',(.43,.047,.027))
                    verts=[(x,-.04-.05*u,.67-.52*u+.009*math.sin(j*1.9)) for u in (0,.25,.5,.75,1) for j,x in enumerate(np.linspace(-.12-.08*u,.12+.08*u,12))]
                    ob=self.K.mesh('Hector pleated cape',verts,[(r*12+j,r*12+j+1,(r+1)*12+j+1,(r+1)*12+j) for r in range(4) for j in range(11)],cape,H.root,True)
                    self.human_attach(H,ob,'chest')
            if k=='maenads':
                hand=self.joint_node(H,'hand.R','Thyrsus grip')
                self.horn(hand,[(.15,.02,.04),(.15,.02,.78)],.005,'horn','Maenad thyrsus staff')
                self.ell('Thyrsus cone',(.15,.02,.797),(.022,.023,.040),'belly',hand,2)
            if k=='harpies':
                self.anatomical_shell(H,.42,.65,self.mats['fur'],'Harpy fitted feather mantle',.009)
                self.eagle_wings(H.root,.67,.60)
                for side in (-1,1):
                    foot=self.joint_node(H,'foot.'+('R' if side>0 else 'L'),'Avian ankle and talons')
                    x=side*.065
                    for j in range(3):self.horn(foot,[(x+(j-1)*.012,.020,.105),(x+(j-1)*.019,.064,.058),(x+(j-1)*.026,.098,.043)],.008,'horn','Harpy curved talon')

    def marine(self):
        if self.kind=='scylla':
            self.tube('Scylla muscular marine peduncle',[(0,-.31,.10),(0,-.13,.26),(0,0,.48),(0,.03,.64)],[(.10,.05),(.21,.14),(.19,.18),(.13,.09)],'snake',ring=24)
            H,h=self.human(loc=(0,0,.24),scale=1.04,torso_only=True);self.crown_small(h)
            self.anatomical_shell(H,.44,.64,self.mats['metal'],'Scylla fitted bronze bodice',.006)
            for i in range(6):
                a=math.tau*i/6;x=math.cos(a);y=math.sin(a)
                pts=[(.11*x,.11*y,.41),(.33*x,.28*y,.39),(.45*x,.39*y,.59),(.47*x,.46*y,.69+(i%2)*.05)]
                t=self.tube('Scylla muscular canine neck',spline(pts,22),[.067*(1-.45*j/21) for j in range(22)],'snake',ring=14)
                dog=self.library_head('dog',self.root,pts[-1],1.02);dog.rotation_euler.z=-a+math.pi/2
                self.necks.append((t,dog,pts,i))
        else:
            mantle=self.K.empty('Octopus mantle and siphon',self.root,(0,0,.57))
            controls=[(0,-.07,-.06),(0,-.13,.09),(0,-.18,.32),(0,-.16,.51),(0,-.13,.59)]
            radii=[(.25,.20),(.32,.28),(.27,.29),(.16,.17),(.002,.002)]
            dense=AN._catmull(radii,7)
            self.tube('Octopus tapered mantle',spline(controls,len(dense)),[tuple(max(.002,v) for v in r) for r in dense],parent=mantle,ring=32)
            self.ell('Kraken recessed lateral eye',(0,.211,.014),(.11,.064,.095),'belly',mantle,3)
            self.ell('Kraken amber iris',(0,.269,.014),(.074,.022,.071),'eyes',mantle,2)
            self.ell('Kraken horizontal pupil',(0,.290,.014),(.066,.007,.014),'horn',mantle,2)
            self.ell('Kraken corneal brow',(0,.224,.088),(.119,.053,.029),'skin',mantle,2)
            self.tube('Octopus exhalant siphon',[(.09,.19,-.015),(.11,.29,-.071),(.10,.34,-.052)],[.040,.036,.023],'belly',mantle,14)
            self.horn(mantle,[(0,.19,-.14),(0,.27,-.19),(0,.27,-.12)],.027,'horn','Octopus beak')
            jaw=self.K.empty('Kraken mouth',mantle);self.heads.append((mantle,jaw,Vector((0,.26,-.15))))
            self.actors.append((mantle,Vector((0,0,.57)),'kraken'))
            for i in range(8):
                a=math.tau*i/8;x=math.cos(a);y=math.sin(a)
                pts=[(.18*x,.18*y,.48),(.36*x,.36*y,.20),(.64*x,.64*y,.085),(.89*x,.89*y,.12),(.99*x,.99*y,.27),(.91*x,.91*y,.35),(.81*x,.81*y,.28)]
                t=self.tube('Octopus tapered muscular arm',spline(pts,38),[.10*(1-j/38)**1.3+.003 for j in range(38)],ring=16)
                self.tails.append((t,pts,'arm',i))
                # Real concave sucker rims with open centres; paired rows follow arm skin.
                for j in range(3,34,2):
                    u=j/37;r=.025*(1-u)+.007
                    for side in (-1,1):
                        o=self.sucker(r);o['arm_index']=i;o['arm_u']=u;o['sucker_side']=side
                        self.dynamic.append((o,t,u,side,r))

    def sucker(self,r):
        verts=[];n=10
        for rad,z in ((r*.8,.005),(r,0),(r*.48,-.008),(r*.30,-.005)):
            for i in range(n):verts.append((rad*math.cos(i*math.tau/n),rad*math.sin(i*math.tau/n),z))
        return self.K.mesh('Octopus concave suction cup',verts,[(row*n+j,row*n+(j+1)%n,(row+1)*n+(j+1)%n,(row+1)*n+j) for row in range(3) for j in range(n)],self.mats['belly'],self.root,True)

    def build(self):
        if self.kind in ('calydonianboar','cerberus','chimera','sphinx','dragon','echidna'):self.animal_monster()
        elif self.kind in ('scylla','kraken'):self.marine()
        else:self.humanoid_monster()
        self.legs=[None]*len(self.contact)
        self.animate(0,'idle')
        lo,hi=self.limits();self.scale=self.height/(hi-lo);self.base_z=.025-lo*self.scale
        self.root.scale=(self.scale,)*3
        for o in self.root.children_recursive:
            if o.type=='MESH' and not o.hide_render and not o.data.color_attributes.get('Coat colour'):
                paint(o,self.color_of(o),.025)
        self.animate(0,'idle')
        return self

    def limits(self):
        # Library head/body cuts can retain unused source vertices for weights
        # and palette identity. Only vertices belonging to rendered faces govern
        # scale and grounding; the exporter removes those unused points too.
        deps=bpy.context.evaluated_depsgraph_get();zs=[]
        cache=getattr(self,'_bounds_indices',{});self._bounds_indices=cache
        for ob in self.root.children_recursive:
            if ob.type!='MESH' or ob.hide_render:continue
            e=ob.evaluated_get(deps);key=(ob.name,len(e.data.vertices),len(e.data.polygons))
            if key not in cache:cache[key]=sorted({i for p in e.data.polygons for i in p.vertices})
            zs.extend((e.matrix_world@e.data.vertices[i].co).z for i in cache[key])
        return min(zs),max(zs)

    def animate(self,f,clip):
        self.root.rotation_euler=(0,0,0);self.root.scale=(self.scale,)*3;self.root.location=(0,0,self.base_z)
        phase=f/24; ph=math.tau*phase; strike=max(0,math.sin(ph))
        lifts={}; stance=.72
        def step(offset):
            u=(phase+offset)%1
            if clip!='walk':return 0,0
            if u<stance:return (.32-.64*u)/self.scale,0
            t=(u-stance)/(1-stance)
            return ((.32-.64*stance)+.64*stance*smooth(t))/self.scale,.105*math.sin(math.pi*t)/self.scale
        for H,kind,loc,scale in self.people:
            feet={};hands={}
            for side in (-1,1):
                dy,lift=step(0 if side<0 else .5)
                feet[side]=(side*.068,dy/scale,lift/scale)
                lifts[id(H),side]=lift
                if clip in ('fight','fight2'):
                    hands[side]=(side*(.15 if clip=='fight' else .22),.11+.09*strike,.53+.08*strike)
                else:hands[side]=(side*.16,.006+(.06*side*math.sin(ph) if clip=='walk' else 0),.38)
            H.pose((0,0,H.pelvis_height-.014),.025 if clip=='idle' else .055*strike if clip=='fight' else .012*math.sin(ph),feet,hands,turn=.06*math.sin(ph) if clip=='fight2' else 0)
        for A,style in self.animals:
            legs={}
            for j,leg in enumerate(AN.LEGS):
                dy,lift=step((0,.5,.5,0)[j]);p=A.J[leg+'_hoof']+Vector((0,dy,lift))
                legs[leg]=('ik',p,0,0);lifts[id(A),leg]=lift
            A.pose(dict(legs=legs,neck=(.08*strike if clip=='fight' else 0,0,.035*math.sin(ph)),head=.08*strike if clip=='fight' else 0,
                        flex=.025*math.sin(ph),tail=(.04*math.sin(ph),0,.05*math.sin(ph))))
        for node,rig,bone in self.bone_nodes:
            R,T=rig.bone_frames[bone] if hasattr(rig,'bone_frames') else (rig.R[bone],rig.T[bone])
            node.matrix_basis=Matrix.Translation(T)@R.to_4x4()
        for node,A,bone,pos in self.head_motion:
            R,T=A.R[bone],A.T[bone];node.location=R@pos+T
            node.rotation_euler=R.to_euler()
        for t,h,pts,i in self.necks:
            pp=[Vector(p) for p in pts];pp[-1]+=Vector((.008*math.sin(ph+i),.05*strike if clip=='fight' else 0,0))
            t.update(spline(pp,len(t.radii)));h.location=pp[-1]
        for w,side in self.wings:
            w.rotation_euler.y=side*(.09*math.sin(ph) if clip=='walk' else .13*math.sin(ph) if clip=='fight2' else .018*math.sin(math.tau*f/12))
            if clip=='die':w.rotation_euler.y+=math.pi*.5*smooth(f/29)
        for t,pts,mode,i in self.tails:
            pp=[Vector(p) for p in pts]
            for j in range(1,len(pp)):
                pp[j].x+=(.009 if mode=='hair' else .025)*math.sin(ph+i+j*.7)
                if mode=='arm':pp[j].z+=.012*math.sin(ph+i+j*.8)
            t.update(spline(pp,len(t.radii)))
        for ob,t,u,side,r in self.dynamic:
            j=round(u*(len(t.points)-1));sx,axis,up=t.frames[j];radius=t.radii[j]
            radius=radius[1] if isinstance(radius,tuple) else radius
            ob.location=t.points[j]-up*radius*.90+sx*(side*radius*.33)
            ob.rotation_mode='QUATERNION';ob.rotation_quaternion=Vector((0,0,1)).rotation_difference(-up)
        for h,jaw,m in self.heads:jaw.rotation_euler.x=-.23*strike if clip in ('fight','fight2') else 0
        for ob,rest,weights,pivot in self.face_deforms:
            R=np.array(Matrix.Rotation(-.22*strike if clip in ('fight','fight2') else -.04,3,'X'))
            moved=(rest-pivot)@R.T+pivot
            posed=rest*(1-weights[:,None])+moved*weights[:,None]
            ob.data.vertices.foreach_set('co',posed.ravel());ob.data.update()
        if clip=='die':
            death=smooth(f/29);self.root.rotation_euler.y=math.pi*.49*death
            self.root.scale=(self.scale*(1-.72*death),self.scale,self.scale*(1-.38*death))
        bpy.context.view_layer.update()
        # All deformations stay above the authored flat floor, including collapse.
        lo,_=self.limits();self.root.location.z+=.025-lo
        bpy.context.view_layer.update()
        mouths=[]
        for h,jaw,m in self.heads:
            v=h.matrix_world@m;mouths.append([round(v.x,6),round(v.z,6),round(-v.y,6)])
        feet=[]
        for typ,rig,leg in self.contact:
            p=Vector(rig.feet[leg]) if typ=='human' else rig.joint(leg+'_hoof')
            v=rig.root.matrix_world@p
            feet.append([round(v.x,6),round(.025+lifts.get((id(rig),leg),0)*self.scale,6),round(-v.y,6)])
        self.probes[f'{clip}_{int(f):02d}']={'root':[0,0,0],'mouths':mouths,'feet':feet}

    def manifest(self):
        return {'revision':REVISION,'design_revision':DESIGN_REVISION,'species':self.kind,'design':self.design,
          'vertex_budget':VERTEX_BUDGET,'imported_vertex_budget':34000,'triangle_budget':34000,
          'shader':'res://shaders/monster_reference.gdshader','heads':len(self.heads),'legs':len(self.contact),
          'height_tiles':self.height,'pose_probes':self.probes,'clips':{'walk':24,'idle':12,'fight':24,'fight2':24,'die':30},
          'scale_contract':'larger than citizen; all non-death pose tops below Zeus body',
          'source':'eZeus/tools/godot_monster_reference.py','anatomy_source':'eZeus/tools/godot_monster_anatomy.py',
          'anatomy_libraries':['Blender Foundation CC0 Human Base Meshes','eZeus anatomical quadruped kit']+(['Blender 5.2 cave lion, CC-BY Joanna Kobierska; base Ken Barthelmey'] if self.kind=='chimera' else [])+(['CC0 wolf, NewDLC'] if self.kind in ('cerberus','scylla') else [])+(['CC0 crocodile, Micket'] if self.kind=='dragon' else []),
          'rights_status':'needs_evidence'}
