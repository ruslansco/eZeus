#!/usr/bin/env python3
"""Owned graphics UI review, with disposable preferences and saves."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', choices=['en', 'ru'], default='en')
    parser.add_argument('--headless', action='store_true')
    args = parser.parse_args()
    protected = [SAVE, REPO/'settings.txt', ROOT/'settings.txt',
                 Path.home()/'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
    before = {p: fingerprint(p) for p in protected}
    log = REPO/f'godot/captures/graphics-{args.lang}{"-headless" if args.headless else ""}.log'
    log.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='ezeus-graphics-') as folder:
        env = os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(folder)/'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(folder)/'saves')
        command = [str(GODOT), '--path', str(REPO/'godot'), '--script',
                   'res://scripts/review_graphics.gd', '--log-file', str(log)]
        if args.headless: command.append('--headless')
        command += ['--', '--silent', '--lang='+args.lang]
        try:
            result = subprocess.run(command, cwd=REPO, env=env, timeout=120,
                                    stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        finally:
            changed = [str(p) for p in protected if fingerprint(p) != before[p]]
            if changed: raise RuntimeError('Protected files changed: '+', '.join(changed))
    output = log.read_text(errors='replace')
    for line in output.splitlines():
        if 'VALIDATION' in line or 'FAIL' in line or 'ERROR:' in line: print(line)
    if result.returncode or 'GRAPHICS_VALIDATION PASS' not in output or 'ERROR:' in output:
        raise SystemExit('Graphics review failed; see '+str(log))
    print('Designated save and player preferences unchanged.')

if __name__ == '__main__': main()
