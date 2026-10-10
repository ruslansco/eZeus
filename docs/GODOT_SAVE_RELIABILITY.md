# Save reliability — 8 October 2026

The user approved player-progress protection as the next release milestone.
The Godot front end retains native `.ez` gameplay serialization, with a checked
presentation trailer and recoverable file commits. No personal save is migrated
or overwritten merely by updating the application.

## Save transaction

`presentation/esavestore.h` owns the portable transaction. A per-name writer lock
refuses simultaneous commits. A dead process's owner lock can be reclaimed;
unknown/live owners are left intact. A unique staging file is written, sealed,
flushed/synced and independently checked before replacement. POSIX uses same-folder
rename and directory sync; the Windows branch uses replace-existing/write-through
replacement. The Windows implementation has not been executed in this milestone.

Two checked previous generations are retained as `.ez.bak1` and `.ez.bak2`.
An imported footerless file is preserved as `.ez.bak0` without displacing checked
generations. A detected damaged primary is kept as `.ez.damaged`. Failure before
the final replacement keeps the committed primary; complete staged files remain
available for recovery. A partial write that returns an error is removed. Actual
power loss can leave a partial stage, which the loader refuses. Success is reported
only after replacement; failure to confirm the final directory sync is explicitly
distinguished from a file that was never committed.

The native `eZeus.ez` payload/version remain unchanged. A version-1 trailer carries
presentation records and CRC32 over payload plus metadata. Explicit lengths and
marker/version checks reject damaged or unsupported protected saves. CRC32 detects
accidental changes; it is not authentication. Native reference readers may ignore
the trailer; saving again in an older/native application can remove presentation
records, although gameplay compatibility is retained.

## Durable presentation choices

Facing uses `(board, city, native type, seed, x, y, width, height)` rather than a
pointer or session presentation ID. Parent episodes share board `-1`, and each
colony uses its native episode index. Records remain through episode handoffs;
current-board deleted/replaced entries are pruned on saving and cannot apply to
another native identity at the same address. Old saves without this metadata keep
their existing automatic/native facing defaults.

The trailer also stores selected game speed and optional camera tile coordinates,
yaw, pitch and distance. The actual city scene restores the view against its map
bounds and terrain surface. Main manual/quicksave and configured autosave paths
capture the current view. Existing global language, display, interface, sound and
controls preferences remain per user. Loaded cities still start paused, and native
pending decisions continue to block saving; no callback or outcome is invented.

## Load preflight and recovery

`save_loader.gd` creates an immutable private copy under the application's staging
directory. An owned headless Godot process runs `save_probe.gd`, checks the trailer,
fully reads the native city and returns a hash/result without advancing ticks,
writing autosaves/settings or answering decisions. The parent city/menu remains
intact while checking. Only the exact proven copy becomes the next scene's input;
its staging files are removed after consumption. Cancellation/timeout terminates
only the loader's own child. The native process never starts an SDL view/window.

The shared save catalog discovers primary, backup and interrupted-first-save
families. It labels recovery availability without asserting that every copy is
valid. A readable backup or completed pending save requires an explicit recovery
choice and displays its local file time. The damaged/original source is retained;
recovering loads the private copy rather than repairing a source silently. When
a readable primary and newer pending copy exist, the player can keep the saved
version. An unreadable file cannot trigger the previous test-city fallback.
Failure/cancellation restores the current game's previous pause and command hold.

Native file reads now bound primitive, string and vector requests against remaining
bytes and reject invalid board dimensions before allocation. Remaining byte counts
are tracked in memory, avoiding a file-position query for every primitive. Existing
memory-backed compatibility readers retain their interface. Legacy malformed enum
or object graphs may still fail inside the isolated probe; the active city is not
used to parse them. Older footerless saves cannot provide checksum guarantees.

## Verification and limits

Use `tools/test_save_store.py` for real temporary-filesystem fault/rotation/lock,
checksum, damaged-primary and legacy/version checks. Use sequential owned
`tools/review_save_reliability.py --lang en` / `ru`, with `--headless` for its dummy
renderer variant, for native round trips, presentation restoration, recovery UI,
interrupted first saves, truncated legacy parsing and active-city preservation.
Headless GLB warming runs on the main thread because the dummy renderer does not
provide safe parallel resource-ID initialization. Metal retains threaded warming.

Retain `validate_saves.gd`, owned loading-screen reviews, embedded/translation
checks and a designated-derived native reference round trip. Tests register their
temporary save directory and assert a successfully loaded snapshot. File counts
distinguish primary saves from recovery artifacts. Current evidence/counts and
captures are in `GODOT_VALIDATION.md`.

Physical power-loss testing, Windows filesystem execution, cloud synchronization,
network/removable filesystems, long-session/large-save profiling and whole-campaign
upgrade migrations remain release acceptance work. Locks without a readable owner
record are conservative; they are not automatically deleted. Pending stage and
damaged evidence cleanup/retention controls are future housekeeping work.
