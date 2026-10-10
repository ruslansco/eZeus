# Godot 3D city rebuild

## Consistent menu frame hierarchy — 10 October 2026

The ornate wood-and-gold frame remains the signature for full menu pages:
Adventures, Load game, Profiles, Settings, Extras and story. Smaller settings
forms and confirmations use matching restrained bronze/slate trim, leaving room
for readable controls. Secondary Back actions share clear padded blue styling.

The duplicate **Read chapter briefing** option is removed. **Start** still opens
the complete story on aged paper, all objectives and difficulty before **Begin**.
Chapter previews retain their native titles/goals and progression rules. Relaunch
**Launch Godot 3D.command** to see the update. Current validation records English/
Russian navigation, enlarged text and all five native campaign story routes.

## Tidebound Covenant campaign — 10 October 2026

Use **Launch Godot 3D.command → New game → Tidebound Covenant**, the fifth featured
campaign, or **Play Tidebound Covenant.command**. Three new English/Russian
chapters teach local food, domestic fleece and Atlantean science/housing, then
timber production and two reserves for a future outpost. No imports or export
income are available. Native buildings unlock by chapter; the city carries forward
and Continue/Load uses a separate campaign save slot.

All three chapters complete through ordinary gameplay, including both Set aside
actions. The static preview shows an owned copy of that successful city. Campaign
reviews pass 52 and normal five-campaign menu/save reviews pass 137 per language.
The retained map is Tributaries 3 by Nightwolf / David Masters; original files
remain intact. See [scope and evidence](../docs/TIDEBOUND_COVENANT.md). This remains
a private adaptation pending commercial retained-content clearance. Human pacing
and Windows acceptance remain open; existing Windows kits are unchanged.

## Stable building categories and readable dock label — 10 October 2026

The bottom toolbar keeps all sixteen building categories in the same order across
maps and chapters. Categories without currently available buildings use muted
grayscale icons, cannot be selected, and explain their status on hover in English
and Russian. They enable in place when the native catalog offers buildings.

The centered category name now reserves measured text space between Demolish and
Overlays, including at enlarged interface/text sizes. Settlement guidance skips
unavailable categories. Relaunch to load the updated interface; game rules and
saved cities are unchanged. See validation for the scoped toolbar reviews.

## Portal fitted to its stone frame — 10 October 2026

The main-menu portal now follows the doorway's actual curve, projecting stone
edges and angled threshold. Its fire stays registered to the scenic image as
the menu moves or resizes. The original artwork and animation are retained.
Relaunch **Launch Godot 3D.command** to see the alignment update. Current
validation records normal and enlarged English/Russian menu reviews.

## Greek settings pages — 10 October 2026

Start-menu **Settings → Display / Graphics / Sound / Interface / Controls / Game**
now opens one focused slate panel with original bronze Greek trim, ivory text,
aligned dropdowns and matching checkbox/slider details. The category hub hides
while a submenu is open; closing it restores its category and keyboard focus.
Small buttons remain plain, with full translated labels padded away from the frame.

Native Apply/Cancel, display preview/revert and nested Game settings behavior are
retained. Interface size/text previews update the panel live and Cancel restores
the prior sizes. The long Controls list keeps its bounded reading area. This
menu-only Theme is in `ui/settings_shell.gd`; the shared city interface and settings
implementations are unchanged. Relaunch **Launch Godot 3D.command** to see it.
See current validation for normal/enlarged English/Russian coverage.

## Sunlit Terraces campaign — 10 October 2026

Use **Launch Godot 3D.command → New game → Sunlit Terraces**, the fourth featured
campaign, or **Play Sunlit Terraces.command**. Three new English/Russian chapters
teach orange orchards on raised fertile terraces, olive oil and Greek housing
services, then vineyards and a shared wine reserve. Buildings unlock by chapter;
the same city carries forward and Continue/Load uses its own campaign save slot.

Ordinary gameplay completes all three chapters with actual orange sales, grain
imports, local oil/wine and an explicitly committed reserve. The retained map is
Everybody loves oranges by Genis. Original files remain intact; this is a private
adaptation with unresolved commercial rights. See [campaign scope and evidence](../docs/SUNLIT_TERRACES.md).
Human pacing and Windows acceptance remain open; existing Windows ZIPs are unchanged.

## Readable briefings on aged paper — 10 October 2026

Campaign headings, difficulty and action buttons now sit inside the wooden
frame. Story text uses an original aged parchment with dark ink, a clear reading
area and matching sepia page buttons. Every objective appears together, with no
objective page switches or scrolling. Smaller windows use a compact grid.
Long stories retain their complete wording across measured pages.

Parchment appears only when reading the story. The preceding adventure preview
now uses a dark slate surface with bronze trim, ivory text and gold headings.
Its chapter selector and all objectives remain visible together.

Relaunch **Launch Godot 3D.command** to see the changes. Paper artwork, exact
prompt and hash are recorded in `assets/menu/aged_parchment_v1.provenance.json`.
The native campaign flow, saves and city episode layout remain unchanged.
Current validation records normal/enlarged English and Russian visual reviews.

## Clear compact settings labels — 9 October 2026

Small key-binding and dialog buttons now use larger, clean sans lettering on
quiet dark surfaces with bronze edges and full padding. The ornate artwork stays
on large menu choices. This fixes crowded text in Home, key-change prompts,
Restore defaults and Done without changing bindings or settings behavior.
Relaunch to see the update; current EN/RU review captures are linked in validation.

## Greek cursor family and quieter focus — 9 October 2026

Menu focus now brightens the sculpted enamel button without a rectangular border.
An original bronze/blue-enamel cursor with an ivory tip is installed throughout
the Godot game, including menus and city play. Matching pointing hand, text,
crosshair, busy/wait, drag, forbidden, resize and help shapes retain each
Control's normal cursor behavior. Interface size scales the cursor; text size
remains independent.

Relaunch **Launch Godot 3D.command** to load the global `GameCursor` autoload.
The built-in generated atlas, exact prompt and derivative hashes are recorded in
`assets/cursors/olympian_cursors_v1.provenance.json`. Regenerate small transparent
textures with `--headless --path godot --script res://scripts/bake_game_cursors.gd
--log-file /tmp/ezeus-cursor-bake.log` from the repository. Native EN/RU menu
reviews pass 58 each; the focused cursor review passes 44. See current validation
for scope and the light/dark runtime-size art capture.

## Ornate Greek menus — 9 October 2026

Normal launch now has a tall walnut panel with antique bronze Greek-key trim,
ivory corners, an eagle crest and blue enamel buttons. The realistic coastal
scene and animated portal remain. The generated menu artwork has painted depth;
the frame itself is a raster asset. Text and controls stay crisp and interactive.

The main choices are Continue (when a save exists), New game, Load game, Settings,
Extras and Quit. Settings groups Display, Graphics, Sound, Interface, Controls
and Game. Extras contains the adventure editor and Profiles. Back/Escape returns
through the relevant parent. The main panel needs no scrolling; adventure, save
and profile catalogs use search and page buttons. Full briefing prose is
paged without discarding native text; objectives now appear together. Existing detailed settings dialogs retain
their behavior, including scrolling in the long key-binding list.

Use **Launch Godot 3D.command** to see the result. Menu-only artwork/theme and
pagination live in `ui/menu_{skin,navigation,list_pager,text_reader}.gd`.
`assets/menu/greek_menu_v3.provenance.json` links the three assets and exact saved
generation prompts. The shared city Theme, simulation and saved cities are
preserved. See current validation for EN/RU input, enlarged-layout and native
campaign/Continue evidence.

## Earlier realistic cinematic menu — 9 October 2026

The main menu now overlooks a realistic Greek coastal city with people, an
Acropolis, olive foliage, ships and detailed mountains. The existing live portal
fills the sanctuary doorway. This is photographic artwork with realtime effects;
the prior procedural city is retained as an earlier source. The ornate menu stage
above replaces the earlier 3D frames; campaign navigation and continuation remain.

Use **Launch Godot 3D.command** to see it. Reduced interface motion freezes the
scenic drift and portal. Artwork and portal remain aligned when the window or
interface scale changes. `scripts/cinematic_menu_world.gd` owns this composition;
`assets/menu/aegean_cinematic_v2.provenance.json` links its original saved prompt.
A separate packed Blender reference is in the parent workspace at
`art/menu/cinematic/aegean-cinematic-v2.blend`; the player's open Blender document
is preserved. The scene's city/people/mountains are a raster image, while its
portal preview is editable. EN/RU menu checks pass 34 each; current validation
records the visual/scale scope and remaining platform review.


## Earlier Olympian main menu (superseded) — 9 October 2026

Normal launch now opens an original 3D Aegean sanctuary: an elevated temple,
terracotta city, coastal harbour, olive gardens and Zeus statue, with the retained
living portal on the foreground terrace. Main, adventure, leader and load pages
have beveled 3D housings and raised primary buttons beneath the existing crisp
text and keyboard/mouse controls. Campaign artwork has more vertical space.
Reduce interface motion freezes camera, sea and portal; native menu actions,
leader/save scopes and settings remain intact.

The editable source is `scripts/olympian_menu_world.gd`; its compressed static
scene is a hash-checked derivative. Rebuild with the bundled Godot executable:
`--headless --path godot --script res://scripts/bake_olympian_menu.gd --log-file /tmp/olympian-bake.log`
from the repository. Missing/stale derivatives fall back to source generation.
Use `tools/review_main_menu.py --lang en` / `ru`; `--art-only` also captures the
unobstructed sanctuary. See current validation for checks and remaining limits.


## Healer treatment clears plague — 9 October 2026

Infirmary healers now cure infected houses they actually serve, including houses
already at full hygiene. Recovery uses the native outbreak registry, so the green
house marker disappears and the live plague count decreases together. Houses
outside the walker's service reach remain infected. Normal hygiene restoration,
road routes, infection risk and unattended recovery timing are retained.

Relaunch to load the signed extension, then let the healer visit again. Existing
infected saves work without conversion. Native EN/RU regressions and disposable
loaded-city patrol reviews pass; see current validation for evidence and scope.

## Stonewatch campaign — 9 October 2026

Use **Launch Godot 3D.command → New game → Stonewatch**. Three new EN/RU
chapters lead from a forest refuge and sea trade to supported defenders and a
warned invasion, then Theseus's preparation and Minotaur trial. The same city
carries between chapters; normal Continue/Load keeps a separate campaign save
slot. **Play Stonewatch.command** retains the isolated-launcher option.

An ordinary-command run wins all three chapters and observes the actual battle,
hero Summon/fight and slaying. The retained map is One Against the World by orius;
this is private adaptation content with unresolved commercial rights. See
[Stonewatch scope and verification](../docs/STONEWATCH.md). Windows ZIPs are frozen
and do not include this campaign. Human pacing/platform acceptance remain open.


## Wheat growth and harvest readiness — 9 October 2026

Wheat farms now grow visible green shoots into tall golden grain heads over their
existing furrows. Plant height and color follow the native harvest cycle and reset
after each harvest. The production inspector shows **Harvest readiness: %** and
a progress bar, separately from harvested wheat awaiting transport.

Staffing, industry shutdown, pause and saved growth retain their native behavior.
Relaunch to load the updated extension and crop layer; existing saves need no
conversion. See [crop contracts](../docs/GODOT_FARM_CROPS.md) and current validation
for tested scope and remaining visual/performance review.

## Both campaigns in the normal menu — 9 October 2026

Use **Launch Godot 3D.command → New game**: First Light Harbor and Bronze River
are first, with static city views, descriptions, default difficulty and selectable
chapter previews. Objectives stay above an optional full briefing. Begin starts
chapter one and applies the campaign's initial view.

Continue/Load identify the saved campaign and chapter. Separate campaign slots
protect autosaves; earlier launcher profiles remain discoverable through their
leader names without moving or overwriting originals. Sequential EN/RU campaign
reviews pass 61 each; retained save-recovery checks pass 36 each. See
[menu, save continuity and scope](../docs/GODOT_CAMPAIGN_LIBRARY.md).
The old launchers remain supported. Windows transfer packages are unchanged;
clean-machine/human acceptance and retained-content permissions remain open.

## Bronze River: second private campaign — 9 October 2026

**Play Bronze River.command** opens a separate three-chapter Armory-map adaptation:
settle the valley, connect copper/bronze/armor across the river, then earn a profit
and set aside supplies through a temporary trade interruption. Buildings unlock
by chapter; English/Russian writing explains imports, bridges, maintenance and
dedicated storage. First Light and its saves remain available through their launchers.

Native authoring passes 9, visible EN/RU reviews 53 each, and ordinary gameplay wins
all chapters with real armor sales/fleece imports and 2,390 final-year profit.
Bridge previews at map edges now safely reject invalid crossings. See
[campaign instructions and evidence](../docs/BRONZE_RIVER.md). Human playtesting,
this campaign's Windows package and retained-input release permissions remain open.

## First Light Harbor: three chapters — 9 October 2026

**Play First Light Harbor.command** now opens the staged campaign: establish food
and housing, add clothing/science/comfortable homes, then timber/trade/profit and
Poseidon's interruption. The city carries forward. New EN/RU briefings explain
appeal, forest placement, the palace needed for taxes and positive export stock
limits. New saves have their own profile; **Continue Previous First Light
Harbor.command** retains the earlier prototype and its saves.

Final EN/RU reviews pass 38 each and an ordinary-command settlement wins all three
chapters, including real timber sales and 1,046 final-year profit. Human 30–60-minute
pacing/newcomer review remains pending. See [chapter evidence](../docs/FIRST_LIGHT_CHAPTERS.md).
The updated private Windows Chapters ZIP includes this campaign/current core;
actual Dell execution remains pending. All retained art and native timing remain.

## Campaign building limits — 9 October 2026

The Build menu and native placement now honor ordinary service/civic permissions
as well as industry/wonder unlocks. Each episode supplies its own set, retained
through export/save/load and refreshed at the next chapter. Culture and market/
trade dependencies are respected. First Light Harbor's revised opening keeps its
required settlement tools and hides unrelated advanced/military buildings.

Relaunch and start a **new game** for its version-3 recipe. Existing saves keep
their stored definitions. The current prototype has one chapter with seven goals;
individual goals do not trigger chapter unlocks. See
[campaign permission contracts](../docs/GODOT_CAMPAIGN_BUILDINGS.md).
EN/RU unlock checks pass 37 each; prototype visible checks pass 34 each.

## First Light Harbor prototype — 8 October 2026

Double-click the root **Play First Light Harbor.command**, then New game →
First Light Harbor → Start → Begin. This separate development catalog has one
Alexandria-based settlement, new EN/RU writing, seven objectives, one neighbor
and a recoverable Poseidon trade interruption. Saves/settings use their own folder.
See [play instructions and scope](../docs/FIRST_LIGHT_HARBOR.md).

Final visible EN/RU checks pass **32 each**, editor **64**, embedded **101**.
Duration/balance and a complete natural playthrough remain pending. This is a Mac
workspace prototype; the Windows kit and Steam package do not include it.

## Community scenario research — 8 October 2026

Six popular Zeus Heaven adventures are downloaded into a separate private
research folder. Alexandria includes editor/map sources and an author invitation
to edit; an independent working copy is prepared as the first terrain candidate.
See the [shortlist and adaptation plan](../docs/CUSTOM_ADVENTURE_RESEARCH.md).
Archive integrity is verified; in-game import, a playable adaptation and commercial
redistribution permission remain pending. The live adventure catalog is unchanged.

## Private Windows test kit compiled — 8 October 2026

The Windows x64 native extension and SDL helpers now compile/link on Mac with a
private MinGW-w64/GCC toolchain. The transfer kit includes the matching official
Godot runtime and **Play.cmd / Run checks.cmd**, so the Dell needs no compiler or
Python. It preserves full-resolution Balanced/High graphics and uses scratch
copies for automated checks. Return the resulting **Dell-test-results.zip**.
See [Windows testing](../docs/WINDOWS_TESTING.md) and
[cross-build evidence](../docs/WINDOWS_CROSS_BUILD.md).

This is a private development kit. DLL architecture/import checks and Mac tests
are verified; actual Windows launch, driver/saves/performance and minimum hardware
remain unverified until the Dell run. The Mac portability rebuild is separately
signed/installed; the user's running game and original saves are retained.

## Modern desktop performance and Windows preparation — 8 October 2026

Game settings → **Graphics settings** now previews Balanced/High with explicit
Apply/Cancel. Both keep full 3D resolution, smooth edges and sun shadows; Balanced
matches the existing city. Windows uses Direct3D 12 with Vulkan fallback; Mac
keeps Metal. The user's old 1 GB card is not a release target.

An owned large-city test records frame pacing, RAM/graphics memory, native speed,
visible fire and repeated guarded loads without writing player saves/preferences.
Windows build/check helpers and provisional hardware targets are documented in
[performance/platform contracts](../docs/GODOT_RELEASE_PERFORMANCE.md) and
[Windows testing](../docs/WINDOWS_TESTING.md). Windows compilation/launch still
needs the Dell. The local Mac dylibs require macOS 26 and Homebrew dependencies;
a standalone build for the proposed earlier macOS floor remains pending.

## Recoverable saves and persistent facing — 8 October 2026

New saves check their contents before committing and retain two earlier recovery
copies. Older imported saves are preserved separately. Interrupted complete saves
can be recovered even when no primary file was finished. Loading checks a private
copy before replacing the current city; damaged files leave the active city intact,
and recovery requires an explicit choice. The original file is kept.

New saves retain explicit building facing, camera position/orbit/zoom and selected
speed. Existing `.ez` cities still load, and the native reference game opens the
new payload with matching gameplay state. Relaunch to load the rebuilt extension.
See [save contracts](../docs/GODOT_SAVE_RELIABILITY.md) and current validation.
Physical power-loss, Windows, cloud/removable storage and long-session upgrade
testing remain release acceptance work.

## Construction clarity and foundation contact, second pass — 7 October 2026

Compatible monuments now reveal upward at their proper proportions as native
construction advances. Timber scaffolding follows the current height and
disappears on completion. The inspector explains halted work, missing road
connections, materials still to deliver and the need for staffed artisans.
Existing foundation-only stages and ordinary instant building placement retain
their native behavior.

Small limestone supports close actual gaps under eligible building bases without
moving the buildings or covering roads/water. Empty new settlements offer the
guide after their briefing; Finish guide remembers the choice, and ? can reopen it.
Relaunch to load the scripts. See the
[construction samples](captures/city-sites-en-stages.png),
[ground-contact sample](captures/city-sites-en-support.png),
[contracts](../docs/GODOT_CITY_CLARITY.md) and current validation. These samples
are isolated presentation fixtures; native state and personal saves are retained.

## City help and first shared art finish — 7 October 2026

The header's **?** button opens **City attention**: filter warnings, read an
explanation and click to visit the affected building. Inspectors explain actual
worker vacancies, missing inputs, full output stores, road access and housing
requirements. Select **Settlement guide** for six short steps through roads,
housing, water, food, maintenance and sustainable growth. Both are also under
**Game → City views** and stay open while the city runs.

Everyday buildings and defences share a subtle stone/marble finish. Existing
work cycles interpolate more smoothly, human walkers get bounded slope clearance,
and unfinished monument inspectors show percentage progress. Full painted
materials, independently planted feet and new construction animations remain
future work. **Game → Sound** offers an optional original lyre/flute score with
wind/bird ambience; it is a development soundscape, disabled by default.

Relaunch to load the rebuilt extension and new scripts. Native gameplay and saves
are retained. Read the [contracts](../docs/GODOT_CITY_CLARITY.md) and current
[verification evidence](../docs/GODOT_VALIDATION.md).

## Building refresh performance, second pass — 7 October 2026

Routine stock/staff totals now refresh inspection records while leaving an
unchanged scene alone. Visible goods, worker activity, construction growth,
building placement and road/overlay changes still update immediately. Minimap
footprints, Agora paving, GPU batches and identical animal finishes are reused.

In a paired test on the full designated city, routine building-refresh CPU work
fell about 84%, from 13.35 to 2.10 ms. The comparison alternates the previous and
current paths within one run; frame pacing remains affected by active workloads,
and first-use loading/actual geometry changes can still hitch. Graphics, native
20 Hz gameplay and saves remain unchanged. Relaunch to load the new scripts.
See current validation and `tools/review_camera_performance.py --refresh-only`.

## Camera movement and first performance pass — 7 October 2026

Wheel zoom now eases between notches while keeping the terrain under the cursor
anchored. Rapid notches accumulate, and Home, Go to, modal input and the world-map
transition cancel pending motion. Pinch and direct camera controls retain their
existing behavior and limits.

Citizen placement reuses unchanged ground/road results, building refreshes reuse
unchanged transforms, and a folded minimap skips its hidden camera refresh.
Detailed physician models are prepared only while nearby detail is used. The
native routes, 20 Hz simulation, saves, model quality and graphics settings remain.
In the designated 1080p test city, presentation processing during running panning
fell from about 7.7 to 5.7 ms per frame. This is a CPU improvement, not a whole-game
FPS guarantee; occasional refresh/loading spikes remain. Relaunch to load the
scripts. See the current validation evidence and `tools/review_camera_performance.py`.

## Character panel and live supplies — 7 October 2026

Right-clicked characters now use a centered charcoal/bronze card with a compact
speech/voice section, bounded scrolling details and a separate Go to / Close
footer. Peddlers show their own Agora's live supply cards, including stock,
capacity and missing vendors. Transport carts show actual goods and cargo loads;
growers show collected goods. Existing portraits and native lines/voice remain.

The panel pauses the city and restores its previous pause state when closed.
Stock refreshes preserve the portrait, speech and card controls. Relaunch to load
the signed extension and interface. See
[the panel and inventory contract](../docs/GODOT_CHARACTER_INVENTORY.md) and the
[peddler preview](captures/character-peddler-en.png). Current verification and
scope are recorded in the validation document.

## Slim instant notifications — 7 October 2026

Instant city notices now show the message and a thin timeout bar, with the title
row and Close button removed. Click the message to pin/unpin it for reading;
right-click to dismiss. Hover still holds the timer, and long messages wrap and
scroll. Journal entries retain their titles and full text. Relaunch to load the
updated interface; no native rebuild or saved-city conversion is required.

## Monster anatomy — 7 October 2026

All sixteen monsters from the user's reference folder now have rebuilt anatomy:
real canine bodies/faces, a detailed lion face, crocodilian skull structure,
anatomical quadrupeds and full human bodies replace the rounded sculptures.
Species features, natural joints, cloven feet, fitted wings and distinct fur,
scale, bronze, cloth and wet-skin finishes preserve their reference identities.
Their existing walk, idle, two attacks and collapse animations remain connected.

Relaunch the game to load the models. Open the
[reference / previous / installed comparison gallery](../../art/monsters/anatomy-v3/comparison.html)
for every monster and its editable Blender scene. Hydra and native gameplay/saves
remain unchanged. These are development meshes with procedural finishes; full
painted textures and visual acceptance remain pending. See the
[art contract](../docs/GODOT_MONSTER_ART.md) and
[verification evidence](../docs/GODOT_VALIDATION.md).

## Common housing models — 6 October 2026

All seven common-house levels now increase in height, from a low starter cottage
to a taller townhouse. The first two levels have new timber/daub and mud-brick
walls, muted reed roofs, doors, shutters and household details. Neutral irregular
soil patches replace the distracting yellow rectangular lots; later courtyards
use grey limestone. Native housing levels, footprints and evolution are retained.

Relaunch to load the installed models and updated starter-house road facing.
See the [first two levels](captures/housing-starter-levels.png),
[complete progression](captures/housing-progression.png) and
[art/export contract](../docs/GODOT_HOUSING_ART.md). The focused art, native housing
and owned Metal review pass 110 checks. Full material baking and minimum-Mac
profiling remain pending; see the current validation evidence.

## Ruined buildings — 6 October 2026

Selecting rubble now shows the former building's name and its complete footprint.
The inspection panel offers Demolish with the full clearing cost; the demolition
tool highlights and clears the whole ruin with one click. Touching ruins remain
separate buildings. Burning rubble must finish burning before it can be cleared.
Relaunch to load the updated extension and interface. Native saves stay compatible;
see [verification and older-save limits](../docs/GODOT_VALIDATION.md).

## Building preview road clearance — 6 October 2026

Building previews now use the same road clearance as placed buildings, including
plots previewed by dragging. The model no longer jumps away from the widened
road edge after construction. Native footprints and costs are preserved.
Rounded inside road corners now also clear square building foundations, while
straight road widths and outer curves retain their existing appearance. The kerb
uses one continuous curve through the join, removing the stacked corner ends.
Relaunch the game to load the fix. See the [preview](captures/placement-clearance-preview.png)
and [corner close-up](captures/road-corners-houses-near-close.png).

## Avenues and boulevards — 6 October 2026

Two-tile avenues and three-tile boulevards now have continuous limestone paving,
contrasting promenade borders, marble statues, benches, flower planters and
olive/cypress trees along their outside edges. Entrances and intersections remain
open. The former grassy median was a native walking lane; its centered trees
made citizens appear to walk through vegetation.

Citizens now keep clear of the street furniture, merge lanes smoothly at bends
and turn with their displayed movement. Native routes, ordinary roads, costs and
undo remain unchanged. Building cards show distinct street miniatures and the
correct full width. Relaunch to update existing avenues and boulevards; no saved
city conversion is required. See the [street preview](captures/avenues-moving-citizens.png)
and [verification evidence](../docs/GODOT_VALIDATION.md).

Wall building choices now omit the Fill wall rectangle checkbox. Drag normally
to build a perimeter; hold Shift while dragging to fill its interior. Native
placement, costs and undo are retained. Relaunch to load this panel change.

## Illustrated notifications and on-demand Objectives — 6 October 2026

A compact upper-right rail now holds Journal and Objectives, with matching
illustrated icons, hover explanations and separate badges. Objectives opens only
when selected; its icon shows progress and highlights newly completed goals.
The full native goals and set-aside actions remain available. Open-play adventures
hide the Objectives icon.

Journal offers All reports, Warnings and Decisions filters. Routine reports stay
in history; urgent messages appear one at a time with later arrivals queued.
Grouped hazard icons use red accents, visits/arrivals use gold, and overflow
scrolls within a bounded rail. Click a hazard to visit its site; right click to
put its icon away. Hidden, clipped or focused alerts retain their attention time.

Required replies still open the centered letter and pause the city through the
native simulation. Escape folds the letter into an amber decision seal; click it
to return to the same unanswered request. Folding never resumes or answers the
request. The rail stays fixed when Resources opens, and opening Objectives leaves
the construction toolbar in place. Relaunch to load the updated HUD.

## Olympian marble walls, gates and towers — 6 October 2026

Walls now have a 2.0-tile walk, raised another 38% from the first marble pass's
1.45 tiles, with white
marble courses, broad battlements and a restrained Greek meander frieze. The
gatehouse is a white Ionic propylon with fluted columns, carved laurel panels,
three pediments and open bronze doors. Matching broader towers have a 3.05-tile
fighting platform. All sixteen wall connections and both gate orientations keep
their existing native footprints and rules.

Guards use the model's roof height and remain inside the platform/wall walk;
street lane offsets no longer push perched guards sideways. Native patrols,
combat and saves remain unchanged. Relaunch to load the models and scripts.
See [defence art and export contracts](../docs/GODOT_DEFENCE_ART.md) and the
[assembled preview](captures/defences-ensemble.png). User visual acceptance,
full material baking and minimum-Mac performance remain pending.

## Compact city overview and message fix — 6 October 2026

The city overview is now a small horizontal panel at the upper left, sized to
its readings. Its charcoal background uses 90% opacity while text and icons stay
opaque. Resources unfold beneath it; the map, clock and construction dock retain
their arrangement.

Fixed messages shrinking into a narrow column after appearing or being pinned.
They retain their full width, complete wording and scroll position. Click a
message title to keep it open; longer reports scroll, and text follows the
interface text-size preference. Later alerts still queue behind the visible one.
Native decision pause and choices are unchanged. Relaunch to load the update.

## Clock, Jobs and dock hotkeys — 6 October 2026

Play/Pause, speeds 1–4 and the date now sit beneath the minimap. Jobs moves after
Layers in the bottom toolbar, and the construction label is centered. The map
icon appears only while the map is hidden; the open map has its own fold button.
Native time settings, employment details and remembered map visibility remain.

Hover help on the main bottom row shows the current working shortcuts: **H**
housing, **B** roads, **G** roadblocks, **L** Layers, **J** Jobs, **X/Delete**
demolition and **Cmd/Ctrl+Z** Undo. They can be changed in Controls. Existing
custom bindings are kept; a conflicting new shortcut stays unassigned until
rebound. Building category hover labels remain unchanged. Relaunch the game to
load the updated HUD. This arrangement supersedes the earlier header clock and
open-map icon beside the circle.

## Rearranged dock and Layers — 6 October 2026

City views now sit inside Layers in the bottom toolbar, together with the full
overlay list. Inspect and the duplicate Build button are removed. Undo, housing,
roads, roadblocks and demolition occupy the left side; building categories still
open the complete available catalog. The illustrated map button sits beside
the minimap and remains reachable when it is folded. Default map visibility and
explicit preferences are retained. Layers scrolls with smaller windows/larger
text and closes through selection, Escape, right click or its Close button.
Relaunch the game to load the updated HUD scene.

## Loading from the main menu — 6 October 2026

Continue, Load game and Begin now show a full-screen charcoal/gold loading
surface before opening the city. It stays through native loading, models,
terrain, interface setup and the first complete rendered city frame. Repeated
clicks and Escape cannot change the pending load. The activity indicator follows
the Reduce interface motion preference; English and Russian text and independent
interface/text sizes use the existing shared Theme.

New games still adopt the already opened adventure and create the native retry
save. A loading failure offers a return to the main menu. Native loading remains
on the main thread, so the indicator can pause during synchronous work. Relaunch
the game to use the screen. See the latest validation evidence; the disposable
review is `python3 tools/review_loading.py --lang en` (or `ru`).

## All monster reference models — 6 October 2026

The sixteen remaining monsters now have individual concept sheets, editable
Blender sculptures and installed 3D models with walk, idle, both attacks and
collapse. They stand about 1.9–2.3 citizen bodies tall, with all sampled raised
poses below Zeus. Native monster behavior and the saved city remain unchanged;
their existing effects now originate at their animated mouths. Hydra is retained.

Browse the [reference catalog](../../art/monsters/REFERENCE_CATALOG.md) and
[concept/model gallery](../../art/monsters/monster-reference-gallery.html).
Hercules film/TV images inform verified designs; the catalog identifies original
mythology/game adaptations and image gaps. These are development references:
painted materials, visual acceptance, slope foot IK and minimum-Mac performance
remain pending. Read [monster art](../docs/GODOT_MONSTER_ART.md) and current
[validation evidence](../docs/GODOT_VALIDATION.md) before re-exporting.

## Correct building-card pictures — 6 October 2026

Common and Grand Agora now show their distinct empty vendor plots and street.
Composite buildings show their assembled native layouts, including full pyramids
and shrines, rather than one component. Each building design has its own cached
picture, with complete silhouettes fitted into the cards and hover context.
Road-based tools retain the illustrated road icon. Native availability, costs,
construction callbacks and saved cities are unchanged. Relaunch to load the fix.
Use `tools/review_toolbar.py --previews --lang en` (or `ru`) for the isolated review.

## Illustrated coin and population — 5 October 2026

The header now uses small static illustrations matching the bottom toolbar:
silver coins with an owl motif and two citizens in colored cloaks. Both occupy
the same 24×24 logical-pixel cell. The old 3D coin viewport/flip is replaced;
native values, monthly balance, mood and hover help remain unchanged.

## Matching compact HUD panels — 5 October 2026

The city panels now share the bottom toolbar's charcoal surface, bronze edge and
shallow corners. The centered top bar uses less padding and a narrower measured
width while retaining native readings, hover help, controls and enlarged-text
wrapping. Resources open within the same width. Objectives, inspectors, Army,
journal, notices and dialog frames use the matching shared Theme.

The map opens by default. The bottom-left City map shortcut is removed; use the
existing dock map button or the map's fold control. The first launch adopts the
new default; subsequent explicit visibility choices are remembered. Trays and
expanded dialogs still fold it temporarily. Relaunch to load the scene/Theme.

## Compact top bar — 5 October 2026

The seven date/speed/city/stat titles are removed at the user's request.
The actual readings and controls remain, centered vertically, with their
existing hover help, responsive layout and corrected mouse activation.
Play/Pause is followed immediately by speeds 1–4, then the date.

## Top/bottom button click correction — 5 October 2026

The illustrated buttons now return mouse focus after the completed click.
The earlier mouse-down focus release canceled normal clicks on both bars.
Keyboard navigation and native callbacks are retained. Chrome/toolbar reviews
now separate mouse-down and mouse-up by frames; `validate_toolbar_input.gd`
also checks ordinary untagged input and canceled clicks. Relaunch the game to
load the corrected shared button script.

## Clearer city overview and panels — 5 October 2026

The top bar labels housing, treasury, monthly balance and population, with a
separate date/speed group and named Resources button. Housing identifies free
places explicitly; treasury debt and monthly balance keep separate colors.
Numbered speed buttons retain the four native settings. Smaller windows or
larger text move the complete statistics group into a second row. Hover help,
keyboard ownership and Escape/right-click return keep city navigation predictable.

Army fits between the actual header and dock, keeps Close visible while scrolling,
and explains unavailable orders. Inspectors show native building size/staffing;
long stored-good names wrap. Inspector/journal scrolling follows keyboard focus,
and objective counts use English/Russian number grouping.

Review sequentially with disposable profiles/city copies/preferences:
`python3 tools/review_chrome.py --lang en`, then `--lang ru`. Add `--army-native`
to exercise native Army orders in unsaved scratch memory. The presentation-only
`validate_army_layout.gd` checks empty/long-name/abroad/aid layouts. See interface
and validation documents for evidence, captures and scope.

## Illustrated bottom toolbar — 5 October 2026

Building categories now use distinct original colored illustrations above a
separate row for inspection, roads, demolition, map, Build, Undo and Overlays.
The dark rectangular dock follows the user's Anno layout reference; gold marks
the active category/tool. Hover shows a category/tool name immediately and a
wrapped explanation after the tooltip delay. English and Russian descriptions
use the shared Theme and independent interface/text settings.

The native catalog and callbacks are retained. Keyboard focus/open popups hold
camera input; choosing a tool/view or closing a tray releases that hold. Build
and Overlays open on release so their opening click cannot select a popup item.
The category row scrolls at smaller/enlarged layouts, while the utility row and
model tray stay reachable. Original static SVGs add no live 3D render windows.

Review sequentially with disposable profiles/city copies/preferences:
`python3 tools/review_toolbar.py --lang en`, then `--lang ru`. See the interface
and validation documents for checked routes, captures and remaining scope.

## Centered required decisions — 7 October 2026

Awaiting your decision opens a centered correspondence card over a dimmed city,
with a compact framed sender portrait, dark reading panel, ivory text and a fixed choice
footer. Refuse sits left, Postpone follows and an available Dispatch/Send troops
or sole receiving city sits right with primary emphasis. Invasions retain
Surrender → Bribe → Defend. Multiple receiving cities remain equal choices.

Right-click on the card or its folded decision icon now selects the offered
Postpone action, just like its button, and lets a running city continue. A manual
pause remains paused. Decisions without Postpone only fold; invasion Bribe is
never selected by dismissal. Escape/the fold button retain the unanswered request
and its clock block; settings and canceled enlistment cannot answer it.
The panel matches the shared dark surfaces, borders, buttons and text, with a
translated right-click hint. Relaunch to load the interface changes.
City picking/camera input is blocked while the
card is expanded, and keyboard focus stays inside it without selecting an answer
on arrival. All wording, available choices and callbacks still come from C++.
Run sequential `python3 tools/review_decision_panel.py --lang en` / `--lang ru`
with disposable city copies/profiles; see the interface and validation documents.

## Episode completion and briefing panels — 5 October 2026

Campaign screens now have a framed chapter header, an original victory medallion,
a parchment story area and a separate column of objective cards. Episode numbers
sit apart from the titles. Native achieved objectives turn green with a check;
long stories and objective lists scroll independently. Difficulty and the main
action stay in a fixed footer, with keyboard-accessible difficulty arrows.

The same authored card serves victory, the next briefing, colony selection,
defeat/retry, campaign completion and the first briefing from New game. Native
wording, goals, narration and campaign commands retain their existing flow.
Run sequential `python3 tools/review_episode_panel.py --lang en` / `--lang ru`
with disposable profiles; `validate_campaign_ui.gd` checks the real campaign
sequence. See [interface contracts](../docs/GODOT_INTERFACE.md) and
[validation evidence](../docs/GODOT_VALIDATION.md).

## Main-menu redesign — 5 October 2026

The main menu uses a compact left-hand panel with an original Greek emblem,
clearer action icons and a separate latest-save card. Continue shows the saved
city's name and timestamp; long names keep a full tooltip. New game is the
prominent adventure action, with Load game below and a quieter editor link.
The footer names Settings and shows the current language alongside Sound and
Quit. The existing 3D gateway remains visible.

An empty leader profile hides the Continue card and focuses New game. The panel
fits its content and scrolls with keyboard focus when interface/text sizes grow.
Leader switching, native saves, adventure selection and settings retain their
existing flow. Use `python3 tools/review_main_menu.py --lang en` / `--lang ru`
sequentially; the review uses disposable leaders, settings and a save copy.
See [interface contracts](../docs/GODOT_INTERFACE.md) and
[validation evidence](../docs/GODOT_VALIDATION.md).

## Field-worker activity — 5 October 2026

Hunters now play spear attacks and display their native prey load on the return
trip. Sheep handlers shear with hand-anchored tools and carry fleece; goat
handlers milk and carry a jug. Growers prune/pick vines and olives, and native
orange tenders use their own tree-working model and clips. Corral workers guide
cattle with a crook; the building's existing processing cycle follows actual
native processing. Boar/deer attack and collapse poses are connected. Work,
carry/leading phase, pause and transitions follow native observations/time;
empty hunting/livestock returns display no invented goods. Native rules, coordinates and saves
stay intact. See [field-work contracts](../docs/GODOT_FIELD_WORK.md) and the validation evidence for
export sources, geometry budgets, review fixtures and remaining limits.
Verified: 235 field-work checks, 1,661 imported pose samples, all nine UV/pose
optimization proofs, geometry/LOD and six seeded replay cases; eight visible
views pass in each launch language. The saved city and player preferences stay
unchanged. `captures/field-work.gif` records the new work/return motions.

## Illustrated adventure selection — 4 October 2026

New game opens a campaign library with a card on the right: the selected
adventure's native artwork, title, main episode count and colony scenarios, description
and first episode's exact objectives. Objective-free adventures are marked
**Sandbox · Open play** and explain that there are no fixed victory objectives.
The gold title band and warm paper details use the shared Theme; the library and
card details scroll and fit independent interface/text sizes. English and Russian
labels come from the interface CSV.

Selection reads campaign templates through `adventure_preview`, without starting
a city, adopting a session, playing a briefing or saving. Previews are cached per
language/reference and fast selections discard stale work. Start, difficulty,
briefing Back, Begin and the editor entry retain their existing native flow.
Installed artwork is read from loose overrides or `interface.e`; no Anno artwork
is bundled. Existing asset provenance/release gates still apply.

Run `python3 tools/adventure_art_metadata.py --check`,
`validate_adventure_cards.gd` and sequential
`python3 tools/review_adventure_cards.py --lang en` / `--lang ru`.
See [interface contracts](../docs/GODOT_INTERFACE.md) and
[validation evidence](../docs/GODOT_VALIDATION.md).


## World-map water, terrain and controls — 4 October 2026

The regional map now has continuous water: the submerged rectangular relief sheet
is clipped at the coast, and the sea mesh has finer curvature. Nonmetallic ripples,
turquoise shallows, quieter foam, weathered limestone, varied woodland sizes and
softer clouds refine the finish. The map keeps its existing artistic elevation.

**Arrow keys or WASD** pan relative to the camera; **Q/E** orbit, **R/F** tilt
25–75°, and **Shift** pans faster. These share the city's rebindable camera keys
and speed settings. The on-screen previous/next buttons still select cities.
Dialogs, text entry, flight and focus loss suppress camera input. Compact framed
headings/controls and a narrower city panel leave more room for the map; portraits
stay circular. Owned-city stock comes from the native world response.

Sequential EN/RU map reviews pass **61 checks each**, including a 180-sample
rendered water comparison and 125%/150% layout checks. Flight reviews pass **37
each**, and native dealings retain 16 checks plus five integration checks. See
[atlas contracts](../docs/GODOT_WORLD_ATLAS.md) and
[validation evidence](../docs/GODOT_VALIDATION.md). Relaunch an existing game to
load these changes. User art acceptance and sustained minimum-Mac profiling remain
pending.

## Fishing spots and authored gathering — 4 October 2026

Animated fish schools and spiny urchin clusters identify native water deposits.
Fishing skiffs now have a seated, hand-driven cast-net cycle: gather, throw,
settle, haul and stow, with rowing tools put away during work. Urchin gatherers
use authored dive/reach/recover, bag-carry and deposit clips. A Godot-only timing
adapter shortens the submerged dip and holds the visible recovery; it does not
change native collection timing. Entry, exit and work-state transitions blend.
Small phase-matched surface glints and three diver bubbles replace the oversized
effects. Motion follows native gameplay time, pause and required decisions.

See [water-life contracts](../docs/GODOT_WATER_LIFE.md) for sources, budgets,
opaque-water limits and reproducible export/review steps. Run
`validate_water_life.gd`, `validate_gathering_motion.gd` and
`python3 tools/review_water_life.py --lang en --record` (or `ru`) for scoped
checks and designated-city captures. Wider campaign art review, user visual
acceptance and minimum-Mac profiling remain pending.

## Monster combat effects — 4 October 2026

Hydra now emits green venom breath and travelling shots, visible contact splashes,
and a dust/debris burst after native building destruction. All 17 monster kinds
share the projectile/impact pipeline; other species currently use a warm generic
finish. Effects obey native pause, speed and required decisions. Building fire
and smoke retain their existing renderer. The new three-headed Hydra now uses
pose-sampled mouth anchors; see the model handoff below.

See [monster effects contracts](../docs/GODOT_MONSTER_EFFECTS.md) and
[validation evidence](../docs/GODOT_VALIDATION.md). Review the real native Hydra
attack with disposable preferences: `python3 tools/review_monster_effects.py
--lang en --record` (also `--lang ru`; recording needs ffmpeg or Pillow).

## Hydra reference model — 4 October 2026

The new three-headed Hydra replaces the Godot model: heavy four-legged body,
curving necks, dark scales, fitted belly bands, crimson eyes and black spines.
It measures about 2.1 times a displayed citizen and 81% of Zeus body height.
Walking, breathing, bites, venom and collapse use the existing native action
and gameplay clock. Both UV sets, palette, reduced LODs and baked poses remain.

Read [monster art contracts](../docs/GODOT_MONSTER_ART.md) for the reproducible
Blender source, editable scene, measured budgets and validators. The previous
runtime model is preserved in the parent art workspace. User visual acceptance,
full material baking, slope foot IK and minimum-Mac profiling remain pending.

## Elder curator portrait reference — 4 October 2026

The Character panel now uses one detailed **68-year-old curator** candidate with
aged facial structure, fine swept-back hair, shorter fuller eyebrows and a short salt-and-pepper
beard. City walkers retain their existing assets. The panel gives this specimen
its own material, full mesh detail, 1.5× rendering scale and closer framing;
switching roles restores ordinary portrait quality settings.
See [the reusable portrait reference](../docs/GODOT_PORTRAIT_REFERENCE.md) for
source, rebuild commands, captures, budgets and limits. Visual acceptance remains
pending; this is one static benchmark, not a catalog rollout.

## Hillside appearance — 3 October 2026

Exposed slopes now use layered, weathered limestone with subtle surface relief
and a grass transition at the rim. The same finish covers steep countryside.
Native elevations, roads, foundations and picking remain unchanged. To capture
matched comparisons with temporary preferences:

```sh
python3 tools/review_hillsides.py
```

See [terrain contracts](../docs/GODOT_TERRAIN.md) and
[verification evidence](../docs/GODOT_VALIDATION.md). This pass changes shading;
terrain silhouette remodelling and minimum-Mac GPU profiling remain pending.


Double-click **`Launch Godot 3D.command`** in the workspace root. It opens
Godot with the existing C++ simulation embedded in the same process and shows
the **start menu**: *Continue* (the newest save), *New game* (the 26 adventures
of the original game and the engine's own, each with its story and objectives),
*Load game*, language and *Quit*. There is no hidden SDL window, renderer or
native game subprocess. New and loaded games start paused; construction and
simulation changes stay in memory until you save (Game menu, F5 quick save;
saves are native `.ez` files in Godot's per-user `saves` folder and open in the
SDL game too). The Game menu's *Main menu* returns to the start. The designated
test city is for automation: `python3 tools/run_godot_pilot.py --skip-start`
or any validation/capture/review flag below opens it directly, and the launcher
checks that the test save and both settings files stay unchanged when the
window closes.

The start menu now opens on the **Gates of Hades**: a monumental stone arch,
carved Hades guardians, a living ember portal, braziers, drifting souls and mist
above the Styx, with a cloudy night sky and subtle mouse camera parallax. Menu
controls sit on the left to keep the gateway visible. This is menu scenery only.
Review it without opening a city or touching player preferences:
`python3 tools/review_menu.py --lang en --size 1920x1080` (also `--lang ru`).
See `assets/menu/menu_sources.json` for retained art inputs and budgets; visual
acceptance, minimum-Mac profiling and production clearance remain pending.

Hades now has an older original angular face, slate-blue skin, amber eyes, a
silver-gray beard and red flame hair. His long midnight chiton, shoulder mantle,
curled train and bronze bident remain. Animated fire and embers surround the cape
hem, follow his movement and blend with his native disappearance/reverse arrival.
The menu guardians are stone derivatives of this same model. All fourteen gods
float instead of walking (3 October): a hover pose, a slow bob, a lean into their travel and a slow turn
(`scripts/god_float.gd`, `tools/godot_god_float.py`). This is a Godot-only
art pass; native atlases, sanctuary monuments and the physician benchmark stay
intact. Review: `python3 tools/run_godot_pilot.py --character-review after
--character-subjects walker_hades --lang en`. See `docs/GODOT_CHARACTER_ART.md`
for rebuilding and the outstanding visual acceptance/provenance gates.

The **World map (F2)** is now a living 3D regional globe with raised coastlines,
mountains, animated water, drifting clouds, decorative sailing ships and small
city landmarks. Arrow keys/WASD pan, Q/E orbit and R/F tilt; mouse drag orbits, wheel/pinch zooms and right drag pans. Overview
and Focus city frame the region or selected city. Names, relationships, trade,
requests and military actions still come from the native world. The city stays
held while the atlas is open; closing restores its rendering and prior running
state. Both Greece and the four Poseidon map regions are supported. Review with
`python3 tools/review_world_atlas.py --lang en` (also `ru` and `--native-ui`). See
`docs/GODOT_WORLD_ATLAS.md` for source contracts, evidence and remaining art gates.

Zooming outward past the city limit now **flies up through cloud wisps into the
world atlas**. Wheel and trackpad pinch share the same 1.55-second ascent; F2 and
Escape menu → World map use it too. Escape or Back to city descends in 1.20 seconds to
the exact city target, zoom, angle and tilt you left. Escape during ascent queues
one safe return. Controls fade in after arrival; city time and queued city
commands remain held throughout the flight/map. Home still fits the city, and
M keeps mute/unmute. The atlas is prepared during paused city loading and stops
rendering while hidden. Review: `python3 tools/review_world_atlas.py --flight
--lang en` (also `ru`).

| Control | Action |
| --- | --- |
| Q / E, held | Continuous 360° camera orbit |
| R / F, held | Raise / lower camera tilt, using the same movement as middle drag |
| WASD, Shift | Camera-relative pan, faster while Shift is held |
| Mouse wheel / trackpad pinch | Cursor-anchored city zoom, in to a closest view of about ten tiles (`MINIMUM_DISTANCE` in `orbit_camera.gd`); beyond the outward limit, fly into the world atlas |
| F2 | Fly to the world map / return to the city |
| Middle drag | Camera yaw and tilt |
| Right click | Cancel construction or close the current panel; on a walker, open its character window (paused, with its spoken line and voice); inspect a tile when idle. Selected army banners retain move orders |
| Home | Show the full city |
| T | Turn the placement preview; R is now reserved for camera tilt |
| Space | Pause / resume |
| Escape | Close the current city window/tool first; otherwise open or close the game menu |
| H / B / G | Select housing / road / roadblock construction |
| L / J | Open Layers / view Jobs |
| X / Delete | Select demolition |
| Ctrl / Cmd + Z | Undo the last construction and refund its cost |
| M | Mute / unmute all sound (Game, Sound… sets the volumes) |
| 1 – 9, Tab, 0 | City overlays: water, supplies, hygiene, fire and collapse risk, appeal, taxes, unrest, security, roads, problems; 0 or Esc returns to normal |

These are the defaults. Escape ▸ Controls… rebinds every key (a key another control has is swapped; Escape, Delete and the mouse are fixed) and sets the camera's pan, turn and zoom speed; Escape ▸ Game settings… sets autosave and voice language, with links to Display settings, Interface options and Controls. Escape ▸ Display settings… selects the window size, fullscreen, monitor, VSync and frame-rate limit. Choices are per user in `user://settings.cfg`.

English and Russian presentation are supported. The Escape menu’s language selector switches the
interface; the launch language selects the native event-message language.
Run `python3 tools/run_godot_pilot.py --lang ru` for Russian native messages.

## Display and screen sizes

**Escape → Display settings…**, or **start-menu gear → Display settings…**, offers
windowed/fullscreen mode, monitor selection, common window sizes that fit that
monitor, a **Fit to display** size, VSync and a frame cap (30/60/120/144 FPS or
Unlimited). Fullscreen uses the monitor's desktop resolution; it does not change
its video mode. The windowed size is retained when entering/leaving fullscreen.
The existing fullscreen shortcut (default **Alt+Enter**) follows the same policy.

**Apply** starts a 15-second preview. **Keep changes** saves; **Revert**, Escape
or timeout restores the previous window, frame cap and VSync. Cancel before
Apply makes no change. Confirmed choices return on launch through per-user
`user://settings.cfg`, preserving language, sound, UI/text sizes and other options.
Native simulation timing and map coordinates stay unchanged. Save and relaunch
an already-running game to load the new interface code.

Review with `python3 tools/review_display_settings.py --lang en` (or `ru`),
`--headless` for preference/type/translation checks. Read
[interface contracts](../docs/GODOT_INTERFACE.md) and
[validation evidence](../docs/GODOT_VALIDATION.md) for tested hardware and limits.

## Interface and surrounding landscape

The city HUD follows the user's Nova Roma reference: slim teal stock ribbon,
city name and treasury/population/jobs inside one top resource bar, welfare shortcuts,
square construction buttons and a small selected-tool card at bottom right.
All 23 native resource types, including zero stocks, appear alongside the food
total; balanced rows keep every item visible on smaller/enlarged interfaces.
Original 3D resource models provide static rendered icons without live HUD
viewports. See [resource art contracts](../docs/GODOT_RESOURCE_ART.md).
Resources start folded in a separate panel; the arrow after Jobs reveals them below
the compact overview bar. Stock and employment totals come from the native current city; the shortcuts open
existing overlays. The dock retains every native category, model cards,
live costs and wall fill. Exact price/obstruction badges follow the cursor.
Pause, speed and date sit at bottom left, with the compact journal control on the
right. The language/gear HUD panel is removed. Escape opens a centred, scrollable
game menu grouping city actions, settings, language and city views. Escape closes
the current window or cancels construction first; settings pages return to the
menu when closed. The menu holds the native clock and command queue, restoring
the previous pause/hold state on return. Inspectors and required decisions
remain bounded. See [interface contracts](../docs/GODOT_INTERFACE.md).
Review with `python3 tools/review_interface_context.py`; add `--checks --lang en`
(or `ru`) for the focused interface integration gates, with save/settings protection.

The minimap starts folded as a **City map** pill at the bottom left. The
pill or dock map icon opens its compact live chart; a small dash button in its
upper-right corner remembers the folded
preference. A small directional chevron and soft cyan halo locate the camera;
the compass elements and large footprint highlight are removed. **Home** keeps
the bounded city overview. The circular chart has no heading row, fills and clips to its circular frame and stays
fixed above the time controls when inspection opens. Inspection cards scroll at
bottom right without discarding drafts. It temporarily folds for construction or decision
reading. Routine reports enter the journal quietly. Urgent native news uses one
compact alert, queuing later arrivals; click to read, Close to dismiss or let the
countdown expire. Hover/reading/hidden/clipped alerts hold the countdown. Pending
decisions retain a persistent amber review chip and original choices; folding
never answers them. The right journal button opens a content-sized City journal with dates and full
wording. Identical labour/shortage/risk warnings group with an occurrence count;
reading and inspector drafts survive refresh. Escape closes the foremost
disclosure before cancelling construction or opening the game menu. Circular
clipping crops chart corners without changing native coordinates or picking.
Review the menu with `python3 tools/review_escape_menu.py --lang en` (or `ru`).
The focused Escape review passes 53 checks in each language.
Map/notification review:
`python3 tools/review_map_notifications.py --checks --lang en` (or `ru`),
`--native-map` for the eight retained map regressions, or neither for captures.
See the interface/validation documents for the scoped evidence and limits.

Building inspectors now have coloured native status summaries, staffing, road
access, maintenance, housing occupancy/needs and related service-view buttons.
Short explanations connect native status to vacant jobs, road access, industry
shutdown, missing inputs and housing vacancies. Cached model previews use warm
key/cool fill lighting and stop rendering when idle.
Overlays show matching colour legends and native assessment counts, with visible
water/supplies/health/risks/roads shortcuts. **Escape → Interface options…** or the
start-menu gear → Interface options previews independent interface/text sizes. Apply remembers them
per user; Cancel restores previous sizes. Reduce interface motion previews and
saves through the same policy. Enlarging the interface preserves map
picking and unfinished inspector edits. Review with
`python3 tools/review_status_ui.py --checks --lang en` (or `ru`): 115 scoped
checks each. Omit `--checks` for captures, or use `--menu` for the enlarged menu.
Further complex-panel and keyboard/gamepad accessibility coverage is pending.
The Nova HUD's focused notification gates pass 115 in each language, plus the
retained message/log checks. Shared menus, native map and display checks are
recorded separately in the validation document. Visual acceptance and matched
performance profiling remain pending; broad gameplay validation retains the
previously recorded aid-regard failure.

Land boundaries continue into cosmetic woodland, foothills and mountains; water
boundaries continue into ocean. Inland maps get a ground horizon. The playable
native footprint stays unchanged. The closest zoom is ten tiles (3 October; it had been 5, close enough to show faces and hands past the detail they carry);
Home still shows the city. See [surroundings contracts](../docs/GODOT_SURROUNDINGS.md).
Review with `python3 tools/review_surroundings.py --lang en` (or `ru`).

## Implemented simulation boundary

`EZeusSimulation` is a Godot GDExtension backed by
`presentation/esimulationservice`. It reads the original `.ez` save/campaign,
retains the existing board, economy, production, pathfinding and walker rules,
and uses the same `engine/esimulationstep` sequence as the SDL game. Godot
supplies elapsed time; the native service accumulates 50 ms ticks, clamps stalls
to 250 ms and retains native speed IDs 0–3, including the highest-speed five-step
loop. Camera movement never rotates simulation coordinates.

Snapshots arrive at up to 10 Hz through direct method calls. They carry session
IDs, terrain, footprints, positions, money, population, date, time and events.
After the initial full map, terrain records are sent only when they change; the
build-eligibility column is observed in full snapshots and not treated as a change
(use the `preview` query for placement). The building list is omitted when unchanged
and the wrapper re-supplies it with a `buildings_changed` flag. `diagnostics()` reports
per-phase snapshot timings (`profile_us`, `wrapper_us`) and the slowest native tick.
The wrapper currently converts a native JSON snapshot into a Godot Dictionary
inside the process; typed packed arrays are a future optimization. The old
loopback adapter remains available explicitly with `--legacy-bridge` as a
regression reference, and is not started by normal launch.

The service loads only `Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez`. It never
registers autosave or settings writes. It waits for native workers before
reading state and detaches callbacks before releasing the campaign. A second
native owner is rejected. Native requests with decisions pause the simulation;
ordinary notifications remain informational. The engine's own events (the monthly summary and the shortage and risk warnings) are
worded by the core, in its language, from the SDL view's language tables and the city's history (population, treasury, food and unrest over the month). The simple decision buttons call
the original callbacks, including eligible destination-city actions. Military
force selection still needs its own interface and
is explicitly held pending rather than discarded.

## Expanded map and assets

The entire saved map is presented: **25,992 native tiles**, a 228×227 bounding
rectangle, and **834 buildings** before construction. The map is the native
irregular shape; empty bounding-box cells are not fabricated land. This expands
the old 32×32 viewport without resizing or overwriting the saved simulation map.
Cosmetic scenery can appear beyond/through non-native cells, with no collision
or build eligibility; the playable footprint stays exact.
Terrain uses 32-tile sections with collision meshes. Repeated building and tree
geometry uses MultiMesh batches grouped spatially, preserving imported materials
and enabling culling. Walkers interpolate between snapshots.

There are **363 development GLB assets**, including native variants for orchards,
walls, towers, gatehouses, temples, statues, pyramids and commemoratives. In the designated city, all
792 rendered building objects and all 279 initial visible walkers have real models.
The other 42 building records are livestock reservations and sanctuary owners;
their animals/components render separately. The former grey boxes and moving gold
spheres are absent in the checked city. Other campaigns still need coverage.

The palace keeps both halves and its full 8×4 footprint. Sheep update their model
when fleece state changes. Role-specific people, handcarts, trailers, animals,
fishing skiff and merchant ships are connected. Authored walker gaits are sampled;
most idle poses are held, while physician idle breathes. Work, combat/death, cargo
states remain pending. Workers and machinery in 35 authored building types now
animate in shared GPU batches, gated by native staffing, shutdown and production
inputs. Pause and pending decisions freeze motion; native speed controls it.
See [building activity contracts](../docs/GODOT_BUILDING_ACTIVITY.md) for coverage,
regeneration and remaining visual states. The building activity gate passes 171
checks; a separate decoder verifies 864 authored part poses and geometry budgets.
Compatible materials
use vertex colours and grouped PBR finishes to reduce draw calls; metal uses sky
reflections. See [asset contracts and export workflow](../docs/GODOT_ASSET_COVERAGE.md).

Road, housing, hospital, fountain, warehouse, granary, olive press, winery
and sculpture studio have authoritative native placement queries, exact quoted costs,
per-cell green/red footprint feedback and imported 3D ghost models. T rotates the
model; new square-building facing is retained across snapshots for the session.
Facing is not yet serialized, and rectangular building rotation remains pending.

Ground now blends limestone soil, vegetation, sand and stone continuously across
tile/section boundaries. Sandy wet banks and a shared coast distance field soften
river corners and tint shallow-to-deep water; restrained normal waves replace the
water checkerboard. Continuous native elevation profiles, road ramps and limestone
cliff sides close the old height gaps. Picking, walker feet and placement previews
follow the generated surface; buildings keep flat native foundation heights.
Native terrain/roads, pathfinding, eligibility and simulation height remain
authoritative. Forests use native forest cells, with independent forked trees,
smooth olive/cypress crowns, real leaf blades, subtle wind and reduced mesh LODs.
Existing water roads now have 3D bridge decks/rails/supports and shore approaches;
pedestrians stand on them, boats retain water height. Native walker positions
convert once from corner-based coordinates to centered Godot tiles, correcting
the previous half-tile offset without changing routes or simulation state.
Distinct native mineral outcrops, continuous quarry soil and sparse olive/sage
forest-edge grass/shrubs are implemented. Spatial batches, instance caps and
distance fading bound small detail; native road/housing/forest edits refresh it.
Resource ground inspectors identify deposits in EN/RU. Further species/content,
bridge topology, occlusion/performance profiling and wider terrain coverage remain pending; see the
[terrain contracts and next slice](../docs/GODOT_TERRAIN.md).
Imported materials carry preview vertex colours and grouped PBR finishes; complete
procedural texture baking and visual state coverage remain pending.

Fish Pond, Topiary, Hedge Maze, Park, Shell Garden, Sundial, Dolphin and Orrery
now use the Godot garden foliage adapter: branching cypresses, broad umbrella
pines, folded leaf geometry, leafy clipped hedges/spirals and flowering stems.
The 164 native 1x1 parks use a full-height pine-and-bench module instead of a
shrunken 3x3 tholos. All 178 garden placements retain native footprints and rules.
Pool/fountain colours survive the PBR export. Garden foliage is static; more
species/park variants, wind, material baking and sustained performance work remain.
See [garden source and budgets](../docs/GODOT_ASSET_COVERAGE.md#garden-foliage).

The 31 human walker assets (and the archer that patrols walls and towers, a 32nd built by the same adapter) now retain anatomical faces/hands, painted skin,
fitted hair/beards and softer skin, cloth and leather finishes. Previously generic
occupations have distinct facial profiles, with fair/light olive complexions;
the philosopher wears a blue wrapped himation with a Greek key hem. Female and
child anatomy, role props and walking anchors remain. This first people pass
does not replace workers embedded in buildings or boat rowers. Full texture baking,
facial animation and work/death/cargo states remain pending. Read the
[character art contract](../docs/GODOT_CHARACTER_ART.md) before re-exporting people;
their shader requires both rest-coordinate and surface-type UV sets.

**Character visual review remains open:** the user rejected this first pass as
still doll-like. Technical checks do not establish realistic appearance. The next
art benchmark is now a textured, skeletally animated physician in the actual city;
see the character art contract before another rollout.

Walking refinement (1 October): existing human walkers smoothly blend between
standing and walking and ease around corners. Gait phase follows horizontal native
travel, so terrain-height corrections do not create steps. The physician benchmark
adds longer support, heel/toe roll, smoother swing, body weight transfer and opposing
arm/shoulder motion. Its crowd twin shares the same phase and transition weight.
The new foot cycle is specific to this benchmark; other roles retain their authored
cycles. [Character contracts and review limits](../docs/GODOT_CHARACTER_ART.md)
include the repeatable locomotion checks and city preview.

## Construction and inspection tools

The **Build ▾** menu has one submenu per category (housing and roads, agriculture,
industry, storage, markets, health and water, administration and security, culture, science,
gardens and monuments) and lists each building with its native cost. It shows the 46
buildings (the road included) the test city may build that have a converted model; the core's `buildable`
query supplies names, footprints, models, costs and availability, and
`scripts/build_catalog.gd` supplies the grouping. Every building shares imported
ghosts, native costs/availability, demolition and construction undo. Launch with
`--placeholders` to list any native type that still has no model (none at present: the last fifteen, the culture and science schools, mint, corral, dairy,
armory, chariot factory and the small garden pieces, were exported on 1 October). The quick row
keeps Inspect, Road, Housing and Demolish.
**Trade** lists one entry for each partner city that can still get a post: "Trading Post: <city>" for a land partner, "Pier: <city>" for a sea
partner (a pier on a shore, with its trade post behind it; the pointer snaps to a fitting shore tile within two tiles). A post's panel lists the goods
its partner sells and buys with prices and this year's limit, and sets which to trade and how much to keep in store. Game, Trade partners… shows
all partners and their goods. **Markets** holds the common and grand agora (laid over
six tiles of road with free ground beside them; the pointer tile only seeds the search) and the food, fleece and oil vendors, which
replace an empty space of an agora (any of its four tiles picks it; one vendor of each kind per agora).

The embedded backend answers `preview TOOL X Y FACING` and `inspect X Y` without
advancing or changing the city. Placement uses the same footprint, ownership,
district, availability, terrain, walker/banner and credit-limit rules as the
native build path. Commands recheck current state when executed; previews do not
reserve a site. Roads can use the native elevation/walker rules and show a stone
preview; other supported tools use the actual imported geometry and materials.

Inspect a building to see its native name/text, road access, maintenance,
employment, or house residents/capacity/level and unmet needs. The inspector
refreshes while selected. Storage inspectors show actual goods counts, overflow,
occupied bays and per-resource **Reject / Accept / Get / Empty** orders and stock
limits. Edit an order/limit and press **Apply**. A bay holds four native cargo loads,
or one sculpture. Reducing a limit does not delete existing goods; carts perform
the resulting orders through the existing simulation. Refresh preserves unfinished
edits. Camera controls pause while a numeric field owns keyboard focus.

Production inspectors show input/output buffers, the native input recipe,
staffing and operational/waiting/shutdown status. **Pause / Resume industry** uses
the native workforce controls: it affects every producer of that resource in
the selected building's city, including shared growers. It does not introduce
individual-building shutdown rules. Existing goods and pending decisions remain
intact. Native descriptions are available under **Building details**.

`storage X Y TOKEN RESOURCE ORDER LIMIT` and `industry X Y TOKEN RESOURCE SHUTDOWN`
recheck ownership, resource support, pending decisions and the selected object's
weak-reference token. Selection changes, demolition, replacement, undo and reload
reject old tokens. Duplicate industry requests are idempotent. Failed/full-queue
requests preserve edits. These tokens are session handles, not durable entity IDs.
Native text follows the launch language; the Escape menu’s language selector changes UI/resource labels.
Trade settings, vendor controls and other specialized interactions remain pending.

Demolition uses `eBuildingsToErase`, including whole-object resolution for child
tiles, housing eviction and native costs. Forest clearing changes native terrain
and forest state. Burning/foreign buildings are rejected. Landmarks and stocked
markets retain confirmation; the dialog pauses play and restores the previous
pause state when closed. A native target token rejects stale confirmations.
Demolition cannot be undone. The Undo button or Ctrl/Cmd+Z removes the last
construction and refunds its actual cost once, using the native 15-game-day
window with a five-second minimum. Failed placements preserve that undo action;
demolition invalidates it. Existing saved buildings are not undo candidates.

All edits remain in memory and disappear on reload. Advanced tools require the
embedded backend; `--legacy-bridge` retains the original simulation/camera
regression route rather than exposing the new query interface.

## Build and verification

Local runtime: Godot **4.6.3**. The extension targets API **4.6** using
`godot-cpp` **10.0.0-stable**, revision
`507ed9d840c01a3c5b2a39af8bb4000bfac30bf5` in `../tools/godot-cpp`.
The private SDL2 source is `release-2.32.10` in `../tools/sdl2-headless`.
The local macOS SDK is built with SDL video/audio drivers disabled to avoid
loading Homebrew's SDL2-compat/SDL3 alongside Godot's own SDL3. Image/font/audio
helper-library copies are redirected and signed locally; Homebrew is untouched.
Additional codec/font dependencies still come from Homebrew. This is a
**development installation**, not a distributable standalone application.

From `eZeus/`:

When another development job is using the default extension build folder, set
`EZEUS_GODOT_BUILD_DIRECTORY` to a separate output directory. The same helper
still signs and atomically installs the completed staged extension; never share
one Ninja output directory between concurrent jobs.

```sh
./tools/build_godot_extension.sh
python3 tools/run_godot_pilot.py --validate --lang en
python3 tools/run_godot_pilot.py --validate --lang ru
python3 tools/run_godot_pilot.py --terrain-review after
python3 tools/run_godot_pilot.py --terrain-review elevation-after
python3 tools/run_godot_pilot.py --terrain-review detail-after
python3 tools/run_godot_pilot.py --garden-review after
python3 tools/run_godot_pilot.py --character-review after
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/character-contract-engine.log" --path godot --script res://scripts/validate_characters.gd
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
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --log-file "$PWD/godot/captures/buildings-engine.log" --path godot --script res://scripts/validate_buildings.gd
python3 tools/save_roundtrip.py
```

The launcher places runtime logs in `godot/captures/` using an absolute path;
relative Godot log paths resolve under `user://`. Headless commands above keep
their logs in the writable project as well.

Model GLBs cost video memory mainly through dense morph targets. After exporting or
re-exporting walkers, run `python3 tools/optimize_glb_memory.py --backup-dir DIR`, then
`godot --headless --path godot --import`, then `tools/verify_glb_optimization.py DIR` (it
merges identical poses, keeps UVs, and is safe to repeat). Animated walkers and animals
use baked pose textures: after exporting them run `python3 tools/bake_walker_vat.py`, then
`godot --headless --path godot --import`, then check with `res://scripts/validate_poses.gd`.
Sources are never modified, a stale derivative falls back to blend shapes, and
`EZEUS_NO_BAKED_POSES=1` forces the old path. The skeletal physician and its crowd twin
(`physician_crowd`) are rebuilt by `blender -b --factory-startup -P tools/build_citizen_benchmark.py`
(set `CITIZEN_OUT=/scratch/dir` for experiments), then `godot --import`,
`python3 tools/configure_citizen_textures.py godot/assets/characters/physician_v2`, `godot --import`,
`python3 tools/optimize_glb_memory.py --only physician_crowd`,
`python3 tools/bake_walker_vat.py --only physician_crowd --force`, `godot --import` and
`res://scripts/validate_citizen.gd`; see `docs/GODOT_CHARACTER_ART.md`. City load reads model files on
worker threads; set `EZEUS_DECODE_TEXTURES=1` only to compare against the old full PNG decode.

Interface: text is `tr()` keyed by English source from `data/ui_strings.csv` (godot's CSV import makes the `.translation` files named in
`project.godot`); the HUD is `ui/hud.tscn` + `ui/hud.gd`, styled by `ui/lapis_gold.tres` (`scripts/build_ui_theme.gd`); F3 toggles the developer
overlay. Drag the road tool to lay a road, or the wall tool to wall the outline of a rectangle (Shift fills it; T turns a gatehouse), or the housing, elite housing and park tools to fill an area; F2 (or Game, World map…) opens the world map: the cities on the map picture, their regard and goods, asking, giving and fulfilling, and the military dealings (Raid, Conquer or Reinforce, Aid and strikes, with an enlist-forces dialog and the armies drawn on their roads); a city's request for troops has a working "send troops" button; F4 (or Game, Army…) opens the army: the soldiers' companies with their size and state, Call all out / Send all home, per-company Call out / Send home / Go to / Place banner, flags on the map (a left click on one chooses its company, the right button moves the chosen banner); during an invasion a red notice counts the invaders and has a button that goes to them, and the player orders the defence with the army panel (the soldiers, heroes and gods fight and fall with their own clips); while a monster is at large a red button with the count stands under the journal and opens a card with its message, the hero who can slay it and Go to the monster / Build the hero's hall / Show the hero's hall (a hall the engine allows mid-game appears in the Build menu at once); F5/F9 quick save and load, the Game menu lists saves (kept in the per-user
`user://saves` directory, never in the repository); the minimap, messages and autosave are described in the migration document. Seeded replays: `EZEUS_SEED`, `tools/replay_parity.py` and `validate_replay.gd` compare the SDL executable and the embedded core.

The build helper creates only the extension target and signs its private
libraries. If rebuilding the SDL executable, follow the repository's mandatory
copy/codesign instructions separately. Model re-exports use background Blender:
`tools/export_godot_pilot.py --asset NAME`; this does not alter the live Blender
scene. Source paths, bounds, sizes and conversion limitations are recorded in
paired model manifests. GLBs, binaries, editor caches and captures are ignored
by Git. Dependency checkout LICENSE files are retained.

## Remaining release work

This is the next working migration stage, not complete game or production parity.
Remaining specialized inspectors/controls, settings, full asset coverage, material/animation
baking and minimum-hardware stress testing remain. Exact seeded replay equality
across disasters and all AI/event paths is not established; the inherited RNG
and cosmetic consumers must be audited before promising deterministic replay.
Preserve the engine's GPLv3 author/license notices. The development installation
still reads original content, and export manifests remain `needs_evidence`.
See `../docs/GODOT_MIGRATION.md` and `../docs/PRODUCTION_ROADMAP.md`.

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

## Journal follows its right-side button — 3 October 2026

The journal/messages rail is now right-aligned, below the compact top bar at the
same level as the welfare shortcuts. Its disclosure opens eight logical pixels
below the icon and shares the right edge. Height remains content-bounded above
construction/time controls, with scrolling, retained reading Controls, full
history and unread semantics unchanged. Resource disclosure/scaling move both
icon and journal together. The right-click back behavior also closes the journal.

## Character window — 3 October 2026

A right click on a walker (the ringed person, or any god, hero, monster, animal, cart or boat near the pointer, never
through a HUD panel) opens `ui/character_panel.gd`, the SDL game's character window: the walker's own 3D model on a lit
marble plinth (it sways and can be dragged round; hovering Olympians get a soft glow), its name and occupation, the line it
speaks typed out in time with its recorded voice, Listen/Stop with a progress bar, a cart's errand, the other people on its
tile and Go to. The city pauses while it is open and resumes only if it was running; Escape, a right click or a click
outside closes it and stops the voice. The core's `character_info <walker id>` words it through
`engine/echaracterinfotext.{h,cpp}`, now shared with the SDL window (which line is spoken uses cosmetic randomness, so
looking at a walker never moves the simulation generator); a trailer speaks for its driver. Review with
`tools/review_character_panel.py --lang en` (or `ru`).

## Character window portraits — 4 October 2026

Roles with a portrait show a pre-rendered still (`assets/portraits/<asset>.png`, about 0.1 MB imported) instead of the live 3D
figure; others keep the live crowd model. Sources are built outside the project (`build-portraits/`, git-ignored) by
`tools/godot_portrait_export.py` and rendered by `tools/render_portraits.py`, then `godot --import`. 26 roles (curator, storehouseman,
hoplite, philosopher, miners ...) have painted images (from `art/ai_portraits`); listing a role in `portrait_models`
(`ui/character_panel.gd`) shows its 3D model again. Contract: `docs/GODOT_CHARACTER_ART.md` and `docs/GODOT_PORTRAIT_REFERENCE.md`.
