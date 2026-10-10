#!/usr/bin/env python3
"""Generate/check metadata for the installed native adventure pictures; never copy or modify artwork."""
import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUTPUT = REPO / 'godot/data/adventure_art.json'
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
header = (REPO / 'esplitbinary.h').read_text()
entries = []
for bitmap in range(18):
    if bitmap < 4:
        shared = f'Zeus_Data_Images/Zeus_Load{bitmap + 1}.jpg'
    elif bitmap < 12:
        shared = f'Zeus_Data_Images/Poseidon_Load{bitmap - 3}.jpg'
    else:
        shared = ''
    loose = '60/' + (shared or f'poseidonCampaign{bitmap - 11}_1.png')
    match = re.search(r'\{"' + re.escape(loose) + r'", eBinaryData\{eFileId::i, (\d+), (\d+)\}\}', header)
    assert match, loose
    if bitmap >= 12:
        sprite = (REPO / f'spriteData/poseidonCampaign{bitmap - 11}60.h').read_text()
        assert 'eSpriteData{1, 0, 0, 800, 600}' in sprite, loose
    entries.append({'bitmap': bitmap, 'loose': loose, 'shared': shared,
                    'offset': int(match[1]), 'length': int(match[2]),
                    'format': 'jpg' if bitmap < 12 else 'png',
                    'crop': [0, 0, 800, 600] if bitmap >= 12 else []})
if args.check:
    assert json.loads(OUTPUT.read_text())['entries'] == entries, 'Regenerate stale artwork metadata'
    print('ADVENTURE_ART_METADATA PASS 18 native mappings and crop bounds')
else:
    OUTPUT.write_text(json.dumps({'source': 'Native eBitmapWidget bitmap IDs / esplitbinary.h 60-pixel UI artwork. Installed development art; no copied Anno imagery.', 'entries': entries}, indent=2) + '\n')
    print('Wrote native campaign artwork metadata; source images unchanged.')
