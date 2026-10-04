#!/bin/zsh
set -euo pipefail
cd -- "${0:A:h}/.."
/usr/bin/python3 tools/prepare_godot_dependencies.py
cmake -S . -B build-godot -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DEZEUS_BUILD_GODOT_EXTENSION=ON
ninja -C build-godot ezeus_godot -j 8
/usr/bin/python3 tools/prepare_godot_dependencies.py --finalize
