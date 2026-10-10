#!/usr/bin/env python3
"""Stage, verify and install the simplified city people, two background exports at a time.

Retains the separately authored Hades, physician skeletal benchmark, monsters,
native art and live Blender. Releases temporary raw files after each verified
installation so a catalog rebuild does not require several GiB of spare disk.
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
from types import SimpleNamespace

from optimize_glb_memory import optimize, read_glb
from verify_glb_optimization import verify
from bake_walker_vat import bake

REPO = Path(__file__).resolve().parents[1]
MODELS = REPO/'godot/assets/models'
REPORTS = REPO/'godot/captures/people-v2'
BLENDER = Path('/Applications/Blender.app/Contents/MacOS/Blender')


def geometry(path):
    doc, _ = read_glb(path)
    return dict(vertices=sum(doc['accessors'][p['attributes']['POSITION']]['count'] for m in doc['meshes'] for p in m['primitives']),
                triangles=sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),
                bytes=path.stat().st_size,
                frames=sorted({label for m in doc['meshes'] for target in m.get('extras',{}).get('targetNames',[]) for label in target.split('|')}))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets',nargs='+')
    parser.add_argument('--jobs',type=int,choices=[1,2],default=2)
    args=parser.parse_args()
    REPORTS.mkdir(parents=True,exist_ok=True)
    contracts={p.stem:json.loads(p.read_text()) for p in MODELS.glob('*.json')}
    catalog=sorted(n for n,m in contracts.items() if 'character' in m and n!='walker_hades')
    names=catalog
    if args.assets:
        assert set(args.assets)<=set(names), 'only existing human city assets are allowed'
        names=args.assets
    baseline=REPORTS/'before.json'
    if not baseline.exists():
        before={n:dict(geometry(MODELS/(n+'.glb')),character=contracts[n]['character'],
                       manifest={k:contracts[n].get(k) for k in ('walk_samples','idle_samples','stride_tiles','clips')}) for n in catalog}
        baseline.write_text(json.dumps(before,indent=2)+'\n')
    before=json.loads(baseline.read_text())
    assert set(names)<=set(before), 'use the full catalog baseline before a scoped rebuild'
    results_path=REPORTS/'results.json'
    results=json.loads(results_path.read_text()) if results_path.exists() else {}

    def rebuild(name):
        start=time.monotonic()
        with tempfile.TemporaryDirectory(prefix=name+'-',dir=REPORTS) as temporary:
            stage=Path(temporary)
            environment=os.environ.copy();environment['VECLIB_MAXIMUM_THREADS']='1'
            with (REPORTS/(name+'.log')).open('w') as log:
                subprocess.run([str(BLENDER),'-b','--factory-startup','--python-exit-code','1',
                    '-P',str(REPO/'tools/export_godot_pilot.py'),'--','--asset',name,'--output-dir',str(stage)],
                    cwd=REPO,env=environment,stdout=log,stderr=subprocess.STDOUT,check=True)
            path=stage/(name+'.glb')
            raw=stage/'raw'
            optimize(path,SimpleNamespace(dry_run=False,backup_dir=raw,drop_uv=False))
            problems,frames,primitives=verify(raw/path.name,path,require_uv=True)
            assert not problems, (name,problems)
            report=json.loads((stage/(name+'.json')).read_text())
            old=before[name]
            assert [(i['name'],i['body_sha256']) for i in old['character']['identities']]==[(i['name'],i['body_sha256']) for i in report['character']['identities']], name+' changed source anatomy'
            assert all(report.get(k)==v for k,v in old['manifest'].items()), name+' changed native clip contract'
            current=geometry(path)
            assert current['frames']==old['frames'], name+' lost pose aliases'
            assert current['triangles'] < old['triangles'], name+' did not reduce geometry'
            assert report['vertices']<=report['character']['city_detail']['allocation_target']*1.4, name+' exceeds city budget'
            # Bake the derivative against the verified candidate before replacing
            # either source file. Moving retains its recorded size/mtime pair.
            vat=bake(path,stage/'runtime',SimpleNamespace(force=True,dry_run=False))
            for suffix in ('.glb','.json'):
                (stage/(name+suffix)).replace(MODELS/(name+suffix))
            for candidate in (stage/'runtime').iterdir():
                if candidate.suffix!='.import':
                    candidate.replace(MODELS/'runtime'/candidate.name)
            return dict(asset=name,seconds=round(time.monotonic()-start,1),before={k:old[k] for k in ('vertices','triangles','bytes')},
                after={k:current[k] for k in ('vertices','triangles','bytes')},verified_frames=frames,primitives=primitives,
                vat_bytes=vat['vat'],max_pose_error=vat['error'],source_sha256=hashlib.sha256((MODELS/(name+'.glb')).read_bytes()).hexdigest())

    pending=[n for n in names if not (n in results and results[n]['source_sha256']==hashlib.sha256((MODELS/(n+'.glb')).read_bytes()).hexdigest())]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for future in concurrent.futures.as_completed([pool.submit(rebuild,n) for n in pending]):
            result=future.result();results[result['asset']]=result
            results_path.write_text(json.dumps(results,indent=2)+'\n')
            print(json.dumps(result),flush=True)
    print('CITY_PEOPLE_REBUILD_PASS',len(results),flush=True)


if __name__=='__main__':
    main()
