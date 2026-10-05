"""Original realtime fishing skiff: +Y bow, tile-plane waterline, anatomical rower.
Built with the local geometry kit; no original sprites are sampled.
"""
import sys, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'art/_kit'))
sys.path.insert(0,str(ROOT/'art/characters/people'))
import ezkit as K
from person_kit import make_person,cap
K.setup('fishing_skiff',2,seed=9826,out_dir=ROOT/'eZeus/godot/assets/models')
wood=K.material('Honey cedar hull',(.36,.18,.065),rough=.65)
trim=K.material('Cream gunwale',(.71,.62,.42),rough=.7)
rope=K.material('Fishing net flax',(.32,.25,.14),rough=.85)
length=1.7;width=.35
for band in range(7):
 vs=[]
 for j in range(25):
  t=-1+2*j/24
  for p in [-math.pi/2+band*math.pi/7,-math.pi/2+(band+1)*math.pi/7-.012]:
   vs.append((width*max(.025,1-t*t)**.6*math.sin(p),t*length/2,.21-.26*math.cos(p)+.07*abs(t)**4))
 K.mesh('Cedar clinker hull',vs,[(2*j,2*j+1,2*j+3,2*j+2) for j in range(24)],wood,K.root)
for y in [-.35,.06,.40]:K.box('Thwart',(0,y,.19),(.62,.10,.035),trim,.008)
for y in [-.53,-.43,-.33]:
 for x in [-.18,-.08,.02,.12]:
  K.rod('Coiled fishing net',(x,y,.22),(x+.10,y+.08,.25),.005,rope)
sys.path.insert(0,str(ROOT/'art/characters/identities'))
import identity
identity.PROFILES['Skiff fisherman']=dict(age=44,skin=(.40,.24,.15),jaw=1.08,cheek=.96,nose=.008,chin=.003,eye=.98,hair=((.03,.02,.01),(.10,.06,.03)),hair_length=.013,beard_length=.017,grey=.16,seed=9826)
h=make_person(K,K.Palette(),'Skiff fisherman',(.18,.40,.45),'exomis',beard=False,seed=9826)
cap(h,K,'petasos',(.70,.59,.36))
h.pose((0,0,h.pelvis_height-.25),.11,{s:(s*.07,.18,.03) for s in [-1,1]}, {s:(s*.14,.20,.40) for s in [-1,1]})
h.root.location=(0,-.08,.16)
K.bpy.context.view_layer.update()
for side in [-1,1]:
 handle=h.root.matrix_world@Vector(h.hands[side])
 blade=Vector((side*.73,-.22,.08))
 K.rod('Oar',handle,blade,.012,wood)
 K.box('Oar blade',blade,(.08,.23,.02),wood,.008)
# Handles follow the actual posed hands, with feet resting on the thwart.


# Fixed-topology cast-net work cycle. The same hand IK places the rope's grip;
# the hull stays at its waterline and rowing props are stowed while collecting.
import bpy
from mathutils import Matrix
base_oars=[ob for ob in bpy.data.objects if ob.name.startswith('Oar')]
oar_rest={ob:(ob.location.copy(),ob.rotation_euler.copy(),ob.scale.copy()) for ob in base_oars}
net_verts=[]; net_faces=[]
# Fine open diamond weave, rather than a floating rectangular grid.
for i in range(-5,6):
 for j in range(-5,6):
  if i*i+j*j>25: continue
  for direction in [(1,0),(0,1)]:
   ii,jj=i+direction[0],j+direction[1]
   if ii*ii+jj*jj>25: continue
   a=Vector((i*.065,j*.065,0)); b=Vector((ii*.065,jj*.065,0))
   side=(b-a).cross(Vector((0,0,1))).normalized()*.0023
   n=len(net_verts); net_verts += [tuple(a-side),tuple(a+side),tuple(b+side),tuple(b-side)]
   net_faces.append((n,n+1,n+2,n+3))
cast_net=K.mesh('Cast net diamond weave',net_verts,net_faces,rope,K.root)
net_rest=[v.co.copy() for v in cast_net.data.vertices]
line=K.rod('Cast net hand line',(0,0,0),(0,0,1),.003,rope,K.root,n=6)

def smooth(t):
 t=max(0,min(1,t)); return t*t*t*(t*(t*6-15)+10)

def rod_between(ob,a,b,r=.003):
 a,b=Vector(a),Vector(b)
 ob.location=(a+b)*.5; ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
 ob.scale=(1,1,max(.0001,(b-a).length))

def seated(hands,lean=.11,turn=0):
 h.root.location=(0,-.08,.16)
 h.pose((0,0,h.pelvis_height-.25),lean,{s:(s*.07,.18,.03) for s in [-1,1]},hands,turn=turn)
 bpy.context.view_layer.update()
 return {s:h.root.matrix_world@Vector(h.hands[s]) for s in [-1,1]}

def hide_net():
 cast_net.hide_render=True;line.hide_render=True

def idle(frame):
 seated({s:(s*.14,.20,.40) for s in [-1,1]})
 for ob,(at,rot,scale) in oar_rest.items(): ob.location=at;ob.rotation_euler=rot;ob.scale=scale;ob.hide_render=False
 hide_net()

def row(frame):
 ph=math.tau*frame/24
 grip=seated({s:(s*.14,.20+.055*math.sin(ph),.40+.025*math.cos(ph)) for s in [-1,1]},.11+.025*math.sin(ph))
 for ob,(at,rot,scale) in oar_rest.items(): ob.location=at;ob.rotation_euler=rot;ob.scale=scale;ob.hide_render=False
 for side in [-1,1]:
  suffix='' if side==-1 else '.001'
  ob=next(o for o in base_oars if o.name=='Oar'+suffix)
  blade=next(o for o in base_oars if o.name=='Oar blade'+suffix)
  at=Vector((side*.73,-.22+.085*math.sin(ph),.08+.045*max(0,math.cos(ph))))
  start=grip[side]
  length=max(v.co.z for v in ob.data.vertices)-min(v.co.z for v in ob.data.vertices)
  ob.location=(start+at)*.5;ob.rotation_euler=(at-start).to_track_quat('Z','Y').to_euler()
  ob.scale=(1,1,(at-start).length/length)
  blade.location=at;blade.rotation_euler.z=side*.08*math.sin(ph)
 hide_net()


def collect(frame):
 t=(frame%40)/40
 # Load near the hip, cast outward, let the weighted skirt settle, haul with
 # alternating grips, then bring the gathered mouth in beside the gunwale.
 load=smooth(t/.14)
 throw=smooth((t-.14)/.16)
 haul=smooth((t-.55)/.32)
 reset=smooth((t-.87)/.13)
 right=Vector((.12,.20,.42)).lerp(Vector((.24,.02,.60)),load)
 right=right.lerp(Vector((.29,.24,.50)),throw)
 right=right.lerp(Vector((.16,.13,.42)),haul)
 left=Vector((-.14,.20,.40)).lerp(Vector((.11,.17,.47)),load)
 left=left.lerp(Vector((.04,.28,.48)),throw)
 left=left.lerp(Vector((-.02,.12,.46)),haul)
 pulse=math.sin(math.tau*(t-.55)*12)*math.sin(math.pi*max(0,min(1,(t-.55)/.32))) if .55<t<.87 else 0
 right.y+=pulse*.035;left.y-=pulse*.035
 right=right.lerp(Vector((.14,.20,.40)),reset)
 left=left.lerp(Vector((-.14,.20,.40)),reset)
 grip=seated({1:tuple(right),-1:tuple(left)},.11+.06*throw*(1-haul),turn=-.05*math.sin(math.pi*t))
 for ob in base_oars:
  ob.location=oar_rest[ob][0];ob.rotation_euler=oar_rest[ob][1];ob.scale=oar_rest[ob][2];ob.hide_render=True
 # A hand-held bunched net expands in an arc, settles into a shallow bowl,
 # then tightens while the fisherman gathers the rope. Everything remains
 # linked to the solved hand and the actual waterline.
 cast_net.hide_render=False;line.hide_render=False
 near=(grip[1]+grip[-1])*.5
 far=Vector((.68,.15,.028))
 center=near.lerp(far,throw).lerp(near,haul)
 center.z+=math.sin(math.pi*throw)*.22*(1-haul)
 spread=(.12+.88*throw)*(1-.87*haul)*(1-.98*reset)
 cast_net.location=center;cast_net.rotation_euler=(0,.15*(1-throw),.35)
 cast_net.scale=(spread,spread,1)
 sag=.08*throw*(1-haul)
 for vertex,rest in zip(cast_net.data.vertices,net_rest):
  vertex.co=(rest.x,rest.y,-sag*(1-min(1,rest.xy.length/.34)))
 rod_between(line,grip[-1],center)
 if t<.025 or t>.975: hide_net()

idle(0)
