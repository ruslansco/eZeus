# Normal campaign menu and Continue — 10 October 2026

Use **Launch Godot 3D.command → New game**. **First Light Harbor**, **Bronze
River**, **Stonewatch**, **Sunlit Terraces** and **Tidebound Covenant** appear first.
Each card shows its description, default difficulty and three selectable chapter
previews. Objectives precede a collapsible full briefing.
Previewing a later chapter does not skip gameplay; Start/Begin starts chapter one.
The retained original adventure/editor catalog is available below the new campaigns.

**Continue** identifies the latest saved campaign and chapter for the selected
leader. **Load game** labels the campaign/chapter as well as the save name, so
two files called `autosave 1` can be distinguished. New games retain their authored
initial camera focus; saved camera, facing, speed and native pause-on-load remain.

## Save continuity

New saves and native retry checkpoints use
`user://saves/<leader>/.campaigns/campaign-<content-name-hash>/`. The content name
is the durable native campaign identity, independent of translated title or
chapter. Both manual saves and autosaves share this scope. Changing campaigns
does not replace another campaign's autosave. Ordinary original adventures also
use separate slots when started through the normal menu. Chapter changes keep
the same slot; native payload and presentation-trailer versions are unchanged.

The catalog merges the selected leader's scoped and earlier flat saves, plus
historical root saves. Existing launcher profiles for all five authored campaigns
are listed in place, including the preserved single-chapter First Light version.
Select the previous leader through **Change leader** if needed. No files are
moved, migrated or silently recovered. Continue loads an immutable checked copy;
subsequent saves from the normal menu use the local leader/campaign slot.
Deletion is disabled for externally discovered profiles and symlinked leaders;
explicit deletion of an owned local leader handles its nested campaign folders.

The previous First Light prototype is installed as a hidden compatibility entry
for old saves. It is omitted from normal New game to distinguish the current
three-chapter campaign, while the editor and earlier launchers remain available.

## Native observations and local content

`adventure_preview` now includes all parent chapter templates with their own
native titles, prose, objective wording and difficulty. Date previews expose
relative native durations instead of promising a future chapter's calendar date.
The templates are copied for date wording; no episode is started or fulfilled.

Read-only `save_info` parses at most a 1 MiB native prefix and caps identity strings
at 4 KiB. It returns campaign identity/chapter as an **informational hint**, never
proof of validity. Guarded-summary caches include the stored checksum so same-size,
same-second replacements refresh; footerless summaries are read afresh. Full
integrity and isolated native parsing remain mandatory before loading. The probe's
actual loaded episode, rather than the display hint, selects the write scope.
An unowned information reader's cleanup no longer clears a running city's audio
sinks. Native rules/RNG, serialization, speed/tick semantics and art geometry remain.

`tools/install_development_campaigns.py` installs only the verified native export,
new EN/RU text and attribution for all five current campaigns and the preserved
prototype. Existing edited destinations are refused; owned older installs are
archived only after a fresh copy verifies. The private index is published atomically.
Re-run this explicit installer after authoring a new export to refresh the normal
catalog. Export/source/player originals remain intact. Installed adaptations are
ignored by Git and retained as `needs_evidence / ships_in_release=false`.

The five 960×360 menu images are static Godot views of copied ordinary-playthrough
checkpoints. There are no live card viewports. Imported textures are preferred;
new private PNG captures also display before editor import through the same
bounded image cache. The review verifies the actual image selected for all five
cards. HUD/aura presentation is hidden for capture; the source cities, models
and simulation remain intact. File/source hashes
and unresolved retained-input rights are in `campaign-library-art.provenance.json`.

## Verification and limits

Use `tools/review_campaign_library.py --lang en` and then `--lang ru`; run visible
reviews sequentially with scratch preferences. Expanded final Metal runs pass **137 each**:
all five normal entries, all chapter previews, disclosure/localization, default
difficulty, saved-progress labels, same-name autosave isolation, real Start/Begin
at chapter one, authored focus, enlarged UI/text bounds, actual Continue/Load of
chapters two/three, Tidebound Covenant’s local timber/science tools without trade,
Sunlit Terraces’ Greek culture/vineyard tools, Stonewatch’s final tools and retained
native hero gate, native staffing/build permissions and treasury/pause, previous
profile continuation/new local saves and source-byte preservation. Progression
checkpoints use explicit structural fixture wins, not human or natural playthroughs.
Earlier campaign ordinary-playthrough evidence is retained separately.

Retained adventure previews pass **256 checks / 58 previews**, native editor **64**,
embedded **101**, filesystem save transactions **19**, and EN/RU headless save
reliability **36 each**. Save tests retain facing/camera/speed, full isolated load
checks, corrupt/legacy files, explicit backup recovery and cancellation restoration.
The menu's old three-page Settings assertion was updated to include the existing
Graphics page. Main-menu navigation/leader/settings checks pass **30 EN / 30 RU**.

Reports/captures are under
`build-content-research/campaign-library/review-<lang>-visible/latest.json`.
These tests protect the designated city, actual user/previous-launcher profiles,
campaign exports, numbers and preferences; no live game or Blender is stopped.
Both Mac native targets are signed on new inodes. The updated Windows core compiles
and six DLLs pass x64/import closure; frozen Windows ZIPs are unchanged and do not
provide the current five-campaign library. Actual Windows/clean-Mac packaging, minimum
machines, human playtesting and commercial content permissions remain pending.

Stonewatch’s native battle/hero progression and ordinary-playthrough evidence are
recorded separately in [STONEWATCH.md](STONEWATCH.md). The earlier three-campaign review passed 86 per language; its current evidence
is also recorded in the validation document.
