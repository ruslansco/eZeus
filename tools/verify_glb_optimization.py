#!/usr/bin/env python3
"""Proves tools/optimize_glb_memory.py was lossless, file against file (standard library only).

For every backed-up original it decodes the optimized GLB and requires that
  * every primitive keeps byte-identical POSITION, NORMAL, COLOR_0 and index data;
  * every original morph frame name still resolves (through the "a|b|c" aliases) to a
    target whose decoded content equals the original target's;
  * nothing but TEXCOORD attributes and duplicate targets disappeared.

    python3 tools/verify_glb_optimization.py /path/to/backup [--models godot/assets/models]
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from optimize_glb_memory import MODELS, accessor_signature, read_glb  # noqa: E402


def verify(original_path, optimized_path, require_uv=False):
    od, ob = read_glb(original_path)
    nd, nb = read_glb(optimized_path)
    problems, frames, prims = [], 0, 0
    if len(od['meshes']) != len(nd['meshes']):
        return [f'mesh count {len(od["meshes"])} -> {len(nd["meshes"])}'], 0, 0
    for mi, (om, nm) in enumerate(zip(od['meshes'], nd['meshes'])):
        if len(om['primitives']) != len(nm['primitives']):
            problems.append(f'mesh {mi}: primitive count changed')
            continue
        for pi, (op, np_) in enumerate(zip(om['primitives'], nm['primitives'])):
            prims += 1
            if 'TEXCOORD_0' in np_['attributes'] and 'TEXCOORD_0' not in op['attributes']:
                problems.append(f'mesh {mi}.{pi}: gained a UV set')
            for name in op['attributes']:
                if name.startswith('TEXCOORD_') and not require_uv:
                    continue
                if name not in np_['attributes'] or accessor_signature(od, ob, op['attributes'][name]) != accessor_signature(nd, nb, np_['attributes'][name]):
                    problems.append(f'mesh {mi}.{pi}: attribute {name} differs')
            if ('indices' in op) != ('indices' in np_) or ('indices' in op and accessor_signature(od, ob, op['indices']) != accessor_signature(nd, nb, np_['indices'])):
                problems.append(f'mesh {mi}.{pi}: indices differ')
        onames = om.get('extras', {}).get('targetNames', [])
        nnames = nm.get('extras', {}).get('targetNames', [])
        alias = {}
        for index, joined in enumerate(nnames):
            for name in joined.split('|'):
                alias[name] = index
        if set(alias) != set(onames):
            problems.append(f'mesh {mi}: frame names changed')
            continue
        for index, name in enumerate(onames):
            frames += 1
            kept = alias[name]
            for op, np_ in zip(om['primitives'], nm['primitives']):
                original = {k: accessor_signature(od, ob, a) for k, a in op['targets'][index].items()}
                now = {k: accessor_signature(nd, nb, a) for k, a in np_['targets'][kept].items()}
                if original != now:
                    problems.append(f'mesh {mi}: frame {name} differs')
    return problems, frames, prims


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('backup', type=Path)
    parser.add_argument('--models', type=Path, default=MODELS)
    parser.add_argument('--require-uv', action='store_true', help='also prove both shader UV sets are byte-identical')
    args = parser.parse_args()
    bad = frames = prims = checked = 0
    for original in sorted(args.backup.glob('*.glb')):
        optimized = args.models / original.name
        if not optimized.exists():
            print('MISSING', original.name)
            bad += 1
            continue
        problems, f, p = verify(original, optimized, args.require_uv)
        checked, frames, prims = checked + 1, frames + f, prims + p
        for problem in problems:
            print('DIFF', original.stem, problem)
        bad += len(problems)
    print(f'verified {checked} models, {prims} primitives, {frames} morph frames: {bad} difference(s)')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
