"""Export the city's source recipes in isolated Blender processes; never touch the live scene."""
from pathlib import Path
import argparse,subprocess,json,sys,time
from godot_asset_sources import RECIPES,PEOPLE
p=argparse.ArgumentParser();p.add_argument('--group',choices=['structures','walkers'],required=True);p.add_argument('--retry',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parents[1];out=root/'godot/assets/models';logs=root/'godot/captures';logs.mkdir(exist_ok=True)
jobs=list(RECIPES) if a.group=='structures' else ['transporter']+['walker_'+n for n in PEOPLE]+['animal_'+n for n in ['sheep_fleeced','sheep_nude','boar','deer','wolf','donkey','ox','goat','cattle','horse']]+['trade_ship','fishing_boat']
failed=[]
for i,n in enumerate(jobs):
 if (out/(n+'.json')).exists() and not a.retry:continue
 print(f'EXPORT {i+1}/{len(jobs)} {n}',flush=True)
 with (logs/f'export-{n}.log').open('w') as log:
  r=subprocess.run(['/Applications/Blender.app/Contents/MacOS/Blender','-b','--factory-startup','--python-exit-code','1','-P',str(root/'tools/export_godot_pilot.py'),'--','--asset',n],stdout=log,stderr=subprocess.STDOUT,cwd=root)
 if r.returncode:
  failed.append(n);print('FAILED',n,flush=True)
 else:print('EXPORTED',n,flush=True)
(logs/f'export-{a.group}-result.json').write_text(json.dumps({'jobs':jobs,'failed':failed},indent=2)+'\n')
print('COMPLETE failed=',failed,flush=True)
sys.exit(bool(failed))
