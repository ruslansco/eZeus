# Living regional world atlas — 2–3 October 2026

The world screen now embeds an independent Godot 3D viewport: curved globe,
raised coast/relief, animated Aegean water, twelve drifting cloud cards, sparse
cypress woodland, up to seven decorative sailboats, and miniature temple/town
landmarks with animated flags. A gold ripple identifies the selected city.
Orbit, pan, zoom, Overview and Focus city work without changing native positions.
The first version covers the common Greece plate and all four Poseidon regions.

## Authority and projection

`ui/world_map.gd` still reads the existing C++ `world` response. Names, indices,
relationships, requests, goods/prices, military eligibility, enlistment and
quests retain the original handlers and callbacks. Native city X/Y fractions
map directly to the same normalized atlas UV; neither the simulation world nor
its saved coordinates are rotated or rewritten. 2D labels project the actual
3D landmark anchors each camera change. Native army endpoints and `frac` are
projected onto the same surface; no decorative ship represents an army or trade
order and no cosmetic motion advances an army's progress.

The 32 × 28.18 patch sits on a radius-100 sea sphere. Relief is artistic,
exaggerated terrain derived from coastline coverage and local deterministic
warped noise, **not surveyed elevation or a full worldwide geographic model**.
No collisions, navigation, placement authority, native map cells or native RNG
exist in this scene. Shader/decoration time may run while the city is held.

`main.gd` synchronously pauses a running city before the flight/relief build,
then hides its covered world/horizon on arrival and disables its camera. Closing restores
those exact visibility/camera states and the existing pause/resume behavior.
Space and city editing/save hotkeys are suppressed while the map is open.
The atlas disables its viewport and processing when closed; geometry stays
cached for reopening. Native fixed timestep, speed rules and decision blocking
are unchanged.

## City-to-world camera flight — 3 October 2026

`OrbitCamera.world_zoom_requested` emits only when an outward, enabled player
wheel/pinch crosses the existing `maximum_distance`. Home/configure/closer
zoom do not open the world. Cameras without a world handler retain the old cap.
`main.gd.open_world()` also connects F2 and Game → World map to the same flight;
M retains the existing mute binding. Modal edits, episode screens, troop/banner
placement and active construction drags exclude travel.

`world_flight.gd` uses 1.55 seconds outward and 1.20 seconds back. The city
camera rises/tilts with eased logarithmic distance; the atlas starts over the
**native current-city anchor** and pulls back to the regional overview. Cloud
wisps and staggered HUD/label/panel fades bridge the two live 3D scenes. This is
a cinematic crossfade between independently scaled scenes, not one continuous
georeferenced terrain. No screenshot copies, new native cells, collision, RNG
draws or model assets are involved. The temporary city camera may exceed the
player cap; its complete saved pose is restored on arrival while hidden and
again after descent. Ordinary limits remain unchanged.

An input shield and `world_map.transitioning`/`atlas.cinematic` suppress camera,
map and city actions during travel. Sea/cloud/ship motion stays live. Escape/F2
during ascent queues one return; repeated wheel events cannot restart the trip.
Back/Escape/F2 return to the saved city target, zoom, yaw and pitch, independent
of later atlas orbit/selection. City visibility/camera enable state and previous
pause state return only at the descent endpoint.

`CoreLink.commands_held` retains accepted city commands in their original order
until the map closes; direct native world-dialog queries still work. This
prevents a queued resume/build from releasing or mutating the held city during
travel. Authoritative snapshots consumed when opening/holding/resuming are
delivered through the ordinary presentation path, preserving delta observations.
Goal-result screens wait until the city view returns. Native decisions retain
their callbacks/block; the flight never resolves them. Paused city loading
prepares the current relief without visible UI or hidden rendering, avoiding a
first-flight geometry build. Overlapping city/atlas rendering is limited to
travel; steady world view and closed atlas retain their rendering suspension.

## Asset and rendering contracts

- `tools/build_world_atlas.py` requires Pillow/numpy and writes five small RGBA
  coast/relief field PNGs plus `assets/world/atlas_sources.json`. Source plates
  are read only. Greece uses the clean Greece08 coastline, shared by Greece01–10,
  so the old foreground character illustrations are absent. Poseidon retains
  four separate coastlines. Source/derivative hashes and provenance are recorded;
  retained commercial plate clearance remains `needs_evidence`.
- R stores height divided by 3.6, G shoreline proximity, B coastline coverage,
  A ecology. Both CPU projection and terrain geometry sample the same field.
  Keep normalized native UVs, aspect and the terrain/sea boundary together.
- Indexed 256 × 226 relief, 128-segment/64-ring sea sphere, one bounded woodland
  MultiMesh (cap 1,600), twelve cloud meshes, seven-ship cap, shared landmark
  mesh/materials, one directional shadow light with two cascades. Measured
  designated-world geometry is 35 meshes / 165,032 triangles; gates are 100
  meshes / 220,000 triangles. No building/catalog geometry baseline was changed.
- Metal/Forward Mobile stays the renderer. Sky reflections, ordinary fog,
  supported glow and additive beacon work; SSR, SSAO and volumetric fog stay off.
- Layout remains `ui/world_map.tscn`; typography uses the shared Theme, and new
  strings use the CSV/`tr()` translation contract. The old flat image is retained
  as hidden source metadata, not shown over the 3D viewport. Do not regenerate
  the scene using the previous one-off flat-map builder.

## Review and limits

`python3 tools/review_world_atlas.py --lang en --size 1600x1000` (also `ru`,
`1280x800`) renders the real atlas and exercises actual input, native labels,
diplomacy permission/dialogs, camera anchoring, army projection, all five field
families, hidden rendering and complete native snapshot equality. All tests use
`CLAUDE-TESTING-ADVENTURE.ez`; preferences are redirected to scratch files.
`--native-ui` additionally runs the retained request/gift/fulfilment and F2/Escape
pause/resume checks inside the real city scene, then checks covered-city rendering
and Space suppression. `--flight` uses actual wheel/pinch/F2/Escape/Back input
inside the city to check live travel, interruption, exact pose restoration,
queued-command isolation, modal suppression and complete native-state equality;
it saves ascent/descent frames for review. Headless `validate_world.gd` retains the economic core
regressions; `validate_ui_text.gd` gates translation coverage.

The designated save is Atlantean. The separate `world-atlas-*-greece.png` image
is explicitly a terrain preview with **no invented Greek campaign cities or
trade facts**. The actual city/diplomacy captures are `*-overview.png` and
`*-city.png`. Source hashes, logs and JSON reports live in `godot/captures/`.

Implemented and technically verified; revised user visual acceptance remains
pending. Terrain is stylized and buildings are symbolic, not reconstructed
ancient cities. Wider live campaign/army coverage, label overlap and very large
accessibility layouts, real geographic elevation, further art polish,
sustained minimum-Mac profiling and release-source clearance remain pending.
