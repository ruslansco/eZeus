#!/usr/bin/env python3
"""Derive the menu's carved guardian directly from Hades's new rest geometry.

No Blender source/native monument is overwritten. Bake the exact idle positions,
drop animated targets, retain normal/palette/both UV accessors, then compact.
"""
import hashlib
import json
from array import array
from pathlib import Path
from optimize_glb_memory import read_glb, write_glb, compact
from bake_walker_vat import decode_floats

REPO = Path(__file__).resolve().parents[1]


def main():
    source = REPO/'godot/assets/models/walker_hades.glb'
    out = REPO/'godot/assets/menu/hades_guardian.glb'
    doc, binary = read_glb(source)
    for mesh in doc['meshes']:
        # The export's base carries visible arrival FX. Bake the real idle
        # pose before stripping targets, so the stone has no floating motes.
        names = mesh['extras']['targetNames']
        idle = next(i for i, name in enumerate(names) if 'idle_00' in name.split('|'))
        for primitive in mesh['primitives']:
            index = primitive['attributes']['POSITION']
            base = decode_floats(doc, binary, index)
            delta = decode_floats(doc, binary, primitive['targets'][idle]['POSITION'])
            posed = array('f', (a+b for a, b in zip(base, delta)))
            binary += b'\0'*(-len(binary)%4)
            doc['bufferViews'].append({'buffer':0, 'byteOffset':len(binary),
                                      'byteLength':len(posed)*4, 'target':34962})
            binary += posed.tobytes()
            count = len(posed)//3
            doc['accessors'].append({'bufferView':len(doc['bufferViews'])-1,
                'componentType':5126, 'count':count, 'type':'VEC3',
                'min':[min(posed[axis::3]) for axis in range(3)],
                'max':[max(posed[axis::3]) for axis in range(3)]})
            primitive['attributes']['POSITION'] = len(doc['accessors'])-1
        mesh.pop('weights', None)
        mesh.get('extras', {}).pop('targetNames', None)
        for primitive in mesh['primitives']:
            primitive.pop('targets', None)
    # God stature is already baked into the vertices. Lift to a 6.6-unit
    # monument by scaling root nodes, with the same ground anchor.
    for scene in doc['scenes']:
        for index in scene['nodes']:
            node = doc['nodes'][index]
            if 'matrix' in node:
                for column in range(3):
                    for row in range(3):
                        node['matrix'][column*4+row] *= 1.85
            else:
                node['scale'] = [v*1.85 for v in node.get('scale', [1, 1, 1])]
    binary = compact(doc, binary)
    write_glb(out, doc, binary)
    manifest = json.loads(source.with_suffix('.json').read_text())
    out.with_suffix('.json').write_text(json.dumps({
        'asset': 'hades_guardian', 'source': 'eZeus/tools/make_hades_guardian.py',
        'source_model': 'res://assets/models/walker_hades.glb',
        'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'art_direction': manifest['character']['art_direction'],
        'method': 'same idle_00 geometry, no morph targets, 1.85 root scale; menu stone finish',
        'vertices': manifest['vertices'], 'surfaces': manifest['surfaces'],
        'rights_status': 'needs_evidence', 'bytes': out.stat().st_size}, indent=2)+'\n')
    print('HADES_GUARDIAN', out, out.stat().st_size)


if __name__ == '__main__':
    main()
