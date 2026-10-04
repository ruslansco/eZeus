#!/usr/bin/env python3
"""Export authored building work loops in disposable Blender processes, then bake VATs.
Original static GLBs, atlases and the user's Blender session stay untouched.
"""
import argparse,concurrent.futures,json,subprocess,sys,time
from pathlib import Path
from types import SimpleNamespace
from bake_walker_vat import bake
REPO=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets',nargs='+')
    parser.add_argument('--jobs',type=int,choices=[1,2],default=2)
    parser.add_argument('--retry-failed',action='store_true')
    args=parser.parse_args()
    names=args.assets or json.loads(Path(__file__).with_name('building_activity_assets.json').read_text())
    out=REPO/'godot/assets/building_activity';source=out/'source';source.mkdir(parents=True,exist_ok=True)
    (source/'.gdignore').touch()
    logs=REPO/'godot/captures/building-exports';logs.mkdir(parents=True,exist_ok=True)
    def export(name):
        if args.retry_failed and (out/'runtime'/f'{name}.vat.json').exists():return {'asset':name,'result':'existing'}
        started=time.monotonic()
        with (logs/f'{name}.log').open('w') as log:
            run=subprocess.run(['/Applications/Blender.app/Contents/MacOS/Blender','-b','--factory-startup','--python-exit-code','1','-P',str(REPO/'tools/export_godot_pilot.py'),'--','--asset',name,'--building-activity','--output-dir',str(source)],cwd=REPO,stdout=log,stderr=subprocess.STDOUT)
        if run.returncode:return {'asset':name,'result':'failed','code':run.returncode}
        manifest=json.loads((source/f'{name}.json').read_text())
        if not manifest['building_activity']['dynamic_source_objects']:return {'asset':name,'result':'failed','reason':'no changing worker or machinery geometry'}
        result=bake(source/f'{name}.glb',out/'runtime',SimpleNamespace(force=True,dry_run=False))
        if result is None:return {'asset':name,'result':'failed','reason':'missing exported work samples'}
        (out/'runtime'/f'{name}.json').write_text(json.dumps(manifest,indent=2)+'\n')
        return {'asset':name,'result':'exported','seconds':round(time.monotonic()-started,1),'bake':result}
    results=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
        for result in executor.map(export,names):
            results.append(result);print(json.dumps(result),flush=True)
    (logs/'rollout.json').write_text(json.dumps(results,indent=2)+'\n')
    return int(any(x['result']=='failed' for x in results))
if __name__=='__main__':sys.exit(main())
