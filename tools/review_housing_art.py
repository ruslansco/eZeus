#!/usr/bin/env python3
"""Owned Metal house-family review; guard saves, preferences and source artwork."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg',
             ROOT / 'art/common_house/levels.py', ROOT / 'art/_kit/greek_house.py']
for level in range(7):
    protected.append(ROOT / f'art/common_house_{level}a/build_sprites.py')
    protected.extend((ROOT / f'art/common_house_{level}a').glob('*.blend'))
before = {p: fingerprint(p) for p in protected}
log = REPO / 'godot/captures/housing-review-engine.log'
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-housing-review-') as folder:
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(folder) / 'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(folder) / 'saves')
        log.write_text('')
        process = subprocess.Popen([str(GODOT), '--path', str(REPO / 'godot'),
                                    '--rendering-method', 'mobile', '--rendering-driver', 'metal',
                                    '--resolution', '1600x1000', '--script', 'res://scripts/review_housing_art.gd',
                                    '--log-file', str(log), '--', '--skip-start', '--silent', '--lang=en'],
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
        if process.returncode or 'HOUSING_REVIEW PASS' not in output or 'ERROR:' in output:
            raise RuntimeError(f'Housing review failed; see {log}')
finally:
    changed = [str(p) for p in protected if before[p] != fingerprint(p)]
    if changed: raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Designated save, player preferences and native house artwork unchanged.', flush=True)
