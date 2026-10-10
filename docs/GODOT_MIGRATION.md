# Preserve the simulation, replace the presentation

## Menu hierarchy and single story route — 10 October 2026

The approved ornate full-page frame is retained across the main menu, adventure
library, load, profiles, Settings hub, Extras and story. Compact settings forms/
confirmations share the lighter bronze/slate native-window frame through
`settings_shell.install_frame`. Secondary Back actions use padded `MenuPageChoice`
controls; compact primary footer actions use `MenuPagePrimary`, while large menu
choices retain their artwork. The adventure metadata
band now matches the slate palette. Theme changes remain menu-owned.

Removed the duplicate chapter-reader button and hidden preview-story controls.
Normal Start→story→Begin retains full native introduction, goals, difficulty,
campaign identity and chapter-one behavior. Full story prose remains measured
into parchment pages. Historical reader source stays available but normal menu
navigation no longer links to it. Current validation covers scoped owned EN/RU
menu/reading/native campaign previews, without claiming new city-loader validation.

## Fifth campaign: Tidebound Covenant — 10 October 2026

Adapted the reviewed Tributaries 3 parent terrain/world by Nightwolf / David
Masters into three new EN/RU chapters: local food, domestic fleece and Atlantean
science/housing, then timber and two reserves for a future outpost. No imports,
exports, trade buildings or automatic tribute are authored. The map's 25,992
native tiles, elevation, ordinary rock, road fragments and wildlife remain intact.
There are no mineral deposits. Native phased permissions and same-city carry
remain authoritative; the final reserve ends this slice without a colony board.

Ordinary gameplay completes every chapter with 496 commands/2,410 service calls,
real local wheat/fleece/timber, taxes and both Set aside actions. Campaign reviews
pass 52 per language; five-campaign menu/save reviews pass 137 per language;
retained editor 64/embedded 101 pass. Installed the verified private export as the
fifth normal New game entry, with separate Continue/Load scope, new static city
art and an isolated Play launcher. Current validation records the review scope.

Source archives, player profiles and earlier campaigns remain protected. No C++
rules, RNG, ticks, native save layout, audio, model/UV/VAT/LOD assets or live game
were changed. Human pacing, user acceptance, actual Windows/minimum machines
and retained-content commercial clearance remain open. Frozen Windows kits are
unchanged; needs_evidence/ships_in_release=false remains. See
[Tidebound Covenant](TIDEBOUND_COVENANT.md).

## Stable construction-category slots — 10 October 2026

`hud.gd` now draws the sixteen canonical `BuildCatalog.CATEGORIES` slots in fixed
order, appending an actual unknown category only when present. `build_groups`,
model cards and placement eligibility still contain exactly the native available
catalog. Empty categories are genuine disabled Buttons with cached grayscale
copies of the original static SVGs and translated explanatory hover help.
Catalog changes enable/disable slots; a newly unavailable selected tray closes.
`open_category` also rejects disabled slots, and settlement guide targets/actions
skip them. Identical catalog refreshes still retain controls, scroll and focus.

The ellipsized center Label previously had effectively no intrinsic width, so a
sparse category row could collapse it. Its preferred width is now measured from
the translated category titles when the catalog/language/text size changes and
bounded by the room left after the clock column and main buttons. No per-frame
text shaping, new native queries, theme saves or simulation changes are added.
Current validation covers native read-only reviews and sparse/empty/re-enabled
presentation fixtures in English/Russian at normal and enlarged sizes.

## Scenic portal aperture alignment — 10 October 2026

Replaced the cinematic doorway's symmetric analytic arch with a source-derived
distance mask. The portal fits the asymmetric perspective curve, protruding
jamb stones and sloping threshold. Its bounds and mask share the existing
image cover/crop/drift transform. A lossless packed distance texture adds one
shader sample, retaining the four-triangle/two-quad composition and existing
fire/cloud motion. Earlier procedural scenes retain the default analytic arch.

`tools/calibrate_menu_portal.py` derives the mask from the unchanged artwork;
source/derivative hashes and registration are recorded in its provenance file.
The historical Blender reference remains unchanged. Native menu behavior,
simulation and player files are retained. See current validation for sequential
EN/RU menu and enlarged-layout evidence; other platforms/minimum-device
profiling and user visual acceptance remain open.

## Cohesive start-menu settings — 10 October 2026

The six retained settings dialogs now use a menu-owned bronze/slate shell instead
of floating above the ornate category buttons. Original SVG meander trim, ivory
serif headings, clear sans labels, aligned choice columns, bronze slider grips
and visible checkbox states match the Greek menu. The inactive category frame
hides behind a scenic shade; closing the last nested dialog restores category focus.

`settings_shell.gd` only decorates dialogs opened by `menu_navigation.gd`. Private
Themes preserve shared city styling and native drafts, persistence, display
preview/revert, nested return and binding callbacks. Footer dimensions use native
AcceptDialog Theme constants and full translated text measurements. Live interface
previews update the skin without rebuilding content, and the long key list remains
bounded. See current validation for sequential disposable EN/RU evidence and limits.

## Fourth campaign: Sunlit Terraces — 10 October 2026

Adapted the reviewed Everybody loves oranges parent terrain/world by Genis into
three new EN/RU chapters: orange harvest and trade, olive oil and housing, then
wine production and an explicit reserve. Native Greek culture services, terrain
heights, staged permissions, same-city carry and save format remain authoritative.
Source road fragments need an actual connecting route; an adjacent isolated road
does not deliver fruit. Briefings distinguish granary orange storage from ordinary
warehouses and explain imported grain while orchards mature.

Installed the verified private export as the fourth normal New game entry, with
chapter previews, authored focus, separate Continue/Load scope and a static view
of a copied ordinary-playthrough city. Added an isolated Play launcher. Source
archives/notes/hashes, earlier campaigns and player files remain protected.
No C++ rules, RNG, native ticks, geometry/UVs/VAT/LODs or audio were changed.

All three chapters complete through 777 ordinary commands/4,100 service calls,
including actual orange sales, grain imports, local oil/wine and the wine reserve.
Visible EN/RU native campaign reviews pass 52 each; retained editor 64/embedded 101
pass. Current validation records expanded four-campaign menu/save checks.
Human pacing, user acceptance, actual Windows/minimum-machine testing and retained
map/content commercial clearance remain open. Frozen Windows ZIPs are unchanged;
the adaptation stays needs_evidence/ships_in_release=false. See [Sunlit Terraces](SUNLIT_TERRACES.md).

## Frame-safe briefing and parchment reading — 10 October 2026

The start-menu frame now reserves an inner reading area below the crest and
above the lower gold rail. The campaign name and native episode counter share
one header row; the chapter title and full difficulty/Back/Begin footer remain
inside the wood. A bounded Control prevents long story labels from enlarging
the panel. The menu owns this instance's layout; city episode cards retain the
shared layout and all native callbacks.

Replaced objective pagination with one visible native list/grid in both the
briefing and adventure preview. Larger lists and short windows arrange goals
in columns; larger lists get a wider objective panel, and short windows place
the story below a compact goal row. Full prose retains measured word-boundary
pagination. Original blank aged parchment,
dark ink, generous content padding and matching sepia page controls replace
the flat bright paper. `aged_parchment_v1.provenance.json` records the built-in
1536×1024 alpha artwork, exact prompt and hash. Current validation records owned
EN/RU native flow and normal/enlarged frame/objective/reader bounds.

The user's follow-up limits parchment to story briefings/full chapter reading.
The adventure-selection preview now uses a dark slate surface, bronze edge,
ivory description/objectives and gold headings. A separate preview text variation
keeps dark story-page counters intact. Existing native actions/layout and source
art remain unchanged; focused EN/RU preview/story checks cover this refinement.

## Compact settings lettering — 9 October 2026

The large ornamental skin no longer overrides generic Button controls. Compact
key-binding and dialog actions inherit the shared clean surface/padding and sans
font, with a menu-local 17-pixel text baseline. Explicit large menu variations
retain their original art and silhouette focus. Existing binding/settings callbacks,
shared city Theme, cursor family and native simulation remain unchanged. Current
validation covers default/enlarged key labels, capture prompts and dialog footers
in sequential owned English/Russian menu reviews.

## Global Greek cursors and menu focus refinement — 9 October 2026

Removed the menu's rectangular gold focus outline. Keyboard focus now uses the
same nine-sliced enamel/bronze silhouette with subtle brightening, preserving
visible feedback and the original Control hit area.

Added `GameCursor` after `UiAccess`: 13 transparent lossless textures cover all
17 Godot cursor roles throughout scene changes. The original generated Greek
atlas supplies arrow, hand, text, cross, wait, busy, drag and forbidden art; five
original SVG symbols supply resize/help roles. Source alpha and generation prompt
are preserved with crop/hotspot/hash provenance. Hardware registration follows
existing cursor roles and adds no per-frame work or input handling. Cached
48/53/60-pixel textures follow 100/110/125% interface size independently of text.
Headless sessions prepare resources without hardware calls.

Sequential owned native EN/RU menu reviews pass 58 each, including actual Continue
into the unchanged copied city. A focused native cursor review passes 44, including
role selection, transparency, click alignment and scale/cache/mouse-mode behavior.
The runtime art sheet was inspected on light/dark surfaces. These are macOS
presentation checks; other platforms/high-DPI and user visual acceptance remain
pending. Native C++ rules, RNG/ticks/saves, model sources and live Blender remain
unchanged. Current interface/validation docs and cursor provenance retain scope.

## Ornate menu artwork and navigation — 9 October 2026

Replaced the plain/corrupted menu housing with original generated Greek frames:
weathered walnut, bronze meander trim, ivory carving, eagle/lightning crests and
blue enamel buttons. A menu-owned Theme copy provides nine-slice button art and
hover/pressed/disabled/focus feedback. No shared scaled Theme is mutated or saved.
The realistic scenic plate and registered animated portal remain. The new frames
are raster artwork with painted depth; historical 3D housings are retained as
source but are not instantiated by ordinary launch.

The fixed tall main page fits Continue/New game/Load game/Settings/Extras/Quit
without scrolling. Named Settings categories use the existing six settings
implementations; Extras contains the native editor and profile roster. Parent
navigation preserves Back/Escape context. Catalog search/page controls map visible
rows to authoritative native indexes, keeping exact campaign/save identity.
Measured prose pagination preserves the complete first briefing and chapter
previews without internal scroll bars; objectives now appear together as above. City episode cards and long
settings forms retain their existing layouts and native semantics.

Generated outputs, exact prompts, dimensions/hashes and runtime crop are recorded
in `assets/menu/greek_menu_v3.provenance.json`. Current interface/validation docs
describe sequential owned EN/RU menu/card and campaign checks. Native C++ rules,
save format, RNG/ticks, models/UVs/LODs and the open Blender document remain intact.
User visual acceptance and broader platform/minimum-device profiling remain open.

## Earlier realistic menu background replaces procedural scenery — 9 October 2026

The user rejected the earlier simple procedural scenery and allowed a partial-3D
presentation. Normal launch now uses a generated realistic scenic plate: weathered
Greek sanctuary architecture, a populated coastal city, rugged mountains, foliage
and boats. The retained live portal shader sits on a precisely registered quad in
the image's dark opening. Original source geometry, earlier baked scene and
historical Blender artwork remain available; native models/UVs/LODs are untouched.

The backdrop is two realtime quads with a shared cover crop and very small bounded
drift. The ornate stage above supersedes its 3D housings; the native text/input layer remains. Reduced
motion holds scenic/portal animation. The already graded image uses linear tone
mapping and unshaded display. Generated dimensions are 1672×941; the prompt's 4K
request is not evidence of 4K output. Source/prompt hashes and runtime registration
are recorded in `assets/menu/aegean_cinematic_v2.provenance.json`.

Blender port 9876 was inspected read-only. A separate background process creates
`art/menu/cinematic/aegean-cinematic-v2.blend`, with a packed scenic image and an
editable procedural portal preview. It does not reconstruct separate people,
city buildings or mountains. English/Russian menu reviews pass 34 each, including
Continue from the unchanged copied city, enlarged layouts and reduced motion.
Current platform/minimum-machine and user visual acceptance remain pending.


## Earlier Olympian menu presentation (superseded) — 9 October 2026

Replaced the ordinary start scene's underworld canyon with original procedural
Aegean scenery inspired by the supplied Athens/Troy references. The original
portal composer and shader remain and are used at a smaller scale within the
foreground sanctuary. Existing local courtyard-house meshes and Zeus sculpture
are reused without changing their originals, materials, UVs or imported LODs.
Natural terrain, temples, streets, harbour, foliage, mountains and daylight are
presentation-only; no simulation, collision/navigation or native RNG is added.

Main, adventure, introduction, load and leader page housings now use physical
beveled stone/bronze geometry; primary navigation controls use raised slabs.
The native Control layer retains readable text, focus, clipping and click targets.
Campaign art grows within the existing bounded/scrollable page. Shared settings
and sound dialogs retain their existing UI and semantics. Reduced motion holds
all new ambient animation. The 12 MiB compressed static derivative is hash-checked
against the composer, retained models and relevant shaders, with regeneration
fallback. On this M4, the observed construction step dropped from about 4–5 s to
193 ms with the derivative (not a cold-start or minimum-machine benchmark).

EN/RU menu navigation and Continue reviews pass 34 checks each, including the
new 3D/reduced-motion checks. User visual acceptance, sustained minimum-device
profiling, alternate aspect-ratio/platform coverage and release evidence for
retained inputs remain open. No packaging or public release is implied.


## Native healer treatment — 9 October 2026

Fixed the missing medical treatment in `eHealer::provideToBuilding()`. A normal
service visit retains exact hygiene provision and additionally sends an infected
common house through `eGameBoard::healHouse()`. This handles full-hygiene houses,
removes outbreak membership and removes the outbreak when its last house recovers.
Treatment stays in the shared C++ simulation; Godot's existing aura/count deltas
reflect recovery without fabricated UI clears. Unvisited houses are unaffected.

The extension is rebuilt, signed and installed on a fresh inode. Loaded infections
recover on actual infirmary patrols; no save-format change/migration, route change,
new ordinary command or infection/natural-recovery tuning was introduced. Scoped
native/headless/Metal EN/RU evidence is in `GODOT_VALIDATION.md`.

## Third private campaign: Stonewatch — 9 October 2026

Implemented three new EN/RU settlement, defense and mythology chapters on the
reviewed One Against the World parent map by orius. Native phase gates/city carry,
sea imports/timber exports, 12-troop invasion and a passive Minotaur/Theseus trial
are authored as scenario content. Editor-only foreign combat-team assignment uses
the existing serialized mappings; ordinary gameplay rejects it. The exported
attacker is explicitly checked. Normal New game/save slots now include Stonewatch.

The ordinary playthrough wins all chapters with real invaders/Fight/victory and
Theseus's Summon/fight/slaying, without injected stocks/population/cash/victory.
824 commands/2,150 calls leave 648 residents and 16,441 treasury. Live earlier
launcher logs can append; actual player files/content remain hash-protected.
See `STONEWATCH.md` for current checks and limits. Human pacing/minimum/Windows,
clean packaging and retained-content release permissions remain pending.


## Wheat growth presentation and readiness — 9 October 2026

Connected the previously omitted farm crop overlay to the existing native
five-stage growth cycle. Read-only farm getters expose normalized harvest
progress and the original effective-field rule. Separate `farm_crops` observations
leave the architecture snapshot cache intact; the inspector reads the same
progress and shows a translated percentage/bar beside output inventory.

Original procedural wheat stalks, leaves, grain heads and awns occupy the villa's
five existing field tiles. Shared spatial MultiMeshes use per-instance growth,
two reduced index LODs and the gameplay clock for subtle sway; field geometry,
farm architecture/facing/setback and native foundation remain independent.
Green shoots rise and turn gold, then reset at the native harvest. The original
farm GLB, source artwork, harvest quantities/timing, staffing, rules, RNG and save
format remain unchanged. Other farm readiness is shared, but wheat is the new
visual crop. See `GODOT_FARM_CROPS.md` and `GODOT_VALIDATION.md` for verification
and pending wider campaign, user-art and minimum-platform acceptance.

## Unified campaign selection and continuation — 9 October 2026

Normal New game now features First Light Harbor and Bronze River, with static city
views, native parent chapter previews/default difficulty, explicit briefing
disclosures and saved-chapter labels. The private verified exports are installed
without source/player mutation; the earlier prototype is a hidden load-compatibility
entry. Separate native-content save scopes preserve each campaign's autosave.
Previous-launcher leaders/saves are read in place; loaded native identity selects
the new write slot only after immutable preflight succeeds.

Bounded read-only save hints and native chapter observations preserve rules/RNG,
save layout, callbacks and timing. Unowned metadata-reader cleanup retains active
audio sinks. EN/RU Metal library checks pass 61 each; whole retained preview checks
256/58, editor 64/embedded 101, save transactions 19/recovery 36 each pass. Mac
targets are signed on fresh inodes; Windows core compiles/static imports resolve.
See `GODOT_CAMPAIGN_LIBRARY.md` for evidence/limits. Existing Windows ZIPs remain
frozen; actual packaging/platforms, newcomers and release-rights evidence are open.

## Second private campaign: Bronze River — 9 October 2026

Implemented an Armory-parent-map adaptation with three EN/RU chapters: settlement,
bronze-to-armor logistics/imported household goods, then profitability and a reserve
through native trade disruption. Chapter permissions and city carryover are native;
sources and First Light profiles remain intact. The authoring wrapper accepts an
explicit recipe and protects reviewed sources/previous campaigns.

All three chapters complete through ordinary gameplay, with explicit native armor
sale/fleece import counters, reserve commitment and trade recovery. Final-year
profit is 2,390. Authoring passes 9 and sequential Metal EN/RU reviews 53 each.
Every water-tile bridge preview survives edge cases; missing native end-neighbor
checks are repaired without changing valid placement rules. Retained First Light,
editor/core and fresh bootstrap checks pass. Both Mac targets are signed safely;
Windows core recompiles with static DLL closure but has no actual-platform acceptance.

See `BRONZE_RIVER.md` and provenance for scope. Newcomer/pacing review, Bronze River's
Windows package/minimum machines and commercial permissions remain pending.

## Staged first campaign and natural completion — 9 October 2026

Implemented three First Light Harbor parent chapters with EN/RU writing, phased
building sets and city/treasury carryover. A new content identity/profile separates
the campaign from the retained single-chapter prototype and old saves. The final
native trade interruption starts after three months, lasts 90 days and is followed
by a six-month settling goal. BC date goals now compare their boolean status, and
preview copies initialize relative dates without mutating templates. An opt-in
working export route also requires positive export capacity.

Normal-play validation won all three chapters with food/clothing/science/appeal,
staffed timber exports and palace-enabled taxes; final-year exports 1,650 and net
profit 1,046. Briefings were refined from those supply/appeal/storage/tax findings.
Visible EN/RU checks pass 38 each, retained unlocks 37 each/editor 64/embedded 101.
Mac/reference builds and isolated Windows cross-build are updated; a fresh private
Windows Chapters package includes the campaign and passes manifest/import checks.

This is private adaptation/playtest content, not commercial clearance. Human pacing,
newcomer feedback, actual Dell/minimum-platform acceptance remain open. See
`FIRST_LIGHT_CHAPTERS.md`, current validation and provenance.

## Complete episode building permissions — 9 October 2026

Ordinary campaign permissions previously discarded by the native availability
adapter now use its existing serialized keyed records. PAK flags, authoring,
template/active saves and next-episode application agree without changing the
binary layout. Native culture/market/trade dependencies and all placement paths
share the authority. Godot clears removed placement tools on catalog refresh.

First Light Harbor version 3 authors a complete opening list while retaining
its one chapter/seven objectives. Relaunch/new game is required for that recipe;
player saves keep their earlier definitions. EN/RU two-episode checks pass 37
each, actual prototype 34 each, retained buildings 505/campaign 26/editor 64/
embedded 101. Both Mac targets rebuild/sign safely. See `GODOT_CAMPAIGN_BUILDINGS.md`.
Natural playthrough, chapter-layout choice, Windows and release gates remain open.

## Playable fan-terrain adaptation — 8 October 2026

Implemented **First Light Harbor** as a separate private Mac launch/catalog with
retained Alexandria parent terrain/roads, new EN/RU writing, one episode,
Mortal/18,000 opening, seven goals, one authored partner and a native 90-day Poseidon
trade interruption after six months. The guide opens at Begin. Unused colony
boards/episode writing/narration IDs are removed; originals and author hashes remain.

Explicit editor operations export a named single-parent adaptation and difficulty.
Zero-colony iteration is safe. An opt-in goal requires staffed road-connected export
posts; original goals retain diplomatic counts. Prototype roots apply to menu/city/
save preflight, and saved views override initial focus. Both native targets rebuild
and are signed/installed safely. Source recipe/manifest make private exports repeatable.

Visible checks pass 32 EN/32 RU, editor 64, embedded 101. Natural progression,
positive staffed-export completion, 30–60-minute pacing, minimum devices and
commercial rights remain pending. No Windows kit update/shipping clearance is
claimed. See `FIRST_LIGHT_HARBOR.md` and current validation/provenance.

## Community terrain candidates — 8 October 2026

The user prefers evaluating popular fan maps as campaign starting points.
Downloaded the five most downloaded Poseidon-category adventures plus single-map
Augea. Retained untouched archives, bounded extracted data, file hashes/author
records and a separate Alexandria working copy. Alexandria is preferred because
editable maps/settings and an author invitation to change them are included.
See `CUSTOM_ADVENTURE_RESEARCH.md` and `custom-adventures.provenance.json`.

This is research/preparation, not a playable campaign milestone. Native/Godot
import, terrain adaptation, new narrative/goals/pacing, playtests and explicit
commercial release rights remain pending. Nothing is added to the runtime catalog
or shipping allowlist; native simulation, saves, current city and art are retained.

## Compiled Windows x64 transfer kit — 8 October 2026

Implemented a private Windows cross-build using checksum-verified isolated
MinGW-w64 14 / GCC 16 compiler copies and pinned SDL/Godot bindings. The x64
extension links and exports the required entry point; six DLLs have no unresolved
non-system imports in the staged runtime. The additional stack-protection DLL
is included. Official Windows Godot 4.6.3 is checksum-verified and bundled.

Portable SDL includes, explicit integer headers, Windows timestamp handling,
SDK macro isolation, MinGW DLL naming and quoted CMake staging fix compilation
without native rule/RNG/timing/save-layout or art changes. The Mac extension also
rebuilds and is signed/installed on a new inode. Private packet assembly uses
independent copies, only the designated test city, explicit resource roots and
retained source/license/monster attribution records; no personal Save folders,
preferences, editor cache or Mac binaries are exported.

A no-Python Godot orchestrator tests save recovery and visible performance with
owned children, scratch paths, protected-file hashes and owned-process RAM
sampling; Windows batch launchers collect a return ZIP. Its Mac execution proves
orchestration only. Windows MSVC/launch/driver behavior, actual Dell performance,
minimum machines and independent-content/standalone release still require
acceptance. See `WINDOWS_TESTING.md`, `WINDOWS_CROSS_BUILD.md` and current validation.

## Modern desktop baseline and platform evidence — 8 October 2026

Implemented full-resolution Balanced/High graphics previews, per-user Apply,
Cancel/Escape/removal restoration and live sun/LOD/ground-detail range changes
without rebuilding city geometry. Balanced preserves the prior appearance;
High extends detail/shadows. Both retain MSAA, shadows, original models/UVs,
native crowd/map coverage, timing/rules and two sun cascades. The user chose a
modern hardware floor; Low and the old-card renderer experiment were removed.

Mac retains Metal; Windows now selects Direct3D 12 with Vulkan fallback. Automatic
OpenGL fallback is disabled. A scratch-only 1080p performance runner separates
frame intervals, core/snapshot/script costs, graphics/RAM use, native-speed and
visible-fire workloads, and six guarded reloads. Required decisions stop a phase
honestly. Windows x64 CMake/DLL staging, platform PID/trace guards, tracked
extension descriptor and PowerShell build/save/performance instructions are
prepared. Mac rebuild/install and scoped checks pass; Windows is not compiled
or launch-verified here.

Provisional Windows/Mac minimum/recommended targets are acceptance proposals,
not Steam requirements. The binary audit revealed a macOS 26 native-library floor
and remaining Homebrew dependencies. Rebuilding/bundling for the proposed macOS
14 floor, actual minimum-Mac/Dell runs, cold/long-session/package testing and
cross-platform save/replay evidence remain pending. See
[GODOT_RELEASE_PERFORMANCE.md](GODOT_RELEASE_PERFORMANCE.md),
[WINDOWS_TESTING.md](WINDOWS_TESTING.md) and current validation.

## Player-progress protection — 8 October 2026

Implemented recoverable per-name save transactions: unique stage, content check,
file sync, two rotating checked backups and atomic replacement/directory sync.
Older footerless content and detected damaged evidence are preserved separately.
A versioned CRC32 trailer keeps durable facing, selected speed and optional
native-coordinate camera view in the same file as the unchanged native payload.
Facing uses native identity/board scope rather than pointers or session IDs, and
survives load/parent episode handoffs. Old `.ez` saves remain supported. The current
signed native reference opens a new guarded save with identical gameplay digest.

Load/Continue now prove a private copy readable in an owned headless process before
the current scene is replaced. Failed/cancelled loads preserve the active city
and restore pause/command holds; readable backups/pending first saves require an
explicit recovery choice and keep the original. Silent test-city fallback is
removed. Bounded native file reads reject truncated lengths/dimensions without
per-primitive file seeking; headless mesh warming avoids dummy-renderer races.
No rule, pathfinding, economy, native tick or decision callback is changed.

Focused EN/RU recovery, native/file-system faults, actual scene transitions,
reference round trip and retained gates pass; see validation and
`GODOT_SAVE_RELIABILITY.md`. Real power-loss tests, Windows filesystem execution,
cloud/removable storage, whole-campaign update migration and large/long-session
profiling remain pending. User saves are not automatically migrated or overwritten.

## Construction and foundation clarity, second pass — 7 October 2026

Implemented an upward construction reveal for compatible opaque vertex-palette
sanctuary/pyramid pieces. Full architectural proportions replace vertical
squashing, while the existing native `grow` percentage controls a batched world
height cutoff. Unsupported textured/VAT content retains its earlier growth
path; foundation-only slabs stay native. Timber posts/rails/braces rise with the
current stage and leave on completion. Native progress, delivery/work, costs,
RNG, construction timing and ordinary instant placement remain unchanged.
Construction inspector advice now uses native halt, road, remaining material
quantities and assigned artisans. Native far-corner pyramid targets are accepted
only when their checked ID and tile lie inside the current rendered footprint.

Cached model base hulls produce limestone skirts only over actual land gaps,
inside the lot, with road/water/hole exclusion and a bounded maximum drop.
Supports/scaffolding are grouped into 32-tile sections and retain unchanged
geometry through work/stock refreshes. Native foundations remain level at their
original heights. Completed/unaffected buildings keep their source GLBs/UVs/LODs.

Empty newly begun adventures offer the manual guide after loading; explicit
Finish guide remembers the presentation preference. A smoke test creates empty
owned land from a disposable designated city using normal native demolition,
then constructs a road, vacant house, fountain and maintenance office. It verifies
real empty-city milestones and road/staffing explanations without test residents
or stock. The first replay test's unregistered temporary-save load was corrected:
new guards require successful opens and compare actual gameplay digests plus
same-session serialized bytes. Cross-load binary save hashes are not claimed
deterministic. Final EN/RU Metal and headless evidence is in validation.

Full first-settlement immigration/food/budget playthrough, material painting,
new anatomical work/construction animation, independently planted feet and
minimum-Mac profiling remain pending. Construction/support studio samples are
disposable views of real source meshes with presentation fixtures, not new native
buildings or save modifications.

## City clarity and art finish, first pass — 7 October 2026

Implemented a separate native `city_attention` observation with clickable,
filtered building warnings. It uses all current-city building objects, including
static roads, while preserving inspector tokens, events, RNG and the clock.
Target IDs/footprints reject stale selections. Inspector advice names actual job
vacancies/input shortfalls, edge road access, stock awaiting collection and
current-level housing needs. Optional upgrades remain house-inspector guidance.
A six-step non-modal settlement guide uses native observations and existing
overlays, with explicit player progression. Theme/CSV and EN/RU scaling remain.

Eligible static everyday architecture and defences now use a cached, restrained
stone finish; both UVs, palettes, LODs, metals and textured/animated materials
are retained. Existing work VAT poses use bounded cubic interpolation with the
same native flags/clock. Cached human sole-area root clearance reduces slope
penetration, preserving routes/stride/perched guards/boats/gods. Unfinished
monument inspectors show the native percentage alongside existing growth.
An opt-in synthesized original lyre/flute and countryside soundscape includes
reproducible source/hash provenance; existing battle/effects/voices remain.

The extension builder stages and signs a separate inode before atomic installation
so the user's running game keeps its old mapping. The new implementation loads
on relaunch. Current evidence is in `GODOT_VALIDATION.md`; contracts are in
`GODOT_CITY_CLARITY.md`. Fresh-settlement playtesting, broader composite-owner and
campaign warning coverage, user art/audio acceptance, painted PBR, full slope IK,
new worker/construction animation, finished varied music and minimum-Mac GPU
profiling remain pending. This completes a bounded first pass of priorities 3/4,
not the full production art/onboarding release gates.

## Building refresh performance, second pass — 7 October 2026

Implemented an exact presentation-state filter for changed native building lists.
Inspection records still refresh, while unchanged geometry/work flags/bay goods
skip the scene rebuild. Native growth/facing/footprints, placement revisions,
overlays and explicit invalidation bypass it. Minimap footprint rows retain
building colours through terrain deltas and clear them on removal/evolution.
Agora paving persists through stock changes, and fixed-template MultiMeshes
reuse their nodes/buffers for count and transform changes. Resizing restores all
per-instance work data; steady activity skips uploads. Identical default animal
VAT finishes share a cached material while each instance retains its exact pose.

Paired owned Metal checks measure about 84% less CPU work for a routine unchanged
building refresh (13.35 to 2.10 ms, 120 alternating pairs). The benchmark uses
frozen prior refresh methods in a disposable subclass and never changes C++.
Current native activity/storage, camera, GPU, overlay/growth and placement gates
pass; validation records the scope. First-use loading, actual geometry changes,
GPU timing and sustained minimum-Mac/user-city performance remain open.

## Camera panning performance, first pass — 7 October 2026

Implemented eased, cursor-anchored wheel zoom with accumulated notches and
cancellation for modal input, Home, Go to and an atlas transition. Pinch and
explicit `zoom_at` callers retain immediate terrain anchoring. Idle keyboard
orbit/tilt no longer rewrite the camera transform twice per frame.

The existing snapshot tile loop now collects native road-kind changes for a small
wide-road index; ordinary movement never rescans map topology. Each citizen reuses
its unchanged lane classification and ground sample, and moving citizens sample
only the final lane-adjusted position. Cached VAT poses skip identical writes,
including aliases and held combat frames, while clocks, planar stride, blends,
god float and LOD phase remain live. Native positions/routes are unchanged.

Building placement caches retain facing, setback, foundations and scale across
work/inventory changes, invalidating on road/elevation, footprint, asset, facing
or construction growth. Existing `buildings_changed` gating and incremental
MultiMesh uploads remain. Camera footprints are cached by transform/projection,
viewport and geometry revision; hidden minimap updates are skipped while native
visible sound bounds remain current. Physician skeleton spares are prepared only
when nearby detail is in use, avoiding an unused first-load hitch at ordinary
camera heights; the existing nearest-24 role mapping is retained.

Scoped checks and an owned 1920×1080 Metal profile pass. Running panning's measured
presentation CPU time falls about 26%, with unchanged graphics/model budgets.
Short samples still show some refresh/first-load spikes; no sustained minimum-Mac,
GPU-time or user-city guarantee is claimed. Native tick cadence, rules, RNG and
save formats remain unchanged. See `GODOT_VALIDATION.md` for measurements and scope.

## Character card and native inventories — 7 October 2026

Implemented the centered dock-matching character card with a smaller portrait,
inset speech/voice area, bounded content scroll and separate persistent footer.
The shared Theme/EN/RU strings retain independent interface/text sizes. Painted
portraits keep their disabled 3D viewport; the existing model fallback, voice,
other-walker selection, camera focus and previous pause/command hold remain.

The read-only `character_info` observation includes inventory; a separate
`character_inventory` query refreshes it without selecting a new spoken line or
drawing RNG. Peddlers report their linked Agora's native stock/capacities/presence,
transporters report actual resource/count in cargo loads, and growers report
collected fruits. Existing resource illustrations and stable in-place stock
cards match the Agora's supplies. No independent peddler stock is invented:
native distribution consumes the Agora directly. Missing vendors and empty cargo
have explicit states. No rule, route, production, saved-data or model change.

The extension is rebuilt/finalized/ad-hoc signed. Focused native checks and owned
sequential EN/RU Metal reviews use scratch preferences/saves; their prepared city
spawns its peddler through ordinary native ticks. See
`GODOT_CHARACTER_INVENTORY.md` and current validation for evidence and limits.

## Slim instant-notice presentation — 7 October 2026

Removed the visible title/icon row and Close button from open instant notices.
The full message and timeout bar retain the shared Theme, independent text
scaling and bounded scrolling. The message card now handles click-release
pin/unpin, keyboard activation and right-click-release dismissal through the
existing informational acknowledgement. Its title remains available in hover
context and journal history. Empty-body notices fall back to their title so a
native report cannot become blank.

History disclosures retain their titled buttons. Single-alert queuing, full
history, hover/reading/hidden/clipped timer holds and original required-decision
callbacks remain intact. This is a GDScript/CSV change; native rules, timing,
event records, save layout and assets are unchanged. Verification is recorded
in `GODOT_VALIDATION.md`.

## Monster anatomical geometry — 7 October 2026

The user's rejection of doll-like monsters supersedes the sixteen v1 reference
sculptures. Godot now installs the `monster_anatomy_v3` rebuild through the existing
stable asset identities and pose contracts. Full CC0 human anatomy, an actual CC0
canine body/skull, a CC-BY cave-lion face, CC0 crocodilian skull planes and the
unchanged project quadruped library form the creatures. Original monster features
follow the sixteen images in the user's Monsters folder. Hybrid body junctions,
flat cloven hooves, canine irises, wing roots and dorsal plates were corrected
after rendered inspection. Surface-family finishes remain cached and compatible
with VAT. Separate neutral v3 Blender scenes retain editable anatomy/pose recipes.

Native simulation/rules/RNG/saves and Hydra's source/runtime/baseline are retained.
Both UVs, palette, 114 aliases, species mouths, 16,500 source/34,000 imported
geometry caps, at most three surfaces and reduced LODs remain required. Only the
sixteen intended baseline entries change. Earlier runtime assets are backed up.
The reference, previous geometry and installed views share a local comparison
gallery; library licenses, authors, source hashes and adaptations are recorded.
Read `GODOT_MONSTER_ART.md` and the latest validation before re-exporting.

This stage supplies anatomical game meshes and procedural preview finishes.
Painted PBR baking, user visual acceptance, slope foot IK, harpy flight refinement,
minimum-Mac performance and overall release-rights evidence remain pending.

## Common housing art and height progression — 6 October 2026

Installed Godot-only replacements for the seven active common-house models,
`common_house_<0-6>a`. The first two are original compact wattle/daub and mud-brick
dwellings with reed roofs and household details. Higher levels retain their
authored Greek domestic geometry. Muted irregular soil and grey paved courts
replace the golden lots. Architecture heights now rise monotonically through
0.96, 1.16, 1.36, 1.58, 1.84, 2.18 and 2.56 native tiles. Resident body dimensions
are preserved independently of the architectural height adjustment.

The export adapter/recipe registry preserve native sprite sources and live
Blender scenes, both UV sets, vertex palettes, bounded PBR surfaces and reduced
imported LODs. Source vertices fall from 512,685 to 153,299 across the family;
this is a source-geometry reduction, not a measured frame-rate improvement.
Only these seven geometry-baseline entries were refreshed. Starter entrances
use the existing road-facing presentation adapter. Native simulation, housing
needs/occupancy, prices, two-by-two footprints, upgrades and saves are unchanged.

Focused art/native/owned Metal checks pass 55/30/25. The model-family, first-level,
city and catalog captures were inspected; source save, player preferences and
native house artwork hashes remain unchanged. See `GODOT_HOUSING_ART.md` and
`GODOT_VALIDATION.md`. Elite houses and unused b variants retain their models.
User visual acceptance, full material baking, more appearance variants and
sustained minimum-Mac profiling remain pending.

## Ruin inspection and whole-building clearing — 6 October 2026

Implemented former-building names from the native saved `eRuins::wasType`, a
ruin-specific inspector with a costed Demolish action, and one complete footprint
for selection, demolition hover and rectangle contact. New collapses share a
transient site identity across their native rubble tiles. Existing saves recover
bounded sites from native type dimensions and saved creation order; neighboring
complete buildings of the same type remain separate.

Native rubble remains one object per tile. Clearing calls the native eraser once
per actual rubble object and charges the existing per-tile erase cost. Fire,
ownership, credit and pending-decision restrictions apply to the entire site.
Independent inspector/tool guards reject stale object sets without inspector
refresh invalidating another demolition hover. Save serialization, collapse RNG,
production, routes and simulation timing are retained. Older saves contain no
original site ID; fragmented, unknown or compound legacy footprints can only be
recovered conservatively. Verification and captures are in `GODOT_VALIDATION.md`.

## Placement preview road clearance — 6 October 2026

Single-building ghosts and area-drag models now share the existing
`StreetSetback.apply` used by installed building batches. Previously only the
installed building stepped back from widened roads, leaving its ghost overlapping
the edge. Native placement quotes, full footprint markers, costs, picking and
simulation rules remain authoritative; roads and exempt structures retain their
existing fitting. Verification and matched theater captures are recorded in
`GODOT_VALIDATION.md`.

Rounded-corner follow-up: the ground shader now limits inward paving bulges to
a 0.18-tile rounded plot contour. The curve clears existing building setbacks
without further shrinking buildings. It uses the retained road texture; native
road cells, straight width, outer rounding, previews, picking and simulation
coordinates are unchanged. GPU corner probes and matched house captures cover
the rendering change; see validation for scope and measured cost.
The user's close review rejected the first corner correction's stacked kerb
ends. The final contour evaluates neighboring plots on both sides of each tile
border; the shared continuous field replaces that discontinuous branch.

## Avenue and boulevard presentation — 6 October 2026

Implemented continuous paving across the native two/three-tile corridors,
blue-grey promenade borders and original procedural marble statues, benches,
flower pockets and edge foliage. Shared read-only topology places ornaments only
along clear straight outside edges. Meshes are cached, spatially batched and
have reduced LODs. The former grass median and centered trees are superseded:
the retained native core treats that median as a walking road.

Wide-road rendering now bounds the eased lateral lane, merges it continuously
at diagonal bends and uses displayed displacement for human heading. Native
tracks, patrol decisions, gait distance, timing, construction, costs and undo
remain authoritative. Street cards have distinct cached miniatures and translated
full-width facts without changing the one-cell native drag anchor.

Verified with 70 street contracts, 18 isolated Metal/native construction and
catalog checks, and retained locomotion/detail/text gates. The source save and
player preferences remain unchanged. See `GODOT_VALIDATION.md` for fixtures and
captures; broad live campaign patrol coverage, minimum-Mac profiling and user
visual acceptance remain pending.

Wall panel follow-up (6 October 2026): removed the visible fill checkbox from
building choices and clarified the EN/RU placement hint. Normal outline dragging
and Shift-drag native filled rectangles remain; no simulation/export change.

## Illustrated notification hub — 6 October 2026

Implemented a fixed upper-right utility/alert rail, replacing the old message
and threat glyphs and permanent objective summary. Original static SVGs extend
the existing dock art without Blender, live render viewports or model changes.
The shared Theme styles the rail/buttons/scrollbar; independent count badges,
objective progress and finite motion-aware highlights are drawn by a reusable
ToolbarButton subclass.

Objectives is an on-demand disclosure with its original native cards/set-aside
callbacks. Journal adds All reports / Warnings / Decisions view filters while
retaining full history, occurrence wording, unread semantics and stable rows.
Existing quiet routine delivery and single urgent-alert queue remain. Required
native choices keep their automatic centered modal, exact callbacks and pause;
a persistent amber seal replaces the folded reminder panel.

Grouped hazard/monster buttons scroll below the utility icons with bounded
height, fixed stock-independent position and original native site/hero actions.
Hidden/clipped/focused controls and blocking dialogs hold attention timers;
integer scroll height fixes enlarged-scale bottom-row clipping. Goal, journal
and monster disclosures clear one another and fit left of the rail above the
dock without moving construction controls. Native core/build/rules/RNG/saves
remain unchanged. See interface and current validation for evidence and limits.

## Wall-height refinement — 6 October 2026

At the user's request, raised the marble wall walk from 1.45 to 2.0 tiles (about
38%) to bring its silhouette closer to the gate and tower. All sixteen mask
pieces retain their design, footprint and widths; guard lift follows the shared
art contract. The tower/gate GLBs and their geometry baselines are retained;
only their shared roof-contract metadata is refreshed. Only the sixteen wall
baseline entries may change for this height adjustment. Current validation and
updated assembled captures are recorded in the validation document.

## Taller marble defences and guard placement — 6 October 2026

Completed the interrupted Godot-only defence builder and connected it to the
exporter/recipe catalog. Installed eighteen models: sixteen wall masks, tower
and gatehouse. White coursed marble, broad battlements, matching meander bands,
fluted Ionic gate columns, carved laurel relief and pediments replace the previous
Roman brick/travertine designs. Wall walk rises from 0.8 to 1.45 tiles; tower floor
rises from 2.57 to 3.05. Gate pylons rise to 3.64 including their roof ornaments.
The full native one-tile passage stays clear between its embedded portal columns.

`defence_perch.gd` indexes wall/tower footprints only during the existing building
refresh. The original native `lift` identifies perched guards; the Godot art
contract supplies their height. Interpolated render positions are bounded inside
the tower battlements or projected onto connected wall walks, at the building's
foundation. Perched guards have no road lane offset. No C++ library, native patrol,
coordinates, attack rules, RNG, construction costs or saves changed. Ground archers
using the same model keep their ordinary presentation.

Geometry is grouped into one/three compatible PBR surfaces, with retained authored
UVs, palette colors and reduced imported LODs. Only the eighteen intended geometry
baseline entries were updated. Native SDL sprite sources/atlases and live Blender
scenes remain intact. Focused art/placement checks, native walls regressions,
geometry gate and LOD silhouette audit pass; an isolated Metal review captures the
assembled design and moving guard. See `GODOT_DEFENCE_ART.md` and current validation
for counts, files and limits. User visual acceptance, texture baking, extended
terrain transitions and minimum-Mac performance remain pending.

## Compact overview and message-width correction — 6 October 2026

Implemented the accepted content-sized horizontal overview at the upper left,
with city name, housing, treasury/monthly balance, population/mood and Resources.
The disclosure shares its left edge and width. The shared ResourceRibbon style
now explicitly inherits PanelContainer, so its compact padding and 90% background
are used rather than the generic panel fallback. Readings/icons remain opaque.
Clock/map/dock placement, cached native values, input callbacks and simulation
rules are retained.

The attached message recording showed a normal-width report collapsing to its
icon/Close minimum. Body fitting reset the PanelContainer's assigned size every
frame, and pin/unpin also reset it. Cards now fill the parent VBox and update only
their bounded body minimum height, leaving width to container layout. The shared
NoticeBody font variation replaces a hard 15-pixel override, preserving independent
text scaling. Full text, scroll identity, pin/hidden timer holds, queued alerts and
informational acknowledgements remain. No required-decision callback or native
pause logic was changed. Sequential EN/RU chrome and headless notice regressions
pass; see validation for captures, counts and remaining coverage.

## Jobs, clock and utility hotkeys — 6 October 2026

Implemented the user's next HUD arrangement: Jobs follows Layers in the bottom
main row; the construction label is centered; the map icon hides while the map
is open; and Play/Pause, speeds and date form a compact panel beneath the map.
Measured map/clock bounds preserve the dock's clear space and independent
interface/text sizing. Native speed/pause, employment-view callbacks, availability,
map transforms/preferences and required-decision input ownership remain.

Main-row hover titles now show rebindable Housing H, Road B, Road Block G,
Layers L and Jobs J, alongside existing X/Delete and Cmd/Ctrl+Z. Category labels
are retained. Older custom bindings take priority over new defaults, leaving a
colliding new action Unassigned until rebound. Original construction callbacks
and existing dialog/typing gates are shared; simulation code/assets are untouched.
Disposable sequential EN/RU toolbar/chrome reviews and the controls/input gates
pass; see current validation for counts, captures and tested presentation limits.

## Toolbar shortcut consolidation — 6 October 2026

Implemented the user's updated dock layout: upper-left City views move into
Layers, duplicate Inspect/Build controls are hidden, Undo moves to the left with
housing/road/roadblock/demolition shortcuts, and the map icon sits beside the
circular map. Categories retain the complete native build catalog. Layers offers
all 25 existing views, bounded scrolling, translated help and predictable input
return; it does not alter the simulation. Native availability, ghost/placement,
Undo, overlays, map preferences/transforms and required-decision pause/callbacks
are retained. An original SVG supplies the roadblock shortcut artwork. Current
focused review evidence and remaining scope are in `GODOT_VALIDATION.md`.

## Main-menu loading transition — 6 October 2026

`ui/loading_screen.gd` owns a root CanvasLayer that survives the menu/city scene
change. `start_menu.go_city` shows it and waits for layout and a real draw before
synchronous native/model work begins. The menu and city hold their processing
and input during the handoff. `main.finish_city_loading` clears the surface only
after the initial native snapshot, terrain/models, HUD/catalog and a rendered
city frame are ready, then restores normal processing. Continue, selected saves,
Begin and the common editor handoff share this path. Automation that skips the
menu retains its direct startup.

The shared Theme and CSV translations provide bounded EN/RU content and
independent size preferences. The moving activity bar gives no percentage and
stays still with Reduce interface motion. Duplicate actions preserve the chosen
session; failure recovery returns to the menu. The retained broken-save fallback
is unchanged. Native simulation/loading stays on the main thread, without new
worker RNG, pause commands or gameplay changes. Begin still adopts its existing
simulation once and creates `autosave replay`, after the surface has drawn.

The focused review covers actual Continue, Load save and Begin input, complete
city readiness and recovery controls with disposable profiles. See validation
for counts, captures and limits; minimum-Mac loading performance and a fully
asynchronous loader are not established by this presentation change.

## All remaining monster reference sculptures — 6 October 2026

Implemented all sixteen requested references and 3D models: Cyclops, Talos,
Hector, Minotaur, Satyr, Medusa, Maenads, Harpies, Calydonian boar, Cerberus,
Chimera, Sphinx, Dragon, Echidna, Scylla and Kraken. Individual generated sheets,
exact prompts, background Blender sources, staged lossless exports and installed
GLB/VAT models are recorded in the parent art catalog and repository provenance.
Six verified species screen studies plus two film anatomy/silhouette motifs
inform eight designs; the other eight retain original game/myth anatomy, with
unverified screen references explicitly identified. Hydra remains unchanged.

`tools/godot_monster_reference.py` replaces only these Godot presentation models.
The eight former humanoid monsters bypass the citizen anatomy/1.12 scale adapter;
the retained 104 human assets remain covered by their own validator. Neutral
heights are 1.79–2.14 tiles, all non-death tops below Zeus. Each monster has 114
in-place walk/idle/fight/fight2/die samples, per-mouth probes and grounded collapse.
Shared effects use all authored mouth counts while retaining native projectile
timing/damage/collapse and bounded two-batch geometry. Both UV sets, palette,
fresh derivatives, material caching and imported reduced LODs are retained;
only these sixteen geometry baselines change. Native recipes, simulation, RNG,
map and saves are unchanged.

The art remains a development reference pass. Generated concepts have finer
surface detail than the procedural sculptures. User visual acceptance, painted
material baking, slope foot IK, harpy flight refinement, minimum-Mac profiling
and release rights are pending. Scoped checks and representative EN/RU city
reviews are recorded in the latest validation; broader unrelated animal/worker
asset failures remain visible. Read [monster art](GODOT_MONSTER_ART.md).

## Complete construction previews — 6 October 2026

Fixed generic Common/Grand Agora pictures and shared component-image caching.
The thumbnail factory now accepts catalog items and assembles native composite
layouts from existing model files using a read-only placement query at one actual
map cell; its placement verdict is irrelevant to the picture. Empty agoras have
their native three/six paved plots and street. Palace/ranch/sanctuary/pyramid/
shrine/god-monument cards show full layouts, with pyramid faces aligned in the
isolated preview. Cache identity follows the building design, sharing only trade
partner variants. One idle-disabled viewport, bounded textures and freed display
instances remain. Native gameplay/rendered-city models, coordinates, rules and
saves are unchanged. See current validation for audited versus rendered scope.

## Static illustrated header icons — 5 October 2026

Replaced the live 3D coin with original shaded treasury artwork and the people
outline with an illustrated citizen pair, extending the dock's existing SVG
system. Both use equal 24×24 logical-pixel TextureRects in the authored HUD.
The live coin viewport and gain-flip path are no longer instantiated; the old
source remains intact. Native money/population/ledger/mood, hover help and
responsive input/layout contracts remain. See validation for scoped evidence.

## Matching HUD chrome and visible map — 5 October 2026

Implemented shared charcoal/bronze panel surfaces matching the illustrated dock,
a narrower centered overview with reduced padding/header typography and measured
text/gauge bounds, and matching resource disclosure width. Full native counts,
four speed callbacks, hover help, focus ownership and responsive wrapping remain.
Inspector/Army/journal/objective/notice/dialog frames retain their content margins,
scrolling and native state. Parchment and semantic status colors remain distinct.

Removed the bottom-left City map shortcut and changed the initial map preference
to open. Unversioned old preferences adopt this default without a launch write;
later explicit choices are versioned and persisted through the existing settings.
The dock toggle, fold control, circle picking and temporary presentation folds
remain. This supersedes older folded-default/pill requirements. Native rules,
timing, coordinates and saved cities are unchanged. See current validation scope.

## Compact city overview — 5 October 2026

Removed the seven visible top-bar captions at the user's request and centered
the remaining readings/controls. Time controls now run Play/Pause → speeds 1–4
→ date. Hidden unique nodes preserve existing scene/
translation references. Native data, hover help, responsive bounds, pointer
activation and keyboard ownership remain intact. This supersedes the earlier
visible-caption design.

## Toolbar pointer activation correction — 5 October 2026

Fixed the shared button's premature focus release: it now defers release on
mouse-up after native activation instead of mouse-down, which canceled a press
held across frames. This restores top/bottom bar clicks without changing native
callbacks, pointer cancel behavior or keyboard ownership. Corrected chrome/dock
reviews hold the press across frames, and a separate presentation regression
uses ordinary untagged events. See validation for before/fix evidence and scope.

## City overview and panel review — 5 October 2026

Implemented explicit top-bar captions, free-housing wording, separate treasury/
monthly-balance readings, a named resource disclosure and numbered native speed
settings. Shared Theme/CSV and bounded hover help retain the existing native
date, occupancy, employment, stock, popularity and ledger observations. Gauge
labels measure their full text; the complete statistics group moves into a
second row at narrow/enlarged layouts. Native pause/speed callbacks are unchanged.

Header keyboard navigation holds camera input, including Home; Escape/right-click
folding Resources releases ownership. Army now fits the actual header/dock bounds
with a fixed title/Close and scrolling company/action content. Names retain full
hover text and native unavailable-order predicates have explanations. Inspector
context uses native footprint/staffing, stored-good names wrap, inspector/journal
scrolling follows focus, and objective counts follow locale grouping. Native
company commands, inspector drafts/tokens, goals, saves and simulation rules remain
unchanged by the implementation.

Scoped EN/RU disposable-city reviews cover these layouts and original GUI routes;
the optional native Army phase exercises actual orders only in unsaved scratch
memory. Separate headless fixtures cover empty/long-name/abroad/aid companies.
See validation for final counts, captures and protected hashes. Other-campaign
coverage, gamepad navigation and sustained performance remain separate gates.

## Illustrated construction toolbar — 5 October 2026

Implemented a dark two-row bottom dock based on the user's Anno layout reference:
original colored category illustrations, distinct city tools, an immediate hover/
focus name and explanatory tooltips. Gold now identifies selection. Static SVGs
replace the ambiguous toolbar glyphs without adding live previews or changing
the running Blender scene. Shared Theme/CSV retain independent UI/text scaling
and English/Russian copy.

Native category eligibility, exact model cards/costs and existing selection,
Undo, map and overlay callbacks remain intact. Identical catalogs preserve
controls/focus/scroll. Keyboard-owned menus suppress camera movement and clear
old drags; selecting a tool/view or closing the tray releases ownership. Native
release activation prevents the opening click from picking a bottom-popup item.
The duplicated direct house shortcut and hidden tray search remain hidden.

Scoped disposable-profile reviews cover native catalog routes, pointer/keyboard
focus, hover help and 1920×1080/1280×720 at default and enlarged interface/text
sizes. See validation for actual results, save/preference hashes and captures.
User visual acceptance, gamepad coverage and other-campaign category availability
remain pending; this presentation change adds no simulation or save rules.

## Required-decision presentation — 7 October 2026

The expanded envoy card is now centered above the city HUD, with a dim input
shield, compact framed sender identity/portrait and a dark ivory-text reading panel. Its
fixed footer orders native actions by their callback meaning, independent of
translated labels: ordinary Refuse → Postpone → Dispatch/Send troops/receive,
and invasion Surrender → Bribe → Defend. Unavailable actions stay absent; multiple
eligible receiving cities retain equal emphasis.

Native blocking, event IDs and original reply/enlistment callbacks are preserved.
Right-click on the expanded card or folded decision icon invokes an available
native Postpone callback through the same guarded reply path as its button.
This supersedes the previous fold-only right-click behavior. Invasions' choice
1 remains Bribe, and decisions without Postpone only fold. Queued replies are
debounced; full queues and rejected commands preserve the visible unanswered
card. Native Postpone releases its own clock block while preserving a manual
pause and any other pending decision. Fold/title-toggle/Escape, game-menu return
and enlistment cancellation never answer a decision.
The expanded card blocks city/camera input, owns keyboard
focus, and takes Escape priority over a journal behind it. Layout responds to
logical viewport and independent UI/text sizes; full correspondence scrolls
above its choices. Shared Theme styles and EN/RU CSV keys supply the
presentation; static native envoy portraits introduce no live render viewport.
The current card matches the charcoal panels, subdued gold borders and shared
button styles, with a translated right-click hint. The focused Theme generator
option preserves unrelated entries; native rules, saves and callbacks stay intact.
Sequential disposable EN/RU reviews and native request regressions are recorded
in the validation document. Wider platform/gamepad and visual acceptance remain
separate from this scoped verification.

## Campaign-panel presentation — 5 October 2026

The shared authored episode card now has a chapter/result banner, separate native
episode counter, readable parchment story and individual objective cards in an
independently scrolling column. Achievement colour/checks and the result summary
follow native `met` flags. Original SVG art and `Episode*` shared Theme variations
provide the presentation; all interface labels and arrow tooltips use the CSV.

Both hosts fit the card to the logical viewport and independent interface/text
sizes. The footer keeps difficulty and Begin/Continue/Back/retry/menu actions
accessible; difficulty arrows now accept keyboard focus. Native story text,
quantities, narration, pending choices, campaign commands and session handoff
remain authoritative. Actual campaign-flow and sequential visible EN/RU evidence
are in [validation](GODOT_VALIDATION.md). User visual acceptance, gamepad coverage,
narrower-window review and minimum-Mac profiling remain pending.

## Main-menu hierarchy and accessibility — 5 October 2026

The authored main page now separates profile, latest-save card, primary New game
action, Load game/editor and utility controls. Original SVG emblem/action icons
and `MainMenu*` shared Theme variations provide the finish. Continue retains
the exact newest native save path, with its name and metadata in the card rather
than inside the button. Empty profiles hide that card and focus New game.
Language displays the current locale; Settings has a visible label and keyboard
focus. All interface copy uses the translation CSV.

The left panel sizes to its content and available logical viewport; its scroll
container follows focus at enlarged interface/text sizes. The gateway remains
the existing 3D scene. Profile switching, save listing/loading, native adventure
and editor flows, sound and display/interface/controls dialogs are preserved.
Sequential scratch-profile English/Russian reviews and scoped limits are recorded
in [validation](GODOT_VALIDATION.md). User visual acceptance, gamepad navigation
and minimum-Mac profiling remain pending.

## Field-worker activity — 5 October 2026

Hunters now play spear attacks and display their native prey load on the return
trip. Sheep handlers shear with hand-anchored tools and carry fleece; goat
handlers milk and carry a jug. Growers prune/pick vines and olives, and native
orange tenders use their own tree-working model and clips. Corral workers guide
cattle with a crook; the building's existing processing cycle follows actual
native processing. Boar/deer attack and collapse poses are connected. Work,
carry/leading phase, pause and transitions follow native observations/time;
empty hunting/livestock returns display no invented goods. Native rules, coordinates and saves
stay intact. See [field-work contracts](GODOT_FIELD_WORK.md) and the validation evidence for
export sources, geometry budgets, review fixtures and remaining limits.
Verified: 235 field-work checks, 1,661 imported pose samples, all nine UV/pose
optimization proofs, geometry/LOD and six seeded replay cases; eight visible
views pass in each launch language. The saved city and player preferences stay
unchanged. `godot/captures/field-work.gif` records the new work/return motions.

## Adventure library and opening-goal cards — 4 October 2026

The authored start-menu adventure page now pairs a scrolling native catalog with
an illustrated card on the right. Native bitmap IDs select the same pictures as
the SDL menu, with loose development overrides first and packed `interface.e`
artwork as fallback. Warm paper, a bronze title band and mode badge organize the
campaign description and all first-episode goal rows. The episode label distinguishes
parent episodes and alternative colony scenarios. Independent interface/text sizes retain bounded
scrolling details and accessible Start/Back controls.

A guarded `EZeusSimulation.adventure_preview` reads the first parent episode's
templates, shares native goal wording, then frees the campaign. It never calls
`startEpisode`, enters a city, attaches event handlers, adopts a session or saves.
It refuses preview requests while a city owns the native globals. The parent
world district supplies Greek/Atlantean military wording before a city starts.
Sandbox classification requires no goals across all parent and colony templates;
an opening episode without goals in a later objective-bearing campaign remains a
campaign. Cache keys include language, kind and reference; a generation guard
coalesces quick selections and cancels departed-page work. Start/difficulty/
briefing Back/Begin and editor commands retain their native flow.

No gameplay rules, installed source artwork or live Blender scene were changed.
Artwork metadata is checked against native packed offsets/crop bounds; runtime
images are bounded to 960 pixels and 18 IDs. Original/development asset provenance
and independent-production release gates remain. User visual acceptance, narrower
windows, campaign-author edge cases and minimum-Mac profiling remain pending.


## World-map realism and keyboard slice — 4 October 2026

Implemented coastline clipping of the submerged relief sheet, finer sea-sphere
geometry (192 segments / 96 rings), world-oriented ripple normals and a
nonmetallic sea finish. Land uses varied vegetation/limestone/strata shading,
woodland instances vary in size, and cloud cards use softer density. Coast/height
fields and their native city anchors are retained.

The atlas now shares held city camera bindings/speed preferences: arrow/WASD pan,
Q/E orbit, R/F tilt (25–75°), Shift boost. Arrow keys no longer cycle cities;
on-screen selection arrows retain that role. Modal/typing/cinematic/focus guards,
bounds, projected labels and native command isolation are preserved. The authored
scene has a compact framed heading/toolbar, narrower side panel, circular portraits
and read-only native owned-city stock. The flight fades the complete toolbar by
its unique scene name rather than its former layout path.

Standalone EN/RU Metal reviews pass **61 each**, flight **37 each**, native-world
UI **16 retained + 5 integration each**; current geometry is **35 meshes /
185,640 triangles**, inside the retained 100 / 220K limits. Evidence and remaining
limits are recorded in [validation](GODOT_VALIDATION.md). This is a presentation
slice, not geographic reconstruction, art acceptance or a production performance
gate.

## Fishing spots and authored gathering — 4 October 2026

Implemented read-only native fish/urchin deposit flags in appended tile column 9,
procedural fish schools/urchin clusters and gameplay-timed surface movement.
Fishing skiffs have an authored 40-sample cast/settle/hand-over-hand haul cycle,
with net line linked to solved hands and oars stowed during collection. Urchin
workers have 40 dive/reach/recovery samples, 12 bag-carry and 12 deposit samples.
The Godot-only dip timing retains a longer visible recovery through opaque water.
Work uses native action observations and 0.22-second transitions, shared by VAT
and blend-shape fallback. Small glints and three phase-gated diver bubbles
replace whole-body root tilting and a separate floating net.

Native positions, travel stride, production, pathfinding, regrowth, RNG and save
formats remain authoritative. Geometry LODs, 32-tile spatial batches and bounded
worker effects are included. See [water-life contracts](GODOT_WATER_LIFE.md)
for sources and reviewers; evidence belongs in [validation](GODOT_VALIDATION.md).
Underwater refraction, wider campaign visuals, user visual acceptance and
minimum-Mac profiling remain pending.

## Monster combat effects slice — 4 October 2026

Implemented a read-only native missile launch/impact/cancellation observer and
a bounded Godot renderer for all 17 monster kinds. Hydra has green venom breath,
a travelling trail, contact splash and native-collapse dust with stone debris;
other monsters share a generic warm attack finish. The observer retains flights
that begin and end between snapshots. Damage, attack delays, collapse, sound,
coordinates, RNG, serialization and the 20 Hz native tick remain authoritative.

The renderer uses two shared MultiMeshes and native game time; pause and decisions
freeze every effect. Existing fight/die poses and building fire/smoke are retained.
See [contracts](GODOT_MONSTER_EFFECTS.md) and scoped evidence in the validation
document. The Hydra model and animated mouth anchors are implemented below.
Individual effects for other species, same-tile hit bursts and minimum-hardware
GPU profiling remain pending.

## Hydra reference model — 4 October 2026

Implemented the concept as a Godot-only three-headed quadruped with a heavy
body, swept spines, charcoal scales, red eyes and fitted ventral bands. The
stable `walker_hydra` identity now loads the new GLB. Measured neutral height
is 2.1 times a displayed citizen and 81% of Zeus; raised poses remain below Zeus.

Authored 24 walk, 12 idle, 24 fight, 24 fight2 and 30 collapse samples. Paws
counter native .64-tile travel during support; roots remain in place. Three
mouth samples per pose interpolate venom anchors through actual facing and
terrain-following root height. Grouped palette materials, both UV sets, mesh
LODs and the VAT/fallback workflow are retained. Only Hydra's baseline changes.
Native art recipes, monster rules, timing, RNG and saved cities remain intact.

The editable Blender source, reproducible adapter and provenance are described
in [monster art](GODOT_MONSTER_ART.md); scoped evidence is in
[validation](GODOT_VALIDATION.md). User art acceptance, full material baking,
slope foot IK, wider campaign coverage and minimum-Mac profiling remain pending.

## Elder curator panel-only benchmark — 4 October 2026

Implemented one 68-year-old curator portrait (`elder_curator_portrait_v2`) with
an anatomical aging pass, corrected facial landmarks, surface-sampled tapered
hair/beard/brow fibers, and isolated close-up skin/eye finish. Character-panel
framing and sampling are improved for this specimen only. Native identity,
voice, decisions, clock, city crowd, and physician benchmark remain unchanged.
Export after the eyebrow correction: 506,830 vertices, 37,123,320 bytes, three surfaces, no skeleton or clips.
This budget applies to one on-demand portrait, never the crowd. Reusable source,
visual direction, rebuild steps and transfer caveats are in
[GODOT_PORTRAIT_REFERENCE.md](GODOT_PORTRAIT_REFERENCE.md). Scoped verification is
in the validation document. User acceptance, facial animation, painted PBR skin
textures and minimum-hardware profiling remain pending.

## Storage building goods display slice — 4 October 2026

Warehouses, trading posts, and granaries now dynamically display their stored goods
and food items as 3D instanced meshes on top of their storage yards and drum bays,
matching native simulation inventories and eZeus visual behavior.
- **Warehouses (3×3)** display their 8 paved bays with authentic 3D stacks of wine barrels,
  marble blocks, black marble, fleece bales, sculptures, amphorae, olive oil, and raw goods.
- **Trading Posts (4×4)** display their 15 perimeter bays with dynamic piles matching trade inventories.
- **Granaries (4×4)** display their 8 radial wedge bins inside the upper drum, showing 3D heaps
  of wheat, carrots, onions, cheese, salted meat, dried fish, sea urchin, and oranges.
- MultiMesh spatial batching groups storage goods into existing spatial chunks with zero performance overhead.
- Snapshot serialization in `EZeusSimulation` detects changes to storage bays and emits updates only when goods quantities change.
- Automated validation suite `validate_storage_goods.gd` passes **204 / 204 checks**. All 421 project assets pass `validate_assets.gd`.

## Hillside appearance slice — 3 October 2026

Native blocked slopes and cliff sides now show layered, weathered limestone with
world-space projection and subtle normal relief. Grass blends into upper edges;
road ramps and foundations retain their existing materials and heights. Steep
cosmetic countryside shares the finish. No geometry, native state, routes,
placement or timing changes. See `GODOT_TERRAIN.md` for the material contract and
`GODOT_VALIDATION.md` for matched captures and scoped checks. Further silhouette
remodelling, wider campaign art review and minimum-Mac GPU profiling remain pending.


30 September 2026: the native simulation now runs directly inside Godot 4.6.3
through GDExtension. Normal launch no longer starts the SDL game process or a
hidden renderer. Continuous Q/E orbit and R/F tilt operate on real 3D meshes.
The full test map replaces the original 32×32 presentation crop. The saved city
and game rules remain in the existing C++ board.

## Display settings slice — 3 October 2026

The Godot game now offers window dimensions, windowed/desktop fullscreen,
monitor selection, VSync and an optional FPS cap. Game → Display settings opens
it directly; the start-menu gear and Game settings link to Display, Interface
options and Controls. Apply starts a 15-second preview; Keep changes persists,
Revert/Escape/timeout restores exact prior window presentation. The earlier
fullscreen key shares this window policy and retains the chosen windowed size.
Normal startup loads confirmed per-user settings. The C++ simulation is unchanged.

Focused Metal/Mobile display reviews pass **48 each in EN/RU**, covering actual
Apply/Keep/Revert, real countdown, fullscreen/shortcut/second-monitor return,
startup preference reload, map picking, input shielding and native state digest
preservation. Headless preference/translation checks pass **23**; retained
controls **59**, retained HUD/context **115 each**, and start-menu gates **17 each**. Exact scope is in
`GODOT_VALIDATION.md`. Fullscreen uses the current desktop mode. Heterogeneous/
high-DPI monitors, other platforms, render scaling and quality presets remain
pending; this does not establish sustained performance at the selectable sizes.

## Unified resource bar — 3 October 2026

The treasury/population/jobs group now shares the top resource surface. The
header observes all 23 native resource bits through silver, plus the food total;
zero stocks remain visible. Balanced responsive rows preserve all types and
exact counts at small/enlarged layouts. Twenty-four original procedural 3D
resource models are saved as scenes and rendered into static transparent icons;
no extra live HUD viewports or city geometry is introduced. The extension was
rebuilt/finalized/signed; observations remain read-only native cached stocks.
Resource/header gates pass 22 each EN/RU, retained notification and status gates
115 each, Escape 53 each, embedded 101 and translations seven. See
`GODOT_RESOURCE_ART.md` and the current validation entry for scoped evidence and
owned-preview isolation/cleanup limits.

## Interface and surroundings slices — 2–3 October 2026

The HUD now has a compact floating category dock, a searchable tray with actual
cached model thumbnails/native costs, floating top status groups, folded objectives and
bounded inspection/decision panels. The vector icons are original drawings;
styles and EN/RU text stay shared. Existing native actions and callbacks are
retained. See `GODOT_INTERFACE.md`; wider accessibility and interface polish
remain pending.

The second interface pass adds a smaller coloured icon dock and centred floating
asset tray, selected/hovered model context, existing-placement facing buttons,
native wall fill and cursor cost/obstruction badges. Translated context grows
upward to clear the toolbar; browsing temporarily folds the minimap. Native
grid-based roads, pricing, placement rules and pending decisions are preserved.
The third pass adds coloured building status summaries, exact native staffing,
road access/maintenance and housing needs, plus related overlay buttons. Service
panels use the existing native observations for matching legends and assessment
counts; their shortcuts stay visible while details scroll. Independent interface
and text sizes preview live, save per user only on Apply, and restore on Cancel.
The shared Theme scales from an immutable baseline; layouts resize without
replacing inspector drafts/tokens or changing native picking and timing.
Focused Metal/Mobile gates pass 115 each in EN/RU, and enlarged menu gates pass
15 each. Next interface work: consistent complex military/campaign inspectors
and keyboard/gamepad navigation; curves require separate native road/pathfinding
work. See `GODOT_INTERFACE.md` and the current scoped validation evidence.

A fourth interface slice folded the live minimap into a bottom-right City map
pill, remembers explicit show/hide choices and shows a small native-coordinate
camera heading chevron with a soft cyan halo. Both compass elements and the
large footprint highlight are removed; Home retains the bounded overview.
The chart has no title row and uses a compact dash button to fold. It stays fixed
at the bottom right as ground/building cards open; inspectors scroll above it
without resetting edits. The status strip moves to the top (32 logical pixels
at default sizes, formerly 46 at the bottom), with its native pause/speed actions.
The dock sits near the bottom edge. The chart temporarily folds for the building
tray or expanded decisions.
That pass used three short animated disclosures with paused reading countdowns;
the Aegean pass below supersedes that delivery and history layout. A required decision stays visible as an
amber review chip, retaining every native choice and callback. Folding is purely
presentation. Focused EN/RU reviews exercise preference isolation, actual UI
clicks, geometry at three sizes, native state preservation and the existing
message/log path. The native minimap build/undo regressions remain intact.
Review with `tools/review_map_notifications.py --checks --lang en` (or `ru`),
`--native-map` for retained native map checks, or without either for captures.
See the latest validation section for exact results; broader campaign/event and
keyboard/gamepad coverage remains pending.

**Escape menu and circular-chart correction — 3 October 2026.** The city’s
language/gear panel is removed; native treasury/population/jobs move to upper
right. A centred, themed Escape menu groups city actions, settings, language and
city views. Escape closes existing city windows/tools first, then opens the menu.
Nested pages return one level at a time. Native pause and queue-hold states are
restored exactly; native decisions remain pending. Escape during a display
preview restores its previous presentation and closes that page. The circular
minimap now covers its frame and clips chart corners, preserving native picking,
map preference and Home overview. Focused Escape checks pass 53 each EN/RU,
notification/HUD and status/context gates 115 each, display 48 each, menu 17
each, native map eight each and translations seven. Final captures and unresolved
threaded-render startup failures are scoped in the validation document.

**Nova reference pass — 3 October 2026.** The user's clearer Nova Roma screenshot
supersedes the Aegean shell below: original teal ribbon/icons, central native city
plaque, second-row stock/job/service shortcuts, square construction dock, left
journal rail, circular map above bottom-left time controls and lower-right native
objectives/selected-tool/inspection cards. Current-city stock and employment are
read-only snapshot fields; no simulation rule, saved map or speed semantics change.
The quiet journal, required callbacks, draft preservation, map preference and
independent UI/text sizing remain. The current circular chart covers and clips its corners, replacing the earlier
full-native-cell fit at the user’s request; inverse picking coordinates remain exact. The speed popup explicitly clears
its opening click. New original SVGs and the shared Theme provide the appearance.
Focused HUD/notification checks pass **115 each EN/RU** (plus nine retained log
checks), existing status/context **115 each**, native map **8 each**, menu **17
each**, display **48 each**, embedded **101** and translations **7**. Final actual
captures, the transient review failures and pending visual/performance scope are
recorded in the newest validation entry.

**Aegean remaster — 3 October 2026.** The approved layout is implemented in the
existing controller: content-sized floating dock, separate time/resource groups,
deep navy/ivory/bronze surfaces, original shallow category medallions and retained
shared heading styles. Routine news is recorded and acknowledged quietly; one
urgent alert is visible at a time, with later alerts queued. Native choices always
retain their required-decision path. The C++ service adds only read-only native
kind metadata; the extension was rebuilt/finalized, with no simulation/save rule
change or SDL renderer change. The compact journal groups exact repeated warnings
while retaining individual dates, text and unread semantics. Reading Controls,
scroll and inspector drafts survive refresh. Escape closes disclosures first.
Thumbnails use warmer lighting and an explicitly idle-disabled viewport; inspectors
explain native staffing, road, input, shutdown and vacancy status. Reduce interface
motion follows explicit preview/Apply/Cancel. An identical catalog refresh now
keeps hover preview and tray state instead of rebuilding it.

Focused EN/RU notification gates pass **84 each**, plus the nine retained message/
log checks; status/context **115 each**, native map **8 each**, translations **7**,
embedded **101**, event wording **45**. Shared menu/display results, actual captures
and broad integration limits are in `GODOT_VALIDATION.md`. The Russian broad run
passes **589** checks and retains the previously recorded aid-regard failure.
Implementation and technical checks are complete for this slice; user visual
acceptance, matched frame-time/memory profiling and wider accessibility remain
pending. See `GODOT_UI_REMASTER_PLAN.md` for checkpoint scope.

Exposed land continues into cosmetic woodland and limestone hills/mountains;
water continues into sea. An inland presentation fixture gets countryside.
Adaptive outside meshes meet native rim profiles, exclude native footprints
and have no collision or simulation cells. Wheel and pinch share a 1.05-map-size
maximum (239.4 vs 364.8 in the test city); Home keeps the full-city overview.
See `GODOT_SURROUNDINGS.md` and current validation evidence. Wider campaign
coverage, map-specific art direction and performance profiling remain pending.

## Completed boundary

**City-to-world flight — 3 October 2026:** outward wheel/pinch crossing the
existing city zoom limit, F2 and the world action now share a live 1.55-second
camera ascent/cloud transition into the regional atlas. Escape/Back use a
1.20-second descent, restoring the exact city pose, visibility and previous
running state. Home remains a city overview; M remains audio mute. City and
atlas cameras blend without changing native coordinates, and UI/atlas input is
locked during travel. Accepted city commands wait in order until return, so a
queued resume cannot release the world hold. The atlas prepares during paused
city load without hidden render passes. Read `GODOT_WORLD_ATLAS.md` and the
focused visible validation entry. The two scenes use independent scales rather
than a continuous surveyed geographic model; minimum-Mac profiling, broader
campaign coverage and reduced-motion accessibility remain pending.

**Living world atlas — 2 October 2026:** the flat world-map backdrop is replaced
by a separate 3D regional globe: coordinate-aligned raised Greece/Poseidon relief,
animated sea, cloud drift, sparse woodland, decorative ships and symbolic city
landmarks/flags. Projected labels, army endpoints/fractions and all native
trade/diplomacy/military/quest handlers remain authoritative. Orbit, pan, zoom,
Overview and Focus city operate only on the presentation. City holding is now
synchronous before the first build; covered city geometry/camera are suspended
and restored on close, and the hidden atlas stops rendering. Source coastplates
remain unchanged, with hashes/provenance; relief is artistic rather than a DEM.
See `GODOT_WORLD_ATLAS.md` and current validation evidence. All five regions build,
but wider live campaigns, geographic survey data, art acceptance, accessibility
extremes, minimum-Mac profiling and source clearance remain pending.

**Floating gods — 3 October 2026:** all fourteen gods float through the city instead of walking: a hover pose made in
the Godot export (`tools/godot_god_float.py`, legs together and trailing, the god's props kept in hand), a low hover
with a slow bob, a lean about the waist into their travel, a gentle sway and a slow turn (`scripts/god_float.gd`).
Presentation only; the clips (fight, bless, appear, disappear) stay. Evidence in `GODOT_VALIDATION.md`.

**God faces slice and closest zoom — 3 October 2026:** the gods looked like dolls (one generic head with
three bumps, dot eyes, a pasted beard). `tools/godot_god_face.py` now sculpts, paints and fits a designed head
inside the Godot-only export (heavy brow, deep-set eyes with sclera/amber iris/pupil/limbal ring, gaunt cheeks, a
longer nose, thin lips, a strand-card beard, brows, a hairline cap); Hades is first and its flame hair now climbs
from red to orange in the shader. The player's closest zoom is held to ten tiles (`MINIMUM_DISTANCE`,
`orbit_camera.gd`). Details in `GODOT_CHARACTER_ART.md`, evidence in `GODOT_VALIDATION.md`. Not done: the other
thirteen gods, facial animation, baked photographic skin, water/air effects for the other gods.

**Hades art slice — 2 October 2026:** `walker_hades` now uses the Godot-only
`godot_hades_art.py` adapter: original angular anatomy, cool skin/amber eyes,
red-fire hair, older facial creases, full silver-gray beard, dark long folded chiton, fitted one-shoulder mantle, curled train
and bronze bident/hem. The user reference supplied the fire/drape mood, not the
face or runtime pixels. All native rig/prop grips, 24/12 walk/idle samples,
16 fight and 32 disappearance frames, reverse arrival and 0.64-tile stride
remain. Sparse red spirals replace the source renderer's opaque exported aura.
Only this god's finish enables flame emission; ordinary people and the physician
benchmark keep their existing rendering. The character has 15,638 vertices and
three mesh groups, below its 22K cap, with imported LODs and fresh GPU poses.
The v2 hem effect adds 96 cosmetic flame triangles, 18 embers and a small
shadowless light; movement and exact disappearance blend weights follow the
presentation pose in both GPU and morph paths (18 focused checks).

The two login guardians now derive from this character's actual idle geometry,
scaled and finished in carved stone. `make_hades_guardian.py` preserves normal,
palette and UV accessors and records the source SHA; the native sanctuary monument
and Blender/SDL art are untouched. The current menu uses 271,928 static triangles
and 29 mesh instances, below the existing gate. Read the character document and
new validation entry for inspected views, checks and rebuilding. User visual
acceptance, further god art, physical cloth/flame simulation, conventional baked
PBR textures, source rights evidence and wider campaign/performance coverage
remain pending; no C++ simulation or packaging change was made in this slice.

- `engine/esimulationstep` is shared by the native SDL view and the embedded
  service. It retains frame advancement, worker scheduling, appeal updates,
  completed-task handling, native time increments, rubbish cleanup and
  highest-speed waiting/order. Godot supplies time to a 20 Hz accumulator.
- `presentation/esimulationservice` loads the original campaign/save, owns the
  board lifetime, waits for workers, exports observations and accepts commands.
  No native main window or game widget is instantiated. The legacy save view
  record and pure message formatters are reused; unused UI code remains linked
  during this migration. SDL sprite metadata remains available without GPU
  raster loading, and native audio playback is suppressed in this backend.
- `presentation/godot/register_types` registers one RefCounted native owner.
  Open, advance, snapshot, command, diagnostics and close are bound directly.
  The wrapper converts native JSON into Dictionaries inside the process; there
  are no normal-session sockets or IPC. Typed packed arrays and permanent
  content/entity identifiers remain future work.
- Native messages/events retain their data and decision callbacks. Simple
  choices and eligible city destinations are exposed. A pending decision holds
  simulation advancement, matching native modal behavior. Complex military and
  campaign interfaces remain pending explicitly. Static message mappings reuse
  the native language data; some specialized event formatting still needs parity.
- All 25,992 tiles are represented in terrain sections. Geometry-affecting tile
  changes rebuild affected sections; placement-only changes update metadata.
  Repeated structures and trees use spatial MultiMesh batches. Selection uses
  terrain raycasts and authoritative footprints. Imported material/anchor
  contracts and individual character identities are retained.
- The previous localhost bridge is an explicit regression reference only.
  Development sessions still load only the designated test save and check file
  hashes after closing. No publishing or save migration occurred.

## Construction and basic inspection slice — 30 September 2026

Native preview/inspection queries are exposed for the four construction types.
Queries are read-only against the city, reuse the exact build footprint/flags and
cost calculation, and are rechecked when a command executes. Godot shows imported
mesh ghosts, per-cell obstruction colours and quoted cost. New square-building
model facing remains in session presentation metadata; persistent save-facing
and rectangular dimensions are still pending.

Basic live inspectors reuse native names/text and employment/house-needs data.
Demolition reuses the native erase helper, resolves child tiles to whole objects,
handles forest state and housing eviction, preserves landmark/stocked-market
confirmation and rejects stale targets. Dialogs preserve prior pause state.
Construction undo uses native recording, actual refunds and the existing time
window; failed builds retain undo, demolition invalidates it. Saves/settings
remain protected. See the additional validation evidence for these contracts.

## Saved-city placeholder replacement — 30 September 2026

The city now has source geometry for all 792 rendered building objects and 279
initial visible walkers; 42 native ownership/livestock records deliberately have
no duplicate mesh. The 362 development GLBs include native orchard/wall/tower/gatehouse/temple/god/
pyramid variants, people, carts and animals. Coverage remains scoped to this city.
Full palace geometry, model-change replacement, rotated footprint fitting, sky
reflections, realtime LOD and material batching are implemented. Read
[GODOT_ASSET_COVERAGE.md](GODOT_ASSET_COVERAGE.md) for export contracts, evidence and
remaining state/campaign gaps. Generated art retains its provenance status.

## Storage / production interaction slice — 30 September 2026

Live storage inspectors expose native inventory, overflow, bay use, all four
resource orders and stock limits. Edits apply explicitly, preserve existing goods
and leave other resource orders intact. Production inspectors expose input/output
buffers, recipes, employment and native operational status. Shutdown/resume calls
the existing city-wide industry/workforce methods, including shared producers;
individual shutdown rules were not added. Selected-object weak-reference tokens
reject stale controls after selection changes, demolition, replacement, undo and
reload. Pending native decisions retain their callbacks and block these edits.

Warehouse, granary, olive press, winery and sculpture studio extend construction
from four to nine tools. They share exact native availability/placement/costs,
imported ghosts, session facing, demolition and undo. EN/RU controls, live refresh,
unfinished edits, full-queue recovery and keyboard focus were verified in Godot.
Existing 3D models were suitable for this slice and remain unchanged. Save/load,
the full building menu, drag construction, specialized trading/vendor/military
controls and animated inventory goods are still pending. The later building
activity slice connects work cycles for 35 supported types.

## Ground and shoreline slice — 30 September 2026

The user prioritized terrain appearance before further interface migration.
Continuous world-space ground materials replace the tile colour checkerboard;
sand/wet banks and a shared coast-distance contour soften shore corners. Calm
normal-based water gains shallow-to-deep colour. Native terrain flags supply soil,
vegetation, stone and road weights. Forests now use forest bit 16 rather than
fertile bit 8, with deterministic per-cell variation and existing independent trees.
No native RNG, saved map, economy, pathfinding, placement or simulation-height
change is introduced. Actual irregular map holes remain empty.

Material/road edits update shared textures; coast changes rebuild only affected
geometry sections/apron neighbors. Forest clearing removes the affected tree and
refreshes soil. Collision and building/road/walker anchors retain native heights.
Read [GODOT_TERRAIN.md](GODOT_TERRAIN.md) for the field contract, evidence, content
source and limits. The elevation slice below extends this material work; next are
outcrops/understory and foliage budgets. The presentation/audio/campaign acceptance
gates below remain required; these visual slices do not establish whole-game parity.

## Elevation and cliff slice — 30 September 2026

Read-only native elevation/walkability/half-slope/foundation observations extend
the original six tile columns. Shared native corner profiles form continuous
slopes, with subdivision only on elevation cells and shared lighting normals.
Vertical limestone sides close discontinuities and actual outer map edges;
irregular holes stay empty. Ordinary ground/water and building foundations retain
native heights. The designated city has 203 blocked cliff cells, eight road ramps
and 112 protected elevation cells, using 181,026 ground vertices and 1,014 side faces.

Picking collision follows the visual mesh while native pathfinding, construction
eligibility, costs and timing remain unchanged. Walker feet, forest positions,
per-cell feedback and tilted road ghosts use the surface sampler without rewriting
native positions or routes. Geometry edits rebuild a two-cell section halo;
flat road/material changes still avoid collision rebuilds. The original snapshot
prefix remains comparable with the SDL reference. No GLBs or live Blender scene
were changed. Actual EN/RU slope picking, demolition/rebuilding/undo and native
state preservation pass; half-height profiles have presentation-copy math tests
only because this save has none. See the validation document for evidence/limits.

## Mineral / forest-edge detail slice — 30 September 2026

Native resource flags now select soft limestone boulders and distinct ore veins,
with continuous mineral soil and low perimeter fragments for walkable marble
quarries. Seven resource kinds have authored procedural meshes; four occur in
this save. Sparse grass and leafy shrubs grow at forest edges with olive/sage
tones and subtle tip wind. They respect native water/road/foundation/field/mineral
clearance and actual map cells, with no new collision or native rules/RNG changes.
Existing tree/building/character GLBs and the live Blender scene remain intact.

Spatial 24×24 MultiMeshes share cached resources and cap grass/shrubs per section.
Small vegetation fades/culls with distance and casts no realtime shadows.
Initial detail is 3,746 instances in 239 batches, including 42 marble perimeter
fragments for 108 native quarry cells. Ground inspectors identify native minerals
in EN/RU. Road/housing construction, undo and forest clearing refresh the affected
props and neighbor habitat; eligibility-only edits preserve batches. Legacy
snapshots without foundation metadata conservatively omit new props. Procedural
source/provenance, budgets and scope are in `GODOT_TERRAIN.md` and the terrain
detail manifest. The map-review slice below adds tree canopy/wind/LOD and fixes
native crossings; wider campaign terrain coverage, production performance and
whole-game gates remain open.

## Map-review refinements — 30 September 2026

The user's map review first corrected missing native crossings and a half-tile
walker coordinate mismatch. All 57 native water-road cells now have 3D decks,
railings/supports and 20 shore approaches, with correct picking and pedestrian
feet; boats retain native water height. Coordinates convert once into centered
Godot tiles, with native routes/state unchanged. Forest presentation now has
forked olive-style/cypress trees, leaf geometry, subtle wind and reduced indexed
LODs: 3,138 trees in 182 batches. Mineral shapes/spacing are less repetitive.
Old GLBs, native SDL assets, C++ simulation and the live Blender scene remain
intact. Read the terrain/validation documents and source manifest for limits.

## Garden foliage refinement — 30 September 2026

Eight existing garden GLBs now have branching, leaf-covered vegetation instead of
coarse cones, stacked balls and flattened vine blobs: Fish Pond, Topiary, Hedge
Maze, Park, Shell Garden, Sundial, Dolphin and Orrery. Formal topiary identities,
maze layout, pools, monuments and native footprints remain. Park export selects
an actual 1x1 pine-and-bench module at full height; it no longer shrinks the source
loop's final 3x3 tholos onto each native cell. The designated city has 178 affected
objects, including 164 parks. Export also retains authored pool/fountain colours.

`tools/godot_garden_foliage.py` adapts only disposable background exports. Native
sprite recipes, the live Blender scene, C++ simulation, asset IDs and saved city
remain unchanged. Per-asset foliage budgets and palette batching are recorded in
the eight manifests. See the asset/validation documents for final evidence.
Additional park/species variants, garden wind, procedural material baking, wider
campaign coverage and sustained minimum-Mac performance remain pending. This
refinement does not complete the broader presentation/audio/campaign parity gate.

## Performance slice: snapshot path and render budget — 30 September 2026

A measured review found the per-snapshot cost and the frame cost were both avoidable.
Delta snapshots no longer scan build eligibility for every tile or re-send the building
list when it did not change (4.2 ms → 0.94 ms end to end); placing a building costs
6.7 ms in Godot instead of 60 ms because model manifests are cached and only changed
batches rebuild. The renderer uses two shadow cascades and a 3-pixel mesh LOD threshold,
cutting triangles about 40% and frame time about 35–45% at matched views with no visible
change. `validate_geometry.gd` adds a LOD-ladder and growth gate for the 240 GLBs, and
the extension diagnostics expose per-phase snapshot timings. Tile column 5
(eligibility) is now a snapshot-time observation, not a change trigger; use `preview`
for placement. See the validation document for the measurements and limits.

## Startup and video memory slice — 30 September 2026

City load fell from about 4.1 s to about 1.1 s: the native open no longer decodes sprite
PNGs this backend never draws (2.1 s to 0.06 s), model files load on worker threads while
terrain is built, and level terrain skips the normal search. Video memory fell from 908 MB
to 821 MB by merging identical morph targets in the development GLBs
(`tools/optimize_glb_memory.py`, proven lossless), which also speeds the walker animation's
per-frame lookups. Removing UVs was rejected after it damaged foliage LODs. New or
re-exported GLBs must be optimized again and re-imported. See the validation document.

## Natural walker presentation — 30 September 2026

**Not visually accepted:** the user reports that this pass still looks like dolls.
A textured, skeletally animated physician benchmark now exists, with a baked crowd twin
and a swap system (see "Citizen benchmark slice" below); it awaits the user's visual
review before any other role is converted. See `GODOT_CHARACTER_ART.md`. The current
technical integration of the 31 walkers remains implemented.

The existing 31 human walker assets now preserve skin colour variation, anatomical
faces/hands, fitted hair/beards and distinct occupation identities. A shared
Godot finish adds rest-coordinate tunic stripes and cloth/skin/leather detail;
the philosopher has a blue wrapped Greek himation. Female/child anatomy, props,
native identities and sampled gaits remain. The adapter operates only in
background exports; native art recipes and C++ rules are unchanged. Both UV sets,
palette batching, morph alias optimization and imported mesh LODs are required.
See `GODOT_CHARACTER_ART.md` and the validation evidence. Building workers/rowers,
full texture baking, facial motion and full gameplay animation states remain open.

## Walker pose memory slice — 30 September 2026

Animated walkers and animals no longer keep dense morph targets in video memory. A tool
bakes each model's poses into a half-float texture and writes a morph-free runtime
derivative beside the untouched source; a shader displaces vertices from the texture, and
the game falls back to the source's blend shapes whenever a derivative is stale. Video
memory after city load fell from 821 MB to 568 MB, and each extra walker costs about 45 KB
instead of 345 KB. Source models, manifests and the new character shader's UV channels are
unchanged. New or re-exported walkers need `tools/bake_walker_vat.py` and an import. See the
validation document.

## Citizen benchmark slice — 30 September 2026

The physician is a textured, rigged MPFB-based citizen (`assets/characters/physician_v2/`,
137 bones, Idle/Walk, blink shapes). It was cut from 89,000 to 30,116 vertices with
VRAM-compressed textures (first load 457 to 210 ms, 1.7 to 0.6 MB per instance, textures 56
to 12.7 MB). Every physician is drawn by a 6,249-vertex baked crowd twin (`physician_crowd`)
and the nearest 24 within 9 units swap to a pooled skeletal citizen that continues the crowd
model's exact clock (`scripts/citizen_lod.gd`); movement stays C++ authoritative. The new
`validate_citizen.gd` (36 checks) found and fixed a per-step walk-loop pop; the full
regression passes. Forward+ was measured at about 1.5 times the frame time of Mobile and
stays an experiment. The himation is now a baked cloth simulation instead of a flat plate. Pending: the
user's visual acceptance (the hem and eyes are known issues; at the closest zoom of 5 units the head is only about 26 px), any wider
rollout, closer-zoom decision, and the native `disgruntled` walker, which has no model.
Evidence is in `GODOT_VALIDATION.md`; rebuild steps in `GODOT_CHARACTER_ART.md`.

## Walking refinement — 1 October 2026

Walking refinement (1 October): `walker_motion.gd` now smooths human start/stop
blends and turns, using planar native travel for phase. VAT and fallback morphs
share normalized blends; skeletal/crowd swaps carry the exact weight. The physician
benchmark adds heel/toe roll, longer support, continuous swing, weight transfer
and arm/shoulder counter-motion. Bone clips export from time zero and import at
100 Hz; the scaled source gait still covers 0.64 native tiles. Gates pass: 3 curve
tests, 20 locomotion checks, 38 citizen checks, 39 baked models, assets/geometry,
and windowed EN/RU 237 each. Native movement and saved files remain unchanged.
The continuous city reviewer uses a review-only physician on a native transporter
route because there is no initial physician in this city. New foot cycles for the
other roles, terrain foot IK and visual approval remain pending; see the character
and validation documents.

## Foundation slice — 1 October 2026

Before building the playable loop: the camera pivots on the terrain (and supports trackpad gestures), the map sits in
open sea under a sky, `godot/captures/` is out of the editor's way, and the simulation is reproducible. A seedable generator,
a gameplay-state digest and a fix for a data race (path-search filters drew the shared random generator from worker threads)
made seeded replays identical between the SDL executable and the embedded core (`tools/replay_parity.py`). The interface moved to
`tr()` keys with a CSV translation table (a third language is a column), one lapis-and-gold Theme and a HUD scene, with the
developer telemetry behind F3, and the windowed harness left `main.gd` (1,341 to 1,041 lines). Details and limits are in
`GODOT_VALIDATION.md`. Next: the 10-minute playable loop (drag roads, message log, minimap, save/load, the remaining
building menu, overlays, audio), then visual polish; the simulation thread and typed commands stay later gates.

## Building activity slice — 1 October 2026

The static exports captured one working pose, leaving staffed buildings frozen.
Thirty-five supported building types now play their authored eight-phase work
cycles with workers, tools, machinery and effects. C++ exports read-only staffing,
work eligibility and the existing cosmetic phase offset; GPU MultiMeshes animate
moving pieces and keep architecture static. Native inputs/shutdown/fire/patrol
availability gate work. Native gameplay time drives speed and freezes motion on
pause or pending decisions; no simulation rules or RNG are changed.

Original GLBs and sprite atlases remain intact. Runtime derivatives have no morph
buffers, retain imported LODs and fall back to original models if their base hash
is stale. Staffing-only changes update custom instance data without rebuilding
geometry. Follow [building activity contracts](GODOT_BUILDING_ACTIVITY.md) before
exporting; workers' new art/texture benchmark, animated inventories, rowers and
the remaining gameplay states still need coverage. Verification evidence and
performance limits are recorded in `GODOT_VALIDATION.md`.

## Playable loop, first part — 1 October 2026

Drag-to-place roads (the native path rule, one undoable step), a message log with toast cards, a minimap with click-to-move,
and per-user saves (Game menu, quick save/load, rotating autosaves, load by restarting the scene; Godot-written saves open in the SDL game
with the identical state). Details and limits are in `GODOT_VALIDATION.md`.

## Playable loop, second part — 1 October 2026

The Build menu now offers 41 buildings in nine categories (farms and lodges, industry, storehouse and granary, infirmary,
fountain and baths, tax and maintenance offices, watchpost, gymnasium, the science buildings, parks, gardens and
monuments) from the core's static `buildSpecs` table. Sixteen native types have no model yet and stay hidden. Still missing
for the 10-minute loop: trade posts, walls and gates, elite housing and park
area-fill, overlays, audio, and a start menu so the game opens something other than the test city. (Agora and vendors followed in the third part.)

## Playable loop, third part — 1 October 2026

Markets: the common and grand agora can be laid over a stretch of road and the food, fleece and oil vendors placed on their
empty spaces, so the farms placed from the menu can finally feed houses (undo covers each step). The placement rules moved out of
the SDL game widget into `engine/eagoraplacement.*`, shared by both views. Still missing for the 10-minute loop: wine, arms,
horse and chariot vendors (no models), trade posts, walls and gates, elite housing and park area-fill, overlays, audio and a
start menu so the game opens something other than the test city.

## Playable loop, fourth part — 1 October 2026

The game no longer opens on the test city. A start menu offers Continue, New game (all 26 adventures, read by the core and listed
as the SDL game lists them), Load game, language and Quit; Start reads an adventure and shows the first episode's story and
objectives before the city opens, paused and empty on the player's own land. An objectives panel follows the goals with live
status and a result card closes a finished episode; the Game menu returns to the start. Saves are per user and open in the SDL game.
Still missing: moving on to the next episode and colonies (the world map), overlays, audio, trade posts, walls and gates, elite
housing and park area-fill, and wine, arms, horse and chariot vendors.

## Playable loop, fifth part — 1 October 2026

Overlays: the SDL game's 25 view modes now work in the Godot city with the same hotkeys (1 water, 2 supplies, 3 hygiene, 4 fire and
collapse risk, 5 appeal, 6 taxes, 7 unrest, 8 security, 9 roads, Tab problems, 0 normal) and an Overlays menu with Culture and Science
submenus. Buildings the overlay is not about lie flat on their footprint, other walkers disappear, value columns and supply markers
float over houses, and the appeal view colours the ground.

## Playable loop, sixth part — 1 October 2026

Sound: the original game's music, effects, ambient layers and recorded voices play in Godot from the `Audio/` folder. The title tune
plays in the menu; city music follows (battle tracks when the simulation says so); campaign introductions speak on the briefing page;
buttons click; placing a building, clicking one, fires, collapses, quarrying, gods and monsters all sound as the native rules ask, and
the wind, bells and the sounds of the places near the middle of the view come and go. Volumes and mute are per user (Game, Sound…, M).
Still missing for the 10-minute loop: walls and gates, elite housing, park
area-fill and the remaining vendors. (The campaign flow followed in the seventh part, trade in the eighth.)

## Playable loop, seventh part — 1 October 2026

Campaign flow: winning an episode shows its result, then what the campaign offers next. The adventure's later episodes, the colonies
(a choice from those on offer, each its own city and map) and the return to the parent city all work, across all 26 adventures; the
parent city and treasury carry over, a game saved in a colony resumes there, the briefing has a difficulty choice, "set aside"
objectives have their button, a defeat offers to retry the episode from its start, and the last episode ends with the adventure's closing
words. The SDL game's world-map picture for choosing a colony is replaced by a list. Still missing for the 10-minute loop: trade
posts, walls and gates, elite housing, park area-fill and the remaining vendors.

## Playable loop, eighth part — 1 October 2026

Trade: trade posts for land partners and piers for sea partners (most partners of the early campaigns are by sea), each opened for one partner city
from the Build menu's Trade category, with a panel to choose what the post imports and exports and how much to keep in stock, and a Trade partners
dialog (Game menu) listing every partner with its goods and prices. Traders, donkeys and ships are the native ones. Still missing for the 10-minute
loop: walls and gates, elite housing, park area-fill and the remaining vendors; the world map's other uses (raids, requests, conquest) remain.

## Playable loop, ninth part — 1 October 2026

Walls and gates: walls are dragged as in the SDL game (the outline of a rectangle, all of it with Shift) with the real wall pieces shown
joined to each other before the release, towers are placed like any 2x2 building, and gatehouses (5x2, or 2x5 with T) lay a road passage
between two gate towers. The tower, the gatehouse and the archer that patrols the walls are new models; the archer stands on the wall or
tower top. Demolishing and undoing work as natively. Still missing for the 10-minute loop: elite housing, park area-fill and the remaining
vendors; the world map's other uses (raids, requests, conquest) remain.

## Playable loop, tenth part — 1 October 2026

Elite housing and area drags: mansions (the ten remastered estates, five levels in two variants) can be placed from the Build menu, and common housing,
mansions and parks are dragged over an area as in the SDL game (houses and mansions in steps of their own size, parks on every tile), with a plate per plot,
the first few as models, and the total cost before the release. Still missing for the 10-minute loop: the wine, arms, horse and chariot vendors (no models);
the world map's other uses (raids, requests, conquest) remain.

## Playable loop, eleventh part — 1 October 2026

The wine, arms, horse and chariot vendors have their stalls (the Roman macellum tabernae of the market art), so a market can sell every good the houses ask for. Still
missing for the 10-minute loop: nothing in the list that began with trade posts, walls and gates, elite housing, park area-fill and the vendors; 15 native building types
(culture and science schools, mint, corral, dairy, armory, chariot factory, the small garden pieces) have no model, and the world map's other uses (raids, requests, conquest) remain.

## Playable loop, twelfth part — 1 October 2026

The last fifteen buildings that had no 3D model have one: the podium, college, drama school and theater (culture), the mint, corral, dairy, armory and chariot factory, and the bench,
bird bath, two obelisks, flower garden and gazebo. Every building the core can place is now offered in the Build menu where the city's culture allows it. Still missing: the world map's
other uses (raids, requests, conquest), the military (soldiers, armies, invasions as the player commands them), the building working animations of most of these models, and production packaging.

## Playable loop, thirteenth part — 1 October 2026

The world map: Game, World map… (F2) opens the picture of the adventure's map with its cities. Selecting a city shows who it is (ally, vassal, rival, colony, distant city), how much it regards the player
with its native name for that regard, what it sells and buys with prices and this year's use of the limits, and its tribute. The player can ask an ally, vassal or rival for goods (the regard of every city falls
for it), give a gift of goods or drachmas, and fulfil the requests a city made, from any of its own cities. The city is held while the map is open. Raids, conquest and military aid are shown but disabled until the
armies exist. Still missing: those military dealings, the army markers on the map, and the editor's map tools (adding or moving cities).

## Next stages and acceptance gates

1. **Presentation parity.** Add remaining specialized interactions, including
   trade/vendor settings, patrols, sanctuaries and military controls. Extend authoritative placement/ghost
   coverage to the remaining building menu and drag construction. Port overlays,
   minimap, military selection, requests, world map, campaign transitions and
   save/load/settings UI. Connect audio
   events to Godot. Preserve EN/RU and all game decisions; do not silently
   replace event callbacks with automatic outcomes.
2. **Core validation and cleanup.** Test identical seeded saves/commands across
   production chains, pathfinding, disasters, wars and campaign progression.
   Audit inherited RNG use, including cosmetic draws, before deterministic
   replay claims. Extract remaining serialization/formatting headers from UI,
   remove unused linked widgets, introduce durable entity/content IDs and
   typed snapshot arrays, and separate commands/results from observations.
3. **3D content completion.** Convert remaining structures, decorations,
   production fields, animals and walkers with explicit identities. Bake
   procedural materials and the remaining building visual states; support work/death
   states and authored idle motion. Extend tree species/content and profile
   foliage/bridge LODs; extend terrain/elevation campaign coverage, richer water interaction,
   occlusion and rectangular building facing.
4. **Performance gate.** Profile simulation, snapshot conversion, loading,
   memory, material count and GPU frame time. Exercise the actual largest city
   and at least 10,000 structures/1,000 active walkers on minimum supported Macs.
   Local M4 observations vary by view and content detail; they do not establish
   sustained minimum-hardware or stress-test performance. Tune batching/culling before broad engine rewrites.
   Done: snapshot path, batch rebuilds, shadow cascades and mesh LOD (see the slice above).
   Done: walker pose memory (baked pose textures). Open: typed snapshot/walker arrays,
   shader-driven or MultiMesh pose updates for crowds, per-asset LOD0 budgets, terrain chunk
   generation at startup, first-use GLB load hitch.
5. **Independent product gate.** Finish original content/provenance review and
   approved packaging lists, add one original scenario and localization/audio,
   per-user writable data, recoverable saves and migrations. Bundle all runtime
   dependencies, preserve licenses/source obligations, then validate a signed,
   notarized downloaded build on a clean Mac without the original installation,
   Homebrew or Blender. Continue with closed testing before store submission.

Detailed launch controls, scope and reproducible local build are in
`../godot/README.md`; evidence is in `GODOT_VALIDATION.md`.

## Playable-loop slice 9: walls, towers and gatehouses — 1 October 2026

**Core.** `wall`, `tower` (now with a model) and `gatehouse` joined the build table. A wall is dragged with `preview_wall` / `build_wall x1 y1 x2 y2 fill`:
the SDL rule (the outline of the rectangle between two tiles, every tile with `fill`, each tile built or skipped on its own, stop at 1000 drachmas of
debt, one undo step), with the verdict and connection mask of every listed tile (at most 3,000 are listed; the counts stay exact). A tower is a standard
2x2 employing building. A gatehouse is a new `Kind::gate`: the footprint is 5x2 or, turned, 2x5, (x, y) is its corner, the two 2x2 blocks and the passage are
checked tile by tile and the gatehouse and its two passage road tiles are created as the native widget does (the gatehouse takes the tiles, the center tile
is the last, one charge). Differences from the native code, deliberate: an existing plain street under the passage is kept and flagged instead of being
replaced by a new road object (the old one stayed registered off the map), and a street that already belongs to an agora, a gatehouse or a hippodrome, or an
avenue, is refused. **Native defect fixed in shared code:** `eGatehouse::erase` emptied all ten tiles but left the two passage roads registered, so they
reappeared on the next load; it erases them now (visible result unchanged, the SDL executable was rebuilt and signed). The snapshot names a tower and a
gatehouse and gives a gatehouse its facing from the footprint; archers (types `archer` and `archerPoseidon`) are `walker_archer` and carry a `lift` (0.8
on a wall, 2.57 on a tower).

**Models.** `tower` and `gatehouse` are exported from `art/tower/build_sprites.py` (`--gate` for the gatehouse's towers); `tools/godot_gatehouse.py`
composes the gatehouse from two gate towers 1.5 tiles either side of the middle and a vaulted passage under a lower wall walk (travertine piers, an arch
ring and keystone, a brick upper storey with a dedication panel, merlons). `walker_archer` is the people kit's archer identity through the natural people
adapter (15,958 vertices like the other walkers, baked pose texture). The geometry baseline gained exactly these three assets; `validate_assets` counts 244.

**Godot.** A "Walls and defence" Build category (wall, tower, gatehouse); the drag tool of `road_drag.gd` also runs the wall tool (the pieces are
drawn as the models they will become, up to 400, over the green or red footprints; Shift fills; the hint says so); the placement ghost of a gatehouse follows
the core's facing (T); archers get the wall or tower top as a height offset. New strings in English and Russian.

**Checks.** `validate_walls.gd` (63 headless): the three tools are offered with models, the drag outline/fill counts, native cost, connection masks, preview
changes nothing, build/undo, neighbours changing as pieces come and go, tower cost/undo/demolition, both gatehouse facings (footprint, passage road, one
charge, refusals, demolition from a passage tile, undo of a fresh and of a street-crossing gatehouse), a save and reload of walls, a tower and gatehouses
(connections kept, a demolished gatehouse's passage does not return), rejections and bounded previews, and last the tower's archer appearing with the
archer model and its lift. `validate_main.gd` adds 16 windowed checks (the Build heading, the drag with its 36 footprints and models and cost, release,
Ctrl Z, the gatehouse ghost, T, the click, undo, models present): windowed EN/RU 301 each. `validate_saves.gd` now saves a wall line and a gatehouse and the SDL game
reads them with the identical digest (`save_roundtrip.py` PASS); replay parity PASS after the native rebuild.

**Limits.** A reloaded city equals the live one only when no employer was built in between (a tower, a tax office and a watchpost all differ: after the reload
several other employers, vendors and storehouses, show one more worker than in the live city; the cause is not yet found, it is unrelated to this slice and was
noticed while writing the save check). The Atlantean tower archer uses the same
model as the Greek one; the archer has no shooting or fighting animation and the walls' brick still reads grey (material baking is pending); archers walk
only where the native rule lets them (a 2x2 block of wall or tower tiles), so a one-tile-thick wall carries none; there is no gate door to open or close.

## Playable-loop slice 10: elite housing and area drags — 1 October 2026

**Core.** `elite_house` joined the build table (4x4, `eEliteHousing`, the native mansion cost) and the snapshot names it `elite_house_<level><a|b>` from its level
(0 to 4) and its seed. `preview_area` / `build_area` (`areaCells`, `areaPreview` in the service) drag common housing (2x2 steps), elite housing (4x4 steps) or
parks (every tile) over an area exactly as the SDL view's three cases do: from the pressed tile toward the released one, columns then rows, a plot built where it
fits and skipped where it does not (`not_owned`, `other_district`, `occupied`, `needs_flat_ground`, `blocked_terrain`), the build stopping when the treasury is 1000
drachmas in debt, one undo step per drag, parks followed by a terrain update. The preview lists at most 3,000 plots (counts, cost and verdict stay exact) and names the
model. Footprints use the Godot convention (the pressed tile is a plot's corner); the SDL anchors a 2x2 plot and a mansion one row up from the hovered tile, which only maps the pointer differently.

**Models.** The ten estates are exported unchanged from the Hospital v2 standard sources (Zeus/Roman style: abandoned farmhouse, residence, mansion with prostas and
fish pond, manor with tower and stable, estate with peristyle; each B variant is the A mirrored). The geometry baseline gained exactly these ten assets;
`validate_assets` counts 254.

**Godot.** Elite Housing in the "Housing and roads" category (English and Russian names); the drag tool of `road_drag.gd` also runs the area tools (one flat plate per
plot, models for the first few, the hint and the cost); `main.gd` no longer lets the real mouse move the end of a drag that a test is driving (the pointer-driven
checks had been timing-sensitive to where the real cursor sat).

**Checks.** `validate_housing.gd` (30 headless): elite housing offered with its model, a drag of 8 by 4 holds six plots in the SDL order, native cost, previews change
nothing, build, level 0 estates in variant a or b, undo, occupied refusals, the backward drag, 2x2 housing and 12 parks at the native cost, partial drags, refusals,
a bounded listing. `validate_main.gd` adds 18 windowed checks (the Build menu, an elite drag with its plates and models, a park drag, the release, Ctrl Z, the models):
windowed EN/RU **319** each. `validate_saves.gd` (34) now saves mansions and parks and the SDL game reads them with the identical digest (`save_roundtrip.py` PASS);
replay parity PASS (the SDL executable is unchanged). A review scene with all ten estates showed the five levels and both variants.

**Limits.** The ten estates are 7 MB each and about 63,000 triangles, as heavy as the other large buildings: a city full of mansions will need the occlusion work still
open for the performance gate. The estates' household tasks (the sprites' animations) are not authored in 3D, and a vacant plot shows the same estate; the mansions'
residents, needs and appeal are native.

## Playable-loop slice 11: the remaining vendors — 1 October 2026

**Core.** The four `buildSpecs` rows (`wine_vendor`, `arms_vendor`, `horse_vendor`, `chariot_vendor`) now name their models and the snapshot maps the native types to them (the
horse trainer's native type is `horseTrainer`). Nothing else changed: placement, one vendor of each good per agora, cost and undo were already the shared native rules.

**Models.** Exported unchanged from `art/agora/build_stall.py` (wine: burgundy thermopolium with sunk dolia; arms: black and red armourer's stall with scuta and a gladius; horse: ochre
and brown hitching rail with a white horse; chariot: purple and gold stall with a gilded chariot and a wheel). The geometry baseline gained exactly these four assets
(48,000 to 57,000 triangles); `validate_assets` counts 258.

**Checks.** `validate_buildings.gd` (421, was 403): the four stalls are listed with their models; each available kind previews on a free agora space with its own model and cost,
is built for the quoted cost and is undone (the horse trainer is skipped in the test city, which does not allow it); `validate_main.gd` adds two windowed checks (the Markets menu lists the
new vendors and a wine vendor is placed on the last space of a common agora through the interface): windowed EN/RU 321 each. A review scene showed all seven stalls.

**Limits.** The horse trainer could be tested for its model and name only, not placed, because no city in the test save allows it. Stalls are shown stocked and staffed as exported.

## Playable-loop slice 12: the last building models — 1 October 2026

**Core.** The fifteen `buildSpecs` rows named no model; they do now, and the snapshot maps their native types (`podium`, `college`, `dramaSchool`, `theater`, `mint`, `corral`, `dairy`,
`armory`, `chariotFactory`, `bench`, `flowerGarden`, `gazebo`, `birdBath`, `shortObelisk`, `tallObelisk`) to them. Placement, costs and undo were already the shared native rules.

**Models.** Exported unchanged from the remastered sources through the generic `art/<name>/build_sprites.py` route and the decoration script's six extra kinds (`tools/godot_asset_sources.py`).
The geometry baseline gained exactly these fifteen assets; `validate_assets` counts 273. A review scene showed them together (the theater a half-round tiered building under striped awnings, the
mint and dairy small tiled houses, the corral a long barn with a fenced pen, the gazebo a monopteros with a verdigris dome).

**Checks.** `validate_buildings.gd` (487): the hidden-model check now allows nothing to be hidden, and the housing and market checks of the earlier slices still hold; `validate_main.gd` adds two windowed checks
(every building in the Build menu has its model file, and the core lists none as unconverted): windowed EN/RU **343** each. Two of the windowed hint checks (the wall and area drag tools) now call
`update_hint()` before comparing, because a pointer resting on the map replaced the hint with the placement text (a timing-dependent failure, as the drag tests had before).

**Limits.** The buildings are shown in the pose of the first frame: the native sprites' working animation (performers, students, workers, the bird bath's water) is not authored in 3D, and
livestock are separate snapshot records. Nothing beyond the geometry gate was measured for these exports.

## Playable-loop slice 13: the world map — 1 October 2026

**Core.** The `world` query and the commands `world_request`, `world_gift` and `world_fulfil` (see `eZeus/AGENTS.md` for the contracts) apply the SDL world menu's and its dialogs' rules: dealings are not for a distant
city, the city played, a colony on the board or a neutral city on the board; a request needs more than 50 regard unless the city is a rival and is refused otherwise; the asked city loses 20 regard in all (every city
loses 10 and the asked city 10 more, which the SDL dialog's `eGameBoard::request` does), a gift is one to three times the good's base size (8 for most goods, 4 for marble and armor, 1 for a sculpture, 500 drachmas),
and goods sent to fulfil a request are taken at once. The dealings schedule the engine's own game events (the answer to a request and the arrival of a gift after 90 days, a follow-up event a little over three months after a request is fulfilled), so what happens
next is the SDL game's own code, not a copy of it. `test_request` exists for the validators.

**Godot.** `ui/world_map.tscn` (a full-screen overlay: the map picture kept in proportion, a marker control per city drawn by `ui/world_marker.gd` in the colour of its kind, the panel of the selected city,
the request, gift and fulfil dialogs built from the core's answers) and `ui/world_map.gd`; `main.gd` opens it from the Game menu or F2, holds the city while it is open and lets a running city run on afterwards.
Markers use drawn badges (a gold ring for the player's own cities, a white ring for the one played, green, blue and red for ally, vassal and rival, a compass arrow for a distant city) instead of the SDL sprites.
Strings are in the interface table in English and Russian; the regard's name and the city names come from the core in its language.

**Checks.** `validate_world.gd` (32 headless): the query's shape and positions, the rules of requests (cold city, unoffered goods, own city, unknown city, wrong sender, the regard falling by 20 and by 10), of gifts
(sizes, goods the city lacks, wrong sender, the treasury, and the regard rising when the gift arrives, found by running the city three months with its own events answered) and of fulfilment (a request that can and one that
cannot be filled, the goods taken, the request removed). `validate_main.gd` adds 16 windowed checks (the Game menu action, markers on the picture, the held city, the first selection, the disabled military buttons, the
arrows, a cold and a friendly city's request dialog, the request through the core, the gift dialog and gift, the requests dialog, Escape, the city running on, F2): windowed EN/RU **359** each; the Game menu count
check was updated for its new entry. Captures: the map, the panel and the request and gift dialogs in English and Russian.

**Limits.** Raid, conquest and aid are disabled. The armies on the map, the editor's tools, the SDL sprites for the cities and the world map's own sound are not ported; the map is the 2D picture of the original game (read from
`Textures/Zeus_Data_Images` beside the repository), not a 3D map. The goods have names but no icons yet. The requests that a city makes of the player arrive as the engine's decision messages, as before; this screen only
lists the ones still open. Troop requests are counted by the core (`troop_requests`) but not shown, since they need an army.

## Playable-loop slice 14: the army — 2 October 2026

**Core.** The soldiers' companies are the engine's banners (see `eZeus/AGENTS.md`, "Army"). The `army` query lists them (kind, name, size, tile, at home or called out, abroad, fighting); a full snapshot always carries them and a
delta only when they changed; `army_call` / `army_home`, `banner_call` / `banner_home` and `banner_move` are the SDL army menu's buttons and the right click (`eGameBoard::bannersBackFromHome` / `bannersGoHome`,
`eSoldierBanner::sPlace`). The housing supplies the soldiers by the engine's own rules, so nothing was invented: common houses send rock throwers (archers in an Atlantean city), elite houses hoplites, and level 4 with horses
horsemen (chariots in an Atlantean city). A called-out soldier walks out of the house that supplies it. `test_soldiers` exists for the validators.

**Models.** Six new people-kit walkers, exported, optimized and baked like the earlier ones: Atlantean hoplite, archer and charioteer, Greek hoplite, slinger and horseman. The designated test city is Atlantean (its
banners are archers, 79 soldiers in ten companies), which is why the Atlantean set came first and why the tower archer now uses `walker_archerposeidon`. Captures: a sheet of the six models, the panel with the flags
over the palace, and the called-out archers standing at their banners.

**Godot.** `ui/army_panel.tscn` (generated by `scripts/build_army_panel_scene.gd`) and `ui/army_panel.gd`: a summary, Call all out and Send all home, a row per company (a swatch in the kind's colour, the company's name,
its kind, "8 of 8" and its state) and a card for the chosen one (Go to, Call out or Send home, Place banner). `scripts/army_view.gd` stands a flag on each placed banner (a pole with a gold finial and a cloth that
waves, in a colour per kind) and rings the chosen one. `main.gd`: Game, Army… or F4; a left click on a flag chooses its company; the right button moves the chosen banner as in the SDL view, and Place banner then a click does the
same; any other click inspects and closes the panel; Escape cancels a placement, then closes the panel. English and Russian strings are in the table; the company and kind names come from the core in its language.

**Found on the way.** Calling the army out, sending it home and calling it out again with no tick in between crashed the process (a null dereference while a company was called out). Soldiers sent home end their move by
`eSA_goHomeFinish`, which calls `eCharacter::kill` (that clears the character's tile); a killed soldier stays in its company until the next tick's clean-up (`emptyRubbish`), and calling the company out again before then
sends it to its banner through the null tile (`eFightingAction::goTo`). I did not trace which soldiers end their move at once (the ones still standing at their house are the likely case, since they are called out and sent home within the same instant). In the
game's loop a tick falls between two orders, so the window is short, but queued commands run one per frame; the army commands now settle finished path tasks and discarded characters first, as a tick does, and the
repeated call-out and send-home sequence of `validate_army.gd` (and a standalone repro that crashed before) now run clean. The shared engine was not changed (so the SDL executable needed no rebuild).

**Checks.** `validate_army.gd` (35 headless): the query's shape and totals, the snapshot rule (carried when changed, left out otherwise), soldiers joining, a company called out and sent home, the whole army called and sent home,
the archers' model, the rule that a company without its houses sends nobody out, banner placement (to a tile, to the palace area, other banners untouched), refusals that change nothing, and archers staying out while time passes.
`validate_main.gd` adds 25 windowed checks (the Game menu action and its row count, flags on the map, the choice and its ring, orders and their messages, Place banner and the right button, a click on a flag, clicking elsewhere,
F4, Escape, the language): windowed EN **384** (359 plus 25); the Game menu count check became 11. `validate_assets` 279 (273 plus six), `validate_geometry` PASS after recording exactly the six new assets,
`validate_characters` now counts 38 refined walkers (it still said 31; the archer had already made it fail), `validate_walls` accepts either archer model.

**Limits.** Fighting is not ported: no attack or death poses for the soldiers (only walking and standing are baked), no invasion decision interface (the invasion events still say "Detailed decision interface pending"),
no enemy soldiers or their models, no heroes' halls beyond the two with models, no amazon or Ares warrior companies (no models), no enlisting of forces, so raids, conquest and military aid on the world map stay disabled.
The Greek soldiers' call-out is not exercised by a test (the test city is Atlantean and has no elite houses); their models are checked and the mapping is in `walkerAsset`. The SDL army menu's four tactics buttons are not
carried over (they have no behaviour in the engine's army menu either).

## Main-menu Gates of Hades — 2 October 2026

The earlier polished-column/cyan gateway prototype is replaced by a cinematic
underworld entrance. `ui/login_scene_3d.tscn` delegates to `login_scene_3d.gd`:
locally seeded, bevelled masonry, a true hollow voussoir arch, fluted columns,
bronze Greek-key relief and bident medallion, a fourteen-step stair, individual
causeway slabs, canyon rock layers, distant ruined columns and the Styx.
Two retained Hades sculptures are batched with stone finishes; their original
GLBs and source manifests remain intact. The user's reference informed scale
and atmosphere; no Warcraft artwork or branding was imported.

The dark portal has a moving fiery threshold and inner depth, rather than an
additive white centre. Crossed shader flames, 276 bounded ember/soul particles,
five moving soul trails, seven mist cards, water ripples, photographed cloud
texture and a crescent moon add motion. World-projected scanned stone materials
retain rough pores, normal detail and damp low surfaces; a lower camera with
small mouse parallax, filmic mapping, bloom and a vignette frame the gateway.
All static surfaces are indexed and batched by finish (346,494 static triangles,
29 total mesh instances). Primitive meshes receive explicit white vertex colours
before batching, preventing black cylinders/heads. The historical
`build_login_scene.gd` entry point no longer overwrites this scene with the old
prototype.

The main page is left-aligned; adventure, briefing and load panels keep their
central layout and existing commands. The empty central container ignores mouse
input so it cannot block the main page beneath it. City automation flags skip
menu geometry. Mobile stays the renderer, with SSR, SSAO and volumetric fog
explicitly disabled; no C++ rules, native RNG, saved maps or live Blender scenes
were changed. Retained texture and sculpture provenance remains `needs_evidence`
in `assets/menu/menu_sources.json`.

Verification: `tools/review_menu.py` drives the actual menu with mouse clicks,
scratch settings/saves and protected-file hashes. See the validation document
for the final EN/RU resolution runs. Existing broader gameplay/parity gaps remain;
this slice establishes menu presentation and navigation, not whole-game parity
or production-ready art. Further sculptural refinement, visual acceptance,
cached scenery setup and sustained minimum-Mac profiling remain pending.

## Engine event words (monthly summary, shortage and risk warnings) — 2 October 2026

The three events the engine raises itself (`eEvent::monthlySummary`, `shortageWarning`, `riskWarning`) have no entry in the game's message catalogue, so the embedded core sent them as toasts titled with the raw
event name and an empty body. `presentation/eenginemessages.h` now words them in the core's language (English and Russian) from the SDL view's own `text/language*.txt` keys and the city history (population, treasury,
food and unrest over the month), and the service's event handler uses it before the catalogue. No shared engine or SDL code changed. 105 other event kinds (god, monster, hero, pyramid and request messages, worded by the SDL
handlers from the god, monster, hero or city the event carries) still arrived without words then (slice 18 words them); `event_texts` (validators only) lists them. Evidence and limits are in `GODOT_VALIDATION.md`.

## Playable-loop slice 15: fighting — 2 October 2026

**What the engine does and what was added.** The engine already fights: an invasion handler (`eInvasionHandler`, started by the invasion event's "fight" decision) marches the invaders on the palace, gods and heroes
step in (the goddess Artemis was on the field when the test city's first invading force was beaten; I did not establish who struck which blow), and the soldiers' actions are `fight`, `fight2` and `die`. The engine calls the companies out by itself only for computer-controlled cities (`updateCityDefense` runs for `!p->isPerson()`; in the first headless battle no archer of the player appeared, which is how this showed): a human player orders the defence, with
the army panel of the previous slice. The invasion's decision (surrender, bribe or fight) already reached the player as a decision message with its buttons; only troop requests (`fCA0`, which need
the enlist-forces dialog) still say "Detailed decision interface pending". What was missing was the sight of it: no soldier but the archer had a model, and no walker could do anything but walk or stand.

**Models.** The people kit's soldier, hero and god identities, through the same natural-people export as the earlier walkers: the player's three Roman-army soldiers (`walker_hoplite`, `walker_horseman`, `walker_rockthrower`; the earlier slice had mapped the Greek player's soldiers to the Greek
armies' `greekhoplite` set by mistake, see below), every nationality of the invasion handler (Trojan, centaur, Persian, Oceanid, Egyptian, Atlantean, Phoenician, Mayan, Greek, and the amazon with its spear and bow forms and the warrior of Ares), the fourteen Olympians
and the eight heroes (Bellerophon on Pegasus): 46 new models, 55 with the nine that were exported again. Each carries clips next to its walk: `fight`, `fight2` (the slinger's cast), `die`, and for the gods `bless`, `disappear` and `appear`.
The exporter captures them from each identity's `STATES` (the people kit's own motion functions, at their native frame counts) as shape keys; props that the walk puts away (a gladius, a club, a stone) are included by taking their rest geometry from the first clip frame that shows
them and folding them to a point inside the body in the poses that hide them (a first attempt left them out, so soldiers fought bare-handed). `bake_walker_vat.py` turns the clips into poses; the heaviest model (Bellerophon on Pegasus, 32,810 vertices) has a 15 MB pose texture, a foot soldier 4 to 7 MB, and 385 MB
of pose textures were added in all (the models folder grew from 1.2 GB to 2.1 GB on disk; only the models in view are loaded). Mounted units and centaurs get a 32,000-vertex allowance (`MOUNTED`); foot soldiers keep 15,000. The centaurs have a man's torso on a horse's body with a folded neck, as in the 2D sprites
(`art/characters/people/centaurhorseman/preview_0_walk.png` shows the same), which reads as a floating torso from the side.

**Presentation.** `scripts/walker_combat.gd` plays the clip the walker's `action` asks for (4 fight, 5 fight2, 6 die, 15 appear, 16 disappear, 17 bless, 18 curse) through the pose shader's primary clip slot, and turns a fighter to the core's `orientation`; `main.gd` has four hooks for it. Fight loops
play at 10 frames a second; the die clip plays once in a second (a corpse stays under two seconds at top speed) and holds its last frame; `appear` is `disappear` backwards when a god has no clip of its own. While an enemy force is in the city every snapshot carries `invasion` and `invaders` and a red notice
at the top of the screen counts them (`ui/invasion_banner.gd`; English and Russian strings). The army panel and the flags of the previous slice are unchanged. The notice's button ("Go to the invaders") jumps to `invader_at`, since a human player has to find the fight to send the army to it.

**The test harness.** `test_invasion <nationality> <infantry> <cavalry> <archers>` (validators only) lands a force through the engine's own `eInvasionHandler`, with a far-future `eInvasionEvent` (the handler reports its outcome to its event) and the hostile team `neutralAggresive` (the test world has only allies,
so no real enemy exists to invade it). A first version without the event aborted in the handler's `assert(mEvent)` when the invaders won.

**Checks.** `validate_fight.gd` (31 headless): refusals without the switch and for bad forces; ten nations land forces whose soldiers all have a model with baked walk, fight and die clips (25 different soldier models in all) and none is left without one; the core counts invaders; a Persian force
lands walking, battle music is asked for, the soldiers fight and fall (actions 4, 5 and 6 reach the snapshot), the count falls to zero, the invasion ends, and the music is the city's again; a second force of 24 lands and the army stays at home until it is called out and its banners are sent to the invaders, when 79 archers come out and fight. `validate_main.gd` adds 10 windowed checks, run last because the battle moves the clock for whatever follows (the first
placement made them run before the market checks and failed three checks that follow it): the notice is hidden in peace, shows the count, has a button that takes the camera to the invaders, and follows the language, the models carry clips, a fighter's pose indices are its clip's frames with the blend at 1, it faces the core's direction, and a fallen soldier plays
the die clip and holds its last frame (measured on its own state, because the corpse is gone within the time a check can wait): windowed EN/RU **394** each. `validate_assets` (325) and `validate_characters` (172 checks, 84 refined walkers) accept the new clips (they hard-coded exactly 35 frames per model,
and now walk_00 may also be present); `validate_poses` (9,445 frames) allows a larger gap for poses that move a part a long way, which two gods' disappearing frames needed (a fingerprint gap of 0.0058 against the 0.004 allowed). `validate_geometry` records the 46 new models, and the five existing models that were exported again
changed by under 1 percent of their triangles.

**Correction to the previous slice.** The player's Greek soldiers use the Roman-army identities (`hoplite`, `horseman`, `rockthrower`, as the SDL view's `fHoplite` and so on), not the people kit's Greek set (`greekhoplite`, ...), which belongs to the Greek armies of other cities (`ePlayerSoldierType::greekHoplite`).
The mapping now says so. The Atlantean tower archer and companies were not affected.

**Limits.** Monsters (the hydra, medusa, minotaur, the cyclops and the rest) had no model in this slice (they got theirs in slice 17). The player's armies abroad (raids,
conquest, aid), the troop-request decision and the enlist-forces dialog were still not ported then (slice 16 did them). Nothing shows a soldier's health or damage; sounds are the native ones. The fights were checked in the test city's one real battle (a Persian force beaten inside the test city) and in windowed runs, not against an
army that wins. A pose texture is read from disk the first time a type of walker appears, so the first battle of a session pauses briefly while the models load (not measured).

## Playable-loop slice 16: the world map's military dealings — 2 October 2026

**Core.** Raids, conquest (or reinforcements for a city of the player's), defensive aid, military strikes and the troop-request decision work through the core (contracts in `eZeus/AGENTS.md`, "Military dealings"). The engine's own events decide everything: the front end only asks (`eGameBoard::requestForces` has a hook for it, which the service now fills),
lists what may be enlisted, and sends the choice (`enlist_dispatch`). The `world` query carries the SDL menu's enabling rules per city (`can_raid`, `can_conquer`, `reinforce`, `aid`) and the armies on the road. A headless probe of a raid showed the whole native chain: the army travels about 200 days, the plunder arrives as the engine's message ("drachmas plundered from Gades!"), the engine
reports the cost of attacking an ally ("Allies hate you"), and the army walks home ("Warriors return from Gades"). A conquest turned the attacked ally into a vassal that pays tribute; aid arrived about a month after it was requested; a troop request became a decision with a working "send troops" choice. The two message placeholders `[time_allotted]` and `[travel_time]`, which the SDL message box fills itself, are now filled
too (a request's "in [time_allotted] months" showed the placeholder before).

**Godot.** `ui/enlist_dialog.gd` is the SDL enlist-forces dialog: companies by kind (horsemen, hoplites, amazons and Ares warriors), heroes, and one allied city's troops, each a toggle (companies and heroes already abroad are shown and cannot be chosen), a plunder chooser for raids, a city switch when the player has several, Enlist all, Clear, Send and Cancel, and the reason when
nothing is chosen. The world map's Raid, Conquer (Reinforce for the player's own cities) and Aid buttons follow the core's flags and say why they are off; Aid also offers the military strike (to a rival, when one exists) and refuses with the reason when the city does not regard the player enough, has nothing to spare, or its aid is already present. `ui/world_armies.gd` draws every army on the map: a dashed road, a disc at the part of the way covered, a head toward where it
goes and a pip per size step (orange raids, red conquests, green help, grey armies going home). In the city, a decision with "send troops" opens the same dialog over the city, and sending the troops answers the request. English and Russian strings are in the table.

**Checks.** `validate_military.gd` (49 headless): the world menu's rules (the city played, every ally, aid by regard, no rival and no army to begin with), refusals, a raid from the session to the plunder and the army's return (the dispatch refusals for no force, a bad company, a second ally, plunder not on offer; companies and a hero abroad and unselectable; the army's progress along the road;
the plunder message, the allies' reaction and the return), a conquest that makes the city a vassal (which then can be neither raided nor conquered), defensive aid (every city's regard falls by 10 and the asked city's by 20 in all, aid present about a month later), a strike on a rival, and a troop request (the decision, the session, cancelling leaves it, dispatching answers it and sends the help).
`validate_main.gd` adds 16 windowed checks (Raid opens the dialog with the core's rows and a plunder chooser, sending nothing is refused, Enlist all, a second ally replaces the first, Send puts the army on the road and the map draws it, a second look shows the companies abroad, Cancel drops the enlisting in the core, Aid costs the regard the engine says, and a troop request's button
opens the dialog over the city and is answered): windowed EN/RU **410** each. The windowed checks run last, as the fight checks do, and the test adds hoplites right before it needs them because the housing takes the test's hoplites away quickly once time runs.

**Found on the way.** An ally's troops enlisted with a raid travel as an army of their own (the map shows two armies). The SDL dialog's `fAres` flag (the god of war joining) is never set by it: its sections are built from sets that do not carry it, so the god of war cannot be chosen separately; the Godot dialog does not offer it either.

**Limits.** The test world has only allies, so conquest of a rival city, strikes against a real rival and the amazon and Ares-warrior companies of the dialog's last section were exercised only through `test_relationship` and the generic rows (the test city has no sanctuary companies). A conquest of a city that is on the board (a colony or rival on the same map) would make the engine fight in that city, which the view does not show; not tried. No display of strengths (the SDL
dialog shows none); outcomes arrive as the engine's messages. Companies at the palace have no walkers to show leaving; they are marked abroad. What the engine does with soldiers that were called out when they are sent is not checked, and the returning companies walk in from the entry point as before.

## Playable-loop slice 17: monsters — 2 October 2026

**Models.** All seventeen monsters of the engine (`eMonsterType`) have a model and a type mapping in `walkerAsset`: eight with human bodies from the people kit (cyclops, Talos, Hector, minotaur, satyr, Medusa, maenads, harpies) and nine creatures from the animal kit (Calydonian boar, Cerberus, chimera, sphinx, echidna, hydra, dragon, Scylla, kraken). Each has the walk and idle samples and the `fight`, `fight2` and `die` clips of the soldiers and gods
(`tools/godot_asset_sources.py`: `MONSTER_PEOPLE`, `MONSTER_BEASTS`, `CREATURES`, and the monsters appended to `COMBAT`), baked as poses and played by the existing `walker_combat.gd`. Creatures go through a path of `tools/export_godot_pilot.py` of their own (no human adapter; the kit's per-point `Coat colour` becomes the vertex palette, written as `CityPalette`, which is
what the plain finish shader shows; the first export had every coat white). The 342 development GLBs (17 new) import; the geometry baseline gained exactly those 17 assets and changed none.

**Core.** `walkerAsset` maps the monster character types. The snapshot says while a monster is loose in the city `monsters`, `monster` (the first one's name from the SDL string table, so it follows the language) and `monster_at`; `army` carries `monsters`. `test_monster <kind>` (validators only) lets any of the seventeen loose the way the engine's monster events do (`eMonster::sCreateMonster`, `registerMonster`, the aggressive neutral team, an aggressive
`eMonsterAction`), at the entry point or, for the kraken and Scylla (the engine's `eWaterMonster`s), in the deep water nearest to it. The engine decides everything else: the monster waits, goes out, patrols and goes back; battle music is asked for while it is out. No shared engine or SDL code changed (the SDL executable was not rebuilt).

**Godot.** The invasion notice (`ui/invasion_banner.gd`) also announces monsters: "A monster stalks the city: Minotaur" with a "Go to the monster" button that takes the camera to it, or a count when there are several (invaders first when both are present). Three new strings in each language.

**Checks.** `validate_monsters.gd` (34 headless): the command is refused without the validators' switch or for an unknown kind, the city starts with no monster, each of the seventeen is let loose and counted, becomes a walker of its own model, is placed where the snapshot says and named, every model has its baked walk, fight and die poses, a Cerberus, a minotaur and a kraken go out and roam and bring battle music, the kraken starts in the water,
and the Cerberus fights what it meets (action 4 or 5 reaches the snapshot). `validate_main.gd` adds 10 windowed checks (the notice names the monster, takes the camera to it and follows the language, the minotaur's fight, fight2 and die clips play through the pose shader, a kraken in the water, two monsters announced together): windowed EN/RU **420** each. `validate_characters.gd` now expects 92 human-bodied assets and lets the harpies hover.

**Limits.** A monster's health and the damage it takes are not shown, and nothing slays one in the tests (the player's companies can be sent to it with banner placement, which was not exercised). The event messages of the monster timeline (appearance, slaying) remain among the 105 event kinds without words. The creatures keep the kit's sizes and plain materials; the models are 1 to 34 MB of GLB and 2 to 24 MB of baked poses each,
so the first appearance of a monster loads its pose texture from disk (not measured).

## Playable-loop slice 18: the words of gods, monsters, heroes, invasions and requests — 2 October 2026

**Why.** The monsters of slice 17 and the fights of slices 15 and 16 raise events (a monster attacks, is slain, a god visits or invades, an invader sets out, a city thanks or rebukes the player for a request) that the message catalogue has no entry for: the SDL view words them in its own handlers from the god, monster, hero and city an event carries. In Godot they arrived as toasts titled with the raw event name and no text (105 of the 338 event kinds).

**Core.** `presentation/eeventwords.h` words 103 of them from the same `eMessages` tables as the SDL handlers (`eGameWidget::handleEvent` and the `handle*Event` helpers in `widgets/egamewidgetevents.cpp`), with the same substitutions: the visit cycle of wooing and jealousy for a god (the SDL view's own counter), a god's invasion, help (with its reason), monster unleashed, sanctuary complete, disaster, end of disaster and the resumption of trade
(Zeus, Poseidon and Hermes only), the two quests and their fulfilment with the hero's name, the arrival of a hero, the monster timeline (warning with the months and the reason, 24, 12, 6 and 1 month warnings, the attack, in the city, slain), the invasion timeline (through `eMessages::invasionMessage`), the 15 sanctuary, pyramid, monument and shrine completions, and the 63 comply / too-late / refuse replies (the favour message with the reply as its reason). The god, monster and hero voice lines are asked for as the SDL
view asks (`sounds`). The service's event handler tries these words first and then the catalogue. `playerInvasion` and `playerGodAttack` are alert tiles in the SDL view with no message, so they are silent. The core's language (English or Russian) decides the words. No shared engine or SDL code changed (the SDL executable was not rebuilt). `test_raise` (validators only) raises any event kind with the god, monster, hero, time, quest, reason and city a caller names; `event_texts` now lists none.

**Differences from the SDL view, on purpose.** Every occurrence of `[reason_phrase]` is filled: the chimera's warning names the reason twice and the SDL view's single replace leaves the second as a literal placeholder. The satyr has no message tables in the game (no event sends it), so it stays silent as in the SDL view.

**Toasts show the condensed wording.** A god's quest is 300 characters, which filled the left of the screen with toasts. Every event now carries the SDL view's condensed text (`eMessageType::fCondensed`, the wording of its pop-up cards) as `brief` when the table has a useful one (twelve characters or more, not the full text); `main.gd` shows it on the toast and the message log keeps the whole text. This applies to the catalogue's messages too (fire, collapse, trade news ...), as in the SDL view's cards.

**Godot.** Informational messages already became toasts and log entries and decisions keep the top-centre box; only the toast's body changed (`brief`).

**Checks.** `validate_events.gd` (45 headless checks, English and Russian): unknown events, gods, monsters and cities are refused and nothing is raised without the validators' switch; the audit lists no unworded kind of 338; all 14 gods have their visit, invasion, help, monster, sanctuary, disaster, end of disaster and both quests with their fulfilment (no placeholder left); three visits of one god say different things; the quest names its hero; trade resumes for exactly Zeus, Poseidon and Hermes; the voice lines are asked for; all eight heroes arrive with words and a voice;
the 16 monsters with messages have all their warnings, the attack, in-city and slain messages (with the months in the first warning and a reason phrase that appears twice filled in); the satyr is silent; the invasion warnings name the invader's city and army; the player's invasion and god attack are silent; all 15 completions and all 63 replies are worded with the city's name; thanking and rebuking differ; the Russian tables are used, and an event carries its condensed wording shorter than its text. `validate_embedded.gd` now requires an empty audit. `validate_main.gd` adds 6 windowed checks (a god's visit,
a quest, a monster slain and a city's thanks reach the toasts and the log with their words; the player's own invasion says nothing): windowed EN/RU **426** each. The fall check of the fight run waits up to 100 seconds instead of 60 for a soldier to fall (it failed once in a run before this and passed on the next).

**Limits.** The words are in the log and toasts; the SDL message box's portraits of the god, monster or hero are not shown. Messages that the SDL view shows as a modal box (an invasion warning, a god's wrath) are toasts here like every dismiss-only message; the decision messages (surrender, bribe, requests) keep their box. The voice lines are asked for but their files are the ones present in `Audio/Voice_*/Walker` (some are missing in the workspace, which the audio slice already reports).

## Playable-loop slice 19: heroes' halls — 2 October 2026

**Why.** The monsters of slice 17 cannot be hurt by the army: the engine's `eCharacter::defend` returns at once for a monster, a god or a hero, and only a hero's own hunt (`eHeroAction`) slays a monster. So the loop of the Mythology category that the Godot game lacked is the heroes: a god's quest lets the city build a hero's hall, the hall asks things of the city, the hero is summoned, arrives, slays his monsters and goes on the quests of the gods.

**Models.** The six missing halls (`hero_hall_achilles`, `bellerophon`, `hercules`, `jason`, `odysseus`, `perseus`) were exported from the existing Roman heroon recipe (all eight heroes are in `RECIPES`); 348 development GLBs, and the geometry baseline gained exactly those six.

**Core.** `buildSpecs` has the eight halls (4x4; the creators build `eHerosHall` of the hero) and the service records a built hall with `eGameBoard::built` as the SDL view does. The inspection has a `hall` object (stage, requirements with their wording and how far the city is, `can_summon`); `hero_summon <x> <y> <token>` summons the hero through the engine (token-guarded like every building control); `world` lists the gods' `quests` and `world_quest <id>` sends an arrived
hero on one (the SDL overview's quest button). Validators only: `test_quest`, `test_hero`, `test_allow`; `test_monster` now puts a land monster at the scenario's monster point when it has one. Details are in `eZeus/AGENTS.md`, "Heroes".

**Two bugs of the engine found on the way (shared code, `eheroaction.*`).** (1) A melee hero fights only within one tile of a monster (`fightMonster`), but the path of his hunt ends on a tile *next to* the monster's, up to 1.41 tiles away diagonally: in about half of the runs he stood beside the monster, unable to fight; the range is now two tiles. (2) A hunt that ends in the very step it began (the hero already stands by the monster, or no path leads to it) began the next hunt in the same step (`lookForMonster` / `huntMonster` / the hunt's finish action in a loop, a path search per iteration: a million in
40 seconds, and the city stopped, in about half of the runs of a validator that slays sixteen monsters in turn, the pairs differing from run to run with the order of the worker threads). A hunt that ended in the step it began now waits 600 time units for the next search (`huntEnded()`), while a chase that took time re-hunts at once, as before. With both, eight runs of the validator in a row slay every monster and none hangs. The SDL executable was rebuilt with the fixes, and the replay parity and the save round trip pass.

**Godot.** A "Heroes' halls" group in the Build menu (the dock icon is `ui/icons/heroes.svg`), offered when a quest has allowed the hero; the hall's inspector (`building_inspector.gd`): the hero's name, the stage of the summoning, "The hero asks of the city" with each requirement and what the city has (amber while unmet, green once met) and a Summon button that is off until all are met; the world map's "Quests of the gods" button and dialog (each quest with its god, the hero and whether he has arrived, and a Send button for an arrived hero). Strings in both languages.

**Checks.** `validate_heroes.gd` (66 headless, English and Russian, seeded): the eight halls are listed with models and names in the core's language; none is offered at first; a god's quest lets the city build the hero's hall; the hall is built and recorded (a second is refused); its inspection lists the requirements (in Russian too), some met and some not; the summon is refused while one is unmet, for a stale token, for no hall and without a token; the saved city's Theseus hall shows his arrival; the hero arrives (stage, walker with
fight and die clips, the event in words, the quest ready); he fights and slays his monster and it vanishes; every other hero slays his monsters too; a quest not asked for is refused, an unarrived hero cannot be sent, the arrived hero is sent and the quest leaves the list; the hall says he is away. `validate_main.gd` adds 13 windowed checks (the Build menu offers the hall after the quest and not once built; the inspector's rows, stage text and off Summon button; the arrival; the monster notice counts one monster less after the hero slays one; the world map's quest list and Send): windowed EN/RU **439** each.

**Limits.** Sanctuaries (the gods' temples, which several heroes' requirements and the gods' visits depend on) are not buildable yet: a hero who asks for one cannot be summoned in a real game until they are. The hall's requirements that count building kinds (the culture access ones) are the engine's own and are shown as it words them. A hero's quest ends with his leaving the city and, 150 days later, the god's thanks (`godQuestFulfilled`); that wait was not run through. The hero has no health or damage display, and
the SDL message box's portrait of the hero is not shown (the arrival is a toast and a log entry with words).

## Playable-loop slice 20: the gods' sanctuaries — 2 October 2026

**Why.** The Mythology category of the SDL game was missing from the Godot build: the gods' sanctuaries, the main building of the game, could not be founded, which also kept several heroes (Perseus asks for the sanctuaries of Athena and Hermes) from being summoned.

**Models.** The 14 missing statues and monuments (athena, atlas, demeter, hades, hera, poseidon, zeus), exported from the existing art recipes: 362 development GLBs, and the geometry baseline gained exactly those 14 assets.

**Core.** Fourteen `Kind::sanctuary` rows in `buildSpecs`; the layouts are loaded when a session is prepared; `buildable` reports the footprint, drachmas, marble and availability of each and the city's sanctuary allowance; `preview` answers with the centred footprint and the list of pieces; `build` applies the SDL rules (limit, marble) and calls the engine's `buildSanctuary`. The snapshot gives each piece `grow` (and `stretch` for a foundation); the inspection of a piece is of its sanctuary
(`monument`: progress and what is needed in the SDL's words, workers, and for a finished one the god's description and help), with `monument_halt` and `sanctuary_help`; the `mythology` query is the SDL page. Two validators-only helpers: `test_allow` lets a sanctuary in past the scenario's limit, and `test_stock` spreads over the stores. Nothing in `engine/` or `widgets/` changed for the sanctuaries; the shared code changed only in the hero fix below. Details are in `eZeus/AGENTS.md`, "Sanctuaries".

**Godot.** The "Sanctuaries" group of the Build menu (dock label "Temples", its own icon), listing drachmas and marble; the placement ghost of the whole layout over the footprint (tiles green or red, the hint with the cost and the reason: no marble, at the limit ...), turned by T; foundations that rise as the work goes on; the inspector's monument section (the progress text, Halt or Resume the work, and for a finished sanctuary the god's description, a help button with its timer and the god's answer); the Game menu's "Mythology… (F6)" page with a Show button for each sanctuary, god attacking and monster at large. Strings in both languages.

**The hero fix, again.** Running the heroes' validator many times (the sanctuaries slice added a check in the same suite) showed that the first fix of slice 19 was not enough: a hunt that ended in the very step it began started the next one in the same step, endlessly (the city stopped, in about half of the runs). `huntEnded()` now makes such a hunt wait; a chase that took time still re-hunts at once. Eight runs in a row pass and none hangs. The SDL executable was rebuilt.

**Checks.** `validate_sanctuaries.gd` (71 headless, English and Russian): fourteen sanctuaries listed with sizes, marble, model and name in the core's language, every piece of every layout has a model; a preview lists the pieces and every tile, a quarter turn swaps its sides, an unavailable sanctuary is refused; the allowance offers it and lets one more in; the footprint is centred on the pointer; a site over buildings is refused; founding pays the drachmas, is not undoable, puts the foundations (slabs and statues at 0%) into the
city; the inspection of any piece is of the sanctuary and words the progress; halting, resuming, a stale token and a missing flag; the carts and workers finish it (a hundred percent, the pieces risen), its god walks in the city; the god is asked for help and answers in words, and asking again is refused in words; the mythology page lists three sanctuaries and, with a Cerberus loose, the monster; the city at its limit refuses another; Atalanta's requirement of a sanctuary to Artemis follows its building. `validate_main.gd` adds the windowed checks (the Build menu, the ghost with its pieces, its cost and the turn, the foundations, the inspector's progress and the halt button, the Mythology page and its Show button); the Game menu count is 12; windowed EN/RU **502** each.

**Also done on the way.** The fight validator of slice 15 is flaky by nature (about one battle in five goes on without a single death, depending on the order the worker threads finish their path searches): it now tries the battle up to three times. The windowed military check sets the allies' regard back to 80 first (it falls as the run goes on, and an ally needs more than 50 to be enlisted), and the late windowed checks answer pending decisions before they build. The windowed run's first checks need the window in front: a run started while another application had the focus failed "native city starts paused" and passed on the next.

**Limits.** The pyramids, monuments and shrines of the expansion (the other `eMonument`s) were not buildable in this slice (slice 21 adds them); asking a god to attack an enemy city was not offered (slice 23 adds it); sacrifice overlays, braziers and the priestess were not shown (slice 24 adds them) and the temple's finished-state animations are not shown; the stages of a piece are a height scale and a paving slab, not separate models; the marble of the test city is scarce (32 slabs and no room to store more), so only the smaller sanctuaries can be completed in it. Another session was changing the HUD and its strings (`ui/inspection_summary.gd`) at the same time; its changes are not part of this slice.

## Playable-loop slice 21: pyramids, monuments and shrines — 2 October 2026

**Why.** The Poseidon expansion's wonders were the last large part of the SDL game's build menu that the Godot city could not found: the saved city's scenario grants a pyramid, five adventures grant pyramids or shrines, and the monuments of the sky, the 42 shrines and the five Olympian and Atlantean monuments were nowhere in the Godot city but as the one modest pyramid it already drew.

**Models.** None new: a pyramid is made of the pieces that already had models (the 72 models `pyramid_p1_<n>` and `pyramid_p2_<n>`: faces, corners, capstones, floors and steps; the sanctuaries' statues, monuments, altar and temple, and the observatory and museum buildings); the geometry baseline is unchanged. The construction-stage cubes of the SDL sprites (`pyramid_p1_34` to `pyramid_p1_43`) exist as renders but were not needed: while a piece is built the ground itself rises under a paving slab.

**Core.** 54 `Kind::pyramid` rows in `buildSpecs`; footprints from the engine's `ePyramid::sDimensions` (3x3 to 9x11), centred on the pointer, no turning; founding through the engine's own `buildPyramid` (no drachmas, no marble up front: the carts bring the materials). The scenario grants each one once with its dark and light levels. `preview` lists the pieces (`ePyramid::sPlan`) with `lift` (the ground each level raises); the snapshot gives larger pieces their real rectangle, the filler tiles no model, and each piece `grow` or a slab while its ground rises; the inspection of any piece is of the monument, with the game's own description when it stands. Two validators-only
commands, `test_allow <name> [levels]` and `test_fund <x> <y>`. **Shared code changed (small):** `ePyramid::initialize`'s layout tables moved into a function (`sLayoutTables`) that the new `ePyramid::sPlan` reads, with identical behaviour; `ePyramidPlan` in `epyramid.h`; `eBoardCity::allowPyramid`. The SDL executable was rebuilt and signed. Details are in `eZeus/AGENTS.md`, "Pyramids, monuments and shrines".

**Godot.** "Pyramids" and "Shrines" groups of the Build menu (their own dock icons; the cards say "Materials by cart"); the placement ghost of the whole pyramid over its footprint, each piece lifted onto the ground its level will raise; the city's ground rising under the work, then the faces, capstone, statue, monument, altar, temple, observatory or museum; the inspector's progress and Halt button while it is built and the game's description once it stands. Pyramid models are lowered by `PYRAMID_RISE` so that a ramp ends at the ground of the next ring (the models are authored at the SDL's proportions, the terrain here rises .22 of a tile a step). Strings in both languages.

**Checks.** `validate_pyramids.gd` (103 headless, English and Russian): 54 buildings with the engine's footprints, names in the core's language, a model for every piece of all 54 layouts (inside the footprint, no overlaps, whole levels of lift), the saved city's scenario granting only the standard pyramid, unlisted ones refused, a grant's dark levels shown as black marble; a Zeus minor shrine founded beside a road at no cost, its pieces as slabs, the grant used up and a second refused, the inspection of any piece (in Russian too), halting and resuming, the funded work finished by the workers with the ground under the statue risen four steps, the description naming Zeus, the shrine demolished (pieces gone, ground level, grant given back); and **all 54 founded in fresh cities on one site, each with exactly the pieces it previewed** (places and sizes); the adventures that grant pyramids offer them and what they grant can be founded; a city with a half-built standard pyramid is saved and reloaded with identical terrain, ground raised by the work included, and `tools/save_roundtrip.py` now opens that save in the SDL executable, which reaches the identical state digest (replay parity and the other two round trips pass too). `validate_main.gd` adds 12 windowed checks (the Build menu's Pyramids and Shrines and their "Materials by cart", the ghost's 25 pieces with the capstone two levels up, the foundations, the inspector's progress and what funding empties, the finished pyramid's description); the windowed EN and RU runs pass **563** checks each and fail one, the Game menu's item count, which another session's new "Interface options…" entry changed from 12 to 13 (the expectation in `run_save_checks` is theirs to update; it is not a pyramid check); `validate_buildings.gd` skips the pyramids in its build-and-undo loop (they are not undoable: the engine does not record them).

**Limits.** The player does not choose the dark and light levels (the scenario does); the construction shows the rising ground and slabs, not the SDL's ashlar cubes; the Temple of Olympus has the Greek finish whatever the city; the observatory and museum on a pyramid are their standard models without workers; the same pyramid pieces' look (steep hipped faces) is the existing art's, scaled to the terrain, not redrawn. A pyramid that is not on a road waits for its materials (the inspector says so).

## Playable-loop slice 22: controls and game settings — 3 October 2026

**Why.** The Godot city had fixed keys and almost no options: the Controls and Settings menus of the SDL game (`eSettingsMenu`, its key bindings) had no counterpart, though the key table in this document's controls list promised a rebinding UI.

**Controls.** `scripts/key_bindings.gd` is the one table of the 33 rebindable controls (the eight held camera keys, the city overview, the placement turn, demolition, undo, pause, quick save and load, the world map, army and mythology keys, mute, the details panel, fullscreen and the overlays' keys), each stored as a physical key (so QWERTY and Cyrillic layouts behave alike) plus Ctrl/Cmd and Alt; Shift is never part of a binding. Every handler asks the table instead of a `KEY_x` constant (`main.gd`, `world_map.gd`); the held camera keys are InputMap actions kept in step with it. Game, Controls… (`ui/controls_dialog.gd`) lists them by group; a click on a key asks for the new one,
Escape cancels, a key another control has is swapped with it, and anything refused (Escape, Delete, modifier keys, a modifier on a camera or overlay key, a swap the other control could not take) is said in words; Reset per control, Restore defaults, and the list of what cannot change (Escape, Delete, Shift, the mouse and the world map's arrows). The Game menu entries, the overlay menu's `[key]`, the undo, turn and pause tooltips and the camera hint all name the player's keys.

**Settings.** `scripts/play_settings.gd`: autosave every 0 (off), 2, 5, 10, 15 or 30 minutes into 1, 3, 5 or 10 slots (the running city follows at once), fullscreen (also by its key; remembered and applied at start), the language of the voices (as the interface, English or Russian), and the camera's pan, turn/tilt and zoom speed (50 to 200%, Controls dialog). Game, Game settings… (`ui/game_settings_dialog.gd`). All of it is in `user://settings.cfg`, never in the original game's `settings.txt`; automation sees the defaults and never writes the player's file (a test points `ezeus_settings_path` at a scratch file); a damaged or hand-edited file is not believed.

**Checks.** `validate_controls.gd` (59 headless): the table's defaults are the game's original keys and no two share one; events match with or without Shift and not with Ctrl/Alt; assign, swap, refusals, reset and reset-all, persistence, a file that gives one key to two controls or holds reserved, modifier, wrong-type and unknown entries; the held keys follow in the InputMap; the Controls dialog's rows, its asking, Escape, a modifier alone, a swap said in words, Reset, the speeds and Restore defaults; the options and their lists, a damaged file, the voice folder chosen, the Game settings dialog; turning and panning at 200% are twice as fast; everything the dialogs say has Russian text; nothing of the player's settings is touched.
`validate_main.gd` adds the windowed checks (the two Game menu entries, rebinding the turn key, an overlay key, quick save, a held camera key with its swap, the world map's own key opening and closing the map, Restore defaults, and the Game settings changing the running city's autosave); they pass in English and Russian, and the Game menu item count now compares with the HUD's own list instead of a number. The windowed runs pass **574** checks each and fail the same seven in both languages, none of them a control: the three "cursor badge stays inside the map area" checks of the new HUD, and the world map's Escape, running-again and F2 checks (which wait 0.4 s for a map that now flies for about 1.5 s, `world_flight.gd`) and the aid-regard check beside them; those belong to the interface work that was changing at the same time. The headless suite passes, with the new validator in it.

**Limits.** The SDL game's resolution list, classic font, weather and monthly-summary options have no counterpart (the Godot city has none of those features, or sizes its own window); the mouse buttons, Escape, Delete, Shift and the world map's arrow keys cannot be rebound; a key typed on a layout the physical-key table does not know is named by the Latin layout.

## Playable-loop slice 23: asking a god to attack an enemy city — 3 October 2026

**Why.** The sanctuary's inspection offered the god's help and its prayer but not the SDL button beside them, "God Invasion", with which the player sends the god against a rival city; slice 20 had left it out because the saved test city has no enemy.

**Core.** `attackInfo()` adds `attack` (`label`, `fraction`, `targets`) to a finished sanctuary's `monument` when the board has enemy cities (`enemyCidsOnBoard`); `sanctuary_attack <x> <y> <token> <city>` calls the engine's `askForAttack`, which sends the god away and raises the attack event in the target city, and answers in the game's own words for the god (`attack_answer`). No shared engine code changed; the SDL executable needs no rebuild for it. Validators only: `test_complete <x> <y>` finishes a monument at once, and `test_stock` refreshes the city's cached goods count.

**Godot.** The inspector shows a `God Invasion` button, a wait bar and the answer line (green when granted, amber when refused) under the help section, with a menu of cities when more than one enemy is on the board; the text and the answers follow the game's language. The inspection scrolls when Russian's longer words fill the panel.

**Checks.** `validate_attack.gd` (51 headless, EN/RU): a city with no rival offers nothing; in The Sands of Betrayal a finished sanctuary offers "God Invasion" with Theron as the one target and the wait over; the inspector's button, bar, answer, menu and the command they send; a stale token, a missing city and a city that is not an enemy are refused; the request is granted in the god's words, the god is away, the wait starts again, a second request is refused in words, the mythology page does not list a god sent away; the invasion is announced and the god walks Theron's land. EN/RU captures: `--attack-review`.

**Limits.** Only the adventures that put a rival city on the board offer it (The Sands of Betrayal among the new games); the SDL game also moves the view to the attacked city (`playerGodAttack`), which the Godot city does not yet do; no windowed check of the new section (the review captures it).

## Playable-loop slice 24: sacrifice scenes, braziers and the priestess — 3 October 2026

**Why.** A finished sanctuary's altar sacrifices a sheep, a bull or goods now and then; the SDL view draws a priestess stabbing the animal on the altar, or raising her arms over the goods, and the altar's braziers burn. The Godot city had the altar's model with a static flame and nothing else, so the engine's rite was invisible.

**Art.** One new model, `walker_priestess` (363 GLBs): a woman of the people kit in a saffron chiton under a cream veil with a gilt fillet and a bronze sacrificial knife (`art/characters/people/people11.py`, wardrobe profile "Priestess"); `fight` is the sacrifice (24 frames: the knife rises overhead and plunges forward and down, twice a cycle), `fight2` the offering (12 frames: both arms raised, swaying), `die` a fall. 15,500 vertices; the pipeline is the soldiers' (export, morph aliases, verification of UVs, baked poses). The animals are the existing `animal_sheep_fleeced` and `animal_ox` (the ox browned by a multiply overlay and shrunk to the table); the goods are built in code. The altar's flames are new: `shaders/ritual_flame.gdshader` tongues of fire (adapted from Hades' cape) at the three tripod braziers, rising while a rite is on.

**Core.** The altar's sacrifice kind and clock are read through two new accessors (`eTempleAltarBuilding::sacrifice()`, `sacrificeTime()`; shared header, SDL executable rebuilt and signed). The snapshot's walkers carry the rite as presentation-only records (`scene`, `role`, `rite`, `size`) for each finished sanctuary's altar that has one; nothing in the simulation changes and replay parity is unaffected. Validators only: `test_sacrifice`.

**Godot.** `scripts/altar_rite.gd` places the parts around the altar, rolls the victim, makes the goods and runs the flames; `main.gd` adds each altar's flames when the buildings change, burns them when a priestess's record names the altar, and gives walker nodes a roll.

**Checks.** `validate_rites.gd` (47 headless): the priestess's model and clips; the designated city's altars; each of the three rites shows a priestess with the right action and the right second part, at the altar's centre with its size, with stable and distinct ids and no scene at any other altar; the city's own walkers carry none; the rite ends as the engine ends it; a sanctuary that is not finished shows no rite and one that is does; the placement rules; the flames' count, positions (also for a turned altar), burning, removal and settling. `validate_main.gd` adds the windowed checks (the priestess and the sheep among the walkers at the right place and height, the sheep on its side, her clip, the braziers burning, and the goods replacing the animal with her arms raised). `--rite-review` captures the three rites from three sides.

**Limits.** The temple's emissive doorway is not animated; the SDL overlay's second figure beside the goods is not shown; the rite's cadence and kind are the engine's (the sheep or bull when the city has such an animal, else goods); no sound.

## Building choices refinement — 3 October 2026

The construction tray now sits five logical pixels above the category dock,
independently of the taller time controls, with a 206-pixel baseline height that
still grows with its contents. Search, facing buttons/angle and placement guidance
are hidden in this tray; the existing placement-turn key and native wall-fill
checkbox remain. Cards and the selected context show native numeric costs beside
an original procedural gold drachma with a raised rim, beading and lightning motif.
`ui/gold_coin.gd` renders one shared 96×96 transparent texture and disables its
viewport after three warm-up frames. Material delivery and marble requirements
retain their native wording. No simulation commands, prices or saves change.
The retained hidden controls keep existing rebinding and translation references
compatible; category browsing is the only card filter.

## Slimmer choices without amounts — 3 October 2026

Supersedes the preceding gold-cost-marker layout: building cards now contain
only the model preview and name. The selected context and folded selected-tool
card show native footprint dimensions without price/material amounts. The tray
uses its content minimum height instead of the former 206-pixel floor; card
minimum height drops from 134 to 110 pixels and still grows for translated text.
The five-pixel dock clearance and native wall-fill checkbox remain. The coin
asset is retained as source but no coin viewport is created by the HUD.
Native placement quotes and construction prices retain their existing rules.

## Foldable resource panel — 3 October 2026

The overview bar contains city, treasury, population and jobs plus a disclosure
arrow immediately after jobs. All 24 stock items now live in a separate panel
below it, folded on every new city launch. The arrow opens/closes a clipped
0.24-second reveal with opacity easing; rapid reversal cancels the previous
tween. Reduce interface motion applies the final state immediately. Welfare,
inspectors and other bounded panels follow the revealed height. Folded space
passes input to the city. Native cached stock updates and resource shortcuts
remain unchanged; no preference writes or extra polling are added.

## Native-style right-click back — 3 October 2026

Right-click now dismisses city panels even over their controls. Building choices
close and cancel their active tool together; active road/area drags and placement
cancel without construction. Inspectors clear selection; journal, objectives,
resources and minimap fold. As of 7 October, right-click on a required decision
uses its offered native Postpone action; decisions without it only fold. Escape
and the fold button retain the unanswered event. The game menu returns through
its existing pause/queue restoration.
Window-local `ui/right_click_back.gd` routes right-click through each window's
existing Escape path so settings Cancel, display Revert and nested menu return
behave identically. With no active tool/panel, right-click inspects the pointed
native tile. Selected army map orders and atlas right-drag panning remain their
existing behavior. This does not add automatic decision answers or save writes.

## Playable-loop slice 25: the rest of the SDL build menu — 3 October 2026

**Why.** About 45 buildings of the SDL game's build menu were not in the core's `buildable` list, so the Godot Build menu could not offer them: orchards (vines, olive and orange trees), livestock (goats, sheep, cattle), the fishery and urchin quay, the palace, the stadium, the hippodrome and its crosswalk, bridges, roadblocks, the horse ranch, the trireme wharf, the water park, the three columns, avenues and boulevards, the nine commemorative monuments and the fourteen gods' monuments. (Storehouse and granary are the whole Storage list in the SDL game too.)

**Models.** 22 new GLBs from the existing Blender scripts (recipes in `tools/godot_asset_sources.py`): stadium, horse ranch, horse paddock (`horse_ranch_enclosure`), urchin quay, trireme wharf, the three columns, water park, the eight hippodrome plates, goat, cattle and horse walkers, and a new Roman roadblock (`art/roadblock/build_sprites.py`: two bollards, a red-banded oak bar, a bell and a sign). The horse's walk misses the animal kit's leg tolerance at one frame; the exporter skips that one assertion for the horse only (the kit is unchanged). Goat, cattle and horse were merged by `optimize_glb_memory.py` (verified, 0 differences) and baked by `bake_walker_vat.py`. The palace, fishery, orchards, sheep and commemoratives already had models; a god's monument is the god's sanctuary colossus on palace paving.

**Shared rules.** `engine/ebuildplacement.{h,cpp}` (new, in `CMakeLists.txt` for both builds) holds the SDL view's placement rules for the special cases, moved out of `widgets/egamewidgetbuild.cpp` / `egamewidget.cpp`, which now call it, as was done for agoras (`eagoraplacement`) and the shore (`eshoreplacement`): the palace and its paving ring, the stadium, the horse ranch and paddock, god monuments, the trireme wharf's sea access and the placement of shore buildings, bridges, the road and column paths, avenue plans and their flanking streets, roadblocks, hippodrome plates and crosswalks. The SDL executable was rebuilt and signed; replay parity and the save round trips pass.

**Core.** `withMenuRest()` adds the rows to `buildSpecs` with new kinds (`palace`, `stadium`, `ranch`, `godMonument`, `shore`, `bridge`, `roadblock`, `hippodrome`, `crosswalk`, `commemorative`, `waterPark`, `animal`, `path`). Names in the menu are the native names (`menuLabel`: the commemoratives and gods' monuments use the SDL menu's own strings, group 198; the roadblock 67/27), in English or Russian. Previews list every tile with a verdict and, for buildings of several models, their `pieces` (palace and paving, ranch and paddock, statue and paving). Shore buildings face the water the engine found (the snapshot orientation, like the pier); a stadium laid along x is turned a quarter; a roadblock is drawn as its barrier across the street. Orchards and livestock drag over an area (`build_area`, an animal on each 1x2 of fertile ground while the city's sheds, dairies or corrals allow one more); columns, avenues and boulevards drag along a path (`preview_path` / `build_path`, answering like `preview_road`; an avenue lays the street beside each median tile). Monuments use up the scenario's grant and, with crosswalks, are not undoable, as in the SDL view. `test_allow` grants a commemorative or god monument by its id. Area and road drag previews now judge each tile on its own once a whole-drag verdict is clear (a blocked first tile no longer marked the rest blocked; the build always skipped only that tile).

**Godot.** The Build menu gains them in the nearest categories: Agriculture (orchards, livestock, fishery, urchin quay), Housing and roads (roadblock, bridge), Administration and security (palace), Culture (stadium, hippodrome, crosswalk), Walls and defence (horse ranch, trireme wharf: the closest to the SDL Military menu) and Gardens and monuments (water park, columns, avenues, boulevards, the 23 monuments). English and Russian names in `data/building_names.csv`, new placement messages in `data/ui_strings.csv`. Shore tools get the pier's nearby-spot help; bridges and crosswalks preview as their tiles only; free buildings (roadblock, commemoratives, gods' monuments) say "Free" instead of "Materials by cart". Walker models for goats, cattle, ranch horses and goatherds.

**Checks.** `validate_menu_rest.gd` (179 headless, EN and RU): every name listed with a model, a category and its own native name; stadium both ways, palace demolished and rebuilt with its paving, ranch and paddock, fishery / wharf / urchin quay facing their water, a bridge across the river at the cost of each tile, a roadblock on a street (refused twice or off a street), a row of four columns and an avenue with its street, an olive grove and a flock dragged, the sheds' limit on sheep and goats needing a dairy, a hippodrome plate and a crosswalk over it, the victory monument (grant used up) and Zeus' statue with twelve paving tiles, and 300 ticks of the city afterwards. `validate_buildings.gd` (535) now builds and undoes the orchards, sheep, columns and water park in its generic loop and leaves the special tools to the new validator; the test city's menu offers 84 buildings (was 46). Roads, housing, embedded, assets and construction validators pass; windowed EN and RU runs pass **588** checks each. `run_godot_pilot.py --menu-rest-review menu|build` captures the trays and builds each new kind with its ghost (11 of 11 built).

**Limits.** The hippodrome plate is chosen with T (the SDL view cycles them over time) and the water park's variant too; the god's monument uses the sanctuary colossus, not a separate small statue; no walker art for the trireme or the horse ranch's trainers beyond the horses; livestock are placed as cattle2/goat/sheep walkers like the SDL view, without their own placement ghost (the plot footprint only). The windowed runs' one failure, "asking for aid costs regard as the engine says (80 to 70)", already failed at 12:46 before this slice's core was built and is not part of it.

## Playable-loop slice 26: taxes, wages, workforce priorities, finances and the data pages — 3 October 2026

**Why.** The Godot city could not be governed: there was no way to set the tax rate or wages, to give sectors priority for workers, to read the year's finances, or to see the SDL side panel's data pages (overview, population, employment, administration, husbandry, storage, hygiene and safety, appeal, culture, science, military, mythology).

**Shared rules.** `engine/ecitydata.{h,cpp}` (new, in both builds) holds the pages' verdicts: which native string a value reads as (popularity superb … terrible, food level, the employment line, hygiene, unrest, the finances trend, the husbandry page's far too little … surplus, the hygiene and unrest pages' wording, what limits immigration, which way people move, coverage terrible … good, the commemoratives' names, a sanctuary's state, the military page's soldiers' and towers' buttons) and how serious it is. The SDL pages (`widgets/datawidgets/*`) now call it instead of their inline chains, so the two views word a city alike. It also orders the tax rates by percentage: the enum's `veryLow` holds 7% and `low` 3% (their names follow the rates), so the SDL admin page's arrows used to step None → Low (7%) → Very low (3%) → Normal; they now step by rate in both views. The SDL executable was rebuilt and signed.

**Core.** `city_data` answers the eleven SDL pages (each with its lines: label, value, severity; and its "See …" overlays), the tax rates (in percentage order, with their ids), the wage rates, the workforce allocation (the eight sectors with priority, need and workers; the industries short of workers), the city's finances (last year and so far this year, the SDL finances window's rows) and the military page's buttons, all in the core's language; mythology stays its own query. Reading changes nothing (no resource refresh; the replay digest holds). `set_tax <id>`, `set_wage <0-5>`, `set_priority <sector 0-7> <0-5>` (the workers are shared out again, as the SDL allocation window does) and `man_towers <0|1>` answer the new data; anything else is `invalid_city_setting`.

**Godot.** `ui/city_dialog.gd`, the City window (F7, rebindable, or Game, City…): a tab per page (Summary, Population, Employment, Administration, Husbandry, Storage, Hygiene and safety, Appeal, Culture, Science, Military, Mythology). The values are tinted green, amber or red by their severity; Employment has the wage list, the workforce table with a priority list per sector and the industries short of workers; Administration has the tax list ("Very low (3%)" …) and the finances table; Military has the muster / send-home and man-towers buttons; Mythology lists the sanctuaries, attacking gods and monsters with Show buttons; every page's See buttons open its overlay. Changes go through the command queue; the window refreshes every two seconds while open (not while a list is open). Strings in both languages.

**Checks.** `validate_city_data.gd` (64 headless, EN and RU): the pages and their verdicts, every See button a native overlay, the taxes in percentage order, the finances adding up, the Russian dictionary's words, asking leaving the city and the replay digest unchanged, every tax rate and the wage rates set and refused when unknown, husbandry losing its workers with no priority (217 to 0 in the test city) and getting its full need at very high (320), towers manned and stood down, and 300 ticks with the new tax rate. `validate_main.gd` adds the window's checks (F7, the twelve tabs, tinted verdicts, the employment lists, a priority and the wage set through the queue, the tax list's order and setting, the finances table, See water) and `validate_controls.gd` the F7 default.

**Limits.** The overview's requests list (god quests, city requests) is left to the world map and messages; the pages are a window rather than the SDL panel's column; the SDL finances window's per-row lines and the workforce window's clickable industries are plain rows here.

## Journal follows its right-side button — 3 October 2026

The journal/messages rail is now right-aligned, below the compact top bar at the
same level as the welfare shortcuts. Its disclosure opens eight logical pixels
below the icon and shares the right edge. Height remains content-bounded above
construction/time controls, with scrolling, retained reading Controls, full
history and unread semantics unchanged. Resource disclosure/scaling move both
icon and journal together. The right-click back behavior also closes the journal.

## Character window — 3 October 2026

**Why.** The SDL game's right click on a walker (portrait, name, occupation, its spoken line and voice, a cart's errand)
was missing from Godot.

**Shared rules.** `engine/echaracterinfotext.{h,cpp}` (new, both builds) holds the SDL window's name, occupation, message
and errand code, moved out of `widgets/infowidgets/echaracterinfowidget.cpp`, which now calls it. The line choice uses
`eRand::cosmetic()` instead of the simulation generator (the SDL window used to draw from it). `eSoundVector::path(id)`
gives the voice file; `eTrailer::follow()` the trailer's driver.

**Core.** `character_info <walker id>`: id, type, asset, kind (person/god/hero/monster), name, occupation, text, voice
(relative, as `Audio/Voice/...`), errand, tile and the named others on the tile. Read-only; unknown ids are `walker_gone`.

**Godot.** `ui/character_panel.gd` with Theme variations `CharacterCard/Frame/Badge/Name/Role/Speech/Voice`
(`build_ui_theme.gd`), icons `voice.svg`/`stop.svg`, EN/RU strings. `main.gd`: `walker_at` (ignores HUD controls),
`open_character`/`close_character` (pause and queue hold restored as the game menu does), `focus_walker`, and
`new_walker_entry` shared by walkers and the portrait.

**Limits.** Animals and empty carts have no line, as in the SDL game (the native text has none). The wolf model's coat is
white in its GLB (vertex colour 0.8 grey), not a portrait issue. No facial or talking animation.

## Playable-loop slice 27: triremes, races, the hippodrome and wharf pages, and the walkers without a model — 4 October 2026

**Why.** The trireme wharf could be built but its ships had no model and could not be commanded; the hippodrome's races were invisible (its chariots are missiles, which the snapshot did not send) and its first plate could only be one of four; the two buildings' SDL inspector pages were missing; and nine character types had no model (trireme, enemy boat, the Greek war chariot, bull, silver and orichalc miners, butcher, the disgruntled and elite rioters).

**Models.** From the existing art: `trireme` (the SDL naval remaster's galley, `art/ships/trireme/source.blend`, crew and oars included) and `enemy_boat` (the same hull with a black sail and lacquer and dull bronze trim, recoloured at export; the exporter reads a material's viewport colour into the vertex palette, so both are set). New people-kit entries in `art/characters/people/people10.py`: `greekchariot` (the Greek chariot company, the hoplites' red and bronze, with fight and die clips) and `racechariot0`–`3` (the four racing teams: red, blue, green and white, each with its own horses; the chariot builder's new `racer` gear drops the bow and quiver and leans the driver on the reins). The silver and orichalc miners were exported from their existing people-kit entries. All were merged by `optimize_glb_memory.py` (verified) and baked by `bake_walker_vat.py`. Reused: bull → `animal_ox`, butcher → `walker_hunter`, disgruntled → `walker_peddler`, elite citizen → `walker_scholar` (those two have no fight clips of their own).

**Shared rules.** `engine/ebuildinginfotext.{h,cpp}` (new, in both builds) words the SDL hippodrome page (racing, open, the length and its verdict, the takings, the horses it has and needs) and the trireme wharf page (the palace it needs, wood and armour in store, no road) and the wharf's switch; the SDL info widgets now call it. `eRacingHorse::team()` gives the team of a race chariot. The SDL executable was rebuilt and signed.

**Core.** The snapshot sends the race chariots with the walkers (`walker_racechariot<team>`, found on the city's hippodrome plates' tiles, so a city without one pays nothing; in the walkers' tile space) and marks the player's triremes that may be given orders (`selectable`). `trireme_move <x> <y> <id>...` sends them as the SDL right click does (`eTrireme::sPlace`). The inspection of any hippodrome plate carries `notes` (the SDL page) and `hippodrome` (closed, length, racing, horses, needed); the wharf's carries `notes` and `switch`, and `building_switch <x> <y> <token> <0|1>` shuts it down or sets it working. The hippodrome tool's turn runs 0–7, so all eight plates can start a track (the SDL view cycles them over time); every other building still turns four ways. Validators only: `test_trireme <x> <y>` (stocks the wharf; the engine's build time and stages are 1 while the city steps, then restored) and `test_race` (horses for the closed hippodrome, then `spawnHorses`).

**Godot.** Triremes and enemy boats sail on the water like the trade ships. `scripts/trireme_orders.gd`: a click by one of the player's triremes selects it (a gold ring), a right click on the water sends it, Escape or a click elsewhere lets it go. The inspector shows the notes and the wharf's switch. T steps through the eight plates with the hippodrome tool. Strings in both languages.

**Checks.** `validate_naval_race.gd` (65 headless, EN and RU): every walker of the city has a model; the nine new models exist; the wharf's page and switch (shut down, working again, stale token and wrong building refused); a launched trireme is selectable and sails toward the water it is sent to; a closed track of four corner plates (7, 1, 3, 5) is inspected with the SDL page in English and Russian, races with four chariots in their teams' colours, and they run the track. `validate_main.gd` adds the windowed wharf and trireme checks. `run_godot_pilot.py --menu-rest-review naval` captures the trireme at its wharf, the race and the other new models.

**Limits.** The engine's race path takes the corners in a tight, nearly square turn about a tile inside each plate's outer edges, while the plate art draws a round ring, so the chariots cross the sand at the corners (the simulation's positions are shown as they are). One trireme at a time is selected (the SDL drag selects several). The disgruntled and elite rioters wear citizens' models without fight clips. Triremes do not row (their oars are still).

## Playable-loop slice 28: leaders and the player's cities on one map — 4 October 2026

**Why.** The SDL game keeps a roster of leaders (each with its own saves, and the name its messages address) and lets the player govern every city of theirs on the map, buy a district no one owns and switch between them by looking at them; the Godot city had one save folder, addressed every message to "Hippodamus" and followed only the board's first city.

**Leaders.** `scripts/leaders.gd`: a leader is a folder under the save root (`user://saves/<leader>`); the chosen one is remembered in `user://settings.cfg` (`profile/leader`); names are refused when empty, too long (24), with a character a folder may not have, starting with a dot, or taken (whatever the case). `SaveFiles.directory()` is the chosen leader's folder; `SaveFiles.list()` lists its saves first, then those from before leaders (left in the root, untouched, marked "From before leaders"). The start menu builds a roster page in code (ui/start_menu.tscn is hand-edited, not regenerated), centred like the load page: the leaders, a name to create one, Delete (after a confirmation; it removes only that leader's folder and saves), Proceed and Back; it opens first while no leader is chosen, and the main page names the leader with Change leader. The leader's name goes to the core (`player_name`), which fills the messages' player name (it was "Hippodamus"); the windowed validation keeps the designated save's own.

**Cities.** The core keeps the city in view (the district under the middle of the view, as the SDL view follows it) and the player's own city the pages follow (`playerCity()`): the header, the Build menu, `city_data`, the army and mythology pages and the tax, wage and priority settings follow it, while a rival or unowned district in view leaves them on the player's last city. `view_tile <x> <y>` reports the middle of the view (answering `cities` with `changed`); `cities` lists every district (owner: player, ally, rival or unowned; price; centre); `buy_city <id>` buys a district no one owns for its price, as the SDL "Buy" does (refused without the drachmas or when it is not for sale). Race chariots are sent for all the player's cities. Godot (`ui/city_switch.gd`, attached at runtime so the HUD scene is unchanged): the middle of the view is reported every 0.4 s when it moves to another tile; a district no one owns shows its price and a Buy button; with two or more cities of the player's a menu beside the city's name takes the camera to each; the Build menu refreshes when the governed city changes. Of the 27 adventures only The Sands of Betrayal has more than one district (the player's Elyria, the unowned Isle of Calliste for 5000 drachmas, the rival Theron).

**Checks.** `validate_leaders_cities.gd` (52 headless): the leader rules (every refused kind, Latin and Cyrillic names, taken names whatever the case), the folders, the save lists with the older saves, deletion touching nothing else, a forgotten leader; the real start-menu scene opening on the roster, creating and choosing Solon, refusing a second, naming him on the main page; and in English and Russian The Sands of Betrayal's three districts, looking at the city for sale (in view, pages unchanged), buying it (refused without the drachmas, then for exactly its price), refusing what is not for sale, governing it (header, Build menu, a road built), looking back and at the rival, a tile off the map refused, the leader's name taken, and looking around leaving the test city's replay digest unchanged (a new adventure is generated afresh at each opening, so it cannot be compared with itself). `run_godot_pilot.py --start-review leaders` captures the roster and main page in a scratch profile (never the player's own), then opens The Sands of Betrayal, captures the offer, buys Calliste through the button, opens the cities menu and goes back to Elyria.

**Limits.** Leaders are not renamed (as in the SDL roster); campaign progress lives in the saves as before. Allied districts would be in view like rival ones (no adventure has one). The city menu takes the camera to a city; the SDL view has no menu (the player pans).

## Greek portrait faces — 4 October 2026

Men in the character window now have Greek faces with classical curly hair and beards, from portrait models
(`tools/godot_portrait_faces.py`, `godot_portrait_export.py`, `export_portraits.py`) shown only by `ui/character_panel.gd`,
which opens on head and shoulders. Crowd models, simulation and the exporter file are unchanged. See the character art
contract for scope and limits.

## Playable-loop slice 29: the requests list, choosing several units, the view on an attack, rowing, rioters and building workers — 4 October 2026

**Requests.** The City window's summary ends with the SDL overview's requests (its heading is the game's own, `requests_title`): each request of a world city with a Send button per city of the player's that has the goods (`world_fulfil`), each god's quest with the hero's state and a Send button once he has arrived (`world_quest`), and how many cities ask for troops; worded as on the world map.

**Several units.** With the selection tool a drag draws a box (`scripts/unit_selection.gd`); on release every company banner and orderable trireme of the player's inside it is chosen, each with its ring (`army_view.select_group`, `trireme_orders.select_many`). A right click sends them all: the companies with the new `banners_move <x> <y> <id>...` (the engine's `eSoldierBanner::sPlace`, so they stand spaced around the tile as the SDL view places a selection; companies abroad or in another district stay) and the triremes with `trireme_move` (which already took several). Escape or a plain click lets them go; a press that does not move ten pixels stays an ordinary click.

**The view on an attack.** When the player's god attacks a city on the map, or the player's army invades one (`playerGodAttack`, `playerInvasion`), the next snapshot carries `view_tile` once and the camera goes there, as the SDL view's `viewTile` does. A god that has not landed yet is stood in for by the middle of the city it was sent against. The event comes during the command that sends the god, so the answer to the next command may carry it.

**Animation.** The trireme and the enemy boat row: the export samples the naval script's oar stroke (each `Oar pivot` turned by its side over 24 phases; the crew and hull hold still, their rig is not in the saved file), at the ships' full static budget (35,000 vertices; the walker budget of 12,000 halved the crew). The rioters have their own models with fight and die clips: `disgruntled` (a brown chiton, a club) and `elitecitizen` (purple and gold, a sword) in `art/characters/people/people10.py`. The clothing step colours every person from `art/characters/roman/wardrobe.py`'s table by name; the Greek charioteer, the four racing teams and the two rioters were missing from it (all wore the default cream and red), so they were added and those seven re-exported. Twelve buildings whose art already animates their workers were added to the building-activity rollout (`tools/export_building_activity.py`, `building_activity_assets.json`, now 47): armory, chariot factory, college, corral, dairy, drama school, mint, podium, theatre, stadium, horse ranch and urchin quay.

**Checks.** `validate_requests_units.gd` (17 headless, EN and RU): the requests heading in the game's words, a request listed with the city that can send it and fulfilled, three companies sent together to their own places around a tile, malformed and unknown groups refused. `validate_attack.gd` (53) now checks the view sent once to the attacked city. `validate_building_activity.gd` passes 219 checks for 47 buildings; `validate_characters.gd` (208) counts 102 human walkers; assets 423, poses, naval and leaders validators pass. `validate_main.gd` adds the summary's request row and its Send button, and a box drawn around banners on screen choosing them all and a right click's order moving them. `run_godot_pilot.py --menu-rest-review anim` captures the rowing trireme, the rioters and the new working buildings.

**Limits.** The rowers' bodies do not move with the oars. Drag selection picks banners and triremes (as the SDL view), not other walkers. The view follows the player's own attacks; an attack on the player's city is announced as before.

## Character window portraits as images — 4 October 2026

At the user's choice the window shows pre-rendered portrait images instead of loading 3D portrait models: the portrait
folder went from 443 MB of models to one 0.3 MB image (the curator); render sources live in git-ignored `build-portraits/`.
The rejected curled portraits were removed. See the character art contract.

## Playable-loop slice 30: the SDL remaster's City History, Trade Summary, City Advisor, walker routes and house card — 4 October 2026

These are the SDL remaster's own additions (not in the 2001 game). The engine already kept their data in every save; Godot now
shows and edits it, worded by the same engine code as the SDL windows.

**Shared engine code.** The advisor's ranking moved out of the SDL widget into `engine/ecityadvisor` (`eCityAdvisor::collect`).
The trade summary's lines are `engine/etradesummary` (`eTradeSummary::lines`: text, tone, indent, section and partner-card marks).
The house card's content is `buildings/ehousecard` (`eHouseCards::card`, over `buildings/ehouseneeds`). The SDL advisor window,
trade summary and hover card now draw from these, so the two views cannot disagree. The City History record is
`engine/ecityhistory` as before.

**Core commands.** `city_history` (six series with labels, each month's name and values, the range and empty-chart words),
`city_advisor` (up to seven problems, most serious first, each with its places), `trade_summary` (the lines) and
`house_card <x> <y>` are read-only queries for the player's city in view. Route editing follows the SDL route editor:
`route_begin <x> <y> <token>` on an inspected walker building of the player's (a vendor or agora space edits its agora, as the
SDL left click does), `route_toggle <x> <y>` adds a road tile as the next guide or removes a guide (`route_needs_road` off a
road), `route_clear`, `route_restore` (the guides it had when editing began), `route_both` and `route_end`; `route` reads the
guides, both-ways flag and the walk the engine found (`path`, `reverse`; the path finder runs on the board's threads, so the
walk appears a moment after a change). The inspection carries `route: {guides, editing}`.

**Godot.** The City window (F7) gains Advisor, History and Trade pages after Mythology, opened also from buttons on the summary
(City advisor, City history) and storage pages (Trade summary), as the SDL panel's buttons. The advisor shows a card per
problem with "Go there n/m", which steps through its places (remembered per problem while the game runs) and closes the
window. The history page (`ui/history_chart.gd`) has a button per series and per range (2 years, 10 years, all), round
gridlines, years along the bottom, the value under the pointer and a line with the latest value and its change in a year;
the window's refresh keeps the chart. The trade page draws the summary's partner cards and goods lines in their tones.
A walker building's inspector has a "Walker route" button (`scripts/route_editor.gd`): a bar replaces the inspector with
Clear, Restore, the one-way/both-ways button (named for the current way, as the SDL button) and Close; left clicks on roads
add numbered posts, the walk is drawn in gold and the way back in pale blue; Escape or a right click closes it, and choosing a
tool ends it. Resting the pointer on an inhabited house for 0.35 s with no tool shows the house card (`ui/house_card.gd`):
level name and pips, residents, the next level (or the decline warning in red) and each need ticked or crossed, missing
first, with the venue kinds that do not reach it.

**Checks.** `validate_city_extras.gd` (52 headless, EN and RU): six series and three ranges, every month named and in order,
the advisor ranked with its places, the trade summary's two sections and tones, a house card and none on an empty tile, a
stale inspector refused, guides set on roads in order and refused off them, the walk found, both ways, removal, restore and
end. `validate_main.gd` adds the window's three pages and their buttons, the chart's choices kept across a refresh, "Go there"
moving the view, the inspector's route button, a click on a road setting a guide and the walk drawn, both ways, restore and
Escape, and the house card filled for a house and hidden for a tool (asked for directly: a windowed run cannot hold the real
pointer still). `--menu-rest-review extras` captures the three pages, a route through two guides and the house card under a
rested pointer (reviews move the pointer with the viewport's `warp_mouse`, which takes viewport coordinates; `Input.warp_mouse`
takes window coordinates and lands off target in a scaled window).

**Fixes on the way.** The English text for the SDL route editor's one-way button read "One directions" (`text/language.txt`).
The start menu skipped itself for most review flags but not `--menu-rest-review`, `--attack-review` or `--rite-review`, so those
reviews waited at the menu; they are now in its automation list.

**Limits.** Seasons and weather and the map bookmarks were not part of this slice (weather would collide with the
terrain work; F1–F4 are taken). The route editor does not show the SDL editor's dashed preview of the legs beyond the
walkers' reach; a guide past it has its post but no walk. The house card names goods without their icons.

## Playable-loop slice 31: fires, ruins, earthquake chasms, lava and marsh — 4 October 2026

**Fires.** The snapshot carries `fires`: `[x, y, w, h, altitude, ruins]` for every burning building, sent whole when the list
changes and in every full snapshot (like the banners). `scripts/building_fires.gd` lights each one: tongues of fire spread
over the footprint at roof height (the model's height from its manifest), one or two smoke columns that face the camera and
lean with the wind (`shaders/building_fire.gdshader`, `shaders/fire_smoke.gdshader`), and for the first six a flickering
light. Smouldering ruins burn low with thin smoke. The fire itself, its spread, the collapse and the ruins are the engine's.

**Ruins.** A building brought down by fire, collapse or an earthquake leaves `eRuins` on each of its buildable tiles; they were
drawn with the "unconverted" placeholder. They are now `ruins_<seed % 8>`, the SDL remaster's eight Roman ruins exported from
the same Blender source (`art/lots/build_sprites.py --part ruins`, recipes in `tools/godot_asset_sources.py`): scorched ground,
a rubble mound of brick, roof tiles and stone, charred beams, and in some a stub of wall, a broken column or an amphora
(822–950 vertices each).

**Ground.** The ground's pattern texture (`terrain_presentation.gd`) gains three channels from the native terrain bits: G for an
earthquake's chasm (2048), B for lava (32768), A for marsh (16384). `shaders/ground.gdshader` draws a chasm as a near-black
rift sunk below the ground inside a rim of pale broken earth with fissures, lava as a dark crust with thin glowing seams and
drifting molten pools (emissive, pulsing), and marsh as dark green tussocks with broad pools of still water. Edges are broken
by noise so the tile grid does not show. Picking and collision are unchanged (the chasm's sink is in the shader only).

**Core commands (validators only).** `test_fire <x> <y>` and `test_collapse <x> <y>` (eBuilding::setOnFire / collapse),
`test_earthquake <x> <y> <size>` (eGameBoard::earthquake: it spreads as the city runs), `test_terrain <quake|lava|marsh> <x> <y>
<radius>`. They answer briefly rather than with a snapshot, so the change reaches the view in its next snapshot.

**Checks.** `validate_disasters.gd` (22 headless): the pattern channels, the eight ruins models, a 2x2 house listed burning with
its footprint and not listed again unchanged, its collapse into ruins models (some smouldering), an earthquake opening chasm
tiles that cannot be built on, chasm, lava and marsh tiles carrying their bits, and bad requests refused. `validate_main.gd` adds
flames and smoke on a burning house, the ruins models after its collapse and lava reaching the ground's pattern.
`validate_geometry.gd` passes again: the 68 assets without a recorded baseline (the ruins and those of slices 25–29) were added
to `data/geometry_baseline.json` without changing the existing entries. `--menu-rest-review disasters` captures burning houses
(two distances), the ruins smouldering and cold, a chasm with an earthquake's cracks beside it, lava and marsh.

**Limits.** No fire sound in the Godot city yet, and burning buildings are not darkened. Marsh has no reeds. The earthquake's
falling rocks, the lava flow's missiles and the tidal wave's surge are not drawn (the water and the tiles they leave are). A
review's direct `pause` query answers with a snapshot and so swallows the terrain changes it carries; reviews queue their pauses.

## Monster card, heroes' halls offered mid-game, wheel over panels — 4 October 2026

**Monster card.** Monsters left the notice at the top of the city (`ui/invasion_banner.gd` is for invaders again). While a monster
is at large a red button with the count stands in the right-hand rail under the journal (`ui/monster_card.gd`, icon
`ui/icons/monster.svg`, pulsing three times when one arrives); it opens a card under the rail with, for each monster, the engine's
own words for its coming (`eMonsterMessages::fInCity`, as the SDL view shows them), the hero who alone can slay it and where the
city stands with him (hall to build, built, summoned, in the city), with "Go to the monster" and "Build the hero's hall" (opens
the Build menu on Heroes' halls with the hall chosen) or "Show the hero's hall" (inspects it). Escape and the journal close it.
The core's new `monster_info` query answers it (name, tile, title, text, hero, `hall_tool`, `hall_allowed`, `hall_built`,
`hall_at`, `hero_stage`); the card refreshes every second while open.

**Halls offered mid-game.** The engine makes the slayer's hall buildable when a monster comes (`eGameBoard::allowHero`, called by
the monster events and gods' quests), but the Build menu was filled only when the city opened, so the hall appeared only after a
reload. The core now sets the board's buttons-visibility hook (`setButtonsVisUpdater`, which the engine calls whenever what may be
built changes: allowed, built, destroyed) to count a `buildable_revision` that every snapshot carries; `main.gd` asks `buildable`
again when it moves (`hud.set_catalog` ignores an unchanged catalog, so hover and scroll are kept).

**Wheel over panels.** Godot passes wheel and trackpad scroll/pinch events on from a panel whose list cannot scroll further
(`mouse_force_pass_scroll_events`), so scrolling the Build tray at either end of its row also zoomed the map. `orbit_camera.gd`
ignores wheel and gesture events while the pointer is over any HUD control (`gui_get_hovered_control()`).

**Limits.** The card's monster words follow the language the city was opened in, as every core message does; the interface around
them follows the EN/RU button. Six new strings in each language.
