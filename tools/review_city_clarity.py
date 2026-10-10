#!/usr/bin/env python3
"""Owned city-help/art review with disposable saves and preferences."""
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
args=parser.parse_args()
protected=[SAVE,REPO/'settings.txt',ROOT/'settings.txt',Path.home()/'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
before={p:fingerprint(p) for p in protected}
log=REPO/('godot/captures/city-clarity-'+args.lang+('-headless' if args.headless else '')+'-engine.log')
command=[str(GODOT),'--path',str(REPO/'godot'),'--script','res://scripts/validate_city_clarity.gd','--log-file',str(log)]
if args.headless:command.append('--headless')
command+=['--','--silent','--lang='+args.lang]
try:
    with tempfile.TemporaryDirectory(prefix='ezeus-city-help-') as directory:
        env=os.environ.copy();env['EZEUS_REVIEW_SETTINGS_PATH']=str(Path(directory)/'settings.cfg');env['EZEUS_REVIEW_SAVE_DIRECTORY']=str(Path(directory)/'saves')
        log.write_text('')
        with subprocess.Popen(command,cwd=REPO,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.STDOUT) as process:
            deadline=time.monotonic()+160
            while process.poll() is None:
                time.sleep(.2)
                with log.open(errors='replace') as file:current=file.read(2_000_000)
                if 'ERROR:' in current or time.monotonic()>deadline:
                    process.terminate();break
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait()
            status=process.returncode
        output=log.read_text(errors='replace')
        for line in output.splitlines():
            if line.startswith('CITY_CLARITY_') or 'ERROR:' in line:print(line,flush=True)
        if status or 'CITY_CLARITY_VALIDATION PASS' not in output or 'ERROR:' in output:raise RuntimeError('City clarity review failed: '+str(log))
finally:
    changed=[str(p) for p in protected if fingerprint(p)!=before[p]]
    if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
    print('Designated city and player preferences unchanged.',flush=True)
