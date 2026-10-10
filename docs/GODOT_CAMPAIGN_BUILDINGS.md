# Campaign building permissions — 9 October 2026

**Later continuation:** the user selected staged progression. The active prototype
now has three chapters; the single-chapter version/profile is retained separately.
See `FIRST_LIGHT_CHAPTERS.md` for current content, natural playthrough and handoff.

Building availability follows the current **episode/chapter**, as authored by the
campaign. Completing one objective inside an episode does not itself unlock a
building. All objectives in that chapter share its allowed building set; the next
set applies at **Begin** for the next parent/colony episode. Native events may
separately grant buildings/heroes and still notify the catalog through its revision.

## Fixed authority and persistence

The Godot catalog already filtered the core's `buildable.available` values and
refreshed on episode entry/native eligibility changes. The missing coverage was
in `eAvailableBuildings`: industry/wonder permissions were preserved, while
`allow`/`disallow` for many ordinary services and civic buildings were discarded.
Original PAK ordinary flags now reach `supportsBuilding` as intended.

Explicit ordinary permissions use the existing serialized building-type keyed
availability records (`fPyramids`, with **empty levels** for ordinary buildings).
The binary layout/version stays unchanged; do not assume every key is a wonder.
An absent ordinary entry retains legacy unrestricted behavior. On episode start,
ordinary overrides are replaced exactly, while completed wonder states retain
their existing behavior. Industry flags and sanctuary perks remain native.
Both template and active-board records persist these permissions in `.epak`/`.ez`.
Older binaries read the records but ignore ordinary overrides; use the rebuilt core.

The editor now exposes ordinary services, markets, science/culture, civic, defence
and decoration permissions alongside industries. Native preview, single/area/path
construction and the SDL view use the same `supportsBuilding` authority. Source
culture picks Greek culture versus Atlantean science. Vendors need an allowed
market, and a pier cannot bypass a forbidden trade-building flag. Existing
buildings are retained when a later episode forbids new copies.

`main.gd` clears a selected placement tool if it leaves the refreshed catalog,
removing its ghost/path state. Normal catalog grouping/order is retained; no
presentation-only unlocks, additional eligibility polling or native RNG draws
were added.

## First Light Harbor opening

Recipe **version 3** supplies its complete `allowed_buildings` list. Housing,
roads, food chains, fountains/maintenance/health, common market/food/fleece/oil,
small science service, warehouses, trade and a few appeal tools are available.
Palace, university/large science, grand agora, elite housing, military/defence,
advanced industries, monuments and unrelated decor remain locked. Every tool
needed for the current seven objectives is retained.

The prototype remains **one chapter with seven objectives** pending the optional
chapter-layout choice. A three-chapter housing/food → clothing/science → trade
design was offered; no answer was assumed and the current layout is preserved.

Relaunch and start a **new game** for the revised recipe. Existing saves retain
their stored campaign/permission definitions, and the running process retains
its mapped library. No player save was migrated or overwritten.

## Evidence

- Native two-episode fixture: **37 EN / 37 RU**. Ordinary/industry locks, culture,
  market/pier dependencies, menu filtering, preview/build refusal, `.epak` export,
  save/reload, next-episode unlock/re-lock and subsequent reload pass.
- Actual prototype menu/briefing/Begin and retained scenario checks: **34 EN /
  34 RU** Metal, including opening prerequisites and unrelated-building locks.
- Retained building checks **505**, campaign flow **26**, editor **64** and
  embedded simulation **101** pass. Both C++ targets rebuild and are signed/
  installed on new inodes. Player files/live game/Blender and original inputs remain.

Private reports are reached from `first-light-harbor/current.json` (`episode-unlocks-*`
and `review-*-visible`); broad retained logs live in `build-content-research/`.
Fixture victories are explicit validators, not natural player progress. Natural
balance/pacing, a full playthrough, minimum devices/Windows and commercial rights
remain pending. The frozen Windows kit has not been rebuilt for these fixes.
