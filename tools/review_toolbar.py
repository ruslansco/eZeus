#!/usr/bin/env python3
"""Owned construction toolbar review with disposable saves/settings and protected hashes."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time

from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--previews', action='store_true', help='Audit every catalog design and render building cards, including composite buildings.')
parser.add_argument('--context', action='store_true', help='Review category labels and unavailable slots with sparse catalogs.')
args = parser.parse_args()
protected = [
    SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
    Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg',
]
before = {path: fingerprint(path) for path in protected}
tag = 'building-previews' if args.previews else ('toolbar-context' if args.context else 'toolbar')
log = REPO / f'godot/captures/{tag}-{args.lang}-engine.log'
command = [
    str(GODOT), '--path', str(REPO / 'godot'), '--script',
    'res://scripts/review_toolbar.gd', '--log-file', str(log),
    '--', '--toolbar-review', '--lang=' + args.lang, '--silent',
]
if args.previews:
    command.append('--previews-only')
if args.context:
    command.append('--context-only')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-toolbar-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        environment['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text('')
        process = subprocess.Popen(
            command, cwd=REPO, env=environment,
            stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT,
        )
        deadline = time.monotonic() + 240
        while process.poll() is None:
            time.sleep(.2)
            tail = log.read_text(errors='replace')[-20000:]
            if 'SCRIPT ERROR:' in tail or time.monotonic() >= deadline:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        code = process.returncode
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Toolbar review closed; designated save and preferences are unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('TOOLBAR_') or 'SCRIPT ERROR:' in line:
        print(line)
if 'TOOLBAR_VALIDATION PASS' not in output or 'SCRIPT ERROR:' in output or 'ERROR:' in output:
    raise SystemExit('Toolbar review failed; see ' + str(log))
raise SystemExit(code)
