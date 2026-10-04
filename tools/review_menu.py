#!/usr/bin/env python3
"""Visible main-menu review. Scratch preferences/saves; never opens a city."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO.parent
GODOT = ROOT / 'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'
PROTECTED = [REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez',
             REPO / 'settings.txt', ROOT / 'settings.txt']

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lang', choices=['en', 'ru'], default='en')
    parser.add_argument('--size', default='1920x1080')
    parser.add_argument('--time', type=float, default=6.0)
    args = parser.parse_args()
    captures = REPO / 'godot/captures'
    captures.mkdir(exist_ok=True)
    stem = f'menu-hades-{args.lang}-{args.size}'
    before = {str(path): digest(path) for path in PROTECTED}
    command = [str(GODOT), '--path', str(REPO / 'godot'),
               '--rendering-method', 'mobile', '--rendering-driver', 'metal',
               '--log-file', str(captures / (stem + '.log')),
               '--script', 'res://scripts/review_menu.gd', '--quit-after', '480', '--',
               '--silent', f'--menu-lang={args.lang}', f'--menu-size={args.size}',
               f'--menu-time={args.time}', f'--menu-output={captures / (stem + ".png")}']
    result = subprocess.run(command, cwd=REPO, capture_output=True, text=True, timeout=90)
    print(result.stdout, end='')
    if result.stderr:
        print(result.stderr, end='')
    reports = [json.loads(line.removeprefix('MENU_REVIEW '))
               for line in result.stdout.splitlines() if line.startswith('MENU_REVIEW ')]
    unchanged = all(digest(Path(path)) == value for path, value in before.items())
    if result.returncode or len(reports) != 1 or not reports[0].get('passed') or not unchanged:
        raise SystemExit('Menu review failed or protected files changed.')
    report = reports[0]
    report['protected_files_unchanged'] = unchanged
    report['protected_sha256'] = before
    (captures / (stem + '.json')).write_text(json.dumps(report, indent=2) + '\n')
    print('Protected test save and settings are unchanged.')

if __name__ == '__main__':
    main()
