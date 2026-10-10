#!/usr/bin/env python3
"""Owned main menu preview, disposable leader/save copy, protected-file guard."""
import argparse
import os
import re
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser = argparse.ArgumentParser()
parser.add_argument('--lang', choices=['en', 'ru'], default='en')
parser.add_argument('--art-only', action='store_true', help='Capture the menu and unobstructed sanctuary, then exit before save fixtures')
parser.add_argument('--menu-only', action='store_true', help='Review menus and settings without loading the 3D city for the final Continue check')
parser.add_argument('--tag', default='main-menu', help='Owned capture/log prefix for concurrent work in the shared project')
args = parser.parse_args()
if not re.fullmatch(r'[a-z0-9][a-z0-9-]*', args.tag):
    parser.error('--tag must contain lowercase letters, digits or hyphens')
protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
             Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before = {path: fingerprint(path) for path in protected}
log = REPO / f'godot/captures/{args.tag}-{args.lang}-engine.log'
command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
           'res://scripts/review_main_menu.gd', '--log-file', str(log),
           '--', '--main-menu-review', '--lang=' + args.lang, '--silent', '--menu-capture-prefix=' + args.tag]
if args.art_only:
    command.append('--olympian-art-only')
if args.menu_only:
    command.append('--menu-only')
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-main-menu-') as directory:
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
    print('Main menu review closed; designated save and preferences are unchanged.', flush=True)
output = log.read_text(errors='replace')
for line in output.splitlines():
    if line.startswith('MAIN_MENU_') or 'SCRIPT ERROR:' in line:
        print(line)
if 'MAIN_MENU_VALIDATION PASS' not in output or 'SCRIPT ERROR:' in output or 'ERROR:' in output:
    raise SystemExit('Main menu review failed; see ' + str(log))
raise SystemExit(code)
