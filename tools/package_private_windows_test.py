#!/usr/bin/env python3
"""Private development kit; explicit resources, no user saves or Mac binaries.

Requires the separately compiled x64 extension/dependencies and a checksum-proven
official Godot archive. Outputs a manifest and source/license evidence. Does not
publish, mutate the live game, or imply Windows runtime acceptance.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import zipfile
from pe_runtime import closure

REPO=Path(__file__).resolve().parents[1]
WORKSPACE=REPO.parent
FIXTURE=REPO/'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez'

def digest(path,algorithm='sha256'):
    h=hashlib.new(algorithm)
    with path.open('rb') as file:
        while block:=file.read(1024*1024):h.update(block)
    return h.hexdigest()

def copy_file(source,target):
    target.parent.mkdir(parents=True,exist_ok=True)
    # Copy-on-write on this Mac: imported metadata can never write through to
    # original files. Other platforms fall back to independent ordinary copies.
    if sys.platform=='darwin':
        library=ctypes.CDLL('/usr/lib/libSystem.B.dylib',use_errno=True)
        library.clonefile.argtypes=[ctypes.c_char_p,ctypes.c_char_p,ctypes.c_int]
        if library.clonefile(os.fsencode(source),os.fsencode(target),0)==0:return
    shutil.copy2(source,target)

def add_tree(source,target,skip=()):
    for root,dirs,files in os.walk(source):
        dirs[:]=[d for d in sorted(dirs) if d not in skip and not d.startswith('.')]
        for name in sorted(files):
            file=Path(root)/name
            if name.startswith('.') or file.is_symlink():continue
            copy_file(file,target/file.relative_to(source))

def pe_x64(path):
    with path.open('rb') as file:
        data=file.read(64)
        if data[:2]!=b'MZ':return False
        file.seek(int.from_bytes(data[60:64],'little'));head=file.read(6)
        return head[:4]==b'PE\0\0' and int.from_bytes(head[4:6],'little')==0x8664

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--dll-directory',type=Path,required=True)
    parser.add_argument('--godot-archive',type=Path,required=True)
    parser.add_argument('--godot-checksums',type=Path,required=True)
    parser.add_argument('--dependency-source',type=Path,required=True)
    parser.add_argument('--extra-notices',type=Path,required=True)
    parser.add_argument('--prepared-imports',type=Path)
    parser.add_argument('--scenario-manifest',type=Path,help='Explicit private scenario export to include, never player saves')
    parser.add_argument('--output',type=Path,default=REPO/'dist-private/CityBuilder-Windows-Test')
    parser.add_argument('--zip',action='store_true')
    args=parser.parse_args()
    protected={p:digest(p) if p.is_file() else None for p in [FIXTURE,REPO/'settings.txt',WORKSPACE/'settings.txt']}
    archive=args.godot_archive.resolve()
    expected=next(line.split()[0] for line in args.godot_checksums.read_text().splitlines() if line.split()[-1].lstrip('*')==archive.name)
    if digest(archive,'sha512')!=expected:raise RuntimeError('Official Godot checksum mismatch')
    dlls=sorted(args.dll_directory.glob('*.dll'))
    required={'ezeus_godot.dll','SDL2.dll','SDL2_ttf.dll','SDL2_image.dll','SDL2_mixer.dll'}
    if not required<={d.name for d in dlls} or not all(pe_x64(d) for d in dlls):raise RuntimeError('Complete x64 extension/dependencies required')
    dependencies=closure(args.dll_directory)
    if any(row['missing_imports'] for row in dependencies):raise RuntimeError('Unresolved non-system DLL imports: '+str(dependencies))
    output=args.output.resolve()
    if output.exists():raise RuntimeError('Output exists; preserve it and choose a new output folder')
    output.mkdir(parents=True)
    kit=output/'CityBuilder';kit.mkdir()
    engine=kit/'eZeus';engine.mkdir()
    try:
        print('PACKAGE_STAGE runtime and native resources',flush=True)
        add_tree(REPO/'godot',engine/'godot',skip=['.godot','captures','bin','profile_baselines'])
        # Development engine assets remain explicit and preserve their names.
        for name in ['Adventures','Sanctuaries','Pyramids','fonts','text']:
            if (REPO/name).is_dir():add_tree(REPO/name,engine/name)
        if args.scenario_manifest:
            scenario=json.loads(args.scenario_manifest.read_text())
            source=Path(scenario['campaign'])
            for name,expected_hash in scenario['files'].items():
                file=source/name
                if file.is_symlink() or digest(file)!=expected_hash:raise RuntimeError('Scenario export hash mismatch: '+str(file))
                copy_file(file,engine/'Adventures'/source.name/name)
            (engine/'first-light-harbor-test.json').write_text(json.dumps({'id':scenario['id'],'version':scenario['version'],'ships_in_release':False,'rights_status':'needs_evidence','campaign':source.name,'files':scenario['files']},indent=2)+'\n')
        for name in ['numbers.txt','interface.e','i15.e','Zeus_Text.xml','Zeus_Text_ru.xml','Zeus_MM.xml','Zeus_MM_ru.xml','LICENSE.md','README.md']:
            copy_file(REPO/name,engine/name)
        (engine/'Bin').mkdir();(engine/'Bin/README.txt').write_text('Native resource-path anchor. No SDL executable is launched.\n')
        copy_file(FIXTURE,engine/'Save/Hippodamus'/FIXTURE.name)
        for name in ['Audio','DATA','Model','Adventures']:
            add_tree(WORKSPACE/name,kit/name,skip=['_disabled','Original','Backup','Backups'])
        # Active loose UI atlases/loading artwork: backups stay in the workspace.
        for name in ['15','Zeus_Data_Images']:
            if (WORKSPACE/'Textures'/name).is_dir():add_tree(WORKSPACE/'Textures'/name,kit/'Textures'/name)
        binaries=engine/'godot/bin';binaries.mkdir()
        for file in dlls:copy_file(file,binaries/file.name)
        copy_file(REPO/'presentation/godot/ezeus.gdextension',binaries/'ezeus.gdextension')
        if args.prepared_imports:
            prepared=engine/'godot/.godot';prepared.mkdir()
            # Imported scenes/textures/UID lookup are runtime resources. Exclude
            # editor state, filesystem indexes, pipeline caches and import hashes.
            entries=0
            for source in sorted((args.prepared_imports/'imported').iterdir()):
                if source.is_file() and source.suffix!='.md5':
                    copy_file(source,prepared/'imported'/source.name);entries+=1
            for name in ['uid_cache.bin','global_script_class_cache.cfg','extension_list.cfg']:
                copy_file(args.prepared_imports/name,prepared/name)
            (engine/'godot/prepared-runtime.json').write_text(json.dumps({'godot':'4.6.3','desktop_formats':True,'imported_resources':entries,'windows_execution_verified':False,'scope':'Prepared platform-neutral scenes/textures and UID lookup, not editor/pipeline preferences.'},indent=2)+'\n')
        runtime=kit/'tools/godot';runtime.mkdir(parents=True)
        with zipfile.ZipFile(archive) as zipped:
            for member in zipped.infolist():
                path=Path(member.filename)
                if path.is_absolute() or '..' in path.parts:raise RuntimeError('Unsafe official archive entry')
                zipped.extract(member,runtime)
        if not pe_x64(runtime/'Godot_v4.6.3-stable_win64.exe'):raise RuntimeError('Wrong Godot executable architecture')
        add_tree(REPO/'tools/windows_package',kit)
        print('PACKAGE_STAGE source and third-party notices',flush=True)
        sources=kit/'Source/eZeus'
        excluded={'godot','.git','build','build-godot','build-godot-windows','build-windows-cross','build-content-research','build-portraits','dist-private','Save','Bin','__pycache__'}
        for root,dirs,files in os.walk(REPO):
            relative=Path(root).relative_to(REPO)
            dirs[:]=[d for d in sorted(dirs) if d not in {'.git','__pycache__'} and not(relative==Path('.') and d in excluded)]
            for name in files:
                path=Path(root)/name
                if path.suffix.lower() in {'.cpp','.h','.hpp','.c','.cmake','.py','.ps1','.json','.md'} or name in {'CMakeLists.txt','.gitignore'}:
                    if not path.is_symlink():copy_file(path,sources/relative/name)
        # The Godot presentation source/assets already live in the playable tree.
        notices=kit/'Third-party notices';notices.mkdir()
        copy_file(args.godot_checksums,notices/'Godot-SHA512-SUMS.txt')
        for root,dirs,files in os.walk(args.dependency_source):
            dirs[:]=[d for d in dirs if d!='.git']
            for name in files:
                upper=name.upper()
                if upper.startswith(('LICENSE','COPYING','COPYRIGHT')) or upper in {'FTL.TXT','GPLV2.TXT'}:
                    path=Path(root)/name
                    if not path.is_symlink():copy_file(path,notices/'SDL and codecs'/path.relative_to(args.dependency_source))
        bindings=WORKSPACE/'tools/godot-cpp'
        copy_file(bindings/'LICENSE.md',notices/'godot-cpp-LICENSE.md')
        add_tree(args.extra_notices,notices/'Runtime licenses')
        # Retain the authored models' existing attribution/reference records.
        for relative in ['monsters/anatomy-v3/ATTRIBUTION.md','monsters/anatomy-v3/gallery/ATTRIBUTION.md','monsters/REFERENCE_CATALOG.md']:
            source=WORKSPACE/'art'/relative
            if source.is_file():copy_file(source,notices/'Art'/relative)
        (notices/'Sources.json').write_text(json.dumps({
            'engine':'https://github.com/MaurycyLiebner/eZeus','engine_license':'GPL-3.0','engine_source':'Source/eZeus plus eZeus/godot',
            'godot':'https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable','godot_license':'MIT','godot_archive_sha512':expected,
            'godot_cpp_revision':'507ed9d840c01a3c5b2a39af8bb4000bfac30bf5','godot_cpp':'https://github.com/godotengine/godot-cpp',
            'SDL2':'https://github.com/libsdl-org/SDL/tree/release-2.32.10','SDL2_image':'https://github.com/libsdl-org/SDL_image/tree/release-2.8.12',
            'SDL2_ttf':'https://github.com/libsdl-org/SDL_ttf/tree/release-2.24.0','SDL2_mixer':'https://github.com/libsdl-org/SDL_mixer/tree/release-2.8.2',
            'gcc_runtime':'GPL with GCC Runtime Library Exception; https://www.gnu.org/licenses/gcc-exception-3.1.html',
            'scope':'Private development test with retained development resources; not a cleared public/Steam package.'},indent=2)+'\n')
        (kit/'windows-dependencies.json').write_text(json.dumps(dependencies,indent=2)+'\n')
        print('PACKAGE_STAGE checksums',flush=True)
        rows=[]
        for path in sorted(kit.rglob('*')):
            if path.is_file():rows.append({'path':path.relative_to(kit).as_posix(),'bytes':path.stat().st_size,'sha256':digest(path)})
        manifest={'schema':1,'windows_execution_verified':False,'build':'Windows x64 cross-compiled on Mac','files':rows,'total_bytes':sum(row['bytes'] for row in rows)}
        (kit/'package-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        if args.zip:
            zip_path=output.with_suffix('.zip')
            if zip_path.exists():raise RuntimeError('Archive exists; preserve it and use a new output')
            print('PACKAGE_STAGE archive',flush=True)
            with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as zipped:
                for path in sorted(kit.rglob('*')):
                    if path.is_file():zipped.write(path,path.relative_to(output))
            zip_path.with_suffix('.zip.sha256').write_text(digest(zip_path)+'  '+zip_path.name+'\n')
            print('PACKAGE_ARCHIVE',zip_path,zip_path.stat().st_size,flush=True)
        print('PACKAGE_READY',kit,'files',len(rows),'bytes',manifest['total_bytes'],flush=True)
    finally:
        for path,before in protected.items():
            if (digest(path) if path.is_file() else None)!=before:raise RuntimeError('Protected source changed: '+str(path))

if __name__=='__main__':main()
