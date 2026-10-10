# City interface — 3 October 2026

## Full-page and utility-frame hierarchy — 10 October 2026

Use the ornate walnut/bronze/ivory frame for full main-menu pages and restrained
bronze/slate trim for dense settings forms and compact confirmations. This is an
art-direction choice applying consistent placement/navigation and readable
contrast from [Xbox guideline 112](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112)
and [guideline 102](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/102);
these guidelines do not prescribe a particular decorative frame or constitute
full accessibility certification for this project. Preserve frame-safe reading
margins, predictable Back/Escape and keyboard focus. Large menu choices retain
ornate artwork; clean padded `MenuPagePrimary` / `MenuPageChoice` footer controls
distinguish primary and secondary actions while keeping full labels readable. Settings and
confirmation native windows share `settings_shell.install_frame`; the root menu
owns its Theme copy and city styling is unchanged.

The chapter preview's duplicate reader action and hidden story Label are removed.
Only the normal Start route opens story parchment and measured complete prose
pages before Begin; objectives and difficulty remain on that screen. The catalog
chapter selector retains preview semantics and cannot skip native progression.
The prior optional-reader descriptions below are historical; its source remains
unlinked. Current validation records all five campaign story routes and scoped
English/Russian visual/navigation evidence.

## Stable category slots and center label — 10 October 2026

All sixteen canonical building categories remain in order across maps/chapters.
`BuildCatalog.groups()` continues returning only currently available native
buildings; the HUD alone adds empty disabled slots. Keep native availability,
exact model cards/commands, unknown-category fallback, and unchanged-catalog
control identity. Empty categories use cached grayscale derivatives of existing
SVGs, a readable muted tint and translated "Unavailable" help explaining that
there are currently no available buildings in that category. Avoid promises
about unlocks the engine has not reported. Disabled clicks cannot open trays or
change tools. Native catalog refresh enables categories in their original slots
and closes a selected tray that loses availability. Guide highlights/actions
must skip disabled categories.

Reserve the center label's translated, font-measured width explicitly: clipping
and ellipsis remove a Label's natural minimum and previously collapsed it with
short category rows. Cache measurement on catalog/language/text-size changes,
cap it by available dock space, and retain centered text, utility shortcuts and
hover/focus help. Small windows retain horizontal category scrolling.

This design applies consistent ordering from [Xbox UI navigation guideline 112](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112)
and explanatory context from [guideline 114](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114).
Run sequential disposable `tools/review_toolbar.py --context --lang en` / `ru`,
then retained toolbar interactions. Sparse/empty catalogs are presentation-only
fixtures over the designated saved city, never native permission changes.

## Themed settings submenus — 10 October 2026

Start-menu settings now use `ui/settings_shell.gd`, attached only to the six known
native settings Window scripts by `menu_navigation.gd`. Each dialog owns its own
Theme copy. Original `ui/settings_art/` SVGs supply bronze/meander frame, close
button, checkbox states, dropdown arrow and slider grip; slate and ivory controls
remain code-native. No reference screenshot or additional generated bitmap is used.

The Settings hub and its ornamental frame hide while any settings window exists.
A dim scenic shade blocks background input; menu settings windows are exclusive.
Nested Game→Display/Graphics/Interface/Controls retains the existing callbacks and
returns to Game before restoring the hub. Final close restores the original category
focus. Dialog drafts, native apply/cancel/persistence and preview deadlines remain
owned by the existing dialog scripts; city settings/shared Theme remain unchanged.

Use a fixed measured caption column with expanding choices for consistent field
alignment. Footer reading padding is measured after native initialization and after
Theme/confirmation changes, using `buttons_min_width` / `buttons_min_height` on
AcceptDialog and ConfirmationDialog. Native dialog layout resets individual footer
custom minimums. Small buttons stay simple; no decorative texture covers text.
Interface preview refreshes the private Theme at independent text size and recenters
without reconstructing controls. The long key list alone retains its bounded scroll
area. Story parchment and the main/category artwork remain as previously specified.
Current validation records six-page bounds, live preview/Cancel, display Apply/Revert,
nested return and sequential English/Russian review captures.

## Frame-safe paper reading and grouped objectives — 10 October 2026

Start-menu frame padding reserves the crest, carved corners and bottom rail.
The briefing campaign name/counter share a row above its chapter title; the
complete footer stays inside the wood. `episode_card.menu_layout` leaves this
instance's sizing to `menu_navigation.gd`; the default city card layout remains.
A clipped plain Control bounds story prose without propagating a Label's long
minimum height. Paginate after layout settles, retaining every native character
and independent text size.

Objective page controls have been removed. Every native goal is visible together
in a grid in the preview/briefing. Briefings with more than four goals give
the grid a wider column; short windows use a goal row above the story. Catalog chapter previews retain their
native identity and do not skip campaign progression. Detailed city/result
callbacks, set-aside actions and settings forms are unchanged.

The menu-owned Theme uses `aged_parchment_v1.png` only for story briefings and
optional full chapter-reader surfaces. The preceding adventure preview now uses
a dark slate `AdventurePaper` with bronze trim, ivory `AdventurePreviewText` and
objective text, and gold headings. Keep the original `AdventureBodyText` dark for
paper page counters; preview colors are scoped to their own variations.
Dark ink is inset from transparent/deckled edges;
`ParchmentPageButton` uses sepia/tan normal/hover/pressed/disabled/focus states.
Only prose and catalogs retain paging. `menu_text_reader.gd` also bounds its
text before measuring full-story pages. Generation provenance retains the exact
prompt, actual 1536×1024 dimensions, true alpha and source hash. See current
validation for owned sequential EN/RU reviews and scoped platform limits.

## Compact button lettering — 9 October 2026

`menu_skin.gd` restricts ornamental textures and serif labels to explicit large
menu variations. Generic `Button` now retains the shared Theme's clean dark
surface, thin bronze border, sans font and 10×7-pixel text padding. Its menu-owned
baseline is 17 pixels, scaled by independent text size. Large menu artwork and
silhouette focus remain. This prevents decorative ends and bevels from crowding
key names, key-capture prompts and dialog footer actions. The shared city Theme
is not modified. Settings/binding callbacks, translated text and detailed-dialog
scrolling remain unchanged. The menu review measures visible key/reset/footer
labels against their padded area and captures default/asking/enlarged states.

## Global cursor family and silhouette focus — 9 October 2026

`menu_skin.gd` uses the enamel button texture for keyboard focus, with gentle
brightening instead of a rectangular border. Hover/press/disabled feedback and
translated labels retain their existing behavior.

`scripts/game_cursor.gd`, installed as `GameCursor` after `UiAccess`, registers
13 original Greek bronze/blue/ivory textures for all 17 `Input.CursorShape` roles.
Control-selected arrow, text, pointing-hand, cross, wait/busy, drag/drop,
forbidden, resize/split/move and help roles remain authoritative across menus,
dialogs, loading and city scenes. It uses Godot's hardware-cursor API with no
software pointer, frame loop, input interception or mouse-mode changes.
See [Godot custom cursors](https://docs.godotengine.org/en/stable/tutorials/inputs/custom_mouse_cursor.html)
and [Input cursor roles/API](https://docs.godotengine.org/en/stable/classes/class_input.html#method-input-set-custom-mouse-cursor).

The 1774×887 built-in generated atlas is retained unchanged. Godot crops its
eight alpha-bounded cells, resizes proportionally to 38 pixels and pads to 48×48;
five original SVG symbols supply semantic resize/help shapes. Arrow/point/busy
hotspots match visible tips; other shapes use their centers. Lossless imports
retain alpha. Interface sizes 100/110/125% install cached 48/53/60-pixel textures
and proportional hotspots. Text-only changes leave them untouched. Headless
sessions prepare resources but skip hardware registration.

`assets/cursors/olympian_cursors_v1.provenance.json` records source/prompt and
derivative hashes, measured crops/hotspots and the rebuild script. Run sequential
owned EN/RU main-menu reviews (58 each) and `tools/review_game_cursor.py` (44).
The cursor review checks actual native Control role selection and captures the
art at runtime sizes on light/dark surfaces. Viewport captures omit OS cursor
pixels; other platforms/high-DPI/multi-monitor review remains pending.

## Ornate menu skin and no-scroll navigation — 9 October 2026

The current main menu uses `ui/menu_navigation.gd` and `menu_skin.gd`. Original
generated portrait/landscape frames surround actual Controls; the button artwork
is cropped in Godot, resized once and nine-sliced with protected text margins.
Hover/press/disabled states retain legibility; the refinement above replaces the
earlier separate gold focus outline with feedback on the artwork's silhouette.
This is raster artwork with painted depth, replacing the earlier projected meshes.
The scenery remains the cinematic plate with its original live portal.

`MainScroll` is a MarginContainer, retaining its authored path/unique name. The
tall main page shows all available choices without scrolling. A compact layout
at shorter heights reduces gaps and removes supporting hints, retaining every
action. Settings has six named categories; Extras contains editor/Profiles.
Back and Escape return to the parent; native dialog preview/revert, Apply/Cancel,
audio, save ownership and campaign session handoff are retained.

`menu_list_pager.gd` derives rows-per-page from the available list height and
scaled font. Search and Previous/Next (also Page Up/Page Down on lists) retain
the authoritative index in row metadata. Empty results disable the action.
Callers use `selected_index`/`select_index()` rather than visible row numbers.
All native entries remain available. The grouped-objective update above
replaces earlier objective pages, retaining every original row.
`menu_text_reader.gd` measures/splits full chapter prose at word boundaries.
The start-menu instance alone adds story page controls to its episode
card; city campaign/result cards keep their existing reading areas. Long detailed
settings forms, such as key bindings, retain their separate scrollable dialogs.

Menu styling duplicates the current independently scaled Theme; no persistent
Theme mutation or new simulation polling is introduced. Labels remain `tr()`/CSV
text. Source art/prompts and measured dimensions/hashes are linked in
`assets/menu/greek_menu_v3.provenance.json`. Sequential owned EN/RU menu/card
reviews cover keyboard/mouse navigation, native identity and 125% UI/130% text
at 1280×800/720. These are scoped checks, not whole-game accessibility certification.
Navigation decisions follow [Xbox guideline 112](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112)
and contextual labels [guideline 114](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114).

## Realistic scenic plate and registered portal — 9 October 2026

The current start scene uses `scripts/cinematic_menu_world.gd`, superseding the
procedural scenery composer below. `assets/menu/aegean_cinematic_v2.png` is a
1672×941 generated photographic Greek scene. The existing portal shader is a
separate quad occupying image pixels `(1194,204,268,468)`. Both quads derive their
position/size from the same cover-cropped image rectangle, with 1.8% overscan
and bounded two-pixel drift. Keep calibration in source-image coordinates;
independent viewport UVs would detach the effect at other aspect ratios/scales.

The 10 October alignment correction uses `aegean_portal_distance.png` instead
of the symmetric arch for this scenic plate. `tools/calibrate_menu_portal.py`
extracts only the connected dark doorway and encodes its signed distance in
two linear-data channels; keep lossless import, no mipmaps and no automatic
3D compression. This follows the actual arch perspective, projecting jambs and
sloping sill without changing the original artwork. Both hashes are recorded
in the artwork provenance. Older procedural portal scenes retain their default
analytic arch; the packed historical Blender preview is unchanged.

Linear tone mapping/unshaded display preserves the image's finished grade. People,
ships, foliage and mountains are scenic artwork, not native simulation entities.
The native Control layer retains readable labels and exact focus/click behavior.
The ornate stage above replaces `olympian_menu_surface.gd` and scrolling. Settings/dialogs, campaign
callbacks, leaders/saves and all translations retain their existing behavior.
Reduced motion freezes portal time and recenters scenic drift. Test sequential
owned EN/RU `tools/review_main_menu.py`; `--art-only` captures the full scene.
Optional `--tag portal-alignment` isolates capture/log filenames in this shared
workspace without changing the default review behavior.


## Earlier Olympian menu housings (superseded) — 9 October 2026

`ui/login_scene_3d.tscn` now selects `scripts/olympian_menu_world.gd`, which inherits
only reusable masonry/portal helpers from the retained underworld composer.
`olympian_menu_surface.gd` projects current Control bounds into camera-local
beveled meshes. It replaces only page panel and selected primary-button fills,
preserving content margins, native signals, focus strokes and accessible text.
Scroll-ancestor clipping determines physical button bounds. Hover/focus changes
depth with perspective compensation, so the visible hit area stays aligned.
Reduced motion snaps control feedback and stops ambient camera/water/portal time.
When scenery is skipped for automation, the existing flat Theme remains intact.

Preserve MainAnchor/MainScroll and all unique page/control references, native
campaign/leader/save commands, original modal settings and display-preview flows.
Do not place labels on distorted or moving text surfaces. Adventure page bounds
are at most 1220×790 logical pixels; art is up to 230 pixels tall and shrinks for
enlarged text, with existing independent scrolling. Do not regenerate authored
scenes with historical generators. `bake_olympian_menu.gd` writes only the new
static menu derivative and its hash manifest; model originals and historical
portal source/provenance stay intact. See `assets/menu/olympian_menu_sources.json`.


## Farm harvest readiness — 9 October 2026

Farm `production.harvest_progress` is a read-only native fraction for the current
harvest cycle. The existing production inspector adds a translated floored
percentage and shared-theme progress bar after its operational status. Output
inventory remains a separate reading; readiness does not estimate wall-clock
time or change production. Refresh updates the stable controls without resetting
native target tokens, input drafts or industry commands. EN/RU strings live in
the interface CSV. See `GODOT_FARM_CROPS.md` for the matching 3D growth contract.

## City attention and settlement guide — 7 October 2026

The header's ? button and Game → City views open non-modal help styled with the
shared Theme. Filtered warnings explain native problems and select a current
building by checked ID/footprint. Inspector advice preserves native stop reasons,
house requirements and editor drafts. The six-step manual guide stays open while
building and uses existing overlays/native observations; it never builds,
auto-answers or completes an episode. Visible-only five-second polling holds
while reading; hidden help polls nothing. Game-menu pause/queue restoration,
Escape/card right-click folding, EN/RU and independent text/interface sizing are
retained. See `GODOT_CITY_CLARITY.md` and current validation.

8 October 2026: the card's dropdown became segmented **Issues | Guide** tabs with
collapse/close buttons. The guide is a stepper: title, "n of 6 done", a segmented
progress bar, a step list with done/current/upcoming markers and one expanded step
card (advice, a Done/Not yet strip with a live native count, Build and overlay
buttons, Back and a gold Next step). An outline pulses round the dock tool or
category the current step needs. The card sizes to its content and stops above
the minimap. The Issues tab uses counted filter pills and one severity-edged,
fully clickable card per warning, with a pager and an empty state. `Guide*` and
`Issue*` Theme variations; contracts in `GODOT_CITY_CLARITY.md`.

## Character inspection and live supply cards — 7 October 2026

The centered character card uses the dock's charcoal/bronze surface, a bounded
portrait, inset native speech/voice section, scrollable details and separate
Go to / Close footer. Ordinary roles use a smaller height; peddlers have space
for the six Agora-style supply tiles. Shared Theme variations and EN/RU text
respect independent UI/text scales. Portrait images retain disabled viewports;
roles without them retain the existing 3D stage.

Peddlers display their own linked Agora's stock/capacity/missing vendors. Native
transport carts display actual resource types and cargo loads, including goods
without a rendered cargo model; growers show their collected fruit. Empty loads
and unavailable Agoras are explicit. There is no separate native peddler cart
inventory: supply comes directly from its Agora, which the card names.

One read-only `character_inventory` query per second updates stable cards without
rerolling speech or restarting voice/portrait. The native clock stays paused and
queued commands held; all close/focus paths retain the previous pause/hold state
and required decision callbacks. See `GODOT_CHARACTER_INVENTORY.md` and current
validation before modifying inventory sources, units or this layout.

## Slim instant notices — 7 October 2026

Open `notification_chip.gd` cards contain only the wrapped NoticeBody and thin
timeout bar. The former title/icon/Close row is removed. The card itself owns
left-click release and keyboard activation for pin/unpin; right-click release
emits the existing informational dismissal signal. Descendant text ignores
pointer input, the body scroll passes clicks to the card, and its scrollbar
retains scrolling ownership. Titles and action hints remain in translated hover
text; an empty native body falls back to its title.

This supersedes the instant title/Close controls described in older sections.
Journal rows retain their title/icon disclosure buttons. Keep full bodies,
parent-allotted width, bounded 132/260-pixel reading areas, stable scroll identity,
shared Theme/text scaling, progress and the one-alert queue. Hover, pinned
reading, hidden/clipped notices hold their timers; expiry/right-click follow the
original record-before-ack path. Required correspondence and native choices keep
their existing controls and pause ownership. Run the layout gate and sequential
disposable `tools/review_chrome.py --notifications-only --lang en` / `ru`.

## Ruin inspection and demolition — 6 October 2026

Inspection adds a read-only `ruin` record with native original type/name, current
rubble count, exact clearing cost, availability/reason and a guarded target token.
`Hud` titles known ruins “Ruins of %s”; unknown types retain the native generic
name. `InspectionSummary` shows ruin/fire status and clearing guidance, hiding
fictitious maintenance, road metrics and service links. `BuildingInspector` adds
the shared-theme Demolish button with cost and an irreversible-clearing tooltip.
It disables while queued and reenables after a refused queue handoff.

The panel sends `demolish_ruin` with the current inspection and member-set guard.
The ordinary tool has an independent hover guard. Refreshing an inspector never
changes another ruin's hover token. Single hover and held rectangle previews draw
one complete site plate rather than one overlay per native rubble tile; tooltip
costs reflect all current rubble members. Rectangle contact expands to the whole
site. Native fire, ownership, credit and decision checks remain authoritative;
the command erases only matching rubble, preserving neighboring standing objects.
EN/RU strings use the shared CSV/Theme; no native save fields or extra polling
are introduced. Run `validate_ruins.gd` and sequential disposable
`tools/review_ruins.py --lang en` / `ru` for the focused contract.

## Avenue and boulevard cards — 6 October 2026

`building_preview.gd` makes distinct original street miniatures using the shared
edge-decoration generator: limestone slabs, promenade border and olive/cypress
furniture. These are static meshes rendered through the existing single cached
thumbnail viewport; no per-card viewport, physics or native construction is
added, and the idle-disable contract remains. `hud.gd` reports translated
“Street width: 2 tiles” / “Street width: 3 tiles” in tool facts and hover context.
The native catalog's one-cell drag anchor remains unchanged. Dedicated card
captures and checks are in the avenue review described in validation.

Wall panel follow-up (6 October 2026): `%WallFill` stays hidden for selected and
hovered walls, superseding the older visible checkbox contract. Keep ordinary
outline dragging and the Shift-drag native fill modifier; placement help explains
the shortcut in English and Russian. Native preview/build/undo remain unchanged.

## Illustrated notification hub and objective disclosure — 6 October 2026

The upper-right rail is fixed at eight logical pixels from the top and sixteen
from the right, independent of the upper-left Resources disclosure. A 60-pixel
minimum shell keeps its width steady when the bounded alert scrollbar appears.
Two primary controls are Journal (bound parchment/quill) and Objectives
(scroll/check/laurel). A third envelope/seal appears only for a pending native
choice. `notification_button.gd` extends ToolbarButton, preserving ordinary
mouse release activation and keyboard focus. Counts are drawn separately from
art; objective progress uses a small bottom line. Finite highlights honor Reduce
interface motion. All styles and font sizes come from the shared Theme, and
original static `notice_*.svg` assets extend the existing colored dock system.

Objectives begins closed, hides when there are no native goals and opens its
existing ObjectiveCards beside the rail. Native met/total/progress and set-aside
callbacks remain authoritative. Newly completed unseen goals add a badge; opening
clears it. The panel closes with its icon, Close, Escape or a competing disclosure.
Opening never shifts the dock. Journal and monster disclosures use the same
right-side clearance; inspection is hidden while reading goals, preserving its
existing selection/draft/token data for return.

Journal has All reports / Warnings / Decisions filters. They select presentation
rows without deleting records, changing unread policy, acknowledging an event or
inventing a decision outcome. Unchanged refresh retains reading controls/order
and complete grouped occurrence text. Opening still marks the recorded journal
read. Warning kinds come from read-only native metadata; choices retain their
existing classification. History and urgent cards use the corresponding art.
Routine reports stay quiet in history; urgent reports retain one visible card
with later arrivals queued. No new native polling or event/save fields are added.

Hazards retain one icon per original kind group, original grouping/order, site
dedup, count, right-click dismissal and newest-site navigation. Live monsters
retain their separate native hero/action card. Red count accents identify threats;
gold accents identify visits/arrivals. AlertScroll has a visible slim bronze
scrollbar, keyboard focus following and an integer height bounded by 240 pixels
or 32% of the viewport. Integer sizing avoids a fractional last-row clip at 125%
interface scaling. Hover, focus, hidden/clipped presentation and blocking dialogs
hold the existing attention allowance. Persistent fires/plague last as before.

Required choices still open the centered correspondence modal automatically.
Folding replaces it with the persistent amber seal, with native pending count,
request title and paused-reply hover text. Neither folding nor a journal filter
answers it or unblocks the native clock; original choice IDs, labels, enlisting
and reply callbacks remain. Modal Tab containment and camera blocking are kept.

Design references are the official [Anno UI designer notes](https://www.anno-union.com/devblog-user-interface-2/)
(function hierarchy, clear feedback and a quiet HUD) and [Farthest Frontier's
controls guide](https://www.farthestfrontier.com/guide/about/basics/) (an on-demand
event log). These informed the hierarchy; no reference artwork is embedded.
Current validation records the tested languages, sizes, native request behavior
and remaining scope.

## Upper-left overview and stable report width — 6 October 2026

The accepted compact overview supersedes its centered 86%-width layout.
`_layout_header` measures the current city's name at the active Theme font size
(90–220 logical pixels, with the complete name in hover text), adds StatsGroup,
row separation and frame margins, and caps the result at viewport width minus
32. `_layout_panels` anchors it 16 pixels from the left, with ResourcesReveal
below on the same edge/width. StatsGroup wraps beneath the city only when the
available width requires it; a half-pixel tolerance avoids repeated reparenting
from float rounding. All lower panels still use the actual header/disclosure
height. Native cached readings and button commands are unchanged.

ResourceRibbon explicitly inherits PanelContainer in the shared Theme generator.
Its charcoal surface has alpha .90, 8/3 horizontal/vertical padding and the dock's
bronze edge. The previous unregistered variation fell back to the generic panel.
Only the background is softened: text/icons do not receive subtree modulation.
The native Play/Pause/speeds/date remain under the map; Jobs remains after Layers.

`notification_chip.gd` fills its parent VBox. Body fitting computes a bounded
minimum height (132 open, 260 pinned) and assigns it only on a change. It never
resets the card's size, including pin/unpin. An autowrapped Label and ellipsized
heading report almost no minimum width; resetting the PanelContainer repeatedly
threw away the parent's allotted width and left a narrow icon/Close column, as
seen in the recording. NoticeBody inherits Caption at 15 baseline pixels and
participates in UiAccess text scaling without a local font override.

Preserve the original complete body, stable controls/scroll, full history,
reading/hover/hidden/clipped timer holds, single visible alert and queued arrivals.
Close emits only the existing informational acknowledgement; reading never
answers a native decision. Static folded history stays process-disabled and its
expanded body retains the existing 180-pixel bound. Required-decision pause,
callbacks and journal record-before-ack policy are unchanged.

## Clock column and main-row shortcut help — 6 October 2026

`%TimeBar` is reparented from the overview to a root HUD panel using ToolbarDock.
Its authored VBox has Play/Pause and all four native speed buttons on the first
row, then the date/month gauge. The panel sits below the minimap at bottom left.
Map and clock share a measured column; the dock reserves the larger minimum
width even when the map is folded, avoiding overlap or horizontal shifts.
Time controls retain their native signals, speed IDs, translated help and
keyboard camera hold through the shared header-focus helpers. Right-click army
input explicitly excludes the clock. No time accumulator or speed rule changes.

`%MapToggle` is visible only while `%MinimapPanel` is actually hidden and stays
above the clock. `%MapClose` folds an open map. Version-2 explicit preferences,
default visibility, temporary tray/journal/decision folds, the native map
transforms and circle corner picking are unchanged. This supersedes the previous
map button beside the open circle. `%Jobs` is reparented after `%OverlayMenu`
in ToolbarUtilities with ToolbarTool styling; its original industry-view callback,
availability and native employment tooltip figures remain. `%ToolbarContext`
is center aligned and reads the first tooltip line, keeping those figures from
expanding the footer height.

Only the main bottom controls add current `KeyBindings` labels to their hover
titles. New rebindable defaults are Housing H, Road B, Road Block G, Layers L
and Jobs J; existing demolition X/Delete and Cmd/Ctrl+Z Undo remain. Category
hover names are unchanged. New key dispatch uses the existing button callback
and native catalog availability after dialog, typing and required-decision
input gates. Controls changes refresh the complete hover titles from cached
observations. No extra native query, tile scan or HUD viewport is added.

When reading older custom keys, validate existing actions first. If their key
occupies a new dock default, keep the earlier binding and leave that new action
Unassigned (0), with EN/RU text. It can be assigned normally and survives reload.
Empty keys cannot match or own an action, and a swap cannot disable a held
camera control. Preferences are not rewritten merely to add defaults.

## Dock utilities and Layers disclosure — 6 October 2026

The upper-left `%WelfareGroup` is reparented into `%LayersPanel`. Its original
four quick buttons retain exact native supplies/water/hygiene/hazards signals,
selected markers and translated hover help. `%OverlayMenu` is now a toggle
Button opening a framed panel above the dock. The remaining 21 native overlay
choices (including Normal, culture and science) are translated buttons in a
bounded, keyboard-following scroll grid. Full tooltip labels survive ellipsis.
Existing overlay IDs/legends/count observations/hotkeys and the compatibility
activation/menu route are retained, with no extra polling or rule changes.

`%BuildMenu` and the registered `select` button remain hidden for compatibility.
Default/right-click inspection and Escape are unchanged; all native buildings
remain in category trays. `%Undo` is first on the left, followed by direct
housing, roads, roadblocks and demolition. Those building shortcuts use native
catalog availability, the existing tool/ghost/placement callbacks and original
colored icons (roadblocks add an original SVG barrier over limestone paving).

`%MapToggle` is a root HUD control immediately to the right of the open map and
moves to a reachable bottom-left position when it is folded. Dock sizing reserves
its width, so map visibility does not shift the dock. Keep the circular map's
masked picking/native coordinate transforms and version-2 explicit visibility
preference; temporary folds do not overwrite it. The removed `%MapPeek` pill
stays hidden. Header bounds no longer reserve the removed welfare strip.

Layers uses the shared charcoal/bronze Theme and measured fixed header/chrome
height to bound its scroll room between the actual overview and dock. It draws
above ordinary inspectors, below required decisions. It owns camera keys while
open; choice/Escape/right-click/Close release that hold. Clicking terrain to
dismiss it consumes the click before an existing construction tool can act.
Opening another category, journal, map or required decision closes Layers.
Closing Layers when it was already closed must preserve unrelated keyboard
focus. Pending decision pause, callbacks, queue and saved state remain native.

## Complete building-card previews — 6 October 2026

`scripts/building_preview.gd` assembles catalog pictures: common/grand agoras are
their newly founded three/six empty 2×2 paved plots beside/across a six-tile road.
No vendor is implied in the agora's construction cost. Other composites use
the existing native placement query's `pieces` (palace, ranch, sanctuaries,
pyramids, shrines and god monuments). A known map cell supplies the read-only
layout even when placement there is refused; the native city focus preserves
the player's scenario-specific marble levels. No valid-site scan, command, grant,
simulation advance or recurring polling is needed. Picture ground is flat;
native relative pyramid lifts and model fitting remain. Pyramid face geometry,
authored on sprite axes, receives a preview-only axis adapter so adjacent faces
join. It reflects copied geometry (positions/normals/tangents/triangle winding),
retains colors/both UV arrays/shared finishes, then applies a quarter-turn with
positive scale. Negative display scale was found to reverse the two-sided GLB's
lit normals. Temporary copied geometry is freed with the display; no imported
model/material or world instance is modified.
The rendered city and native placement ghosts are not modified by this adapter.

`building_thumbnails.gd::request` accepts a full catalog Dictionary and keys by
base tool name, preserving distinct designs sharing `agora_space`, pyramid caps
or shrine monuments. Partner-city trade entries share the same base picture.
Cards and selected/hover context use that same key for asynchronous updates.
Invisible subtrees do not expand the fitted silhouette. Missing geometry cannot
produce a cached partial composite; terrain tools retain the colored road
illustration, and other loading/missing/headless fallbacks use the dock's colored
category art. The one 160×100 viewport renders twice per new design and stops
when idle, retaining only textures and releasing temporary display nodes.

Use sequential disposable `tools/review_toolbar.py --previews --lang en` / `ru`
for catalog geometry, composite completeness, rendered alpha bounds, distinct
shared-component pictures, context matching, actual clicks and native preservation.

## Treasury and population illustrations — 5 October 2026

The header uses `toolbar_icons/treasury.svg` and `population.svg`: original
96×96 shaded vector sources matching the construction dock. `%TreasuryIcon`
and `%CitizensIcon` are equal 24×24 logical-pixel TextureRects with vertical
shrink-center alignment, ignore-size expansion, aspect-preserving centered
stretch and pointer-ignore behavior. Neutral tint preserves their colors.
Native tooltip parents and values remain unchanged. The HUD's `SilverCoin`
preload, live viewport and treasury-gain flip bookkeeping are removed; its
standalone source stays archived. This supersedes earlier live-coin styling.

## Matching dock surfaces and compact overview — 5 October 2026

The shared Theme generator styles city panel frames in the illustrated toolbar's
charcoal/bronze palette with four-pixel corners. Existing frame content margins,
independent text scaling, semantic button/status colors and parchment interiors
stay intact. Default header values use 14 px, monthly trend 13 px and city title
18 px; gauges measure full text. Compact frame/well margins and 28 px controls
reduce height. The centered overview aims for 86% of the viewport, capped at 1560
logical pixels, and widens to its full native readings before wrapping at the
available screen width. The resource panel measures rows against that same width.
Header gaps remain pointer-transparent and actual bounds govern other panels.

`%MapPeek` is always hidden; its unique scene reference remains for compatibility.
The default map is open in normal and review launches. `preferred_minimap_open`
treats an unversioned older folded preference as the new open default without
writing on launch. Explicit dock/fold choices save visibility with policy version
2 and are honored thereafter. Trays, journal and expanded required decisions
only hide the map temporarily; callbacks, pause ownership and native picking stay
unchanged. The dock still reserves the map corner while it is folded, preventing
layout movement when toggled. This supersedes the old City map pill/open policy.

## Caption-free top bar — 5 October 2026

The user's request removes Date/Speed/Current city/Housing/Treasury/Monthly
balance/Population titles. Their unique Label nodes remain hidden, preserving
translation/reference compatibility without contributing layout height.
Remaining value columns use vertical shrink-center alignment. Keep native
counts/date/gauges/coin/mood, hover help, numbered speed indices, resources,
responsive row sizing and the shared mouse-up focus-release fix. Translation
or independent text scaling must not make these captions visible again.
The authored TimeRow orders Play/Pause, SpeedColumn, then Calendar; the native
speed indices and date observation stay attached to their existing unique nodes.

## Shared button pointer ordering — 5 October 2026

`ToolbarButton` must keep focus while a mouse press is armed. Its `gui_input`
handler defers `release_focus` on mouse-up, after native Button/MenuButton
activation has completed. Deferring it on mouse-down cancels Godot's armed press
before a later hardware release and affects every redesigned header/dock button.
Keyboard input retains focus; drag-outside cancellation must not issue an action.
Do not replace native signals or menu activation modes. Review mouse helpers
wait two frames between down/up so deferred focus changes are included;
the dock reviewer also aligns the physical cursor with injected motion for
between-frame hover checks. `validate_toolbar_input.gd` covers untagged pointer
and keyboard behavior.

## City overview and panel bounds — 5 October 2026

The authored overview separates Date/Speed, Current city and the native statistics.
Captions identify Housing/Treasury/Monthly balance/Population; Resources has a
translated name and static storage icon. Housing reads native vacancies / total
capacity and explicitly says free, while the gauge still shows occupancy. Treasury
debt color is independent of the existing monthly-ledger balance. Retain native
month lengths, four speed indices, coin freshness/animation and popularity thresholds.

`Header*` variations in the shared Theme own typography/focus surfaces. Gauge
minimum sizes include their full date/count labels; `_layout_header` moves the
complete `%StatsGroup` between `%OverviewRow` and `%ResourceLayout` according to
available width. Resource wrapping and all dependent panels use the actual header
height. This changes presentation bounds, never stock observations or polling.

`hover_help.gd` builds the same wrapped, bounded, pointer-ignoring help for dock
buttons, header controls and company rows. Native title/body text remains complete.
Header focus participates in existing `toolbar_focus_changed` camera ownership,
clears old drags, and blocks Home as well as continuous camera keys. Mouse choices
of Jobs/stock/welfare views release focus through the original view callbacks.
Escape/right-click folding Resources releases ownership without changing native
pause; required decisions and dialogs retain their earlier input/pause priority.

Army is nonmodal and receives `fit_host` bounds below the actual header and above
the dock/objectives. A fixed title/Close surrounds one scrolling body. Company
rows ellipsize with full native hover text, selection reveals details, and unchanged
refreshes preserve controls/selection/scroll. Empty/abroad/unplaced explanations
must follow the existing native action predicates; keep IDs and order callbacks.

Inspector subtitles show native footprint and staffing, retaining city context
in hover text. Stored-good names wrap with a full translated hover name, while
orders, stock limits and drafts retain their original controls/state. Inspector
and journal scrolls follow keyboard focus. Objective disclosure uses a directional
chevron; number grouping matches the HUD locale and native `met` still owns completion.
Sequential disposable `tools/review_chrome.py` reviews and the optional native Army
phase are documented in validation. Do not overwrite the authored scenes with
historical UI generators or persist the scaled Theme.

## Illustrated construction toolbar — 5 October 2026

The authored `%BottomBar` uses `ToolbarDock`: a horizontally scrolling category
row, separator, then a utility row with an immediate `%ToolbarContext` label.
This replaces only the older dock layout. The current header, minimap, cards,
journal and required-decision layout remain governed by their own contracts.
Original shaded SVGs in `ui/toolbar_icons/` identify each native category; their
Theme tint stays white so roofs, crops, amphorae, shields and other silhouettes
retain their distinct colors. Gold marks selection. These are static textures,
without extra native polling, thumbnail viewports or Blender scene changes.

`toolbar_button.gd` provides a native custom tooltip with the full translated
title and explanation. Wrapped labels receive their width before the tooltip
window measures height; the tooltip ignores pointer input. All explanations use
CSV `tr()` keys and shared `Toolbar*` Theme variations. Focus/hover updates the
context without selecting a category or issuing a native command. Categories
follow keyboard focus when scrolling; smaller windows and independent UI/text
sizes keep utilities visible and the model tray above the dock.

Keep the native `BuildCatalog` groups and eligibility, precise card membership,
placement/cost callbacks, trade-partner suffixes, model selection, map preference,
Undo availability and overlay metadata. The duplicate direct house shortcut and
the category-only tray's BuildSearch remain hidden. Identical catalog data must
retain controls, card state, hover, scroll and keyboard focus. Do not replace
native routes with presentation decisions or regenerate this authored scene.

`toolbar_focus_changed` holds continuous and event camera input while a dock
control or native popup owns keyboard navigation, clearing an old drag on entry.
Mouse selections, tray closing and actual Build/overlay menu choices release
dock focus; merely reapplying an overlay does not. Escape closes the tray while
preserving its chosen construction tool, following the existing two-step cancel
contract. MenuButtons use native release activation with hover switching off:
the click that opens a bottom popup must not select an item repositioned over it.

Run `tools/review_toolbar.py` sequentially in EN/RU with copied designated cities,
disposable leaders/settings and protected original hashes. Reviews distinguish
real native catalog/GUI routes from tooltip and Undo-availability fixtures; queued
Undo is observed but not executed. See current validation for evidence and limits.

## Centered required-decision card — 7 October 2026

`hud.tscn` is authored: `%EventsBox`/`%DecisionShade` are raised above the normal
HUD, below subsequently opened character/settings controls. Expanded correspondence
has a compact bounded center card, native sender identity/static `envoy_portrait.gd`,
`EnvoyPaper` with `%EventScroll`, and `%DecisionFooter` outside the letter scroll.
`%EventActions` is now a responsive GridContainer inside its own bounded scroll;
long native labels wrap. The folded reminder is `%DecisionReview` in the upper-right rail. Do not
regenerate this scene with the old HUD builder or save the scaled live Theme.

`hud.gd` orders/stylizes choices by native callback codes, never translated
strings. Ordinary 2/1/0 or -2 correspond to Refuse/Postpone/Dispatch or enlisting;
1000+ remains the exact receiving-city callback. A sole destination gets primary
emphasis; multiple destinations are peers. Native kind `invasion` uses its own
0/1/2 meanings (Surrender/Bribe/Defend). `main.gd` binds each reordered Button to
the original event ID and choice; -2 still opens the original `EnlistDialog`.
No default native answer receives focus. Tab cycles inside the card, whose
backdrop intercepts city clicks; `orbit.modal_input_blocked` holds camera input
and clears an old drag while expanded. A native reply removes these input holds.

Required decisions retain the C++ clock block, independently of the user's pause
preference. Right-click on an expanded card or folded decision icon selects the
actual offered native Postpone action, sharing the guarded button callback path.
`decision_can_postpone` excludes invasion kind, where choice 1 means Bribe, and
requires choice 1 to exist; decisions without it only fold. Pending replies are
debounced, with buttons disabled until completion; queue-full/error paths leave
the request visible/retryable. Never send an extra resume: native Postpone
releases its own block and keeps user pause/other pending decisions authoritative.
Fold/title-toggle/Escape only change presentation; the same reminder reopens
the same event. Escape folds this foreground card before
any journal behind it, preserving the journal's reading state. Canceling troop
enlistment and returning from the game menu preserve the pending event and block.
There is no automatic reply, save write or replacement simulation pause owner.
Edit/regenerate only the relevant `Envoy*`/`Decision*` Theme entries through
`build_ui_theme.gd -- --decisions-only`; visible labels use translated CSV keys.
The charcoal card and letter, ivory sans body text, compact rectangular portrait
and matching button surfaces follow the current shared panel design. Reading
height follows content within the viewport budget instead of allocating a large
empty page. The footer/icon hint advertises right-click only when Postpone exists.

Use sequential `tools/review_decision_panel.py --lang en` / `--lang ru` with
disposable leaders/city copies/settings. Validation distinguishes real native
callbacks from long-wording and invasion/destination presentation fixtures.

## Campaign completion and briefing card — 5 October 2026

Edit `ui/episode_card.tscn` directly; the historical `build_episode_card_scene.gd`
and overlay/start scene generators must not overwrite it. The unique Heading,
Subtitle, Body, Scroll, Colonies, Goals and action controls remain the host API.
EpisodeProgress separates the native episode number/count from the episode title.
The banner, parchment and objective surfaces use `Episode*` Theme variations;
`episode_victory.svg` is original vector art. Do not save the scaled live Theme.

`fit_host` bounds both the city overlay and first start-menu briefing to the
logical viewport, responding to window/UI/text changes. Story and objective
scroll areas keep long content reachable; the footer is outside both. Difficulty
arrows have keyboard focus and translated tooltips. Objective cards preserve
native text/status/index and `met`; only native achieved flags colour them green.
The completed-objective heading appears only when every supplied goal is met.
Empty goal lists show the existing objective-free explanation. Colony selection
keeps native indices, ItemList navigation and activation.

`episode_overlay.gd` retains its original native commands and callbacks:
finish_episode, choose_colony, begin_episode, restart and main menu. Presentation
never advances the campaign, answers a pending choice or writes a save by itself.
First-briefing Back still releases the opened session and returns to the selected
adventure. Run `validate_campaign_ui.gd` and sequential scratch-profile
`tools/review_episode_panel.py --lang en` / `--lang ru`; see validation for the
real transitions, frozen-clock checks, captures and presentation-only fixture.

## Main-menu shell — 5 October 2026

`ui/start_menu.tscn` owns the main page directly. Keep its unique MainAnchor,
MainPage, MainScroll, MainColumn, LeaderSlot and ContinueCard references alongside
the existing action names. The shared Theme's `MainMenu*` variations supply
typography, surfaces and button states; `ui/icons/menu_*.svg` are original vector
art. Never save a live scaled Theme or regenerate this page with the old builder.

`refresh_main` reads `SaveFiles.latest()` for the current native leader, puts its
name/metadata into the card and keeps the exact path for Continue. Long names
are ellipsized with full tooltips. An empty profile hides the card, disables Load
with its translated reason and focuses New game. Leader identity and the current
language remain visible; named Settings and all footer controls accept keyboard
focus. Preserve existing handlers and preference scopes.

`fit_main_page` bounds a content-sized left panel to the logical viewport and
responds to size/text changes. MainScroll follows focus so utility actions remain
reachable when the content is taller than the window. The illustrated adventure
page is a separate bounded layout. Run sequential `tools/review_main_menu.py
--lang en` / `--lang ru` with disposable preferences/leaders/save copies; real
pointer/key input exercises navigation and Continue opens the designated native
city only from its scratch copy. Read the latest validation entry for scope.

## Adventure selection card — 4 October 2026

`ui/start_menu.tscn` is authored directly; do not regenerate it with the historical
start-scene builder. Its left library uses `AdventureList`; the card on the right
uses shared `AdventureCard`, `AdventureRibbon`, `AdventurePaper`, badge and text
variations. All new interface strings use `tr()` and `data/ui_strings.csv`.
`fit_adventure_page` bounds the shell/illustration to the logical viewport;
list/detail scrolling and wrapped goals preserve enlarged interface/text settings.

`adventure_preview` is a native template read, not a new game: validate kind/ref
against the shared adventure catalog, read the first parent episode, emit native
goal texts, close the temporary campaign and release ownership even on failure.
Never start/advance a city or write a save for card selection. Native ownership
must refuse previews while a live city holds the globals. Read the parent world
district for civilization-specific goal terms; template boards have no selected
city yet. A sandbox has no objectives across any parent/colony episode, rather
than merely an empty first goal list or a title containing 'Sandbox'. Do not
invent goals or auto-answer events. The episode label distinguishes main episodes and alternative colony scenarios.

`adventure_art.gd` resolves native bitmap IDs from `data/adventure_art.json`:
installed loose overrides, then packed native artwork. It caps images to 960
pixels, caches at most 18 IDs and shows a translated missing-art fallback.
`tools/adventure_art_metadata.py --check` verifies all offsets/crops against the
native headers; regenerate metadata if packed artwork changes. No source pictures
or atlases are copied or edited, and existing provenance/release gates apply.

Preview cache keys include language/kind/ref. Selection generations cancel stale
reads before they touch the native service; Starting also cancels pending work.
Keep ItemList keyboard navigation, native Start/briefing/difficulty/Begin, selected
card on briefing Back, Escape and the editor's new-adventure row. Reviews use a
scratch leader/settings/save root, close only their own windows and protect the
designated save and player preferences. Run `validate_adventure_cards.gd` and
`tools/review_adventure_cards.py --lang en` / `--lang ru` sequentially.


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
the existing model factory and two renders per requested building design. It caches
only small finished ImageTextures and frees the temporary model instances. The
viewport stops rendering when idle. It never reads or advances the simulation.
Warm key light and cool fill refine the previews; the final render explicitly
returns the viewport to `UPDATE_DISABLED`.
Road terrain keeps the colored road illustration; absent development meshes and
headless runs keep colored category artwork.
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
