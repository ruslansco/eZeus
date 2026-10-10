# Fan adventure shortlist — 8 October 2026

## Fifth implemented adaptation — 10 October 2026

**Tidebound Covenant** adapts the separately copied Tributaries 3 parent
terrain/world by Nightwolf / David Masters (file510). Three new EN/RU chapters
focus on local food, domestic fleece/Atlantean science/housing, then timber and
two explicitly committed reserves. This private slice has no trade or automatic
tribute. All chapters complete through ordinary native gameplay. The fifth
normal menu entry has phased tools, a static city view and its own save scope.
See [implementation and evidence](TIDEBOUND_COVENANT.md).

Original archives/text/notes/hashes remain intact, with
needs_evidence/ships_in_release=false unchanged. Selection uses retained
8 October page/archive evidence; it does not claim a new live ranking.
The remaining shortlisted map is **Augea - Open Play**.

## Fourth implemented adaptation — 10 October 2026

**Sunlit Terraces** adapts the separately copied Everybody loves oranges parent
map/world by Genis (file828). Three new EN/RU chapters cover oranges and trade,
olive oil/Greek housing, then wine and an explicit reserve. Raised fertile land
and source tracks remain; ordinary gameplay proves the complete delivery chain.
It is installed in the private normal menu with staged building permissions and
its own save slot. See [implementation and evidence](SUNLIT_TERRACES.md).
Original archives/text/hashes remain intact; `needs_evidence / ships_in_release=false`
is unchanged. The catalog was inaccessible to live browsing on 10 October, so
selection uses the retained 8 October page/archive evidence rather than new rankings.
At that stage the remaining maps were Tributaries 3 and Augea - Open Play; see
the fifth adaptation above for the subsequent implementation.

## Third implemented adaptation — 9 October 2026

**Stonewatch** uses a separately copied One Against the World parent map by
orius (file514), with three new English/Russian settlement, defense and hero
chapters. The original archive/notes/hash records remain untouched. Source terrain
and coordinates are retained; native markers, opposing combat teams and scheduled
invasion/Minotaur settings are authored in the private export. See
[Stonewatch implementation and evidence](STONEWATCH.md). Its commercial status
remains `needs_evidence / ships_in_release=false`; this update supersedes the
original research-only scope below for this specific local adaptation.


**Second playable adaptation — 9 October:** the reviewed Armory parent map now
supports [Bronze River](BRONZE_RIVER.md), with new EN/RU story, three native chapters,
bronze/armor logistics and phased buildings. Ordinary gameplay completes it and
visible reviews pass 53 in each language. Original source files remain intact;
the corresponding provenance record still excludes commercial shipping.

**Continuation:** the selected terrain is exported into the playable private
[First Light Harbor prototype](FIRST_LIGHT_HARBOR.md), with new writing/goals and
verified EN/RU import/menu/save/event flow. The selection-stage notes below precede
implementation; natural playthrough/pacing and release rights remain open.

The user approved downloading popular community adventures from Zeus Heaven as
potential terrain/campaign starting points instead of generating a new map.
Six archives are retained unchanged in ignored `build-content-research/archives/`.
Separate extracted data copies are under `review-copies/`; an independent
Alexandria working copy is under `working-copy/alexandria/`. None is installed in
the game's adventure catalog or included in a release package.

## Selection evidence

The supplied [catalog](https://zeus.heavengames.com/downloads/lister.php?category=adventures_pos&start=0&s=r&o=d)
sorts ratings. The [download ranking](https://zeus.heavengames.com/downloads/lister.php?category=adventures_pos&start=0&s=dls&o=d)
was also checked: the category lists 496 adventures. Counts below are observations
on the research date, not enduring measures of quality. The first five rows are
the five most downloaded entries in that category; Augea is a shorter alternative.

| Adventure / author | Downloads; rating (reviews) | Extracted authoring data | Prototype fit |
| --- | --- | --- | --- |
| [Alexandria](https://zeus.heavengames.com/downloads/showfile.php?fileid=532), LVLarry | 16,554; 4.5 (7) | `.pak`, `.set`, four `.map`, campaign text and author notes | Preferred starting point. Spacious Atlantean setting, Mortal difficulty, five parent/two colony episodes. Author explicitly invites editing and includes sources. |
| [Armory](https://zeus.heavengames.com/downloads/showfile.php?fileid=653), Nightwolf / David Masters | 10,624; 4.7 (4) | `.pak`, campaign text and author notes | Later production/military benchmark; six episodes and moderate/hard challenge. |
| [One Against the World](https://zeus.heavengames.com/downloads/showfile.php?fileid=514), orius | 8,995; 4.2 (7) | `.pak` and campaign text | Later combat/survival benchmark; six parent/three colony episodes. |
| [Everybody loves oranges](https://zeus.heavengames.com/downloads/showfile.php?fileid=828), Genis | 8,253; 4.9 (20) | `.pak`, campaign text, PDF guide and audio in archive; only campaign/text extracted | Strong challenge/reference candidate; ten episodes. No `.set`/standalone `.map` sources in archive. Too complex for the initial settlement. |
| [Tributaries 3](https://zeus.heavengames.com/downloads/showfile.php?fileid=510), Nightwolf / David Masters | 8,211; 5.0 (2) | `.pak`, campaign text and author notes | Advanced constrained-economy/tribute challenge; not an introductory scenario. |
| [Augea - Open Play](https://zeus.heavengames.com/downloads/showfile.php?fileid=867), Haspen | 2,525; 4.9 (4) | `.pak`, `.set`, parent `.map` and campaign text | Single-map alternative. Its open-play objectives and ruler events would need a deliberate short progression. |

These are desk/archival assessments, not playtest results. A missing `.set` limits
editing in the original scenario editor; it does not imply that the existing
native `.pak` importer cannot read the adventure.

## Recommended first development slice

Use the copied Alexandria parent terrain as the first import candidate. Keep
LVLarry's original files and attribution intact. Start with one parent map and a
new development campaign identity; defer the colony sequence. The proposed
30–60-minute progression is housing/water/food, a staffed production chain, one
working trade route, a bounded mythological challenge and a clear victory.
Write new briefings, objectives, event prose and translations. Confirm resources,
road access and construction space after import before choosing the exact goals.

The following work remains: isolated native/Godot import and terrain review,
creation of the playable adaptation, goal/pacing implementation, EN/RU progression
and save/load checks, and user playtesting. No binary terrain, campaign rules,
live city, personal save, model or simulation library was changed in this research.

## Source and permission record

`custom-adventures.provenance.json` records author/source URLs, archive SHA-256,
source-file hashes and unresolved rights. Local `archive-inventory.json` also lists
every archive member and hash. Raw pages and complete author notes stay in the
private research folder rather than the tracked documentation.

Alexandria's page and bundled notes expressly invite changes. That is useful
editing evidence; no explicit permission for commercial redistribution in a
separately branded game was established. No such grant was found in the other
five inspected pages/extracted text files. All records remain `needs_evidence`
and `ships_in_release=false`; third-party/original-game inputs also need review.
For Steam inclusion, establish permission covering the retained map/campaign
expression and commercial distribution, or replace those retained inputs.
[U.S. Copyright Office: derivative works](https://www.copyright.gov/circs/circ14.pdf)

No author has been contacted. Download availability, an editable source file,
new prose or a new product name does not by itself establish release rights.

## Verification

All six ZIPs pass CRC validation and bounded path/member checks. Only `.pak`,
`.set`, `.map` and `.txt` data were extracted, with hashes matching the untouched
archives. Downloaded executables/scripts were not run. The working copy matches
Alexandria's extracted inputs. Native import/gameplay/performance and commercial
clearance are explicitly unverified.
