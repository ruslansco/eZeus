#!/usr/bin/env python3
"""Owned hillside review using the designated city and scratch preferences."""
import argparse
import subprocess
import os
import tempfile
import time
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
args = parser.parse_args()
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
suffix = args.lang
engine_log = REPO / ('godot/captures/hillsides-'  + suffix + '-engine.log')
command = [str(GODOT), '--path', str(REPO / 'godot'),
           '--script', 'res://scripts/review_hillsides.gd',
           '--log-file', str(engine_log),
           '--', '--lang=' + args.lang, '--silent']
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-hillside-review-') as directory:
        environment = os.environ.copy()
        environment['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
        engine_log.write_text('')
        process = subprocess.Popen(command, cwd=REPO, env=environment)
        deadline = time.monotonic() + 180
        while process.poll() is None:
            time.sleep(.2)
            with engine_log.open('rb') as file:
                file.seek(max(0,engine_log.stat().st_size-16384))
                tail = file.read().decode('utf-8',errors='replace')
            if tail.count('Parameter "material" is null') >= 8 or time.monotonic() >= deadline:
                process.terminate()
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired: process.kill(); process.wait()
                print('Stopped this owned review after repeated renderer errors or timeout.',flush=True)
        result = process.returncode
finally:
    changed = [str(path) for path in protected if before[path] != fingerprint(path)]
    if changed:
        raise RuntimeError('Protected files changed: ' + ', '.join(changed))
    print('Hillside review closed; designated save and preferences are unchanged.', flush=True)
log = engine_log.read_text()
marker = 'HILLSIDE_REVIEW PASS'
if marker not in log or 'SCRIPT ERROR:' in log or 'ERROR:' in log:
    raise SystemExit('Hillside review did not complete cleanly; see ' + str(engine_log))
raise SystemExit(result)
