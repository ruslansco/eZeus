#!/usr/bin/env python3
"""Local macOS development dependencies; never patches Homebrew's installed libraries."""
from pathlib import Path
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
ROOT = REPO.parent
OUT = REPO / 'godot/bin'
SDL = ROOT / 'tools/sdl2-headless'

def run(*args):
    subprocess.run([str(a) for a in args], check=True)

def redirect(path):
    dependencies = subprocess.check_output(['otool', '-L', str(path)], text=True).splitlines()[1:]
    for line in dependencies:
        source = line.strip().split(' (')[0]
        name = Path(source).name
        if name in {'libSDL2-2.0.0.dylib','libSDL2_ttf-2.0.0.dylib','libSDL2_image-2.0.0.dylib','libSDL2_mixer-2.0.0.dylib'}:
            run('install_name_tool','-change',source,'@loader_path/'+name,path)
    run('codesign','--force','--sign','-',path)

def prepare():
    OUT.mkdir(parents=True, exist_ok=True)
    private = OUT / 'libSDL2-2.0.0.dylib'
    if not private.exists():
        if not (SDL / 'CMakeLists.txt').is_file():
            raise SystemExit('Missing tools/sdl2-headless: install official SDL release-2.32.10 as documented.')
        # SDL2's old header-copy CMake rule mishandles ampersands in paths.
        with tempfile.TemporaryDirectory(prefix='ezeus-sdl2-') as folder:
            temp = Path(folder); source = temp / 'source'; source.symlink_to(SDL, target_is_directory=True)
            run('cmake','-S',source,'-B',temp/'build','-G','Ninja','-DCMAKE_BUILD_TYPE=Release',
                '-DSDL_SHARED=ON','-DSDL_STATIC=OFF','-DSDL_TEST=OFF','-DSDL_VIDEO=OFF','-DSDL_AUDIO=OFF',
                '-DSDL_JOYSTICK=OFF','-DSDL_HAPTIC=OFF','-DSDL_SENSOR=OFF','-DCMAKE_OSX_ARCHITECTURES=arm64')
            run('ninja','-C',temp/'build','-j','6')
            shutil.copy2(temp/'build/libSDL2-2.0.0.dylib',private)
        run('install_name_tool','-id','@loader_path/'+private.name,private)
        run('codesign','--force','--sign','-',private)
    for name in ['SDL2_ttf','SDL2_image','SDL2_mixer']:
        source = Path('/opt/homebrew/opt') / name.lower() / 'lib' / ('lib'+name+'-2.0.0.dylib')
        target = OUT/source.name
        if target.exists():
            target.unlink()
        shutil.copy2(source,target)
        target.chmod(0o644)
        run('install_name_tool','-id','@loader_path/'+target.name,target)
        redirect(target)

if __name__ == '__main__':
    import sys
    if '--finalize' in sys.argv:
        redirect(OUT/'libezeus_godot.dylib')
    else:
        prepare()
