# Private Windows x64 cross-build — 8 October 2026

The Windows extension and SDL2 helpers now compile/link on the Mac using a
private MinGW-w64 14.0.0 / GCC 16.2.0 toolchain. This avoids requiring a compiler
or Python on the Dell. The build is **not Windows execution evidence**; the
Windows CPU/GPU/OS, native save/recovery and visible graphics still need the Dell.

## Evidence and isolation

- Verified official Homebrew arm64-Tahoe compiler/dependency bottles using the
  formula API's SHA256 records. These are extracted into `build-windows-cross/`,
  not installed into Homebrew. The original bottles/hashes remain intact.
- Relocated and signed only private native compiler copies. Restored the normal
  bottle prefix placeholders in target COFF/archive data, preserving original
  object offsets; native Mach-O files use install-name relocation instead.
- A compiler smoke test creates an x64 Windows executable using C++17 vectors
  and threads. CMake uses a short, private source snapshot and separate build
  directory; original code/assets and the running Mac game are preserved.
- Pinned SDL2 2.32.10, image 2.8.12, ttf 2.24.0, mixer 2.8.2 and the existing
  godot-cpp revision/API. Codec libraries are linked into the helper DLLs where
  possible. The remaining x64 `libssp-0.dll` is included; stack protection is
  retained. The C++ runtime is linked statically through godot-cpp's policy.
- Audited the six x64 DLLs' PE headers/import tables and checked the native
  `ezeus_library_init` export. No unresolved non-system DLL import remains in
  the prepared runtime folder. Windows system/API-set imports still depend on
  the actual target OS. This static audit does not execute the DLLs.
- The official matching Windows Godot 4.6.3 ZIP is verified against the upstream
  SHA512 list and retained unchanged. All files in that ZIP, including its
  console launcher/driver components, are packaged.

`build-windows-cross/toolchain-metadata/`, `configure.log`, `build.log`, PE dumps,
official checksums and `godot/captures/windows-compiled-audit.json` retain local
evidence. Build directories and private packages are ignored by Git.

The cross-build exposed and fixed portable header includes, missing fixed-width
integer headers, a Windows save timestamp branch, Windows SDK macro collisions,
MinGW's DLL prefix and CMake's quoting of paths containing ampersands. Native
rules, RNG, tick sequence, serialization layout, art/UVs/LODs and quality remain
unchanged. The Mac extension is separately rebuilt, signed on a new inode and
atomically installed; native reference executable rebuilding is not required.

## Preparing another private build

The toolchain metadata records lock compiler/version/bottle hashes. Set a CMake
Windows toolchain file with x86_64-w64-mingw32 GCC/G++, windres, target-only library/
include/package searches and the relocated GCC runtime search directory. Preserve
the dependency pins and use a source snapshot containing all CMake-listed code
and resources. Build only `ezeus_godot` with Release/Ninja. Never point cross-build
output at the live Mac runtime folder.

After compiling, include all non-system DLL imports, then:

```sh
python3 tools/audit_platform_runtime.py --platform windows --directory build-windows-cross/staged-extension --require-ready
python3 tools/package_private_windows_test.py --dll-directory build-windows-cross/staged-extension --godot-archive build-windows-cross/downloads/Godot_v4.6.3-stable_win64.exe.zip --godot-checksums build-windows-cross/downloads/godot-SHA512-SUMS.txt --dependency-source /path/to/the/private/build/_deps --extra-notices build-windows-cross/extra-notices
python3 tools/verify_private_windows_package.py dist-private/CityBuilder-Windows-Test/CityBuilder
```

The packaging helper uses independent copies (APFS copy-on-write where available),
explicit development-resource roots and only the designated test city. It excludes
personal Save folders, preferences, Mac binaries, editor state/pipeline caches and
capture logs. Only prepared runtime scenes/textures plus UID/extension lookup are
retained under the .godot runtime directory. A cold editor import exceeded ten
minutes partway through; prepared data avoids that work on first launch.
Original campaign `.sav` files within Adventures remain scenario content. Keep
upstream GPL source/notices, SDL/codec/Godot/GCC runtime licenses and existing
monster attribution/reference catalogs. The kit is private development content,
not a cleared public/Steam package.

The `Play.cmd` and `Run checks.cmd` launchers use the bundled Godot directly.
The test orchestrator runs owned child processes with independent scratch saves/
preferences, fingerprints protected files and samples only the owned process's
RAM. A native decision ends the max-speed phase; it is never answered automatically.
Results are collected in `Dell-test-results.zip`. The Windows batch launchers
themselves and prepared desktop resource formats still require actual Windows
validation. Independent Mac resource tests exercise the copied runtime only.
