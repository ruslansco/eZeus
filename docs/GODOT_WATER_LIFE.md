# Fishing spots and authored collection — 4 October 2026

Native `hasFish()` and `hasUrchin()` are appended as tile column 9 (bits 1/2)
in full and changed observations. The other nine columns keep their meaning.
The mask participates in the existing terrain cache; no extra tile scan,
resource mutation, native random draw or save-format change is introduced.
The native collector targets these flags even while resource quantity regrows;
markers follow the same flags, rather than inventing depletion rules.

`water_life.gd` creates procedural fish schools, stationary spiny urchin clusters
and subdued surface movement, only on native water. Roads/decks and occupied
foundations suppress markers. It rebuilds affected 32-tile sections, uses shared
materials, reduced mesh LODs and distance culling. The opaque sea requires
wildlife to sit at its surface with an aquatic tint; this is a readable deposit
presentation, not an underwater/refraction renderer.

`gathering_motion.gd` connects native action 7 (`collect`) to 40 authored samples
on both collecting roles. The fishing skiff's seated worker gathers a bunched
net, casts, lets its skirt settle, hauls hand over hand and stows it. The net line
follows solved hand positions; rowing oars are hidden during collection. The
urchin worker dives/reaches, recovers with the bag and returns upright. Native
action 14 (`carry`) selects 12 bag-carry samples; action 22 (`deposit`) selects
12 bag-emptying samples. Travel/standing/death retain ordinary walker motion.
The boat hull and worker root never receive the former procedural body tilt.

The collect loop lasts five presentation seconds. The Godot-only
`tools/godot_gathering_art.py` adapter retimes the existing authored dive into a
short submerged dip and longer visible recovery. It leaves source/native art
and simulation collection timing untouched. Carry phase follows the existing
0.64-tile travel stride. Entry/exit and work-state transitions use 0.22 gameplay
seconds; work-state transitions begin at the previous work pose. Both VAT and
blend-shape fallback use the same two normalized pose pairs. No root motion or
native travel-phase edits are introduced.

Small broken surface glints follow work phase. The diver releases three tiny
bubbles only during the submerged reach; there is no separate floating mesh net
or diagram ring for workers. Surface effects cap at 128 workers/384 bubbles.
Effects and authored motion use total gameplay time divided by 30 with the same
100 ms interpolation convention as building activity. Paused and blocked
snapshots hold all wildlife, work motion and transition weights. No physics,
navigation, production logic, decisions or new sounds are added.

Reproducible asset sources are `tools/godot_fishing_boat.py`,
`art/characters/people/people2.py:urchin_gatherer` in the parent art workspace,
and the Godot-only timing adapter. `tools/export_godot_pilot.py` samples the clips,
excludes the diver's legacy torus ripples and records `authored_gather_v2` in both
asset manifests. Export only these two models through background Blender into
a staging directory; never alter the live Blender scene. Optimize with
`tools/optimize_glb_memory.py`, verify with `tools/verify_glb_optimization.py
--require-uv`, install source GLBs/manifests, bake both with
`tools/bake_walker_vat.py`, and import. Keep UV/UV2, palette finishes, original
sources and source hashes. `validate_poses.gd` checks runtime/source equivalence;
`validate_geometry.gd` gates imported geometry and LOD growth.

Development provenance is recorded in `godot/data/water_life_art.json` and the
individual asset manifests. Rights status remains `needs_evidence`; these changes
do not establish production asset clearance. Underwater optics, wider campaign
review, user visual acceptance and minimum-Mac profiling remain pending.

Run `validate_water_life.gd` and `validate_gathering_motion.gd` headlessly with
explicit writable logs. Run `python3 tools/review_water_life.py --lang en
--record` (or `ru`) sequentially using the designated city and scratch
preferences. Recording produces MP4 when ffmpeg is available, otherwise GIF
when Pillow is available. The designated city has four native fish deposits and
no native urchins, so the urchin view adds bit 2 only to a copied presentation
tile on existing water. Both collecting workers are render-only fixtures at
resource tiles; the core/save and live roles remain intact. These captures prove
presentation, not an end-to-end native collector journey.
