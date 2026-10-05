# Godot 3D city rebuild

## World-map water, terrain and controls — 4 October 2026

The regional map now has continuous water: the submerged rectangular relief sheet
is clipped at the coast, and the sea mesh has finer curvature. Nonmetallic ripples,
turquoise shallows, quieter foam, weathered limestone, varied woodland sizes and
softer clouds refine the finish. The map keeps its existing artistic elevation.

**Arrow keys or WASD** pan relative to the camera; **Q/E** orbit, **R/F** tilt
25–75°, and **Shift** pans faster. These share the city's rebindable camera keys
and speed settings. The on-screen previous/next buttons still select cities.
Dialogs, text entry, flight and focus loss suppress camera input. Compact framed
headings/controls and a narrower city panel leave more room for the map; portraits
stay circular. Owned-city stock comes from the native world response.

Sequential EN/RU map reviews pass **61 checks each**, including a 180-sample
rendered water comparison and 125%/150% layout checks. Flight reviews pass **37
each**, and native dealings retain 16 checks plus five integration checks. See
[atlas contracts](../docs/GODOT_WORLD_ATLAS.md) and
[validation evidence](../docs/GODOT_VALIDATION.md). Relaunch an existing game to
load these changes. User art acceptance and sustained minimum-Mac profiling remain
pending.

## Fishing spots and authored gathering — 4 October 2026

Animated fish schools and spiny urchin clusters identify native water deposits.
Fishing skiffs now have a seated, hand-driven cast-net cycle: gather, throw,
settle, haul and stow, with rowing tools put away during work. Urchin gatherers
use authored dive/reach/recover, bag-carry and deposit clips. A Godot-only timing
adapter shortens the submerged dip and holds the visible recovery; it does not
change native collection timing. Entry, exit and work-state transitions blend.
Small phase-matched surface glints and three diver bubbles replace the oversized
effects. Motion follows native gameplay time, pause and required decisions.

See [water-life contracts](../docs/GODOT_WATER_LIFE.md) for sources, budgets,
opaque-water limits and reproducible export/review steps. Run
`validate_water_life.gd`, `validate_gathering_motion.gd` and
`python3 tools/review_water_life.py --lang en --record` (or `ru`) for scoped
checks and designated-city captures. Wider campaign art review, user visual
acceptance and minimum-Mac profiling remain pending.

## Monster combat effects — 4 October 2026

Hydra now emits green venom breath and travelling shots, visible contact splashes,
and a dust/debris burst after native building destruction. All 17 monster kinds
share the projectile/impact pipeline; other species currently use a warm generic
finish. Effects obey native pause, speed and required decisions. Building fire
and smoke retain their existing renderer. The new three-headed Hydra now uses
pose-sampled mouth anchors; see the model handoff below.

See [monster effects contracts](../docs/GODOT_MONSTER_EFFECTS.md) and
[validation evidence](../docs/GODOT_VALIDATION.md). Review the real native Hydra
attack with disposable preferences: `python3 tools/review_monster_effects.py
--lang en --record` (also `--lang ru`; recording needs ffmpeg or Pillow).

## Hydra reference model — 4 October 2026

The new three-headed Hydra replaces the Godot model: heavy four-legged body,
curving necks, dark scales, fitted belly bands, crimson eyes and black spines.
It measures about 2.1 times a displayed citizen and 81% of Zeus body height.
Walking, breathing, bites, venom and collapse use the existing native action
and gameplay clock. Both UV sets, palette, reduced LODs and baked poses remain.

Read [monster art contracts](../docs/GODOT_MONSTER_ART.md) for the reproducible
Blender source, editable scene, measured budgets and validators. The previous
runtime model is preserved in the parent art workspace. User visual acceptance,
full material baking, slope foot IK and minimum-Mac profiling remain pending.

## Elder curator portrait reference — 4 October 2026

The Character panel now uses one detailed **68-year-old curator** candidate with
aged facial structure, fine swept-back hair, shorter fuller eyebrows and a short salt-and-pepper
beard. City walkers retain their existing assets. The panel gives this specimen
its own material, full mesh detail, 1.5× rendering scale and closer framing;
switching roles restores ordinary portrait quality settings.
See [the reusable portrait reference](../docs/GODOT_PORTRAIT_REFERENCE.md) for
source, rebuild commands, captures, budgets and limits. Visual acceptance remains
pending; this is one static benchmark, not a catalog rollout.

## Hillside appearance — 3 October 2026

Exposed slopes now use layered, weathered limestone with subtle surface relief
and a grass transition at the rim. The same finish covers steep countryside.
Native elevations, roads, foundations and picking remain unchanged. To capture
matched comparisons with temporary preferences:

```sh
python3 tools/review_hillsides.py
```

See [terrain contracts](../docs/GODOT_TERRAIN.md) and
[verification evidence](../docs/GODOT_VALIDATION.md). This pass changes shading;
terrain silhouette remodelling and minimum-Mac GPU profiling remain pending.


Double-click **`Launch Godot 3D.command`** in the workspace root. It opens
Godot with the existing C++ simulation embedded in the same process and shows
the **start menu**: *Continue* (the newest save), *New game* (the 26 adventures
of the original game and the engine's own, each with its story and objectives),
*Load game*, language and *Quit*. There is no hidden SDL window, renderer or
native game subprocess. New and loaded games start paused; construction and
simulation changes stay in memory until you save (Game menu, F5 quick save;
saves are native `.ez` files in Godot's per-user `saves` folder and open in the
SDL game too). The Game menu's *Main menu* returns to the start. The designated
test city is for automation: `python3 tools/run_godot_pilot.py --skip-start`
or any validation/capture/review flag below opens it directly, and the launcher
checks that the test save and both settings files stay unchanged when the
window closes.

The start menu now opens on the **Gates of Hades**: a monumental stone arch,
carved Hades guardians, a living ember portal, braziers, drifting souls and mist
above the Styx, with a cloudy night sky and subtle mouse camera parallax. Menu
controls sit on the left to keep the gateway visible. This is menu scenery only.
Review it without opening a city or touching player preferences:
`python3 tools/review_menu.py --lang en --size 1920x1080` (also `--lang ru`).
See `assets/menu/menu_sources.json` for retained art inputs and budgets; visual
acceptance, minimum-Mac profiling and production clearance remain pending.

Hades now has an older original angular face, slate-blue skin, amber eyes, a
silver-gray beard and red flame hair. His long midnight chiton, shoulder mantle,
curled train and bronze bident remain. Animated fire and embers surround the cape
hem, follow his movement and blend with his native disappearance/reverse arrival.
The menu guardians are stone derivatives of this same model. All fourteen gods
float instead of walking (3 October): a hover pose, a slow bob, a lean into their travel and a slow turn
(`scripts/god_float.gd`, `tools/godot_god_float.py`). This is a Godot-only
art pass; native atlases, sanctuary monuments and the physician benchmark stay
intact. Review: `python3 tools/run_godot_pilot.py --character-review after
--character-subjects walker_hades --lang en`. See `docs/GODOT_CHARACTER_ART.md`
for rebuilding and the outstanding visual acceptance/provenance gates.

The **World map (F2)** is now a living 3D regional globe with raised coastlines,
mountains, animated water, drifting clouds, decorative sailing ships and small
city landmarks. Arrow keys/WASD pan, Q/E orbit and R/F tilt; mouse drag orbits, wheel/pinch zooms and right drag pans. Overview
and Focus city frame the region or selected city. Names, relationships, trade,
requests and military actions still come from the native world. The city stays
held while the atlas is open; closing restores its rendering and prior running
state. Both Greece and the four Poseidon map regions are supported. Review with
`python3 tools/review_world_atlas.py --lang en` (also `ru` and `--native-ui`). See
`docs/GODOT_WORLD_ATLAS.md` for source contracts, evidence and remaining art gates.

Zooming outward past the city limit now **flies up through cloud wisps into the
world atlas**. Wheel and trackpad pinch share the same 1.55-second ascent; F2 and
Escape menu → World map use it too. Escape or Back to city descends in 1.20 seconds to
the exact city target, zoom, angle and tilt you left. Escape during ascent queues
one safe return. Controls fade in after arrival; city time and queued city
commands remain held throughout the flight/map. Home still fits the city, and
M keeps mute/unmute. The atlas is prepared during paused city loading and stops
rendering while hidden. Review: `python3 tools/review_world_atlas.py --flight
--lang en` (also `ru`).

| Control | Action |
| --- | --- |
| Q / E, held | Continuous 360° camera orbit |
| R / F, held | Raise / lower camera tilt, using the same movement as middle drag |
| WASD, Shift | Camera-relative pan, faster while Shift is held |
| Mouse wheel / trackpad pinch | Cursor-anchored city zoom, in to a closest view of about ten tiles (`MINIMUM_DISTANCE` in `orbit_camera.gd`); beyond the outward limit, fly into the world atlas |
| F2 | Fly to the world map / return to the city |
| Middle drag | Camera yaw and tilt |
| Right click | Cancel construction or close the current panel; on a walker, open its character window (paused, with its spoken line and voice); inspect a tile when idle. Selected army banners retain move orders |
| Home | Show the full city |
| T | Turn the placement preview; R is now reserved for camera tilt |
| Space | Pause / resume |
| Escape | Close the current city window/tool first; otherwise open or close the game menu |
| X / Delete | Select demolition |
| Ctrl / Cmd + Z | Undo the last construction and refund its cost |
| M | Mute / unmute all sound (Game, Sound… sets the volumes) |
| 1 – 9, Tab, 0 | City overlays: water, supplies, hygiene, fire and collapse risk, appeal, taxes, unrest, security, roads, problems; 0 or Esc returns to normal |

These are the defaults. Escape ▸ Controls… rebinds every key (a key another control has is swapped; Escape, Delete and the mouse are fixed) and sets the camera's pan, turn and zoom speed; Escape ▸ Game settings… sets autosave and voice language, with links to Display settings, Interface options and Controls. Escape ▸ Display settings… selects the window size, fullscreen, monitor, VSync and frame-rate limit. Choices are per user in `user://settings.cfg`.

English and Russian presentation are supported. The Escape menu’s language selector switches the
interface; the launch language selects the native event-message language.
Run `python3 tools/run_godot_pilot.py --lang ru` for Russian native messages.

## Display and screen sizes

**Escape → Display settings…**, or **start-menu gear → Display settings…**, offers
windowed/fullscreen mode, monitor selection, common window sizes that fit that
monitor, a **Fit to display** size, VSync and a frame cap (30/60/120/144 FPS or
Unlimited). Fullscreen uses the monitor's desktop resolution; it does not change
its video mode. The windowed size is retained when entering/leaving fullscreen.
The existing fullscreen shortcut (default **Alt+Enter**) follows the same policy.

**Apply** starts a 15-second preview. **Keep changes** saves; **Revert**, Escape
or timeout restores the previous window, frame cap and VSync. Cancel before
Apply makes no change. Confirmed choices return on launch through per-user
`user://settings.cfg`, preserving language, sound, UI/text sizes and other options.
Native simulation timing and map coordinates stay unchanged. Save and relaunch
an already-running game to load the new interface code.

Review with `python3 tools/review_display_settings.py --lang en` (or `ru`),
`--headless` for preference/type/translation checks. Read
[interface contracts](../docs/GODOT_INTERFACE.md) and
[validation evidence](../docs/GODOT_VALIDATION.md) for tested hardware and limits.

## Interface and surrounding landscape

The city HUD follows the user's Nova Roma reference: slim teal stock ribbon,
city name and treasury/population/jobs inside one top resource bar, welfare shortcuts,
square construction buttons and a small selected-tool card at bottom right.
All 23 native resource types, including zero stocks, appear alongside the food
total; balanced rows keep every item visible on smaller/enlarged interfaces.
Original 3D resource models provide static rendered icons without live HUD
viewports. See [resource art contracts](../docs/GODOT_RESOURCE_ART.md).
Resources start folded in a separate panel; the arrow after Jobs reveals them below
the compact overview bar. Stock and employment totals come from the native current city; the shortcuts open
existing overlays. The dock retains every native category, model cards,
live costs and wall fill. Exact price/obstruction badges follow the cursor.
Pause, speed and date sit at bottom left, with the compact journal control on the
right. The language/gear HUD panel is removed. Escape opens a centred, scrollable
game menu grouping city actions, settings, language and city views. Escape closes
the current window or cancels construction first; settings pages return to the
menu when closed. The menu holds the native clock and command queue, restoring
the previous pause/hold state on return. Inspectors and required decisions
remain bounded. See [interface contracts](../docs/GODOT_INTERFACE.md).
Review with `python3 tools/review_interface_context.py`; add `--checks --lang en`
(or `ru`) for the focused interface integration gates, with save/settings protection.

The minimap starts folded as a **City map** pill at the bottom left. The
pill or dock map icon opens its compact live chart; a small dash button in its
upper-right corner remembers the folded
preference. A small directional chevron and soft cyan halo locate the camera;
the compass elements and large footprint highlight are removed. **Home** keeps
the bounded city overview. The circular chart has no heading row, fills and clips to its circular frame and stays
fixed above the time controls when inspection opens. Inspection cards scroll at
bottom right without discarding drafts. It temporarily folds for construction or decision
reading. Routine reports enter the journal quietly. Urgent native news uses one
compact alert, queuing later arrivals; click to read, Close to dismiss or let the
countdown expire. Hover/reading/hidden/clipped alerts hold the countdown. Pending
decisions retain a persistent amber review chip and original choices; folding
never answers them. The right journal button opens a content-sized City journal with dates and full
wording. Identical labour/shortage/risk warnings group with an occurrence count;
reading and inspector drafts survive refresh. Escape closes the foremost
disclosure before cancelling construction or opening the game menu. Circular
clipping crops chart corners without changing native coordinates or picking.
Review the menu with `python3 tools/review_escape_menu.py --lang en` (or `ru`).
The focused Escape review passes 53 checks in each language.
Map/notification review:
`python3 tools/review_map_notifications.py --checks --lang en` (or `ru`),
`--native-map` for the eight retained map regressions, or neither for captures.
See the interface/validation documents for the scoped evidence and limits.

Building inspectors now have coloured native status summaries, staffing, road
access, maintenance, housing occupancy/needs and related service-view buttons.
Short explanations connect native status to vacant jobs, road access, industry
shutdown, missing inputs and housing vacancies. Cached model previews use warm
key/cool fill lighting and stop rendering when idle.
Overlays show matching colour legends and native assessment counts, with visible
water/supplies/health/risks/roads shortcuts. **Escape → Interface options…** or the
start-menu gear → Interface options previews independent interface/text sizes. Apply remembers them
per user; Cancel restores previous sizes. Reduce interface motion previews and
saves through the same policy. Enlarging the interface preserves map
picking and unfinished inspector edits. Review with
`python3 tools/review_status_ui.py --checks --lang en` (or `ru`): 115 scoped
checks each. Omit `--checks` for captures, or use `--menu` for the enlarged menu.
Further complex-panel and keyboard/gamepad accessibility coverage is pending.
The Nova HUD's focused notification gates pass 115 in each language, plus the
retained message/log checks. Shared menus, native map and display checks are
recorded separately in the validation document. Visual acceptance and matched
performance profiling remain pending; broad gameplay validation retains the
previously recorded aid-regard failure.

Land boundaries continue into cosmetic woodland, foothills and mountains; water
boundaries continue into ocean. Inland maps get a ground horizon. The playable
native footprint stays unchanged. The closest zoom is ten tiles (3 October; it had been 5, close enough to show faces and hands past the detail they carry);
Home still shows the city. See [surroundings contracts](../docs/GODOT_SURROUNDINGS.md).
Review with `python3 tools/review_surroundings.py --lang en` (or `ru`).

## Implemented simulation boundary

`EZeusSimulation` is a Godot GDExtension backed by
`presentation/esimulationservice`. It reads the original `.ez` save/campaign,
retains the existing board, economy, production, pathfinding and walker rules,
and uses the same `engine/esimulationstep` sequence as the SDL game. Godot
supplies elapsed time; the native service accumulates 50 ms ticks, clamps stalls
to 250 ms and retains native speed IDs 0–3, including the highest-speed five-step
loop. Camera movement never rotates simulation coordinates.

Snapshots arrive at up to 10 Hz through direct method calls. They carry session
IDs, terrain, footprints, positions, money, population, date, time and events.
After the initial full map, terrain records are sent only when they change; the
build-eligibility column is observed in full snapshots and not treated as a change
(use the `preview` query for placement). The building list is omitted when unchanged
and the wrapper re-supplies it with a `buildings_changed` flag. `diagnostics()` reports
per-phase snapshot timings (`profile_us`, `wrapper_us`) and the slowest native tick.
The wrapper currently converts a native JSON snapshot into a Godot Dictionary
inside the process; typed packed arrays are a future optimization. The old
loopback adapter remains available explicitly with `--legacy-bridge` as a
regression reference, and is not started by normal launch.

The service loads only `Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`. It never
registers autosave or settings writes. It waits for native workers before
reading state and detaches callbacks before releasing the campaign. A second
native owner is rejected. Native requests with decisions pause the simulation;
ordinary notifications remain informational. The engine's own events (the monthly summary and the shortage and risk warnings) are
worded by the core, in its language, from the SDL view's language tables and the city's history (population, treasury, food and unrest over the month). The simple decision buttons call
the original callbacks, including eligible destination-city actions. Military
force selection still needs its own interface and
is explicitly held pending rather than discarded.

## Expanded map and assets

The entire saved map is presented: **25,992 native tiles**, a 228×227 bounding
rectangle, and **834 buildings** before construction. The map is the native
irregular shape; empty bounding-box cells are not fabricated land. This expands
the old 32×32 viewport without resizing or overwriting the saved simulation map.
Cosmetic scenery can appear beyond/through non-native cells, with no collision
or build eligibility; the playable footprint stays exact.
Terrain uses 32-tile sections with collision meshes. Repeated building and tree
geometry uses MultiMesh batches grouped spatially, preserving imported materials
and enabling culling. Walkers interpolate between snapshots.

There are **363 development GLB assets**, including native variants for orchards,
walls, towers, gatehouses, temples, statues, pyramids and commemoratives. In the designated city, all
792 rendered building objects and all 279 initial visible walkers have real models.
The other 42 building records are livestock reservations and sanctuary owners;
their animals/components render separately. The former grey boxes and moving gold
spheres are absent in the checked city. Other campaigns still need coverage.

The palace keeps both halves and its full 8×4 footprint. Sheep update their model
when fleece state changes. Role-specific people, handcarts, trailers, animals,
fishing skiff and merchant ships are connected. Authored walker gaits are sampled;
most idle poses are held, while physician idle breathes. Work, combat/death, cargo
states remain pending. Workers and machinery in 35 authored building types now
animate in shared GPU batches, gated by native staffing, shutdown and production
inputs. Pause and pending decisions freeze motion; native speed controls it.
See [building activity contracts](../docs/GODOT_BUILDING_ACTIVITY.md) for coverage,
regeneration and remaining visual states. The building activity gate passes 171
checks; a separate decoder verifies 864 authored part poses and geometry budgets.
Compatible materials
use vertex colours and grouped PBR finishes to reduce draw calls; metal uses sky
reflections. See [asset contracts and export workflow](../docs/GODOT_ASSET_COVERAGE.md).

Road, housing, hospital, fountain, warehouse, granary, olive press, winery
and sculpture studio have authoritative native placement queries, exact quoted costs,
per-cell green/red footprint feedback and imported 3D ghost models. T rotates the
model; new square-building facing is retained across snapshots for the session.
Facing is not yet serialized, and rectangular building rotation remains pending.

Ground now blends limestone soil, vegetation, sand and stone continuously across
tile/section boundaries. Sandy wet banks and a shared coast distance field soften
river corners and tint shallow-to-deep water; restrained normal waves replace the
water checkerboard. Continuous native elevation profiles, road ramps and limestone
cliff sides close the old height gaps. Picking, walker feet and placement previews
follow the generated surface; buildings keep flat native foundation heights.
Native terrain/roads, pathfinding, eligibility and simulation height remain
authoritative. Forests use native forest cells, with independent forked trees,
smooth olive/cypress crowns, real leaf blades, subtle wind and reduced mesh LODs.
Existing water roads now have 3D bridge decks/rails/supports and shore approaches;
pedestrians stand on them, boats retain water height. Native walker positions
convert once from corner-based coordinates to centered Godot tiles, correcting
the previous half-tile offset without changing routes or simulation state.
Distinct native mineral outcrops, continuous quarry soil and sparse olive/sage
forest-edge grass/shrubs are implemented. Spatial batches, instance caps and
distance fading bound small detail; native road/housing/forest edits refresh it.
Resource ground inspectors identify deposits in EN/RU. Further species/content,
bridge topology, occlusion/performance profiling and wider terrain coverage remain pending; see the
[terrain contracts and next slice](../docs/GODOT_TERRAIN.md).
Imported materials carry preview vertex colours and grouped PBR finishes; complete
procedural texture baking and visual state coverage remain pending.

Fish Pond, Topiary, Hedge Maze, Park, Shell Garden, Sundial, Dolphin and Orrery
now use the Godot garden foliage adapter: branching cypresses, broad umbrella
pines, folded leaf geometry, leafy clipped hedges/spirals and flowering stems.
The 164 native 1x1 parks use a full-height pine-and-bench module instead of a
shrunken 3x3 tholos. All 178 garden placements retain native footprints and rules.
Pool/fountain colours survive the PBR export. Garden foliage is static; more
species/park variants, wind, material baking and sustained performance work remain.
See [garden source and budgets](../docs/GODOT_ASSET_COVERAGE.md#garden-foliage).

The 31 human walker assets (and the archer that patrols walls and towers, a 32nd built by the same adapter) now retain anatomical faces/hands, painted skin,
fitted hair/beards and softer skin, cloth and leather finishes. Previously generic
occupations have distinct facial profiles, with fair/light olive complexions;
the philosopher wears a blue wrapped himation with a Greek key hem. Female and
child anatomy, role props and walking anchors remain. This first people pass
does not replace workers embedded in buildings or boat rowers. Full texture baking,
facial animation and work/death/cargo states remain pending. Read the
[character art contract](../docs/GODOT_CHARACTER_ART.md) before re-exporting people;
their shader requires both rest-coordinate and surface-type UV sets.

**Character visual review remains open:** the user rejected this first pass as
still doll-like. Technical checks do not establish realistic appearance. The next
art benchmark is now a textured, skeletally animated physician in the actual city;
see the character art contract before another rollout.

Walking refinement (1 October): existing human walkers smoothly blend between
standing and walking and ease around corners. Gait phase follows horizontal native
travel, so terrain-height corrections do not create steps. The physician benchmark
adds longer support, heel/toe roll, smoother swing, body weight transfer and opposing
arm/shoulder motion. Its crowd twin shares the same phase and transition weight.
The new foot cycle is specific to this benchmark; other roles retain their authored
cycles. [Character contracts and review limits](../docs/GODOT_CHARACTER_ART.md)
include the repeatable locomotion checks and city preview.

## Construction and inspection tools

The **Build ▾** menu has one submenu per category (housing and roads, agriculture,
industry, storage, markets, health and water, administration and security, culture, science,
gardens and monuments) and lists each building with its native cost. It shows the 46
buildings (the road included) the test city may build that have a converted model; the core's `buildable`
query supplies names, footprints, models, costs and availability, and
`scripts/build_catalog.gd` supplies the grouping. Every building shares imported
ghosts, native costs/availability, demolition and construction undo. Launch with
`--placeholders` to list any native type that still has no model (none at present: the last fifteen, the culture and science schools, mint, corral, dairy,
armory, chariot factory and the small garden pieces, were exported on 1 October). The quick row
keeps Inspect, Road, Housing and Demolish.
**Trade** lists one entry for each partner city that can still get a post: "Trading Post: <city>" for a land partner, "Pier: <city>" for a sea
partner (a pier on a shore, with its trade post behind it; the pointer snaps to a fitting shore tile within two tiles). A post's panel lists the goods
its partner sells and buys with prices and this year's limit, and sets which to trade and how much to keep in store. Game, Trade partners… shows
all partners and their goods. **Markets** holds the common and grand agora (laid over
six tiles of road with free ground beside them; the pointer tile only seeds the search) and the food, fleece and oil vendors, which
replace an empty space of an agora (any of its four tiles picks it; one vendor of each kind per agora).

The embedded backend answers `preview TOOL X Y FACING` and `inspect X Y` without
advancing or changing the city. Placement uses the same footprint, ownership,
district, availability, terrain, walker/banner and credit-limit rules as the
native build path. Commands recheck current state when executed; previews do not
reserve a site. Roads can use the native elevation/walker rules and show a stone
preview; other supported tools use the actual imported geometry and materials.

Inspect a building to see its native name/text, road access, maintenance,
employment, or house residents/capacity/level and unmet needs. The inspector
refreshes while selected. Storage inspectors show actual goods counts, overflow,
occupied bays and per-resource **Reject / Accept / Get / Empty** orders and stock
limits. Edit an order/limit and press **Apply**. A bay holds four native cargo loads,
or one sculpture. Reducing a limit does not delete existing goods; carts perform
the resulting orders through the existing simulation. Refresh preserves unfinished
edits. Camera controls pause while a numeric field owns keyboard focus.

Production inspectors show input/output buffers, the native input recipe,
staffing and operational/waiting/shutdown status. **Pause / Resume industry** uses
the native workforce controls: it affects every producer of that resource in
the selected building's city, including shared growers. It does not introduce
individual-building shutdown rules. Existing goods and pending decisions remain
intact. Native descriptions are available under **Building details**.

`storage X Y TOKEN RESOURCE ORDER LIMIT` and `industry X Y TOKEN RESOURCE SHUTDOWN`
recheck ownership, resource support, pending decisions and the selected object's
weak-reference token. Selection changes, demolition, replacement, undo and reload
reject old tokens. Duplicate industry requests are idempotent. Failed/full-queue
requests preserve edits. These tokens are session handles, not durable entity IDs.
Native text follows the launch language; the Escape menu’s language selector changes UI/resource labels.
Trade settings, vendor controls and other specialized interactions remain pending.

Demolition uses `eBuildingsToErase`, including whole-object resolution for child
tiles, housing eviction and native costs. Forest clearing changes native terrain
and forest state. Burning/foreign buildings are rejected. Landmarks and stocked
markets retain confirmation; the dialog pauses play and restores the previous
pause state when closed. A native target token rejects stale confirmations.
Demolition cannot be undone. The Undo button or Ctrl/Cmd+Z removes the last
construction and refunds its actual cost once, using the native 15-game-day
window with a five-second minimum. Failed placements preserve that undo action;
demolition invalidates it. Existing saved buildings are not undo candidates.

All edits remain in memory and disappear on reload. Advanced tools require the
embedded backend; `--legacy-bridge` retains the original simulation/camera
regression route rather than exposing the new query interface.

## Build and verification

Local runtime: Godot **4.6.3**. The extension targets API **4.6** using
`godot-cpp` **10.0.0-stable**, revision
`507ed9d840c01a3c5b2a39af8bb4000bfac30bf5` in `../tools/godot-cpp`.
The private SDL2 source is `release-2.32.10` in `../tools/sdl2-headless`.
The local macOS SDK is built with SDL video/audio drivers disabled to avoid
loading Homebrew's SDL2-compat/SDL3 alongside Godot's own SDL3. Image/font/audio
helper-library copies are redirected and signed locally; Homebrew is untouched.
Additional codec/font dependencies still come from Homebrew. This is a
**development installation**, not a distributable standalone application.

From `eZeus/`:

```sh
./tools/build_godot_extension.sh
python3 tools/run_godot_pilot.py --validate --lang en
python3 tools/run_godot_pilot.py --validate --lang ru
python3 tools/run_godot_pilot.py --terrain-review after
python3 tools/run_godot_pilot.py --terrain-review elevation-after
python3 tools/run_godot_pilot.py --terrain-review detail-after
python3 tools/run_godot_pilot.py --garden-review after
python3 tools/run_godot_pilot.py --character-review after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/character-contract-engine.log" --path godot --script res://scripts/validate_characters.gd
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
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/buildings-engine.log" --path godot --script res://scripts/validate_buildings.gd
python3 tools/save_roundtrip.py
```

The launcher places runtime logs in `godot/captures/` using an absolute path;
relative Godot log paths resolve under `user://`. Headless commands above keep
their logs in the writable project as well.

Model GLBs cost video memory mainly through dense morph targets. After exporting or
re-exporting walkers, run `python3 tools/optimize_glb_memory.py --backup-dir DIR`, then
`godot --headless --path godot --import`, then `tools/verify_glb_optimization.py DIR` (it
merges identical poses, keeps UVs, and is safe to repeat). Animated walkers and animals
use baked pose textures: after exporting them run `python3 tools/bake_walker_vat.py`, then
`godot --headless --path godot --import`, then check with `res://scripts/validate_poses.gd`.
Sources are never modified, a stale derivative falls back to blend shapes, and
`EZEUS_NO_BAKED_POSES=1` forces the old path. The skeletal physician and its crowd twin
(`physician_crowd`) are rebuilt by `blender -b --factory-startup -P tools/build_citizen_benchmark.py`
(set `CITIZEN_OUT=/scratch/dir` for experiments), then `godot --import`,
`python3 tools/configure_citizen_textures.py godot/assets/characters/physician_v2`, `godot --import`,
`python3 tools/optimize_glb_memory.py --only physician_crowd`,
`python3 tools/bake_walker_vat.py --only physician_crowd --force`, `godot --import` and
`res://scripts/validate_citizen.gd`; see `docs/GODOT_CHARACTER_ART.md`. City load reads model files on
worker threads; set `EZEUS_DECODE_TEXTURES=1` only to compare against the old full PNG decode.

Interface: text is `tr()` keyed by English source from `data/ui_strings.csv` (godot's CSV import makes the `.translation` files named in
`project.godot`); the HUD is `ui/hud.tscn` + `ui/hud.gd`, styled by `ui/lapis_gold.tres` (`scripts/build_ui_theme.gd`); F3 toggles the developer
overlay. Drag the road tool to lay a road, or the wall tool to wall the outline of a rectangle (Shift fills it; T turns a gatehouse), or the housing, elite housing and park tools to fill an area; F2 (or Game, World map…) opens the world map: the cities on the map picture, their regard and goods, asking, giving and fulfilling, and the military dealings (Raid, Conquer or Reinforce, Aid and strikes, with an enlist-forces dialog and the armies drawn on their roads); a city's request for troops has a working "send troops" button; F4 (or Game, Army…) opens the army: the soldiers' companies with their size and state, Call all out / Send all home, per-company Call out / Send home / Go to / Place banner, flags on the map (a left click on one chooses its company, the right button moves the chosen banner); during an invasion a red notice counts the invaders and has a button that goes to them, and the player orders the defence with the army panel (the soldiers, heroes and gods fight and fall with their own clips); while a monster is at large a red button with the count stands under the journal and opens a card with its message, the hero who can slay it and Go to the monster / Build the hero's hall / Show the hero's hall (a hall the engine allows mid-game appears in the Build menu at once); F5/F9 quick save and load, the Game menu lists saves (kept in the per-user
`user://saves` directory, never in the repository); the minimap, messages and autosave are described in the migration document. Seeded replays: `EZEUS_SEED`, `tools/replay_parity.py` and `validate_replay.gd` compare the SDL executable and the embedded core.

The build helper creates only the extension target and signs its private
libraries. If rebuilding the SDL executable, follow the repository's mandatory
copy/codesign instructions separately. Model re-exports use background Blender:
`tools/export_godot_pilot.py --asset NAME`; this does not alter the live Blender
scene. Source paths, bounds, sizes and conversion limitations are recorded in
paired model manifests. GLBs, binaries, editor caches and captures are ignored
by Git. Dependency checkout LICENSE files are retained.

## Remaining release work

This is the next working migration stage, not complete game or production parity.
Remaining specialized inspectors/controls, settings, full asset coverage, material/animation
baking and minimum-hardware stress testing remain. Exact seeded replay equality
across disasters and all AI/event paths is not established; the inherited RNG
and cosmetic consumers must be audited before promising deterministic replay.
Preserve the engine's GPLv3 author/license notices. The development installation
still reads original content, and export manifests remain `needs_evidence`.
See `../docs/GODOT_MIGRATION.md` and `../docs/PRODUCTION_ROADMAP.md`.

## Building choices refinement — 3 October 2026

The construction tray now sits five logical pixels above the category dock,
independently of the taller time controls, with a 206-pixel baseline height that
still grows with its contents. Search, facing buttons/angle and placement guidance
are hidden in this tray; the existing placement-turn key and native wall-fill
checkbox remain. Cards and the selected context show native numeric costs beside
an original procedural gold drachma with a raised rim, beading and lightning motif.
`ui/gold_coin.gd` renders one shared 96×96 transparent texture and disables its
viewport after three warm-up frames. Material delivery and marble requirements
retain their native wording. No simulation commands, prices or saves change.
The retained hidden controls keep existing rebinding and translation references
compatible; category browsing is the only card filter.

## Slimmer choices without amounts — 3 October 2026

Supersedes the preceding gold-cost-marker layout: building cards now contain
only the model preview and name. The selected context and folded selected-tool
card show native footprint dimensions without price/material amounts. The tray
uses its content minimum height instead of the former 206-pixel floor; card
minimum height drops from 134 to 110 pixels and still grows for translated text.
The five-pixel dock clearance and native wall-fill checkbox remain. The coin
asset is retained as source but no coin viewport is created by the HUD.
Native placement quotes and construction prices retain their existing rules.

## Foldable resource panel — 3 October 2026

The overview bar contains city, treasury, population and jobs plus a disclosure
arrow immediately after jobs. All 24 stock items now live in a separate panel
below it, folded on every new city launch. The arrow opens/closes a clipped
0.24-second reveal with opacity easing; rapid reversal cancels the previous
tween. Reduce interface motion applies the final state immediately. Welfare,
inspectors and other bounded panels follow the revealed height. Folded space
passes input to the city. Native cached stock updates and resource shortcuts
remain unchanged; no preference writes or extra polling are added.

## Native-style right-click back — 3 October 2026

Right-click now dismisses city panels even over their controls. Building choices
close and cancel their active tool together; active road/area drags and placement
cancel without construction. Inspectors clear selection; journal, objectives,
resources and minimap fold. A required decision only folds, retaining its ID and
callbacks. The game menu returns through its existing pause/queue restoration.
Window-local `ui/right_click_back.gd` routes right-click through each window's
existing Escape path so settings Cancel, display Revert and nested menu return
behave identically. With no active tool/panel, right-click inspects the pointed
native tile. Selected army map orders and atlas right-drag panning remain their
existing behavior. This does not add automatic decision answers or save writes.

## Journal follows its right-side button — 3 October 2026

The journal/messages rail is now right-aligned, below the compact top bar at the
same level as the welfare shortcuts. Its disclosure opens eight logical pixels
below the icon and shares the right edge. Height remains content-bounded above
construction/time controls, with scrolling, retained reading Controls, full
history and unread semantics unchanged. Resource disclosure/scaling move both
icon and journal together. The right-click back behavior also closes the journal.

## Character window — 3 October 2026

A right click on a walker (the ringed person, or any god, hero, monster, animal, cart or boat near the pointer, never
through a HUD panel) opens `ui/character_panel.gd`, the SDL game's character window: the walker's own 3D model on a lit
marble plinth (it sways and can be dragged round; hovering Olympians get a soft glow), its name and occupation, the line it
speaks typed out in time with its recorded voice, Listen/Stop with a progress bar, a cart's errand, the other people on its
tile and Go to. The city pauses while it is open and resumes only if it was running; Escape, a right click or a click
outside closes it and stops the voice. The core's `character_info <walker id>` words it through
`engine/echaracterinfotext.{h,cpp}`, now shared with the SDL window (which line is spoken uses cosmetic randomness, so
looking at a walker never moves the simulation generator); a trailer speaks for its driver. Review with
`tools/review_character_panel.py --lang en` (or `ru`).

## Character window portraits — 4 October 2026

Roles with a portrait show a pre-rendered still (`assets/portraits/<asset>.png`, about 0.1 MB imported) instead of the live 3D
figure; others keep the live crowd model. Sources are built outside the project (`build-portraits/`, git-ignored) by
`tools/godot_portrait_export.py` and rendered by `tools/render_portraits.py`, then `godot --import`. The curator, storehouseman,
hoplite and philosopher have painted images (from `art/ai_portraits`); listing a role in `portrait_models`
(`ui/character_panel.gd`) shows its 3D model again. Contract: `docs/GODOT_CHARACTER_ART.md` and `docs/GODOT_PORTRAIT_REFERENCE.md`.
