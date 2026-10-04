# Modern renderer and full camera rotation

**Godot embedding now implemented:** `../godot/project.godot` and the root
`Launch Godot 3D.command` provide continuous Q/E orbit around real meshes while
the native test city runs its original simulation. The SDL controls described
below retain their four sprite views. See `GODOT_MIGRATION.md` and
`../godot/README.md` for the current boundary and remaining migration work.

## Retained native SDL reference, verified in this checkout

The game is C++17/SDL2 with a fixed 20 Hz simulation and a separately paced viewport. `eWorldDirection` is ordered N, W, S, E. `eGameWidget::setWorldDirection()` changes the board's presentation direction, preserves the focal tile subject to map-boundary clamping, refreshes terrain and maps, and updates the compass. It does not physically rotate the city tile array. The toolbar already exposes these four views. Tile-centering now uses pixel/grid coordinates directly to avoid a one-tile rounding drift observed at 2560×1440.

Q and E now call that same path, left -1 and right +1 respectively, once per physical key press. Repeated OS keydown events and Ctrl/Cmd combinations do not spin the map. R retains its existing placement-preview behavior; the default eyedropper is C. The controls dialog permits rebinding both camera directions. Legacy defaults migrate; a custom binding occupying Q/E or C is preserved rather than overwritten, potentially leaving a camera action unbound until configured. New empty bindings survive save/load.

This completes stepped rotation through 360 degrees in the existing renderer. Continuous yaw between those views needs more than an input change. Most runtime art is an RGBA sprite atlas with lighting, silhouette and perspective baked into the pixels. Rotating the final screen image would tilt UI/ground and give incorrect geometry, picking and occlusion. Adding 8/16 sprite directions is a possible transitional improvement, but grows atlas memory and still has angle changes.

## Chosen route: Godot 3D presentation with the C++ core

Continue the approved Godot 4 migration around the existing simulation. The route comparison below is design background; the user has already chosen Godot. Godot supports C++ shared-library integration through GDExtension and glTF/GLB scene imports; it provides a scene editor, camera, depth rendering, materials and animation tooling. The embedded GDExtension now runs the C++ board directly; the loopback pilot remains an explicit regression reference. Reusing the GPLv3 core retains its license obligations. [GDExtension](https://docs.godotengine.org/en/stable/engine_details/engine_api/gdextension/what_is_gdextension.html), [3D import formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)

| Route | Work and tradeoff | Choose when |
| --- | --- | --- |
| Extend SDL2 sprite renderer | Keep remastered atlases, improve batching/animation/zoom, add authored directional views. Lowest disruption; cannot expose arbitrary sides of flat sprites. | Shipping the existing visual style and original-content replacement is the near-term goal. |
| Godot presentation + C++ core | Extract simulation dependency boundary, add GDExtension bridge, port presentation/UI incrementally and export assets. Gains mature 3D tooling; core/UI coupling and large-city performance need proof. | Free camera orbit and editable 3D scenes are central to the product. Chosen route; migration is underway. |
| Custom SDL3 GPU renderer | Port platform layer, implement mesh import, shaders/PBR, depth buffers, batching, skinning, terrain/water, tools and UI integration. SDL3 GPU supports Metal/Vulkan/D3D12; upgrading SDL alone creates none of these systems. | Maintaining a custom C++ renderer is a deliberate long-term investment backed by graphics expertise. [SDL GPU](https://wiki.libsdl.org/SDL3/CategoryGPU) |

The initial pilot used a 32×32 presentation crop. Current presentation covers the full designated saved map (25,992 native tiles) with 240 development GLBs; this development content is not an original cleared commercial scenario. The next performance gate is a stress scene with at least 10,000 visible static instances and 1,000 active walkers, or the measured worst case in the supported maps if larger. Measure on the minimum target Apple Silicon device. Proposed gate: sustained 60 FPS at 1080p in the representative city, 95th-percentile presentation frame time below 16.7 ms, and no accumulation of overdue 50 ms simulation steps. These are targets, not measured results or promises for every map.

Use visibility culling, chunked terrain, instancing for repeated objects, mesh/animation LOD and a bounded shadow budget. Record CPU simulation, render preparation, GPU frame time and peak RAM/VRAM separately. Existing paint timers exclude presentation waits and are not full GPU profiling.

## Simulation/presentation contract and remaining cleanup

World state remains in fixed coordinates `(tile_x, tile_y, height)`, independent of yaw. The target contract gives a building a durable entity ID, content ID, origin tile, footprint and orientation. Current snapshots use session IDs; new square-building facing is presentation metadata and is not serialized yet. Walkers retain route, state and world position. The presentation consumes immutable snapshots; UI emits commands such as `PlaceBuilding`, `Demolish`, `SetSpeed` or `SetPaused` for the next simulation tick.

The embedded service already owns the existing campaign/board without a native window or renderer. Continue extracting remaining UI-linked serialization/formatting and unused widget dependencies; audit rendering/audio dependencies before declaring the linked library fully independent. Keep the current native engine as the reference during the pilot. Do not run two authoritative simulations or replace gameplay pathfinding with engine physics/navigation merely to render meshes.

Terrain snapshots now append read-only native elevation/walkability/foundation
classification and character height after the original six tile columns. Godot
uses them for continuous slope/cliff meshes, presentation picking and walker foot
projection. Buildings keep native foundation heights; native routes, eligibility,
simulation heights and costs remain authoritative. See `GODOT_TERRAIN.md` for the
geometry contract, conservative legacy bridge behavior and campaign coverage limits.

Interpolate walker display positions between the last two snapshots at their observed delivery interval (currently up to 10 Hz). The underlying simulation still uses 50 ms ticks. Keep production, tax, pathfinding and event timers at 20 ticks/sec. Preserve the physician benchmark's distance-driven 24-frame gait and breathing idle when translating it to animation clips. Separate camera/UI timing from simulation pause. Saving is a simulation operation; camera/view state is independently versioned.

## Continuous Q/E orbit contract for the pilot

The current `Camera3D` uses perspective with a 48-degree field of view and a 49-degree starting pitch. R/F and middle drag tilt between 25 and 75 degrees; Q/E continuously orbit the selected world focal point. An orthographic tactical mode remains optional. Preserve the world coordinate conventions in the adapter: Blender is Z-up; the imported scene/Godot world is Y-up. Validate exactly one axis conversion; never rotate data to compensate for a double conversion. [Camera3D](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)

Per display frame, compute `axis = held_E - held_Q` and `yaw = wrap(yaw + axis * angular_speed * dt, 0, 2*pi)`. The implemented angular speed is 65 degrees/sec; tilt is 35 degrees/sec. Holding both keys gives zero rotation. Acceleration/damping is optional and reduced-motion settings can use four snapped headings. Support a short tap to snap to the next 90-degree view if desired; do not combine a tap step and held rotation unintentionally. Define and test left/right signs visually, because coordinate conventions can invert apparent direction.

Pause orbit while typing or rebinding and when a modal dialog owns input; clear held-state on focus loss. Rotate around the focal point without moving buildings, walkers or roads. Screen-relative WASD pans along the camera's projected right/forward axes. Zoom preserves the cursor's world point by unprojecting a ray and moving the pivot after adjusting camera size. Clamp the focal point and zoom to useful map bounds.

For construction, cast a camera ray to the terrain, convert the hit to a world-grid tile, then apply existing footprint and elevation rules. In Godot, T changes object orientation `(orientation + 1) % 4`; Q/E change camera yaw and R/F change camera tilt. Native SDL uses R for placement rotation. A non-square footprint swaps width/depth on odd object orientations regardless of camera direction. Render its validity grid in world space; do not rotate footprint validation with the screen. Placement, demolition and selection use native tile coordinates, independent of camera yaw. Permanent stable entity IDs and overlay coverage remain migration work; current snapshot IDs are session-only.

Tests must cover 0/90/180/270 and intermediate yaw (e.g. 15/45/135 degrees), slopes/edges, tall buildings hiding smaller objects, rectangular footprints, independent T placement orientation (native SDL uses R), zoom/pan combinations, focus loss and typing, save/load, both languages and HiDPI. World state must be identical before/after a camera-only revolution. Protect existing saves with migration fixtures and recovery copies.

## Blender-to-runtime asset contract

The user has made Blender available at `127.0.0.1:9876`; check its current scene before any live interaction and preserve it. The earlier art inventory found 109 `.blend` files, so existing source geometry can often be adapted, subject to provenance review. Runtime exports use background Blender and do not require the live service.

Use `.blend` as authoring source and reproducibly export glTF 2.0/GLB with an approved pinned Blender version. Runtime users must not need Blender or the localhost service. Process saved scenes in a separate background Blender process, preserving the interactive scene. Exclude atlas preview cameras, render planes, lights and reference sheets from the runtime mesh export unless explicitly part of an asset.

For each approved asset, retain:

- Stable content ID, creator/rights record, source scene revision and source-input records.
- One documented world scale (start with one Blender unit per tile), ground pivot, footprint and gameplay origin. Sprite anchor offsets differ from mesh ground origins; sanctuary/stadium modules require explicit connector transforms.
- Exportable UVs and baked PBR materials/textures. Procedural Blender shaders, lighting baked into sprites and compositor effects do not automatically become runtime materials.
- Mesh LODs, draw-call/triangle/material budgets and simplified picking geometry. Keep gameplay collision/placement on the tile grid unless a deliberate rules change is made.
- Rig, clip names, duration, root-motion policy and animation bounds. For the hospital, `hospital_reference.blend` is a posed scene; its Python `animate()` function is the motion source, not a fully baked timeline. Bake actual keyframes/clips before export. The same check applies to procedural walker builds.
- Content validation of finite transforms, bounds, axes, missing textures, skin weights and clips, plus production hashes and attribution.

Preserve the bright hospital/landmark/sanctuary benchmarks, modular joins, independent tree assets, individual walker identities and calm water. Reuse height/normal/roughness data where its sources are approved, while replacing legacy-derived shoreline shapes. Existing terrain's light and water blending are mostly sprite effects; a mesh renderer needs an independently validated material/shoreline implementation.

Implemented exports: 240 development GLBs, with geometry for every rendered building and initial walker in the designated city. Native ownership/livestock records do not draw duplicate geometry. See `GODOT_ASSET_COVERAGE.md` for scope and remaining state/campaign gaps. The full 25,992-tile designated city is presented by Godot with embedded C++ simulation. Exact nine-tool construction queries/ghosts, live storage orders/limits, production input/output and native city-wide industry controls, demolition and undo are implemented. Numeric-field focus suppresses camera keys; weak object tokens reject stale inspector actions. Skeletal/work clips, full procedural material baking, remaining core dependency cleanup and complete game UI remain migration work. See `GODOT_MIGRATION.md` for acceptance gates.

## Native validation added here

`tests/camera_controls_smoke.cpp` checks defaults, legacy migration, custom-key collisions, persistence of unbound/custom camera keys, cyclic directions and repeat-state dispatch in a disposable settings directory. It refuses to overwrite existing settings.

`EZEUS_TEST_CAMERA=1` with the existing screenshot harness exercises actual camera key dispatch, four views both ways, full-turn focus, repeat/modifier suppression, R independence and unchanged simulation/building layout. Run only on `Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`. `EZEUS_SHOT_CONTROLS=1` captures the controls panel over that city. Screenshot mode already disables player saves/settings writes. After every build, copy the binary to `Bin/eZeus` and ad-hoc sign it per project rules.

From `eZeus/`, run `python3 tools/validate_camera_controls.py` for the disposable settings regression, or add `--in-game --output <capture-directory>` for the native camera/layout checks. The latter needs access to macOS display services, uses the designated save, checks its hash and the player's settings hash before/after, and retains a JSON result plus captures/logs. Current coverage is the standard and magnified zooms at a central view; map-boundary clamping and the 50% overview need separate acceptance checks in the renderer pilot. Existing missing legacy-resource/voice warnings and text-render warnings during shutdown are visible in logs; these are not content-clearance passes.
