# Hydra reference model — 4 October 2026

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
