# City interface — 3 October 2026

## Living world-map presentation — 2 October 2026

The world screen now uses the independent 3D regional atlas described in
`GODOT_WORLD_ATLAS.md`. Keep the existing native city/army/quest/dealings handlers,
normalized city UVs, projected label selection, synchronous city holding and
visibility/camera restoration. New typography is in the shared Theme and text in
the CSV. Hidden atlas rendering is disabled. Do not run the old flat-world scene
builder over the authored scene. Current focused EN/RU and native economic/UI
checks pass; broader campaign, art and accessibility acceptance remain separate.

Outward wheel/pinch at the city limit, F2 and the world action share the live
ascent/cloud transition; Back/Escape descends to the exact previous city view.
The atlas/input shield holds all city controls during travel, and queued city
actions wait until return. Native world dialogs and pending decision callbacks
remain authoritative. Home still fits the city; M remains mute. See the world
atlas contract and the 3 October flight validation entry.


The Nova Roma screenshot supplied by the user now guides the city shell: a slim
teal unified resource/overview ribbon with native city name, squared framed dock buttons,
left-side journal control, and time/map controls at bottom left. Original vector
glyphs and shared Theme styles supply the art. The previous Aegean delivery and
journal behaviour is retained; its navy/bronze medallion layout is superseded.
Body text remains Cyrillic-capable and headings retain the existing OFL Alegreya.

## Escape game menu — 3 October 2026

`ui/escape_menu.gd` replaces the city’s language/gear popup with a centred themed
card over the city. It groups city actions, settings and city views; the language
selector lives inside it. The start-menu gear remains available outside gameplay.
The card scrolls with keyboard focus at small viewports/enlarged text sizes.

The controller handles Escape before text-field input: close the journal,
expanded decision, construction tray, active drag/banner placement, army,
inspector or objectives first, then cancel the selected construction tool or
active overlay. Existing modal windows and the world/campaign flows retain their
own Escape handlers. An idle city opens the menu; another Escape or Return to city
closes it. Folding a required choice never answers its callback.

Opening synchronously pauses the native city and holds its pending command queue.
Closing restores the prior pause/queue-hold state, including an already paused city.
Settings, trade, mythology and save/load/leave confirmations suspend the menu and
return to it on close; nested settings return one page at a time. World/army and
quick-save/load actions close the menu before following their existing handlers.
The old HUD language/game-action signals and popup nodes are removed.

Use `tools/review_escape_menu.py --lang en` (or `ru`) for real input, native clock/
queue preservation, modal return paths, live language changes, size/focus bounds
and actual game captures. The wrapper protects the designated city and player
preferences. Display previews retain their explicit Apply/Keep policy.

## Player flow

- The top ribbon shows all 23 individual native resource stocks plus the food
  total, including zeros. Original 3D model renders replace the tiny vector goods
  icons; exact values and translated names remain in tooltips. The resource grid
  wraps into balanced rows instead of scrolling or hiding types.
  Food sums the native food mask. The city title preserves the full native
  city name in its tooltip. Stock controls open existing supplies/distribution
  overlays; welfare buttons open supplies, water, hygiene and risk views. Treasury,
  population and Jobs share the top bar’s overview row; Jobs exposes employed/employable,
  vacancies and unemployment and opens Industry. No synthetic welfare score is added.
  The snapshot reads every cached native resource total and employment data, with no new
  tile scan, polling path or simulation mutation. The language/gear HUD panel is removed.
  Pause, four native speeds and date sit at bottom left. The speed popup opens
  above the control, clearing its opening click and retaining keyboard selection.
- The dock keeps Inspect, Road, Housing, Demolish and Undo, and exposes each
  available construction category directly. The four-square button retains the
  complete categorized Build menu. The layers button retains all native overlays.
- A category opens a centred floating building tray with small model tiles,
  translated names and native prices. Its left context panel shows the selected
  building's larger model preview, full name, price, footprint and tool instructions.
  Hovering a tile temporarily previews it without changing the construction tool.
  Search finds buildings across all available
  categories. Long names have full tooltips; the tray scrolls. Closing it leaves
  the selected construction tool active; Inspect or Escape cancels that tool.
  Typing in search suppresses camera keys. Escape from search closes the tray.
- Turning buttons use the same session facing as **T**. Road, wall, pier and
  native-directed gatehouse contexts omit arbitrary facing controls. A wall-fill
  checkbox selects the native filled-rectangle mode; holding Shift still fills.
  Roads continue to use the native orthogonal route, not curved geometry.
- Closing the tray keeps a small selected-building card at bottom right with its
  translated name, native catalogue cost, footprint and placement instructions.
  Inspectors, journal and expanded decisions take priority; its close button uses
  the existing Inspect action. No extra thumbnail viewport is created.
- A blue or coral cursor badge displays the exact native placement price/status,
  drag counts or obstruction reason. It ignores mouse input, hides over Controls
  and clears when leaving native terrain or returning to inspection. Native
  per-cell footprints and imported ghosts remain the placement authority.
- The live minimap starts folded into a **City map** pill at the bottom left.
  The pill or dock map icon reveals it; a small dash button over its upper-right
  corner folds it again. The chart has no title/header row. Explicit choices
  save only `interface/minimap_visible` in the existing per-user preferences.
  Its chart has a small pale camera heading chevron with a soft cyan halo. Both
  compass elements and the large viewport highlight are removed at the user's
  request. **Home** retains the bounded overview. Clicking/dragging still uses exact
  native coordinates and ground height; releasing outside ends a drag.
  The circular chart stays anchored above the time controls when ground or building
  inspection opens. The native chart now covers the circular viewport and its
  corners are clipped, replacing the previous inscribed-square view at the user’s
  request. Native coordinate transforms and inverse picking are unchanged;
  masked corners pass pointer input through. Inspectors hug the bottom right, scroll and preserve
  drafts and target tokens. Simple ground cards hug their shorter contents.
  Construction, history and expanded decisions temporarily fold the chart;
  closing them restores the preference. Opening the map while browsing closes
  the tray; opening it during decision reading only folds that disclosure.
  Objectives sit at bottom right, initially folded; at narrow/enlarged layouts they
  wrap below the header. Build trays and expanded decisions fold the goal disclosure.
  Language and settings are reached through the Escape menu.
- Routine native reports and informational updates enter the journal and unread
  count quietly. Fire, collapse, invasions and monsters use **one compact alert**;
  later alerts queue without displacing the item being read. Events lacking
  specific native kind metadata retain a visible fallback. A bounded disclosure
  shows full wording; hover, reading, hiding and clipping pause its countdown.
  Close/expiration retain the existing informational acknowledgement path.
  No event with required choices is routed through that path.
- **Inbox** opens a content-sized **City journal**, capped at 55% of available
  height before scrolling. Repeated labour/shortage/risk warnings group only by
  native kind and exact title/body, with a count and every occurrence's date/text.
  Opening it clears the underlying unread event count. Existing row controls,
  expansion and scroll survive refresh; new arrivals do not reorder neighbours
  while reading. Historical entries never execute stale choices. The journal
  hides the inspector without destroying drafts, and closes before cancelling a
  tool on Escape. Its bottom stays above an open construction tray.
- Inspection has a heading, city label, real workforce bar and close button.
  A coloured status summary shows native staffing, road access, maintenance,
  occupancy and housing needs. Native status now includes a short explanation
  for vacant jobs, disconnected roads, paused industry, missing inputs and housing
  vacancies. Production uses the core's operational status;
  generic buildings are not labelled operational just because they exist.
  Related-view buttons open the existing native services, roads and risk overlays.
  Simple buildings use a short panel; storage and trade retain a scrollable panel
  with the existing explicit Apply controls, dirty drafts and stale-token checks.
  Opening the build tray moves the inspector's lower boundary above it. The tray
  grows upward for translated descriptions and never covers the bottom dock.
- Native decisions remain as persistent amber **review chips** until answered
  through their original callbacks. The header identifies that a decision is
  required and counts queued decisions. Click to show bounded full text and
  the original native choices; click again to fold. Reading gets priority over
  transient news. A folded decision never expires, answers itself or releases
  the native simulation's decision block. The next pending ID starts folded;
  refreshing the same ID preserves reading state. Native event-text substitution
  gaps remain separate work.
- Active overlays have a named panel, matching colour keys and counts from the
  native observations. Water/supplies/health/risks/roads shortcuts stay visible
  while the legend and readings scroll; Close restores normal visibility.
  Counts describe assessed homes/buildings and the native displayed coverage
  levels, not invented population coverage or service radii. Selecting a view
  folds expanded objectives to make room.
- **Escape → Interface options…**, or the start-menu gear → Interface options, previews interface sizes
  100/110/125% and text sizes 100/115/130%. Apply remembers the choices in
  `user://settings.cfg`; Cancel restores the previous sizes without writing.
  **Reduce interface motion** disables the new alert entrance fade. Motion
  preview follows the same explicit Apply/Cancel policy and persists only in the
  interface section. Defaults can be previewed in the same dialog. Camera and city shortcuts are
  suppressed while it is open; native simulation timing remains unchanged.

## Display settings — 3 October 2026

Escape → Display settings and start-menu gear → Display settings open the same
`ui/display_dialog.gd`. The gear now opens `game_settings_dialog.gd` with display,
interface and controls links alongside autosave/voice choices; the city's direct
Interface options and Controls actions remain. The shared Theme and CSV apply.

`scripts/display_settings.gd` owns windowed/fullscreen mode, monitor, remembered
window dimensions, VSync and the optional frame cap (0/30/60/120/144). Common sizes
are filtered to the selected monitor's usable rectangle, reserving title-bar space;
the current custom size and Fit to display are included. Unsupported types/options
fall back to defaults (1280×800 windowed, current display, VSync, no extra FPS cap).
An unavailable saved screen falls back to the current monitor. Fullscreen uses
the desktop resolution and keeps the last windowed size; changing the monitor
never changes its hardware video mode. On macOS fullscreen needs main-window
focus before the transition; do not move `current_screen` to itself. Returning
windowed explicitly clears the fullscreen borderless flag. Preserve the earlier
PlaySettings fullscreen shortcut and migrate its `game/fullscreen` preference.

Editing choices does nothing to the runtime. Apply changes the presentation and
starts a 15-second **wall-clock** deadline independent of simulation pause/speed.
Keep changes persists the sanitized display section and matching legacy fullscreen
flag, preserving other ConfigFile sections. Revert, Escape and timeout restore
mode, client size, position, border, exact VSync mode and FPS cap without writing.
Escape also closes the display dialog, including during a preview; the Revert
button and timeout restore the preview while leaving the page open.
Cancel before Apply closes unchanged. Removing a pending dialog restores after
it exits the tree so resize work cannot target the removed embedded Window.
Failed saving shows an error and leaves the preview uncommitted. UiAccess shields
city camera/shortcuts for the dialog's lifetime. Native tick timing, world/camera
coordinates, pending commands and inspector state remain independent.

Normal startup reapplies confirmed display settings through UiAccess/PlaySettings.
Automation defaults to isolation; the display reviewer redirects its entire
preference lifecycle to a disposable file and protects the designated save and
real preferences. See [Godot DisplayServer](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html)
for the desktop fullscreen/window API. High-DPI, heterogeneous displays, other
OSs and minimum-Mac performance still need broader validation. Render scaling,
quality presets and exclusive hardware resolution switching are future work.

## Files and contracts

`godot/ui/hud.tscn` is the editable layout; do not regenerate it with the old
`build_hud_scene.gd`. `hud.gd` presents data and emits actions; `main.gd` owns
selection and commands. Styling comes from the shared `lapis_gold.tres`, regenerated
by `scripts/build_ui_theme.gd`. The resource name is retained for existing scenes.
New interface text belongs in `data/ui_strings.csv`; native building labels stay
in `data/building_names.csv`. Icon sources and provenance are in `ui/icons/`.

`ui/inspection_summary.gd` is read-only; the existing inspector still owns dirty
drafts, explicit Apply actions and stale-action tokens. `ui/overlay_summary.gd`
consumes `overlay_view.observations_changed`, using the existing polling cadence
and query results. Do not add a second overlay poll or infer missing statistics.
The water zero-coverage colour and appeal legend match the rendered colours.

`UiAccess` (`scripts/ui_accessibility.gd`) holds the one cached Theme and an
immutable baseline. Text changes always rescale the baseline's font sizes,
including heading/status variations; they never accumulate scaling or save a
modified `.tres`. Interface scale uses root Window content scaling with the
existing `canvas_items`/`expand` mode. HUD panel widths, dock/status heights and
model-card text space follow their minimum sizes; inspection/overlay scrolling
clears the construction tray. Resize must preserve picking, drafts and tokens.
The options dialog writes only interface size, text size and reduced-motion keys in the shared ConfigFile,
preserving language/sound/other settings. Unsupported types/choices fall back
to 100%. Scripted reviews/validation start at defaults and redirect test writes
through `ezeus_settings_path` to disposable files. Normal launches load the user's
choices. See [Godot Window scaling](https://docs.godotengine.org/en/4.6/classes/class_window.html#class-window-property-content-scale-factor).

`ui/notification_chip.gd` is a reusable, presentation-only disclosure with no
simulation access. `hud.gd` retains IDs and forwards only explicit dismissal;
`main.gd` keeps the original decision buttons/callbacks, informational classifier,
event deduplication and complete log wording. `scripts/notification_policy.gd`
routes read-only native `kind` metadata; choices take precedence over kind. The
embedded service adds kind to event observations without changing event rules,
timing or saves. Journal acknowledgement happens only after recording, retries
when the command queue is full and leaves queue capacity for player actions.
Chip lifetimes use UI elapsed time,
independent of simulation time. Decision chips have no news timer or dismiss
control. Text/layout colours come from shared Theme variations and CSV strings.
Minimap terrain/building texture updates remain incremental and authoritative;
the screen-sized camera chevron does not alter tile transforms or texture colours.
Its halo is 26 logical pixels across regardless of camera zoom. The ground
footprint remains available as an observation, without a visible polygon.
`MapSurface` contains the full chart and a compact overlay button; removing its
heading must never change map transforms or reduce the native coordinate area.
The centred dock uses measured content width, retaining every category/tool;
unchanged catalog refreshes reuse the tray so hover previews and scroll survive.
The bottom dock owns its own margin; moving the status groups does not leave
the old empty footer gap. Inspector, tray, history and notice bounds follow
the actual top controls and bottom dock at each text/interface size.
Scripted reviews use folded defaults and redirect preference writes to scratch
ConfigFiles; temporary panel hiding never persists a different preference.

`ui/building_thumbnails.gd` uses one isolated 160×100 transparent SubViewport,
the already-loaded model factory and two renders per requested asset. It caches
only small finished ImageTextures and frees the temporary model instances. The
viewport stops rendering when idle. It never reads or advances the simulation.
Warm key light and cool fill refine the previews; the final render explicitly
returns the viewport to `UPDATE_DISABLED`.
Road terrain, absent development meshes and headless runs keep their vector icon.
Cache lifetime is one HUD/session; a scene reload rebuilds it from current assets.

The viewport aspect mode is `expand`, using extra window width for the city instead
of pillarboxing. Native placement, coordinates, dates, speeds and save formats are
unchanged. There is no new synthetic income, happiness or demand statistic.

## Review and verification

`validate_main.gd::run_hud_checks` drives real viewport clicks, searches in the
current language, verifies camera suppression while typing, close and minimap
actions, native-state preservation and panel bounds at 1440×900, 1280×720 and
1920×1080 in EN/RU. Existing construction, storage, trade, messages, overlays,
campaign, saving and terrain checks continue to run. Camera input assertions use
fixed elapsed intervals through the full camera `_process` path so a Metal frame
stall cannot make the two R/F test intervals unequal; runtime controls are unchanged.

`scripts/validate_context_ui.gd` adds real rotation/hover/fill interactions, native
successful/blocked quotes, viewport-edge badge bounds and context layouts in EN/RU
at the same three resolutions. It checks unchanged treasury, clock, buildings and
walkers. This suite runs with the normal visible validator and independently through
`python3 tools/review_interface_context.py --checks --lang en` (or `ru`).
`python3 tools/review_interface_context.py` captures selected-tool, successful and
blocked placement, Russian industry and wall contexts in `captures/interface-context-*.png`.
The helper verifies the designated save and both settings hashes and times out
its own preview. Fixed review pointer placement is presentation-only; all quotes
and ghosts come from the actual native city. It leaves the user's other apps alone.

`validate_status_ui.gd` runs with the normal visible validator. The focused
`python3 tools/review_status_ui.py --checks --lang en` (or `ru`) combines its
48 checks with the existing 67 HUD/context checks. It verifies native status/counts,
real overlay buttons, matching water colours, size preview/Apply/Cancel/reload,
malformed preferences, camera suppression, picking and an unfinished storage edit.
Each run exercises both languages, three requested window sizes and independently
enlarged UI/text combinations. `--menu` checks the options entry and enlarged menu
without opening a city; omit these flags for city captures. The wrapper protects
the designated save, workspace settings and actual per-user settings, rejects
script errors/missing completion markers, and bounds its own preview lifetime.

`scripts/review_hud.gd` renders the designated city, every available catalog model,
the construction tray and inspectors, a synthetic long-message layout fixture,
and the start menu in both languages. It does not open another save or persist
settings. Captures are `godot/captures/hud-*.png`. Read `GODOT_VALIDATION.md` for
the completed runs and remaining limits; this is a HUD redesign, not a full UI
accessibility, gamepad-navigation or minimum-hardware performance certification.
Complex military/campaign inspector layouts at every size, broader campaign
coverage, keyboard/gamepad navigation and sustained performance remain pending.

`tools/review_map_notifications.py --checks --lang en` (or `ru`) exercises real
pill/close/overview/disclosure/choice clicks, countdown holds, overflow while
reading, native coordinates, outside-release, isolated preferences, six layout
combinations per language and native city preservation, plus the retained
message/log regression. Aegean gates additionally cover quiet delivery, retry and
queue headroom, exact warning groups, stable reading/controls, compact bounds,
native kind emission, draft restoration on Escape, thumbnail shutdown and motion
Cancel. `--native-map` runs the existing incremental road/undo
and minimap coordinate checks. Without flags, captures cover folded/open maps,
expanded news, required-decision fixtures, history/building trays and inspection
at maximum sizes. News samples use real engine-written events raised only in the
disposable review; long decision fixtures test layout and never invoke gameplay
choices. The wrapper redirects the entire review preference lifecycle to a temporary
ConfigFile, rejects errors/missing completion markers and verifies the
designated city and actual user/workspace preferences remain byte-identical.

The Nova reference gates additionally compare ribbon stocks to the independent
native world query, verify jobs arithmetic, real native overlay actions, every
actual map cell's picking round trip and circular chart coverage (0.0001 tile tolerance), circular
corner pass-through, long native names/large amounts, and selected-tool bounds at
three resolutions with normal/enlarged independent sizing. Full tooltips retain
text clipped in compact controls. The map mask is a single canvas shader; no live
blur, render texture or 3D UI scene is introduced. See the validation entry for
actual passing counts and captures.

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
resources and minimap fold. A required decision only folds, retaining its ID and
callbacks. The game menu returns through its existing pause/queue restoration.
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
