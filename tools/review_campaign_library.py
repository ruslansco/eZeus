#!/usr/bin/env python3
"""Owned normal-menu campaign review; guards every existing source/profile."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO.parent
GODOT = ROOT / 'tools/godot-runtime/Godot.app/Contents/MacOS/Godot'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lang', choices=['en','ru'], default='en')
    parser.add_argument('--headless', action='store_true')
    parser.add_argument('--menu-only', action='store_true', help='Review native chapter previews and the next-screen stories without loading the 3D city')
    args = parser.parse_args()
    report = REPO / 'build-content-research/campaign-library' / ('review-' + args.lang + ('-headless' if args.headless else '-visible') + ('-menus' if args.menu_only else '')) / str(time.time_ns())
    report.mkdir(parents=True)
    userdata = Path.home() / 'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot'
    protected = [REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez', REPO / 'settings.txt',
                 ROOT / 'settings.txt', userdata / 'settings.cfg', REPO / 'numbers.txt']
    roots = [userdata / 'saves', REPO / 'build-content-research/first-light-harbor/play',
             REPO / 'build-content-research/bronze-river/play',
             REPO / 'build-content-research/stonewatch/play',
             REPO / 'build-content-research/sunlit-terraces/play',
             REPO / 'build-content-research/tidebound-covenant/play']
    for path in roots:
        protected += [file for file in path.rglob('*') if file.is_file() and file.suffix != '.log']
    for slug in ['first-light-harbor','bronze-river','stonewatch','sunlit-terraces','tidebound-covenant']:
        manifest = json.loads((REPO / 'build-content-research' / slug / 'current.json').read_text())
        protected += [Path(manifest['campaign']) / file for file in manifest['files']]
    before = {path: digest(path) for path in protected}
    env = os.environ.copy()
    env.update(EZEUS_SCENARIO_REPORT=str(report), EZEUS_REVIEW_SETTINGS_PATH=str(report / 'settings.cfg'),
               EZEUS_REVIEW_SAVE_DIRECTORY=str(report / 'saves'))
    log = report / 'engine.log'
    command = [str(GODOT), '--path', str(REPO / 'godot'), '--script',
               'res://scripts/review_campaign_library.gd', '--log-file', str(log)]
    command += ['--headless'] if args.headless else ['--rendering-method','mobile','--rendering-driver','metal']
    command += ['--','--lang='+args.lang,'--silent']
    if args.menu_only:
        command.append('--menu-only')
    try:
        with (report / 'console.log').open('w') as stream:
            result = subprocess.run(command, cwd=REPO, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=240)
        output = log.read_text(errors='replace')
        for line in output.splitlines():
            if line.startswith('CAMPAIGN_LIBRARY_') or 'ERROR:' in line:
                print(line, flush=True)
        if result.returncode or 'ERROR:' in output or 'CAMPAIGN_LIBRARY_REVIEW PASS' not in output:
            raise RuntimeError('Campaign library review failed: ' + str(report))
        (report.parent / 'latest.json').write_text(json.dumps({'report': str(report)}, indent=2)+'\n')
    finally:
        changed = [str(path) for path in protected if digest(path) != before[path]]
        if changed:
            raise RuntimeError('Protected inputs changed: ' + ', '.join(changed))
        print('Protected original profiles, sources and preferences unchanged.', flush=True)


if __name__ == '__main__':
    main()
