#!/usr/bin/env python3
"""Native decision/portrait review using the designated city."""
import argparse
import subprocess
import os
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
engine_log = REPO / ('godot/captures/envoy-' + args.lang + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'),
           '--script', 'res://scripts/review_envoys.gd',
           '--log-file', str(engine_log),
           '--', '--lang=' + args.lang, '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-envoy-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        result = subprocess.run(command, cwd=REPO, timeout=180, env=environment)
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Envoy review closed; designated save and preferences are unchanged.', flush=True)
log = engine_log.read_text()
marker = 'ENVOY_REVIEW PASS'
if marker not in log or 'SCRIPT ERROR:' in log or 'ERROR:' in log:
    raise SystemExit('Envoy review did not complete cleanly; see ' + str(engine_log))
raise SystemExit(result.returncode)
