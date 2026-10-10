#!/usr/bin/env python3
"""Owned save/recovery review; isolated files, probe processes and settings."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser=argparse.ArgumentParser()
parser.add_argument('--lang',choices=['en','ru'],default='en')
parser.add_argument('--headless',action='store_true')
parser.add_argument('--godot',type=Path,default=GODOT)
args=parser.parse_args()
protected=[SAVE,REPO/'settings.txt',ROOT/'settings.txt',Path.home()/'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg',Path(os.environ.get('APPDATA',str(Path.home()/'AppData/Roaming')))/'Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before={p:fingerprint(p) for p in protected}
log=REPO/('godot/captures/save-reliability-'+args.lang+('-headless' if args.headless else '')+'-engine.log')
command=[str(args.godot.resolve()),'--path',str(REPO/'godot'),'--script','res://scripts/validate_save_reliability.gd','--log-file',str(log)]
if args.headless:command.append('--headless')
command+=['--','--silent','--lang='+args.lang]
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-save-review-') as directory:
        env=os.environ.copy();env['EZEUS_REVIEW_SETTINGS_PATH']=str(Path(directory)/'settings.cfg');env['EZEUS_REVIEW_SAVE_DIRECTORY']=str(Path(directory)/'saves')
        log.write_text('')
        with subprocess.Popen(command,cwd=REPO,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.STDOUT) as process:
            deadline=time.monotonic()+240
            while process.poll() is None:
                time.sleep(.2)
                with log.open(errors='replace') as f:current=f.read(2_000_000)
                if 'SCRIPT ERROR:' in current or time.monotonic()>deadline:process.terminate();break
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait()
            status=process.returncode
        output=log.read_text(errors='replace')
        for line in output.splitlines():
            if line.startswith('SAVE_RELIABILITY_') or 'ERROR:' in line:print(line,flush=True)
        if status or 'SAVE_RELIABILITY_VALIDATION PASS' not in output or 'ERROR:' in output:raise RuntimeError('Save review failed: '+str(log))
finally:
    changed=[str(p) for p in protected if fingerprint(p)!=before[p]]
    if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
    print('Designated city and player preferences unchanged.',flush=True)
