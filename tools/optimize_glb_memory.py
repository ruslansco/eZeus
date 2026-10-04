#!/usr/bin/env python3
"""Lossless memory diet for the development GLBs (standard library only).

Godot expands every morph target to a dense per-vertex buffer, so a walker with 35 poses
costs about 16 MB of video memory for 0.5 MB of geometry. This tool rewrites a GLB so the
same frames cost less:

* identical morph targets of a mesh are merged. The kept target's name lists every frame
  it stands for ("idle_00|idle_01|..."), so a frame name still resolves to exact data
  (held idle poses are 12 identical targets; main.gd resolves the aliases);
* unreferenced accessors and buffer views (the merged targets) are removed from the file;
* with --drop-uv, TEXCOORD attributes are removed from untextured primitives. This is OFF
  by default: it saves about 38 MB but changes how Godot's LOD generator simplifies thin
  geometry, and at the 3-pixel LOD threshold it stripped the foliage from cypresses and
  pergolas. Do not enable it without comparing rendered views.

Nothing else changes: positions, normals, colours, indices and every distinct pose are
byte-identical; tools/verify_glb_optimization.py proves it against the backups. Re-running
is a no-op, and a fresh Blender export (tools/export_godot_pilot.py) can simply be
optimized again.

    python3 tools/optimize_glb_memory.py --dry-run
    python3 tools/optimize_glb_memory.py --backup-dir /path/to/backup
    godot --headless --path godot --import        # re-import the changed files
    python3 tools/verify_glb_optimization.py /path/to/backup
"""
import argparse
import hashlib
import json
import shutil
import struct
import sys
from pathlib import Path

JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942
COMPONENT_SIZE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
TYPE_COMPONENTS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT2': 4, 'MAT3': 9, 'MAT4': 16}
TEXTURE_KEYS = ('baseColorTexture', 'metallicRoughnessTexture', 'normalTexture', 'occlusionTexture', 'emissiveTexture')
MODELS = Path(__file__).resolve().parents[1] / 'godot/assets/models'


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack('<4sII', data[:12])
    if magic != b'glTF' or version != 2 or length != len(data):
        raise ValueError(f'{path.name}: not a valid GLB 2.0 file')
    offset, document, binary = 12, None, b''
    while offset < length:
        size, kind = struct.unpack('<II', data[offset:offset + 8])
        chunk = data[offset + 8:offset + 8 + size]
        if kind == JSON_CHUNK:
            document = json.loads(chunk)
        elif kind == BIN_CHUNK:
            binary = chunk
        offset += 8 + size
    return document, binary


def write_glb(path, document, binary):
    text = json.dumps(document, separators=(',', ':')).encode()
    text += b' ' * (-len(text) % 4)
    binary = binary + b'\0' * (-len(binary) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    blob = struct.pack('<4sII', b'glTF', 2, total)
    blob += struct.pack('<II', len(text), JSON_CHUNK) + text
    blob += struct.pack('<II', len(binary), BIN_CHUNK) + binary
    path.write_bytes(blob)


def view_bytes(doc, binary, index, extra_offset, length):
    view = doc['bufferViews'][index]
    start = view.get('byteOffset', 0) + extra_offset
    return binary[start:start + length]


def accessor_signature(doc, binary, index):
    """Hash of everything that defines an accessor's decoded content."""
    a = doc['accessors'][index]
    esize = COMPONENT_SIZE[a['componentType']] * TYPE_COMPONENTS[a['type']]
    h = hashlib.sha1()
    h.update(repr((a['componentType'], a['type'], a['count'], a.get('normalized', False), 'bufferView' in a)).encode())
    if 'bufferView' in a:
        view = doc['bufferViews'][a['bufferView']]
        stride = view.get('byteStride') or esize
        start = a.get('byteOffset', 0)
        if stride == esize:
            h.update(view_bytes(doc, binary, a['bufferView'], start, esize * a['count']))
        else:
            for i in range(a['count']):
                h.update(view_bytes(doc, binary, a['bufferView'], start + i * stride, esize))
    sparse = a.get('sparse')
    if sparse:
        ind, val = sparse['indices'], sparse['values']
        h.update(repr((sparse['count'], ind['componentType'])).encode())
        h.update(view_bytes(doc, binary, ind['bufferView'], ind.get('byteOffset', 0), sparse['count'] * COMPONENT_SIZE[ind['componentType']]))
        h.update(view_bytes(doc, binary, val['bufferView'], val.get('byteOffset', 0), sparse['count'] * esize))
    return h.hexdigest()


def merge_targets(doc, binary):
    """Merge identical morph targets per mesh. Returns (before, after) target counts."""
    before = after = 0
    for mesh in doc.get('meshes', []):
        primitives = mesh['primitives']
        count = len(primitives[0].get('targets', []))
        if not count or any(len(p.get('targets', [])) != count for p in primitives):
            continue
        names = mesh.get('extras', {}).get('targetNames')
        if not names or len(names) != count:
            before += count
            after += count
            continue
        keys = []
        for i in range(count):
            keys.append(tuple(tuple(sorted((name, accessor_signature(doc, binary, acc)) for name, acc in p['targets'][i].items())) for p in primitives))
        groups, order = {}, []
        for i, key in enumerate(keys):
            if key not in groups:
                groups[key] = []
                order.append(key)
            groups[key].append(i)
        keep = [groups[key][0] for key in order]
        for p in primitives:
            p['targets'] = [p['targets'][i] for i in keep]
        mesh['extras']['targetNames'] = ['|'.join(names[i] for i in groups[key]) for key in order]
        if 'weights' in mesh:
            mesh['weights'] = [0.0] * len(keep)
        before += count
        after += len(keep)
    return before, after


def drop_unused_texcoords(doc):
    removed = 0
    materials = doc.get('materials', [])
    for mesh in doc.get('meshes', []):
        for p in mesh['primitives']:
            material = materials[p['material']] if 'material' in p else {}
            textured = any(k in material for k in TEXTURE_KEYS) or any(k in material.get('pbrMetallicRoughness', {}) for k in TEXTURE_KEYS)
            if textured:
                continue
            for key in [k for k in p['attributes'] if k.startswith('TEXCOORD_')]:
                del p['attributes'][key]
                removed += 1
    return removed


def compact(doc, binary):
    """Drop unreferenced accessors and buffer views; returns the new binary chunk."""
    used = set()
    for mesh in doc.get('meshes', []):
        for p in mesh['primitives']:
            used.update(p['attributes'].values())
            if 'indices' in p:
                used.add(p['indices'])
            for target in p.get('targets', []):
                used.update(target.values())
    for skin in doc.get('skins', []):
        if 'inverseBindMatrices' in skin:
            used.add(skin['inverseBindMatrices'])
    for animation in doc.get('animations', []):
        for sampler in animation['samplers']:
            used.update((sampler['input'], sampler['output']))
    accessor_map = {old: new for new, old in enumerate(sorted(used))}
    accessors = [doc['accessors'][old] for old in sorted(used)]
    views = set()
    for a in accessors:
        if 'bufferView' in a:
            views.add(a['bufferView'])
        if 'sparse' in a:
            views.add(a['sparse']['indices']['bufferView'])
            views.add(a['sparse']['values']['bufferView'])
    for image in doc.get('images', []):
        if 'bufferView' in image:
            views.add(image['bufferView'])
    view_map = {old: new for new, old in enumerate(sorted(views))}
    new_binary, new_views = bytearray(), []
    for old in sorted(views):
        view = dict(doc['bufferViews'][old])
        new_binary.extend(b'\0' * (-len(new_binary) % 4))
        start = view.get('byteOffset', 0)
        view['byteOffset'] = len(new_binary)
        new_binary.extend(binary[start:start + view['byteLength']])
        new_views.append(view)
    for a in accessors:
        if 'bufferView' in a:
            a['bufferView'] = view_map[a['bufferView']]
        if 'sparse' in a:
            a['sparse']['indices']['bufferView'] = view_map[a['sparse']['indices']['bufferView']]
            a['sparse']['values']['bufferView'] = view_map[a['sparse']['values']['bufferView']]
    for image in doc.get('images', []):
        if 'bufferView' in image:
            image['bufferView'] = view_map[image['bufferView']]
    for mesh in doc.get('meshes', []):
        for p in mesh['primitives']:
            p['attributes'] = {k: accessor_map[v] for k, v in p['attributes'].items()}
            if 'indices' in p:
                p['indices'] = accessor_map[p['indices']]
            p['targets'] = [{k: accessor_map[v] for k, v in t.items()} for t in p.get('targets', [])] or p.get('targets', [])
            if not p.get('targets'):
                p.pop('targets', None)
    for skin in doc.get('skins', []):
        if 'inverseBindMatrices' in skin:
            skin['inverseBindMatrices'] = accessor_map[skin['inverseBindMatrices']]
    for animation in doc.get('animations', []):
        for sampler in animation['samplers']:
            sampler['input'], sampler['output'] = accessor_map[sampler['input']], accessor_map[sampler['output']]
    doc['accessors'], doc['bufferViews'] = accessors, new_views
    doc['buffers'] = [{'byteLength': len(new_binary)}]
    return bytes(new_binary)


def optimize(path, args):
    manifest = path.with_suffix('.json')
    if args.drop_uv and manifest.exists() and json.loads(manifest.read_text()).get('character'):
        raise ValueError(f'{path.name}: character shader requires both rest and surface UV sets')
    document, binary = read_glb(path)
    if document.get('asset', {}).get('extras', {}).get('memory_optimized'):
        return None
    unsupported = {'KHR_draco_mesh_compression', 'EXT_meshopt_compression', 'KHR_mesh_quantization'} & set(document.get('extensionsUsed', []))
    if unsupported:
        raise ValueError(f'{path.name}: unsupported extension {sorted(unsupported)}')
    size_before = path.stat().st_size
    targets_before, targets_after = merge_targets(document, binary)
    removed_uv = drop_unused_texcoords(document) if args.drop_uv else 0
    binary = compact(document, binary)
    document.setdefault('asset', {}).setdefault('extras', {})['memory_optimized'] = {
        'version': 1, 'targets_before': targets_before, 'targets_after': targets_after, 'uv_attributes_removed': removed_uv}
    summary = {'name': path.stem, 'bytes_before': size_before, 'targets_before': targets_before,
               'targets_after': targets_after, 'uv_removed': removed_uv}
    if args.dry_run:
        summary['bytes_after'] = 12 + 8 + len(json.dumps(document, separators=(',', ':'))) + 8 + len(binary)
        return summary
    if args.backup_dir:
        args.backup_dir.mkdir(parents=True, exist_ok=True)
        for suffix in ('.glb', '.glb.import', '.json'):
            source = path.with_name(path.stem + suffix)
            if source.exists() and not (args.backup_dir / source.name).exists():
                shutil.copy2(source, args.backup_dir / source.name)
    temporary = path.with_name(path.stem + '.optimizing.glb')
    write_glb(temporary, document, binary)
    temporary.replace(path)
    summary['bytes_after'] = path.stat().st_size
    manifest = path.with_suffix('.json')
    if manifest.exists():
        record = json.loads(manifest.read_text())
        record['bytes'] = summary['bytes_after']
        record['memory_optimization'] = document['asset']['extras']['memory_optimized']
        manifest.write_text(json.dumps(record, indent=2) + '\n')
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--models', type=Path, default=MODELS)
    parser.add_argument('--only', nargs='*', help='asset names (without .glb)')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--backup-dir', type=Path, help='copy each original .glb/.glb.import/.json here first')
    parser.add_argument('--drop-uv', action='store_true', help='remove unused TEXCOORD attributes (changes LODs; see the docstring)')
    args = parser.parse_args()
    names = args.only or sorted(p.stem for p in args.models.glob('*.glb'))
    total_before = total_after = changed = 0
    for name in names:
        path = args.models / (name + '.glb')
        summary = optimize(path, args)
        if summary is None:
            continue
        changed += 1
        total_before += summary['bytes_before']
        total_after += summary['bytes_after']
        print(f"{summary['name']:28s} {summary['bytes_before'] / 1048576:7.1f} -> {summary['bytes_after'] / 1048576:7.1f} MB  "
              f"targets {summary['targets_before']:3d} -> {summary['targets_after']:3d}  uv attributes removed {summary['uv_removed']}")
    print(f"{changed} file(s) {'would change' if args.dry_run else 'rewritten'}: {total_before / 1048576:.0f} -> {total_after / 1048576:.0f} MB on disk")


if __name__ == '__main__':
    sys.exit(main())
