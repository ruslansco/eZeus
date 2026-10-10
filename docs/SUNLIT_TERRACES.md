# Sunlit Terraces — 10 October 2026

Use **Launch Godot 3D.command → New game → Sunlit Terraces**, or the separate
**Play Sunlit Terraces.command** launcher. Normal Continue/Load uses the campaign's
own save slot, preserving the three earlier campaigns.

The fourth private campaign adapts the parent terrain/world from **Everybody
loves oranges**, by **Genis**, [Zeus Heaven file828](https://zeus.heavengames.com/downloads/showfile.php?fileid=828).
The reviewed archive, original text and hashes remain intact. The new English and
Russian story, goals, permission sets and trade settings are authored separately.
The source's branching colonies, events and narration are replaced in this export.

## Chapters

| Chapter | Objectives | Tools added |
| --- | --- | --- |
| The First Orange Harvest | 240 residents; annual oranges 16; one working export route | Basic settlement, orange tenders/trees, food, timber and land trade |
| Oil for the Household | 480 residents; 64 in Homestead or better; annual oil 8 | Olives/growers/presses, imported fleece, Greek culture, health and gardens |
| The Shared Cellar | 700 residents; annual wine 8; reserve wine 16; treasury 5,000; remain six months | Vines/wineries, palace/taxes, further culture and optional defenses |

All three parent chapters retain one city and economy. Native permissions gate
the actual Build menu and placement. This is a Greek city: housing uses athletes
and philosophers, rather than the earlier Atlantean campaigns' science services.
Amber Crossing buys oranges 96, timber 64, oil 32 and wine 32 annually, and supplies
wheat 128 and fleece 48. It uses the existing land connection. The opening briefing
explains feeding the town with imported grain while orchards mature.

The map has 25,992 native tiles, 228×227 bounds, 373 fertile cells, 4,352 forest,
505 water, 72 marble and 37 silver. Most fertile land is raised above the dry
settlement valley. Coordinates, elevation, resources and native rules are retained.
No source terrain or live player city is rewritten. Existing road fragments do
not form one connected network: join the terrace district to the town, rather
than relying on an adjacent isolated road.

Oranges need a granary or trading post; ordinary warehouses cannot store them.
Keep the orchard granary free of imported grain. Warehouses hold olives, grapes,
oil and wine. Reserve separate bays, connect roads, employ workers and maintain
remote buildings. Orange tenders and ordinary growers serve different crops.
Wine must be committed through the explicit **Set aside** objective action;
planting, stockpiling and workshop output retain ordinary native behavior.
The retained native reserve wording says for colony; this slice provisions the
reserve and ends without opening a playable colony map.

## Authoring and evidence

Recipe: `content/scenarios/sunlit_terraces_chapters.json`, version 1. Use
`tools/create_first_scenario.py --plan content/scenarios/sunlit_terraces_chapters.json`
with `--build`, `--review --visible --lang en|ru`, `--playthrough` or `--play`.
The current manifest is `build-content-research/sunlit-terraces/current.json`.
Source inputs, exports and the other campaigns' player files are hash protected.
Failed tests remain in separately archived report folders.

Native authoring passes 9 checks. The ordinary-command playthrough passes all
three chapters with **777 commands / 4,100 service calls**, without test commands
or injected people, money, goods or victory. Completions have **400 / 1,096 /
1,080 residents**, with final treasury **33,562**. Direct observations confirm
**22 oranges sold** in a year, **70 wheat imported** in a year, local annual oil 12
and wine 13, raised orange-tree placement and the committed16-wine reserve.
Reports are `natural-playthrough/result.json` and `orchard-proof.json` under the
current manifest's report directory. Earlier runs completed objectives but failed
the stronger actual-sale check because their road networks were disconnected.

Sequential visible reviews pass **52 English / 52 Russian**; expanded normal-menu
checks pass **113 English / 113 Russian**. See the current validation document. Structural chapter wins in those UI/save fixtures
are separate from the ordinary playthrough above. The static card art is a view
of a copied ordinary-playthrough checkpoint, with source/file provenance.

This is `needs_evidence / ships_in_release=false`: retained map/world expression
and compatibility inputs still need commercial permission or replacement. No
source archive audio or original prose is installed. The 45–90-minute human
target, user visual acceptance, actual Windows build and minimum-machine testing
remain unverified. Frozen Windows ZIPs do not include this fourth campaign.
