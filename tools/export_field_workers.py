#!/usr/bin/env python3
"""Stage authored field-worker GLBs in disposable background Blender processes."""
import argparse
import concurrent.futures
import subprocess
from pathlib import Path

REPO=Path(__file__).resolve().parents[1]
ASSETS=['walker_hunter','walker_deerhunter','walker_shepherd','walker_goatherd','walker_grower','walker_orangetender','walker_rancher','animal_boar','animal_deer']
p=argparse.ArgumentParser()
p.add_argument('--only',help='Comma-separated subset of field-work assets')
p.add_argument('--output-dir',type=Path,default=REPO/'godot/captures/field-work-staged')
p.add_argument('--jobs',type=int,default=2)
a=p.parse_args()
assets=a.only.split(',') if a.only else ASSETS
if any(n not in ASSETS for n in assets):p.error('Unknown field-work asset')
a.output_dir.mkdir(parents=True,exist_ok=True)
(a.output_dir/'.gdignore').touch()
def export(name):
 log=a.output_dir/(name+'-export.log')
 with log.open('w') as out:
  r=subprocess.run(['/Applications/Blender.app/Contents/MacOS/Blender','-b','--factory-startup','--python-exit-code','1','-P',str(REPO/'tools/export_godot_pilot.py'),'--','--asset',name,'--output-dir',str(a.output_dir)],cwd=REPO,stdout=out,stderr=subprocess.STDOUT)
 return name,r.returncode,log
failed=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=max(1,min(a.jobs,2))) as pool:
 for future in concurrent.futures.as_completed([pool.submit(export,n) for n in assets]):
  name,code,log=future.result()
  print(name,'PASS' if code==0 else 'FAIL',str(log),flush=True)
  if code:failed.append(name)
if failed:raise SystemExit('Failed exports: '+', '.join(failed))
print('FIELD_EXPORT PASS '+str(len(assets)),flush=True)
