# Tidebound Covenant — 10 October 2026

Use **Launch Godot 3D.command → New game → Tidebound Covenant**, or the separate
**Play Tidebound Covenant.command** launcher. The fifth featured private campaign
uses its own Continue/Load slot and keeps one city across all three chapters.

The parent terrain/world comes from **Tributaries 3** by **Nightwolf / David
Masters**, [Zeus Heaven file510](https://zeus.heavengames.com/downloads/showfile.php?fileid=510).
Original archives, campaign text, author notes and hashes remain intact. The
private export replaces source prose, events, objectives and colony progression
with new English/Russian writing and staged native permissions.

## Chapters

| Chapter | Objectives | Tools added |
| --- | --- | --- |
| Bread Before Bargains | 240 residents; annual wheat 32 | Homes, water, maintenance, storage, food production/distribution and bridges |
| The Woven City | 480 residents; 64 in Homestead or better; annual fleece 16 | Sheep/carding sheds, fleece stalls, Atlantean science, health, gardens, palace and taxes |
| Supplies for the Far Shore | 700 residents; annual timber 24; reserve timber 32 and fleece 16; treasury 5,000; remain six months | Timber mills, further science and optional defenses |

No chapter enables trade buildings, imports, exports or automatic tribute.
Far Shore is a retained world contact with empty trading lists. Food and clothing
must be produced locally; taxes support the treasury once the palace unlocks.
This is an Atlantean city, so bibliothekes/observatories supply early science.
Native Build availability and placement enforce each chapter's permissions.

The map keeps all **25,992 native tiles**, **228×227 bounds**, **2,802 fertile**,
**2,205 forest**, **5,384 water** and **575 ordinary rock cells**. It has no copper,
silver, marble, orichalc or black-marble deposits. No mineral industry or invented
deposits are required. Native heights, road fragments and wildlife markers remain.
Opening focus is `(110,-45)`, with 36,000 funds and Mortal difficulty.

Reserve pasture outside housing/gardens. Native placement permits several sheep
on one cell; distinct grazing sites give shepherds better access. Connect remote
pasture and timber districts to the actual town network. A short adjacent road
can be isolated, and a full fleece warehouse cannot receive timber until bays
are freed. Keep a dedicated timber store and enough fleece for the markets.

Both **Set aside** actions are required. They remove goods from city stock and
remain credited to their respective goals. Native wording says for colony; the
new story explicitly prepares supplies for a future outpost. This three-chapter
slice ends without opening a second playable city.

## Authoring and evidence

Recipe: `content/scenarios/tidebound_covenant_chapters.json`, version 1. Use
`tools/create_first_scenario.py --plan content/scenarios/tidebound_covenant_chapters.json`
with `--build`, `--review --visible --lang en|ru`, `--playthrough` or `--play`.
The current manifest is `build-content-research/tidebound-covenant/current.json`.
The installer verifies the export before adding it to the private normal catalog.

Native authoring passes **9** checks. The final ordinary-command run completes
all three chapters with **496 commands / 2,410 service calls**, without injecting
population, money, goods or victory. Completions have **376 / 566 / 757 residents**
and final treasury **27,293**. Observations show annual local wheat **32**, fleece
**21** and timber **26**, no trade, and both committed reserves. Native randomness
can change these completion figures in subsequent runs.

Sequential visible Mobile/Metal campaign reviews pass **52 English / 52 Russian**:
terrain, native-valid farms, localized goals, phased permissions, locked placement,
Atlantean science, absence of trade, same-city carry, save/reload, empty-reserve
refusal, relative BC waiting, ending and full paged briefing/actual Build menu.
Those review wins use explicit structural fixtures, separate from ordinary play.
Retained native editor **64** and embedded **101** checks pass.

The static 960×360 menu image is rendered from an owned copy of the final ordinary
playthrough checkpoint; source and image hashes are recorded separately. Earlier
failed pasture/road/storage layouts are retained as diagnostic logs/results,
not acceptance evidence. Redundant generated failed-test cities were removed
after disk exhaustion; original sources, player cities and successful checkpoints
remain intact.

Expanded sequential normal-menu reviews pass **137 English / 137 Russian**:
normal New game, fifteen chapter previews, individual images/full briefings,
actual Begin/Continue/Load and five independent autosave scopes. See current
validation and campaign-library documentation for the scope and reports. No C++
rules, RNG, tick timing, native save layout, audio or model geometry changed.

This remains `needs_evidence / ships_in_release=false`. Human pacing (45–90-minute
target), user visual acceptance, actual Windows/minimum-machine testing and
retained map/content commercial permission or replacement remain open. Frozen
Windows kits do not include this fifth campaign.
