# Saved-city model coverage — 30 September 2026

The dark footprint squares and moving gold dots were conversion placeholders.
The embedded presentation now maps every initially visible object in the designated
`CLAUDE-TESTING-ADVENTURE.ez` city to its own source geometry, or an explicitly
non-rendered native ownership/reservation record.

- Initial native building records: 834. Actual model placements: 792. The remaining
  42 are 40 livestock reservations and two sanctuary owners. Native livestock
  characters and sanctuary components render separately; these records must not
  draw a second animal or a box over the assembled sanctuary.
- Initial visible walkers: 279 across 28 native types. People, handcarts, trailers,
  animals, a fishing skiff and merchant ships replace the gold spheres.
- Coverage validation requests 60 seconds of native simulation and checks each
  resulting snapshot. It finds 140 distinct model IDs and no missing models.
  A native decision becomes pending and remains unanswered; later snapshots hold
  native gameplay time. This is a presentation coverage check, not 60 seconds
  of uninterrupted gameplay or deterministic whole-game replay proof.

## Content contracts

All 31 existing human walker GLBs (and `walker_archer`, added with the walls slice) now use the natural people adapter and runtime
finish. Painted skin, eyes, face/hand detail and fitted hair survive export;
occupations retain distinct anatomy/props and predominantly fair/light olive skin.
The philosopher's cream tunic, blue wrapped himation and Greek key hem follow the
user's clothing reference with natural proportions. The settler mother and child
retain separate female/age-specific meshes. Both UV sets and palette colours are
required; do not flatten them or strip them during memory optimization. Read
[the character art contract](GODOT_CHARACTER_ART.md). Embedded building workers,
boat rowers, full procedural texture baking and facial/work/death/cargo animation
remain pending.

Defences (1 October): `tower` (2x2, `art/tower/build_sprites.py`), `gatehouse` (5x2: two gate towers, `--gate`, composed with a vaulted passage by
`tools/godot_gatehouse.py`; the 2x5 form is the same model turned) and `walker_archer` (the people kit's archer through the natural people adapter, shown
standing on wall and tower tops through the snapshot's `lift`) complete the walls slice. The archer has no shooting animation yet.

Soldiers (2 October, the army slice): six more people-kit identities through the same adapter, added to `PEOPLE` in `tools/godot_asset_sources.py` and exported with
`tools/export_character_assets.py`: Atlantean `walker_hopliteposeidon` (trident and blue shield, 15,996 vertices), `walker_archerposeidon` (15,666; also the Atlantean tower archer, which no longer shares the Greek model)
and `walker_chariotposeidon` (a charioteer with two horses, 34,232), and Greek `walker_greekhoplite` (15,841), `walker_greekrockthrower` (a slinger, 15,551) and `walker_greekhorseman` (32,909).
The two mounted units carry their horses, so `tools/export_godot_pilot.py` gives them a 32,000-vertex allocation and a 45,000 cap (persons keep 15,000 and 22,000). Each is memory-optimized (`verify_glb_optimization.py --require-uv`: 0 differences)
and has a baked pose texture (`bake_walker_vat.py`: 3.0 to 6.4 MB each, 25 MB for the six). The snapshot's `asset` for a soldier follows the character type: `archerPoseidon`, `hoplitePoseidon`, `chariotPoseidon`, `hoplite`, `rockThrower` and `horseman`. Not yet modelled: the amazon and Ares warrior sanctuary companies, the enemy armies' soldiers, and the soldiers' fight and death poses.

Fighting (2 October, the fighting slice): 46 more people-kit identities through the same adapter, and nine exported again with clips (so 55 models carry them). Lists in `tools/godot_asset_sources.py`: `PEOPLE` (what can be exported), `COMBAT` (what gets clips), `MOUNTED`
(what carries a horse: a 32,000-vertex allowance and a 45,000 cap), `GODS` and `HEROES`. New models: the player's Roman-army soldiers `walker_hoplite`, `walker_horseman`, `walker_rockthrower`; the invading nationalities `walker_trojanhoplite`, `trojanspearthrower`, `trojanhorseman`,
`centaurhorseman`, `centaurarcher`, `persianhoplite`, `persianarcher`, `persianhorseman`, `oceanidhoplite`, `oceanidspearthrower`, `egyptianhoplite`, `egyptianarcher`, `egyptianchariot`, `atlanteanhoplite`, `atlanteanarcher`, `atlanteanchariot`, `phoenicianhorseman`, `phoenicianarcher`,
`mayanhoplite`, `mayanarcher`, `amazonspear`, `amazonarcher`, `areswarrior`; the gods `walker_apollo`, `ares`, `artemis`, `athena`, `atlas`, `demeter`, `dionysus`, `hades`, `hephaestus`, `hera`, `hermes`, `poseidon`, `zeus` (with the earlier `aphrodite`); the heroes `walker_achilles`, `atalanta`,
`hercules`, `jason`, `odysseus`, `perseus` and `bellerophon` (on Pegasus, 32,810 vertices; with the earlier `theseus`). A clip is a run of shape keys `<clip>_NN` taken from the identity's `STATES` at its native frame count: `fight`, `fight2`, `die` for soldiers and heroes, and `bless`, `disappear`, `appear` for
gods. Props that the walk puts away are part of the model (their rest geometry comes from the first clip frame that shows them, and the poses that hide them fold them to a point inside the body). A model with props that the walk hides has an explicit `walk_00` shape key as well. The snapshot's `asset` follows the character
type (`walkerAsset` in `presentation/esimulationservice.cpp`); the amazon type picks its spear or bow form from its `isArcher` flag. The seventeen monsters are modelled too (next paragraph).

**Monsters (2 October).** All seventeen `eMonsterType`s have a model, 17 more GLBs (342 in all): eight with human bodies from the people kit (`walker_cyclops`, `talos`, `hector`, `minotaur`, `satyr`, `medusa`, `maenads`, `harpies`; 15,000 to 16,300 vertices, the human adapter, both UV sets and `CityPalette`; the harpies hover about half a metre over the ground) and nine animal-kit creatures (`walker_calydonianboar`,
`cerberus`, `chimera`, `sphinx`, `echidna` at 20,000 to 24,500 vertices; `hydra`, `dragon`, `scylla`, `kraken` at 700 to 2,000 vertices, smooth and plain). Each carries `walk`, `idle`, `fight`, `fight2` and `die` shape keys baked as poses; the kit's per-point `Coat colour` attribute is the vertex palette of the creatures (without it a Cerberus came out white), written by the `CREATURES` path of
`tools/export_godot_pilot.py`. The type is chosen by `walkerAsset`; the kraken and Scylla swim in deep water and the others walk the roads. Not modelled: a monster's death in the water (the die clip is the kit's), spray or foam beyond the kit's foam rings, and the scale beside the 1:1 SDL art (the creatures are the kit's own sizes).
 
**Heroes' halls (2 October).** All eight halls have a model, 6 more GLBs (348 in all): `hero_hall_achilles`, `bellerophon`, `hercules`, `jason`, `odysseus` and `perseus` join `atalanta` and `theseus`. Each is the Roman heroon of `art/hero_hall/build_sprites.py --hero <name>` (a peripteral shrine on a podium with the hero's colour on the frieze, a banner, trophies of arms and a gilded statue with the hero's attributes), about 27,000 vertices and 5 to 6 MB, exported through the
generic recipe path (`RECIPES` in `tools/godot_asset_sources.py` lists all eight). The footprint is the native 4x4.

**Sanctuaries (2 October).** The fourteen gods' statues and monuments all have models, 14 more GLBs (362 in all): `sanctuary_statue_<god>` and `sanctuary_monument_<god>` for `athena`, `atlas`, `demeter`, `hades`, `hera`, `poseidon` and `zeus` join the seven of the saved city (`art/sanctuary_statues/build_sprites.py --god <name> [--monument]`, the recipes of `tools/godot_asset_sources.py` list all fourteen). With the temple pieces (`sanctuary_temple_0` to `3`), the court tiles (`sanctuary_court_0` to `5`) and the altar, every piece of every layout in `eZeus/Sanctuaries/` has a model
(`validate_sanctuaries.gd` checks each piece the preview lists). A piece that has not begun is drawn as the paving tile over its footprint and one that is being built is scaled in height by its progress (stages are not separate models). **Facing (2 October):** the temple pieces, statues and monuments are turned in quarter turns by the snapshot's `orientation` so that the temple's entrance and every god look to the sanctuary's front (see `AGENTS.md`). The temple GLBs keep their authored facing (pieces 0 and 2 toward +x, 1 and 3 toward +y), the small statues face +y, and the 14 monument GLBs were re-exported on 2 October with the figure facing +y (`tools/export_godot_pilot.py` sets the figure group's turn to zero; the 2D sprites' 45 degree turn made the pedestal diamond-wise in the tile grid): same vertex counts, new bounds, manifests rewritten.

**Pyramids, monuments and shrines (2 October).** The 54 wonders add no model: each piece of a layout (`ePyramid::sPlan`) maps to one that exists. Walls and capstones are `pyramid_p1_<n>` (a level above the ground) and `pyramid_p2_<n>` (the ground level; 34 and 38 GLBs, light and dark marble, the stairs, eagle and wreath faces) chosen by `pyramidWallAsset` from the piece's orientation, special and level; floors are `palace_tile_plain` (light) or `pyramid_p2_32` (dark), and the two emblem floors `pyramid_p2_33` and `pyramid_p2_34`; statues and monuments are the god's `sanctuary_statue_<god>` and `sanctuary_monument_<god>`, then `sanctuary_altar`, `sanctuary_temple_0` (4x4), `observatory` (5x5) and `museum` (6x6). A filler tile of a larger piece is `native_marker`; larger pieces are placed by their real rectangle. The pyramid GLBs are authored at the SDL game's proportions (a level 30 px, .408 of a tile), the terrain here rises .22 of a tile a step, so `main.gd` lowers them by `PYRAMID_RISE` (.5388) and lifts each piece by the steps its level raises the ground. While a piece is built its ground rises under the paving slab `sanctuary_court_0`; the SDL sprites' ashlar cubes (`pyramid_p1_34` to `pyramid_p1_43`) are renders only and are not exported. `validate_pyramids.gd` checks that every piece of all 54 layouts has a model and that founding each one puts exactly the previewed pieces in the city.

The last fifteen buildings (1 October): `podium`, `college`, `drama_school`, `theater`, `mint`, `corral`, `dairy`, `armory`, `chariot_factory` (each `art/<name>/build_sprites.py`, exported
by name; 28,000 to 38,000 vertices, about 53,000 to 69,000 triangles, 6 to 10 MB of GLB) and the small garden pieces `deco_bench`, `deco_birdbath`, `deco_short_obelisk`,
`deco_tall_obelisk`, `deco_flower_garden` and `deco_gazebo` (`art/decorations/build_sprites.py --kind`, 77 to 28,000 vertices). Every extent matches the native footprint. With them every
`buildSpecs` row names a model. The buildings are shown as exported (the pose of the first frame): the native sprites' working animation (performers, students, the corral's keepers) is not authored in 3D, and
livestock are separate snapshot records.

Agora vendors (1 October): `wine_vendor`, `arms_vendor`, `horse_vendor` and `chariot_vendor` join the food, fleece and oil stalls (`art/agora/build_stall.py --kind`; 24,700 to 28,700
vertices each, 48,000 to 57,000 triangles, 5 to 7 MB of GLB), so all seven goods have a stall. Stock and the vendor at work are not shown (the SDL game's unstocked/working frames are
not authored in 3D).

Elite housing (1 October): the ten remastered estates `elite_house_<0-4><a|b>` (`art/elite_house_<key>/build_sprites.py`, exported by name; 34,000 to 37,000
vertices each, about 61,000 to 65,000 triangles after the imported LODs, 7 MB of GLB each) are picked by the snapshot from the house's level and seed. They show the
inhabited estate; vacant plots and Atlantean cities use the same set (the SDL game's choice for Atlantean estates), and the household task of the sprites is not animated.

`tools/godot_asset_sources.py` describes the shared source recipes. The C++
service selects native house levels, orchard ripeness, wall connections,
commemorative identity, temple piece IDs, paving IDs, god identities and pyramid
piece/tone variants. Sheep appearance changes retain their native entity IDs;
Godot replaces their models when the selected asset changes. Positions, prices,
pathfinding and simulation coordinates remain native and independent of camera yaw.

The palace export keeps both authored halves, centers the full building and fits
its native 8×4 footprint. Rotation fitting uses the rotated width/depth. Temple
pieces remain distinct 4×4 modules, rather than overlapping full sanctuary models.
Sky reflections illuminate metal roofs and gold figures.

Most characters reuse their own authored anatomy, wardrobe, tools and gait.
The three previously absent science roles have distinct local profiles and carried
instruments in `tools/godot_science_walkers.py`; the small fishing skiff and its
anatomical rower are authored in `tools/godot_fishing_boat.py`. These use the local
geometry/anatomy kit and retain `needs_evidence` provenance status.

Exports use realtime geometry budgets and batch compatible PBR finishes with
per-vertex colours. Morph targets are retained. The batching keeps colour and
silhouette while approximating roughness/metallic finishes; full procedural
material baking remains pending. Workers/machinery in 35 building types now use
eight authored work phases and an inactive pose; ships still use an authored
pose. Read [building activity contracts](GODOT_BUILDING_ACTIVITY.md). Sampled
walkers have 24 walking phases and 12 held idle phases; physician
idle retains breathing. Work, combat, death, cargo/load states and complete authored
idle motion still need coverage. Other campaigns may require additional models.
Farm crops and sanctuary and pyramid construction stages are not yet a complete visual state
matrix; the current city coverage does not establish that parity.

Terrain mineral outcrops and forest-edge grass/shrubs are now authored separately
as cached procedural meshes in `godot/scripts/terrain_details.gd`, with a source
manifest under `godot/assets/terrain/`. They do not change the 240 GLB count.
Four mineral kinds have native saved-city coverage; silver/tall stone/black marble
remain geometry-only checks. The map-review forest presentation uses independent
procedural trees with leaf blades, wind and reduced mesh LODs; the old tree GLBs
remain available. Native water roads now have procedural 3D crossing decks and
shore approaches, separately from the 240 GLBs. Native walker absolute positions
convert from corner-based coordinates into centered Godot cells once. Read
`GODOT_TERRAIN.md` for identities, native clearance, budgets, provenance and the
remaining species/bridge topology, performance and wider terrain work.

**Sanctuary rites (3 October).** One more GLB (363 in all): `walker_priestess`, a people-kit woman (`art/characters/people/people11.py`; saffron chiton, cream veil, gilt fillet, bronze knife) with the combat clips `fight` (the sacrifice, 24 frames), `fight2` (the offering, 12) and `die` (8), 15,500 vertices, baked like the soldiers. She is shown only beside an altar with a rite on it (the walkers' list's `scene` records; see `eZeus/AGENTS.md`, "Sanctuary rites"); she is not a native walker type and never walks the city. The sacrificial sheep and bull are the existing `animal_sheep_fleeced` and `animal_ox`; the offering of goods (amphorae, a dish, fruit) is built in code (`scripts/altar_rite.gd`, no GLB); the braziers' flames are a Godot-only effect (`shaders/ritual_flame.gdshader`) over the altar GLB's static flame, which is unchanged.

## Garden foliage

The eight garden recipes use `tools/godot_garden_foliage.py` revision 1 during
Godot export. It substitutes vegetation calls without editing native sprite
sources: branches/stems, opaque folded double-sided leaves, varying greens,
volumetric canopies, climbing vines and individually leaf-covered formal shapes.
Trees have no solid canopy spheres. Close-clipped spirals/peacock/maze retain
recessed support masses; ordinary cone topiaries are leaf geometry. Garden water
uses the authored Principled colour rather than Blender's default diffuse grey.
This is geometry and preview PBR, not a complete procedural material bake.

| Asset | Native city objects | Footprint | Source vertices / budget | Surfaces |
| --- | ---: | --- | ---: | ---: |
| Fish Pond | 6 | 4x4 | 80,851 / 85,000 | 2 |
| Topiary | 3 | 3x3 | 45,374 / 50,000 | 2 |
| Hedge Maze | 1 | 3x3 | 118,121 / 120,000 | 3 |
| Park | 164 | 1x1 | 12,434 / 16,000 | 2 |
| Shell Garden | 1 | 2x2 | 8,968 / 35,000 | 3 |
| Sundial | 1 | 2x2 | 6,472 / 35,000 | 3 |
| Dolphin | 1 | 3x3 | 39,759 / 45,000 | 3 |
| Orrery | 1 | 3x3 | 32,862 / 45,000 | 3 |

Budgets protect leaf shapes from destructive generic decimation and then allocate
the remaining allowance to architecture. The higher unique garden budgets are
bounded, not a production performance acceptance. Source vertices weighted by
these 178 placements fall from 4,851,774 to 2,866,586 because parks no longer carry
a shrunken tholos. GLTF may split vertices for UV/normal seams; these counts are
not GPU vertex counts or FPS predictions. Compatible PBR surfaces remain batched.

`RECIPES['park']` explicitly selects `--only pine`. Its real 1x1 bounds preserve
native tile anchors and full tree height. Native prices, ownership, paths,
placement and IDs do not change. Random foliage layout uses local stable Python
seeds, never native simulation RNG. The live Blender scene and native SDL atlases
stay intact. Each GLB manifest records the adapter, revision, footprint and budget
and retains `needs_evidence`. Garden foliage is static; species/park diversity,
wind, material baking and wider campaign/state coverage remain pending.

## Export and verification

Use isolated background Blender processes. Keep the user's live Blender scene intact.
The exporter suppresses sprite rendering, source-scene saving, atlas metadata writes
and atlas split-render holdouts. It writes the GLB and its manifest into the Godot
model folder, or `--output-dir` for isolated checks. Every export now applies colour
batching automatically. `tools/optimize_godot_models.py` can batch previous exports.

```sh
python3 tools/export_city_assets.py --group structures
python3 tools/export_city_assets.py --group walkers
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --editor --path godot --log-file "$PWD/godot/captures/asset-import-engine.log" --quit
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --log-file "$PWD/godot/captures/assets-engine.log" --script res://scripts/validate_assets.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --log-file "$PWD/godot/captures/coverage-engine.log" --script res://scripts/validate_city_coverage.gd
python3 tools/run_godot_pilot.py --garden-review after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/garden-contract-engine.log" --path godot --script res://scripts/validate_gardens.gd
python3 tools/run_godot_pilot.py --asset-review --lang en
```

The explicit review mode captures overview, palace, museum, housing and sanctuary
views, moving transporters, sheep and fishing boats at 45°, 135°, 225° and 315°,
then closes. It uses the protected test-city
launcher and does not save simulation changes. See `GODOT_VALIDATION.md` for final
check results and performance limits. Generated models and captures remain ignored
by Git; no rights clearance or production packaging is implied.
