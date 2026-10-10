# Olympian marble defences

The 6 October 2026 wall/tower/gatehouse pass completes the interrupted
`tools/godot_defences.py` builder. Godot exports use that source directly through
`tools/export_godot_pilot.py` and `tools/godot_asset_sources.py`. Parent
`art/walls/`, `art/tower/`, `art/gate_tower/`, their sprite atlases and live Blender
scenes stay unchanged. The older `tools/godot_gatehouse.py` remains a legacy source.

## Design and scale

The design follows the user's white marble/Olympian brief and supplied city
screenshot, retaining the earlier session's Greek meander motif. The specific
3D propylon, relief leaves, podiums and geometry are procedural adaptations;
the current pass does not claim a verified pixel-exact original-game replica.
Original-game screenshot search was background reference only. Provenance stays
`needs_evidence`; neither procedural generation nor a new filename clears release
rights. No external image or original sprite texture is embedded in the models.

| Piece | Installed design | Height in tiles |
| --- | --- | --- |
| All 16 wall masks | White marble courses, 0.58-wide curtain, consistent walk height, wider corner piers, broad battlements, blue/red meander | Walk 2.0; merlon crowns about 2.24 |
| Native 2×2 tower | 1.72-wide shaft, battered 1.92-wide foot, engaged corner pilasters, arrow recesses, matching cornice/meander | Platform 3.05; crowns 3.32 |
| Native 5×2 / 2×5 gate | Two marble pylons, paired fluted Ionic columns, carved laurel panels, three pediments, restrained gilding, open bronze doors | Pylon ornaments 3.64; portal ornaments 3.12 |

Walls previously used a 0.8-tile native lift and towers 2.57. Those read-only
native observations remain intact. The first marble pass used a 1.45-tile walk;
the user's follow-up raises it to 2.0 (37.9% higher), with unchanged widths and
ornament proportions. Shared contract revision 3 records this adjustment. The
tower/gate GLBs stay byte-identical; their manifests refresh the shared contract
metadata only. The sixteen wall geometry baseline entries alone may be updated.
Portal
columns at ±0.64 leave at least the one-tile native passage free; the GLB contains
no ground slab in that lane. Real city roads remain native terrain. Review-only
paving makes the gallery passage readable and is not installed in the model.

`godot/data/defence_art.json` is the shared authoring/runtime roof contract.
Do not duplicate its heights in native gameplay or sprite offsets. `main.gd`
rebuilds `DefencePerch`'s small cell index only when its existing building refresh
runs. A positive native `lift` and a matching footprint activate the projection.
Ground soldiers sharing an archer asset retain their original ground behavior.

The render projection keeps tower roots within ±0.58 tiles of their platform
center, leaving margin for the feet and battlements. Walls project transverse
drift to 0.15 around the center/connected arms, including corners and branches.
Position/altitude follows the owning building's foundation, rather than terrain
under a decorative overhang. `walker_streets.gd` clears the lane immediately for
perched walkers. Routes, native interpolation track, locomotion phase, combat,
selection IDs and saves remain native; there is no per-frame tile/building scan.

## Export and validation

Use background Blender only, one named asset per export:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 -P tools/export_godot_pilot.py -- --asset gatehouse
# Likewise tower and wall_0 through wall_15.
./tools/reimport_models.sh gatehouse tower wall_0 wall_1 wall_2 wall_3 wall_4 wall_5 wall_6 wall_7 wall_8 wall_9 wall_10 wall_11 wall_12 wall_13 wall_14 wall_15
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://scripts/validate_defences.gd
python3 tools/review_defences.py
```

Authored point caps are 2,500 per wall, 6,000 tower and 16,000 gatehouse. Imported
caps account for normal/UV splits: 6,000 vertices/triangles per wall, 10,000 for
tower, 34,000 vertices / 25,000 triangles for gatehouse. Final imports use
1,020–1,836 triangles per wall, 4,440 tower and 16,012 gatehouse. Lowest LODs
retain 84–104, 408 and 662 triangles respectively. Walls/tower share one finish;
gatehouse uses three (stone and gilding). Authored UVs and vertex palettes are
retained. Full marble vein/normal baking is pending.

The exporter formerly excluded the arrow-recess batch because its material name
contained `shadow`. The new material is `Arrow recess`, so the slit geometry is
included. Preserve that detail during re-export.

Preserve imported LOD generation and existing silhouette guards; audit named
assets with `audit_lod_coverage.gd`. Merge measured `tris`/`verts` from
`godot/captures/defence-runtime.json` into **only** these eighteen baseline entries.
Never replace the whole baseline to approve this art change.

Focused validation checks all masks, cache removal, roof/ground discrimination,
extreme guard positions, manifests, UVs, surface/geometry budgets and reduced LODs.
The visible review is isolated, uses disposable preferences, freezes the native
city, and exercises actual `update_walkers` / `_process` with a render-only guard
fixture across 120 moving samples. The native wall regression separately verifies
staffed tower archers, construction, connections, both gate facings, undo,
demolition and disposable save/load. Review does not overwrite the player's city
or restart any existing game/Blender session. See current validation for evidence.

User acceptance, minimum-Mac profiling, extended elevated-wall/tower transitions,
complete procedural material baking and release-rights evidence remain pending.
