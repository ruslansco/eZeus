#!/usr/bin/env python3
"""Turn the LOD guard (godot/scripts/lod_guard.gd) on for the development building models.

Godot's automatic mesh LODs can delete a model's roof at ordinary zoom-out (maintenance office, hospital ...). The guard is
an import script: it measures each surface's LODs and replaces the damaging ones with vertex-clustering LODs. This tool sets
`import_script/path` in the models' .import files; the models are then re-imported by Godot:

    python3 tools/apply_lod_guard.py                 # every non-character model
    python3 tools/apply_lod_guard.py --only maintenance_office hospital
    python3 tools/apply_lod_guard.py --remove        # back to Godot's LODs
    godot --headless --path godot --import          # re-import the changed files

Characters (walkers, animals, heroes, monsters, gods) and goods are left alone. Re-running is a no-op. A fresh Blender
export leaves the .import file as it is, so the guard stays on for it.
"""
import argparse
import re
import sys
from pathlib import Path

MODELS = Path(__file__).resolve().parents[1] / 'godot/assets/models'
SCRIPT = 'res://scripts/lod_guard.gd'
SKIP = ('walker_', 'animal_', 'hero_', 'monster_', 'god_', 'good_')
SETTING = re.compile(r'^import_script/path=.*$', re.M)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--only', nargs='+', help='Model names (without .glb) to change')
    parser.add_argument('--remove', action='store_true')
    args = parser.parse_args()
    wanted = f'import_script/path="{"" if args.remove else SCRIPT}"'
    changed = 0
    for path in sorted(MODELS.glob('*.glb.import')):
        name = path.name[:-len('.glb.import')]
        if args.only is not None and name not in args.only:
            continue
        if args.only is None and name.startswith(SKIP):
            continue
        text = path.read_text()
        if not SETTING.search(text):
            sys.exit(f'{path.name}: no import_script/path setting to change')
        updated = SETTING.sub(wanted, text)
        if updated != text:
            path.write_text(updated)
            changed += 1
    print(f'{changed} import files changed ({"guard removed" if args.remove else "guard on"})')


if __name__ == '__main__':
    main()
