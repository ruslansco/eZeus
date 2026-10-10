# Monster reference art

## Anatomical rebuild from the user's folder — 7 October 2026

The sixteen images in `/Users/ruslans/Documents/Monsters/` match the retained
concept sheets byte for byte. `art/monsters/reference-refinement-v2/reference-map.json`
records that association. The user's rejection of the rounded doll-like models
supersedes the v1 sculptures and the staged v2 detail pass. All sixteen Godot
identities now use `tools/godot_monster_anatomy.py` through the existing exporter.
The stable `monster_reference_v1` runtime contract is retained, with the separate
`design_revision: monster_anatomy_v3` field identifying this geometry.

The new foundations are complete CC0 male/female anatomical meshes, an actual
CC0 wolf body and facial mesh adapted to Cerberus's mastiff proportions, the same
canine craniofacial mesh for Scylla, the CC-BY cave-lion face/eyes/teeth from the
official Blender 5.2 demo for Chimera, and CC0 crocodilian skull planes for Dragon.
The unchanged project quadruped library provides anatomical boar, goat and hybrid
rib cages, elbows, hocks and joint motion. Original features retain the reference
identities: cloven hoof walls, boar tusks/bristles, bull horns, articulated bronze,
Greek clothing, feather/bat wings, snakes, marine necks and eight tapered Kraken
arms with concave paired suction cups. Continuous junctions connect hybrid heads,
torsos, wing shoulders and dorsal plates. Surface families distinguish fur,
scales, human skin and wet octopus skin through the cached VAT-compatible shader.

Editable neutral sources are now
`art/monsters/<species>/<species>-reference-v3.blend`. Each includes its pose
recipe. Keep the earlier v1 scenes as history. Run only isolated background
Blender; the live port-9876 document remains untouched. Do not execute downloaded
demo scripts or replace the shared human/animal libraries. The embedded original
scene README, source archives, hashes and adaptation credits are retained in
`art/monsters/anatomy-v3/vendor/`, `library-sources.json` and
[ATTRIBUTION.md](../../art/monsters/anatomy-v3/ATTRIBUTION.md).

[The comparison gallery](../../art/monsters/anatomy-v3/comparison.html) pairs
each unchanged reference with the former geometry and current installed geometry
in matching studio views. Previous geometry uses the current shared finish and
lighting for that comparison. Installed render evidence is under
`godot/captures/monsters-v3/`; the gallery also links each editable scene.

All 114 samples, species-specific mouth counts, in-place stride, scale envelope,
both UVs, palette, grouped draw surfaces, fresh VAT and reduced LOD contracts
below still apply. Backups for this revision are in
`art/monsters/anatomy-v3/previous-runtime/`; exact raw exports for the lossless
proof are in `anatomy-v3/raw-runtime/`. Only the sixteen deliberate geometry
baseline entries may change. Hydra, native recipes, rules, RNG and saved cities
are excluded. Use `monster-candidates-v3` when following the export sequence below.

This completes an anatomical development-art replacement, with procedural preview
materials. Full painted PBR texture baking, user visual acceptance, slope foot IK,
harpy flight refinement, minimum-Mac profiling and overall release-rights evidence
remain pending. Library licenses are recorded separately from concept/screen-image
provenance. See the latest validation evidence for measured verification scope.

## Remaining sixteen sculptures — 6 October 2026

The user's request covers references **and all 3D models**. Cyclops, Talos,
Hector, Minotaur, Satyr, Medusa, Maenads, Harpies, Calydonian boar, Cerberus,
Chimera, Sphinx, Dragon, Echidna, Scylla and Kraken now have individual generated
concepts and installed reference sculptures. Hydra's source, runtime derivatives
and geometry baseline are untouched. Native monster mappings, rules, collision,
projectile timing/damage, paths, RNG and saved city remain authoritative.

`tools/godot_monster_reference.py` constructs the Godot-only anatomy. It reuses
the Hydra tube/reptile helpers and retained CC0 human face data, with fused muscle
surfaces, articulated limbs/jaws, horns, teeth, dresses, feathers, wing membranes
and species props. The editable **neutral** sources are
`art/monsters/<species>/<species>-reference-v1.blend` in the parent workspace;
the pose recipe is embedded as text. Animation is sampled into GLB morphs and
VAT rather than a new skeletal rig. Always export through background Blender.
Native people/animal sprite recipes and the live Blender document are preserved.

[Reference catalog](../../art/monsters/REFERENCE_CATALOG.md) and
[local comparison gallery](../../art/monsters/monster-reference-gallery.html)
pair each concept with an actual Godot sculpture and front/side/attack/fallen
views. All sixteen exact prompts and built-in `image_gen.imagegen` records are
retained in `art/monsters/generation-records-v1.json`. Eight downloaded film/TV
images or anatomy motifs inform the designs; the other eight use original
mythology/game anatomy. The boar screenshot's exact species is unverified, Phil
is an anatomy motif for Satyr, and TV Sphinx Martindale is not the female game
Sphinx. No unverified character image is presented as a Hercules design.
`assets/monsters/monster_reference_sources.json` records sources, hashes and
that distinction. All source rights remain `needs_evidence`.

Neutral heights range from **1.79 to 2.14 tiles** (approximately **1.89–2.25
displayed citizen bodies**, **73–87% of Zeus**). All non-death sampled pose tops
stay below the measured 2.455466-tile Zeus body. Concept scale captions are
illustrative; decoded mesh measurements govern installation. The new humanoid
monsters have no `character` contract, preventing the citizen scale/finish adapter
from being applied a second time. The retained human validator now expects 104
anatomy-adapted assets; the eight former humanoid monsters are covered here.

Each source has 24 walk, 12 idle, 24 fight, 24 fight2 and 30 die samples, retaining
the 0.64-tile in-place stride and support-foot probes. Mouth counts are species
specific: Cerberus and Chimera three, Maenads three, Harpies two, Scylla seven
(female mouth plus six dogs), the other models one. Kraken has eight animated
arms. Pose-sampled mouth origins now serve all authored monsters through
`monster_effects.gd`; native attacks and the two bounded effect batches remain.

Per-asset caps: 16,500 authored points, 34,000 imported vertices/triangles and
three grouped draw surfaces. Both UV sets and `CityPalette` survive lossless
optimization. UV2 selects ten procedural skin/belly/horn/mouth/tooth/eye/fur/
metal/cloth/snake finishes. Cached `monster_reference.gdshader` materials retain
VAT lookup. Imported LODs are required; only these sixteen baseline entries may
change. Existing models and pose derivatives are backed up under
`art/monsters/previous-runtime-v1`; raw exported candidates are retained under
`art/monsters/raw-runtime-v1` for the lossless proof.

Export/validation sequence:

1. `tools/export_character_assets.py --output-dir godot/captures/monster-candidates-v1
   --assets <sixteen walker IDs> --jobs 2`.
2. Optimize that directory with `tools/optimize_glb_memory.py --backup-dir
   <fresh directory> --only <IDs>`; prove it with
   `tools/verify_glb_optimization.py <backup> --models <candidates> --require-uv`.
3. `tools/validate_monster_reference.py --models <candidates>` checks the complete
   pose envelope, scale, support feet and mouth/contact contracts.
4. Back up/install only the sixteen GLB/JSON pairs, bake their VAT with
   `tools/bake_walker_vat.py --only <IDs>`, then import in Godot.
5. `validate_monster_reference.gd -- --update-monster-baselines` verifies imports,
   reduced LODs, material sharing, clips, pause/death and every mouth transform,
   updating only these approved sculpture entries. Then run retained Hydra,
   monsters, effects, geometry and scoped pose gates sequentially.
6. `review_monster_catalog.gd -- --installed` captures the sixteen sculptures;
   `tools/review_monster_effects.py --monster <kind> --lang en` / `ru` reviews
   native attacks in disposable copies of the designated city.

These are development reference sculptures. The generated concepts contain
finer painted detail than the meshes. User visual acceptance, full material
baking, slope foot IK, harpy flight refinement, minimum-Mac GPU profiling and
release-rights evidence remain pending. See the latest validation section for
verified scope and unrelated broad-suite failures.

## Hydra reference model — 4 October 2026

The three-headed Hydra is now authored and installed as `walker_hydra` in the
Godot city. It follows the user's image and the generated
[concept sheet](../../art/monsters/hydra/hydra-concept-v1.png): three separate
arched necks, a taller central head, heavy brows, crimson eyes, ivory teeth,
a muscular quadrupedal body, four clawed paws and one tapering tail. Charcoal
aubergine skin, smoky belly shields and swept black spines define its finish.
The original seven-headed native recipe and sprite atlases remain intact.

## Sources and authority

- `tools/godot_hydra.py` is the reproducible Godot-only Blender adapter.
  The editable scene is `art/monsters/hydra/hydra-reference-v1.blend` in the
  parent art workspace. Run Blender with factory startup in background mode;
  never replace the user's live scene.
- `tools/export_godot_pilot.py` uses this adapter only for `walker_hydra`.
  `assets/models/walker_hydra.glb` and its JSON retain that stable identity.
  Native head count, coordinates, collision, combat, hero interactions, sound,
  pathfinding, RNG and saves are unaffected by the presentation replacement.
- `shaders/hydra.gdshader` provides matte micro-scales and restrained eye glow.
  UV2 encodes six surface finishes: skin, belly, horn, mouth, teeth, eyes.
  Both UV sets and `CityPalette` survive optimization and the runtime bake.
  `character_appearance.gd` caches the finish; `walker_vat.gd` adds pose lookup
  without replacing it. This is procedural preview art, not fully baked PBR.
- `assets/monsters/hydra_sources.json` records source and reference hashes.
  Provenance remains `needs_evidence`; technical checks do not clear release
  rights or constitute user visual acceptance. The parent art workspace is
  not included in a standalone repository checkout.

## Size, geometry and movement

The scale gate measures decoded neutral mesh body heights against the displayed
tax collector (1.12 presentation multiplier) and Zeus. Semantic UV2 excludes
held props; no god hover offset is included. The neutral Hydra is approximately
2.1 times the citizen body and 81% of Zeus. Its raised combat envelope also
stays below Zeus. Exact measurements are in `captures/hydra-asset-validation.json`.

Allocations: 24,000 authored points, 32,000 exported/imported vertices,
30,000 triangles and two grouped surfaces. Godot generates a reduced LOD ladder.
Only Hydra's geometry-baseline entry is updated for this deliberate art change.
The reference-model budget does not authorize scaling every other monster.

There are 24 walking samples, 12 breathing/neck-sway samples, 24 sequential-bite
samples, 24 shared breath/rear samples and 30 collapse samples. Poses have fixed
topology and no root displacement. The paws counter native travel during 72%
support phases at the existing .64-tile gait period. Surface-sampled ventral
bands follow the swept skin through every pose. Death finishes above flat ground
and holds until the native corpse is removed. `walker_combat.gd` retains action
4/5/6 and native gameplay time, pause, speed and decision semantics.

Three sampled mouth anchors per pose drive venom launch and windup origins,
transformed by the displayed Hydra's actual height and facing. They interpolate
at the same combat phase as VAT/fallback animation. Native projectile timing,
target and damage stay authoritative; green venom adds no poison rule.
Read [effect contracts](GODOT_MONSTER_EFFECTS.md).

## Rebuild and review

From the repository, stage exports before replacing runtime assets:

```sh
python3 tools/export_character_assets.py --assets walker_hydra --jobs 1 --output-dir godot/captures/hydra-candidate-v1
python3 tools/optimize_glb_memory.py --models godot/captures/hydra-candidate-v1 --only walker_hydra --backup-dir /path/to/fresh-backup
python3 tools/verify_glb_optimization.py /path/to/fresh-backup --models godot/captures/hydra-candidate-v1 --require-uv
python3 tools/validate_hydra_asset.py --models godot/captures/hydra-candidate-v1
```

Preserve the previous model and derivatives, install the validated GLB/JSON at
the stable asset path, bake with `python3 tools/bake_walker_vat.py --only
walker_hydra`, then import with Godot. Run `validate_hydra.gd` with the explicit
`--update-hydra-baseline` argument only for an approved art revision. It edits
only that entry. Retain `validate_geometry.gd`, `validate_assets.gd`,
`validate_poses.gd -- --only=walker_hydra`, `validate_monsters.gd` and
`validate_monster_effects.gd`.

`review_hydra_model.gd -- --installed` captures eight neutral studio views,
combat/collapse poses and an actual-mesh citizen/god comparison. Run visible
`tools/review_monster_effects.py --lang en --record` and `--lang ru` sequentially
with the designated city and scratch preferences. They exercise real native
building attacks; the recorded destruction is not a renderer-side simulation.
Evidence and current counts are in [validation](GODOT_VALIDATION.md).

## Remaining review

User visual acceptance, full painted material baking, slope/stair foot IK,
multiple simultaneous combatants, wider campaign coverage and matched
minimum-Mac GPU profiling remain pending. Current contact verification is an
authored flat-ground pose envelope; the game retains its existing terrain-following
root, not per-paw terrain adaptation. Other monster bodies retain their prior
art until independently authored and reviewed.
