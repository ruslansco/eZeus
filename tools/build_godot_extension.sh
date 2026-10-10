#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}/.."
# Independent output directories keep concurrent development builds from sharing objects.
build_root="${EZEUS_GODOT_BUILD_DIRECTORY:-$PWD/build-godot}"
mkdir -p -- "$build_root"
build_root="${build_root:A}"
/usr/bin/python3 tools/prepare_godot_dependencies.py
cmake -S . -B "$build_root" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DEZEUS_BUILD_GODOT_EXTENSION=ON -DEZEUS_GODOT_OUTPUT_DIRECTORY="$build_root/staged-extension"
ninja -C "$build_root" ezeus_godot -j 8
/usr/bin/python3 tools/prepare_godot_dependencies.py --install-staged "$build_root/staged-extension/libezeus_godot.dylib"
