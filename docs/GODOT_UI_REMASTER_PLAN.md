# Interface remaster — implementation plan

Latest direction (3 October): the user supplied a clearer Nova Roma reference and
requested matching its city HUD. The implemented Nova shell supersedes the Aegean
shell described below; delivery/history and native command contracts remain.
See `GODOT_INTERFACE.md` and the newest validation entry for current layout and
verification. Original teal frames, stock glyphs and compact native tool cards
are repository-authored; no reference screenshot assets are embedded.

Date: 3 October 2026. Status: implemented in the Godot HUD; focused validation
completed, user visual acceptance and matched performance profiling pending.

## Earlier Aegean implementation checkpoint

The floating Aegean shell, quiet journal, one-alert queue, persistent native
decisions, warning occurrence groups, native inspector explanations, cached
thumbnail lighting, motion preference and Escape/draft coordination are in game.
Existing category icons receive original bronze medallion treatment through the
shared Theme, with provenance in `ui/icons/README.md`; no screenshot artwork or
new model assets were imported. Language and Game remain directly reachable at
the upper right rather than moving language exclusively into Game.

The service needed a read-only event `kind` field to distinguish routine news
without parsing translated titles. The finalized extension and relevant embedded/
event checks pass; simulation timing, coordinates, save format and callbacks are
unchanged. Unchanged catalog refreshes now preserve hover previews and scroll.

All three delivery checkpoints below are implemented. Actual EN/RU captures and
scoped checks are recorded in `GODOT_VALIDATION.md`. The broad run still reports
the existing aid-regard assertion, and an initial hover failure was fixed and
verified. Matched before/after frame-time and memory medians, minimum-Mac testing,
all specialized panels at every scale and user visual acceptance remain open.
Do not interpret the targets below as completed performance/accessibility gates.

## Direction and scope

Use the selected Aegean floating-dock layout with the classical character of the
user's Zeus/Poseidon references: deep navy, warm ivory, restrained bronze,
original sculpted category emblems, serif headings and clear sans-serif body text.
The new screenshot's compact monthly report is a useful content hierarchy;
routine monthly reports will be available in the journal rather than automatically
covering the city. Preserve the native report text and values.

Deliver the city HUD, construction tray, journal, notification policy and inspector
presentation. Shared styling must remain compatible with menus, settings, world
atlas and campaign dialogs. Reuse those flows; a separate redesign of every
specialized screen is outside this slice. No simulation, terrain, camera or asset
catalog expansion is planned.

Use shallow visual depth for controls and existing model thumbnails. Do not put
HUD text in perspective or introduce continuously rendered 3D UI scenes. Author
new icon treatments; do not extract artwork from the reference screenshots.

## Target layout

Dimensions below are starting design targets in logical pixels, adjusted upward
for accessible text sizes rather than enforced as clipping limits.

- Top: two compact groups, time controls/date on the left and native treasury,
  population and Game access on the right. Retain all four native speed settings.
  Target 36–40px height at default scale, with 12–16px outer margins.
- Upper left: folded objectives, expanding on request.
- Upper right: Inbox with unread count; a separate persistent amber review control
  when native decisions are pending. Language remains reachable from Game.
- Bottom centre: content-sized construction dock with original category medallions,
  active-state depth and readable labels/tooltips. Preserve all ten categories,
  the complete catalog/search, quick tools, demolition, undo and overlays. The
  seven-category mockup is illustrative, not a reduction of supported features.
- Bottom right: existing folded City map control and remembered map visibility.
  Keep Home overview, heading chevron and current coordinate transforms.
- Above dock: upward-growing model tray, retaining selected/hovered context,
  prices, footprints, facing, wall fill and search.
- Right: one content-sized information surface. Initial width target 340–380px;
  journal starts at content height and grows to at most 55% of usable height
  before scrolling. Inspectors may use more height for complex forms.
- Responsive fallback: compact/group dock categories and wrap top controls when
  needed; every action remains reachable. Resolve from actual measured minimum
  sizes, including Russian and maximum independent text/interface scaling.

Panel coordination: required decision reading has priority; opening journal hides
inspector presentation without destroying drafts. Construction/journal/decision
reading retain existing temporary map-folding and restoration rules. Map remains
bottom-right. Escape closes the foremost disclosure before cancelling a tool,
while preserving existing dialog-specific Escape behaviour. Empty HUD margins
pass pointer input through to the city; visible controls block it.

## Implementation sequence

### 1. Baseline and interface state inventory

Capture matched before views on the designated save: idle city, construction,
short and long inspectors, journal, pending decision, minimap and active overlay.
Record bounds, frame times and thumbnail behaviour at a fixed camera pose.
Inventory current event fields and acknowledgement paths before changing routing.
Record every action's new destination so none disappears with the old toolbar.

Acceptance: a reproducible baseline, action map and event-policy table; unrelated
workspace changes and real preferences untouched.

### 2. Shared visual foundation and HUD shell

Change `godot/scripts/build_ui_theme.gd` and regenerate the shared
`godot/ui/lapis_gold.tres`, preserving all named variations, including AtlasTitle
and AtlasHint. Use existing licensed Alegreya for headings and a Cyrillic-capable
body font. Add original emblem assets and provenance under `godot/ui/icons/`.
Edit `godot/ui/hud.tscn` directly, and adapt layout in `godot/ui/hud.gd`.
Do not run the obsolete HUD scene generator.

Implement compact top groups, floating dock and folded utilities. Preserve existing
signals into main.gd. Use restrained gradients, edge highlights and shadows;
avoid live blur and decorative perpetual animation. Target 120–180ms local
hover/open transitions, with motion reduction support through interface options
if no existing preference is available.

Acceptance: idle city layout has no full-width bottom slab, no empty history panel
and no lost actions; controls remain legible and clickable at every test size.

### 3. Quiet journal and notification routing

Keep the authoritative log in `godot/scripts/message_log.gd`; separate recording,
presentation and native informational acknowledgement in main.gd. Extract a small
presentation-policy helper if necessary rather than scattering rules across HUD.

| Event class | Default presentation | Lifetime and action |
| --- | --- | --- |
| Routine report or informational update | Journal + unread count only | Full native text retained; no popup or new UI sound |
| Repeated informational warning | Grouped journal row with count and latest date | Preserve individual records and expand occurrences |
| Explicitly identified urgent informational event | At most one compact upper-right alert | Full text on click; no screen dimming or focus theft; timed display pauses while reading/hovered/hidden |
| Native decision | Persistent amber review control | No expiration or automatic answer; original live ID and choices |

Use stable event kind/source metadata if available. Never classify or group by
translated title alone. If the necessary metadata is missing, retain safe ungrouped
entries; expose read-only native metadata only if needed and document that scope.
Unknown decision-bearing events always remain decisions. Unknown informational
events use a conservative visible fallback until their policy is established.

Quiet routine events must follow the same proven informational acknowledgement
path as current toast dismissal, exactly once, after being retained in history.
Never reuse that path for required decisions. Do not suppress existing native
campaign/voice behaviour as an incidental UI change.

Retain newest-first ordering, opening-journal read semantics, complete wording
and deduplication. Preserve expanded row identity and scroll position on refresh;
new arrivals must not displace the event being read. Group counts do not replace
the underlying unread event count. Historical entries never execute stale choices.
Urgent bursts queue/group conservatively without losing log records or decisions.

Acceptance: routine monthly reports and labour warnings produce no automatic
popup; no invisible pending informational events; required decisions block and
resolve exactly as before; full history and reading state survive updates.

### 4. Construction presentation and useful inspectors

Reuse `godot/ui/building_thumbnails.gd`: one isolated, idle-disabled viewport and
cached textures from loaded models. Improve framing, lighting and tile surfaces;
keep prices/names readable and exact native availability. No per-card render loops.

Refine `godot/ui/inspection_summary.gd` and `godot/ui/overlay_summary.gd` around
status → cause → relevant action. Start with housing, staffing and production.
Show immigration constraints or worker shortages only when native observations
support them. Reuse current overlay shortcuts; add Locate only for a validated
live target. No synthetic coverage percentages, diagnoses or economy statistics.
Preserve storage/trade drafts, explicit Apply and stale-target token checks.

Acceptance: players can understand the native problem and reach an existing
relevant view; model cards add no ongoing idle render cost; every current native
construction and inspector operation remains available.

### 5. Integration, accessibility and visual review

All new interface text goes through `tr()` and `godot/data/ui_strings.csv`.
Preserve UiAccess's immutable Theme baseline and independent interface/text sizes.
Support keyboard focus, visible labels for key actions, colour-plus-text urgency
and contrast across both bright terrain and dark water. Preserve camera suppression
while typing, custom bindings and existing display Apply/Keep/Revert semantics.

Review actual Metal/Mobile captures for idle/build/journal/urgent/decision/map/
storage/overlay states, plus shared-theme menu, world and campaign screens.
Compare the same designated city and camera with the baseline. Technical test
success and visual acceptance are reported separately.

Acceptance: no overlap, clipped Russian text, inaccessible controls, click-through
under panels, lost drafts or material matched-view performance regression.

## Validation and completion gates

- Only `Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez` for city testing; use disposable
  preferences and in-memory edits. Verify save/settings hashes before and after.
- Layout matrix: EN/RU at 1280×720, 1440×900 and 1920×1080, default and maximum
  interface/text sizes, plus mixed independent scales and resize while reading.
- Extend `tools/review_map_notifications.py` for quiet delivery, exactly-once
  acknowledgement, grouped history, overflow, active reading, unknown events,
  urgent queue and decision callbacks. Replace superseded three-chip assertions
  with the new policy assertions; retain semantic history/decision safeguards.
- Run `tools/review_status_ui.py --checks --lang en` and `ru`, the focused
  context/HUD checks, map-notification checks and `--native-map`, and
  `validate_ui_text.gd`. Exercise construction, storage/trade drafts, overlays,
  controls and display review suites affected by layout or shared styling.
- Run the visible pilot validation in both launch languages for final integration;
  distinguish pre-existing failures from regressions rather than claiming broad
  parity from historical check counts.
- Verify idle thumbnail viewport shutdown and matched camera frame-time/memory
  comparisons for closed HUD, open catalog and long journal. Investigate a median
  frame-time increase over 5% across repeated matched runs; this target is not a
  minimum-Mac performance certification.
- If C++ changes become necessary, use the extension build/finalization helper;
  run the relevant embedded/event regressions. Simulation changes additionally
  require rebuilt/signed native reference and replay parity per repository rules.
- At each completed stage update `godot/README.md`, `docs/GODOT_MIGRATION.md`,
  `docs/GODOT_VALIDATION.md` and `docs/GODOT_INTERFACE.md` together. Clearly mark
  proposed, implemented, verified and visually accepted work.

## Delivery checkpoints

1. Reviewable in-game Aegean shell with existing commands intact.
2. Quiet journal and safe decisions, with focused regression evidence.
3. Refined construction/inspectors and full EN/RU layout evidence.

Implement in this order. Reuse the current interface rather than replacing its
controller. Do not broaden into new gameplay systems or unrelated art work.
