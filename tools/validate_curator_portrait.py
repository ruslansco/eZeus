#!/usr/bin/env python3
"""Static GLB/manifest gate for the panel-only curator; no Godot, saves or preferences touched."""
import json
import struct
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
folder = repo / 'build-portraits'   # the render source; the game ships only its image
binary = (folder / 'walker_curator.glb').read_bytes()
manifest = json.loads((folder / 'walker_curator.json').read_text())
magic, version, length = struct.unpack_from('<III', binary)
assert magic == 0x46546c67 and version == 2 and length == len(binary)
chunk_length, chunk_type = struct.unpack_from('<II', binary, 12)
assert chunk_type == 0x4e4f534a
scene = json.loads(binary[20:20+chunk_length])
assert manifest['portrait']['revision'] == 'elder_curator_portrait_v2'
assert manifest['portrait']['finish'] == 'elder_portrait_v2'
assert manifest['portrait']['people'][0]['age'] == 68
assert manifest['rights_status'] == 'needs_evidence'
assert manifest['walk_samples'] == manifest['idle_samples'] == 0
assert not scene.get('animations') and not scene.get('skins')
vertices = 0
for mesh in scene['meshes']:
    for primitive in mesh['primitives']:
        attrs = primitive['attributes']
        assert {'POSITION','NORMAL','TEXCOORD_0','TEXCOORD_1','COLOR_0'} <= attrs.keys()
        assert not primitive.get('targets')
        vertices += scene['accessors'][attrs['POSITION']]['count']
assert 40000 < vertices <= 600000, vertices
assert len(binary) < 40 * 1024 * 1024
assert vertices == manifest['vertices'], (vertices,manifest['vertices'])
print(f'CURATOR_PORTRAIT PASS: {vertices:,} vertices, {len(binary):,} bytes, rest UVs/palette, no animations, panel-only revision')
image = repo / 'godot/assets/portraits/walker_curator.png'
assert image.exists() and image.stat().st_size < 2 * 1024 * 1024, 'render the portrait image: tools/render_portraits.py'
print(f'CURATOR_IMAGE PASS: {image.stat().st_size:,} bytes')
