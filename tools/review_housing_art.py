#!/usr/bin/env python3
"""Owned Metal house-family review; guard saves, preferences and source artwork."""
import os
import argparse
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--lang',choices=['en','ru'],default='en')
parser.add_argument('--checks',action='store_true',help='Run native immigration, scratch reload and occupancy checks headlessly')
parser.add_argument('--residents-only',action='store_true',help='Use the small resident render fixture instead of loading the full city')
args = parser.parse_args()

protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg',
             ROOT / 'art/common_house/levels.py', ROOT / 'art/_kit/greek_house.py']
for level in range(7):
    protected.append(ROOT / f'art/common_house_{level}a/build_sprites.py')
    protected.extend((ROOT / f'art/common_house_{level}a').glob('*.blend'))
before = {p: fingerprint(p) for p in protected}
captures=REPO/'godot/captures/housing-occupancy'/args.lang
captures.mkdir(parents=True,exist_ok=True)
log = captures/('housing-residents-engine.log' if args.checks else 'resident-review-engine.log' if args.residents_only else 'housing-review-engine.log')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-housing-review-') as folder:
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(folder) / 'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(folder) / 'saves')
        env['EZEUS_HOUSING_REVIEW_DIRECTORY'] = str(captures)
        log.write_text('')
        script='validate_house_residents.gd' if args.checks else 'review_house_residents.gd' if args.residents_only else 'review_housing_art.gd'
        expected='HOUSE_RESIDENT_VALIDATION PASS' if args.checks else 'HOUSE_RESIDENT_REVIEW PASS' if args.residents_only else 'HOUSING_REVIEW PASS'
        process = subprocess.Popen([str(GODOT), *(['--headless'] if args.checks else []), '--path', str(REPO / 'godot'),
                                    '--rendering-method', 'mobile', '--rendering-driver', 'metal',
                                    '--resolution', '1600x1000', '--script', 'res://scripts/'+script,
                                    '--log-file', str(log), '--', '--skip-start', '--silent', '--lang='+args.lang],
                                   cwd=REPO, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 240
        while process.poll() is None:
            time.sleep(.2)
            if 'SCRIPT ERROR:' in log.read_text(errors='replace') or time.monotonic() >= deadline:
                process.terminate()
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill(); process.wait()
        output = log.read_text(errors='replace'); print(output, flush=True)
        if process.returncode or expected not in output or 'ERROR:' in output:
            raise RuntimeError(f'Housing review failed; see {log}')
finally:
    changed = [str(p) for p in protected if before[p] != fingerprint(p)]
    if changed: raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Designated save, player preferences and native house artwork unchanged.', flush=True)
