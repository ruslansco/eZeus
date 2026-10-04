# Natural people refinement — 30 September 2026

**Visual status: not accepted.** After reviewing `natural_people_v1`, the user
reported that the characters still look like dolls. The checks below establish
technical compatibility, not realistic appearance. Treat these assets as working
prototypes, not the approved production benchmark.

**Benchmark status (30 September 2026, later session): built, integrated and
gated, awaiting the user's visual review.** The physician benchmark described in
"Revised next step" now exists: see "Skeletal physician benchmark" below. It is
not a catalog rollout and no other role uses the pipeline.

## Hades: underworld lord — 2 October 2026

The user explicitly requested a separate stylized god direction, starting with
Hades. `tools/godot_hades_art.py` applies only inside disposable Godot exports.
It derives an original narrow jaw/strong cheek face from the existing anatomical
source, with cool slate skin, amber irises and fitted dark eyebrows. The follow-up
revision `underworld_lord_v2` ages him to 72 with stronger facial creases, a full
silver-gray fitted beard and swept locks, and red flame hair.
The provided statue reference informs flame hair and dark Greek drapery;
its face and pixels are not copied. The physician benchmark is unaffected.

The long fluted chiton, asymmetrical wrapped mantle and surface-fitted shoulder
fold overlap the underlying anatomy. The curled train clears the stride and
clamps at the ground. Replaced crown/groom/Roman garments are removed from the
pose list so native visibility callbacks cannot resurrect them. The original
bident grip is kept and its material changes to bronze. Native Aura callbacks
still drive arrival/disappearance; sparse red spirals replace the opaque
export of the source's transparent light column. Hades's flame contours are
protected during export simplification. Emission/flicker is enabled only by
the `underworld_lord_` manifest tag, through the existing VAT-compatible finish.

`hades_hem_fire.gd` attaches one 96-triangle additive flame mesh, 18 embers and
one 2.4-unit shadowless warm light to this god only. It reads the existing
presentation pose table, carrying exact frame blend weights through VAT and
morph fallback. Scale/lift match the native shrink curve; the fire vanishes at
the last disappearance pose and returns with reverse arrival. It has no physics,
navigation, gameplay authority or native RNG. Gray beard fill and crimson hair
emission are restricted to Hades; ordinary people retain their finish.

Contracts retained: CityPalette, both rest/surface UV sets, native rig and all
24 walk/12 held idle/16 fight/32 disappearance samples, reverse arrival,
0.64-tile stride, imported LODs, three mesh groups and a 22K vertex cap. Current
export: **15,638 vertices**, 9,492,972-byte source GLB, 130 unique targets after
lossless merging of 252 targets, **6.2 MB** of GPU pose data; half-float displacement
error is at most 0.000972 units. The static menu guardian bakes `idle_00`, drops
only animated targets, scales roots 1.85 and uses the menu stone shader. Its
source hash is recorded in `assets/menu/hades_guardian.json`. The existing
sanctuary monument/source atlas and the live Blender scene are preserved.

Rebuild in order:

1. `python3 tools/export_character_assets.py --output-dir <candidate-directory> --assets walker_hades --jobs 1`
2. Optimize the candidate with `tools/optimize_glb_memory.py --models <candidate-directory> --only walker_hades --backup-dir <backup-directory>` and verify with `tools/verify_glb_optimization.py <backup-directory> --models <candidate-directory> --require-uv`.
3. Preserve the current development GLB/manifest, install the candidate pair,
   then `python3 tools/bake_walker_vat.py --only walker_hades --force` and
   `python3 tools/make_hades_guardian.py`.
4. Import with Godot, run `validate_hades.gd` (18 focused fire checks),
   character/geometry/pose/asset gates and the focused
   `--character-review after --character-subjects walker_hades` reviewer, then
   the EN/RU menu reviewer. Never rebuild the native sprite atlases for this pass.

The focused reviewer now frames all enlarged gods properly, actually selects
GPU pose indices, shows fight and reverse-arrival frames, and captures a
temporary Hades specimen at a native pedestrian route in the designated city.
It never adds a god to the simulation; snapshot equality and protected-file
hashes pass. Full/portrait/rear/walk/fight/arrival and city captures were inspected.
Technical results are in `GODOT_VALIDATION.md`. The user approved the initial direction and requested this red-fire/older/beard
revision. **Revised visual acceptance is pending.** Further god art, facial acting, continuous physical cloth/flame motion and
conventional texture baking are future art work. Provenance stays `needs_evidence`.

## God faces: a designed head, starting with Hades — 3 October 2026

The user found the gods still looked like dolls. Every god was the shared CC0 body with three Gaussian bumps
on its head (`identity.morph`), a flat vertex-colour skin, a dark ball with an amber dot for an eye (no sclera,
no lids, no brows) and a pasted shell for a beard. `tools/godot_god_face.py` now designs a god's head inside the
disposable export, and `tools/godot_hades_art.py` calls it; Hades is the first. Nothing here touches the
simulation, the native art kit or the shared body cache.

- `sculpt` displaces the head from a spec of amplitudes in units (1 = 2 m, so .001 is 2 mm): brow ridge that
  overhangs the eyes, heavy lids, cheekbones, hollow cheeks and temples, a raised bridge and longer, lower nose
  tip, thin downturned lips over a firm seam, a longer pointed chin, a frown and the nasolabial folds. Specs are
  in `SPECS` (`HADES`); the module is meant to be reused for the other thirteen gods.
- `occlusion` bakes ambient occlusion into the vertex palette by ray casting the sculpted skin (22 rays per
  vertex), so sockets, nostrils, the lip seam and folds stay dark after the exporter's simplifier. `paint`
  adds the cold slate skin with low-frequency mottling, violet under-eye shadow, dark blue-violet lips, nostrils,
  lid margins and lashes (dark where skin touches the eyeball), forehead creases, crow's feet, thin temple veins
  and the beard's undercoat.
- `eyes` builds an eyeball per eye on one mesh: sclera, amber iris, pupil and a dark limbal ring as sharp colour
  rings by angle from the gaze axis, a slightly bulging cornea, and the lids' occlusion shading the ball.
  `brows` raises tapered, grey brows from the skin; `beard` is a dragged shell over the jaw (a chin sock) plus
  strand cards for the fringe and a moustache that sweeps out; `hairline` is a cap with a receding, widow's-peaked
  edge that the flames grow from (the eight flame cones start lower so they are buried in it).
- The head the exporter sees is the **169,362-vertex** subdivided body, not the 42K `greek_male.npz`, so
  `thin` decimates each shell (brows 320, beard shell 1,500, hairline 1,000 vertices) and takes colours from the
  nearest source vertex. `PROTECTED` names (eyeball, brow hair, beard hair, hairline) are kept whole by the
  exporter's simplifier, which would otherwise erase iris rings and strand cards, and count against the budget:
  Hades's allocation is 19,000 (was 15,000). Export: **19,514 vertices, 35,301 triangles**, three surfaces, GLB
  10.9 MB after the optimizer merged 252 targets to 130, **7.3 MB** of baked poses (was 6.1).
- `character.gdshader` (gated by `hades_flame`, the historical name of the underworld-lord flag): wet glossy
  eyes whose amber iris glows faintly, cold waxy skin with a pale rim, flame hair whose painted colour climbs
  from deep red to hot orange at the tips, and a silver-beard rule that needs a grey/blue colour, so the dark-red
  scalp cap no longer reads as beard.
- Preview and review: `blender -b --factory-startup -P tools/preview_god_face.py -- --god hades --out DIR` renders
  close-ups of the freshly built god in about 20 seconds (palette colour only, no Godot finishes);
  `run_godot_pilot.py --character-review after --character-subjects walker_hades` captures whole, face, portrait
  (straight on, yaw 180), rear, walk, fight, appear, city and city-closest (the closest zoom a player has).
- To give another god a face: add its spec, call `sculpt`, `paint`, `eyes`, `brows`, `beard` and `hairline` from
  its adapter (replace the generic `paint_skin` and `groom`), raise its budget in `export_godot_pilot.py` by the
  protected vertices, rebuild with the order above and re-record its geometry baseline (that god only).

Limits. At the closest zoom (ten tiles) a god's face is about 25 to 30 pixels, so the face shows in close views,
the menu and portraits, while in the city the silhouette, colour and effects carry the god. Skin is still painted
vertex colour with a procedural grain, not a baked photographic texture (a UV'd head would need a textured part in
the pose-baking pipeline); there is no facial animation; the other thirteen gods are unchanged; provenance stays
`needs_evidence`. The user's visual acceptance is pending.

## Floating gods — 3 October 2026

The user asked that the gods float through the city instead of walking like the townspeople. It is presentation only:
the core's routes, positions, clocks and random numbers are untouched, and every god keeps its fight, bless, curse,
appear and disappear clips.

- Pose (export, `tools/godot_god_float.py`, called by `export_godot_pilot.py` for the fourteen `walker_<god>`): the
  god's held pose is a hover instead of the first frame of its stride. Legs hang together and trail a little, the
  feet are lifted (the knees bend a little through the kit's own leg IK), the body leans a little forward and the
  hands keep the god's own targets, so the staff, spear, bident, thunderbolt or hammer stay in them. It is made by
  calling the god's own walk closure with `people6.hero_walk` replaced for that call, so no native art file changes
  and the SDL sprites keep walking. The idle is a twelve-frame drift of that pose (3 s per loop at runtime); the 24
  walk samples are all its first frame, identical, so the optimizer stores them once. Manifests say
  `character.floating: floating_gods_v1`.
- Motion (`godot/scripts/god_float.gd`, from `main.gd`): `animate_walker` hands a god's travel to `GodFloat.update`
  and then animates it as if it had not moved, so it never steps. The node is raised by a hover (0.12 tiles at
  rest, 0.20 gliding at full speed, lowered at the user's request from 0.45/0.62, plus a slow 0.03 bob at 0.42 Hz, each god at its own phase), leans up to 8
  degrees into its travel about the waist (the waist stays over the spot: head forward, feet back) and sways
  1.3 degrees side to side. Speed is low-passed twice (4/s, then 2.4/s), so starting and stopping ease in and out,
  and a god turns at 2.6/s instead of a citizen's 12. Everything is recomputed from the surface position each frame.
- Checks: `validate_locomotion.gd` (now loads `main.gd` at run time; preloading it no longer compiled once `main.gd`
  named the `GameAudio` autoload) has fifteen floating checks, and `run_godot_pilot.py --character-review after
  --character-subjects walker_<god> ...` puts each named god through the city's own per-frame code
  (`review_god_float.gd`): a presentation-only walker glides 3.5 tiles and rests; heights, lean, gait phase and
  walk blend are measured, Hades, Zeus and Poseidon are captured gliding and resting (`captures/god-float-*`), and the
  snapshot equality gate proves the native state is unchanged.

Limits: the hover pose is one authored pose per god, not cloth or hair simulation; a god fights, blesses and appears
at hover height; the floating pose was judged in Blender and in the captures, the user's visual verdict is pending.

## Revised next step: one convincing citizen

Build one adult Greek/Roman citizen with natural proportions, using the physician
as the first candidate. Compare the existing anatomical source with a textured,
rigged MPFB base before choosing; a generator alone does not establish quality.
Do not repeat a whole-catalog shader or geometry rollout before the new benchmark
has been reviewed in the actual Godot city at normal and maximum supported zoom.

1. Refine eyelids, eyes, lips, ears and hands; fix shoulder/garment openings and
   replace solid-looking beard/scalp shapes with authored game-ready hair.
2. Introduce conventional texture UVs and authored/baked skin and clothing colour,
   normal and roughness maps. Current rest-coordinate UVs are not texture unwraps;
   version the material contract and keep legacy assets working during migration.
   Add separate eye/cornea materials and cloth folds/seams. Export and verify these
   materials in Godot, not only in Blender.
3. Export a real deformation skeleton, skin weights and animation clips to GLB.
   Use Godot Skeleton3D/AnimationTree for body animation and facial blend shapes
   for blinking and expressions. Existing full-body sampled morph gaits remain a
   fallback; preserve native IDs, ground anchors, roles, props and movement.
4. Start with idle breathing/weight shifts, blinking/gaze, walking with starts,
   stops and turns. Add carrying and role-specific work after the body is sound.
   Movement and gameplay state remain C++ authoritative; animation must not move
   simulation coordinates or consume simulation RNG. Reduce facial/animation work
   at distance, and check foot sliding, clothing penetration and pose transitions.
5. Compare Mobile and Forward+ with identical assets/camera/light, as an experiment
   rather than a default renderer change. Forward+ supports skin subsurface
   scattering; the current Mobile renderer does not. Benchmark the full designated
   city as well as the close-up before adopting any more expensive settings.

Acceptance requires a convincing still frame and a short continuous motion review
in the real city, followed by crowd performance and existing simulation checks.
Do not equate a larger polygon count, installed library or passing tests with
visual acceptance. Steps 1–4 exist for the physician only (see below); the Forward+
comparison in step 5 is measured and rejected for now; carrying, work states and
the other roles are not started.

Candidate tools researched on 30 September 2026:

- [MPFB for Blender](https://static.makehumancommunity.org/mpfb.html): human bases,
  skins and rigs. [Core assets are CC0](https://static.makehumancommunity.org/about/license.html);
  verify separately sourced community assets and record each asset's provenance.
- [Mixamo](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html): optional
  humanoid motion library, free with Adobe ID, with commercial game use permitted
  by its FAQ. Record clip terms; this is not a blanket permission to redistribute
  raw source assets. Custom facial and job/prop motion still needs authoring.
- [Godot skeleton retargeting](https://docs.godotengine.org/en/4.6/tutorials/assets_pipeline/retargeting_3d_skeletons.html)
  and [AnimationTree](https://docs.godotengine.org/en/4.6/tutorials/animation/animation_tree.html)
  provide the runtime framework. Additional animation middleware is not required
  for this first benchmark.
- [Godot renderer comparison](https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html)
  documents the Mobile/Forward+ feature differences.

The user's direction is natural human proportions, Greek/Roman clothing and
predominantly fair/light olive complexions. The supplied sage illustration is a
clothing/grooming reference: cream linen, blue wrapped wool, sandals and grey
beard. Its large head, hands and toy eyes are not the anatomical target. Keep
individual ages, faces, female anatomy and age-specific child proportions.

## Implemented presentation

All 31 existing human walker GLBs (plus `walker_archer`, 1 October: the people kit's archer identity, 15,958 vertices, baked pose texture, shown standing on walls and towers, and, on 2 October, 52 soldiers, gods and heroes: the Roman-army and Atlantean-guard soldiers of the player, the armies of nine nationalities, the fourteen Olympians and eight heroes, with 32,000/45,000-vertex budgets for the ten mounted ones; 55 models carry the fight, die, bless, disappear and appear clips, see `GODOT_ASSET_COVERAGE.md`) use the Godot-only adapter
`tools/godot_character_realism.py`: physician, philosopher, transporter, settler
family and 27 occupation/hero/god assets. It clones identity profiles inside
disposable background exports, retains the local CC0 anatomical sources and rigs,
and gives previously generic occupations distinct facial profiles. Face and hand
geometry have separate simplification allocations. Scalp-fitted hair/beard shells,
individual locks and orbital eyebrows replace the coarse voxelised strand masses.

Painted skin retains lips, cheek warmth, under-eye shading and age variation.
The shared `character.gdshader` distinguishes skin, woven cloth, hair, eyes,
leather, metal and wood. Roman tunic stripes are evaluated from rest coordinates;
the philosopher has a wrapped blue himation and a Greek key hem. Source props,
role colours, sandals, cart geometry, native asset IDs and movement anchors remain.

The runtime caches one finish per asset. Keep both UV sets and the painted
`CityPalette` through simplification, batching, GLB optimization and import:

- UV stores local rest X and 1-Z in Godot. It stays fixed through morph poses.
- `round(UV2.x * 8)` identifies skin/cloth/hair/eye/leather/metal/wood/other/tunica
  (0–8). `floor(UV2.y * 8)` identifies the person within a group (family/water carriers).
- `character` manifests describe identities, wardrobe accents and budgets.
  Assets without this contract keep their existing materials.
- Allocation targets are 15,000 vertices per single person/prop asset and
  32,000 per settler family. Final export caps are 22,000/45,000 vertices;
  modifier output and per-material boundary vertices can exceed allocation targets.
  Each GLB keeps at most three PBR mesh groups and an imported LOD ladder.
- Preserve all 24 walking samples, 12 idle aliases and the 0.64-tile stride.
  The existing runtime resolves optimized shape aliases through `morph_table`.

## Rebuild and verification

From the repository, stage a rollout in an isolated directory:

```sh
python3 tools/export_character_assets.py --output-dir /path/to/candidates
python3 tools/optimize_glb_memory.py --models /path/to/candidates --backup-dir /path/to/unoptimized
python3 tools/verify_glb_optimization.py /path/to/unoptimized --models /path/to/candidates --require-uv
```

Import and visually review candidates before installation. After an intentional
art update, record its geometry baseline with `validate_geometry.gd --write-baseline`,
then run the normal geometry gate and `validate_characters.gd`. Use
`tools/run_godot_pilot.py --character-review before/after` for matching front,
portrait, rear, walking-pose and actual-city captures. Review only the designated
test save; preserve native state, settings and the live Blender scene.

## Limits and next work

This is the first natural walker pass. Building-embedded workers, boat rowers,
animals and humanoid assets outside the existing 31-walker catalog are unchanged.
Full skin/fabric normal-map baking, additional hair styles, facial animation,
work/death/combat/cargo states and most authored idle movement remain pending.
Skin and weave use spatial colour/procedural shading, not a completed production
texture bake. No measured minimum-hardware or large-crowd performance claim is
made. Preserve `needs_evidence` provenance and the production release gates.

## Skeletal physician benchmark — built, awaiting visual acceptance

`godot/assets/characters/physician_v2/physician.glb` is a textured, rigged adult
built from the CC0 MPFB human with Greek clothing (tunic, blue mantle, sandals,
satchel), fitted hair/brows/lashes, separate eye materials, a 137-bone skeleton,
`Idle` (3.0 s) and `Walk` clips and `Blink_L/R` shapes. It is generated by
`tools/build_citizen_benchmark.py` in background Blender (`blender -b --factory-startup
-P tools/build_citizen_benchmark.py`; it also writes `physician_v2.blend` and the procedural
detail maps under `art/characters/citizen_v2/`, outside the Godot project, and never touches
the live scene). Environment: `CITIZEN_OUT` redirects every
output to a scratch directory (experiments), `CITIZEN_BODY_SUBDIV`/`CITIZEN_CLOTH_SUBDIV`
(default 0) and `CITIZEN_CROWD_VERTICES` (default 4,500). Sources and licences:
`tools/prepare_citizen_sources.py`, `tools/citizen_sources.json`, `manifest.json`.

**Budget (gated by `validate_citizen.gd`).** 30,116 vertices in 17 meshes/20 surfaces
(first version: 89,000 vertices, 1.7 MB video memory per instance, 457 ms to first load;
now about 0.6 MB and 210 ms). Nine VRAM-compressed textures, largest 2,048 px (skin), about
12.7 MB (was 56 MB uncompressed): after any rebuild run `godot --headless --path godot
--import`, `python3 tools/configure_citizen_textures.py godot/assets/characters/physician_v2` (sets compression and normal-map
flags on the extracted textures) and import again. Body subdivision looked identical at
portrait distance and is off.

**Runtime.** `scripts/skeletal_citizen.gd` drives an `AnimationTree` with absolute seeks:
the idle pose follows an idle clock, the walk pose follows travelled distance, and the two
blend by a walk weight, so animation never moves the C++ coordinates. The controller seeks
`fposmod(travel / 0.64, 1) * clip_length`. The original import's 0.66 s period and initial
hold are now corrected: export with `export_anim_slide_to_zero=True`, author/import bone
tracks at 100 Hz, and compensate the 1.045 rig scale in the source stride. Current loops
are exactly 0.64/3.0 s. See the walking refinement below for the stronger contact check;
the former 1.7% average stride check did not measure each contact's directional error.
Facial blinking runs only within 14 units.

**Crowd level of detail.** Skeletal skinning costs per-instance buffers, so every physician in
the city is shown by `physician_crowd` (`godot/assets/models/physician_crowd.glb/.json`,
generated in the same Blender run): 6,249 imported vertices, colours baked from the textures,
the same 24 walk and 12 idle poses stored as morph targets and turned into a pose texture by
`tools/bake_walker_vat.py` (1.9 MB), and a normal `walker_*` style entry. `scripts/citizen_lod.gd`
(wired in `main.gd`) swaps the nearest 24 physicians within 9 units to a pooled skeletal
citizen (back beyond 11.5), copying the crowd model's walk phase, idle clock and gait so
there is no pop. Nothing else about movement changes. Side-on silhouettes of the two models
are pixel identical at idle and at walk phase 0. 1,000 injected crowd physicians add 45 MB
of video memory; eight skeletal citizens near the camera add about 7 MB. Frame cost is the
normal per-walker cost: 279 walkers 1.49 ms, 1,279 walkers 6.13 ms (about 4.6 µs per walker,
of which 2.7 µs is the surface-height lookup).

**Rebuild workflow.** Blender build (about 40 s); `godot --import`; `configure_citizen_textures.py <folder>`;
`godot --import`; `python3 tools/optimize_glb_memory.py --only physician_crowd`;
`python3 tools/bake_walker_vat.py --only physician_crowd --force`; `godot --import`; then
`validate_citizen.gd`, `validate_poses.gd`, `validate_assets.gd`, `validate_geometry.gd
--write-baseline` only if the geometry change is deliberate (review the diff: only
`physician_crowd` should change).

## Walking refinement — 1 October 2026

`scripts/walker_motion.gd` supplies frame-rate-independent human start/stop blends,
an 80 ms grace period for short observation gaps, and smooth shortest-path heading
changes. `main.gd` measures horizontal displacement of the interpolated native
position before applying the surface height. Height corrections therefore do not
advance the gait. Native positions, routes, speed, fixed ticks and RNG remain
authoritative. Walk phase holds when stationary; the previous breathing idle
continues during pause. Animals and boats retain their existing clip switching.

Both VAT and fallback morphs blend idle/walk pairs. Shared optimized aliases add
their weights; a negative pose remains the implicit rest pose. Fully walking or
fully idle VAT instances fetch only their active pair. `citizen_lod.gd` carries the
exact intermediate weight across the swap and hidden crowd poses stay current.
Do not replace this with a binary moving flag or restart a phase on a LOD change.

The physician's `contact_roll_v1` is authored in `tools/citizen_gait.py` and
`tools/build_citizen_benchmark.py`: 56% support per foot, 12% double support,
matching swing/stance tangents, heel strike and toe push-off, 0.05-unit swing
clearance, pelvic weight transfer and shoulder counter-rotation. The sandal's
lowest point determines the ankle height and contact offset. Compensate rig scale
in the stride; keep the 0.64-tile cycle and 24/12 crowd samples. The body, clothing,
textures and 137-bone/24-near-citizen budgets are retained. The configuration helper
reads `animation.bone_sample_hz` from the manifest and preserves the 100 Hz import.

Checks: `python3 tools/test_citizen_gait.py` (3 curve/contact gates),
`validate_locomotion.gd` (20 transition/heading/VAT/fallback/animal gates), and
`validate_citizen.gd` (38 rig/contact/LOD gates). The contact gate samples 256
intervals per cycle and counts both supporting feet. It sums each interval's
directional error relative to native travel, rather than allowing fast/slow
intervals to cancel. Current mean error is 3.1% of supporting travel (4% limit);
minimum contact is -0.001 units, within the -0.002 tolerance. Geometry and memory
budgets remain unchanged. These are technical gates, not visual acceptance.

`review_locomotion.gd` captures a full cycle and continuous motion in the designated
city. This city's initial snapshot has no physician: the reviewer temporarily
displays the physician on a travelling transporter's native route, without changing
the role mapping or C++ observations. The fixed pose portion leaves native state
unchanged; the live portion advances C++ normally. Report and frames are in
`captures/locomotion/`; the GIF is `captures/walking-improved.gif`.

**Still pending:** user acceptance of the physician's appearance/motion, new
occupation-specific cycles for the other 30 people, per-foot slope/stair IK,
turn-in-place/pivot clips, work/cargo/death transitions and facial expression.
This runtime refinement does not roll the new art pipeline out to other roles or
building workers.

**Review status and what the stills show.** Stills in the real designated city at distances
5 (closest zoom the game allows), 9, 18 and 34, front and rear, plus walking phases, are in
`godot/captures/citizen-review/`. At distance 5 the whole figure is about 21% of the window
height (about 195 px on 900 px) and the head about 26 px, so facial detail, eye texture and
skin subsurface scattering are not legible at the closest zoom; silhouette, garment shapes and
gait carry the impression. The himation was a flat blue plate that read as a backpack from
behind. It is now a piece of wool dropped onto the left shoulder in a Blender cloth
simulation (`CITIZEN_MANTLE=cloth`, the default; pinned on the shoulder, settled for 150
frames, relaxed, baked at rest and skinned like the tunic; `plate` keeps the old flat mantle
for comparison and `none` removes it): it now falls in natural folds in front, behind and over the
upper arm with a woven border on its two hanging ends. The satchel stands clear of the tunic on
a strap. The previous stills are in `godot/captures/citizen-review/plate-mantle/`. The simulation is
sensitive: a broader piece (width 0.52) crumpled into lumps, so change width, length and position
(`CITIZEN_CLOTH_WIDTH/LENGTH/X/Z`, defaults 0.36/0.74/0.12/0.668) only with a preview render
(`CITIZEN_PREVIEW=dir CITIZEN_PREVIEW_ONLY=1` writes five Workbench views and exits before
export). Remaining known art issues: the tunic hem looks frayed, the tunic still reads somewhat
modern, a pointed cloth corner can hang at the left side, and the eyes look pale at portrait
range. The crowd's skin is slightly warmer than the skeletal one.
Visual acceptance, a decision on closer camera zoom, and any wider rollout remain the user's
call.

**Renderer comparison (experiment, not a change).** Same city, camera and assets on an
Apple M4, uncapped frame time: Mobile about 17 ms (58 fps; 10.5 ms when far), Forward+ about
26–28 ms (36–39 fps), with 661 MB against 610 MB of video memory. Forward+ is needed for
skin subsurface scattering, which is not visible at the closest zoom, so Mobile stays. GPU
timestamps were not available from the Metal driver here, so no GPU-only figure exists.

**Known limit.** The native `disgruntled` walker (spawned by unrest) has no asset mapping
(`presentation/esimulationservice.cpp` returns `unconverted`); `validate_city_coverage.gd`
fails when one spawns in its 60 simulated seconds (it passed on two re-runs, so it is a
random-event flake, not a regression).

## Monsters — 2 October 2026

The seventeen monsters of the engine use the same pipeline as the soldiers and gods. Eight have human bodies from the people kit (`MONSTER_PEOPLE` in `tools/godot_asset_sources.py`: cyclops, Talos, Hector, minotaur, satyr, Medusa, maenads, harpies) and take the human adapter, so the rules above apply: individual anatomy, painted skin, fitted hair, both UV sets and `CityPalette`, 22,000 vertices at most
(they come out at 15,000 to 16,300). The harpies hover about half a metre over the ground: do not "fix" that to touch it. Nine are creatures from the animal kit (`MONSTER_BEASTS`, `CREATURES`): they are exported without the human adapter, with a budget of 32,000 vertices, and their coats and scales come from the kit's per-point `Coat colour` attribute, which the exporter now reads
(`attributes['GodotPalette']` in `evaluated()`) and writes as `CityPalette`; check a new creature in the roster sheet, because a white one means the palette was lost. All carry `fight`, `fight2` and `die`. The monsters have no facial or work animation, and the creatures' sizes are the kit's own.

## The priestess — 3 October 2026

`walker_priestess` is the figure of a sanctuary's altar rite (`art/characters/people/people11.py`, `RITE_PEOPLE` in `tools/godot_asset_sources.py`; she is a COMBAT model like the gods). A woman of the kit (seed 111001, saffron chiton with white clavi, cream veil, gilt fillet, bronze knife; the colours are the wardrobe's "Priestess" profile in `art/characters/roman/wardrobe.py`). `fight` is the sacrifice: the knife rises overhead and plunges forward and down, twice in 24 frames; `fight2` is the offering with both arms raised, closing exactly in 12 frames; `die` the kit's fall. The exported model has 15,500 vertices and 154 baked poses; `verify_glb_optimization.py --require-uv` reports no difference. Poses are checked in Blender with `build_person.py --who priestess --validate-only` (reach, loops, headings), looked at with `--preview` and `--states fight --dirs bottom`. She is shown only at an altar (see `eZeus/AGENTS.md`, "Sanctuary rites"); the SDL overlay's goods frames also show a second figure beside the altar (apparently a priest in a pale cone hat), which is not made.

## The cape behind the arms — 3 October 2026

Every person of the people kit whose wardrobe profile has a cloak colour (`art/characters/roman/wardrobe.py`, `PROFILES`; a name that is not listed gets the default cloak) wears the "Roman draped cloak". It was a rigid half-tube whose side edges lay on the body's middle plane, exactly where the arms hang, narrower than the arms and skinned to the torso only: every arm swing went through it, most visibly the right arm from behind, and it read as a board. `_cloak_shape(h, hem)` now fits it to each person: it is measured on the dressed body in the rest pose (body and garments, not hair or props) in bands of height; across the back it is the width of the deltoids plus .03, flaring .05 to the hem; its side edges lie .04 behind the arms' back surface (the walk swings the arms mostly forward, away from it) and its middle .045 behind the torso; over the shoulders it wraps forward as a yoke onto the shoulder tops; vertical folds deepen toward the hem with a per-person phase; the profile is smoothed down the cape. Only the yoke follows the upper arms (half weight) so a deltoid cannot push through, while the rest hangs from chest, spine and pelvis; the right shoulder's pin sits at the yoke's front corner. 59 Godot models carry it and were re-exported: 49 walkers of the townspeople, soldiers, gods and heroes, the cyclops, Hector, Medusa, the maenads, the harpies, the priestess, the astronomer, inventor and curator, the philosopher (his cape stays hidden under his blue himation) and the settler family. The SDL sprite renders under `art/characters/people/<who>/` were not re-rendered. Check a cape with a scratch render that never writes the art folders (renders of the walk from four sides); `build_person.py --validate-only` passes for every spec with it.


## Greek portrait faces for the character window — 4 October 2026

The user asked for more Greek-looking men, at least in the character window, with the stylised philosopher as a mood
reference (curly grey hair and beard, laurel). The crowd walkers are unchanged; the window shows a separate portrait model.

- `tools/godot_portrait_faces.py` (revision `greek_portrait_faces_v1`) rebuilds each grown man's head inside a disposable
  export, reusing `godot_god_face` (sculpt, occlusion, eyes): a Greek profile (filled nasion so the nose continues the
  forehead, firm brow, fuller lower lip, strong chin and square jaw), fair warm skin with baked occlusion and warm blood
  tones, brown eyes, brows of short hairs, hair as snail-shell curls over a dark cap with a fringe at the hairline, and a
  beard of snail curls on the cheeks, corkscrew locks from the jaw and a drooping moustache over a dragged shell. Colour by
  age or role: black or dark brown, grey from about 52, white from 66 (scholar, astronomer, Zeus white; philosopher,
  inventor, curator, Poseidon grey). Laurel for the philosopher, scholar, astronomer, Zeus, Apollo and the competitor.
  Men in helmets or hats keep the crowd scalp groom (curls would push through) and get the face and beard.
- `tools/godot_portrait_export.py` loads `export_godot_pilot.py`'s source unchanged and patches it in memory: one held
  pose, no walk/idle/clip samples or shape keys, `--budget` (26,000) for everything but the protected face parts
  (`Portrait …`, eyeballs). It writes `godot/assets/portraits/<asset>.glb` and a manifest with the eye position and head
  height. `--preview DIR` renders Blender close-ups instead (about 20 s). `tools/export_portraits.py` batches every Greek
  male role (citizens, the player's and Trojan/Atlantean soldiers, charioteers, male heroes and gods except Hades);
  assets without a grown Greek man are skipped. Women, foreign armies and creatures keep the crowd model.
- Typical portrait: 68–95K vertices, 4–7 MB (portrait GLBs are git-ignored like the crowd GLBs; manifests are tracked).
- `ui/character_panel.gd` loads the portrait when it exists (with the role's character finish) and opens people on their
  head and shoulders; the wheel or a double click eases to the whole figure and back.

Limits: static held pose in the window (no breathing or blinking); curls are geometry, not groomed strands; skin is
painted vertex colour; one face per role, not per walker; provenance stays `needs_evidence`. Visual acceptance pending.
