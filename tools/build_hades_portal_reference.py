"""Packed editable depth-layer portal reference, built in background Blender.

Never connects to the interactive Blender document. Godot's shaders are the
authoritative animated effect; this separate scene provides an approximate preview.
"""
from pathlib import Path
import hashlib
import json
import bpy

REPO = Path(__file__).resolve().parents[1]
ART = REPO / 'godot/assets/menu'
OUT = REPO.parent / 'art/menu/hades-portal'
OUT.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x,scene.render.resolution_y=1672,941
scene.view_settings.view_transform='Standard'
scene.view_settings.look='None'
scene.world.color=(.01,.02,.02)


def image(name, data=False):
    result=bpy.data.images.load(str(ART/name))
    if data:result.colorspace_settings.name='Non-Color'
    result.pack()
    return result


def material(name):
    result=bpy.data.materials.new(name)
    result.use_nodes=True
    result.surface_render_method='DITHERED'
    result.node_tree.nodes.clear()
    return result


def texture(mat, img):
    result=mat.node_tree.nodes.new('ShaderNodeTexImage')
    result.image=img
    result.extension='CLIP'
    return result


def quad(name, pixels, depth, mat):
    x,y,w,h=pixels
    cx=(x+w/2-836)/100
    cy=(470.5-y-h/2)/100
    data=bpy.data.meshes.new(name)
    data.from_pydata([(cx-w/200,cy-h/200,depth),(cx+w/200,cy-h/200,depth),
        (cx+w/200,cy+h/200,depth),(cx-w/200,cy+h/200,depth)],[],[(0,1,2,3)])
    uv=data.uv_layers.new(name='UVMap')
    for loop,p in zip(uv.data,[(0,0),(1,0),(1,1),(0,1)]):loop.uv=p
    uv2=data.uv_layers.new(name='UVDetail')
    for a,b in zip(uv2.data,uv.data):a.uv=b.uv
    result=bpy.data.objects.new(name,data)
    scene.collection.objects.link(result)
    data.materials.append(mat)
    result['source_image_rect']=pixels
    return result


def math(mat, op, a, b=None):
    node=mat.node_tree.nodes.new('ShaderNodeMath');node.operation=op
    for i,value in enumerate([a,b]):
        if value is None:continue
        if isinstance(value,(float,int)):node.inputs[i].default_value=value
        else:mat.node_tree.links.new(value,node.inputs[i])
    return node.outputs[0]


def emission_output(mat, color, alpha=None):
    nodes=mat.node_tree.nodes;links=mat.node_tree.links
    emission=nodes.new('ShaderNodeEmission')
    if isinstance(color,tuple):emission.inputs['Color'].default_value=color
    else:links.new(color,emission.inputs['Color'])
    result=emission.outputs[0]
    if alpha is not None:
        clear=nodes.new('ShaderNodeBsdfTransparent')
        mix=nodes.new('ShaderNodeMixShader')
        links.new(alpha,mix.inputs[0]);links.new(clear.outputs[0],mix.inputs[1]);links.new(result,mix.inputs[2])
        result=mix.outputs[0]
    output=nodes.new('ShaderNodeOutputMaterial');links.new(result,output.inputs['Surface'])


plate=image('aegean_cinematic_v2.png')
mat=material('Retained Greek scenic plate')
tex=texture(mat,plate)
emission_output(mat,tex.outputs['Color'])
quad('Cinematic backdrop - raster artwork',(0,0,1672,941),0,mat)

mat=material('Animated green aperture - approximate Godot preview')
mask=texture(mat,image('aegean_portal_distance.png',True))
split=mat.node_tree.nodes.new('ShaderNodeSeparateColor')
mat.node_tree.links.new(mask.outputs['Color'],split.inputs[0])
distance=math(mat,'SUBTRACT',math(mat,'ADD',math(mat,'MULTIPLY',split.outputs[0],256/257),
    math(mat,'MULTIPLY',split.outputs[1],1/257)),.5)
alpha=math(mat,'GREATER_THAN',distance,0)
uv=mat.node_tree.nodes.new('ShaderNodeTexCoord')
mapping=mat.node_tree.nodes.new('ShaderNodeMapping')
mat.node_tree.links.new(uv.outputs['UV'],mapping.inputs[0])
for frame,value in [(1,0),(241,4)]:
    mapping.inputs['Location'].default_value[1]=value
    mapping.inputs['Location'].keyframe_insert('default_value',frame=frame,index=1)
noise=mat.node_tree.nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value=12;noise.inputs['Detail'].default_value=4
mat.node_tree.links.new(mapping.outputs[0],noise.inputs[0])
edge=math(mat,'POWER',2.718281828,math(mat,'MULTIPLY',distance,-60))
flow=math(mat,'MULTIPLY',edge,math(mat,'ADD',noise.outputs['Fac'],.3))
ramp=mat.node_tree.nodes.new('ShaderNodeValToRGB')
ramp.color_ramp.elements[0].color=(.015,.10,.12,1)
ramp.color_ramp.elements[1].color=(.45,1.0,.04,1)
mat.node_tree.links.new(flow,ramp.inputs[0])
emission_output(mat,ramp.outputs[0],alpha)
quad('Green portal - registered animated plane',(1194,204,268,468),.02,mat)

mat=material('Detailed painted guardian - generated transparent art')
tex=texture(mat,image('hades_guardian_cutout_v1.png'))
emission_output(mat,tex.outputs['Color'],tex.outputs['Alpha'])
quad('Hooded guardian - detailed depth layer',(1188,294,240,368),.05,mat)

camera_data=bpy.data.cameras.new('Hades reference camera')
camera_data.type='ORTHO';camera_data.ortho_scale=16.72
camera=bpy.data.objects.new('Hades reference camera',camera_data)
scene.collection.objects.link(camera)
camera.location=(0,0,10);scene.camera=camera
scene.frame_start,scene.frame_end=1,240
scene.frame_set(40)
readme=bpy.data.texts.new('README - Hades portal reference')
readme.write('Separate packed depth-layer scene; the photographic backdrop and detailed guardian are raster artwork on registered 3D planes.\n'
    'Godot supplies the authoritative animated flames, depths, green eye/rim light and foreground mist. Blender material is an approximate preview.\n'
    'The editable geometry draft is hades-portal-guardian-v1.blend; it is not loaded in the current menu.\n'
    'Original source artwork, old portal/guardian, native simulation and interactive Blender document are retained.\n')
prompt=bpy.data.texts.new('Guardian generation prompt')
prompt.write((ART/'hades_guardian_cutout_v1.prompt.txt').read_text())
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.shading.type='MATERIAL'
path=OUT/'hades-portal-menu-v1.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(path))
report={'source':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
    'objects':len(scene.objects),'packed_images':len([i for i in bpy.data.images if i.packed_file]),
    'preview':'Approximate Blender effect; authoritative runtime shaders in Godot'}
(OUT/'hades-portal-menu-v1.json').write_text(json.dumps(report,indent=2)+'\n')
print('HADES_PORTAL_REFERENCE PASS '+json.dumps(report))
