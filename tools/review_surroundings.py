#!/usr/bin/env python3
"""Read-only landscape review on the designated test city, with file-hash protection."""
import argparse
import subprocess
from run_godot_pilot import REPO, ROOT, GODOT, SAVE, fingerprint

parser=argparse.ArgumentParser()
parser.add_argument('--headless',action='store_true')
parser.add_argument('--lang',choices=['en','ru'],default='en')
args=parser.parse_args()
protected=[SAVE,REPO/'settings.txt',ROOT/'settings.txt']
before={p:fingerprint(p) for p in protected}
command=[str(GODOT),'--path',str(REPO/'godot'),'--script','res://scripts/review_surroundings.gd','--log-file',str(REPO/'godot/captures/surroundings-engine.log')]
if args.headless:command.append('--headless')
command+=['--','--lang='+args.lang,'--silent']
try:
 result=subprocess.run(command,cwd=REPO,timeout=120)
finally:
 changed=[str(p) for p in protected if before[p]!=fingerprint(p)]
 if changed:raise RuntimeError('Protected files changed: '+', '.join(changed))
 print('Landscape review closed; designated save and settings are unchanged.',flush=True)
raise SystemExit(result.returncode)
