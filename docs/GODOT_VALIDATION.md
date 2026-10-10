# Godot embedding validation — 9 October 2026

## Ornate menu hierarchy and single briefing route — 10 October 2026

The approved wood-and-gold frame remains on full menu pages; detailed settings
forms and compact confirmations use matching restrained bronze/slate trim.
The shared native-window frame is configured through `settings_shell.install_frame`.
Large menu choices keep their art. Compact primary/secondary footer actions use
clear padded `MenuPagePrimary` / `MenuPageChoice` controls; preview metadata now
matches the slate palette. The duplicate Read chapter briefing button and hidden
preview-story controls are removed. Start retains the complete normal story and
objectives before Begin. Story parchment, native chapter-preview semantics,
settings callbacks and shared city Theme remain intact.

Owned sequential Apple M4 Metal/Forward Mobile results:

- `tools/review_main_menu.py --lang en` / `ru --tag menu-hierarchy --menu-only`:
  **88 each**. Full-page carved-frame family, removed duplicate action, frame-safe
  category contents, keyboard/Back/Escape, all six settings forms, preview/Cancel,
  nested return, catalogs and protected save/preference bytes pass at default and
  enlarged 125% UI / 130% text, including 1280×800/720.
- `tools/review_adventure_cards.py --lang en` / `ru`: **70 each** plus **18** art
  metadata checks each. Complete footer labels fit their clean padded controls;
  story headers/actions remain inside the wood. Default/enlarged previews and
  briefings, seven real objectives together, full prose across readable parchment
  pages, native difficulty/Back and sandbox/editor coverage pass.
- `tools/review_campaign_library.py --lang en` / `ru --menu-only`: **85 each**.
  All five installed campaigns retain each chapter's native goals. Previewing
  chapter three still starts chapter one; Start shows the complete native story
  and every story page fits. Duplicate reader actions are absent. Owned campaign
  slots, summaries, earlier-profile discovery and all source checkpoint hashes
  remain intact. This scoped mode deliberately stops before 3D city loading.

All **486 scoped checks** pass, excluding repeated art metadata assertions.
Final visible logs exit successfully without engine/script errors. Evidence:
`godot/captures/menu-hierarchy-{en,ru}-engine.log`,
`adventure-card-{en,ru}-engine.log`, their adventure/story PNGs, and
`build-content-research/campaign-library/review-{en,ru}-visible-menus/latest.json`.
English library and Russian enlarged story captures were visually inspected.
`git diff --check` passes. The preliminary sandboxed headless campaign run passed
its assertions but logged the existing system-certificate restriction; it is not
part of the final clean native evidence. No source art, model/UV/LOD, native rules,
RNG/timing, player files or live game/Blender were changed. Broader city shutdown,
platform/high-DPI/gamepad and user visual acceptance remain separate open scope.

## Tidebound Covenant and five-campaign library — 10 October 2026

Recipe `content/scenarios/tidebound_covenant_chapters.json` v1 uses the reviewed
Tributaries 3 parent terrain/world by Nightwolf / David Masters (file510). Native
authoring passes **9** checks. All **25,992 tiles / 228×227 bounds** retain source
coordinates, height and terrain, with 2,802 fertile, 2,205 forest, 5,384 water and
575 ordinary rock cells. No mineral deposits are invented. New EN/RU writing,
goals and phased permissions replace source story/events/colony progression.
Atlantean science remains native; no trade buildings/imports/exports/tribute
are authored. The final two reserves prepare an outpost without a colony board.

Final ordinary gameplay passes all three chapters with **496 commands / 2,410
service calls**, no editor/test commands and no population/money/goods/victory
injection. Completions have **376 / 566 / 757 residents** and final treasury
**27,293**. Direct observations confirm local annual wheat **32**, fleece **21**,
timber **26**, empty trading lists and both committed reserves (wood 32/fleece 16).
Completion figures can vary with retained native randomness. Earlier diagnostic
layouts exposed sheep stacking, decoration replacing livestock reservations,
isolated road segments and fleece-filled bays blocking timber. They are not
acceptance evidence. Failed-test cities were removed after disk exhaustion;
attempt logs/results, originals and final successful checkpoints remain.

Sequential disposable Mobile/Metal campaign reviews pass **52 English / 52
Russian**: native geometry/valid farms, localized goals, phased buildings,
locked placement, science rather than Greek culture, no trading tools/lists,
same-city carry, chapter save/reload, empty-reserve refusal, relative BC waiting,
ending and complete paged briefing/actual Build menu. These review wins use
explicit structural fixtures, separate from the ordinary gameplay evidence.
Retained native editor **64** and embedded **101** checks pass.

The verified installer adds the fifth normal New game entry. A static **960×360**
card image comes from a hash-checked owned copy of the successful chapter-three
checkpoint. Its original checkpoint remains untouched. Expanded sequential
normal-menu reviews pass **137 English / 137 Russian**, covering five distinct
same-name autosaves, all fifteen native chapter previews/full readers/images,
new-game chapter-one/focus behavior, enlarged layouts, actual Continue/Load,
exact treasury/pause/write scopes and Tidebound's local-supply/science tools
without trade. Prior profile continuation and source-byte protection still pass.

Reports are selected by `build-content-research/tidebound-covenant/current.json`;
authoring, natural-playthrough/result.json, self-supply-proof.json and
review-en/ru-visible/result.json are under its report directory. Shared results
are selected by `build-content-research/campaign-library/review-<lang>-visible/latest.json`.
See [scope and provenance](TIDEBOUND_COVENANT.md). No native rebuild, model/UV/VAT/
LOD change, audio change, live-game interruption or player-save mutation occurred.
Human pacing/visual acceptance, actual Windows/minimum devices and commercial
retained-content permission/replacement remain open; frozen Windows kits are
unchanged. needs_evidence/ships_in_release=false remains.

## Greek settings submenu shell — 10 October 2026

The six existing start-menu settings dialogs use private bronze/slate Themes,
original Greek SVG trim, clear ivory labels, aligned fields and matching checkbox/
slider details. Category artwork hides behind a scenic input shield while any
settings window is open. Final close restores category focus; nested Game settings
return to Game first. Native dialog drafts, persistence, callbacks and the shared
city Theme remain unchanged. The long Controls area adapts to actual translated
message/footer height, including enlarged Russian text.

Final owned `tools/review_main_menu.py --lang en --tag settings-final --menu-only`
and the corresponding Russian run cover **83 checks each / 166 total** on Apple M4
Metal/Forward Mobile: six forms and complete footers at default and 125% UI / 130%
text at 1280×800/720, native Display Apply/Revert, aligned resolution fields, live
Interface preview and Cancel restoration, full key/capture text, category focus,
nested Game→Display→Back, catalogs and protected save/preference bytes. Evidence
uses `godot/captures/settings-final-{en,ru}-engine.log` and corresponding `display`,
`interface-preview`, `controls-large-720` and other six-page captures. Original
vectors and scope are documented in `ui/settings_art/README.md`; no generated
bitmap/reference crop was added. `git diff --check` passes.
Both final scoped runs exit successfully with no engine/script errors. English
Display and Russian enlarged Controls captures were visually inspected; all text
and the complete frame/footer remain inside the viewport.

Broader `main-menu-settings-{en,ru}` runs passed all **87 assertions** each,
including actual Continue into **25,992 cells / 841 building records**, but exited
with a native Godot shutdown crash after the city was freed. The macOS report
identifies `RendererRD::MaterialStorage::shader_free` during ResourceLoader cleanup.
Those runs are not clean full-game validation; the final menu-only reviews avoid
that separate city/render-resource shutdown path. No city loader/model changes
were made for this settings refinement. Wider platform/high-DPI/gamepad and user
visual acceptance remain pending.

## Stable category slots and restored dock text — 10 October 2026

The ellipsized center Label could have effectively zero minimum width when a
chapter exposed only a short category row. The HUD now caches translated title
measurements and reserves bounded center space. It retains sixteen canonical
category positions; unavailable native groups become genuine disabled Buttons
with cached grayscale original artwork and an EN/RU explanation. No additional
native buildings, unlocks, permission changes or queries are introduced.
Settlement guide targets/actions skip disabled categories.

Owned sequential Apple M4 Metal/Forward Mobile reviews:

- `python3 tools/review_toolbar.py --context --lang en` / `ru`: **54 each**.
  Eight-category, empty and re-enabled presentation catalogs retain fixed order;
  disabled artwork is actually grayscale; real hover identifies the category;
  tooltip content explains unavailability; disabled clicks issue no command;
  selected titles remain centered after pointer exit; stale trays close; guide
  actions/targets skip disabled categories. Normal 100%/100% and enlarged
  125% UI/130% text layouts at 1920×1080 and 1280×720 retain readable category text,
  accessible main buttons and bounded clock/map/trays. Every native snapshot
  field agrees before/after, apart from the observation sequence number.
- Retained `tools/review_toolbar.py --lang en` / `ru`: **178 each**, covering
  available native model cards, hover/focus, separated mouse down/up, keyboard
  navigation, main-row shortcuts/rebinding, Undo, all Layers choices and bounds.
  These and the focused reviews total **464 scoped checks**. Enabled-category
  assertions in the main and map-notification reviewers now count enabled slots,
  rather than assuming that unavailable categories disappear; those larger
  reviewers were not rerun in this slice.

Evidence: `godot/captures/toolbar-context-{en,ru}-engine.log`, retained
`toolbar-{en,ru}-engine.log`, `toolbar-{en,ru}-context-unavailable.png`,
`toolbar-{en,ru}-context-selected.png` and `toolbar-ru-context-1280-125.png`.
English disabled icons and Russian enlarged selected-title captures were visually
inspected. Native tooltip windows are outside viewport captures; tooltip content
is checked through the shared tooltip factory and real pointer hover separately.
The designated save/copy and user preferences retain their protected hashes;
focused diffs pass whitespace checks. Final review logs contain no script/engine
errors. The original artwork and native simulation/save layout remain intact.

Review corrections: the initial sparse fixture was overwritten by the native
catalog's existing delayed 1.5-second trade refresh, so the fixture now waits for
it before narrowing presentation. Incomplete injected mouse metadata caused
missed retained Russian clicks; events now include real button masks/global
positions and still span frames. A post-assertion Godot renderer cleanup fault
led to explicit owned city/thumbnail disposal before exit; the final focused
reviews exit normally. These are review changes, not simulation workarounds.
Actual chapter unlock progression, other platforms and whole-game accessibility
certification remain outside this focused interface slice.

## Portal fitted to the scenic stone opening — 10 October 2026

The cinematic portal now uses a source-derived signed-distance mask at image
bounds `(1194,204,268,468)`. Its fire follows the perspective arch, projecting
jamb stones and sloping sill. The scenic artwork and packed historical Blender
reference retain their recorded hashes; native code/rules/saves are unchanged.

- Final sequential `python3 tools/review_main_menu.py --lang en --tag
  portal-alignment` and `--lang ru --tag portal-alignment-final` pass **87 each**
  and exit cleanly on Metal/Forward Mobile. They cover reduced-motion stop/resume,
  native menu/input/settings/leader/save flows, actual Continue into the copied
  designated city, 1920×1080 and enlarged 125% UI / 130% text at 1280×800/720.
  Protected saves/preferences remain unchanged; city loads drain all requests.
- An EN art-only review passes **11**. Full-scene/detail and EN/RU enlarged
  captures were visually inspected. The composition retains four triangles/two
  quads; the mask adds one shader lookup rather than runtime image processing.
- Mask/source/hash validation and deterministic regeneration pass: **110,742**
  doorway pixels, no spill onto stone, 12 disconnected dark masonry pixels
  excluded. Both packed channels use lossless linear-data import with no mipmaps
  or automatic 3D compression. Python syntax and scoped whitespace checks pass.

Evidence: `captures/portal-alignment-en-engine.log`,
`portal-alignment-final-ru-engine.log`, their matching menu PNGs,
`portal-alignment-detail.png`, and `portal-mask-validation.log`. Dedicated review
prefixes avoid collisions with another chat's menu outputs. An earlier Russian
run passed all checks but exited with SIGBUS in `RendererRD::MaterialStorage`
during city teardown; the final repeat exits zero. General teardown stability,
other platforms, minimum-device profiling and user visual acceptance are outside
this alignment verification. The original artwork/animation and legacy analytic
portal remain retained.

## Sunlit Terraces and four-campaign library — 10 October 2026

Recipe `content/scenarios/sunlit_terraces_chapters.json` v1 uses the reviewed
Genis Everybody loves oranges parent terrain/world (file828). Native authoring
passes 9 checks. All 25,992 tiles retain source coordinates, height and terrain;
228×227 bounds, 373 fertile cells and disconnected source tracks remain. The
export replaces source writing/events/colony progression, keeping Greek culture
and native orchard, delivery, economy and chapter rules.

Final ordinary gameplay passes all three chapters with **777 commands / 4,100
service calls** and no test commands or population/money/goods/victory injection.
Completions have 400/1,096/1,080 residents and final treasury 33,562. Observations
prove raised orange placement, annual orange sales 22, grain imports 70, local
oil 12/wine 13 and explicit commitment of the 16-wine reserve. Earlier failed
actual-sale checks exposed separate road networks and the need for dedicated
orange granaries; those attempts are retained separately, not acceptance evidence.

Sequential disposable Mobile/Metal campaign reviews pass **52 English / 52
Russian**: source geometry, 362 native-valid orchard sites, three localized goal/
permission sets, unavailable placement, Greek culture rather than science,
same-city building carry, native chapter checkpoint save/reload, unfunded-reserve
refusal, BC relative waiting, ending and full paged opening briefing/Build menu.
Review chapter wins are explicit structural fixtures, distinct from natural play.
Retained native editor 64 and embedded 101 pass. No native rebuild was needed.

The verified private installer adds a fourth normal New game entry and preserves
the previous prototype and all player profiles. A 960×360 static card image comes
from a hash-checked copied ordinary-playthrough checkpoint. The capture helper
sets that owned copy's read directory, preserving the native file-path guard.
Original checkpoints, model/UV/VAT/LOD assets and live game/Blender remain intact.

Expanded sequential normal-menu reviews pass **113 English / 113 Russian**.
They cover four distinct same-name autosaves, all twelve chapter previews,
complete reader text, individual images, new-game chapter-one/focus behavior,
enlarged layouts, actual Continue/Load and exact pause/treasury/write scopes,
including Sunlit Terraces's final vineyard/Greek-culture permissions. Earlier
campaigns, prior profiles, immutable preflight and source-byte checks remain.
Python compile, JSON/provenance/hash and scoped whitespace checks pass.

Evidence is selected by `build-content-research/sunlit-terraces/current.json`;
its report holds authoring, natural-playthrough and review-en/ru-visible results.
Shared reports are `build-content-research/campaign-library/review-<lang>-visible/latest.json`.
See [campaign scope](SUNLIT_TERRACES.md) and its provenance. Human pacing/visual
acceptance, actual Windows/minimum machines and retained-input commercial rights
remain open. Frozen Windows ZIPs are unchanged. This is private
`needs_evidence / ships_in_release=false` content, with no public distribution.

## Parchment only for story reading — 10 October 2026

The adventure-selection preview now uses a code-native dark slate surface with
a bronze edge, ivory description/objectives and gold headings. Parchment stays
on story briefings and the optional full chapter reader. Preview text uses its
own Theme variation, retaining dark ink for story page numbers. No new bitmap
was generated; existing source artwork and native campaign actions are unchanged.

Sequential owned `tools/review_adventure_cards.py --lang en` / `ru` pass
**62 each / 124 focused checks** on Apple M4 Metal/Forward Mobile. New assertions
verify the preview has no parchment, actual description/objective/heading contrast
is at least 7:1, story retains its paper/page controls, and page numbers retain dark
readable ink. Existing native wording, all objectives together, frame-safe header/
footer, full story pages, sandbox, difficulty/Back and enlarged 125% UI / 130% text
at 1280×800/720 pass. Art metadata passes **18** mappings/crop bounds each.
Protected saves/preferences remain unchanged; final native logs have no engine/
script errors. English default and Russian enlarged previews were visually
inspected. Evidence: `godot/captures/adventure-card-{en,ru}-engine.log`,
`adventure-card-en-campaign.png`, `adventure-card-ru-large-720.png` and retained
`stonewatch` story captures. `git diff --check` passes. This is a menu-only visual
refinement; the broader campaign/main-menu results below remain earlier evidence.

## Frame-safe parchment briefings and all objectives — 10 October 2026

The current start-menu briefing reserves an inner walnut reading area below the
crest and above the lower carved rail. A bounded story Control prevents long
prose from enlarging the frame. Every objective is visible together, with no
objective paging buttons or internal scrolling. Larger lists use a wider two-
column grid; short windows use a compact goal row. The original aged parchment
has dark native ink and matching sepia story-page controls. City episode layout
and native difficulty/campaign callbacks remain intact.

Owned sequential Apple M4 Metal/Forward Mobile reviews:

- `tools/review_main_menu.py --lang en` / `ru`: **61 each**. All main actions
  fit at normal/enlarged preferences; Settings and catalog navigation, compact
  labels, global cursors and native Continue remain intact. Continue matches
  **25,992 cells / 841 building records**, retaining the protected saved city.
- `tools/review_adventure_cards.py --lang en` / `ru`: **59 each**. Native wording,
  quantities and all visible goals are retained. Athens/Stonewatch headers and
  full difficulty/Back/Begin footers stay inside the wood. Default 1600×1000 and
  enlarged 125% UI / 130% text at 1280×800/720 fit; all story pages preserve the
  full native string. A review-only seven-goal fixture uses the native earlier
  First Light Harbor preview, obtained before any city owns the engine; every
  goal is visible and complete story pages fit at enlarged 720p. No objective
  page buttons remain. Art metadata passes **18** mappings/crop bounds each.
- `tools/review_campaign_library.py --lang en` / `ru`: **89 each**. All three
  campaign chapter previews retain their own native goals; the optional paper
  reader preserves full chapter prose and each page fits without scrolling.
  Normal Begin, saved chapter restoration, Continue/load permissions and separate
  campaign write slots pass. Existing source/checkpoint/preference bytes remain
  unchanged.

English Stonewatch, seven-objective and chapter-reader captures, plus Russian
seven-objective/enlarged captures, were visually inspected. Evidence is
`godot/captures/adventure-card-{en,ru}-engine.log`, their `stonewatch`,
`briefing-large-*` and `seven-objectives` PNGs, and
`build-content-research/campaign-library/review-{en,ru}-visible/latest.json`.
All **418 focused checks** pass across both languages, excluding repeated art
metadata assertions. Final native logs contain no engine/script errors;
`git diff --check` passes. The generated blank paper is
**1536×1024**, with true alpha; its exact prompt and source hash are in
`assets/menu/aged_parchment_v1.provenance.json`. It was created with built-in image
generation. Headless import's existing sandbox certificate/editor-preference
diagnostics are not included in clean native-review evidence.

The development checks caught and corrected library height, the seven-goal
column width and reviewer native-ownership ordering before final runs. Scope is
menu presentation/reading; no C++ rules/RNG/tick/save changes, model/UV/LOD edits
or live game/Blender changes are claimed. Wider aspect ratios/platforms, full
accessibility/gamepad and minimum-device profiling remain pending user review.

## Compact settings text correction — 9 October 2026

Sequential owned `tools/review_main_menu.py --lang en` / `--lang ru` pass
**61 each / 122 checks** on Apple M4 Metal/Forward Mobile. The large ornamental
texture no longer skins generic Button controls; compact keys/footer actions use
the clean shared surface/padding and sans font at a menu-local 17-pixel baseline.
Explicit large menu choices retain their artwork and silhouette focus.

Three additional assertions per language cover key/reset/footer text fitting its
padded surface, the translated key-capture prompt and full padding at 125% UI /
130% text. English default and Russian asking/enlarged Controls captures were
visually inspected. Evidence is `godot/captures/main-menu-{en,ru}-controls*.png`
and `main-menu-{en,ru}-engine.log`; final native logs contain no engine/script
errors. Retained native Continue still matches **25,992 cells / 841 building
records**; protected save/preferences remain unchanged. `git diff --check` passes.

Scope: menu-owned compact button styling. Detailed Controls-list scrolling,
bindings/settings callbacks, shared city Theme, global cursor artwork and native
simulation remain intact. No new bitmap artwork was generated for this correction.

## Global cursors and quieter menu focus — 9 October 2026

Owned visible Metal/Forward Mobile reviews on Apple M4 pass **160 checks**:

- `tools/review_main_menu.py --lang en` / `--lang ru`: **58 each**. The retained
  navigation/ownership/native Continue checks pass, plus silhouette-based focus,
  all 17 global cursor roles, proportional tip hotspots at 125% interface size
  with 130% text and 1280×800/720, and persistence into native city gameplay.
  Continue matches the independent native read of **25,992 cells / 841 building
  records**. Protected save and preference bytes remain unchanged.
- `tools/review_game_cursor.py`: **44**. All 13 textures have transparent padding
  and valid hotspots; arrow/hand/busy tips are visible at their click points.
  Native Controls select each of the 17 installed roles. Edge clicks remain
  aligned at 100/110/125% interface sizes; resources fit the hardware budget.
  Text-only scaling leaves pointers unchanged; revisiting sizes reuses cached
  textures. No frame/input processing or mouse capture/visibility change occurs.

Final native logs `godot/captures/main-menu-{en,ru}-engine.log` and
`game-cursor-engine.log` contain no engine/script errors. The English focused menu
and `game-cursors.png` light/dark art sheet were visually inspected. Viewport
captures contain the art sheet but omit the operating-system pointer; selected
role checks are API evidence, not an OS cursor pixel capture. Python compilation
uses a writable temporary cache; `git diff --check` passes.

The built-in generated source is **1774×887**, with real alpha and eight cells.
Godot creates eight cropped sprites plus five original vector resize/help symbols,
all **48×48**; runtime interface scales cache **48/53/60** pixels. Source atlas,
exact prompt, hashes, crops and hotspots remain in `assets/cursors/` with
`olympian_cursors_v1.provenance.json`. The headless derivative bake passes
`CURSOR_BAKE PASS textures=13 base_size=48`; its existing sandbox macOS certificate
diagnostic is not included in clean native-review evidence.

Scope: Godot cursor artwork/registration and menu focus. Existing scene navigation,
Control roles, native simulation/RNG/ticks/save format, model/UV/LODs and live
game/Blender are retained. User visual acceptance, other operating systems and
high-DPI/multi-monitor review remain pending. Earlier menu/card/campaign evidence
below remains historical; no unrelated gameplay changes are claimed here.

## Ornate menu completion and no-scroll pages — 9 October 2026

The current ordinary menu replaces the plain projected housing with generated
Greek walnut/bronze/ivory frames and enamel buttons. The realistic backdrop and
original registered live portal remain. Frame art has painted depth, with actual
translated Control text and native actions over it; it is not a new 3D mesh set.
The main page has no ScrollContainer. Catalogs and native briefings/objectives
use pages without losing entries, exact paths, prose or objective quantities.

Final owned visible Metal/Forward Mobile evidence on Apple M4:

- `tools/review_main_menu.py --lang en` / `--lang ru`: **53 each**. Checks include
  all fixed main choices at 125% UI/130% text and 1280×800/720, keyboard/mouse,
  search/paging for adventures, saves and profiles, empty results, authoritative
  identity/ownership, Extras → editor → Back, all six Settings categories,
  language, reduced motion and actual native Continue. Continue matches an
  independent native read of **25,992 cells / 841 building records**.
- `tools/review_adventure_cards.py --lang en` / `--lang ru`: **36 each**. Native
  campaign/sandbox previews, every exact objective across pages, full first-story
  concatenation, difficulty/Back, stale-preview cancellation and enlarged menu/
  briefing bounds pass. Each enlarged story page fits its visible reading area.
  The retained art metadata checker passes **18** mappings/crop bounds per run.
- `tools/review_campaign_library.py --lang en` / `--lang ru`: **89 each**. All
  three private campaigns retain chapter previews/default difficulty, full paged
  chapter prose, no chapter skipping from the selector, normal Begin/Continue,
  exact restored chapter permissions, separate write slots and read-in-place
  continuation of an earlier-launcher profile. Every reader page fits its window.
- **356 focused menu/card/campaign checks** across both languages, excluding
  repeated art-metadata assertions. Protected saves, preferences, campaign
  sources and fixture checkpoint bytes remain unchanged. Final visible logs have
  no engine/script errors. `git diff --check` and Python tool compilation pass.

English main/settings/library/briefing and Russian main/enlarged/briefing captures
were visually inspected. Evidence is `godot/captures/main-menu-{en,ru}-engine.log`,
`adventure-card-{en,ru}-engine.log`, their PNGs, and
`build-content-research/campaign-library/review-{en,ru}-visible/latest.json`.
Prompts, measured dimensions, source hashes and the runtime button crop are in
`assets/menu/greek_menu_v3.provenance.json`. Assets are **887×1774** (portrait),
**1586×992** (landscape) and **2098×749** (padded button source); the sampled button
region is **2098×361**, resized once to 520 pixels wide in Godot.

During development, programmatic search fixtures needed the normal text-change
signal, and small briefing buttons needed utility styling/text-safe margins.
Those failures were corrected before final reviews. A sandboxed headless campaign
run passed 86 functional checks but its wrapper rejected the existing macOS
certificate diagnostic; owned visible regressions are the final evidence.
One earlier visible run also had a transient CoreAudio startup diagnostic; the
final rerun is clean. Python compilation uses an explicit writable cache path.

Scope: menu presentation and native navigation. City episode cards, detailed
settings forms (including the long scrollable key-binding dialog), shared Theme,
C++ rules/RNG/ticks/save format and model/UV/LOD sources are preserved. User visual
acceptance, wider aspect ratios/platforms, full gamepad/accessibility coverage and
sustained minimum-device profiling remain pending.

## Earlier realistic cinematic menu correction — 9 October 2026

The user rejected the earlier cartoon-like procedural scenery. Normal start now
uses generated realistic Greek artwork with people, a dense coastal city,
Acropolis, textured geological mountains and weathered gateway architecture.
The retained live portal shader is registered to the empty doorway on a separate
quad; accessible controls are retained and the stage above supersedes its housings. Scenic people,
landscape and architecture are raster artwork, not live simulated 3D entities.

- Sequential `python3 tools/review_main_menu.py --lang en` / `--lang ru` pass
  **34 each / 68 total** on Metal/Forward Mobile. Native campaign/leader/save
  navigation, actual Continue into the copied designated city, language,
  keyboard/mouse input, sound/settings, 125% UI with 130% text at 1280×800/720,
  and reduced-motion stop/resume remain verified. Continue matches the native
  read of **25,992 cells and 841 building records** and retains the save hash.
- `--lang en --art-only` passes **nine** initial checks and captures the scene
  without UI. English full-scene/main-page and Russian enlarged menu captures
  were visually inspected; the portal remains aligned in the doorway through
  these viewport/interface size changes. The visible reviews exit without
  engine or script errors; protected save/preferences remain unchanged.
- Artwork is **1672×941**, generated by the built-in image tool. It is not 4K;
  the prompt's requested resolution is not an output measurement. The exact
  prompt, source image hash, pixel-calibrated aperture and provenance are saved
  under `godot/assets/menu/aegean_cinematic_v2.*`.
- Background preparation observed **17 ms EN / 13 ms RU**, with **four triangles
  on two quads**, excluding existing UI geometry. The earlier procedural cache
  remains intact and is not loaded by ordinary launch. This is construction
  timing, not a sustained/minimum-device GPU or cold-start benchmark.
- Blender port **9876** was inspected read-only. The original default Cube,
  Light and Camera document was confirmed intact afterward. A separate
  background Blender 5.2.2 process builds the packed reference
  `art/menu/cinematic/aegean-cinematic-v2.blend` (**three objects, one packed
  image**). A background EEVEE frame renders successfully and was visually
  inspected. Its procedural portal material is an editable approximate preview;
  Godot retains the exact original portal shader. The scene does not reconstruct
  separate editable city/person/mountain meshes.

Evidence: `godot/captures/main-menu-{en,ru}-engine.log`, current
`main-menu-{en,ru}-*.png`, `cinematic-blender-reference-{build,render}.log`, and
parent `art/menu/cinematic/aegean-cinematic-v2-preview.png`. Generation/runtime
provenance is `assets/menu/aegean_cinematic_v2.provenance.json`.
Initial sandboxed background-app startup was retried successfully with the owned
preview/background tools; editor import retains the existing macOS certificate
and protected editor-preference diagnostics. These are not final visible errors.

User visual acceptance, additional aspect/platform coverage and sustained
minimum-device profiling remain pending. Original procedural scene/bake, historical
Blender city, native model/source files, UVs/LODs, C++ rules/RNG/ticks and save
formats remain intact. `git diff --check` passes.


## Earlier Olympian main menu (superseded) — 9 October 2026

The ordinary menu now uses the original Aegean sanctuary composer, retaining the
previous living portal within a daylight Greek city/temple scene. The 3D housings
are real beveled meshes projected under the retained accessible Control layer;
settings/sound dialogs retain their established UI and native callbacks.

Final sequential owned Metal/Forward Mobile reviews on this Apple M4:

- `python3 tools/review_main_menu.py --lang en` and `--lang ru`: **34 each**.
  Real mouse/keyboard navigation, leader switching, empty profile, latest save,
  language, editor, sound/settings, 125% UI with 130% text at 1280×800/720, new
  scene/portal/3D housing presence and reduced-motion stop/resume all pass.
  Continue opens the copied designated city with **25,992 cells / 841 building
  records**, matching an independent native read; the copy is unchanged.
- `python3 tools/review_adventure_cards.py --lang en` and `--lang ru`: **29 each**.
  Increased artwork height preserves native opening goals, keyboard selection,
  campaign/sandbox semantics, cached previews, Start/briefing/difficulty/Back,
  enlarged layouts, independent scrolling and stale-selection cancellation.
  Metadata verification also passes its 18 retained mappings/crop bounds.
- **126 focused menu/card checks** pass in total. English main/adventure and
  Russian main/adventure/enlarged screenshots were visually inspected. Main-menu
  reviews also capture load, leader and settings pages. The dedicated `--art-only`
  path passes nine initial checks and captures the unobstructed scene.
- Headless `bake_olympian_menu.gd` succeeds. The compressed derivative is about
  **12 MiB**, with **576,037 merged static triangles and 27 mesh/MultiMesh nodes**;
  that triangle count excludes instanced courtyard-house copies and UI meshes.
  Source generation observed around 4–5 s; hash-checked cached scene construction
  observed **193 ms EN / 141 ms RU**. These are the scene construction intervals,
  not total cold startup, GPU timings or sustained/minimum-machine benchmarks.
  Missing/stale cache inputs fall back to the original procedural construction.
- The final visible runs have no engine/script errors; protected save/settings
  fingerprints are unchanged. `git diff --check` passes. Initial visual iterations
  and corrected scenery type errors are not counted as final validation. Headless
  tooling retains the existing macOS CA-certificate warning and requires an
  explicit writable `--log-file` to avoid the sandboxed default user-log path.

Evidence: `godot/captures/main-menu-{en,ru}-engine.log`,
`main-menu-{en,ru}-{new-player,continue,adventures,load,leaders,settings,large-720,large-800}.png`,
`adventure-card-{en,ru}-engine.log`; cache inputs/provenance live in
`assets/menu/olympian_sanctuary.json` and `olympian_menu_sources.json`.

Scope remains a development menu presentation. User art acceptance, ultrawide and
other-platform coverage, sustained minimum-device profiling and retained-input
release-rights evidence are pending. Original model/source files, UVs, imported
LODs, live Blender/game sessions, C++ rules/RNG/ticks and save formats are retained.


## Healer treatment and plague recovery — 9 October 2026

The original healer only supplied hygiene; it never treated an already infected
house. The native regression reproduced failed recovery at full hygiene and via
the actual adjacent-road `changeTile()` service scan. The fix adds medical
treatment to the native healer's provision override and uses the existing board
recovery path. It does not clear every house in an outbreak or alter normal
infection risk/unattended recovery, paths, hygiene units or the save layout.

`./tools/build_godot_extension.sh` rebuilt the extension into staging and signed/
installed it on a fresh inode; `codesign --verify` passes. The user's live game
and Blender were left running. No SDL executable rebuild was required.

- `tools/test_plague_healer.py` passes **17 EN / 17 RU** native checks against the
  installed extension. Full-hygiene and decayed-hygiene houses recover; exhausted
  healers do not treat them. Exact hygiene provision/supply consumption and
  residents are retained. Adjacent-road service cures the visited house,
  untreated neighbors retain their infection/membership, repeated visits are
  harmless and the final recovery removes the outbreak. Infection seeds are
  deterministic. The fixture reads only the designated city.
- `tools/review_plague_healing.py --headless --lang en` passes **12 checks**;
  sequential owned Metal EN/RU reviews pass **12 each**. Existing infirmaries
  spawn real healers after ordinary preparation ticks, with hygiene workforce
  priority set through the native command. The fixture's known sculpture request
  uses its original Postpone callback only in the disposable session. Test mode
  injects the outbreak; an infected scratch checkpoint is then saved/reloaded.
  Pause holds recovery, while ordinary patrol ticks subsequently heal the chosen
  house in **35 service ticks**. Actual city aura nodes disappear and the hazard
  rail follows the remaining infected count. Unvisited houses remain infected.
  Both visible previews exit without engine/script errors; before/after EN/RU
  captures were visually inspected.
- Retained embedded checks pass **101** and hazard-rail checks pass **87**.
  All **258 scoped checks** pass. Save, settings and number-table hash guards
  remain unchanged. The signed native smoke executable and all scratch saves
  are temporary; the live game is never controlled by these fixtures.

Evidence: `godot/captures/plague-healer-{before,native}.log`,
`plague-treatment-build.log`, `plague-{embedded,hazard}-engine.log`,
`plague-healing-en-headless-engine.log`,
`plague-healing-{en,ru}-engine.log`, and
`plague-healing-{en,ru}-{infected,treated}.png`. Headless retains the known macOS
certificate warning and legacy missing audio/adventure-source diagnostics.
Earlier review fixture failures were corrected (patrol spawn delay, a pending
native request, and camera helper arguments); only the final runs are counted.

Scope: treatment by actual native healers in their existing service reach,
including loaded infections. A new infirmary still requires its native staff,
enabled state and road access; its mere presence does not cure distant houses.
Broader campaign/minimum-platform profiling remains pending.


## Stonewatch campaign — 9 October 2026

Final native authoring passes **10** checks, including explicit exported rival
selection. Sequential disposable Metal reviews pass **49 EN / 49 RU**: opposing
serialized combat teams; invalid/missing/player-city and ordinary team-command
refusal; three objective/unlock sets; same-city carry and save/reload; blocking
invasion choice/save refusal; timed Minotaur/native Theseus-hall gate; complete
localized menu/Start/Begin briefing and opening Build gates. Fixture wins are
explicit structural checks, separate from the ordinary playthrough.

The **final signed-core ordinary playthrough wins all three chapters** with actual
invaders, Fight/victory, Minotaur, Theseus Summon/fight and fulfilled slaying. All
seven direct battle/hero proof flags are true. **824 ordinary commands / 2,150
service calls**, no test commands or injected people/goods/money/victory; final
populations **432 / 735 / 648**, treasury **16,441**, native time **641,400 units**.
Connected pier-side warehouses resolve saturated import bays; standing armies
down supports immigration; ordinary repairs clear wall ruins where needed.
The 45–90-minute human pacing target remains untested.

Current manifest: `build-content-research/stonewatch/current.json`; scoped results
and PNGs are under its `report/review-en-visible`, `review-ru-visible` and
`natural-playthrough` directories. Failed attempts stay archived. The static card
view uses a copied earlier successful checkpoint; source/PNG hashes remain in
`campaign-library-art.provenance.json`. Raw sources/other campaigns/actual saves
and settings are hash-protected. Live launcher diagnostic logs may append and are
excluded from player-file hashes; an earlier log-only false positive is retained.
Retained editor **64** / embedded **101** pass with the rebuilt signed Mac core.

Expanded normal-menu reviews pass **86 EN / 86 RU**: all three featured campaigns,
chapter previews/prose/default difficulty, actual Start/Begin/Continue/Load,
authored focus, saved chapter-three tools/native hero gate and treasury/pause,
three same-named autosaves in separate scopes, actual per-campaign static images,
enlarged layouts, prior profiles
and immutable source bytes. Both sequential Metal runs pass with scratch preferences.
Originals/model geometry/UV/VAT/LOD/native rules/RNG/save versions remain intact.
Windows kits are frozen and exclude Stonewatch; actual platforms/minimum machines,
newcomer/visual acceptance and retained-input commercial permissions remain open.
See [Stonewatch scope](STONEWATCH.md); this is private development content.


## Wheat growth and harvest readiness — 9 October 2026

Implemented the omitted 3D crop overlay for wheat farms and the native harvest
percentage/bar in the production inspector. `eFarmBase` exposes only read-only
growth/field getters; its saved timers, five-stage harvest, output quantity and
staffing rules remain unchanged. Separate crop observations do not invalidate
the architecture snapshot cache. The original farm GLB/source artwork and other
crop models are untouched. See `GODOT_FARM_CROPS.md` for the detailed contract.

`validate_farm_crops.gd` passes **34 checks** across EN/RU, including the shared
4,200-vertex field mesh/two reduced LODs, both UV anchor arrays, native field
bounds, changed-instance-only updates, unchanged/paused zero writes and removal.
Native checks use the designated city in memory with ordinary farming workforce
priority and native replay ticks. Inspector and crop progress agree; repeated
observations retain saved state/RNG and cached architecture. Pause and industry
shutdown hold growth, staffed ticks advance it, and a disposable native save/load
round trip preserves readiness. The designated source hash remains unchanged.
The initial run identified ProgressBar's default value rounding; explicit zero
step now retains the continuous native reading while text is floored to a whole
percentage. Final rerun passes all 34.

Final sequential `tools/review_farm_crops.py --lang en` / `ru` Metal/Mobile
galleries pass **39 checks each**. Original architecture, all five fields, GPU
growth data and translated percentages are verified at 0/20/50/85/98%.
Regrowth reuses the crop objects; reduced native field coverage and overlay
hiding work; all four facings preserve field foundations. These phases are
presentation samples, not injected native maturity.

Final sequential `--city --lang en` / `ru` runs pass **6 checks each** through
the actual `main.gd` receive/placement/inspection path. A real saved wheat farm
advances through ordinary native ticks to approximately 24.19%; its visible crop
and readiness reading agree. Additional mature city samples are explicitly
labeled, then restored; they leave serialized native state/RNG unchanged.
Growth-only snapshots preserve the live architecture and crop GPU objects.
Protected farm GLB, native source script, designated-save and player-preference
hashes remain unchanged in every visible review. Owned previews exit cleanly;
no final engine/script errors or outstanding model loaders remain.

Retained industry checks pass **140**, interface translations **7**, and native
SDL/embedded seeded replay **6 cases** (seeds 7/11, ticks 0/200/1200). Total
focused checks/cases: **277**. The native executable was rebuilt and atomically
installed on a freshly signed inode. A concurrent job was using the default
extension output folder; the helper now accepts `EZEUS_GODOT_BUILD_DIRECTORY`.
The completed build used `build-godot-wheat`, retained the pinned configuration,
and finalized/signed/atomically installed its staged library. No live game or
unowned build was stopped. Headless retains the known certificate warning;
CSV import completed with denied global editor-preference writes on exit.

Evidence under `godot/captures/`: `wheat-{native,industry,text}-validation.log`,
`wheat-extension-build.log`, `wheat-native-build.log`, `wheat-parity.log`,
`wheat-import.log`, `wheat-{en,ru}{,-city}-review.log`,
`wheat-{en,ru}-{00,20,50,85,98}.png`,
`wheat-{en,ru}-city-native.png` and
`wheat-{en,ru}-city-mature-sample.png`. Short/mature gallery and final native/mature
city captures in both languages were visually inspected.

Limits: wheat is the new visual crop; shared native farm readiness can also be
shown for other farms, but their 3D crop art is not added here. This does not
establish every campaign terrain/farm configuration or sustained minimum-device
GPU cost. Shader sway uses approximate rest-normal lighting. User visual
acceptance remains pending; existing villa provenance stays `needs_evidence`.

## Normal campaign menu and Continue — 9 October 2026

Final Metal campaign-library reviews pass **61 EN / 61 RU** over disposable native
chapter fixtures. Both authored campaigns lead normal New game; all three chapter
previews/goals, descriptions/default difficulty, optional full briefing, saved
progress labels and enlarged 1280×800/720 layouts pass. Actual Start/Begin begins
chapter one and retains authored focus. Actual Continue loads Bronze chapter three;
Load switches to First Light chapter two with correct goals/build permissions,
treasury and native pause. Same-named autosaves stay in distinct content scopes.
Prior-launcher/prototype saves load in place and can save locally without changing
source bytes; owned nested leader deletion and external-profile protection pass.
Fixture wins are explicitly structural; prior natural campaign proofs remain.

All retained adventure preview checks pass **256 / 58 previews** after exposing
native parent templates. Editor **64**, embedded **101**, save transaction **19**
and headless save reliability **36 EN / 36 RU** pass, including full immutable
parsing, facing/camera/speed, corrupt/legacy bodies, explicit recovery and cancelled
load restoration. The old Settings fixture expected three links; it now checks
the existing Display/Graphics/Interface/Controls hub. Menu regressions pass **30
EN / 30 RU**; results
and campaign captures are retained separately.

Bounded campaign/chapter hints do not authorize loading; actual probe episode
identity picks the new write scope. Checksum-aware hints avoid stale protected
replacements. Native payload/trailer versions, rules/RNG/ticks/decisions and model
geometry are unchanged. Both Mac targets are signed on new inodes. Windows core
compiles with six x64 DLLs/static import closure, without actual-platform proof.
The source campaign/profile/settings/numbers hashes remain intact. New thumbnails
are static renders from copied natural-play checkpoints, with recorded provenance.
Reports: `build-content-research/campaign-library/review-<lang>-visible/latest.json`;
scope/limits: `GODOT_CAMPAIGN_LIBRARY.md`. Windows ZIPs remain frozen. Clean-machine,
human pacing/minimum platforms and retained-input release permission remain open.

## Bronze River, second private campaign — 9 October 2026

Armory-based recipe v1 exports three parent/no-colony chapters on unchanged terrain
and replaces source writing/episode events/narration and trades. Authoring **9** and
sequential visible reviews **53 EN / 53 RU** pass: distinct localized titles/types/
goal counts, opening budget/terrain, staged native permissions and placement refusal,
footprint/treasury carry, chapter saves/reloads, trade closure/recovery, waiting date,
ending and actual menu briefing/Begin/build catalog. Structural wins are fixtures.

The final separate ordinary-command run naturally wins all three chapters: native
mining/bronze/armor, connected eight-cell river bridge, maintained industry, fleece
imports, actual armor exports, palace/taxes and an explicitly committed 16-armor
reserve. No test commands or state injections. Completions: **432 / 736 / 1,176**
residents; final annual armor **20**, profit **2,390**, export income **3,725**.
Direct trade counters observe annual armor sales **16** / fleece imports **32**.
567 commands and 2,660 service calls advance **792,900 native units** (~27.5 slowest-
speed unpaused minutes). This does not qualify human 45–90-minute pacing.

All **2,925** water-cell bridge previews execute safely and find **120** valid sites.
The first broad scan exposed null end neighbors near map edges in bridgeTiles;
guarding them rejects invalid crossings and preserves valid costs/footprints/rules.
Retained First Light chapter review, editor **64**, embedded **101**, fresh bootstrap
and protected source/First Light hashes pass. Mac native targets are signed/installed
on fresh inodes. Windows bridge fix compiles; six DLLs pass static import closure.
The old Windows ZIP remains unchanged and does not contain Bronze River.

Current manifest points to EN/RU visual reports/captures, natural result/trade proof
and launcher check. Earlier failed economic runs are diagnosis, not acceptance.
Human playtesting, minimum machines, this campaign's actual Windows build/run and
commercial retained-input permissions remain unverified. See `BRONZE_RIVER.md`.

## Three First Light chapters — 9 October 2026

Version-4 separate content identity exports three parent chapters on retained
terrain/roads/animals, with EN/RU prose and complete cumulative building permissions.
Authoring passes **9**; final sequential Metal reviews **38 EN / 38 RU** verify
briefings/goals, phased menus, retained footprints, checkpoints/save/reload, BC
waiting goal initially false then true, authored trade shutdown/recovery, ending
and actual menu/Begin. Structural victories are explicitly validator fixtures.

The separate normal-command run **naturally wins all three chapters**, without
test-mode commands, artificial goods/money/population or forced wins. It reaches
208, 608 and 648 people at the respective completions; final goals show timber 24,
working route 1, annual profit 1,046 and wheat 40 plus the met waiting date. Finance
reports final-year exports 1,650. It uses 241 ordinary commands/2,660 service calls
and advances 792,900 native units (~27.5 unpaused minutes at the slowest standard
speed). This is simulation completion/pacing evidence, not a measured human test.

Early runs stalled on appeal/fleece, zero export capacity and palace-less taxes;
the final successful run uses better placement/supply and ordinary stock orders.
Native rules remain; briefings now explain these requirements. Date-goal status
comparison fixes BC years without changing layout; date previews use copies and
zero-capacity export orders no longer meet the opt-in route goal.

Retained unlock checks **37 EN/RU**, editor **64**, embedded **101** pass. Mac
extension/reference are safely signed/installed; Windows x64 core recompiles with
six-DLL static closure. Updated Windows package manifest passes **12,097 files /
9,281,692,919 bytes** and ZIP is **6,519,084,130 bytes**; private scenario hashes and
source/notices are included, player/research files excluded. Windows execution is
unverified. Original kit, earlier prototype/profile, designated save/settings/live
game/Blender remain intact. Reports are under the private current manifest and
Windows Chapters package logs. See `FIRST_LIGHT_CHAPTERS.md` for exact scope.

## Campaign building permissions — 9 October 2026

Final scoped two-episode native fixture passes **37 EN / 37 RU**, covering ordinary
civic/science and industry permissions, culture/market/pier dependency gates,
catalog filtering and direct native preview/build refusal. `.epak` export, active
and future permission save/load, the next-parent transition and second-stage
reload agree. Fixture victories are test commands; no player outcomes are assumed.

The full First Light Harbor version-3 recipe passes **34 EN / 34 RU** visible
menu/Start/Begin and retained construction/save/event checks, including all current
objective prerequisites and hidden advanced/military/other-culture tools. Retained
building **505**, whole-campaign flow **26**, editor **64**, embedded **101** pass.
Both native targets build and are signed/installed on new inodes. Original source
archives and protected player files remain intact; no live process is stopped.

The keyed availability serialization/layout remains compatible; ordinary entries
carry empty levels. Missing overrides preserve older saved definitions. Existing
prototype saves are not migrated. Reports: private current.json points to
`episode-unlocks-en/ru` and `review-en/ru-visible`; broad retained logs are under
`build-content-research/`. Natural full playthrough, three-chapter choice, minimum
hardware/Windows and rights remain pending. See `GODOT_CAMPAIGN_BUILDINGS.md`.

## First Light Harbor adaptation — 8 October 2026

The final version-2 recipe exports one native parent/no colonies, 18,000/Mortal,
seven goals, new EN/RU writing and an authored neighbor from the private Alexandria
copy. Authoring passes **7** checks; parent tiles match before/after separation.
Original fan archives/data remain hash-identical. Terrain/roads/animals and native
coordinates are retained.

- Sequential Metal reviews: **32 EN / 32 RU**. The real menu uses the private
  catalog, Start shows localized prose and Begin adopts it into 3D with the guide.
  Native house/service/food/fleece/timber/trade sites, ordinary housing build,
  scratch save/immutable preflight/reload and objective retention pass. Native
  six-month disaster shutdown and 90-day reopening occur without a decision/payment.
- The optional route goal starts unmet and stays unmet for an unstaffed post
  without orders; its modifier survives reload. Default/original goals retain
  diplomatic counts (PAK import leaves the modifier zero). Full positive staffed
  export progression belongs to the pending natural playthrough.
- Retained editor **64**, embedded **101** pass. Editor covers unsafe/existing-name
  refusal, retained terrain, independent one-parent export/difficulty/readback and
  refusal of authoring in play. Both C++ targets rebuild and are signed/installed
  on new inodes. Live game/Blender and protected player files are retained.

Reports/captures are addressed by private `first-light-harbor/current.json`;
retained checks have sibling folders. Reviewer field/method errors were corrected
before final passes. The ending is a `test_win` fixture, not a natural win.
The exact bootstrap passes a fresh-roster headless launch/exit check after creating
its private save folder before the menu reads it; `bootstrap-check.json` records it.
Playthrough/balance/duration, minimum/long sessions, new Windows execution and
commercial rights remain unverified. See `FIRST_LIGHT_HARBOR.md`.

## Settlement guide stepper — 8 October 2026

The city help card's guide was redesigned after the user found it confusing (see
`GODOT_CITY_CLARITY.md`, "Stepper layout"): Issues | Guide segmented tabs, a
collapsible one-line tracker, a progress bar, a six-step list with live markers,
one expanded step card with a Done/Not yet strip and native counts, Build and view
buttons, Back/Next, a pulsing dock pointer, content-sized fitting above the minimap
and a visible `GuideScrollBar`. Only presentation changed: the same read-only
`city_attention` report, five-second visible-only polling, explicit step
advancement and the Finish/opt-out preference are retained.

- Sequential owned `tools/review_city_clarity.py --lang en` / `ru`: **134 checks
  each** (116 before). The 18 new checks cover the selected tab, native state and
  count on the current step, content sizing, minimap clearance at 1080p, the dock
  pointer for a tool and a category, Build opening the category and stopping the
  pointer, the overlay toggle on/off, Next/Back, collapse/expand, "Don't offer
  again", refresh restoration, first-unfinished-step opening and a visible scroll
  bar at 125% interface / 130% text in a 720p window.
- Some runs failed the retained "finish adds no draw calls" profile: its first
  sample averaged 1.1–1.6 extra draw calls. Probes traced this to the main
  viewport's canvas pass: the HUD's "Normal view" notice pill (`%Feedback`, two
  draw calls) was still fading. The guide test's view toggle posts that notice,
  which lasts 3.5 s of unpaused time; the validator's later pauses and native work
  stretched it into the profile on fast runs. The guide checks now wait for the
  notice to finish (at most 6 s). The help card itself was hidden, nothing was
  hovered and no 3D object differed.
- Translations: **7** (26 new rows, 11 retired; no orphans). Escape menu (EN):
  **68**. Theme: `build_ui_theme.gd -- --guide-only` adds only `Guide*` styles;
  a normalised diff shows no existing Theme entry changed.

Captures: `city-clarity-<lang>-guide.png` (designated city, five steps done),
`-guide-fresh.png` (a fresh-city sample report with the Housing pointer),
`-guide-folded.png`, `-large-guide.png` and `-attention.png`.

**Issues tab, same day.** Counted filter pills, severity-edged cards with one
full-card click target, a pager and an empty state (contracts in
`GODOT_CITY_CLARITY.md`, "Issues tab"). Final sequential EN/RU clarity reviews:
**142 checks each**, with four identical draw-call samples (**1,159.69**). The
eight new checks cover one card per warning on the page,
pill counts with All selected, the severity edge, the full-card click target, a
disabled empty pill, a pill narrowing the cards, the "1–8 of 109" pager and the
empty state. Captures:
`city-clarity-<lang>-issues.png` and `-issues-empty.png`. Translations: **7** (2
added, 2 retired). The filter check narrows with the first non-empty filter
(Production here) and checks an empty pill (Roads) is disabled.

Pending: user visual acceptance and a real fresh-adventure playthrough with the
guide.

## Fan adventure research — 8 October 2026

Six public archives downloaded through Zeus Heaven's normal download flow:
Alexandria, Armory, One Against the World, Everybody loves oranges, Tributaries 3
and Augea - Open Play. All six pass ZIP CRC/member/path/size checks; all extracted
campaign/map/editor/text data match recorded archive hashes. Originals remain
unchanged; the separate Alexandria working copy matches its extracted inputs.
Metadata and provenance are recorded in `CUSTOM_ADVENTURE_RESEARCH.md`,
`custom-adventures.provenance.json` and private `build-content-research/` records.

These checks establish downloaded-file integrity only. No native/Godot adventure
import, modified terrain, playable progression, full source originality or
commercial redistribution rights are claimed. No downloaded program was run,
runtime catalog changed, personal save loaded or live game/Blender stopped.

## Compiled private Windows transfer kit — 8 October 2026

The Windows x64 extension now **compiles/links on Mac** using isolated,
SHA256-verified Homebrew MinGW-w64 14.0.0 / GCC 16.2.0 compiler copies and a short
private source snapshot. No system compiler installation or live Mac DLL overwrite
occurred. Pinned SDL/Godot versions are retained. Portability fixes cover SDL helper
includes, integer headers, Windows timestamps/SDK macros, Windows DLL naming and
quoted dependency staging. Native rules/RNG/tick/save layout and art remain intact.

- Native ezeus_godot.dll (~16.9 MB) exports `ezeus_library_init`. Six x64 DLLs
  pass PE header and static import closure checks: the extension, SDL2, SDL image,
  ttf, mixer and libssp-0. The latter was identified by auditing the compiled
  mixer and bundled; stack protection was retained. `windows-compiled-audit.json`
  records the check. Windows system/API-set runtime behavior remains unverified.
- Official Windows Godot 4.6.3 archive SHA512 matches upstream. The complete
  archive is retained with runtime/GCC/SDL/codec/Godot source/license records,
  engine source, and existing monster attribution/reference catalogs.
- Mac portability rebuild completes, is signed/installed on a new inode and
  retains embedded checks **101** and filesystem save-store checks **19**.
  No native SDL executable, live game or Blender session is stopped.
- Official portable PowerShell 7.6.6 parser accepts both existing MSVC build/test
  scripts. This proves syntax only, not MSVC or Windows execution. MinGW's
  cross-build is a separate verified compilation path.
- The no-Python package orchestrator passes **36 save/recovery + 25 performance
  logic checks** on Mac, and repeats them successfully against an independent
  copied resource tree with editor/pipeline state and import MD5 records removed.
  It checks protected hashes and samples only owned-process memory. No source/
  player saves/settings changed. Logs/results are under
  `windows-kit-runtime-only-mac-check/`; `windows_execution=false` is explicit.
- Independent cold editor import reached only about 47% within ten minutes.
  The exploration was stopped only in the owned copy. The final kit includes
  **963 prepared runtime scenes/textures** plus UID/extension/class lookup,
  excluding editor preferences/filesystem/pipeline caches. This avoids a full
  editor import on the Dell. Windows desktop texture/scene compatibility still
  needs actual Windows execution.
- Independent kit checks found a capture-path bug: performance screenshots
  expected an excluded captures folder. They now use the report directory and
  are included in the result bundle. Repeated copied-resource checks pass after
  this fix. A retained ObjectDB exit warning occurs in the performance probe;
  no whole-game leak-free or long-session claim is made.
- Private kit manifest and file hashes are validated; personal Save directories,
  preferences, Mac binaries and editor/capture state are excluded. Only the
  designated test city is present. Original `.sav` files under Adventures remain
  scenario development content. Source/attribution checks and duplicate/archive
  integrity checks accompany the final ZIP and SHA256 sidecar.

The kit's Play/Run checks batch launchers require **actual Dell/Windows execution**.
No Windows FPS, minimum hardware, MSVC compilation, full standalone shipping or
independent-content clearance is claimed. The prepared artifacts are private
user development resources, not a public Steam build. See `WINDOWS_TESTING.md`
and `WINDOWS_CROSS_BUILD.md` for the handoff and reproducibility/evidence boundaries.

## Modern desktop baseline and platform preparation — 8 October 2026

The final scope follows the user's modern-hardware direction. Low and the
Compatibility crowd/material experiment were removed. Balanced/High retain
full-resolution rendering, MSAA, shadows, authored models/UVs, native crowd/map,
rules/RNG/timing and two shadow cascades. Windows selects Direct3D 12 with Vulkan
fallback; Mac retains Metal. Automatic OpenGL fallback is disabled.

- Final sequential owned graphics reviews: **37 EN / 37 RU** Metal checks, plus **37 headless**,
  covering defaults/type fallback, live sun/LOD/detail settings without world
  rebuilding, full resolution/shadows, native picking at two zoom levels, sharp
  UI, no preview writes, Apply/startup, Cancel/Escape/removal, failed writes,
  independent enlarged UI/text sizes and unchanged native digest/command queue.
  Logs/captures: `graphics-en.log`, `graphics-ru.log`,
  `graphics-balanced-*.png`, `graphics-high-*.png`.
- Retained nested menu reviews: **68 EN / 68 RU**. The extra assertion covers
  graphics Cancel returning to Game settings with the previous preset. The
  designated city is now open-play with no objectives, so the review explicitly
  supplies a disposable presentation objective for dismissal coverage; it does
  not install a native goal. Failure context is logged. Native state, menu
  pause/command holds and callbacks remain unchanged.
- New full-map performance run: **25 Metal / 25 headless checks**, `harness_verified=true`, zero
  engine errors, actual **1920×1080**, Mobile/Metal, Apple M4. Source city has
  **25,992 tiles / 841 building records / 279 walkers**. Requested/actual
  resolution is recorded: a prior windowed run was fitted to 1920×1018 by macOS,
  so it was superseded by the owned exact-size fullscreen run. VSync/frame cap
  were disabled; ordinary player display preferences were not altered.
- Paused Balanced frame p95: **17.04 / 16.43 / 14.72 ms** for stationary,
  near-pan and wide-pan; High: **18.85 / 19.59 / 19.65 ms**. Normal-speed
  near-pan p95 **16.75 ms**; native visible-fire view p95 **14.90 ms**.
  These are short wall-clock frame intervals on this host, not GPU timings or
  minimum-Mac qualification. The M4 does not pass every proposed strict 60-FPS
  p95 target in this run. GPU timing returned zero and is marked unavailable.
- Maximum speed retained its native decision block after about one second;
  p95 **30.76 ms**, p99 **34.26 ms** on that limited sample. No reply was
  invented. It is not a sustained maximum-speed or completed long-session test.
- Sampled owned-process RAM peak **1,959.8 MiB** (about 1.91 GiB), excluding
  load-probe child/other apps; graphics memory peak about **923.2 MiB**.
  Six guarded reloads cost **3.48–3.56 s**, including preflight, new scene and
  settling frames. The last three keep matching native gameplay digests; reported
  static memory stays **239.67–239.68 MiB** and graphics memory settles at
  **922.83 MiB**. This is short-run evidence, not a leak-free long-session claim.
  See `release-performance-mobile.json/.log`,
  `performance-mobile-balanced-pan_near.png` and
  `performance-mobile-balanced-native_fire.png`.
- Retained rebuilt embedded-core checks **101**, camera cache **31**, refresh
  **28**, locomotion **35**, sacrifice rites **47**, translations **7** and
  scratch save/recovery **36 headless** pass. The never-readied locomotion fixture
  now owns its nested ring/army/flight nodes before cleanup; its prior exit RID
  leaks are removed. No game renderer leak was inferred from that fixture.
- Mac extension configured/rebuilt successfully and signed/installed from a new
  inode. Installed runtime audit reports all five Mac dylibs require **macOS
  26.0**; SDL image/font/audio helpers retain external Homebrew dependencies.
  `platform-runtime-audit.json` therefore honestly has `target_ready=false`
  for the proposed macOS 14 floor. Windows artifact audit finds no local DLLs;
  no Windows compiler, PowerShell runtime or Windows launch was available here.

Windows x64 CMake/DLL staging, two guarded platform helpers, tracked extension
configuration and PowerShell build/save/performance instructions are implemented
and source-reviewed. Their MSVC/D3D12/Vulkan paths require the Dell run. Hardware
minimum/recommended tables are **proposals**. Oldest Mac/OS, standalone dependency
closure, cold import/loading, hour-scale sessions, broader disaster/campaign
coverage, installer/export packaging and cross-platform saves/replays remain
release acceptance work. No Linux/Steam Deck platform is validated. Designated
save/player settings fingerprints were unchanged throughout the owned reviews.

See `GODOT_RELEASE_PERFORMANCE.md`, `WINDOWS_TESTING.md` and the production roadmap.

## Save reliability and persistent presentation — 8 October 2026

Implemented unique staged file commits, content/version checks, file/directory
sync and atomic replacement. Per-name locks refuse another writer and release on
normal error/success. Two previous protected generations rotate; legacy imports
and detected damaged evidence are retained separately. Complete interrupted first
saves are discoverable and recoverable, while partial/bad data is refused. A CRC32
trailer includes facing/speed/camera in the same file without changing native
payload/version. Facing keys include board/city/type/seed/rect, avoiding pointer or
session-ID persistence. Current-view manual/quicksave/configured autosave callers
capture tile coordinates, yaw, pitch and distance. Loaded games remain paused.

Before Load/Continue replaces the scene, an owned headless probe fully parses an
immutable private copy. Corruption, unsupported versions, cancellation and timeout
leave the current city available. Recovery requires an explicit choice, shows local
file time and keeps the original/damaged source. There is no silent test-city
fallback. Exact previous pause/command holds restore after a cancelled failed load.
Native file reads reject impossible string/list requests and board dimensions;
remaining bytes are tracked in memory. Headless GLB warming is synchronous because
the dummy renderer produced invalid-RID errors during threaded resource setup;
Metal retains joined threaded warming.

Verification:

- `tools/test_save_store.py`: **19** temporary-filesystem checks, including exact
  two-generation bytes, write/backup/replace interruptions, writer exclusion,
  checksum corruption, damaged-primary preservation, legacy/native version,
  truncated headers and lock release.
- Sequential owned EN/RU Metal `review_save_reliability.py`: **36 checks each**;
  headless: **36**. Actual native save/reload restores facing, all four speeds,
  exact camera coordinates and actual scene orbit/zoom. Native gameplay digest
  remains identical. Three explicit validator failure points leave the committed
  primary unchanged and a valid pending copy. Corrupt load precheck preserves the
  live native board/building-cache records. Saving over damage cannot poison the
  good backup. Non-finite view data and overly long UTF-8 names are refused/bounded.
  Independent parser probes verify healthy/legacy copies, reject truncated legacy
  bodies and future versions, require explicit backup/pending-first-save recovery,
  preserve original evidence, and keep the live city and its pause/hold on failure.
- Retained `validate_saves.gd`: **34**, preserving native gameplay, roads, walls,
  gatehouse, mansions, parks, names, permitted directories and the designated source.
  Counts now distinguish primaries from their recovery copies.
- Retained actual scene loading: **14**, with scratch save/settings paths and
  explicit corrupt-start rejection instead of the old fallback assertion.
- Owned sequential start-menu/loading reviews: **40 EN / 40 RU**, including
  enlarged 1280×720 RU layout, one transition/session, input holds, native-time
  hold, translated loading/failure recovery and source-save guards. The fixture
  waits for isolated preflight before asserting the full-screen handoff.
- Existing Game-menu review: **67 EN**; embedded simulation: **101**; camera
  caches/controls: **31**; translations: **7**. Known older headless fixture
  cleanup warnings remain; save/recovery visible reviews exit without script or
  engine errors. New recovery strings are shared across both entry points.
- A newly guarded designated-derived save opens in the existing signed native
  reference with the same digest as the embedded core:
  `c69ba427b8ca8cdc:1646:279:4486720`. The footer is present; the legacy native reader
  ignores it. `save-compatibility-godot.log` / `save-compatibility-native.log` record
  the comparison. No native executable rebuild was needed for this evidence.

The first bounded-reader draft queried stream position for every primitive and
slowed city reading to roughly 3 seconds. The final byte-counter implementation
reads the test city in about **90–91 ms** in the scoped EN Metal/headless run;
this is load-read evidence, not a frame-rate or sustained minimum-hardware claim.
The older load validator initially left one uniquely named backup in the real
profile directory; only that owned artifact was removed, and the validator now
uses explicit temporary save/preferences for all output. Original/player save
files were not overwritten. The extension was staged/signed/atomically installed
on a separate inode; the user game and Blender were not stopped.

Evidence under `godot/captures/`: `save-store-unit.log`,
`save-reliability-{en,ru,en-headless}-*`, `save-retained-*`,
`save-load-retained-*`, `save-loading-{en,ru}-*`, `save-menu-en-summary.log`,
`save-{embedded,camera,translations}-*` and the native compatibility logs. Recovery,
accepted/interrupted/truncated/damaged/newer-version dialog captures use
`save-reliability-<lang>-<case>.png`. EN/RU recovery panels were visually inspected.
Contracts and remaining acceptance work: `GODOT_SAVE_RELIABILITY.md`.

Limits: actual power failure was simulated at transaction boundaries, not exercised
on hardware. Windows replacement code, network/removable storage, Steam Cloud,
whole-campaign/colony upgrade migrations, maximum-size/long-session files and
source-trailer removal by older writers remain unverified. CRC32 is accidental
corruption detection, not authentication; footerless files rely on isolated parser
validation. Conservative unknown-owner locks and pending/damaged artifact retention
still need user-facing housekeeping. A game loaded from a recovery source does
not silently repair or overwrite the original file.

## Construction reveal, foundation contact and guide, second pass — 7 October 2026

Compatible opaque vertex-palette sanctuary/pyramid pieces retain full mesh
proportions during construction. Native `grow` drives a world-height reveal in
MultiMesh custom blue/alpha; existing work flag/phase remain red/green. The shader
preserves original roughness, metal and vertex colour, with the shared restrained
stone finish. Unsupported textured/VAT/transparent/emissive parts keep their prior
growth path, and foundation-only court slabs stay native. Timber scaffolding
follows actual construction height and is removed on completion. Advice uses
native halted/road/needed-material/employee observations. Far-corner native pyramid
targets are accepted only by current ID and tile containment in the rendered
footprint. Costs, material delivery, rules, timing and ordinary instant placement
are unchanged.

Eligible static base hulls now receive bounded limestone supports where they stand
above existing land. The support overlaps its actual base contact band, stays
inside the lot/setback and skips roads, water, holes and drops above 0.88 tile.
Buildings keep their native level heights. Cached building data and dirty 32-tile
sections avoid repeated geometry work. The designated city contains **24,168**
support vertices (**8,056** simple triangles), mostly thin raised court plinths;
it has no large unfinished above-foundation monument in this snapshot, so initial
scaffold count is zero. Isolated 25/65/100% stage fixtures verify the actual reveal
shader and timber appearance. An analytical slope fixture uses a real house mesh
to inspect contact. These fixtures add no native entity or saved geometry.

Empty newly begun games offer the non-modal guide after loading if the player has
not explicitly finished it. Finish saves only the presentation preference; manual
? / Game access remains. A native first-step smoke clears owned land through normal
demolition in a disposable designated copy, retaining native non-demolishable
bridge/entry roads, then builds a fourteen-cell road, vacant home, fountain and
maintenance office. It verifies no invented residents/supplies/milestones and
real worker shortages despite valid edge road connections. No new adventure,
personal save, test stock or test residents are used.

Verification with the final scripts:

- Sequential owned EN/RU Metal clarity/site reviews: **116 checks each**, clean
  exits and return to the start menu. All earlier live warnings/layout/scaling,
  inspector, guide, material, audio, contact and undo checks are retained.
  New checks cover site cache reuse, lot/road/water/hole exclusion, native full
  proportions and fallback slabs, brace end positions, stage height and completion
  removal, construction explanations, first-game guide offer/completion preference
  and native state preservation. Real GPU readback verifies independent per-building
  reveal flags and a **20.25** world height without alpha clamping; changing the
  cutoff alone uploads custom data without a geometry rebuild.
- Headless clarity/site review: **115 checks**; its dummy renderer uses cached
  upload data instead of pretending to read GPU buffers. Both language Metal runs
  perform actual GPU readback.
- Retained placement review: **95** checks pass after the reveal/support changes.
  Preview/placed transforms, native prices, all facing, widened roads, drag/undo
  and protected save/preferences remain intact.
- Native elevation: **22**, retaining exact native foundations and height sampling.
  Camera cache/controls: **31**. Incremental refresh/batches: **28**. All **47**
  work assets: **219**, retaining staffing, shutdown, speeds, pauses/decisions and
  **107,151,360** VAT bytes. Translations: **7**. Two existing Russian rows with
  unquoted commas were corrected alongside the new construction explanations.

The first-pass replay assertion had not registered its scratch save directory and
compared rejected loads; its earlier replay claim is superseded. The corrected
gate requires a successfully loaded snapshot, checks identical gameplay state and
serialized save bytes before/after twenty attention reads in the same session, then
compares actual seeded gameplay digests/sections after sixty ticks in separate
loads. Both produce `a00980b79f9b438e:1615:281:4487020` with zero worker-thread RNG.
Cross-load binary save hashes differ and are recorded without claiming byte
determinism across loads. `city-help-replay-comparison.json` records this evidence.

Final native report means are approximately **0.65 ms EN / 0.66 ms RU** in this
session. Matched finish baseline/enabled views both average **1,159.79** draw calls;
these compare the stone finish within the same current site presentation, not a
before/after comparison of support geometry. The latter adds a small static mesh
per populated support section. GPU timing still returns zero/unavailable; no
minimum-Mac or sustained frame-time guarantee is claimed. Known cleanup warnings
remain in the older headless camera/translation fixtures; the new visible reviews
exit without script/engine errors. No user game, personal save or Blender scene
was stopped, modified or overwritten.

Evidence: `city-sites-en/ru-summary.log`, `city-clarity-en/ru.json` and their engine
logs, `city-sites-headless-summary.log` / `city-clarity-en-headless.json`,
`sites-placement-final-summary.log`, `city-sites-{elevation,camera,refresh,activity,
translations}-*`. `city-sites-<lang>-stages.png` and `-support.png` were visually
inspected; all EN/RU attention/guide/enlarged/Sound captures are also regenerated.
Contracts: `GODOT_CITY_CLARITY.md`.

Still pending: full first-settlement immigration/food-distribution/budget success,
broader adventure/composite-owner coverage, painted textures, authored construction
workers/material piles, full foot IK, longer/mastered original music, visual/audio
acceptance and minimum-Mac profiling. The support drop cap, source-base hull band
and clipped open construction surfaces are deliberate first-pass art limits.

## City clarity and shared art finish, first pass — 7 October 2026

Implemented a read-only native attention report, actionable inspector advice,
filtered warning navigation and a six-step manual settlement guide. Static roads
are counted from `allBuildings()`, rather than the timed-building list. Current
player objects without emitted/selectable presentation records are excluded.
Full producer output/overflow is a pickup hint; native production states remain
unchanged. Current housing decline is distinguished from optional improvements.
Help uses shared Theme/CSV, visible-only five-second reads with pointer holds,
ID/footprint checks and existing overlays. Opening it from the menu restores the
prior pause/queue state. The header ? entry remains visible at enlarged sizes.

Eligible static architecture shares restrained stone colour/roughness variation,
with derivative fading and continuous grain. Textured/metal/emissive/VAT and
citizen/monster finishes, source GLBs, both UVs, palettes and LODs are retained.
Existing eight-pose work cycles use periodic bounded cubic interpolation. Cached
human root clearance near slopes is capped at 0.065 tiles and skips level ground,
boats, gods, perches and combat. Monument inspectors show actual native percentage
progress. A default-off original synthesized lyre/flute and wind/bird soundscape
has reproducible generator/output hashes; battle/effects/voices retain their
current paths. Sound settings scroll within a bounded window at enlarged text.

Verification with the final rebuilt/ad-hoc-signed extension:

- Owned sequential `tools/review_city_clarity.py --lang en` / `ru` reported **74 checks
  each**, clean exits and normal return to the start menu. The rejected-load replay
  comparison in this fixture is corrected/superseded by the second-pass evidence above. Live reads preserve
  inspector tokens/storage and the clock. All **109** initial warning targets
  agree with native inspection; exercised kinds include understaffing, inputs,
  output pickup, missing targets and construction. A real disposable roadless
  maintenance office verifies warning navigation and removal on native undo.
  Stale IDs are rejected, filters lead with the selected cause, and optional
  housing upgrades stay informational. Guide milestones, translated controls,
  menu restoration and enlarged 1280×720 layouts pass. Seven everyday/defence
  model templates use the shared finish; metal/textured parts are retained.
  Runtime work holds, construction bar, synthetic slope cache/invalidation and
  shipped WAV resources/options are exercised.
- Focused headless review: **73 checks**, with separate
  `city-clarity-en-headless.json` evidence. GPU comparison is intentionally skipped.
- Retained owned status/HUD/context reviews pass in EN/RU, including **48**
  status/overlay/accessibility and **46** context checks per run, editor draft
  retention, related overlays and the existing viewport/size matrix. The old
  minimap fixture now clicks the visible fold button rather than the hidden opener.
- Sequential owned Escape-menu reviews: **67 checks each**, preserving native
  city/timing/callbacks, prior pause/queue hold, settings/navigation/language and
  enlarged scrolling. Rebuilding popup menus had removed their right-click helper;
  the helper now survives/reconnects. Popup tests enter through local Window input,
  and journal bounds match the current layout beside the icon rail.
- Embedded core: **101** retained checks. Building activity: **219**, all **47**
  assets / **107,151,360** VAT bytes, including native staffing, shutdown, speeds,
  pause and pending decisions. Audio: **31** retained checks. Camera caches: **31**
  retained checks. Translations: **7**, with replaced explanations removed from
  the catalog. Source/output soundscape hashes and Python syntax also verify.

Protected save/source preferences remain unchanged. No user's running game or
Blender document was closed. The extension was built to a separate staging path,
signed on a new inode and installed atomically; relaunch picks it up. Headless
camera/translation and older status/menu fixtures retain their known cleanup
warnings; the new visible clarity reviews have no script/engine errors or leaks.

The final native report averages **2.46 ms EN / 1.60 ms RU** over twenty paused
reads (ranges **2.01–5.57 / 1.52–1.74 ms**) on this M4 while the user's game remains
open. It is not polled while folded. Matched moving-view baseline/finish passes
have identical **1,145.46** average draw calls in both language runs. Render CPU
samples vary around **0.80–1.11 ms** after warm-up; no consistent GPU/frame-time
claim is made. Metal's GPU-time observation returns zero here, so GPU cost remains
unavailable. The comparison uses four alternating modes, thirty warm-up and
eighty moving frames each; it changes only static finish and work interpolation.

Evidence under `godot/captures/`: `city-clarity-en/ru.json`, their `-engine.log`,
`city-help-final-clarity-en/ru-summary.log`, `city-help-status-en/ru-summary.log`,
`city-help-final-escape-en/ru-summary.log`, and
`city-help-{embedded,activity,audio,camera,translations}-*`. Captures per language:
`city-clarity-<lang>-attention.png`, `-guide.png`, `-large-guide.png`,
`-large-sound.png` and `-city-finish.png`. The enlarged guide and Sound dialog
were visually inspected; content scrolls without hiding the dialog's Done button.

Scope limits: initial native city plus controlled disposable fixtures, not a
fresh-settlement playthrough or whole-adventure warning audit. Internal owner
navigation, independently planted feet/full slope IK, building slope skirts,
painted PBR, newly authored worker/construction motion, a longer/mastered original
soundtrack, visual/listening acceptance and sustained minimum-Mac GPU/frame pacing
remain pending. Ordinary native instant placement retains its timing. No monster,
Hydra, native recipe/rule/save or campaign asset was modified by this pass. See
`GODOT_CITY_CLARITY.md` for implementation and maintenance contracts.

## Building refresh performance, second pass — 7 October 2026

Changed native building lists always replace inspection records. Their exact
ordered rendering key includes IDs/assets, position/footprint/altitude,
orientation/growth/stretch, work flags/phases and occupied bay indices/goods,
plus map/placement/overlay revisions. Stock quantities and staffing totals alone
skip the scene rebuild; explicit road/terrain/overlay invalidation bypasses it.
Actual visible changes remain immediate. Chart footprint/category rows avoid
stock-only texture repainting, preserve building colours over terrain deltas and
reveal updated terrain on demolition. Empty Agora paving nodes persist by ID and
are freed on replacement. Fixed-template MultiMesh nodes/buffers persist through
movement/count changes; resizing restores all independent activity data. Cached
immutable animal VAT finishes share matching texture/finish values while retaining
per-instance pose/layout, original palette and all source/LOD/UV contracts.

Verification:

- `validate_refresh_performance.gd`: **28** checks on real chart pixels, negative
  map origins, terrain beneath buildings, demolition/evolution/overlap order,
  batch growth/compaction/removal, selective work/phase uploads and independent
  animal poses/finish values. It exits cleanly with the headless renderer.
- `validate_building_activity.gd`: **219** checks across all **47** current work
  assets, including EN/RU native staffing, shutdown/resume, all speed levels,
  pause/decision holds and derivative/address/animation contracts.
- `validate_storage_goods.gd`: **204** native inventory/asset/batch checks. Its
  unused eager main-scene preload was removed so autoload names resolve normally;
  the final gate has no script/engine errors.
- Retained `validate_camera_performance.gd`: **31** checks, including the unchanged
  0.00191-tile wheel anchoring bound and cache/idle/combat transitions. It retains
  the previously documented un-readied-main ObjectDB cleanup warning.
- Owned Metal camera review passes **60** checks covering native stock/work/occupied bay/footprint,
  rendered growth, forced invalidation, empty Agora replacement, overlay
  entry/exit, actual GPU transform/custom-data readback and all retained camera
  behaviors. Disposable presentation records cover Agora spaces because this
  save has none; they never issue a native build command. The benchmark verifies
  native time, buildings, walkers and tiles before/after, and file guards retain
  the designated save and all protected player settings.
- Owned `tools/review_placement_clearance.py`: **95** native road, preview/placed
  transform, all facing, native cost, area-drag and undo checks pass cleanly with
  protected save/preferences unchanged.

All **637** scoped checks pass. Logs under `godot/captures/`:
`refresh-performance-checks-engine.log`, `refresh-building-activity-engine.log`,
`refresh-storage-goods-engine.log`, `refresh-camera-checks-engine.log`,
`camera-performance-review-engine.log` and `placement-clearance-review.log`.
Owned visible reviews run sequentially and exit without script/engine errors.

The refresh benchmark alternates **120** old/current pairs on one paused,
25,992-tile native city snapshot within the same Metal run. Frozen previous
building-loop/batch methods live under `tools/profile_baselines/`; the temporary
subclass uses the previous full chart paint. Hidden baseline batches share
already loaded templates, avoiding duplicate geometry or startup-load comparison.
The fixture contains no empty Agora spaces, so paving reuse is behaviorally
verified separately. No benchmark override is installed into gameplay.

| Routine building-refresh CPU work | Previous path | Current path |
| --- | ---: | ---: |
| Mean | 13.354 ms | 2.101 ms |
| Median | 12.822 ms | 1.965 ms |
| p95 | 21.362 ms | 3.538 ms |
| Maximum | 22.960 ms | 3.803 ms |

This is approximately **84% less routine refresh CPU work**, not an FPS claim.
Evidence: `building-refresh-comparison.json`; latest full movement evidence:
`camera-performance-review.json`. Background workload was heavier than in the
first-pass session, including the live game, so its absolute frame intervals
are not directly comparable. The paired comparison controls the snapshot and
alternates order within each frame; scheduling still affects the tails.
During ordinary native speed-1 panning, four routine building refreshes take
1.652–2.044 ms and one full visible-change refresh takes 8.052 ms. Stationary
running also includes full-refresh spikes up to 16.809 ms. The filter reduces
routine work; genuine scene changes and cold loads retain their full path.
Native cadence/RNG/saves, graphics preferences, mesh/material appearance and
model quality remain unchanged. First-use model loading, genuine geometry
changes, GPU timing, sustained minimum-Mac profiling and the user's exact city
and hardware gestures remain pending.

## Camera performance and wheel easing — 7 October 2026

Presentation-only changes reuse citizen ground/lane results, building placements
and camera footprints. Road-kind indexing is updated from the existing tile
delta, without an added steady map scan. Citizens retain native interpolation,
planar gait distance and animation clocks. Identical VAT aliases/held poses skip
shader writes; combat owns the same pose cache so returning to walking cannot
retain a combat frame. Road/elevation and native geometry/growth edits invalidate
placements before the existing incremental batches update.

Wheel events now accumulate a bounded destination and ease exponentially while
preserving the terrain point under the cursor. Pinch/direct callers remain
immediate. Modal/text/toolbar holds and Home/Go to cancel pending motion; an
outward limit crossing still opens the atlas. A folded minimap omits hidden
footprint work, while native view-box/sound observations remain active. Detailed
physician spare preparation now requires nearby detail in use: a longer profile
found a 27.8 ms LOD preparation hitch while the camera was too far away to display
any physician skeleton. The final profile's LOD section peaks at 0.059 ms in the
running pan; nearest-first assignment, hysteresis and the 24-model cap remain.

Verification:

- `validate_camera_performance.gd`: **31** behavioral checks for accumulated,
  bounded, frame-rate-independent zoom; slope anchoring (0.00191-tile maximum
  drift); cancellation; road index edits; held-citizen height/offset invalidation;
  cached building work/growth/road/footprint changes; native-record immutability;
  and cached idle/combat transitions. No native city is opened.
- Retained `validate_controls.gd` **65**, `validate_streets.gd` **70** and
  `validate_locomotion.gd` **35** pass. `validate_citizen.gd` passes **39**, adding
  the distant-physician no-load/no-instantiation regression while retaining real
  nearest-first skeleton swaps, exact gait state, reuse and hysteresis.
- Owned `tools/review_placement_clearance.py` passes **95** Metal checks, including
  preview/placed-transform equality, native road edits, facings, building costs
  and undo. The save and player preference hashes remain unchanged.
- Owned `tools/review_camera_performance.py` passes **15** full-city Metal checks
  on the 25,992-tile designated save at 1920×1080. It covers cache invalidation,
  fold/open minimap behavior, native sound bounds, actual wheel input, Go to and
  unchanged native walker tracks during paused rendering. Its temporary city
  subclass inserts timers into the current `_process` body only for this run.
  Each of seven timing conditions records 240 frames, with stationary/panning,
  near/wide views, a diagnostic no-3D condition and ordinary speed-1 native ticks.
  Required decisions are never auto-answered; a native block ends that sample.

All **350** scoped behavioral checks pass. Logs: `camera-performance-checks-engine.log`,
`camera-controls-engine.log`, `camera-streets-engine.log`,
`camera-locomotion-engine.log`, `camera-citizen-engine.log`,
`placement-clearance-review.log`, `camera-performance-review-engine.log` under
`godot/captures/`. The two un-readied-main headless fixtures retain ObjectDB
cleanup warnings; the older locomotion fixture also retains its known unused
ring/canvas dummy-renderer cleanup diagnostics. The owned Metal reviews exit
without script/engine errors and preserve all protected hashes.

Measured CPU work (Apple M4, Metal/Mobile, full designated city, distance 33):

| Running panning measurement | Before | Final |
| --- | ---: | ---: |
| City presentation, mean | 7.675 ms | 5.694 ms |
| Citizen frame updates, mean | 7.055 ms | 5.141 ms |
| City presentation, p95 | 8.870 ms | 6.530 ms |
| Observed total frame interval, p95 | 19.779 ms | 18.472 ms |
| Observed total frame interval, maximum | 27.969 ms | 23.842 ms |

Baseline evidence is `camera-profile-running-2026-10-07.json` (120-frame
conditions); final first-pass evidence is `camera-performance-pass1-final.json` (240-frame
conditions). The same initial city, view anchor, resolution and smooth eight-tile
pan are used. Short samples and background scheduling limit tail comparisons;
these numbers establish reduced presentation CPU work, not an FPS guarantee.
Average pacing remains near 60 Hz. In the initial matched 120-frame after pass,
the expensive building refresh fell from 11.364 to 6.361 ms; the longer final
pan includes different inventory changes and peaks at 7.1 ms.

No native extension rebuild, model/LOD reduction, graphics preference, art export
or save conversion is part of this change. First-use model instantiation, native
refresh spikes, GPU timing, sustained minimum-Mac profiling and the user's exact
city/input recording remain open performance scope. Scroll smoothing is validated
behaviorally; the profiler pans the camera directly rather than replaying recorded
hardware gestures.

## Character panel and live supplies — 7 October 2026

The right-click character card now shares the dock's charcoal/bronze styling,
uses a smaller portrait, an inset speech/voice section and a separate persistent
footer. Peddlers display their own linked Agora's live supply cards; transport
carts display actual goods/load counts and growers report collected items.
The native peddler consumes Agora vendor stock directly and has no independent
cart inventory. The source caption makes that relationship explicit.
`GODOT_CHARACTER_INVENTORY.md` records the observation and UI contracts.

The final native extension was relinked and finalized/signed through
`tools/prepare_godot_dependencies.py --finalize`. Native rules, paths, stock
distribution, save serialization and character art are retained. No SDL
executable rebuild or Blender export was required.

- `validate_character_inventory.gd` passes **94 checks** across EN/RU. After
  200 normal native ticks spawn a real peddler from the existing Agora, the
  fixture pauses. Its supply coordinates resolve to a real vendor inspector;
  stock/capacity/presence match that Agora exactly. Actual transporter/trailer
  loads match native walker observations. Unknown walkers are rejected and
  all subsequent inventory queries leave the entire native snapshot unchanged
  except its sequence number.
- Sequential owned `tools/review_character_panel.py --lang en` / `ru` pass
  **113 checks each** in Metal/Mobile. They cover real right-click opening,
  peddler/cargo cards, stable in-place count refresh without speech/portrait
  replacement, native pause/queue hold, retained voice and other-walker controls,
  Go to/Close, 73 portrait/model switches, and bounded 1280×720 layout with
  interface/text sizes 125/130. Long content scrolls above the reachable footer.
  Save and player-preference hashes remain unchanged; both owned previews exit
  with no engine/script errors. EN retains an ObjectDB cleanup warning.
- The signed extension passes **101 retained embedded checks**. The shared
  interface text gate passes **7 checks**, including the new EN/RU inventory
  captions. All **428 scoped checks** pass.

Final peddler, cargo and enlarged-text EN/RU captures were visually inspected.
Evidence: `godot/captures/character-inventory-engine.log`,
`character-embedded-engine.log`, `character-text-engine.log`,
`character-{en,ru}-engine.log`, and
`character-{peddler,peddler-large,cargo}-{en,ru}.png`.
The headless runs retain the known macOS certificate warning and missing
audio/adventure-source diagnostics. The review launcher uses `--skip-start`
and disposable settings/save directories. Native coordinate checks use
`x()/y()`, including negative coordinates on irregular boards.

Scope: read-only character inventories and the existing character window.
Other roles with no exposed native cargo observation do not receive invented
counts. Broader campaign coverage, minimum-Mac profiling and user visual
acceptance remain pending.

## Slim instant notices — 7 October 2026

Open instant notices now omit the title/icon row and Close button. The existing
full body, shared NoticeBody font and thin progress bar remain. Mouse release on
the card pins/unpins; right-click release follows its original informational
dismissal signal. Journal headings and required correspondence remain intact.
This is a GDScript/CSV change; no native build, model export, rule, RNG, event
record or save-format modification is part of this task.

`validate_notification_layout.gd` passes **14 checks**: stable full width after
60 frames, absent header/button row, complete wrapping, pin/unpin, independent
UI/text scaling, bounded long-text scrolling and stable refresh, retained titled
journal disclosures with idle-disabled folding, a slim one-line notice and
keyboard pinning without a title button. `validate_ui_text.gd` passes **7**,
including the translated right-click help and no orphan CSV rows.

Sequential owned `tools/review_chrome.py --notifications-only --lang en` / `ru`
pass **53 checks each** in Metal/Mobile. The focused mode instantiates the actual
HUD and notice widgets over a neutral background with synthetic informational
reports and a callback sink; it never starts a native city. It covers 1920×1080
and 1280×720 at UI/text 100/100 and 125/130, including real mouse press/release
pin/unpin, right-click dismissal, queue advancement, automatic expiry, hidden
journal timer holds, full long-report scrolling, refresh/width retention and
shared font sizing. The source save and player preference hashes remain
unchanged. Both previews exit cleanly with no engine/script errors. Final short
and long EN/RU captures were visually inspected.

Evidence: `godot/captures/slim-notices-{layout,text,import}.log`,
`chrome-{en,ru}-notifications-engine.log`,
`slim-notices-chrome-{en,ru}-output.log`, and
`chrome-{en,ru}-{1920,1280}-{100,125}-{slim-notice,notice}.png`.
All **127 focused checks** pass. The screenshot helper now waits for the normal
post-draw frame instead of forcing a synchronous rendering-server draw.

Limits: full-city Metal attempts did not finish, one during a capture and one
while loading the designated city. Their owned previews were closed and their
protected hashes were unchanged. The final focused UI evidence establishes
notification layout/input behavior, not full-city renderer stability or new
native event coverage. Headless retains the known macOS certificate warning;
CSV import completed with sandbox-denied global editor-preference writes on
exit. User visual acceptance remains pending.

## Monster anatomical rebuild and installed poses — 7 October 2026

Installed `monster_anatomy_v3` geometry for all sixteen non-Hydra monsters from
the user's Monsters folder. The files in that folder match the retained concept
sheets byte for byte. Full human bodies, actual canine body/faces, a detailed
cave-lion face and crocodilian skull planes replace the rounded sculptures;
the unchanged anatomical quadruped library supplies boar/goat/hybrid joints.
Editable neutral v3 scenes, original vendor archives, adaptation/license credits,
source hashes and previous runtime assets are retained in parent `art/monsters/`.
Rendered inspection prompted corrections to cloven feet, hybrid torso/neck
junctions, wing roots/dorsal plates, canine irises and the single Cyclops eye.
The final corrected exports were validated, optimized, installed, rebaked and
imported before the checks below.

- `tools/validate_monster_reference.py` passes **174 checks** on the final sixteen
  candidates: 114 aliases each, both UVs/palette, finite pose envelopes, scale,
  grounded collapse, species mouth counts, in-place roots and support contacts.
  Neutral heights are **1.79–2.14 tiles**; the highest non-death sample is
  **2.323043**, below the 2.455466-tile Zeus body. Decoded vertices are
  **12,586–26,539**; the maximum triangle count is **30,908**. Source allocations
  remain at or below 16,500 points and all models use two or three surfaces.
- The lossless comparison against the exact final raw exports verifies
  **16 models, 37 primitives and 4,181 morph frames, zero differences** in
  geometry, normals, palette and both UV sets. The original raw files are in
  `art/monsters/anatomy-v3/raw-runtime/`; UV removal was not used.
- `validate_monster_reference.gd` passes **210 checks** against the installed
  imports and fresh VAT twins: geometry caps, reduced LODs below 30%, correct v3
  identity/scale, shared finishes/pose textures, both attack clips, held death,
  pause and every interpolated mouth transform. Only the sixteen deliberate
  geometry-baseline entries changed; a comparison with the saved baseline
  confirms all other entries and metadata are unchanged.
- Final pose textures total **228 MiB** for these sixteen development assets.
  Scoped `validate_poses.gd` verifies all sixteen fresh derivatives and **2,878
  frames**, with maximum fingerprint gap **0.001852**, below the 0.004 threshold.
  These storage measurements are not a minimum-Mac performance result.
- Retained Hydra / native monsters / native effects checks pass **17 / 36 / 77**.
  The geometry gate passes all four retained assertions across 441 models,
  including LOD coverage and baseline growth limits. Native rules, recipes,
  collision, attack timing/damage, RNG and saves remain authoritative.
- The final Mobile/Metal studio renders **all sixteen installed models** from
  front, side, back, three-quarter, attack and fallen views, plus citizen/Zeus
  comparisons. Previous geometry was rendered with the same current finish,
  lighting and distance. The actual renders were inspected, including corrected
  connections, hooves and eye visibility. Sequential disposable Cerberus native
  attack reviews pass **14 EN and 14 RU checks**, capturing breath, impact and
  real building collapse; original save and player preference guards pass.

Evidence: `monster-anatomy-v3-validation.json/.log`,
`monster-anatomy-v3-lossless.log`, `monster-anatomy-v3-runtime.json/.log`,
`monster-anatomy-v3-final-import-engine.log`, the `monster-anatomy-v3-validate_*`
logs, `monster-anatomy-v3-installed-review.log`, `monsters-v3/`,
`monster-anatomy-v3-native-en.log` / `-ru.log`, and the Cerberus native phase
captures in `godot/captures/`. The gallery is
`art/monsters/anatomy-v3/comparison.html`; it links all editable v3 scenes.
`protected-check.json` confirms eight retained Hydra/runtime/save hashes;
the shared human/animal data and Hydra adapter also match their recorded hashes.
Background exports did not operate on the live philosopher Blender document.

Scope: anatomical development meshes and procedural preview materials. Full
painted PBR textures, user visual acceptance, slope foot IK, harpy flight
refinement, minimum-Mac profiling and overall release-rights evidence remain
pending. Library licenses are recorded separately from reference-image rights.
Retained fixtures still report the known missing audio/adventure resources;
the final checks and visible reviews have no script/engine errors. No native
extension or executable rebuild was required.

## Common-house models, neutral yards and level heights — 6 October 2026

Seven installed common-house models use `tools/godot_housing.py` through the
existing background exporter. Levels 0/1 have new original starter architecture;
levels 2–6 retain the native source geometry with deliberate height proportions.
Golden rectangular earth mats/bottom slabs are replaced by muted irregular soil
patches, with grey limestone for paved courts. Architecture rises through
0.96/1.16/1.36/1.58/1.84/2.18/2.56 tiles; resident anatomy is counter-scaled.

`validate_housing_art.gd` passes **55 checks**. The gate verifies installed source,
revision and level, exact authored heights and monotonic growth, unchanged
resident dimensions, both UVs and vertex palettes, at most three PBR mesh groups,
finite geometry within the native 2×2 footprint, bounded source/imported geometry,
effective reduced LODs and actual imported neutral-earth/brown-reed colors.
Its explicit `--write-baseline` refreshed only the seven intended house entries.
Source vertices total 153,299 (previously 512,685, about 70% fewer); imported
surface seams produce different GPU vertex counts. No FPS gain is claimed.

Retained `validate_housing.gd` passes **30 checks**, covering native common/elite
housing and parks, area placement, exact prices, undo and refused commands.
The owned disposable `tools/review_housing_art.py` passes **25 Metal/Mobile checks**
with no engine/script errors. It renders every installed model at native size,
substitutes each house level into one existing building observation, verifies
the retained ID/footprint/foundation, restores the original city, checks the
on-demand starter thumbnail and compares the complete native snapshots. The
render-only gallery never enters the native simulation. Save, settings and
native sprite recipe/Blender-source hashes remain unchanged. Owned review exits.

Visually inspected `housing-progression.png`, `housing-starter-levels.png`,
`housing-upper-levels.png`, `housing-city-houses.png` and `housing-catalog.png`
in `godot/captures/` show the
new family, first two levels, existing house block and matching catalog preview.
Additional evidence: `housing-art-engine.log`, `housing-runtime.json`,
`housing-native-engine.log`, `housing-review-engine.log`, `housing-import-engine.log`.
The first visible fixture attempt stopped at an incorrect thumbnail helper name;
the corrected final run uses the existing request/cache API and passes all 25.
Import succeeded; headless retains the known macOS certificate warning and the
sandbox importer reported denied global editor preference writes on exit.

Scope: common a variants only. Native rules/RNG/saves, b variants and elite house
models remain intact. Higher-level source provenance stays `needs_evidence`.
Preview PBR palette materials are not a full texture bake; user visual acceptance,
all-campaign street context, animated household tasks and sustained minimum-Mac
performance remain pending. No native extension/executable rebuild was required.

## Ruin names, panel clearing and complete footprints — 6 October 2026

Implemented native former-building names, a costed Demolish action and complete
ruin selection/hover/rectangle contact. Native per-tile rubble and save fields
remain intact; new collapses attach only a transient site identity. The signed
extension was rebuilt with `tools/build_godot_extension.sh`; the retained native
executable was rebuilt/copied/ad-hoc signed as required.

Final `validate_ruins.gd` passes **75 checks** across EN/RU. Its designated city
is held in memory; adjacent native 3×3 buildings and a neighboring park are
constructed and collapsed, then round-tripped through a disposable native save.
Checks cover native original names, each corner/cell yielding the same complete
site, separate adjacent sites after reload, one rectangle plate at the full cost,
panel availability and guarded command, pending/queue handoff, stale selection
and reload rejection, inspector refresh leaving another hover guard unchanged,
any-member fire exclusion, exact native clearing charges, full removal and
neighbor preservation. The source save hash remains unchanged.

Sequential disposable `tools/review_ruins.py --lang en` / `ru` Metal/Mobile runs
pass **10 checks each** with no engine/script errors. The actual city's native
3×3 University is collapsed in memory. Its translated former name, complete
selection, status/costed button, ordinary pointer hover after multiple frames,
single held-press plan and full native cost are verified. Real panel mouse
press/release clears all rubble, closes inspection and preserves pause/time.
Protected designated-save and player-preference hashes remain unchanged; owned
previews close after the review. Final inspector and hover captures in both
languages were visually inspected.

Retained gates pass: area demolition **26**, disasters **22**, embedded core
**101**, interface translations **7**, and SDL/embedded seeded replay **6 cases**
(seeds 7/11 at 0/200/1200 ticks). Headless retains the known macOS certificate
warning. CSV import completed; sandbox-denied editor preference writes were
reported on importer exit, without changing player preferences.

Evidence in `godot/captures/`: `ruins-validation.log`,
`ruins-{en,ru}-engine.log`, `ruins-{en,ru}-{inspector,hover,cleared}.png`,
`ruins-{area,disasters,embedded,text}-validation.log`, `ruins-parity.log`,
`ruins-extension-build.log`, `ruins-native-build.log` and `ruins-import.log`.
The visible wrapper and headless fixture use scratch saves/preferences and never
overwrite the designated city. No GLB, VAT or geometry baseline export is part
of this fix.

Limits: legacy native saves record former type and rubble creation order, but no
original site ID or footprint. Complete adjacent rectangular sites are verified;
already fragmented, unknown-type or compound legacy sites use conservative
bounded recovery and may show a smaller footprint. New collapses retain their
exact site bounds, including horse-ranch enclosure tiles. Wider campaign and
compound-building coverage, minimum-Mac profiling and user visual acceptance
remain pending.

## Rounded road corners and building foundations — 6 October 2026

The ground shader's shared `road_contour.gdshaderinc` tightens inward road
curves to clear existing square building setbacks. No additional building
shrink, model export, native rule, road width or save change is involved.

`validate_road_corners.gd` passes **24 Metal GPU checks** using the actual shared
shader include in a diagnostic viewport. Each of the four corner orientations
first reproduces the original paving over a .12-tile-setback plot, then verifies
clearance with the new contour, retained rounding and disconnected-diagonal
behavior. Actual `StreetSetback` transforms for the smallest surrounded one-tile
plot also clear the rendered paving. Straight width/edge gradients and convex
outside corners match the original mask; observation fixtures remain unchanged.
The user's screenshot exposed stacked kerb ends missed by the first 20 checks:
the previous contour jumped at the road/non-road tile border. Four new tests,
covering 56 probe pairs across both borders of all corner orientations, fail on
that version and pass on the final continuous field. Reproduction/final logs
are `road-corners-seam-before.log` and `road-corners-seam-after.log`.

The owned disposable `tools/review_road_corners.py` passes **7 checks** and exits
cleanly. Matched `road-corners-houses-before.png` / `road-corners-houses-after.png`
captures show the same common-house 3a/5a models and transforms beside native
roads. The final overview plus `road-corners-houses-near-close.png` and
`road-corners-houses-far-close.png` were visually inspected: each kerb follows
one continuous curve without stacked ends, and foundations retain clearance.
The rejected first correction is preserved as `road-corners-stacked-before.png`.
Alternating 90-frame timing samples retain 436 draw calls and 2,120,216 primitives;
mean CPU render time is 0.75 ms with the original contour and 0.98 ms with the fix
on this M4. Metal reports zero GPU timing here, so GPU cost is unmeasured.
Evidence: `godot/captures/road-corners-seam-after.log`, `road-corners-review.log`,
`road-corners-timing.json` and `road-corners-continuous-wrapper.log`.

The preceding placement integration passed **95 checks**, including exact preview /
installed fitting, occupied previews, area drags, costs and undo. Terrain passed
**18 checks**, preserving the road texture, native observations and incremental
texture/cache behavior. Save and player preference hashes remain unchanged.
The final seam correction passes **31 focused checks**; placement and texture
update code are unchanged and the preceding evidence is retained. Broader
campaign art coverage, minimum-Mac GPU
profiling and user visual acceptance remain pending.

## Building preview road clearance — 6 October 2026

`python3 tools/review_placement_clearance.py` passes **95 checks** in an owned
Metal/Mobile session with disposable preferences and in-memory construction in
the designated test city. Theater, hospital, house, park and exempt tower previews
are compared with actual installed batch transforms in all four orientations.
Horizontal position and fitting match; only the existing .02-tile preview lift
differs. Valid and occupied previews, full native footprint counts, exact quoted
costs and native undo pass. House/park area-drag models match their single previews;
isolated buildings retain ordinary fitting and road previews retain full size.

Matched captures are `godot/captures/placement-clearance-preview.png` and
`placement-clearance-placed.png`; visual inspection confirms the same theater
edge clearance. Evidence: `placement-clearance-review.log` and
`placement-clearance-wrapper.log`. The review exits cleanly and confirms unchanged
designated save and player preference hashes. No native rules, model geometry,
road width, picking authority or save format changed. Wider campaign coverage
and user visual acceptance remain pending.

## Paved avenues, boulevards and walker clearance — 6 October 2026

Implemented the presentation described in `GODOT_TERRAIN.md`: paved native
medians, outside edge sculpture/benches/planters/foliage, bounded smooth render
lanes and dedicated full-width street card previews. No C++ build, native rule,
RNG, route, timing, footprint or save-format change.

`validate_streets.gd` passes **70 checks**. Fixtures cover both kinds and axes,
outside edge placement, clear ends/bends/crossings, finite original meshes and
reduced LODs, native observation immutability, 301-sample straight/transverse/
diagonal lane sweeps, both directions around an L-bend, stopped/paused lane
stability, single-road preservation, adjacent grass rejection, and incremental
entrance changes across a 24-cell section boundary. Both static street miniature
fixtures contain no viewport or physics. The bend sweep caught a one-frame
rounded-cell classification discontinuity; continuous paved-corner detection and
separate raw lane easing fix it, and the final run passes.

The owned disposable `python3 tools/review_avenues.py` Metal/Mobile run passes
**18 checks**. It uses native previews/build commands for two 17-cell strips,
checks exact quoted costs, actual two/three-cell widths and walkable medians,
immediately undoes/refunds each latest drag and checks all flank cells disappear,
then reconstructs the gallery. Five native lanes are sampled 100 times each
using a real philosopher model and the ordinary update/render path. Displayed
feet stay paved and native positions remain exact. Both cached card textures and
full-width facts are verified. All native snapshot fields except the observation
sequence match before/after the art, UI and moving-citizen fixtures. The wrapper
guards source save and player preference hashes; all remain unchanged.

Retained focused gates pass: locomotion **35**, terrain details **31**, and UI
text **7** (including the Russian width label). Detail instance/batch counts
remain 3,746 / 239 in the designated city. Total focused checks: **161**.
Evidence in `godot/captures/`: `street-contract-engine.log`,
`street-locomotion-engine.log`, `street-details-engine.log`,
`street-text-engine.log`, `avenues-review-engine.log`,
`avenues-{two-and-three-tile-streets,avenue,boulevard,moving-citizens}.png` and
`avenues-catalog-{avenue,boulevard}.png`. Final catalog, individual street and
moving-citizen captures were visually inspected. The Metal review exits 0 with
no engine/script errors; headless retains the known macOS certificate warning.

Scope: movement sweeps are presentation fixtures driven through native tile
observations; they do not establish every live native patrol in every campaign.
Native random patrol choices remain intact. Wider junction/terrain coverage,
sustained minimum-Mac performance and user visual acceptance remain pending.
The gallery is disposable and is never written into the player's saved city.

## Wall panel simplification — 6 October 2026

The fill checkbox stays hidden in building context; the EN/RU wall-placement
hint describes the retained Shift-drag modifier. No native command/rule change.
The isolated `tools/review_toolbar.py --lang en` run passes **178 checks**,
including category/model activation, keyboard input and default/enlarged bounds
at 1920×1080 and 1280×720. Saves and preferences remain unchanged.
`toolbar-en-walls.png` was inspected: wall/tower/gate cards and footprint context
are present without the checkbox. The translation gate passes **7 checks**;
headless retains its known certificate and exit-leak warnings.
Evidence: `toolbar-en-engine.log`, `toolbar-en-walls.png`,
`wall-panel-text-engine.log` and `wall-panel-import.log` in `godot/captures/`.
The older contextual validator is updated to stop clicking the hidden checkbox;
its other historical layout assertions were not rerun as current acceptance.
Shift-fill/outline commands and native costs/undo code are retained unchanged.

## Illustrated notification hub — 6 October 2026

Implemented the fixed upper-right illustrated utility/alert rail, on-demand
objectives and journal view filters described in `GODOT_INTERFACE.md`. New art
is original SVG work extending the dock system; no model/export, C++ build,
native rule, RNG, save format or simulation timing change was required.

Final sequential disposable `tools/review_chrome.py --lang en` / `ru` runs pass
**322 checks each**. The added hub cases cover:

- Default icon-only Objectives, distinct Journal/Goals art, separate unread and
  unseen-completion badges, translated filters and shared hit areas.
- Real mouse presses/releases for opening, Close and history filters; Escape
  returning from disclosures without answering events or opening settings.
- Every supplied native ObjectiveCard, viewport/rail/dock clearance and a
  stationary construction dock. The original set-aside wiring is retained.
- All reports / Warnings / Decisions retaining the complete input history.
- All fourteen hazard groups in bounded scrolling, reaching the last icon,
  clipped/focused timer holds, keyboard camera ownership and compact empty rail.
- Fixed right-side utility positions when Resources opens/folds; retained
  notice queue, pin/unpin, full long text, width and scroll preservation.

Windows were requested at 1920×1080 and 1280×720, each at 100% interface/text
and 125% interface / 130% text. macOS fits the larger window to its usable screen;
`CHROME_LAYOUT` records actual logical bounds and scaling. All read-only header,
stock, native Army/storage inspector and time-callback checks remain. Native
before/after time, money, population, buildings, city_header, paused and speed
observations match; no queued callback remains. The wrappers guard hashes of the
designated source save and player preference files and remove only their owned
review process/profile. Completion-count, filter records and alert overflow are
explicit presentation fixtures; they are never inserted into native events or
saved. The native goals used for ordinary reading come from the episode query.

Sequential disposable `tools/review_decision_panel.py --lang en` / `ru` pass
**52 checks each**. A real native required resource request pauses through the
core's block; Escape folds into the persistent amber seal, and clicking it
reopens the same ID. Resume attempts/settings return cannot bypass the block.
Native choice IDs/wording, semantic ordering, explicit Enter callback, centered
bounds/long-letter scrolling at both scales, camera/picking containment and Tab
cycling remain. Native troop enlistment cancellation leaves the exact request
pending. The revised pointer helper spans frames between down/up, matching real
mouse input. No source city is written.

Headless `validate_hazard_alerts.gd` passes **87 checks**: native alert-kind
coverage, illustrated icon coverage, per-site/id grouping/counts/navigation,
expiry/dismissal, persistent plague, hidden/dialog/modal timer holds and Reduce
interface motion. `validate_notification_layout.gd` passes **10 checks** for
retained full-width notices and journal rows, text scaling, long scrolling,
pin/unpin and unchanged reading positions. `validate_ui_text.gd` passes **7 checks**, including loaded Russian text, source
coverage and orphan detection. Evidence is in `notification-text-engine.log`; stale labels from removed HUD controls were
removed and the existing overflow-tooltip lookup's leading-space mismatch was
corrected. The intentional trailing space in the surroundings source key remains.

The first added chrome run froze before the scheduled episode query; the helper
now explicitly reads the native episode after freezing, so it tests actual goals
rather than an uninitialized icon. The next run exposed a fractional 230.4-pixel
alert page leaving the last row 0.6 pixels clipped at enlarged scaling. Integer
height plus a one-logical-pixel visibility tolerance resolves this; the final
runs pass. Initial Journal art was also being overwritten by a legacy assignment;
the final assignment uses its colored illustration.

Evidence: `chrome-{en,ru}-engine.log`, `chrome-{en,ru}-{1280,1920}-{100,125}-{goals,
journal,alerts}.png`, `decision-panel-{en,ru}-engine.log` and folded/request/large
captures, `notification-hazard-engine.log`, `notification-layout-engine.log`,
`notification-text-engine.log`, `notification-theme-engine.log` and
`notification-hub-import.log`. Default/enlarged English and Russian goal/journal/
alert captures and the folded native Russian decision were inspected visually.
Visible runs exit 0 without script or engine errors. Headless runs retain the
known macOS certificate warning; import also reports sandbox-protected global
editor-settings writes, while project assets/translations import successfully.

Scope: this does not establish every campaign's live alert timing, all monster
hero-card contents, full keyboard/gamepad accessibility, high-DPI/platform
coverage, sustained minimum-Mac performance or user visual acceptance. The
native hero/site callbacks are retained; the all-kind rail is a UI stress fixture.
Older historical map-notification gates still assert superseded layouts; their
results are not presented as current acceptance for this rail.

## Raised marble wall follow-up — 6 October 2026

At the user's request, increased wall walk height **1.45 → 2.0 tiles** (+37.9%).
Merlon crowns reach about **2.24 tiles**, bringing the wall closer to the existing
3.05-tile tower platform and gate pediments. Exported/reimported only **sixteen
wall masks** in background Blender. Tower/gate GLB SHA-256 fingerprints are exactly
unchanged; their manifests refresh shared contract metadata only (revision 3).
Native simulation, saves, wall widths/footprints, costs and patrol routes retain
the earlier contract. Runtime roof lift follows the same shared authoring data.

`validate_defences.gd` passes **94/94 checks** for the installed kit, including the
updated two-tile walk and all masks. Log: `defence-raised-walls-validation.log`.
`tools/review_defences.py` passes **6/6 checks** in the isolated **1600×1000 Metal /
Forward Mobile** session: the real city walker/frame code places the wall guard
on the new floor, keeps street lane zero, retains the tower guard's bounds/height
across **120 moving samples**, and leaves native city observations unchanged.
Designated save/player settings hashes stay identical. The final run exits 0
without script/engine errors; unchanged optional-loader file notices remain.

Named wall LOD silhouette audit passes **16 assets, zero lossy assets/surfaces**
(`defence-raised-walls-lod.log`). Full-detail vertex/triangle counts stay exactly
as in the earlier pass: **1,020–1,836 triangles / 2,040–3,664 vertices** per wall.
No geometry baseline entry needed to change; the complete baseline dictionary
remains identical to its pre-adjustment fingerprint record. Lowest wall LODs now
use **84–104 triangles**. The earlier native **63-check** construction/save-load
regression remains the rule evidence; this height-only follow-up reruns the art/
runtime placement and LOD checks rather than claiming a new native rule change.

Visually reviewed the updated joins, proportions and guard contacts in
[raised-wall ensemble](../godot/captures/defences-raised-walls.png) and gate close-up.
The preceding capture is retained as `defences-wall-height-before.png`.
This supersedes the 1.45-tile height below. User visual acceptance, full material
baking, elevated-roof transitions and minimum-Mac profiling remain pending.

## Olympian marble defences and guard platforms — 6 October 2026

Completed the interrupted `tools/godot_defences.py` source, connected it to the
Godot exporter/catalog, and installed **18 models** (sixteen wall masks, tower,
gatehouse). White marble courses, broad battlements, carved panels, fluted Ionic
columns and three gate pediments are implemented. The shared roof contract is
`godot/data/defence_art.json`: wall walk **1.45** instead of 0.8 tiles; tower
platform **3.05** instead of 2.57. Gate pillars leave the native one-tile passage
clear even at their bases/capitals. Native footprints, facings, recipes, rules,
patrol coordinates and original SDL sprite assets remain unchanged. No library
rebuild or existing game/Blender restart was performed.

Final installed evidence:

- `validate_defences.gd`: **94/94 checks**, covering all eighteen installed source/
  manifest contracts, authored UVs, one/three compatible surfaces, import budgets,
  reduced LODs, full portal clearance, the four-cell tower index, extreme patrol
  positions, all sixteen connected wall walks, ground-archer discrimination,
  native observation preservation and cache removal. The import measurements are
  `godot/captures/defence-runtime.json`; final log is `defence-validation.log`.
- `validate_walls.gd`: **63/63 native checks**, including wall masks/connections,
  native costs/eligibility, both gate orientations and roads, undo/demolition,
  disposable save/load and an actually staffed tower's native archer/model/lift.
  Log: `defence-validate_walls.log`. The legacy native lift remains 2.57; the
  separate Godot projection supplies the new floor height.
- `validate_geometry.gd`: **PASS**, all **441** development models have recorded
  growth baselines and heavy models keep LOD ladders. Only the eighteen defence
  entries were deliberately merged into the existing baseline, preserving earlier
  unrelated art changes. Log: `defence-validate_geometry.log`.
- `audit_lod_coverage.gd -- tower gatehouse wall_0 … wall_15`: **PASS**, **18 assets,
  zero lossy assets/surfaces**. Log: `defence-audit_lod_coverage.log`.
- `python3 tools/review_defences.py`: final isolated **Metal / Forward Mobile**
  review at **1600×1000**, **5/5 checks**. A render-only guard fixture runs through
  actual `main.gd` walker update/frame presentation: **120 moving samples** stay
  within the tower's ±0.58 safety margin, on the exact roof, with no street lane.
  Native tiles/buildings/walkers/money/time remain identical before/after. Review
  helper fingerprints the designated save, native settings and player Godot
  preferences; all stay unchanged. Scratch preferences/save paths are disposable.
  Final log: `defences-review.log`; no script/engine errors or ObjectDB cleanup
  leak warning remain in the final run. The retained optional audio/adventure
  missing-file notices are unrelated loader evidence.

Visually inspected final captures:
[assembled defences](../godot/captures/defences-ensemble.png),
[gate facade](../godot/captures/defences-gate.png),
[gate reverse](../godot/captures/defences-gate-back.png) and
[guard platform](../godot/captures/defences-tower-guard.png).
Gallery paving and guards are review fixtures; the installed gate contains no
road floor. The frozen native city receives no construction or save command from
the visual review. Actual native construction is checked separately above.

Final geometry: walls **1,020–1,836 triangles / 2,040–3,664 imported vertices**,
tower **4,440 / 8,880**, gatehouse **16,012 / 32,364**. Lowest LODs have **84–112**,
**408** and **662** triangles respectively. The gate uses three PBR surfaces;
walls/tower use one. Export caps and refresh/projection contracts are recorded in
`GODOT_DEFENCE_ART.md`. Blender's sandboxed startup crashed before running the
source; background exports and final visible reviews succeeded with the normal
desktop capability. Headless sandbox import retained the known certificate/
editor-settings write warnings; final isolated reviews ran without those errors.

This proves the installed art/placement slice and designated-city native defence
behavior. It does not establish user art acceptance, whole-campaign visual
coverage, stair/elevated roof transitions, full material baking, minimum-Mac
performance or release-rights clearance. `needs_evidence` provenance is retained.
No character/monster/terrain exports, personal save files, simulation timing or
native RNG changed in this pass.

## Compact overview and message collapse — 6 October 2026

Implemented the accepted compact horizontal overview at the upper left with
90% background opacity, opaque readings/icons and Resources below it. On the
designated city its default logical size is **663×34 EN / 669×34 RU**, at x=16,
in a 1697×900 logical viewport. Larger text measures naturally instead of restoring
the former empty centered span. ResourceRibbon's PanelContainer inheritance is
now registered; an initial review exposed the older generic-panel fallback,
which ignored the requested alpha and padding.

Inspected the attached four-second `Untitled.mov`: the first readable report
narrows to roughly an icon/Close column in subsequent frames. The notice's
per-frame `reset_size()` discards its container-assigned width; pin/unpin also
reset it. Removed these resets, explicitly filled the parent VBox and limited
body fitting to changed minimum heights. NoticeBody uses shared Theme scaling
instead of a local 15-pixel override. Native text, commands and simulation rules
are unchanged.

The before-fix isolated regression passed initial wrapping but failed pinning,
unpinning, independent text scaling and stable refresh. Final headless
`validate_notification_layout.gd` passes **10 checks**: full width over many
frames, exact Russian recording text, pin/unpin, 125%/130% sizing, long-text end
scrolling, unchanged reading position, journal width/bounds/refresh and idle-disabled
folded history. The headless run retains the known macOS certificate warning.

Final sequential disposable `tools/review_chrome.py --lang en` / `ru` runs pass
**234 checks each**. They exercise the actual header/map/clock/Jobs/resource
callbacks and native values, Army/storage inspector bounds, content-sized left
placement, background-only alpha and stock disclosure alignment. At each of four
size combinations, notices retain their allotted width after 60 frames and real
pin/unpin clicks, use the complete fixture text and scaled Theme font, retain
scroll on refresh, queue a later arrival, hold their hidden/pinned timer and
advance exactly one report on Close. Informational ack commands are inspected
and discarded; they never execute against the copied city. The frozen native
pause/time/treasury/population/buildings/header/speed and save hashes remain exact.
Required-decision implementation and native callbacks were not modified.

Windows were reviewed sequentially at requested **1920×1080** (macOS fits this
display to **1920×1018**) and **1280×720**, with interface/text preferences
**100%/100%** and **125%/130%**. Final runs exit 0 without script/engine errors and
leave protected saves/preferences unchanged. A review-only cursor mismatch at
enlarged scale was corrected by aligning the physical cursor with marked injected
motion before separated mouse-down/up, matching the existing toolbar harness.
No production pointer behavior was changed for that correction.

Evidence under `godot/captures/`: `notice-layout-before-engine.log`,
`notice-layout-after-engine.log`, `chrome-{en,ru}-engine.log`,
`chrome-{en,ru}-overview.png`, `chrome-{en,ru}-1920-100-notice.png` and
`chrome-{en,ru}-1280-125-notice.png`. Default EN and enlarged RU captures were
visually reviewed. Changed source whitespace checks pass. Coverage remains the
designated copied city, focused presentation and informational acknowledgements;
other campaigns/platforms/high-DPI/gamepads, minimum-Mac profiling and user visual
acceptance are not established by this gate. No user game or Blender was restarted.

## Clock below the map, Jobs and shortcut help — 6 October 2026

Implemented the requested Jobs move after Layers, centered construction context,
map icon hidden while the circle is open, and native Play/Pause/speeds/date below
the map. Main-row hover help shows working, rebindable H/B/G/L/J shortcuts,
existing X/Delete demolition and Cmd/Ctrl+Z Undo. Categories retain their existing
plain labels. Legacy custom keys win over new defaults, with occupied new dock
keys left Unassigned until rebound. Native C++ timing/rules, saved city, model
assets and Blender scenes are unchanged.

Final sequential disposable toolbar reviews pass **178 checks in each of EN and
RU**. They cover Jobs' bottom-row ancestry/order, centered context, correct open/
folded map buttons, measured clock/dock bounds, every native category/card route,
main-row shortcut titles, actual H/B/G/X tool selection, L disclosure and J native
industry selection, immediate help updates/rebound Housing callback, existing
Undo/map/Layers callbacks and camera ownership. All native time, treasury,
buildings, cached header and source-save fields checked remain unchanged. Queued
Undo is inspected then discarded, without executing native construction.

Sequential neighboring-panel chrome reviews pass **169 checks per language**:
actual relocated Play/Pause and all speed callbacks retain exact native commands;
time controls stay in their own panel, date below speeds/map, Jobs in the dock;
native housing/treasury/monthly balance/population/jobs/stocks stay exact. Resource
disclosure, map preference callbacks, focused clock/header camera ownership,
Army and warehouse inspector bounds/scrolling and protected file hashes pass.

Captures fit requested **1920×1080** (macOS fits this display to **1920×1018**) and
**1280×720**, with interface/text preferences **100%/100%** and **125%/130%**.
EN/RU default and enlarged captures were visually reviewed. An initial review
harness retained a freed category reference after rebinding refreshed the catalog;
the harness now reacquires it. Hardware cursor movement during desktop work also
interfered with delayed hover observations; the final marked injected motion is
observed immediately through the actual GUI route. No production hover logic was
changed for either harness correction. Final visible runs exit 0 without engine
or script errors and close only their owned windows.

Headless `validate_controls.gd` passes **65 checks**, including duplicate-key
policy, new-default migration without displacing an older Army binding, empty-key
suppression/held-camera protection, rebinding/restoration, EN/RU control labels
and untouched player preferences. `validate_toolbar_input.gd` passes **18** ordinary
input checks, preserving separated press/release, cancellation and keyboard focus.
These headless runs retain the known macOS sandbox certificate warning; the
controls damaged-file fixture deliberately emits its duplicate-key warning.
Changed code whitespace checks pass; the existing trailing-space CSV source key
for surroundings remains untouched.

Evidence: `toolbar-{en,ru}-engine.log`, `toolbar-{en,ru}-rearranged.png`,
`toolbar-{en,ru}-layers-1280-125.png`, `chrome-{en,ru}-engine.log`,
`chrome-{en,ru}-1280-125-overview.png`, `controls-clock-dock-engine.log` and
`toolbar-input-engine.log` under `godot/captures/`. These focused reviews use the
designated copied city with disposable preferences/profiles. Broader campaigns,
other platforms/high-DPI/gamepads and minimum-Mac profiling remain outside this
gate; no user game or Blender instance is restarted.

## Dock rearrangement and Layers — 6 October 2026

Implemented the user's revised arrangement: no upper-left City views strip,
quick supply/water/hygiene/hazard buttons inside Layers, hidden duplicate
Inspect/Build controls, left Undo/housing/road/roadblock/demolition shortcuts,
and a map button beside the circular map (reachable while folded). Layers
retains all 25 native views in a bounded scroll panel. Roadblocks use an original
SVG illustration. No native C++ rules, saved city, GLBs, Blender scene, map
coordinates or simulation timing were changed.

Final sequential disposable `tools/review_toolbar.py --lang en` / `ru` reviews
pass **160 checks each**, with normal separated mouse-down/up activation. They
cover every available native category/card route, full translated hover help,
direct housing/road/roadblock/demolition selection, disabled/enabled Undo (its
single queued callback is discarded), map opening/folding, Layers keyboard input,
the four quick views, actors/Normal/all-science callbacks, complete view coverage,
Escape/Close/outside dismissal, and native time/treasury/buildings/header/save
preservation. The extra dismissal checks select a real native army company and
an active housing tool: closing Layers issues no order/build, keeps the army
selection, and stays clickable above the dynamic Army inspector. Required
decision surfaces remain above Layers. Keyboard Jobs also closes Layers and
returns camera input.

Both languages fit **1920×1080** and **1280×720**, at independent interface/text
settings **100%/100%** and **125%/130%**. Layers clears the actual overview and
dock; its last science choice is scroll-reachable. All four quick-view buttons
remain visible and the open-map control stays beside the circle. An initial
review caught keyboard focus being released when an already closed Layers panel
was closed, and enlarged fixed chrome exceeding a guessed allowance. The final
implementation only releases Layers-owned focus on a real close and measures
fixed chrome before bounding its scroll room. Final runs exit 0 without engine
or script errors. Captures were visually reviewed in EN/RU, including Russian
labels and the compact dock.

Sequential neighboring-panel `tools/review_chrome.py --lang en` / `ru` gates
also pass **139 each**, covering the retained top-bar values/buttons, resources,
map preferences, keyboard camera ownership, Army/warehouse bounds and unchanged
native observations/protected files. The ordinary-input headless
`validate_toolbar_input.gd` still passes **18 checks**; it emits the known macOS
sandbox certificate warning. Review helper and roadblock SVG syntax, script
import and changed-file whitespace checks pass. All owned reviews close and
verify source-save/player-preference hashes; no user game or Blender is restarted.

Evidence: `godot/captures/toolbar-{en,ru}-engine.log`,
`toolbar-{en,ru}-{rearranged,layers,layers-1920-100,layers-1920-125,layers-1280-100,layers-1280-125}.png`,
`chrome-{en,ru}-engine.log` and `toolbar-input-engine.log`.
These are focused UI routes over the designated copied city; broader campaign
coverage, other platforms/high-DPI configurations, gamepad review and minimum-Mac
performance remain outside this gate. Native placement/army commands were not
executed merely to verify button rearrangement.

## Loading screen from the main menu — 6 October 2026

Implemented a root-owned, opaque loading surface for Continue, selected Load
save and Begin, also shared by the editor handoff. It draws before synchronous
loading and remains until full initial terrain/models/HUD and a city draw are
ready. City processing/input are held through that interval. New games retain
their original adopted simulation and native retry checkpoint.

`tools/review_loading.py` runs real button down/up transitions with a disposable
leader, scratch settings and a byte-for-byte copy of the designated test save.
Focused checks cover immediate screen appearance, one pending session despite
repeat actions/Escape, viewport coverage, translated bounded content, a complete
held snapshot before dismissal, restored processing, native pause, all **25,992
cells**, consumed handoff metadata, adoption identity and retry save creation.
It also checks missing-file handling, Reduce interface motion and a translated,
focused failure return button. Failure recovery is exercised by the UI's failure
path; the review does not deliberately corrupt the engine installation to force
both native save-open attempts to fail.

Evidence is `godot/captures/loading-{en,ru}-engine.log` and
`loading-{en,ru}-{continue,load-save,new-game,city,failure}.png`. The English
screen is reviewed at 1600×1000; Russian at 1280×720 with interface **125%** and
text **130%**. Launchers guard the designated save and player settings before
and after every run. Final sequential EN/RU reviews pass **40 checks each**;
all four new loading labels also pass a direct check against Godot's imported
Russian translation. Captures are visually inspected in both languages. The
final isolated Metal surface preview also confirms the same colours are loaded
from the shared Theme (`loading-surface-engine.log`, `loading-final-theme.png`). The
first Russian new-game run exceeded the review's 30-second wait; the final
review uses a 90-second per-transition guard and completes. This extends test
patience, not the game's loading behavior.

**Retained broader text failure:** `validate_ui_text.gd` passes **5/7 checks**.
The existing `(overflow: %d)` call does not match its leading-space CSV key, and
older labels are orphaned (including `%s citizens`, `City ground` and prior
decision/action hints). The four added keys and imported Russian values pass
their direct gate. Unrelated wording and translation rows are left unchanged.
Evidence: `godot/captures/loading-text-engine.log` and
`godot/captures/loading-labels-engine.log`.

**Limits:** this is a presentation transition. Native loading and existing model
joins remain synchronous, so activity animation can pause during those steps.
Cold shader/asset behavior on minimum hardware, every campaign/editor route and
fully asynchronous loading remain outside this focused acceptance. Existing
whole-game and unrelated asset-gate limitations retain their earlier scope.

## Sixteen remaining monster reference models — 6 October 2026

Installed individually authored Godot-only sculptures, generated reference
sheets and neutral Blender sources for all sixteen remaining monster identities.
Hydra is retained. Six screen-design studies and two film anatomy/silhouette
motifs informed eight designs; the other eight use original mythology/game
anatomy. Exact generation prompts, downloaded-image scope, source/output hashes
and pending rights/visual acceptance are recorded in
`assets/monsters/monster_reference_sources.json` and the parent art catalog.

Verified scope:

- `tools/validate_monster_reference.py` passes **158 checks** across all 114
  samples per monster: both UVs, palette, finite topology, all aliases, neutral
  and raised height bounds, support feet, grounded collapse and every mouth/
  contact probe. Neutral heights **1.79–2.14 tiles** equal about **1.89–2.25
  displayed citizens**, **73–87% of Zeus**. Largest raised non-death top is
  **2.293366**, below Zeus's measured **2.455466** body. Final clothing/Harpy fit
  exports repeat the full 158-check proof in `captures/monster-fit-source.log`.
- Lossless optimization proves **16 models / 38 primitives / 4,294 stored morph
  frames with zero differences**, including both UVs. Final fitted Medusa,
  Maenads and Harpies repeat the proof for **3 models / 8 primitives / 904 frames**.
  Their fresh raw backups are separate from the first batch. Both pose-bake
  operations complete; old runtime models remain backed up in parent art.
- `validate_monster_reference.gd` passes **211 checks**, repeated after final
  fit changes: complete native attack/death clips, fresh derivatives, cached
  material/texture sharing, no runtime dense morph buffers, pause/held corpse,
  and interpolated world mouth positions under translation, height and facing.
  Scylla has seven anchors; Cerberus/Chimera/Maenads three, Harpies two, others
  one. Imported maxima **28,529 vertices / 31,620 triangles** stay within caps;
  **8–17 LOD levels**, terminal totals below **1.63%** of full geometry. All new
  models use two or three animated grouped surfaces.
- Only the sixteen deliberate `walker_*` baseline entries change. A before/
  after integrity guard confirms every Hydra source/manifest/import/runtime file
  is byte-identical and no unrelated geometry entry changes. Native recipes,
  simulation code, RNG and designated saved-city file are preserved.
- Retained gates pass: Hydra **17**, monsters **36**, native effects **77**,
  human characters **212** (104 adapted human assets), and the complete geometry
  catalog. Scoped `validate_poses.gd` passes **3,264 runtime part/frame checks**,
  then **623** for the three final fit revisions (largest final-fit fingerprint
  gap **0.0024394**, inside the existing quantization allowance). The whole
  geometry gate is repeated after the final fit installation and passes.
- Metal/Mobile studio captures cover **all sixteen**, with neutral three-quarter,
  front, side, attack and fallen views: **80 images**. Final dress fit covers
  Medusa/Maenads; Harpies gain feather coverage and hooked talons. Those three
  views are replaced after re-export. `review_monster_lineup.gd` renders a native
  1800×1600 review board, also inspected with representative city captures.
- Sequential disposable native city reviews pass **14 checks each** for Cerberus
  EN/RU, Medusa EN, Scylla RU and Kraken EN. After final fitting, Medusa EN is
  repeated and Harpies RU added, both **14**. Each records three launches,
  three impacts and one real native collapse, with effects/time frozen while
  paused. Every launcher fingerprint check preserves the designated save and
  player settings. Sea monsters are moved into the disposable warehouse attack
  fixture for transport/render coverage; this is not sea-navigation acceptance.

**Broader retained failure:** `validate_assets.gd` passes **425/441** records,
including all sixteen new monster models. The sixteen failures are unrelated
pre-existing modified animal/worker models: `animal_boar`, `animal_deer`,
`walker_artisan`, `walker_bronzeminer`, `walker_deerhunter`, `walker_firefighter`,
`walker_goatherd`, `walker_grower`, `walker_hunter`, `walker_lumberjack`,
`walker_marbleminer`, `walker_orangetender`, `walker_orichalcminer`,
`walker_rancher`, `walker_shepherd`, `walker_silverminer`. Their newer clip names
(for example `restanimal`, `animalattack`, `fallen`, `build`, `buildstand`,
`pickoranges`, `pruneoranges`) are not accepted by the generic asset gate. Their
models and that gate are not altered by this pass. These failures prevent a
whole-catalog clean claim; they do not fail the separate monster/pose/geometry
or human-character gates.

Evidence: `captures/monster-reference-validation.json`,
`monster-reference-runtime.json`, `monster-reference-gates.json`,
`monster-fit-*.log`, `monster-final-checks.json`, per-species EN/RU review JSON,
`captures/monsters/`, and the
[reference catalog](../../art/monsters/REFERENCE_CATALOG.md).

**Remaining:** these are development reference sculptures, with less painted
detail than the concept sheets. User visual acceptance, full material baking,
slope foot IK, harpy flight refinement, minimum-Mac GPU profiling, broad campaign
coverage and release-rights evidence remain pending. Existing unrelated
whole-game/campaign and asset-gate failures retain their earlier scope.

## Complete construction-card previews — 6 October 2026

Fixed missing Agora pictures and component-only/shared-cache pictures for
composite buildings. Thumbnail identity now follows the catalog tool; native
placement pieces supply full layouts without granting or constructing anything.
The player's native focus retains scenario-specific pyramid levels. Agoras show
three/six empty paved vendor plots and their street. Pyramid picture axes use
temporary copied geometry with corrected normals/tangents/winding, preserving
colors/UVs/shared finishes and leaving imported models/world instances untouched.

Verification:

- Sequential disposable `tools/review_toolbar.py --previews --lang en` / `ru`
  pass **29 checks each** and exit normally, with no engine/script errors.
  Every one of **189 converted catalog designs** (including unavailable scenario
  designs) has geometry; every composite has its complete native piece layout
  and matches the city's coordinate conversion/relative heights.
- **86 rendered designs per language** cover all 79 available model-backed cards
  plus seven otherwise-unavailable pyramid/shrine/sanctuary samples. Alpha bounds,
  visible surface occupancy and lighting checks pass. Five terrain tools retain
  the intended colored road illustration. Distinct Agora and pyramid sizes
  produce distinct textures; Markets/Pyramids/Administration/Defence cards,
  hover context and Agora pointer selection use the correct picture/native tool.
- One shared 160×100 viewport returns to `UPDATE_DISABLED` with no temporary
  building nodes retained. All native game-state fields agree before/after
  assembly, rendering and browsing (only observation sequence is excluded).
  Source-city/copied-city and player-preference hashes remain unchanged.
- `validate_toolbar_input.gd` passes **18 ordinary untagged input checks**.
  Its headless macOS certificate warning is the known sandbox limitation.
  Code whitespace checks pass. Markets, full pyramid, shrine and sanctuary
  renders were inspected visually. Earlier attempts caught snapshot-sequence
  comparison and negative-scale lighting/winding issues; the final runs include
  their fixes and stronger coordinate/surface/lighting assertions.

Evidence: `building-previews-{en,ru}-engine.log`,
`building-preview-{en,ru}-<tool>.png`, `toolbar-{en,ru}-previews-*.png` and
`thumbnail-input-engine.log`. Rendering every unavailable design, broader campaign
art review and matched minimum-Mac profiling remain pending. No C++ rule/save or
asset-export change was needed. Relaunch the player session to load the fix.

## Illustrated treasury and citizen icons — 5 October 2026

Added original 96×96 `toolbar_icons/treasury.svg` (silver coin stack with owl
relief) and `population.svg` (two citizens), using the dock's shaded illustration
palette. Their authored TextureRects both use 24×24 logical-pixel cells with
aspect-preserving centered stretch and pointer-ignore behavior. The old live
coin viewport and treasury-gain flip path are no longer instantiated; native
money, population, monthly ledger, mood and tooltip parents are unchanged.

Verification:

- Both sources parse as valid SVGs and import successfully through Godot.
  Only these two new images needed asset import. Existing headless macOS
  certificate/global-editor-settings warnings remain sandbox limitations.
- Sequential disposable `tools/review_chrome.py --lang en` / `--lang ru`
  pass **139 checks each**, including exact native values, hover help,
  pause/speed/resources/jobs callbacks, map visibility choices, keyboard
  ownership, responsive bounds and inspectors at normal/enlarged UI/text sizes.
  Source-city/copied-city and preference hashes remain unchanged.
- The rendered header was visually inspected at its actual display size;
  both illustrated icons align within their equal cells. `header-icons-detail.png`
  and the updated `chrome-en-header-detail.png` show the result. Scene/script
  review confirms the old live coin/preload/flip bookkeeping is absent, while
  the standalone old coin source remains preserved.

Evidence is `header-icons-import.log`, `chrome-{en,ru}-engine.log` and the
size-qualified header/overview captures. No native simulation, Theme-font,
translation or saved-city change was needed. Relaunch to load the new scene/art.

## Matching panels, compact header and open map — 5 October 2026

City panel frames, dropdowns and popup surfaces now share the illustrated dock's
charcoal/bronze palette and shallow corners. Content margins, parchment interiors
and semantic action/status colors remain. The header uses reduced padding and
typography, centers at a measured narrower width and preserves complete native
readings. Resources wrap within the same width; other panels use actual header
bounds. The corner City map shortcut stays hidden and the map starts open.
Unversioned old folded preferences adopt the new default without a launch write;
later explicit visibility choices are remembered with policy version 2.

Verification:

- Sequential disposable `tools/review_chrome.py --lang en` / `--lang ru` pass
  **139 checks each**, covering exact native values, all four speed indices,
  pause/resources/jobs callbacks, hover text, focus ownership, compact bounds,
  Army/warehouse inspectors and independent interface/text sizes. Real map fold/
  reopen clicks persist explicit choices without issuing a native command. The
  reviewer also seeds the legacy unversioned false preference and verifies its
  new open policy. Designated-city/copied-city and preference hashes are unchanged.
- `CHROME_LAYOUT` records actual logical viewports and bounds. The default wide
  English view has a **1459.42×52** overview in a **1697×900** logical viewport
  (86% width), with 118.79 margins. The native values stay complete at requested
  1920×1080 and 1280×720 windows with interface/text 100/100 and 125/130.
  macOS window clamping and canvas scaling are accounted for; these are logical
  dimensions rather than a promise of physical window size.
- Dock reviews pass **110 UI checks each** in English/Russian. An initial English
  tooltip-capture failure targeted a category before deferred layout/scrolling had
  settled; the reviewer now waits and brings that category into the scroll view
  before the unchanged hover assertion. The subsequent English run completed all
  110 checks, then returned SIGABRT during process shutdown; Russian exited normally.
  This slice does not establish a general renderer-shutdown fix.
- Headless ordinary-input `validate_toolbar_input.gd` passes **18 checks**. Theme
  generation succeeds and scoped diff whitespace checks pass. The headless macOS
  certificate warning remains separate from the visible UI checks.
- `tools/review_map_notifications.py --native-map --lang en` passes **8 native
  map checks** and exits normally: full terrain/building depiction, unsaved road
  construction/undo texture refresh, coordinate round trips and ground-following
  camera navigation. The source city and preferences remain unchanged. This
  native map phase was run in English; Russian map controls/preference behavior
  are covered by the chrome/dock reviews above.

Evidence is `chrome-{en,ru}-engine.log` (including `CHROME_LAYOUT`), size-qualified
overview/resource/Army/inspector captures, `toolbar-{en,ru}-engine.log`,
`toolbar-input-engine.log` and `map-notices-native-map-en-engine.log`.
Styling of other dialog frames is implemented through
the shared Theme; their full campaign/decision workflows were not rerun here.
Relaunch the player session to load the authored scene and Theme changes.

## Compact top bar and time-control order — 5 October 2026

The seven Date/Speed/Current city/Housing/Treasury/Monthly balance/Population
captions are hidden in the authored HUD. Unique nodes remain for translation
compatibility; their hidden labels contribute no layout height. Remaining value
columns are vertically centered, and TimeRow now orders Play/Pause → speeds
1–4 → date. Native readings, gauges, hover help and callbacks remain attached
to their existing controls. This supersedes the earlier visible-caption design.

Verification:

- Final sequential disposable `tools/review_chrome.py --lang en` / `--lang ru`
  pass **136 checks each** and exit normally with no script errors. The existing
  caption assertion now checks that all seven requested labels stay hidden;
  native data, hover text, mouse presses held across frames, pause/speed callback
  indices, keyboard ownership, resource disclosure and responsive bounds pass.
- Requested 1920×1080 and 1280×720 layouts at interface/text sizes 100/100 and
  125/130 retain the complete readings and controls. Header/Army/warehouse
  clearances remain valid. Actual viewport bounds account for macOS window
  clamping. English and Russian overview captures confirm the new time order.
- Designated-city, copied-city and preference hashes remain unchanged, and no
  reviewed native callback remains queued. The native Army command phase was
  not rerun for this presentation-only change.
- An earlier Russian run passed all 136 checks, then aborted during renderer
  material teardown (`RendererRD::MaterialStorage::shader_free`, macOS crash
  report at 22:36:26). The final English/Russian runs after the time reorder both
  exit normally; this does not establish a general renderer-teardown fix.

Evidence remains `chrome-{en,ru}-engine.log`, size-qualified overview captures
and the updated `chrome-en-header-detail.png`. Relaunch the player session to
load the authored scene changes.

## Top/bottom mouse activation correction — 5 October 2026

The user reported that both redesigned bars ignored every button. A minimal
ordinary-input reproduction identified premature focus release in the shared
`ToolbarButton`: plain Button down → two frames → up produced one callback;
scripted down/up in one frame produced one; scripted down → two frames → up
produced **zero**. Deferred mouse-down focus loss canceled Godot's armed press.
The previous same-frame review helpers concealed this failure.

The shared script now defers focus release on mouse-up, after native activation.
Keyboard focus and existing native Button/MenuButton signals are retained.
`review_chrome.gd` and `review_toolbar.gd` now wait two process frames between
mouse-down and mouse-up, including all deferred work before release.

Verification:

- Headless `validate_toolbar_input.gd` passes **18 checks** using ordinary
  untagged input, without a native city or review input gate. The formerly
  failing held click now activates once. Momentary/toggle/menu activation,
  held focus, post-release focus, keyboard Enter, drag-outside cancellation,
  subsequent recovery and no opening-click popup selection are checked.
- Corrected sequential `tools/review_chrome.py --lang en` / `--lang ru` pass
  **136 checks each**; `tools/review_toolbar.py --lang en` / `--lang ru` pass
  **110 each**. These real GUI routes exercise pause/speed/resources/jobs,
  tools/categories/model selection, map and Build/Overlays menus, keyboard focus
  and normal/enlarged layouts with presses held across frames.
- Visible wrappers confirm unchanged designated-city and preference hashes;
  the reviews use disposable save/profile/settings roots and preserve native
  observations. No native callback, simulation rule or save-format change was
  needed. The running player session must be relaunched to load the shared fix.
- An initial corrected Russian dock run passed all click/menu routes but had two
  hover-only failures. The reviewer now aligns the physical cursor with injected
  motion before Godot's between-frame hover checks. Exact hover predicates remain
  intact, without retries or direct HUD mutation; the final 110-check run passes.

Before-fix evidence is `toolbar-input-before-fix.log`; the new headless log is
`toolbar-input-engine.log`. Final visible logs remain `chrome-{en,ru}-engine.log`
and `toolbar-{en,ru}-engine.log`. These gates cover actual engine GUI ordering
and the designated city, rather than general platform/gamepad coverage.

## City overview and panel polish — 5 October 2026

Implemented labeled date/speed/city/stat groups, explicit free housing, separate
treasury/monthly balance, named Resources disclosure and bounded hover help.
Responsive header bounds also govern the nonmodal Army panel. Inspector context,
stored-good name wrapping, focus-following inspector/journal scrolls and locale
objective grouping complete this presentation slice. Native rules/callbacks remain
authoritative.

Verification:

- Final sequential disposable `tools/review_chrome.py --lang en` / `--lang ru`
  pass **136 checks each**, with no script/runtime errors. Actual GUI callbacks
  preserve the original pause-zero/pause-one and four native speed indices;
  these time commands are inspected then discarded without execution. Exact
  cached dates, signed treasury, population, housing, monthly-ledger balance,
  employment and all 24 resource counts remain unchanged before/after review.
- An independent native world query matches 18 giftable resource types and the
  food total (sum of eight food bits), with drachmas matched to treasury rather
  than mistaken for a header stock item. The world gift catalog excludes some
  header resources; the other exact cached counts are asserted directly.
- Keyboard Resources/Enter, Home, Escape and right-click exercise actual input
  ownership. Header navigation holds the camera; returning releases it without
  a pause/save command. Actual Jobs and food-stock clicks retain native industry/
  supplies routes and return camera input. Independent text-size changes enlarge
  monthly-balance and speed fonts through the shared Theme.
- Requested **1920×1080** and **1280×720** windows, with **100/100** and **125/130**
  interface/text sizes, keep native readings and every expanded stock item bounded.
  Assertions use the actual logical viewport; macOS can limit the larger window
  to its available screen area. Native Army and warehouse inspector fit the actual
  header/dock clearance; title/Close stay fixed while final content is reachable.
  Inspector footprint/staffing captions and wrapped full goods names are checked.
- Separate sequential `--army-native` runs pass **25 native Army checks each**
  after a 132-check read-only phase. They execute Call all out/Send all home,
  selected-company return, banner placement/right-click relocation, flag picking,
  Escape/F4 and language switching only in unsaved scratch memory. Native time,
  money and buildings remain equal; the copied city is never written.
- Headless `validate_army_layout.gd` passes **132 fixture checks** across EN/RU,
  requested 1920×1080/1280×720/1024×576 and UI100/125 with text130. Empty companies,
  12 long names, native abroad/aid/unplaced predicates, wrapped full help, stable
  controls/selection, detail scrolling and fixed Close are covered.
- All visible review runs confirm unchanged hashes for the designated source city,
  root/repository preferences and Godot user settings. All runs use disposable
  leaders/save roots/settings. Debt/positive-treasury color captures are local
  presentation fixtures; the designated city's real treasury is positive.
- All **16 new description/caption keys** are unique, used by the interface and
  have nonempty Russian translations. Shared Theme generation and script imports
  succeed; the existing sandbox macOS certificate/editor-settings warnings are
  separate from the clean visible runtime reviews.

Logs are `chrome-{en,ru}-engine.log`, `chrome-{en,ru}-army-native-engine.log` and
`army-layout-engine.log`. Captures include `chrome-{en,ru}-{overview,resources,
negative-treasury-fixture,army-native}.png` and size-qualified overview/resource/
Army/inspector views. `chrome-en-header-detail.png` shows the final top bar.
Shared hover-help extraction also passed headless width/wrapping/Theme/pointer
checks. These gates cover the designated city and explicit presentation fixtures;
other campaigns, gamepad navigation, sustained performance and user visual review
of this new slice remain separate.

## Illustrated construction toolbar — 5 October 2026

Implemented the user's Anno-inspired bottom-dock layout with original colored
category/tool illustrations, separate category and utility rows, immediate
hover/focus names, explanatory tooltips and a gold selected marker. Shared Theme
and CSV retain English/Russian copy and independent interface/text sizes. The
authored scene, native catalog, model cards and action callbacks are preserved.

Verification:

- Sequential disposable `tools/review_toolbar.py --lang en` and `--lang ru`
  pass **110 checks each**, with no script/runtime errors in either final log.
  Both wrappers report unchanged hashes for the designated source city, root/
  repository preferences and Godot user settings. Each city loads only from its
  temporary leader/save-root copy and is never written back.
- Every category available in the designated city's native catalog retains
  exact card membership, full translated title and one selected category marker.
  Each has a distinct original SVG texture with neutral tint. Hover is read-only;
  identical catalog refreshes preserve controls, card state, scroll and focus.
- Actual pointer/key input exercises Inspect/Road/Demolish, category Enter,
  model selection, map unfolding/folding, both native menus, and a keyboard Water
  overlay choice. The Culture submenu uses its original callback metadata.
  Keyboard-owned controls/popups hold camera input and clear an existing drag;
  selections and tray Escape release ownership. Escape preserves the previously
  selected construction tool, following the existing two-step cancel behavior.
- Both MenuButtons use native release activation without hover switching. The
  opening click remains separate from choosing a menu item; the final Build/
  Overlays keyboard and mouse checks pass. Tooltip labels receive their wrapped
  width before measuring height, correcting an oversized native tooltip window.
- With requested windows of **1920×1080** and **1280×720**, and **100/100** and
  **125/130** interface/text sizes, both rows and all utilities fit; the model
  tray clears the dock and stays bounded. Assertions use the actual logical
  viewport (macOS may limit the larger window to its available screen area).
  The intentionally hidden category-only search remains hidden.
- Tooltip/Undo availability are presentation fixtures: the displayed tooltip
  uses the actual custom control, and queued Undo is asserted but never executed.
  Native time, treasury, buildings and city-header observations are equal before
  and after the review. All **24 original SVGs** parse, and all **24 new hover
  description keys** are used and have nonempty Russian translations.

Captures are `toolbar-{en,ru}-{default,models,hover-help,1920-100,1920-125,
1280-100,1280-125}.png`; `toolbar-en-detail.png` crops the reviewed hover-help
viewport to the new dock. Logs are `toolbar-{en,ru}-engine.log`. The local tooltip
capture moves the pointer away first to avoid duplicating the native tooltip.
Artwork provenance is in `godot/ui/toolbar_icons/README.md`; no reference pixels
or live Blender scene were changed. These checks cover the designated city,
not other-campaign eligibility, gamepad navigation or sustained GPU profiling.
User visual acceptance remains pending.

## Centered required decisions and right-click Postpone — 7 October 2026

Implemented and scoped native/visible checks pass. User visual acceptance remains
separate. The card is centered over a dimmed full 25,992-tile designated city;
sender identity and all available choice labels/IDs are native observations.
Refuse/Postpone precede the emphasized available affirmative action; invasions
use Surrender/Bribe/Defend and multiple receiving cities retain equal emphasis.

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| English decision review (full-city layout plus native reply routes) | 80 PASS | `decision-panel-en-engine.log` |
| Russian decision review (full-city layout plus native reply routes) | 80 PASS | `decision-panel-ru-engine.log` |
| Retained native EN/RU requests and group-unit rules | 17 PASS | `decision-native-requests-engine.log` |
| Current translated interface text | 7 PASS | `decision-ui-text-engine.log` |
| Retained notice/journal layout after the type correction | 13 PASS | `decision-notice-layout-engine.log` |

`tools/review_decision_panel.py` uses a copied city in a disposable leader/save
root and scratch preferences, and hashes the live designated save/native/Godot
settings. Source/copy hashes remain identical; no native gameplay file is saved.
Visible reviews run sequentially, with hardware input isolated. The final visible
logs contain no script/runtime errors or warnings; the retained native gate
completed cleanly outside the restricted macOS certificate environment.

Real native correspondence proves exact sender/world identity, available choices,
semantic ordering, no default Enter reply, Tab confinement, modal picking/camera
shield, fixed choice footer, and actual keyboard submission of the exact original
callback. Folding/Escape, requesting resume and game-menu return retain the
native clock/block. Escape folds the foreground card before a journal behind it.
Actual native troop requests prove pointer Send troops opens existing enlistment
without answering, and cancellation leaves the event paused and waiting.

Current native troop requests additionally exercise expanded-card right-click,
folded-icon right-click, the actual Postpone button, and right-click while manually
paused. Each queues exactly one `event <id> 1`, with no extra pause/resume command;
the native callback removes the notification/block, preserves outstanding world
requests/treasury, and advances time only when the user was running. Repeated
right-clicks cannot enqueue duplicate replies. A saturated queue preserves the
visible retryable card. A synthetic rejected-command result tests re-enabling
the same choices without answering the native event. Invasion and receiving-city
fixtures prove right-click only folds when no actual Postpone is offered; Bribe
is never invoked. Their UI fixtures leave the real troop request blocked.

The compact charcoal letter/frame, ivory body text (at least 7:1 measured contrast),
rectangular portrait and shared button surfaces replace the parchment/oval
presentation. EN/RU hints advertise right-click only for an available Postpone.
Only relevant decision Theme entries were regenerated; CSV import succeeded.
A pre-existing notification-chip inferred-type parse error was corrected by
declaring its activation flag as bool.

Bounds and readable letter/choice areas pass at 1600×1000 and 1280×720, with
100/100 and 125% interface/130% text, including three troop choices at the latter
small-window setting. A tenfold long-letter presentation fixture reaches its
last line while choices remain accessible and the native message stays untouched.
Invasion and multiple/single receiving-city ordering/emphasis checks use explicit
presentation fixtures; they do not claim new gameplay outcomes for those events.
Native requests/group movement are separately exercised by the retained gate.

Captures: `decision-panel-{en,ru}-request.png`, `-folded.png`, `-1600-{100,125}.png`,
`-1280-{100,125}.png`, `-long-letter.png`, `-troops.png`, `-troops-large.png`.
The full-city layout/input checks use Metal/Mobile. After their captures, 22
repeated native reply/retry checks retain the same native city and real 2D input
Controls with 3D rendering disabled only in the disposable reviewer. Two earlier
extended attempts stalled in the local Metal frame fence, confirmed by an owned
process sample, and the wrapper closed those owned windows. The final isolated
English/Russian runs complete; no game renderer or simulation policy was changed to
work around the test stall. The text gate retains its known exit-only RID/ObjectDB
warnings. Wider platform/high-DPI/gamepad coverage, minimum-Mac profiling and user
visual acceptance remain pending; no native rule or save-schema change is made.

## Field-worker activity — 5 October 2026

**Implemented and technically verified; user visual acceptance remains separate.**
Native hunter/grower variants and goat/corral roles select their own models.
Work clips follow native gameplay time; loaded return clips follow distance and
require actual collected goods. The corral's retained building cycle also
requires native processing. Read [field-work contracts](GODOT_FIELD_WORK.md).

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| Native observations, source/VAT work states, load guards, pause and transitions | 235 PASS | `field-work-validation.log` |
| Nine optimized models, both shader UV sets and morph positions | 2,309 primitive pose frames, zero differences | `field-work-uv.log` |
| Imported source/VAT pose agreement | 1,661 samples PASS, worst fingerprint gap 0.00111 tile | `field-work-poses.log` |
| Geometry and LOD gate | 434 models PASS; only nine baseline entries updated | `field-work-geometry.log` |
| English / Russian visible Metal reviews | Eight views PASS each; no runtime script errors | `field-work-en-engine.log`, `field-work-ru-engine.log` |
| Retained building activity | 219 PASS, 47 authored types | `field-work-building-activity.log` |
| Retained collection and locomotion | 18 / 35 PASS | `field-work-gathering.log`, `field-work-locomotion.log` |
| Embedded core | 101 PASS | `field-work-embedded.log` |
| Signed native/embedded seeded parity | All six cases PASS (0/200/1200 ticks, seeds 7/11), repeated native results identical | `field-work-parity.log` |

The designated native city's initial snapshot includes five hunters, two sheep
handlers, six growers and 32 wild animals. Hunters/shepherds report actual loads.
Fixture checks cover every new native action on both source morphs and crowd
VATs, including held corpse poses and empty-return guards. No native production,
damage, RNG, routing, coordinate, serialization or saved-state change is made.
The mandatory extension signing helper and native executable signing were used.

Seven human models keep three material surfaces and the 22,000-source-vertex
limit. The two animals keep two surfaces. Imported ladders have 9–15 levels
across each model's surfaces. Additional sheep/goat/prey geometry is shared per
role and hidden outside its applicable clip. Per-role pose textures total about
96.1 MB for all nine roles; no per-worker texture/mesh duplication is introduced.
The existing physician crowd derivative had a stale source timestamp after a
separate import pass; it was rebaked without changing the benchmark source or
extending its skeletal use before rerunning the locomotion gate.

Visible reviews use presentation fixtures on the designated city's actual flat
ground, with native simulation paused and scratch preference/save roots.
These captures establish appearance and state selection, not complete native
production journeys through every campaign. The first capture helper used a
full-snapshot tile key after a delta refresh; it now reads the persistent tile
map. Protected native save and preference fingerprints stay unchanged.
The first shoulder-load view was partly hidden by the cloak; the final Godot
load is raised .12 tile and widened from .55 to .70 scale. Final captures are
`field-work-{gallery,boar,deer,goatherd,grapes,olives,oranges,corral}-{work,return}.png`
and `field-work.gif`. They include attack/recovery, sheep contact, visible loads,
fruit reaching and a rancher guiding a cow outside the active corral. The live
Blender service still reports the same 129-object scene; exports used factory
background processes only. A stale `%MoneyIcon` lookup in the current HUD was
removed because its replacement coin is constructed dynamically; this also
removed the dependent startup errors. Final EN/RU reviews are clean.
Headless import completed; the sandbox refused the optional editor-settings
write under Library. Runtime gates and visible reviews do not depend on that
write. User visual acceptance, slope foot IK, full material baking, minimum-Mac
profiling and broader campaign coverage remain pending.

## Episode completion and briefing redesign — 5 October 2026

**Implemented and technically verified; user visual acceptance pending.**
The shared campaign card has a framed chapter/result header, original victory
medallion, separate native episode counter, parchment story and individual
objective cards. Native achieved flags alone supply green checks and the count;
the completed-objective heading appears only when every supplied goal is met.
Story and objective lists scroll independently above a fixed action/difficulty
footer. Both the city overlay and first New game briefing use the same layout.

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| English actual pointer/keyboard/panel review | 39 PASS | `episode-panel-en-engine.log` |
| Russian actual pointer/keyboard/panel review | 39 PASS | `episode-panel-ru-engine.log` |
| Actual campaign scenes and native progression | 21 PASS | `episode-panel-campaign-ui.log` |
| Broad translation gate | 5 PASS, 2 retained unrelated FAIL | `episode-panel-text.log` |

Visible reviews load an owned, disposable copy of the full designated city
(25,992 tiles), then freeze its presentation for the campaign screens. Native
story text and objective quantities are compared directly with episode/preview
queries. Pointer and Enter difficulty changes reach the native service. Reviews
exercise result → Continue → next briefing → Begin, native paused time while
reading, full story scrolling, retry/menu callbacks and first-briefing Back
releasing ownership. 125% interface / 130% text at 1280×800 and 1280×720 retains
bounded shells, useful reading areas, the first objective and visible actions.
All added interface headings/tooltips are imported and visibly reviewed in RU.

The native `test_win` command drives the visible transition without playing hours;
it deliberately leaves native goal flags alone, and the result card retains them.
`completed-fixture` is a separate **presentation-only** all-achieved copy to review
the normal victory heading/green-card wrap at enlarged text sizes. The reviewer
proves that this copy never changes native goals. Retry/menu callbacks are observed
without replacing the frozen backdrop in that fixture; the campaign-scene gate
separately exercises actual retry, both colony maps, the return to the parent with
its road preserved and the final Main menu transition. The gate's two stale
direct-child Set aside lookups now search the existing nested objective cards;
its episode-number assertion reads the new separate counter.

Captures are `episode-panel-{en,ru}-{briefing,victory,story-end,next-chapter,
large-800,large-720,completed-fixture,defeat,complete,menu-briefing}.png`.
Scratch profiles/settings/save roots protect the source city and player
preferences; hashes remain unchanged. No native C++ rebuild or source artwork
edit is part of this presentation slice. Narration/campaign callbacks remain.

The broad CSV gate still finds the unrelated building-inspector overflow key
with a leading-space CSV row plus five older unused interface rows; no new
campaign-panel text is missing. The scoped passes do not claim whole-game parity,
gamepad coverage, narrower-window acceptance or minimum-Mac performance. Existing
production content provenance/release gates remain applicable.

## Main-menu redesign — 5 October 2026

**Implemented and technically verified; user visual acceptance pending.**
The left-hand main menu separates the leader row, latest-save card, primary New
game action, load/editor actions and utility row. Its original SVG emblem/icons,
navy/bronze surfaces and typography use the shared Theme. Continue shows the exact
latest save's name and metadata, with an ellipsis/full tooltip for long names.
Empty profiles hide the card and focus New game. Current language and named
Settings are visible; keyboard focus follows the scrolling shell when needed.

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| English actual pointer/keyboard/menu review | 30 PASS | `main-menu-en-engine.log` |
| Russian actual pointer/keyboard/menu review | 30 PASS | `main-menu-ru-engine.log` |
| Native leader/city regression | 52 PASS | `main-menu-leaders.log` |
| Broad translation gate | 5 PASS, 2 FAIL outside main-menu copy | `main-menu-text.log` |

Visible reviews use owned Metal/Mobile windows with scratch preferences, two
disposable leader profiles and a byte-for-byte copy of the designated save. They
exercise empty/existing saves, language cycling, profile switching, Load/Back,
New game/Escape, editor/Back, Tab order, settings and five sound volume controls.
125% interface / 130% text at 1280×800 and 1280×720 keeps the shell bounded and
scrolls Settings fully into view. Captures are
`main-menu-{en,ru}-{new-player,continue,large-800,large-720}.png`.

Actual Continue reopens all **25,992 cells** and matches a fresh native read of
the same scratch save (**841 current building records**). The comparison reader
uses the same allowed save directory; the reopened city is paused before ticks
can change its initial records. Source save and player preference fingerprints
remain unchanged, and browsing adopts no simulation. The older startup gate's
Continue assertion now checks the separate save-name field.

The broad CSV gate finds an unrelated building-inspector `(overflow: %d)` key
whose CSV row starts with a space, plus the five previously unused interface
rows. Main-menu/adventure copy is translated and visually reviewed in Russian;
these focused passes do not claim the whole CSV gate passes. Gamepad navigation,
wider window/platform coverage, user art acceptance and minimum-Mac profiling
remain pending.

## Illustrated adventure library — 4–5 October 2026

**Implemented and technically verified; user visual review remains separate.**
The selected adventure has native artwork, description, a mode badge and exact
first-episode goals in its right-hand card. Objective-free adventures are marked
Sandbox across all parent/colony templates, not inferred from their names or
an empty opening episode. Main episodes and alternative colony scenarios are
counted separately; alternatives are not presented as a linear playthrough total.

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| Native preview/ownership/goal/art gate | 232 PASS; 52 previews, all 26 adventures in EN/RU | `adventure-cards-native.log` |
| Packed artwork metadata | 18 IDs PASS against native headers | `tools/adventure_art_metadata.py --check` |
| English actual menu navigation/card review | 29 PASS | `adventure-card-en-engine.log` |
| Russian actual menu navigation/card review | 29 PASS | `adventure-card-ru-engine.log` |
| Retained embedded simulation regression | 101 PASS | `adventure-cards-embedded.log` |

Native previews match opening-goal wording from fresh native games, release
temporary ownership and reject foreign references or live-city ownership.
The parent world district supplies Atlantean ship terms before an active city
exists. Installed loose images and packed Poseidon artwork load through a bounded
18-ID, 960-pixel cache; no reference screenshot or source artwork was copied.

Visible Metal/Mobile reviews exercise pointer and arrow selection, campaign/
Poseidon/sandbox cards, rapid stale selections, Start/difficulty/briefing Back,
Escape, editor controls and 125% interface / 130% text layouts at 1280×800 and
1280×720. The opening objective stays visible; longer details scroll. Captures
are `adventure-card-{en,ru}-{campaign,atlantis,sandbox,large-800,large-720}.png`.
Scratch settings/save roots protect the designated native city and player
preferences; both fingerprints remain unchanged. Extension builds used the
mandatory finalization/signing helper. Preview selection creates no city or
adopted simulation. Existing production artwork provenance remains applicable.

The broad translation gate had five pre-existing unused rows at this slice;
all adventure copy has imported Russian translations. Later concurrent interface
work is tracked in the main-menu translation evidence below. Wider custom-author
edge cases, narrower windows, gamepad coverage and minimum-Mac profiling remain
pending. These focused results do not clear older whole-game parity failures.


## Hydra reference model — 4 October 2026

**Implemented and technically verified; user visual acceptance pending.**
The new `hydra_reference_v1` replaces only the Godot `walker_hydra` asset.
Three arched necks and expressive heads join a four-legged muscular body, with
charcoal scales, crimson eyes, black hooked spines, ivory teeth and one tail.
The reproducible background Blender adapter and editable scene are retained.
Native sprite recipes, coordinates, rules, RNG, saves and timing are unchanged.

Measured decoded geometry:

- **17,046 authored vertices**, **27,860 imported vertices**, **24,160 triangles**,
  **two surfaces**. Allocations: 24,000 / 32,000 / 30,000 respectively.
  Imported meshes have **9 LOD entries**, with **112 terminal triangles** in total.
  Only `walker_hydra` is deliberately updated by this slice in the existing
  geometry baseline; other prior workspace entries are preserved.
- Neutral vertical bounds **0.021592–2.006921** Godot units; body height
  **1.985329**. Displayed tax collector body height **0.949020** (1.12 multiplier),
  Zeus body height **2.455466**. Hydra ratios: **2.091977** citizen / **0.808534**
  Zeus. The comparison excludes held props through UV2 and excludes god hover.
- All **114 authored samples** have a vertical envelope **0.010414–2.082220**;
  the fallen body finishes below **0.737922**. These are flat-ground geometry
  checks, not per-paw terrain IK. 24 walk / 12 idle / 24 fight / 24 fight2 /
  30 die samples retain an in-place root, independent necks and .64-tile native
  stride. Support paw velocity cancels native travel rather than merely matching
  a manifest number.
- UV-preserving optimization proves **226 part-frame aliases**, two primitives,
  **zero differences** to the fresh backup. Both UV sets, palette, indices and
  positions are preserved. The runtime bake has **205 distinct part poses**,
  **23.5 MiB** of half-float pose texture and maximum component error **0.000488**.
  This is an allocation measurement, not a matched GPU performance result.

Verification:

| Check | Result | Evidence under `godot/captures/` |
| --- | --- | --- |
| Decoded scale/contact/clip/stride gate | 25 PASS | `hydra-asset-validation.json`, `hydra-asset-validation.log` |
| Imported LOD/finish/VAT/mouth/clock gate | 17 PASS | `hydra-runtime-validation.json`, `hydra-runtime-engine.log` |
| Exact source optimization | zero differences | `hydra-optimization-verification.log` |
| Runtime/source pose proof | 205 part poses PASS, no stale derivative | `hydra-poses-engine.log`; worst fingerprint gap 0.000562 |
| Whole development asset catalog | 431 PASS | `hydra-assets-engine.log` |
| Native monster gate, including Hydra roaming | 36 PASS | `hydra-monsters-engine.log`; Hydra travels 4.8 tiles |
| Native effect contract | 77 PASS | `hydra-effects-engine.log` |
| Whole geometry/LOD gate | PASS | `hydra-geometry-engine.log` |
| Studio model/scale review | eight captures PASS | `hydra-model-engine.log`, `hydra-model-*.png` |
| English native-city combat | 14 PASS | `monster-effects-en-engine.log`, `monster-effects-en.json` |
| Russian native-city combat | 14 PASS | `monster-effects-ru-engine.log`, `monster-effects-ru.json` |

The general asset gate now recognizes only manifest-declared collect/carry/deposit
samples with exact contiguous counts, correcting false failures for the already
authored skiff/diver clips. The pose gate's optional `--only=` runs the unchanged
texel/position proof on selected re-exported assets; its default remains all assets.

The studio captures inspect front, side, rear, three-quarter, bite, venom, fallen
and citizen/Zeus comparison views. City reviews use the actual native three-shot
obstacle-destruction action, native facing and terrain-following root. Venom
origins interpolate three sampled mouths through the displayed model transform.
The English GIF `hydra-combat-en.gif` records 66 frames at 10 fps. Both languages
capture breath, impact and real native ruin creation, hold particle/native time
while paused, and preserve save/preferences fingerprints. Reviews are sequential
and close their owned windows. An initial recording timed out while large model
checks were running; the isolated rerun passed. Final desktop logs have no
Hydra-specific script/shader errors; existing ObjectDB cleanup, missing native
voice/adventure and sandbox certificate/editor-settings warnings remain separate.

User art acceptance, full painted material baking, slope/stair foot IK,
multiple combatants, wider campaign coverage and minimum-Mac profiling remain
pending. Other monsters keep their earlier bodies. Provenance remains
`needs_evidence`; source/asset hashes are in `assets/monsters/hydra_sources.json`.
Read [monster art contracts](GODOT_MONSTER_ART.md).


## World-map water, keyboard and interface refinement — 4 October 2026

The submerged rectangular relief grid used to show through the coarser sea
sphere. Coast-coverage clipping now removes those fragments and their shadows;
sea curvature, ripple normals/materials, weathered terrain, woodland scale and
soft cloud density were refined. The atlas shares held city camera bindings and
speeds, with fixed arrow-key pan; on-screen arrows select cities. Layout uses
shared Theme/CSV, a responsive toolbar/heading, circular portraits and existing
native owned-city stock. Native fields, positions, callbacks, rules and saves
remain authoritative. See `GODOT_WORLD_ATLAS.md`.

- `python3 tools/review_world_atlas.py --lang en --size 1600x1000` and sequential
  `--lang ru --size 1280x800`: **61 PASS each**, no script/shader errors in final
  runs. Includes all earlier 31 checks, exact native stock rows, held WASD/arrows,
  camera-relative direction, Q/E/R/F signs, cancellation/release, Shift, pitch/pan
  limits, flight/modal/typing/modifier/focus guards, rebinding and 125%/150% layout
  bounds. Scene remains **35 meshes / 185,640 triangles**, below 100 / 220K.
- A real-render comparison hides only the relief mesh and compares deep water
  to the ordinary scene: **180/180 samples** remain within 0.025 RGB tolerance
  in each final language run. This catches the original rectangular plate;
  normal cosmetic wave/cloud motion is tolerated. Overview, city, Greece and
  enlarged-interface PNGs were opened and inspected. This proves the designated
  view, not all angles or every campaign's coast.
- Headless `validate_world.gd`: **32 PASS**. `validate_controls.gd`: **59 PASS**.
  `validate_ui_text.gd`: **6 PASS / 1 FAIL**, solely the existing orphan rows
  `City ground`, `Decision required · Click to review`, `%d pending decisions ·
  Click to review`, `Cancel a drag; send the selected banner to a tile`, and
  `Paused · Awaiting your reply`. Every used literal has a Russian translation;
  the three new hint/tooltip rows are used and translated. Unrelated rows remain.
- Final standalone first builds measured **434 ms EN / 382 ms RU**, cached
  revisits **37 / 41 ms** on the local M4. These are short setup observations,
  not sustained GPU or minimum-Mac performance evidence.
- The reviewer foregrounds its owned window and forces capture draws to avoid
  waiting indefinitely for `frame_post_draw` when macOS occludes the preview.
  Initial review-only parse/focus/recording issues were repaired before the
  final 61-check runs. The flight's moved-toolbar reference was repaired to
  `%AtlasToolbar`.
- `python3 tools/review_world_atlas.py --flight --lang en` and sequential
  `--flight --lang ru --size 1280x800`: **37 PASS each**, with exact city pose,
  visibility, running/paused state, pending-command ordering and native snapshot
  restoration. Both use the unchanged 1.55 / 1.20-second animation constants.
  The existing six-second wait excludes measured synchronous capture storage:
  **17,741 ms EN / 11,505 ms RU** across 25 / 24 saved images. The helper's
  overall 150-second deadline remains. These recorded runs are not FPS benchmarks.
- `--native-ui --lang en` and `--native-ui --lang ru --size 1280x800`: **16
  retained native assertions + 5 integration checks each**. Native requests,
  regard, 500-drachma gift, fulfilment, city selection, F2/Escape, pause/resume,
  covered-city rendering and Space suppression pass. The panel and whole toolbar
  are visible after ascent; `world-atlas-{en,ru}-integrated.png` was opened for
  visual review. Native economic mutations stay inside disposable memory runs.
  The city-scene reviews retain an ObjectDB cleanup warning after reporting zero
  outstanding batch loads; standalone map reviews have no such warning.
- Every final visible run verifies designated-save, workspace-settings and
  per-user preference hashes. Missing legacy voice/Atlantis-text notices persist;
  headless startup retains the macOS certificate/editor-settings sandbox notices.
  No C++ rebuild, source-map/field rebake or live Blender edit was needed.

Remaining: user visual acceptance, label crowding at accessibility extremes,
wider native campaigns/armies, surveyed geographic elevation, further terrain
and character art, minimum-Mac profiling and release-source clearance. Terrain
is still artistic and city landmarks symbolic.

## Fishing spots and authored gathering — 4 October 2026

**Implemented and technically verified; revised art awaits user visual review.**
The finalized/signed embedded extension appends native `hasFish`/`hasUrchin`
flags at tile column 9 through the existing terrain delta cache. Procedural fish
schools and spiny urchin clusters render in spatial MultiMeshes. Fishing skiffs
and urchin workers now use authored 40-sample collect clips; the diver also has
12 bag-carry and 12 deposit samples. Cast nets follow solved hand positions;
a Godot-only timing adapter shortens the submerged dip and extends recovery.
Work-state changes blend from the previous work pose. Small surface glints and
three diver bubbles replace the first pass's root tilt and separate floating net.

Verified:

- `validate_water_life.gd`: **33/33**, including native deposit observations,
  idle delta stability, legacy rows, incremental spatial rebuild/removal,
  paused/blocked clocks, visible fin/spine indices, LODs and 128-worker/384-bubble
  caps. Evidence: `godot/captures/gather-final-water-engine.log`.
- `validate_gathering_motion.gd`: **18/18**, complete clip samples, normalized
  weights, native-clock progression/pause, entry/exit, no root tilt, carry/deposit
  transition continuity and death priority. Evidence: `gather-final-motion-engine.log`.
- Source optimization: both models retain exact geometry/morph positions and both
  UV sets. Final runtime/source pose gate verifies **2 models / 328 distinct
  part-poses**, no stale derivatives, worst fingerprint gap **0.000460**.
  Evidence: `gather-final-poses-engine.log` (the standard pose gate scoped to these
  two changed assets). The full geometry/LOD gate passes:
  `gather-geometry-engine.log`. Imported full-detail triangles: diver **29,625**,
  skiff **27,071**; terminal LODs: **485** and **1,518** respectively. Only these
  two geometry baseline entries were changed by this slice.
- Retained embedded engine: **101 checks**; replay: **200 ticks**; map polish:
  **16**; elevation: **22**; locomotion: **35**. All pass. The elevation gate
  accepts the appended resource mask while retaining earlier column checks.
  Logs: `validate_<embedded|replay|map_polish|elevation|locomotion>-water-engine.log`.
- Separate Metal/Mobile English and Russian previews pass using scratch
  preferences. The designated save, native settings and per-user preferences
  fingerprints remain unchanged; no pending threaded model requests remain.
  Evidence: `water-life-en-engine.log`, `water-life-ru-engine.log`.
- Captures: `godot/captures/water-life-spots.png`, `water-life-urchins.png`,
  `water-life-fish.png`; the revised animated close-up is `water-life.gif`.

Scope: the designated city has **4 native fish / 0 native urchin deposits**.
The urchin visual fixture adds bit 2 only to a copied presentation tile on real
water. Both collectors are render-only fixtures; these captures do not prove a
complete native gatherer journey or broader campaign coverage. Opaque water uses
surface-tinted wildlife. Underwater refraction, user visual acceptance and
minimum-Mac profiling remain pending. Development art retains `needs_evidence`
provenance. Existing missing voice/adventure warnings and the sandboxed headless
certificate warning remain unrelated to these checks. Some preview exits also
report an ObjectDB cleanup warning; neither visible language review reports
shader/script errors or uncollected threaded model loads.
See [water-life contracts](GODOT_WATER_LIFE.md) for sources and reproducible steps.

## Monster combat effects — 4 October 2026

**Implemented and technically verified; user visual acceptance pending.** Hydra
has green venom breath/trails, visible facade contacts, impact rings/splashes,
and dust with stone debris after its target becomes native ruins. All 17 native
monster kinds have the shared launch/impact renderer; other species currently
use a generic warm finish. Fight/fight2/die poses and building fire/smoke already
existed. This effects slice originally used the old mesh; the subsequent
three-headed replacement is verified in the model section above.
Contracts/provenance: [GODOT_MONSTER_EFFECTS.md](GODOT_MONSTER_EFFECTS.md).

| Check | Result | Evidence |
| --- | --- | --- |
| Signed extension helper build | PASS | `godot/captures/monster-effects-build.log` |
| `validate_monster_effects.gd` | 77 PASS | `godot/captures/monster-effects-contract-output.log` |
| Actual-city English Metal/Mobile review | 14 PASS | `godot/captures/monster-effects-en-engine.log` and `monster-effects-en.json` |
| Actual-city Russian Metal/Mobile review | 14 PASS | `godot/captures/monster-effects-ru-engine.log` and `monster-effects-ru.json` |
| Retained `validate_monsters.gd` | 34 PASS | `godot/captures/monster-effects-monsters-output.log` |
| Retained `validate_embedded.gd` | 101 PASS | `godot/captures/monster-effects-embedded-output.log` |
| Native/embedded seeded replay | 6 cases PASS | `godot/captures/monster-effects-replay-parity.log`; ticks 0/200/1200, seeds 7/11 |
| Python syntax, source JSON and scoped whitespace check | PASS | Preview wrapper/manifest parse and `git diff --check` |

The 77-check suite covers renderer budgets, native-time interpolation, pause and
decision blocking, duplicate/cancel handling, transient expiry and city/session
reset. Hydra runs the original native three-shot obstacle-destruction action in
EN/RU. Launch and impact events survive an entire short flight between snapshots;
snapshots do not mutate native state or replay consumed impacts. Every other
monster kind independently produces matching native launch/impact records.
Sea creatures use a disposable land-side strike solely to test event transport;
this is not sea navigation or species-specific art evidence.

Sequential visible reviews use the designated city, scratch preferences and
scratch save directories. They capture real native breath, impact and collapse,
verify held native time/particle transforms while paused, and observe three
launches, three impacts, one collapse and two shared drawing nodes. Final saved
images `godot/captures/monster-effects-{breath,impact,collapse}-{en,ru}.png` show
the head-cluster breath, visible wall contact, dust and debris. English recording:
`godot/captures/hydra-combat-en.gif` (66 captured frames, 10 fps). Screenshots were
visually inspected. Save/preference hashes stayed unchanged. All replay cases
match native gameplay-state digests and native reproducibility, with no
worker-thread RNG draws. This proves the tested cases, not all campaign/combat parity.

The first desktop run inside the filesystem sandbox aborted before logging;
the final desktop reviews ran with approved desktop access. Final visible runs
have no effect-specific script/shader errors. Headless sandbox runs emit a macOS
certificate-lookup warning; existing missing voice-file and Atlantis-description
warnings remain outside this slice. Individual art beyond
Hydra, same-tile attacks without missiles, mouth/socket tracking for other species,
loaded in-flight visual review, simultaneous combat stress and minimum-Mac
profiling remain pending. The effects introduce no persistent poison or damage rule.

## Historical Hydra concept pass — 4 October 2026

Reference-only art work: a built-in imagegen concept sheet, with a primary
three-quarter rendering, side/rear studies and a citizen/Hydra/god size guide.
Selected PNG and the preserved user input have hashes in the accompanying
provenance record; exact initial and scale-refinement prompts are retained.
The proposed height relationship is 1.0 / 2.1 / about 2.7; actual runtime mesh
measurement and city-camera comparison were pending at that stage; the model
pass above supplies measured geometry and city evidence.

Visual review covers three distinct heads, arched necks, four weight-bearing
legs, a single tail, dark scales, pale belly scutes and red eyes. The generated
views are concept studies, not exact orthographic projections. No runtime code,
model, native sprite, save or preference was changed, and no game run/build or
gameplay validator was needed for this document/image task. This is not evidence
of model integration, animation, performance or user art acceptance. Handoff:
[GODOT_MONSTER_ART.md](GODOT_MONSTER_ART.md).

## Curator eyebrow correction — 4 October 2026

At the user's request, shortened the brow root span from .030 to .022 units,
widened the brow body with tapered tails, and increased fine hairs from 650 to
1,000 per eyebrow. Only the curator portrait was re-exported. Manifest records
`eyebrows: compact_full_v1`; updated reference guide preserves this direction.
Current export is 506,830 vertices / 37,123,320 bytes. Static portrait validation
and the final English Character-panel review pass (33 checks); front/three-quarter
captures in `godot/captures/character-curator-*-en.png` show the updated brows.
Native time, save and preference hashes remained unchanged. The first review
passed portrait checks but failed two pointer-picking assertions; its evidence
is retained in `godot/captures/curator-brows-first-review.log`. The unchanged
review passed on rerun; this is not a claimed pointer-picking fix. Russian UI
was not rerun for this geometry-only adjustment. Visual approval remains pending.

## Elder curator Character-panel benchmark — 4 October 2026

**Implemented and technically verified; user visual acceptance pending.** One
68-year-old curator portrait replaces the previous thick curl geometry with
surface-sampled tapered hair, eyebrows and a short salt-and-pepper beard, and
uses corrected facial landmarks and an aging sculpt/paint pass. Only this
on-demand portrait enables a private close-up material, full mesh detail, 1.5×
render scale, softer key and closer framing. The crowd and C++ simulation are
unchanged. Source/workflow: [GODOT_PORTRAIT_REFERENCE.md](GODOT_PORTRAIT_REFERENCE.md).

| Check | Result | Evidence |
| --- | --- | --- |
| `python3 tools/validate_curator_portrait.py` | PASS | 498,433 exported vertices, 36,518,832 bytes; both UVs, palette and normals; no skeleton, morph targets or animations; revision/age/provenance checks |
| `python3 tools/review_character_panel.py --lang en` | 33 PASS | `godot/captures/character-en-engine.log` |
| `python3 tools/review_character_panel.py --lang ru` | 33 PASS | `godot/captures/character-ru-engine.log` |
| Source syntax and `git diff --check` | PASS | Python compile checks, no whitespace errors |

Visible reviews ran sequentially with scratch preferences and the designated test
city. They cover native lines/voices, person/god/hero/animal panels, paused-clock
and queued-command holding, Escape/Go to, large UI layout, native curator model
selection, private material identity, unchanged city finish, portrait quality
reset when switching roles, and native money/buildings/events preservation.
Native time remained 4486720.0 throughout each final review. Wrapper hashes prove
the designated save and protected preferences stayed unchanged.

Actual final Godot captures: `godot/captures/character-curator-{front,three,side,full}-{en,ru}.png`.
Front, three-quarter, side and full-figure geometry/framing were inspected; Blender
source close-ups are under `godot/captures/curator-reference/`. The earlier portrait
pair is retained there in `before/`. GLBs/captures remain ignored generated files;
the paired portrait manifest and reusable source are retained in the repository.

An initial reviewer type-inference error was corrected before passing runs.
Headless import completed; the sandbox denied unrelated global editor-settings
writes. The subsequent visible Metal/Mobile runs loaded the imported asset and
shader without errors. No extension/native executable rebuild was needed.

Limits: static held pose, no facial performance/blinking; vertex-painted skin and
procedural microrelief rather than scanned/painted skin textures; one face per
role. The 600K-vertex/40-MiB ceiling is for one panel model, not a crowd allocation.
Minimum-hardware profiling, photorealism, user approval and production provenance
clearance are not established. Do not propagate this candidate across the catalog
without the requested visual review.

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

## Character window — 3 October 2026

- `python3 tools/review_character_panel.py --lang en` and `--lang ru`: **PASS, 26 checks each**, designated save and
  real preferences unchanged. All 279 drawn walkers are described by the core; 183 have a voice file and all load; the
  only wordless walkers are animals and carts with nothing to say (as in SDL). Covers picking (not through the dock),
  pause/queue hold with the native clock held, model, voice play/stop/replay, others on the tile, 1280x720 at 125%/130%,
  Escape and right-click closing with resume, a god, a hero, a wolf, Go to, and unchanged money/buildings/events.
  Captures: `godot/captures/character-*-{en,ru}.png`.
- `python3 tools/review_escape_menu.py --lang en`: PASS, 67 (right-click back unchanged).
- The extension was rebuilt with `tools/build_godot_extension.sh` (it compiles the SDL widget too). The SDL
  executable `Bin/eZeus` was not rebuilt.

## Playable-loop slice 27: triremes, races, wharf and hippodrome pages — 4 October 2026

- `validate_naval_race.gd`: **PASS, 65 checks** (EN and RU), headless.
- `validate_menu_rest.gd` 179, `validate_assets.gd` 393 (the nine new models included), `validate_city_data.gd` 64: PASS.
- `validate_ui_text.gd`: the new strings are used and translated; the orphan rows ("Decision required · Click to review", "%d pending decisions · Click to review", "Paused · Awaiting your reply", "Cancel a drag; send the selected banner to a tile") come from another session's HUD and controls work.
- Review: `--menu-rest-review naval` (trireme at its wharf, the race with four chariots, the lineup), `captures/menu-rest-naval-*.png`.

## Playable-loop slice 28: leaders and the player's cities — 4 October 2026

- `validate_leaders_cities.gd`: **PASS, 52 checks** (leaders; cities in EN and RU), headless.
- `validate_buildings.gd` 535, `validate_city_data.gd` 64, `validate_menu_rest.gd` 179, `validate_naval_race.gd` 65, `validate_embedded.gd`: PASS after the Build menu, header and pages started following the player's city in view.
- Review: `--start-review leaders` in EN and RU (`captures/start-review-<lang>-*.png`, `captures/menu-rest-cities-*.png`).
- Windowed `run_godot_pilot.py --validate`: EN **610 pass**, RU **610 pass** (on a second run; the first RU run once found the city unpaused at the start, which did not recur), each with the one long-standing failure (the world map's aid-regard check).
- `validate_ui_text.gd`: the new strings are used and translated; the orphan rows ("City ground", the decision rail's and the controls' rows) come from another session's work.

## Gold HUD — 4 October 2026

- The theme (`build_ui_theme.gd`: `gold_frame`, `gold_face`) replaces the teal "Nova Roma" frames. Covered: the status
  strip, the resource ribbon, mini panels, the dock, the floating tray, cards, tools, category medallions, building
  cards, notice chips, the map pill and fold, the escape card, placement verdicts, progress bars, and the minimap ring
  (`minimap.gd` reads `MapCard` `rim`).
- No validator checks style colours. `--objectives-review gold` captures every panel: closed, open, housing,
  inspector, build and messages (`captures/hud-gold-before-after.jpg`).

## Gold dialogs and escape menu — 4 October 2026

- The dialog frame now contains the title bar and close cross, and the escape menu has new heading, rule and action styles.
- `tools/review_escape_menu.py`:
  - RU passes all 67 checks; captures in `captures/escape-dialogs-gold.jpg`.
  - EN passes all 67 checks, then Godot crashed at exit in `BaseMaterial3D::~BaseMaterial3D` (the known
    material race).
- Windowed runs before the dialog changes: EN 610/611 (only the known aid check fails). The RU run's 610 checks all
  passed, then shutdown flooded `Parameter "material" is null` (123 MB) until stopped. That is the same threaded
  GLB-loading bug.

## Playable-loop slice 29: requests, box selection, the view on attacks, rowing, rioters, building workers — 4 October 2026

- `validate_requests_units.gd` **17**, `validate_attack.gd` **53** (the view sent once to the attacked city), `validate_building_activity.gd` **219** (47 buildings), `validate_characters.gd` **208** (102 human walkers), `validate_assets.gd` 423, `validate_poses.gd`, `validate_naval_race.gd` 65, `validate_leaders_cities.gd` 52, `validate_fight.gd` 31: PASS.
- Windowed `run_godot_pilot.py --validate`: EN and RU **617 pass**, each with the one long-standing failure (the world map's aid-regard check). The new checks: the summary's request row and Send button; three placed banners boxed on screen, each with its ring, sent together (they stand spaced around the tile, the farthest about seven tiles off, as the engine places a group); Escape lets them go. The windowed checks raise fresh companies first (earlier checks send the city's own abroad) and place their banners (a flag is drawn only for a placed banner).
- Review: `--menu-rest-review anim` (the trireme rowing at two moments, the two rioters in their own dress, the college, dairy and armory at work), `captures/menu-rest-naval-anim-*.png`.

## Character window portraits as images — 4 October 2026

- `python3 tools/render_portraits.py`: PASS, curator rendered 592×760 (301,673 bytes, transparent), designated save and
  preferences unchanged.
- `python3 tools/review_character_panel.py --lang en` and `--lang ru`: **PASS, 31 checks each** (curator still shown with
  no 3D figure and the viewport disabled; switching to a role without an image restores the live figure; city material
  unchanged). Capture: `godot/captures/character-curator-{en,ru}.png`.
- Removed: 68 curled portrait GLBs/manifests, their `.import` files and 70 imported cache files (443 MB in the project).

## Playable-loop slice 30: City History, Trade Summary, City Advisor, walker routes, house card — 4 October 2026

- `validate_city_extras.gd` **52** (headless, EN and RU), `validate_city_data.gd` 64, `validate_naval_race.gd` 65, `validate_embedded.gd`: PASS.
- Windowed `run_godot_pilot.py --validate`: EN and RU **638 pass** each, with the one long-standing failure (the world map's aid-regard check); test save and settings unchanged. The 21 new checks: the window's Advisor/History/Trade pages and the summary's and storage page's buttons, a card per problem and per partner, the chart's last two years, a series and range kept across a refresh, "Go there" moving the view and closing the window, the inspector's route button opening the bar, a click on a road setting a guide, the walk drawn with its post, both ways, restore, Escape closing the editor, and the house card filled and hidden for a tool. Earlier runs on the same code each failed one different older check once (a free sanctuary site, the six-tile road drag, the husbandry no-priority share-out), all passing in the final runs: treat them as flaky.
- SDL: `Bin/eZeus` rebuilt and signed; `EZEUS_SHOT_PANEL=trade` and `advisor` render as before from the shared engine code.
- Review: `--menu-rest-review extras` in EN and RU (`captures/menu-rest-extras-<lang>-{advisor,history,trade,route,house}.png`): 5 of 5 captured.
- Dock width (4 October): `hud.gd` now measures the dock's full row: every control, the categories unscrolled, and the
  frame margins. This replaces the fixed 166 px allowance. When the dock and the objectives panel don't fit side by
  side, the objectives move up instead of the dock scrolling. At 1280×800 all 12 categories and the utility buttons
  show without scrolling (`captures/objectives-dock-closed.png`).
- While another session was editing it, `scripts/orbit_camera.gd:170` failed to compile (`var scroll :=` with an
  untyped `in` expression), which stopped `main.gd` from loading. It is now typed `var scroll: bool =`.

## Playable-loop slice 31: fires, ruins, chasm, lava and marsh — 4 October 2026

- `validate_disasters.gd` **22** (headless), `validate_assets.gd` 431, `validate_geometry.gd` PASS (68 missing baselines merged in: the eight ruins and the assets of slices 25–29; existing entries unchanged).
- Windowed `run_godot_pilot.py --validate`: EN and RU **643 pass** each, with the one long-standing failure (aid regard); test save and settings unchanged. The four new checks: flames (4) and smoke (2) on a burning house, ruins models after its collapse, lava in the ground's pattern texture. One earlier EN run on the same code failed three known-flaky older checks at once (the soldier's die clip, a free sanctuary site, whose script error then skipped the rest of the sanctuary checks, and the husbandry priority share-out); the re-run passed them.
- Review: `--menu-rest-review disasters` (`captures/menu-rest-disasters-{fire,fire-near,ruins-burning,ruins,quake,lava,marsh}.png`): 7 of 7.

## Model-loading crash and log flood fixed — 4 October 2026

- Cause: `building_batches.gd` requested GLBs with `ResourceLoader.load_threaded_request` and collected
  only the ones it used. Two failures followed:
  - Loads that were never collected kept their meshes and materials until engine exit, after the renderer was
    gone. That gave the `~BaseMaterial3D` → `shader_free` crashes and the endless `Parameter "material" is null`
    flood that filled the disk on 3 October.
  - Loader threads set up BaseMaterial3D shaders while the main thread rendered or built terrain, which caused
    the crash inside `material_set_shader` on a WorkerThreadPool thread.
- Fix: `prefetch_paths` still starts every load in parallel, then `join()` waits for all of them at once,
  so no loader thread runs during a frame. Every result is kept in `loaded`, released in `_exit_tree`, and
  `citizen_lod.gd` uses `warmed()`. `walker_vat.gd` joins its pose reads on teardown.
- Rejected:
  - Loading on the main thread: the buildings stage went from about 0.2 s to 1.0–1.3 s.
  - `rendering/driver/threads/thread_model=2`: Godot calls it experimental, and it added `_texture_2d_update`
    errors.
- Load time with the fix: buildings 0.13–0.22 s and walkers 0.07–0.12 s (before: 0.18–0.25 s and 0.15–0.59 s).
  `--objectives-review` prints `STARTUP_TIMING`.
- Stress run, with no crash, no flood and no new crash report:
  - `review_escape_menu.py` EN and RU: 67/67 each.
  - `--validate` EN and RU: 643/644 each (only the known aid-regard check fails).
  - Four objectives reviews.

## Aid check, gold decision cards and confirm buttons, Sparta street — 4 October 2026

- Aid regard: the core is right. A probe gave 90 → 70: 10 from every foreign city plus 10 from the city asked,
  as in the SDL game. `validate_main.gd` read "before" from the world map just after `wm.close()`.
  `open_world` returns early while the map is still visible or flying out, so the map kept stale data (80). The
  check now reads "before" from the core.
- The decision card and `EnvoyAction` buttons use `gold_frame`/`gold_face`. Every AcceptDialog's OK button is
  Primary. `hud._attach_right_click_back` is untyped, so a dialog freed before the deferred call no longer
  errors ("Cannot convert argument 1 from Object to Object"). `review_envoys.py` passes 21/21 and the EN escape
  review 67/67.
- Street facing on the player's Sparta street, opened from a scratch copy of the 3 October 23:35 autosave with
  `--street-review` (copy deleted afterwards; the original is untouched): 19 of 27 Hovels turned, and doors and
  yards face the road on both sides and at corners (`captures/sparta-street-facing.jpg`).

## Monster card, heroes' halls offered mid-game, wheel over panels — 4 October 2026

- Extension rebuilt and finalized with `tools/build_godot_extension.sh` (new `monster_info` query, `buildable_revision` in the
  snapshot); new icon and strings imported with `--import`.
- Windowed EN: **GODOT_VALIDATION PASS**, 652 checks. Windowed RU: 651 pass, **one fails**: "a fallen soldier plays its die clip
  and then holds its last frame (no fall seen)", a timing-dependent fight check that passed in the EN run of the same build and
  does not touch the changed code.
- `validate_main.gd` monster checks rewritten for the card (13, all passing in both languages): no button before a monster, a red
  button with its count in the rail, the top notice left to invaders, the card with the monster's own message under the rail and
  within the screen, its slaying hero and hall, Go to the monster, a hall allowed mid-game (`test_allow`) in the Build menu without
  reopening the city, Build the hero's hall opening the Build menu on it with the hall chosen, the card following the language, two
  monsters counted and listed. A new camera check: the wheel over the Build tray at the start of its row does not zoom the map.
- The player's Thebes autosave (4 October 16:52, a hydra at large) was opened read-only from a scratch copy (deleted afterwards; the
  original is untouched) to find why no hall was offered: the core allowed Hercules' hall, the menu had not been refreshed.
- Scratch capture over the designated city (hydra let loose, hall allowed): the button, the card in English, with the build
  button, and with the Russian interface.

## Area demolition — 4 October 2026

Dragging the demolition tool over a rectangle removes everything the SDL erase tool would (`preview_demolish_area` /
`demolish_area`; see AGENTS.md). Headless `validate_area_demolition.gd` passes 26 checks in memory on the designated
city: the plan's count and cost equal the native cost per target, corners drag in any order, charging matches the quote,
an emptied rectangle is refused, a landmark rectangle needs confirmation, a stale token is rejected, unconfirmed
demolition spares the landmark and charges only the rest, a confirmed one removes it (an agora uncovers its street, which
a second drag clears), malformed and out-of-map commands are refused and oversize rectangles are clamped to 3000 listed
targets. The windowed `--validate` runs pass 657 checks each in EN and RU, including four new drag checks (press starts
the drag, the six roads are tinted and quoted, Escape cancels, release removes them for the quoted cost); the existing
demolition click checks now send a release. Not yet reviewed by eye: the amber landmark tint and the three-button dialog.


**Hazard alert icons (4 October 2026).** `ui/hazard_rail.gd` + the snapshot's `alerts` list. `validate_hazard_alerts.gd`
(headless, designated city) passes **34** checks: every hazard kind raised by `test_raise` arrives as an alert, a
journal-only event raises none, one button per kind, counts, ids shown once, dedup by place, go-to, lapse. Windowed
capture: `review_hazard_alerts.gd` (`godot/captures/hazard-alerts-*.png`). `review_map_notifications.py --checks --lang en`
has the same seven failures with and without the change (build tool card cost, header distribution shortcut).

**Building panel (4 October 2026).** Auto-applying store/trade drafts, the "All goods" row, wide pages, stall boxes and the
house card in the inspector. `review_building_panel.gd` (designated city plus an in-memory agora and food vendor) passes
**12** checks in EN and RU (order change applies by itself, the all-goods row sets every good, nothing left queued,
stalls listed, house needs shown); `validate_trade_ui.gd` 18; the status/context review 115 (its storage-draft check now uses
`edit_storage`); `validate_inspector_ui.gd` (inside `run_godot_pilot.py --validate`) covers draft, stale completion, full
queue (draft kept, sent again later) and commit with no Apply. `review_map_notifications.py --checks` still has the same seven
failures with and without the change.

**House needs and road chip (5 October 2026).** The house page leads with "To reach <level>" (or "Needed to keep this level"),
the missing needs with how to supply them, then "Already met"; the "Road access: Connected" chip is hidden unless the building
is cut off. `review_building_panel.gd` now has 18 checks (EN and RU pass); status/context review 115 in EN and RU.

## Roofs at zoom-out: LOD guard — 5 October 2026

Reproduced in isolation with `review_lod_roofs.gd`: at camera distance 70 the maintenance office and hospital lost their
blue roofs. Cause: `maintenance_office_3` (31,584 triangles of shingles) kept 16% of its silhouette at LOD 1 (12,666
triangles, error 0.23). The guard (see AGENTS.md) replaces that ladder with clustering LODs of 1,552 / 496 / 108
triangles that keep 99% / 78% / 70% on the same metric; at distance 70 both roofs now show. Audit before: 238 lossy
surfaces in 173 of 286 non-character models (old, stricter 64-cell metric: 285); after: 0 (`LOD_ROOF_VALIDATION PASS`).
`validate_geometry.gd` passes (431 GLBs, LOD ladders present, no growth over baseline) and windowed `--validate --lang en`
passes 659 checks. Not measured: frame time against the previous LODs (clustering levels are generally smaller than
Godot's, but surfaces left with only their sound levels keep a coarser-to-nothing ladder), RU windowed run (mesh-only
change), and a captured before/after at the user's exact zoom.

**Hazard alert audit (5 October 2026).** Added `land`, `monster` and `risk` buttons and persistent fire/plague buttons;
`validate_hazard_alerts.gd` 83 checks (every new kind raised by `test_raise`, snapshot `plague`, persistence, silencing).

## Camera reach when zoomed out — 5 October 2026

`validate_controls.gd` passes 62 checks (3 new: full reach at play zoom, middle 30% at the farthest zoom, eased between).
Windowed `--validate --lang en` passes (the final two runs, with the limit on and with it off). Two earlier runs failed 3-5
timing checks (held R/F tilt, slope picking, halt/resume, hero quest dialog) while another session's extension build kept
the machine at load 50-170; they did not reproduce on a quiet machine. Render cost per camera position (Metal reports no
GPU time, so primitives/draw calls): play 1.54 M / 925, overview 2.27 M / 1,970, far outside at the border 1.48 M / 934.

**Building auras (5 October 2026).** Plague over sick houses, blessed and cursed buildings. `review_auras.gd` passes **6**
checks on the designated city in memory (house sickens and the engine's plague spreads to several, the snapshot counts them,
blessed/cursed get their effects, clearing removes them); captures `godot/captures/auras-{plague,blessed,cursed}-en.png`.
The plague count also feeds the rail's plague button.

## Top bar — 5 October 2026

Time controls, a housing gauge, a money well with a 3D silver coin and monthly balance, and a popularity face now sit in
the top ribbon (see AGENTS.md). Captures: `captures/topbar-en.png`, `captures/topbar-ru.png` (1920×1080, designated
city). `review_map_notifications.gd` checks the time bar inside the header, a chevron sending `speed 1`/`speed 3`, and the
map beside the dock; `review_escape_menu.gd` folds the overlay popup instead of the removed speed popup;
`review_envoys.gd` keeps cards above the dock.

**Aura visibility (5 October 2026).** Blessed and cursed buildings were drawn but too faint at play zoom (thin beam, pale ring on pale
stone). Added a zoom-stable disc badge over every marked building and a stronger ring; `review_auras.gd` now marks through the live
command queue and passes 6 checks, captures at distance 34 show all three badges.

**Disaster effects and on-screen sounds (5 October 2026).** `review_disasters.gd` passes **6** checks on the designated city in
memory: an earthquake, a lava flow, a landslide (on a slope; its alert opens the effect) and a tidal wave each draw their effects
(60-620 per disaster), and a building on fire in view is heard (the sound log, bus muted). Captures
`godot/captures/disaster-{quake,lava,landslide,tidal}[-front]-en.png`. The visibility checker only changes which sounds play
(`eRand::cosmetic`), not the simulation; replay parity was not re-run for it.

**Thrown missiles and soot (5 October 2026).** `review_missiles_soot.gd` passes **7** checks on the designated city in memory: 18
engine-made arrows, spears and rocks arrive as `shots` and are drawn in flight, a paused city holds them in the air, landed ones
disappear, a burning house gets a soot shell that darkens (0.34 to 0.68 after 15 s of burning). Captures `godot/captures/missiles-*.png`.
