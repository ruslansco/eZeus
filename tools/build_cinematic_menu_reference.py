"""Build a separate, packed 2.5D Blender reference; never contact/reset the live scene.
Run: Blender -b --factory-startup --python-exit-code 1 -P tools/build_cinematic_menu_reference.py
The photographic plate remains a raster asset; the registered portal is a mesh.
"""
from pathlib import Path
import json
import bpy

REPO = Path(__file__).resolve().parents[1]
OUT = REPO.parent / 'art/menu/cinematic'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x, scene.render.resolution_y = 1672, 941
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1
scene.world.color = (0.005, 0.008, 0.01)

def quad(name, center, width, height, mat):
    mesh = bpy.data.meshes.new(name)
    x, y, z = center
    mesh.from_pydata([(x-width/2,y-height/2,z),(x+width/2,y-height/2,z),
                     (x+width/2,y+height/2,z),(x-width/2,y+height/2,z)], [], [(0,1,2,3)])
    uv = mesh.uv_layers.new(name='UVMap')
    for loop, coord in zip(uv.data, [(0,0),(1,0),(1,1),(0,1)]): loop.uv = coord
    obj = bpy.data.objects.new(name,mesh)
    scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj

image = bpy.data.images.load(str(REPO / 'godot/assets/menu/aegean_cinematic_v2.png'))
image.pack()
plate_mat = bpy.data.materials.new('Cinematic plate - already graded photographic artwork')
plate_mat.use_nodes = True
nodes = plate_mat.node_tree.nodes
nodes.clear()
links = plate_mat.node_tree.links
tex = nodes.new('ShaderNodeTexImage'); tex.image = image
emit = nodes.new('ShaderNodeEmission'); emit.inputs['Strength'].default_value = 1
out = nodes.new('ShaderNodeOutputMaterial')
links.new(tex.outputs['Color'],emit.inputs['Color'])
links.new(emit.outputs[0],out.inputs['Surface'])
quad('Aegean cinematic plate - raster backdrop', (0,0,0),16.72,9.41,plate_mat)

portal_mat = bpy.data.materials.new('Living portal - editable procedural preview')
portal_mat.use_nodes = True
portal_mat.surface_render_method = 'DITHERED'
nodes = portal_mat.node_tree.nodes; nodes.clear()
links = portal_mat.node_tree.links
uv = nodes.new('ShaderNodeTexCoord')
sep = nodes.new('ShaderNodeSeparateXYZ'); links.new(uv.outputs['UV'],sep.inputs[0])

def math_node(op, a, b=None):
    node = nodes.new('ShaderNodeMath'); node.operation=op
    for i,value in enumerate([a,b]):
        if value is None: continue
        if isinstance(value,(int,float)): node.inputs[i].default_value=value
        else: links.new(value,node.inputs[i])
    return node.outputs[0]

x = math_node('SUBTRACT',math_node('MULTIPLY',sep.outputs['X'],9.2),4.6)
y = math_node('MULTIPLY',sep.outputs['Y'],16.2)
stem = math_node('MINIMUM',math_node('SUBTRACT',4.6,math_node('ABSOLUTE',x)),y)
dist = math_node('SQRT',math_node('ADD',math_node('MULTIPLY',x,x),
    math_node('POWER',math_node('SUBTRACT',y,11.6),2)))
arch = math_node('SUBTRACT',4.6,dist)
curved = math_node('GREATER_THAN',y,11.6)
edge = math_node('ADD',math_node('MULTIPLY',arch,curved),
    math_node('MULTIPLY',stem,math_node('SUBTRACT',1,curved)))
mask = math_node('GREATER_THAN',edge,0)
fire = math_node('POWER',2.7182818,math_node('MULTIPLY',edge,-4))
noise = nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value=3
noise.inputs['Detail'].default_value=3
mapping = nodes.new('ShaderNodeMapping')
links.new(uv.outputs['UV'],mapping.inputs['Vector'])
links.new(mapping.outputs[0],noise.inputs['Vector'])
for frame,value in [(1,0.0),(240,2.0)]:
    mapping.inputs['Location'].default_value[1]=value
    mapping.inputs['Location'].keyframe_insert('default_value',frame=frame,index=1)
color_ramp = nodes.new('ShaderNodeValToRGB')
color_ramp.color_ramp.elements.remove(color_ramp.color_ramp.elements[1])
for i,(pos,color) in enumerate([(0,(.003,.010,.012,1)),(.05,(.12,.018,.003,1)),
                              (.3,(1,.14,.012,1)),(1,(1,.68,.12,1))]):
    element = color_ramp.color_ramp.elements[0] if i==0 else color_ramp.color_ramp.elements.new(pos)
    element.position=pos; element.color=color
links.new(math_node('MULTIPLY',fire,math_node('ADD',.65,noise.outputs['Fac'])),color_ramp.inputs[0])
emit = nodes.new('ShaderNodeEmission'); emit.inputs['Strength'].default_value=1.7
links.new(color_ramp.outputs['Color'],emit.inputs['Color'])
transparent = nodes.new('ShaderNodeBsdfTransparent')
mix = nodes.new('ShaderNodeMixShader')
links.new(mask,mix.inputs[0]); links.new(transparent.outputs[0],mix.inputs[1]); links.new(emit.outputs[0],mix.inputs[2])
out = nodes.new('ShaderNodeOutputMaterial'); links.new(mix.outputs[0],out.inputs['Surface'])
portal = quad('Registered live portal - arch aperture', (4.925,.305,.02),2.53,4.62,portal_mat)
portal['artwork_aperture_pixels']=[1202,209,253,462]
portal['runtime_shader']='eZeus/godot/shaders/login_portal.gdshader'

camera_data = bpy.data.cameras.new('Cinematic reference camera')
camera_data.type='ORTHO'; camera_data.ortho_scale=16.72
camera = bpy.data.objects.new('Cinematic reference camera',camera_data)
scene.collection.objects.link(camera)
camera.location=(0,0,10); scene.camera=camera
scene.frame_start, scene.frame_end=1,240
scene.frame_set(48)
text = bpy.data.texts.new('README - cinematic menu reference')
text.write('Separate packed 2.5D reference. Scenic people, city and mountains are photographic artwork, not editable individual meshes.\n'
           'The portal mesh/material is editable and registered to the artwork. Godot supplies the retained exact portal shader and the accessible 3D menu housings.\n'
           'Regenerate scenic artwork using the saved image-generation prompt in godot/assets/menu/aegean_cinematic_v2.prompt.txt.\n')
text = bpy.data.texts.new('Image generation prompt')
text.write((REPO / 'godot/assets/menu/aegean_cinematic_v2.prompt.txt').read_text())
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.shading.type='MATERIAL'
scene['scope']='Presentation-only reference; no native model/map or live Blender edits.'
path=OUT / 'aegean-cinematic-v2.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(path))
print('CINEMATIC_REFERENCE PASS '+json.dumps({'path':str(path),'objects':len(scene.objects),'packed_images':len([i for i in bpy.data.images if i.packed_file])}))
