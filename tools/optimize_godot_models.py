"""Batch compatible PBR surfaces with vertex colours; retain geometry and morph poses.
Run in background Blender with -- --all, or --asset NAME. Development GLBs only.
"""
import argparse,json,math,sys
from pathlib import Path
import bpy
OUT=Path(__file__).resolve().parents[1]/'godot/assets/models'

def batch_materials(objects):
    buckets={}; groups={}
    for ob in objects:
        mesh=ob.data
        palette=mesh.color_attributes.get('CityPalette') or mesh.color_attributes.new(name='CityPalette',type='FLOAT_COLOR',domain='CORNER')
        keys=[];colours=[]
        for material in mesh.materials:
            p=next((n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if material and material.use_nodes else None
            colour=tuple(p.inputs['Base Color'].default_value) if p else tuple(material.diffuse_color)
            rough=float(p.inputs['Roughness'].default_value) if p else .75
            metal=float(p.inputs['Metallic'].default_value) if p else 0
            # Similar finishes share a draw; authored colours remain per vertex.
            key=(rough>.6,metal>.5)
            if 'building_activity' in ob:
                key += (bool(ob['building_activity']),)
            if key not in buckets:
                m=bpy.data.materials.new('City palette '+str(key));m.use_nodes=True
                shader=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
                shader.inputs['Base Color'].default_value=(1,1,1,1)
                shader.inputs['Roughness'].default_value=.85 if key[0] else .4
                shader.inputs['Metallic'].default_value=.8 if key[1] else 0
                vertex=m.node_tree.nodes.new('ShaderNodeVertexColor');vertex.layer_name='CityPalette'
                m.node_tree.links.new(vertex.outputs['Color'],shader.inputs['Base Color'])
                buckets[key]=m
            keys.append(key);colours.append(colour)
        if not ob.get('preserve_city_palette',False):
            for face in mesh.polygons:
                colour=colours[face.material_index]
                for loop in face.loop_indices:palette.data[loop].color=colour
        # Exported source meshes each have one material; split imported multi-slot ones safely.
        if len(set(keys))>1:
            raise RuntimeError('Expected source material groups, found mixed PBR finishes '+ob.name)
        key=keys[0];mesh.materials.clear();mesh.materials.append(buckets[key]);groups.setdefault(key,[]).append(ob)
        for face in mesh.polygons:face.material_index=0
    merged=[]
    for members in groups.values():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in members:ob.select_set(True)
        bpy.context.view_layer.objects.active=members[0]
        if len(members)>1:bpy.ops.object.join()
        merged.append(bpy.context.view_layer.objects.active)
    return merged

def optimize(name):
    path=OUT/(name+'.glb');report_path=path.with_suffix('.json');report=json.loads(report_path.read_text())
    if report.get('draw_batching')=='vertex_palette_compatible_PBR':return
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    before=len(objects);merged=batch_materials(objects)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in merged:ob.select_set(True)
    temporary=path.with_name(name+'.optimized.glb')
    bpy.ops.export_scene.gltf(filepath=str(temporary),export_format='GLB',use_selection=True,export_animations=False,export_morph=True,export_morph_normal=False,export_cameras=False,export_lights=False,export_yup=True)
    temporary.replace(path)
    report.update(bytes=path.stat().st_size,surfaces=len(merged),source_surfaces=before,draw_batching='vertex_palette_compatible_PBR',material_mode='preview_vertex_colours_with_grouped_PBR_finishes_not_full_procedural_bake')
    report_path.write_text(json.dumps(report,indent=2)+'\n')
    print('CITY_BATCH',name,before,'->',len(merged),flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--all',action='store_true');p.add_argument('--asset');a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    jobs=sorted(p.stem for p in OUT.glob('*.json')) if a.all else [a.asset]
    for name in jobs:optimize(name)
