# Independent city-builder: production roadmap

Repository audit: 29 September 2026. Working direction: a separately named, premium ancient-city game, initially on Apple Silicon macOS. This is a proposed product direction, not an approved name, price or launch date. Windows support follows platform validation. Nothing has been published or legally cleared by this work.

## Decisions supported by this project

1. Keep the C++ simulation while proving a modern 3D presentation in a small pilot. Preserve the 20 Hz simulation and current save compatibility; do not rewrite economy, pathfinding and rendering together.
2. Replace the original game's expressive content and branding through a reviewed asset pipeline. Renaming files or rendering an original design again does not establish independent ownership.
3. Retain required engine author and license notices. `LICENSE.md` is GPLv3, and `README.md` identifies the upstream eZeus author. GPL software may be sold, but distributing this covered engine requires GPL compliance, including appropriate Corresponding Source and notices. A Godot wrapper or new renderer does not make the inherited engine proprietary. If a closed-source engine is essential, obtain appropriate rights from all relevant contributors or develop an independent implementation; assess this before budgeting a rewrite. [GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html.en)
4. Treat the Sierra/Impressions game's graphics, voices, music, campaign writing, maps, logos and other original content separately from the engine license. An open-source reimplementation does not license the original commercial content. No permission to distribute those assets was established in this audit. Derivative adaptations may still need permission. [US Copyright Office: derivative works](https://www.copyright.gov/circs/circ14.pdf)

The audit tool found 332 runtime asset families, 7,279 files (about 2.51 GB in decimal units), and 109 Blender scenes. These are discovery counts, not a completeness or clearance certificate. Regenerate `asset-inventory.json` as work changes. Counts include material that should stay out of a commercial package.

## What needs replacement, review or retention

| Project material | Evidence and action |
| --- | --- |
| `DATA/`, root `Audio/`, `Model/`, `Adventures/`, `Binks/`, `Zeus.exe`, official PDF | Original/compatibility material. Exclude from an independent product unless specific distribution rights are documented. Replace gameplay data where it contains copied expression; independently authored balancing values need their own provenance. |
| `eZeus/interface.e`, `i15.e`, `i30.e`, `textureTemplates/` | Legacy UI/resource dependencies. Replace assets and remove production fallback routes after feature coverage is complete. |
| `Zeus_Text*.xml`, `Zeus_MM*.xml`, event/campaign messages | Replace game prose, mission content, dialogue, tutorials and translations with original writing. Test English and Russian with complete independent dictionaries. |
| `fonts/` | Audit each font individually. `Alegreya-OFL.txt` is evidence to review for its paired font; it does not clear the Zeus fonts. Record required font notices. |
| `Textures/Original`, backups, `_disabled`, art reference extracts | Development references, excluded from shipping by default. Audit derivative inputs to new assets as well as final images. |
| `Textures/Remastered/`, terrain, menu and panel images | Candidates, all currently `needs_evidence`. Record creators, original models/textures, source licenses and generation history where applicable. New filenames or high resolution do not prove clearance. |
| `art/terrain/build_shores.py` | Uses extracted legacy sprite shapes (`original/sprites.json` and original terrain images). Review the dependency and author new shoreline shapes; not sampling original RGB alone does not clear it. |
| `art/_kit/assets/human-base-meshes-bundle-v1.4.1/` | Art notes describe CC0 base meshes. Retain the original license/download evidence and verify the exact upstream files before approving derived walkers. |
| Native `eZeus/Adventures/*.epak` and fan campaigns | Audit authors and source inputs separately. Native format and custom campaign names do not establish rights. |
| C++ engine, dependency licenses, author notices | Retain applicable notices, audit code provenance, and prepare exact release source plus build instructions. Do not remove authorship simply to rebrand the game. |

Mythological names and historical architectural ideas require a different assessment from the original game's specific artwork, character designs and text. Create your own visual and narrative expression, and review the final product name and store presentation for trademark/confusion risks. Do not perform a blind search-and-replace of Zeus/Poseidon in serialization keys or identifiers: that can break saves without resolving content ownership.

## Executable backlog and acceptance gates

| Priority / stage | Deliverable | Acceptance gate |
| --- | --- | --- |
| P0 — product and rights baseline | Select independent brand, target customer/platforms, premium base game scope; collect rights evidence using `provenance-register.template.json`; review engine obligations. | Every intended shipping category has an owner and replacement/approval decision. Original assets are identified, rather than silently treated as cleared. |
| P0 — release isolation | Explicit package allowlist of approved paths and SHA-256 hashes; staged packaging only. Separate development compatibility loaders from a production content provider. | Unapproved, missing, changed or symlinked package entries fail CI. Production starts with original `DATA`, `Audio`, XMLs and `.pak` folders unavailable and reports missing replacements clearly. No fallback to the player's original installation. |
| P1 — complete original content slice | One original scenario, original terrain/UI, ordinary housing, hospital, production chain, a few walkers, independent text/audio. | Entire slice playable with approved assets only, including pause, alerts, disasters, selected/ghost states, all four directions, both languages and credits. No copied campaign/story dependencies. |
| P1 — 3D decision pilot | Export approved Blender sources, bake animation/materials, implement depth-based rendering and smooth Q/E orbit on a representative city; bridge the existing core. See `ENGINE_AND_ROTATION.md`. | Correct picking, placement, elevation, water, anchors, independent object rotation and save/load throughout 360 degrees. Performance measured on the minimum target Mac. Decide renderer route from measurements. |
| P1 — engine boundary | Headless simulation target; command interface; stable entity IDs; immutable render snapshots; versioned content IDs. | Same commands and seeded state give the same simulation results independent of camera FPS/yaw. Rendering never modifies world layout or economy. Document any existing nondeterminism before relying on replay/networking. |
| P2 — content completion | Finish selected campaign/features, approved music/SFX/voices, unique character identities, building activity and animations, accessibility and controls. | Content coverage checklist is complete; remaster directory presence is not counted as installed/working coverage. Test loading, overlays and save migrations with the whole supported content set. |
| P2 — distributable application | Versioned `.app`, bundled dependencies, writable user-data paths, recoverable saves, crash reporting/logs, notices/source archive and signed installer/archive. | Launch on a clean Mac without the source tree, Homebrew, Blender or original Zeus files. Developer ID signing, hardened runtime, notarization and downloaded-build Gatekeeper test pass. |
| P2 — beta and store readiness | Closed beta, reproducible release builds, minimum/recommended specs, original trailer/screenshots, support/patch process, compliant store declarations. | No critical save loss/crash/progression issues; source/notices download matches binary revision; content approvals match packaged hashes; store review complete. |
| P3 — paid launch and updates | Freeze release content, price after demo/playtest feedback and market research, staged launch, supported patches. | All previous gates pass. Budget ongoing QA, customer support and content development. |

Stages are dependencies, not calendar promises. A first planning envelope is 1–2 weeks for inventory/rights triage, 2–4 weeks for a bounded renderer pilot, and 4–8 weeks for an original vertical slice with an experienced small team. These are rough estimates; content replacement, engineering coupling and external rights reviews can dominate. Re-estimate after the slice, before assigning a launch date.

## Packaging and commercial model

Start with a premium base game and a demo of the original scenario. Consider paid scenario/content expansions only after the base game has reliable saves and a support process. GPL-covered engine code must remain available under its applicable terms; independently authored art/content needs a separate rights and packaging assessment. Paid convenience, curated content, support and distribution can have value even when code is available. Do not assume DRM, a store wrapper or a launcher changes GPL obligations.

Use explicit packaging lists; never zip the whole workspace. Exclude personal saves, test cities, original installation resources, backups, source reference renders, old executables, `.blend1` files and local settings. Separately distribute the preferred source and build/install material required by applicable licenses. Preserve exact source revisions and dependency notices.

`eGameDir` currently stores saves/settings next to the executable and locates assets via a relative root or `zeus_path.txt`. Before production, split these into packaged read-only content and per-user writable data (using SDL's user-preference path or an equivalent platform location), migrate existing profiles non-destructively, and keep test installations isolated. Add atomic saves, validation/checksums, recovery copies and documented save-version migrations as separate work items.

The current ad-hoc signature is for development. Direct Mac distribution requires a distribution workflow using Developer ID signing and hardened runtime, followed by notarization; test the downloaded artifact and its bundled libraries. [Apple notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

For Steam, verify the current onboarding terms, fee and review lead times before setting a launch date. Declare relevant AI-assisted/generated content according to the current content survey; do not infer disclosure requirements from the appearance of the final art. [Steam Direct](https://partner.steamgames.com/steamdirect), [Steam content survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey)

## Implemented foundation in this change

- Q/E rotate the current map view in 90-degree steps; four presses complete a revolution. The current engine renders directional sprite atlases, not continuously orbitable meshes. R rotates placement preview; C is the default eyedropper. Existing custom bindings are preserved where defaults would conflict, with affected new actions left unbound for the user to configure.
- New controls are persisted and shown in English/Russian settings and the shortcut sheet. Rotation uses the existing view-direction path, keeping the world data intact and updating the minimap/compass. Tile-centering avoids a measured rounding drift at larger viewports; controls dialogs are centered after they acquire their parent.
- `tools/production_inventory.py` produces a repeatable candidate inventory. It performs no rights approvals, deletion, runtime fallback removal or packaging validation.
- Godot 4.6.3 now embeds the C++ simulation directly through GDExtension, with no hidden SDL renderer/process in normal launch. Q/E orbit, R/F tilt, 25,992 tiles, 834 initial building objects, spatial batches and 240 development model exports, with no building/walker conversion placeholders in the designated city are implemented. Pause/speed, nine construction types and simple event decisions use native rules/callbacks. The construction slice adds exact native previews/costs, imported mesh ghosts, live storage/production inspectors with native city-wide industry controls, native demolition/landmark dialogs and construction undo; new square-building facing is session-only. The launcher protects the designated save/settings. Full UI/audio/campaign parity, seeded replay proof, remaining conversion, clean-machine packaging and content clearance remain backlog items. See `GODOT_MIGRATION.md` and `../godot/README.md`.

Run the audit from `eZeus/`: `python3 tools/production_inventory.py`. Use the output to assign review tasks. Fill the provenance template with real evidence before changing any record to cleared. A legal review of the final code/content/distribution arrangement is a release gate, not a reason to discard working development assets now.
