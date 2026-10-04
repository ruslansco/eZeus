#!/usr/bin/env python3
"""Owned character-window review using the designated city and scratch preferences."""
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
suffix = args.lang
engine_log = REPO / ('godot/captures/character-' + suffix + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'),
           '--script', 'res://scripts/review_character_panel.gd',
           '--log-file', str(engine_log),
           '--', '--lang=' + args.lang, '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-character-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        result = subprocess.run(command, cwd=REPO, timeout=180, env=environment)
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Character window review closed; designated save and preferences are unchanged.', flush=True)
log = engine_log.read_text()
marker = 'CHARACTER_PANEL_VALIDATION PASS'
if marker not in log or 'SCRIPT ERROR:' in log or 'ERROR:' in log:
    raise SystemExit('Character window review did not complete cleanly; see ' + str(engine_log))
raise SystemExit(result.returncode)
