# Surrounding landscape and camera limits — 2 October 2026

The native board now sits within cosmetic countryside and a continuous ocean.
Exposed land edges continue into gently rising terrain, woodland and distant
limestone hills. Water edges open into sea. An inland board gets countryside
and a ground horizon instead. These meshes replace the visible cut edge and
grey void; they do not enlarge the playable map or add defensive walls.

## Native boundary

`scripts/horizon.gd` owns the sea/ground horizon and `surroundings.gd` owns the
outside terrain and trees. Native cells, including irregular holes, remain the
exact same Dictionary. An occupancy prefix/quadtree excludes every native cell
from scenery geometry. There are no collision objects, navigation regions,
building records or simulation commands in the scenery. Native picking and
placement stay authoritative. Only the camera can sample the cosmetic height.

The scenery's integer coordinates are native **corners**, one half-tile above
the native centre coordinates. `world()` performs the same centre/reversed-Z
conversion as the terrain. Boundary vertices meet the highest adjacent native
land profile exactly; water rim vertices meet the submerged native ground.
Stitched adaptive edges share vertices at changes of mesh resolution. The
indexed mesh retains one-unit detail at the rim, eight-unit detail in nearby
hills, and coarser distant/water detail. Submerged exterior seabed is omitted.

The coarse field stores land fraction, vegetation, altitude and distance from
the exposed native boundary. Distance uses the actual boundary seed position.
Far land/water fractions are smoothed; perturbations act only on coastal
transitions, avoiding random polygon islands in open sea. Hills taper before
the distant coast. Native land at sea level must not receive a thin overlay of
ocean: the ocean shader masks its near land continuation. Native coast masks
and sea colours are reused. Pixel derivatives attenuate normal waves at distance
in both water shaders, avoiding distant shimmer.

The noise has a fixed local seed; never draw from `eRand`. Existing independent
forest meshes/materials supply a tapered woodland fringe, capped at 800 trees
and spatially batched. Background meshes cast no shadows. No original sprite,
new GLB or external art library is required. The underlying campaign map and
other development content retain the production roadmap's provenance gates.

Native vegetation continues only 4–18 tiles past the rim (`_vertex` cover
fade); beyond that the shared green palette shades open country. The old
260–340 tile fade stretched the nearest edge tile's forest into long stripes.

## Map border — 3 October 2026

`scripts/map_border.gd` (a child of `horizon.gd`) draws a dashed white border
around the playable board, in the manner of Cities: Skylines. It traces the
outside edges of the native cells, keeps the longest loop (interior holes get no
border), straightens the one-tile staircase of diamond boards through edge
midpoints with Douglas–Peucker (0.75 tiles), and insets the loop 0.7 tiles.
The ribbon is sampled every half tile on the higher of native ground and native
water (+0.04). `map_border.gdshader` is unshaded and depth-tested, so buildings
and hills occlude it, and widens the ribbon with camera distance so it keeps
its on-screen weight (dash period 3.4 tiles). It has no collision and reads no
simulation state beyond the tile Dictionary; it hides with the horizon on the
world map. The designated city has a four-corner outline of 637 tiles.

Outside the border everything is darker and slightly desaturated, like unowned
land in Cities: Skylines. `map_border.gd` publishes its straight loop (world XZ)
as the shader globals `map_border_points` (an RG float texture), `map_border_count`
and `map_outside_tint` (strength, 1.0; set 0 to switch the tint off), declared in
`project.godot`. `shaders/map_outside.gdshaderinc` does a point-in-polygon test
with a 1.2-tile soft edge and is used by the ground, countryside, ocean, native
water and tree shaders, so the tint edge is the dashed line, not the tile
staircase. With no loop (headless tools) nothing is tinted. The loop is capped
at 256 corners in the shader; the designated city has 4.

## Camera and lifetime

`OrbitCamera.configure_map()` is the single source of the maximum distance:
`max(60, longest_map_dimension * MAP_ZOOM_SCALE)`, with the scale currently
**1.05**. The designated city limit is **239.4**, down from **364.8** (34.4%).
Wheel and trackpad magnification use the same player limit. Crossing it outward
now starts the live city-to-world flight (`GODOT_WORLD_ATLAS.md`); its temporary
cinematic pose is outside ordinary player limits and is restored afterwards.
Home uses 0.95 of the map dimension, preserving the full-city overview without
opening the world. Closest zoom and Q/E/R/F are intact.

Scenery is built once when a city scene loads; ordinary construction, language
changes and snapshots do not regenerate it. Coast-field textures update in
place. Future terrain editing that changes exposed elevations/water needs an
explicit scenery rebuild; changing the visual background must never create
native tiles. Campaign reloads reconstruct the whole scene normally.

## Verification and remaining work

Run `python3 tools/review_surroundings.py --lang en` (or `ru`; `--headless`
skips captures). It uses only the designated test city and hashes the save and
both settings files. Checks cover actual submitted rim vertices, native-cell
exclusion, geometry/tree caps, wheel/pinch/Home limits, unchanged native state,
and a separate tiny inland presentation fixture derived from a real test tile.
It captures five orbit angles, a low horizon and a close forest boundary, and
checks that the map border's corners lie on native tiles, that it runs around
the whole board and that the outside tint uses the same loop.

`captures/surroundings-review.json` records measured setup time and counts; see
`GODOT_VALIDATION.md` for completed evidence. The CPU setup is a one-time load
cost, not a frame-time result. Wider campaign coast/height coverage, per-map art
direction, cached/asynchronous generation and minimum-Mac profiling remain
pending. Keep the native map and current performance contracts intact.
