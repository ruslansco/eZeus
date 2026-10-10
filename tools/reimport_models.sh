#!/bin/sh
# Force Godot to re-import the named development models (e.g. after changing an import script):
#   tools/reimport_models.sh maintenance_office hospital
# Deletes each model's import stamp and touches the GLB; then runs a headless import. With no names, nothing is done.
cd "$(dirname "$0")/../godot" || exit 1
for name in "$@"; do
  dest=$(sed -n 's/^path="res:\/\/\.godot\/imported\/\(.*\)\.scn"/\1/p' "assets/models/$name.glb.import")
  [ -n "$dest" ] && rm -f ".godot/imported/$dest.md5"
  touch "assets/models/$name.glb"
done
[ $# -gt 0 ] && ../../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path . --import
