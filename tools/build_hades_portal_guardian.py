"""Original hooded stone sentinel; run only in background factory-startup Blender.

The user's visual reference supplies hood/sword/green-eye motifs, not game meshes.
Outputs a separate editable source and a menu-only GLB; no native art is changed.
"""
from pathlib import Path
from math import sin, cos, pi
import hashlib
import json
import bpy
from mathutils import Vector

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO.parent / 'art/menu/hades-portal'
SOURCE.mkdir(parents=True, exist_ok=True)
OUTPUT = REPO / 'godot/assets/menu/hades_portal_guardian.glb'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def material(name, color, metallic=0.0, emission=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Roughness'].default_value = .88
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Emission Color'].default_value = (*color, 1)
    p.inputs['Emission Strength'].default_value = emission
    return m


stone = material('Guardian weathered limestone', (.32, .29, .21))
bronze = material('Guardian antique bronze', (.29, .20, .085), .55)
dark = material('Hood deep shadow', (.006, .011, .007))
eyes = material('Guardian living green eyes', (.38, 1, .025), emission=2)
objects = []


def mesh(name, vertices, faces, mat=stone, smooth=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(mat)
    for poly in data.polygons:
        poly.use_smooth = smooth
    objects.append(obj)
    return obj


def tube(name, points, radii, mat=stone, segments=12):
    vertices = []
    for i, point in enumerate(points):
        tangent = Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        tangent.normalize()
        right = tangent.cross(Vector((0,1,0)))
        if right.length < .01: right = tangent.cross(Vector((1,0,0)))
        right.normalize()
        up = tangent.cross(right).normalized()
        for j in range(segments):
            a = j*2*pi/segments
            vertices.append(Vector(point)+(right*cos(a)+up*sin(a))*radii[i])
    faces = []
    for i in range(len(points)-1):
        for j in range(segments):
            a=i*segments+j; b=i*segments+(j+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.extend([tuple(reversed(range(segments))),tuple(range((len(points)-1)*segments,len(points)*segments))])
    return mesh(name, vertices, faces, mat)


def robe(name, profile, folds, mat=stone):
    vertices=[]; rings=65; segments=80
    for i in range(rings):
        h=i/(rings-1)*profile[-1][0]
        lower=next(j for j in range(len(profile)-1) if profile[j][0] <= h <= profile[j+1][0])
        a,b=profile[lower:lower+2]; f=(h-a[0])/(b[0]-a[0])
        rx=a[1]*(1-f)+b[1]*f; ry=a[2]*(1-f)+b[2]*f
        for j in range(segments):
            angle=j*2*pi/segments
            pleat=(cos(angle*folds+h*.16)*.065+cos(angle*folds*2-h*.11)*.018)
            pleat*=.7+.3*cos(h*.7)
            vertices.append(((rx+pleat)*sin(angle),(ry+pleat)*cos(angle),h))
    faces=[]
    for i in range(rings-1):
        for j in range(segments):
            a=i*segments+j; b=i*segments+(j+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces.extend([tuple(reversed(range(segments))),tuple(range((rings-1)*segments,rings*segments))])
    return mesh(name,vertices,faces,mat)


# One continuous carved robe: grounded hem, narrowed waist, broad mantle.
robe('Long carved chiton',[(0,1.04,.54),(.25,1.01,.53),(1.8,.82,.45),
    (3.3,.62,.40),(4.1,.82,.44),(4.65,1.02,.42),(4.90,.52,.28)],14)
for side in [-1,1]:
    tube('Folded mantle shoulder',[(side*.30,.05,4.8),(side*.67,-.03,4.68),
        (side*1.0,-.02,4.5),(side*1.1,.04,4.32)],[.26,.34,.32,.16],segments=20)
    tube('Draped upper sleeve',[(side*.88,0,4.50),(side*1.00,-.08,4.20),
        (side*.97,-.20,3.88),(side*.82,-.40,3.62)],[.33,.35,.29,.27],segments=20)
    tube('Bent sleeve to sword',[(side*.82,-.40,3.62),(side*.61,-.63,3.45),
        (side*.40,-.82,3.35),(side*.22,-.94,3.32)],[.27,.24,.20,.15],segments=20)
    # Fine raised folds follow the bent arm instead of floating straight tubes.
    for k in [-1,0,1]:
        tube('Sleeve carved seam',[(side*.97,-.25+k*.075,4.32),
            (side*1.05,-.36+k*.075,3.96),(side*.83,-.64+k*.07,3.65)],
            [.025,.035,.018],segments=8)

# Thick hollow cowl, with a recessed face opening. Front is Blender -Y.
segments=64; rings=9; vertices=[]
for i in range(rings):
    f=i/(rings-1)
    for j in range(segments):
        a=j*2*pi/segments
        z=cos(a)
        inner=Vector((.40*sin(a),-.78,5.58+.58*z))
        outer=Vector((.67*sin(a)*(1-.12*z),-.27,5.58+(.86 if z>0 else .70)*z))
        v=inner.lerp(outer,f)
        v.y-=sin(f*pi)*.14
        vertices.append(v)
faces=[]
for i in range(rings-1):
    for j in range(segments):
        a=i*segments+j;b=i*segments+(j+1)%segments
        faces.append((a,b,b+segments,a+segments))
hood=mesh('Deep hollow pointed cowl',vertices,faces)
back=[]
for depth in range(12):
    f=depth/11
    for j in range(segments):
        a=j*2*pi/segments; z=cos(a)
        back.append((.67*sin(a)*(1-.12*z)*(1-f*.92),-.27+sin(f*pi*.5)*.88,
            5.58+(.86 if z>0 else .70)*z*(1-f*.92)))
faces=[]
for i in range(11):
    for j in range(segments):
        a=i*segments+j;b=i*segments+(j+1)%segments
        faces.append((a,b,b+segments,a+segments))
mesh('Cowl back and crown',back,faces)
shadow=[(0,-.48,5.58)]+[(.40*sin(j*2*pi/segments),-.49,5.58+.58*cos(j*2*pi/segments)) for j in range(segments)]
mesh('Recessed faceless hood shadow',shadow,[(0,j+1,(j+1)%segments+1) for j in range(segments)],dark,False)
for side in [-1,1]:
    x=side*.15; z=5.64
    mesh('Green almond eye',[(x-side*.095,-.57,z+.015),(x,-.58,z+.033),
        (x+side*.075,-.57,z+.009),(x,-.58,z-.023)],[(0,1,2,3)],eyes,False)

# Hands: solid palms, four curved fingers and opposing thumbs around the grip.
for side, height in [(-1,3.52),(1,3.24)]:
    tube('Carved palm',[(side*.19,-.96,height-.12),(side*.19,-.98,height+.12)],
        [.145,.14],segments=16)
    for finger in range(4):
        z=height+.11-finger*.071
        tube('Individual gripping finger',[(side*.24,-1.02,z),(side*.12,-1.11,z),
            (side*.015,-1.14,z-.012),(-side*.045,-1.06,z-.029)],
            [.047,.052,.046,.028],segments=10)
    tube('Opposing thumb',[(side*.31,-.96,height+.055),(side*.22,-1.12,height+.13),
        (side*.08,-1.14,height+.11)],[.065,.062,.039],segments=12)

tube('Sword leather-carved grip',[(0,-1.01,3.03),(0,-1.01,3.75)],[.071,.071],bronze,16)
for z in [3.10,3.22,3.34,3.46,3.58,3.70]:
    tube('Grip ferrule',[(0,-1.01,z),(0,-1.01,z+.018)],[.077,.077],bronze,16)
tube('Bronze sword pommel',[(0,-1.01,3.75),(0,-1.01,3.88)],[.12,.06],bronze,16)
tube('Curved sword guard',[(-.48,-1.01,3.02),(-.28,-1.01,2.96),(0,-1.01,2.98),
    (.28,-1.01,2.96),(.48,-1.01,3.02)],[.04,.065,.07,.065,.04],bronze,12)
mesh('Leaf-shaped underworld sword',[(0,-1.11,.27),(-.16,-1.04,.72),(-.18,-1.04,2.7),
    (-.10,-1.04,2.98),(0,-1.14,2.98),(.10,-1.04,2.98),(.18,-1.04,2.7),(.16,-1.04,.72),
    (0,-.97,2.98),(0,-.97,.72)],[(0,1,2,3,4),(0,4,5,6,7),(0,9,8,3,2,1),
    (0,7,6,5,8,9)],bronze,False)

# Small original Greek brooches and a mantle border.
for side in [-1,1]:
    tube('Mantle bronze border',[(side*.34,-.35,4.86),(side*.61,-.48,4.57),
        (side*.75,-.48,4.30),(side*.62,-.43,4.03)],[.035]*4,bronze,10)
    tube('Circular shoulder brooch',[(side*.64,-.50,4.54),(side*.64,-.55,4.54)],
        [.105,.105],bronze,20)

# Explicit UV pairs, outward normals and material-wise batching for the GLB.
for obj in objects:
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    for name in ['UVMap','UVDetail']:
        uv=obj.data.uv_layers.new(name=name)
        for loop in obj.data.loops:
            p=obj.data.vertices[loop.vertex_index].co
            uv.data[loop.index].uv=(p.x*.25+.5,p.z/6.5)
    obj.select_set(False)

groups=[[o for o in objects if o.data.materials[0]==mat] for mat in [stone,bronze,dark,eyes]]
for mat,group in zip([stone,bronze,dark,eyes],groups):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in group:obj.select_set(True)
    bpy.context.view_layer.objects.active=group[0]
    bpy.ops.object.join()
    group[0].name=mat.name
scene=bpy.context.scene
scene['scope']='Original menu-only hooded sentinel. No reference image pixels or imported game geometry.'
scene['forward']='Blender -Y, Godot +Z; feet at zero, height 6.44'
blend=SOURCE/'hades-portal-guardian-v1.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_format='GLB',export_yup=True,
    export_texcoords=True,export_normals=True,export_materials='EXPORT',export_animations=False)
for obj in scene.objects:
    if obj.type=='MESH':obj.data.calc_loop_triangles()
triangles=sum(len(o.data.loop_triangles) for o in scene.objects if o.type=='MESH')
manifest={'version':1,'asset':OUTPUT.name,'creator':'Original authored geometry by Codex for this project',
    'source':'art/menu/hades-portal/hades-portal-guardian-v1.blend','builder':'tools/build_hades_portal_guardian.py',
    'inspiration':'User-supplied Burning Crusade doorway screenshot: hooded stone guardian, sword, glowing green eyes; original Greek mantle, chiton, brooches and leaf-shaped sword.',
    'source_sha256':hashlib.sha256(blend.read_bytes()).hexdigest(),
    'glb_sha256':hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
    'triangles':triangles,'surfaces':4,'uv_sets':2,'scope':'Menu-only; does not replace native Hades, monsters or older guardian assets',
    'release_status':'Original development sculpture; reference comparison and user visual acceptance remain pending.'}
OUTPUT.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('HADES_PORTAL_GUARDIAN PASS '+json.dumps(manifest))
