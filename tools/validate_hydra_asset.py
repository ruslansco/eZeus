#!/usr/bin/env python3
"""Measure the Hydra's complete pose envelope, scale and contact probes from GLB.

Uses decoded geometry, not bounds that include held props or hidden animations.
Human/god comparisons retain skin, hair, cloth and sandals through semantic UV2.
"""
import argparse
import json
import math
from pathlib import Path
from bake_walker_vat import decode_floats
from optimize_glb_memory import MODELS, read_glb

parser = argparse.ArgumentParser()
parser.add_argument('--models', type=Path, default=MODELS)
parser.add_argument('--output', type=Path, default=MODELS.parents[1] / 'captures/hydra-asset-validation.json')
args = parser.parse_args()
checks = []


def check(value, description):
    checks.append({'okay': bool(value), 'description': description})
    print('HYDRA_ASSET_CHECK', 'PASS' if value else 'FAIL', description)


def parts(path):
    doc, binary = read_glb(path)
    result = []
    for mesh in doc['meshes']:
        aliases = {name: i for i, joined in enumerate(mesh.get('extras', {}).get('targetNames', []))
                   for name in joined.split('|')}
        for primitive in mesh['primitives']:
            at = primitive['attributes']
            base = decode_floats(doc, binary, at['POSITION'])
            result.append((doc, binary, primitive, aliases, base))
    return result


def posed_heights(part, label):
    doc, binary, primitive, aliases, base = part
    heights = base[1::3]
    if label in aliases:
        target = primitive['targets'][aliases[label]]
        delta = decode_floats(doc, binary, target['POSITION'])[1::3]
        heights = [a + b for a, b in zip(heights, delta)]
    return heights


def body_bounds(asset, scale=1):
    selected = []
    for part in parts(MODELS / (asset + '.glb')):
        doc, binary, primitive, aliases, base = part
        kinds = decode_floats(doc, binary, primitive['attributes']['TEXCOORD_1'])[::2]
        heights = posed_heights(part, 'idle_00')
        selected.extend(h * scale for h, k in zip(heights, kinds) if round(k * 8) in [0, 1, 2, 3, 8])
    return min(selected), max(selected)


contract = json.loads((args.models / 'walker_hydra.json').read_text())
monster = contract['monster']
geometry = parts(args.models / 'walker_hydra.glb')
check(monster['revision'] == 'hydra_reference_v1' and monster['heads'] == 3 and monster['legs'] == 4 and monster['tails'] == 1,
      'three heads, four legs, one tail use the approved reference adapter')
check(contract['vertices'] <= monster['vertex_budget'], 'authored vertex allocation stays below 24,000')
vertices = sum(len(p[4]) // 3 for p in geometry)
triangles = sum(p[0]['accessors'][p[2]['indices']]['count'] // 3 for p in geometry)
check(vertices <= monster['imported_vertex_budget'] and triangles <= monster['triangle_budget'],
      'exported vertices and triangles stay below the explicit 32,000/30,000 allocations')
check(len(geometry) == 2, 'two grouped PBR surfaces')
kinds = set()
clips = {'walk': 24, 'idle': 12, 'fight': 24, 'fight2': 24, 'die': 30}
for part in geometry:
    doc, binary, primitive, aliases, base = part
    attributes = primitive['attributes']
    check(all(a in attributes for a in ['NORMAL', 'COLOR_0', 'TEXCOORD_0', 'TEXCOORD_1']),
          'palette, normals and both shader UV sets survive export')
    check(all(math.isfinite(v) for v in base), 'geometry contains finite coordinates')
    uv2 = decode_floats(doc, binary, attributes['TEXCOORD_1'])
    kinds.update(round(k * 8) for k in uv2[::2])
    check(all('%s_%02d' % (clip, i) in aliases or (clip == 'walk' and i == 0)
              for clip, count in clips.items() for i in range(count)),
          'all walking, breathing, bite, venom and death samples resolve through aliases')
check(kinds == set(range(6)), 'skin, belly, horn, mouth, ivory and eye finishes remain distinct')
envelope = {}
for clip, count in clips.items():
    for i in range(count):
        label = '%s_%02d' % (clip, i)
        limits = [(min(h), max(h)) for h in (posed_heights(p, label) for p in geometry)]
        envelope[label] = [min(v[0] for v in limits), max(v[1] for v in limits)]
low = min(v[0] for v in envelope.values())
high = max(v[1] for v in envelope.values())
neutral = envelope['idle_00']
check(low >= -.005, 'all 114 authored poses stay above the ground within 5 mm')
check(envelope['die_29'][1] < 1, 'fallen body and three jaws finish on the ground')
citizen = body_bounds('walker_taxcollector', 1.12)
god = body_bounds('walker_zeus')
height = neutral[1] - neutral[0]
citizen_ratio = height / (citizen[1] - citizen[0])
god_ratio = height / (god[1] - god[0])
check(2.0 <= citizen_ratio <= 2.2, 'neutral Hydra is 2.0–2.2 times the displayed citizen body')
check(.75 <= god_ratio <= .90 and high < god[1] - god[0], 'neutral and raised Hydra stay below Zeus body height')
probes = monster['pose_probes']
check(set(probes) == set(envelope), 'mouth and contact probes cover every authored pose')
check(all(p['root'] == [0, 0, 0] for p in probes.values()), 'all poses remain in place without root displacement')
check(all(len(p['mouths']) == 3 and len(p['feet']) == 4 for p in probes.values()), 'three mouth anchors and four feet per pose')
check(all(sum(abs(foot[1] - .0235) < .001 for foot in probes['walk_%02d' % i]['feet']) >= 2 for i in range(24)),
      'every walking sample retains at least two planted feet')
for foot in range(4):
    # During support the native travel and local foot motion cancel at a .64-tile stride.
    offset = (0 if foot % 2 == 0 else .5) + (0 if foot < 2 else .25)
    stance = sorted(((i / 24 + offset) % 1, probes['walk_%02d' % i]['feet'][foot][2])
                    for i in range(24) if (i / 24 + offset) % 1 < .72)
    slope = (stance[-1][1] - stance[0][1]) / (stance[-1][0] - stance[0][0])
    check(abs(slope - .64) < .001, 'paw %d cancels native travel over the .64-tile gait cycle' % foot)
strikes = []
for head in range(3):
    strikes.append(min(range(24), key=lambda i: probes['fight_%02d' % i]['mouths'][head][2]))
check(len(set(strikes)) == 3, 'three heads bite in separate phases')
mouth_heights = [p[1] for p in probes['idle_00']['mouths']]
check(mouth_heights[1] > max(mouth_heights[0], mouth_heights[2]) + .2, 'central head retains the taller reference silhouette')
result = {'okay': all(c['okay'] for c in checks), 'checks': checks, 'vertices': vertices, 'triangles': triangles,
          'authored_vertices': contract['vertices'], 'neutral_bounds': neutral, 'pose_bounds': [low, high],
          'fallen_bounds': envelope['die_29'], 'citizen_body_bounds': citizen, 'god_body_bounds': god,
          'citizen_height_ratio': citizen_ratio, 'god_height_ratio': god_ratio, 'pose_count': len(envelope)}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(result, indent=2) + '\n')
print('HYDRA_ASSET_VALIDATION', 'PASS' if result['okay'] else 'FAIL', 'checks=', len(checks))
raise SystemExit(0 if result['okay'] else 1)
