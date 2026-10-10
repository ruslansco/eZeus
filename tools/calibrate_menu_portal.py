#!/usr/bin/env python3
"""Derive the scenic doorway distance mask without changing the source artwork."""
from collections import deque
import hashlib
import json
from math import sqrt
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
ART = REPO / 'godot/assets/menu'
SOURCE = ART / 'aegean_cinematic_v2.png'
OUTPUT = ART / 'aegean_portal_distance.png'
# Source-image pixels, with padding around every edge of the opening.
BOUNDS = (1194, 204, 268, 468)
DISTANCE_RANGE = 256.0


def distances(seeds, width, height):
    """Two-pass octile distance in source pixels; no runtime image processing."""
    values = [0.0 if seed else 10000.0 for seed in seeds]
    diagonal = sqrt(2.0)
    for ys, xs, direction in [(range(height), range(width), 1),
                              (range(height-1, -1, -1), range(width-1, -1, -1), -1)]:
        for y in ys:
            for x in xs:
                i = y*width+x
                if 0 <= x-direction < width:
                    values[i] = min(values[i], values[i-direction]+1.0)
                previous_y = y-direction
                if 0 <= previous_y < height:
                    values[i] = min(values[i], values[previous_y*width+x]+1.0)
                    for dx in [-1, 1]:
                        if 0 <= x+dx < width:
                            values[i] = min(values[i], values[previous_y*width+x+dx]+diagonal)
    return values


def main():
    provenance_path = ART / 'aegean_cinematic_v2.provenance.json'
    provenance = json.loads(provenance_path.read_text())
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == provenance['sha256']
    source = Image.open(SOURCE).convert('RGB')
    left, top, width, height = BOUNDS
    pixels = source.crop((left, top, left+width, top+height))
    pixels_access = pixels.load()
    dark = [max(pixels_access[x, y]) < 28 for y in range(height) for x in range(width)]
    # Only the connected empty doorway, excluding dark marks in the masonry.
    seed = (440-top)*width+(1330-left)
    assert dark[seed]
    mask = [False]*len(dark)
    pending = deque([seed])
    mask[seed] = True
    while pending:
        i = pending.popleft()
        x, y = i % width, i // width
        for nx, ny in [(x-1, y), (x+1, y), (x, y-1), (x, y+1)]:
            if 0 <= nx < width and 0 <= ny < height:
                j = ny*width+nx
                if dark[j] and not mask[j]:
                    mask[j] = True
                    pending.append(j)
    assert sum(mask) > 100000 and not any(mask[:width]) and not any(mask[-width:])
    assert not any(mask[y*width] or mask[(y+1)*width-1] for y in range(height))
    inside = distances([not value for value in mask], width, height)
    outside = distances(mask, width, height)
    encoded = []
    for i, is_inside in enumerate(mask):
        distance = inside[i]-.5 if is_inside else .5-outside[i]
        value = round(max(0.0, min(1.0, .5+distance/DISTANCE_RANGE))*65535)
        # Two linear-data channels preserve subpixel distances in an ordinary PNG.
        encoded.append((value >> 8, value & 255, 0))
    result = Image.new('RGB', (width, height))
    result.putdata(encoded)
    result.save(OUTPUT)
    provenance['portal_registration'].update({
        'opening_pixels': list(BOUNDS),
        'distance_mask': OUTPUT.name,
        'distance_mask_sha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        'distance_range_pixels': DISTANCE_RANGE,
        'derivation': 'tools/calibrate_menu_portal.py: connected dark opening, threshold 28/255, signed octile distance; original artwork unchanged.',
        'policy': 'Shared cover crop/drift; source-image distance mask follows the perspective arch, projecting jambs and sloping threshold.',
        'calibrated': '2026-10-10',
    })
    provenance_path.write_text(json.dumps(provenance, indent=2)+'\n')
    print(f'Portal mask: {width}x{height}, {sum(mask)} opening pixels; source hash retained.')


if __name__ == '__main__':
    main()
