# eZeus / Godot 3D development instructions

## World-map refinement — 4 October 2026

The atlas clips submerged relief at the coast and uses a 192×96 sea sphere;
current designated-world geometry is 35 meshes / 185,640 triangles (retain the
100 / 220K caps). Arrow/WASD pan, Q/E orbit and R/F tilt share the city bindings
and camera speeds, with Shift boost and modal/typing/cinematic/focus guards.
On-screen arrows still select cities. Keep native UV/height fields and stock
observations authoritative. The responsive framed toolbar is `%AtlasToolbar`;
`world_flight.gd` fades that whole surface and must keep its unique scene reference
when layout changes. Read `docs/GODOT_WORLD_ATLAS.md` and current validation.
Visible reviews run sequentially with scratch preferences and the designated save;
the reviewer foregrounds only its owned preview for captures.

## Water-life presentation — 4 October 2026

Native fish/urchin flags are appended tile column 9 (bits 1/2), feeding procedural
fish schools and spiny urchin clusters. Fishing skiffs and urchin workers use
native-action-gated authored collection clips; the diver also has bag-carry and
deposit clips. Preserve gameplay-clock transitions, UVs/VAT freshness, source
geometry/LODs, the nine earlier tile columns, terrain delta cache and bounded
surface glints/three bubbles. Use background-only asset exports; keep native art
and the live Blender scene intact. See [water-life contracts](docs/GODOT_WATER_LIFE.md).
The designated city has four native fish deposits and no urchins; reviewers use
a copied presentation-only urchin tile and temporary collectors, never an
altered save/core or live role. Run both water-life and gathering-motion gates
and visible language reviews sequentially with scratch preferences.

Current handoff: **3 October 2026**. This is the Git repository; its parent is
the local installation/art workspace. When available, read the parent
[AGENTS.md](../AGENTS.md) for detailed native-engine knowledge and art benchmarks.
Claude's additional native UI/font/screenshot notes remain in the parent
[CLAUDE.md](../CLAUDE.md). The rules below also apply to a standalone checkout.

Latest presentation slices: the compact category dock/search/model previews and
bounded inspector/decisions are implemented; read [interface contracts](docs/GODOT_INTERFACE.md).
The second interface pass uses a coloured icon dock, smaller centred model tiles,
selected/hovered context, facing buttons sharing T, native wall fill and native
cost/obstruction cursor badges. Preserve upward tray sizing, minimap preference,
pointer pass-through, exact native quotes and the shared Theme/CSV. Pier and
gatehouse facing comes from the core. Curved roads are not implemented. Use
`tools/review_interface_context.py --checks --lang en` (or `ru`) and the visual
review; do not regenerate `hud.tscn` with the old scene builder.
Focused Metal/Mobile interface gates pass 67 each in EN/RU (20 existing plus
47 context checks); native road 22, wall 63 and translation 7 also pass. These
scoped results do not clear historical broader gameplay/campaign failures.
The third interface pass adds native status/maintenance/road/staffing/housing
summaries and related-view buttons. Service panels consume the already-polled
overlay observations for counts and matching colour keys; keep quick switches
visible and avoid duplicate queries or invented coverage statistics.
`UiAccess` scales cached Theme fonts from an immutable baseline and root Window
content for independent UI/text sizes. Game → Interface options and the menu gear → Interface options
preview changes; Apply saves only interface size/text/motion keys, Cancel restores without writing.
Preserve per-user language/sound, dirty inspector drafts/tokens, camera suppression
inside the dialog, dynamic panel/card minimum sizes and native picking/timing.
Do not save the scaled Theme resource. Automation uses defaults and scratch
preferences. `tools/review_status_ui.py --checks --lang en` (or `ru`) passes
115 each (48 status/accessibility + 67 existing); `--menu` passes 17 each.
Native overlays 59, translation 7 and startup 39 pass; see the validation document
for captures, the corrected MP3/WAV test assumption and remaining limits.
**Nova reference HUD (3 October 2026):** the user's clearer Nova Roma screenshot
supersedes the Aegean shell and older bottom-right minimap layout. Preserve the
thin teal current-city stock ribbon, centred native city plaque, native jobs and
welfare shortcuts, square dock, left journal rail, bottom-left time controls and
circular minimap. The default folded map preference, exact native transformations,
heading chevron remain; the chart now covers/clips to its circle at the user’s
request rather than fitting every corner inside. Masked corners pass input through. Native objectives and selected-tool/inspection cards sit lower right,
wrapping below the header when necessary. Build trays/expanded decisions fold the
goal disclosure. The speed popup must clear its opening click at every UI scale.
Stock/employment fields are read-only observations from native caches, without
extra polling/tile scans. Retain quiet reports, one urgent alert, required callbacks,
full history, inspector drafts/tokens, translated text and independent size/motion
preferences. Art is original SVG/Theme work; no reference screenshot is embedded.
The city language/gear panel is removed; treasury/population/jobs now share the
unified resource bar. Every native resource type through silver and the food
total is shown, including zeros; balanced rows wrap rather than hide items.
Original procedural 3D model renders provide static icons without live HUD
viewports. Read the resource art contract and use `tools/review_resource_bar.py`.
Escape closes the current city window/tool first, then opens the centred game menu
with city/settings/views and language. Nested settings return one page at a time;
menu pause and command-queue hold restore their prior states. Display Escape reverts
a pending preview and closes that page. Preserve native decision callbacks. Use
`tools/review_escape_menu.py --lang en` (or `ru`).
Run visible reviews sequentially with disposable preferences. Latest counts,
captures and scoped limits are in `GODOT_VALIDATION.md`.

**Storage building goods display (4 October 2026):** warehouses (8 bays), trade posts
(15 bays), and granaries (8 radial bins in drum) dynamically display 3D stored goods
and food items on top of their yards/drums matching native simulation inventories. 20
goods models and 8 granary food models exported with vertex-palette PBR materials; MultiMesh
spatial batching; `EZeusSimulation` detects inventory changes and emits updates only when
bay quantities change. Automated test suite `validate_storage_goods.gd` passes 204/204 checks.

**Monster combat effects (4 October):** `monster_effects.gd` draws Hydra venom and
the shared native projectile/impact pipeline for all 17 monsters. The optional
missile observer is presentation-only, empty in SDL and nonserialized; preserve
native timing, damage, collapse, sounds and RNG. Effects freeze on pause/decisions
and use two bounded MultiMeshes. Read `docs/GODOT_MONSTER_EFFECTS.md`; the native
contract passes 77, sequential EN/RU city reviews 14 each, and six seeded replay
cases match. Use `tools/review_monster_effects.py` only on the designated city with
scratch preferences. The new three-headed Godot Hydra is implemented through
`tools/godot_hydra.py`, with .64-tile paws, in-place walk/idle/fight/fight2/die,
UV2 surface semantics and three interpolated mouth anchors. Read
`docs/GODOT_MONSTER_ART.md`; preserve the native recipe and live Blender scene.
After re-export, verify both UVs, VAT freshness, flat-ground pose bounds, measured
citizen/god size and LODs. `validate_hydra.gd -- --update-hydra-baseline` edits only
that model's entry. User visual acceptance, individual art for other monsters,
slope foot IK and minimum-Mac GPU profiling remain pending.

Historical fourth interface pass (superseded layout) folds the minimap into a bottom-right City map pill
(default folded), remembers explicit visibility choices, and shows a small camera
heading chevron with a soft cyan halo. Both compass elements and the large camera
footprint highlight are removed at the user's request; Home retains overview.
Keep the native coordinate transforms and footprint observations. The chart has
no heading row and uses a small overlaid dash to fold. It stays fixed at the
bottom right when ground/building cards open; inspectors scroll above it without
resetting drafts. The Aegean pass uses separate floating time/resource groups;
keep utility/objective/notice bounds below them and the content-sized floating dock
near the bottom edge. Shared Theme variations preserve independent text scaling;
the generator must also preserve AtlasTitle/AtlasHint typography. The map folds
temporarily for trays/history/expanded decisions. Routine native news enters the
compact journal quietly; one urgent alert is visible and later alerts queue.
Missing native kind metadata retains a visible fallback. Preserve paused
hover/reading/hidden/clipped countdowns, complete history/unread semantics, exact
warning occurrence groups and stable reading Controls. Required decisions are persistent amber review
chips; folding/reading never answers them or releases the native block. Original
choice callbacks stay in main.gd. Theme/CSV and pointer pass-through contracts
remain. Quiet acknowledgements follow recording, retry with queue headroom and
never answer choices. Native kind is observation-only. Preserve inspector drafts
when the journal opens and Escape closes it. Identical catalogs reuse cards and
hover state; thumbnail viewports remain idle-disabled. Reduce interface motion
uses explicit preview/Apply/Cancel. Navy/ivory/bronze styles and original medallions
come from the Theme generator, not extracted reference art.
Use tools/review_map_notifications.py --checks --lang en (or ru): 84
focused checks plus nine retained message/log assertions each; --native-map
passes eight each. Existing status/HUD/context gates pass 115 each; translations
seven. See interface/validation docs for fixtures, captures, the existing broad
aid-regard failure and remaining visual/performance limits. Run visible reviews
sequentially with disposable preferences; do not overlap them.

Exposed land now continues into cosmetic woodland/hills and water into sea;
read [surroundings contracts](docs/GODOT_SURROUNDINGS.md). Scenery is strictly
outside native cells with no physics, navigation or build eligibility. Preserve
the exact rim profiles, indexed adaptive mesh, local deterministic noise,
800-tree cap and ocean masking over level land. `OrbitCamera.configure_map()`
owns the 1.05-map-dimension maximum; wheel/pinch and Home share these limits.
Outward wheel/pinch crossing that limit now requests the animated world atlas;
F2/world actions share the ascent, and Back/Escape returns to the exact city
pose. Home stays in the city and M keeps mute. Read
[world-flight contracts](docs/GODOT_WORLD_ATLAS.md): preserve synchronous pause,
queued-command holding, input shielding, pending decisions and hidden rendering.
Review only the designated city with `tools/review_surroundings.py`; its inland
fixture is presentation-only. Check the validation document for actual evidence
and remaining campaign/performance coverage. These replace the former visible
map cuts without extending the simulation. Further UI polish remains pending.

Display settings (3 October): Game → Display settings and start-menu gear →
Display settings select window size, desktop fullscreen, monitor, VSync and FPS
cap. The gear now opens Game settings with Display/Interface/Controls links.
`scripts/display_settings.gd` shares the earlier fullscreen key and migrates its
preference. Preserve explicit Apply → 15-second wall-clock preview → Keep;
Revert/Escape/timeout/removal restore exact window presentation without writing.
Startup loads only confirmed per-user settings. Do not change hardware display
modes, native timing, map coordinates or real preferences during reviews. Use
`tools/review_display_settings.py --lang en` (or ru, --headless for preferences):
48 scoped Metal checks each, 23 headless; controls 59, menu 17 each. Wider high-DPI/mixed-display,
platform and performance coverage remains pending. Read interface/validation docs.

**Character window (3 October 2026):** right click on a walker opens `ui/character_panel.gd` (3D model on a plinth, name, occupation, the native spoken line typed with its voice, errand, others on the tile, Go to), pausing the city. Words come from `character_info` via `engine/echaracterinfotext` (shared with the SDL window; cosmetic randomness). Use `tools/review_character_panel.py --lang en` (or `ru`): 26 checks each.

## Read before continuing

- [Godot README](godot/README.md): launch, controls, implemented scope and build.
- [Migration stages](docs/GODOT_MIGRATION.md): completed work and next gates.
- [Validation evidence](docs/GODOT_VALIDATION.md): checks and practical limits.
- [Engine/rotation architecture](docs/ENGINE_AND_ROTATION.md).
- [Production roadmap](docs/PRODUCTION_ROADMAP.md): independent content and release.

The user approved **Godot 3D presentation while preserving the C++ simulation**.
Normal launch embeds the simulation through GDExtension, with no hidden SDL
renderer or native game subprocess. The old `--legacy-bridge` adapter is an
explicit regression reference. Keep normal launch on the embedded backend.

The full saved map and 363 development GLBs are implemented. All 792 rendered
building objects and 279 initial walkers in the designated city have real models;
42 native livestock/sanctuary records render through their animals/components.
Other campaigns and visual states still need coverage. Read
[asset contracts](docs/GODOT_ASSET_COVERAGE.md) before exporting or changing mappings. Audio, specialized UI/military/campaign/save-load/settings
coverage, material/state-animation baking, seeded replay proof and standalone
production packaging remain pending. Follow the migration document's ordered
stages; update the status after each completed stage.

The Build menu lists every building the core's `buildable` query offers that has a
converted model and that the city's culture may build (46 in the test city, road included, in ten
categories: housing and roads, agriculture, industry, storage, markets, health and water,
administration and security, culture, science, gardens and monuments). Each has an
exact native preview/cost, imported ghost, demolition and undo; every native building
has a model now (a building added later without one stays hidden; `--placeholders` lists such types for
development). The quick row keeps Inspect, Road, Housing and Demolish. Live storage inspectors include native orders
and limits; production inspectors include inputs/outputs and city-wide industry
shutdown/resume. Preserve native workforce semantics and weak-reference tokens
against stale actions. New square-building facing is session-only; serialization,
rectangular facing, remaining tools/drag roads and the vendor stall inspectors
are pending. Numeric edits must suppress camera keys and survive refresh.
See the updated README and validation document before adding more presentation.

The user prioritized terrain realism next. Continuous ground materials, sandy
wet banks, a shared coast contour and shallow-to-deep calm water are implemented.
Forests use native forest bit 16 (not fertile bit 8); the latest map review adds
independent procedural olive-style/cypress canopies, leaf geometry, wind and reduced
mesh LODs. Old tree GLBs and native SDL assets remain intact.
Continuous elevation profiles, road ramps and limestone cliff/outer-edge sides
are implemented with shared lighting normals. Read [terrain contracts](docs/GODOT_TERRAIN.md)
before continuing. Snapshots append read-only geometry flags/character height
after their original six tile columns. Presentation picking, walker feet and
placement previews follow the generated surface; foundations retain native heights.
Native terrain/resources, pathfinding, eligibility, routes and 20 Hz timing stay
authoritative; irregular map holes stay empty. Flat road/material edits must not
rebuild collision. Native mineral outcrops, continuous mineral soil and forest-edge
grass/shrubs are now implemented in `terrain_details.gd`, separate from the 240
GLBs and independent trees. Since 3 October each deposit kind has its own Blender
model (`tools/godot_mineral_outcrops.py` → `assets/terrain/mineral_outcrops.glb`),
`outcrop.gdshader` response and ground soil/pattern, so stone, copper, marble and
orichalcum no longer look alike; re-export and `--import` after editing the script.
The ground is green now: board and countryside share `shaders/terrain_palette.gdshaderinc`
(meadow, scrub, forest floor, lusher fertile land), and `scripts/map_border.gd` draws a
dashed Cities: Skylines-style border just inside the native board edge; everything outside it is
tinted darker (`shaders/map_outside.gdshaderinc`, shader globals `map_border_*`).
Water and the sea share `shaders/water_surface.gdshaderinc` (depth colour, ripples, sky reflection,
foam); a low-pass `coast_distance()` smooths shore teeth; banks vary in width with wet sand.
Roads pave their whole tile with kerbs; `scripts/walker_streets.gd` draws people 12% larger, in
right-hand lanes on roads (presentation only), and rings the hovered person.
Buildings step back 0.12 tile from roads (`street_setback.gd`); snapshot tile column 8 is the road
kind (avenue 2, boulevard 3), drawn with dressed paving, planted medians and street trees (`terrain_avenues.gd`).
Buildings turn their front (door, or the kits' dressed +X/+Y corner) to the longest adjacent road
(`street_facing.gd`, presentation only); T breaks ties, so it picks the street when roads surround a building.
Objectives panel (3 October): the `episode` query adds per goal `kind`, `current`, `required` and, for an unmet
housing goal, `housing` (houses below the level by level, their people, and per need how many houses lack it, from
`eHouseNeeds`). `ui/objective_card.gd` draws a card per goal (icon, bar with the count or the core's status, need chips
with advice tooltips); `ui/objective_wreath.gd` is a 3D gold laurel in the header whose leaves grow with the share met
and which turns once when a goal is met. Styles are the theme's `Objective*` variations; `--objectives-review <name>`.
Gold HUD (4 October): every HUD surface now uses the objectives panel's look. `build_ui_theme.gd` has `gold_frame()`
(lapis, gold rim, rounded corners, soft shadow) and `gold_face()` (button rest/hover/chosen), and the slim teal "Nova Roma"
frames are gone. Categories are round gold medallions; tools and build cards are gold tiles; progress bars are gold.
The minimap draws a gold rim from the theme's `MapCard` `rim`/`rim_shadow` colours. `--objectives-review` also
captures the inspector with the minimap, the build tray and the message log.
Dialogs and the escape menu match it: embedded windows use a gold frame grown upward by the title height
(`expand_margin_top` = `title_height` 40, so the title and close cross sit inside it; Godot draws `embedded_border` under the
content only), a 3 px gold top line, pale-gold bold titles, and a content panel with no second border. The escape menu
uses `EscapeHeading`, `EscapeRule` and `EscapeAction`, with Primary for "Return to city". `review_escape_menu.gd` captures
every dialog it opens (`captures/escape-dialog-<action>-<lang>.png`).
A dialog's OK button is Primary (set where `hud.gd` attaches RightClickBack to each Window), and the decision card and
`EnvoyAction` buttons use the gold frame and faces. `--street-review <save copy>` opens a COPY of a save from a scratch
folder (used as the save directory), pauses, and captures its densest blocks of houses (`captures/street-*.png`) to
judge `street_facing.gd`; never point it at a player's own save folder. The initial city has 3,746 detail instances in 239 spatial
batches. Preserve native flags, foundation/road/field/water buffers, height anchors,
per-section caps and distance fading; props have no collision or native RNG.
Resource ground inspectors identify deposits in EN/RU. Construction, undo and
forest clearing refresh detail and neighbor habitat. Missing legacy foundation
metadata conservatively disables new props. Read the terrain source manifest and
contracts before extending the catalog. The map review also fixes missing native
bridges (57 water-road cells, 20 shore approaches) and a half-tile walker offset.
Subtract 0.5 once from native absolute walker X/Y for integer-centered Godot tiles;
never rewrite native positions. Pedestrians sample deck/approach heights; boats
keep native water height. Crossing picking collision is separate from terrain
and does not change native rules. Forests have 3,138 trees in 182 batches; use
`terrain_forest.gd` and `terrain_bridges.gd`, with their source manifest.
**Next terrain work: additional species/bridge topology, LOD/occlusion profiling
and wider native campaign coverage.** Terrain fields pass 18 checks, elevation
geometry 22, details 31, map review 16 and visible EN/RU runs 182 each; the complete
current regression set passes 900. Half-slope and absent
mineral-kind tests are presentation/geometry checks only; minimum-hardware
performance remains an open gate.

The eight garden GLBs now use `tools/godot_garden_foliage.py` for branching
cypresses/pines, folded leaves, vine coverage, clipped topiary and flowering stems.
All 178 native garden placements retain their footprints. `RECIPES['park']` selects
the real 1x1 pine/bench module; do not restore the shrunken 3x3 tholos on 164 parks.
Keep per-asset foliage budgets, double-sided palette batching and adapter provenance.
Export only in disposable background Blender; native sprite recipes/live scenes
remain intact. Garden wind, more variants and material baking remain pending.
The new garden contract passes 26 checks; read the final validation evidence before
claiming broader performance or campaign coverage.

## Architecture and controls

Building work animation is now connected for 35 authored types. Read
[building activity contracts](docs/GODOT_BUILDING_ACTIVITY.md): preserve native
`working`/`workers`/phase observations and gameplay-time clock, GPU work/inactive
poses, static/dynamic spatial batches, per-asset geometry tiers, original-model
SHA freshness fallback and source-write guards. Keep pause/decision/speed semantics
and incremental rebuilds. Export through `tools/export_building_activity.py` in
background Blender, then import and run `validate_building_activity.gd` and the
visible reviewer. This does not extend the physician art benchmark to on-site
workers; inventory/rower/full-state coverage still remains pending.

The first natural people pass covers all 31 existing human walker GLBs.
Read `docs/GODOT_CHARACTER_ART.md`: the Godot-only adapter preserves distinct
anatomy, painted skin, fitted hair, female/child proportions and sampled gaits.
The philosopher's blue wrapped himation follows the user's clothing reference.
Keep `CityPalette` and both UV sets (rest coordinates/surface type/person index),
face/hand allocations, three-or-fewer mesh groups, geometry caps and imported LODs.
Stage exports with `tools/export_character_assets.py`; optimize duplicate morph
targets and prove losslessness with `verify_glb_optimization.py --require-uv`.
Validate characters and compare `--character-review before/after` captures.
Gods get designed faces from `tools/godot_god_face.py` (3 October; Hades first, called from
`godot_hades_art.py`): sculpted head, baked occlusion and painted features in the vertex palette, real eyeballs,
brows, a strand-card beard and a hairline cap. The exporter sees a 169K-vertex body, so shells are thinned and the
`PROTECTED` parts bypass the simplifier and count against the god's budget (Hades 19,000). Preview with
`tools/preview_god_face.py`, judge in Godot (`--character-review after --character-subjects walker_<god>`, which has a
straight-on `portrait` and a `city-closest` view), and re-record only that god's geometry baseline. The player's
closest zoom is `MINIMUM_DISTANCE` (ten tiles) in `orbit_camera.gd`; reviewers and validators may still set `distance`.
The fourteen gods float (3 October): `tools/godot_god_float.py` makes their held pose a hover in the export (24
identical walk samples, a twelve-frame idle drift; never edit `art/characters/people`), and `scripts/god_float.gd`
gives them hover, bob, lean, sway and a slow turn from `main.gd` (`animate_walker`, the heading); keep it presentation
only. Re-export all gods together if the kit changes, and check with `validate_locomotion.gd` and the character review.
Embedded building workers/rowers, full texture baking and facial/work/death/cargo
motion remain pending; do not claim those are complete or clear provenance.

- `presentation/esimulationservice.*` owns the native campaign/board;
  `presentation/godot/` binds `EZeusSimulation` into Godot.
- `engine/esimulationstep.*` shares the original tick sequence with the SDL
  reference. Preserve the 20 Hz/50 ms accumulator and native speed semantics.
  Economy, pathfinding, production and decisions remain in C++; camera yaw must
  never rotate or rewrite simulation coordinates.
- `godot/scripts/core_link.gd` supplies direct calls and snapshots. JSON conversion
  is still inside the process; snapshot IDs are session IDs, not durable IDs.
- `godot/scripts/orbit_camera.gd` implements physical-key **Q/E continuous 360°
  orbit**, **R/F tilt (25–75°)**, WASD pan, Shift boost, cursor zoom (closest view ten tiles, `MINIMUM_DISTANCE` in `orbit_camera.gd`, player input only) and middle-drag
  yaw/tilt. `scripts/main.gd` binds actions; **T** rotates the placement preview,
  **Home** fits the city, **Space** pauses, **Escape** returns to inspection.
  **X/Delete** selects demolition; **Ctrl/Cmd+Z** undoes the last construction.
- Native SDL controls differ: Q/E change among four directional views, R rotates
  placement and default C clones a building. Preserve custom-binding migration.
- Retain original event callbacks and pending decisions. Do not silently invent
  outcomes for military/campaign interfaces awaiting migration. Preserve EN/RU.

## Panel-only elder curator reference — 4 October 2026

Read [GODOT_PORTRAIT_REFERENCE.md](docs/GODOT_PORTRAIT_REFERENCE.md) before further
portrait work. The user requested one older, more realistic character only in the
Character panel. `tools/godot_curator_portrait.py` builds the 68-year-old curator
(`elder_curator_portrait_v2`); it replaces the rejected thick curls with fine
surface-sampled fibers and corrects face landmarks. Portrait finish, full mesh
quality, 1.5× render scale and framing are isolated to the panel. Keep native
words/voice, city crowd assets and the physician benchmark intact. The one-model
budget is 600K vertices/40 MiB, not a walker budget. Rebuild only `walker_curator`
with `godot_portrait_export.py`, run `validate_curator_portrait.py` and sequential
EN/RU `review_character_panel.py` reviews. User visual acceptance remains pending;
do not call it production-approved or roll it across the catalog automatically.

## Character art review status — 30 September 2026

The user rejected `natural_people_v1` as still doll-like. Treat the 31 updated
human assets as technical prototypes, not accepted production art. Read the
revised one-citizen benchmark plan in `docs/GODOT_CHARACTER_ART.md`: proper texture
UVs/PBR maps, anatomy/eyes/hair/garments, a runtime skeleton and natural idle/walk
motion. Verify the result in the actual city before another catalog rollout.
Existing check counts do not prove visual realism.

Later session: the benchmark is built and integrated, awaiting the user's visual review.
`assets/characters/physician_v2/physician.glb` (30K vertices, VRAM-compressed textures,
137 bones, Idle/Walk, blink shapes; `tools/build_citizen_benchmark.py`) is shown near the
camera by `scripts/skeletal_citizen.gd`; every physician is drawn by the baked 6K-vertex
crowd twin `physician_crowd` and `scripts/citizen_lod.gd` swaps the nearest 24 within 9
units to a pooled skeletal citizen with the same clock. Contracts: seek Walk by cycle
fraction (`walk_time`), never multiply a skinned
mesh's bounds by node scale, keep textures VRAM-compressed (`tools/configure_citizen_textures.py <folder>`),
and rebuild with the workflow in `docs/GODOT_CHARACTER_ART.md`. `validate_citizen.gd` (36
checks originally; 38 after the gait refinement) gates it. Do not roll the pipeline out to other roles until the user accepts the
benchmark in the real city. Forward+ was measured (about 1.5x frame time, +50 MB) and stays
an experiment; Mobile is the renderer. The himation is now a cloth-simulated drape over the left
shoulder (`CITIZEN_MANTLE`, preview with `CITIZEN_PREVIEW`; the simulation is sensitive, see the
character document). Known gaps: frayed hem, pale eyes, and the native `disgruntled` walker has no
model (`validate_city_coverage.gd` flakes on it).

Walking refinement (1 October): `walker_motion.gd` blends human starts/stops and
smooths shortest-path turns; gait phase uses horizontal native displacement before
surface-height correction. Keep VAT/fallback normalized alias weights and exact
transition weight/phase across citizen LOD swaps. The physician's `contact_roll_v1`
adds support/heel/toe/swing/weight/counter-motion in `tools/citizen_gait.py`; it
retains the 0.64-tile stride, 24/12 crowd samples and existing geometry budgets.
Export bone clips from time zero (`export_anim_slide_to_zero=True`), at 100 Hz;
`configure_citizen_textures.py` preserves the manifest's bone import rate. Current
periods are 0.64/3.0 seconds, fixing the older 0.66-second import/initial hold.
Run `test_citizen_gait.py`, `validate_locomotion.gd`, `validate_citizen.gd` and
the continuous city reviewer after changes. The reviewer uses a temporary physician
on a native transporter route if the designated city has no physician. Never
change the live role mapping to make that review pass. Other roles' new cycles,
foot IK on slopes, building-worker art and visual approval remain pending.

## Build and verify

Commands run from this directory:

```sh
./tools/build_godot_extension.sh
python3 tools/run_godot_pilot.py --validate --lang en
python3 tools/run_godot_pilot.py --validate --lang ru
python3 tools/run_godot_pilot.py --terrain-review after
python3 tools/run_godot_pilot.py --terrain-review elevation-after
python3 tools/run_godot_pilot.py --terrain-review detail-after
python3 tools/run_godot_pilot.py --garden-review after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/garden-contract-engine.log" --path godot --script res://scripts/validate_gardens.gd
python3 tools/run_godot_pilot.py --terrain-review polish-after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/polish-contract-engine.log" --path godot --script res://scripts/validate_map_polish.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/terrain-engine.log" --path godot --script res://scripts/validate_terrain.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/elevation-engine.log" --path godot --script res://scripts/validate_elevation.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/detail-engine.log" --path godot --script res://scripts/validate_details.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/embedded-engine.log" --path godot --script res://scripts/validate_embedded.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/assets-engine.log" --path godot --script res://scripts/validate_assets.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/construction-engine.log" --path godot --script res://scripts/validate_construction.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/industry-engine.log" --path godot --script res://scripts/validate_industry.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/coverage-engine.log" --path godot --script res://scripts/validate_city_coverage.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/geometry-engine.log" --path godot --script res://scripts/validate_geometry.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/poses-engine.log" --path godot --script res://scripts/validate_poses.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/citizen-engine.log" --path godot --script res://scripts/validate_citizen.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/replay-engine.log" --path godot --script res://scripts/validate_replay.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/ui-text-engine.log" --path godot --script res://scripts/validate_ui_text.gd
python3 tools/replay_parity.py
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/roads-engine.log" --path godot --script res://scripts/validate_roads.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/saves-engine.log" --path godot --script res://scripts/validate_saves.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/load-engine.log" --path godot --script res://scripts/validate_load.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/adventures-engine.log" --path godot --script res://scripts/validate_adventures.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/start-engine.log" --path godot --script res://scripts/validate_start.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/overlays-engine.log" --path godot --script res://scripts/validate_overlays.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/audio-engine.log" --path godot --script res://scripts/validate_audio.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/campaign-engine.log" --path godot --script res://scripts/validate_campaign.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/campaign-ui-engine.log" --path godot --script res://scripts/validate_campaign_ui.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/trade-engine.log" --path godot --script res://scripts/validate_trade.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/trade-ui-engine.log" --path godot --script res://scripts/validate_trade_ui.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/buildings-engine.log" --path godot --script res://scripts/validate_buildings.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/walls-engine.log" --path godot --script res://scripts/validate_walls.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/housing-engine.log" --path godot --script res://scripts/validate_housing.gd
python3 tools/save_roundtrip.py
```

Performance contracts (measured 30 September 2026; see the validation document): keep
delta snapshots free of per-tile eligibility scans and unchanged building lists, keep
`buildings_changed` gating and incremental batch rebuilds, never read model manifests
per building, and keep two shadow cascades and the 3-pixel mesh LOD threshold unless a
new measurement justifies a change. New models need a LOD ladder and a
`--write-baseline` entry in `data/geometry_baseline.json`. Startup contracts: the embedded
backend must not fully decode sprite images (only their size), model GLBs are requested on
worker threads before terrain is built and joined at once (`building_batches.gd` `join()`: the main thread
waits, so no loading thread sets up a BaseMaterial3D while a frame renders; every load is collected into
`loaded`, released with the node; an uncollected threaded load outlives the renderer and crashes or floods
`Parameter "material" is null` at exit; never leave a `load_threaded_request` uncollected), and exported walkers must go through
`tools/optimize_glb_memory.py` (then import and `tools/verify_glb_optimization.py`). Never
drop UVs to save memory (it stripped foliage LODs), and resolve `idle_00|idle_01` style shape
names through `morph_table` in `main.gd`. Animated models are baked by `tools/bake_walker_vat.py`
into `models/runtime/` (never edit sources for it; keep UV and UV2 free for character
shaders); a custom shader adopts poses with `walker_vat.gdshaderinc` or by not defining its own
`vertex()`, and after any walker re-export run the tool, import, and `validate_poses.gd`.
Keep `limits/global_shader_variables/buffer_size` large enough for the crowd (4,096 animated
parts per 65,536).

Foundation contracts (1 October 2026; evidence in the validation document). **Interface:** all text is `tr("English source")`
from `godot/data/ui_strings.csv` (never inline language pairs or a language flag; add a column for a language, import, and register
the new `.translation` in project.godot; `validate_ui_text.gd` gates it); style comes only from `ui/lapis_gold.tres`
(`scripts/build_ui_theme.gd`) and layout from the scene `ui/hud.tscn` (edit it as a scene, do not rerun
`build_hud_scene.gd` over edits); players never see developer telemetry (F3 overlay only); new windowed checks go in
`validate_main.gd`, not `main.gd`. **Camera:** the orbit centre follows the terrain through `orbit.ground_height`; keep
`terrain_point`/`snap_to_ground` and never reanchor on y = 0. **Simulation reproducibility:** never call `eRand` from a worker
thread (path-search filters use `eRand::searchCoin(salt, x, y)` with a salt drawn on the game thread); after any C++
change to simulation code run `tools/replay_parity.py` (rebuild and sign `Bin/eZeus` first) and `validate_replay.gd`.
Trade: a trade post belongs to one partner city. The partners offered are the SDL build panel's list (`engine/etradepartners.*`, shared
with it): not a rival or an enemy, active and visible, something to trade, no post yet. A land partner takes a 4x4 `trade_post`, a sea partner
a `pier` (a 2x2 pier on a shore tile whose water leads to the sea, with its 4x4 trade post on the land behind it; the rules live in
`engine/eshoreplacement.*`, shared with the SDL widget, along with the fishery's shore rule). `preview`/`build` take the partner as a fifth
number (its index in the world's city list); a pier's (x, y) is its first tile. Both are charged as a trade post; a post is removed with its
pier, and a freed partner returns to the list one simulation step after the removal (the menu asks again after 1.5 s). `trade_partners` lists
every candidate with its goods and prices, `inspect` gives a post a `trade` object (imports the partner sells, exports it buys, stock, price,
this year's use of the partner's limit, the stock to keep), and `trade x y token resource direction enabled quota` edits it (quotas follow the
storage steps). The Build menu's Trade category is built from the partner list (items "pier:3" / "trade_post:3"); the pointer snaps a pier to a
fitting shore tile within two tiles; Game, Trade partners… shows the partners and their goods. Traders and their donkeys, and trade ships, are
the native walkers.
Elite housing and area drags: `elite_house` is a 4x4 `buildSpecs` row (`eEliteHousing`, charged as the native mansion) shown as `elite_house_<level 0-4><a|b>`, the
variant chosen by the building's seed as the SDL view does (a vacant plot and Atlantean cities use the same set; the remastered estates are
`art/elite_house_<level><a|b>`, exported by name through the generic `art/<name>/build_sprites.py` fallback of `export_godot_pilot.py`). Common housing, elite
housing and parks are dragged over an area with `preview_area name x1 y1 x2 y2` / `build_area name x1 y1 x2 y2 orientation`: houses in 2x2 and
mansions in 4x4 steps from the pressed tile toward the released one (columns, then rows, the SDL order), parks on every tile of the rectangle, each plot
built or skipped on its own with the usual reasons, stop at 1000 drachmas of debt, one undo step, at most 3,000 plots listed (counts stay exact). The
plan carries the model name; `road_drag.gd` (now the drag tool for road, wall and the area tools, `AREA_TOOLS`) draws one flat plate per plot and the
real model for the first few (`MODEL_LIMIT`: a mansion has ~63,000 triangles). A click without moving is a one-plot drag. While a test drives a drag
(`road_drag.guard` false) `main.gd` no longer lets the real mouse move its end.
World map: the `world` query reports the map picture (`image`, a file of `Textures/Zeus_Data_Images` beside the repository), the player's cities with their stock of
giftable goods (`mine`, each good with its gift step), the cities on the map (`cities`: kind, relationship, nationality, position as fractions of the picture, regard 0 to 100 and
its native name, goods sold and bought with prices, tribute, and flags `can_request`, `regarded`, `can_gift`, `can_fulfil`, and the military ones below) and the pending
requests (`requests`: the city, the goods, and the player's cities that can fill them). Three commands act, each answering with the new `world`: `world_request <city> <resource> <own city>`
(not for a distant city, the city played or a colony or neutral city on the board; refused while the regard is 50 or less unless the city is a rival; only what the city sells or
drachmas; every city on the map then loses 10 regard and the asked city 10 more, as `eGameBoard::request` does, and the event answers in 90 days), `world_gift <city> <resource> <count> <own city>`
(a whole number of steps, one to three, of the good's base size; the goods leave the city at once, the regard rises when the gift arrives 90 days later) and `world_fulfil <request> <own city>`.
The military dealings (raid, conquest, aid, strike) are described next. `test_request` (validators only) registers a city's request. The scene is `ui/world_map.tscn` (generated once by `scripts/build_world_map_scene.gd`,
then edited as a scene) with `ui/world_map.gd` and the marker control `ui/world_marker.gd`; `main.gd` holds the city while it is open (`open_world` / `close_world`, F2).
Army: the soldiers' companies are the engine's banners (`eSoldierBanner`, at most `per_banner` = 8 soldiers each, kept at the palace while at home). Housing supplies the soldiers by the engine's own
rules (`eBoardCity::updateMaxSoldiers`, every 1000 time units): common houses of level 2 and above send rock throwers (archers in an Atlantean city), elite houses of level 2 and above hoplites (they need arms) and, at level 4 with horses, horsemen
(chariots in an Atlantean city), up to the 20 places of the palace. The `army` query reports `palace`, `capacity`, `per_banner`, the soldier totals (`hoplites`, `horsemen`, `rabble`) and `banners` (`id`, `city`,
`type` one of hoplite, horseman, rock_thrower, amazon, ares_warrior, `name` and `kind_name` in the core's language, `count`, `placed` with the tile `x`,`y` (tiles can be negative), `home`, `abroad`, `aid`,
`fighting`, `atlantean`). A full snapshot always carries `banners`; a delta carries them only when the list changed, and the presentation keeps the last list. Orders answer with `army`: `army_call` / `army_home` (every company in the
city, through `bannersBackFromHome` / `bannersGoHome`), `banner_call <id>` / `banner_home <id>`, and `banner_move <id> <x> <y>` (the banner goes to the tile or the nearest free walkable one, as the SDL right
click does through `eSoldierBanner::sPlace`; refused: `unknown_banner`, `banner_abroad`, `out_of_map`, `other_district`, `no_room`, `pending_decision`). Calling a company out creates its soldiers at once, at the
house that supplies them (`eSoldierAction::sFindHome`), so a company whose houses do not exist sends nobody out (the test city has no elite houses: its hoplite and horseman companies stay at the palace). The orders first settle
finished path tasks and discarded characters (`settle()`), as the tick does: a soldier sent home straight after being called out is a tile-less husk until the next tick, and calling its company out again
inside that window dereferenced its null tile (a crash found by `validate_army.gd`, avoided in the service, not changed in the shared engine). Soldier walkers: the player's soldiers use `walker_hoplite`, `walker_horseman` and `walker_rockthrower` (the Roman army of the Greek cities, as in the SDL view) or `walker_hopliteposeidon`, `walker_chariotposeidon` and `walker_archerposeidon`
(the guard of the Poseidon cities); the test city is Atlantean, so a Greek call-out is checked only through the models. Amazon and Ares warrior companies use `walker_amazonspear`, `walker_amazonarcher` and `walker_areswarrior`. `test_soldiers <hoplite|horseman|rock_thrower> <n>` (validators only) adds soldiers to the companies; the housing redistributes them within a few game seconds. The panel is `ui/army_panel.tscn`
(generated once by `scripts/build_army_panel_scene.gd`, then edited as a scene) with `ui/army_panel.gd`, in the inspector's slot; `scripts/army_view.gd` draws a flag (pole, gold finial, waving cloth in the kind's colour) on
each placed banner and a gold ring on the chosen one. `main.gd`: Game, Army… or F4 opens the panel; a left click on a flag chooses its company; the right button (with a company chosen) or the panel's Place banner button then
a click moves it; clicking elsewhere inspects and closes the panel; Escape cancels a placement, then closes the panel. Fighting and the world map's military dealings are described next.
Fighting: every character type of an army has a model, chosen in `walkerAsset` by type: the player's soldiers (above), the armies abroad and allied (`greekHoplite`/`greekHorseman`/`greekRockThrower` to `walker_greekhoplite` and so on), and the invading
nationalities (`trojan*`, `centaur*`, `persian*`, `oceanid*`, `egyptian*`, `atlantean*`, `phoenician*`, `mayan*`, and the `amazon` with its `isArcher` flag), 25 enemy models in all; the fourteen gods (`walker_aphrodite`, `walker_apollo` ... `walker_zeus`) and the heroes
(`walker_achilles` ... `walker_theseus`, `walker_bellerophon` on Pegasus) too. The seventeen monsters have models too (see "Monsters" below). Each of those 55 models carries the people kit's combat clips as shape keys next to `walk_NN` and `idle_NN`: `fight_NN`, `fight2_NN` (a slinger's
cast), `die_NN`, and for the gods `bless_NN`, `disappear_NN`, `appear_NN` (written by `tools/export_godot_pilot.py` from the identity's `STATES`; the lists `COMBAT` and `MOUNTED` in `tools/godot_asset_sources.py` say which models get clips and which carry a horse and so a larger vertex allowance), and `bake_walker_vat.py` turns them into poses.
Props that the walk puts away (a sword, a club, a thrown stone) are part of the model: their rest geometry comes from the first clip frame that shows them and the poses that hide them fold them to a point inside the body. The snapshot's walker `action` (4 fight, 5 fight2,
6 die, 15 appear, 16 disappear, 17 bless, 18 curse) picks the clip in `scripts/walker_combat.gd`: fight, bless and curse loop at 10 frames a second, die plays once in a second and holds its last frame until the core removes the corpse (2048 time units, under two seconds at top speed), disappear and appear play once
(appear is the disappear clip backwards for a god without its own), and a fighting walker turns to the core's `orientation`. Models without clips keep walking and standing as before. While an enemy force is in the city every snapshot carries `invasion: true` and `invaders` (soldiers of an enemy team alive in the
city; `army` reports the same) and `main.gd` shows them in a red notice (`ui/invasion_banner.gd`); the notice also has a "Go to the invaders" button (the snapshot's `invader_at` is the tile of the invader nearest their middle). The engine defends by itself only for computer-controlled cities (`eBoardCity::updateCityDefense` runs for `!p->isPerson()`): a human player's army stays at home until ordered, so the player calls the companies out and sends their banners to the invasion with the army panel (`validate_fight.gd`
checks that archers called out and sent to the invaders do come out and fight). The invasion's decision (surrender, bribe, fight) was already a decision message with its buttons. `test_invasion <nationality> <infantry> <cavalry> <archers>` (validators only) lands a force of a nationality (greek, trojan, persian, centaur, amazon, egyptian, mayan, phoenician, oceanid, atlantean) at the city's entry point through the engine's own `eInvasionHandler`, with an `eInvasionEvent` that is scheduled ten
years ahead, and a hostile team (`neutralAggresive`), because the test world has only allies. Not ported: any health or damage display (the troop request and the armies abroad are in the military dealings below; monsters follow them).
Military dealings: the SDL world menu's rules are in the `world` query: per city `can_raid` (not a vassal, colony, distant city, a city on the board, or the city played), `can_conquer` (not a distant city, the city played or a neutral one on the board, nor a vassal or colony unless a rival conquered it; for the player's own cities on a board with
several it means reinforcements, `reinforce` true), `aid` (`""` when nothing can be asked, else `not_regarded` at a regard of 65 or less, `cant_spare` below two shields, `present` while its aid is with the city, `ok`), `troops` and `shields` (1 to 5, `1 + troops/20`); the top level adds `rivals` (city indices), `armies` and `enlisting`.
`armies` are the army events on the road (`reason` raid, conquest, help or home, `from`, `to`, `frac` of the way, `size` 0 to 3, `heroes`). A raid or a conquest does not send anything by itself: `world_raid <city>` and `world_conquer <city>` ask the engine for the forces (`eGameBoard::requestForces`, whose front-end hook the service sets) and keep the request as a session; the `enlist` query lists it
(`purpose` raid, conquer, reinforce or troops, the player's `cities`, `soldiers` companies of hoplites, horsemen, amazons and Ares warriors with their `abroad` flag, `heroes` whose halls have their hero, `allies` whose troops may go along, the `plunder` a raid may ask for, `target`), and `enlist_dispatch <plunder resource or -1> [s:<banner ids>] [h:<city>:<hero>,...] [a:<ally city index>]`
sends the choice as the SDL dialog does (`enlistForces`, then the engine's own `ePlayerRaidEvent`, `ePlayerConquestEvent` or `eReinforcementsEvent`, due after `eNumbers::sArmyTravelTime` or `sReinforcementsTravelTime` days); refused: `no_forces` (nothing without a company or a hero), `not_enlistable`, `already_abroad`, `one_ally_only`, `not_offered`, `invalid_enlistment`, `no_enlistment`; `enlist_cancel` drops the session.
The outcome is the engine's: a raid is paid if the army's strength exceeds 0.75 of the city's troops, a conquest wins if it exceeds them (and the city is not at the top military strength), the armies lose a share of their soldiers, attacking an ally costs every ally's trust (a message says so), the army comes home after the same time and its companies walk in at the entry point. `world_aid <city> <own city>` requests defensive aid
(refused as `aid` says; every city's regard falls by 10 and the asked city's by 10 more, and a third of the city's troops arrive about a month later as companies of its own) and `world_strike <city> <rival>` a military strike (30 days). A troop request (`eTroopsRequestEvent`) is a decision whose "send troops" choice has `choice` -2: `event <id> -2` opens the same enlisting (`purpose` troops, `event` the request)
and dispatching it removes the request and sends the help (`help` army). `test_relationship`, `test_attitude`, `test_troops` and `test_troops_request <asked city> <attacking city>` (validators only) set up the test world, which has only allies. The service also words the two placeholders the SDL message box fills itself, `[time_allotted]` and `[travel_time]`.
The Godot side: `ui/enlist_dialog.gd` (the dialog: companies by kind, heroes, allied troops with one city at a time, Enlist all, Clear, Send, Cancel, a plunder chooser for a raid, a city switch when the player has several), `ui/world_armies.gd` (the armies on the map: dashed road, a disc at `frac` with a head and a pip per size step), the Raid, Conquer or Reinforce and Aid buttons of `ui/world_map.gd`
(Aid also offers the strike when a rival exists), and `main.gd` (the "send troops" button of the decision opens the dialog over the city). Not ported: the Ares god as a separate choice (the SDL dialog's rows do not list it), conquest of a city that is on the board (the engine then fights in that city, which the view does not show; not tried), and any display of strengths.
Monsters: all seventeen of the engine's `eMonsterType`s have a model, chosen in `walkerAsset` by character type (`walker_calydonianboar`, `walker_cerberus`, `walker_chimera`, `walker_cyclops`, `walker_dragon`, `walker_echidna`, `walker_harpies`, `walker_hector`, `walker_hydra`, `walker_kraken`, `walker_maenads`, `walker_medusa`, `walker_minotaur`, `walker_scylla`, `walker_sphinx`, `walker_talos`, `walker_satyr`),
with the same `fight_NN`, `fight2_NN` and `die_NN` clips as the soldiers (`COMBAT` in `tools/godot_asset_sources.py`; `walker_combat.gd` plays them unchanged). Eight have a human body from the people kit and take the human adapter (`MONSTER_PEOPLE`: cyclops, talos, hector, minotaur, satyr, medusa, maenads, harpies; the harpies hover about half a metre above the ground, and `validate_characters.gd` expects that);
nine are creatures from the animal kit (`MONSTER_BEASTS`, exported by the `CREATURES` path of `tools/export_godot_pilot.py`: no human adapter, 32,000 vertices at most, the kit's per-point `Coat colour` carried as the vertex palette so a Cerberus is black and not white). The snapshot says while a monster is loose in the city `monsters` (how many), `monster` (the first one's name, from the SDL string table, so it follows the language) and
`monster_at` (its tile); `army` carries `monsters` too. `main.gd` shows them with a red button in the rail under the journal and its card (`ui/monster_card.gd`, from the core's `monster_info`: the monster's own message, its slaying hero, the hall's state, Go / Build / Show buttons); the top notice (`ui/invasion_banner.gd`) is for invaders only. The snapshot's `buildable_revision` moves whenever the engine changes what may be built (a monster or quest allowing a hall); `main.gd` then refreshes the Build menu. The monster's own behaviour is the engine's (`eMonsterAction`: it waits, goes out to attack, patrols, goes back; the kraken and Scylla roam the deep water, the others the roads); the music turns to battle while one is out,
as it does in the SDL game. `test_monster <kind>` (validators only; `calydonian_boar`, `cerberus`, `chimera`, `cyclops`, `dragon`, `echidna`, `harpies`, `hector`, `hydra`, `kraken`, `maenads`, `medusa`, `minotaur`, `scylla`, `sphinx`, `talos`, `satyr`) lets one loose the way a monster event does (`eMonster::sCreateMonster`, `registerMonster`, the aggressive neutral team, an aggressive `eMonsterAction`):
at the entry point, or in the deep water nearest to it for the kraken and Scylla. Not ported: a monster's health or the damage it takes (the engine gives a monster none: only a hero can slay one, see Heroes below) and the god-sent timeline of a campaign beyond what the engine does by itself.
Heroes: the eight heroes' halls are `buildSpecs` rows (`hero_hall_achilles` ... `hero_hall_theseus`, 4x4, built through `buildBase` and then recorded with `eGameBoard::built`, as the SDL view does, so a hero has one hall) under the Build menu's "Heroes' halls" heading (`build_catalog.gd`; the dock's icon is `ui/icons/heroes.svg`). A hall is offered only when the scenario allows its hero: a god's quest (`eGodQuestEvent::trigger`) calls the engine's `allowHero` and says so in a message ("Perseus' Hall"). Each has a model (`art/hero_hall/build_sprites.py --hero <name>`, a Roman heroon with the hero's colours and statue; `RECIPES` in `tools/godot_asset_sources.py`).
The inspection of a hall carries `hall`: `hero`, `hero_name`, `stage` (`none`, `summoned`, `arrived`), `on_quest`, `can_summon` and `requirements` (each `text`, `status` and `met`, worded by `eHerosHall::sHeroRequirementText` and `sHeroRequirementStatusText`, so they follow the core's language and are the SDL inspector's content); a hall that has not summoned its hero updates the requirements on every inspection, as the SDL widget does.
`hero_summon <x> <y> <token>` is the Summon button (it needs the inspection's token like every building control, and is refused as `requirements_not_met`, `already_summoned`, `no_hall`, `not_owned`, `pending_decision`); the engine does the rest: the hero arrives after `sHerosHallArrivalPeriod`, the `heroArrival` event is raised and a hero walker with his model appears. A hero hunts the monsters he is the slayer of (`eMonster::sSlayer`) by himself, and the engine's soldiers cannot hurt a monster (`eCharacter::defend`), so a hero is the only way to slay one.
`world` carries `quests` (the gods' quests: `id`, `god`, `god_name`, `hero`, `hero_name`, `name`, `hall` whether the city has the hero's hall, `ready` whether he has arrived) and `world_quest <id>` sends the hero on the quest as the SDL overview's quest button does (refused: `unknown_quest`, `no_hall`, `hero_not_ready`); the world map's "Quests of the gods" button lists them. Validators only: `test_quest <god> <1|2>` (a god's quest through the engine's own event), `test_hero <hero>` (the hero of the player's hall arrives at once), `test_allow <building name>` (lets the city build what its scenario does not offer).
Two fixes in shared code (`characters/actions/eheroaction.*`; the SDL executable was rebuilt with them): a melee hero fought only within one tile of a monster, but the hunt's path ends on a tile *next to* the monster's (a diagonal neighbour is 1.41 tiles away), so about half the time he stood beside it unable to fight (`fightMonster`'s range is now two tiles); and a hunt that ends in the very step it began (the hero already stands by the monster, or no path leads to it) began the next hunt at once, endlessly, a path search per iteration inside one step, so the city stopped (`huntEnded()`: a hunt that ended in the step it began waits 600 time units before the next search, while a chase that took time re-hunts at once as before).
Sanctuaries: the fourteen gods' sanctuaries are `buildSpecs` rows (`temple_aphrodite` ... `temple_zeus`, `Kind::sanctuary`) under the Build menu's "Sanctuaries" heading (dock icon `ui/icons/sanctuaries.svg`, short label "Temples"). The footprint is the god's layout (`eZeus/Sanctuaries/<god>.txt`, loaded in `prepare()` through `eSanctBlueprints::load()`; 10x6 to 24x16, the quarter turn swaps the sides) centred on the pointer, as the SDL view centres it, and it is founded through the engine's own
`eGameBoard::buildSanctuary` after the SDL view's two rules (`max_sanctuaries`: the city's `maxSanctuaries`; `need_marble`: the initial marble of `eBuilding::sInitialMarbleCost` in the city's stores). A scenario decides which are offered (the test city offers none and has its two); `buildable` also reports each one's `marble` and the city's `sanctuaries` (`built`, `max`, `marble`). `preview temple_<god> x y orientation` answers with the footprint's
tiles, `x`/`y` its corner, `w`/`h` turned, `cost`, `marble` and `pieces` (each `asset`, `x`, `y`, `w`, `h`, `orientation`: temple, court tiles, statues, monument and altar at the offsets `buildSanctuary` uses); Godot draws them as a translucent ghost (`main.gd`: `show_sanctuary_ghost`), the footprint tiles showing whether the ground takes it. A sanctuary is not undoable (its marble would not come back).
The pieces rise as the workers build (each `eSanctBuilding` has stages): a building in the snapshot carries `grow` (percent) while it is less than whole, and `stretch` for a temple, monument or altar that has not begun (the paving tile `sanctuary_court_0` laid over its footprint); `main.gd` scales the model's height by `grow` (a low slab at the least) and stretches the paving. The marble, wood and sculpture are fetched by the engine's carts (a monument is an `eEmployingBuilding` with workers and needs a road beside it), and the god (`walker_<god>`) appears when it stands.
Facing (2 October): the temple's entrance and every god look to the sanctuary's front, along its long axis, not to the camera or a corner. The front is where the yard, monument and altar lie, away from the temple: tile +x for a layout as the file gives it, +y for the turned one (the file's rows run toward the front, and `rotate` swaps rows and columns). The models are authored looking one way (temple pieces 0 and 2 look toward +x, 1 and 3 toward +y, statues and monuments toward +y: in the 3D city the kit's X and Y are the tile's x and y, unlike the SDL view, where kit X is tile +y) and `sanctuaryQuarterTurns` (esimulationservice.cpp) gives each piece the quarter turns that bring it to the front, as the snapshot's and the preview's `orientation`, which `model_basis` already applies; quarter turns keep every pedestal square to the tiles. That is why the monument GLBs are exported with the figure facing +Y (`tools/export_godot_pilot.py` zeroes the 45 degree turn the 2D sprites give them); never turn a piece by anything but a quarter. The altar and the paving keep their facing. `validate_sanctuaries.gd` computes the front from the geometry (from the temple toward the monument) and checks all 28 layouts, the saved city's two turned sanctuaries and a founded unturned one; `run_godot_pilot.py --sanctuary-review <name>` captures the city's sanctuaries from four sides and from above (`captures/sanctuary-<name>-*.png`).
The inspection of any piece of a sanctuary carries `monument` (`title`, `lines`: the SDL widget's wording of the progress, what is still needed and the warnings; `needed`, `stored`, `used`, `cost`, `progress`, `halted`, `employees`; for a finished sanctuary the god's `description`, `help_label`, `help_fraction`, `sacrificing`, `god_abroad`) and `can_control`. `monument_halt <x> <y> <token> <0|1>` halts or resumes the work and `sanctuary_help <x> <y> <token>` asks the god for help as the SDL button does (the answer, `help`:
`granted`, `reason` `too_soon`/`no_target`, `text` from the SDL strings); both need the inspection's token. The `mythology` query is the SDL page: the sanctuaries with their state, the gods attacking and the monsters at large, each with a tile (the Game menu's "Mythology… (F6)", `ui/mythology_dialog.gd`). The fourteen gods' statues and monuments have models (`sanctuary_statue_<god>`, `sanctuary_monument_<god>`, from `art/sanctuary_statues`).
Validators only: `test_allow <building>` also lets one more sanctuary in when the city is at its limit, and `test_stock` now spreads what does not fit in the first store over the others. `test_complete <x> <y>` (validators only) fills a monument's materials and finishes all its pieces at once, and `test_stock` now refreshes the city's cached goods count so what it stocks counts at once (marble for a founding).
God Invasion (3 October): the inspection of a finished sanctuary of the player's own carries `monument.attack` when an enemy city is on the board (`eGameBoard::enemyCidsOnBoard`; only The Sands of Betrayal's Theron among the new games, a few saved campaigns): `label` (the SDL strings' "God Invasion", `zeusText(156, 27)`), `fraction` (`helpAttackTimeFraction()`: the wait since the last request, which the engine shares with asking for help) and `targets` (`city` id, `name`). `sanctuary_attack <x> <y> <token> <city>` asks the god exactly as the SDL button does (`eSanctuary::askForAttack`: the god leaves and `eGodAttackEvent` is raised in that city, which spawns the hostile god there and announces the invasion) and answers `attack_answer` (`granted`, `reason` `too_soon`/`""`, `text`: the god's name and the SDL's own words, strings group 59 entries 19 to 25 by how far the wait has come); `not_an_enemy_city` refuses a city that is not an enemy. Inspector: `building_inspector.gd` `build_attack` (a button, a wait bar and an answer line under the help section; a menu of cities when there are several), `ask_attack`, `show_attack_answer`. `validate_attack.gd` (51, EN/RU) and the windowed review `run_godot_pilot.py --skip-start --attack-review <name>` (the first pass founds and finishes a sanctuary in a new Sands of Betrayal game and reloads the city scene with it; captures `captures/attack-<name>-*.png`).
Sanctuary rites (3 October): the engine's altar (`eTempleAltarBuilding`) sacrifices a sheep, a bull or goods for 25,000 time units roughly every 125,000, which the SDL view draws as an overlay on the altar's sprite (sprite collections 493 to 540: a priestess in a saffron chiton stabbing the animal on the altar, or raising her arms over two jars and a dish); the engine has no priestess walker. The altar now has read-only accessors `sacrifice()` and `sacrificeTime()` (shared header; the SDL executable was rebuilt and signed). The snapshot's walkers list carries each rite of a *finished* sanctuary as two records with `type` -1, a `scene` ("altar"), a `role` ("priestess" with `action` 4, "fight", for an animal or 5, "fight2", for goods; "victim": `animal_sheep_fleeced` or `animal_ox`; "offering": `sacrifice_goods`), the `rite` kind and the altar's `size`, standing at the altar's centre; their ids come from the altar's address (and the byte after it) so they last as long as the rite. `main.gd` places them through `scripts/altar_rite.gd`: the priestess one tile out on the altar's +y stairs (the stairs of `art/sanctuary_altar/build_sprites.py`; she is .87 tall, the table .84, so she stands .30 up, facing tile -y), the victim rolled onto its side on the table (`roll`, applied to the node each frame; the ox model is pale, so a multiply overlay browns it and it is shrunk to .72), the goods built in code (`goods_node`: three amphorae, a dish, fruit). The three tripod braziers of every finished altar burn as animated flame meshes (`AltarRite.Fires`, shader `shaders/ritual_flame.gdshader`, one instance uniform `burn`) that rise higher while a rite is on that altar; the model's own static flame stays under them. The priestess is `walker_priestess`: `art/characters/people/people11.py` (registered in `people.py`; wardrobe profile "Priestess" in `art/characters/roman/wardrobe.py`; `RITE_PEOPLE` in `tools/godot_asset_sources.py`, a COMBAT model with `fight` 24 frames, `fight2` 12 and `die` 8), exported with `export_godot_pilot.py --asset walker_priestess`, 15,500 vertices. Validators only: `test_sacrifice <x> <y> <sheep|bull|goods>` begins a rite on the altar at that tile. `validate_rites.gd` (47) and the windowed review `run_godot_pilot.py --skip-start --rite-review <name>` (three kinds from three sides; `captures/rite-<name>-<kind>-<yaw>-<n>.png`). Not done: the temple's emissive doorway does not flicker, and the SDL overlay's goods frames also show a second figure (apparently a priest in a pale cone hat) beside the altar, which is not shown.
Pyramids, monuments and shrines: the expansion's 54 wonders are `buildSpecs` rows (`Kind::pyramid`, added to the table by `withPyramids()`): `pyramid_modest`, `pyramid_standard`, `pyramid_great`, `pyramid_majestic`, `pyramid_sky_small`, `pyramid_sky`, `pyramid_sky_grand`, `pyramid_pantheon` (9x11), `pyramid_altar`, `pyramid_temple`, `pyramid_observatory` and `pyramid_museum` (the Build menu's "Pyramids", dock icon `ui/icons/pyramids.svg`) and `shrine_minor_<god>`, `shrine_<god>` and `shrine_major_<god>` (42; "Shrines", `ui/icons/shrines.svg`). The footprint is `ePyramid::sDimensions` (3x3 to 9x11, no turning), centred on the pointer, and the founding is the engine's own
`eGameBoard::buildPyramid`; there is no drachma cost and no marble up front (`cost_text` says "Materials by cart": the carts bring marble, orichalc, sculpture and, for a dark level, black marble as the monument is built, and an artisans' guild sends the workers). A scenario grants each one once, with its dark and light levels (`eAvailableBuildings::allowPyramid`; `supportsBuilding`): the saved city grants the standard pyramid (its own modest pyramid stands), five of the 26 adventures grant
pyramids or shrines, a pyramid is used up when founded and given back when the finished one is demolished (the engine frees it a few steps later). `preview <name> x y 0` answers as for a sanctuary (`x`/`y` the corner, `w`/`h`, `tiles`, `pieces`), each piece also with `lift`, the native altitude steps its level raises the ground (four a level), so that the ghost stands the capstone on its raised ground. The pieces come from `ePyramid::sPlan(type)`, which exposes the layout tables that `ePyramid::initialize` places
(they moved into `sLayoutTables`; the SDL behaviour is unchanged, including the middle shrines' two appended levels). The snapshot maps each piece in `asset()`: the faces and capstones are the existing `pyramid_p1_<n>` and `pyramid_p2_<n>` (`pyramidWallAsset`: light or dark, stairs, eagle, wreath), floors `palace_tile_plain`, `pyramid_p2_32` to `pyramid_p2_34`, statues and monuments `sanctuary_statue_<god>` and `sanctuary_monument_<god>`, `sanctuary_altar`, `sanctuary_temple_0`, `observatory` and `museum`; a filler
tile of a larger piece (`pyramidPart`) is `native_marker`, and a piece of 2, 4, 5 or 6 tiles on a side is registered by the engine at its far corner only, so the snapshot gives it its real rectangle (`pyramidPieceSize`). Construction: a piece first raises its ground (the engine lifts the tile a step for each of the four stages of every level, so the terrain in the city rises under a paving slab), then is built; a piece with stages (the temple's three, the monument's two) rises with `grow`. `main.gd` lowers the pyramid models by `PYRAMID_RISE` (.22 / (30 / 73.48)):
they are authored at the SDL game's proportions (a level is 30 px, .408 of a tile) while this view raises the ground .22 of a tile a step, so that a ramp ends exactly at the ground of the next ring. The inspection of any piece is of the monument (`monument.pyramid` true, no god, no help): the progress and what is still needed in the SDL's words, `monument_halt`, and, once finished, the game's description (group 132, lines 114 to 128; a shrine names its god). Validators only: `test_allow <name> [levels]` grants one (`0` or `1` for each level, 1 = black marble; light and dark by turns when none are given; a
pyramid already built, as the saved city's modest one, cannot be granted until it is demolished) and `test_fund <x> <y>` puts into a monument all the materials it still needs (the workers still build it). Godot: the two Build categories, the ghost (`show_sanctuary_ghost`, now with `lift`), `building_inspector.gd` (the description of a finished one), and the review tool `run_godot_pilot.py --pyramid-review <name>` (the city's own pyramids from four sides and above), `--pyramid-review=build:<tool>,...` (founds, funds and captures each at the foundations, partway and done) and `--pyramid-review=menu`; a review that calls `core.query("build ...")` itself must pass the answer to `city.receive_state` (the
answer is the snapshot of what changed and nobody else sees it). Not ported: the cube stages of the SDL sprites (`pyramid_p1_34` to `pyramid_p1_43` exist as renders but are not exported: construction shows the rising ground under a slab), a choice of dark and light levels by the player (the scenario decides), the Atlantean finish of the Temple of Olympus, and any animation of the observatory and museum on top.

The rest of the SDL build menu (3 October): `withMenuRest()` rows in `buildSpecs` for orchards, livestock, fishery, urchin quay, trireme wharf, horse ranch, palace, stadium, bridge, roadblock, the three columns, avenue, boulevard, water park, hippodrome (plates), crosswalk, `monument_<id>` (9 commemoratives) and `god_monument_<god>` (14). Their placement rules are shared with the SDL view in `engine/ebuildplacement.{h,cpp}`; change a rule there, never in one view only, and rebuild and sign `Bin/eZeus` too. Anchors: shore buildings and hippodrome plates take their first tile like a pier (the SDL view's tile is one further on), the palace, stadium, ranch and god monument the SDL pointer tile; the turn (T) picks the hippodrome plate and the water park's variant. Orchards and livestock are `build_area` tools; columns, avenues and boulevards `preview_path` / `build_path` (a click is a one-tile path). Monuments and crosswalks are not undoable. Test with `validate_menu_rest.gd`; review with `run_godot_pilot.py --menu-rest-review menu|build`. A building taken away by undo or demolition leaves the board at the next simulation step: validators that rebuild on the same site first `core.replay(4)`.

City data, taxes, wages and priorities (3 October): `city_data` answers the SDL side panel's pages, the tax and wage rates, the workforce allocation and the finances; `set_tax`, `set_wage`, `set_priority`, `man_towers` change them (answer: the new data). The pages' verdicts live in `engine/ecitydata` and the SDL data widgets call it: change a threshold or a string there, not in one view. Tax rates must be stepped with `eCityData::stepTaxRate` / `taxRatesInOrder` (the enum's veryLow is 7%, low 3%). Godot's window is `ui/city_dialog.gd` (F7, Game, City…); test with `validate_city_data.gd`.

Triremes, races and the two pages (4 October): race chariots are missiles; the snapshot adds them to the walkers from the hippodrome plates' tiles (no `+.5`: missiles and walkers share the tile space). `trireme_move`, `building_switch` and the inspection's `notes`/`switch`/`hippodrome` are described in slice 27 of the migration document; the page texts live in `engine/ebuildinginfotext` (shared with the SDL widgets). The hippodrome tool turns 0-7 in `preview`/`build` and in `turn_placement`. When recolouring an export, set the material's `diffuse_color` too: the vertex palette is read from it. Test with `validate_naval_race.gd` (`test_trireme`, `test_race`).

Leaders and cities (4 October): saves live in `user://saves/<leader>` (`scripts/leaders.gd`, `SaveFiles.directory()`); older root saves are listed, never moved. Tests and reviews must set Engine meta `ezeus_save_directory` and `ezeus_settings_path` to scratch paths so the player's profile is untouched. The core's pages follow `playerCity()` (the player's district in view, reported by `view_tile`); use it rather than `currentCityId()` for anything the player governs. `--start-review leaders` drives the start menu and then a two-city adventure.

Requests, groups, rowing (4 October): `banners_move` takes several companies (`eSoldierBanner::sPlace`); `scripts/unit_selection.gd` draws the selection box. `view_tile` in a snapshot moves the camera once (player invasions and god attacks; the event fires inside the sending command, so validators must read that command's next answers). Person exports take their clothing colours from `art/characters/roman/wardrobe.py` by the person's name: a new people-kit entry needs a row there, or it wears the default cream and red. Ships keep a 35,000-vertex budget when posed. Building workers: add a building to `tools/building_activity_assets.json` and run `tools/export_building_activity.py --assets <name>`.

Remaster extras (4 October): the SDL remaster's City Advisor, Trade Summary and house card draw from shared engine code (`engine/ecityadvisor`, `engine/etradesummary`, `buildings/ehousecard`; keep the SDL widgets on them rather than adding logic back to the widgets). The core answers `city_history`, `city_advisor`, `trade_summary`, `house_card <x> <y>` and the route commands (`route_begin <x> <y> <token>`, `route_toggle`, `route_clear`, `route_restore`, `route_both`, `route_end`, `route`); a route's walk comes from the board's path-finder thread, so it appears only after the city advances (validators call `advance`, reviews unpause). The City window's Advisor/History/Trade pages sit after Mythology (tab indexes 12-14); `scripts/route_editor.gd` takes the map's left/right clicks while active and is ended by Escape, a right click or any tool; `ui/house_card.gd` shows only with the select tool and nothing under the pointer. Test with `validate_city_extras.gd`; review with `--menu-rest-review extras`.

Disasters (4 October): burning buildings come in the snapshot's `fires` list (not the building records, so a fire does not rebuild the static batches); `scripts/building_fires.gd` draws them. Ruins are `ruins_<seed % 8>` from `art/lots/build_sprites.py` (recipes `ruins_0`..`ruins_7`). Chasm, lava and marsh are the G, B and A channels of `terrain_presentation.gd`'s pattern texture, drawn in `ground.gdshader` (R stays the quarry blocks). Validator commands `test_fire`, `test_collapse`, `test_earthquake`, `test_terrain` answer briefly; any command that answers with a snapshot (including `pause` sent as a query) consumes that delta, so tests that need the view to see a change must not query such commands in between (send them through the queue). New GLBs need a `data/geometry_baseline.json` entry: merge new assets in rather than rewriting existing counts. Test with `validate_disasters.gd`; review with `--menu-rest-review disasters`.

Controls and settings (3 October): `scripts/key_bindings.gd` (static, `KeyBindings`) is the one table of rebindable controls (33: eight held camera keys, the city overview, the placement turn, the demolition tool, undo, pause, quick save and load, the world map, army and mythology keys, mute, the details panel, fullscreen (default Alt+Enter) and the overlays' keys) with their defaults, kinds and rules. A binding is one code, the physical key plus Ctrl/Cmd and Alt (Shift is never part of one: it stays the fast-pan and wall-fill modifier, and a key matches with or without it;
the SDL game's own Ctrl/Cmd+Z for undo is one of the defaults). Held camera keys (`orbit_*`, `tilt_*`, `pan_*`, no modifier allowed) are InputMap actions kept in step by `apply_input_map()`; every other handler asks `KeyBindings.matches(event, id)` (`main.gd`'s `_unhandled_input`, `ui/world_map.gd`), and `overlay_for(event)` names the overlay of a digit, Tab or the back quote. `assign(id, code)` hands a key over and gives the control that had it the key the first one leaves (refused: `reserved` for Escape, Delete and the modifier keys, `modifier` for a held, overview or overlay key
with Ctrl/Cmd/Alt, `swap_refused` when the other control could not take the old key); `reset(id)` and `reset_all()` put keys back. Choices live in `user://settings.cfg` section `keys` (only what differs from the default; a damaged file, or one that gives a key to two controls, is not believed and the defaults hold), never in the original game's `settings.txt`. Automation sees the defaults and never writes the player's file, unless a test points `Engine` meta `ezeus_settings_path` at a scratch file and calls `KeyBindings.reload()` and `PlaySettings.reload()`.
`scripts/play_settings.gd` (`PlaySettings`) holds the other options, each with a default and its own short list of values: `autosave_minutes` (0 off, 2, 5, 10, 15, 30; default 5), `autosave_slots` (1, 3, 5, 10; default 3), `fullscreen` (applied at start by `ui_accessibility.gd`, toggled by its key), `voice_language` (auto, en, ru; `audio_manager.gd` takes the voice folder from it) and the camera's `pan_percent`, `turn_percent`, `zoom_percent` (50 to 200; `orbit_camera.gd` scales its pan, turn and tilt by them, and the wheel and the middle-button drag too). The Game menu has two new entries,
"Controls…" (`ui/controls_dialog.gd`: every control by group with a button for its key, a click asks for the new key, Escape cancels, a swap or refusal is said in words, Reset per control, Restore defaults, the camera speeds and the list of fixed controls; `assign_from_event` is its testable core) and "Game settings…" (`ui/game_settings_dialog.gd`; the running city's autosave follows at once through `main.gd`'s `apply_play_settings`). Everything that names a key (the Game menu's quick save, world map, army and mythology entries, the overlay menu's `[key]`, the undo, turn
and pause tooltips, the camera hint) is built from the bindings, so the interface strings no longer carry key names; the hints' translations are formats (`%s`). Review tool: `run_godot_pilot.py --controls-review <name>` (scratch settings; captures the dialogs). Display settings now provides window dimensions/fullscreen/monitor controls; see the current handoff above. Not ported: classic font, weather, monthly-summary and edge-scroll options; mouse buttons and the arrow keys of the world map cannot be rebound.
Walls and defence: `wall`, `tower` and `gatehouse` are `buildSpecs` rows under the Build menu's "Walls and defence" heading. A wall is dragged
as in the SDL view: `preview_wall x1 y1 x2 y2 fill` / `build_wall ...` cover the outline of the rectangle between two tiles (all of it with
Shift, the `fill` flag), each tile built or skipped on its own (`not_owned`, `occupied`, `needs_flat_ground`, `blocked_terrain`) until the
treasury is 1000 drachmas in debt, one undo step per drag; the preview carries each tile's connection mask (1 x-1, 2 x+1, 4 y-1, 8 y+1, as the
snapshot's `wall_<mask>` assets) so the Godot drag (`road_drag.gd`, tool "wall") draws the real wall models, up to 400. Tiles off the map are
skipped silently, as in the SDL view, so a test plot must count its pieces. A tower is an ordinary 2x2 building (an employer: its archer appears
once staffed). A gatehouse (`Kind::gate`) is two 2x2 towers around a one-tile passage: 5x2 tiles, or 2x5 turned (T, orientation 1); (x, y) is the
corner of the whole footprint, the ten tiles are checked one by one (`gateReason`: free building ground, but the two passage tiles may be an
existing plain street that belongs to no agora, gatehouse or hippodrome), the gatehouse takes them and lays road under the passage, and it is
charged once. Demolishing any passage tile targets the whole gatehouse and, as natively, empties all ten tiles. The snapshot gives a gatehouse
its facing from its footprint. Archers (type `archer`, asset `walker_archer`, the people kit's archer identity) patrol the tops of wall and tower
tiles: the walker record carries `lift` (0.8 on a wall, 2.57 on a tower, in tiles) and `main.gd` adds it to the walker's height offset.
Native defect fixed in shared code: `eGatehouse::erase` left its passage roads registered but off the map (they came back on the next save);
it now erases them. A saved and reloaded city is not identical to the live one when an employer (tower, tax office, watchpost) was built
since the open: several other employers (vendors, storehouses) show one more worker after the reload, the cause is not yet found, so
`validate_saves.gd` leaves towers out of its strict digest comparison and `validate_walls.gd` saves and reloads one by building list. The gatehouse model is composed in `tools/godot_gatehouse.py` from the tower script's `--gate` towers.
Campaign flow: the service keeps the campaign across episodes (`detach()` lets go of a city, `close()` of everything). A won
episode (the board's own goal check, `mVictory`) stops the game; `finish_episode` books it (`eCampaign::episodeFinished`: treasury,
date, goods set aside) and answers with what is next: the end of the adventure, the next parent episode, or the colonies on offer
(`choose_colony i`); `preview_episode` is the briefing (the episode's template goals), and `begin_episode` starts it
(`eCampaign::startEpisode`, possibly on another board: a colony), writes "autosave replay" (the retry point; the start menu writes it
for the first episode) and re-enters the session. The city scene then restarts and adopts the same simulation
(`main.switch_session`). The screens are `ui/episode_card.tscn` (one layout, five modes; also the start menu's briefing page) inside
`ui/episode_overlay.tscn`, which only drives those commands and reports by signals. `set_aside i` is the SDL goals window's button
(goods leave the stores, the goal counts as met); `difficulty [n]` reads or sets the campaign's level (applied at once, kept across
episodes). Collisions to avoid: the goal count is `total`, the episode count `episode_count`. `test_win` and `test_stock` exist only
after `EZeusSimulation.enable_test_commands()` (validators); the game never calls it.
Sound: `scripts/audio_manager.gd` is the autoload `GameAudio` (music, effects, ambient, voices on four buses, per-user volumes and
mute in `user://settings.cfg`, `ui/sound_dialog.gd`, M key). It reads the original files straight from the workspace `Audio/` folder
at run time (WAV and MP3; nothing is copied or imported). What plays comes from the core: `eSoundVector::setSink` hands every sound
the native rules ask for (fire, collapse, quarrying, gods and monsters, combat, the building-placed sound) to the service as a file
name (snapshot `sounds`), `eMusic::setModeSink` reports battle or peaceful music (snapshot `music`; the embedded core has no
`eMusic`, and an invasion used to dereference it), and the commands `ambient x y` and `building_sound x y` run the native
`playSoundForTile` and `playSoundForBuilding` tables. Which of several files plays uses `eRand::cosmetic()`, never the simulation
generator, so sounds cannot change a replay or differ between the SDL game and the embedded core; keep it that way. Automation
(`--validate`, captures, reviews, `--silent`, headless) leaves the manager disabled; tests enable it with the master bus muted and a
scratch settings file (`ezeus_settings_path` meta). A script run registers autoloads after compiling the script, so a validator must
`load()` (not `preload`) anything that names `GameAudio`.
Overlays: the SDL game's view modes (water, supplies, hygiene, fire and collapse risk, appeal, taxes, unrest, security, roads,
problems, farming, industry, storage and trade, immortals, culture and science groups; 25 with the normal view) work with the SDL
hotkeys 1-9, Tab and 0. The core's `overlay <id>` query answers from the native rules: `eViewModeHelpers::buildingVisible` and
`characterVisible` decide what stays visible, the per-house values are the ones `eGameWidget::drawBuildingModes` reads, and the
appeal grid applies the same rating rule as the SDL paint. `scripts/overlays.gd` is the catalog (names, legends, hotkeys, tones),
`scripts/overlay_view.gd` draws columns, supply markers and the appeal Decal, and `main.gd` applies the filters (hidden buildings
lie flat in the footprint batch, hidden walkers are invisible nodes) and polls once a second (appeal every three). A new overlay is a
catalog entry plus its core mapping; keep the data read-only (`validate_overlays.gd` checks the replay digest is unchanged).
Start menu and new games: `ui/start_menu.tscn` (script `ui/start_menu.gd`) is the project's main scene. Continue opens the
newest save, New game lists the adventures, Start reads one and shows its first episode's story and objectives, Begin hands the
opened simulation to `main.tscn` through Engine meta `ezeus_simulation` (`core_link.adopt`, so the campaign is read once);
saves go through meta `ezeus_load`. Any automation flag (`--validate`, `--capture=`, the reviews, `--bridge-port=`, or
`--skip-start`) skips the menu and opens the designated test city, so validators and reviews are unchanged; the launcher passes no
`--lang` unless asked, so the menu opens in the language the player last chose (`user://settings.cfg`, `scripts/user_settings.gd`).
The adventure list is the SDL menu's own: `engine/eadventurelist.*` (shared by both views), exposed as
`EZeusSimulation.adventures` and `open_adventure(kind, ref)`, which opens only what the listing offers. The `episode` query gives
titles, introduction and the objectives with live status (same texts and progress rule as the SDL tracker); the HUD's
objectives panel polls it every two seconds, and a finished episode shows its result card. (Campaign progression to the next
episode and the colonies followed; see the campaign flow below.) Saves live in `user://saves`
(`scripts/save_files.gd`); tests redirect them with Engine meta `ezeus_save_directory`. The binding caches the building list only
for snapshots: other answers that carry a `buildings` key (the build menu's `buildable`) must never replace it.
Build-menu contracts: the core's static `buildSpecs` table (presentation/esimulationservice.cpp: mode, native type,
footprint, model name, fertile/flat flags, constructor) is the only list of what can be built; never probe by constructing a
building (a constructor registers with the city and draws random numbers, which changed the replay digest). The Godot menu
is `scripts/build_catalog.gd` (category per name, English `NAMES` equal to the core's English labels) over the `buildable`
reply, filled in `main.gd` after the core opens; labels are `tr()` keys from `data/building_names.csv` (a second Russian
translation registered in project.godot, kept apart from the interface strings because the orphan gate reads only those).
Markets: `engine/eagoraplacement.*` holds the one rule for laying a common or grand agora over a stretch of road
(`find`/`build`) and for filling its spaces with vendors (`canPlaceVendor`/`placeVendor`); the SDL widget delegates to it, so
never reimplement it. The pointer tile only seeds the search (like the SDL view), a vendor tool picks the space by any of its
four tiles, each agora takes one vendor of each good, and the wine, arms, horse and chariot vendors share the stall models of the other three (`art/agora/build_stall.py --kind`; the horse trainer is offered only where the city's culture allows it, which the test city does not; they used to stay hidden until they had models). An empty space is `agora_space`, drawn by `main.gd` (`add_plaza`) as pale paving. `buildSpecs` rows carry a `Kind`
(standard, agora, vendor) for these.
A new building needs a `buildSpecs` row, a category and name here, a Russian name, and a model before it is shown.
`validate_buildings.gd` fails while any listed name lacks a category, English name or Russian name.
Playable-loop contracts: roads are placed by `preview_road`/`build_road` (one path rule shared with the SDL view; never
loop single `build road` calls from the UI). Saves go only to the per-user `user://saves` directory in the native `.ez`
format through `save_city`; never write into `Save/` or beside the original game, and never open anything but the designated
test save or that directory. A load restarts the scene (`Engine` meta `ezeus_load`) rather than patching a live city, so any
new presentation cache needs no reset code. Messages: toasts for dismiss-only messages, the top-centre box for decisions,
everything in `message_log.gd`. The core words the events the engine raises itself (`eEvent::monthlySummary`, `shortageWarning`,
`riskWarning`) in `presentation/eenginemessages.h`, from the SDL view's own `text/language*.txt` keys and the city history (the card reads the same in both
views; keep the two in step); an engine event without a catalogue message would otherwise arrive titled with its raw name and no text. `event_texts` and
`test_event` (validators only) audit and raise them, and `validate_embedded.gd` gates it. The other 103 kinds that the SDL view words in its own handlers from god, monster, hero and city data (gods' visits, invasions, help, quests, disasters and
trade resumptions, the monster and invasion timelines, hero arrivals, the 15 sanctuary, pyramid, monument and shrine completions, and the 63 comply / too-late / refuse replies to requests) are worded in `presentation/eeventwords.h` from the same `eMessages` tables and
substitutions (`[reason_phrase]`, `[hero_needed]`, `[time_until_attack]`, then `eMessageBox::sFormatText` for the city, god, monster and amounts), with the god, monster and hero voice lines asked for as the SDL view asks (they arrive in `sounds`); keep the two in step. Differences, on purpose: every
occurrence of `[reason_phrase]` is filled (the chimera's warning names the reason twice and the SDL view's single replace leaves the second), and `playerInvasion` and `playerGodAttack`, which the SDL view shows only as alert tiles, are silent. `test_raise <event> [god g] [monster m] [hero h] [time n] [quest 1|2] [reason w] [city i]` (validators only) raises any
event kind through the board's event path, `event_texts` must list none, and `validate_events.gd` checks all of them in both languages. Informational ones become toasts (showing the condensed wording the core sends as `brief` when there is one, as the SDL view's pop-up cards do) and log entries (with the whole text) like every dismiss-only message.
The minimap draws only what main.gd hands it.
Diagnostics: `EZEUS_RAND_TRACE=N` prints the call stacks of the first N worker-thread random draws, and `EZEUS_REPLAY_DUMP=file` keeps the
serialized state of an SDL replay for byte comparison.

The helper prepares pinned dependencies, builds `build-godot/`, then finalizes and
signs `godot/bin/` libraries. Do not skip finalization after relinking. Keep the
private SDL2 with video/audio drivers disabled; do not redirect it to Homebrew
SDL2-compat/SDL3 or modify system libraries. The README records dependency pins.
The local setup still needs the parent runtime/assets and Homebrew dependencies;
a standalone checkout is not yet a self-contained release.

If rebuilding the native SDL reference executable, run from this directory:

```sh
ninja -C build
cp build/eZeus Bin/eZeus
codesign --force --deep --sign - Bin/eZeus
```

Always copy and sign after a native executable rebuild. The extension helper
does not rebuild that executable. Close only the owned preview before replacing
loaded binaries; never terminate unrelated Godot, Blender or game sessions.

## Save, asset and handoff safeguards

- City testing uses **`Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`** only. Keep
  Godot preview changes in memory; preserve the launcher's before/after save and
  settings checks. Do not enable autosave or overwrite personal saves. Original
  `.sav` files are unsupported by this core. Save serialization tests may use
  disposable copies derived from the designated test city.
- Inspect existing Git changes before edits; preserve unrelated remaster work.
  Check binary sizes before committing; generated GLBs, libraries, captures and
  editor caches are currently ignored. No commit or publishing is implied.
- Reuse local Blender source geometry and paired model manifests. Read relevant
  parent `art/**/DESIGN_REFERENCE.md` benchmarks. Preserve distinct anatomy,
  actual female/child meshes, ground anchors and independent trees. Blender +Y
  forward becomes Godot −Z after Y-up GLB export; apply this conversion once.
  Use background `tools/export_godot_pilot.py` exports to protect the live scene.
  Native atlas sizes are not a Godot mesh contract.
- Preserve English and Russian text/input paths. Test high-DPI scaling when
  changing native font sizing. The EN/RU presentation toggle and native message
  launch language are separate; Godot plays the original game's sound (see the sound contract below).
- Preserve required upstream author/GPLv3/dependency notices and provenance
  evidence. Original commercial content and new export manifests are not cleared
  merely by rebranding. Follow the production roadmap before release work.
- Update `godot/README.md`, `docs/GODOT_MIGRATION.md` and
  `docs/GODOT_VALIDATION.md` together as scope changes. Record commands, results,
  limitations and remaining work; distinguish implemented from verified and
  production-ready. Do not turn transient process IDs into standing instructions.
