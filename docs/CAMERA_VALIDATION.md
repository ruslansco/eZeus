# Camera controls validation — 29 September 2026

Result: passed the binding regression and ten native screenshot-harness cases after fixing tile-centering rounding and controls-dialog alignment.

- Built with the configured Ninja/Clang toolchain, copied to `Bin/eZeus`, ad-hoc signed and verified. The subsequent build check reported no work needed.
- Disposable settings test: new defaults, legacy Q-to-C migration, occupied-key preservation, explicit custom/unbound directions, read/write persistence, direction wraparound/inverses and repeat-state propagation.
- Native cases: four starting world directions at 1920×1080; English and Russian controls at 1280×720 and 2560×1440; 150% and 200% zoom at 1920×1080.
- Each native case dispatches both camera directions through four turns, checks wraparound/focal tile, ignores repeat and Ctrl events, verifies opposite turns and independent R preview rotation, and verifies unchanged simulation time/treasury/building layout during those inputs.
- Visually inspected the English/Russian control layouts at standard and larger sizes. New actions are readable, centered and correctly bound.
- SHA-256 comparisons confirmed the designated `Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez` and player `settings.txt` were unchanged. Screenshot mode disables their writes.
- Inventory regeneration produced the same report: 332 families, 7,279 candidate files, 109 Blender scenes; no discovered read errors or asset-family symlinks. No rights approvals were performed.

Reproduce with `python3 tools/validate_camera_controls.py --in-game --output <capture-directory>` from `eZeus/` after building/deploying/signing. macOS display services must be accessible. The runner retains screenshots, logs and `validation.json` in the selected directory. This run's captures are in `/private/tmp/ezeus-camera-final-validation/` (temporary, not a release artifact).

Limits: no continuous 3D renderer was tested or implemented. Current automated cases use a central view at standard/magnified zooms; the 50% overview, map-edge clamping and full interactive placement/overlay acceptance remain additional coverage. Logs include existing missing legacy-resource/voice warnings and text-render warnings during teardown after capture. Native input tests call the widget dispatch with repeat/modifier flags; they do not synthesize physical macOS key presses or test every custom binding. These checks do not establish production content coverage or distribution rights.
