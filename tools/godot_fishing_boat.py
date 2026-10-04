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

