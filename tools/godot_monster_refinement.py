"""Reference-sheet silhouette/detail pass. Applied before fixed-topology pose sampling.

All attachments use existing animated parents; native rules and recipes are untouched.
The Minotaur's independently authored v2 anatomy is deliberately retained.
"""
import math
from mathutils import Vector
from godot_hydra import linear

REVISION = 'monster_sheet_refinement_v2'


def leaf(s, parent, name, start, end, width, material='fur'):
    """Closed, folded lance shape: readable feather/fur silhouette at low cost."""
    a,b=Vector(start),Vector(end);axis=(b-a).normalized()
    cross=axis.cross(Vector((0,1,0)))
    if cross.length<.01:cross=axis.cross(Vector((1,0,0)))
    cross.normalize();mid=a.lerp(b,.44);ridge=axis.cross(cross)*width*.22
    vs=[a,mid+cross*width,b,mid-cross*width,mid+ridge,mid-ridge*.3]
    return s.K.mesh(name,vs,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(1,0,5),(2,1,5),(3,2,5),(0,3,5)],s.mats[material],parent,True)


def recolor(ob,mat):
    if ob.type=='MESH':ob.data.materials.clear();ob.data.materials.append(mat)


def visible(parent,term):
    return [o for o in parent.children_recursive if o.type=='MESH' and not o.hide_render and o.name.startswith(term)]


def hide(parent,term):
    for o in visible(parent,term):o.hide_render=True


def band(s,parent,name,z,rx,ry,material='metal'):
    pts=[(rx*math.cos(i*math.tau/32),ry*math.sin(i*math.tau/32),z) for i in range(33)]
    return s.tube(name,pts,[.015]*33,material,parent,6)


def refine_head(s,h):
    if not any(o.type=='MESH' and not o.hide_render for o in h.children_recursive):return
    name=h.name.split(' expressive')[0]
    if name not in ('dog','lion','goat','boar','satyr','cyclops','echidna','bronze'):return
    jaw=next((o for o in h.children if 'jaw hinge' in o.name),None)
    if name in ('dog','lion','boar'):
        for ob in visible(h,name+' ear'):ob.scale.x*=.60;ob.scale.z*=1.4
        for side in (-1,1):
            s.horn(h,[(side*.07,.18,.16),(side*.22,.17,.17),(side*.25,.02,.17)],.024,'skin','Sloping predatory brow')
        if jaw:
            for side in (-1,1):
                s.horn(jaw,[(side*.15,.12,.025),(side*.16,.27,.02),(side*.10,.34,.015)],.020,'mouth','Sculpted gum rim')
    if name=='dog':
        for side in (-1,1):
            s.horn(h,[(side*.18,-.09,.13),(side*.28,-.15,.30),(side*.40,-.27,.32)],.070,'skin','Swept hound ear')
        h.scale.z*=1.15
    if name=='lion':
        hide(h,'Layered mane lock')
        for row in range(3):
            for i in range(16):
                a=math.tau*(i+.5*(row%2))/16
                r=.22+row*.035
                leaf(s,h,'Chimera sculpted flame mane',(math.cos(a)*r,-.05-row*.06,math.sin(a)*r),
                     (math.cos(a)*(.42+row*.045),-.17-row*.11,math.sin(a)*(.43+row*.055)-.12),.085,'fur')
        for ob in h.children_recursive:
            if ob.type=='MESH' and ob.active_material==s.mats['skin']:recolor(ob,s.mats['fur'])
    if name=='goat':
        hide(h,'Swept horn')
        for side in (-1,1):
            s.horn(h,[(side*.13,-.03,.17),(side*.33,-.09,.48),(side*.44,-.29,.46),(side*.43,-.40,.21)],.065,'horn','Chimera recurved ram horn')
        for i in range(5):leaf(s,h,'Goat pointed beard',((i-2)*.035,.13,-.18),((i-2)*.02,.10,-.44),.032)
        for ob in h.children_recursive:
            if ob.type=='MESH' and ob.active_material==s.mats['skin']:recolor(ob,s.mats['goat'])
    if name=='boar':
        for row in range(2):
            for i in range(13):
                a=math.tau*i/13
                leaf(s,h,'Boar cheek bristle',(.21*math.cos(a),-.02-row*.08,.20*math.sin(a)),(.36*math.cos(a),-.29-row*.12,.34*math.sin(a)-.05),.055)
        for ob in visible(h,'Curved boar tusk'):ob.scale*=1.35
    if name=='satyr':
        hide(h,'Layered mane lock')
        for i in range(9):
            x=(i-4)*.033
            leaf(s,h,'Satyr pointed beard',(x,.25,-.11),(x*.6,.25,-.40+.02*abs(i-4)),.045)
        for side in (-1,1):
            leaf(s,h,'Satyr long pointed ear',(side*.16,-.01,.06),(side*.40,-.045,.25),.075,'skin')
        hide(h,'Swept horn')
        for side in (-1,1):
            pts=[(side*.15,-.03,.17),(side*.29,-.08,.37),(side*.42,-.17,.32),(side*.42,-.20,.10),(side*.30,-.16,.06)]
            s.horn(h,pts,.073,'horn','Curled ram horn')
    if name=='cyclops':
        s.horn(h,[(-.13,.13,.22),(0,.13,.25),(.13,.13,.22)],.026,'skin','Heavy single orbital brow')
        if jaw:
            for side in (-1,1):s.horn(jaw,[(side*.12,.20,.015),(side*.14,.24,.07),(side*.11,.23,.14)],.035,'teeth','Cyclops lower tusk')
    if name=='bronze':
        for side in (-1,1):
            leaf(s,h,'Talos angular cheek guard',(side*.15,.15,.13),(side*.15,.19,-.20),.087,'metal')
        leaf(s,h,'Talos helmet nasal guard',(0,.19,.23),(0,.23,-.035),.028,'metal')


def refine(s):
    if s.kind=='minotaur':return
    k=s.kind
    for name,rgb in [('goat',(.35,.29,.24)),('cream',(.69,.62,.43)),('auburn',(.32,.105,.06))]:
        s.mats[name]=s.K.material('Monster '+('fur ' if name!='goat' else 'skin ')+name,linear(rgb),rough=.86)
    if k in ('satyr','sphinx','harpies','maenads','scylla'):
        s.mats['fur'].diffuse_color=(*linear((.11,.075,.06) if k!='satyr' else (.32,.10,.055)),1)
    if k=='chimera':s.mats['eyes'].diffuse_color=(*linear((1,.56,.06)),1)
    if k=='echidna':
        s.mats['skin'].diffuse_color=(*linear((.40,.34,.13)),1)
        s.mats['horn'].diffuse_color=(*linear((.08,.16,.20)),1)
    if k=='kraken':s.mats['belly'].diffuse_color=(*linear((.62,.43,.43)),1)
    if k in ('hector','maenads'):s.mats['eyes'].diffuse_color=(*linear((.22,.13,.065)),1)
    for h,jaw,m in list(s.heads):
        if k in ('maenads','harpies','sphinx','scylla') and any(o.type=='MESH' and not o.hide_render for o in h.children_recursive) and h.name.startswith(('human','sphinx')):
            s.ell('Crown hair volume',(0,-.055,.22),(.18,.14,.17),'fur',h)
            for i in range(9):
                x=(i-4)*.039
                leaf(s,h,'Swept crown hair',(x,.015,.31),(x*1.18,-.24,.08),.038)
        refine_head(s,h)
        if k in ('harpies','scylla'):
            for i,ob in enumerate(visible(h,'Flowing hair lock')):
                if i%2:ob.hide_render=True
    for actor,pos,kind in s.actors:
        if kind in ('cyclops','satyr'):
            hide(actor,'Wrapped cloth skirt')
            width=.40 if kind=='cyclops' else .29
            for i in range(11):
                a=math.tau*i/11
                leaf(s,actor,'Ragged hide loincloth',(width*math.cos(a),.205*math.sin(a),1.01),
                     (width*1.08*math.cos(a),.26*math.sin(a),.67+.065*math.cos(i*2)),.085,'cloth')
            band(s,actor,'Hide waist cord',1.015,width,.21,'cloth')
            for side in (-1,1):
                for z in (1.10,1.20,1.30):s.ell('Defined abdominal muscle',(side*.09,.177,z),(.10,.064,.067),'skin',actor)
            if kind=='cyclops':
                s.ell('Cyclops humped trapezius',(0,-.04,1.64),(.40,.23,.23),'skin',actor)
                for ob in visible(actor,'Hand pivot'):ob.scale*=1.5
            else:
                for side in (-1,1):
                    for i in range(9):
                        x=side*(.23+.024*i)
                        leaf(s,actor,'Satyr shoulder fur',(x,-.035,1.62),(x+side*.05,-.15,1.40-.025*i),.045)
        if kind in ('talos','hector'):
            if kind=='talos':
                for ob in actor.children_recursive:
                    if ob.type=='MESH' and ob.active_material==s.mats['skin']:recolor(ob,s.mats['metal'])
            hide(actor,'Wrapped cloth skirt')
            for i in range(14):
                a=math.tau*i/14
                leaf(s,actor,'Armour hanging pteruges',(.30*math.cos(a),.22*math.sin(a),1.00),(.36*math.cos(a),.27*math.sin(a),.63+.035*(i%2)),.061,'metal' if kind=='talos' else 'cloth')
                s.ell('Armour belt rivet',(.31*math.cos(a),.23*math.sin(a),.98),(.018,.018,.018),'metal',actor,1)
            band(s,actor,'Bronze belt edging',1.02,.31,.23)
            for side in (-1,1):
                for z in (1.12,1.23,1.34):s.ell('Cuirass anatomical plate',(side*.10,.24,z),(.105,.04,.072),'metal',actor)
            if kind=='hector':
                shield=next(o for o in actor.children if o.name.startswith('Bronze round shield'))
                for i in range(12):
                    a=math.tau*i/12
                    leaf(s,shield,'Shield sunburst ray',(.09*math.cos(a),.09*math.sin(a),-.05),(.265*math.cos(a),.265*math.sin(a),-.05),.026,'metal')
                band(s,shield,'Shield rim',-.045,.30,.30)
        if kind in ('medusa','maenads'):
            for side in (-1,1):
                # Raised folds follow the existing torso, keeping the original garment coverage.
                for i in range(6):
                    z=.18+i*.12
                    s.horn(actor,[(side*.10,.39,z+.13),(side*.27,.34,z+.04),(side*.39,.15,z)],.013,'cloth','Diagonal drapery fold')
            band(s,actor,'Girdle',1.07,.25,.25,'cloth')
            if kind=='maenads':
                for j in range(12):
                    a=j*2.4;z=1.86+j*.013
                    leaf(s,actor,'Thyrsus cone scale',(.53+.042*math.cos(a),.03+.042*math.sin(a),z),(.53+.077*math.cos(a),.03+.077*math.sin(a),z+.055),.025,'belly')
        if kind=='echidna':
            for i in range(22):
                a=math.tau*i/22
                leaf(s,actor,'Echidna layered cream ruff',(.18*math.cos(a),.10+.12*math.sin(a),1.65),(.36*math.cos(a),.17+.19*math.sin(a),1.21+.15*abs(math.cos(a))),.070,'cream')
        if kind=='sphinx':
            for row in range(3):
                for i in range(9):
                    x=(i-4)*.057
                    leaf(s,actor,'Sphinx cream chest feather',(x,.58,1.28-row*.12),(x*1.1,.64,1.04-row*.12),.058,'cream')
        if kind in ('calydonianboar','cerberus'):
            hide(actor,'Dorsal bristle')
            for row in range(3 if kind=='calydonianboar' else 1):
                for i in range(18):
                    y=-.73+i*.065;x=(row-1)*.09 if kind=='calydonianboar' else 0
                    leaf(s,actor,'Swept dorsal bristle',(x,y,1.28),(x,y-.22,1.53+.12*math.sin(i/18*math.pi)),.038)
    # Replace rod feathers with overlapping closed vanes on the same wing pivots.
    if k in ('harpies','sphinx'):
        for w,side in s.wings:
            hide(w,'Flight feather')
            for row in range(3):
                for j in range(13):
                    u=j/12
                    start=(side*(.13+.85*u),-.11-row*.09,.23-.09*u-row*.055)
                    end=(side*(.30+.97*u),-.64+.27*u-row*.09,-.35+.46*u-row*.09)
                    leaf(s,w,'Layered flight feather',start,end,.053 if row==0 else .044)
    # Legs retain the swept deformation; new fur follows the planted foot pivots.
    for t,foot,top,base,quad in s.legs:
        if k=='satyr':
            recolor(t.ob,s.mats['fur'])
            for j in range(8):
                a=j*math.tau/8
                leaf(s,foot,'Satyr fetlock fur',(.09*math.cos(a),.02+.08*math.sin(a),.23),(.12*math.cos(a),.035+.11*math.sin(a),.015),.040)
        if k in ('talos','hector'):
            if k=='talos':recolor(t.ob,s.mats['metal'])
            leaf(s,foot,'Articulated greave',(0,.24,.54),(0,.26,.12),.085,'metal')
    if k=='chimera':
        # Correct orange forequarters and grey goat, keeping blue-green hindquarters.
        for t,foot,top,base,quad in s.legs:
            if base.y>0:
                recolor(t.ob,s.mats['fur'])
                for ob in foot.children_recursive:
                    if ob.type=='MESH' and ob.active_material==s.mats['skin']:recolor(ob,s.mats['fur'])
    if k=='scylla':
        for t,h,pts,i in s.necks:
            s.decor.append(__import__('godot_hydra').SurfaceDecor(s.K,t,s.mats['skin'],s.mats['cream'],s.mats['horn'],s.root,5,4,spines=True))
    if k=='kraken':
        mantle=s.actors[0][0]
        for i in range(7):
            x=(i-3)*.12
            s.horn(mantle,[(x,.22,.73),(x*1.3,-.07,.96),(x,-.45,.50)],.027,'skin','Kraken mantle ridge')
    if k in ('dragon','echidna','chimera'):
        from godot_hydra import SurfaceDecor
        for t,pts,mode,i in s.tails:
            if mode=='tail':s.decor.append(SurfaceDecor(s.K,t,s.mats['skin'],s.mats['cream'],s.mats['horn'],t.ob.parent,12,6,spines=k=='dragon'))
        if k=='dragon':
            s.mats['belly'].diffuse_color=(*linear((.66,.61,.43)),1)
            for w,side in s.wings:
                for j in range(5):
                    leaf(s,w,'Dragon ivory wing talon',(side*(.43+j*.20),-.08-j*.045,.46-j*.035),(side*(.52+j*.22),-.10-j*.05,.59-j*.035),.03,'teeth')
