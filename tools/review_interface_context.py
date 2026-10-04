#!/usr/bin/env python3
"""Contextual construction review/gates on the designated city; protect saves/settings."""
import argparse
import subprocess
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser=argparse.ArgumentParser()
parser.add_argument('--checks',action='store_true')
parser.add_argument('--lang',choices=['en','ru'],default='en')
args=parser.parse_args()
protected=[SAVE,REPO/'settings.txt',ROOT/'settings.txt']
before={p:fingerprint(p) for p in protected}
suffix=('checks-'+args.lang) if args.checks else 'review'
command=[str(GODOT),'--path',str(REPO/'godot'),'--script','res://scripts/review_interface_context.gd',
         '--log-file',str(REPO/('godot/captures/interface-context-'+suffix+'-engine.log')),
         '--','--lang='+args.lang,'--silent']
if args.checks:command.append('--checks')
try:
 result=subprocess.run(command,cwd=REPO,timeout=120)
finally:
 changed=[str(p) for p in protected if before[p]!=fingerprint(p)]
 if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
 print('Interface review closed; designated save and settings are unchanged.',flush=True)
raise SystemExit(result.returncode)
