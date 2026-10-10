# Desktop performance and platform preparation — 8 October 2026

The user chose a modern desktop hardware floor rather than lowering the art for
an older 1 GB graphics card. The final implementation offers **Balanced** and
**High** under Game settings → Graphics settings, also reachable from the start
menu gear. Both retain full 3D resolution, 4× MSAA, sun shadows, original models,
UVs and native crowd/map coverage. Balanced matches the previous city appearance.
High uses more detailed distant meshes and farther shadows/ground foliage.

Changes preview immediately. Apply stores only the graphics section in per-user
settings; Cancel/Escape/removal restores the preceding preset. No world/model
rebuild is required. Display preview, interface/text sizes, camera picking,
inspector drafts, native pause/decision callbacks and simulation timing remain
separate and unchanged. Two sun-shadow cascades stay in use at both levels.

The retained desktop renderer uses Metal on Mac and Direct3D 12 on Windows, with
Godot's Vulkan driver fallback available on Windows. Automatic fallback to the
older OpenGL renderer is disabled. The earlier Low/Compatibility experiment was
removed following the user's direction; it is not part of the release path.
Godot documents this modern driver policy in its
[renderer overview](https://docs.godotengine.org/en/4.6/tutorials/rendering/renderers.html)
and [project settings](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html#class-projectsettings-property-rendering-rendering-device-driver-windows).
The existing Mobile rendering method remains because earlier matched measurements
favored it; changing the API does not require switching to Forward+.

## Proposed hardware targets

These are **engineering targets**, not measured Steam minimum requirements. There
is no universal 2026 game specification. Qualify actual machines at the stated
resolution and quality before publishing a requirement or platform badge.

| Platform | Proposed minimum test target | Proposed recommended test target |
| --- | --- | --- |
| Windows | Windows 11 x64; Core i5-8400 / Ryzen 3 3100 class CPU; 16 GB RAM; GTX 1650 / equivalent 4 GB GPU; SSD | Core i5-12400 / Ryzen 5 5600 class CPU; 16 GB RAM; RTX 3060 / RX 6600 class GPU; SSD |
| Mac | Apple Silicon M1; 8 GB unified memory; intended macOS 14+; SSD | M2 or newer; 16 GB unified memory; SSD |

Minimum acceptance target: 1080p Balanced, at least 30 FPS with p95 frame time
under 33.3 ms in the designated large city. Recommended target: 1080p Balanced,
60 FPS with p95 under 16.7 ms. Examine p99 and long frames as well as averages.
Proposed working budgets are under 2 GB reported graphics memory and under 4 GB
resident game memory; sample transient load-probe/package peaks separately.
These budgets and CPU/GPU examples must be revised from real Windows/minimum-Mac
measurements. Storage size comes from the final independent-content package.

Windows launch, minimum-Mac hardware and older macOS are **unverified**. Linux and
Steam Deck are future candidates, not advertised platforms. Modern integrated
graphics can qualify on performance; the old HP desktop is no longer the target.

The runtime audit found all five installed Mac dylibs currently encode **macOS
26.0**, and the SDL image/font/audio helpers still reference Homebrew codec/font
libraries. A macOS 14 claim would therefore be incorrect for this installation.
Rebuild/bundle pinned dependencies and the extension for an explicit deployment
target, then launch without Homebrew on that OS before accepting the proposed
floor. Do not patch binary version metadata to pretend compatibility.

## Repeatable owned performance run

Run from the repository, with the user's game/Blender left running only if their
possible effect on measurements is recorded:

```sh
python3 tools/review_release_performance.py
python3 tools/review_release_performance.py --phase-seconds 10 --soak-minutes 30
python3 tools/review_release_performance.py --headless --phase-seconds 1
python3 tools/audit_platform_runtime.py --output godot/captures/platform-runtime-audit.json
```

The default visible run is 1920×1080 with VSync/frame cap disabled, a fixed seed,
and the designated 25,992-tile city copied into scratch storage. It warms drawing
before sampling. Balanced/High use matched stationary/near-pan/wide-pan views.
Separate phases exercise normal/max native speed, a real native fire centered in
the view, and six guarded reload transitions, including three repeated reloads
with matching gameplay digests. Only the owned test simulation enables the fire
command; no fire is started in the user's game.

The JSON report records actual rendering driver/method, CPU/GPU identity, window
size, native counts, p50/p95/p99/max frame intervals, frames over 50 ms, separate
core/snapshot and city-script costs, draw calls/primitives, graphics memory,
native diagnostics, reload durations and the owned process's sampled resident
memory. Zero backend GPU timing is reported unavailable. Headless numbers do not
measure graphics performance. The wrapper rejects engine/script errors and
records `harness_verified`; a script's internal PASS alone is insufficient.

Saves, player preferences and designated source are fingerprinted before/after;
all temporary saves/preferences/load staging are isolated. Autosave is disabled.
Hardware input is shielded in the owned window. Native 20 Hz stepping, speed
semantics, routes, RNG and pending decisions are retained. A required decision or
episode block stops its running phase and is recorded; no answer is invented.
The designated fixture reaches a decision quickly at maximum speed, so this
run does not qualify a full long session. Conduct a separate human playthrough
with normal decisions and longer save/load/disaster coverage before release.

## Windows development build and test

This prepares a Windows build **on Windows**; no Windows DLL was cross-compiled
or executed on the Mac. The user has another Dell laptop available. Follow
[Windows testing](WINDOWS_TESTING.md). CMake now selects platform SDL targets,
stages transitive DLL targets and emits the extension into a separate folder.
The POSIX-only random trace and digest process ID have guarded Windows paths.
The same pinned godot-cpp/API and SDL source releases remain in use.

The tracked `presentation/godot/ezeus.gdextension` is installed into the ignored
runtime folder by both build helpers. It declares Mac arm64 and Windows x64;
declaration is not proof the platform works. The Mac extension was rebuilt,
signed on a new inode and installed atomically, leaving the live mapping intact.

Audit metadata and checked builds are preparation. Standalone dependency closure,
oldest OS, installer/export package, signing/notarization, full campaign coverage,
cross-platform save/replay behavior and real minimum-hardware performance still
require acceptance. Independent-content and source/license release gates remain
in the production roadmap.
