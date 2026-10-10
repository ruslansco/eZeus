# Farm growth presentation — 9 October 2026

## Native authority

`eFarmBase` already owns a five-stage harvest cycle in saved `mRipe` and
`mNextRipe`. Its new read-only `harvestProgress()` reports
`(mRipe + clamp(mNextRipe / sFarmRipePeriod, 0, 1)) / 5`. The native method still
produces four loads and resets at its existing fifth-stage threshold. Staffing,
blessings/curses, industry shutdown, enabled state and saved phase retain their
existing behavior. No new save fields, RNG calls or harvest scheduling are added.
`usedFields()` shares the original native overlay rule
`clamp(round(1 + effectiveness() * 4), 0, 5)` without changing it.

Snapshots append a small `farm_crops` list (`id`, `crop`, normalized `progress`,
`fields`) during the existing building traversal. It is independent of the cached
architecture records, so growing crops alone never resend the full building list.
The inspection's `production.harvest_progress` reads the same native method.
The EN/RU production panel shows a floored readiness percentage and progress bar,
separately from already-harvested output waiting for transport. This is current
cycle completion, not a promised wall-clock ETA. Inspection refresh retains its
existing schedule and target/draft guards.

## Wheat geometry and runtime

The original `farm.glb` and `art/farm/build_sprites.py` remain intact. The villa
source uses five field tiles in a front L; `farm_crops.gd` overlays original
procedural stalks, leaves, tapered grain heads and awns on those exact fields.
It applies the same `main.gd` building transform, including native foundation,
road setback and facing. Blender +Y converts to Godot -Z exactly once.

One shared ArrayMesh has 4,200 vertices / 1,400 triangles per full-detail field
and two sparse index LODs. Both authored UV arrays encode grain-head anchors;
there are no external raster assets, skeletons, AnimationPlayers, physics,
navigation or native resource draws. Spatial 16-tile MultiMeshes share one wheat
material. Growth changes only instance custom data; layout changes rebuild only
affected batches. Demolition, reload and overlay visibility remove stale crops.
Range culling ends at 110 tiles; reduced LODs bound distant cost. Minimum-platform
GPU cost is not established by these geometry budgets.

`farm_wheat.gdshader` grows green shoots continuously in height, unfolds grain
heads later, and turns mature stalks gold. At a native harvest reset, the field
returns to bare furrows and begins its next cycle. Subtle sway uses the existing
gameplay `building_work_clock`; pause and pending-decision holds apply. No separate
real-time growth estimate runs in the renderer. Shader deformation retains the
authored rest normals, so its small sway uses approximate lighting.

Wheat is the implemented visual crop. Other native farm types can expose their
readiness through the shared base but retain their existing art until separately
authored. The new code-created wheat overlay is original presentation geometry;
the retained villa's `needs_evidence` provenance is unchanged.

## Verification

Run `validate_farm_crops.gd`, `validate_industry.gd` and `validate_ui_text.gd` with
the signed embedded extension. Native checks use only the designated test city
in memory and a scratch save round trip. Run sequential disposable
`tools/review_farm_crops.py --lang en` / `ru` for Metal geometry, GPU custom-data,
all four facings, reduced field coverage and translated inspector samples.
The gallery's 0/20/50/85/98% samples are presentation fixtures, not injected
native farm maturity. Current counts, captures and limits are recorded in
`GODOT_VALIDATION.md`. Preserve original art/GLB hashes, native save/RNG rules,
building delta caches and shared Theme/text scaling when extending this layer.

`--city` also runs the actual `main.gd` observation/placement path, native growth,
inspection and GPU reuse in the designated city held in memory. Its extra mature
city sample is explicitly labeled and restored without changing native maturity.
The build helper accepts `EZEUS_GODOT_BUILD_DIRECTORY` for isolated output when
another development job is using the default folder; staged signing/atomic
installation remain mandatory.
