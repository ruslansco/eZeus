#!/usr/bin/env python3
"""A city saved by the Godot presentation, or a new game started from an adventure, opens in the native SDL game with the
identical gameplay state.

Runs godot/scripts/validate_saves.gd (the embedded core builds a road, saves the city and reloads it) and
godot/scripts/validate_adventures.gd (new games saved and reloaded), keeps one save of each in a scratch directory,
loads them in the SDL executable (Bin/eZeus, EZEUS_REPLAY with zero ticks) and compares the state digest it prints
with the embedded core's digest of the same city.

    python3 tools/save_roundtrip.py

Nothing in the repository is written: the designated save and settings are hashed before and after.
"""
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


# (validator, digest line it prints, saved file it keeps): a city saved from the designated save, and a new game
# started from an adventure, must both open in the SDL game with the identical gameplay state.
CASES = [('validate_saves.gd', r'SAVE_DIGEST (\S+) file=', 'SAVE_VALIDATION PASS', 'first save.ez'),
         ('validate_adventures.gd', r'ADVENTURE_DIGEST (\S+) file=', 'ADVENTURE_VALIDATION PASS', 'The-Founding-of-Athens.ez'),
         ('validate_pyramids.gd', r'PYRAMID_DIGEST (\S+) file=', 'PYRAMID_VALIDATION PASS', 'pyramid-city.ez')]


def native_digest(file, scratch):
    env = {k: v for k, v in os.environ.items() if not k.startswith('EZEUS_')}
    env['EZEUS_SHOT'] = f'{file};{scratch}/unused.png;1'
    env['EZEUS_REPLAY'] = '0;7'
    native = subprocess.run([str(SDL)], cwd=REPO, env=env, capture_output=True, text=True, timeout=600)
    found = re.search(r'EZEUS_REPLAY: ticks=0 seed=7 digest=(\S+)', native.stdout)
    if not found:
        raise SystemExit(f'The SDL executable produced no digest for {file}:\n{native.stdout[-600:]}')
    return found.group(1)


def main():
    protected = [SAVE, REPO / 'settings.txt']
    before = {p: digest_of(p) for p in protected}
    results = []
    for validator, pattern, passed, name in CASES:
        with tempfile.TemporaryDirectory(prefix='ezeus-saves-') as scratch:
            # The pyramid validator runs only its save section here (the rest of it is a validator of its own).
            extra = ['--only=save'] if validator == 'validate_pyramids.gd' else []
            run = subprocess.run([str(GODOT), '--headless', '--path', str(REPO / 'godot'), '--script', f'res://scripts/{validator}',
                                  '--', f'--keep={scratch}'] + extra, cwd=REPO, capture_output=True, text=True, timeout=600)
            match = re.search(pattern, run.stdout)
            if not match or passed not in run.stdout:
                raise SystemExit(f'{validator} failed:\n{run.stdout[-800:]}')
            embedded = match.group(1)
            native = native_digest(f'{scratch}/{name}', scratch)
        results.append((name, embedded, native))
    unchanged = all(digest_of(p) == before[p] for p in protected)
    same = all(e == n for _, e, n in results)
    for name, embedded, native in results:
        print(f"{'PASS' if embedded == native else 'FAIL'}  {name}  embedded={embedded}  sdl={native}")
    print('protected save and settings unchanged' if unchanged else 'PROTECTED FILE CHANGED')
    print('SAVE_ROUNDTRIP', 'PASS' if same and unchanged else 'FAIL')
    return 0 if same and unchanged else 1


if __name__ == '__main__':
    sys.exit(main())
