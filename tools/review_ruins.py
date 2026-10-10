#!/usr/bin/env python3
"""Owned ruin-inspection and full-site clearing review; disposable profile only."""
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
log = REPO / f'godot/captures/ruins-{args.lang}-engine.log'
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-ruins-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        environment['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text('')
        process = subprocess.Popen([str(GODOT), '--path', str(REPO / 'godot'), '--script',
                                    'res://scripts/review_ruins.gd', '--log-file', str(log),
                                    '--', '--skip-start', '--lang=' + args.lang, '--silent'],
                                   cwd=REPO, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 240
        while process.poll() is None:
            time.sleep(.2)
            if 'SCRIPT ERROR:' in log.read_text(errors='replace') or time.monotonic() >= deadline:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        code = process.returncode
        startup = process.stdout.read().decode(errors='replace')
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Ruin review closed; designated save and player preferences unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('RUINS_') or 'SCRIPT ERROR:' in line:
        print(line)
if 'RUINS_REVIEW PASS' not in output or 'SCRIPT ERROR:' in output or 'ERROR:' in output:
    print('Owned preview exit:', code, startup[-1800:])
    raise SystemExit('Ruin review failed; see ' + str(log))
raise SystemExit(code)
