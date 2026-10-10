"""Godot-only monster reference sculptures and fixed-topology in-place poses.

Hercules screen studies inform verified species; undocumented counterparts use
the game's mythology. Native sprite recipes, rules and simulation RNG are not used.
Blender +Y is forward. Run in a disposable background Blender process only.
"""
import math
from pathlib import Path
import bpy
from mathutils import Vector, Matrix
from godot_hydra import Tube, spline, linear, paint, smooth, Head as ReptileHead, SurfaceDecor

REVISION = 'monster_reference_v1'
ASSETS = ('cyclops', 'talos', 'hector', 'minotaur', 'satyr', 'medusa', 'maenads', 'harpies',
          'calydonianboar', 'cerberus', 'chimera', 'sphinx', 'dragon', 'echidna', 'scylla', 'kraken')
VERTEX_BUDGET = 16500
PROFILES = {
 'cyclops': ((.57,.25,.17), 2.08, 'single-eyed terracotta giant'),
 'talos': ((.56,.34,.14), 2.14, 'bronze automaton with articulated armour and ankle seal'),
 'hector': ((.67,.45,.27), 1.92, 'monumental Trojan warrior, crested bronze helm, shield and spear'),
 'minotaur': ((.42,.24,.12), 2.10, 'bull-headed muscular guardian with swept horns and hoof feet'),
 'satyr': ((.53,.34,.20), 1.82, 'fierce woodland goat man with curled horns and panpipes'),
 'medusa': ((.45,.55,.27), 1.93, 'green Gorgon, living blue-green snake hair and purple Greek dress'),
 'maenads': ((.69,.45,.32), 1.86, 'three frenzied ivy-crowned women with wine-purple dresses and thyrsoi'),
 'harpies': ((.52,.34,.28), 1.92, 'pair of wing-armed women with hooked talons and dark feathers'),
 'calydonianboar': ((.13,.095,.08), 1.79, 'massive bristled boar with four legs, long ivory tusks and narrow eyes'),
 'cerberus': ((.095,.09,.10), 1.97, 'three black mastiff heads, heavy jowls, red eyes and one whip tail'),
 'chimera': ((.64,.40,.16), 1.99, 'lion forequarters, goat head rising from back and serpent-headed tail'),
 'sphinx': ((.65,.47,.26), 2.00, 'human-headed winged lion with gold diadem and dark layered feathers'),
 'dragon': ((.20,.33,.24), 2.08, 'horned winged serpent with four clawed legs and segmented belly'),
 'echidna': ((.39,.43,.22), 2.09, 'horned mother of monsters, female torso, dragon body, bat wings and stinger tail'),
 'scylla': ((.22,.34,.36), 2.11, 'sea monster with crowned female trunk and six snarling dog necks'),
 'kraken': ((.29,.27,.40), 2.02, 'massive octopus with eight curling sucker-lined arms and one huge eye'),
}


class Sculpt:
    def __init__(self, K, kind):
        self.K, self.kind = K, kind
        self.rgb, self.height, self.design = PROFILES[kind]
        K.setup('Godot '+kind, 3, 61026, Path(__file__).resolve().parents[2]/'art/monsters'/kind, exposure=.25)
        self.root = K.empty('Monster authored body', K.root)
        self.mats = {}
        for label, rgb, rough, metal in [
          ('skin', self.rgb, .72, 0), ('belly', tuple(min(.9,c*1.32) for c in self.rgb), .82, 0),
          ('horn', (.10,.085,.075), .48, 0), ('mouth', (.21,.035,.04), .85, 0),
          ('teeth', (.85,.79,.64), .62, 0), ('eyes', (1,.055,.025), .38, 0),
          ('fur', tuple(c*.55 for c in self.rgb), .86, 0), ('metal', (.55,.34,.12), .4, .75),
          ('cloth', (.25,.085,.21), .9, 0), ('snake', (.19,.37,.32), .72, 0)]:
            self.mats[label] = K.material('Monster '+label, linear(rgb), rough=rough, metal=metal)
        if kind in ('minotaur','satyr','medusa','sphinx','echidna','calydonianboar','kraken','dragon','talos'):
            self.mats['eyes'].diffuse_color = (*linear((1,.56,.06)),1)
        if kind=='cyclops':self.mats['eyes'].diffuse_color=(*linear((.28,.14,.075)),1)
        if kind in ('minotaur','satyr','cyclops','hector'):
            self.mats['cloth'].diffuse_color = (*linear((.20,.105,.065)),1)
        if kind=='chimera':
            self.mats['skin'].diffuse_color=(*linear((.12,.29,.28)),1)
            self.mats['fur'].diffuse_color=(*linear((.64,.27,.08)),1)
        self.actors, self.legs, self.necks, self.arms, self.wings, self.tails = [], [], [], [], [], []
        self.heads, self.mouths, self.feet, self.probes = [], [], [], {}
        self.decor = []
        self.scale = 1.

    def ell(self, name, pos, size, material='skin', parent=None, subdiv=2):
        return self.K.ell(name, pos, size, self.mats[material], parent or self.root, subdiv=subdiv)

    def tube(self, name, points, radii, material='skin', parent=None, ring=14):
        t = Tube(self.K, name, radii, self.mats[material], parent or self.root, ring=ring)
        t.update(points)
        return t

    def horn(self, parent, points, radius=.05, material='horn', name='Swept horn'):
        n=12
        return self.tube(name, spline(points,n), [radius*(1-i/(n-1))**.65+.001 for i in range(n)], material,parent,10)

    def head(self, style, parent, pos, size=1., yaw=0):
        if style=='reptile':
            head=ReptileHead(self.K,'Guardian dragon',self.mats['skin'],self.mats['belly'],self.mats['horn'],self.mats['mouth'],self.mats['teeth'],self.mats['eyes'],parent)
            head.root.location=pos;head.root.rotation_euler.z=yaw;head.root.scale=(size,)*3
            self.heads.append((head.root,head.jaw,Vector((0,.43,-.10))))
            return head.root
        h=self.K.empty(style+' expressive head',parent,pos);h.rotation_euler.z=yaw
        if style in ('human','gorgon','sphinx'):
            return self.anatomical_head(h,style,size)
        s=size
        def e(label,p,d,mat='skin',sub=2):
            return self.ell(style+' '+label,tuple(s*x for x in p),tuple(s*x for x in d),mat,h,sub)
        humanoid=style in ('human','gorgon','cyclops','bronze','satyr','sphinx','echidna')
        e('cranium',(0,0,.02),(.19,.15,.23) if humanoid else (.23,.24,.20),sub=3)
        e('cheek L',(-.12,.09,-.05),(.10,.12,.11));e('cheek R',(.12,.09,-.05),(.10,.12,.11))
        jaw=self.K.empty(style+' jaw hinge',h,(0,0,-.13*s))
        self.ell(style+' lower jaw',(0,.13*s,-.03*s),(.16*s,.17*s,.085*s),'skin',jaw)
        self.ell(style+' dark mouth',(0,.15*s,-.006*s),(.14*s,.145*s,.038*s),'mouth',jaw)
        snout=.16 if humanoid else .32
        e('nose bridge',(0,.14,.055),(.055,.10,.11) if humanoid else (.17,.24,.105))
        e('nose tip',(0,snout+.04,-.02),(.082,.07,.055) if humanoid else (.135,.085,.075),'skin' if humanoid else 'horn')
        for side in (-1,1):
            e('nostril',(side*(.034 if humanoid else .08),snout+.08,-.02),(.019,.017,.025),'horn',1)
            brow=e('brow',(side*.102,.132,.11),(.11,.07,.052));brow.rotation_euler.y=side*-.22
        eye_x=(0,) if style=='cyclops' else (-.102,.102) if humanoid else (-.18,.18)
        for x in eye_x:
            if style=='cyclops':
                e('single sclera',(0,.157,.12),(.105,.055,.108),'teeth',3)
                e('single iris',(0,.209,.12),(.055,.023,.060),'eyes')
                e('single pupil',(0,.23,.12),(.022,.009,.030),'horn')
            else:
                e('eye',(x,.204 if not humanoid else .184,.107),(.052,.026,.031),'eyes')
                e('pupil',(x,.227 if not humanoid else .207,.108),(.012,.008,.025),'horn',1)
        if style not in ('human','gorgon','sphinx','bronze'):
            for side in (-1,1):
                for i in range(5):
                    x=side*(.045+.023*i);y=snout+.10-.02*i
                    self.horn(jaw,[(x*s,y*s,.036*s),(x*s,y*s,.085*s)],.014*s,'teeth','Lower fang')
                for i in range(5):
                    x=side*(.04+.027*i);y=snout+.075-.02*i
                    self.horn(h,[(x*s,y*s,-.07*s),(x*s,y*s,-.14*s)],.017*s,'teeth','Upper fang')
        for side in (-1,1):
            if style not in ('cyclops','bronze'):
                ear=e('ear',(side*.21,-.04,.075),(.11,.065,.12));ear.rotation_euler.y=side*-.6
            if style in ('bull','goat','satyr','reptile','echidna'):
                points=[(side*.15*s,-.03*s,.14*s),(side*.30*s,-.08*s,.32*s),(side*.38*s,.02*s,.47*s),(side*.24*s,.11*s,.52*s)]
                if style=='satyr':points=[(side*.16*s,-.03*s,.15*s),(side*.32*s,-.10*s,.26*s),(side*.30*s,-.16*s,.07*s),(side*.18*s,-.12*s,.03*s)]
                if style=='echidna':points=[(side*.16*s,-.03*s,.14*s),(side*.44*s,-.13*s,.36*s),(side*.48*s,-.12*s,.67*s),(side*.28*s,.04*s,.73*s)]
                self.horn(h,points,.055*s,'horn')
            if style in ('dog','reptile','boar'):
                self.horn(h,[(side*.18*s,-.10*s,.1*s),(side*.23*s,-.15*s,.31*s)],.07*s,'skin','Pointed ear')
        if style in ('bull','lion','satyr','echidna'):
            for i in range(18):
                a=math.tau*i/18
                self.horn(h,[(math.cos(a)*.23*s,-.12*s,math.sin(a)*.25*s),
                             (math.cos(a)*.31*s,-.20*s,math.sin(a)*.30*s),
                             (math.cos(a)*.25*s,-.29*s,math.sin(a)*.27*s-.08*s)],.06*s,'fur','Layered mane lock')
        if style=='boar':
            for side in (-1,1):
                self.horn(jaw,[(side*.18*s,.17*s,-.03*s),(side*.33*s,.30*s,.05*s),(side*.32*s,.36*s,.25*s),(side*.24*s,.38*s,.32*s)],.060*s,'teeth','Curved boar tusk')
        self.fuse(h,[o for o in h.children if o.type=='MESH' and o.active_material==self.mats['skin']],.017*s)
        self.heads.append((h,jaw,Vector((0,(snout+.12)*s,-.12*s))))
        return h

    def anatomical_head(self,h,style,size):
        """Use the retained CC0 anatomical face, with original monster dress/hair."""
        import human
        a=human.load_body('male' if self.kind=='hector' else 'female')
        co=a['co'];polys=human.Human._polys(a['face_len'],a['face_idx'])
        selected=[f for f in polys if all(co[i][2]>.735 for i in f)]
        indices=sorted({i for f in selected for i in f});remap={old:i for i,old in enumerate(indices)}
        factor=3.4*size
        xyz=[(float(co[i][0])*factor,float(co[i][1])*factor,(float(co[i][2])-.80)*factor) for i in indices]
        self.K.mesh('Anatomical '+style+' face',xyz,[tuple(remap[i] for i in f) for f in selected],self.mats['skin'],h,True)
        eyes=a['eye_co'].reshape(-1,3)
        for side in (-1,1):
            selected_eye=eyes[eyes[:,0]*side>0]
            center=selected_eye.mean(axis=0)
            p=Vector((float(center[0])*factor,float(center[1])*factor,(float(center[2])-.80)*factor))
            self.ell('Monster eye sclera',p,(.035*size,.022*size,.026*size),'teeth',h)
            self.ell('Monster iris',p+Vector((0,.020*size,0)),(.018*size,.009*size,.020*size),'eyes',h)
            self.ell('Monster eye slit',p+Vector((0,.028*size,0)),(.005*size,.004*size,.016*size),'horn',h,1)
        jaw=self.K.empty('Anatomical jaw pose anchor',h)
        if style!='gorgon':
            for i in range(24):
                angle=math.tau*i/24
                pts=[(.14*math.cos(angle),.10*math.sin(angle),.15),(.19*math.cos(angle),.12*math.sin(angle)-.045,.15),(.16*math.cos(angle),-.14-.08*abs(math.sin(angle)),-.22)]
                self.horn(h,[tuple(v*size for v in p) for p in pts],.043*size,'fur','Flowing hair lock')
        if style=='gorgon':
            for side in (-1,1):
                self.horn(h,[(side*.15*size,0,.04*size),(side*.23*size,-.03*size,.10*size)],.035*size,'skin','Pointed Gorgon ear')
        self.heads.append((h,jaw,Vector((0,.14*size,-.10*size))))
        return h

    def fuse(self,parent,objects,voxel):
        """Union static flesh only; articulated jaws, eyes and moving tubes stay separate."""
        if len(objects)<2:return
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        ob=bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        mod=ob.modifiers.new('Unified sculpted flesh','REMESH');mod.mode='VOXEL';mod.voxel_size=voxel
        bpy.ops.object.modifier_apply(modifier=mod.name)
        smooth_mod=ob.modifiers.new('Sculpt surface relax','SMOOTH');smooth_mod.factor=.65;smooth_mod.iterations=3
        bpy.ops.object.modifier_apply(modifier=smooth_mod.name)
        for face in ob.data.polygons:face.use_smooth=True

    def crown(self, head, ivy=False):
        for i in range(12):
            a=math.tau*i/12; p=(.185*math.cos(a),.15*math.sin(a),.16)
            if ivy:
                o=self.ell('Ivy crown leaf',p,(.067,.025,.04),'snake',head);o.rotation_euler.z=a
            else:self.horn(head,[p,(p[0]*1.05,p[1]*1.05,.27 if i%2 else .23)],.028,'metal','Diadem point')

    def snake_hair(self, head):
        for i in range(10):
            a=math.tau*i/10
            base=(.10*math.cos(a),.10*math.sin(a),.16)
            tip=(.37*math.cos(a),.28*math.sin(a),.24+.12*(i%3))
            pts=[base,(.19*math.cos(a),.17*math.sin(a),.40),tip]
            t=self.tube('Living snake hair',spline(pts,12),[.032*(1-.5*j/11) for j in range(12)],'snake',head,10)
            h=self.K.empty('Snake hair head',head,tip)
            self.ell('Snake hair muzzle',(0,.024,0),(.032,.059,.025),'snake',h,1)
            for side in (-1,1):self.ell('Snake hair eye',(side*.024,.034,.018),(.009,.009,.009),'eyes',h,1)
            self.tails.append((t,pts,'hair',i))

    def wing(self,parent,side,feathers=True,level=1.13):
        w=self.K.empty('Left wing' if side<0 else 'Right wing',parent,(side*.28,-.08,level))
        if not feathers:
            wrist=Vector((side*.43,-.08,.46))
            tips=[Vector((side*1.23,-.08,.79)),Vector((side*1.55,-.27,.45)),Vector((side*1.23,-.51,.10)),Vector((side*.78,-.65,-.15)),Vector((side*.28,-.54,-.24))]
            border=[Vector((0,0,0)),wrist,tips[0]]
            for a,b in zip(tips,tips[1:]):
                for j in range(1,9):
                    u=j/8
                    p=a.lerp(b,u)
                    p=p.lerp(wrist,.20*math.sin(math.pi*u))
                    border.append(p)
            vs=[wrist+Vector((0,-.025,0))]+border
            self.K.mesh('Scalloped bat wing membrane',vs,[(0,i+1,(i+1)%len(border)+1) for i in range(len(border))],self.mats['mouth'],w,True)
            self.horn(w,[(0,0,0),tuple(wrist),tuple(tips[0])],.050,'skin','Bat leading arm')
            for tip in tips[1:]:self.horn(w,[tuple(wrist),tuple(wrist.lerp(tip,.52)+Vector((0,-.022,0))),tuple(tip)],.023,'horn','Bat radial wing finger')
            self.horn(w,[tuple(wrist),tuple(wrist+Vector((side*.12,.035,.12)))],.035,'horn','Wing thumb claw')
            self.wings.append((w,side));return w
        verts=[(0,0,0),(side*.46,-.10,.43),(side*1.1,-.14,.34),(side*1.24,-.26,.15),
               (side*.9,-.50,-.07),(side*.54,-.56,-.22),(side*.17,-.39,-.18)]
        self.K.mesh('Wing web',verts,[(0,1,2,3),(0,3,4),(0,4,5),(0,5,6)],self.mats['fur' if feathers else 'mouth'],w,True)
        for j in range(12 if feathers else 4):
            u=j/(11 if feathers else 3); start=(side*(.25+.65*u),-.12,.28-.08*u)
            end=(side*(.35+.88*u),-.59+.30*u,-.30+.43*u)
            self.horn(w,[start,end],.065 if feathers else .023,'fur' if feathers else 'horn','Flight feather' if feathers else 'Wing finger')
        self.wings.append((w,side));return w

    def hands(self,parent):
        self.ell('Palm',(0,0,0),(.082,.05,.11),'skin',parent)
        for i in range(4):
            x=(i-1.5)*.039
            self.horn(parent,[(x,.014,-.05),(x,.04,-.14),(x,.06,-.20+.02*abs(i-1.5))],.022,'skin','Long finger')
            self.horn(parent,[(x,.06,-.16),(x,.075,-.21)],.013,'horn','Claw nail')
        self.horn(parent,[(.075,0,-.01),(.115,.02,-.08),(.11,.04,-.13)],.025,'skin','Opposed thumb')

    def leg(self,x,y,hip_z,quad=False,hoof=False):
        foot=self.K.empty('Hoof' if hoof else 'Planted paw',self.root,(x,y,.08))
        self.ell('Foot pad',(0,.045,0),(.13 if quad else .10,.20,.079),'horn' if hoof else 'skin',foot)
        for j in range(2 if hoof else 3):
            self.ell('Toe',(j-(.5 if hoof else 1),.0,0),(.01,.01,.01),'skin',foot,1) if False else None
            xx=(j-(.5 if hoof else 1))*(.085 if hoof else .075)
            self.ell('Split hoof toe' if hoof else 'Paw toe',(xx,.17,-.02),(.045,.065,.053),'horn' if hoof else 'skin',foot)
            if not hoof and quad:self.horn(foot,[(xx,.19,-.025),(xx,.28,-.055)],.025,'teeth','Toe claw')
        top=Vector((x*.75,y,hip_z)); end=Vector((x,y,.20)); knee=top.lerp(end,.55)+Vector((0,-.12 if quad else .09,0))
        t=self.tube('Muscular leg',spline([top,knee,end],12),[(.19 if quad else .16)*(1-.60*i/11)+.015 for i in range(12)])
        self.legs.append((t,foot,top,Vector((x,y,.08)),quad));return foot

    def biped(self, kind=None, x=0., y=0., scale=1., wings=False, tail=False):
        kind=kind or self.kind
        actor=self.K.empty('Monster torso '+kind,self.root,(x,y,0));actor.scale=(scale,)*3
        female=kind in ('medusa','maenads','harpies','sphinx','echidna','scylla')
        width=.25 if female else .52 if kind=='cyclops' else .40
        self.tube('Sculpted trunk',[(0,0,.87),(0,0,1.0),(0,0,1.17),(0,0,1.38),(0,0,1.57)],[(width*.75,.18),(width*.70,.17),(width*.84,.21),(width,.24),(width*.82,.19)],parent=actor,ring=24)
        for side in (-1,1):
            self.ell('Pectoral',(side*width*.48,.17,1.40),(width*.62,.12,.16),'skin',actor,3)
            self.ell('Deltoid',(side*(width+.06),0,1.49),(.115,.11,.16) if female else (.18,.17,.21),'skin',actor)
            top=Vector((side*(width+.05),0,1.48)); hand=Vector((side*(width+.22),.03,1.01))
            t=self.tube('Continuous arm',spline([top,(side*(width+.24),.02,1.25),hand],10),[(.09 if female else .17)*(1-.6*i/9) for i in range(10)],parent=actor)
            h=self.K.empty('Hand pivot',actor,hand);self.hands(h);self.arms.append((t,h,top,hand,actor,side))
        self.ell('Pelvis',(0,0,.88),(width*.88,.19,.20),'skin',actor)
        self.ell('Neck',(0,0,1.65),(.115,.115,.19),'skin',actor)
        style={'minotaur':'bull','cyclops':'cyclops','talos':'bronze','medusa':'gorgon','satyr':'satyr','sphinx':'sphinx','echidna':'echidna'}.get(kind,'human')
        head=self.head(style,actor,(0,.015,1.84),1.12 if kind in ('minotaur','cyclops') else 1)
        if kind in ('medusa',):self.snake_hair(head)
        if kind in ('maenads','scylla','sphinx'):self.crown(head,kind=='maenads')
        if kind in ('medusa','maenads','hector','satyr','minotaur','cyclops'):
            # A continuous flared garment rather than rigid stacked rings.
            n=16;vs=[]
            for zz,rx,ry in [(1.07,width*.76,.19),(.86,width*.93,.23),(.54,width*1.15,.29)]:
                for j in range(n):
                    a=math.tau*j/n;r=1+.065*math.cos(6*a)
                    vs.append((math.cos(a)*rx*r,math.sin(a)*ry*r,zz))
            self.K.mesh('Wrapped cloth skirt',vs,[(k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j) for k in range(2) for j in range(n)],self.mats['cloth'],actor,True)
            if female:
                self.tube('Asymmetric wrapped bodice',[(0,0,1.02),(0,0,1.18),(0,0,1.38),(0,0,1.54)],[(width*.90,.23),(width*1.18,.32),(width*1.34,.37),(width*.92,.25)],'cloth',actor,24)
                self.ell('Gold shoulder clasp',(-width*.75,.245,1.52),(.05,.035,.05),'metal',actor)
        if kind in ('medusa','maenads'):
            n=24;vs=[]
            for z,rx,ry in [(1.10,.25,.24),(.92,.40,.33),(.63,.43,.36),(.33,.44,.39),(.075,.46,.42)]:
                for j in range(n):
                    a=math.tau*j/n;r=1+.07*math.cos(8*a)
                    vs.append((math.cos(a)*rx*r,math.sin(a)*ry*r,z+.02*math.sin(3*a)))
            faces=[(row*n+j,row*n+(j+1)%n,(row+1)*n+(j+1)%n,(row+1)*n+j) for row in range(4) for j in range(n) if j not in (5,6)]
            self.K.mesh('Long slit Greek dress',vs,faces,self.mats['cloth'],actor,True)
        if kind=='harpies':
            self.tube('Harpy feather chest',[(0,0,1.02),(0,0,1.18),(0,0,1.38),(0,0,1.54)],[(.25,.24),(.29,.32),(.335,.37),(.23,.25)],'fur',actor,24)
            self.tube('Harpy feather hip mantle',[(0,0,1.0),(0,0,.84),(0,0,.62)],[(.28,.26),(.32,.30),(.35,.31)],'fur',actor,24)
            for j in range(14):
                a=math.tau*j/14
                self.horn(actor,[(.29*math.cos(a),.28*math.sin(a),.83),(.34*math.cos(a),.33*math.sin(a),.59),(.35*math.cos(a),.34*math.sin(a),.46)],.049,'fur','Harpy body feather')
        if kind=='talos':
            for z,r in [(1.38,.39),(1.12,.30),(.87,.28)]:
                self.ell('Bronze articulated cuirass',(0,.01,z),(r,.253,.17),'metal',actor,3)
            for side in (-1,1):
                self.ell('Bronze shoulder guard',(side*.42,0,1.50),(.23,.195,.21),'metal',actor)
                self.ell('Bronze elbow joint',(side*.59,0,1.22),(.11,.11,.12),'horn',actor)
            self.ell('Bronze helmet',(0,-.01,.065),(.22,.175,.225),'metal',head)
            for j in range(13):self.horn(head,[(0,-.16+j*.025,.25),(0,-.16+j*.025,.37)],.032,'metal','Bronze helmet crest')
        if kind=='hector':
            self.ell('Trojan breastplate',(0,.04,1.32),(.365,.252,.29),'metal',actor,3)
            self.ell('Helmet cap',(0,-.01,.06),(.205,.16,.23),'metal',head)
            for j in range(13):self.ell('Helmet crimson crest',(0,-.16+j*.025,.27),(.045,.04,.12),'cloth',head,1)
            shield=self.K.empty('Bronze round shield',actor,(-.59,.13,1.1));shield.rotation_euler.x=math.pi/2
            self.ell('Shield face',(0,0,0),(.31,.31,.045),'metal',shield,3)
            self.ell('Shield boss',(0,0,.035),(.075,.075,.065),'metal',shield)
            self.horn(actor,[(.62,.04,.38),(.62,.04,1.97)],.018,'horn','Spear haft')
            self.horn(actor,[(.62,.04,1.86),(.62,.04,2.09)],.060,'metal','Spear point')
            cloak=self.K.material('Monster cloth red cloak',linear((.42,.055,.035)),rough=.9)
            vs=[];cols=9
            for z,rx,y in [(1.55,.32,-.20),(1.15,.40,-.28),(.66,.44,-.34),(.12,.49,-.42)]:
                for j in range(cols):
                    x=(j/(cols-1)-.5)*rx*2
                    vs.append((x,y-.022*math.cos(j*math.pi),z+.016*math.sin(j*1.8)))
            self.K.mesh('Hector draped red cape',vs,[(r*cols+j,r*cols+j+1,(r+1)*cols+j+1,(r+1)*cols+j) for r in range(3) for j in range(cols-1)],cloak,actor,True)
        if kind=='maenads':
            self.horn(actor,[(.53,.03,.42),(.53,.03,1.93)],.022,'horn','Thyrsus staff')
            self.ell('Thyrsus pine cone',(.53,.03,1.94),(.074,.074,.13),'belly',actor)
        if kind=='satyr':
            for j in range(6):self.horn(actor,[(-.11+j*.041,.26,1.0),(-.11+j*.041,.26,1.17+j*.025)],.017,'belly','Panpipe')
        if kind in ('minotaur','satyr'):
            pp=[(0,-.14,.88),(.25,-.39,.71),(.45,-.56,.83)]
            t=self.tube('Bovine or goat tail',spline(pp,20),[.06*(1-j/20)+.007 for j in range(20)],parent=actor)
            self.tails.append((t,pp,'tail',0))
        if kind=='cyclops':
            for j in range(5):self.horn(head,[((j-2)*.04,-.08,.20),((j-2)*.05,-.12,.30),((j-2)*.06,-.04,.29)],.014,'fur','Sparse Cyclops scalp hair')
        if wings:
            self.wing(actor,-1,kind!='echidna',1.50);self.wing(actor,1,kind!='echidna',1.50)
        self.actors.append((actor,Vector((x,y,0)),kind))
        if not tail:
            for side in (-1,1):
                foot=self.leg(x+side*.17*scale,y,.92*scale,False,kind in ('satyr','minotaur'))
                if kind=='harpies':
                    for j in range(3):
                        xx=(j-1)*.075
                        self.horn(foot,[(xx,.15,-.012),(xx,.27,-.02),(xx,.32,-.071)],.023,'horn','Hooked harpy talon')
                if kind=='talos':
                    for ob in foot.children_recursive:
                        if ob.type=='MESH':ob.data.materials.clear();ob.data.materials.append(self.mats['metal'])
                    self.ell('Talos ankle seal',(0,.06,.15),(.055,.035,.055),'metal',foot)
        return actor,head

    def quadruped(self,kind):
        chest=self.K.empty('Massive quadruped chest',self.root)
        self.tube('Continuous quadruped barrel',[(0,-.76,.77),(0,-.52,.93),(0,-.04,1.02),(0,.40,1.0),(0,.57,.97)],[(.27,.28),(.39,.39),(.46,.46),(.49,.48),(.35,.29)],parent=chest,ring=24)
        for side in (-1,1):
            self.ell('Shoulder muscle',(side*.35,.34,.94),(.23,.32,.33),parent=chest,subdiv=3)
            self.ell('Haunch',(side*.30,-.55,.86),(.23,.29,.30),parent=chest,subdiv=3)
            for y in (-.62,.39):self.leg(side*.39,y,.89,True,kind=='calydonianboar')
        count=3 if kind=='cerberus' else 1
        for i in range(count):
            x=(i-(count-1)/2)*.43
            top=(x,.66,1.44 if count==1 or i!=1 else 1.65)
            pts=[(x*.35,.37,1.02),(x*.7,.48,1.22),top]
            t=self.tube('Powerful neck',spline(pts,12),[.21*(1-.20*j/11) for j in range(12)],parent=chest)
            style={'cerberus':'dog','calydonianboar':'boar','chimera':'lion','dragon':'reptile'}.get(kind,'lion')
            h=self.head(style,chest,top,1.08 if kind!='calydonianboar' else 1.30,(i-1)*-.18 if count==3 else 0)
            self.necks.append((t,h,pts,i))
            if kind=='dragon':self.decor.append(SurfaceDecor(self.K,t,self.mats['skin'],self.mats['belly'],self.mats['horn'],chest,12,8,spines=True))
        if kind in ('calydonianboar','cerberus'):
            for j in range(20):
                y=-.75+j*.065
                self.horn(chest,[(0,y,1.28),(0,y-.09,1.47+(j%3)*.02)],.025,'fur','Dorsal bristle')
        pts=[(0,-.77,.84),(.35,-1.20,.55),(.49,-1.63,.31),(.22,-1.92,.50)]
        t=self.tube('Whip tail',spline(pts,24),[.13*(1-j/24)+.008 for j in range(24)],parent=chest)
        self.tails.append((t,pts,'tail',0))
        if kind=='chimera':
            gp=[(0,-.15,1.25),(0,-.18,1.60),(0,-.12,1.76)]
            g=self.tube('Goat neck from back',spline(gp,10),[.14]*10,parent=chest)
            gh=self.head('goat',chest,gp[-1],.79);self.necks.append((g,gh,gp,1))
            sh=self.head('reptile',chest,pts[-1],.48);self.necks.append((None,sh,pts,2))
        if kind=='dragon':
            self.wing(chest,-1,False);self.wing(chest,1,False)
            for j in range(14):self.horn(chest,[(0,.48-j*.10,1.37),(0,.39-j*.10,1.60)],.055,'horn','Dragon ridge spine')
        if kind=='sphinx':
            # Replace the animal face with a human-headed lion; no goat head.
            old=self.necks.pop();old[1].hide_render=True
            for o in old[1].children_recursive:o.hide_render=True
            h=self.head('sphinx',chest,old[2][-1],1.05);self.crown(h)
            self.necks.append((old[0],h,old[2],0))
            self.wing(chest,-1,True);self.wing(chest,1,True)
        self.actors.append((chest,Vector((0,0,0)),kind));return chest

    def build(self):
        k=self.kind
        if k=='maenads':
            for x,y,s in [(-.43,-.12,.87),(.43,-.12,.87),(0,.26,1.)]:self.biped(k,x,y,s)
        elif k=='harpies':
            for x,y in [(-.57,-.12),(.57,.12)]:self.biped(k,x,y,.90,True)
        elif k=='minotaur':
            from godot_minotaur import build_anatomy
            build_anatomy(self)
        elif k in ('cyclops','talos','hector','satyr','medusa'):self.biped()
        elif k in ('calydonianboar','cerberus','chimera','sphinx','dragon'):self.quadruped(k)
        elif k=='echidna':
            self.quadruped('dragon')
            for wing,side in self.wings:
                for o in wing.children_recursive:o.hide_render=True
            self.wings.clear()
            # The mother of monsters replaces the dragon neck/head with a torso.
            for t,h,pts,i in self.necks:
                t.ob.hide_render=True
                for o in h.children_recursive:o.hide_render=True
            self.necks.clear()
            for decoration in self.decor:
                for entry in decoration.entries + decoration.bands:
                    entry[0].hide_render=True
            self.decor.clear()
            self.biped(k,0,.37,.70,True,True)
            self.actors[-1][0].location.z=.45
            self.actors[-1]=(self.actors[-1][0],Vector((0,.37,.45)),k)
            torso=self.actors[-1][0]
            mane=self.K.material('Monster fur cream chest mane',linear((.67,.65,.41)),rough=.92)
            for i in range(9):
                x=(i-4)*.045
                ob=self.horn(torso,[(x,.15,1.62),(x*1.7,.22,1.49),(x*1.5,.22,1.31-.08*math.cos(i))],.049,'fur','Echidna cream chest mane')
                ob.ob.data.materials.clear();ob.ob.data.materials.append(mane)
        elif k=='scylla':
            self.ell('Submerged sea trunk',(0,0,.38),(.43,.38,.43),subdiv=3)
            actor,head=self.biped(k,0,0,.82,False,True)
            self.actors[-1]=(actor,Vector((0,0,.34)),k);actor.location.z=.34
            for i in range(6):
                a=math.tau*i/6;x=math.cos(a);y=math.sin(a)
                pts=[(.20*x,.20*y,.5),(.62*x,.52*y,.63),(.78*x,.66*y,1.06),(.90*x,.80*y,1.30+(i%2)*.20)]
                t=self.tube('Scylla dog neck',spline(pts,20),[.145*(1-.30*j/19) for j in range(20)])
                h=self.head('dog',self.root,pts[-1],.82,-a)
                self.necks.append((t,h,pts,i))
        else:
            mantle=self.K.empty('Kraken mantle',self.root,(0,0,.99))
            self.ell('Kraken bulbous mantle',(0,-.13,.26),(.62,.52,.79),'skin',mantle,3)
            self.ell('Kraken brow',(0,.40,.18),(.37,.23,.30),'belly',mantle,3)
            self.ell('Kraken single eye white',(0,.56,.21),(.27,.13,.23),'teeth',mantle,3)
            self.ell('Kraken single eye iris',(0,.675,.21),(.16,.045,.18),'eyes',mantle)
            self.ell('Kraken eye slit',(0,.715,.21),(.035,.014,.13),'horn',mantle)
            self.ell('Kraken beak',(0,.52,-.10),(.13,.15,.13),'horn',mantle)
            self.actors.append((mantle,Vector((0,0,.99)),k))
            for i in range(8):
                a=math.tau*i/8;x=math.cos(a);y=math.sin(a)
                pts=[(.30*x,.30*y,.69),(.72*x,.72*y,.23),(1.27*x,1.27*y,.14),(1.53*x,1.53*y,.34),(1.42*x,1.42*y,.62),(1.22*x,1.22*y,.57)]
                t=self.tube('Kraken curling arm',spline(pts,32),[.19*(1-j/32)**1.3+.007 for j in range(32)],ring=16)
                self.tails.append((t,pts,'arm',i))
                for j in range(14):
                    p=Vector(t.points[2+j*2]);r=.056*(1-j/16)
                    o=self.ell('Kraken sucker',p+Vector((0,0,-.10*(1-j/16))),(r,r,r*.4),'belly',self.root,1)
                    o['arm_index']=i;o['arm_u']=(2+j*2)/31
        from godot_monster_refinement import refine
        refine(self)
        for actor,pos,kind in self.actors:
            objects=[o for o in actor.children if o.type=='MESH' and o.active_material==self.mats['skin'] and
                     any(o.name.startswith(term) for term in ('Sculpted trunk','Pectoral','Deltoid','Pelvis','Neck','Continuous quadruped barrel','Shoulder muscle','Haunch'))]
            self.fuse(actor,objects,.026)
        self.animate(0,'idle')
        bpy.context.view_layer.update()
        lo,hi=self.limits()
        self.scale=self.height/(hi-lo)
        self.root.scale=(self.scale,)*3
        self.base_z=.025-lo*self.scale
        self.root.location.z=self.base_z
        for o in self.root.children_recursive:
            if o.type=='MESH' and not o.hide_render:
                previous=o.data.color_attributes.get('Coat colour')
                if previous:o.data.color_attributes.remove(previous)
                paint(o,o.active_material.diffuse_color[:3] if False else self.color_of(o),.012 if self.kind=='minotaur' else .045)
        self.animate(0,'idle')
        return self

    def color_of(self,o):
        # Material colours are already linear; invert before the shared painter.
        c=o.active_material.diffuse_color[:3]
        return tuple(12.92*v if v<=.0031308 else 1.055*v**(1/2.4)-.055 for v in c)

    def limits(self):
        deps=bpy.context.evaluated_depsgraph_get(); zs=[]
        # Exporter-created rest meshes must not influence authored collapse grounding.
        for o in self.root.children_recursive:
            if o.type=='MESH' and not o.hide_render:
                e=o.evaluated_get(deps)
                zs.extend((e.matrix_world@v.co).z for v in e.data.vertices)
        return min(zs),max(zs)

    def animate(self,f,clip):
        self.root.rotation_euler=(0,0,0)
        self.root.location=(0,0,getattr(self,'base_z',0))
        phase=f/24;breath=math.sin(math.tau*f/12)*.010
        strike=math.sin(math.tau*phase)
        death=smooth(f/29) if clip=='die' else 0
        for actor,pos,k in self.actors:
            actor.location=pos+Vector((0,0,breath if clip=='idle' else .012*math.sin(math.tau*phase)))
            actor.rotation_euler=(.07*max(0,strike) if clip=='fight' else 0,0,.05*strike if clip=='fight2' else 0)
        for j,(t,foot,top,base,quad) in enumerate(self.legs):
            if self.kind=='minotaur':continue
            p=(phase+(j%2)*.5+(j//2)*.25)%1
            stance=.72
            if clip=='walk':
                dy=(.32-.64*p)/max(self.scale,.01) if p<stance else ((.32-.64*stance)+.64*stance*smooth((p-stance)/(1-stance)))/max(self.scale,.01)
                lift=0 if p<stance else .12*math.sin(math.pi*(p-stance)/(1-stance))
            else:dy=lift=0
            end=base+Vector((0,dy,lift));foot.location=end
            knee=top.lerp(end,.55)+Vector((0,-.13 if quad else .11,.055))
            pts=spline([top,knee,end+Vector((0,0,.07))],12);t.update(pts)
        for t,h,top,base,actor,side in self.arms:
            if clip=='fight':target=Vector((side*.37,.43,1.43+.12*strike))
            elif clip=='fight2':target=Vector((side*.62,.20,1.48+.14*strike))
            else:target=base+Vector((0,.13*side*math.sin(math.tau*phase) if clip=='walk' else 0,breath))
            t.update(spline([top,top.lerp(target,.56)+Vector((side*.08,0,-.09)),target],10));h.location=target
        for t,h,pts,i in self.necks:
            pp=[Vector(p) for p in pts]
            sway=.025*math.sin(math.tau*phase+i)
            attack=max(0,math.sin(math.tau*phase-i*.9)) if clip=='fight' else 0
            pp[-1]+=Vector((sway,.22*attack,-.12*attack))
            if t:t.update(spline(pp,len(t.radii)))
            h.location=pp[-1];h.rotation_euler.x=.06*strike
        for h,jaw,m in self.heads:jaw.rotation_euler.x=-(.30*max(0,strike)+.06 if clip in ('fight','fight2') else .035)
        for w,side in self.wings:
            w.rotation_euler.y=side*(.10*math.sin(math.tau*phase) if clip=='walk' else .16*strike if clip=='fight2' else .025*math.sin(math.tau*f/12))
        for t,pts,mode,i in self.tails:
            pp=[Vector(p) for p in pts]
            for j in range(1,len(pp)):
                amplitude=.024 if mode=='hair' else .095 if mode=='arm' else .12
                pp[j].x+=amplitude*math.sin(math.tau*phase+i+j*.8)
                if mode=='arm':pp[j].z+=.035*math.sin(math.tau*phase+i)
            t.update(spline(pp,len(t.radii)))
            if mode=='arm':
                for o in self.root.children:
                    if o.get('arm_index',-1)==i:
                        u=o['arm_u'];p=t.points[round(u*(len(t.points)-1))]
                        o.location=p+Vector((0,0,-.10*(1-u)))
        for decoration in self.decor:decoration.update()
        if self.kind=='minotaur':
            from godot_minotaur import animate_anatomy
            animate_anatomy(self,f,clip)
        if death:
            self.root.rotation_euler.y=math.pi*.49*death
            self.root.scale=(self.scale*(1-.72*death),self.scale,self.scale*(1-.38*death))
            bpy.context.view_layer.update();lo,_=self.limits();self.root.location.z+=.025-lo
        else:self.root.scale=(self.scale,)*3
        bpy.context.view_layer.update()
        mouths=[]
        for h,jaw,m in self.heads:
            if any(o.type=='MESH' and not o.hide_render for o in h.children_recursive):
                v=h.matrix_world@m;mouths.append([round(v.x,6),round(v.z,6),round(-v.y,6)])
        if self.kind=='kraken':
            v=self.actors[0][0].matrix_world@Vector((0,.56,-.10))
            mouths.append([round(v.x,6),round(v.z,6),round(-v.y,6)])
        feet=[]
        for _,foot,*rest in self.legs:
            v=foot.matrix_world.translation;feet.append([round(v.x,6),round(v.z-.079*self.scale,6),round(-v.y,6)])
        self.probes[f'{clip}_{int(f):02d}']={'root':[0,0,0],'mouths':mouths,'feet':feet}

    def manifest(self):
        result={'revision':REVISION,'species':self.kind,'design':self.design,
         'vertex_budget':VERTEX_BUDGET,'imported_vertex_budget':34000,'triangle_budget':34000,
         'shader':'res://shaders/monster_reference.gdshader','heads':len(self.probes['idle_00']['mouths']),
         'legs':len(self.legs),'height_tiles':self.height,'pose_probes':self.probes,
         'clips':{'walk':24,'idle':12,'fight':24,'fight2':24,'die':30},
         'scale_contract':'larger than citizen; all non-death pose tops below Zeus body',
         'source':'eZeus/tools/godot_monster_reference.py','rights_status':'needs_evidence'}
        if self.kind=='minotaur':
            from godot_minotaur import DESIGN_REVISION
            result.update(design_revision=DESIGN_REVISION,
                          anatomy_source='eZeus/tools/godot_minotaur.py',
                          reference='art/monsters/minotaur/minotaur-target-reference-v2.png')
        if self.kind!='minotaur':
            from godot_monster_refinement import REVISION as design_revision
            result.update(design_revision=design_revision, anatomy_source='eZeus/tools/godot_monster_refinement.py')
        return result


CURRENT=None
def build(K,kind):
    global CURRENT
    from godot_monster_anatomy import Anatomy
    CURRENT=Anatomy(K,kind).build()
    recipe=bpy.data.texts.new('Godot monster pose recipe.py')
    recipe.write(Path(__file__).read_text())
    if kind=='minotaur':
        recipe=bpy.data.texts.new('Minotaur reference v2 anatomy.py')
        recipe.write(Path(__file__).with_name('godot_minotaur.py').read_text())
    recipe=bpy.data.texts.new('Monster sheet refinement v2.py')
    recipe.write(Path(__file__).with_name('godot_monster_refinement.py').read_text())
    recipe=bpy.data.texts.new('Monster anatomical rebuild v3.py')
    recipe.write(Path(__file__).with_name('godot_monster_anatomy.py').read_text())
    target=Path(__file__).resolve().parents[2]/'art/monsters'/kind/(kind+'-reference-v3.blend')
    target.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(target))
    def fn(clip):return lambda f:CURRENT.animate(f,clip)
    return fn('walk'),fn('idle'),[(c,n,fn(c)) for c,n in [('fight',24),('fight2',24),('die',30)]]


def manifest():return CURRENT.manifest()


if __name__=='__main__':
    import sys
    root=Path(__file__).resolve().parents[2]
    sys.path.insert(0,str(root/'art/_kit'))
    import ezkit as K
    kind=sys.argv[sys.argv.index('--kind')+1]
    from godot_monster_anatomy import Anatomy
    sculpt=Anatomy(K,kind).build()
    for clip,n in [('walk',24),('idle',12),('fight',24),('fight2',24),('die',30)]:
        for f in range(n):
            sculpt.animate(f,clip)
            for o in K.scene.objects:
                if o.type=='EMPTY':
                    o.keyframe_insert('location',frame={'walk':0,'idle':30,'fight':50,'fight2':80,'die':110}[clip]+f)
                    o.keyframe_insert('rotation_euler',frame={'walk':0,'idle':30,'fight':50,'fight2':80,'die':110}[clip]+f)
    sculpt.animate(0,'idle')
    target=root/'art/monsters'/kind/(kind+'-reference-v3.blend')
    target.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(target))
