# Continuous terrain, elevation and shores — 30 September 2026

## Hillside limestone finish — 3 October 2026

Exposed native blocked slopes and vertical side faces now use original procedural
limestone in `shaders/terrain_rock.gdshaderinc`: irregular bedding, weathering,
fractures and restrained relief. Three world-space projections avoid stretching
the horizontal grass texture down a cliff; derivative surface normals add relief
without moving any vertex. Inclination blends grass into exposed stone at upper
edges. Road paving and quarry surfaces take precedence. Ordinary ground,
walkable ramps and foundations retain their existing materials. Cosmetic steep
countryside uses the same limestone finish. Noise remains local and deterministic.

This is a material/shading pass: the native contours and generated geometry,
collision, height sampler, placement, feet and foundations are unchanged. No new
meshes, props, texture files, simulation observations or native RNG draws. The
extra rock sampling runs on classified native rock faces and steep countryside;
minimum-Mac GPU cost and wider campaign appearance remain unmeasured.

`python3 tools/review_hillsides.py` captures matched before/after cliff, ramp and
countryside views using the designated save, temporary preferences and an owned
preview watchdog. `hillside_finish=0` is a review-only material comparison switch;
normal games default to 1. See validation evidence for completed runs and limits.


The user prioritized the map's blocky appearance before the next interface slice.
This first terrain slice replaces the per-tile colour checkerboard with continuous
limestone soil, vegetation, sand and stone materials. It softens river corners,
adds wet banks and shallow-to-deep water colour, and restores forests to the
native forest cells. The following elevation slice joins native ramps and closes
cliff/outer-edge gaps with real 3D surfaces and softly shaded limestone sides.
The detail slice adds native mineral outcrops, continuous mineral soil and sparse
forest-edge understory, with explicit instance and distance budgets.

## Green ground palette — 3 October 2026

At the user's request the sandy limestone base gave way to green land. The
board (`ground.gdshader`) and the countryside (`surroundings.gdshader`) share
`shaders/terrain_palette.gdshaderinc`, so they meet without a seam:
- plain land: grazed grassland, yellower on dry rises, with bare earth patches;
- chopped forest/scrub: olive maquis ground;
- forest: moss and leaf litter;
- fertile meadow: the plain grassland, with no colour or weight of its own (a separate
  green read as flat patches with a dark fringe where it blended into plain land).
Sand stays on native beaches and wet banks; roads, minerals and cliffs are
unchanged. Large-scale variation uses two rotated noise lookups, because a
single lookup showed the seamless texture's blend skirt as straight bands.
Native flags, fertility and placement rules are untouched.

## Realistic water and shores — 3 October 2026

Native water (`water.gdshader`) and the open sea (`ocean.gdshader`) share
`shaders/water_surface.gdshaderinc`:
- colour by coast distance, from a sandy see-through edge to turquoise, deep blue
  and a darker open sea, with faint drifting caustics in the shallows;
- three layers of drifting noise ripples plus two swells, faded by pixel footprint
  at distance;
- low roughness, so the scene's sky reflects and the sun glitters;
- lapping foam: a thin contact line plus bands that run up the beach.
`coast_distance()` (terrain_common) is the bilinear field at the centre plus a 0.6-tile
diagonal low-pass (five taps), which removes the zigzag that staircase coasts left
in the contour; a one-tile channel stays open. Two noise scales shape coves and
a ragged edge. In `ground.gdshader`, banks vary in width (0.7–2.2 tiles) with a ragged
grass edge, and a darker, glossier wet-sand strip runs along the waterline. Native
water cells, altitudes and the field values stay unchanged. Catmull-Rom sampling
was tried and dropped, because the low-pass alone gave the same contour more cheaply
(the 65-distance review views rose from a minimum of 47 to 55 fps on the M4).

## Wider-looking streets — 3 October 2026

Native roads stay one tile; only their drawing changed. In `ground.gdshader` the
road mask's 0.5 level is the tile edge, so a straight road paves its whole tile
(before, the solid paving covered about 0.56 of it and faded out by 0.8), with soft
rounded outer corners. Paving is worn limestone slabs in staggered courses, with
dust patches, a light kerb stone along the edge and a shaded gutter inside it.
`scripts/walker_streets.gd` makes people easier to see:
- people (not gods, animals, boats or rite figures) are drawn 12% larger;
- on road tiles, moving walkers drift 0.17 tiles to the right of their direction of
  travel, so walkers passing in opposite directions use separate lanes. The offset
  is eased, is added only when drawing, and is zero in fights, afloat and off roads;
- a soft gold ring marks the person the mouse rests on.
The native position track (`native_position`, from/to) and every native rule are
unchanged. `--terrain-review road-after` runs time, captures a street between
buildings at distances 8/16, and checks the size, the lanes, the untouched track
and the hover ring.

## Setbacks, avenues and boulevards — 3 October 2026

- Setbacks (`scripts/street_setback.gd`): a building's model is drawn 0.12 tile in from
  each side that faces a road, at most 15% of a dimension in total. Footprints, picking
  and every native rule are unchanged. Walls, towers, gates, shore buildings, sanctuaries,
  monuments, agoras and the like keep their full size. The ground shader paves the freed
  strip with small setts (a pavement band where the road mask is 0.38–0.5). When a road is
  added or removed, the building transforms are rebuilt.
- Road kinds: the snapshot tile row has an appended column 8 (0 none, 1 road, 2 avenue,
  3 boulevard; column 4 keeps its 0/1 meaning). `validate_elevation.gd` checks it.
  The avenue and boulevard tiles are the medians the native tool lays beside its streets.
- The road texture is RGBA: R road, G dressed paving (a median or a street next to one),
  B median bed, A boulevard. Avenues get large pale dressed slabs with a dark border band
  and an olive-green bed. Boulevards get a lusher bed full of flowers.
  (`TerrainPresentation.road_pattern`).
- Street trees (`scripts/terrain_avenues.gd`, a forest-batch subclass): one tree every
  second median tile; a clipped olive on an avenue, a cypress on a boulevard.
- `--terrain-review road-after` lays one avenue and one boulevard near the focus. They exist
  in memory only; the save is never written. It captures them and checks the setbacks (all
  bounded) and the median tiles.

## Buildings face the street — 3 October 2026

`scripts/street_facing.gd` picks the quarter turn a building is drawn with, for the placement
ghost, area-drag pieces and the built city alike:
- The front looks at the longest stretch of road beside the footprint.
- The stored facing (the T key's choice) is kept when no road touches the building, and it
  breaks ties. With roads equally on several sides (all around a square building), T
  picks the street.
- Long footprints only turn end for end, so the model keeps its footprint.
- The SDL kit models are built to be seen from the +X/+Y corner, so +X and +Y are dressed
  faces and −X/−Y backs. `FRONTS` lists the door face where the kit has one (common houses
  from `art/common_house/levels.py`: 1a–3a +X, 5a–6a +Y, 0a and 4a their corner). Other
  models turn their dressed corner to the street, never their back.
- A quarter turn takes +X to +Y, as `sanctuaryQuarterTurns` does.
- Walls, gates, shore buildings, sanctuaries, monuments, the palace, vendor stalls and other
  engine-faced buildings keep their facing.
- The core's stored facing and every native rule are unchanged. Adding or removing a road
  re-turns its neighbours.
- `--terrain-review road-after` lays a row of houses beside a straight road (in memory
  only) and checks that every house with a known door touching a road shows its door to
  the longest road side.

## Native and presentation boundary

The source is still the designated city's 25,992 native tiles in its 228×227
bounding rectangle. No save, resource distribution, pathfinding, ownership,
construction eligibility, simulation height or tick rules are rewritten.
One tile is one Godot unit horizontally; native double-altitude units use the
existing 0.22 vertical scale. Camera orbit never rotates the native map.

`godot/scripts/terrain_presentation.gd` builds a shared floating-point field from
native flags: water 4, beach 2, fertile 8, forest 16, chopped forest 32, and the
existing stone/mineral bits. R is signed distance to the opposite water/land
class, bounded to eight tiles; G is vegetation, B stone, A native beach. A
separate R8 image retains roads. Both fields use the entire map's coordinate
system; all 32-tile sections share the same material and field textures. Noise
uses world coordinates and mipmaps rather than resetting at each tile or section.

Distances use a bounded, two-pass chamfer transform, including diagonals. Linear
sampling creates the coast contour between native cell centers; a small shared
noise offset softens its outline. Ground and water use the same contour function.
Native water centers remain water and land centers remain land. A cosmetic
one-cell water apron covers actual adjacent land cells and is clipped by that
contour. Unused bounding cells may hold texture padding, but never receive ground,
water geometry, collision or trees. Native water altitude is retained as a float.

The ground vertex shader depresses only native water cells to suggest a seabed;
water picking retains the native water plane. The coast contour and apron are
visual details, not changes to shipping, road or building rules.

## Elevation geometry and anchors

Native tile observations retain their original six columns and append two:
`[x, y, doubleAltitude, terrain, road, canBuild, geometryFlags, characterDoubleAltitude]`.
Geometry flags are elevation 1, walkable elevation 2, half slope 4 and non-road
building/foundation 8. These are read-only native getters. The original prefix
remains comparable with the SDL reference; a legacy six-column bridge snapshot
conservatively keeps flat terrain rather than inferring native slope eligibility.

`godot/scripts/terrain_geometry.gd` builds shared corner profiles from the actual
neighbor heights. Unoccupied native elevation cells receive 4×4 subdivisions;
ordinary ground, water and building foundations retain their exact flat native
heights. Matching slope edges share positions and lighting normals across terrain
sections. Discontinuous edges get vertical limestone side faces. Outer skirts
end 1.2 units below the lowest initial native height and occupy only the actual
map boundary; empty bounding cells never acquire horizontal land or collision.
The irregular saved outline still follows its native cell footprint.

Godot picking collision now follows these generated tops and cliff sides. It is
presentation picking geometry, not native pathfinding or simulation physics.
Exact shared-edge ray misses retry tiny screen offsets; the bounded plane
fallback is restricted to flat native cells. Native build eligibility and costs
still decide whether a selected tile can accept construction. Per-cell placement
feedback follows the surface, and road ghosts tilt to its profile; T model facing
is independent of camera yaw. Buildings retain their native foundation heights.

Walker display interpolation retains native horizontal positions/routes and
projects feet onto the same triangulated height sampler, preserving explicit
native character altitude offsets. Tree positions sample it within their native
forest cells. Neither operation changes C++ state, timing or random numbers.
Geometry changes invalidate shared profiles/normals and rebuild a two-cell halo
of affected sections, including cliff and water-apron neighbors. Flat road or
availability changes still update metadata/materials without rebuilding collision.

The designated city has 203 unoccupied blocked cliff cells, eight walkable road
ramps and 112 protected elevation cells. Its ground uses 181,026 vertices,
including 1,014 vertical side faces; subdivisions are confined to slope cells.
There are no native half slopes in this save. Half-height profiles are checked
only on disposable presentation copies; wider native campaign coverage is pending.

## Materials and trees

The new ground/water shaders, shared shader include and two seeded NoiseTexture2D
resources in `godot/assets/terrain/` are authored for this Godot presentation.
They generate colour variation and fine normals without loading original game
sprite RGB, extracted shoreline stencils, or the SDL baked water plates. Godot's
FastNoiseLite implementation generates the small seamless noise textures.
This source record does not clear the rest of the game's commercial content;
the production roadmap and existing asset provenance requirements still apply.

Water uses quiet directional normal waves, sky reflections and a static distance
tint from shallow turquoise to deep blue. It has no colour-wave checkerboard,
white foam border, shoreline rock decorations or transparent overlapping tile
layers. It is opaque PBR water with visual depth colour; physical depth,
refraction, scene reflections, fluid flow and wave interaction are not implemented.

The original forest-mask fix changed fertile bit 8 to forest bit 16. The map
review now replaces the coarse Godot forest presentation with independent
procedural olive-style crowns and cypress foliage in `terrain_forest.gd`. Forked
trunks, smooth asymmetric crowns and real leaf blades use sage/olive colours,
deterministic species/size/yaw, subtle pinned-root wind and indexed reduced LODs.
There are 3,138 trees (2,327 olive-style / 811 cypress) in 182 spatial batches.
Four cached meshes hold 4,224–4,320 vertices including their reduced LOD geometry;
reduced index sets use less than 40% of near geometry. Godot selects LOD by
projected geometric error; this is not a fixed-distance quality promise. See the
[ArrayMesh contract](https://docs.godotengine.org/en/4.6/classes/class_arraymesh.html#class-arraymesh-method-add-surface-from-arrays).
Complete canopies stay inside native forest cells with a wind margin; roads,
water, holes and foundations remain clear. Neighbor sections refresh on actual
forest/height/road/foundation edits; eligibility alone preserves batches.
The old independent tree GLBs and native SDL tree assets remain available,
and building/character GLBs and the live Blender scene are unchanged.

## Map-review corrections: bridges and walker coordinates

Native water roads were previously hidden by the water surface. The city's 57
water-road cells now receive timber decks, open railings and stone supports via
`terrain_bridges.gd`, with 20 connected shore-road approaches. Twenty spatial
batches share two meshes (540 deck / 12 approach vertices). Decks sit 0.14 units
above native water, span the actual native road direction and remain 0.68 units
wide. Approach slopes join them to land without a step. Only existing native
crossings are represented; no routes or build rules are added.

Native character local coordinates range 0..1, while Godot integer tiles are
centers. `walker_world_position()` now subtracts 0.5 once from the unchanged native
absolute X/Y, including negative coordinates. Interpolation, heading, gait, routes
and timing still follow native observations. Pedestrian feet sample bridge decks
and approaches; ships keep native water height even when crossing underneath.
Picking uses separate deck/approach tops, with unchanged native eligibility and
cost queries. Terrain collision and the underlying water/ground are unchanged.
Water-road edits refresh crossing geometry and neighboring approaches; ordinary
road metadata must still avoid rebuilding the terrain mesh. Current saved-city
crossings are straight; wider junction/height/campaign coverage remains pending.

The review also broadens rock tops and increases deterministic height/spacing
variation to reduce the rows of repeated conical piles. Deposits still match
their original flags/cells, and walkable quarry centers remain open. These sources
are recorded in `map_polish_manifest.json` with `needs_evidence` provenance;
they do not clear the remaining commercial content or production gates.

## Mineral outcrops and understory

`godot/scripts/terrain_details.gd` places the outcrops; their models come from
`tools/godot_mineral_outcrops.py` (revision 1), exported in background Blender to
`godot/assets/terrain/mineral_outcrops.glb` (one mesh per kind:variant, imported
without compression, LODs or tangents). No original sprite RGB or existing GLB is
replaced. Each kind has its own silhouette, baked vertex palette (RGB linear albedo,
A ore mask) and `outcrop.gdshader` response (`ROCK_LOOKS`), so deposits no longer
read as the same pale pebbles:
- stone: rugged grey limestone piles, dark crevices, sparse ochre/grey-green lichen;
- tall stone: a strata-banded crag with a satellite boulder;
- copper: jagged rust-red gossan with verdigris crusts and metallic native-copper glints;
- silver: dark host rock studded with bright metallic galena cubes;
- orichalcum: dark basalt with a gold-orange crystal druse, metallic with a slow glow;
- white/black marble: sawn, bevelled ledge blocks with model-space veins.
Non-quarry models stay within 0.40 tiles of their centre; scale 0.88–1.04 and a
±0.04 offset keep them inside the cell. Low marble fragments follow the quarry
perimeter rather than creating slab rows through its interior. The walkable native
quarry cell centers remain open (ledges lie 0.22–0.44 from the centre).

Native resource flags alone select identities: 64 stone, 128 copper, 256 silver,
512 tall stone, 1024 marble, 4096 orichalcum, 8192 black marble. Since the green
ground (3 October), only quarries get a floor. The RGBA8 mineral field in
`terrain_presentation.gd` colours white and black marble cells, including quarry
interiors, which have no props. A linear `mineral_pattern` mask (R) adds sawn
blocks in staggered courses in `ground.gdshader`. Stone, copper, silver and
orichalcum leave the green ground untouched, and their outcrop models alone mark
them. The tile-shaped grey soil under them was distracting, so the field's B
"stone" channel is no longer set for deposits. Linear interpolation blends quarry
floors at their edges; zero-alpha padding is unpremultiplied before shading to
avoid dark borders. The fields change with native flags, reuse their textures and
do not recompute coast distance. These materials do not add extractable resources
to neighboring cells.

Small grass tufts and leafy branch shrubs use olive/sage tones and subtle tip
wind. They occur in sparse native forest edges and nearby dry cells, with limited
forest-interior grass. A one-cell buffer excludes roads, foundations, water,
fertile fields, minerals and missing map cells. Existing broadleaf/cypress trees
remain independent. New props require the appended foundation metadata; the
explicit legacy six-column bridge conservatively disables them.

All prop geometry stays within its actual native cell, with space for wind.
Roots use the existing triangulated height sampler. No collision/navigation,
resource amount, native random number, placement cost/rule or simulation height
changes are introduced. Spatial 24×24 sections share cached meshes/materials and
MultiMeshes; there is no node per prop. Each section caps grass at 96 and shrubs
at 48. Grass fades from 42–62 units, shrubs from 65–95, using opaque screen-door
coverage plus conservative section culling. Foliage casts no realtime shadows.
Resource outcrops retain visibility; every mesh has at most 384 vertices in the
current catalog (budget 400). Seven resource kinds and two foliage kinds have two variants each.

The initial designated city has 1,044 stone, 38 copper and 50 orichalcum outcrops,
42 marble perimeter fragments for 108 native marble cells, 2,101 grass tufts and
471 shrubs: 3,746 instances in 239 batches across 64 actual terrain sections.
Silver/tall stone/black marble geometry is checked, but this saved city has none;
their native campaign visual coverage remains pending. Ground inspectors identify
native resources in EN/RU. Road/housing construction removes affected understory,
undo restores its deterministic layout, and native forest clearing removes shrubs
and refreshes neighbor habitat. Relevant flags/heights/occupancy edits rebuild
only affected sections and a one-cell neighbor halo; eligibility-only changes do
not rebuild props. Existing ground collision and coast caches remain independent.

`godot/assets/terrain/details_manifest.json` records the procedural source,
palette/design, budgets and `needs_evidence` provenance status. This authored
development slice does not clear the rest of the game's content or release gates.

Flat road/material edits update shared textures without rebuilding ground collision
or recomputing coast distance. Native water-mask changes refresh the whole
bounded coast field and rebuild affected geometry sections and their apron
neighbors. Water-altitude changes also refresh adjacent apron sections. Geometry
is emitted only for actual native tiles. Full-map field updates currently upload
small complete textures; sparse texture-region updates are a later optimization.

## Review and verification

From `eZeus/`:

```sh
python3 tools/run_godot_pilot.py --terrain-review after
python3 tools/run_godot_pilot.py --terrain-review elevation-after
python3 tools/run_godot_pilot.py --terrain-review detail-after
python3 tools/run_godot_pilot.py --terrain-review polish-after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/polish-contract-engine.log" --path godot --script res://scripts/validate_map_polish.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/terrain-engine.log" --path godot --script res://scripts/validate_terrain.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/elevation-engine.log" --path godot --script res://scripts/validate_elevation.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/detail-engine.log" --path godot --script res://scripts/validate_details.gd
python3 tools/run_godot_pilot.py --validate --lang en
python3 tools/run_godot_pilot.py --validate --lang ru
```

The review pauses the designated city, hides controls and captures the same
district and coast at distances 24/65 and yaw 15/45/135/225/315, plus an overview.
It compares full native tiles, buildings, walkers, time and treasury before/after.
`--terrain-review before` is a capture label; it does not restore the old renderer.
The preserved before images were made before the material changes.
Elevation review instead captures a native cliff and road ramp at distances
12/38 and the same five angles, plus an overview (21 views per phase). Its
`elevation-before` images were captured before the geometry change; selecting that
label now does not roll back code. Both review modes compare the full native state.
`--terrain-review mineral-before|mineral-after` captures stone/copper/marble/orichalcum
at distances 7/16 and yaw 45/225 plus an overview (17 views) for material review;
the labels do not roll back code. The 3 October outcrop revision compares them in
`captures/terrain-mineral-before-after.jpg`; in this city the stone subject sits
beside an orichalcum cluster, so both appear in its views.
Detail review captures stone/copper/marble/orichalcum and a clear forest edge at
distances 10/32, yaw 45/135/225/315, plus an overview (41 views). Unlike the older
capture labels, `detail-before` explicitly hides the new props/mineral tint in the
current renderer for a controlled comparison; native state and terrain geometry
remain identical. `detail-after` displays them. Comparisons test native state
unchanged, not whole-game parity or performance on minimum hardware.
`polish-after` adds a native bridge at the same distances/four angles, producing
49 views including the overview. Historical detail-after images retain the old
forest presentation; polish review also records current tree/crossing budgets.

Final review samples count settled frames over about one second after a half-second
warmup, before screenshot readback. They are local observations at 1280×800 on an
M4, not sustained minimum-hardware or maximum-city benchmarks. The original rapid
before capture's FPS counters include screenshot stalls and must not be used to
claim a performance improvement. Validation logs and limitations are recorded in
[GODOT_VALIDATION.md](GODOT_VALIDATION.md).

## Next terrain work

- Extend tree species/content and bridge topology, and profile foliage LOD/occlusion,
  then wider campaign coverage. Do not scatter unbounded individual mesh nodes across the map.
- Wider native mineral/elevation fixtures, marsh/lava/quake visuals and terrain
  landmarks remain pending. Preserve resource identity and independent tree assets.
- Calibrated material detail at street scale, optional refraction and water
  interaction after profiling. Full building material/state baking is separate.
