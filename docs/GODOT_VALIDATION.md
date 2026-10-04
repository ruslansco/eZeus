# Godot embedding validation — 4 October 2026

## Storage building goods display validation — 4 October 2026

**Implemented.** Warehouses, trade posts, and granaries now render their stored items
and food in 3D directly on top of their yards and bins matching the native simulation.
- `EZeusSimulation::snapshot()` inspects `eStorageBuilding` instances and serializes non-empty
  bays only when goods inventory changes, preserving sub-millisecond simulation tick latency.
- 20 goods models (`good_<name>.glb`) and 8 granary food models (`granary_food_<name>.glb`)
  exported with vertex-palette compatible PBR materials and batched into MultiMesh chunks.
- Granary food wedges are positioned at `GRANARY_DRUM_CENTER` and rotated by `bay_idx * PI / 4.0`
  matching the 8 radial dividers in the granary drum.

**Scoped validation evidence:**

| Review | Result | Evidence in `godot/captures/` |
| --- | --- | --- |
| Storage goods / granary validation | 204 checks PASS | `validate_storage_goods.gd` |
| Full asset suite validation | 421 models PASS | `assets-engine.log` |
| Embedded simulation regression | PASS | `embedded-engine.log` |
| Visual frame captures | 3 renders PASS | `storage-goods-warehouses.png`, `storage-goods-granary.png`, `storage-goods-tradepost.png` |

## Unified complete resource bar and 3D icon art — 3 October 2026

**Implemented.** The city name and treasury/population/jobs share the top resource
surface. All 23 individual native resource bits through silver are displayed,
plus the existing aggregate food total; drachmas remain the treasury. Zero stocks
are never filtered out. Balanced rows wrap at small/enlarged layouts without
scrolling, preserving exact counts and full translated tooltips. The native
snapshot observes cached stored stocks only, without tile scans, refresh, extra
polling, RNG or rule/timing changes. The extension helper rebuilt/finalized/signed
the library. Native mineral deposits are not counted as stored inventory.

Twenty-four original procedural 3D resource models are saved as reusable scenes
and rendered into transparent 128-pixel textures. The live HUD uses only static
icons, adding no thumbnail viewport, light, city geometry or simulation entity.
The resource art manifest records geometry and provenance; the largest offline
mesh is wheat at 7,344 triangles, within the 8,192 limit. The native building/
walker model manifest is unchanged by this UI art. See `GODOT_RESOURCE_ART.md`.

**Final scoped checks, designated save with scratch preferences:**

| Review | Result | Evidence in `godot/captures/` |
| --- | --- | --- |
| Resource completeness/art/bounds/native shortcuts | 22 each EN/RU | `resources-review-{en,ru}-console.log` |
| Retained notifications/map/HUD | 115 each plus nine retained log assertions | `resources-notifications-{en,ru}-console.log` |
| Retained status/context/accessibility | 115 each EN/RU | `resources-status-{en,ru}-console.log` |
| Escape/menu/native pause preservation | 53 each EN/RU | `resources-escape-{en,ru}-console.log` |
| Embedded service regression | 101 | `resources-embedded-console.log` |
| Translation table | 7 | `resources-translations-console.log` |

The resource review checks the complete native type set, enabled zero stocks,
independent giftable world stocks/food sum, original model/texture contracts,
all-item visibility at 1920×1080, 1600×1000 and 1280×720 with independent normal/
enlarged UI/text sizes, actual overlay clicks, long exact values/title tooltips
and unchanged native state. The world-gift query excludes non-giftable expansion
materials/horses/chariots/silver; a missing gift entry is not a zero stock. Earlier
eight-goods tests were updated to preserve that distinction rather than fabricate
counts. The unused old Wood translation row was removed in favour of the shared
Timber resource label; all translation gates pass.

Actual game captures: `resources-{1920,1600,1280}-{en,ru}.png`, their `-detail-`
header crops, and `resources-1280-large-{en,ru}.png`. The original art contact sheet
is `resources-art-sheet.png`. The regular game remains open; relaunch loads the
new extension/header. Player/workspace preference and designated-save fingerprints
remain unchanged.

Initial review-only type/budget assertions were corrected before passing results.
An initial English menu fixture lost its active menu during interaction; subsequent
owned reviews shield hardware input while tagged injected events take the real
GUI path. A Russian resource preview hit the previously observed repeated
null-material renderer stall; its owned process was stopped and small samples
retained in `resources-stalled-*`. The resource wrapper now terminates only its
own child promptly on repeated errors. Retained Escape checks completed their
functional assertions but crashed during renderer finalization in both languages;
those traces remain in `resources-escape-*-teardown-crash.log`. Explicitly freeing
the owned city and allowing render frames before quitting produces clean reruns.
These repairs concern review isolation/cleanup, not a claimed production renderer
stability fix. Whole-game parity, wider campaign layouts, minimum-Mac performance,
full gamepad coverage and user art acceptance remain pending.


## Escape menu, upper-right stats and circular chart — 3 October 2026

**Implemented.** Removed the city language/gear panel and its popup/signals;
treasury/population/jobs align upper right. Escape closes city windows/disclosures,
construction drags/tools and overlays before opening a centred, themed menu.
City actions, settings, city views and interface language are grouped there.
Settings and save/load/leave confirmations return to the menu; nested settings
return one level at a time. Opening holds the native clock/command queue;
closing restores the previous pause/hold state. Native choices are never answered
by folding or menu navigation. Escape during a display preview restores the
previous exact presentation and closes that page. The minimap now covers its
circular frame and clips chart corners, replacing the old inscribed square while
retaining exact native coordinates, map preference and Home overview.

**Final scoped evidence, Metal/Forward Mobile, designated city and temporary preferences:**

| Review | Result | Evidence in `godot/captures/` |
| --- | --- | --- |
| Escape menu and real input | 53 each, EN/RU | `escape-review-{en,ru}-console.log` |
| HUD, notifications and chart transformations | 115 each, plus nine retained message/log assertions each | `escape-map-{en,ru}-console.log` |
| Status/accessibility/HUD/context | 115 each, EN/RU | `escape-status-{en,ru}-console.log` |
| Display Apply/Keep/Revert/fullscreen and Escape closure | 48 each, EN/RU | `escape-display-{en,ru}-console.log` |
| Enlarged shared start menu and nested settings | 17 each, EN/RU | `escape-start-menu-{en,ru}-console.log` |
| Native incremental map/navigation | 8 each, EN/RU | `escape-native-map-{en,ru}-console.log` |
| Translation table | 7 | `escape-translations-console.log` |

The Escape review exercises journal, objectives, inspector, tray/tool, road-drag,
army, overlay and folded-decision priority with actual Escape input; verifies
native pause/queue preservation for running/already paused cities, every modal
page return path, nested display-preview cancellation, live language selection
and keyboard focus scrolling at three resolutions with independent normal/
enlarged sizing. Circular-map checks retain all 25,992 inverse coordinate round
trips within 0.0001 tile while verifying cover/cropping and corner pass-through.
Actual captures: `escape-city-map-{en,ru}.png`, `escape-map-detail-{en,ru}.png`,
`escape-menu-{en,ru}.png` and `escape-menu-large-{en,ru}.png`.

An initial review had a test-only time-type error, repaired before final checks.
An English native-map startup crashed in Godot's threaded resource/material
loader; its unchanged isolated rerun passed eight. The trace is retained in
`escape-native-map-en-startup-crash.log`. A repeated Russian Escape run stalled
with null-render-material messages before its checks; the owned preview was stopped,
its repeated generated log was cleared and small samples retained as
`escape-ru-stalled-*`. The subsequent isolated run completed cleanly. These failed
attempts are not counted as passing evidence. Earlier threaded-render startup
failures remain unresolved; no renderer stability or whole-game parity claim is
made by these UI checks. Wider campaign layouts, full gamepad coverage, sustained
minimum-Mac performance and user visual acceptance remain pending. Save and actual
player/workspace preference fingerprints stayed unchanged; the regular game was
left open. No C++ simulation change was required for this pass.


## Aegean interface remaster — 3 October 2026

**Implemented.** Separate floating time/resource groups, a content-sized bronze
category dock, navy/ivory shared surfaces, quiet routine journal delivery, one
visible urgent alert with a queue, exact repeated-warning groups, persistent
native decisions, preserved journal reading/inspector drafts, native status
explanations, warmer cached thumbnails and a preview/Apply/Cancel motion option.
The service adds read-only event `kind` metadata; the extension build/finalization
helper completed. No simulation, native coordinates, save format or SDL rendering
change was made. Theme generation preserves AtlasTitle/AtlasHint and independent
text scaling; all new wording is in the EN/RU CSV.

**Final focused evidence (Metal/Forward Mobile).**

| Review | Result | Evidence in `godot/captures/` |
| --- | --- | --- |
| Notifications/journal/layout | 84 each, EN/RU; nine retained message/log assertions also pass | `aegean-final-notifications-{en,ru}-console.log` |
| Status, accessibility, HUD/context | 115 each, EN/RU | `aegean-final-status-{en,ru}-console.log` |
| Native minimap/navigation/road/undo | 8 each, EN/RU | `aegean-final-native-map-{en,ru}-console.log` |
| Enlarged shared start menu | 17 each, EN/RU | `aegean-final-menu-{en,ru}-console.log` |
| Display Apply/Keep/Revert/fullscreen | 48 each, EN/RU | `aegean-final-display-{en,ru}-console.log` |
| Translation table | 7 | `aegean-text.log` |
| Embedded service | 101 | `aegean-embedded.log` |
| Native event wording | 45, including EN/RU | `aegean-events.log` |

Notifications exercise missing-kind fallback, choices overriding routine kind,
record-before-acknowledge, deduplication, full-queue retry, reserved player-command
capacity, native kind emission, exact occurrence text, reading/control identity,
compact journal bounds, every category, Escape restoring a dirty storage draft,
thumbnail `UPDATE_DISABLED` and restoring motion on Cancel. Retained layout tests
cover three window sizes and independent interface/text scaling combinations.
Display reviews preserve native state and confirm the existing 15-second preview
policy. Final focused wrappers verify the designated save, workspace settings and
actual per-user preferences remain byte-identical for each run.

**Integration limits.** The first broad English run passed 587/590, failing hover
preview, the previously documented battle-dependent fallen-soldier assertion and
the existing aid-regard assertion. Identical delayed catalog refreshes were
rebuilding hovered cards; they now reuse the tray. The subsequent broad Russian
run passes 589/590, including hover and soldier checks, retaining only `asking for
aid costs regard as the engine says (80 to 70)`. The aid failure is recorded in
earlier world/gameplay entries below. These broad runs exit with failure and
renderer/resource cleanup diagnostics; they do not establish a clean full-game
pass. Logs are `aegean-pilot-{en,ru}-console.log`.

An initial native-map review overlapped a broad run and its hash guard reported
that actual per-user preferences changed (`aegean-native-map-en-console.log`).
The source of that change was not established and real preferences were not
overwritten to force a match. Later isolated EN/RU map and other focused reviews
pass their guards. Do not run visible review processes concurrently. Capture
helpers bring only their owned review window forward before waiting for Metal's
next rendered frame; a background window can suspend that wait.

**Visual evidence.** Actual city captures are
`map-notices-aegean-{idle,journal,build}-{en,ru}.png`; retained captures include
maximum-scale 720p journal/tray, decisions, minimap and inspector states.
Before captures are kept under `aegean-before/`. Review uses only
`Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`, disposable preferences and in-memory
test events. Screenshots were inspected for composition and legibility; user
visual acceptance remains separate. Matched before/after frame-time/memory
medians, sustained minimum-Mac performance, every specialized panel at all scales,
broader campaign coverage and full keyboard/gamepad navigation remain pending.

## Display settings and window dimensions — 3 October 2026

The new Display settings dialog selects windowed/fullscreen mode, monitor,
client-area dimensions, VSync and an optional frame cap. The start-menu gear is
now a Game settings hub linking Display, Interface options and Controls; direct
city actions remain. Confirmation is a timed preview, with explicit Keep and
restoration on Revert/Escape/timeout. See `GODOT_INTERFACE.md`.

- Focused **Metal/Forward Mobile** reviews pass **48 each in EN/RU**:
  `display-settings-{en,ru}-engine.log`. Real Apply/Keep/Revert buttons, Cancel,
  Escape, a real **15-second** expiry while the core is paused, and removing a
  preview dialog preserve or restore the exact window position/size/mode/border,
  VSync and FPS cap without prematurely writing preferences.
- On this Mac, three reported displays are **1920×1080**. The review moves its
  window from display 1 to display 2 and restores it. Fullscreen reaches
  **1920×1080**; confirmed fullscreen retains **1280×720** for return by the
  existing Alt+Enter binding. Standard choices are filtered to the usable area;
  Fit to display is **1904×1002** on the reviewed screen. Disconnected indices
  fall back. This is not heterogeneous/high-DPI monitor or video-mode evidence.
- Confirmed preferences reload through the actual startup helper. Language,
  sound, interface sizes, keys and autosave options survive display commits.
  Native map picking passes after window and fullscreen resize. Dialogs fit at
  100/100 and 125/130 UI/text sizes in a 1280×720 window. The paused native state
  digest, treasury, time, buildings/walkers, queued commands and camera pose stay
  unchanged. Snapshot sequence counters are observations, not compared as state.
- Headless preference/type/migration/translation checks pass **23**:
  `display-settings-headless-en-engine.log`; retained controls/game settings pass
  **59**: `display-controls.log` (its deliberate duplicate-key fixture warns as
  before). Visible runs finish without script/runtime errors; existing missing
  campaign/voice resource messages remain.
- Retained HUD/status/context checks pass **115 each in EN/RU**:
  `status-ui-checks-{en,ru}-engine.log`. Storage drafts/tokens, native picking,
  independent interface/text sizes and bounded panels remain covered. Enlarged
  start-menu checks pass **17 each**: `status-ui-menu-{en,ru}-engine.log`, including
  the gear's Game settings hub and its Display/Interface routes.
- Actual rendered captures: `display-settings-{options,preview,fullscreen,
  windowed,large}-{en,ru}.png`. Each reviewer uses a disposable ConfigFile for
  its entire lifetime, checking the designated city, both workspace settings
  and actual player preferences byte-for-byte. No native binary or art asset
  changed; the user-owned running game remains open.

Fullscreen uses the desktop resolution without switching hardware modes. The
FPS option is a cap, not measured performance. Minimum-Mac profiling, other OSs,
heterogeneous/high-DPI screens, graphics quality/render scaling and user visual
acceptance remain separate gates. Earlier entries describe their earlier UI.

## Fixed map and slim top status strip — 3 October 2026

The minimap's title/header row is removed. Its small dash fold button overlays
the upper-right corner, leaving a 192×192 logical-pixel card around the existing
184×184 native chart. The map stays fixed at the bottom right when either city
ground or a building is inspected; cards scroll above it, retaining their drafts
and native target tokens. The pause/speed/date/treasury/population strip now sits
at the top, 32 logical pixels at default sizes (formerly 46 at the bottom).
Utilities, objectives, history and notices clear the header; the dock no longer
reserves the former footer space. See `GODOT_INTERFACE.md`.

- Final focused Metal/Mobile runs pass **64 each in EN/RU**, plus **nine**
  retained message/log assertions each. Evidence:
  `map-notices-checks-{en,ru}-engine.log`. Real viewport pause clicks and speed
  dropdown keyboard selection forward the original native commands; the review
  removes those queued commands while holding the core. Home, minimize/reopen,
  map picking and per-user visibility persistence remain covered.
- At requested **1440×900, 1280×720 and 1920×1080**, with UI/text **100/100 and
  125/130**, opening native ground and warehouse inspectors leaves the map's
  entire rectangle unchanged. Top-strip contents stay inside it; inspectors,
  notices, history and construction still clear each other and the dock. Native
  money, time, buildings and walkers remain unchanged during these UI checks.
- The broader **115** status/accessibility/HUD/context assertions pass each in
  EN/RU. Evidence: `status-ui-checks-{en,ru}-engine.log`. They retain storage
  drafts/tokens, native picking, Apply/Cancel preference semantics, related
  overlays and all four independent UI/text combinations at three resolutions.
  Cursor-badge assertions now follow the actual top strip/bottom dock instead
  of the old fixed footer margins. Status reviews redirect their full preference
  lifecycle to disposable ConfigFiles, matching the minimap review's protection.
- Retained native-map checks pass **eight each in EN/RU**, including RAM-only
  road construction/undo and coordinate round trips:
  `map-notices-native-map-{en,ru}-engine.log`. Translation passes **seven**:
  `top-status-text.log`. Shared Theme review confirms its existing styles only
  change for MapCard/StatusStrip; atlas typography is preserved in the generator.
- Fresh EN/RU screenshots show the compact chart, top strip, native ground
  card and scrolling warehouse card at default and maximum sizes. Evidence:
  `map-notices-{map-reading,map-ground,map-ground-720,map-inspector-720}-{en,ru}.png`
  and the actual chart crops `map-notices-map-detail-{en,ru}.png`. Both capture
  reviews finish without runtime errors and preserve the save and preferences.

This slice changes presentation/layout only; no C++ rules, timing or 3D assets
changed. Wider campaign panels, keyboard/gamepad navigation, minimum-Mac
performance and user visual acceptance remain separate gates. Earlier sections
record the prior layouts and their scoped evidence.

## Animated city-to-world flight — 3 October 2026

Outward wheel/pinch crossing the city limit, F2 and the world action now share a
live 1.55-second ascent into the regional atlas. Escape/Back descends in 1.20
seconds to the exact saved city camera. Cloud wisps and staggered control fades
bridge the two independently scaled 3D scenes. Native time, queued city commands
and input are held until return; no simulation coordinates/rules changed. The
atlas is prepared during paused loading and hidden rendering remains disabled.
See `GODOT_WORLD_ATLAS.md` for the authority/lifetime contracts.

- Focused **Metal/Forward Mobile** flight reviews pass **37 checks each in
  EN (1600×1000) and RU (1280×800)**. Actual viewport wheel/pinch/F2/Escape/Back
  exercises ascent, moving clouds, repeated-scroll/key suppression, interrupted
  ascent, exact target/zoom/yaw/pitch restoration, modal blocking, M mute,
  queued-command isolation and paused/running return. Complete native tile,
  building, walker, treasury, time, event and world observations remain equal
  through the paused flight. Logs/reports: `world-atlas-{en,ru}-flight.{log,json}`;
  real-rendered frames: `world-flight-{en,ru}-{out,in}-*.png`, arrival and return.
- Retained native-world UI checks pass **16 plus four integration checks each
  in EN/RU**: actual native requests/regard, a 500-drachma gift, fulfilment,
  F2/Escape and pause/resume, covered-city rendering/camera suspension, Space
  suppression and visibility restoration. The validator waits for flight
  completion rather than assuming the old instant screen change. Evidence:
  `world-atlas-{en,ru}-native-ui.{log,json}`.
- The existing embedded-core, world-economic, translation and surroundings
  contracts pass again. Evidence: `world-flight-embedded.log` (**101**),
  `world-flight-core-world.log` (**32**), `world-flight-text.log` (**seven**) and
  `surroundings-engine.log` (**16**). Scenery still has 113,115 submitted vertices,
  393 background trees in 33 batches and 976 exact rim corners; the ordinary
  city cap stays 239.4. The scenery reviewer isolates that cap; actual enabled
  city-to-world input is tested separately by the flight review.
- `world-flight-preview.gif` is a sampled export of the actual EN ascent frames
  listed in the review report, ending at the live native atlas. It is a visual
  preview, not a measured frame-rate recording.
- Visible wrappers preserve the designated save, workspace settings and actual
  Godot user preferences byte-for-byte, using scratch preferences. The missing
  city HUD minimize icon exposed by the first run was supplied and imported;
  final visible runs finish without runtime errors. Headless runs retain the
  sandbox system-certificate warning; existing missing voice/campaign resources
  are unchanged. No native binary or art model was rebuilt.

This is scoped animation/state evidence on the development Mac. Broader live
campaigns, sustained minimum-Mac profiling (both views render briefly during
travel), reduced-motion options and revised user visual acceptance remain
pending. The flight is a live camera blend, not surveyed geographic continuity.

## Minimap marker refinement — 3 October 2026

At the user's request, both compass elements are removed: the header's compass
overview button and the chart's north disk. The filled/outlined camera footprint
and circle/stem marker are replaced with a small pale heading chevron and a soft
cyan halo, 26 logical pixels across at every zoom. Native map transforms,
incremental texture updates, click/drag navigation and Home overview remain.
The ground-footprint observation is retained but no longer drawn.

- Repeated focused Metal/Mobile reviews pass **50 each in EN/RU**, including
  **nine** retained event/log assertions each. The overview check now sends a
  real Home key through the viewport. Evidence:
  `map-notices-checks-{en,ru}-engine.log`.
- Retained native-map checks pass **eight each in EN/RU**; they cover native
  colours, RAM-only road construction/undo, coordinate round trips, ground
  navigation and the underlying footprint geometry. Evidence:
  `map-notices-native-map-{en,ru}-engine.log`. Translation passes **seven**:
  `map-marker-text.log`.
- Fresh visible EN/RU captures show the clean chart, heading marker and unchanged
  inspector/news spacing at normal and maximum interface/text sizes. The actual
  panel crops are `map-notices-map-detail-{en,ru}.png`; full-frame evidence uses
  `map-notices-{map-reading,map-inspector-720}-{en,ru}.png`. Both review runs
  finish without runtime errors and preserve the designated save and preferences.

No C++ simulation, terrain, assets or native camera coordinates changed. This is
scoped minimap/interface evidence; the earlier 115-check status suite was not
repeated for this visual refinement. User visual acceptance remains pending.

## Compact minimap, news chips and history — 2 October 2026

The live chart now folds into a bottom-right City map pill with a remembered
preference, a camera heading marker and non-destructive positioning
alongside inspection. News uses three short animated disclosures; history is a
right drawer; required decisions retain a persistent amber review chip and their
original native choices. See `GODOT_INTERFACE.md` for the contracts.
Reproduce with `python3 tools/review_map_notifications.py --checks --lang en`
(or `ru`); use `--native-map` for the retained map regressions, or neither for captures.

- Focused Metal/Mobile runs pass **50 checks each in EN/RU**, with the **nine**
  existing message/log assertions also passing in each run. Evidence:
  `captures/map-notices-checks-{en,ru}-engine.log`. Real viewport clicks open/fold
  the chart, expand news and forward an explicit
  decision choice with its original event ID/value. Folding sends no answer;
  refresh of the same pending ID preserves reading state. These callback checks
  use synthetic pending events in the real controller; they verify forwarding,
  not every native campaign/military outcome. Home retains the bounded overview.
- Navigation preserves native coordinates and generated ground height; release
  outside ends a map drag. Preference tests use a disposable ConfigFile and
  preserve unrelated language/sound values. Reading, hidden or completely
  clipped chips hold their countdown; visible unread news expires through the
  existing dismissal signal. Incoming news keeps the item being read. The
  established log checks cover deduplication, unread counts, complete history,
  newest-first ordering and translated labels.
- Layout checks use requested **1440×900, 1280×720 and 1920×1080**, at UI/text
  **100/100 and 125/130** in each launch language. Bounds use the actual logical
  viewport. News/map rectangles clear an open warehouse inspector; the chart
  clears the toolbar and the history clears the construction tray. Native
  treasury, clock, buildings and walkers are unchanged by navigation/UI checks.
- The retained incremental minimap suite passes **eight each in EN/RU**:
  native water/road/building colours, RAM-only road construction and undo,
  coordinate round trips, ground-anchored navigation and camera footprint.
  Evidence: `map-notices-native-map-{en,ru}-engine.log`.
- The existing **115** status/accessibility/HUD/context assertions pass in both
  launch languages after the new layout; translation passes **seven**.
  Evidence: `status-ui-checks-{en,ru}-engine.log`, `map-notices-text.log`.
  No C++ simulation or asset export changed in this slice.
- Visible reviews capture folded/open maps, compact/expanded news, a required
  decision fixture, history above construction and a map alongside inspection,
  including maximum UI/text at 1280×720. Files:
  `map-notices-{compact,map-reading,decision-chip,decision-720,history-720,map-inspector-720}-{en,ru}.png`.
  News uses actual engine-written god/monster/city messages raised only in the
  disposable city. Long decision fixtures exercise layout without answering a
  native event. The review wrapper rejects runtime errors/missing markers,
  limits its own process lifetime and verifies designated save, workspace
  settings and actual user preferences remain byte-identical.

An intermediate settings-hash safeguard detected the shared file changing while
an independently launched normal game was running. That session was left alone.
The new review wrapper now redirects its entire preference lifecycle to a
per-process temporary ConfigFile, including restoration after nested preference
tests. Final focused runs check the current shared preferences without writing
or restoring them. This avoids treating another live session's settings as test
scratch data.

This is scoped desktop HUD evidence, not whole-game decision parity or sustained
minimum-Mac performance. Wider campaign/event coverage, complex-panel sizing at
every combination, keyboard/gamepad navigation and visual acceptance remain
pending. Existing missing voice/campaign files are unchanged.

## Building status, service panels and interface sizes — 2 October 2026

Read-only inspection summaries and native service legends/counts are implemented,
along with live, independent UI/text sizing and explicit Apply/Cancel. See
`GODOT_INTERFACE.md` for the observation, Theme, preference and input contracts.

- Final Metal/Mobile runs pass **115 checks each in EN and RU**: **48** new
  status/accessibility checks, the existing **20** HUD checks and **47** contextual
  construction checks. Evidence: `captures/status-ui-final-{en,ru}.log` and
  `status-ui-checks-{en,ru}-engine.log`. Hospital, warehouse and olive-press
  summaries use exact native staffing/maintenance/road observations; production
  keeps the native operational status. Housing shows occupants and actual needs.
  Real viewport clicks open supplies/water views, matching counts and rendered
  water colours, and close back to normal visibility.
- Each new run checks **24** layout combinations: both interface languages,
  requested 1440×900, 1280×720 and 1920×1080 windows, and UI/text pairs
  100/100, 125/100, 100/130 and 125/130. Bounds use the actual HUD viewport;
  macOS may constrain requested physical window sizes. Inspector/overlay panels
  clear the construction tray. Enlarging the UI preserves projected native
  terrain picking and a dirty storage-limit draft with its original target token.
- Preference tests use disposable ConfigFiles. Preview writes nothing; Cancel
  restores previous sizes; Apply saves both keys and preserves unrelated
  language/sound/other fields. Reload restores saved choices and malformed or
  unsupported values fall back to defaults. Camera orbit is blocked while the
  options dialog is open. Native treasury, clock, buildings and walkers are
  identical before/after browsing; no C++ gameplay change was required.
- Enlarged-menu runs pass **15 each in EN/RU** at 1280×720, checking all seven
  buttons at defaults and maximum sizes and the shared options entry. These
  reviews open no native city and use scratch save/preferences directories.
  Evidence: `status-ui-menu-{en,ru}.log` and `status-ui-menu-720-{en,ru}.png`.
- Native overlay observations pass **59**, translated interface text **7** and
  startup/campaign flow **39**: `status-ui-{overlays,text,start}.log`. The startup
  assertion initially accepted only the old WAV fanfare. It now accepts either
  existing supported format; the final diagnostic records
  `Audio/Music/mission_intro.mp3` and `cue:mission_intro`. Audio runtime logic and
  assets were not changed in this slice.
- Final city reviews capture production/housing services at 1600×1000 and
  maximum UI/text sizes with storage/construction/options at 1280×720:
  `status-ui-{production,water,large-720,options-720}-{en,ru}.png`, with
  `status-ui-review-{en,ru}.log`. Actual EN/RU screens and enlarged menus were
  opened for visual inspection. Wider model cards prevent enlarged Russian names
  splitting midword; full long-name/instruction tooltips remain. Maximum-level
  houses show the current level without repeating it as a future level.
- The final focused runs/reviews finish without script/shader errors and protect
  SHA-256 hashes of the designated save, both workspace settings files and the
  real per-user Godot settings. The harness rejects missing completion markers
  and runtime errors as well as nonzero exit codes. Early headless attempts using
  relative log paths hit a Godot logger crash before scene startup; final commands
  use absolute paths. Enlarged status-strip overflow, scroll-hidden service
  shortcuts and a deferred resize targeting a closing options Window were fixed.

Limits: this covers the designated city's ordinary inspection, service and
construction flows plus the start menu. Every complex military/campaign panel at
all sizes, keyboard/gamepad navigation, wider campaign coverage and sustained
minimum-Mac performance remain pending. Earlier whole-game parity failures and
independent-product content/provenance/release gates are not cleared by these
scoped UI results.

## Living regional world atlas — 2 October 2026

The new world backdrop is installed in the real Godot 3D world screen. Greek
coastline and four Poseidon field families preserve native normalized positions;
relief is artistic. See `GODOT_WORLD_ATLAS.md` for scope/source rebuilding.

- Actual Metal/Mobile standalone EN 1600×1000 and RU 1280×800 reviews pass **31
  checks each**: independent live 3D viewport, collision/navigation exclusion,
  every native label/landmark anchored in overview and after camera changes,
  actual mouse city selection/arrows/request dialog, native action permissions,
  wheel/drag/Focus/Overview controls, moving clouds/water, bounded controls,
  native army endpoints/fraction, all four alternate Poseidon builds, complete
  city/world snapshot equality, and disabled rendering on close.
- Final designated-world scene: **35 mesh instances / 165,032 triangles**,
  below 100 / 220K caps. Twelve clouds, at most seven cosmetic ships, at most
  1,600 cypresses, shared landmark mesh, one two-cascade directional shadow light.
  Source and derivative SHA checks pass for all five field maps; original plates
  were never overwritten. No catalog geometry baseline relaxation.
- Real city-scene `--native-ui` EN/RU checks preserve the **16 existing world UI
  assertions each**, including actual native regard changes after a request,
  500-drachma gift, fulfilment dialog, F2/Escape and running-city pause/resume.
  **Four additional checks each** verify covered-city geometry/camera suspension,
  Space suppression while the map is open, and exact visibility/camera restoration.
  These permitted economic mutations occur only in disposable in-memory runs.
- Headless native `validate_world.gd`: **32 PASS** for economic rules and request/
  gift/fulfilment progression. `validate_ui_text.gd`: **7 PASS**, including new
  CSV strings. Protected designated save, workspace settings and per-user
  preferences remain unchanged in every visible run.
- EN/RU overview, focused-city and Greek coast preview PNGs were opened and
  inspected. The designated city is Atlantean; Greek preview deliberately has
  no invented campaign labels/dealings. Ordinary game campaigns retain their
  exact native city data. Logs/JSON are `captures/world-atlas-<lang>-<size>.{log,json}`
  and `world-atlas-<lang>-native-ui.{log,json}`; field/text/core results use
  `world-atlas-*-validation.*`.
- Scene construction reported roughly **112–124 ms** on first field build and
  **13–14 ms** on cached revisits on this M4. These are short CPU setup observations,
  not sustained GPU or minimum-hardware performance evidence.

Initial normal-format/layout errors, a test-only unreleased wheel event and
repeating terrain/water patterns were fixed; final visible reviews have no
script/shader errors or unsupported-effect warnings. Existing missing voice/
Atlantis text notices persist; headless sandbox import retains macOS certificate/
editor-settings notices. Art acceptance, full-world geography, real elevations,
wider live campaigns/army journeys, label crowding/accessibility extremes,
minimum-Mac profiling and release-source clearance remain pending.

## Hades red-fire/older/beard revision — 2 October 2026

`underworld_lord_v2` implements the user's follow-up: red flame hair, older face,
full silver-gray beard, and animated flames/embers around the cape hem. The
initial direction was approved; the revised appearance awaits user review.

- Staged export: **15,638 vertices**, three core surfaces, retained 24/12 walk/idle,
  16 fight/32 disappearance samples and native reverse arrival/0.64 stride.
  Lossless optimization preserves all three primitives and **252 frame payloads**,
  both UVs, normals and palettes with **zero differences**; 130 unique targets,
  **9,492,972-byte** GLB. Evidence: `captures/hades-v2-{candidate,optimization-original}`.
- Fresh GPU derivative: **6.2 MB**, 790 texture rows, maximum half-float
  displacement error **0.000972**. The guardian matches `idle_00` within
  **0.000000030** units, preserves normals/palette/both UVs byte-for-byte,
  has no morph targets and records the current source SHA.
- `validate_hades.gd`: **18 PASS** across GPU and morph fallback: bounded
  96-triangle flame mesh/18 embers/2.4-range shadowless light, opaque character
  finish, movement/facing, full/partial disappearance, exact 0.45 frame blend
  weight and reverse arrival. No collision/navigation or native authority.
- Character **188 PASS**, geometry/LOD/growth **PASS**, all **362 assets PASS**,
  poses **109 models / 12,324 fingerprints PASS**, zero stale derivatives.
  No geometry-baseline relaxation. Logs: `captures/hades-v2-*-validation.{log,txt}`.
- Actual Metal/Mobile character captures (whole, face, rear, walk, fight, arrival
  and designated-city specimen) inspected. Snapshot equality and protected
  save/settings hashes pass. Hair was refined from orange to crimson, the beard
  gets neutral silver fill, and cape flames have varied heights/radii and soft
  edges. These are cosmetic shader effects; native timing/rules are preserved.

The menu guardian derivative is updated to the older bearded idle geometry.
EN 1920×1080 and RU 960×600 visible reviews pass 18 checks each, preserve the
protected files, and report 271,928 static triangles / 29 mesh instances.
Source clearance, physical cloth/fire simulation, facial acting, whole-campaign
visits and minimum-Mac profiling remain pending. Earlier v1 evidence below is
historical. This pass changes no C++ simulation, save/settings or source atlases.

## Floating gods — 3 October 2026

All fourteen gods float instead of walking (`scripts/god_float.gd`, `tools/godot_god_float.py`; see
`GODOT_CHARACTER_ART.md`). The hover was lowered at the user's request to 0.12 tiles at rest and 0.20 gliding.

- Export of the fourteen `walker_<god>` (two background Blenders, about 50 minutes on a busy machine): 15,370 to
  16,019 vertices, Hades 19,523, three surfaces each. `optimize_glb_memory.py` 191 to 138 MB on disk, and
  `verify_glb_optimization.py --require-uv` found **0 differences** in 14 models, 42 primitives and 3,921 morph frames.
  `bake_walker_vat.py --only <gods> --force`: 93 MB of pose textures in all (Zeus 10.2 MB, Hermes 3.7 MB); half-float
  error at most 0.00098 except Zeus at 0.0078 tiles. Hades's guardian was rebuilt. The previous god GLBs, manifests and
  derivatives were kept outside the project for rollback.
- `validate_locomotion.gd` **35 PASS** (20 earlier plus 15 floating checks: all gods recognised and nothing else, no gait
  phase or walk blend, hover range, lean up to 8 degrees and small sway, frame-to-frame smoothness, the waist pivot,
  rest hover, eased start, the same lean at 30/60/120 FPS, the core's track untouched, gods out of step, citizens not
  lifted, a slower turn by the short way). It had stopped compiling when `main.gd` began naming the `GameAudio`
  autoload; it now loads `main.gd` at run time.
- City review (`run_godot_pilot.py --character-review after --character-subjects` the fourteen gods): **14 PASS**,
  native state unchanged. Gliding hover 0.20 to 0.24 tiles, at rest 0.11 to 0.16 (plus the pose's lifted feet),
  lean 8.0 degrees, gait travel and walk blend 0, fastest vertical movement 0.10 to 0.36 tiles/s. Zeus, Poseidon
  and Hades captures (`captures/god-float-after-*-{gliding,resting}.png`) were inspected.
- `validate_characters.gd` **190 PASS** (a floating god's lowest point may now be just above the ground, as the
  harpies' may); `validate_poses.gd` **PASS** (12,522 fingerprints); `validate_assets.gd` **PASS** (384);
  `validate_hades.gd` **18 PASS**; `validate_geometry.gd`: no asset grew; it fails only because assets added by
  other sessions (animals, columns, hippodromes and others) have no baseline yet.
- Windowed `run_godot_pilot.py --validate`: EN **586 PASS, 3 FAIL**; RU **585 PASS, 4 FAIL**. None concerns walkers
  or gods: two Build-menu heading checks (`build_catalog.gd` was changed by another session that afternoon), the
  world-map aid regard check noted above, and in RU the monument halt label, while `hud.gd` and `validate_main.gd` were
  being edited by another session during the run.

## God faces and the closest zoom — 3 October 2026

Hades has a designed head (`tools/godot_god_face.py`, see `GODOT_CHARACTER_ART.md`) and the player's closest
zoom is ten tiles. Visual acceptance is pending: the images below were opened and inspected, but they are an
art review, not a verdict.

- Export (background Blender, 199 to 235 s): **19,514 vertices, 35,301 triangles**, three surfaces, 17.7 MB raw;
  `optimize_glb_memory.py` merged **252 to 130** targets (10.9 MB) and `verify_glb_optimization.py --require-uv`
  found **0 differences** in 252 morph frames; `bake_walker_vat.py --only walker_hades --force` gave **7.3 MB**
  (940 rows, half-float error at most 0.000972, as before); `make_hades_guardian.py` rebuilt the menu guardian
  (1.23 MB). The first export attempt failed its own foliage-budget guard (shell parts at source resolution, 20.6K
  protected vertices); the shells are now thinned in `godot_god_face.thin`.
- `validate_hades.gd` **18 PASS**; `validate_poses.gd` **PASS** (12,478 pose fingerprints); `validate_assets.gd`
  **PASS** (363 assets); `validate_geometry.gd` passes every check except one that is not Hades's: the geometry
  baseline of Hades was re-recorded on purpose (**29,275 to 35,301 triangles**; only that entry of
  `data/geometry_baseline.json` changed, the file was regenerated in scratch and merged by hand), and the validator
  still reports `walker_priestess` as lacking a baseline (a new asset from another session).
  `validate_characters.gd` is **189 PASS and one FAIL**, the same cause: it expects 92 refined human walkers and
  `walker_priestess` makes 93. Logs: `captures/hades-v3-*-engine.log`.
- `run_godot_pilot.py --character-review after --character-subjects walker_hades --lang en` **PASS** (native state
  unchanged); whole, face, portrait (new, straight on), rear, walk, fight, appear, city and city-closest (new, the
  closest zoom: ten tiles) captures were inspected. In the straight-on portrait the head has a heavy brow, deep-set
  eyes with white, amber iris and a faint glow, gaunt cheeks, a long nose, a grey strand beard and flame hair that
  climbs from red to orange. At the closest zoom the face is about 25 to 30 px: it reads as a bearded face, not as
  detail.
- Menu: `review_menu.py --lang en --size 1920x1080` and `--lang ru --size 960x600` each pass **18 checks**; the
  carved guardians use the new rest pose, 29 mesh instances as before.
- Windowed `run_godot_pilot.py --validate --lang en` and `--lang ru`: **589 PASS and 1 FAIL each**. The three new
  checks (zooming in by wheel and by pinch stops at the minimum distance (10.0); zooming out works from it) pass.
  The failing check is "asking for aid costs regard as the engine says (80 to 70)", in the world-map aid dialog,
  where another session was editing `esimulationservice.cpp` and `validate_main.gd` while the run was going; it is
  not connected to the camera or the character.
- Not run: `tools/replay_parity.py` and an SDL rebuild (no simulation code changed by this slice).

## Hades character and matching menu guardians — 2 October 2026

The Godot-only Hades design is installed and visually reviewed through the actual
Metal/Forward Mobile renderer. See `GODOT_CHARACTER_ART.md` for scope/rebuilding.
His original angular face, slate skin, amber eyes, blue flame hair and long dark
Greek drapery use the existing anatomical source/rig and the user's mood reference.
The menu's stone guardians derive from exactly the same idle pose; the native
sanctuary monument, atlases, Blender source and live scene remain unchanged.

- Staged background Blender export: **15,517 vertices**, **three surfaces**,
  24 walk/12 idle samples, 16 fight/32 disappearance samples; arrival uses the
  existing reverse-disappearance contract. Local generation never draws native RNG.
- `optimize_glb_memory.py` merges **252 → 130** duplicate targets; final file
  **9,389,632 bytes**. `verify_glb_optimization.py --require-uv` proves all three
  primitives, **252 original frame payloads**, normals, palettes and both UVs
  survive with **zero differences**. Final original/candidate evidence is in
  `captures/hades-flame-optimization-original` and `captures/hades-candidate`.
- `bake_walker_vat.py --only walker_hades --force`: fresh derivative, **6.1 MB**,
  780 texture rows, maximum half-float displacement error **0.000972** units.
- `validate_characters.gd`: **188 PASS**; `validate_geometry.gd`: **PASS** across
  the current 362-model catalog, including LOD and existing growth-baseline gates.
  `validate_assets.gd` also passes **all 362 assets**. No baseline relaxation
  was required for Hades.
- `validate_poses.gd`: **109 animated models PASS**, **12,324 pose fingerprints**,
  zero stale derivatives, including Hades's fight/disappearance payloads. Logs
  are `captures/hades-{characters,geometry,poses,assets}-validation.{log,txt}`.
- The guardian's source SHA is current; an independent accessor comparison
  verifies its positions equal the source's `idle_00` pose within 0.000001 units,
  and normal/palette/both UV accessors remain byte-identical. It has no morph
  targets or native collision/navigation authority.
- `run_godot_pilot.py --character-review after --character-subjects walker_hades
  --lang en` captures full body, portrait, rear, walk, fight, reverse arrival and
  a presentation-only specimen on a native firefighter route. These were opened
  and inspected; neckline overlap, a floating clasp and the former opaque aura
  were repaired during this pass. The final snapshot matches initial native
  tiles, buildings, walkers, time and money. Protected test save and both settings
  hashes remain unchanged. This is an art review, not proof of a live god visit.
- Final EN 1920×1080 and RU 960×600 menu reviews each pass **18 checks** (**36
  total**) and preserve the protected files. Both captures were inspected.
  Current menu geometry
  is **271,940 static triangles**, **29 mesh instances** and the existing 276
  bounded particles, below its original caps. The new guardians use the actual
  idle pose, so the arrival motes are absent from the stone.

The ordinary source-held idle, no facial acting and procedural rather than baked
PBR finishes remain art limitations. Blue fire flicker is cosmetic; native
animation timing and simulation clocks are retained. User visual acceptance,
physical cloth/flame simulation, other gods, minimum-Mac performance and source
clearance remain pending. Existing missing audio/Atlantis text notices and
sandboxed macOS certificate/editor-settings messages persist. These scoped
results do not clear historical wider gameplay/campaign failures.

## Main-menu Gates of Hades — 2 October 2026

The menu backdrop was rebuilt in real Godot 3D and visually reviewed in the
actual Metal/Forward Mobile renderer. See the corresponding migration slice
and `godot/assets/menu/menu_sources.json` for scope, sources and budgets.

- `python3 tools/review_menu.py --lang en --size 1920x1080`, `--lang ru --size
  1920x1080`, `--lang en --size 1280x800` and `--lang ru --size 960x600` each
  pass **18 checks** (**72 total**). The harness captures the real menu, sends
  actual mouse clicks to switch language twice, opens the adventure list and
  returns, opens the empty scratch load list and returns, verifies button bounds,
  the absence of native city/adventure adoption, collision/navigation exclusion,
  geometry caps and supported Mobile effects. No city was opened or simulated.
- All four runs preserve SHA-256 hashes of the designated test save and both
  workspace settings files. Godot settings/saves are redirected to disposable
  scratch directories. Logs, JSON results and PNGs are
  `captures/menu-hades-{en,ru}-{1920x1080,1280x800,960x600}.{log,json,png}`
  for the four combinations above. The English/Russian 1080p, normal window and
  small Russian captures were opened and inspected for composition and legibility.
- Final scene: **346,494 static triangles**, **29 mesh instances**, **276 bounded
  particles**, one directional shadow light with two cascades. The gate uses a
  real arch, stepped causeway and two retained carved Hades figures. Initial
  unindexed procedural surfaces and missing primitive vertex colours were fixed;
  the final visible runs have no script/shader errors or unsupported-effect warnings.
- Short 120-frame samples at display cadence measured **16.67–16.92 ms** on this
  Apple M4. Final setup was **0.81–1.60 s**; earlier cold passes reached **2.41 s**.
  These are brief VSync-limited observations, not GPU benchmarks or a sustained
  minimum-Mac performance pass. Cached setup and broader profiling remain pending.
- `validate_ui_text.gd` passes **7 checks**, after refreshing the translation
  import cache. An initial run found a stale import for a newly added, unrelated
  native-facing placement hint; its translation already existed in the CSV.
  No interface strings or C++ gameplay sources were edited in this menu slice.
- The adventure-list query retains existing missing-voice-file notices for
  `Had_e_3.mp3`, `Pos_e_3.mp3` and `omg_e_5.mp3` in both languages. These are not
  menu visual failures. Sandboxed headless import/text runs also report the
  existing macOS certificate/editor-settings access messages; visible reviews
  exit normally. Whole-game/campaign parity, source clearance, visual acceptance
  and production packaging remain separate gates.

## Contextual construction interface — 2 October 2026

The second interface pass keeps the native commands and replaces the large card
row with a coloured icon dock, centred smaller model tiles and a selected/hovered
tool panel. Facing buttons share T; wall fill forwards the existing native fill
flag. Blue/coral cursor badges display native prices, counts and restrictions.
Translated contexts grow upward and the tray temporarily folds the minimap.

- Metal/Mobile focused runs pass **67 checks each in EN and RU**: the existing
  **20** HUD integration checks plus **47** contextual construction checks. Real
  viewport events exercise facing buttons, tile hover/restore, one-click map
  restoration from the tray and wall fill.
  The fill checkbox quotes nine pieces versus eight for a native 3×3 outline.
  Successful and occupied native previews supply the badge text and colours;
  bounds, pointer pass-through and clearing outside native terrain are checked.
  Hospital and wall contexts clear the toolbar at 1440×900, 1280×720 and
  1920×1080 in both interface languages. Browsing preserves native treasury,
  time, buildings and walkers. Evidence: `captures/interface-context-final-{en,ru}.log`.
- Native road **22**, wall **63** and interface translation **7** gates pass.
  Logs: `interface-context-roads.log`, `interface-context-walls.log` and
  `interface-context-text.log`. No C++ or asset-geometry change was needed.
- Visual review completed and exited normally: English selected-tool, successful
  and occupied native ghosts, Russian industry/storage and wall options at
  1280×720. Screenshots: `interface-context-{build-en,placement-en,blocked-en,
  build-ru-720,wall-ru-720}.png`; log: `interface-context-review.log`.
  The tray/toolbar overlap seen in the first Russian capture was corrected.
  An earlier combined capture timed out while resizing; the final review
  completed cleanly. This does not establish sustained rendering performance.
- The protected designated save and both settings files remain byte-identical
  after the focused runs and final review. Original SVG rotation icons extend
  the existing icon system; there is no reference-game artwork or new UI library.

Limits at this earlier slice: roads still follow the native orthogonal grid;
curves require separate simulation/pathfinding work. The later status/service/
size slice above implements text/control options and service summaries.
Keyboard/gamepad navigation and complex inspector polish remain pending.
This scoped pass does not supersede earlier full-suite failures below or prove
whole-game/campaign parity or minimum-Mac performance.

## Interface and surrounding landscape — 2 October 2026

The shared HUD redesign and cosmetic landscape are implemented. Normal launch
still embeds C++ with no SDL renderer. The new outside geometry has no collision,
navigation or native cells; the native map retains all 25,992 tiles. See
`GODOT_INTERFACE.md` and `GODOT_SURROUNDINGS.md` for source contracts.

- Visible Metal/Mobile scenery review: **16 checks pass in EN and RU**; the
  final headless runs also pass **16 each**. The added check verifies indexed vertex reuse.
  Tests include **976 actual submitted land-rim corners** against native geometry,
  outside-cell exclusion, zero collision objects, caps, repeated wheel/pinch
  clamps, the actual Home-key path, and unchanged native time/money/tiles/
  buildings/walkers. A five-by-five inland component fixture derived from a
  real test tile verifies country ground instead of ocean; it never enters C++.
- Final scenery: **113,115 triangle corners**, **19,440 indexed vertices**, **11,302 adaptive
  leaves**, **393 trees in 33 batches**. Visible setup measured **403–468 ms**
  on this M4. This adds a one-time city-load cost; no new sustained frame-time
  or minimum-Mac claim is made. Ocean normal waves attenuate at distance.
- Maximum camera distance is **239.4** instead of **364.8**, a **34.4% reduction**.
  Home remains below that limit. Five orbit captures, a low horizon and a close
  land/forest join were visually reviewed. Earlier wet-rim and high-frequency
  mountain-strata artifacts were corrected before the final captures.
- Save and both settings hashes stay unchanged in the visible EN/RU runs.
  Evidence: `captures/surroundings-{en,ru}.log`, `surroundings-review*.json` and
  `surroundings-*.png`. The image set uses the designated city, not the user's
  other campaign screenshot. Wider campaign boundary coverage remains pending.
- The interface text gate passes **7**, and the updated native catalog/menu
  gate passes **487** across EN/RU. Evidence: `captures/interface-text.log` and
  `interface-catalog.log`. HUD click/search/focus/close/minimap/live-workforce
  and six EN/RU resolution cases pass in the broader visible English run.
- The earlier broad English gameplay run passes **437 checks** and fails **two
  hero-hall catalog assertions** (quest offering/removal), recorded in
  `captures/interface-gameplay-en.log`. Camera, construction, storage, overlays,
  map/terrain and HUD gates pass. An isolated native Hades-quest query produces
  the expected Perseus hall; full ordered-suite hero-menu behavior still needs
  investigation. Do not claim whole-game parity. A Russian full-suite attempt
  also hit a startup threaded-resource/render crash; later dedicated scenery
  runs load and close normally. Full EN/RU gameplay clearance remains pending.

That run's hero-test diagnostic had a mismatched bracket that prevented game
script loading; a narrow syntax repair restored the visible scene. Early broad
runs recorded Mobile SSR/SSAO warnings and shutdown RID leaks. The final scenery
reviews exit without those warnings/errors; broader test cleanup remains pending.
Further interface polish, per-map scenic art, cached/asynchronous scenery setup
and minimum-hardware profiling remain pending.

## Walking refinement — 1 October 2026

The human runtime now blends idle/walk through acceleration and stopping, holds
short observation gaps and eases headings around corners. Phase uses native
horizontal displacement before terrain-height adjustment. The physician benchmark
has new authored heel/toe contact, swing, weight transfer and counter-motion;
other roles retain their own cycles. Export timestamps now start at zero and
the 100 Hz bone import preserves the sampled contact motion. No C++ rules changed.

- `tools/test_citizen_gait.py`: **3 tests** pass, checking planted contact against
  scaled native travel, swing/double support and loop/contact-velocity continuity.
- `gait-validate_locomotion.log`: **20** checks pass, including 30/60/120 FPS
  equivalence, stop phase, short gaps, vertical corrections, angle wrap, shared
  aliases, actual fallback morphs and VAT blend parameters. No exit leaks/errors.
- `gait-validate_citizen.log`: **38** checks pass. Exact 0.64/3.0 s loops; 137
  bones, 30,116 vertices, 17 meshes and 12.7 MB compressed textures. The 6,249-vertex
  crowd twin and the nearest-24 pool retain their budgets and intermediate weights.
  At 256 intervals, 286 individual support intervals cover 0.715 tiles. Mean
  directional contact error is **3.1%**, below the 4% budget; lowest contact is
  **-0.000983** units, above -0.002. This stronger metric replaces the prior
  average-length sliding check, whose fast and slow intervals could cancel.
- Baked poses: **39/39** fresh animated models, **2,313** poses verified, maximum
  fingerprint gap **0.000267**. **241** assets and the geometry growth/LOD gate pass.
- Visible EN/RU: **237 each**, no errors; designated save and settings hashes
  unchanged. These also cover the concurrent Build-menu work.
- Metal/Mobile continuous reviewer passes. Fixed pose samples preserve native
  time, money, tiles, buildings and walkers. The live run advances 128 native ticks
  (6.4 seconds, including the route-selection preflight), and the displayed
  character travels **3.53 tiles**. Its appearance is a review-only physician on
  a native transporter route; the initial city has no physician. Role mapping,
  simulation coordinates and saved files are untouched. Report/frames:
  `captures/locomotion/`; preview: `captures/walking-improved.gif`.

Limits: foot contact error remains small but nonzero; individual foot placement
on slopes/stairs, other occupations' new cycles, work/cargo/death states and
physician visual acceptance remain pending. No minimum-hardware or sustained
performance claim follows from this short capture. The earlier concurrent
playable-loop citizen failures below are superseded by this completed gait gate.

## Building work animation — 1 October 2026

The Godot building exports held a single working pose. The fix samples authored
workers/tools/machinery/effects for 35 types and provides an inactive pose in
GPU spatial batches. Native `working`, staffing and existing phase observations
control the presentation; native gameplay time controls cadence, pause and speed.
Read [the activity contract](GODOT_BUILDING_ACTIVITY.md) for coverage and rebuilding.

- `validate_building_activity.gd`: **171 checks**, all passing. All 35 derivatives
  match their original-model hash; animated mesh parts bind GPU materials and
  retain unique imported texel addresses, move through their work cycles and
  include inactive states. Native EN/RU checks cover employees, industry
  shutdown/resume, all four speeds, pause, pending decisions and unchanged delta
  snapshots. Work-state changes preserve existing geometry batches; demolition
  removes them. Decorative palace/baths follow their native enabled state.
- `tools/verify_building_activity.py`: **35 assets / 864 part poses**, all passing.
  Independent decoded baked texels match authored samples within **0.000968 tile**;
  source-to-runtime rest positions, normals, colours, UVs and triangle indices are
  byte-identical. Runtime morph buffers are absent, finish groups are at most six,
  and full-detail triangles stay within five percent of each original model's
  budget. Six initial exports were trimmed back to their existing geometry tiers.
- Existing embedded-core **67**, storage/production **140**, and visible city
  checks **232 per EN/RU** pass. Visible logs contain no script/render errors;
  both launches report unchanged designated save/settings. The extension was
  rebuilt and finalized/signed with `tools/build_godot_extension.sh`.
- The actual Metal/Mobile city reviewer samples olive press, timber mill and
  warehouse at native placements, captures 24 working views and a worker-free
  olive-press view, reads back independent work flags/offsets on shared GPU
  instances, checks imported LOD ladders for all 35 derivatives, and verifies the
  entire paused native city remains unchanged. Captures and report are in
  `godot/captures/work-*.png` and `building-activity-review.json`; the olive-press
  loop is `building-workers.gif`.

Evidence logs: `building-activity-validation.log`, `building-activity-pose-proof.log`,
`building-activity-review.log`, `building-activity-embedded.log`,
`building-activity-industry.log`, and `building-activity-visible-{en,ru}.log`
under `godot/captures/`. Runtime VATs total **67.8 MiB across all 35 types**;
only present types load in normal play. Capture readback stalls make capture FPS
unsuitable for performance claims. Draw groups can rise from three to six;
minimum-Mac/stress performance remains pending.

The broader visible harness also needed a corrected load-dialog signal test
(prevent scene replacement during the test), isolated save fixtures, physical
action registration on scene reload, and a language-change check that starts
correctly in either EN or RU. These checks preserve the normal game controls.
The industry reload comparison excludes cosmetic phase offsets as well as
session IDs; staffing and work-state observations remain compared.

Limits: this connects existing authored work geometry. It does not extend the
physician realism benchmark to on-site workers. Morph samples retain rest normals;
rotating-tool lighting is approximate. Inventory/cargo overlays, rowers, remaining
construction/fire/destruction/combat states and unmapped campaign types still
need coverage. This is not whole-game production or sustained performance proof.

## Earlier baseline evidence

The C++ simulation is loaded by GDExtension in the Godot process. Diagnostics
confirm that SDL video and audio subsystems are off and no native window/renderer
is created. Normal launch starts only Godot. The SDL2-compat/SDL3 class conflict
was resolved using a private SDL2 build with video/audio drivers disabled and
signed local helper-library copies. Installed Homebrew libraries are untouched.

| Area | Result |
| --- | --- |
| Embedded core | 67 checks across EN/RU: original save, initial clock/treasury/population and district tile metadata against the SDL reference, full map, paused tick scheduling, all four native speeds, frame-stall clamp, invalid controls/placement, modal request pause and original callback, four building footprints/costs/occupied rejection, one-owner restriction, close/reload and designated-save enforcement. |
| Godot input and simulation | 182 checks per EN/RU run: 99 camera/construction/inspector checks, 17 terrain, 20 elevation, 33 detail and 13 map-review checks. Q/E orbit, R/F tilt/limits, T independence, pan, full revolution, 30/60/120-update timing, walker alignment, cursor zoom, picking, native clock/no SDL; nine imported ghosts/native costs, storage/production inspectors, keyboard focus/drafts/queue recovery, undo and landmark demolition remain covered. Terrain checks cover actual cells/shared materials, forest clearing, water/bank and cliff/ramp picking at four angles, eligibility, texture updates without collision/coast rebuild, foot/ghost projection and ramp-road costs/undo. Detail adds four actual resource kinds' picking/eligibility at four angles, EN/RU ground identity, read-only native state, actual decorated road/housing construction/refunds and native forest clearing. |
| Terrain fields | 18 checks in `validate_terrain.gd`: the actual 25,992 tiles/228×227 bounds, floating signed field, every native water/land center, finite bounded distance, shallow/deep falloff, native water altitude, fertile/forest/road masks, empty irregular cells, read-only native state, incremental texture reuse, road updates, water-mask refresh/reversal and forest soil refresh. |
| Elevation geometry | 22 checks in `validate_elevation.gd`: additive native classifications, flat native foundations/water, shared slopes across sections, closed vertical sides, exact mesh/sampler agreement, finite geometry/budget, read-only native state and incremental cache refresh. Half-height road/foundation checks use disposable presentation copies only; this native save has no half slopes. |
| Terrain detail | 31 checks in `validate_details.gd`: native deposit/perimeter identity, complete mineral-field centers/empty padding, shared texture/edit reversal, native habitats/buffers, anchored and bounded geometry, instance/mesh/batch budgets, finite normals, open quarry centers, distinct resource palettes, deterministic layouts, road/foundation/water/height/cache reversal, section-edge refresh, conservative legacy snapshots and full native state unchanged. Absent silver/tall stone/black marble kinds are geometry checks only. |
| Map-review corrections | 16 checks in `validate_map_polish.gd`: complete native forest and 57 crossing-cell coverage, shore approaches, tree bounds/anchors, uploaded reduced LOD indices/budgets/normals, spatial batching, deck heights/joins, forest and road edit restoration, eligibility cache reuse and native state unchanged. The 13 visible checks per language cover coordinate conversion, actual pedestrians on decks, both crossing axes picking at four angles, ships retaining water height and read-only state. |
| Garden foliage | 26 checks in `validate_gardens.gd`: all 178 native placements across eight updated assets, native footprint/inspection identity, anchored full-height park geometry, finite bounds/normals, double-sided palette materials, surface and source-geometry budgets, and the entire paused native city unchanged. |
| Construction / inspection | 242 checks across EN/RU in `validate_construction.gd`: safe invalid coordinates, read-only queries, nine exact footprints/costs, occupied/rejected placement, native inspectors, session model facing, one-time undo refunds, demolition charges/removal, protected/stale/confirmed landmark operations, forest clearing, paused clock and reload restoration. |
| Storage / production | 140 checks across EN/RU in `validate_industry.gd`: native inventories/recipes/buffers, four orders, independent limits, stock preservation, sculpture capacity, invalid/unsupported resources, stale selection/reload/demolition/replacement/undo tokens, city-wide industry staffing and idempotence, shared-grower semantics, paused time/terrain/money, protected reload and pending decision preservation. |
| SDL reference (previous baseline) | 16 original bridge checks for startup, validation, road/housing/hospital/fountain construction and costs, speed and paused clock; 26 Godot camera/simulation checks on that reference view. |
| Models | All 362 development GLBs import. Animated people/animals retain 35 morph targets and measured walking displacement after vertex-colour/material batching. Most idle poses are held; complete visual state coverage remains pending. |
| Saved-city coverage | All 792 rendered building objects and 279 initial walkers have models. The other 42 building records are native reservations/owners. Initial and subsequent snapshots checked during 60 seconds of requested simulation contain no missing assets. |
| Native controls (previous baseline; bindings unchanged) | Existing camera binding migration/conflict/persistence/wraparound/repeat checks pass. |
| File protection | Launcher checks show the designated test save and both settings files unchanged. Construction is discarded on reload. No commits or publishing occurred. |
| Visual checks | Actual EN/RU captures reviewed at 1280×800, using Metal/Forward Mobile. UI text and Cyrillic, model pivots, spatial batches, forest and full-map navigation are visible. No grey/gold conversion placeholders remain in the designated city. Thirty-two review captures cover buildings, moving people, animals and boats; other campaign coverage remains pending. |

The saved map has 25,992 actual tiles inside a 228×227 bounding rectangle and
834 initial building objects. The building count changes during construction/demolition
checks; this is not saved to disk. Session walker counts vary after running
because the native simulation continues creating/removing walkers.

A reference-view regression exposed a ray missing an exact shared triangle edge
at 270°. Picking now retries tiny ray offsets at shared edges; its bounded native
height-plane fallback applies only to flat valid-map cells. Slopes use their
generated presentation collision. Unchanged full reference snapshots also stop
recreating collision geometry. Both terrain-ray and authoritative-grid behavior
remain independent of camera yaw.

There are 362 development model variants; current package sizes are recorded
in each model manifest. Compatible PBR
surfaces are merged with per-vertex colours; 578 model batches replace thousands
of source material groups. Ten retained building types were re-exported with
realtime geometry budgets. Full procedural baking remains pending.
Generated GLBs, extension/helper binaries, editor caches and captures are ignored
by Git. Local dependency source LICENSE files and engine GPLv3 notices remain.
The final native executable was rebuilt, copied, signed and checked. The extension
build/sign helper was also exercised. The source checkout already contained
substantial unrelated remaster work, which was retained.

The previous 21-model baseline observed around 60 FPS with conversion placeholders.
Earlier representative city views have much more geometry. Batching reduced the
sampled full-map draw count from roughly 6,800 to 1,270 before the final geometry
pass. Final short M4 captures recorded about 55–63 FPS in the overview and 24–67 FPS
across close views, with roughly 166–1,270 sampled draw calls. Per-view FPS
varies; see `coverage-visual.log` for local observations.
Those observations predate the corrected forest mask and new terrain materials;
use the terrain evidence below for current local observations.
These are short M4 observations, not sustained minimum-hardware, maximum-city or
1080p acceptance benchmarks. Whole-game UI/audio,
campaign progression, deterministic seeded replay, full art/material/state
coverage and standalone production packaging remain unverified acceptance gates.
The inherited missing campaign-text warning is still a content dependency; this
work does not make the original development installation release-ready.

Earlier construction-slice evidence is in `../godot/captures/`:
`construction-native.log` (122), `construction-embedded.log` (67),
`construction-ui-en.log` / `construction-ui-ru.log` (45 each), and
`construction-en.png` / `construction-ru.png`. Both visible Metal runs passed
with save/settings protection. The extension helper and native executable build,
copy/sign/strict verification completed. Existing override warnings during native
compilation remain; final runtime checks have no script/extension errors.

A restricted headless launch initially encountered Godot's user-log rotation
crash and a macOS certificate-store diagnostic. Absolute project log paths avoid
the former; final checks were rerun with normal macOS access. These startup issues
are separate from the unchanged missing original campaign-text warning. The
launcher now supplies an absolute project log path in both backends.

Earlier baseline evidence remains in `embedded-validation.json`,
asset/reference/camera logs, and `full-city-en.png` / `full-city-ru.png`.
See `GODOT_MIGRATION.md` for the remaining stages.

## Placeholder-replacement evidence

Final evidence uses `coverage-city.log` / `city-coverage.json`,
`coverage-assets.log`, `coverage-embedded.log`, `coverage-construction.log`,
`coverage-ui-en.log` / `coverage-ui-ru.log`, and `coverage-visual.log`.
`models-<subject>-<angle>.png` contains thirty-two 1280×800 Metal review captures.
The export pipeline was also exercised into an isolated temporary output folder.
Native executable copy/sign/strict verification and GDExtension build/finalization
completed. The designated save/settings SHA-256 hashes remain unchanged.

During implementation, validation caught missing god variants, a monument
generator's atlas-only early exit and two lighting-script API errors. The final
imports and runs resolve these; failed intermediate checks are not parity evidence.
Read `GODOT_ASSET_COVERAGE.md` for source/model contracts and the remaining visual
state matrix, cargo, animation, terrain and campaign limitations.

The coverage fixture schedules 1,200 native ticks over 60 seconds of requested
advance. A native decision becomes pending; it is preserved and later snapshots
hold native gameplay time. Coverage success is not evidence of uninterrupted
campaign progression. The live review exercises several seconds of walker
movement and preserves its own pending decisions.

## Storage / production evidence

Final logs are `inspectors-industry.log` (140), `inspectors-construction.log`
(242), `inspectors-embedded.log` (67), and `inspectors-ui-en.log` /
`inspectors-ui-ru.log` (99 each). `inspector-warehouse-<lang>.png`,
`inspector-granary-<lang>.png`, `inspector-olive_press-<lang>.png` and
`inspectors-<lang>.png` are actual 1280×800 Metal captures. Both languages passed
with the designated save/settings unchanged. Industry controls use native
city/resource workforce bookkeeping; duplicate requests do not double-adjust
jobs. Storage limit reductions preserve stock. Object tokens remain session
handles and are deliberately not treated as durable IDs on reload.

The extension build/finalization/sign helper completed; the native reference
executable was rebuilt, copied and ad-hoc signed with strict verification.
Existing compiler override warnings remain. An initial restricted editor import
reported certificate/editor-settings access errors; final runtime verification
used normal macOS access. One early reload test incorrectly compared session IDs
and allocation order; it now compares native building state by location/type.
Failed intermediate attempts are not parity evidence.

Nine square/road tools are covered in this designated city. Full construction
menus, drag roads, trading/vendor controls, save/load/settings, campaign/military
parity and visual building activity remain pending. Imported geometry was not
changed in this slice. These tests validate command/state contracts and visible
controls; complete timed production-chain/pathfinding parity remains a separate
seeded replay gate. New per-view captures do not extend the performance claim.

## Ground / shoreline evidence

Final evidence is `terrain-contract.log` (18), `terrain-ui-en.log` /
`terrain-ui-ru.log` (116 each), `terrain-construction.log` (242), and
`terrain-embedded.log` (67). The prior storage/industry suite remains recorded
above; its C++ implementation was not changed in this visual slice.
`terrain-validation.json` records signed-field, mask/cache/edit and irregular-map
checks. Visible controls exercise river/bank picking at four orbit angles,
authoritative road eligibility, road construction/undo material refresh without
collision rebuild, and native forest clearing with the corresponding tree removal.

`terrain-before-<subject>-<distance>-<angle>.png` and
`terrain-after-<subject>-<distance>-<angle>.png` contain 21 matching views per phase:
district/shore at distances 24/65 and yaw 15/45/135/225/315 plus the full map.
Actual Metal screenshots were reviewed at 1280×800. The ground checkerboard and
colour-wave water grid are absent; sand banks, shallow-depth tint and corrected
native forest placement are visible. Existing building/character geometry is
unchanged. Both `terrain-review-<phase>.json` reports compare all native tiles,
buildings, walkers, clock and treasury and pass unchanged. `terrain-ui-<lang>.png`
shows the current interface; UI tests make temporary in-memory edits.

The final `terrain-review-after.json` samples settled frames before capture, over
about one second per view after a half-second warmup. On this M4, observed frame
rates were **34–71 FPS**, with **379–1,763** sampled draw calls across those 20
district/shore views. The rapid original before capture's FPS counters included
screenshot stalls; they are not comparable performance evidence. This is not a
sustained benchmark, a minimum-Mac acceptance test or proof of a speed improvement.
Forest/geometry budgets and wider campaigns still require profiling.

The protected save SHA-256 remains
`f1ce69f681522b1bf249b5f7792d8fb3759c644297500cf77093412219744ab9`;
repository settings remain
`71a72815007e3bb8c08a61924105755641870600d5de0327416fc2ee6bd98686`;
root settings remain absent. No C++, GLB or runtime library changes were required,
so neither native binary was rebuilt in this slice. Final runs have no script or
shader errors; the inherited missing campaign-text warning remains. Blender's
live scene was not modified.

At this material-stage baseline, elevation planes and outer map edges were still
stepped. The next section records their geometry replacement. Mineral outcrops,
understory, richer water interaction and broader campaign coverage remain pending.
Read [GODOT_TERRAIN.md](GODOT_TERRAIN.md) for the current boundary and next slice.

## Elevation / cliff evidence

Final evidence is `elevation-contract.log` (22), `elevation-ui-en.log` /
`elevation-ui-ru.log` (136 each), `elevation-embedded.log` (67),
`elevation-construction.log` (242), `elevation-industry.log` (140), and
`elevation-terrain.log` (18): **761 passing checks**. `elevation-validation.json`
records 203 blocked cliff cells, eight walkable road ramps, 112 protected elevation
cells, 181,026 ground vertices and 1,014 vertical side faces. Every flat native
water/foundation profile retains its native height; generated slope triangles
agree with the walker/preview height sampler. Native state remains unchanged by
geometry generation and read-only queries. Half-height profiles and cache edits
use disposable presentation copies, not a modified or alternate saved city.

Visible Metal runs exercise cliff/ramp picking and native eligibility at four
angles, surface-following road ghosts and walker foot projection, and actual
native road demolition/reconstruction/inspection/undo on an unoccupied ramp.
Costs/refunds and the continuous ramp profile remain correct. Invalid map-edge
feedback does not create land. Both EN/RU captures were reviewed at 1280×800.

`terrain-elevation-before-<subject>-<distance>-<angle>.png` and corresponding
`after` files contain 21 matched views per phase: cliff/ramp at distances 12/38,
yaw 15/45/135/225/315, plus the full map. Reviewed captures show closed cliff gaps,
joined road ramps and shared soft lighting along limestone slopes. The irregular
native boundary remains its original cell footprint. Both
`terrain-review-elevation-<phase>.json` reports pass full native tiles/buildings/
walkers/time/treasury unchanged. The final after review observes roughly
**30–93 FPS** and **226–1,247** draw calls across the 20 close/wide subjects on this
M4, sampled for about one second after a half-second warmup. These short local
observations do not establish minimum-Mac performance or a speed improvement.

`elevation-build.log` records the GDExtension rebuild and mandatory library
finalization/signing. Native reference Ninja was up to date; its executable was
copied, ad-hoc signed and strictly verified, as was the extension. No GLBs or live
Blender scene changed. The protected save/settings hashes remain exactly those
recorded above, and root settings remain absent. Final runs have no script/shader
errors. Intermediate parser/type errors were corrected before these final runs;
failed attempts are not parity evidence. The inherited missing campaign-text
warning remains. Wider native elevation/half-slope coverage, outcrops/understory,
material/activity baking, sustained performance and all production release gates
remain pending. Presentation collision changed; native pathfinding, simulation
heights, construction rules, routes and 20 Hz timing did not.

## Mineral / forest-edge detail evidence

Final evidence is `detail-details.log` (31), `detail-ui-en.log` /
`detail-ui-ru.log` (169 each), `detail-embedded.log` (67),
`detail-construction.log` (242), `detail-industry.log` (140),
`detail-terrain.log` (18) and `detail-elevation.log` (22): **858 passing checks**.
`detail-validation.json` records 3,746 initial instances in 239 MultiMesh batches
across 64 actual 24-tile sections: 1,044 stone, 38 copper, 50 orichalcum,
42 marble perimeter fragments for 108 native marble cells, 2,101 grass tufts and
471 shrubs. Cached meshes have 81–330 vertices in the instantiated city catalog.
All seven resource kinds/two foliage kinds and both variants are checked for finite
geometry, budget and distinct palettes. Silver/tall stone/black marble are absent
from this save; mesh checks do not establish their native campaign visual coverage.

Geometry roots follow the triangulated native presentation surface; complete
props stay inside their cells. Every native deposit center has the appropriate
shared mineral soil mask, including unobstructed quarry interiors. Understory
excludes native roads/foundations, fields, mineral cells, water and missing cells
with a one-cell buffer. Per-section caps and opaque distance fades bound foliage;
there is no per-prop node, collision or navigation. Deterministic layout checks
do not use native RNG. Road/foundation/water/height/resource-field/cache edit tests
operate on disposable observation copies and restore every original column.
The full paused native tiles/buildings/walkers/treasury/clock remain unchanged.

Both actual Metal UI runs verify stone/copper/marble/orichalcum picking and native
road eligibility at 0/90/180/270 degrees, localized resource ground inspectors,
native road/housing construction on decorated dry land, exact costs/refunds and
deterministic detail restoration after undo. Native forest clearing removes its
shrubs and refreshes neighbor habitat without rebuilding coast distance. These
commands are in memory and never write the saved city. `detail-ui-<lang>.png`
captures were reviewed at 1280×800; EN/RU runs have no script/shader errors.

`terrain-detail-before-<subject>-<distance>-<angle>.png` and corresponding `after`
files capture five subjects (stone/copper/marble/orichalcum/clear forest edge),
distances 10/32, yaw 45/135/225/315 and an overview: **41 views per phase**.
The controlled before mode hides only new props/mineral tint in the current
renderer. Both `terrain-review-detail-<phase>.json` reports pass full native
state unchanged. Reviewed after images show softened mineral outcrops, distinct
ore veins, continuous marble soil with low perimeter fragments, and sparse grass/
leafy shrubs. No decorative shoreline rocks were added. Existing trees and all
240 building/character GLBs remain unchanged; tree canopy quality is still pending.

The final after review ran alone after UI/native checks and sampled settled
frames over about one second per view after a half-second warmup. This M4 at
1280×800 observed **53–117 FPS** and **53–856** draw calls across the 40 subject
views. These are short local observations, not a sustained/minimum-Mac benchmark,
1080p acceptance result or proof of a performance improvement. New detail budgets
do not replace the full simulation/loading/memory/GPU performance gate.

No C++, GLB or runtime-library change/rebuild was needed. The protected save and
repository settings SHA-256 hashes remain those recorded above; root settings
remain absent. Blender's live scene was preserved. Intermediate GDScript type/API
errors and test-helper mistakes were corrected; failed attempts are not parity
evidence. Final logs retain only the inherited missing campaign-text warning.
The new procedural source manifest retains `needs_evidence` provenance status.
Tree canopy/species quality, tree wind/LOD/occlusion profiling, wider native
mineral/elevation/marsh/lava/quake coverage, material/activity baking and all
whole-game and production release gates remain pending.


## Map-review refinement evidence

The review exposed missing native bridge presentation and a half-tile walker
coordinate mismatch. Final evidence is `polish-ui-en.log` / `polish-ui-ru.log`
(**182 each**), `polish-contract.log` (**16**), `polish-details.log` (31),
`polish-terrain.log` (18), `polish-elevation.log` (22), `polish-embedded.log` (67),
`polish-construction.log` (242) and `polish-industry.log` (140): **900 passing checks**.
Both Metal UI runs finish with no script/shader errors and unchanged protected
save/settings. Native routes, resource flags, ownership, costs and 20 Hz timing
remain unchanged; these are presentation corrections, not a seeded replay proof.

`map-polish-validation.json` records all 3,138 native forest cells represented by
independently anchored trees in 182 MultiMesh batches: 2,327 olive-style and 811
cypress. Four meshes have 4,224–4,320 vertices including reduced LOD geometry.
Tests inspect the uploaded rendering-server index buffers for valid reduced LODs,
finite normals and budgets; roots/canopies stay bounded with wind space. Native
forest clearing and reversal refresh the affected sections deterministically.
Further species, occlusion and sustained minimum-hardware performance need coverage.

All **57 native water-road cells** now have real timber decks, rails and stone
supports, with **20 connected shore-road approaches** in 20 spatial batches.
The two meshes have 540/12 vertices. Approach/deck heights join continuously;
water-road observation edits remove/restore crossings and neighbor approaches.
Only deck/approach picking tops have new collision, separate from the unchanged
terrain mesh and native pathfinding. Visible checks pick both axes at four orbit
angles and compare original placement eligibility. Actual crossing pedestrians
stand on decks; boats retain native water height beneath them. The unchanged
native absolute positions are converted once from 0..1 local coordinates into
Godot tile centers, including negative coordinates. Heading/interpolation follow
the same native deltas. Wider bridge junction/height/campaign coverage is pending.

Mineral tops and deterministic height/spacing now vary more to reduce the rows of
conical piles. The existing 31 detail checks retain deposit identity, exact native
cells, quarry walkable centers, habitats and construction/undo restoration.
`polish-ui-<lang>.png` contains final interface captures. `polish-review.log` and
`terrain-review-polish-after.json` record 49 Metal views: the five previous detail
subjects plus a native bridge, distances 10/32, four orbit angles and an overview.
The report compares all native tiles/buildings/walkers/time/money unchanged.
Historical detail-after images retain the prior forest/absent-bridge presentation.
The final review ran alone after regression checks at 1280×800 on this M4,
observing **45–60 FPS** and **61–1,354 draw calls** across the 48 subject views.
These are short local observations, not a sustained/minimum-Mac or 1080p acceptance
benchmark, nor evidence of a speed improvement. Tree/crossing geometry and shadow
budgets still require the production performance gate.

No C++, GLB or runtime-library changes/rebuilds were required. The old independent
tree GLBs, native SDL terrain assets and live Blender scene remain intact. New
sources retain `needs_evidence` provenance in `map_polish_manifest.json`. Intermediate
script/geometry and validation-inspection API errors were corrected; failed attempts
are not parity evidence. The inherited campaign-text warning remains a development
content dependency. Whole-game and production gates remain open.


## Garden foliage evidence

The final eight garden GLBs were exported in disposable background Blender sessions
with the Godot-only foliage adapter. Native sprite sources, live Blender scene,
C++ simulation and runtime libraries were not changed/rebuilt. The existing asset
IDs remain, and the 240-model catalog size is unchanged. Source/footprint/revision/
budget records retain `needs_evidence` provenance in each garden manifest.

Final evidence under `godot/captures/`:

- `garden-contract.log` / `garden-validation.json`: **26 checks** covering all
  **178 garden placements** (164 parks), native footprint/inspection identity,
  finite imported normals/bounds, ground anchors, actual full-height 1x1 park
  geometry, double-sided palette materials, budgets and native state unchanged.
- `garden-assets.log`: **240** models import; existing walker morphs/gaits remain.
- `garden-ui-en.log` / `garden-ui-ru.log`: **182 each** with final assets, covering
  Q/E, R/F, picking, construction/inspection, undo, terrain and existing bridges.
- `garden-embedded.log`: all **67** embedded/native-core regressions still pass.

This slice reran **697 checks**. The previous 900-check map-review suite remains
historical evidence; its separate construction/industry/terrain-only runners were
not rerun for this asset-only refinement.

`gardens-before.log` / `garden-review-before.json` record the old models.
`gardens-after.log` / `garden-review-after.json` record **32 final Metal views**:
each of the eight native garden types at 45/135/225/315 degrees, using the same
baseline placement, camera distance and pitch. The entire paused native tile,
building, walker, treasury and clock state remains equal before/after each review.
`garden-after-*.png` and four `garden-review-sheet-*.png` sheets were inspected.
The final topiary has clipped leaf-covered cones/spirals and a peacock; Fish Pond
has branchy cypresses and individual vine leaves across the whole pergola. Parks
show full-height umbrella canopies/bench modules. Maze gaps and monuments remain.

At 1280x800 on this M4 the final review's short frame-counter observations ranged
**40–50 FPS** and **38–770 draw calls**. These include screenshot readbacks and do
not constitute settled/sustained profiling, a before/after speed comparison or a
minimum-Mac/1080p performance gate. The per-asset budgets and lower weighted source
geometry count are documented in `GODOT_ASSET_COVERAGE.md`; more garden species,
park variants, wind, material baking and campaign coverage remain pending. The
normal preview was reopened with final assets; its initial frame-300 counter read
28 FPS/1,057 draws, another startup observation rather than a sustained benchmark.

The first Russian UI attempt lost its initial held-camera interval during window
activation. Validation now brings its owned window forward and lets focus settle
before injecting keys, and logs the measured angle. Both final language runs pass;
the failed attempt is not parity evidence.

The launcher and final hashes confirm the protected save and settings unchanged:
`CLAUDE-TESTING-ADVENTURE.ez` SHA256 remains
`f1ce69f681522b1bf249b5f7792d8fb3759c644297500cf77093412219744ab9`, and repository
`settings.txt` remains
`71a72815007e3bb8c08a61924105755641870600d5de0327416fc2ee6bd98686`; parent settings
remain absent. The inherited campaign-text warning persists. No production
packaging, publication, rights clearance or whole-game parity is implied.

## Performance slice: snapshot path and render budget — 30 September 2026

A measured review of the embedded boundary and the frame cost. All numbers are from
this M4 (16 GB) while another Godot instance and normal desktop load were running,
so absolute times are indicative; before/after pairs were taken back to back.

**Snapshot path** (designated city: 25,992 tiles, 834 buildings, 279 walkers; headless
`EZeusSimulation`, in-memory only; diagnostics now expose `profile_us` and `wrapper_us`):

| Item | Before | After |
| --- | --- | --- |
| Delta snapshot, paused, end to end | 4.2–4.5 ms | 0.94 ms |
| Delta snapshot, running, end to end | 4.2 ms | 0.99 ms |
| C++ tile scan per snapshot | 1.30 ms | 0.26–0.32 ms |
| C++ building list | 0.41 ms | 0 ms when unchanged |
| Godot JSON parse of the snapshot | 1.9 ms (135 KB) | 0.44 ms |
| Tiles re-sent per running snapshot (walker-driven eligibility flips) | 1.9 | 0 |
| `receive_state` after placing one house | 60 ms | 6.7 ms steady (22 ms the first time an asset's GLB loads) |
| Full `update_buildings` | 39 ms (25 ms of it reading manifests from disk per building) | 2.6 ms |

The tile scan no longer calls `canBuild` for every tile in delta snapshots and keeps
a flat last-sent array; the eligibility column (index 5) is computed for full
snapshots and for tiles re-sent for another reason, and is not part of change
detection because it flips whenever a walker steps. Only validators read it;
authoritative placement is the `preview` query. The service omits the building list
when no record changed; the extension wrapper re-inserts the last list, so consumers
always see `state.buildings` plus a `buildings_changed` flag. Godot caches model
manifests and GLB existence, and `building_batches.gd` rebuilds only the batches whose
placements changed.

**Native tick cost:** 6,000 ticks (five game minutes, three pending decisions
dismissed) averaged 81 µs per tick. One 17–25 ms spike occurs at tick ~301 in every
run, where the test city raises its first native decision. Steady simulation cost does
not currently justify a simulation thread; the spike is unexplained.

**Render cost.** An offscreen probe forces draws and reads `RENDER_TOTAL_PRIMITIVES_IN_FRAME`
and wall time per forced frame (the window need not be presented). Hiding categories
showed the building MultiMesh batches account for almost all frame time (frame 11.8 ms
→ 2.0 ms without them; terrain, forest, details and all walkers together are small).
No single asset dominates: the top building type is 12% of triangles. Godot's default
four shadow cascades re-render every building four times. Adopted defaults, matched
views at the default and street distances are visually indistinguishable:

| View (M4) | Triangles before → after | Frame time before → after (paired runs) |
| --- | --- | --- |
| default, distance 33 | 7.77 M → 4.56 M | 48–60 ms → 34–35 ms |
| street, distance 14 | 7.70 M → 3.98 M | 52–62 ms → 30–33 ms |
| wide, distance 65 | 8.16 M → 5.26 M | 50–53 ms → 28–31 ms |

Settings: `sun.directional_shadow_mode = PARALLEL_2_SPLITS` in `main.gd` and
`rendering/mesh_lod/lod_change/threshold_pixels=3.0` in `project.godot`. A threshold of 6
started to thin pergolas and railings, so 3 is the conservative choice. Smaller batch
cells (12 or 6 tiles) raised triangles (5.2 M, 6.3 M at the default view), so cells stay
at 24. Imported meshes, including morph-target walkers, already carry LOD ladders
(for example a house 180,728 → 3,394 triangles).

`validate_geometry.gd` records full-detail triangles for the 240 GLBs in
`data/geometry_baseline.json` and fails if any asset above 5,000 triangles lacks a LOD
ladder, an asset lacks a baseline, or an asset grows more than 5%. Current totals: 6.0 M
triangles at full detail (0.52 M at the lowest LODs); the designated city at full detail
is 19.0 M triangles. It fails when the baseline is tampered with.

Startup to the first drawn frame is about 6.5 s (open the save 2.4 s, then terrain,
props and the first snapshot). Loaded assets use 143 MB of process memory and about
908 MB of video memory (734 MB buffers, 100 MB textures); that number is the one to
watch for the minimum-Mac gate. Regression after the changes: headless validators
passed 67, 242, 140, 18, 22, 31, 16 and 240 asset checks plus city coverage, and the
windowed EN and RU runs each passed 182. The protected save and settings hashes are
unchanged. Limits: timings were taken under contention, not on a minimum Mac or at
1080p; walker crowds, typed snapshot arrays, per-asset LOD0 budgets, video-memory
reduction and the unexplained tick spike remain open.

## Startup and video memory slice — 30 September 2026

Same conditions as the previous performance slice (M4, 16 GB, windowed Metal probe that
forces its own draws, other desktop load present). Startup is measured to the first drawn
frame; memory is `RenderingServer` video memory after the designated city has loaded.

| Item | Before | After |
| --- | --- | --- |
| Startup to first drawn frame | about 4.1 s (6.5 s in an earlier, busier run) | 1.05–1.27 s |
| Native city open (first in a process) | 2.1–2.3 s | 0.06 s (later opens 58 ms) |
| Godot first-snapshot stages | about 2.0 s | 0.87 s |
| Video memory after load | 908 MB (734 buffers, 100 textures) | 821 MB (618 buffers, 100 textures) |
| Process memory | 143 MB | 142 MB |

**Startup.** 97% of the native open was `eSmallHouse` and `eAgoraBase` constructors lazily
decoding the remastered SDL sprite PNG atlases, which this backend never draws; only the
pixel size was kept. `eTexture::load` now reads PNG/JPEG dimensions from the header when no
renderer exists (`EZEUS_DECODE_TEXTURES=1` restores the full decode). Checks: 350 textures
compared against a full decode, 0 mismatches; the freshly loaded state (all tiles,
buildings, walkers and 72 inspect/placement queries) hashes identically in both modes.
Running simulation state is not reproducible run to run even in one mode (inherited
randomness), so that comparison is not evidence. Godot then requests every model GLB on
worker threads as soon as the first snapshot arrives, so the building and walker stages fell
from about 1.2 s to 28 ms while terrain generates. Level terrain cells with no sloped
neighbour skip the shared-normal search (chunk build 0.52 s to 0.41 s); all 25,992 cells
produce byte-identical vertex, normal, colour and UV arrays in both footprint variants, 98%
take the fast path, and 40 incremental edits compare equal. `startup_timing` and
`diagnostics().open_us` expose the stages.

**Video memory.** Exact accounting of the 139 loaded assets (9.3 M vertices): pose targets
336 MB, vertices 112 MB, attributes 74 MB, indices 60 MB, shadow meshes 48 MB. Walker meshes
are about 430 MB and building meshes 265 MB. The 100 MB of textures is 35 MB of 2x MSAA, about
42 MB of the 4096 shadow atlas and the rest small; it scales with resolution and was not
measured at Retina fullscreen. `tools/optimize_glb_memory.py` merges identical morph targets
(held idle poses are 12 identical targets), naming the kept one `idle_00|idle_01|...`, and
compacts the file: 3,710 targets became 2,274 and pose memory fell from 336 MB to 220 MB.
`main.gd` resolves the aliases (and adds weights when two frames share a pose).
`tools/verify_glb_optimization.py` proves the rewrite against the backups (240 models, 577
primitives, 3,710 frames, 0 differences), and hashes of every imported mesh and named pose
matched exactly as well (0 differences), triangle counts and LOD ladders are unchanged, and
55,920 animated mesh-frames keep weights summing to one. Rendered views differ from the
earlier captures only where animation and water move.

Two tempting changes were measured and rejected. Removing unused UVs saves another 38 MB but
changed the generated LODs, and at the 3-pixel threshold it stripped the foliage from
cypresses and pergolas (seen in a crop; the tool keeps UVs unless `--drop-uv`). The
`ensure_tangents` import option changes nothing in these meshes. The real vertex counts in
the GLB are 1.8–4.4 times the manifest `vertices` (for example 151,642 against 34,642 for
`common_house_6a`); the geometry gate counts imported triangles and is unaffected.

Regression after these changes: headless 67, 242, 140, 18, 22, 31, 16 and 240 asset checks,
city coverage, and windowed EN and RU 182 each; protected hashes unchanged. Limits: one
machine under load, no minimum-Mac run; `validate_geometry.gd` currently fails for
`philosopher`, re-exported by another session during this work (9,179 to 29,114 triangles)
and not yet optimized; it needs a deliberate `--write-baseline` decision. Open: walker pose
data (220 MB) is the largest item, then building meshes; the shadow atlas is an option
(2048 saves about 42 MB with visibly coarser shadows); terrain chunk generation (0.41 s) is
the main startup cost; an asset first seen after load still costs a one-time 15–22 ms read.



## Natural people refinement — 30 September 2026

**Visual acceptance failed:** the user rejected the delivered characters as still
doll-like. The 767 checks recorded below establish technical contracts and
regressions only, not realistic anatomy, materials or motion. The replacement
single-citizen benchmark described in `GODOT_CHARACTER_ART.md` is not implemented
or verified yet. No tests were rerun for this documentation-only status correction.

The existing 31 human walker GLBs use `natural_people_v1`. This is a first
anatomical/material pass, covering 173 of the designated city's 279 initial
walkers. The other 106 are animals/boats/trailers. Female and age-specific child
anatomy, roles, props, ground anchors and the native 0.64-tile sampled gait remain.
The philosopher's wrapped blue robe follows the user's clothing reference with
natural proportions. Its outer skirt shares the tunic's drape weights, avoiding
cloth piercing during a forward step.

Final checks all pass:

| Check | Evidence | Passed |
| --- | --- | ---: |
| People geometry/materials/poses and paused native state | `captures/character-contract.log` | 66 |
| Entire development GLB catalog and sampled motion | `captures/character-assets.log` | 240 |
| Embedded simulation regressions | `captures/character-embedded.log` | 67 |
| Existing garden footprint/material contracts | `captures/character-gardens.log` | 26 |
| Imported LOD ladders and deliberate geometry baseline | `captures/character-geometry.log` | 4 |
| Visible English controls/construction/presentation | `captures/character-validation-en.log` | 182 |
| Visible Russian controls/construction/presentation | `captures/character-validation-ru.log` | 182 |
| **Total** | | **767** |

`captures/character-memory-proof.log` proves that optimization keeps all 31 models,
92 primitives and 3,220 logical morph frames byte-identical, including both UV
sets (`--require-uv`). UV stripping is rejected for character manifests because
it would erase rest-coordinate cloth detail and surface identities. Shapes still
resolve through the runtime's alias table. Every changed asset keeps an imported
LOD ladder; the normal geometry gate passes after the deliberate baseline update.

Only the 31 human assets changed full-detail triangle counts: 713,433 to 942,351
triangles across their catalog. Total catalog geometry is about 6.2 million
triangles (0.49 million at the lowest imported LODs); the actual designated city
would draw about 20.4 million at full detail. The two shadow cascades and 3-pixel
mesh LOD threshold remain. This records the cost of the added face/hand detail;
it does not establish minimum-Mac or large-crowd performance. Existing buildings,
animals, vegetation and boat models retain their current versions, including the
separately completed pose-memory optimization.

Matched captures cover seven representative assets from the front, face, rear
and a real `walk_06` pose, plus three actual native pedestrian placements: 31
views per phase. Studio portraits have the same temporary fill light in both
phases; actual city views use the normal world lighting. Enlarged Aphrodite
models use proportional portrait framing; the targeted before/after reports are
`captures/character-review-*-subjects.json`. The paused native tiles, buildings,
walkers, time and treasury stay unchanged. Final images include
`captures/character-refinement-comparison.png`, `character-after-philosopher-whole.png`
and `character-after-city-transporter.png`. `character-exports/rollout.json` records
final installed asset hashes/metadata.

Protected file SHA-256 values remain:

- Designated test save: `f1ce69f681522b1bf249b5f7792d8fb3759c644297500cf77093412219744ab9`.
- Repository settings: `71a72815007e3bb8c08a61924105755641870600d5de0327416fc2ee6bd98686`.
- Parent settings remains absent.

Building-embedded people/rowers, full skin/fabric normal-map baking, facial
animation, most authored idle movement and work/death/combat/cargo state coverage
remain pending. Gallery/read-only city checks do not establish whole-game parity,
production rights clearance or sustained performance. See `GODOT_CHARACTER_ART.md`.

## Walker pose memory slice — 30 September 2026

Same conditions as the previous slices, with heavy load from other processes (load average
8) during most runs, so absolute times are indicative; before/after pairs were taken back to
back or as the minimum of several runs.

| Item | Before | After |
| --- | --- | --- |
| Video memory after city load | 821 MB (618 buffers, 100 textures) | 568 MB (314 buffers, 184 textures) |
| Marginal cost of one walker instance | about 345 KB | about 45 KB |
| 1,500 walkers, all 38 types loaded | 1,348 MB (1,192 buffers, 156 textures) | 676 MB (400 buffers, 276 textures) |
| `animate_walker` CPU per frame, 279 walkers | 4.7 ms | 3.4 ms |
| Startup to first drawn frame (two paired runs on a loaded machine; one pair hit a load spike and is excluded) | 2.85–2.97 s | 2.66–2.69 s |

**Where the memory was.** Besides the 220 MB of morph targets, every animated walker instance
carried its own morph output buffer, about 345 KB each. An earlier test that freed the city's
walkers saw no change in the counters and wrongly suggested there was none; scaling a crowd
exposed it. At 1,000 walkers the old path would hold about 1.07 GB against about 0.6 GB now.

**Design.** `tools/bake_walker_vat.py` writes, for each source GLB with morph targets, a
runtime derivative in `models/runtime/`: the same meshes without morph targets plus
`TEXCOORD_2` = (column, row) of the vertex's texel, which Godot imports as `CUSTOM0`; one
half-float texture per model (`.vat`, 8 bytes per vertex per pose, parts stacked) and a
sidecar with the part table, frame-name to pose map and the source's size and modification
time. Godot reorders vertices on import, so the address travels with the vertex instead of
relying on order. UV and UV2 are untouched because the new character shader reads them, and
a UV index was rejected for that reason. Source GLBs and manifests are never modified, so
`validate_characters.gd`, `review_characters.gd` and any tool that reads morph targets keep
working. `shaders/walker_vat.gdshaderinc` holds the pose lookup; `walker_vat.gd` injects it
into the character shader at runtime (copying its parameters) and uses
`walker_vat.gdshader` for models with no custom shader. A derivative is used only while the
recorded source size and time still match; otherwise `model()` loads the source and blend
shapes, so a re-export never shows stale art. If a character shader defines its own
`vertex()` the model also falls back. Shadow meshes are off for derivatives because a shadow
mesh has no `CUSTOM0`. `EZEUS_NO_BAKED_POSES=1` forces the old path. The skeletal physician
benchmark added by the other session runs before this branch and is unaffected.

**Verification.** All 106 imported derivative meshes have no morph targets or shadow mesh,
unique integer texel addresses covering every vertex, LODs where large, and rest geometry
within 0.00007 of the source (static meshes store quantized positions). `validate_poses.gd`
rebuilds each model's poses from the texture and compares every distinct pose of every part
with the source blend shapes using an order-independent fingerprint: 2,278 poses pass with
a worst gap of 0.00027; swapping two adjacent poses in one file gives 0.0108 and fails
(a first version using only bounds and a second moment passed that corruption and was
replaced). Rendered A/B of the blend-shape and baked paths at five poses on seven models,
including three with the character shader, differs by a mean of 0.04–0.08% with at most 0.3%
of pixels off by more than 8%; the pairs look identical. A stale sidecar makes the game and
validator fall back as intended. Regression: headless 67, 242, 140, 18, 22, 31, 16, 240
asset, 4 geometry, 39 pose and 66 character checks, city coverage, windowed EN and RU 182
each; protected hashes unchanged.

**Crowd limit found.** Godot gives each instance that uses instance uniforms a fixed block of a
shared buffer, so the default 65,536-entry buffer ran out near 4,096 animated parts
(about 1,300 walkers, with errors). `limits/global_shader_variables/buffer_size` is now
262,144 (a few MB); 1,500 walkers (4,061 parts) then render without errors.

Limits: one machine under load, no minimum-Mac run, GPU frame time not measurably different
(triangles about 3% higher without shadow meshes). Per-walker GDScript work still scales:
animating 1,500 walkers took about 21 ms per frame under load, so crowds of that size need
a shader-driven or MultiMesh pose update. `.vat` files are not Godot resources and need an
export filter when packaging. The remaining unexplained 56 MB of extra texture memory when
every walker type is instantiated also appears on the old path and is not from poses.

## Citizen benchmark: budget, crowd level of detail and gate — 30 September 2026 (later session)

**What was verified.** The physician benchmark from the character session was unverified,
over budget and undocumented. `build_citizen_benchmark.py` now defaults to no subdivision
(30,116 vertices, was 89,000) and right-sized textures; with VRAM compression
(`configure_citizen_textures.py`) the first citizen loads in 210 ms (was 457) and costs about
0.6 MB per instance (was 1.7), textures 12.7 MB (was 56). A 5K-vertex crowd twin,
`physician_crowd`, is baked into pose textures and swapped for the nearest 24 physicians
by `citizen_lod.gd`.

**New gate: `validate_citizen.gd` (headless, read-only, 36 checks).** Rig and clips (137
bones, Idle and Walk), vertex/mesh/texture budgets and VRAM compression, blink shapes,
walk/idle loop closure, no root motion, planted-foot sliding against the 0.64 stride
(1.7%), controller determinism (equal travel gives the same pose, travel drives the walk,
idling never advances travel), the crowd model (manifest, fresh baked poses, 6,249
vertices, 1,523 baked colours, same standing height as the skeletal citizen) and the swap
manager with a stub batch loader (only the physician is substituted; nearest-first; the
pose, clock and gait carry over; hysteresis between 9 and 11.5 units; the pool never exceeds
24 and returns removed or distant walkers' models; pooled models are reused). It
found two real defects before they shipped: the imported Walk clip loops in 0.66 s but the
controller wrapped it at 0.64 s (a 3.6 cm pop each step; now seeked by cycle fraction), and
a first height comparison wrongly multiplied a skinned mesh's bounds by the node scale
(skinned meshes draw from their own vertices; a side-on render of the skeletal and crowd
models gives identical silhouettes, 0.854 high at idle and 0.828 at walk phase 0). Tamper
test: restoring the old stride mapping fails "one stride of travel is exactly one walk loop".

**Regression after the integration.** Headless: 67 embedded, 242 construction, 140
industry, 241 assets (`physician_crowd` added), 18 terrain, 22 elevation, 31 details, 16 map
polish, 26 gardens, 4 geometry (only `physician_crowd` added to the baseline: 8,434
triangles, 6,249 vertices), 40 poses (2,313 frames, worst gap 0.00027), 66 characters and
36 citizen checks, all passing. Windowed EN and RU 182 each. Protected save and settings
hashes unchanged. Two flakes, neither from this work: `validate_city_coverage.gd` failed
once on a random native `disgruntled` walker with no asset mapping (passed on two re-runs
with identical native time) and a windowed EN timing check ("held F lowers the camera
tilt") failed once and passed on re-run.

**Frame cost.** Per-walker main-thread cost is unchanged by the crowd model: 279 walkers
1.49 ms, +250 crowd physicians 2.54 ms, +500 3.54 ms, +1,000 6.13 ms (about 4.6 µs per
walker: 2.7 µs surface-height lookup, 1.8 µs animation update). An earlier 9 ms reading
for 1,000 was taken while the machine was loaded. Mobile versus Forward+ on the same city
and camera (uncapped frame time, Apple M4): Mobile about 17 ms (58 fps), Forward+ about
26–28 ms (36–39 fps), video memory 610 versus 661 MB. Forward+ stays an experiment; skin
subsurface scattering is not visible at the closest zoom (head about 26 px). Metal GPU
timestamps were unavailable, so only whole-frame figures exist.

Limits: one machine, no minimum-Mac run; visual acceptance is not established and the
hem and eye finish are known art issues, and the cloth-simulated himation replaced a flat plate after the numbers above were taken (the validators and the check counts were re-run on the rebuilt assets; see `GODOT_CHARACTER_ART.md`); only the
physician uses this pipeline; the per-walker lookup is still done every frame even for
stationary walkers.

## Foundation slice: camera, sea, replay parity, interface — 1 October 2026

**Camera.** The orbit centre now follows the terrain: `orbit_camera.gd` takes a `ground_height` callable from
`main.gd` (`terrain_height_world`, the same surface as picking), `terrain_point()` marches the cursor ray to the
surface, zoom keeps that surface point under the cursor, and the centre eases onto the ground while panning.
A claim in the first review, that a y = 0 plane anchor makes cursor zoom drift on a plateau, turned out wrong:
with a fixed camera orientation the cursor ray keeps its direction, so a plane anchor is exact at any height. The real defect
was the pivot: it stayed at y = 0, below a raised plateau, so orbiting and tilting swung around a point under the
ground. Tamper test: the old plane-anchored zoom fails "the orbit centre sits on the ground" and "stands on the
plateau" (the designated city has a level-8 plateau; the anchor itself holds in both versions). Trackpad gestures
were added (pinch zooms, two-finger scroll pans, Option + scroll orbits and tilts); only synthetic gesture events
were tested, no real trackpad. A zoom costs about 0.6 ms (a ray march is 0.13 ms). Windowed runs now pass 187 checks
(182 plus the anchor, pivot, plateau and gesture checks).

**Sea, sky and housekeeping.** `horizon.gd` adds an open sea plane just under the lowest ground in the water shader's
deepest colour, with the procedural sky as background and light fog, so the map is an island instead of a tile in a
navy void. Filmic and ACES tonemappers were compared on the designated city and both washed the sand out and flattened the
road-to-ground contrast, so the linear mapping stays. The saw-tooth map edge is the native map's diagonal tile
boundary and is not fixed. `godot/captures/` (1,286 files, 323 MB) now has a `.gdignore`; 420 generated `.import` files
and 1,080 orphaned import-cache files (294 MB) were removed and the project re-imports cleanly (`.godot/imported` 826
to 543 MB).

**Seeded replay parity (the most valuable missing test).** `eRand` had no seed (`std::random_device`), so nothing
could be reproduced. It now seeds from `EZEUS_SEED` or `eRand::seed()`. A first digest of the whole save differed
between runs even at zero ticks because the save also stores cosmetic randomised values, so `engine/estatedigest.cpp`
digests the gameplay state instead (terrain, roads, every building, every character, treasury, population, clock; sorted)
and also reports the raw save digest for information. Per-section digests then showed terrain, buildings and the economy
reproducible and only characters diverging after 10 to 30 ticks: 97 to 113 random draws per run came from path-search
worker threads, in `eGrowerAction::findResourceDecision` and `eShepherdAction::findResourceDecision`, which called the
shared non-thread-safe generator inside their per-tile filters (a data race, and a draw order that follows thread
timing). Both now use `eRand::searchCoin(salt, x, y)`, a deterministic 50% coin with one salt drawn on the game thread per
search, which keeps the same distribution. Afterwards three SDL runs agree at 30, 200 and 1,200 ticks with zero worker-thread draws,
different seeds give different digests, and the SDL executable and the embedded core produce identical digests for
0, 200 and 1,200 ticks with seeds 7 and 11. `tools/replay_parity.py` runs the comparison (`EZEUS_REPLAY` in the SDL
executable, `validate_replay.gd --print` in the embedded core); `validate_replay.gd` alone checks reproducibility, seed
sensitivity and the worker-thread counter (4 checks). Protected save and settings hashes unchanged.
Limits: the replay uses the maximum-speed stepping (five sub-steps per tick, waiting for workers each time), not the normal
paint-driven loop with asynchronous path results; one save and 1,200 ticks; random draws from other worker-thread
paths that the exercised ticks do not reach would show in the same counter. The SDL executable was rebuilt and signed
(`Bin/eZeus`); the previous one was kept in the session scratch area.

**Interface foundation.** All interface text is `tr()` keyed by its English source text, from `data/ui_strings.csv`
(one column per language; Godot's CSV import makes `ui_strings.<locale>.translation`, registered in `project.godot`);
the `ru` boolean and 135 inline `tr_pair(en, ru)` pairs are gone, a third language is one more column, and switching language
re-applies texts with `hud.retranslate()` instead of rebuilding every control. One Theme, `ui/lapis_gold.tres`
(generated by `scripts/build_ui_theme.gd`, lapis body, gold hairline, Alegreya from `assets/fonts/` with its OFL licence),
styles every control. The player interface is the scene `ui/hud.tscn` with `ui/hud.gd` (signals and setters, no game
logic), generated once by `scripts/build_hud_scene.gd` and now edited as a scene. The top bar shows date, treasury
and citizens (grouped digits, BC dates); the tile count, FPS and coverage telemetry moved to a developer overlay on F3, and the
duplicate title is gone. The windowed integration harness (about 270 lines) moved from `main.gd` to `validate_main.gd`, so
`main.gd` went from 1,341 to 1,041 lines. `validate_ui_text.gd` (7 checks) fails when a literal `tr()` text lacks a
translation, a row is orphaned, the language cycle breaks or digit grouping is wrong; tamper test: deleting the "Undo" row fails it.

**Regression.** See the figures at the end of this section.
Regression after the foundation slice: headless 67 embedded, 242 construction, 140 industry, 241 assets, 18 terrain, 22
elevation, 31 details, 16 map polish, 26 gardens, 4 geometry, 40 poses, 66 characters, 36 citizen, 4 replay and 7
interface-text checks, and city coverage, all passing; windowed EN and RU 187 each; replay parity PASS (SDL and embedded
identical at 0, 200 and 1,200 ticks for seeds 7 and 11); protected save and settings hashes unchanged.

## Playable-loop slice 1: drag roads, messages, minimap, saves — 1 October 2026

**Drag roads.** `preview_road x1 y1 x2 y2` and `build_road x1 y1 x2 y2` are new embedded-core commands. They use the SDL
view's own rule (`eGameWidget::roadPath`: `ePathFinder`, orthogonal tile steps over buildable ground that holds only roads,
no climbing of unwalkable elevation, search limited to 100 tiles), so a drag lays the same path in both builds. The preview
returns every tile with its verdict (valid, existing, or the native reason), the count and the cost: the native road cost
per new tile, existing roads free, and the native rule that building may run 1,000 drachmas into debt and then stops. Building
is one undoable step that refunds the exact cost. In the Godot view (`scripts/road_drag.gd`, wired in `main.gd`) pressing the
left button in the road tool starts a drag, the path and its cost follow the cursor, release builds it, a press and release on
one tile is the ordinary single road, and Escape, right click or leaving the tool cancels (a release over the interface is
caught by checking the held button). Headless `validate_roads.gd` (22 checks, in memory) covers path shape and
length, costs, no mutation by previews, building, finished roads costing nothing, extension charging only the new tile,
single-step undo, and rejections (blocked end, extreme or malformed input, beyond 100 tiles) never charging; the windowed
harness drives press, drag, release, Ctrl+Z, Escape, right click and a click through the real input path.
Limit: SDL-versus-Godot parity of the path is by construction (the same finder and predicate); no automated SDL drag was run.

**Messages.** Minor news (messages that only offer to be dismissed) is a toast card top left that fades after nine seconds,
holds while hovered, goes when clicked and is dismissed in the core when it goes; at most four show. Decisions stay in a box
at the top centre with the core's own choices. Every message is kept in a session log (`message_log.gd`, 300 entries,
newest first, with the game date) behind a Messages button with an unread count. Nine windowed checks use synthetic
events (no deterministic way to provoke real ones). Not done: filters by kind, saving the log with the city.

**Minimap.** `ui/minimap.gd` draws terrain, roads and buildings from the snapshot, turned 45 degrees so the native
diamond map is the upright square the default camera shows, repaints incrementally when tiles change, outlines the camera's
footprint and moves the camera where it is clicked or dragged (onto the ground). Six windowed checks.

**Saves.** The embedded service gained `set_save_directory` and `save_city`. A save is the native `.ez` file (written to a
temporary file and renamed), only into the configured directory, with names of 1 to 64 letters (any alphabet), digits, space,
`_`, `-` and `.`, never a leading dot; a city can be opened from the designated test save or from that directory only, so a session
cannot touch the designated save or anyone's own saves. The Godot side keeps saves in the per-user data directory
(`user://saves`), with a Game menu (save, load, F5 quick save, F9 quick load), a load list (newest first, selection, double click)
and three rotating autosaves every five minutes of running play. Loading restarts the scene around the chosen file so every piece
of presentation state is rebuilt from the first snapshot, keeps the interface language, and falls back to the test city with a
notice if the file cannot be opened. Evidence: `validate_saves.gd` (29 checks: written file, no temporary left, designated save
hash unchanged, ten refused names, reopened treasury, roads, clock and population, identical gameplay-state digest after a
round trip, overwrite, other alphabets, files outside the directory refused), `validate_load.gd` (14 checks: a real scene
restart, the default start still opening the test city, a broken file falling back, the live `reload_current_scene` path) and
`tools/save_roundtrip.py`: the native SDL executable opens a Godot-written save with the identical gameplay-state digest.
Limits: the presentation facing of newly placed buildings, the message log, pending decisions (saving is refused while one is
pending) and the camera are not saved; there is no delete or rename, no save preview and no scenario or campaign menu, so the
game still starts in the designated test city.

Regression after this slice: headless 67 embedded, 242 construction, 140 industry, 241 assets, 18 terrain, 22 elevation, 31
details, 16 map polish, 26 gardens, 4 geometry, 40 poses, 66 characters, 36 citizen, 4 replay, 7 interface-text, 22 road, 29
save and 14 load checks plus city coverage, all passing; windowed EN and RU 232 each; replay parity and the save round trip PASS;
protected save and settings hashes unchanged.


## Playable-loop slice 2: the Build menu — 1 October 2026

**Source of truth.** `buildable` (embedded-core command) lists 59 names from a static `buildSpecs` table: native build mode,
native type, footprint, model name, fertile/flat flags and constructor, plus the native display name, cost for the city's
difficulty and whether the city's culture supports the mode. A first version probed each name by constructing a throw-away
building; that registered buildings with the board (employment totals, scheduled city-plan buildings) and changed the
replay digest after 200 ticks, so it was replaced by static data. Asking for the list now leaves the digest at
`bce129cb831a92a7:1615:277:4487720`, the same as a session that never asked (checked in `validate_buildings.gd`).

**Menu.** `scripts/build_catalog.gd` groups the reply into nine categories and hides what has no converted model (16 native
types: podium, college, drama school, theater, mint, corral, dairy, tower, armory, chariot factory, bench, flower garden,
gazebo, bird bath and the two obelisks) and what the city cannot build (carrot and onion farms, corral, dairy, mint and
chariot factory in the test city). `ui/hud.gd` builds one submenu per category; items read "Name — cost". Names are `tr()` keys
from `data/building_names.csv` (second Russian translation, registered in project.godot), because the core's own label is in
the language the city was opened in and the interface language can change at any time; the core's Russian labels are also
abbreviated ("Оливк. пресс") and in one case wrong ("Мята" for the mint), so the menu carries its own Russian names.

**Checks.** `validate_buildings.gd`, 299 headless checks (in memory; the designated save is never written): the list is complete,
unique and well formed in EN and RU; every building is categorized, named in English (equal to the core's English label) and
translated; the menu offers exactly the 41 available entries that have a model (53 are available, 12 of those lack a model); placeholders are hidden unless requested; each
HUD item selects its tool; 40 buildings (the road has its own gate) are previewed, built for exactly the quoted cost with the quoted footprint, and undone;
the Russian menu button re-translates; the replay digest is unchanged. The windowed run gained five checks (237 per EN/RU),
and `validate_inspector_ui.gd` now drives the real submenus. A windowed capture showed a wheat farm (farmhouse on a ploughed
plot) placed through the new path.

**Regression.** Headless embedded, assets, construction, industry, terrain, elevation, details, map polish, gardens, geometry,
poses, roads, saves, load, replay, interface text and the new buildings gate pass; windowed EN and RU 237 each; replay parity
(SDL and embedded identical at 0, 200 and 1,200 ticks for seeds 7 and 11) and the save round trip PASS after rebuilding and
signing `Bin/eZeus`. `validate_citizen.gd` fails two checks (foot sliding 13 % against the 10 % limit, and a stale baked
crowd model) because `physician_crowd.glb`, `tools/build_citizen_benchmark.py` and the new `tools/citizen_gait.py` were
changed at 07:24–07:28, outside this slice's work; those need `tools/bake_walker_vat.py` and the character owner's review.

## Playable-loop slice 3: markets — 1 October 2026

**Shared rule.** The agora search (`find`: six tiles of road, then the free ground beside them, tried in four orientations around the
pointer tile; two lobes for a grand agora), the laying (`build`: road tiles keep their road but belong to the agora, the rest is taken,
the spaces are filled) and the vendor rule (`canPlaceVendor`/`placeVendor`: an empty space, one vendor of each good per agora) moved
from `eGameWidget` into `engine/eagoraplacement.*`. The SDL widget now calls it (its build cases, `canBuildVendor` and
`agoraBuildPlaceIter`); the embedded service calls the same functions for the new `common_agora`, `grand_agora` and `*_vendor` entries of
`buildSpecs` (a `Kind` of standard, agora or vendor). The previews list unique tiles (the grand agora's two halves share one road strip):
18 tiles for the common and 30 for the grand agora. A vendor preview outlines its 2x2 space and answers `needs_agora_space`,
`occupied` or `vendor_exists`; any tile of a space picks it, where SDL needs the exact centre tile (the result is the same state).
Undo takes a whole agora, or a vendor, and restores the space. Wine, arms, horse and chariot vendors are listed but hidden (no model).

**Checks.** `validate_buildings.gd` (now 373 headless checks): sites exist, previews are free of side effects and quote the real cost,
the agora and its three or six spaces appear in the snapshot as `agora_space` 2x2 buildings, a second agora on the same road is refused,
undo restores money, buildings and roads exactly, a food vendor replaces a space for the quoted cost, an agora takes one vendor of a
kind, a stall reads in the inspector and the city runs 300 ticks with it. The windowed run gained a market regression through the real
interface (Build menu, pointer, clicks, 245 checks per EN/RU) and a capture, `godot/captures/market-<lang>.png`: a food stall and an oil
stall beside a paved empty space. Menu: 46 buildings in ten categories (61 with placeholders); every vendor and agora has Russian text.

**Regression.** All headless validators pass (including `validate_citizen.gd` at the other session's current gait); replay parity
and the save round trip PASS after rebuilding and signing `Bin/eZeus` with the refactored widget; protected save and settings unchanged.
Limits: the agora has no model of its own (its road and spaces are the picture), the plaza is a flat pale square rather than the
remastered paving, and nothing yet tests the SDL agora path other than that it compiles from the same functions.

## Playable-loop slice 4: start menu and new games — 1 October 2026

**Core.** `engine/eadventurelist.*` (the SDL menu's two scans and `readPakGlossary`, moved out of the widget and shared) lists 26
adventures: the engine's own campaigns and every `.pak` under `Adventures/`. The service split `open()` into `prepare` (directories,
language, textures), the save read and `enter` (board, map extent, handlers, first snapshot), and added `adventures`,
`openAdventure(kind, ref)` and the `episode` query. An adventure opens only if it is in the listing, so a path or folder name from
anywhere else is refused. A new city focuses on the middle of the player's own land (saved cities keep focusing on their houses).
All 26 open in 40 to 400 ms, paused, with 14,792 to 92,700 tiles, a treasury, a title, objectives (0 to 4), no buildings and no
placeholder, and room to build near the starting view.

**Menu.** `ui/start_menu.tscn` (generated once by `scripts/build_start_scene.gd`, then edited as a scene) is the main scene. Pages:
main, adventures, introduction, load. Start reads the campaign (about 0.3 s) and shows the first episode's title, story and
objectives; Begin passes the opened simulation to the city scene (`core_link.adopt`), so it is read once. Automation flags skip the
menu, so every validator and review is unchanged. The launcher no longer forces English: the menu opens in the player's last language
(`user://settings.cfg`).

**City.** `ui/hud` gained the objectives panel (title with `met / total`, ticks, live status, fold-away), the Main menu entry behind a
confirmation, and the result card for a finished episode (victory text from the adventure, or defeat). The panel reads the `episode`
query every two seconds and toasts a newly met objective. The test city carries a real episode (four objectives, one met), so the
windowed run covers it.

**A bug the new flow found.** The binding cached the building list from any answer that had a `buildings` key, so after the build menu's
`buildable` query a paused city whose buildings had not changed returned the 59 menu entries as its buildings (the test city hid it
because its animation offsets change buildings every snapshot). The cache is now filled by snapshots only; `validate_buildings.gd`
checks a quiet snapshot after the query.

**Checks.** `validate_adventures.gd` (12 headless): the listing, every adventure opens as above, three saved games reload to the same
state, foreign paths refused, Russian lists the same adventures (18 with Russian titles), the designated save untouched.
`validate_start.gd` (34 headless) drives the real scenes: Continue and Load are off with no saves, language switching, the list,
Start and Back (the simulation is released), Begin, the new city (paused, empty, four objectives, build menu), a road, quick save,
Main menu with its confirmation, Continue reopening the save, the load page, Russian titles. Windowed EN/RU 253 each (objectives panel and
menu entry added). `tools/save_roundtrip.py` now also opens a new-game save of The Founding of Athens in the SDL build: identical state
(`e2d3f12621217354:0:0:0`). Replay parity PASS; all headless validators pass; protected save and settings unchanged.
Captures: start menu main page, list and introduction in EN and RU; an adventure city with its objectives and result card.

**Limits.** The next episode and colonies need the campaign interface (the world map), so a finished episode ends at the menu; the
player's name in messages is still the test leader's; adventure previews (the pictures) and the menu's 3D backdrop are not ported;
the menu and its pages have no keyboard focus ring styling beyond the theme; there is no delete or rename of saves.

## Playable-loop slice 5: overlays — 1 October 2026

**Core.** `overlay <id>` (25 ids, the normal view included) answers from the native rules: the visible building ids and walker kinds
(`eViewModeHelpers`, so the filters cannot drift from the SDL view), the per-house value columns with their tone (the values and
thresholds of `drawBuildingModes`: hazards `(100 - maintenance) / 15`, taxes paid or not, water `/ 2`, hygiene and unrest `/ 15`, the
culture and science house values), the supplies of each house (three goods, six for palaces) and, for appeal, one character per tile
(`0`-`9` the core's rating, `a`-`j` on houses, `.` for none). A query takes about 0.25 ms (appeal about 1 ms) and changes nothing.

**Godot.** `scripts/overlays.gd` (catalog), `scripts/overlay_view.gd` (columns and markers as MultiMeshes, the appeal Decal with the
grid as a texture whose rows run from the far edge), HUD Overlays menu with Culture and Science submenus, a legend line, hotkeys as in the
SDL game, Escape returns to normal. Hidden buildings are not removed: the batches are rebuilt with them as thin footprints, so
selection, placement and the snapshot are unchanged. Columns start above each building's roof (from its model contract). A tax
column of zero is drawn as a short red stub (the SDL game draws a green column of no height). Names and legends are in English and
Russian (the ten original overlays use the SDL game's Russian names).

**Checks.** `validate_overlays.gd` (59 headless): all 25 answer, an unknown id is refused, every id belongs to a snapshot building, the
filters keep every house and hide unrelated buildings, one column per inhabited house, supplies list three or six goods, tones and walker
kinds are as expected, the appeal grid covers the map and marks every house, the replay digest is the same whether or not every overlay
was queried, and a new empty city answers. The windowed run gained 17 checks (270 per EN/RU): the 1, 2, 4, 5, 6, 0 and Tab keys (Tab and 4
through the real input pipeline), the menu and its submenus, hospital flat under the water overlay, walkers filtered, columns, markers,
the decal, the legend, language, Escape, plus captures `overlay-{hazards,appeal,water}-<lang>.png`.

**Limits.** The SDL "patrol" coverage view and the per-building coverage on hover are not ported; the plain footprint slab is dark grey and
hides what a hidden building was; the appeal decal is as sharp as a block of pixels per tile, not a texture per tile; overlays are not saved.

## Playable-loop slice 6: sound — 1 October 2026

**Source and route.** The game's `Audio/` folder is read at run time: 700 WAV effects and ambient sounds (22 kHz 16-bit, loaded in half a second
by `AudioStreamWAV.load_from_file`), 29 MP3 tracks and the 900 voice lines. The native sound manager already chose files through
`eSoundVector::play`, which returned at once in the embedded core. It now hands the path to a sink the service installs; the service
reports the paths in the snapshot (`sounds`), the music mode (`music`) and answers `ambient x y` and `building_sound x y` with the native tables'
choice. `eSounds::load()` (file names only) runs when a session is prepared. Placing anything but a road also plays the native
building-placed sound.

**Two native defects fixed on the way.** (1) The simulation asks for battle or peaceful music through `eMusic` statics that dereferenced a
missing object in the embedded core, so an invasion (the Trojan War, for one) would have crashed the Godot game; they are now null-safe and
report the mode instead. (2) Choosing which of several sound files to play drew from the simulation's random generator in the SDL game but
not in the embedded core (it returned before the draw), a latent replay-parity gap that any fire or quarrying sound would have opened.
Sound and music choices now use `eRand::cosmetic()`, outside the simulation state. Replay parity is unchanged (identical digests at 0, 200
and 1,200 ticks for seeds 7 and 11) and asking for ambient or building sounds leaves the replay digest unchanged.

**Godot.** `GameAudio` autoload: four buses plus master with per-user volumes and mute, an effect pool of 14 voices with a 0.12 s repeat
guard, cross-faded music (title loop, random city tracks that never repeat at once, battle tracks, the mission and victory cues), voices
that follow the interface language with an English fallback, every button clicks, ambient sound drawn from the middle of the view
whenever nothing else is audible (about every four seconds, as in the SDL game). The Game menu's Sound… and the start menu's Sound button open the volume
dialog; M mutes. The start menu plays the title tune, and a campaign's recorded introduction (14 of 26 adventures have one) or the mission
fanfare plays on the briefing page.

**Checks.** `validate_audio.gd` (31 headless): the autoload and the Audio folder, all 700 effects and every music track and cue load, voice
folders by language, 52 different sounds from 400 ambient queries with both layers and every file present, building clicks, silence for
roads and the place sound for buildings, one-time delivery, the replay digest unchanged, the voices of adventures, routing to the buses,
the repeat guard, button clicks, menu, city and battle music (no immediate repeats), the cue, volumes and mute on the buses and remembered
in a scratch settings file. `validate_start.gd` gained five (the title tune, the Sound button and dialog, the briefing's voice or fanfare,
the tune returning). The windowed run gained nine checks (279 per EN/RU) with the manager enabled and the master bus muted: city and battle
music from snapshots, native sounds on their buses, a building click, ambient from the view, the M key and the dialog's sliders.

**Limits.** Sounds are not positional (as in the SDL game, they play whole); there is no ducking of the music under a voice line; the weather
sounds and the front end's thunder are not ported; nothing audible can be verified by these gates, only what was asked to play and on
which bus, so the mix and loudness need a listening pass; the files are read from the workspace (the production package will need them
bundled).

## Playable-loop slice 7: campaign flow — 1 October 2026

**Core.** `detach()` lets go of a running city but keeps the campaign; `finish_episode`, `preview_episode`, `choose_colony`, `begin_episode`,
`set_aside` and `difficulty` follow the SDL main window (`episodeFinished`, the colony selection, `startEpisode`, the goals window's
button, the briefing's difficulty arrows) on `eCampaign` itself, so the campaign's own rules decide the order of episodes. The episode query
gained the victory and defeat flags, the episode number and count (`episode_number` / `episode_count`; an early version reused `total`, which
already meant the goal count), the difficulty and, per goal, its index and whether goods can be set aside (the stores are totalled first, as the
SDL window does). Moving to another board re-enters the session (new map, handlers, caches) and writes "autosave replay". `test_win` and
`test_stock` exist only after a validator calls `enable_test_commands()`.

**Godot.** `ui/episode_card.tscn` (one card, five modes: briefing, victory, colonies, adventure complete, defeat) is used by the start
menu's briefing page and by `ui/episode_overlay.tscn`, which covers the city and drives the commands. The city restarts and adopts the same
simulation when a new episode begins (`switch_session`); the defeat card's retry loads "autosave replay". The objectives panel has the
"Set aside" button; voices and fanfares play for briefings and results. The old end dialog was removed.

**Checks.** `validate_campaign.gd` (26 headless): commands are refused before they are due and after they were used; test commands are refused
unless enabled; difficulty (cost 2 beginner, 7 olympian) is applied and range-checked; goods are set aside only when sixteen are in store;
winning stops the game; the colonies on offer, an invalid choice, no start before a choice; a colony is another map, saved and resumed mid-way
with the same objectives, and finishing it returns to the second parent episode with the road built in the first and the same difficulty; the
treasury carries over; all 26 adventures are played to their end through 135 episodes (21 visit colonies). `validate_campaign_ui.gd` (21
headless) drives the real scenes through the same story (menu briefing with difficulty, set-aside button, defeat card and retry, victory,
colonies, colony briefing, the colony city, return to the parent, the end, back to the menu). Windowed EN/RU 282 each (the host checks). Replay
parity and the save round trip PASS; protected files unchanged; scratch folders are removed, and no test touches the player's settings or saves.
Captures of the briefing, victory, colony choice, colony briefing and defeat cards in both languages were reviewed.

**Limits.** The colony is chosen from a list, not the SDL game's world map (names only: no attitudes, trade or military info); requests, gifts
and the world map's other uses (raids, conquest, trade between cities) are still absent; the card does not show the goods already set
aside for the colony or the gifts waiting there; the briefing's difficulty arrows are plain buttons.

## Playable-loop slice 8: trade posts and piers — 1 October 2026

**Shared rules.** The partner list (`eTradePartners::available`) and the shore rules (`eShorePlacement`: tile buildable, the fishery's shore fit,
water that leads to the sea, the pier's 4x4 land, laying a pier with its trade post) moved out of the SDL game widget and menu, which now call
them, so the embedded core cannot disagree about who can be traded with or where a pier fits. Across the 26 adventures the core lists 110 partners at the start (the survey counts): 109 are
available and 66 are by sea (the Founding of Athens has only sea partners).

**Core.** `trade_post` and `pier` joined the build table (`Kind::trade`); `preview` and `build` take the partner; the preview of a pier covers the
pier and its post (20 tiles) with reasons `not_on_shore`, `no_sea_access`, `blocked_terrain` or `trade_partner_unavailable`; both are charged as a
trade post. New queries: `trade_partners` (every candidate, its goods, prices, use of the yearly limits, whether a post stands there) and, in `inspect`,
a `trade` object for a post; new command `trade` (resource, import or export, on or off, quota) with the SDL panel's quota steps and the usual stale
token and ownership checks. The snapshot gives a pier its facing. A probe showed the native traders and donkeys arriving at a new post.

**Godot.** The Build menu gets a Trade category from the partner list; the pointer finds a fitting shore tile within two tiles for a pier;
the post's panel replaces the raw store orders with the partner's goods and the quotas; Game, Trade partners… opens the overview. New strings in
English and Russian. The scratch save folders of the windowed validation (30 empty ones had accumulated) are now removed at the end of the run.

**Checks.** `validate_trade.gd` (36 headless): partners and their goods, refusals (no partner, unknown partner, land post for a sea partner and the
reverse, a second post, a pier inland), cost and footprint, build, undo (refund, partner freed after a step), the panel and orders (quota steps,
range, stale token), demolition (the post takes its pier with it), a pier facing and sea post, the test city's four posts. `validate_trade_ui.gd`
(18 headless) drives the real scenes through the Founding of Athens (the Trade category, a pier, snapping, the click, the partner leaving the menu, the
panel, Apply, undo) and the Peloponnesian War (a land post). Windowed EN/RU 285 each (the partners dialog, the post's panel). Replay parity and the save
round trip PASS after rebuilding and signing `Bin/eZeus` with the refactored widget. Captures show the pier with its post on the shore, the panel and the dialog.

**Limits.** The two-way trade with one's own colony is listed but untested end to end; the quotas shown ("this year 0 of 12") are the partner's yearly
limits, not what the player has traded in the SDL ledger; there is no way yet to stop all land or sea trade (the city-wide shutdown); the Russian partner
names follow the core's language; the pier's model facing was checked against one shore only.

## Playable-loop slice 9: walls, towers and gatehouses — 1 October 2026

See `GODOT_MIGRATION.md` for the design. Results: `validate_walls.gd` **63** headless checks; `validate_buildings` 397 (was 379); `validate_assets` 244 (was 241: tower,
gatehouse, archer); `validate_geometry` PASS after recording exactly the three new assets (gatehouse 3,588 triangles, tower 1,260, archer 29,083 like the other
walkers); `validate_saves` 32 and the SDL save round trip PASS with a wall line and a gatehouse in the saved city; replay parity PASS (all six runs, SDL and
embedded digests equal) after rebuilding and signing `Bin/eZeus` with the gatehouse change; windowed EN/RU **301** each (285 plus 16 for walls, the gatehouse and
the models). The rest of the headless set (gardens 26, map polish 16, terrain 18, elevation 22, details 31, embedded, construction 242, industry 140, city
coverage with no missing model, poses, citizen 38, replay, ui text 7, roads 22, load 14, adventures 12, start 39, overlays 59, campaign 26/21, trade 36/18)
is unchanged. Captures: the wall drag with its ghost pieces, the built rectangle with a tower and a gatehouse, and an archer's shadow on a tower.

**Probes worth keeping.** A building that employs workers (tower, tax office, watchpost) makes a saved-and-reloaded city differ from the live one in the state
digest, with the building records equal except for the worker counts: after the reload the vendors and storehouses have one more worker each than in the live
city (observed with a watchpost; 7 buildings differ). The cause is not yet found (it may lie in the employment distribution or in what a save keeps of it); it is the same
with ordinary employers, so the strict save comparison avoids them. `validate_audio` failed once among six runs while four validators ran in parallel ("asking for ambient and building sounds
leaves the replay digest unchanged") and passed in four parallel reruns and alone; it is treated as a rare flake of the worker threads under load until it
recurs.

## Playable-loop slice 10: elite housing and area drags — 1 October 2026

See `GODOT_MIGRATION.md` for the design. Results: `validate_housing.gd` **30** headless checks; `validate_buildings` 403 (was 397); `validate_assets` 254 (was 244: ten estates);
`validate_geometry` PASS after recording exactly the ten new assets (61,000 to 65,000 triangles each); `validate_saves` 34 and the SDL save round trip PASS with four mansions
and twelve parks in the saved city; replay parity PASS (SDL and embedded digests equal in all six runs); windowed EN/RU **319** each (301 plus 18). The rest of the headless set
is unchanged (see slice 9). Captures: a review scene with the ten estates.

**Probe worth keeping.** The first windowed run of the new drag checks failed for the park drag only, and differently from run to run: `main.gd`'s per-frame pick from the real
mouse moved the end of the drag the test was driving whenever the real cursor sat over the game view (the earlier drag tests passed by luck of that position). The pointer pick is
now skipped while a drag runs with `road_drag.guard` off.

## Playable-loop slice 11: the remaining vendors — 1 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_buildings` 421 (was 403); `validate_assets` 258 (was 254); `validate_geometry` PASS after recording exactly the four new assets;
`validate_city_coverage` PASS with no missing model; windowed EN/RU **321** each (319 plus 2). The earlier windowed English run of this slice failed three early checks
("native city starts paused", the held-F camera tilt, "orbit and picking do not advance paused simulation") while the owner's own game session was running on the same Mac and
three headless validators from earlier script errors were still alive; it passed on the rerun after those stale processes were stopped, so those checks may be load-sensitive (not confirmed).

## Playable-loop slice 12: the last building models — 1 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_buildings` 487 (was 421); `validate_assets` 273 (was 258: fifteen models); `validate_geometry` PASS after recording exactly the fifteen new assets
(the largest, the theater, 69,416 triangles); windowed EN/RU **343** each. Between my windowed runs the count rose by 20 without any check of mine, together with changes to `ui/hud.gd`,
`ui/building_thumbnails.gd`, `ui/hud.tscn` and `scripts/main.gd` that I did not make (another session was editing the Build menu in the same checkout: it left `building_thumbnails.gd`
uncompilable for a few minutes, which showed as a script error in one `validate_buildings` run that still reported its checks as passing). The held-R/F camera-tilt checks failed in one windowed
run and passed on the next, the known load-sensitive pair.

## Playable-loop slice 13: the world map — 1 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_world.gd` **32** headless checks; windowed EN/RU **359** each (343 plus 16; the world checks and one updated Game menu count); the rest of the headless set and replay
parity and the SDL save round trip are unchanged (see slices 9 to 12).

**Probe worth keeping.** Asking a city for goods lowers its regard by 20, not 10: `eGameBoard::request` takes 10 from every city on the map that is not the current one (the asked city included) and then 10 from the asked
city again. The SDL dialog calls it as it is, so the Godot screen does too, and its note says "every city's regard falls by 10 when you ask, and this city's by 10 more".

## Playable-loop slice 14: the army — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_army.gd` **35** headless checks; windowed EN/RU **384** each (359 plus 25 army checks; the Game menu count check now expects 11 entries); `validate_assets` 279
(273 plus the six soldiers); `validate_geometry` PASS after recording exactly the six new assets (the diff against the old baseline shows only additions); `validate_characters` 80 checks with the refined-walker count
corrected to 38 (it expected 31 and had been failing since the archer was added: a hard-coded count, not a model fault); `validate_walls` accepts either archer model. The rest of the headless set (embedded, gardens, map polish, terrain, elevation,
details, construction, industry, city coverage with no missing model, poses, citizen, replay, UI text 7, roads 22, saves 34, load 14, adventures 12, start 39, overlays 59, audio 31, campaign 26 and 21, trade 36 and 18,
buildings 487, walls 63, housing 30, world 32, building activity 171), replay parity (SDL and embedded digests equal) and the SDL save round trip pass. `validate_locomotion.gd` does not compile when run headless
(`GameAudio`, an autoload, is not available to a bare `--script`); I did not touch it and did not establish whether it is meant to run another way.

**Probe worth keeping.** Orders to the army must be preceded by what a tick does first (finished path tasks, discarded characters): without it, call out, send home and call out again with no tick in between crashes the process, and
`validate_army.gd` is built so that it would. The called-out soldiers of the housing-supplied companies appear at once, at the houses that supply them, so a test that checks soldiers right after an order needs no time to pass; the
campaign's own decisions block the clock, so anything that lets time pass answers them with `event <id> <choice>` (the validator does, and keeps that part last).

## Engine event words: the monthly summary and the early warnings — 2 October 2026

**Symptom.** After a game month the Godot city showed a toast titled with the raw event name ("MonthlySummary") and an empty body.

**Cause.** The embedded service's event handler (`presentation/esimulationservice.cpp`) takes a title and text from the game's message catalogue (`eEventMessage`, `eeventmessages.h`) and, when an
event has none, falls back to the event's name and `eEventData::fReason`. The three events the engine raises itself have no catalogue entry: `eEvent::monthlySummary`, `shortageWarning` and `riskWarning`
(`eBoardCity::nextMonth`, `warnShortages`, `warnRisks`). The SDL view words them in `eGameWidget::showMonthlySummary` and `eGameWidget::handleEvent` from `text/language*.txt` and the city's history, so the SDL game
was never affected. The shortage and risk events reached Godot the same way (their `fReason` is empty or a building name).

**Audit (which events arrive without words).** `event_texts` (validators only) lists them: of 338 event kinds 230 have a catalogue message, 3 are now worded by the core, and **105 still arrive with the raw
event name and no text**. They are the kinds the SDL view words in its own handlers from god, monster, hero and city data: gods (`godVisit`, `godInvasion`, `godHelp`, `godQuest`, `godQuestFulfilled`,
`godMonsterUnleash`, `sanctuaryComplete`, `godDisaster`, `godDisasterEnds`, `godTradeResumes`: 10), the 15 pyramid, monument, shrine and sanctuary completions, `heroArrival`, the monster timeline (8) and the
invasion timeline with `playerInvasion` and `playerGodAttack` (8), and the comply / too-late / refuse replies of the general-request, famine, project, festival, financial-woes and tribute requests (63).
Their texts need the god, monster, hero or requesting city that `eEventData` carries, and several have decision buttons, so they were left for their own slice (the military ones with the fighting).
The audit is the first place to look before adding a toast for one of them.

**Fix.** `presentation/eenginemessages.h` words the three events in the core's language with the SDL view's own keys, English fallbacks and figures; the handler calls it before the catalogue
(`eEngineMessages::handles`). Nothing in `engine/` or `widgets/` changed, and the SDL text is untouched: the two places are kept in step by comment and by the validator, which reads the SDL tables.
- Monthly summary: "<Month> in review" (`summary_title`, the month that ended, prefixed by the city's name when the player has several), then `Population N (+d)`, `Treasury N (+d)`, `Food N (+d)  ·  Unrest N%`
  from the city history's last two samples, as the SDL card (`summary_*` keys). Like the SDL card it needs two consecutive monthly samples, otherwise it says nothing. The SDL card's icon, tone and "click for the history"
  line, and its Settings switch (`monthly_summary`), are not carried over: the Godot toast has a title and a body, there is no Godot city-history window yet, and the card shows every month (the SDL default).
- Shortage: "Running low: <goods>" or "Treasury running low" with the stock and the months left (`warn_*`). Risk: fire, collapse (names the worst building) and rising unrest with its percentage (`risk_*`).
  The English "1 more months" of the SDL table is carried over as it is.
- Two validators-only commands, behind `enable_test_commands()` like `test_win`: `test_event shortage <resource> <stock> <months>` / `test_event risk <kind 0-2> <count> [x y]` raise the event through the board's own
  `event()` path with the fields the monthly check fills in, and `event_texts` is the audit above. The game never calls them.

**Checks.** `validate_embedded.gd` **101** (67 before; +17 for each language): the audit lists the three engine kinds as worded; each warning's title and text equal the SDL table's template filled with the figures
(goods, treasury, fire with and without a building, collapse with and without, unrest) in English and Russian; malformed test events are refused; and a **real month** (replay to the next month end, 23 rounds of 100 ticks)
brings a new summary card whose title fits the SDL template, with three lines naming population, treasury, food and unrest in the language's words, each figure with its change, population and treasury equal to the snapshot's
(gaps 0 and 0), only a dismiss action and no raw event name. Example, English: "February in review: Population 1920 (0) / Treasury 1911797 (-388) / Food 0 (-8)  ·  Unrest 0%"; Russian: "Итоги месяца: Февраль: Население 1920 (0) / Казна 1911797 (-388) / Еда 0 (-8)  ·  Беспорядки 0%".
Also run after the change and passing: `validate_replay.gd` (200 ticks), `validate_campaign.gd` 26 and windowed EN **384** / RU **384** (unchanged from the army slice: the harness uses synthetic events for toasts).
The extension was rebuilt and signed with `tools/build_godot_extension.sh`. No simulation code changed, so `tools/replay_parity.py` was not rerun and the SDL executable was not rebuilt.

Limits: the visible toast was not captured as an image (the windowed harness feeds the toast path synthetic events); the real-month check covers the data it shows. The 105 kinds above are still unworded. Population and treasury in the
summary are compared with the snapshot after up to 100 further ticks (they matched exactly in both languages here; the check allows a small gap, so it is not a bit-exact proof of the figures).

## Playable-loop slice 15: fighting — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_fight.gd` **31** headless checks; windowed EN/RU **394** each (393 plus the notice's button check; the nine fight checks run last); `validate_assets` 325 and `validate_characters` 172 checks (84 refined walkers) with the combat clips accepted;
`validate_poses` 9,445 frames; `validate_geometry` PASS after recording the 46 new models (the five existing ones that were exported again changed by under 1 percent of their triangles); the rest of the headless set (embedded, gardens, map polish, building activity, terrain, elevation, details,
construction, industry, city coverage with no missing model, citizen, replay, UI text 7, roads 22, saves 34, load 14, adventures 12, start 39, overlays 59, audio 31, campaign 26 and 21, trade 36 and 18, buildings 487, walls 63, housing 30, world 32, army 35), replay parity and the SDL save round trip pass. The shared engine was not
changed, so the SDL executable was not rebuilt. `validate_locomotion.gd` still does not compile headless (`GameAudio`), as before.

**Probe worth keeping.** A headless run with no soldier of the player's in sight is how the engine's rule showed: `updateCityDefense` calls companies out for computer-controlled cities only. If a future test expects the army to defend by itself it will fail for that reason, not because of the presentation.
A second probe: a one-line fight check on a soldier's pose indices is not enough to know the clip looks right; the first export had every fighter bare-handed (the props the walk hides were not part of the model), which only a picture of the fight frames showed. Roster sheets of all 33 soldiers and the fourteen
Olympians in walk and fight frames were rendered and looked at (`godot/captures/soldiers-fighting.png`, `gods-fighting.png`), and a battle in the live city (`battle-invasion-en.png`).

## Playable-loop slice 16: the world map's military dealings — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_military.gd` **49** headless checks; windowed EN/RU **410** each (394 plus 16); the rest of the headless set (embedded, assets 325, gardens, map polish, building activity, characters 172, fight 31, terrain, elevation, details, construction, industry, city coverage with no missing model, geometry, poses, citizen,
replay, UI text 7, roads, saves, load, adventures, start, overlays, audio, campaign, trade, buildings 487, walls 63, housing 30, world 32, army 35), replay parity and the SDL save round trip pass. The shared engine was not changed (the SDL executable was not rebuilt). Two strings that the new code no longer used were removed from the interface table (the orphan check of `validate_ui_text.gd` found them).

**Probes worth keeping.** (1) The test world has only allies, so every dealing is tried on an ally (raiding an ally is allowed by the SDL menu's rules and the engine reports the consequence), and a rival is made with `test_relationship`. (2) The engine's own troop request event needs its attacking city set (`setAttackingCity`): without it `eTroopsRequestEvent::dispatch` passes a null city
to `requestForces` and the process crashed in the test; real events set it. (3) The housing removes test hoplites quickly once time runs, so a test that needs companies adds them right before it enlists them, while the clock is held (by a paused city or a pending decision). (4) Lambdas capture locals by value: the raid test's watch lives in a dictionary, and a first version that
did not saw nothing happen. (5) Windowed runs under heavy load (another session was running its own tests) showed a flaky "fallen soldier" fight check once; it passed on the next run.

## Playable-loop slice 17: monsters — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_monsters.gd` **34** headless checks; windowed EN/RU **420** each (410 plus 10); the rest of the headless set (embedded, assets with 342 models, gardens 26, map polish, building activity, characters 188 for 92 human-bodied assets, fight 31, terrain, elevation, details, construction, industry, city coverage with no missing model, geometry, poses, citizen, replay, UI text 7, roads, saves, load, adventures, start, overlays, audio, campaign, trade, buildings 487, walls 63, housing 30,
world 32, army 35, military 49), replay parity and the SDL save round trip pass. The shared engine was not changed (the SDL executable was not rebuilt). The geometry baseline gained exactly the 17 monster assets. Roster sheets of all seventeen monsters in walk and fight frames and the monsters in the live city were rendered and looked at (`godot/captures/monsters-*.png`).

**Probes worth keeping.** (1) A white Cerberus: the animal kit paints coats as a per-point `Coat colour` attribute, which the exporter did not read for non-human assets; the materials themselves are neutral. A model that renders white in the plain finish has lost its vertex palette. (2) The hydra is a land monster (`eBasicMonster`); only the kraken and Scylla are `eWaterMonster`s (my first test placed the hydra in the water). (3) The harpies fly:
their lowest point is about half a metre above the ground, so the ground-anchor check of `validate_characters.gd` is replaced by a hover check for them. (4) A monster that was placed with `changeTile` and given its action runs by itself in the test world: a Cerberus found something to fight in the test city within the validator's loop (at speed 3).

## Playable-loop slice 18: the words of gods, monsters, heroes, invasions and requests — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_events.gd` **45** headless checks (English and Russian); `validate_embedded.gd` now requires `event_texts` to list nothing (the 105 unworded kinds of the earlier audit are down to none: 103 worded in `presentation/eeventwords.h`, two silent alerts); windowed EN/RU **426** each (420 plus 6); the rest of the headless set (assets 342, characters 188, fight 31, monsters 34, military 49, army 35, geometry, poses, replay, UI text 7, ...), replay parity and the SDL save round trip pass. The shared engine was not changed.

**Probes worth keeping.** (1) The SDL god-visit counter (`eGodMessages::fLastMessage`) runs wooing, jealousy, jealousy, then jealousy again before wooing, so four visits say three things and a test must not expect three visits to differ when the counter starts at its last step. (2) A chimera's attack warning names its reason twice; the SDL view replaces only the first and leaves a literal `[reason_phrase]`. (3) An invasion warning for twelve months says "in one year": a test must not look for the number.
(4) `godTradeResumes` is silent for every god but Zeus, Poseidon and Hermes, as in the SDL view. (5) The raised events need a city for `[city_name]` and `[leader_name]`: `test_raise ... city <index>`; the game's own events carry theirs. (6) A first survey of the unworded kinds reported 212 "empty" results that were the survey's own freshness test, not missing words: compare the event id with the last one seen.

## Playable-loop slice 19: heroes' halls — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_heroes.gd` **66** headless checks (English and Russian); windowed EN/RU **439** each (426 plus 13); the rest of the headless set (embedded, assets 348, characters 188, fight 31, monsters 34, events 45, military 49, army 35, buildings 487, ... ), replay parity and the SDL save round trip pass. The shared engine was changed once (the melee range of `eHeroAction::fightMonster`) and the SDL executable rebuilt and signed; it starts (`art/menu/shot.sh`). The geometry baseline gained exactly the six new halls.

**Probes worth keeping.** (1) A hero hunting a monster was the only place a test could freeze the city (fixed in slice 20 with a second change to `eheroaction.cpp`, see `GODOT_MIGRATION.md`): the engine's path searches run on worker threads and the service waits for them each tick, so a hunt that never ends shows as one slow `advance` after another (a `sample` of the process showed `huntMonster` queueing `ePathFindTask`s). Bound such a loop by wall-clock time in a validator and seed it (`core.replay(0, seed)`): the outcome of a fight is a matter of random draws. (2) The test city's halls of Atalanta and Theseus are
built and not offered; the other six are not allowed by the scenario, so `test_allow` or a quest (`test_quest hades 1` allows Perseus) is how a test gets a hall. After the windowed run's battles other halls are offered again (the invaders destroy buildings), so a check must not expect the group to hold only one hall. (3) A god's quest names a default hero (`eGodQuest::sDefaultHero`): Hades' first quest asks for Perseus. (4) `validate_fight.gd` failed once in a full run that was sharing the machine with a geometry run and passed twice alone and in the next full run.

## Playable-loop slice 20: the gods' sanctuaries — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_sanctuaries.gd` **71** headless checks (English and Russian); windowed EN/RU **502** each; the rest of the headless set (embedded, assets 362, characters 188, fight 31 with its retries, monsters 34, events 45, heroes 66, military 49, army 35, buildings 487, UI text 7, ...), replay parity and the SDL save round trip pass. The shared engine was changed once more (`eheroaction.*`) and the SDL executable rebuilt, signed and started. The geometry baseline gained exactly the 14 new models.

**Probes worth keeping.** (1) `test_stock 1 ...` stocks urchins: marble is `32768`, wood `8192`, sculpture `131072` (the resource enum is a bit set). (2) A sanctuary's carts need a road beside the footprint (`WARNING: This building needs access to a road` and no progress): a test site must touch a road, and the first valid site from the tile list often does not. (3) The scarce marble of the test city (32 slabs, no room for more) means the Grove of Dionysus (8 + 20) completes and the Pillar of Zeus (48) is refused with `need_marble`. (4) An ally request left pending refuses itself,
and every refusal lowers the regard: after enough game time no ally can be enlisted, so a check that needs one sets the regard first (`test_attitude`). (5) A stalled-looking run is often a decision pending (the city is paused and every building command is refused with `pending_decision`): answer the events first. (6) A flaky headless validator can hide a real engine bug: the hero hunt's infinite loop first showed as an occasional timeout of the suite and was reproduced only by running the validator eight times in a row with a watchdog (`perl -e 'alarm N; exec @ARGV'`), then sampled (`sample <pid>`) and instrumented. (7) The first fight validator
run in a suite failed again after a window of passes: one battle in five has no death; measure a flaky check's rate before blaming the last change.

## Sanctuary facing: temple and gods look to the front — 2 October 2026

**Symptom.** In the placement ghost and in the built city the gods' statues looked toward a corner of the footprint and the temple stood across its sanctuary: each 4x4 temple piece was a whole temple with its ridge along the short axis and its pediment toward a long side, so a two-piece temple read as two separate buildings side by side.

**Cause.** The 3D city set no facing for any sanctuary piece (`orientation` 0 for all, and the preview's `pieces` had none). The models are authored for the SDL view's frame, where the kit's X is tile +y and its Y is tile +x; in the Godot city the kit's axes are the tile's own, so the temple pieces, which the layout stacks along the rows, had their long axes across the stack. The small statues looked toward tile +y (the kit's own facing) and the 14 monuments toward the diagonal: the 2D sprite script turns the colossus 45 degrees to face the camera.

**Fix.**
- `sanctuaryQuarterTurns` (`presentation/esimulationservice.cpp`) gives the temple, statues and monuments the quarter turns that bring them to the sanctuary's front: tile +x for a layout as the file gives it, +y for the turned one (rows toward the front; `rotate` swaps rows and columns). The snapshot's `orientation` and the preview's new `orientation` carry it; `model_basis` and the ghost (`main.gd`, `show_sanctuary_ghost`) apply it. Altar and paving keep their facing. The result is presentation only: no simulation state or save changes.
- The 14 `sanctuary_monument_<god>` GLBs were re-exported (`tools/export_godot_pilot.py` now zeroes the figure group's 45 degree turn) so that all pieces turn by quarters and the pedestals stay square: same vertex counts (e.g. 33,186 for Artemis), new bounds, manifests rewritten, imported with `godot --headless --import`. The previous files were kept in the session's scratch folder, not in the repository.
- `run_godot_pilot.py --sanctuary-review <name>` (new, `review_sanctuaries.gd`, also in the two automation lists of `start_menu.gd` and `audio_manager.gd`) captures the city's sanctuaries from four sides and from above, and the placement ghost of two layouts unturned and turned, into `captures/sanctuary-<name>-*.png`.

**Checks.** `validate_sanctuaries.gd` **79** (71 before; +4 per language): in all 28 layouts (14 gods, unturned and turned) and in the saved city's two turned sanctuaries and the one founded unturned, every temple, statue and monument looks to the front, worked out from the geometry (for a two-piece temple from its extension toward its complete half, which is also where the pediment must look; for a one-piece temple toward the monuments; Atlas and Hera put their monuments beside the temple, so the rule had to be the temple's own), and the altar and paving keep their facing. Also run after the change and passing: `validate_assets` 362, `validate_geometry`, `validate_city_coverage` (834 buildings, 279 walkers, nothing missing), `validate_embedded` (102 lines passing), `validate_buildings` 487, `validate_replay` (200 ticks). Windowed EN and RU: **549** checks pass each and **one fails in both**: "the Game menu offers ... the main menu" expects 12 entries and the menu now has 13, because `ui/hud.gd` gained an "Interface options…" entry (another session's change, made minutes earlier; not touched here).

**Visual review.** Before: both sanctuaries of the saved city showed two temples across the long axis (Artemis) or one temple across the axis (Aphrodite), gods diagonal. After: one continuous temple with its ridge along the long axis and its pediment toward the yard, and the monument and every statue looking the same way, on square pedestals (`sanctuary-before-*` and `sanctuary-after-*`).

Limits: the Atlas and Hera layouts are wide or square, and their temples face the file's row direction (the long side of a 20x12 Hera), as the SDL game draws them; the user's description of the front as the short width holds for the other twelve. The altar's own colonnade (an L along its back two sides, written for the SDL camera) was not turned. A saved city keeps no facing (it is derived), so older saves look right at once. The placement ghost was captured too (`sanctuary-final-ghost-<god>-<turn>-<yaw>-<pitch>.png`: the Promontory of Poseidon, the user's screenshot case, and Hermes' Refuge, unturned and turned): one long temple with its pediment toward the statues, every god looking the same way. The ghost shots needed `city.set_process(false)` in the reviewer, because `main.gd` picks the tile under the real mouse pointer every frame and moves the ghost there.

## Playable-loop slice 21: pyramids, monuments and shrines — 2 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_pyramids.gd` **103** headless checks (English 47 and Russian 48, plus 3 for the adventures and 5 for a half-built pyramid's save and reload, which `tools/save_roundtrip.py` also opens in the SDL executable); `validate_buildings.gd` 487 (the pyramids are skipped in its build-and-undo loop); the windowed EN and RU runs have 12 more checks and pass 563 each, failing only the Game menu's item count (13 items since another session added "Interface options…"; not a pyramid check); the rest of the headless set passes except `validate_ui_text.gd`, whose orphaned-row check lists strings of the world map's new labels from the other session ("Focus city", "Zoom in" ...), none of them pyramid strings; the SDL executable was rebuilt and signed because the shared engine changed (`epyramid.*`, `eboardcity.*`).

**Probes worth keeping.** (1) A command's answer is the snapshot of what it changed: a review or test that calls `core.query("build ...")` itself consumes it, and the Godot city never draws the new buildings (an empty site) unless the answer is passed to `city.receive_state`; the real path (`core.send`, handled by `core_link.gd`) does that. (2) `monument_halt` and `sanctuary_help` need the token of the *last* inspection: inspecting another piece of the same monument in between makes it stale. (3) The saved city's scenario grants the standard pyramid and its modest one stands, so `test_allow pyramid_modest` does nothing until that is demolished; a granted pyramid is given back only when the engine has freed the demolished one, a few steps later (advance before checking). (4) A new `--...-review=` flag has to be added to the `AUTOMATION` arrays of `ui/start_menu.gd` and `scripts/audio_manager.gd` (`login_scene_3d.gd` and `ui_accessibility.gd` match "-review"), or the window waits at the start menu; and a capture taken after a long run needs `DisplayServer.window_move_to_foreground()` first, or `frame_post_draw` never fires. (5) After the windowed run's battles the artisans' guilds may be gone, so a windowed check cannot wait for monuments to be built ("Without Artisans, this project will never get off the ground"); `validate_pyramids.gd` runs the work headless. (6) Pyramids cost nothing and the engine does not record them for undo: a generic build-undo-refund test must skip them.

## Playable-loop slice 22: controls and game settings — 3 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_controls.gd` **59** headless checks; the rest of the headless suite passes (embedded, assets 362, buildings 487, UI text 7, sanctuaries 79, pyramids 103, ...); windowed EN and RU **574** each, with the same seven failures in both (the HUD's cursor badge, and the world map's Escape, running-again, F2 and aid-regard checks around the new map flight), none of them involving the keys.

**Probes worth keeping.** (1) `ConfigFile.get_value(section, key, null)` is an error ("no default was given"), not a null: use a sentinel or `has_section_key`. (2) Godot's key constants share one integer (checked in 4.6.3): the key is the low 23 bits (`KEY_CODE_MASK`), `KEY_SPECIAL` (F-keys, arrows) is bit 22 of it, and the modifier masks are Shift 1<<25, Alt 1<<26, Meta 1<<27 and Ctrl 1<<28 (`KEY_MASK_CMD_OR_CTRL` is 1<<24); a binding that wants its own flags must reuse those masks (as `KeyBindings` does: `KEY_MASK_CTRL` means Ctrl or Cmd, `KEY_MASK_ALT` Alt), never low bits. (3) A test of rebinding points `Engine` meta `ezeus_settings_path` at a scratch file and must call `KeyBindings.reload()` and `PlaySettings.reload()` (and `KeyBindings.apply_input_map()` after) when it starts and when it ends: both cache what they read, and automation otherwise sees only defaults and writes nothing. (4) Held keys are polled through the InputMap; rebinding them means erasing and re-adding the action's events, and a test that wants to prove it reads `InputMap.action_get_events`. (5) A key dialog must stop the camera polling and the city's handlers while it waits (`UiAccess.dialog_open`), and must catch the key before the dialog's own Escape handling (`window_input`). (6) A world-map check has to wait for the flight (`city.world_flight.busy()`), not a fixed 0.4 s: `wait_world_flight()` in `validate_main.gd`.

## Playable-loop slice 23: asking a god to attack an enemy city — 3 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_attack.gd` **51** headless checks (EN/RU); `--attack-review` captures the inspector's offer, the granted answer and the refusal in both languages. The windowed runs do not exercise the section (the saved city has no rival on the board); the review captures do.

**Probes worth keeping.** (1) `eBoardCity::resourceCount` reads a cache (`mResources`) that the simulation refreshes once a second (`updateResources`), so goods put in a store by a test command do not count (a sanctuary reports `need_marble`) until `updateResources(cid)` is called; `test_stock` now calls it. (2) Only one city lives in the process: a review that opens another adventure inside the running city scene must `close_city()` the loaded one first, then hand the opened core to a reloaded scene through `Engine` meta `ezeus_simulation` (the start menu's way), and mark the second pass with its own meta so the review does not run twice. (3) `adventures()` on a second `EZeusSimulation` returned no `adventures` key while the city scene's own core held a loaded city (closing that city first fixed it; the cause was not investigated further). (4) The help and the attack requests share one wait: after asking one, the other's bar is empty too.

## Playable-loop slice 24: sacrifice scenes, braziers and the priestess — 3 October 2026

See `GODOT_MIGRATION.md`. Results: `validate_rites.gd` **47** headless checks; `validate_attack.gd` (slice 23) 51; the whole headless suite passes (assets **363**, characters 190 with the human-walker count now 93, geometry with the priestess's baseline added by hand: `--write-baseline` also rewrote thirteen unrelated `sanctuary_monument_*` entries, which were left as recorded; poses 12,478 frames, buildings 487, sanctuaries 79, pyramids 103, controls 59, ...); replay parity and the save round trip (including the half-built pyramid city) pass with the rebuilt SDL executable; windowed EN and RU **589** each, with one failure in both, the aid-regard check that was already failing (`asking for aid costs regard as the engine says (80 to 70)`, another session's world-map work). A first Russian run had twelve failures that were not repeated (the window was probably not in front for it): a windowed run must be left alone. `--rite-review` captures (`godot/captures/rite-<name>-<kind>-<yaw>-<n>.png`).

**Probes worth keeping.** (1) The model's forward is -Z (`atan2(-dx, -dz)`); the walker orientation `o` is the yaw `-180 + 45 o` degrees, so 0 faces tile -y, 2 tile +x, 4 tile +y, 6 tile -x (world z is minus tile y). (2) The people kit's person is .87 tall in tile units, as the altar's table is .84: stand a person at a table on stairs, never on the ground. (3) The altar GLB has three tripod braziers at (.70, -.70), (.70, .40) and (-.40, -.70) in the model's own x and z (Blender y of the build script is minus z), and its static flame is vertex colour (1, .5, .1) in the model's last group; the temple's vertex colour (1, .62, .25) is a thin lit slab (1.6 wide, 2.2 tall, in the temple's last group), probably its doorway glow, not a flame. (4) A roll about a walker's forward axis is `node.rotation.z` (Euler order YXZ), applied each frame because the heading code sets only `rotation.y`; the body then spreads sideways by its height about the model's origin at its feet, so shift it back by about half. (5) `StandardMaterial3D` with `BLEND_MODE_MUL` as a `material_overlay` browns a pale model without touching its palette. (6) A walker `type` of -1 is hidden by every overlay (`walker_visible`), which suits a presentation-only part. (7) `get_instance_shader_parameter` of an instance uniform that was never set returns null here, not the shader default.

## Mineral outcrops: each deposit kind looks different — 3 October 2026

Stone, copper, marble and orichalcum all used to show as the same pale beige pebbles.
Each kind now has its own model, built by `tools/godot_mineral_outcrops.py` (exported in background
Blender to `godot/assets/terrain/mineral_outcrops.glb`; 204–384 vertices per mesh). Each kind also has
its own `outcrop.gdshader` look (`ROCK_LOOKS`) and its own deposit soil and ground pattern
(`mineral_pattern`). See [terrain contracts](GODOT_TERRAIN.md).
- `--terrain-review mineral-before` / `mineral-after`: 17 views each, native state unchanged.
  The comparison is `captures/terrain-mineral-before-after.jpg`.
- Headless checks pass: details 31, terrain 18, map polish 16, elevation 22.
- Windowed EN and RU runs: 588 of 590 checks pass in each. Both fail the same two checks, neither of
  them terrain:
  - "asking for aid costs regard as the engine says (80 to 70)"
  - "the goods stand on the table where the animal was"

  Other sessions were editing `main.gd` and the UI scripts at the same time; these two failures were
  not investigated in this slice.

## Green ground and the map border — 3 October 2026

The sandy limestone base is now green land. The board and the countryside share
`shaders/terrain_palette.gdshaderinc`. `scripts/map_border.gd` draws a dashed white border just inside
the native board edge. Countryside cover now fades 4–18 tiles past the rim, which removes the old
stripes in open country. See [terrain contracts](GODOT_TERRAIN.md) and
[surroundings](GODOT_SURROUNDINGS.md).
- Headless checks pass: details 31, terrain 18, map polish 16, elevation 22. The landscape review
  passes 18, including two new border checks: the four corners lie on native tiles, and the border
  runs 637 tiles around the board.
- Windowed EN run: 587 of 590 checks pass. Windowed RU run: 589 of 590 pass.
  - Both runs fail "asking for aid costs regard (80 to 70)", as in the previous slice.
  - The EN run also fails "the goods stand on the table". It passed in RU.
  - The EN run also fails the Build-menu "hover previews another building" check. It passed in RU,
    and other sessions are editing the interface.
  - Both runs end with the same exit-time renderer leak messages as the previous runs.
- Images: `captures/terrain-green-border-before-after.jpg`; the after views are in
  `surroundings-*.png` and `terrain-after-*.png`.

## Darker land outside the map border — 3 October 2026

Everything outside the dashed border (countryside, sea, native water and trees) is now darker and
slightly desaturated, like unowned land in Cities: Skylines. The tint uses
`shaders/map_outside.gdshaderinc` and the shader globals `map_border_*` (see
[surroundings](GODOT_SURROUNDINGS.md)).
- Landscape review: 19 checks pass, including the new check that the tint uses the dashed loop.
- Headless checks pass: details 31, terrain 18, map polish 16, elevation 22. None reported a shader
  or script error.
- Windowed EN and RU runs: 588 of 590 checks pass in each. Both fail the same two non-terrain checks
  as before: the aid regard check (80 to 70) and the rite goods on the table.

## Realistic water and shores — 3 October 2026

River water and the sea now share `shaders/water_surface.gdshaderinc`: depth colour, caustics,
layered ripples, sky reflection and lapping foam. A five-tap low-pass in `coast_distance()` smooths
the saw-tooth shoreline. Banks vary in width and have a wet-sand strip. See
[terrain contracts](GODOT_TERRAIN.md).
- Headless checks pass: details 31, terrain 18, map polish 16, elevation 22. The landscape review
  passes 19. No shader errors.
- Terrain review frame rates at 1280×800 on the M4: minimum 54.6 fps, mean 59.4. A trial with
  Catmull-Rom sampling dipped to 47 fps and was dropped.
- Windowed runs: EN passes 587 of 590 checks, RU 586 of 590. Both fail the known aid-regard check.
  RU also fails the rite-goods check.
- Both runs also fail two interface checks: "the log keeps the title / unread count" and "the Game
  menu offers …". Another session edited `ui/hud.gd` during these runs (13:44); these failures are
  outside the terrain work.
- Images: `captures/water-before-after.jpg`.

## Mineral deposits on green ground — 3 October 2026

Stone, copper, silver and orichalcum no longer tint the ground. Their outcrop models alone mark them,
and the field's B "stone" channel is no longer set for deposits. Marble quarries keep their sawn
floor, because their interior cells have no props. `validate_details.gd` now expects quarry floors
only and runs its soil-edit checks on a marble cell.
- Headless checks: details 31 and terrain 18 pass. The mineral review passes.
- Windowed EN run: 588 of 590 checks pass. It fails the known aid-regard and rite-goods checks.
- Windowed RU run: the same 588 pass with the same two failures. After printing its result, the
  process looped on `Parameter "material" is null` (material_set_shader) during shutdown and wrote a
  1.8 GB log. This had not happened in the earlier EN/RU runs with the same shaders, and its cause
  was not identified.


## Nova reference city HUD — 3 October 2026

Implemented from the user's clearer Nova Roma screenshot: thin teal stock ribbon,
central native city plaque, second-row native stats/jobs/welfare shortcuts, square
construction dock, left journal control, bottom-left time and circular map, and
lower-right selected-tool/inspection/objective cards. Original SVGs and shared
Theme styles provide the appearance. Quiet journal delivery, pending choice
callbacks, independent text/interface/motion preferences, drafts and native rules
remain. The embedded service adds read-only current-city cached stock/employment
observations; the extension helper rebuilt/finalized/signed it successfully.

Verification uses only `CLAUDE-TESTING-ADVENTURE.ez` and temporary preferences:

- `review_map_notifications.py --checks --lang en` and `ru`: **115 each**, plus
  the **nine retained message/log checks each**. Retains the earlier 84 gates and
  adds 31: independent world-stock comparison (including native food aggregation),
  employment arithmetic, actual native overlay shortcut clicks, full 25,992-cell
  circular-chart bounds/picking round trips within 0.0001 tile, corner input
  pass-through, long city names/large stocks, and selected-card/speed-menu checks
  at 1440×900, 1280×720 and 1920×1080 with normal/enlarged independent sizing.
- `review_status_ui.py --checks`: **115 each EN/RU**; existing status/context,
  native quotes/facing/hover/wall controls, panel bounds, camera suppression and
  unfinished inspector drafts pass. `--menu`: **17 each**.
- Native incremental map/navigation checks: **eight each EN/RU**.
- Display settings review: **48 each EN/RU**; native picking, Apply/Keep/Revert,
  timeout, fullscreen/window/monitor restoration and unchanged native state pass.
- Embedded simulation regression: **101**; translation gate: **seven**. No new
  whole-game/broad campaign pass is claimed. Earlier broad aid-regard and other
  independently documented gameplay/renderer failures retain their prior scope.

The initial bottom-edge speed click selected an item immediately; explicitly
positioning the popup above the control fixed it. The real-input selection and
six size combinations now pass. All-map inverse comparisons use a 0.0001-tile
floating-point tolerance instead of exact Vector2 equality near zero.
One Russian display run attempted to access an already-freed review dialog; the
unchanged isolated rerun passes all 48. The cause of that transient closure is
not established. An earlier Russian HUD rerun ended without a completion marker
while disk space was exhausted by an unrelated shared-launch validation log.
The user authorized stopping that stalled validation process; the regular game
was left open. A sample of its repeated null-render-material errors is retained
in `captures/nova-background-log-sample.txt`, and repeated generated output was
cleared to recover space. The clean subsequent HUD reviews protect the designated
save and actual user/workspace preference hashes. No failed/overlapping run is
counted as verification evidence.

Final captures: `map-notices-nova-idle-*`, `nova-map-*`, `nova-build-*`,
`nova-road-*`, `nova-journal-*` (all with the `map-notices-` prefix) and retained
maximum-size decision/history/map/inspector fixtures, in EN/RU. These are actual
Metal/Mobile game captures. The idle map remains folded by default; the open-map
capture demonstrates the user's reference arrangement without changing the
player's visibility preference. User visual acceptance, sustained minimum-Mac
performance, wider campaign layouts and full keyboard/gamepad coverage remain
pending.

## Wider-looking streets and readable walkers — 3 October 2026

Roads pave their whole tile, with kerbs and a gutter. `scripts/walker_streets.gd` draws people 12%
larger, keeps moving walkers in right-hand lanes on roads (0.17 tiles, presentation only) and rings
the hovered person. See [terrain contracts](GODOT_TERRAIN.md).
- `--terrain-review road-after` passes. Of 169 people, all 169 are scaled, 62 were in lanes, the
  native track was kept, and the hover ring appeared under the warped mouse.
- Headless checks pass: details 31, terrain 18, map polish 16, elevation 22, locomotion 35,
  citizen 38.
- Windowed EN and RU runs: 587 of 590 checks pass in each.
  - Both fail the known aid-regard check. EN also fails the known rite-goods check.
  - New Build-menu failures: model files for columns and others in EN; the walls heading and elite
    housing in RU. Other sessions edited `build_catalog.gd`, `hud.gd` and `main.gd` (14:32–14:35)
    while these runs were going.
- An earlier run of the road review crashed with SIGBUS inside BaseMaterial3D threaded loading
  (`Godot-2026-10-03-142609.ips` and `-142739.ips`). The same code shows the
  `Parameter "material" is null` flood that filled the disk. A separate task was suggested to fix
  threaded GLB loading in `building_batches.gd`.
- Images: `captures/roads-before-after.jpg`.

## Sanctuary floor flicker fix — 3 October 2026

The plain paving tiles of a sanctuary (`sanctuary_court_0`, also the slab of a piece not yet begun) are flat to a ten-thousandth of a tile and lay exactly on the terrain, so they z-fought with it: white squares between the statues appeared, half-hatched or vanished as the camera turned. The patterned tiles (a thousandth thick) won the fight by that margin. `main.gd` now lays every `sanctuary_court_*` piece at the highest terrain under its corners and centre plus 0.015 (`flat_floor_height`, `FLAT_FLOOR_LIFT`); the models are unchanged. Checked with `--sanctuary-review` on both sanctuaries of the designated city from five angles and the windowed English run.


## Building choices and gold cost marker — 3 October 2026

`python3 tools/review_interface_context.py --checks --lang en` and `--lang ru`
both pass **66 checks** (19 retained HUD checks, 47 context checks). Obsolete
search/rotation-button assertions now check the requested hidden controls, the
five-pixel dock gap and the shared coin viewport's disabled idle state. Both
launches cover EN/RU layouts at 1440×900, 1280×720 and 1920×1080, category selection,
native costs, wall fill, hover context, placement feedback and unchanged native
city state. The launcher confirms the designated save and settings are unchanged.
One duplicate local layout variable from overlapping HUD edits was renamed to
`inspector_available` to restore parsing without changing its calculation.
The original procedural coin is authored in `ui/gold_coin.gd`; no external image
or commercial texture is used. Production provenance review remains pending.
Visual review uses `python3 tools/review_interface_context.py`; captures are
`captures/interface-context-build-en.png`, `interface-context-build-ru-720.png`
and `interface-context-wall-ru-720.png`. User art acceptance, larger independent
text scales and minimum-Mac performance remain pending.

## Slimmer choices without cost amounts — 3 October 2026

The updated `tools/review_interface_context.py --checks --lang en` passes all
66 checks and exits cleanly. The Russian launch also reaches 66 passing checks
and `INTERFACE_CONTEXT_CHECKS PASS`; its shutdown then repeatedly reports
`material_set_shader: material is null`, requiring interruption of that owned
review. Treat Russian UI assertions as passed and shutdown as unresolved.
Checks now verify cards contain only preview/name and selected context shows
native footprint dimensions without cost amounts. Both runs retain category,
hover, wall-fill, placement, dock clearance and EN/RU layout coverage at three
window sizes, along with unchanged native state. The price/coin rows are removed,
card minimum height is 110 instead of 134, and tray height follows its content
minimum instead of a 206-pixel floor. The HUD creates no coin viewport.

The separate visual review completes and closes cleanly, confirming the save and
settings guard. Final cards use a 110-pixel minimum (24 fewer than before) with
extra padding for two-line localized names. Selected footprint dimensions remain;
price and coin rows are absent. English/Russian screenshots and the wall-fill
layout were inspected; user visual acceptance remains pending.

## Foldable resource panel — 3 October 2026

`python3 tools/review_resource_bar.py --lang en` passes 25 checks and exits cleanly.
After adding rapid-reversal and reduced-motion assertions, `--lang ru` passes
28 checks and exits cleanly. Both use scratch preferences and confirm the
designated save and real preferences are unchanged. Evidence covers default
folded state, a real arrow click to open/close, resource/native shortcut clicks,
all 24 native stock items, independent native stock agreement, bounded icon art,
three resolutions with default and enlarged UI/text, long values/title tooltips
and unchanged native city state. Russian additionally verifies reversing a live
tween and immediate open/close with reduced motion. No script/rendering errors
occurred in these two resource review runs. Headless editor import completed;
`git diff --check` passes.

Inspected `captures/resources-folded-en.png`, `resources-1280-en.png` and
`resources-1280-ru.png`: the arrow follows jobs, the top bar stays compact, and
the separate resource panel clears the welfare controls. Captures include
larger UI/text variants. User visual acceptance, wider campaign coverage and
minimum-Mac profiling remain pending. The disclosure is presentation-only,
uses wall-clock UI tweening and adds neither native commands nor polling.

## Playable-loop slice 25: the rest of the SDL build menu — 3 October 2026

- `validate_menu_rest.gd`: **PASS, 179 checks** (EN and RU), headless, designated save in memory only.
- `validate_buildings.gd`: PASS, 535 (84 buildings offered in the test city, 63 exercised per language).
- `validate_roads.gd` 22, `validate_housing.gd` 30, `validate_embedded.gd` 102, `validate_assets.gd` 384, `validate_construction.gd` 242: PASS.
- `validate_ui_text.gd`: one orphan row, "Cancel a drag; send the selected banner to a tile", left by another session's change to `ui/controls_dialog.gd` (16:47); not this slice's.
- `tools/replay_parity.py`: PASS (one SDL-side non-reproducible 1200-tick seed-7 run on the first try, PASS on two re-runs); `tools/save_roundtrip.py`: PASS.
- Windowed `run_godot_pilot.py --validate`: EN and RU **588 pass, 1 fail** (the world map's aid-regard check, failing since before this slice).
- Reviews: `--menu-rest-review build` built all 11 sampled kinds (33 captures), `--menu-rest-review menu` captured 6 trays; captures in `godot/captures/menu-rest-*.png`.

## Setbacks, avenues/boulevards and street facing — 3 October 2026

- Changes: `street_setback.gd`, snapshot column 8 (road kind), RGBA road texture, `terrain_avenues.gd`
  and `street_facing.gd`. See [terrain contracts](GODOT_TERRAIN.md).
- `--terrain-review road-after` passes:
  - setbacks: 210 buildings set back, all within limits;
  - medians: 16 tiles, with 64 street trees;
  - facing: 110 buildings turned to their street, and every house with a known door shows it to its longest road;
  - walkers: hover ring, lanes and the native track all pass.
  - The hover check now passes a screen point directly: an unfocused window ignores `warp_mouse`.
- Headless validators pass: details, terrain, map polish, elevation (with the new column), locomotion, citizen,
  embedded.
- Windowed runs:
  - After setbacks and avenues: EN 588/589, RU 588/589.
  - After facing: EN 588/589, RU 587/589.
  - The only failures are the known aid-regard check and, in one RU run, the known flaky fallen-soldier die-clip check.

## Playable-loop slice 26: city data, taxes, wages, priorities, finances — 3 October 2026

- `validate_city_data.gd`: **PASS, 64 checks** (EN and RU), headless.
- `validate_controls.gd`: PASS, 59 (F7 opens the City window by default).
- `validate_ui_text.gd`: the new strings are all used and translated; the one orphan row is another session's (see slice 25).
- Windowed `run_godot_pilot.py --validate`: EN and RU **600 pass, 1 fail** (the world map's aid-regard check, failing since before slice 25); the 12 City window checks pass in both.
- `tools/replay_parity.py` and `tools/save_roundtrip.py`: PASS (the SDL data pages now use engine/ecitydata).
- Review: `--menu-rest-review city` captures the window's summary, employment, administration and military pages (`captures/menu-rest-city-<lang>-<page>.png`).
- Note for the controls checks: while they give F7 to the world map, the City window takes the map's F2, so their F2 press opens a City window; `run_city_data_checks` closes it first.

## Right-click back and right-side journal — 3 October 2026

Final `python3 tools/review_escape_menu.py --lang en` and `--lang ru` runs pass
**67 checks each**, exit cleanly and confirm unchanged designated save and real
preferences. The owned reviews use scratch preferences. Added assertions cover
right-click over the construction tray, tool/road-drag cancellation, inspector
selection clearing, journal/resources/objectives dismissal, folding a required
decision without commands, returning from the game menu and closing an internal
speed popup. Eleven city/settings pages—including the newly added City page—
return through their existing Escape/Cancel paths. Retained checks cover menu
pause/command-queue restoration, nested display preview reversion, translations,
keyboard scrolling, six size/text combinations and unchanged native city state.

The journal icon is aligned to the right screen edge; its panel opens eight
logical pixels below it with matching right edges. Both geometry assertions
pass. Inspected `captures/escape-journal-right-ru.png` and the equivalent English
capture. History grouping, unread semantics and message Controls are unchanged.
The missing City link in the redesigned menu was added so its existing action
remains reachable. Fixed-controls wording now describes right-click in EN/RU.
`git diff --check` passes. No C++ simulation change or binary rebuild was needed.

Embedded Windows use deferred root Escape input; internal PopupMenus close
without item selection. The initial approaches were corrected before the final
runs: directly emitting cancellation omitted persistent-window hiding, and
ordinary child enumeration missed internal popups. Selected army map orders
and world-map panning retain their existing paths but were not independently
re-exercised in this review. Idle native-tile inspection and wider campaign/input
coverage remain outside these scoped assertions. User visual acceptance remains
pending; these results do not establish whole-game parity or minimum-Mac speed.

## Objectives panel — 3 October 2026

- The objective check was not broken. In the player's Sparta save the goal is "800 people in Homestead or better",
  and all 27 houses are Hovels (648 people), so 0 qualify.
- `episode` now adds per goal `kind`, `current` and `required`; an unmet housing goal also gets `housing`
  (by level, people, and the needs from `eHouseNeeds`). Read from a scratch copy of the Sparta save, the shortfall is:
  27 Hovels, all lacking fleece and appeal.
- The panel is rebuilt with `ui/objective_card.gd`, the 3D laurel `ui/objective_wreath.gd`, and the theme variations
  `Objective*`. There are 16 new interface strings, all with Russian.
- `--objectives-review en|ru` passes: closed, open, and with a sample housing shortfall (`captures/objectives-*.png`).
- `validate_ui_text.gd` still fails on another session's decision-prompt strings, not on the new ones.
