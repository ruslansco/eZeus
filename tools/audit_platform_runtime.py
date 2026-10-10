#!/usr/bin/env python3
"""Read-only platform evidence. Binary metadata is not a runtime acceptance test."""
import argparse
import json
from pathlib import Path
import re
import struct
import subprocess
import sys
from pe_runtime import closure

REPO=Path(__file__).resolve().parents[1]

def version(value): return tuple(int(part) for part in value.split('.'))

def mac_artifacts(directory, target):
    rows=[]
    for path in sorted(directory.glob('*.dylib')):
        load=subprocess.check_output(['otool','-l',str(path)],text=True)
        minimum=re.search(r'\bminos\s+(\S+)',load)
        if minimum is None:minimum=re.search(r'LC_VERSION_MIN_MACOSX\s+cmdsize\s+\d+\s+version\s+(\S+)',load)
        arch=subprocess.check_output(['lipo','-archs',str(path)],text=True).strip().split()
        dependencies=subprocess.check_output(['otool','-L',str(path)],text=True).splitlines()[2:]
        external=[]
        for line in dependencies:
            name=line.strip().split(' (')[0]
            if name.startswith(('/System/','/usr/lib/')):continue
            if name.startswith(('@loader_path/','@rpath/')) and (directory/Path(name).name).is_file():continue
            external.append(name)
        minimum=minimum.group(1) if minimum else None
        rows.append({'file':path.name,'architectures':arch,'minimum_os':minimum,
                     'satisfies_target':minimum is not None and version(minimum)<=version(target),
                     'external_dependencies':external})
    return {'platform':'macos.arm64','proposed_os_target':target,'artifacts':rows,
            'binary_os_floor':max((r['minimum_os'] for r in rows if r['minimum_os']),key=version,default=None),
            'target_ready':bool(rows) and all(r['satisfies_target'] and 'arm64' in r['architectures'] and not r['external_dependencies'] for r in rows),
            'scope':'Mach-O metadata only; oldest supported Mac/OS and complete standalone runtime still require launch tests.'}

def windows_artifacts(directory):
    rows=closure(directory)
    expected={'ezeus_godot.dll','SDL2.dll','SDL2_ttf.dll','SDL2_image.dll','SDL2_mixer.dll'}
    present={r['file'] for r in rows}
    return {'platform':'windows.x86_64','artifacts':rows,'missing':sorted(expected-present),
            'target_ready':bool(rows) and expected<=present and all(r['x64'] and not r['missing_imports'] for r in rows),
            'scope':'PE architecture, principal DLLs and static non-system import closure; dynamic loader behavior, target OS/API sets, launch, saves and graphics still require Windows execution.'}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--platform',choices=['mac','windows'],default='windows' if sys.platform=='win32' else 'mac')
    parser.add_argument('--directory',type=Path,default=REPO/'godot/bin')
    parser.add_argument('--mac-target',default='14.0')
    parser.add_argument('--output',type=Path)
    parser.add_argument('--require-ready',action='store_true')
    args=parser.parse_args()
    result=mac_artifacts(args.directory,args.mac_target) if args.platform=='mac' else windows_artifacts(args.directory)
    text=json.dumps(result,indent=2)+'\n'
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(text)
    print(text)
    if args.require_ready and not result['target_ready']:raise SystemExit(1)

if __name__=='__main__':main()
