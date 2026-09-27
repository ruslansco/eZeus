# eZeus HD terrain atlas builder

This package stages exact-size RGBA replacements for the existing 60 px terrain
atlases. It currently remasters the requested first pass:

- `zeusLand1`, sprites 106–163: dry Aegean land
- `zeusLand3`, sprites 99–189: Aegean water

The script reads the authoritative rectangles from `spriteData/zeusLand160.h`
and `spriteData/zeusLand360.h`. It maps a periodic material through the inverse
2:1 dimetric transform, applies the exact 116×60 diamond mask, and extends edge
RGB four pixels into transparent pixels while preserving alpha.

## Build and inspect

From the repository root:

```bash
python3 eZeus/tools/terrain_remaster/build_terrain_atlases.py
```

The staged atlases are written to `eZeus/tools/terrain_remaster/output/`. They
retain the source dimensions (`4084×1116` and `4060×938`) and do not overwrite
the live game textures.

## Install

After inspecting the staged sheets:

```bash
python3 eZeus/tools/terrain_remaster/build_terrain_atlases.py --install
```

Installation first saves the original sheets in
`Textures/60/terrain_remaster_backup/`, then copies the generated files into
`Textures/60/` under the exact names loaded by `ebinaryimageloader.cpp`.

## Atlas-padding limitation

The current headers pack many 116 px sprite rectangles directly adjacent to one
another. A drop-in atlas with unchanged dimensions and coordinates cannot add a
literal gutter between those rectangles. This builder provides four-pixel RGB
extrusion inside transparent corners and keeps matching material color at the
diamond tips. True gutters require repacking every sprite and regenerating both
sprite-data headers; that should be treated as a separate engine-format change.
