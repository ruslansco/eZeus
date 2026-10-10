# Common housing art — 6 October 2026

The seven active common-house models, common_house_<0-6>a, use a Godot-only
adapter in tools/godot_housing.py. Native eSmallHouse still selects the level;
footprints, occupancy, needs, evolution, prices, ID and saved data are unchanged.
The native sprite recipes, unused b variants, elite houses and live Blender scene
remain intact. Normal launch continues to use the embedded simulation.

## Appearance and scale

The first two levels replace the white conical starter hut and shorter flat box
with original compact dwellings. The first has wattle-and-daub walls, exposed oak
posts, layered brown reed thatch, an open timber door, household pots and firewood.
The second has higher mud-brick walls, limewash repairs, framed shutters and a
supported reed porch. Their front is model +Y; street_facing.gd turns their
entrances toward native roads without changing placement orientation or tiles.

Levels 2–6 retain the authored Greek domestic geometry from
art/common_house/levels.py: plastered homes, tiled homesteads, courtyards,
apartments and a richer townhouse. The adapter increases architectural height
in native tile units:

| Native level | Display name | Architecture height |
| --- | --- | ---: |
| 0 | Hut | 0.96 |
| 1 | Shack | 1.16 |
| 2 | Hovel | 1.36 |
| 3 | Homestead | 1.58 |
| 4 | Tenement | 1.84 |
| 5 | Apartment | 2.18 |
| 6 | Townhouse | 2.56 |

The previous starter hut was taller than level 1, and the previous apartment
was taller than the townhouse. The new architecture grows at every step.
Architecture scales vertically around the native foundation. Resident roots
move with their authored floor, with inverse local height scaling to preserve
anatomy; manifests record before/after resident heights. Footprint width/depth
stay unchanged. This is an art proportion pass, not new floors or occupancy rules.

Earth yards use muted neutral soil in irregular thin patches with exposed
terrain corners and small approach stones. The golden rectangular earth mat and
bottom slab are removed. Later paved courts use grey limestone. Brown thatch
and mud-brick diffuse/base colors are explicitly set, since the preview palette
cannot evaluate the original procedural textures. Original static smoke spheres
are excluded from the house silhouette; native sprite smoke loops are retained.

## Export contract

Use background Blender only:

~~~sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
  --python-exit-code 1 -P tools/export_godot_pilot.py -- \
  --asset common_house_0a --output-dir /private/tmp/housing-stage
~~~

Export all seven into a staging directory before installing their GLBs/manifests.
The adapter stores no source scene, sprite or atlas. execute_source suppresses
native atlas/render/save writers and captures the existing held working pose.
Use only local source seeds; never simulation RNG. godot_asset_sources.py
registers the active family for future background exports.

godot/data/housing_art.json records height/provenance/geometry contracts.
The exporter allocates 24,000 source vertices (22,000 for the ornamented
townhouse, allowing disconnected-geometry headroom), with a five-percent
allocation tolerance. CityPalette colors and compatible PBR batching remain.
Both UV sets are retained; the second currently duplicates the generated planar
coordinates. Imported reduced LODs are mandatory. These are preview materials,
not a full procedural material bake or production performance acceptance.

Import models, run validate_housing_art.gd, and update only these seven entries
with its explicit --write-baseline option after an intended art change.
tools/review_housing_art.py opens one owned disposable Metal preview, protects
the designated save/preferences/native source artwork, checks native placement
and level-model replacement and captures the family, first levels and city.
The existing validate_housing.gd covers native area placement, prices and undo.
Current verified evidence and limits are in GODOT_VALIDATION.md.

## Remaining work

User visual acceptance, complete material baking, animated household tasks,
additional appearance variants and sustained minimum-Mac profiling remain
pending. Source-derived higher levels retain needs_evidence provenance.
This pass changes common housing only; native elite housing keeps its models.
