#!/usr/bin/env python3
"""Read-only status/accessibility review using the designated city."""
import argparse
import subprocess
import os
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--checks', action='store_true')
parser.add_argument('--menu', action='store_true')
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
suffix = ('menu-' if args.menu else ('checks-' if args.checks else 'review-')) + args.lang
engine_log = REPO / ('godot/captures/status-ui-' + suffix + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'),
           '--script', 'res://scripts/review_status_ui.gd',
           '--log-file', str(engine_log),
           '--', '--lang=' + args.lang, '--silent']
if args.checks:
    command.append('--checks')
if args.menu:
    command.append('--menu')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-status-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        result = subprocess.run(command, cwd=REPO, timeout=180, env=environment)
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Status review closed; designated save and preferences are unchanged.', flush=True)
log = engine_log.read_text()
marker = 'STATUS_MENU_VALIDATION PASS' if args.menu else ('STATUS_UI_COMBINED PASS' if args.checks else 'STATUS_UI_REVIEW_DONE')
if marker not in log or 'SCRIPT ERROR:' in log or 'ERROR:' in log:
    raise SystemExit('Status review did not complete cleanly; see ' + str(engine_log))
raise SystemExit(result.returncode)
