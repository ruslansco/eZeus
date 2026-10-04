#!/usr/bin/env python3
"""Disposable display-settings review; never write the designated city/player preferences."""
import argparse
import os
import subprocess
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--headless', action='store_true')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {p: fingerprint(p) for p in protected}
suffix = ('headless-' if args.headless else '') + args.lang
log = REPO / ('godot/captures/display-settings-' + suffix + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
           'res://scripts/review_display_settings.gd', '--log-file', str(log)]
if args.headless:
    command.append('--headless')
command += ['--', '--lang=' + args.lang, '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-display-review-') as directory:
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        result = subprocess.run(command, cwd=REPO, timeout=180, env=env)
finally:
    changed = [str(p) for p in protected if before[p] != fingerprint(p)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Display review closed; designated save and player preferences are unchanged.', flush=True)
text = log.read_text()
if 'DISPLAY_SETTINGS_VALIDATION PASS' not in text or 'SCRIPT ERROR:' in text or 'ERROR:' in text:
    raise SystemExit('Display review failed; see ' + str(log))
raise SystemExit(result.returncode)
