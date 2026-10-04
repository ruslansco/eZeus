#!/usr/bin/env python3
"""Bakes walker and animal poses into vertex-animation textures for the game runtime.

Godot stores every morph target as a dense 20-byte-per-vertex buffer and keeps one copy per
walker type, so animated models were most of the video memory. For each source GLB that has
morph targets this tool writes a runtime derivative into godot/assets/models/runtime/:

* <asset>.glb      the same meshes without morph targets, plus TEXCOORD_2 = (column, row):
                   the vertex's texel address, which Godot imports as CUSTOM0 and which
                   survives whatever vertex order the importer picks. UV and UV2 are left
                   untouched, so custom character shaders keep their rest-anatomy coordinates;
* <asset>.vat      every pose of every part as RGBA half-float displacement texels (8 bytes
                   per vertex per pose), parts stacked vertically in one 1024-wide texture;
* <asset>.vat.json the part table (first row, rows per pose, pose count, frame-name ->
                   pose index; merged "a|b|c" names all resolve) and the source file's size
                   and modification time.

The source GLB and manifest are never modified, so validators and review tools keep reading
the authored morph targets. The game uses a derivative only while its recorded source size
and time still match (a fresh re-export falls back to blend shapes until this tool is run
again). The shader displaces the rest vertex by the blend of two poses, which is what the
normalized blend shape did; the morph normals equal the base normals in these files, so
lighting is unchanged. shaders/walker_vat.gdshaderinc holds the lookup so any shader can use it.

    python3 tools/bake_walker_vat.py --dry-run
    python3 tools/bake_walker_vat.py
    godot --headless --path godot --import
    godot --headless --path godot --script res://scripts/validate_poses.gd
"""
import argparse
import json
import struct
import sys
from array import array
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from optimize_glb_memory import (COMPONENT_SIZE, MODELS, TYPE_COMPONENTS, compact,  # noqa: E402
                                 merge_targets, read_glb, write_glb)

WIDTH = 1024
if sys.byteorder != 'little':
    raise SystemExit('little-endian host required')


def decode_floats(doc, binary, index):
    """Dense float values of an accessor, with sparse overrides applied."""
    a = doc['accessors'][index]
    if a['componentType'] != 5126:
        raise ValueError('only float accessors are supported')
    comps = TYPE_COMPONENTS[a['type']]
    esize = 4 * comps
    out = array('f', bytes(4 * comps * a['count']))
    if 'bufferView' in a:
        view = doc['bufferViews'][a['bufferView']]
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = view.get('byteStride') or esize
        if stride == esize:
            out = array('f')
            out.frombytes(binary[start:start + esize * a['count']])
        else:
            for i in range(a['count']):
                chunk = array('f')
                chunk.frombytes(binary[start + i * stride:start + i * stride + esize])
                out[i * comps:(i + 1) * comps] = chunk
    sparse = a.get('sparse')
    if sparse:
        ind, val = sparse['indices'], sparse['values']
        n = sparse['count']
        code = {5121: 'B', 5123: 'H', 5125: 'I'}[ind['componentType']]
        indices = array(code)
        iv = doc['bufferViews'][ind['bufferView']]
        o = iv.get('byteOffset', 0) + ind.get('byteOffset', 0)
        indices.frombytes(binary[o:o + n * COMPONENT_SIZE[ind['componentType']]])
        values = array('f')
        vv = doc['bufferViews'][val['bufferView']]
        o = vv.get('byteOffset', 0) + val.get('byteOffset', 0)
        values.frombytes(binary[o:o + n * esize])
        for k, vertex in enumerate(indices):
            out[vertex * comps:(vertex + 1) * comps] = values[k * comps:(k + 1) * comps]
    return out


def to_texels(deltas):
    """Pack xyz float deltas as RGBA half floats (alpha 0)."""
    count = len(deltas) // 3
    halves = array('H')
    halves.frombytes(struct.pack('<%de' % len(deltas), *deltas))
    texels = array('H', bytes(8 * count))
    texels[0::4] = halves[0::3]
    texels[1::4] = halves[1::3]
    texels[2::4] = halves[2::3]
    return texels, halves


def bake_mesh(doc, binary, mesh):
    primitive = mesh['primitives'][0]
    names = mesh.get('extras', {}).get('targetNames')
    targets = primitive.get('targets', [])
    if len(mesh['primitives']) != 1 or not targets or not names or len(names) != len(targets):
        return None
    if any(set(t) != {'POSITION'} for t in targets):
        raise ValueError(f"{mesh.get('name')}: only POSITION morph targets are supported")
    count = doc['accessors'][primitive['attributes']['POSITION']]['count']
    rows = -(-count // WIDTH)
    blocks, frames, worst = [], {}, 0.0
    for pose, (name, target) in enumerate(zip(names, targets)):
        deltas = decode_floats(doc, binary, target['POSITION'])
        texels, halves = to_texels(deltas)
        decoded = array('f')
        decoded.frombytes(struct.pack('<%df' % len(deltas), *struct.unpack('<%de' % len(deltas), halves.tobytes())))
        worst = max(worst, max((abs(a - b) for a, b in zip(deltas, decoded)), default=0.0))
        padded = bytearray(texels.tobytes()) + bytes(8 * (rows * WIDTH - count))
        blocks.append(bytes(padded))
        for alias in name.split('|'):
            frames[alias] = pose
    return {'primitive': primitive, 'count': count, 'rows': rows, 'blocks': blocks, 'frames': frames, 'error': worst}


def add_texel_address(doc, binary, primitive, count):
    """TEXCOORD_2 = (column, row) of each vertex's texel; Godot imports it as CUSTOM0."""
    address = array('f', [0.0] * (2 * count))
    for i in range(count):
        address[2 * i] = float(i % WIDTH)
        address[2 * i + 1] = float(i // WIDTH)
    binary = binary + b'\0' * (-len(binary) % 4)
    doc['bufferViews'].append({'buffer': 0, 'byteOffset': len(binary), 'byteLength': 8 * count, 'target': 34962})
    doc['accessors'].append({'bufferView': len(doc['bufferViews']) - 1, 'componentType': 5126, 'count': count, 'type': 'VEC2'})
    primitive['attributes']['TEXCOORD_2'] = len(doc['accessors']) - 1
    return binary + address.tobytes()


IMPORT_TEMPLATE = """[remap]

importer="scene"
importer_version=1
type="PackedScene"

[params]

nodes/root_type=""
nodes/root_name=""
nodes/root_script=null
nodes/apply_root_scale=true
nodes/root_scale=1.0
nodes/import_as_skeleton_bones=false
nodes/use_name_suffixes=true
nodes/use_node_type_suffixes=true
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=false
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
meshes/force_disable_compression=false
skins/use_named_skins=true
animation/import=true
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
animation/import_rest_as_RESET=false
import_script/path=""
materials/extract=0
materials/extract_format=0
materials/extract_path=""
_subresources={}
gltf/naming_version=2
gltf/embedded_image_handling=1
"""


def bake(path, out_dir, args):
    document, binary = read_glb(path)
    if not any(p.get('targets') for m in document['meshes'] for p in m['primitives']):
        return None
    stat = path.stat()
    sidecar = out_dir / (path.stem + '.vat.json')
    if sidecar.exists() and not args.force:
        recorded = json.loads(sidecar.read_text()).get('source', {})
        if recorded.get('bytes') == stat.st_size and recorded.get('mtime') == int(stat.st_mtime):
            return None
    merge_targets(document, binary)
    parts, texture, row = {}, bytearray(), 0
    for mesh in document['meshes']:
        result = bake_mesh(document, binary, mesh)
        if result is None:
            continue
        parts[mesh['name']] = {'row': row, 'rows': result['rows'], 'poses': len(result['blocks']),
                               'vertices': result['count'], 'frames': result['frames'], 'max_error': result['error']}
        texture.extend(b''.join(result['blocks']))
        row += result['rows'] * len(result['blocks'])
        binary = add_texel_address(document, binary, result['primitive'], result['count'])
        for primitive in mesh['primitives']:
            primitive.pop('targets', None)
        mesh.get('extras', {}).pop('targetNames', None)
        mesh.pop('weights', None)
    if row > 16384:
        raise ValueError(f'{path.stem}: pose texture needs {row} rows, the limit is 16384')
    binary = compact(document, binary)
    summary = {'name': path.stem, 'source': stat.st_size, 'vat': len(texture), 'parts': len(parts),
               'poses': sum(p['poses'] for p in parts.values()), 'error': max(p['max_error'] for p in parts.values()),
               'rows': row}
    if args.dry_run:
        return summary
    out_dir.mkdir(parents=True, exist_ok=True)
    temporary = out_dir / (path.stem + '.baking.glb')
    write_glb(temporary, document, binary)
    summary['glb'] = temporary.stat().st_size
    temporary.replace(out_dir / (path.stem + '.glb'))
    (out_dir / (path.stem + '.vat')).write_bytes(bytes(texture))
    option = out_dir / (path.stem + '.glb.import')
    if not option.exists():
        option.write_text(IMPORT_TEMPLATE)
    sidecar.write_text(json.dumps({'format': 'RGBAH', 'width': WIDTH, 'height': row, 'parts': parts,
                                   'source': {'file': path.name, 'bytes': stat.st_size, 'mtime': int(stat.st_mtime)}}, indent=1) + '\n')
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--models', type=Path, default=MODELS)
    parser.add_argument('--only', nargs='*')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--force', action='store_true', help='rebake even if the source is unchanged')
    args = parser.parse_args()
    out_dir = args.models / 'runtime'
    names = args.only or sorted(p.stem for p in args.models.glob('*.glb'))
    total = changed = 0
    for name in names:
        summary = bake(args.models / (name + '.glb'), out_dir, args)
        if summary is None:
            continue
        changed += 1
        total += summary['vat']
        print(f"{summary['name']:26s} parts {summary['parts']} poses {summary['poses']:3d}  texture {summary['vat'] / 1048576:5.1f} MB ({summary['rows']} rows)  max half-float error {summary['error']:.6f}")
    print(f"{changed} model(s) {'would be ' if args.dry_run else ''}baked, {total / 1048576:.0f} MB of pose textures")


if __name__ == '__main__':
    sys.exit(main())
