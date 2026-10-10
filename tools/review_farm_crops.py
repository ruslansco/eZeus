#!/usr/bin/env python3
"""Owned wheat growth/inspector gallery with disposable preferences."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--city', action='store_true', help='Verify the live observation path in the designated city held in memory.')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             REPO / 'godot/assets/models/farm.glb',
             ROOT / 'art/farm/build_sprites.py',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
log = REPO / f'godot/captures/wheat-{args.lang}{"-city" if args.city else ""}-review.log'
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-wheat-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        environment['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
                                 'res://scripts/review_farm_crops.gd', '--log-file', str(log),
                                 '--', '--lang=' + args.lang, '--silent', '--skip-start']
        if args.city:
            command.append('--city')
        result = subprocess.run(command, cwd=REPO, env=environment,
                                timeout=240, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        output = log.read_text(errors='replace') if log.exists() else result.stdout
        for line in output.splitlines():
            if line.startswith('FARM_') or 'SCRIPT ERROR:' in line or 'ERROR:' in line:
                print(line)
        if result.returncode or 'FARM_REVIEW PASS' not in output or 'ERROR:' in output:
            raise RuntimeError(f'Wheat preview exited {result.returncode}; see {log}')
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Wheat review closed; native art, designated save and player preferences unchanged.', flush=True)
