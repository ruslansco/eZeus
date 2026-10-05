#!/usr/bin/env python3
"""Owned campaign-card preview, real installed adventures, scratch profile and protected-file guard."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
log = REPO / f'godot/captures/adventure-card-{args.lang}-engine.log'
command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
           'res://scripts/review_adventure_cards.gd', '--log-file', str(log),
           '--', '--adventure-card-review', '--lang=' + args.lang, '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-adventure-card-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        environment['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        log.write_text('')
        process = subprocess.Popen(command, cwd=REPO, env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 150
        while process.poll() is None:
            time.sleep(.2)
            tail = log.read_text(errors='replace')[-16000:]
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
    print('Adventure review closed; designated save and preferences are unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('ADVENTURE_UI_') or 'SCRIPT ERROR:' in line:
        print(line)
if 'ADVENTURE_UI_VALIDATION PASS' not in output or 'SCRIPT ERROR:' in output or 'ERROR:' in output:
    raise SystemExit('Adventure review failed; see ' + str(log))
raise SystemExit(code)
