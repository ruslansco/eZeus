#!/usr/bin/env python3
"""Native healer regression linked against the installed, signed extension."""
import hashlib
from pathlib import Path
import shlex
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def main():
    protected = [REPO / 'Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez',
                 REPO / 'settings.txt', REPO.parent / 'settings.txt',
                 REPO / 'numbers.txt', REPO.parent / 'numbers.txt']
    before = {path: digest(path) for path in protected}
    try:
        with tempfile.TemporaryDirectory(prefix='ezeus-plague-healer-') as temporary:
            executable = Path(temporary) / 'plague-healer'
            includes = shlex.split(subprocess.check_output(['pkg-config', '--cflags', 'sdl2', 'SDL2_image', 'SDL2_ttf', 'SDL2_mixer'], text=True))
            subprocess.run(['c++', '-std=c++17', '-O1', '-I', str(REPO), *includes,
                            str(REPO / 'tests/plague_healer_smoke.cpp'),
                            str(REPO / 'godot/bin/libezeus_godot.dylib'),
                            '-Wl,-rpath,' + str(REPO / 'godot/bin'), '-o', str(executable)], check=True)
            subprocess.run(['codesign', '--force', '--sign', '-', str(executable)], check=True)
            for lang in ('en', 'ru'):
                subprocess.run([str(executable), str(REPO), lang], cwd=REPO, timeout=60, check=True)
    finally:
        if before != {path: digest(path) for path in protected}:
            raise RuntimeError('Protected save, settings or number tables changed')
        print('Plague healer regression: protected save/settings/numbers unchanged.', flush=True)

if __name__ == '__main__':
    main()
