"""Distinct realtime science walkers, built from local CC0 anatomy and new role props."""
import sys,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'art/_kit'));sys.path.insert(0,str(ROOT/'art/characters/people'));sys.path.insert(0,str(ROOT/'art/characters/identities'))
import ezkit as K
from person_kit import make_person,walk,lin
import identity
who=sys.argv[sys.argv.index('--who')+1]
data={'astronomer':('Astronomer',57,(.20,.28,.58),1.04,.94,.009,.035,.54,9827),
      'inventor':('Inventor',31,(.50,.28,.12),1.14,1.04,.003,.010,0,9828),
      'curator':('Curator',44,(.43,.20,.40),.97,1.02,.005,.022,.15,9829)}
name,age,cloth,jaw,cheek,nose,beard,grey,seed=data[who]
identity.PROFILES[name]=dict(age=age,skin=(.50,.31,.20),jaw=jaw,cheek=cheek,nose=nose,chin=.004,eye=.99,hair=((.06,.035,.018),(.20,.14,.08)),hair_length=.019,beard_length=beard,grey=grey,seed=seed)
K.setup(who,1,seed=seed,out_dir=ROOT/'eZeus/godot/assets/models')
h=make_person(K,K.Palette(),name,cloth,seed=seed)
bronze=K.material('Scientific bronze',(.60,.34,.09),metal=.7,rough=.35)
linen=K.material('Scroll parchment',(.78,.66,.44),rough=.9)
prop=K.empty(name+' carried instrument',K.root)
if who=='astronomer':
 for axis in [0,1]:
  vs=[]
  for k in range(32):
   angle=k*math.tau/32
   for radius in [.072,.08]:
    vs.append((radius*math.cos(angle),radius*math.sin(angle) if axis else 0,radius*math.sin(angle) if not axis else 0))
  K.mesh('Astrolabe ring',vs,[(2*k,2*k+1,(2*k+3)%64,(2*k+2)%64) for k in range(32)],bronze,prop)
 K.rod('Astrolabe pointer',(-.07,0,0),(.07,0,0),.005,bronze,prop)
elif who=='inventor':
 for x in [-.06,.06]:
  wheel=K.cyl('Demonstration wheel',(x,0,0),.065,.014,bronze,20,prop)
  wheel.rotation_euler.y=math.pi/2
 K.rod('Mechanism spindle',(-.08,0,0),(.08,0,0),.009,bronze,prop)
else:
 scroll=K.cyl('Museum scroll',(0,0,0),.024,.19,linen,20,prop)
 scroll.rotation_euler.y=math.pi/2
 K.box('Catalog tablet',(0,.015,-.025),(.14,.018,.11),linen,.004,prop)
def pose(frame):
 _,hands=walk(h,frame,N=24,stride=.21,hands=lambda p:{1:(.16,.15,.45),-1:(-.15,.04+.04*math.cos(p),.41)})
 prop.location=h.root.matrix_basis@Vector(hands[1])
pose(0)
