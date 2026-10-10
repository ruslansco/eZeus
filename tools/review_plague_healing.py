#!/usr/bin/env python3
"""Owned plague recovery review; never changes the user's active game or saves."""
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
    protected = [SAVE, REPO / 'settings.txt', ROOT / 'settings.txt',
                 REPO / 'numbers.txt', ROOT / 'numbers.txt',
                 Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
    before = {p: fingerprint(p) for p in protected}
    log = REPO / f'godot/captures/plague-healing-{args.lang}{"-headless" if args.headless else ""}-engine.log'
    try:
        with tempfile.TemporaryDirectory(prefix='ezeus-plague-review-') as directory:
            env = os.environ.copy()
            env['EZEUS_REVIEW_SETTINGS_PATH'] = str(Path(directory) / 'settings.cfg')
            env['EZEUS_REVIEW_SAVE_DIRECTORY'] = str(Path(directory) / 'saves')
            Path(env['EZEUS_REVIEW_SAVE_DIRECTORY']).mkdir()
            command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
                       'res://scripts/review_plague_healing.gd', '--log-file', str(log)]
            if args.headless: command.append('--headless')
            command += ['--', '--skip-start', '--silent', '--lang=' + args.lang]
            result = subprocess.run(command, cwd=REPO, env=env, timeout=180,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            output = log.read_text(errors='replace') if log.exists() else result.stdout
            for line in output.splitlines():
                if line.startswith('PLAGUE_') or 'SCRIPT ERROR:' in line: print(line, flush=True)
            if result.returncode or 'PLAGUE_REVIEW PASS' not in output or 'SCRIPT ERROR:' in output:
                raise RuntimeError(f'Plague recovery review failed: {log}')
    finally:
        changed = [str(p) for p in protected if fingerprint(p) != before[p]]
        if changed: raise RuntimeError('Protected files changed: ' + ', '.join(changed))
        print('Plague review closed; designated city, player preferences and number tables unchanged.', flush=True)

if __name__ == '__main__': main()
