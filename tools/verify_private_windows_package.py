#!/usr/bin/env python3
"""Check transfer contents and hashes, not Windows execution."""
import argparse
import hashlib
import json
from pathlib import Path
from pe_runtime import closure

def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as file:
        while block:=file.read(1048576):h.update(block)
    return h.hexdigest()

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('kit',type=Path)
    parser.add_argument('--refresh-manifest',action='store_true')
    args=parser.parse_args();root=args.kit.resolve();manifest=root/'package-manifest.json'
    if args.refresh_manifest:
        data=json.loads(manifest.read_text());data['files']=[{'path':p.relative_to(root).as_posix(),'bytes':p.stat().st_size,'sha256':digest(p)} for p in sorted(root.rglob('*')) if p.is_file() and p!=manifest];data['total_bytes']=sum(r['bytes'] for r in data['files']);manifest.write_text(json.dumps(data,indent=2)+'\n')
    data=json.loads(manifest.read_text());expected={r['path'] for r in data['files']}
    actual={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p!=manifest}
    if expected!=actual:raise RuntimeError('Package file list differs from manifest')
    for row in data['files']:
        path=root/row['path']
        if path.stat().st_size!=row['bytes'] or digest(path)!=row['sha256']:raise RuntimeError('File checksum differs: '+row['path'])
        lower=row['path'].lower()
        # Original campaign scenario files may use .sav inside Adventures; they
        # are development content, distinct from personal Save directories.
        permitted_runtime=lower.startswith('ezeus/godot/.godot/imported/') or lower in ['ezeus/godot/.godot/uid_cache.bin','ezeus/godot/.godot/global_script_class_cache.cfg','ezeus/godot/.godot/extension_list.cfg']
        if lower.endswith('.dylib') or (lower.endswith('.sav') and not lower.startswith('adventures/')) or ('/.godot/' in lower and not permitted_runtime) or lower.endswith(('settings.cfg','.md5')):raise RuntimeError('Unexpected platform/player artifact: '+row['path'])
        if lower.endswith('.ez') and lower!='ezeus/save/hippodamus/claude-testing-adventure.ez':raise RuntimeError('Unexpected saved city: '+row['path'])
    for relative in ['Play.cmd','Run checks.cmd','README.txt','eZeus/Bin/README.txt','eZeus/numbers.txt','eZeus/i15.e','eZeus/interface.e','eZeus/Zeus_Text.xml','eZeus/Zeus_Text_ru.xml','eZeus/godot/project.godot','Third-party notices/Art/monsters/anatomy-v3/ATTRIBUTION.md']:
        if not (root/relative).is_file():raise RuntimeError('Required package item missing: '+relative)
    imports=closure(root/'eZeus/godot/bin')
    if not imports or any(not row['x64'] or row['missing_imports'] for row in imports):raise RuntimeError('DLL architecture/import check failed')
    print('PRIVATE_PACKAGE_VALIDATION PASS files='+str(len(actual))+' bytes='+str(data['total_bytes'])+' windows_execution_verified='+str(data['windows_execution_verified']))

if __name__=='__main__':main()
