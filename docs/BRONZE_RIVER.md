# Bronze River — 9 October 2026

**Normal-menu continuation:** use Launch Godot 3D.command → New game → Bronze
River. Both current campaigns now share the regular browser and campaign-aware
Continue/Load, with separate autosaves and prior-profile discovery. The dedicated
launcher below remains supported. See [menu/save continuity](GODOT_CAMPAIGN_LIBRARY.md).

Double-click **Play Bronze River.command**, then **New game → Bronze River →
Start → Begin**. This is a separate private development campaign/profile. First
Light's launchers, exported campaigns and player files remain intact.

The retained parent terrain comes from **Armory**, by **Nightwolf / David Masters**:
https://zeus.heavengames.com/downloads/showfile.php?fileid=653. Its untouched archive,
author notes and hashes remain in the private research collection. The new writing,
goals, trading settings and progression are authored for this project. Retained
terrain/world and compatibility resources remain adaptations with unresolved
commercial permissions; `ships_in_release=false` is retained.

## Chapters

| Chapter | Objectives | Buildings added |
| --- | --- | --- |
| A Town Before a Forge | 240 residents; annual wheat 24; annual timber 16 | Housing, water, maintenance, food/markets, stores, timber and trade |
| Ore, Hands and Hearths | 480 residents; 64 people in Homestead or better; annual bronze 16; annual armor 12; one operating export route | Foundries, armories, library science, imported fleece stalls, health and gardens |
| The River Covenant | 700 residents; annual armor 16; annual net profit 1,500; set aside 16 armor; remain at least six months | Palace/tax offices, oil stall, observatory and optional walls/gates/towers |

Three parent episodes retain the same city, treasury and buildings. Each has a
complete native permission set and distinct English/Russian briefing and ending.
There are no colony handoffs. The set-aside goal funds a planned downstream colony;
it is an explicit reserve action, not an automatic next-city transition.

Willow Quay buys up to 48 timber and 48 armor per year and sells up to 32 fleece
and 24 oil. It uses the source world's land route. This valley has forest and
copper but no local fleece chain; imports support housing. Foundries/armories
across the river need a bridge connected to both road networks, maintenance and
warehouse bays reserved for industrial goods. Positive export/import stock limits
and native staff/road access are required. The briefing explains those choices.

In the final chapter, the native Poseidon event closes trade after three months
for 60 days, then restores it. Food/clothing stocks buffer the interruption.
The relative six-month/two-day waiting goal prevents finishing before recovery.
Temporarily stopping armor exports lets the player accumulate the 16-item reserve;
the objective's **Set aside** button commits it. Taxes require a palace. All
production, deliveries, prices, staffing, dates and costs use existing native rules.

## Authoring and isolation

Recipe: `content/scenarios/bronze_river_chapters.json`, version 1. The reusable
`tools/create_first_scenario.py --plan <recipe>` supports inspected source copies,
fresh exports, review/playthrough and isolated play profiles. Its First Light
defaults and Previous launcher remain supported. The wrapper verifies source
hashes, campaign output hashes and untouched First Light files. Failed/repeated
natural runs are retained in separately named report folders.

Native imported map: 25,992 tiles; 228×227 bounds; 1,573 meadow, 4,841 forest,
2,925 water and 190 copper tiles, plus 214 pre-existing road cells. No parent terrain,
coordinates, native RNG/timing or art/UV/LOD is rewritten. Source episodes/colonies,
writing, narration references and trading settings are replaced in the private
export; unused world towns are hidden and their trade/tribute lists cleared.

`build-content-research/bronze-river/current.json` selects the fresh export.
Player files use `build-content-research/bronze-river/play/chapters/`; test profiles
and snapshots are separate. The normal installed adventure catalog is retained.
No original archive, live game, Blender document or personal save is modified.

## Verification

- Native authoring: **9** checks. Source terrain is retained; three parent chapters
  export with their own permissions and objective lists.
- Sequential Metal reviews: **53 English / 53 Russian**. Native chapter goals,
  unlocks/refused locked placement, carryover, save/reload, trade closure/recovery,
  BC waiting date and ending pass. Real menu/Start/Begin shows the complete new
  briefing and opening Build menu. Structural victories are explicit test fixtures.
- All **2,925 water-tile bridge previews** survive the irregular map boundaries;
  **120 native-valid bridge sites** are found. This exposed missing end-neighbor
  checks in native bridge placement; invalid edge crossings now return false.
  Existing valid bridge rules, footprints and costs are retained.
- The final **ordinary-command playthrough naturally wins all three chapters**.
  No test commands or population/money/goods/victory injections are used. It builds
  a real eight-cell bridge connection, mines copper, supplies armories, imports
  fleece, sells armor, lives through the interruption and explicitly commits the
  reserve. Latest completions: 432 / 736 / 1,176 residents. Final objectives report
  annual armor 20 and net profit 2,390; final-year export income is 3,725.
- Direct native trade counters observe **16 armor sold in a year** and **32 fleece
  imported in a year**. 567 ordinary commands / 2,660 service calls advance 792,900
  native units, about **27.5 unpaused minutes at the slowest standard speed**.
  This is automated simulation evidence; the 45–90-minute human target is untested.
- First Light's retained chapter review, editor **64**, embedded **101**, fresh
  launcher bootstrap and protected input/campaign hashes pass. Mac extension and
  reference binary are signed/installed on fresh inodes. Windows x64 bridge fix
  compiles and all six DLL imports resolve statically; it is not Windows execution.

Reports/captures are under the current manifest's `report` directory, especially
`review-en-visible/`, `review-ru-visible/`, `natural-playthrough/result.json` and
`trade-proof.json`. Earlier stalls exposed disconnected delivery roads, unmaintained
remote industry and exports draining the reserve; the final natural pass is the
acceptance evidence. The final annual armor target was tuned from 24 to 16 for a
shorter Mortal progression, retaining the reserve/profit/logistics challenge.

Actual newcomer pacing, user visual acceptance, Windows packaging/execution for
this campaign, minimum hardware and commercial clearance remain pending. The
existing Windows Chapters ZIP remains frozen and contains First Light, not Bronze
River. No shipping, publishing or Steam upload is authorized or performed.
