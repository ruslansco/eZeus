# First Light Harbor: three chapters — 9 October 2026

**Normal-menu continuation:** Launch Godot 3D.command → New game → First Light
Harbor now supports this campaign alongside Bronze River, with chapter previews,
separate autosaves and prior-profile Continue/Load. The launchers below remain
supported. See [menu/save continuity](GODOT_CAMPAIGN_LIBRARY.md).

Use **Play First Light Harbor.command** and start a new game. The native content
identity is `First Light Harbor Chapters`; the displayed title remains First Light
Harbor. New saves/settings use `build-content-research/first-light-harbor/play/chapters/`.
**Continue Previous First Light Harbor.command** uses the preserved single-chapter
manifest and original prototype profile. Neither prior saves nor their campaign
files are migrated or overwritten.

## Progression

| Chapter | Goals | Main additions |
| --- | --- | --- |
| A Shore Worth Staying On | 160 residents; 64 people in Shack or better; annual wheat 16 | Housing, roads, fountains, maintenance, food production/granary/common market |
| Homes for the Winter | 400 residents; 64 people in Homestead or better; annual fleece 8 | Storehouse, sheep/carding, fleece vendor, bibliotheke, health and small gardens |
| The Harbor Keeps Its Word | Annual timber 16; one operating export route; annual profit 500; annual wheat 24; six-month settling period | Timber mills, trade, palace/tax offices, observatory, oil vendor |

All three are parent episodes on the same retained Alexandria terrain. Buildings,
population, treasury and native economy carry forward. Each episode authors the
complete building set; there are no colony handoffs or per-objective UI unlocks.
Both languages have distinct introductions/completion prose for every chapter.

Poseidon closes Reedhaven trade three months into the final chapter for 90 days;
the native consequence restores it. The final native waiting goal prevents an
early finish before recovery. There is no defeat deadline or automatic decision.
Trade orders need positive storage limits: enabling export with a zero limit does
not fetch goods. The new opt-in route goal checks this alongside staffing/road/
native trade permissions. Original diplomatic-count goals remain unchanged.

Playthrough feedback refined the briefing: flower gardens belong close to homes,
stores/workshops farther away; timber mills need forest nearby; tax collectors
need a palace; exports need an enabled order and a positive stock target (example
32 timber). These are explanations of existing rules, not changed production costs.

## Implementation and compatibility

Recipe: `content/scenarios/first_light_harbor_chapters.json`, version 4. The old
single-chapter recipe is retained. The authoring tool makes three explicit native
episodes, checks source hashes, and exports a fresh private campaign. `current.json`
points to the new build; `single-chapter.json` retains the prior build. Bootstrap
uses the chosen manifest/resource root and the matching profile directory.

Date goals store a calendar year in `fRequiredCount`. Their old generic quantity
comparison made negative BC years look complete while the native date status was
still false. `eEpisodeGoal::met()` now reads the boolean status for survive/deadline
goals; quantities keep their original comparison. Briefing previews initialize a
copied relative date goal, preserving the actual template. The binary save layout,
RNG, economy, pathfinding, speed semantics and art/UV/LOD are retained.

Older binaries ignore ordinary permission/working-route modifiers and mishandle
BC date completion. Use the rebuilt native core. This remains private adaptation
content with author evidence/attribution, excluded from commercial shipping.

## Verification

- Authoring: **9** checks. Three chapter definitions export on unchanged parent
  terrain with no colonies; prior sources/archives remain intact.
- Final visible EN/RU: **38 each**. Three distinct briefings/goals, phased building
  sets, native preview/catalog behavior, city footprint carryover, checkpoints,
  save/reload, future date refusal, real shutdown/recovery/calendar completion and
  real menu/Begin checks pass. Structural victories use explicit test fixtures.
- A separate **ordinary-command playthrough completes all three chapters** without
  enabling test commands or injecting population, goods, money or victories.
  It constructs its settlement, obtains native staffing/food/fleece/science/appeal,
  enables timber exports with stock capacity and collects taxes after a palace.
  Final recorded year: **1,650 export income and 1,046 net profit**; all final goals
  are met. 241 ordinary commands and 2,660 maximum-speed service calls are recorded.
- That run advances **792,900 native time units**, roughly six simulation years.
  At the slowest standard rate (24 units × 20 Hz), this is about **27.5 minutes of
  unpaused simulation**, excluding player planning/reading. 30–60 minutes remains
  a human playtest target, not measured player time. Other speeds shorten it.
- Retained two-episode locks: **37 EN/RU**; editor **64**, embedded **101**. Scope
  reports distinguish fixture checks from natural economy progression.

Private current-manifest reports include `natural-playthrough/result.json`, its
settlement snapshot/checkpoints, and `review-*-visible/`. Early natural runs exposed
appeal/supply/stock/tax problems; only the final natural pass is acceptance evidence.
Native Mac/reference targets are signed and installed on new inodes; live game,
Blender and player source files remain protected. Windows launch/graphics/minimum
machines and newcomer playtesting remain acceptance work.

## Updated Windows handoff

`dist-private/CityBuilder-Windows-Chapters-2026-10-09.zip` bundles the updated x64
core, official Godot 4.6.3, prepared runtime assets, the explicit new campaign and
required source/license/author notices. It preserves Balanced/High quality and
excludes research archives, reference pages, prototype/player saves and preferences.
Six DLLs pass static import closure; the package manifest/hashes pass. The prior
Windows kit remains intact. On the Dell: extract, run **Run checks.cmd**, then
**Play.cmd → New game → First Light Harbor**; return **Dell-test-results.zip**.
Compilation/static audits are not Windows execution or Steam readiness evidence.
