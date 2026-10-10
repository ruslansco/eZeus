#!/usr/bin/env python3
"""Owned native cursor review with disposable preferences and a protected-file guard."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--hold', action='store_true', help='Leave the owned cursor sheet open for 45 seconds')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
log = REPO / 'godot/captures/game-cursor-engine.log'
command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
           'res://scripts/review_game_cursor.gd', '--log-file', str(log), '--', '--cursor-review']
if args.hold:
    command.append('--hold')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-cursor-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        log.write_text('')
        process = subprocess.Popen(command, cwd=REPO, env=environment,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 90
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
    print('Cursor review closed; designated save and preferences are unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('CURSOR_') or 'SCRIPT ERROR:' in line:
        print(line)
if 'CURSOR_VALIDATION PASS' not in output or 'ERROR:' in output:
    raise SystemExit('Cursor review failed; see ' + str(log))
raise SystemExit(code)
