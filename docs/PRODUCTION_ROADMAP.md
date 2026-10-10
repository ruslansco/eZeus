# Independent city-builder: production roadmap

## Fifth private campaign: Tidebound Covenant — 10 October 2026

The reviewed Tributaries 3 map now supplies a fifth featured campaign. Three new
EN/RU chapters develop local food, domestic fleece/science/housing, then timber
and reserves for a future outpost. Ordinary gameplay completes all chapters
without trade or injected stock/victory. Source terrain, phased native permissions,
same-city carry and separate saves are retained. Campaign reviews pass 52 and the
five-campaign library passes 137 per language. See
[scope, evidence and limits](TIDEBOUND_COVENANT.md).

The remaining archived map candidate is **Augea - Open Play**. Human newcomer
pacing, clean-platform builds and retained-content commercial clearance remain
release gates. Existing Windows kits are frozen and exclude this campaign.

## Fourth private campaign: Sunlit Terraces — 10 October 2026

The next shortlisted map, Genis's Everybody loves oranges, now supplies a fourth
featured campaign. New EN/RU chapters focus on raised orange orchards, olive oil
and Greek housing services, then wine and a shared reserve. Ordinary gameplay
completes all three with actual fruit trade and local processing; phased native
tools, source terrain and separate saves are retained. Campaign reviews pass 52
per language; the expanded four-campaign library passes 113 per language. See
[scope, evidence and limits](SUNLIT_TERRACES.md).

At that stage the remaining candidates were Tributaries 3 and Augea - Open Play;
the fifth-campaign update above records the subsequent Tributaries adaptation.
Newcomer pacing, clean-platform builds and commercial retained-content clearance
remain release gates. Existing Windows kits are frozen and exclude this campaign.

## Third campaign implemented in simulation — 9 October 2026

Stonewatch adds a distinct defense/mythology progression to the normal campaign
browser: forest settlement/sea trade, supported archers and a native invasion,
then Theseus's hall/supplies and actual Minotaur slaying. Its full ordinary-command
run completes three new EN/RU chapters on the reviewed orius map. First Light,
Bronze River and prior saves remain available. See [evidence and scope](STONEWATCH.md).
Next acceptance is newcomer playtesting across the three different campaign loops,
then verified clean-platform builds and retained-content rights work. Frozen Windows
kits are unchanged and do not include Stonewatch; no public release is performed.


## Normal campaign browser and Continuation — 9 October 2026

All three authored campaigns now appear first in normal New game, with descriptions,
native chapter/difficulty previews, static city views and saved-progress labels.
Independent campaign slots protect autosaves; previous-launcher profiles are
offered in place and Continue restores the actual saved chapter after full
preflight. EN/RU checks pass 86 each, retained menu checks 30 each, save recovery
36 each. See [campaign library](GODOT_CAMPAIGN_LIBRARY.md). Next acceptance remains
newcomer playtesting and actual clean-platform packaging. Retained-input permissions remain unresolved for public release.

## Second private campaign: Bronze River — 9 October 2026

Bronze River adapts the reviewed Armory parent map into a new EN/RU production/trade
story with three chapters and native building unlocks. Ordinary gameplay completes
the mining/armor/import/export/reserve chain and the trade interruption; visible
checks pass 53 per language. First Light remains available. See
[campaign scope](BRONZE_RIVER.md). Retained map/world/content permissions, human
playtesting and this campaign's actual Windows package/execution remain release
gates, alongside standalone Mac packaging.

## First campaign completed in simulation — 9 October 2026

The three-chapter First Light campaign now has staged tools and EN/RU writing.
An ordinary-command settlement wins all chapters with real food/clothing/science,
housing appeal, exports and profit. City/treasury carry and saved unlocks are checked.
The old prototype/profile is retained. A fresh private Windows Chapters kit includes
current native fixes/campaign and passes static/hash checks. Next acceptance is human
newcomer pacing/clarity and actual Dell execution, followed by content/rights review.
See `FIRST_LIGHT_CHAPTERS.md`; this remains private adaptation content, not Steam
clearance or a release-qualified platform build.

## First scenario implementation — 8 October 2026

The private [First Light Harbor prototype](FIRST_LIGHT_HARBOR.md) is playable from
its separate Mac launcher. It retains selected fan terrain and has new EN/RU prose,
one episode, seven objectives and a recoverable native trade challenge. Visible
menu/construction/save/event checks pass in both languages. Next content acceptance
is a complete natural settlement playthrough and pacing/balance revision. It remains
excluded from shipping pending retained-input/commercial permission and wider content
coverage; no independent-release clearance is inferred from new writing.

## Community map starting points — 8 October 2026

The user approved evaluating popular fan adventures instead of creating a map
from scratch. Six private downloads and a separate Alexandria working copy are
prepared. Its editable source maps and author invitation to edit make it the first
prototype candidate; Augea is a one-map alternative. See
[candidate evidence and next implementation](CUSTOM_ADVENTURE_RESEARCH.md).
Source/file hashes and author records remain `needs_evidence`, excluded from
shipping. Isolated import and a newly written short adaptation are next; commercial
redistribution permission must cover any retained fan/original-game expression.

## Desktop targets and platform work — 8 October 2026

The user prefers a modern Windows/Mac minimum specification instead of adapting
visuals to an old 1 GB card; a Dell laptop is available for Windows tests.
Balanced/High now preserve full-resolution city rendering and shadows. Practical
proposed hardware/acceptance targets and owned performance evidence are in
[GODOT_RELEASE_PERFORMANCE.md](GODOT_RELEASE_PERFORMANCE.md). They are not
published Steam minimums. Windows x64 build/test preparation is implemented;
actual MSVC/Dell execution remains pending. Current Mac libraries require macOS
26 and Homebrew, so the intended earlier OS floor and standalone package need
proper dependency rebuilding/bundling and launch tests. No new platform or
package is release-qualified by these source changes.

Repository audit: 29 September 2026. **Independent branding confirmed by the user on 7 October 2026.** The intended product is a separately named ancient-city game. Premium pricing remains a proposal; no final name, price or launch date is approved. The current validated development platform is Apple Silicon macOS; shipping platform claims, including Windows, require validation. Nothing has been published or legally cleared by this decision. See [release direction](RELEASE_IDENTITY.md).

The user plans new campaigns through changes to existing maps, prose and objectives,
and reports custom music already implemented, with effects/other audio to follow.
These are development plans and a user-reported implementation status. Modified
original content is recorded as an adaptation until retained expression and
permission/replacement evidence are assessed; it is not automatically cleared by
new branding or regeneration. File-level music ownership/coverage still needs an
audit. The original installation remains intact as a development reference.

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
