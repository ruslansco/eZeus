#!/usr/bin/env python3
"""Owned HUD chrome review with disposable saves/settings and protected hashes."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time

from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--army-native', action='store_true', help='Run the existing native army regression after the read-only chrome phase.')
parser.add_argument('--notifications-only', action='store_true', help='Review only instant notices at both window and interface sizes.')
args = parser.parse_args()
if args.notifications_only and args.army_native:
    parser.error('--notifications-only cannot be combined with --army-native')
protected = [
    SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
    Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg',
]
before = {path: fingerprint(path) for path in protected}
log = REPO / f'godot/captures/chrome-{args.lang}{"-notifications" if args.notifications_only else ("-army-native" if args.army_native else "")}-engine.log'
command = [
    str(GODOT), '--path', str(REPO / 'godot'), '--script',
    'res://scripts/review_chrome.gd', '--log-file', str(log),
    '--', '--chrome-review', '--lang=' + args.lang, '--silent',
]
if args.army_native:
    command.append('--army-native')
if args.notifications_only:
    command.append('--notifications-only')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-chrome-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        environment['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text('')
        process = subprocess.Popen(
            command, cwd=REPO, env=environment,
            stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT,
        )
        deadline = time.monotonic() + 360
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
    print('HUD chrome review closed; designated save and preferences are unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('CHROME_') or (args.army_native and line.startswith('GODOT_CHECK ')) or 'SCRIPT ERROR:' in line:
        print(line)
if args.army_native:
    native_checks = [line for line in output.splitlines() if line.startswith('GODOT_CHECK ')]
    print(f'CHROME_ARMY_NATIVE_CHECKS total={len(native_checks)} failed={sum(" FAIL " in line for line in native_checks)}')
if 'CHROME_VALIDATION PASS' not in output or 'SCRIPT ERROR:' in output or 'ERROR:' in output:
    raise SystemExit('HUD chrome review failed; see ' + str(log))
if args.army_native and ('CHROME_ARMY_NATIVE PASS' not in output or 'GODOT_CHECK FAIL' in output):
    raise SystemExit('Native army chrome regression failed; see ' + str(log))
raise SystemExit(code)
