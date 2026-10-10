# First Light Harbor — private scenario prototype, 8 October 2026

**Three-chapter continuation:** use `FIRST_LIGHT_CHAPTERS.md` for the active campaign.
This page records the earlier single-chapter prototype, still available through
**Continue Previous First Light Harbor.command** with its original save profile.

**9 October update:** recipe version 3 now supplies the complete opening building
set, including native limits for ordinary services/civic structures. Its one
chapter/seven goals remain. New games hide unrelated advanced/military choices;
older saves keep their stored definitions. Current visible EN/RU checks pass 34
each, with two-episode unlock/save checks 37 each. See `GODOT_CAMPAIGN_BUILDINGS.md`.

Double-click `../Play First Light Harbor.command`, choose/create a leader in its
separate roster, then **New game → First Light Harbor → Start → Begin**. The menu
can switch English/Russian. Saves/settings stay under
`build-content-research/first-light-harbor/play/`. This launcher requires the
current Mac workspace/runtime; it is not a standalone or Steam package.

## Playable content

LVLarry's Alexandria parent terrain and prepared roads are retained: 25,992 native
tiles, 228×227 bounds, 3,048 meadow, 6,229 forest and 5,245 water cells. Native
wildlife affects the exact count of free sites when play begins. A deterministic
initial camera view at native (127, -34) shows usable land near meadow/timber;
terrain, entry points and simulation coordinates are unchanged.

One new episode, **A Shore Worth Staying On**, has newly drafted English/Russian
campaign and episode briefings/closing prose. The opening is 18,000 at Mortal
difficulty, with food/fleece/timber industries and the native basic services.
Minting is omitted because this parent map has no silver. Seven objectives require:

1. 400 residents.
2. 64 people in Homestead or better (common-house level 3).
3. Annual wheat production of 24.
4. Annual timber production of 16.
5. One staffed export route connected to roads.
6. Annual fleece production of 8.
7. Annual profit of 500.

**Reedhaven** buys timber/wheat and offers fleece/olive oil. Only it and the parent
city are visible/active. Other inherited world-city records are renamed,
hidden/inactive and their trade/tribute offers cleared. World geography/route
inputs remain adaptations. A native Poseidon disaster closes Reedhaven trade
after six months for 90 days; its native consequence reopens trade without an
invented answer/payment/battle. Local production supports recovery. There is no
defeat deadline or colony handoff. The existing settlement guide opens on Begin.

30–60 minutes is a design target, not measured playtime. Complete natural
progression, economic balance, newcomer clarity and user acceptance remain pending.
Native world-city names are stored as First Light/Reedhaven; campaign prose and
goal wording are localized. Map expansion/art direction can follow playtesting.

## Authoring and compatibility

`content/scenarios/first_light_harbor.json` is the version-2 recipe.
`tools/create_first_scenario.py --build` checks the reviewed PAK hash, creates a
fresh private compatibility root, opens the copied source through the native editor
and exports a new `.epak`, translated text and attribution. It never overwrites an
existing build or runs downloaded programs. Private `current.json` selects the
build used by the launcher; older build folders are evidence, not live saves.

`editor_single_parent <name>` explicitly resets campaign identity/episode content,
retains the parent board/world, drops colony boards and refuses unsafe/existing
names. `editor_difficulty 0..4` stores difficulty. Both are refused outside editing.
Actual-size colony iteration supports zero-colony campaigns. Source narration IDs
are cleared. No economy, production, pathfinding, RNG, art/UV/LOD or tick change is
made to existing gameplay.

The original trading-partners objective counts diplomatic availability, so it was
met without a post. This recipe opts into `working_route=1`, stored in the existing
trading-partner goal's `fEnumInt2`. It counts distinct partners served by a player's
post with employees, road access, an enabled export, no shutdown/fire and native
trade permission. Original PAK goals leave the field zero and retain their count.
Goal/status/checkbox wording lives in the shared native EN/RU text tables. Saved
layout and enum values are unchanged, but older binaries ignore the modifier:
use the rebuilt engine. The frozen Windows transfer kit is not updated here.

The bootstrap supplies an explicit `ezeus_engine_directory` and one-shot camera
focus. Menu/city/immutable save preflight honor that local root; ordinary sessions
retain the default. Saved camera values take priority over the initial focus.

## Verification and source evidence

- Authoring: **7** checks for isolated source/import, naming, single parent/no
  colonies, retained terrain, partner selection and authored objectives.
- Final visible EN/RU: **32 each** through the actual menu, briefing and Begin
  into 3D. Native-valid construction sites, premature trade-goal refusal,
  save/preflight/reload and real shutdown/reopening pass.
- Retained editor: **64**; embedded simulation: **101**. Both C++ targets rebuild;
  Mac extension and native reference are signed/installed on new inodes.
- The exact bootstrap also opens/exits cleanly with a fresh empty roster and
  creates its private save folder before the menu lists saves.
- Protected designated-save/player settings hashes and all six original archives
  remain intact. No live game or Blender process is stopped.

Reports/captures use the `report` path in private `current.json`. The ending check
uses the existing validator-only victory fixture: it proves the single-episode
handoff, not natural completion. Positive staffed-export progression, balance,
minimum hardware and long sessions still need acceptance.

Source: **LVLarry**, [Alexandria](https://zeus.heavengames.com/downloads/showfile.php?fileid=532).
Original hashes are in `custom-adventures.provenance.json`; derived inputs/files
are in `first-light-harbor.provenance.json` and the private manifest. The invitation
to edit is retained. Commercial permission and underlying content review remain
unresolved; this adaptation/compatibility content is excluded from release packaging.
