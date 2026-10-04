#!/usr/bin/env python3
"""Read-only proof of building VAT poses, retained geometry/UVs and asset budgets."""
import hashlib,json,struct,sys
from pathlib import Path
from bake_walker_vat import decode_floats
from optimize_glb_memory import accessor_signature,read_glb
REPO=Path(__file__).resolve().parents[1]

def main():
    folder=REPO/'godot/assets/building_activity'
    names=json.loads(Path(__file__).with_name('building_activity_assets.json').read_text())
    frames=0;worst=0.;problems=[]
    for name in names:
        manifest=json.loads((folder/'runtime'/f'{name}.json').read_text())
        layout=json.loads((folder/'runtime'/f'{name}.vat.json').read_text())
        original=REPO/'godot/assets/models'/f'{name}.glb'
        if hashlib.sha256(original.read_bytes()).hexdigest()!=manifest['building_activity']['base_sha256']:
            problems.append(name+': original model changed')
        source,sb=read_glb(folder/'source'/f'{name}.glb')
        runtime,rb=read_glb(folder/'runtime'/f'{name}.glb')
        if len(source['meshes']) != len(runtime['meshes']):problems.append(name+': changed mesh count')
        base,_=read_glb(original)
        triangle_count=lambda doc:sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives'])
        # Separating dynamic pieces may add a few seams, not a new geometry tier.
        if triangle_count(runtime)>triangle_count(base)*1.05:problems.append(name+': exceeds original triangle budget by 5%')
        if len(runtime['meshes'])>6:problems.append(name+': more than six static/dynamic finish groups')
        texture=(folder/'runtime'/f'{name}.vat').read_bytes()
        for sm,rm in zip(source['meshes'],runtime['meshes']):
            if len(sm['primitives']) != len(rm['primitives']):problems.append(name+': changed surface count')
            for sp,rp in zip(sm['primitives'],rm['primitives']):
                for attr,index in sp['attributes'].items():
                    if accessor_signature(source,sb,index)!=accessor_signature(runtime,rb,rp['attributes'][attr]):
                        problems.append(f'{name}/{sm["name"]}: changed {attr}')
                if accessor_signature(source,sb,sp['indices'])!=accessor_signature(runtime,rb,rp['indices']):
                    problems.append(name+': changed triangle indices')
                if rp.get('targets'):problems.append(name+': runtime still has morph buffers')
                if not sp.get('targets'):continue
                part=layout['parts'][sm['name']]
                count=source['accessors'][sp['attributes']['POSITION']]['count']
                for frame,target in zip(sm['extras']['targetNames'],sp['targets']):
                    expected=decode_floats(source,sb,target['POSITION'])
                    pose=part['frames'][frame]
                    if pose < 0:
                        gap=max(map(abs,expected),default=0.)
                    else:
                        offset=(part['row']+pose*part['rows'])*layout['width']*8
                        values=struct.unpack_from(f'<{count*4}e',texture,offset)
                        gap=max((abs(expected[3*i+j]-values[4*i+j]) for i in range(count) for j in range(3)),default=0.)
                    worst=max(worst,gap);frames+=1
                    if gap>.002:problems.append(f'{name}/{sm["name"]}/{frame}: pose differs by {gap}')
        print('ACTIVITY_POSE_CHECK',name,'triangles',triangle_count(runtime),flush=True)
    for problem in problems:print('ACTIVITY_POSE_FAIL',problem)
    print('ACTIVITY_POSE_VALIDATION', 'FAIL' if problems else 'PASS', 'assets',len(names),'frames',frames,'worst_position_error',worst)
    return int(bool(problems))
if __name__=='__main__':sys.exit(main())
