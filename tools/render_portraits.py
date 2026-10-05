#!/usr/bin/env python3
"""Render still portraits of the models in build-portraits (to build-portraits/renders unless --out is given),
using the designated city read-only and scratch preferences. Copying a render into godot/assets/portraits replaces that
role's painted portrait; run `godot --import` afterwards."""
import argparse
import subprocess
import os
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--only', default='', help='comma-separated assets (default: every model in build-portraits)')
parser.add_argument('--out', default='', help='output folder (default: build-portraits/renders; the game\'s painted portraits are never overwritten)')
parser.add_argument('--views', default='bust', help='bust and/or full, comma-separated')
parser.add_argument('--crowd', action='store_true', help='render roles without a portrait model from their crowd model (references)')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
suffix = args.lang
engine_log = REPO / ('godot/captures/portrait-render-' + suffix + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'),
           '--script', 'res://scripts/render_portraits.gd',
           '--log-file', str(engine_log),
           '--', '--lang=' + args.lang, '--source=' + str(REPO / 'build-portraits'), '--only=' + args.only, '--views=' + args.views] + (['--out=' + args.out] if args.out else []) + (['--crowd'] if args.crowd else []) + [ '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-portrait-render-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        result = subprocess.run(command, cwd=REPO, timeout=180, env=environment)
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Portrait render closed; designated save and preferences are unchanged.', flush=True)
log = engine_log.read_text()
marker = 'PORTRAIT_RENDERED'
if marker not in log or 'PORTRAIT_RENDER ' in log and ' FAIL' in log or 'SCRIPT ERROR:' in log or 'ERROR:' in log:
    raise SystemExit('Portrait render did not complete cleanly; see ' + str(engine_log))
raise SystemExit(result.returncode)
