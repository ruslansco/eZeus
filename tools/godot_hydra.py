"""Godot-only three-headed Hydra, authored from the user's creature reference.

Editable fixed-topology surfaces and in-place poses. Native people9.py, atlases
and live Blender scenes are untouched. +Y is forward, Z is up in Blender.
"""
import math
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector, Matrix

REVISION = 'hydra_reference_v1'
VERTEX_BUDGET = 24000
WALK_SAMPLES = 24
COMBAT_SAMPLES = 24
DIE_SAMPLES = 30
TAU = math.tau
POSE_PROBES = {}


def linear(rgb):
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb)


def smooth(t):
    t = max(0., min(1., t))
    return t * t * (3 - 2 * t)


def spline(points, count):
    p = [Vector(v) for v in points]
    out = []
    for k in range(count):
        u = k / (count - 1) * (len(p) - 1)
        i = min(int(u), len(p) - 2)
        t = u - i
        a, b, c, d = p[max(0, i - 1)], p[i], p[i + 1], p[min(len(p) - 1, i + 2)]
        out.append(.5 * (2*b + (-a+c)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t))
    return out


def frame(direction):
    f = Vector(direction).normalized()
    x = f.cross(Vector((0, 0, 1)))
    if x.length < .05:
        x = Vector((1, 0, 0))
    x.normalize()
    up = x.cross(f).normalized()
    return x, f, up


def paint(ob, rgb, variation=.12):
    """Point palette follows geometry through the existing creature exporter."""
    attr = ob.data.color_attributes.new(name='Coat colour', type='FLOAT_COLOR', domain='POINT')
    base = linear(rgb)
    for i, vertex in enumerate(ob.data.vertices):
        p = vertex.co
        shade = 1 + variation * (.55 * math.sin(p.x * 37 + p.y * 29 + p.z * 17) + .45 * math.sin(i * 2.39996))
        attr.data[i].color = (*[max(.001, c * shade) for c in base], 1)


class Tube:
    """Parallel-transport swept skin with stable topology and oval sections."""
    def __init__(self, K, name, radii, material, parent, ring=16, side_sign=1):
        self.K, self.radii, self.ring = K, radii, ring
        self.side_sign = side_sign
        n = len(radii)
        faces = []
        for j in range(n-1):
            for i in range(ring):
                a = j*ring+i
                faces.append((a, a+ring, (j+1)*ring+(i+1)%ring, j*ring+(i+1)%ring))
        faces += [tuple(range(ring)), tuple((n-1)*ring+i for i in reversed(range(ring)))]
        self.ob = K.mesh(name, [(0,0,0)]*(n*ring), faces, material, parent, True)
        self.points, self.frames = [], []

    def update(self, points):
        self.points = [Vector(v) for v in points]
        vertices, self.frames = [], []
        side = Vector((self.side_sign,0,0))
        for j, p in enumerate(self.points):
            f = (self.points[min(j+1,len(points)-1)] - self.points[max(0,j-1)]).normalized()
            side = (side-f*side.dot(f)).normalized()
            if side.length < .01:
                side = frame(f)[0]
            up = side.cross(f).normalized()
            self.frames.append((side.copy(), f, up))
            rx, rz = self.radii[j] if isinstance(self.radii[j], tuple) else (self.radii[j],)*2
            for i in range(self.ring):
                a = TAU*i/self.ring
                vertices.append(p + side*math.cos(a)*rx + up*math.sin(a)*rz)
        self.ob.data.vertices.foreach_set('co', np.asarray(vertices, dtype=np.float32).ravel())
        self.ob.data.update()

    def at(self, u, angle):
        j = min(len(self.points)-2, int(u*(len(self.points)-1)))
        f = u*(len(self.points)-1)-j
        p = self.points[j].lerp(self.points[j+1], f)
        side, tangent, up = self.frames[j]
        r0 = self.radii[j] if isinstance(self.radii[j], tuple) else (self.radii[j],)*2
        r1 = self.radii[j+1] if isinstance(self.radii[j+1], tuple) else (self.radii[j+1],)*2
        rx, rz = (r0[k]*(1-f)+r1[k]*f for k in range(2))
        normal = (side*math.cos(angle)+up*math.sin(angle)).normalized()
        p += side*math.cos(angle)*rx + up*math.sin(angle)*rz
        return p, side, tangent, normal


def plate(K, name, material, parent, width, length, rise=.014):
    # Raised overlapping hexagonal scute with a central keel and bevel-like rim.
    curve = min(.025,width*.12)
    v = [(-width*.5,0,-curve),(-width*.38,-length*.43,-curve*.5),(0,-length*.58,0),
         (width*.38,-length*.43,-curve*.5),(width*.5,0,-curve),(0,length*.5,0),
         (0,-length*.06,rise)]
    ob = K.mesh(name,v,[(i,(i+1)%6,6) for i in range(6)],material,parent,True)
    return ob


def spike(K, name, material, parent, length=.2, width=.07):
    # A hooked swept thorn rather than a straight cone.
    pts = spline([(0,0,0),(0,-length*.08,length*.30),(0,-length*.45,length*.72),(0,-length*.92,length)],5)
    tube = Tube(K,name,[width,width*.85,width*.58,width*.28,.001],material,parent,8)
    tube.update(pts)
    return tube.ob


def belly_shield(K, material, parent, radius, length):
    # Broad bands curve around the neck instead of reading as flat pointed fins.
    vertices = []
    width = radius * 1.72
    for y, taper in [(-length*.48,.86),(0,1),(length*.48,.86)]:
        for column in range(5):
            x = (column/4-.5)*width*taper
            sag = radius*(1-math.sqrt(max(.01,1-(x/radius)**2)))
            vertices.append((x,y,-sag+.008*(1-abs(column-2)/2)))
    faces = [(j*5+i,j*5+i+1,(j+1)*5+i+1,(j+1)*5+i) for j in range(2) for i in range(4)]
    return K.mesh('Hydra curved ventral shield',vertices,faces,material,parent,True)


class SurfaceDecor:
    def __init__(self,K,tube,skin,belly,horn,parent,rows,columns,belly_angle=-math.pi*.5,spines=True):
        self.tube = tube
        self.entries = []
        self.bands = []
        for row in range(rows):
            u = (row+.4)/(rows+.2)
            # Visible outer scales and broad segmented belly shields.
            for col in range(columns):
                angle = TAU*(col+(row%2)*.5)/columns
                if abs(math.atan2(math.sin(angle-belly_angle),math.cos(angle-belly_angle))) < .83:
                    continue
                material = skin
                r = tube.radii[min(len(tube.radii)-1,int(u*(len(tube.radii)-1)))]
                r = r[0] if isinstance(r,tuple) else r
                w = max(.035, TAU*r/columns*.95)
                length = sum((tube.points[j+1]-tube.points[j]).length for j in range(len(tube.points)-1))/rows*1.25
                ob = plate(K,'Hydra overlapping scute',material,parent,w,length,.008)
                self.entries.append((ob,u,angle,False))
            r = tube.radii[min(len(tube.radii)-1,int(u*(len(tube.radii)-1)))]
            r = r[0] if isinstance(r,tuple) else r
            length = sum((tube.points[j+1]-tube.points[j]).length for j in range(len(tube.points)-1))/rows*1.28
            ob = belly_shield(K,belly,parent,r,length)
            self.bands.append((ob,u,belly_angle,.92/rows))
            if spines and row > 1:
                ob = spike(K,'Hydra swept dorsal spine',horn,parent,.08+.14*math.sin(u*math.pi),.038)
                self.entries.append((ob,u,math.pi*.5,True))
        self.update()

    def update(self):
        for ob,u,angle,is_spine in self.entries:
            p,side,tangent,normal = self.tube.at(u,angle)
            lateral = tangent.cross(normal).normalized()
            up = lateral.cross(tangent).normalized()
            ob.matrix_basis = Matrix.Translation(p+normal*.004) @ Matrix((lateral,tangent,up)).transposed().to_4x4()
        for ob,u,angle,span in self.bands:
            vertices = []
            for row in range(3):
                v = max(.001,min(.999,u+(row/2-.5)*span))
                taper = .88 if row != 1 else 1.0
                for column in range(5):
                    a = angle + (.5-column/4)*1.85*taper
                    p,side,tangent,normal = self.tube.at(v,a)
                    vertices.append(p+normal*.008)
            ob.data.vertices.foreach_set('co',np.asarray(vertices,dtype=np.float32).ravel())
            ob.data.update()


class Head:
    def __init__(self,K,name,skin,belly,horn,mouth,tooth,eye,parent):
        self.root = K.empty(name,parent)
        # Ring profiles sculpt a wedge-shaped skull: back, brow, muzzle, nose.
        profiles = [(-.20,.10,.09,.02),(-.09,.185,.135,.03),(.08,.17,.115,.015),
                    (.27,.14,.078,-.015),(.39,.115,.05,-.026)]
        v=[];faces=[]
        for y,w,h,z in profiles:
            for i in range(12):
                a=TAU*i/12
                v.append((w*math.cos(a),y,z+h*math.sin(a)))
        for j in range(len(profiles)-1):
            for i in range(12):
                a=j*12+i;faces.append((a,a+12,(j+1)*12+(i+1)%12,j*12+(i+1)%12))
        faces += [tuple(range(12)),tuple(48+i for i in reversed(range(12)))]
        skull=K.mesh(name+' wedge skull',v,faces,skin,self.root,True)
        paint(skull,(.30,.255,.28))
        K.ell(name+' recessed mouth',(0,.21,-.082),(.118,.19,.038),mouth,self.root,2)
        self.jaw=K.empty(name+' jaw hinge',self.root,(0,-.04,-.10))
        K.ell(name+' muscular lower jaw',(0,.23,-.005),(.13,.22,.045),skin,self.jaw,2)
        K.ell(name+' inner jaw',(0,.24,.03),(.106,.19,.015),mouth,self.jaw,2)
        K.ell(name+' lower chin',(0,.30,-.037),(.09,.14,.017),belly,self.jaw,1)
        for s in [-1,1]:
            e=K.ell(name+' crimson slit eye',(s*.160,.055,.080),(.030,.070,.026),eye,self.root,2)
            e.rotation_euler.y=s*-.26
            # Heavy descending eyebrow masks the top half of the eye.
            brow=K.ell(name+' threatening brow',(s*.154,.06,.114),(.062,.13,.045),skin,self.root,2)
            brow.rotation_euler.y=s*-.30; brow.rotation_euler.z=s*.28
            K.ell(name+' nostril',(s*.059,.379,.002),(.022,.007,.017),mouth,self.root,1)
            cheek=K.ell(name+' cheek armor',(s*.16,-.045,-.01),(.065,.12,.07),skin,self.root,2)
            for i in range(7):
                y=.07+i*.043; x=s*(.128-.028*i/6)
                fang = Tube(K,name+' upper tooth',[.015,.012,.001],tooth,self.root,6)
                fang.update([(x,y,-.039),(x,y+.008,-.080),(x,y+.02,-.11-(.03 if i in [0,4] else 0))])
                fang = Tube(K,name+' lower tooth',[.012,.009,.001],tooth,self.jaw,6)
                fang.update([(x*.9,y+.04,.040),(x*.9,y+.045,.069),(x*.9,y+.05,.09)])
            h=spike(K,name+' swept temple horn',horn,self.root,.29,.063)
            h.location=(s*.125,-.12,.13); h.rotation_euler.y=s*.4
            for i in range(2):
                h=spike(K,name+' cheek fin',horn,self.root,.12,.035)
                h.location=(s*.20,-.08-i*.08,-.02);h.rotation_euler.y=s*.85
        for i in range(4):
            ob=plate(K,name+' skull shield',skin,self.root,.19-i*.02,.11,.025)
            ob.location=(0,.23-i*.105,.098+i*.015)
        h=spike(K,name+' sagittal crest',horn,self.root,.17,.04)
        h.location=(0,-.17,.13)

    def place(self,point,forward,opening=.2):
        x,f,up=frame(forward)
        self.root.matrix_basis=Matrix.Translation(Vector(point)) @ Matrix((x,f,up)).transposed().to_4x4()
        self.jaw.rotation_euler.x=-opening


class Leg:
    def __init__(self,K,side,front,skin,belly,horn,parent):
        self.side,self.front=side,front
        self.hip=Vector((side*.38,.42 if front else -.70,.67))
        self.home=Vector((side*.61,.62 if front else -.78,.09))
        self.tube=Tube(K,'Hydra foreleg' if front else 'Hydra hindleg',
                       [(.21,.20),(.20,.185),(.165,.145),(.12,.115),(.092,.085),(.07,.07)],skin,parent,14)
        self.foot=K.empty('Hydra planted forepaw' if front else 'Hydra planted hindpaw',parent)
        K.ell('Hydra broad paw',(0,.025,.018),(.17,.19,.075),skin,self.foot,2)
        for i in range(4):
            x=(i-1.5)*.075
            K.ell('Hydra articulated toe',(x,.14,.012),(.044,.12,.040),skin,self.foot,1)
            claw=Tube(K,'Hydra ivory-black talon',[.035,.025,.008,.001],horn,self.foot,7)
            claw.update([(x,.20,.03),(x,.25,.025),(x,.30,-.026),(x,.285,-.065)])
        self.set(self.home,0,0)
        self.decor=SurfaceDecor(K,self.tube,skin,belly,horn,parent,8,9,spines=False)

    def set(self,foot,bob,collapse):
        hip=self.hip+Vector((0,0,bob-.40*collapse))
        ankle=Vector(foot)+Vector((0,-.07,.12))
        mid=(hip+ankle)*.5
        mid+=Vector((self.side*(.16 if self.front else .20),-.10 if self.front else .20,.04))
        self.tube.update(spline([hip,mid,ankle,Vector(foot)],6))
        self.foot.location=foot
        if hasattr(self,'decor'):self.decor.update()


def build(K):
    POSE_PROBES.clear()
    output=Path(__file__).resolve().parents[1]/'godot/captures/hydra-source'
    K.setup('Godot Hydra',3,100426,output,exposure=.25)
    skin=K.material('Hydra charcoal aubergine skin',linear((.225,.20,.215)),rough=.72)
    belly=K.material('Hydra smoky belly scutes',linear((.47,.445,.41)),rough=.80)
    horn=K.material('Hydra black swept horn',linear((.135,.125,.14)),rough=.40)
    mouth=K.material('Hydra dark mouth',linear((.18,.055,.057)),rough=.85)
    tooth=K.material('Hydra ivory teeth',linear((.82,.77,.65)),rough=.65)
    eye=K.material('Hydra crimson eyes',linear((.90,.035,.015)),rough=.40)
    root=K.empty('Hydra reference body',K.root)
    torso=Tube(K,'Hydra continuous muscular torso',
               [(.16,.16),(.35,.28),(.44,.32),(.44,.32),(.40,.33),(.30,.32),(.14,.23)],skin,root,24)
    torso.update(spline([(0,-1.02,.62),(0,-.64,.68),(0,-.20,.73),(0,.30,.76),(0,.57,.83)],7))
    torso_rest_radii = list(torso.radii)
    paint(torso.ob,(.225,.20,.215),.12)
    body_decor=SurfaceDecor(K,torso,skin,belly,horn,root,14,14,spines=True)
    tail=Tube(K,'Hydra thick tapering hooked tail',
              [(.20*(1-i/19)**.7+.009,.17*(1-i/19)**.7+.007) for i in range(20)],skin,root,14,side_sign=-1)
    tail.update(spline([(0,-.90,.64),(.13,-1.35,.43),(.38,-1.9,.25),(.68,-2.32,.36),(.75,-2.52,.78)],20))
    tail_decor=SurfaceDecor(K,tail,skin,belly,horn,root,20,8,spines=True)
    legs=[Leg(K,s,front,skin,belly,horn,root) for front in [True,False] for s in [-1,1]]
    necks=[]; heads=[]; decor=[]
    for i in range(3):
        central=i==1
        neck=Tube(K,'Hydra central neck' if central else 'Hydra side neck',
                   [(.205-(j/19)*.093,.19-(j/19)*.085) for j in range(20)],skin,root,18)
        top=Vector(((i-1)*.53,.65,1.68 if central else 1.37))
        base=Vector(((i-1)*.21,.40,.82))
        neck.update(spline([base,((i-1)*.50,.17,1.1),((i-1)*.60,.20,top.z),top],20))
        necks.append(neck)
        decor.append(SurfaceDecor(K,neck,skin,belly,horn,root,18,10,belly_angle=-math.pi*.5,spines=True))
        heads.append(Head(K,['Hydra left','Hydra central','Hydra right'][i],skin,belly,horn,mouth,tooth,eye,root))
    # Keep actual head and crest heights below the measured Zeus body benchmark.
    scale=.94
    root.scale=(scale,)*3

    def pose(phase,mode='idle'):
        t=phase
        collapse=smooth(t) if mode=='die' else 0.
        bob=.018*math.sin(TAU*t*2) if mode=='walk' else .005*math.sin(TAU*t)
        root.location.z=0
        torso.radii=[(rx,rz*(1-.28*collapse)) for rx,rz in torso_rest_radii]
        torso.update(spline([(0,-1.02,.62-.36*collapse),
                             (0,-.64,.68-.40*collapse),(0,-.20,.73-.42*collapse),
                             (0,.30,.76+bob-.44*collapse),(0,.57,.83+bob-.44*collapse)],7))
        body_decor.update()
        tail.update(spline([(0,-.90,.64-.35*collapse),(.13,-1.35,.43-.15*collapse),
                            (.38+.09*math.sin(TAU*t),-1.9,.25),(.68+.12*math.sin(TAU*t+.5),-2.32,.36-.15*collapse),
                            (.75+.16*math.sin(TAU*t+1),-2.52,.78-.51*collapse)],20))
        tail_decor.update()
        for leg in legs:
            foot=leg.home.copy()
            if mode=='walk':
                # Three-quarter stance, short swing. Feet stay on the floor
                # during support and move opposite native travel in local space.
                offset = (0 if leg.side<0 else .5) + (0 if leg.front else .25)
                p=(t+offset)%1
                if p<.72:
                    foot.y+=(.36-p)*(.64/scale)
                else:
                    q=(p-.72)/.28
                    foot.y+=(-.36+.72*smooth(q))*(.64/scale)
                    foot.z+=math.sin(math.pi*q)*.14
            leg.set(foot,bob,collapse)
        for i,(neck,head,ornaments) in enumerate(zip(necks,heads,decor)):
            s=i-1;central=i==1
            sway=.025*math.sin(TAU*t+i*1.8)
            top=Vector((s*.53+sway,.65,1.68 if central else 1.37))
            opening=.18+.04*math.sin(TAU*t+i)
            strike=0
            rear=0
            if mode=='fight':
                q=(t*3-i)%3
                strike=math.sin(math.pi*q)**2 if q<1 else 0
                top.y+=strike*.27;top.z-=strike*.20
                opening+=strike*.68
            elif mode=='fight2':
                rear=math.sin(math.pi*t)**2
                top.y+=rear*.06;top.z+=rear*.10
                opening+=rear*.70
            top=top.lerp(Vector((s*.65,1.0,.33)),collapse)
            base=Vector((s*.21,.40,.82-.43*collapse))
            mid=Vector((s*.50+sway,.10,1.08-.60*collapse))
            arch=Vector((s*.60+sway,.15,top.z+.015))
            neck.update(spline([base,mid,arch,top],20));ornaments.update()
            forward=Vector((s*.10,.98,-.16-strike*.30+rear*.06))
            head.place(top,forward,opening*(1-collapse)+collapse*.30)
        bpy.context.view_layer.update()

    def record(label,index):
        mouths=[]
        for head in heads:
            # Jaw hinge/muzzle rather than a root-level approximate emission.
            p=head.root.matrix_world @ Vector((0,.33,-.08))
            mouths.append([round(p.x,6),round(p.z,6),round(-p.y,6)])
        feet=[]
        for leg in legs:
            p=leg.foot.matrix_world @ Vector((0,0,-.065))
            feet.append([round(p.x,6),round(p.z,6),round(-p.y,6)])
        POSE_PROBES['%s_%02d'%(label,index)]={'mouths':mouths,'feet':feet,'root':[0,0,0]}

    def walk(f):pose((f/24)%1,'walk');record('walk',int(f))
    def idle(f):pose((f/12)%1,'idle');record('idle',int(f))
    def fight(f):pose(f/24,'fight');record('fight',int(f))
    def fight2(f):pose(f/24,'fight2');record('fight2',int(f))
    def die(f):pose(f/(DIE_SAMPLES-1),'die');record('die',int(f))
    walk(0)
    return walk,idle,[('fight',24,fight),('fight2',24,fight2),('die',30,die)]


def manifest():
    return {'revision':REVISION,'adapter':'eZeus/tools/godot_hydra.py',
            'reference':'art/monsters/hydra/hydra-concept-v1.png',
            'heads':3,'legs':4,'tails':1,'vertex_budget':VERTEX_BUDGET,
            'imported_vertex_budget':32000,'triangle_budget':30000,'stride_tiles':.64,
            'palette':'charcoal aubergine skin, smoky belly, black horn, ivory teeth, crimson eyes',
            'motion':'in-place quadruped stance/swing, independent neck sway, sequential bites, shared breath, controlled collapse',
            'fight_samples':24,'fight2_samples':24,'die_samples':30,
            'pose_probes':POSE_PROBES,
            'native_assets':'unchanged people9.py and native sprite atlases',
            'rights_status':'needs_evidence'}


if __name__ == '__main__':
    import sys
    sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'art/_kit'))
    import ezkit as K
    build(K)
    target=Path(__file__).resolve().parents[2]/'art/monsters/hydra/hydra-reference-v1.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(target))
    print('HYDRA_SOURCE_SAVED',target)
