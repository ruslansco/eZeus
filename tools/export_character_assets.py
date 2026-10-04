#!/usr/bin/env python3
"""Export the Godot people in isolated background Blender processes.

Stage candidates first; inspect/import them before replacing development assets.
This never connects to the live Blender scene or rebuilds native sprite atlases.
"""
import argparse
import concurrent.futures
import json
from pathlib import Path
import subprocess
import time
from godot_asset_sources import PEOPLE, CREATURES

REPO = Path(__file__).resolve().parents[1]
BLENDER = Path('/Applications/Blender.app/Contents/MacOS/Blender')
NAMES = ['philosopher','physician','transporter','settlers1'] + ['walker_'+n for n in PEOPLE + CREATURES]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output-dir',type=Path,required=True)
    parser.add_argument('--assets',nargs='+',choices=NAMES,default=NAMES)
    parser.add_argument('--jobs',type=int,choices=[1,2],default=2)
    args=parser.parse_args()
    output=args.output_dir.resolve();output.mkdir(parents=True,exist_ok=True)
    logs=REPO/'godot/captures/character-exports';logs.mkdir(exist_ok=True)
    def export(name):
        start=time.monotonic()
        with (logs/(name+'.log')).open('w') as log:
            run=subprocess.run([str(BLENDER),'-b','--factory-startup','--python-exit-code','1',
                '-P',str(REPO/'tools/export_godot_pilot.py'),'--','--asset',name,
                '--output-dir',str(output)],cwd=REPO,stdout=log,stderr=subprocess.STDOUT)
        result={'asset':name,'seconds':round(time.monotonic()-start,2),'exit_code':run.returncode}
        if run.returncode == 0:
            report=json.loads((output/(name+'.json')).read_text())
            result.update(vertices=report['vertices'],bytes=report['bytes'],surfaces=report['surfaces'])
            if report['vertices'] > report.get('character', {}).get('vertex_budget', 60000):
                result['error']='geometry budget exceeded'
        else:
            result['error']='export failed; see '+str(logs/(name+'.log'))
        return result
    results=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for future in concurrent.futures.as_completed([pool.submit(export,n) for n in args.assets]):
            result=future.result();results.append(result)
            print(json.dumps(result),flush=True)
    (logs/'rollout.json').write_text(json.dumps({'assets':sorted(results,key=lambda r:r['asset'])},indent=2)+'\n')
    if any(r.get('error') for r in results):raise SystemExit(1)

if __name__=='__main__':main()
