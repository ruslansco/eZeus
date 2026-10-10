#!/usr/bin/env python3
"""Review marble defence models and guard projection with disposable preferences."""
import os
import subprocess
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {p: fingerprint(p) for p in protected}
log = REPO / 'godot/captures/defences-review.log'
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-defence-review-') as directory:
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        result = subprocess.run([str(GODOT), '--path', str(REPO / 'godot'), '--rendering-method', 'mobile',
                                 '--rendering-driver', 'metal', '--resolution', '1600x1000', '--script',
                                 'res://scripts/review_defences.gd', '--log-file', str(log),
                                 '--', '--skip-start', '--silent', '--lang=en'], cwd=REPO, env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=240)
        print(result.stdout, flush=True)
        if result.returncode or 'DEFENCE_REVIEW PASS' not in result.stdout or 'SCRIPT ERROR:' in result.stdout or 'ERROR:' in result.stdout:
            raise RuntimeError(f'Defence review failed; see {log}')
finally:
    changed = [str(p) for p in protected if before[p] != fingerprint(p)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Designated save and player preferences unchanged.', flush=True)
