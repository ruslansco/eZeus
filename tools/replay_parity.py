#!/usr/bin/env python3
"""Seeded replay parity between the native SDL executable and the embedded Godot core.

Both builds replay the designated test city through the shared simulation order (engine/esimulationstep.cpp)
for N ticks from the same random seed and print a digest of the gameplay state (engine/estatedigest.cpp):
terrain, roads, every building, every character, treasury, population and clock. The digests must match
exactly. The check also runs the SDL executable twice per case to prove it is reproducible.

    python3 tools/replay_parity.py                   # ticks 0, 200 and 1200 with seeds 7 and 11
    python3 tools/replay_parity.py --ticks 600 --seeds 3

Requires Bin/eZeus (rebuild and sign it after C++ changes) and the Godot extension. Nothing is written: the
designated save and settings are hashed before and after.
"""
import argparse
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SAVE = REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez'
GODOT = REPO.parent / 'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'
SDL = REPO / 'Bin/eZeus'


def digest_of(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def sdl_replay(ticks, seed):
    env = {k: v for k, v in os.environ.items() if not k.startswith('EZEUS_')}
    env['EZEUS_SEED'] = str(seed)
    with tempfile.TemporaryDirectory(prefix='ezeus-replay-') as scratch:
        env['EZEUS_SHOT'] = f'{SAVE};{scratch}/unused.png;1'
        env['EZEUS_REPLAY'] = f'{ticks};{seed}'
        run = subprocess.run([str(SDL)], cwd=REPO, env=env, capture_output=True, text=True, timeout=600)
    match = re.search(r'EZEUS_REPLAY: ticks=\d+ seed=-?\d+ digest=(\S+) sections=\[([^\]]*)\] off_thread_draws=(\d+)', run.stdout)
    if not match:
        raise SystemExit(f'SDL replay produced no digest (exit {run.returncode}):\n{run.stdout[-600:]}\n{run.stderr[-600:]}')
    return match.group(1), match.group(2), int(match.group(3))


def embedded_replay(ticks, seed):
    command = [str(GODOT), '--headless', '--path', str(REPO / 'godot'), '--script', 'res://scripts/validate_replay.gd',
               '--', f'--ticks={ticks}', f'--seed={seed}', '--print']
    run = subprocess.run(command, cwd=REPO, capture_output=True, text=True, timeout=600)
    match = re.search(r'REPLAY_DIGEST (\S+) sections=\[([^\]]*)\] off_thread_draws=(-?\d+)', run.stdout)
    if not match:
        raise SystemExit(f'Embedded replay produced no digest (exit {run.returncode}):\n{run.stdout[-600:]}')
    return match.group(1), match.group(2), int(match.group(3))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--ticks', type=int, nargs='*', default=[0, 200, 1200])
    parser.add_argument('--seeds', type=int, nargs='*', default=[7, 11])
    args = parser.parse_args()
    for needed in (SDL, GODOT, SAVE):
        if not needed.exists():
            raise SystemExit(f'Missing {needed}')
    protected = [SAVE, REPO / 'settings.txt']
    before = {p: digest_of(p) for p in protected}
    failures = 0
    for seed in args.seeds:
        for ticks in args.ticks:
            first = sdl_replay(ticks, seed)
            again = sdl_replay(ticks, seed)
            embedded = embedded_replay(ticks, seed)
            reproducible = first[0] == again[0]
            parity = first[0] == embedded[0]
            threads = first[2] == 0 and embedded[2] == 0
            ok = reproducible and parity and threads
            failures += not ok
            print(f"{'PASS' if ok else 'FAIL'} ticks={ticks:5d} seed={seed:3d}  sdl={first[0]}  embedded={embedded[0]}"
                  f"{'' if reproducible else '  (SDL not reproducible: ' + again[0] + ')'}"
                  f"{'' if threads else '  (worker-thread random draws)'}")
            if not parity:
                print(f'     sdl      [{first[1]}]\n     embedded [{embedded[1]}]')
    unchanged = all(digest_of(p) == before[p] for p in protected)
    print('protected save and settings unchanged' if unchanged else 'PROTECTED FILE CHANGED')
    print('REPLAY_PARITY', 'PASS' if not failures and unchanged else 'FAIL')
    return 0 if not failures and unchanged else 1


if __name__ == '__main__':
    sys.exit(main())
