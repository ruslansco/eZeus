# City clarity and shared art finish — 7 October 2026

These are two bounded implementation passes of the user's city-understanding and art
priorities. They add actionable help and a manual settlement guide alongside
bounded presentation refinements. It does not change construction, staffing,
production, housing, routes, simulation RNG or saves. Current counts and captures
are recorded in `GODOT_VALIDATION.md`.

## Second pass: construction, foundations and onboarding

`building_construction.gd` checks every part of eligible sanctuary/pyramid models
before opting into the reveal. Opaque, untextured vertex-palette parts retain their
base colour, roughness and metallic finish in the reveal shader. Any unsupported
texture/VAT/transparent/emissive override keeps the asset on its original growth
path. Foundation-only court slabs are excluded. Compatible stages retain full
mesh proportions; `grow` becomes a world-height cutoff carried in MultiMesh custom
blue/alpha, while red/green remain the original work flag/phase. The full transform
is prepared after checking the template's compatibility. Metadata-only cutoff
changes upload instance data; they do not rebuild geometry or invent progress.
The shared material guard also excludes normal/roughness/metal/AO/height maps and
clearcoat/rim features, including a normal-map-only material with no albedo texture.

`building_sites.gd` caches base hulls from the lowest static mesh band, overlaps
the actual base contact surface and samples existing triangulated terrain. Skirts
are confined to the native footprint and street setback, skip roads/water/missing
cells and gaps above 0.88 tile, and add no faces when the base meets level ground.
Native transforms/heights, terrain, physics/navigation and GLB art are unchanged.
Gates, water structures, animals and starter earth lots are excluded. Timber posts,
rails and braces fit inside unfinished monument lots, rise only with their current
height and disappear on completion. Both details cache by placement/growth and
surface revision, with dirty 32-tile section rebuilds rather than frame updates.

Construction advice uses the existing monument observation: explicit halt first,
road access next, exact remaining material quantities, then assigned builders.
Warning navigation accepts the native far corner of a large pyramid piece when
the current ID and rendered footprint still contain it; it inspects that native
tile rather than assuming every registered object is at its presentation origin.

New-game Begin marks an optional guide offer; after the loading surface dismisses,
an empty city offers it if Finish guide has not already been chosen. Finishing
stores only the interface preference. The guide remains available from ? and
the Game menu. It neither resumes the simulation nor certifies victory.

The first replay fixture failed to register its temporary save directory, allowing
a comparison of rejected opens. It now asserts successful loads. The corrected
test verifies unchanged same-session state/serialized bytes after twenty attention
reads, then matching seeded gameplay digests/sections after sixty ticks and zero
worker-thread RNG. Binary save hashes after separate loads can differ and are
recorded without claiming cross-load byte determinism.

## City attention and advice

Open the header's **?** button or **Game → City views → City attention** (the card's
**Issues** tab). The shared Theme card filters production, workers, roads, housing and construction,
with eight buildings per page. Click a warning to move the camera and open the
actual native inspector. The target's session ID and footprint are checked
against the current building index before selection; stale targets refresh the
list. A road filter leads with road advice even if the building also lacks staff.

`city_attention` is a separate read-only native observation. It waits for board
work and visits the current city's `allBuildings()` list, including static roads;
the timed `buildings()` list excludes them. It never selects an inspector, changes
an edit token, consumes an event/voice, draws randomness or advances gameplay.
Only current-player objects with an emitted presentation record become clickable
warning targets. Internal owners without a selectable rendered footprint are
excluded; composite-owner navigation remains future coverage.

Warnings use native fire, shutdown, employment, road access, processor inputs,
collector targets, current housing support and sanctuary/pyramid progress.
Producer full output or overflow is labelled **Goods awaiting collection** as a
stock observation, rather than claiming the native production state changed.
Unmet optional house upgrades do not become decline warnings. The inspector
retains its native house card, exact requirements, supply/service hints and editor
drafts; production stop reasons remain authoritative. Worker advice shows actual
vacancies, input advice shows the exact next-batch shortfall, and road advice
explains that access requires an edge connection rather than a corner contact.

The report is queried only while help is visible, at most once every five seconds,
or on explicit refresh/open. Pointer reading holds automatic list replacement;
identical observations keep controls stable. Hidden help performs no polling.
The panel is non-modal and uses existing overlays without duplicate polling.
Opening it from the Game menu restores the previous pause and command hold.
Escape and card right-click fold it without answering a decision or pausing.
Popup menu rebuilds retain their right-click helper; retranslation must not
delete it along with replaced submenus.

## First-settlement guide

Select the **Guide** tab in the help card, or its City views menu item. Six
short steps explain a compact road, common housing, water, food through a granary
and agora vendor, maintenance, and gradual growth with staffed jobs. Relevant-view
buttons use the existing native road/water/supply/hazard/industry views. The guide
stays open while the player builds. Each step advances explicitly; it never builds,
answers an event or completes an episode. Adventure resources/objectives may differ.

Native observations mark conditions already present: roads, residents, supplied
common houses, staffed road-connected maintenance and employment. The final marker
also requires food, water and maintenance and no reported vacancies, road losses
or housing decline. These are advisory observations, not a complete connectivity,
budget or sustained food-balance proof. A fresh-settlement playthrough and broader
adventure coverage remain acceptance work. EN/RU text and independent interface
and text scaling use the existing CSV and live Theme.

### Stepper layout — 8 October 2026

The user found the first guide card confusing (a dropdown as its title, plain text
for status and buttons, a fixed tall card with empty space over the minimap). The
card now follows the usual objective-tracker pattern:

- **Issues | Guide** segmented tabs replace the dropdown (full names in tooltips).
  Collapse folds the card to one line (the current step and "Step n of 6", or the
  warning count); clicking that line or the button expands it. × closes it.
- The guide has a title, "n of 6 done" and a six-segment progress bar (green done,
  gold current). All six steps are listed with done/current/upcoming markers; any
  row opens that step. Only the current step expands into an inset card.
- The current step card holds the shortened advice, a full-width status strip
  ("Done" green / "Not yet" teal) with a live native count (road tiles, residents,
  homes with water/food, working maintenance offices, workers employed), and for
  the last step what still holds the settlement back (missing basics, vacant jobs,
  roadless buildings, declining homes from the same report).
- Actions: a Build button, wearing the dock button's own illustration, presses the
  step's dock tool (road, housing) or opens its build category (Health and water;
  Agriculture for food; Administration and security), or opens the objectives on
  the last step. A view button named after
  the overlay toggles it and follows overlay changes made elsewhere. Back is a
  quiet link; Next step / Finish guide is the one gold primary button.
- While the current step is not done, the card draws a pulsing outline (static
  with Reduce interface motion) round the dock tool/category that builds it. It
  stops when the step is done, the tool is active or the category's tray is open.
  The outline is drawn by the pass-through help layer; it takes no input.
- The guide opens once on the first step this city has not done; afterwards it
  stays on the step the player chose. Steps still advance only by Next, Back or a
  click on a step — never automatically, so text does not move while being read.
- The footer's "Don't offer again" link stores the same preference as Finish guide.
  The adventure caveat lives in the step texts (food "this adventure allows",
  "check your objectives") instead of a separate footnote.
- The card is sized to its content and aligned with the header's left edge. It
  stays above the time controls, and above the open minimap whenever the whole card
  fits there; otherwise (small windows, enlarged text) it uses the height down to
  the time controls and scrolls with its own visible `GuideScrollBar` (the base
  Theme scroll bars have zero-width styles).

Styles are the `Guide*` variations in `build_ui_theme.gd`; regenerate only them
with `-- --guide-only`. Icons `guide_done/current/todo.svg` and `next.svg` are
original drawings (see `ui/icons/README.md`).

### Issues tab — 8 October 2026

The Issues tab now matches the guide. Under the "City attention" title (with a
refresh icon button) and its hint:

- **Filter pills** (All, Production, Workers, Roads, Housing, Construction) replace
  the dropdown and show how many warnings each holds; empty ones are dimmed and
  disabled unless chosen.
- **One card per warning**: a severity edge and tinted icon (red: on fire, housing
  decline; amber: no workers, no road, paused industry, no resource, waiting for
  input; teal: understaffed, goods awaiting collection, construction), the building
  name, the status in the severity colour, the existing advice in a muted smaller
  style, tags for the building's other conditions and a chevron. A transparent
  `IssueCardButton` lies over the whole card (last child of the PanelContainer), so
  any part of the card opens the building and the card lights on hover/focus. The
  button carries the `attention_item` meta; validators find it recursively.
- A **pager** ("1–8 of 109" between ‹ ›) appears only with more than eight warnings.
  The housing footnote shows only when a housing card is on the page.
- An **empty state** with a green check: "Nothing needs attention right now." (or
  "No issues in this category." under a filter).

Filtering, the fire → housing → position order, eight per page, `status_for`,
stale-target refresh through `focus_attention`, five-second visible polling and
pointer holds are unchanged. Styles are `Issue*` variations, regenerated together
with `Guide*` by `-- --guide-only`; `refresh.svg` and `previous.svg` are new icons.

## Shared finish, contact and work motion

`building_finish.gd` applies a cached procedural stone/plaster finish to eligible
everyday buildings, housing, sanctuaries and defences. Pale low-chroma vertex
colours receive restrained veins/grain and shared stone roughness. Detail fades
with screen derivatives; continuous grain avoids hash-cell shimmer. Saturated
roofs/wood/foliage keep their palette. Metal, textures, emissive/transparent parts,
VAT overrides and citizen/monster adapters are preserved. The same static-model
factory covers placement ghosts and thumbnail models. No GLB, UV, geometry, LOD
or source art is regenerated. This is a subtle runtime finish, not painted PBR baking.

Building activity uses bounded cubic interpolation between the same eight authored
poses, with periodic neighbours and component clamping to prevent overshoot.
Inactive poses, native work flags and gameplay clock still drive all motion. No
new animation state, skeleton or per-building process is added. Rest-normal
approximation and the existing workers' anatomical quality remain limitations.

Human walk/idle root support samples four small sole-area offsets near native
slopes, with a maximum 0.065-tile lift. A 1/32-tile position bucket, heading and
surface revision cache avoid repeat queries; level ground adds none. Perched
guards, gods, boats and combat retain their anchors. Native coordinates and planar
stride remain untouched. This reduces ground penetration; independently planted
feet and slope IK remain future work. Bounded adaptive building skirts are now
implemented in the second pass above; broader foundation art still needs review.

Unfinished monument inspectors now show native percentage progress in a bar.
Compatible rising geometry now uses the reveal above; construction timing remains. Ordinary instantly
placed buildings do not gain invented construction stages.

## Original soundscape prototype

**Game → Sound → Original lyre score and countryside ambience** is opt-in and
defaults off. `tools/generate_original_soundscape.py` creates a 48-second Dorian
plucked-string/flute score and synthetic wind/bird ambience, without external
samples or melodies. WAVs load through Godot resources and retain bus/mute/volume
controls. Battle music, effects and voices keep their current recordings.
The Sound dialog bounds its content scroll so large text keeps Done visible.
`assets/audio/original/PROVENANCE.json` records the generator and output hashes.
Listening acceptance, mastering, a longer varied score and final licensing/package
evidence remain pending. This prototype is not a complete replacement soundtrack.

## Build and verification

The development extension builder outputs to a staging directory. The dependency
helper signs a new temporary inode, then atomically replaces the installed library;
live processes retain their earlier mapping. Relaunch the game to load the new
extension and scripts. Do not re-sign or truncate a library mapped by the user's
running game.

Run owned visible reviews sequentially with temporary saves/preferences:

```sh
python3 tools/review_city_clarity.py --lang en
python3 tools/review_city_clarity.py --lang ru
python3 tools/review_status_ui.py --checks --lang en
python3 tools/review_status_ui.py --checks --lang ru
python3 tools/review_escape_menu.py --lang en
python3 tools/review_escape_menu.py --lang ru
```

Retain embedded simulation, building activity, camera cache, audio and translation
checks. The clarity review compares seeded native replay with/without reports,
checks live inspector agreement and target validity, constructs/undoes a real
roadless building in a disposable city, verifies enlarged layouts, real materials,
work holds, slope caches, resource audio and a normal return to the start menu.
Paired moving-view renderer measurements report CPU/draw counts only when GPU
timing is unavailable. Sustained minimum-Mac GPU/frame pacing remains unverified.

Second-pass checks also exercise real native empty-land road/housing/service
construction in a disposable designated copy, compatible/fallback growth,
bounded supports, timber removal, per-building GPU custom-data readback and guide
completion preferences. `city-sites-<lang>-stages.png` shows 25/65/100% render-only
stage fixtures; `-support.png` uses an isolated analytical slope with a real house
mesh. Neither fixture adds a native entity. Immigration, complete food distribution
and sustained household-budget success still require a full first-settlement test.
