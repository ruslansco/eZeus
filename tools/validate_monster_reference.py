#!/usr/bin/env python3
"""Decode every new monster's full pose envelope, clips, palette and source probes."""
import argparse,json,math
from pathlib import Path
from optimize_glb_memory import read_glb,MODELS
from bake_walker_vat import decode_floats

NAMES='cyclops talos hector minotaur satyr medusa maenads harpies calydonianboar cerberus chimera sphinx dragon echidna scylla kraken'.split()
parser=argparse.ArgumentParser()
parser.add_argument('--models',type=Path,default=MODELS)
parser.add_argument('--output',type=Path,default=MODELS.parents[1]/'captures/monster-reference-validation.json')
parser.add_argument('--only',nargs='+',choices=NAMES,help='species names for an individual art revision')
args=parser.parse_args();checks=[];records={}
def check(ok,text):
 checks.append({'okay':bool(ok),'description':text})
 print('MONSTER_REFERENCE_CHECK','PASS' if ok else 'FAIL',text,flush=True)
for name in args.only or NAMES:
 asset='walker_'+name;contract=json.loads((args.models/(asset+'.json')).read_text());m=contract['monster']
 doc,binary=read_glb(args.models/(asset+'.glb'));vertices=tris=0;envelope={};finite=True;uv=True;complete=True;surfaces=0
 for mesh in doc['meshes']:
  aliases={label:i for i,j in enumerate(mesh.get('extras',{}).get('targetNames',[])) for label in j.split('|')}
  for p in mesh['primitives']:
   surfaces+=1;a=p['attributes'];base=decode_floats(doc,binary,a['POSITION']);vertices+=len(base)//3
   tris+=doc['accessors'][p['indices']]['count']//3
   uv=uv and all(x in a for x in ('NORMAL','COLOR_0','TEXCOORD_0','TEXCOORD_1'))
   finite=finite and all(math.isfinite(v) for v in base)
   for clip,count in m['clips'].items():
    for frame in range(count):
     label=f'{clip}_{frame:02d}';posed=base[1::3]
     if label in aliases:
      delta=decode_floats(doc,binary,p['targets'][aliases[label]]['POSITION'])
      finite=finite and all(math.isfinite(v) for v in delta)
      posed=[b+d for b,d in zip(posed,delta[1::3])]
     elif not (clip=='walk' and frame==0):complete=False
     lo,hi=min(posed),max(posed)
     prev=envelope.get(label,[lo,hi]);envelope[label]=[min(lo,prev[0]),max(hi,prev[1])]
 check(m['revision']=='monster_reference_v1' and m.get('design_revision')=='monster_anatomy_v3' and m['species']==name,asset+' uses its own v3 anatomical geometry')
 check(contract['vertices']<=m['vertex_budget'] and vertices<=m['imported_vertex_budget'] and tris<=m['triangle_budget'],asset+f' stays in geometry budget ({vertices} vertices/{tris} triangles)')
 check(uv and finite,asset+' retains both UV sets, vertex palette and finite geometry for every pose')
 check(complete and len(envelope)==114,asset+' resolves all 114 walk/idle/fight/fight2/die frames')
 neutral=envelope['idle_00'];peak=max(v[1] for k,v in envelope.items() if not k.startswith('die'))
 check(1.65<=neutral[1]-neutral[0]<=2.20 and peak<2.455466,asset+f' is above citizen and below Zeus ({neutral[1]-neutral[0]:.3f}/{peak:.3f} tiles)')
 check(min(v[0] for v in envelope.values())>=-.025,asset+' remains grounded through the full pose envelope')
 check(envelope['die_29'][1] < neutral[1]*.72,asset+' ends in a lower grounded fallen pose')
 expected_heads={'cerberus':3,'chimera':3,'maenads':3,'harpies':2,'scylla':7}.get(name,1)
 check(m['heads']==expected_heads,asset+' preserves the species mouth count')
 probes=m['pose_probes']
 check(set(probes)==set(envelope) and all(p['root']==[0,0,0] for p in probes.values()),asset+' probes cover every pose without native root motion')
 check(all(len(p['mouths'])==m['heads'] and len(p['feet'])==m['legs'] for p in probes.values()),asset+' keeps its individual mouth and foot anchors')
 if m['legs']:
  check(all(sum(abs(p[1]-.025)<.002 for p in probes[f'walk_{i:02d}']['feet'])>=max(1,m['legs']//2) for i in range(24)),asset+' keeps support feet planted throughout walking')
 records[asset]={'vertices':vertices,'triangles':tris,'surfaces':surfaces,'height':neutral[1]-neutral[0],'pose_peak':peak,'pose_low':min(v[0] for v in envelope.values()),'fallen':envelope['die_29'],'heads':m['heads'],'legs':m['legs']}
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps({'checks':checks,'models':records,'okay':all(c['okay'] for c in checks)},indent=2)+'\n')
print('MONSTER_REFERENCE_VALIDATION',len(checks),'PASS' if all(c['okay'] for c in checks) else 'FAIL')
raise SystemExit(0 if all(c['okay'] for c in checks) else 1)
