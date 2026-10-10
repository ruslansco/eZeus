# Windows x64 development test

## Prepared private package — 8 October 2026

A MinGW-w64/GCC Windows x64 build is now compiled and linked on the Mac. The
extension and five supporting DLLs pass architecture/import checks, including
the extra stack-protection runtime. A private transfer kit bundles them with the
checksum-verified official Godot 4.6.3 runtime, existing development resources,
only the designated test city, engine source and retained license/attribution
records. Windows execution is still unverified; MSVC remains a separate build path.

For the Dell, copy/extract the prepared **CityBuilder** folder to `C:\CityBuilder`.
Double-click **Run checks.cmd**, then return **Dell-test-results.zip**.
Double-click **Play.cmd** for normal play. No compiler or Python is needed on
the Dell for this package. Prepared runtime resources avoid an editor import;
run from the extracted folder. Editor/pipeline state and preferences are excluded.
See [cross-build evidence](WINDOWS_CROSS_BUILD.md). This is a private development
test, not a cleared public/Steam release or a validated minimum-spec claim.

The original MSVC path below is prepared and parser-checked on Mac. **MSVC
compilation and Windows execution have not yet been verified.** Use the Dell laptop to establish
evidence before setting Steam requirements. Ordinary Windows rendering uses
Direct3D 12 with Vulkan fallback; the full-resolution Balanced art is the baseline.

## Prepare the PC

Use Windows 11 x64. Install Visual Studio 2022 Build Tools with **Desktop
development with C++**, an x64 compiler and Windows SDK; CMake 3.25+; Git; Python
3.9+; and the standard Windows x64 **Godot 4.6.3** executable. Open Developer
PowerShell for VS 2022. The scripts fetch pinned open-source build dependencies;
the first compilation may take some time.

Create a private development workspace such as `C:\CityBuilder\eZeus`, with the
same parent resource layout as this Mac workspace. Use ASCII paths without `&`
for the older SDL header-copy rule. Copy engine source, fonts/text, native
adventures and `godot/` source/assets—including generated GLBs and VAT derivatives.
The parent `DATA`, `Model`, `Audio`, `Adventures` folders still serve this
development build. Retain source/license/provenance files. For automated city
testing, copy only `eZeus\Save\Hippodamus\CLAUDE-TESTING-ADVENTURE.ez`.

Omit Mac application bundles/dylibs, existing build directories, captures and
`godot\.godot` caches; Windows imports its own cache. This is a private development
copy, not a standalone shipping package. The project still needs its development
resources. Do not infer a distributable independent-content package from this copy.

## Build and check

From `C:\CityBuilder\eZeus`, replace the Godot path below with the executable:

```powershell
.\tools\build_godot_windows.ps1 -Godot C:\Tools\Godot\Godot_v4.6.3-stable_win64.exe -Jobs 4
python .\tools\audit_platform_runtime.py --platform windows --output godot\captures\windows-artifact-audit.json
.\tools\test_windows_build.ps1 -Godot C:\Tools\Godot\Godot_v4.6.3-stable_win64.exe
```

The helper checks Godot's version and the pinned godot-cpp revision, builds the
Release extension with MSVC x64 and stages the DLLs separately. Existing binding
checkouts at a different revision are preserved. DLL replacement fails safely if
a running game has locked the file; close that Windows game before installing.
The script does not terminate another process. Architecture audit is a file
check; actual launch remains necessary.

The test first performs the scratch-only save/recovery review, then the visible
1080p large-city performance run. It restores no personal saves and writes no
player preferences. Return these files for review:

- `godot\captures\release-performance-mobile.json` and `.log`
- `godot\captures\save-reliability-en-headless-engine.log`
- `godot\captures\windows-artifact-audit.json`
- `build-godot-windows\staged-extension\dll-manifest.json`

The performance report identifies the actual GPU/CPU/driver and RAM usage, so no
manual hardware guess is required. Keep compilation/background benchmarks closed
during measurement. Record power mode, display resolution and whether the laptop
was plugged in. A short pass is not long-session qualification; a native required
decision can stop max-speed/soak measurements without being answered automatically.

## Play normally

```powershell
& C:\Tools\Godot\Godot_v4.6.3-stable_win64.exe --path .\godot --rendering-method mobile
```

Choose Balanced in Game settings → Graphics settings and test camera movement,
construction, population growth, trade, native decisions/Postpone, save/load,
fullscreen and audio in English/Russian. Test the new DLL and all transitive
dependencies without development-tool folders in the runtime search path before
accepting a standalone package. Do not claim cross-platform replay/save parity
from a single local run; preserve the same gameplay state for a separate comparison.
# Latest private handoff — 9 October 2026

Use **CityBuilder-Windows-Chapters-2026-10-09.zip** for the current campaign/core.
It includes the three First Light chapters and the ordinary episode permission,
BC date-goal and nonzero export-capacity fixes. Extract, run **Run checks.cmd**,
then **Play.cmd → New game → First Light Harbor**. Return **Dell-test-results.zip**.
The prior kit is retained; current static import/package checks pass but no Dell
execution is claimed. See `FIRST_LIGHT_CHAPTERS.md` for scenario scope and hashes.
