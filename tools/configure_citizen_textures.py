#!/usr/bin/env python3
"""Sets the import mode of the textures Godot extracts from a citizen GLB (standard library only).

Godot extracts embedded glTF images next to the model and imports them lossless by default,
which costs about 56 MB of video memory for one person. This switches them to VRAM
compression (normal maps with the normal-map flag) and keeps mipmaps. Run it after the first
import of a character folder, then import again. When the manifest specifies bone_sample_hz,
keep that skeletal import rate too, so contact curves are not coarsened:

    godot --headless --path godot --import
    python3 tools/configure_citizen_textures.py godot/assets/characters/physician_v2
    godot --headless --path godot --import
"""
import sys
import json
from pathlib import Path


def configure(folder):
    changed = 0
    manifest = folder / 'manifest.json'
    if manifest.exists():
        contract = json.loads(manifest.read_text())
        hz = contract.get('animation', {}).get('bone_sample_hz')
        rig_import = folder / (contract.get('file', '') + '.import')
        if hz and rig_import.exists():
            lines = rig_import.read_text().split('\n')
            for i, line in enumerate(lines):
                if line.startswith('animation/fps=') and line != f'animation/fps={hz}':
                    lines[i] = f'animation/fps={hz}'
                    changed += 1
            rig_import.write_text('\n'.join(lines))
    for path in sorted(folder.glob('*.png.import')):
        text = path.read_text()
        wanted = {'compress/mode': '2', 'compress/normal_map': '1' if 'normal' in path.name else '0', 'mipmaps/generate': 'true'}
        lines = text.split('\n')
        for i, line in enumerate(lines):
            key = line.split('=')[0]
            if key in wanted and line != f'{key}={wanted[key]}':
                lines[i] = f'{key}={wanted[key]}'
                changed += 1
        path.write_text('\n'.join(lines))
    return changed


if __name__ == '__main__':
    folder = Path(sys.argv[1])
    print(f'{configure(folder)} import setting(s) changed in {folder}')
