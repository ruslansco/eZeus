# Field-worker activity — 5 October 2026

Godot field work follows read-only C++ observations. Economy, combat damage,
production, livestock replacement, routes, RNG, native coordinates and saves
remain unchanged. Work uses the interpolated gameplay clock shared with
water-life activity; pause, speed and required decisions apply. Carrying and
cattle-leading gait phase follows horizontal travel with the retained .64-tile
stride. The crowd VAT and source blend-shape fallback use the same pose pairs
and .22-second entry, exit and work-state transitions.

| Native role/state | Godot asset/clip |
| --- | --- |
| Hunter fight/collect (4/7) | `walker_hunter` or native deer variant `walker_deerhunter`, `hunt` |
| Hunter loaded return (14) | Authored shoulder-carried boar / rope-dragged deer, `carry` |
| Shepherd collect/groom (7/4) | `walker_shepherd`, hand-anchored shears / crook, `shear` / `groom` |
| Goatherd collect/groom (7/4) | `walker_goatherd`, crouched milking / crook, `milk` / `groom` |
| Loaded sheep/goat return (14) | Fleece bundle / milk jug, `carry` |
| Grower prune grapes/olives (8/9) | `walker_grower`, `prunegrapes` / `pruneolives` |
| Grower harvest grapes/olives (11/12) | `walker_grower`, `pickgrapes` / `pickolives` |
| Orange tender prune/harvest (10/13) | `walker_orangetender`, `pruneoranges` / `pickoranges` |
| Corral worker leading cattle | `walker_rancher`, guiding crook and `lead` |
| Boar/deer fight, collapse, lie (4/6/2) | `animalattack`, held-final `fallen`, `restanimal` |

`walkerAsset` uses the native hunter/grower variant instead of a generic model,
and distinguishes the goat handler and corral worker. Snapshot `field_load`
comes from the actual hunter/shepherd/goatherd collection count. A carry action
with zero goods never creates a carcass, fleece or jug. `field_task=lead_cattle`
comes from read-only take/replace action accessors; the rancher does not hunt
cattle. No nearest-animal heuristic or invented damage/harvest outcome is used.
The corral's existing authored building cycle is retained and `working` now
requires native cattle processing as well as staffing/shutdown/fire eligibility.

The native sheep/goat collection action hides its animal until collection
finishes. Its authored work model supplies that hidden animal alongside the
worker; travel/carry/groom clips hide this embedded geometry. Thus shearing and
milking remain visible without making a native hidden animal visible or adding
another native entity. A short blended presentation stance places the worker
.30 tile behind its native work centre, with feet on generated terrain and hands
reaching into the target. Native position/path/picking observations are intact.
The corpse collapse excludes the source's sprite-camera fitting translation.
The Godot boar load is raised .12 tile and widened from .55 to .70 of the
animal kit scale so it sits visibly above the cloak on the shoulders; the
native sprite recipe and carried-meat count are unchanged.

Sources are the existing `art/characters/people/people*.py` and
`art/characters/animals/build_animal.py` in the parent workspace, with
Godot-only shears/cattle-handling adaptation in `tools/godot_field_work_art.py`.
`tools/export_field_workers.py` stages nine models in independent background
Blender processes. It never accesses or saves the user's live scene.
The field-only export evaluates the same sparse skin weights per bone rather
than allocating all vertex/bone pairs; sampled results must match the source
calculation within 1e-12. Native skinning and other export roles are untouched.
Optimize staged GLBs with `tools/optimize_glb_memory.py`, verify both UV sets and exact
poses with `tools/verify_glb_optimization.py --require-uv`, install GLBs/manifests,
bake fresh VATs with `tools/bake_walker_vat.py`, then import. Keep native recipes,
faces/role clothing, `CityPalette`, UV/UV2, morph aliases and reduced LODs.
Only these nine geometry baseline entries belong to this change. Shared pose
textures are per role, not per worker; no additional particle or light system
is added. Individual manifests record `authored_field_work_v1` and development
provenance remains `needs_evidence`.

Checks: `validate_field_work.gd`, retained gathering/water-life/locomotion and
building-activity gates, `validate_poses.gd`, `validate_geometry.gd`, embedded
engine and seeded replay. Visible reviews use
`tools/review_field_work.py --lang en --record` / `--lang ru` sequentially with
scratch preferences and the designated saved city. The workers, work targets
and active corral in those views are render-only fixtures on actual terrain;
they never alter the core/save or live roles. Captures prove presentation and
state selection, not complete production journeys through every campaign.
User visual acceptance, slope foot IK, full material baking and minimum-Mac
profiling remain pending. See `GODOT_VALIDATION.md` for verified results.

## Townspeople's work clips — 5 October 2026

The same authored-clip path now covers the crews whose native work states Godot never showed. The clips come from the
existing people-kit states (`CLIPS` in `tools/godot_field_work_art.py`), selected in `scripts/gathering_motion.gd` from the
native action (no new simulation data; a collector carries only with goods collected, `goBackDecision`):

| Native role/state | Godot asset/clip |
| --- | --- |
| Firefighter carry (14) / put-out (4, native "fight") | `walker_firefighter`, `carry` / `putout` (the 40-frame boomerang throw in one 24-sample loop) |
| Lumberjack collect/carry (7/14) | `walker_lumberjack`, `chop` / `carry` (log on the shoulder) |
| Bronze, silver, orichalc miner collect/carry (7/14) | `walker_*miner`, `mine` / `carry` (ore basket) |
| Quarryman collect (7) | `walker_marbleminer`, `quarry` |
| Artisan build / build standing (20/21, 4) | `walker_artisan`, `build` / `buildstand` |

Their `die` clips are exported too. The sick man's coughing clip was left out: the engine never sets his fight state.
`validate_work_clips.gd` (189 checks) covers every action of these seven in the source and VAT models, pause, clock and
distance phase, return to travel, no combat clip for the native "fight" of a firefighter or artisan, and death;
`review_work_clips.gd` captures render-only fixtures (`captures/work-clips-*.png`). The pose textures of the seven add about
52 MB. `validate_characters.gd` now accepts these work clip names (and the field work's), which it had been rejecting.

## Wolves, sheep and goats — 6 October 2026

- **Coat colours:** `export_godot_pilot.py` now writes the animal kit's per-point `Coat colour` as the vertex palette for every
  `animal_*` model (it did so only for monsters), so the wolf, sheep, goat, boar, deer, donkey, horse, ox and cattle are no
  longer exported white. `altar_rite.gd` `BULL_COAT` became a light multiply (.92/.68/.52) over the ox's own coat.
- **Anatomy** (`art/characters/animals/species.py`): the wolf rebuilt on a grey wolf's proportions (deep narrow chest, tucked
  loin, big head with broad muzzle, pricked cone ears, neck ruff, sturdier legs with the elbows at the chest, Apennine
  grey-fawn coat with cream cheeks and tawny legs) and a fuller lunge; the sheep with a short wool-covered neck and the
  head carried low (it had a llama's neck), sturdier legs; the goat with a deep barrel, long guard hair and larger ears.
  The SDL sprites of these species were not re-rendered.
- **Clips:** `ANIMAL_STATES` in the exporter adds `fallen` and `restanimal` for the wolf, sheep and goats (and the wolf's
  `animalattack`); `gathering_motion.gd` plays them from native actions 6, 2 and (wolf) 4. Animals lie down half the time
  (`eAnimalAction::decide`), which Godot now shows.
- **The bite** (`scripts/wolf_attacks.gd`): the engine puts both a wolf and whoever it attacks into the fight action; the
  victim is the nearest other fighting walker within 1.6 tiles (no fight pairs are published). At the clip's two snaps dust
  is kicked up where they grapple, wool or hair tears loose from an animal victim, and the victim flinches away. The attack
  and hit sounds are the engine's own. `validate_wolf_attack.gd` (47 checks); `review_wolf_attack.gd` captures render-only
  fixtures (`captures/wolf-review-*.png`).
