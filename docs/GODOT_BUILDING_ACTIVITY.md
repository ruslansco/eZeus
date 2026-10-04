# Building work animation — 1 October 2026

The static Godot exports previously captured only `animate(0, True)` from the
building recipes. Native staffing worked, but on-site workers and machinery had
no playable work cycle. The activity derivative now samples the existing eight
work poses and the worker-free inactive pose. It separates animated pieces from
static architecture and bakes only their position deltas into RGBA half-float
textures. Original building GLBs and native sprite atlases remain unchanged.

## State and clock contracts

- C++ snapshots append read-only `workers`, `working`, and `animation_offset`.
  Employment, industry shutdown, production inputs, patrol availability and fire
  remain native. `working` follows `enabled()` and native `overlayEnabled()`;
  employing buildings also require employees and no shutdown. Palace and baths
  are native decorative buildings without employment, so their existing activity
  follows native enabled/overlay state instead.
- Read the already-existing native frame shift for phase variation. Do not draw
  simulation RNG, change staffing or advance production to animate a mesh.
- The work clock is native gameplay `time / 30`: ten sampled phases per second
  at normal speed. Interpolate received clock values over 100 ms. Native pause
  and pending decisions freeze it, and all four native speeds remain exact.
  Set the global shader clock modulo eight to retain GPU float precision.
- Register `building_work_clock` in `project.godot`. Never enumerate global shader
  parameters at runtime: that API is editor-only on the Metal renderer.
- Dynamic MultiMesh instances carry work flag and phase offset in custom data.
  Work-state changes update those values without rebuilding geometry. Buildings
  without a work derivative retain the original static model; placement ghosts
  keep their existing source model. Cache contracts/textures/materials once per
  asset. Derivatives require a matching original-model SHA-256 and complete VAT.
  Require every `work_00` through `work_07` and `inactive` alias. The explicit
  first pose hides effects absent at frame zero while retaining non-degenerate
  rest geometry/normals for particles that become visible later.
- No per-frame building list is needed: the existing delta snapshot cache still
  resends buildings only when state/geometry changes. No AnimationPlayer, skeleton
  or new per-building process is added. Keep spatial batches, imported mesh LODs,
  the three-pixel LOD threshold and native foundation transforms.

## Coverage and rebuilding

`tools/building_activity_assets.json` is the 35-type catalog: hospital, fountain,
warehouse, watch/maintenance/tax offices, gymnasium, granary, bibliotheke,
observatory, university, laboratory, inventors workshop, museum, hunting lodge,
fishery, carding shed, growers/orange lodges, trade post, harbour, food/fleece/oil
vendors, timber mill, masonry shop, foundry, winery, olive press, sculpture studio,
artisans guild, palace, baths, refinery and black marble workshop.

Run from the repository:

```sh
python3 tools/export_building_activity.py
python3 tools/verify_building_activity.py
./tools/build_godot_extension.sh
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --import
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/validate_building_activity.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --path godot --rendering-method mobile --rendering-driver metal --script res://scripts/review_building_activity.gd
```

Use `--assets olive_press winery` for a limited background export. It runs in
disposable Blender processes, preserves the live Blender scene, blocks source
writers and excludes SDL inventory-overlay generation. Raw sampled sources live
in `assets/building_activity/source/` under `.gdignore`; morph-free runtime GLBs,
VATs and provenance/layout manifests live in `assets/building_activity/runtime/`.
Re-export and re-import after source art changes. Do not write original models
or native atlases to regenerate activity. Retain `needs_evidence` provenance.

## Verified scope and limits

The 35 derivatives pass asset-address, moving-cycle/inactive, native staffing,
shutdown/resume, pause, speed, pending-decision and incremental-batch checks.
The visible Metal review samples olive press, timber mill and warehouse on their
actual placements in the designated test city, reads back independent work flags,
and captures worker-free olive presses. A separate decoder checks all 864 authored
part poses against the actual baked texels, byte-identical rest attributes/UVs and
indices, unchanged original GLBs, six-or-fewer finish groups and the original
per-building triangle budget (at most five percent growth). Native city state stays unchanged.
See `GODOT_VALIDATION.md` for current counts and files.

This connects existing authored animation, not the new physician art benchmark
to building workers. Their body/material realism remains a separate art task.
Interpolated position samples retain rest normals, so rotating tools approximate
lighting. Runtime instances still have at most six static/dynamic finish groups,
instead of the original three; all 35 VAT files total 67.8 MiB, loaded only for
present types. Minimum-hardware performance has not been established. Inventory
overlays, cargo, construction stages, fire/destruction, combat/death, rowers and
unmapped campaign building types still require their own state/content coverage.
