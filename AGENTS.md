# eZeus / Godot 3D development instructions

## Menu frame hierarchy and one briefing route — 10 October 2026

Keep the user's approved ornate walnut/bronze/ivory frame on full menu pages:
landing, adventures, load, profiles, Settings hub, Extras and story. Detailed
settings forms and compact confirmations use the quieter bronze/slate frame.
The common palette, serif headings, predictable Back/Escape and padded text give
these roles one coherent theme; never put dense form labels on carved borders.
`settings_shell.install_frame` shares the compact native-window art; `menu_skin`
keeps decorative large menu choices, clear `MenuPageChoice` secondary navigation
and `MenuPagePrimary` compact footer actions. City Theme and all native callbacks
remain unchanged.

The duplicate Read chapter briefing button/hidden preview-story controls have
been removed. Catalog chapter previews still show native titles and objectives;
Start opens the normal complete story, difficulty and goals before Begin. Do not
turn a chapter preview into a chapter-skipping command. Full prose remains paged
on parchment only on the story screen. The older `menu_text_reader.gd` is retained
historical source and is not linked from normal navigation. Run sequential owned
EN/RU menu/adventure reviews and the scoped native campaign-library `--menu-only`
review; current validation distinguishes these from broader city checks.

## Tidebound Covenant fifth campaign — 10 October 2026

Read `docs/TIDEBOUND_COVENANT.md` and its provenance. Recipe
`tidebound_covenant_chapters.json` v1 adapts Nightwolf / David Masters's Tributaries
3 parent terrain/world into three new EN/RU local-food, fleece/science/housing and
timber-supply chapters. Keep the source map's native heights, roads and wildlife.
The stone terrain is ordinary rock; do not invent mineral deposits. The city is
Atlantean, with native science services. No imports, exports, trade buildings or
automatic tribute are authored. Two explicit Set aside goals provision a future
outpost; no playable colony handoff is added.

Preserve separate pasture, distinct grazing sites, real road connections and
dedicated timber bays in the ordinary review layout. Native animal placement can
stack sheep on one tile; decoration can replace livestock reservations. Ordinary
gameplay passes three chapters with 496 commands/2,410 service calls and both
reserves. Campaign EN/RU reviews pass 52 each; five-campaign menu/save reviews
pass 137 each; retained editor 64/embedded 101 pass. The installer owns five
verified private exports. Protect every earlier campaign/player profile and run
visible reviews sequentially with disposable preferences. Art capture uses a
hash-checked owned checkpoint copy, never a live player city.

Keep original archives/text/hashes, live game/Blender, C++ rules/RNG/20Hz/save
layout, art/UV/VAT/LODs and audio intact. This remains
needs_evidence/ships_in_release=false. Human pacing, user acceptance, platform
testing and retained-content commercial permission/replacement remain open;
frozen Windows kits exclude this campaign.

## Stable category slots and dock label — 10 October 2026

The HUD now retains all sixteen canonical category positions across maps and
chapters. `BuildCatalog.groups()` and cards still contain only native available
entries. Empty slots are disabled, use cached grayscale original SVGs and explain
unavailability in EN/RU hover help; catalog refresh enables them in place. Guard
`open_category`, close stale trays and skip disabled settlement-guide targets and
actions. Preserve unchanged-catalog control identity and native placement rules.

The center dock Label reserves translated font-measured width, cached on catalog,
language and text-size changes and capped by remaining main-row space. Do not
depend on an ellipsized Label's minimum size or let a sparse chapter collapse it.
Run sequential disposable `tools/review_toolbar.py --context --lang en` / `ru`
and retained toolbar reviews; sparse/empty/re-enabled catalogs are presentation
fixtures only. Keep clock/map columns, shortcuts, shared Theme and saved state.

## Portal follows the scenic doorway — 10 October 2026

The cinematic menu uses `aegean_portal_distance.png`, a lossless linear-data
distance mask derived from the original artwork's connected dark opening by
`tools/calibrate_menu_portal.py`. Preserve both packed distance channels and
disable 3D compression/mipmaps. Source-image bounds are `(1194,204,268,468)`;
keep the portal and plate on their shared cover/crop/drift transform. The mask
fits the perspective arch, projecting jamb stones and angled sill. The shader's
default analytic arch remains for older procedural scenes. Source artwork and
the historical Blender reference remain unchanged. Read current interface and
validation evidence; run owned sequential EN/RU main-menu reviews with scratch
profiles, preserving the live game and player files. Use `--tag portal-alignment`
for dedicated capture/log filenames when other chats are also reviewing menus.

## Greek settings submenus — 10 October 2026

`ui/settings_shell.gd` decorates the six existing start-menu settings dialogs
with a private Theme copy: original bronze/meander SVG frame, slate surfaces,
ivory text, aligned choices and readable small controls. It is installed only by
`menu_navigation.gd`; shared city Theme and dialog implementations stay intact.
The Settings hub/frame hides behind an input-blocking scenic shade until all
nested settings windows close, then restores the original category focus.

Preserve native drafts, Apply/Cancel, preview/revert deadlines, key capture,
sound/game persistence and Game's nested settings return. Use AcceptDialog's
`buttons_min_width` / `buttons_min_height` Theme constants for footer padding:
native layout overwrites individual footer custom minimums. Recompute from full
translated labels after Theme or confirmation-state changes. Keep small buttons
plain and inset from decorations; parchment remains story-only. The long key list
retains its bounded scroll area. Run sequential disposable EN/RU main-menu reviews;
current validation records coverage and captures.

## Sunlit Terraces fourth campaign — 10 October 2026

Read `docs/SUNLIT_TERRACES.md` and its provenance. Recipe
`sunlit_terraces_chapters.json` v1 adapts Genis's Everybody loves oranges parent
map/world into three new EN/RU orange, oil/housing and wine-reserve chapters.
Normal New game and the separate Play launcher retain native permissions,
same-city carry and campaign save slots. This source city is Greek: keep native
gymnasium/college/podium culture, not Atlantean science substitutions.

Raised fertile terraces and old disconnected road fragments remain. Connect
orchards to the town explicitly. Oranges require granaries/trading posts, not
ordinary warehouses; reserve orchard granaries against imported grain. Maintain
separate oil/wine bays and explicit native Set aside. No colony handoff is added.
Ordinary gameplay passes all chapters with 777 commands/4,100 calls, actual orange
sales/grain imports, oil/wine output and the committed reserve. Authoring 9,
visible EN/RU 52 each and retained editor 64/embedded 101 pass. Expanded four-campaign
menu/save reviews are recorded in validation. Capture art only from owned copied
checkpoints, using their read directory and preserving native path guards.

Preserve original archives/text/hashes, earlier campaigns/player files, live
game/Blender, art/UV/VAT/LODs and C++ rules/RNG/20Hz/save layout. Run visible reviews
sequentially with scratch profiles. This remains needs_evidence/ships_in_release=false;
human pacing, platform testing and commercial map/content clearance remain open.
Frozen Windows ZIPs exclude this campaign.

## Frame-safe menu reading and parchment — 10 October 2026

Parchment is now limited to story briefings and the optional full chapter reader.
The adventure-selection preview uses a dark slate `AdventurePaper` surface with
bronze trim, ivory `AdventurePreviewText`/goal lettering and gold headings.
Keep `AdventureBodyText` dark for story page counters; do not recolor it globally
or reapply parchment to the preview. Native chapter/objective behavior is retained.

The start-menu briefing now keeps campaign/chapter headings and the complete
footer inside the walnut reading area, below the crest and above the carved
lower rail. `menu_navigation.gd` owns this instance's layout through
`episode_card.menu_layout`; ordinary city episode cards retain their layout.
A plain bounded Control around story text prevents long prose from expanding
the frame. Measure full prose into pages after layout settles; never truncate
native text to force a fit.

Objectives now appear together in one container, with no objective paging
buttons or scrolling. Keep every native row and quantity. Short windows and
larger objective lists use a grid; larger lists get a wider objective column. Catalog
chapter selection remains a native preview, not a chapter-skipping command.
The original generated parchment and exact prompt/hash are in
`assets/menu/aged_parchment_v1.provenance.json`. Preserve dark ink, padded clean
paper interiors and sepia `ParchmentPageButton` states. Story pages still have
Previous/Next controls. Run owned sequential EN/RU adventure, campaign-library
and main-menu reviews with disposable profiles; read current validation scope.

## Compact settings-button text — 9 October 2026

`ui/menu_skin.gd` now limits ornamental button textures/serif type to explicit
large menu variations. Generic `Button` retains the shared clean surface, padding
and sans lettering, with a menu-local 17-pixel baseline scaled only by text size.
Do not apply the large ornamental texture to generic Button again: it crowds
key caps, capture prompts and dialog footer labels. Shared city Theme and native
binding/settings behavior remain unchanged. Sequential EN/RU main-menu reviews
cover full key/footer text and enlarged labels; read current validation evidence.

## Subtle menu focus and global cursors — 9 October 2026

Menu keyboard focus now follows the original enamel/bronze button texture with
gentle brightening; preserve focus feedback without restoring a rectangular gold
outline. `scripts/game_cursor.gd` is the `GameCursor` autoload, after `UiAccess`.
It installs 13 original bronze/blue/ivory textures for all 17 Godot cursor roles
across menus, settings, loading and city scenes. Existing Control roles remain
authoritative. Preserve hardware cursors, tip hotspots, transparent padding and
interface-only sizing (48/53/60 pixels at 100/110/125%); text size alone must not
rebuild pointers. Cache each size; no frame loop, input interception or mouse-mode
changes. Headless prepares resources but skips hardware registration.

Retain the generated atlas/prompt/provenance in `assets/cursors/`; regenerate
only derivatives with `scripts/bake_game_cursors.gd`. Five original SVG symbols
supply resize/help roles. Run owned sequential `tools/review_main_menu.py --lang
en` / `ru` (58 each) and `tools/review_game_cursor.py` (44). The latter captures
runtime-size art on light/dark surfaces; viewport captures omit OS cursor pixels.
Keep protected saves/preferences, C++ rules/ticks/RNG and the live game/Blender.

## Ornate Greek menu and fixed navigation — 9 October 2026

Current menu direction supersedes the earlier projected 3D housings below.
`ui/menu_navigation.gd` installs original generated walnut/bronze/ivory frames
and blue enamel buttons through a menu-owned copy of the scaled shared Theme.
These frame assets have painted depth, not separate 3D meshes. The realistic
cinematic background and registered original portal remain. Generation prompts,
measured dimensions and hashes are in `assets/menu/greek_menu_v3.provenance.json`.

Continue (when available), New game, Load game, Settings, Extras and Quit fit the
tall main panel without scrolling. Preserve the `MainScroll` unique reference:
it is now a MarginContainer. Settings groups Display, Graphics, Sound, Interface,
Controls and Game, retaining native preview/Apply/Cancel behavior. Extras holds
the editor and Profiles; Back/Escape returns to the appropriate parent page.
`menu_list_pager.gd` pages/searches catalogs while preserving authoritative native
indexes and exact save paths. Never interpret a visible row as a catalog index.
`menu_text_reader.gd` pages full chapter prose. First-episode story pagination is scoped to the start menu; objectives now
appear together as described above. City episode cards remain unchanged.
Keep all objectives/prose reachable, translated text/focus and reduced motion,
native callbacks, leader/save scopes, C++ rules/RNG/timing and authored scenes.
Run visible EN/RU menu and adventure reviews sequentially with disposable profiles;
read current interface/validation evidence before altering navigation.

## Earlier realistic cinematic main-menu background — 9 October 2026

The user's realism correction supersedes the procedural Olympian scenery below.
Normal `login_scene_3d.tscn` uses `scripts/cinematic_menu_world.gd`: generated
1672×941 photographic Greek artwork with people, a coastal city and geologically
detailed mountains; the original live portal shader is registered to its doorway.
Keep artwork and portal on the same cover/crop/drift transform, calibrated in
original image pixels. The backdrop uses two quads; the current ornate menu stage
above replaces the earlier 3D housings. Reduced motion freezes drift/portal; native menu,
settings and saves remain intact. Preserve the older source/bake and provenance.

`assets/menu/aegean_cinematic_v2.provenance.json` records the built-in generation,
exact saved prompt and hash. A separate packed Blender reference is
`art/menu/cinematic/aegean-cinematic-v2.blend` in the parent workspace; recreate
with `tools/build_cinematic_menu_reference.py` in background Blender. The backdrop
is raster artwork, not individual editable city/person/mountain meshes. Preserve
the live Blender document/connection. Read current interface/validation docs and
run owned sequential EN/RU menu reviews with disposable profiles (34 each).


## Earlier Olympian main menu (superseded) — 9 October 2026

Normal start scenery is `godot/scripts/olympian_menu_world.gd`, with the prior
portal retained through the original composer. `olympian_menu_surface.gd` creates
camera-projected 3D page housings/button slabs under the accessible Control layer.
Keep native callbacks, all unique controls, save/leader scopes, clipping, keyboard
focus and independent UI/text sizing. Shared settings dialogs stay intact.
Reduced motion freezes the camera/sea/portal. Source/retained model hashes guard
`assets/menu/olympian_sanctuary.scn`; regenerate only this derivative with
`bake_olympian_menu.gd`, using a writable explicit log file. Preserve original
portal and model assets, UVs, imported LODs and both provenance catalogs.
Read current interface/validation docs; use sequential disposable EN/RU
`tools/review_main_menu.py` (34 each), or `--art-only` for scene captures.
User art acceptance, minimum-machine profiling and retained-input release
rights remain pending.


## Healers and plague treatment — 9 October 2026

`eHealer::provideToBuilding()` now retains normal hygiene provision and treats
infected common houses through `eGameBoard::healHouse()`, including full-hygiene
houses. Preserve native adjacent-tile reach, finite service supply, outbreak
membership/final-outbreak cleanup, unrelated houses, infection/natural recovery
settings and save layout. Do not fake recovery by hiding Godot aura nodes.
Run `tools/test_plague_healer.py`, disposable sequential EN/RU
`tools/review_plague_healing.py`, embedded and hazard gates. The patrol review
injects only infection and uses a scratch save plus the fixture's known native
Postpone callback. Protect the live game/Blender and install signed fresh inodes.

## Stonewatch defense/hero campaign — 9 October 2026

Read `docs/STONEWATCH.md` and its provenance. Recipe stonewatch_chapters.json v1
adapts the reviewed orius One Against the World parent terrain/world into three
new EN/RU settlement, invasion-defense and Theseus/Minotaur chapters. Normal New
game and the separate Play Stonewatch launcher use native permission/carry/save
flows. Preserve raw sources, First Light/Bronze/player files, live game/Blender,
art/UV/VAT/LODs, native combat/RNG/20Hz/save layout and required callbacks.

Land invasion IDs1–7 are land; higher IDs are sea. Explicitly check the exported
attacker city fields. Editor-only editor_city_team assigns an off-board foreign
city an independent player/team through existing serialized mappings; reject
invalid teams/missing/player/on-board cities and all ordinary play calls. Read-only
editor_world player/team fields provide audit evidence. Never auto-answer an
ordinary player's invasion decision; the owned playthrough explicitly chooses Fight.

Theseus's hall unlocks on monster arrival and retains native palace/appeal/walls/
32-marble/16-wine requirements. Native import bay limits are not city-wide stock
limits; use connected pier-side warehouses, explicit orders and deliberate import
stopping after stocking. Ruined walls need ordinary demolition before rebuilding.
Called companies limit immigration; stand down after battle. Profile integrity
checks protect actual content/saves/settings while allowing active launcher logs
to append. Installer refreshes private verified exports/index explicitly.

Authoring10, visible EN/RU49 each, retained editor64/embedded101 and final ordinary
three-chapter battle/hero completion pass (824 commands/2,150 calls, 648 residents,
16,441 treasury). Shared EN/RU library86 each pass.
Run visible reviews sequentially with scratch roots; sign/install on new inodes.
All adaptations remain needs_evidence/ships_in_release=false. Human pacing/visual,
actual Windows/clean-platform/minimum and commercial clearance remain open; frozen
Windows ZIPs exclude Stonewatch.


## Wheat growth and harvest readiness — 9 October 2026

Read `docs/GODOT_FARM_CROPS.md`. `eFarmBase::harvestProgress()` observes saved
`mRipe`/`mNextRipe`; `usedFields()` shares the original native overlay rule.
Preserve harvest timing/output, staffing, shutdown, save layout and RNG. Separate
snapshot `farm_crops` records must not dirty the cached architecture list.
`farm_crops.gd` overlays original procedural wheat on the villa's five field
tiles using the same foundation/facing/setback transform. Keep spatial batches,
per-instance-only growth updates, both UV anchor sets, reduced LODs and shared
gameplay-clock sway. Do not overwrite farm GLB/source art or other crop models.
The EN/RU inspector shows the native readiness percentage separately from output.
Run `validate_farm_crops.gd` and sequential disposable `tools/review_farm_crops.py`;
use only the designated city/scratch saves and safely signed staged binaries.

## Normal campaign menu and save scopes — 9 October 2026

Read `docs/GODOT_CAMPAIGN_LIBRARY.md`. Normal New game features First Light/Bronze
River/Stonewatch via verified private native installs and an explicit development index;
prior prototype is hidden from New game but remains load-compatible. Source
exports/profiles stay intact. Installer refuses local destination edits, stages
copies before archiving owned installs, and publishes its index atomically.
Refresh it explicitly after authoring. Keep installed private content ignored and
needs_evidence/ships_in_release=false; thumbnails retain input/file provenance.

SaveFiles separates new saves/retry autosaves by native campaign identity under
each leader's .campaigns directory; lists merge owned scopes/flat files and prior
launcher profiles without migration. Only the actual immutable probe's loaded
episode identity selects the write scope after success. External/symlinked leader
deletion is disabled; explicit owned deletion must handle hidden nested folders.
Saved view takes precedence; new Begin applies the indexed authored focus.

Native save_info is a capped informational prefix (1 MiB / 4 KiB identities), not
load validation; checksum-aware hints refresh same-second protected replacements.
Full check/probe/recovery and pause/queue restoration remain. Parent chapter
previews are native template observations; never enable test commands in ordinary
menus or jump chapters from the preview selector. Unowned reader cleanup must not
clear active sound/music sinks. Preserve payload/trailer versions, RNG/rules/ticks,
decisions, models/UVs/LODs, live game/Blender and source/profile hashes.

Visible EN/RU campaign checks pass 61 each; preview regressions 256/58, editor64/
embedded101, save transactions19/recovery36 each pass. Run visible reviews
sequentially with scratch roots. Sign/install Mac binaries on fresh inodes. Windows
core statically compiles; frozen Windows ZIPs do not include this integration.
Actual platform/minimum machines, newcomers and release rights remain pending.

## Bronze River campaign and bridge edge safety — 9 October 2026

Read `docs/BRONZE_RIVER.md`. Recipe bronze_river_chapters.json v1 adapts the reviewed
Armory parent terrain into three new EN/RU chapters, with native phased permissions,
one land partner and copper/bronze/armor/import/reserve/profit progression. Use its
separate Play launcher/profile and generic --plan wrapper; preserve First Light
manifests/profiles, original archives/notes/hashes, live game/Blender and art/UV/LODs.
No colony handoffs. Final Poseidon trade closure begins month 3 for 60 days; waiting
goal remains relative six months/two days. Reserve is an explicit Set aside action.

Bridge placement's four directional end checks must reject null neighbor/shore
tiles before dereferencing. All 2,925 water previews and 120 valid sites pass; valid
costs/geometry/rules are retained. Sign/install both Mac targets on fresh inodes.
Latest ordinary-command run wins all chapters with actual armor sales/fleece imports,
reserve and recovery; 567 commands, 2,660 calls, ~27.5 slowest-speed unpaused minutes
are simulation evidence, not human pacing. Authoring 9, visible EN/RU 53 each,
retained First Light/editor 64/embedded 101 and fresh bootstrap pass. Windows core
compiles statically; existing Windows ZIP is frozen and excludes Bronze River.
No commercial permissions are established; needs_evidence/ships_in_release=false
remain. Human/Windows/minimum-platform acceptance and packaging remain open.

## Three First Light chapters — 9 October 2026

Read `docs/FIRST_LIGHT_CHAPTERS.md`. Active recipe is first_light_harbor_chapters.json
v4, native identity First Light Harbor Chapters; old recipe/manifest/profile remain
through the Previous launcher. Each parent chapter has explicit permissions and
its own EN/RU goals/prose; same city/economy carry. Preserve ordinary permission
records, native RNG/rules/timing/art and originals. The final native trade closure
begins at month 3 for 90 days; its waiting goal is relative six months/two days.
Date met() is boolean for survive/deadline (BC years are not quantities); previews
initialize copied goals. Opt-in export routes need a positive/default stock limit,
native staff/road/trade permission and no fire/shutdown.

Normal-command playthrough wins three chapters; no injected stock/money/people/
victory. Final-year exports 1,650/net profit 1,046. Preserve its proof/scope: ~27.5
slowest-speed unpaused simulation minutes, not a human playtime certificate. EN/RU
visible 38 each, unlocks 37 each, editor 64/embedded 101 pass. Updated private Windows
Chapters kit includes current core/campaign and source/notices; actual Dell remains
pending. Do not package research archives or player/prototype saves. Rights remain
needs_evidence/ships_in_release=false; protect live game/Blender and sign new inodes.

## Episode building gates — 9 October 2026

Read `docs/GODOT_CAMPAIGN_BUILDINGS.md`. Ordinary episode permissions are stored
in existing fPyramids keyed records with empty levels; do not assume every key is
a wonder or change the binary layout. Absent overrides preserve legacy behavior.
Replace ordinary overrides on episode entry, preserve built wonders/native perks,
and use the shared supportsBuilding authority for menu/preview/all placement.
Keep culture, market/vendor and trade/pier dependency gates and removed-tool cleanup.

First Light Harbor v3 authors a complete allowed_buildings list but retains one
chapter/seven goals pending the optional layout choice. Relaunch/new game applies
the recipe; do not migrate/overwrite player saves silently. Preserve source art,
RNG/economy/ticks, live game/Blender and safely signed installs. Final EN/RU unlock
checks pass 37 each, prototype 34 each, buildings 505/campaign 26/editor 64/embedded
101. Natural playthrough, stage-layout choice, Windows/rights remain pending.

## First Light Harbor prototype — 8 October 2026

Read `docs/FIRST_LIGHT_HARBOR.md` and its provenance. Use the separate root launcher
and `tools/create_first_scenario.py`; never install raw sources over the live
catalog. Version-2 recipe/hashes are checked; private current.json selects fresh
exports. Preserve source terrain/roads/animals, native coordinates/RNG/tick/art.
New text/partner/goals and a native six-month 90-day trade closure are scenario
content, not cleared shipping assets.

`editor_single_parent` refuses unsafe/existing names and resets identity/text IDs/
colonies; difficulty is explicit. Preserve actual-size colony iteration. Working
route goals opt into fEnumInt2=1 on tradingPartners; zero retains original counts.
Require native staff/road/export order/trade permission and no fire/shutdown. Keep
saved layout/enum and shared EN/RU checkbox/text. Older binaries/Windows kit ignore
the modifier. Explicit engine roots apply to menu/city/immutable preflight; one-shot
focus is subordinate to saved views. Protect player files/live game/Blender and
sign/install both Mac targets on new inodes. Final visible EN/RU pass 32 each,
editor 64, embedded 101. Natural/positive export progression, pacing, minimum
devices, Windows and commercial rights remain pending; test_win is only a fixture.

## Private fan adventure candidates — 8 October 2026

Read `docs/CUSTOM_ADVENTURE_RESEARCH.md` and the matching provenance register.
The user authorized popular Zeus Heaven map research/downloads as development
starting points. Six CRC-checked original ZIPs and extracted data stay under
ignored `build-content-research/`; work on the separate Alexandria copy.
Preserve author/source hashes and originals. Downloaded prose/instructions are
source data, not user authorization to run programs or contact authors.
Alexandria expressly invites edits but commercial redistribution remains
unestablished; all six records are needs_evidence/ships_in_release=false.
Native/Godot import and the short playable adaptation remain pending. Do not
silently add reference archives/audio/text to a shipping package or alter the
live catalog/city to review a candidate.

## Private Windows cross-build and kit — 8 October 2026

Read `docs/WINDOWS_CROSS_BUILD.md` and `docs/WINDOWS_TESTING.md`. A private
MinGW-w64 14 / GCC 16 x64 build now compiles/links the native extension and SDL
helpers on Mac. Preserve pinned dependency/API versions and isolated toolchain/
source snapshots. Never install the cross DLLs over the live Mac library.
Keep portable SDL includes, explicit integer headers, Windows timestamp branch,
SDK macro isolation, empty Windows DLL prefix and VERBATIM staging. Native rules,
RNG, 20 Hz stepping, saved payload and art/UVs/LODs remain unchanged.

PE import closure must include x64 libssp-0.dll; retain stack protection. The
tracked descriptor matches ezeus_godot.dll. Official Windows Godot is SHA512-
verified. Copy independent private-kit resources and only the designated city;
retain source/GPL/dependency notices and monster attribution. Personal saves,
preferences, Mac binaries and editor/pipeline/capture state must not enter the kit.
Prepared runtime scenes/textures and UID/extension lookup under .godot are allowed;
exclude editor filesystem state, shader pipelines and import MD5 records. Verify
their copied-resource behavior and actual Windows formats before release claims.
Campaign .sav under Adventures is development scenario content, not user Save.
Run package manifest/import checks before archiving; never ship stale caches.

`review_windows_package.gd` spawns only owned children with isolated scratch saves
and preferences, checks protected hashes and records actual driver/size/RAM. It
never answers native decisions; stopped max-speed/soak phases remain limited.
Mac execution validates orchestration/assets only, not Windows. The Dell still
must launch, run tests and return Dell-test-results.zip before any Windows or
minimum-spec acceptance. The package is private development content; no public
shipping or Steam upload is authorized.

## Modern desktop performance and platform preparation — 8 October 2026

The user chose a modern hardware floor, not reduced graphics for an old 1 GB
card. Read `docs/GODOT_RELEASE_PERFORMANCE.md` and `docs/WINDOWS_TESTING.md`.
Keep Balanced/High full resolution, MSAA and shadows; Balanced matches prior
appearance. Two cascades, source models/UVs/LODs, native map/crowd/rules/RNG,
20 Hz stepping and decisions remain. Graphics previews apply without world
rebuild; only Apply stores the graphics section. Cancel/Escape/removal restores.
Preserve display preview, independent UI sizes and nested menu holds.

Mac uses Metal; Windows uses Direct3D 12 with Vulkan fallback. Automatic legacy
OpenGL fallback is disabled. Low/Compatibility work was removed on user steering.
Hardware/OS targets are provisional until actual minimum-machine launches and
matched frame-pacing runs. Windows build scripts are prepared, not MSVC-verified.
The installed Mac dylibs encode macOS 26 and still reference Homebrew helpers;
do not advertise macOS 14 from current binaries or fake a lower binary version.

Use sequential owned EN/RU `tools/review_graphics.py`, Escape-menu checks and
`tools/review_release_performance.py` with scratch settings/saves. Record actual
resolution/driver, p95/p99/hitches, RAM/VRAM and phase block limits. A window manager
may fit the requested size; only an exact-size run qualifies that resolution.
Never answer decisions automatically or claim a stopped soak is a long run.
Keep source/preferences fingerprints and guard full scene save/load transitions.
`tools/audit_platform_runtime.py` checks metadata only, not hardware acceptance.
Build/sign/install Mac on a new inode; preserve the running game and Blender.
The tracked `presentation/godot/ezeus.gdextension` feeds both platform helpers.

## Save reliability — 8 October 2026

Read `docs/GODOT_SAVE_RELIABILITY.md` and current validation. Keep native `.ez`
payload/version compatible; the versioned checked trailer owns persistent facing,
speed and native-coordinate camera view. Facing keys are board/city/type/seed/rect,
not raw pointers/session IDs. Parent boards share -1; colony indices remain scoped.
Preserve native pause-on-load and refusal to save required pending decisions.

Writer stages are unique and verified/synced before replacement. Keep two checked
previous generations, separate legacy copy and damaged evidence; refuse concurrent
writers and retain complete interrupted stages for recovery. Do not rotate an
unchecked legacy/damaged file over a verified backup. Bounded file readers track
remaining bytes in memory, not by seeking per primitive. Valid empty inactive
boards remain supported. No native rule/RNG/economy/serialization layout changes.

Load preflight uses an owned headless probe over a private immutable copy, never
the active core. Only that proven copy is handed to the next scene and cleaned.
Failed/cancelled loads keep the live city and restore exact pause/command holds.
Recovery is explicit; originals remain intact; never restore the old silent
test-city fallback. Header checks alone do not prove footerless legacy content.
Headless GLB warming is synchronous for dummy-renderer RID safety; Metal still
uses joined threaded loading. Keep save-name UTF-8 limits and EN/RU messages.

Run `tools/test_save_store.py`, sequential owned
`tools/review_save_reliability.py --lang en` / `ru`, loading/menu reviews, retained
saves/load/embedded/camera/translations and a designated-derived native round trip.
Every validator must register scratch save/preferences, assert loaded snapshots
and distinguish primary files from backup artifacts. Never use actual player
save folders for temporary test output. Build/sign/install the extension on a
new inode through staging, preserving the user's running library mapping.

## Independent product decision — 7 October 2026

The user confirmed an independently branded city-builder for the intended Steam
release. Read `docs/RELEASE_IDENTITY.md` and `docs/PRODUCTION_ROADMAP.md`. Final
name/price/date/platform promises remain unapproved. The user plans campaigns
based on modifications to current maps/text/objectives and reports custom music
implemented, with effects to follow. Preserve originals and work on copies;
record adaptations/source inputs rather than silently marking them independent
or cleared. New/generated/revised content needs file-level provenance and any
necessary retained-content permission. Keep development compatibility resources
separate from the shipping allowlist/content provider. Retain GPL/authorship and
save identifiers; Steamworks SDK integration remains a separate unresolved review.
This decision does not authorize deleting original files or publishing a build.

## Construction reveal and foundation supports — 7 October 2026

Preserve the second-pass contracts in `docs/GODOT_CITY_CLARITY.md`. Compatible
opaque vertex-palette sanctuary/pyramid meshes use full proportions with native
`grow` mapped to a world-height cutoff in MultiMesh custom blue/alpha. Red/green
remain work flag/phase. Check complete template compatibility before computing
the cached transform; retain unsupported textured/VAT and foundation-only paths.
Timber scaffolding stays inside unfinished lots, follows actual height and leaves
on completion. Native costs/material deliveries, work/progress/timing stay intact.

Base hull/support caches follow placement, growth and surface revision. Skirts
sample existing land only, inside lot/setback; skip roads, water, holes, starter
earth lots, gates/water structures and drops above 0.88 tile. Keep native level
foundation heights and dirty 32-tile grouping. No new physics/navigation or GLB
rewrites. Construction advice uses native halted/road/needed/employee fields.
Warning IDs and native tiles must lie in the current rendered footprint, allowing
registered far-corner pyramid pieces without accepting stale/replaced objects.

New empty-game Begin may offer the non-modal guide after loading. Finish remembers
only a presentation preference; ?/menu retain manual access. Native smoke tests
clear/build only in a disposable designated copy, never another personal save.
Replay tests must register the scratch save directory and assert loaded snapshots;
compare same-session save bytes and seeded gameplay digests, not equality of
binary save hashes after separate loads. Retain sequential owned EN/RU clarity,
placement, native elevation, camera, refresh, activity and translation checks.

## City clarity and shared finish — 7 October 2026

Read `docs/GODOT_CITY_CLARITY.md` and current validation. `city_attention` visits
the current city's all-building list (static roads are absent from the timed
list) without changing inspector tokens, events, RNG, native rules or time.
Only emitted current-player targets become warnings. Check ID/footprint before
Go to; retain editor drafts. Preserve exact native stop reasons, current-level
housing decline versus optional upgrades and stock-pickup hints. Help polls only
while visible, at most every five seconds with pointer reading holds; preserve
non-modal pause/queue restoration, filters and the six explicit guide steps.
The help card (8 October) has Issues | Guide tabs, a collapsible one-line tracker,
and a stepper whose current step shows live native counts, Build/view actions and
a pulsing outline on the dock button that builds it. Steps never auto-advance.
Issues uses counted filter pills and severity cards whose overlay button carries
`attention_item` (find it recursively). Styles are `Guide*`/`Issue*` Theme
variations (regenerate with `build_ui_theme.gd -- --guide-only`).

The cached architecture finish applies only to eligible opaque, untextured,
non-metal vertex-palette static surfaces. Preserve both UVs/LODs, source GLBs,
textured/VAT/emissive materials and citizen/monster adapters. Work interpolation
is bounded between existing periodic poses and retains native flags/clock.
Human slope support is capped root clearance, not IK; cache position/heading and
surface revision and skip level ground, boats, gods, perches and combat. Native
monument percentage/growth remain; do not invent ordinary construction timing.
The original synthesized soundscape is opt-in; preserve source/output provenance
and existing battle/voice/effect routing. Full art/audio acceptance remains open.

Build the extension to staging and atomically install a newly signed inode;
never truncate or re-sign the live game's mapped library. Run sequential owned
EN/RU `tools/review_city_clarity.py`, status UI and Escape-menu reviews with
disposable settings/saves, plus embedded, activity, camera and audio gates.

## Building refresh performance, second pass — 7 October 2026

Keep inspection records current on every changed native building list. An exact
ordered rendering key may omit quantity/staff totals, but includes native IDs,
assets, geometry/facing/growth, work flags/phases, occupied bay indices/goods,
placement revision, map coordinates and overlay visibility. Explicit road,
terrain and overlay rebuilds must bypass the unchanged-render filter.

Minimap building footprints/categories repaint only when their ordered rows
change; tile deltas retain occupied building colours until removal reveals the
latest terrain. Agora paving persists by ID and must be removed on replacement
as well as demolition. Reuse each fixed-template MultiMesh group on count/position
changes; resizing invalidates cached custom data and restores every work flag.
Unchanged activity data skips GPU writes. Default animal VAT finishes may share
only identical pose textures and finish values; pose/layout stay per instance.
Preserve worker clocks, UVs, materials, LODs, native rules/RNG/saves and loading
thread joins. Run `validate_refresh_performance.gd`, camera cache, native storage
and building activity gates, owned placement review and sequential camera review.
The latter has a frozen pre-filter refresh baseline in `tools/profile_baselines/`
used only in its disposable subclass; never install the benchmark in gameplay.
See validation for paired CPU evidence and remaining frame/loading limits.

## First camera performance pass — 7 October 2026

Preserve the road-kind index driven by native tile deltas, per-citizen ground/lane
cache invalidation, unchanged building placement cache and camera footprint key.
Road/elevation, native growth/facing/footprints and projection/viewport changes
must refresh before drawing. Native positions, gait clocks/planar stride, god
float and exact VAT/fallback/skeletal blending remain authoritative as before.
Normal and combat VAT writers share pose cache state; held aliases may skip writes.
Keep `buildings_changed` gating and incremental batches. Hidden minimap camera
work may be skipped, but native sound `view_box` observations must stay live.

Wheel notches ease toward an accumulated bounded destination with terrain cursor
anchoring. Pinch and explicit `zoom_at` calls remain immediate; Home/Go to and
modal/text/toolbar holds cancel pending motion. Outward atlas crossing retains
the existing callback. Detailed physician spares are prepared only while nearby
detail is used; preserve the role mapping, nearest-24 cap, hysteresis and phase.
Run `validate_camera_performance.gd`, controls, streets, locomotion, citizen,
owned placement review and `tools/review_camera_performance.py` with disposable
preferences/saves. Performance evidence is scoped CPU work; read current
validation before claiming full-game or minimum-Mac performance.

## Character panel and native stock — 7 October 2026

Read `docs/GODOT_CHARACTER_INVENTORY.md` and current validation before changing
the centered character card. Peddler supplies are the linked Agora's native
vendor stock/capacities, not an independent cart store. Transporters use actual
resource/count loads; growers use collected fruit counts. Keep resource bits,
native `x()/y()` command coordinates, missing-vendor/empty-load distinctions and
the existing illustrated goods icons. Never infer cargo from portraits or invent
simulation inventory. `character_inventory` is a read-only query, independent
of spoken-line selection and RNG, polled once per second only for an open
inventory-bearing character.

Preserve stable cards, native text/voice, disabled portrait viewports, model
fallback, same-tile selection, focus and exact previous pause/command hold on
every close path. Shared Theme/CSV and independent text/UI scales stay in use;
scroll details above the persistent footer. Native rules/routes/saves/model art
remain intact. Run `validate_character_inventory.gd`, sequential owned EN/RU
`tools/review_character_panel.py`, embedded and translation gates with scratch
preferences/saves. The review's 200 ordinary native ticks spawn the saved city's
peddler; no test-only peddler or simulation inventory is installed.

## Slim instant notices — 7 October 2026

Instant open notices omit the title/icon row and Close button. Preserve their
full wrapped body, thin timer bar, shared Theme, width/scroll fitting and all
attention holds. The card handles click-release/keyboard pinning and right-click
release dismissal via the original informational callback. Keep titled journal
disclosures and required-decision controls intact. This supersedes older instant
title/Close instructions. Use `validate_notification_layout.gd` and sequential
scratch-only `tools/review_chrome.py --notifications-only --lang en` / `ru`;
the focused mode avoids unrelated chrome fixtures. No native rebuild is needed.

## Anatomical monster rebuild — 7 October 2026

The sixteen non-Hydra monster identities now use `tools/godot_monster_anatomy.py`
through `godot_monster_reference.py`. The user's Monsters folder is mapped to the
retained concept sheets; v3 neutral sources are
`art/monsters/<species>/<species>-reference-v3.blend` in the parent workspace.
The earlier rounded v1 sculptures/staged v2 details are superseded. Read the
current monster art contract, validation and reference catalog before exporting.
Use isolated background Blender only, preserving the live port-9876 document,
shared animal/human libraries, Hydra, native rules/RNG/recipes/saves, both UVs,
CityPalette, 114 poses, mouth/contact probes, cached finishes, fresh VAT and
reduced LODs. Stable runtime revision remains `monster_reference_v1`; the anatomy
has separate `design_revision: monster_anatomy_v3`.

Sources include CC0 human/wolf/crocodile anatomy and a CC-BY cave-lion face.
Preserve `art/monsters/anatomy-v3/ATTRIBUTION.md`, library records/source hashes,
and backups. Do not execute vendor scripts. Cap source points at 16,500,
imported vertices/triangles at 34,000 and surfaces at three. Change only the
sixteen deliberate geometry entries. Source/export/runtime/native effect checks
and matching multi-view Metal captures are required after geometry changes.
Painted PBR textures, user visual acceptance, slope IK, flight refinement,
minimum-Mac profiling and overall release-rights evidence remain pending.

## Common housing models — 6 October 2026

The active `common_house_<0-6>a` family uses `tools/godot_housing.py`; read
`docs/GODOT_HOUSING_ART.md` and the latest validation before re-exporting. Original
starter wattle/daub and mud-brick cottages replace the white conical hut/short
box, neutral irregular yards replace the golden lots, and architecture heights
rise through 0.96/1.16/1.36/1.58/1.84/2.18/2.56 tiles. Preserve resident anatomy
with inverse local height scaling; the first two entrances are model +Y for
the existing road-facing adapter. Native rules, footprints, needs, occupancy,
evolution and saves stay authoritative.

Use disposable background Blender only. Preserve native house recipes/Blender
scenes, both UVs, CityPalette, bounded PBR groups, source vertex allocations and
imported reduced LODs. Update only the seven intended house baseline entries
through `validate_housing_art.gd --write-baseline`; never rewrite other geometry.
Use `validate_housing.gd` and the owned scratch-only `tools/review_housing_art.py`.
Elite houses/unused b variants retain their art. Full material baking, user visual
acceptance, source rights evidence and minimum-Mac profiling remain pending.

## Ruined-building inspection and clearing — 6 October 2026

Godot ruins show the native former building name and expose a guarded, costed
Demolish action. Preserve `eRuins::Site` as transient presentation identity only:
native rubble objects, serialization, collapse RNG and per-tile erase cost stay
unchanged. New collapse footprints are exact; legacy saves recover bounded
creation-order runs using native dimensions, with conservative unknown/fragmented
fallbacks. Never merge all touching same-type ruins with an unbounded flood fill.
Hover, held/area preview and rectangle contact operate on one complete site;
clear only its current matching rubble and block a site if any member burns.
Inspector and tool member-set guards are independent. Keep EN/RU CSV/Theme and
scratch-only tests; use `validate_ruins.gd`, `tools/review_ruins.py`, and the
current interface/validation documents before changing this contract.

## Paved avenues, boulevards and walker clearance — 6 October 2026

Native avenue/boulevard medians are walkable roads. Keep the entire two/three
tile corridor paved; the old grass median and centered trees are superseded.
`street_layout.gd` supplies read-only topology for `terrain_avenues.gd` and
`walker_streets.gd`. Cached original marble statues, benches and planters, plus
olive/cypress trees, occupy narrow outside edge pockets. Ends, bends, crossings
and building entrances stay clear. Preserve spatial MultiMesh batching, reduced
mesh LODs and the avenue detail layer's two-cell dirty-neighbor radius; ordinary
detail layers retain radius one. No native placement, collision, route, RNG,
timing, footprint, cost or save change is needed.

Wide-road render lanes retain their separate `lane_raw` easing state, merge
smoothly at diagonal corners and stay inside the undecorated walking corridor.
Human heading follows displayed travel there; gait phase still follows native
horizontal travel. Single-tile roads and perched-guard behavior remain unchanged.
Dedicated cached street thumbnails show the full two/three-tile width; keep the
native one-cell drag anchor in the catalog. Run `validate_streets.gd` and the
owned disposable `tools/review_avenues.py`; see validation for scope and limits.

Wall choices no longer show `%WallFill` (6 October 2026). Keep it hidden during
selected/hovered context refresh; Shift-drag retains the native filled-rectangle
modifier. This supersedes earlier instructions to show the fill checkbox.

## Right-side notification hub — 6 October 2026

The fixed upper-right `%EventRail` now contains an illustrated Journal and an
Objectives scroll, followed by an amber `%DecisionReview` only while a native
reply is pending. This supersedes the permanent bottom-right objective summary
and the folded correspondence reminder panel. Objectives opens its existing
native cards on demand, with a progress line and unseen-completion badge on the
icon; open-play hides it. Opening goals never moves the construction dock.
Keep the fixed rail independent of the Resources drawer, measured disclosures to
its left, native set-aside commands and inspector drafts/tokens.

`notification_button.gd` extends the mouse-up-safe ToolbarButton, drawing a
separate count/progress overlay without input Controls. Original shaded SVGs in
`toolbar_icons/notice_*.svg` share the existing illustration system. Use shared
NotificationRail/Button/ScrollBar Theme variations; highlights are finite and
respect Reduce interface motion. Journal filters change only the view (All
reports / Warnings / Decisions); retain complete history and stable reading rows.
Routine reports remain quiet, urgent reports keep the one-alert queue, and new
required choices still open their centered native correspondence modal.

Hazard/monster controls occupy the bounded `%AlertScroll` / `%AlertList` below
the utility icons. Retain native kind grouping/order, occurrence/site dedup,
persistent fire/plague, location and dismissal callbacks. Integer scroll height
avoids a fractional last-row clip at enlarged UI sizes. Hover, keyboard focus,
hidden/clipped controls and blocking dialogs hold hazard attention timers.
Folding a decision never answers it or releases the native block. Review with
sequential disposable chrome/decision helpers and the headless notification/
hazard gates; see current validation for verified counts and limits.

## Olympian marble defences and roof guards — 6 October 2026

Godot now exports all sixteen wall masks, tower and gatehouse through
`tools/godot_defences.py`; preserve the parent native sprite recipes/atlases and
live Blender scenes. Read `docs/GODOT_DEFENCE_ART.md` and current validation before
re-export. `godot/data/defence_art.json` shares model/runtime heights: wall walk
2.0, tower platform 3.05. The native `lift` observations stay 0.8/2.57 and identify
perched guards; do not change C++ rules/coordinates/RNG to match art.

`defence_perch.gd` refreshes its footprint index only with the existing building
change path, bounds render-only guard positions inside platforms/connected walks,
and uses the building's foundation height. Street lanes are immediately zero for
perched guards; ground archers retain their ordinary path. Preserve native patrol,
combat, selection, construction, costs, facing and save behavior. The portal keeps
its one-tile road free. Preserve authored UVs, palette finishes and reduced LODs;
update only intended geometry baseline entries (sixteen wall entries for the height follow-up). Focused art checks,
native walls and isolated Metal/moving-guard review pass; user art acceptance,
full material baking, height transitions and minimum-Mac profiling remain pending.

## Compact upper-left overview and stable notices — 6 October 2026

This supersedes the centered 86%-width overview. `%ResourceRibbon` starts at
16 logical pixels from the left, measures city name plus the native stats, and
uses only their width, capped by the viewport. Stocks open directly beneath it.
Keep measured text widths, responsive stats wrapping, actual header-height bounds,
opaque readings/icons, native cached observations and existing callbacks. The
shared Theme registers ResourceRibbon as a PanelContainer variation, with a 90%
charcoal background and compact padding; do not fade the whole Control subtree.
Time remains below the map and Jobs remains after Layers.

Notice cards explicitly fill their parent VBox. Never call `reset_size()` from
`notification_chip.gd` body fitting or pin/unpin: autowrapped labels and ellipsized
headings have a tiny minimum width, so that reset discards the parent's assigned
width and collapses the report. Update the bounded body minimum height only when
it changes; let containers arrange the card. NoticeBody is a shared 15-pixel
Caption variation, scaled by UiAccess rather than a font override. Preserve full
wording, scroll/row identity, reading/hover/hidden/clipped timer holds, single-alert
queue, informational acknowledgements and native required-decision ownership.
Run `validate_notification_layout.gd` and sequential disposable chrome reviews;
see validation evidence for reproduction, counts and tested scope.

## Clock below the map and main-row hotkeys — 6 October 2026

This supersedes the preceding map-button/header placement. `%TimeBar` is a root
HUD panel below the circular minimap: Play/Pause and speeds 1–4 on its first row,
with the native date/month gauge below. Measure its minimum size and reserve the
map/clock column when fitting the dock. `%MapToggle` is visible only when the
actual map is hidden, above the clock; the open circle retains `%MapClose`.
Keep default/explicit version-2 preferences and temporary folds unchanged.
`%Jobs` now follows Layers in the bottom main row, preserving its industry-view
callback and all native employment figures in hover help. The construction/
hover context is centered and uses the tooltip's first line to avoid growing
the row with Jobs' multiline figures.

Only the bottom main buttons add shortcut titles: Housing H, Road B, Road Block
G, Layers L, Jobs J, plus existing X/Delete demolition and Cmd/Ctrl+Z Undo.
Use `KeyBindings`, the Controls dialog and original button callbacks/native
availability. Categories retain plain hover names. New shortcuts respect typing,
dialogs and required decisions. Legacy custom bindings take precedence over new
defaults: a collision leaves the new dock action translated as Unassigned (code
0), without rewriting preferences; it can be rebound normally. Never allow an
empty key to fire or replace a held camera key. Controls changes refresh hover
help without querying the native simulation. Time keyboard focus still holds
camera input, and mouse/Escape releases it. Review sequentially with disposable
toolbar/chrome helpers; current counts and limits are in the validation document.

## Dock shortcut arrangement — 6 October 2026

The upper-left City views strip is removed. Its four original supply/water/
hygiene/hazard buttons live inside the bottom Layers disclosure, alongside all
25 native overlay choices. The duplicate Inspect and Build buttons stay hidden;
normal inspection, Escape and the complete categorized native catalog remain.
Left utilities are Undo → Housing → Road → Road Block → Demolish. Direct building
shortcuts follow native catalog availability. `toolbar_icons/roadblock.svg` is
an original shaded barrier illustration; no Blender/export change is needed.

`%MapToggle` is a root HUD button beside the circular minimap, with a reachable
bottom-left button while folded. It is outside the construction dock. Preserve
version-2 visibility preferences, the open default, temporary tray/journal/
decision folds, circle corner pass-through and native transforms. Layers fits
above the dock using measured header/chrome heights and a scrolling list;
opening click never selects a view. Escape/right click/Close return input;
outside terrain dismissal consumes its click before construction. Closing an
already closed Layers panel must not steal another control's keyboard focus.
Required decisions retain their original native pause/callback ownership.
Review sequentially with disposable `tools/review_toolbar.py --lang en` / `ru`
and the chrome gate; see interface/validation documents for the tested scope.

## All monster reference sculptures — 6 October 2026

All sixteen remaining monsters use `tools/godot_monster_reference.py`, with
individual concept sheets and editable neutral `.blend` scenes under parent
`art/monsters/<species>/`. Only background Blender is authorized. Hydra's sources,
runtime and baseline remain intact. Read `docs/GODOT_MONSTER_ART.md` and the latest
validation before re-exporting. Preserve both UVs, palette, 114 pose aliases,
per-mouth/contact probes, native rules/RNG/saves, cached finishes, VAT freshness
and reduced LODs. Cap each new sculpture at 16,500 authored points, 34,000 imported
vertices/triangles and three surfaces; update only its deliberate baseline entry.
The eight humanoid monsters bypass the citizen adapter; the human validator now
expects 104 adapted assets. The source catalog distinguishes verified Hercules
screen studies, film anatomy motifs and original mythology/game designs.
User art acceptance, painted materials, slope foot IK, harpy flight refinement,
minimum-Mac profiling and release-rights evidence remain pending.

## Complete construction-card previews — 6 October 2026

Thumbnail requests carry the catalog item and cache by building/tool identity,
not its component asset. Trade partners share the same base design. The Common
and Grand Agora use distinct previews of their three/six empty paved vendor plots
and street; they have no standalone GLB and do not include vendors. Composite
palace/ranch/sanctuary/pyramid/shrine/god-monument pictures assemble the native
read-only placement `pieces` on a flat display, using existing models and fitting.
Pyramid sprite-face axes receive a preview-only reflection/quarter-turn to join
correctly, baking copied geometry/winding rather than using negative node scale;
retain colors, both UV arrays and shared finishes without mutating imports.
Never place/grant a building to make a picture, scan for a valid site, or add
simulation polling. Keep one on-demand 160×100 viewport, idle disabled, freeing
temporary nodes and bounding complete silhouettes. Terrain tools keep the colored
road illustration. `tools/review_toolbar.py --previews --lang en` / `--lang ru`
audits all catalog geometry and rendered/card/context/callback behavior with
disposable profiles. Read interface/validation evidence for scope.

## Illustrated header coin and citizens — 5 October 2026

`%TreasuryIcon` and `%CitizensIcon` now use original static `toolbar_icons/treasury.svg`
and `population.svg` in matching 24×24 logical-pixel, aspect-preserving cells.
They extend the existing colored SVG icon system. The HUD no longer instantiates
`SilverCoin` or runs its treasury-gain flip; its old source remains archived.
Preserve native treasury/population/ledger/mood data, tooltip parents, white tint
and pointer pass-through. This supersedes the older live-coin requirement.

## Matching HUD panels and open map — 5 October 2026

City surfaces now share the construction dock's charcoal fill, restrained bronze
edge and shallow corners through the shared Theme generator. Preserve parchment
story/letter surfaces and meaningful chosen/completed/danger colors. The centered
overview measures its native readings, aims for 86% width (1560 logical-pixel
cap) and grows/wraps for large text/counts. Reduced padding and header typography
keep the default bar compact. Resource disclosure follows the same centered width;
actual header height still governs lower panels and native input remains intact.

The corner `%MapPeek` shortcut stays hidden. `%MapToggle` in the dock and `%MapClose`
remain the map controls. The map now starts open, superseding the old folded
default. Unversioned old visibility preferences adopt the open default without
a launch-time write; explicit choices save `minimap_visibility_version=2` with
`minimap_visible` and are remembered thereafter. Temporary folds for trays,
journal/expanded decisions do not change that preference or native pause ownership.
Keep the circle mask, pass-through corners and native coordinate transforms.

## Top-bar titles removed — 5 October 2026

At the user's request, Date/Speed/Current city/Housing/Treasury/Monthly balance/
Population captions are hidden in the authored HUD; their unique nodes remain
for compatibility. Do not restore them during translation/scaling. Values and
icons are vertically centered. Time controls are ordered Play/Pause → speeds
1–4 → date, with existing native readings, hover explanations,
responsive wrapping and mouse-up focus release retained. This supersedes the
visible-caption requirement in the earlier overview section below.

## Toolbar mouse activation fix — 5 October 2026

The shared `toolbar_button.gd` releases mouse focus only after mouse-up. Releasing
on mouse-down cancels Godot's armed Button before a normal later release, making
both redesigned bars unresponsive. Keep keyboard focus for navigation and native
release activation for MenuButtons. Review mouse helpers must wait frames between
down/up; same-frame injection concealed this failure. `validate_toolbar_input.gd`
checks ordinary untagged pointer input and cancellation/focus behavior without a
native city. See validation for the reproduction and corrected visible reviews.

## City overview and panel polish — 5 October 2026

The top ribbon now has Date/Speed/Current city/Housing/Treasury/Monthly balance/
Population captions, numbered native speeds, explicit free housing and named
Resources disclosure. Keep the native month/occupancy gauges, static silver coin,
native mood and existing ledger calculation. Shared `Header*` Theme variations
respect independent text size; `hud.gd` measures gauge labels and reparents the
whole stats group into a second row when necessary. Actual header height governs
the resource rows, notices and side-panel bounds. Do not regenerate the authored
HUD or save a scaled Theme.

`hover_help.gd` shares bounded, pointer-ignoring help between dock buttons, header
controls and Army company rows. Header keyboard focus holds camera input; Home
honors both header/dock ownership. Escape/right-click folding Resources and actual
Jobs/stock/view selections release that focus without a pause/save command.

Army uses `fit_host` against the actual header/dock clearance, a fixed title/Close
and scrolling content. Preserve native company IDs/order predicates/callbacks,
stable rows and nonmodal behavior; long rows keep full hover text and disabled
orders explain their native restrictions. Inspector headings show native footprint/
staffing, stored-good names wrap with full tooltips, inspector/journal scrolls
follow focus, and objective numbers use locale-appropriate grouping. Preserve
inspector drafts/tokens and native goal completion. Run sequential disposable
`tools/review_chrome.py --lang en` / `--lang ru`; `--army-native` adds existing
native Army regression commands only in unsaved scratch memory. The headless
`validate_army_layout.gd` covers long-name/empty/abroad/aid fixtures. See the
interface/validation documents for verified scope and protected-save evidence.

## Illustrated construction toolbar — 5 October 2026

The bottom dock now has a colored category row and a separate utility/context
row, following the user's Anno toolbar layout reference. Original static SVGs
in `godot/ui/toolbar_icons/` replace the category/tool gold glyphs; preserve their
white icon tint and use gold for the selected marker. Every visible control has
an immediate translated name and bounded explanatory tooltip. Keep the authored
HUD, shared `Toolbar*` Theme variations and CSV translations; do not regenerate
the HUD with its historical builder or save a scaled Theme.

Native category eligibility, model cards/costs, tools, map preference, Undo and
overlay callbacks remain authoritative. Identical catalog refreshes preserve
controls, scroll and focus. The duplicate direct housing shortcut and BuildSearch
remain hidden. Category scrolling follows keyboard focus; mouse selections,
tray closing and actual Build/overlay choices release toolbar focus. Open toolbar
popups/focus hold camera input and clear a previous drag. Both MenuButtons open
on release without switching on hover, preventing accidental opening-click picks.
Run sequential disposable `tools/review_toolbar.py --lang en` / `--lang ru`;
read interface/validation contracts for scope and protected-save evidence.

## Centered required decisions — 7 October 2026

Expanded `%EventsBox` is a centered correspondence modal above the HUD, with a
dim `%DecisionShade`, native sender/static framed portrait, dark reading panel and fixed
choice footer. `%EventActions` is now a GridContainer; preserve exact native IDs,
labels and callbacks when ordering/styling Refuse/Postpone/affirmative actions.
Invasion callback meanings differ (0 Surrender / 1 Bribe / 2 Defend); multiple
receiving cities are equal choices and -2 retains the existing enlistment flow.
The native required-decision block owns the stopped clock. Right-click on an
expanded card or its folded `%DecisionReview` icon invokes the offered native
Postpone callback (choice 1), sharing the button's guarded reply path. Exclude
invasions: their choice 1 is Bribe. Without Postpone, right-click only folds.
Fold/title-toggle/Escape/settings return/canceled enlistment never answer or
resume it. Postpone releases its own native block without changing manual pause
or other pending decisions. Debounce queued replies, preserve retry on queue
full/error, and never add a forced resume. Expanded
cards intercept city clicks/camera input and trap Tab without focusing a reply;
Escape folds the foreground card before a journal behind it. Keep UiAccess's
separate dialog/pause owners intact. Edit the authored HUD, not its old generator,
and regenerate only shared Theme styles (`build_ui_theme.gd -- --decisions-only`). Sequential disposable
`tools/review_decision_panel.py --lang en` / `--lang ru` checks and native request
evidence are in the interface/validation documents.

## City notices in full at the top centre — 5 October 2026

Toasts (`hud.show_toast`) are `NotificationChip`s with `open = true`: title and full text shown at once (15 px body, up to
132 px then scrolling; a click pins it with 260 px and stops the countdown). The stack sits at the top centre under the
top bar, below the tool hint / invasion notice and a decision reminder, and narrows left of an open inspector or journal.
Reading time is 9 s + 1 s per 25 letters (max 24 s), paused on hover. One notice at a time; the rest queue as before.
Journal rows (`history_row`) stay collapsed. `review_map_notifications.py --checks` keeps 8 failures unrelated to this
(tool-card cost x6, distribution shortcut, decision button order).

## Top bar (time, housing, money, popularity) — 5 October 2026

The bottom-left time panel moved into the top ribbon (`hud.tscn` OverviewRow: `%TimeBar` with `%Pause`, the date over
`%MonthProgress` (the month's days, real month lengths) and `%Speed`, four chevron buttons for native speeds 0..3 built in
`hud.gd` `build_top_bar()`; `hud.speed_button` and its popup are gone). The stats now read: `%Housing` gauge (native
`ePopulationData` people / people + vacancies, label "free / total", deep gold, terracotta when nothing is free; no green: lapis and gold only), `%Money` well with a 3D
silver drachma (`ui/silver_coin.gd`: owl/helmet relief from SVG height maps, rendered once and only while it flips on a
treasury gain), the treasury and the monthly balance `%Income` (running income less running costs over the last twelve
months, construction excluded: `hud.gd` `monthly_balance`), then population with `ui/mood_face.gd` (native popularity,
eCityData thresholds). The core adds `housing`, `popularity` and `finances` (this/last year ledgers) to `city_header`.
The minimap and City map pill take the bottom-left corner; the dock reserves that column. Popularity words use
"Popularity is …" keys so generic words such as "OK" keep their translations.

## Campaign-panel presentation — 5 October 2026

The authored `episode_card.tscn` now has separate chapter/episode metadata,
parchment story, native objective cards and a fixed action/difficulty footer.
Keep its unique controls/signals and both hosts, `fit_host` bounds, independent
story/goal scrolling, keyboard difficulty controls and shared Theme/CSV. Native
`met` flags alone determine achieved cards/counts. The overlay's campaign/retry/
menu commands and voice/session handoff remain unchanged. Do not rerun historical
card/overlay/start generators over these authored scenes. Use
`validate_campaign_ui.gd` and sequential disposable-profile
`tools/review_episode_panel.py --lang en` / `--lang ru`; read interface/validation
contracts for the test-win and all-achieved visual fixture scopes.

## Camera reach when zoomed out — 5 October 2026

The orbit centre was already clamped to the map, but at far zoom and low tilt the view showed mostly land or sea past the
border. `orbit_camera.gd` now holds the centre toward the middle as the zoom grows (`reach()`, `PULL_START` 45,
`EDGE_PULL` .7: the whole map up to distance 45, the middle 30% at the farthest zoom). It is not a performance measure:
`--view-review <tag>` (`review_view_bounds.gd`) shows the land outside the border is cheap (a far-outside view draws 1.48 M
primitives against 1.54 M in play and 2.27 M for the whole-city overview), so keep `visibility_range_end` and the
800-tree cap in `surroundings.gd`. Preserve `world_zoom_requested` (atlas) and `jump_to_cell` / `focus_walker` clamping.

## Earlier main-menu shell (layout superseded above) — 5 October 2026

The authored main page has a content-sized left shell, original SVG emblem/icons,
separate latest-save card, primary New game action and named keyboard-accessible
Settings. Empty profiles hide Continue and focus New game. Preserve unique scene
references, `SaveFiles`/leader paths, full save-name tooltips, current-language
display, native action callbacks and shared Theme/CSV. MainScroll follows focus
at enlarged UI/text sizes; never save a scaled Theme or regenerate the authored
page. Use sequential disposable-profile `tools/review_main_menu.py --lang en` /
`--lang ru`; read interface/validation contracts for evidence and scope.

## Field-worker activity — 5 October 2026

Hunters now play spear attacks and display their native prey load on the return
trip. Sheep handlers shear with hand-anchored tools and carry fleece; goat
handlers milk and carry a jug. Growers prune/pick vines and olives, and native
orange tenders use their own tree-working model and clips. Corral workers guide
cattle with a crook; the building's existing processing cycle follows actual
native processing. Boar/deer attack and collapse poses are connected. Work,
carry/leading phase, pause and transitions follow native observations/time;
empty hunting/livestock returns display no invented goods. Native rules, coordinates and saves
stay intact. See [field-work contracts](docs/GODOT_FIELD_WORK.md) and the validation evidence for
export sources, geometry budgets, review fixtures and remaining limits.

## Roofs lost when zoomed out (LOD guard) — 5 October 2026

At ordinary zoom-out Godot's automatic mesh LODs deleted roofs (maintenance office, hospital/infirmary and, by audit,
153 surfaces of 192 building/scenery models): the quadric simplifier treats dense shingle detail as cheap, so the first
LOD (switching error ~0.2 tile) had no roof. `scripts/lod_guard.gd` is an import script (set by `tools/apply_lod_guard.py`
in every non-character model's .import) that measures each surface's LODs with `scripts/lod_coverage.gd` (cells touched
on a grid as coarse as the LOD's own error) and, where a near LOD keeps under 60%, replaces the ladder with vertex-
clustering LODs (representative vertices only, so colours, UVs and morph targets stay valid), dropping any level that
itself fails, or keeping only Godot's sound levels. Preserve it: after changing the script or re-exporting a model run
`tools/reimport_models.sh <names...>` (Godot needs the stamp removed and the GLB touched) and gate with
`scripts/audit_lod_coverage.gd` (286 models, 0 lossy surfaces, ~10 min, non-zero exit on failure) plus
`validate_geometry.gd`. Characters are not guarded. `scripts/review_lod_roofs.gd` captures a model at several distances.

## Area demolition — 4 October 2026

The demolition tool drags a rectangle, as the SDL erase tool does: press, hold, release. A press and release on one
tile is still the single-tile demolition (`demolish`, its landmark dialog and stale-object token), so keep that path.
The core answers `preview_demolish_area x1 y1 x2 y2` (every building with a tile in the rectangle once, forest tiles,
cost, landmarks listed as protected, a token for that exact set) and `demolish_area x1 y1 x2 y2 confirmed [token]`
(`demolitionPlan` in `presentation/esimulationservice.cpp`; same ownership, fire and funds rules, never undoable).
Landmarks (palace, temples, stocked agoras) go only with `confirmed 1` and the matching token; `confirmed 0` spares them.
`scripts/road_drag.gd` draws the plan (amber for landmarks) and `main.gd` (`demolish_click`, `ask_area_demolition`)
owns the dialog, which offers Demolish / Spare landmarks / Keep. Taking an agora away uncovers its street, as natively.
Tests that inject a demolition click must send the release too (a press alone starts a drag). Gates:
`validate_area_demolition.gd` (26, headless) and the drag checks in `validate_main.gd`.

## Cart range and cart loads — 4 October 2026

Every cart that finds goods by road (producer give, processing/vendor/trireme-wharf take) searches up to 200
road steps (`numbers.txt`, `eNumbers`; avenues count 10); the old 60 left producers 82-92 steps from storage
stalled. A cart saves its own range, so the owning building re-applies the setting every tick
(`eresourcebuildingbase.cpp`, `evendor.cpp`, `eprocessingbuilding.cpp`, `etriremewharf.cpp`); keep that when
adding cart owners. Walker records of `cartTransporter` carry `cargo` (the good's model name from
`goodModelName` in `esimulationservice.cpp`, shared with the storage bays) and `cargo_count` only while loaded;
`scripts/cart_cargo.gd` fits the existing `good_<name>.glb` models into the bed of `transporter.glb` and scales
them by loads. An ox cart's marble, black marble, timber and sculptures ride the separate `trailer` walker: the core sends
`cargo` on the trailer (from the cart it follows) and `cart_cargo.gd` has a bed for each model (`BEDS`). Horse and chariot
vendor carts have no model and show an empty bed; silver is never carried.

## Adventure cards — 4 October 2026

The authored start-menu adventure page has a scrolling left library and illustrated
right card with exact native opening goals, main episode and colony-scenario counts and
an explicit sandbox badge for adventures with no goals in any episode. Keep the
shared Theme/CSV, native bitmap mapping, bounded artwork cache, responsive scroll
areas, ItemList keyboard selection and existing Start/briefing/difficulty/Begin/
editor flow. `adventure_preview` reads templates without starting/entering/saving a
city, releases its campaign and refuses calls while the core is owned. Cache by
language/kind/ref and cancel stale selections; the parent world district supplies
Atlantean wording before a city is active. Never infer sandbox from the title or
invent objectives. Read `docs/GODOT_INTERFACE.md`; use `validate_adventure_cards.gd`,
`tools/adventure_art_metadata.py --check` and sequential scratch-profile
`tools/review_adventure_cards.py --lang en` / `--lang ru`. Preserve installed art
and its existing provenance; the Anno reference is a layout reference only.


## World-map refinement — 4 October 2026

The atlas clips submerged relief at the coast and uses a 192×96 sea sphere;
current designated-world geometry is 35 meshes / 185,640 triangles (retain the
100 / 220K caps). Arrow/WASD pan, Q/E orbit and R/F tilt share the city bindings
and camera speeds, with Shift boost and modal/typing/cinematic/focus guards.
On-screen arrows still select cities. Keep native UV/height fields and stock
observations authoritative. The responsive framed toolbar is `%AtlasToolbar`;
`world_flight.gd` fades that whole surface and must keep its unique scene reference
when layout changes. Read `docs/GODOT_WORLD_ATLAS.md` and current validation.
Visible reviews run sequentially with scratch preferences and the designated save;
the reviewer foregrounds only its owned preview for captures.

## Water-life presentation — 4 October 2026

Native fish/urchin flags are appended tile column 9 (bits 1/2), feeding procedural
fish schools and spiny urchin clusters. Fishing skiffs and urchin workers use
native-action-gated authored collection clips; the diver also has bag-carry and
deposit clips. Preserve gameplay-clock transitions, UVs/VAT freshness, source
geometry/LODs, the nine earlier tile columns, terrain delta cache and bounded
surface glints/three bubbles. Use background-only asset exports; keep native art
and the live Blender scene intact. See [water-life contracts](docs/GODOT_WATER_LIFE.md).
The designated city has four native fish deposits and no urchins; reviewers use
a copied presentation-only urchin tile and temporary collectors, never an
altered save/core or live role. Run both water-life and gathering-motion gates
and visible language reviews sequentially with scratch preferences.

Current handoff: **3 October 2026**. This is the Git repository; its parent is
the local installation/art workspace. When available, read the parent
[AGENTS.md](../AGENTS.md) for detailed native-engine knowledge and art benchmarks.
Claude's additional native UI/font/screenshot notes remain in the parent
[CLAUDE.md](../CLAUDE.md). The rules below also apply to a standalone checkout.

Latest presentation slices: the compact category dock/search/model previews and
bounded inspector/decisions are implemented; read [interface contracts](docs/GODOT_INTERFACE.md).
The second interface pass uses a coloured icon dock, smaller centred model tiles,
selected/hovered context, facing buttons sharing T, native wall fill and native
cost/obstruction cursor badges. Preserve upward tray sizing, minimap preference,
pointer pass-through, exact native quotes and the shared Theme/CSV. Pier and
gatehouse facing comes from the core. Curved roads are not implemented. Use
`tools/review_interface_context.py --checks --lang en` (or `ru`) and the visual
review; do not regenerate `hud.tscn` with the old scene builder.
Focused Metal/Mobile interface gates pass 67 each in EN/RU (20 existing plus
47 context checks); native road 22, wall 63 and translation 7 also pass. These
scoped results do not clear historical broader gameplay/campaign failures.
The third interface pass adds native status/maintenance/road/staffing/housing
summaries and related-view buttons. Service panels consume the already-polled
overlay observations for counts and matching colour keys; keep quick switches
visible and avoid duplicate queries or invented coverage statistics.
`UiAccess` scales cached Theme fonts from an immutable baseline and root Window
content for independent UI/text sizes. Game → Interface options and the menu gear → Interface options
preview changes; Apply saves only interface size/text/motion keys, Cancel restores without writing.
Preserve per-user language/sound, dirty inspector drafts/tokens, camera suppression
inside the dialog, dynamic panel/card minimum sizes and native picking/timing.
Do not save the scaled Theme resource. Automation uses defaults and scratch
preferences. `tools/review_status_ui.py --checks --lang en` (or `ru`) passes
115 each (48 status/accessibility + 67 existing); `--menu` passes 17 each.
Native overlays 59, translation 7 and startup 39 pass; see the validation document
for captures, the corrected MP3/WAV test assumption and remaining limits.
**Nova reference HUD (3 October 2026):** the user's clearer Nova Roma screenshot
supersedes the Aegean shell and older bottom-right minimap layout. Preserve the
thin teal current-city stock ribbon, centred native city plaque, native jobs and
welfare shortcuts, square dock, left journal rail, bottom-left time controls and
circular minimap. The default folded map preference, exact native transformations,
heading chevron remain; the chart now covers/clips to its circle at the user’s
request rather than fitting every corner inside. Masked corners pass input through. Native objectives and selected-tool/inspection cards sit lower right,
wrapping below the header when necessary. Build trays/expanded decisions fold the
goal disclosure. The speed popup must clear its opening click at every UI scale.
Stock/employment fields are read-only observations from native caches, without
extra polling/tile scans. Retain quiet reports, one urgent alert, required callbacks,
full history, inspector drafts/tokens, translated text and independent size/motion
preferences. Art is original SVG/Theme work; no reference screenshot is embedded.
The city language/gear panel is removed; treasury/population/jobs now share the
unified resource bar. Every native resource type through silver and the food
total is shown, including zeros; balanced rows wrap rather than hide items.
Original procedural 3D model renders provide static icons without live HUD
viewports. Read the resource art contract and use `tools/review_resource_bar.py`.
Escape closes the current city window/tool first, then opens the centred game menu
with city/settings/views and language. Nested settings return one page at a time;
menu pause and command-queue hold restore their prior states. Display Escape reverts
a pending preview and closes that page. Preserve native decision callbacks. Use
`tools/review_escape_menu.py --lang en` (or `ru`).
Run visible reviews sequentially with disposable preferences. Latest counts,
captures and scoped limits are in `GODOT_VALIDATION.md`.

**Storage building goods display (4 October 2026):** warehouses (8 bays), trade posts
(15 bays), and granaries (8 radial bins in drum) dynamically display 3D stored goods
and food items on top of their yards/drums matching native simulation inventories. 20
goods models and 8 granary food models exported with vertex-palette PBR materials; MultiMesh
spatial batching; `EZeusSimulation` detects inventory changes and emits updates only when
bay quantities change. Automated test suite `validate_storage_goods.gd` passes 204/204 checks.

**Building panel (4 October):** the inspector keeps its right-hand dock (the city stays visible) and widens to
500 px for pages with tables (stores, trade posts, agoras and stalls, houses). Status is a tinted card, the readings are
chips in one row. Stores (`building_inspector.gd`) are a Stock / Orders / Limit table with goods icons and an "All goods"
row that sets the order or limit of every good; **there is no Apply button any more**: an order is sent at once, a typed
limit after 700 ms or on Enter/focus loss, drafts go one at a time, stay dirty (and keep the player's value through live
refreshes, size changes and stale tokens) until the core answers, a full command queue keeps the draft and retries after
1 s, a core refusal restores the building's own values. Trade posts work the same way. Agora and stall pages show the six
stall boxes (`inspect.agora`: stock/capacity, No vendor / No goods / Distributing); a house shows the house card
(`inspect.house`, shared `writeHouseCardFields` with the `house_card` query). New strings are in `data/ui_strings.csv`.
The road chip shows only for a building cut off from the roads. A house page is headed by the level it is
reaching (`house.target_name`, from `eHouseCard::fTargetName`), lists what is still needed first, each with how to supply
it (`inspection_summary.gd` `hint_for`), and folds the met needs below ("Already met").
`review_building_panel.gd` (18 checks, captures `building-panel-*`) and the updated `validate_inspector_ui.gd`,
`validate_trade_ui.gd`, `validate_status_ui.gd` cover it.

**Building auras (5 October):** `scripts/building_auras.gd` (+ `shaders/building_aura_column.gdshader`,
`building_aura_ground.gdshader`) draws the SDL view's per-building states: the plague over a sick house (green miasma with
flies over a pulsing stain on the ground), a blessing (golden beam, sparkles, ring) and a curse (purple wisps, red sparks).
The snapshot's `auras` (`[x, y, w, h, altitude, kind]`, 0 plague / 1 blessed / 2 cursed, sent whole on change like `fires`)
drives it; the sickness and its spread stay the engine's. `test_aura <x> <y> plague|blessed|cursed|clear` (validators only)
and `review_auras.gd` (6 checks, captures `auras-*`; `AURA_DISTANCE=34` takes them at play zoom, the marks go through the live
command queue and delta snapshots). Each marked building also has a zoom-stable badge (`building_aura_badge.gdshader`: green
ringed cross, golden star, purple slashed X; disc with a dark edge and a light outline) because the ground ring and beam
alone were too faint at play zoom. Disaster effects and the fire sound are below.

**Disaster effects and on-screen sounds (5 October):** `scripts/disaster_effects.gd` (+ `shaders/disaster_flat`, `_billboard`,
`_projectile`) draws what the engine's tile-by-tile fronts do, from the terrain changes in the delta snapshots (`main.gd` tile loop
`note`, then `flush`; `note_alert` opens the landslide window): surf and spray sweeping over land a tidal wave takes (and back),
lava blobs thrown in arcs that land in a glow and smoke, dust with falling stones over earthquake cracks, dust and tumbling
stones for a landslide (only while the engine's `landSlide` alert is recent: pyramids also change altitudes). Bounded ring-buffer
MultiMeshes, no simulation effect. The fire crackle and every other sound the native game plays only for tiles on screen
(`eGameBoard::ifVisible`: gods, monsters, archers, builders, collectors, towers) were silent in Godot because the service set no
visibility checker; it now follows the camera box that `main.gd` sends (`view_box x0 y0 x1 y1`, only when it changes, margin 3 tiles;
nothing is "on screen" until the first box). Validators-only `test_disaster earthquake|tidal|lava|landslide <x> <y>` marks the zone and
starts the engine's own front; `review_disasters.gd` (6 checks, captures `disaster-*`; it answers the city's pending decisions because a
decision blocks the simulation). Thrown arrows, spears and rocks: `scripts/thrown_shots.gd`. The engine announces each at launch from the `eMissile` constructor
(`observeMissile(this, 0)`, arrow/spear/rock only) into a bounded queue that every snapshot drains as `shots` (kind, native launch time,
speed, path points); Godot flies it along that arc in native time (path length x 40 / speed ms, so pause and game speed hold), leaves an
arrow or spear stuck for 280 ms and puffs dust where a rock lands. `test_shot arrow|spear|rock x0 y0 x1 y1` (validators only) makes the
engine's own missiles. Burning buildings are charred: `building_fires.gd` lays a soot shell (`shaders/building_char.gdshader`, the building's
own meshes via `building_placements`, which `main.gd` records at placement) that darkens over 28 s and goes with the fire; rubble is left as it
is. `review_missiles_soot.gd` passes 7 checks (captures `missiles-*`).

**Hazard alert icons (4 October):** the right-hand rail under the journal shows one button per hazard kind
(`ui/hazard_rail.gd`: fire, collapse, earthquake, flood, lava, plague, invasion, a god's attack or visit, a hero's
arrival, the army's return; the SDL `eEventWidget` list). The core's snapshot `alerts` (id, kind, tile; raised in
`eSimulationService::raiseAlert` before any wording, so silent events still alert) feeds it; each id is shown once,
same kind and place is one alert, a count shows past one, click goes to the newest site, right click puts the button
away, 12 s lapse (held while hovered). Monsters keep `monster_card.gd`. `validate_hazard_alerts.gd` passes 34 checks;
`review_hazard_alerts.gd` captures the rail. Beyond the SDL alert list the rail also covers god-made lava, sinking land and
landslides (`land`), a road cut that collapses buildings (`areaCutOff`), the invasion and monster approach warnings
(24/12/6/1 months) and the engine's risk warnings. Fire and plague are persistent: their buttons stay while buildings burn
(`fires`, ruins excluded) or houses are sick (snapshot `plague.houses/at`) and come back only after the hazard has ended if
put away (`set_persistent`). A monster already in the city keeps its own button and card. Validator now 83 checks.
Preserve the quiet journal/toast policy; alerts are additive.

**Monster combat effects (4 October):** `monster_effects.gd` draws Hydra venom and
the shared native projectile/impact pipeline for all 17 monsters. The optional
missile observer is presentation-only, empty in SDL and nonserialized; preserve
native timing, damage, collapse, sounds and RNG. Effects freeze on pause/decisions
and use two bounded MultiMeshes. Read `docs/GODOT_MONSTER_EFFECTS.md`; the native
contract passes 77, sequential EN/RU city reviews 14 each, and six seeded replay
cases match. Use `tools/review_monster_effects.py` only on the designated city with
scratch preferences. The new three-headed Godot Hydra is implemented through
`tools/godot_hydra.py`, with .64-tile paws, in-place walk/idle/fight/fight2/die,
UV2 surface semantics and three interpolated mouth anchors. Read
`docs/GODOT_MONSTER_ART.md`; preserve the native recipe and live Blender scene.
After re-export, verify both UVs, VAT freshness, flat-ground pose bounds, measured
citizen/god size and LODs. `validate_hydra.gd -- --update-hydra-baseline` edits only
that model's entry. User visual acceptance, individual art for other monsters,
slope foot IK and minimum-Mac GPU profiling remain pending.

Historical fourth interface pass (superseded layout) folds the minimap into a bottom-right City map pill
(default folded), remembers explicit visibility choices, and shows a small camera
heading chevron with a soft cyan halo. Both compass elements and the large camera
footprint highlight are removed at the user's request; Home retains overview.
Keep the native coordinate transforms and footprint observations. The chart has
no heading row and uses a small overlaid dash to fold. It stays fixed at the
bottom right when ground/building cards open; inspectors scroll above it without
resetting drafts. The Aegean pass uses separate floating time/resource groups;
keep utility/objective/notice bounds below them and the content-sized floating dock
near the bottom edge. Shared Theme variations preserve independent text scaling;
the generator must also preserve AtlasTitle/AtlasHint typography. The map folds
temporarily for trays/history/expanded decisions. Routine native news enters the
compact journal quietly; one urgent alert is visible and later alerts queue.
Missing native kind metadata retains a visible fallback. Preserve paused
hover/reading/hidden/clipped countdowns, complete history/unread semantics, exact
warning occurrence groups and stable reading Controls. Required decisions are persistent amber review
chips; folding/reading never answers them or releases the native block. Original
choice callbacks stay in main.gd. Theme/CSV and pointer pass-through contracts
remain. Quiet acknowledgements follow recording, retry with queue headroom and
never answer choices. Native kind is observation-only. Preserve inspector drafts
when the journal opens and Escape closes it. Identical catalogs reuse cards and
hover state; thumbnail viewports remain idle-disabled. Reduce interface motion
uses explicit preview/Apply/Cancel. Navy/ivory/bronze styles and original medallions
come from the Theme generator, not extracted reference art.
Use tools/review_map_notifications.py --checks --lang en (or ru): 84
focused checks plus nine retained message/log assertions each; --native-map
passes eight each. Existing status/HUD/context gates pass 115 each; translations
seven. See interface/validation docs for fixtures, captures, the existing broad
aid-regard failure and remaining visual/performance limits. Run visible reviews
sequentially with disposable preferences; do not overlap them.

Exposed land now continues into cosmetic woodland/hills and water into sea;
read [surroundings contracts](docs/GODOT_SURROUNDINGS.md). Scenery is strictly
outside native cells with no physics, navigation or build eligibility. Preserve
the exact rim profiles, indexed adaptive mesh, local deterministic noise,
800-tree cap and ocean masking over level land. `OrbitCamera.configure_map()`
owns the 1.05-map-dimension maximum; wheel/pinch and Home share these limits.
Outward wheel/pinch crossing that limit now requests the animated world atlas;
F2/world actions share the ascent, and Back/Escape returns to the exact city
pose. Home stays in the city and M keeps mute. Read
[world-flight contracts](docs/GODOT_WORLD_ATLAS.md): preserve synchronous pause,
queued-command holding, input shielding, pending decisions and hidden rendering.
Review only the designated city with `tools/review_surroundings.py`; its inland
fixture is presentation-only. Check the validation document for actual evidence
and remaining campaign/performance coverage. These replace the former visible
map cuts without extending the simulation. Further UI polish remains pending.

Display settings (3 October): Game → Display settings and start-menu gear →
Display settings select window size, desktop fullscreen, monitor, VSync and FPS
cap. The gear now opens Game settings with Display/Interface/Controls links.
`scripts/display_settings.gd` shares the earlier fullscreen key and migrates its
preference. Preserve explicit Apply → 15-second wall-clock preview → Keep;
Revert/Escape/timeout/removal restore exact window presentation without writing.
Startup loads only confirmed per-user settings. Do not change hardware display
modes, native timing, map coordinates or real preferences during reviews. Use
`tools/review_display_settings.py --lang en` (or ru, --headless for preferences):
48 scoped Metal checks each, 23 headless; controls 59, menu 17 each. Wider high-DPI/mixed-display,
platform and performance coverage remains pending. Read interface/validation docs.

**Character window (3 October 2026):** right click on a walker opens `ui/character_panel.gd` (3D model on a plinth, name, occupation, the native spoken line typed with its voice, errand, others on the tile, Go to), pausing the city. Words come from `character_info` via `engine/echaracterinfotext` (shared with the SDL window; cosmetic randomness). Use `tools/review_character_panel.py --lang en` (or `ru`): 26 checks each.

## Read before continuing

- [Godot README](godot/README.md): launch, controls, implemented scope and build.
- [Migration stages](docs/GODOT_MIGRATION.md): completed work and next gates.
- [Validation evidence](docs/GODOT_VALIDATION.md): checks and practical limits.
- [Engine/rotation architecture](docs/ENGINE_AND_ROTATION.md).
- [Production roadmap](docs/PRODUCTION_ROADMAP.md): independent content and release.

The user approved **Godot 3D presentation while preserving the C++ simulation**.
Normal launch embeds the simulation through GDExtension, with no hidden SDL
renderer or native game subprocess. The old `--legacy-bridge` adapter is an
explicit regression reference. Keep normal launch on the embedded backend.

The full saved map and 363 development GLBs are implemented. All 792 rendered
building objects and 279 initial walkers in the designated city have real models;
42 native livestock/sanctuary records render through their animals/components.
Other campaigns and visual states still need coverage. Read
[asset contracts](docs/GODOT_ASSET_COVERAGE.md) before exporting or changing mappings. Audio, specialized UI/military/campaign/save-load/settings
coverage, material/state-animation baking, seeded replay proof and standalone
production packaging remain pending. Follow the migration document's ordered
stages; update the status after each completed stage.

The Build menu lists every building the core's `buildable` query offers that has a
converted model and that the city's culture may build (46 in the test city, road included, in ten
categories: housing and roads, agriculture, industry, storage, markets, health and water,
administration and security, culture, science, gardens and monuments). Each has an
exact native preview/cost, imported ghost, demolition and undo; every native building
has a model now (a building added later without one stays hidden; `--placeholders` lists such types for
development). The quick row keeps Inspect, Road, Housing and Demolish. Live storage inspectors include native orders
and limits; production inspectors include inputs/outputs and city-wide industry
shutdown/resume. Preserve native workforce semantics and weak-reference tokens
against stale actions. New square-building facing is session-only; serialization,
rectangular facing, remaining tools/drag roads and the vendor stall inspectors
are pending. Numeric edits must suppress camera keys and survive refresh.
See the updated README and validation document before adding more presentation.

The user prioritized terrain realism next. Continuous ground materials, sandy
wet banks, a shared coast contour and shallow-to-deep calm water are implemented.
Forests use native forest bit 16 (not fertile bit 8); the latest map review adds
independent procedural olive-style/cypress canopies, leaf geometry, wind and reduced
mesh LODs. Old tree GLBs and native SDL assets remain intact.
Continuous elevation profiles, road ramps and limestone cliff/outer-edge sides
are implemented with shared lighting normals. Read [terrain contracts](docs/GODOT_TERRAIN.md)
before continuing. Snapshots append read-only geometry flags/character height
after their original six tile columns. Presentation picking, walker feet and
placement previews follow the generated surface; foundations retain native heights.
Native terrain/resources, pathfinding, eligibility, routes and 20 Hz timing stay
authoritative; irregular map holes stay empty. Flat road/material edits must not
rebuild collision. Native mineral outcrops, continuous mineral soil and forest-edge
grass/shrubs are now implemented in `terrain_details.gd`, separate from the 240
GLBs and independent trees. Since 3 October each deposit kind has its own Blender
model (`tools/godot_mineral_outcrops.py` → `assets/terrain/mineral_outcrops.glb`),
`outcrop.gdshader` response and ground soil/pattern, so stone, copper, marble and
orichalcum no longer look alike; re-export and `--import` after editing the script.
The ground is green now: board and countryside share `shaders/terrain_palette.gdshaderinc`
(meadow, scrub, forest floor, lusher fertile land), and `scripts/map_border.gd` draws a
dashed Cities: Skylines-style border just inside the native board edge; everything outside it is
tinted darker (`shaders/map_outside.gdshaderinc`, shader globals `map_border_*`).
Water and the sea share `shaders/water_surface.gdshaderinc` (depth colour, ripples, sky reflection,
foam); a low-pass `coast_distance()` smooths shore teeth; banks vary in width with wet sand.
Roads pave their whole tile with kerbs; `scripts/walker_streets.gd` draws people 12% larger, in
right-hand lanes on roads (presentation only), and rings the hovered person.
Buildings step back 0.12 tile from roads (`street_setback.gd`); snapshot tile column 8 is the road
kind (avenue 2, boulevard 3), drawn with dressed paving, planted medians and street trees (`terrain_avenues.gd`).
Buildings turn their front (door, or the kits' dressed +X/+Y corner) to the longest adjacent road
(`street_facing.gd`, presentation only); T breaks ties, so it picks the street when roads surround a building.
Objectives panel (3 October): the `episode` query adds per goal `kind`, `current`, `required` and, for an unmet
housing goal, `housing` (houses below the level by level, their people, and per need how many houses lack it, from
`eHouseNeeds`). `ui/objective_card.gd` draws a card per goal (icon, bar with the count or the core's status, need chips
with advice tooltips); `ui/objective_wreath.gd` is a 3D gold laurel in the header whose leaves grow with the share met
and which turns once when a goal is met. Styles are the theme's `Objective*` variations; `--objectives-review <name>`.
Gold HUD (4 October): every HUD surface now uses the objectives panel's look. `build_ui_theme.gd` has `gold_frame()`
(lapis, gold rim, rounded corners, soft shadow) and `gold_face()` (button rest/hover/chosen), and the slim teal "Nova Roma"
frames are gone. Categories are round gold medallions; tools and build cards are gold tiles; progress bars are gold.
The minimap draws a gold rim from the theme's `MapCard` `rim`/`rim_shadow` colours. `--objectives-review` also
captures the inspector with the minimap, the build tray and the message log.
Dialogs and the escape menu match it: embedded windows use a gold frame grown upward by the title height
(`expand_margin_top` = `title_height` 40, so the title and close cross sit inside it; Godot draws `embedded_border` under the
content only), a 3 px gold top line, pale-gold bold titles, and a content panel with no second border. The escape menu
uses `EscapeHeading`, `EscapeRule` and `EscapeAction`, with Primary for "Return to city". `review_escape_menu.gd` captures
every dialog it opens (`captures/escape-dialog-<action>-<lang>.png`).
A dialog's OK button is Primary (set where `hud.gd` attaches RightClickBack to each Window), and the decision card and
`EnvoyAction` buttons use the gold frame and faces. `--street-review <save copy>` opens a COPY of a save from a scratch
folder (used as the save directory), pauses, and captures its densest blocks of houses (`captures/street-*.png`) to
judge `street_facing.gd`; never point it at a player's own save folder. The initial city has 3,746 detail instances in 239 spatial
batches. Preserve native flags, foundation/road/field/water buffers, height anchors,
per-section caps and distance fading; props have no collision or native RNG.
Resource ground inspectors identify deposits in EN/RU. Construction, undo and
forest clearing refresh detail and neighbor habitat. Missing legacy foundation
metadata conservatively disables new props. Read the terrain source manifest and
contracts before extending the catalog. The map review also fixes missing native
bridges (57 water-road cells, 20 shore approaches) and a half-tile walker offset.
Subtract 0.5 once from native absolute walker X/Y for integer-centered Godot tiles;
never rewrite native positions. Pedestrians sample deck/approach heights; boats
keep native water height. Crossing picking collision is separate from terrain
and does not change native rules. Forests have 3,138 trees in 182 batches; use
`terrain_forest.gd` and `terrain_bridges.gd`, with their source manifest.
**Next terrain work: additional species/bridge topology, LOD/occlusion profiling
and wider native campaign coverage.** Terrain fields pass 18 checks, elevation
geometry 22, details 31, map review 16 and visible EN/RU runs 182 each; the complete
current regression set passes 900. Half-slope and absent
mineral-kind tests are presentation/geometry checks only; minimum-hardware
performance remains an open gate.

The eight garden GLBs now use `tools/godot_garden_foliage.py` for branching
cypresses/pines, folded leaves, vine coverage, clipped topiary and flowering stems.
All 178 native garden placements retain their footprints. `RECIPES['park']` selects
the real 1x1 pine/bench module; do not restore the shrunken 3x3 tholos on 164 parks.
Keep per-asset foliage budgets, double-sided palette batching and adapter provenance.
Export only in disposable background Blender; native sprite recipes/live scenes
remain intact. Garden wind, more variants and material baking remain pending.
The new garden contract passes 26 checks; read the final validation evidence before
claiming broader performance or campaign coverage.

## Architecture and controls

Building work animation is now connected for 35 authored types. Read
[building activity contracts](docs/GODOT_BUILDING_ACTIVITY.md): preserve native
`working`/`workers`/phase observations and gameplay-time clock, GPU work/inactive
poses, static/dynamic spatial batches, per-asset geometry tiers, original-model
SHA freshness fallback and source-write guards. Keep pause/decision/speed semantics
and incremental rebuilds. Export through `tools/export_building_activity.py` in
background Blender, then import and run `validate_building_activity.gd` and the
visible reviewer. This does not extend the physician art benchmark to on-site
workers; inventory/rower/full-state coverage still remains pending.

The first natural people pass covers all 31 existing human walker GLBs.
Read `docs/GODOT_CHARACTER_ART.md`: the Godot-only adapter preserves distinct
anatomy, painted skin, fitted hair, female/child proportions and sampled gaits.
The philosopher's blue wrapped himation follows the user's clothing reference.
Keep `CityPalette` and both UV sets (rest coordinates/surface type/person index),
face/hand allocations, three-or-fewer mesh groups, geometry caps and imported LODs.
Stage exports with `tools/export_character_assets.py`; optimize duplicate morph
targets and prove losslessness with `verify_glb_optimization.py --require-uv`.
Validate characters and compare `--character-review before/after` captures.
Gods get designed faces from `tools/godot_god_face.py` (3 October; Hades first, called from
`godot_hades_art.py`): sculpted head, baked occlusion and painted features in the vertex palette, real eyeballs,
brows, a strand-card beard and a hairline cap. The exporter sees a 169K-vertex body, so shells are thinned and the
`PROTECTED` parts bypass the simplifier and count against the god's budget (Hades 19,000). Preview with
`tools/preview_god_face.py`, judge in Godot (`--character-review after --character-subjects walker_<god>`, which has a
straight-on `portrait` and a `city-closest` view), and re-record only that god's geometry baseline. The player's
closest zoom is `MINIMUM_DISTANCE` (ten tiles) in `orbit_camera.gd`; reviewers and validators may still set `distance`.
The fourteen gods float (3 October): `tools/godot_god_float.py` makes their held pose a hover in the export (24
identical walk samples, a twelve-frame idle drift; never edit `art/characters/people`), and `scripts/god_float.gd`
gives them hover, bob, lean, sway and a slow turn from `main.gd` (`animate_walker`, the heading); keep it presentation
only. Re-export all gods together if the kit changes, and check with `validate_locomotion.gd` and the character review.
Embedded building workers/rowers, full texture baking and facial/work/death/cargo
motion remain pending; do not claim those are complete or clear provenance.

- `presentation/esimulationservice.*` owns the native campaign/board;
  `presentation/godot/` binds `EZeusSimulation` into Godot.
- `engine/esimulationstep.*` shares the original tick sequence with the SDL
  reference. Preserve the 20 Hz/50 ms accumulator and native speed semantics.
  Economy, pathfinding, production and decisions remain in C++; camera yaw must
  never rotate or rewrite simulation coordinates.
- `godot/scripts/core_link.gd` supplies direct calls and snapshots. JSON conversion
  is still inside the process; snapshot IDs are session IDs, not durable IDs.
- `godot/scripts/orbit_camera.gd` implements physical-key **Q/E continuous 360°
  orbit**, **R/F tilt (25–75°)**, WASD pan, Shift boost, cursor zoom (closest view ten tiles, `MINIMUM_DISTANCE` in `orbit_camera.gd`, player input only) and middle-drag
  yaw/tilt. `scripts/main.gd` binds actions; **T** rotates the placement preview,
  **Home** fits the city, **Space** pauses, **Escape** returns to inspection.
  **X/Delete** selects demolition; **Ctrl/Cmd+Z** undoes the last construction.
- Native SDL controls differ: Q/E change among four directional views, R rotates
  placement and default C clones a building. Preserve custom-binding migration.
- Retain original event callbacks and pending decisions. Do not silently invent
  outcomes for military/campaign interfaces awaiting migration. Preserve EN/RU.

## Panel-only elder curator reference — 4 October 2026

Read [GODOT_PORTRAIT_REFERENCE.md](docs/GODOT_PORTRAIT_REFERENCE.md) before further
portrait work. The user requested one older, more realistic character only in the
Character panel. `tools/godot_curator_portrait.py` builds the 68-year-old curator
(`elder_curator_portrait_v2`); it replaces the rejected thick curls with fine
surface-sampled fibers and corrects face landmarks. Portrait finish, full mesh
quality, 1.5× render scale and framing are isolated to the panel. Keep native
words/voice, city crowd assets and the physician benchmark intact. The one-model
budget is 600K vertices/40 MiB, not a walker budget. Rebuild only `walker_curator`
with `godot_portrait_export.py`, run `validate_curator_portrait.py` and sequential
EN/RU `review_character_panel.py` reviews. User visual acceptance remains pending;
do not call it production-approved or roll it across the catalog automatically.

## Character art review status — 30 September 2026

The user rejected `natural_people_v1` as still doll-like. Treat the 31 updated
human assets as technical prototypes, not accepted production art. Read the
revised one-citizen benchmark plan in `docs/GODOT_CHARACTER_ART.md`: proper texture
UVs/PBR maps, anatomy/eyes/hair/garments, a runtime skeleton and natural idle/walk
motion. Verify the result in the actual city before another catalog rollout.
Existing check counts do not prove visual realism.

Later session: the benchmark is built and integrated, awaiting the user's visual review.
`assets/characters/physician_v2/physician.glb` (30K vertices, VRAM-compressed textures,
137 bones, Idle/Walk, blink shapes; `tools/build_citizen_benchmark.py`) is shown near the
camera by `scripts/skeletal_citizen.gd`; every physician is drawn by the baked 6K-vertex
crowd twin `physician_crowd` and `scripts/citizen_lod.gd` swaps the nearest 24 within 9
units to a pooled skeletal citizen with the same clock. Contracts: seek Walk by cycle
fraction (`walk_time`), never multiply a skinned
mesh's bounds by node scale, keep textures VRAM-compressed (`tools/configure_citizen_textures.py <folder>`),
and rebuild with the workflow in `docs/GODOT_CHARACTER_ART.md`. `validate_citizen.gd` (36
checks originally; 38 after the gait refinement) gates it. Do not roll the pipeline out to other roles until the user accepts the
benchmark in the real city. Forward+ was measured (about 1.5x frame time, +50 MB) and stays
an experiment; Mobile is the renderer. The himation is now a cloth-simulated drape over the left
shoulder (`CITIZEN_MANTLE`, preview with `CITIZEN_PREVIEW`; the simulation is sensitive, see the
character document). Known gaps: frayed hem, pale eyes, and the native `disgruntled` walker has no
model (`validate_city_coverage.gd` flakes on it).

Walking refinement (1 October): `walker_motion.gd` blends human starts/stops and
smooths shortest-path turns; gait phase uses horizontal native displacement before
surface-height correction. Keep VAT/fallback normalized alias weights and exact
transition weight/phase across citizen LOD swaps. The physician's `contact_roll_v1`
adds support/heel/toe/swing/weight/counter-motion in `tools/citizen_gait.py`; it
retains the 0.64-tile stride, 24/12 crowd samples and existing geometry budgets.
Export bone clips from time zero (`export_anim_slide_to_zero=True`), at 100 Hz;
`configure_citizen_textures.py` preserves the manifest's bone import rate. Current
periods are 0.64/3.0 seconds, fixing the older 0.66-second import/initial hold.
Run `test_citizen_gait.py`, `validate_locomotion.gd`, `validate_citizen.gd` and
the continuous city reviewer after changes. The reviewer uses a temporary physician
on a native transporter route if the designated city has no physician. Never
change the live role mapping to make that review pass. Other roles' new cycles,
foot IK on slopes, building-worker art and visual approval remain pending.

## Build and verify

Commands run from this directory:

```sh
./tools/build_godot_extension.sh
python3 tools/run_godot_pilot.py --validate --lang en
python3 tools/run_godot_pilot.py --validate --lang ru
python3 tools/run_godot_pilot.py --terrain-review after
python3 tools/run_godot_pilot.py --terrain-review elevation-after
python3 tools/run_godot_pilot.py --terrain-review detail-after
python3 tools/run_godot_pilot.py --garden-review after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/garden-contract-engine.log" --path godot --script res://scripts/validate_gardens.gd
python3 tools/run_godot_pilot.py --terrain-review polish-after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/polish-contract-engine.log" --path godot --script res://scripts/validate_map_polish.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/terrain-engine.log" --path godot --script res://scripts/validate_terrain.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/elevation-engine.log" --path godot --script res://scripts/validate_elevation.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/detail-engine.log" --path godot --script res://scripts/validate_details.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/embedded-engine.log" --path godot --script res://scripts/validate_embedded.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/assets-engine.log" --path godot --script res://scripts/validate_assets.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/construction-engine.log" --path godot --script res://scripts/validate_construction.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/industry-engine.log" --path godot --script res://scripts/validate_industry.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/coverage-engine.log" --path godot --script res://scripts/validate_city_coverage.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/geometry-engine.log" --path godot --script res://scripts/validate_geometry.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/poses-engine.log" --path godot --script res://scripts/validate_poses.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/citizen-engine.log" --path godot --script res://scripts/validate_citizen.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/replay-engine.log" --path godot --script res://scripts/validate_replay.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/ui-text-engine.log" --path godot --script res://scripts/validate_ui_text.gd
python3 tools/replay_parity.py
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/roads-engine.log" --path godot --script res://scripts/validate_roads.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/saves-engine.log" --path godot --script res://scripts/validate_saves.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/load-engine.log" --path godot --script res://scripts/validate_load.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/adventures-engine.log" --path godot --script res://scripts/validate_adventures.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/start-engine.log" --path godot --script res://scripts/validate_start.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/overlays-engine.log" --path godot --script res://scripts/validate_overlays.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/audio-engine.log" --path godot --script res://scripts/validate_audio.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/campaign-engine.log" --path godot --script res://scripts/validate_campaign.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/campaign-ui-engine.log" --path godot --script res://scripts/validate_campaign_ui.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/trade-engine.log" --path godot --script res://scripts/validate_trade.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/trade-ui-engine.log" --path godot --script res://scripts/validate_trade_ui.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/buildings-engine.log" --path godot --script res://scripts/validate_buildings.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/walls-engine.log" --path godot --script res://scripts/validate_walls.gd
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/housing-engine.log" --path godot --script res://scripts/validate_housing.gd
python3 tools/save_roundtrip.py
```

Performance contracts (measured 30 September 2026; see the validation document): keep
delta snapshots free of per-tile eligibility scans and unchanged building lists, keep
`buildings_changed` gating and incremental batch rebuilds, never read model manifests
per building, and keep two shadow cascades and the 3-pixel mesh LOD threshold unless a
new measurement justifies a change. New models need a LOD ladder and a
`--write-baseline` entry in `data/geometry_baseline.json`. Startup contracts: the embedded
backend must not fully decode sprite images (only their size), model GLBs are requested on
worker threads before terrain is built and joined at once (`building_batches.gd` `join()`: the main thread
waits, so no loading thread sets up a BaseMaterial3D while a frame renders; every load is collected into
`loaded`, released with the node; an uncollected threaded load outlives the renderer and crashes or floods
`Parameter "material" is null` at exit; never leave a `load_threaded_request` uncollected), and exported walkers must go through
`tools/optimize_glb_memory.py` (then import and `tools/verify_glb_optimization.py`). Never
drop UVs to save memory (it stripped foliage LODs), and resolve `idle_00|idle_01` style shape
names through `morph_table` in `main.gd`. Animated models are baked by `tools/bake_walker_vat.py`
into `models/runtime/` (never edit sources for it; keep UV and UV2 free for character
shaders); a custom shader adopts poses with `walker_vat.gdshaderinc` or by not defining its own
`vertex()`, and after any walker re-export run the tool, import, and `validate_poses.gd`.
Keep `limits/global_shader_variables/buffer_size` large enough for the crowd (4,096 animated
parts per 65,536).

Foundation contracts (1 October 2026; evidence in the validation document). **Interface:** all text is `tr("English source")`
from `godot/data/ui_strings.csv` (never inline language pairs or a language flag; add a column for a language, import, and register
the new `.translation` in project.godot; `validate_ui_text.gd` gates it); style comes only from `ui/lapis_gold.tres`
(`scripts/build_ui_theme.gd`) and layout from the scene `ui/hud.tscn` (edit it as a scene, do not rerun
`build_hud_scene.gd` over edits); players never see developer telemetry (F3 overlay only); new windowed checks go in
`validate_main.gd`, not `main.gd`. **Camera:** the orbit centre follows the terrain through `orbit.ground_height`; keep
`terrain_point`/`snap_to_ground` and never reanchor on y = 0. **Simulation reproducibility:** never call `eRand` from a worker
thread (path-search filters use `eRand::searchCoin(salt, x, y)` with a salt drawn on the game thread); after any C++
change to simulation code run `tools/replay_parity.py` (rebuild and sign `Bin/eZeus` first) and `validate_replay.gd`.
Trade: a trade post belongs to one partner city. The partners offered are the SDL build panel's list (`engine/etradepartners.*`, shared
with it): not a rival or an enemy, active and visible, something to trade, no post yet. A land partner takes a 4x4 `trade_post`, a sea partner
a `pier` (a 2x2 pier on a shore tile whose water leads to the sea, with its 4x4 trade post on the land behind it; the rules live in
`engine/eshoreplacement.*`, shared with the SDL widget, along with the fishery's shore rule). `preview`/`build` take the partner as a fifth
number (its index in the world's city list); a pier's (x, y) is its first tile. Both are charged as a trade post; a post is removed with its
pier, and a freed partner returns to the list one simulation step after the removal (the menu asks again after 1.5 s). `trade_partners` lists
every candidate with its goods and prices, `inspect` gives a post a `trade` object (imports the partner sells, exports it buys, stock, price,
this year's use of the partner's limit, the stock to keep), and `trade x y token resource direction enabled quota` edits it (quotas follow the
storage steps). The Build menu's Trade category is built from the partner list (items "pier:3" / "trade_post:3"); the pointer snaps a pier to a
fitting shore tile within two tiles; Game, Trade partners… shows the partners and their goods. Traders and their donkeys, and trade ships, are
the native walkers.
Elite housing and area drags: `elite_house` is a 4x4 `buildSpecs` row (`eEliteHousing`, charged as the native mansion) shown as `elite_house_<level 0-4><a|b>`, the
variant chosen by the building's seed as the SDL view does (a vacant plot and Atlantean cities use the same set; the remastered estates are
`art/elite_house_<level><a|b>`, exported by name through the generic `art/<name>/build_sprites.py` fallback of `export_godot_pilot.py`). Common housing, elite
housing and parks are dragged over an area with `preview_area name x1 y1 x2 y2` / `build_area name x1 y1 x2 y2 orientation`: houses in 2x2 and
mansions in 4x4 steps from the pressed tile toward the released one (columns, then rows, the SDL order), parks on every tile of the rectangle, each plot
built or skipped on its own with the usual reasons, stop at 1000 drachmas of debt, one undo step, at most 3,000 plots listed (counts stay exact). The
plan carries the model name; `road_drag.gd` (now the drag tool for road, wall and the area tools, `AREA_TOOLS`) draws one flat plate per plot and the
real model for the first few (`MODEL_LIMIT`: a mansion has ~63,000 triangles). A click without moving is a one-plot drag. While a test drives a drag
(`road_drag.guard` false) `main.gd` no longer lets the real mouse move its end.
World map: the `world` query reports the map picture (`image`, a file of `Textures/Zeus_Data_Images` beside the repository), the player's cities with their stock of
giftable goods (`mine`, each good with its gift step), the cities on the map (`cities`: kind, relationship, nationality, position as fractions of the picture, regard 0 to 100 and
its native name, goods sold and bought with prices, tribute, and flags `can_request`, `regarded`, `can_gift`, `can_fulfil`, and the military ones below) and the pending
requests (`requests`: the city, the goods, and the player's cities that can fill them). Three commands act, each answering with the new `world`: `world_request <city> <resource> <own city>`
(not for a distant city, the city played or a colony or neutral city on the board; refused while the regard is 50 or less unless the city is a rival; only what the city sells or
drachmas; every city on the map then loses 10 regard and the asked city 10 more, as `eGameBoard::request` does, and the event answers in 90 days), `world_gift <city> <resource> <count> <own city>`
(a whole number of steps, one to three, of the good's base size; the goods leave the city at once, the regard rises when the gift arrives 90 days later) and `world_fulfil <request> <own city>`.
The military dealings (raid, conquest, aid, strike) are described next. `test_request` (validators only) registers a city's request. The scene is `ui/world_map.tscn` (generated once by `scripts/build_world_map_scene.gd`,
then edited as a scene) with `ui/world_map.gd` and the marker control `ui/world_marker.gd`; `main.gd` holds the city while it is open (`open_world` / `close_world`, F2).
Army: the soldiers' companies are the engine's banners (`eSoldierBanner`, at most `per_banner` = 8 soldiers each, kept at the palace while at home). Housing supplies the soldiers by the engine's own
rules (`eBoardCity::updateMaxSoldiers`, every 1000 time units): common houses of level 2 and above send rock throwers (archers in an Atlantean city), elite houses of level 2 and above hoplites (they need arms) and, at level 4 with horses, horsemen
(chariots in an Atlantean city), up to the 20 places of the palace. The `army` query reports `palace`, `capacity`, `per_banner`, the soldier totals (`hoplites`, `horsemen`, `rabble`) and `banners` (`id`, `city`,
`type` one of hoplite, horseman, rock_thrower, amazon, ares_warrior, `name` and `kind_name` in the core's language, `count`, `placed` with the tile `x`,`y` (tiles can be negative), `home`, `abroad`, `aid`,
`fighting`, `atlantean`). A full snapshot always carries `banners`; a delta carries them only when the list changed, and the presentation keeps the last list. Orders answer with `army`: `army_call` / `army_home` (every company in the
city, through `bannersBackFromHome` / `bannersGoHome`), `banner_call <id>` / `banner_home <id>`, and `banner_move <id> <x> <y>` (the banner goes to the tile or the nearest free walkable one, as the SDL right
click does through `eSoldierBanner::sPlace`; refused: `unknown_banner`, `banner_abroad`, `out_of_map`, `other_district`, `no_room`, `pending_decision`). Calling a company out creates its soldiers at once, at the
house that supplies them (`eSoldierAction::sFindHome`), so a company whose houses do not exist sends nobody out (the test city has no elite houses: its hoplite and horseman companies stay at the palace). The orders first settle
finished path tasks and discarded characters (`settle()`), as the tick does: a soldier sent home straight after being called out is a tile-less husk until the next tick, and calling its company out again
inside that window dereferenced its null tile (a crash found by `validate_army.gd`, avoided in the service, not changed in the shared engine). Soldier walkers: the player's soldiers use `walker_hoplite`, `walker_horseman` and `walker_rockthrower` (the Roman army of the Greek cities, as in the SDL view) or `walker_hopliteposeidon`, `walker_chariotposeidon` and `walker_archerposeidon`
(the guard of the Poseidon cities); the test city is Atlantean, so a Greek call-out is checked only through the models. Amazon and Ares warrior companies use `walker_amazonspear`, `walker_amazonarcher` and `walker_areswarrior`. `test_soldiers <hoplite|horseman|rock_thrower> <n>` (validators only) adds soldiers to the companies; the housing redistributes them within a few game seconds. The panel is `ui/army_panel.tscn`
(generated once by `scripts/build_army_panel_scene.gd`, then edited as a scene) with `ui/army_panel.gd`, in the inspector's slot; `scripts/army_view.gd` draws a flag (pole, gold finial, waving cloth in the kind's colour) on
each placed banner and a gold ring on the chosen one. `main.gd`: Game, Army… or F4 opens the panel; a left click on a flag chooses its company; the right button (with a company chosen) or the panel's Place banner button then
a click moves it; clicking elsewhere inspects and closes the panel; Escape cancels a placement, then closes the panel. Fighting and the world map's military dealings are described next.
Fighting: every character type of an army has a model, chosen in `walkerAsset` by type: the player's soldiers (above), the armies abroad and allied (`greekHoplite`/`greekHorseman`/`greekRockThrower` to `walker_greekhoplite` and so on), and the invading
nationalities (`trojan*`, `centaur*`, `persian*`, `oceanid*`, `egyptian*`, `atlantean*`, `phoenician*`, `mayan*`, and the `amazon` with its `isArcher` flag), 25 enemy models in all; the fourteen gods (`walker_aphrodite`, `walker_apollo` ... `walker_zeus`) and the heroes
(`walker_achilles` ... `walker_theseus`, `walker_bellerophon` on Pegasus) too. The seventeen monsters have models too (see "Monsters" below). Each of those 55 models carries the people kit's combat clips as shape keys next to `walk_NN` and `idle_NN`: `fight_NN`, `fight2_NN` (a slinger's
cast), `die_NN`, and for the gods `bless_NN`, `disappear_NN`, `appear_NN` (written by `tools/export_godot_pilot.py` from the identity's `STATES`; the lists `COMBAT` and `MOUNTED` in `tools/godot_asset_sources.py` say which models get clips and which carry a horse and so a larger vertex allowance), and `bake_walker_vat.py` turns them into poses.
Props that the walk puts away (a sword, a club, a thrown stone) are part of the model: their rest geometry comes from the first clip frame that shows them and the poses that hide them fold them to a point inside the body. The snapshot's walker `action` (4 fight, 5 fight2,
6 die, 15 appear, 16 disappear, 17 bless, 18 curse) picks the clip in `scripts/walker_combat.gd`: fight, bless and curse loop at 10 frames a second, die plays once in a second and holds its last frame until the core removes the corpse (2048 time units, under two seconds at top speed), disappear and appear play once
(appear is the disappear clip backwards for a god without its own), and a fighting walker turns to the core's `orientation`. Models without clips keep walking and standing as before. While an enemy force is in the city every snapshot carries `invasion: true` and `invaders` (soldiers of an enemy team alive in the
city; `army` reports the same) and `main.gd` shows them in a red notice (`ui/invasion_banner.gd`); the notice also has a "Go to the invaders" button (the snapshot's `invader_at` is the tile of the invader nearest their middle). The engine defends by itself only for computer-controlled cities (`eBoardCity::updateCityDefense` runs for `!p->isPerson()`): a human player's army stays at home until ordered, so the player calls the companies out and sends their banners to the invasion with the army panel (`validate_fight.gd`
checks that archers called out and sent to the invaders do come out and fight). The invasion's decision (surrender, bribe, fight) was already a decision message with its buttons. `test_invasion <nationality> <infantry> <cavalry> <archers>` (validators only) lands a force of a nationality (greek, trojan, persian, centaur, amazon, egyptian, mayan, phoenician, oceanid, atlantean) at the city's entry point through the engine's own `eInvasionHandler`, with an `eInvasionEvent` that is scheduled ten
years ahead, and a hostile team (`neutralAggresive`), because the test world has only allies. Not ported: any health or damage display (the troop request and the armies abroad are in the military dealings below; monsters follow them).
Military dealings: the SDL world menu's rules are in the `world` query: per city `can_raid` (not a vassal, colony, distant city, a city on the board, or the city played), `can_conquer` (not a distant city, the city played or a neutral one on the board, nor a vassal or colony unless a rival conquered it; for the player's own cities on a board with
several it means reinforcements, `reinforce` true), `aid` (`""` when nothing can be asked, else `not_regarded` at a regard of 65 or less, `cant_spare` below two shields, `present` while its aid is with the city, `ok`), `troops` and `shields` (1 to 5, `1 + troops/20`); the top level adds `rivals` (city indices), `armies` and `enlisting`.
`armies` are the army events on the road (`reason` raid, conquest, help or home, `from`, `to`, `frac` of the way, `size` 0 to 3, `heroes`). A raid or a conquest does not send anything by itself: `world_raid <city>` and `world_conquer <city>` ask the engine for the forces (`eGameBoard::requestForces`, whose front-end hook the service sets) and keep the request as a session; the `enlist` query lists it
(`purpose` raid, conquer, reinforce or troops, the player's `cities`, `soldiers` companies of hoplites, horsemen, amazons and Ares warriors with their `abroad` flag, `heroes` whose halls have their hero, `allies` whose troops may go along, the `plunder` a raid may ask for, `target`), and `enlist_dispatch <plunder resource or -1> [s:<banner ids>] [h:<city>:<hero>,...] [a:<ally city index>]`
sends the choice as the SDL dialog does (`enlistForces`, then the engine's own `ePlayerRaidEvent`, `ePlayerConquestEvent` or `eReinforcementsEvent`, due after `eNumbers::sArmyTravelTime` or `sReinforcementsTravelTime` days); refused: `no_forces` (nothing without a company or a hero), `not_enlistable`, `already_abroad`, `one_ally_only`, `not_offered`, `invalid_enlistment`, `no_enlistment`; `enlist_cancel` drops the session.
The outcome is the engine's: a raid is paid if the army's strength exceeds 0.75 of the city's troops, a conquest wins if it exceeds them (and the city is not at the top military strength), the armies lose a share of their soldiers, attacking an ally costs every ally's trust (a message says so), the army comes home after the same time and its companies walk in at the entry point. `world_aid <city> <own city>` requests defensive aid
(refused as `aid` says; every city's regard falls by 10 and the asked city's by 10 more, and a third of the city's troops arrive about a month later as companies of its own) and `world_strike <city> <rival>` a military strike (30 days). A troop request (`eTroopsRequestEvent`) is a decision whose "send troops" choice has `choice` -2: `event <id> -2` opens the same enlisting (`purpose` troops, `event` the request)
and dispatching it removes the request and sends the help (`help` army). `test_relationship`, `test_attitude`, `test_troops` and `test_troops_request <asked city> <attacking city>` (validators only) set up the test world, which has only allies. The service also words the two placeholders the SDL message box fills itself, `[time_allotted]` and `[travel_time]`.
The Godot side: `ui/enlist_dialog.gd` (the dialog: companies by kind, heroes, allied troops with one city at a time, Enlist all, Clear, Send, Cancel, a plunder chooser for a raid, a city switch when the player has several), `ui/world_armies.gd` (the armies on the map: dashed road, a disc at `frac` with a head and a pip per size step), the Raid, Conquer or Reinforce and Aid buttons of `ui/world_map.gd`
(Aid also offers the strike when a rival exists), and `main.gd` (the "send troops" button of the decision opens the dialog over the city). Not ported: the Ares god as a separate choice (the SDL dialog's rows do not list it), conquest of a city that is on the board (the engine then fights in that city, which the view does not show; not tried), and any display of strengths.
Monsters: all seventeen of the engine's `eMonsterType`s have a model, chosen in `walkerAsset` by character type (`walker_calydonianboar`, `walker_cerberus`, `walker_chimera`, `walker_cyclops`, `walker_dragon`, `walker_echidna`, `walker_harpies`, `walker_hector`, `walker_hydra`, `walker_kraken`, `walker_maenads`, `walker_medusa`, `walker_minotaur`, `walker_scylla`, `walker_sphinx`, `walker_talos`, `walker_satyr`),
with the same `fight_NN`, `fight2_NN` and `die_NN` clips as the soldiers (`COMBAT` in `tools/godot_asset_sources.py`; `walker_combat.gd` plays them unchanged). Eight have a human body from the people kit and take the human adapter (`MONSTER_PEOPLE`: cyclops, talos, hector, minotaur, satyr, medusa, maenads, harpies; the harpies hover about half a metre above the ground, and `validate_characters.gd` expects that);
nine are creatures from the animal kit (`MONSTER_BEASTS`, exported by the `CREATURES` path of `tools/export_godot_pilot.py`: no human adapter, 32,000 vertices at most, the kit's per-point `Coat colour` carried as the vertex palette so a Cerberus is black and not white). The snapshot says while a monster is loose in the city `monsters` (how many), `monster` (the first one's name, from the SDL string table, so it follows the language) and
`monster_at` (its tile); `army` carries `monsters` too. `main.gd` shows them with a red button in the rail under the journal and its card (`ui/monster_card.gd`, from the core's `monster_info`: the monster's own message, its slaying hero, the hall's state, Go / Build / Show buttons); the top notice (`ui/invasion_banner.gd`) is for invaders only. The snapshot's `buildable_revision` moves whenever the engine changes what may be built (a monster or quest allowing a hall); `main.gd` then refreshes the Build menu. The monster's own behaviour is the engine's (`eMonsterAction`: it waits, goes out to attack, patrols, goes back; the kraken and Scylla roam the deep water, the others the roads); the music turns to battle while one is out,
as it does in the SDL game. `test_monster <kind>` (validators only; `calydonian_boar`, `cerberus`, `chimera`, `cyclops`, `dragon`, `echidna`, `harpies`, `hector`, `hydra`, `kraken`, `maenads`, `medusa`, `minotaur`, `scylla`, `sphinx`, `talos`, `satyr`) lets one loose the way a monster event does (`eMonster::sCreateMonster`, `registerMonster`, the aggressive neutral team, an aggressive `eMonsterAction`):
at the entry point, or in the deep water nearest to it for the kraken and Scylla. Not ported: a monster's health or the damage it takes (the engine gives a monster none: only a hero can slay one, see Heroes below) and the god-sent timeline of a campaign beyond what the engine does by itself.
Heroes: the eight heroes' halls are `buildSpecs` rows (`hero_hall_achilles` ... `hero_hall_theseus`, 4x4, built through `buildBase` and then recorded with `eGameBoard::built`, as the SDL view does, so a hero has one hall) under the Build menu's "Heroes' halls" heading (`build_catalog.gd`; the dock's icon is `ui/icons/heroes.svg`). A hall is offered only when the scenario allows its hero: a god's quest (`eGodQuestEvent::trigger`) calls the engine's `allowHero` and says so in a message ("Perseus' Hall"). Each has a model (`art/hero_hall/build_sprites.py --hero <name>`, a Roman heroon with the hero's colours and statue; `RECIPES` in `tools/godot_asset_sources.py`).
The inspection of a hall carries `hall`: `hero`, `hero_name`, `stage` (`none`, `summoned`, `arrived`), `on_quest`, `can_summon` and `requirements` (each `text`, `status` and `met`, worded by `eHerosHall::sHeroRequirementText` and `sHeroRequirementStatusText`, so they follow the core's language and are the SDL inspector's content); a hall that has not summoned its hero updates the requirements on every inspection, as the SDL widget does.
`hero_summon <x> <y> <token>` is the Summon button (it needs the inspection's token like every building control, and is refused as `requirements_not_met`, `already_summoned`, `no_hall`, `not_owned`, `pending_decision`); the engine does the rest: the hero arrives after `sHerosHallArrivalPeriod`, the `heroArrival` event is raised and a hero walker with his model appears. A hero hunts the monsters he is the slayer of (`eMonster::sSlayer`) by himself, and the engine's soldiers cannot hurt a monster (`eCharacter::defend`), so a hero is the only way to slay one.
`world` carries `quests` (the gods' quests: `id`, `god`, `god_name`, `hero`, `hero_name`, `name`, `hall` whether the city has the hero's hall, `ready` whether he has arrived) and `world_quest <id>` sends the hero on the quest as the SDL overview's quest button does (refused: `unknown_quest`, `no_hall`, `hero_not_ready`); the world map's "Quests of the gods" button lists them. Validators only: `test_quest <god> <1|2>` (a god's quest through the engine's own event), `test_hero <hero>` (the hero of the player's hall arrives at once), `test_allow <building name>` (lets the city build what its scenario does not offer).
Two fixes in shared code (`characters/actions/eheroaction.*`; the SDL executable was rebuilt with them): a melee hero fought only within one tile of a monster, but the hunt's path ends on a tile *next to* the monster's (a diagonal neighbour is 1.41 tiles away), so about half the time he stood beside it unable to fight (`fightMonster`'s range is now two tiles); and a hunt that ends in the very step it began (the hero already stands by the monster, or no path leads to it) began the next hunt at once, endlessly, a path search per iteration inside one step, so the city stopped (`huntEnded()`: a hunt that ended in the step it began waits 600 time units before the next search, while a chase that took time re-hunts at once as before).
Sanctuaries: the fourteen gods' sanctuaries are `buildSpecs` rows (`temple_aphrodite` ... `temple_zeus`, `Kind::sanctuary`) under the Build menu's "Sanctuaries" heading (dock icon `ui/icons/sanctuaries.svg`, short label "Temples"). The footprint is the god's layout (`eZeus/Sanctuaries/<god>.txt`, loaded in `prepare()` through `eSanctBlueprints::load()`; 10x6 to 24x16, the quarter turn swaps the sides) centred on the pointer, as the SDL view centres it, and it is founded through the engine's own
`eGameBoard::buildSanctuary` after the SDL view's two rules (`max_sanctuaries`: the city's `maxSanctuaries`; `need_marble`: the initial marble of `eBuilding::sInitialMarbleCost` in the city's stores). A scenario decides which are offered (the test city offers none and has its two); `buildable` also reports each one's `marble` and the city's `sanctuaries` (`built`, `max`, `marble`). `preview temple_<god> x y orientation` answers with the footprint's
tiles, `x`/`y` its corner, `w`/`h` turned, `cost`, `marble` and `pieces` (each `asset`, `x`, `y`, `w`, `h`, `orientation`: temple, court tiles, statues, monument and altar at the offsets `buildSanctuary` uses); Godot draws them as a translucent ghost (`main.gd`: `show_sanctuary_ghost`), the footprint tiles showing whether the ground takes it. A sanctuary is not undoable (its marble would not come back).
The pieces rise as the workers build (each `eSanctBuilding` has stages): a building in the snapshot carries `grow` (percent) while it is less than whole, and `stretch` for a temple, monument or altar that has not begun (the paving tile `sanctuary_court_0` laid over its footprint); `main.gd` scales the model's height by `grow` (a low slab at the least) and stretches the paving. The marble, wood and sculpture are fetched by the engine's carts (a monument is an `eEmployingBuilding` with workers and needs a road beside it), and the god (`walker_<god>`) appears when it stands.
Facing (2 October): the temple's entrance and every god look to the sanctuary's front, along its long axis, not to the camera or a corner. The front is where the yard, monument and altar lie, away from the temple: tile +x for a layout as the file gives it, +y for the turned one (the file's rows run toward the front, and `rotate` swaps rows and columns). The models are authored looking one way (temple pieces 0 and 2 look toward +x, 1 and 3 toward +y, statues and monuments toward +y: in the 3D city the kit's X and Y are the tile's x and y, unlike the SDL view, where kit X is tile +y) and `sanctuaryQuarterTurns` (esimulationservice.cpp) gives each piece the quarter turns that bring it to the front, as the snapshot's and the preview's `orientation`, which `model_basis` already applies; quarter turns keep every pedestal square to the tiles. That is why the monument GLBs are exported with the figure facing +Y (`tools/export_godot_pilot.py` zeroes the 45 degree turn the 2D sprites give them); never turn a piece by anything but a quarter. The altar and the paving keep their facing. `validate_sanctuaries.gd` computes the front from the geometry (from the temple toward the monument) and checks all 28 layouts, the saved city's two turned sanctuaries and a founded unturned one; `run_godot_pilot.py --sanctuary-review <name>` captures the city's sanctuaries from four sides and from above (`captures/sanctuary-<name>-*.png`).
The inspection of any piece of a sanctuary carries `monument` (`title`, `lines`: the SDL widget's wording of the progress, what is still needed and the warnings; `needed`, `stored`, `used`, `cost`, `progress`, `halted`, `employees`; for a finished sanctuary the god's `description`, `help_label`, `help_fraction`, `sacrificing`, `god_abroad`) and `can_control`. `monument_halt <x> <y> <token> <0|1>` halts or resumes the work and `sanctuary_help <x> <y> <token>` asks the god for help as the SDL button does (the answer, `help`:
`granted`, `reason` `too_soon`/`no_target`, `text` from the SDL strings); both need the inspection's token. The `mythology` query is the SDL page: the sanctuaries with their state, the gods attacking and the monsters at large, each with a tile (the Game menu's "Mythology… (F6)", `ui/mythology_dialog.gd`). The fourteen gods' statues and monuments have models (`sanctuary_statue_<god>`, `sanctuary_monument_<god>`, from `art/sanctuary_statues`).
Validators only: `test_allow <building>` also lets one more sanctuary in when the city is at its limit, and `test_stock` now spreads what does not fit in the first store over the others. `test_complete <x> <y>` (validators only) fills a monument's materials and finishes all its pieces at once, and `test_stock` now refreshes the city's cached goods count so what it stocks counts at once (marble for a founding).
God Invasion (3 October): the inspection of a finished sanctuary of the player's own carries `monument.attack` when an enemy city is on the board (`eGameBoard::enemyCidsOnBoard`; only The Sands of Betrayal's Theron among the new games, a few saved campaigns): `label` (the SDL strings' "God Invasion", `zeusText(156, 27)`), `fraction` (`helpAttackTimeFraction()`: the wait since the last request, which the engine shares with asking for help) and `targets` (`city` id, `name`). `sanctuary_attack <x> <y> <token> <city>` asks the god exactly as the SDL button does (`eSanctuary::askForAttack`: the god leaves and `eGodAttackEvent` is raised in that city, which spawns the hostile god there and announces the invasion) and answers `attack_answer` (`granted`, `reason` `too_soon`/`""`, `text`: the god's name and the SDL's own words, strings group 59 entries 19 to 25 by how far the wait has come); `not_an_enemy_city` refuses a city that is not an enemy. Inspector: `building_inspector.gd` `build_attack` (a button, a wait bar and an answer line under the help section; a menu of cities when there are several), `ask_attack`, `show_attack_answer`. `validate_attack.gd` (51, EN/RU) and the windowed review `run_godot_pilot.py --skip-start --attack-review <name>` (the first pass founds and finishes a sanctuary in a new Sands of Betrayal game and reloads the city scene with it; captures `captures/attack-<name>-*.png`).
Sanctuary rites (3 October): the engine's altar (`eTempleAltarBuilding`) sacrifices a sheep, a bull or goods for 25,000 time units roughly every 125,000, which the SDL view draws as an overlay on the altar's sprite (sprite collections 493 to 540: a priestess in a saffron chiton stabbing the animal on the altar, or raising her arms over two jars and a dish); the engine has no priestess walker. The altar now has read-only accessors `sacrifice()` and `sacrificeTime()` (shared header; the SDL executable was rebuilt and signed). The snapshot's walkers list carries each rite of a *finished* sanctuary as two records with `type` -1, a `scene` ("altar"), a `role` ("priestess" with `action` 4, "fight", for an animal or 5, "fight2", for goods; "victim": `animal_sheep_fleeced` or `animal_ox`; "offering": `sacrifice_goods`), the `rite` kind and the altar's `size`, standing at the altar's centre; their ids come from the altar's address (and the byte after it) so they last as long as the rite. `main.gd` places them through `scripts/altar_rite.gd`: the priestess one tile out on the altar's +y stairs (the stairs of `art/sanctuary_altar/build_sprites.py`; she is .87 tall, the table .84, so she stands .30 up, facing tile -y), the victim rolled onto its side on the table (`roll`, applied to the node each frame; the ox model is pale, so a multiply overlay browns it and it is shrunk to .72), the goods built in code (`goods_node`: three amphorae, a dish, fruit). The three tripod braziers of every finished altar burn as animated flame meshes (`AltarRite.Fires`, shader `shaders/ritual_flame.gdshader`, one instance uniform `burn`) that rise higher while a rite is on that altar; the model's own static flame stays under them. The priestess is `walker_priestess`: `art/characters/people/people11.py` (registered in `people.py`; wardrobe profile "Priestess" in `art/characters/roman/wardrobe.py`; `RITE_PEOPLE` in `tools/godot_asset_sources.py`, a COMBAT model with `fight` 24 frames, `fight2` 12 and `die` 8), exported with `export_godot_pilot.py --asset walker_priestess`, 15,500 vertices. Validators only: `test_sacrifice <x> <y> <sheep|bull|goods>` begins a rite on the altar at that tile. `validate_rites.gd` (47) and the windowed review `run_godot_pilot.py --skip-start --rite-review <name>` (three kinds from three sides; `captures/rite-<name>-<kind>-<yaw>-<n>.png`). Not done: the temple's emissive doorway does not flicker, and the SDL overlay's goods frames also show a second figure (apparently a priest in a pale cone hat) beside the altar, which is not shown.
Pyramids, monuments and shrines: the expansion's 54 wonders are `buildSpecs` rows (`Kind::pyramid`, added to the table by `withPyramids()`): `pyramid_modest`, `pyramid_standard`, `pyramid_great`, `pyramid_majestic`, `pyramid_sky_small`, `pyramid_sky`, `pyramid_sky_grand`, `pyramid_pantheon` (9x11), `pyramid_altar`, `pyramid_temple`, `pyramid_observatory` and `pyramid_museum` (the Build menu's "Pyramids", dock icon `ui/icons/pyramids.svg`) and `shrine_minor_<god>`, `shrine_<god>` and `shrine_major_<god>` (42; "Shrines", `ui/icons/shrines.svg`). The footprint is `ePyramid::sDimensions` (3x3 to 9x11, no turning), centred on the pointer, and the founding is the engine's own
`eGameBoard::buildPyramid`; there is no drachma cost and no marble up front (`cost_text` says "Materials by cart": the carts bring marble, orichalc, sculpture and, for a dark level, black marble as the monument is built, and an artisans' guild sends the workers). A scenario grants each one once, with its dark and light levels (`eAvailableBuildings::allowPyramid`; `supportsBuilding`): the saved city grants the standard pyramid (its own modest pyramid stands), five of the 26 adventures grant
pyramids or shrines, a pyramid is used up when founded and given back when the finished one is demolished (the engine frees it a few steps later). `preview <name> x y 0` answers as for a sanctuary (`x`/`y` the corner, `w`/`h`, `tiles`, `pieces`), each piece also with `lift`, the native altitude steps its level raises the ground (four a level), so that the ghost stands the capstone on its raised ground. The pieces come from `ePyramid::sPlan(type)`, which exposes the layout tables that `ePyramid::initialize` places
(they moved into `sLayoutTables`; the SDL behaviour is unchanged, including the middle shrines' two appended levels). The snapshot maps each piece in `asset()`: the faces and capstones are the existing `pyramid_p1_<n>` and `pyramid_p2_<n>` (`pyramidWallAsset`: light or dark, stairs, eagle, wreath), floors `palace_tile_plain`, `pyramid_p2_32` to `pyramid_p2_34`, statues and monuments `sanctuary_statue_<god>` and `sanctuary_monument_<god>`, `sanctuary_altar`, `sanctuary_temple_0`, `observatory` and `museum`; a filler
tile of a larger piece (`pyramidPart`) is `native_marker`, and a piece of 2, 4, 5 or 6 tiles on a side is registered by the engine at its far corner only, so the snapshot gives it its real rectangle (`pyramidPieceSize`). Construction: a piece first raises its ground (the engine lifts the tile a step for each of the four stages of every level, so the terrain in the city rises under a paving slab), then is built; a piece with stages (the temple's three, the monument's two) rises with `grow`. `main.gd` lowers the pyramid models by `PYRAMID_RISE` (.22 / (30 / 73.48)):
they are authored at the SDL game's proportions (a level is 30 px, .408 of a tile) while this view raises the ground .22 of a tile a step, so that a ramp ends exactly at the ground of the next ring. The inspection of any piece is of the monument (`monument.pyramid` true, no god, no help): the progress and what is still needed in the SDL's words, `monument_halt`, and, once finished, the game's description (group 132, lines 114 to 128; a shrine names its god). Validators only: `test_allow <name> [levels]` grants one (`0` or `1` for each level, 1 = black marble; light and dark by turns when none are given; a
pyramid already built, as the saved city's modest one, cannot be granted until it is demolished) and `test_fund <x> <y>` puts into a monument all the materials it still needs (the workers still build it). Godot: the two Build categories, the ghost (`show_sanctuary_ghost`, now with `lift`), `building_inspector.gd` (the description of a finished one), and the review tool `run_godot_pilot.py --pyramid-review <name>` (the city's own pyramids from four sides and above), `--pyramid-review=build:<tool>,...` (founds, funds and captures each at the foundations, partway and done) and `--pyramid-review=menu`; a review that calls `core.query("build ...")` itself must pass the answer to `city.receive_state` (the
answer is the snapshot of what changed and nobody else sees it). Not ported: the cube stages of the SDL sprites (`pyramid_p1_34` to `pyramid_p1_43` exist as renders but are not exported: construction shows the rising ground under a slab), a choice of dark and light levels by the player (the scenario decides), the Atlantean finish of the Temple of Olympus, and any animation of the observatory and museum on top.

The rest of the SDL build menu (3 October): `withMenuRest()` rows in `buildSpecs` for orchards, livestock, fishery, urchin quay, trireme wharf, horse ranch, palace, stadium, bridge, roadblock, the three columns, avenue, boulevard, water park, hippodrome (plates), crosswalk, `monument_<id>` (9 commemoratives) and `god_monument_<god>` (14). Their placement rules are shared with the SDL view in `engine/ebuildplacement.{h,cpp}`; change a rule there, never in one view only, and rebuild and sign `Bin/eZeus` too. Anchors: shore buildings and hippodrome plates take their first tile like a pier (the SDL view's tile is one further on), the palace, stadium, ranch and god monument the SDL pointer tile; the turn (T) picks the hippodrome plate and the water park's variant. Orchards and livestock are `build_area` tools; columns, avenues and boulevards `preview_path` / `build_path` (a click is a one-tile path). Monuments and crosswalks are not undoable. Test with `validate_menu_rest.gd`; review with `run_godot_pilot.py --menu-rest-review menu|build`. A building taken away by undo or demolition leaves the board at the next simulation step: validators that rebuild on the same site first `core.replay(4)`.

City data, taxes, wages and priorities (3 October): `city_data` answers the SDL side panel's pages, the tax and wage rates, the workforce allocation and the finances; `set_tax`, `set_wage`, `set_priority`, `man_towers` change them (answer: the new data). The pages' verdicts live in `engine/ecitydata` and the SDL data widgets call it: change a threshold or a string there, not in one view. Tax rates must be stepped with `eCityData::stepTaxRate` / `taxRatesInOrder` (the enum's veryLow is 7%, low 3%). Godot's window is `ui/city_dialog.gd` (F7, Game, City…); test with `validate_city_data.gd`.

Triremes, races and the two pages (4 October): race chariots are missiles; the snapshot adds them to the walkers from the hippodrome plates' tiles (no `+.5`: missiles and walkers share the tile space). `trireme_move`, `building_switch` and the inspection's `notes`/`switch`/`hippodrome` are described in slice 27 of the migration document; the page texts live in `engine/ebuildinginfotext` (shared with the SDL widgets). The hippodrome tool turns 0-7 in `preview`/`build` and in `turn_placement`. When recolouring an export, set the material's `diffuse_color` too: the vertex palette is read from it. Test with `validate_naval_race.gd` (`test_trireme`, `test_race`).

Leaders and cities (4 October): saves live in `user://saves/<leader>` (`scripts/leaders.gd`, `SaveFiles.directory()`); older root saves are listed, never moved. Tests and reviews must set Engine meta `ezeus_save_directory` and `ezeus_settings_path` to scratch paths so the player's profile is untouched. The core's pages follow `playerCity()` (the player's district in view, reported by `view_tile`); use it rather than `currentCityId()` for anything the player governs. `--start-review leaders` drives the start menu and then a two-city adventure.

Requests, groups, rowing (4 October): `banners_move` takes several companies (`eSoldierBanner::sPlace`); `scripts/unit_selection.gd` draws the selection box. `view_tile` in a snapshot moves the camera once (player invasions and god attacks; the event fires inside the sending command, so validators must read that command's next answers). Person exports take their clothing colours from `art/characters/roman/wardrobe.py` by the person's name: a new people-kit entry needs a row there, or it wears the default cream and red. Ships keep a 35,000-vertex budget when posed. Building workers: add a building to `tools/building_activity_assets.json` and run `tools/export_building_activity.py --assets <name>`.

Remaster extras (4 October): the SDL remaster's City Advisor, Trade Summary and house card draw from shared engine code (`engine/ecityadvisor`, `engine/etradesummary`, `buildings/ehousecard`; keep the SDL widgets on them rather than adding logic back to the widgets). The core answers `city_history`, `city_advisor`, `trade_summary`, `house_card <x> <y>` and the route commands (`route_begin <x> <y> <token>`, `route_toggle`, `route_clear`, `route_restore`, `route_both`, `route_end`, `route`); a route's walk comes from the board's path-finder thread, so it appears only after the city advances (validators call `advance`, reviews unpause). The City window's Advisor/History/Trade pages sit after Mythology (tab indexes 12-14); `scripts/route_editor.gd` takes the map's left/right clicks while active and is ended by Escape, a right click or any tool; `ui/house_card.gd` shows only with the select tool and nothing under the pointer. Test with `validate_city_extras.gd`; review with `--menu-rest-review extras`.

Disasters (4 October): burning buildings come in the snapshot's `fires` list (not the building records, so a fire does not rebuild the static batches); `scripts/building_fires.gd` draws them. Ruins are `ruins_<seed % 8>` from `art/lots/build_sprites.py` (recipes `ruins_0`..`ruins_7`). Chasm, lava and marsh are the G, B and A channels of `terrain_presentation.gd`'s pattern texture, drawn in `ground.gdshader` (R stays the quarry blocks). Validator commands `test_fire`, `test_collapse`, `test_earthquake`, `test_terrain` answer briefly; any command that answers with a snapshot (including `pause` sent as a query) consumes that delta, so tests that need the view to see a change must not query such commands in between (send them through the queue). New GLBs need a `data/geometry_baseline.json` entry: merge new assets in rather than rewriting existing counts. Test with `validate_disasters.gd`; review with `--menu-rest-review disasters`.

Controls and settings (3 October): `scripts/key_bindings.gd` (static, `KeyBindings`) is the one table of rebindable controls (33: eight held camera keys, the city overview, the placement turn, the demolition tool, undo, pause, quick save and load, the world map, army and mythology keys, mute, the details panel, fullscreen (default Alt+Enter) and the overlays' keys) with their defaults, kinds and rules. A binding is one code, the physical key plus Ctrl/Cmd and Alt (Shift is never part of one: it stays the fast-pan and wall-fill modifier, and a key matches with or without it;
the SDL game's own Ctrl/Cmd+Z for undo is one of the defaults). Held camera keys (`orbit_*`, `tilt_*`, `pan_*`, no modifier allowed) are InputMap actions kept in step by `apply_input_map()`; every other handler asks `KeyBindings.matches(event, id)` (`main.gd`'s `_unhandled_input`, `ui/world_map.gd`), and `overlay_for(event)` names the overlay of a digit, Tab or the back quote. `assign(id, code)` hands a key over and gives the control that had it the key the first one leaves (refused: `reserved` for Escape, Delete and the modifier keys, `modifier` for a held, overview or overlay key
with Ctrl/Cmd/Alt, `swap_refused` when the other control could not take the old key); `reset(id)` and `reset_all()` put keys back. Choices live in `user://settings.cfg` section `keys` (only what differs from the default; a damaged file, or one that gives a key to two controls, is not believed and the defaults hold), never in the original game's `settings.txt`. Automation sees the defaults and never writes the player's file, unless a test points `Engine` meta `ezeus_settings_path` at a scratch file and calls `KeyBindings.reload()` and `PlaySettings.reload()`.
`scripts/play_settings.gd` (`PlaySettings`) holds the other options, each with a default and its own short list of values: `autosave_minutes` (0 off, 2, 5, 10, 15, 30; default 5), `autosave_slots` (1, 3, 5, 10; default 3), `fullscreen` (applied at start by `ui_accessibility.gd`, toggled by its key), `voice_language` (auto, en, ru; `audio_manager.gd` takes the voice folder from it) and the camera's `pan_percent`, `turn_percent`, `zoom_percent` (50 to 200; `orbit_camera.gd` scales its pan, turn and tilt by them, and the wheel and the middle-button drag too). The Game menu has two new entries,
"Controls…" (`ui/controls_dialog.gd`: every control by group with a button for its key, a click asks for the new key, Escape cancels, a swap or refusal is said in words, Reset per control, Restore defaults, the camera speeds and the list of fixed controls; `assign_from_event` is its testable core) and "Game settings…" (`ui/game_settings_dialog.gd`; the running city's autosave follows at once through `main.gd`'s `apply_play_settings`). Everything that names a key (the Game menu's quick save, world map, army and mythology entries, the overlay menu's `[key]`, the undo, turn
and pause tooltips, the camera hint) is built from the bindings, so the interface strings no longer carry key names; the hints' translations are formats (`%s`). Review tool: `run_godot_pilot.py --controls-review <name>` (scratch settings; captures the dialogs). Display settings now provides window dimensions/fullscreen/monitor controls; see the current handoff above. Not ported: classic font, weather, monthly-summary and edge-scroll options; mouse buttons and the arrow keys of the world map cannot be rebound.
Walls and defence: `wall`, `tower` and `gatehouse` are `buildSpecs` rows under the Build menu's "Walls and defence" heading. A wall is dragged
as in the SDL view: `preview_wall x1 y1 x2 y2 fill` / `build_wall ...` cover the outline of the rectangle between two tiles (all of it with
Shift, the `fill` flag), each tile built or skipped on its own (`not_owned`, `occupied`, `needs_flat_ground`, `blocked_terrain`) until the
treasury is 1000 drachmas in debt, one undo step per drag; the preview carries each tile's connection mask (1 x-1, 2 x+1, 4 y-1, 8 y+1, as the
snapshot's `wall_<mask>` assets) so the Godot drag (`road_drag.gd`, tool "wall") draws the real wall models, up to 400. Tiles off the map are
skipped silently, as in the SDL view, so a test plot must count its pieces. A tower is an ordinary 2x2 building (an employer: its archer appears
once staffed). A gatehouse (`Kind::gate`) is two 2x2 towers around a one-tile passage: 5x2 tiles, or 2x5 turned (T, orientation 1); (x, y) is the
corner of the whole footprint, the ten tiles are checked one by one (`gateReason`: free building ground, but the two passage tiles may be an
existing plain street that belongs to no agora, gatehouse or hippodrome), the gatehouse takes them and lays road under the passage, and it is
charged once. Demolishing any passage tile targets the whole gatehouse and, as natively, empties all ten tiles. The snapshot gives a gatehouse
its facing from its footprint. Archers (type `archer`, asset `walker_archer`, the people kit's archer identity) patrol the tops of wall and tower
tiles: the walker record carries the retained native `lift` (0.8 on a wall, 2.57 on a tower, in tiles). Since 6 October,
`defence_perch.gd` supplies the Godot roof height and safe render position; see the marble-defence contract above.
Native defect fixed in shared code: `eGatehouse::erase` left its passage roads registered but off the map (they came back on the next save);
it now erases them. A saved and reloaded city is not identical to the live one when an employer (tower, tax office, watchpost) was built
since the open: several other employers (vendors, storehouses) show one more worker after the reload, the cause is not yet found, so
`validate_saves.gd` leaves towers out of its strict digest comparison and `validate_walls.gd` saves and reloads one by building list. The old gatehouse composer is retained as a legacy source; current Godot defences use `tools/godot_defences.py`.
Campaign flow: the service keeps the campaign across episodes (`detach()` lets go of a city, `close()` of everything). A won
episode (the board's own goal check, `mVictory`) stops the game; `finish_episode` books it (`eCampaign::episodeFinished`: treasury,
date, goods set aside) and answers with what is next: the end of the adventure, the next parent episode, or the colonies on offer
(`choose_colony i`); `preview_episode` is the briefing (the episode's template goals), and `begin_episode` starts it
(`eCampaign::startEpisode`, possibly on another board: a colony), writes "autosave replay" (the retry point; the start menu writes it
for the first episode) and re-enters the session. The city scene then restarts and adopts the same simulation
(`main.switch_session`). The screens are `ui/episode_card.tscn` (one layout, five modes; also the start menu's briefing page) inside
`ui/episode_overlay.tscn`, which only drives those commands and reports by signals. `set_aside i` is the SDL goals window's button
(goods leave the stores, the goal counts as met); `difficulty [n]` reads or sets the campaign's level (applied at once, kept across
episodes). Collisions to avoid: the goal count is `total`, the episode count `episode_count`. `test_win` and `test_stock` exist only
after `EZeusSimulation.enable_test_commands()` (validators); the game never calls it.
Sound: `scripts/audio_manager.gd` is the autoload `GameAudio` (music, effects, ambient, voices on four buses, per-user volumes and
mute in `user://settings.cfg`, `ui/sound_dialog.gd`, M key). It reads the original files straight from the workspace `Audio/` folder
at run time (WAV and MP3; nothing is copied or imported). What plays comes from the core: `eSoundVector::setSink` hands every sound
the native rules ask for (fire, collapse, quarrying, gods and monsters, combat, the building-placed sound) to the service as a file
name (snapshot `sounds`), `eMusic::setModeSink` reports battle or peaceful music (snapshot `music`; the embedded core has no
`eMusic`, and an invasion used to dereference it), and the commands `ambient x y` and `building_sound x y` run the native
`playSoundForTile` and `playSoundForBuilding` tables. Which of several files plays uses `eRand::cosmetic()`, never the simulation
generator, so sounds cannot change a replay or differ between the SDL game and the embedded core; keep it that way. Automation
(`--validate`, captures, reviews, `--silent`, headless) leaves the manager disabled; tests enable it with the master bus muted and a
scratch settings file (`ezeus_settings_path` meta). A script run registers autoloads after compiling the script, so a validator must
`load()` (not `preload`) anything that names `GameAudio`.
Overlays: the SDL game's view modes (water, supplies, hygiene, fire and collapse risk, appeal, taxes, unrest, security, roads,
problems, farming, industry, storage and trade, immortals, culture and science groups; 25 with the normal view) work with the SDL
hotkeys 1-9, Tab and 0. The core's `overlay <id>` query answers from the native rules: `eViewModeHelpers::buildingVisible` and
`characterVisible` decide what stays visible, the per-house values are the ones `eGameWidget::drawBuildingModes` reads, and the
appeal grid applies the same rating rule as the SDL paint. `scripts/overlays.gd` is the catalog (names, legends, hotkeys, tones),
`scripts/overlay_view.gd` draws columns, supply markers and the appeal Decal, and `main.gd` applies the filters (hidden buildings
lie flat in the footprint batch, hidden walkers are invisible nodes) and polls once a second (appeal every three). A new overlay is a
catalog entry plus its core mapping; keep the data read-only (`validate_overlays.gd` checks the replay digest is unchanged).
Start menu and new games: `ui/start_menu.tscn` (script `ui/start_menu.gd`) is the project's main scene. Continue opens the
newest save, New game lists the adventures, Start reads one and shows its first episode's story and objectives, Begin hands the
opened simulation to `main.tscn` through Engine meta `ezeus_simulation` (`core_link.adopt`, so the campaign is read once);
saves go through meta `ezeus_load`. Any automation flag (`--validate`, `--capture=`, the reviews, `--bridge-port=`, or
`--skip-start`) skips the menu and opens the designated test city, so validators and reviews are unchanged; the launcher passes no
`--lang` unless asked, so the menu opens in the language the player last chose (`user://settings.cfg`, `scripts/user_settings.gd`).
The adventure list is the SDL menu's own: `engine/eadventurelist.*` (shared by both views), exposed as
`EZeusSimulation.adventures` and `open_adventure(kind, ref)`, which opens only what the listing offers. The `episode` query gives
titles, introduction and the objectives with live status (same texts and progress rule as the SDL tracker); the HUD's
objectives panel polls it every two seconds, and a finished episode shows its result card. (Campaign progression to the next
episode and the colonies followed; see the campaign flow below.) Saves live in `user://saves`
(`scripts/save_files.gd`); tests redirect them with Engine meta `ezeus_save_directory`. The binding caches the building list only
for snapshots: other answers that carry a `buildings` key (the build menu's `buildable`) must never replace it.
Build-menu contracts: the core's static `buildSpecs` table (presentation/esimulationservice.cpp: mode, native type,
footprint, model name, fertile/flat flags, constructor) is the only list of what can be built; never probe by constructing a
building (a constructor registers with the city and draws random numbers, which changed the replay digest). The Godot menu
is `scripts/build_catalog.gd` (category per name, English `NAMES` equal to the core's English labels) over the `buildable`
reply, filled in `main.gd` after the core opens; labels are `tr()` keys from `data/building_names.csv` (a second Russian
translation registered in project.godot, kept apart from the interface strings because the orphan gate reads only those).
Markets: `engine/eagoraplacement.*` holds the one rule for laying a common or grand agora over a stretch of road
(`find`/`build`) and for filling its spaces with vendors (`canPlaceVendor`/`placeVendor`); the SDL widget delegates to it, so
never reimplement it. The pointer tile only seeds the search (like the SDL view), a vendor tool picks the space by any of its
four tiles, each agora takes one vendor of each good, and the wine, arms, horse and chariot vendors share the stall models of the other three (`art/agora/build_stall.py --kind`; the horse trainer is offered only where the city's culture allows it, which the test city does not; they used to stay hidden until they had models). An empty space is `agora_space`, drawn by `main.gd` (`add_plaza`) as pale paving. `buildSpecs` rows carry a `Kind`
(standard, agora, vendor) for these.
A new building needs a `buildSpecs` row, a category and name here, a Russian name, and a model before it is shown.
`validate_buildings.gd` fails while any listed name lacks a category, English name or Russian name.
Playable-loop contracts: roads are placed by `preview_road`/`build_road` (one path rule shared with the SDL view; never
loop single `build road` calls from the UI). Saves go only to the per-user `user://saves` directory in the native `.ez`
format through `save_city`; never write into `Save/` or beside the original game, and never open anything but the designated
test save or that directory. A load restarts the scene (`Engine` meta `ezeus_load`) rather than patching a live city, so any
new presentation cache needs no reset code. Messages: toasts for dismiss-only messages, the top-centre box for decisions,
everything in `message_log.gd`. The core words the events the engine raises itself (`eEvent::monthlySummary`, `shortageWarning`,
`riskWarning`) in `presentation/eenginemessages.h`, from the SDL view's own `text/language*.txt` keys and the city history (the card reads the same in both
views; keep the two in step); an engine event without a catalogue message would otherwise arrive titled with its raw name and no text. `event_texts` and
`test_event` (validators only) audit and raise them, and `validate_embedded.gd` gates it. The other 103 kinds that the SDL view words in its own handlers from god, monster, hero and city data (gods' visits, invasions, help, quests, disasters and
trade resumptions, the monster and invasion timelines, hero arrivals, the 15 sanctuary, pyramid, monument and shrine completions, and the 63 comply / too-late / refuse replies to requests) are worded in `presentation/eeventwords.h` from the same `eMessages` tables and
substitutions (`[reason_phrase]`, `[hero_needed]`, `[time_until_attack]`, then `eMessageBox::sFormatText` for the city, god, monster and amounts), with the god, monster and hero voice lines asked for as the SDL view asks (they arrive in `sounds`); keep the two in step. Differences, on purpose: every
occurrence of `[reason_phrase]` is filled (the chimera's warning names the reason twice and the SDL view's single replace leaves the second), and `playerInvasion` and `playerGodAttack`, which the SDL view shows only as alert tiles, are silent. `test_raise <event> [god g] [monster m] [hero h] [time n] [quest 1|2] [reason w] [city i]` (validators only) raises any
event kind through the board's event path, `event_texts` must list none, and `validate_events.gd` checks all of them in both languages. Informational ones become toasts (showing the condensed wording the core sends as `brief` when there is one, as the SDL view's pop-up cards do) and log entries (with the whole text) like every dismiss-only message.
The minimap draws only what main.gd hands it.
Diagnostics: `EZEUS_RAND_TRACE=N` prints the call stacks of the first N worker-thread random draws, and `EZEUS_REPLAY_DUMP=file` keeps the
serialized state of an SDL replay for byte comparison.

The helper prepares pinned dependencies, builds `build-godot/`, then finalizes and
signs `godot/bin/` libraries. Do not skip finalization after relinking. Keep the
private SDL2 with video/audio drivers disabled; do not redirect it to Homebrew
SDL2-compat/SDL3 or modify system libraries. The README records dependency pins.
The local setup still needs the parent runtime/assets and Homebrew dependencies;
a standalone checkout is not yet a self-contained release.

If rebuilding the native SDL reference executable, run from this directory:

```sh
ninja -C build
cp build/eZeus Bin/eZeus
codesign --force --deep --sign - Bin/eZeus
```

Always copy and sign after a native executable rebuild. The extension helper
does not rebuild that executable. Close only the owned preview before replacing
loaded binaries; never terminate unrelated Godot, Blender or game sessions.

## Save, asset and handoff safeguards

- City testing uses **`Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`** only. Keep
  Godot preview changes in memory; preserve the launcher's before/after save and
  settings checks. Do not enable autosave or overwrite personal saves. Original
  `.sav` files are unsupported by this core. Save serialization tests may use
  disposable copies derived from the designated test city.
- Inspect existing Git changes before edits; preserve unrelated remaster work.
  Check binary sizes before committing; generated GLBs, libraries, captures and
  editor caches are currently ignored. No commit or publishing is implied.
- Reuse local Blender source geometry and paired model manifests. Read relevant
  parent `art/**/DESIGN_REFERENCE.md` benchmarks. Preserve distinct anatomy,
  actual female/child meshes, ground anchors and independent trees. Blender +Y
  forward becomes Godot −Z after Y-up GLB export; apply this conversion once.
  Use background `tools/export_godot_pilot.py` exports to protect the live scene.
  Native atlas sizes are not a Godot mesh contract.
- Preserve English and Russian text/input paths. Test high-DPI scaling when
  changing native font sizing. The EN/RU presentation toggle and native message
  launch language are separate; Godot plays the original game's sound (see the sound contract below).
- Preserve required upstream author/GPLv3/dependency notices and provenance
  evidence. Original commercial content and new export manifests are not cleared
  merely by rebranding. Follow the production roadmap before release work.
- Update `godot/README.md`, `docs/GODOT_MIGRATION.md` and
  `docs/GODOT_VALIDATION.md` together as scope changes. Record commands, results,
  limitations and remaining work; distinguish implemented from verified and
  production-ready. Do not turn transient process IDs into standing instructions.
