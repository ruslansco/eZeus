#!/usr/bin/env python3
"""Visible, read-only 3D world-map review using the designated city."""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--lang', choices=['en','ru'], default='en')
    p.add_argument('--size', default='1600x1000')
    p.add_argument('--native-ui', action='store_true',help='Retained world dealings and city pause/resume through the actual city scene')
    p.add_argument('--flight', action='store_true',help='City zoom/atlas flight, return, input and native state checks')
    args=p.parse_args()
    protected=[SAVE,REPO/'settings.txt',ROOT/'settings.txt',Path.home()/'Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg']
    before={path:fingerprint(path) for path in protected}
    log=REPO/('godot/captures/world-atlas-%s-%s.log'%(args.lang,'flight' if args.flight else 'native-ui' if args.native_ui else args.size))
    script='review_world_flight.gd' if args.flight else 'review_world_atlas.gd'
    command=[str(GODOT),'--path',str(REPO/'godot'),'--rendering-method','mobile','--rendering-driver','metal','--script','res://scripts/'+script,'--log-file',str(log),'--','--silent','--lang='+args.lang,'--size='+args.size]
    if args.native_ui:command.append('--native-ui')
    try:
        with tempfile.TemporaryDirectory(prefix='ezeus-atlas-review-') as directory:
            env={k:v for k,v in os.environ.items() if not k.startswith('EZEUS_')}
            env['EZEUS_REVIEW_SETTINGS_PATH']=str(Path(directory)/'settings.cfg')
            result=subprocess.run(command,cwd=REPO,env=env,capture_output=True,text=True,timeout=150)
            print(result.stdout,end='');print(result.stderr,end='')
    finally:
        changed=[str(path) for path in protected if before[path]!=fingerprint(path)]
        if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
        print('Designated test save and preferences are unchanged.')
    reports=[json.loads(line.removeprefix('WORLD_ATLAS_REVIEW ')) for line in result.stdout.splitlines() if line.startswith('WORLD_ATLAS_REVIEW ')]
    if result.returncode or len(reports)!=1 or not reports[0]['passed'] or 'ERROR:' in result.stdout+result.stderr:
        raise SystemExit('World atlas review failed; see '+str(log))
    report=reports[0];report['protected_files_unchanged']=True
    if args.native_ui:report['retained_world_checks']=sum(line.startswith('GODOT_CHECK PASS') for line in result.stdout.splitlines())
    log.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
