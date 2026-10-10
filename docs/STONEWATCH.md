# Stonewatch — 9 October 2026

Use **Launch Godot 3D.command → New game → Stonewatch**, or the separate
**Play Stonewatch.command** launcher. Normal Continue/Load discovers its native
chapter and preserves the other campaigns’ save slots.

Private third campaign adapted from **One Against the World**, by **orius**:
https://zeus.heavengames.com/downloads/showfile.php?fileid=514. Source archives,
author notes and SHA-256 evidence remain untouched in the research collection.
New English/Russian story, objectives, permissions and encounter settings replace
the source adventure's writing and episode/colony progression.

## Chapters

| Chapter | Objectives | New tools and encounter |
| --- | --- | --- |
| A Refuge in the Forest | 240 residents; annual timber 24; one working export route | Housing, water, food, maintenance, timber and sea trade |
| The Watch Takes Its Post | 600 residents; support 24 archers or better; remain 18 months | Palace, taxes, science, fleece/health/gardens, walls/gates/towers; a warned native invasion |
| Theseus at the Gate | 600 residents; slay the Minotaur; treasury 5,000; remain 10 months | Optional advanced housing; scheduled Minotaur arrival unlocks Theseus's hall |

All three chapters retain one city, treasury and buildings. Native episode gates
control the Build menu and placement. Original campaign voices are excluded.
The forest map has no local copper/marble deposits. Lantern Reach's sea route buys
timber and supplies wheat, fleece, oil, wine, marble and optional armor. A pier's
shore storehouse needs a connected road, staff, maintenance and explicit orders;
warehouse bays and positive stock limits support deliveries.

The Red Banner League sends 12 native troops after one year in chapter two, with
six months' warning. The player's original **Fight / Pay / Surrender** callbacks
remain authoritative. No ordinary-menu choice is answered automatically. Chapter
three sends a passive native Minotaur after eight months. The hero hall unlocks
on arrival; Theseus needs a hall near the palace, adequate appeal, an enclosure of
walls/gates, 32 marble and 16 wine. The explicit Summon action consumes those goods
and the native hero hunts the monster. Arrival alone does not satisfy slaying.

## Isolation and authoring

Recipe: `content/scenarios/stonewatch_chapters.json`, version 1. Use
`tools/create_first_scenario.py --plan content/scenarios/stonewatch_chapters.json`
with `--build`, `--review --visible --lang en|ru`, `--playthrough` or `--play`.
The source working copy and fresh export/profile are separate from First Light,
Bronze River, original adventures and personal saves. Source/export/protected
file hashes are checked. Failed playthroughs remain separately archived.

The 25,992-tile parent terrain, elevation and coordinates remain intact. Two
explicit scenario markers set the eastern invasion approach (land ID7) and
monster arrival (ID99). Land invasion IDs above7 are sea points in native rules.
Foreign diplomacy does not substitute for native combat teams: editor-only
`editor_city_team` assigns an off-board foreign city an independent player/team
using the existing serialized world mapping. Ordinary gameplay rejects this
command. Existing native combat, RNG, save layout, speed and art remain unchanged.

## Verification status

Native authoring passes **10** checks, including exported attacker selection.
The final ordinary-command playthrough wins all three chapters, observing actual
invaders, explicit Fight, native invasion victory, the Minotaur, Theseus's Summon
and fight, and the fulfilled slaying goal. It uses **824 ordinary commands / 2,150
service calls**, with no test commands or injected people/goods/money/victory.
Latest completions: **432 / 735 / 648 residents**; final treasury **16,441**.
It advances **641,400 native time units**.
This is automated simulation evidence; the 45–90-minute human target is untested.

The test uses connected roads around the palace's decorative footprint, maintained
fort streets, science service coverage, standing companies down after battle and
multiple reserved import warehouses beside the pier, with confirmed connecting
roads. Live earlier-launcher diagnostic logs may
append; guards still protect their actual saves/settings/content. Sequential Metal reviews pass **49 English / 49 Russian**. Exported opposing
teams, invalid/ordinary editor-command refusals, three native objective/unlock
sets, carryover, checkpoint reload, blocking invasion/save refusal, Minotaur/hall
gating, complete localized briefings and the real opening Build menu pass.
Structural victories in this review remain explicit fixtures, separate from the
ordinary playthrough above. Retained editor **64** / embedded **101** pass.
The rebuilt Mac extension is installed/signed on a fresh inode; no live game or
Blender is stopped.

Expanded shared-menu checks pass **86 English / 86 Russian**. Native chapter-three Continue/Load, exact money/pause/build permissions,
three identically named autosaves, actual per-campaign city images, authored focus, enlarged layouts and prior
profiles are checked. The static card image is an actual view of a copied earlier
successful ordinary-playthrough city; input/file hashes are retained. Newcomer
pacing and visual acceptance remain open.

This remains `needs_evidence / ships_in_release=false`. Retained map/world and
compatibility content have unresolved commercial permissions. Human pacing,
visual acceptance, minimum machines and actual Windows packaging/execution remain
pending. No public distribution or Steam upload is performed.

Reports/captures are selected by `build-content-research/stonewatch/current.json`,
under `review-en-visible/`, `review-ru-visible/`, `natural-playthrough/` and the
separate `stonewatch/art/` folder. Failed attempts are retained; their stalls are
not acceptance evidence. Earlier successful runs used slower deliveries; the final
run confirms the connected pier-side storage and preserved hero/battle rules.
