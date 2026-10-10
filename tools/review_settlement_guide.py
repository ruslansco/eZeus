#!/usr/bin/env python3
"""Owned sequential guide review; protected designated city and player preferences."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser=argparse.ArgumentParser()
parser.add_argument('--lang',choices=['en','ru'],default='en')
args=parser.parse_args()
protected=[SAVE,ROOT/'settings.txt',REPO/'settings.txt',Path.home()/'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before={path:fingerprint(path) for path in protected}
log=REPO/f'godot/captures/settlement-{args.lang}-engine.log'
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-settlement-') as directory:
        env=os.environ.copy()
        env['EZEUS_REVIEW_SETTINGS_PATH']=str(Path(directory)/'settings.cfg')
        env['EZEUS_REVIEW_SAVE_DIRECTORY']=str(Path(directory)/'saves')
        command=[str(GODOT),'--path',str(REPO/'godot'),'--script','res://scripts/review_settlement_guide.gd','--log-file',str(log),'--','--silent','--lang='+args.lang]
        log.write_text('')
        with subprocess.Popen(command,cwd=REPO,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.STDOUT) as result:
            deadline=time.monotonic()+180
            while result.poll() is None:
                time.sleep(.2)
                if 'SCRIPT ERROR:' in log.read_text(errors='replace') or time.monotonic()>deadline:
                    result.terminate()
                    try:result.wait(timeout=5)
                    except subprocess.TimeoutExpired:result.kill();result.wait()
        output=log.read_text(errors='replace')
        for line in output.splitlines():
            if line.startswith('SETTLEMENT_') or 'ERROR:' in line:print(line)
        if result.returncode or 'SETTLEMENT_VALIDATION PASS' not in output or 'ERROR:' in output:
            raise RuntimeError('Settlement guide review failed: '+str(log))
finally:
    changed=[str(path) for path in protected if fingerprint(path)!=before[path]]
    if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
    print('Designated city and player preferences unchanged.')
