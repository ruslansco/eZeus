# Character panel and live supplies — 7 October 2026

Right-clicking a walker opens the centered charcoal/bronze character card. The
portrait, native name/occupation, spoken line, voice controls and other walkers
on the tile are retained. Speech and supply details share a bounded scrolling
column; Go to and Close remain in a separate footer. Ordinary characters use a
smaller card than peddlers. The shared Theme and independent interface/text sizes
apply to the portrait frame, quote, stock tiles and labels. Portrait images still
disable their 3D viewport; roles without images retain the existing model stage.

Opening holds queued commands and pauses the native simulation. Closing through
Close, the header cross, Escape, right-click or the backdrop uses the existing
callback and restores the previous pause/hold state. Go to uses the current native
walker ID. These controls do not answer a pending native decision.

## Native observations

`character_info <id>` now includes an optional `inventory`. The separate
`character_inventory <id>` returns only the resolved walker ID and inventory,
without calling the spoken-line selector, drawing cosmetic RNG or playing sound.
Both reject missing/dead walkers. Trailer inspections resolve to their driver.

- Peddlers report `kind: agora`, the name/coordinates of their own linked Agora,
  and Food/Fleece/Olive oil/Wine/Arms/Horses. Chariots appear when that vendor is
  present. Each item carries the native resource bit, presence, stock units,
  capacity and vendor location. The quantities use the same `stockUnits()` and
  `capacityUnits()` as the existing Agora inspector.
- Transport carts report `kind: cargo`, `unit: loads`, and their actual
  `resType()`/`resCount()`. Empty carts return an empty item list. Cargo is still
  reported when the good has no 3D cargo model. No capacity is invented.
- Growers report their actual collected grape/olive/orange counts in native item
  units. Characters without these native inventory observations return null.

The native peddler has no independent cart store: `provideToBuilding()` consumes
the linked Agora's vendors directly. The panel therefore says Supplies from that
Agora instead of presenting a second inventory. Do not add a new stock, change
native distribution or infer goods from portrait/asset names. Source and vendor
locations use native `x()/y()` command coordinates, matching snapshot tiles and
the existing inspector; these coordinates can be negative on irregular boards.

## Live presentation

`ui/character_inventory.gd` uses the existing resource illustrations and a stock
grid like the Agora inspector. Missing vendors show a dash; existing empty stalls
show 0 / capacity. Stocked supplies have a restrained green border/status. Empty
cargo has an explicit message. Resource labels retain tooltips when truncated.

While an inventory-bearing character is open, one read-only query per second
updates existing cards in place. No tile scan, portrait reconstruction, voice
restart or speech reroll is performed. The paused city naturally retains its
counts. Changing to another walker resets the disclosure and fetches that
walker's inventory; a stale query clears cargo and disables Go to.

## Verification and limits

Run `scripts/validate_character_inventory.gd`, sequential owned
`tools/review_character_panel.py --lang en` / `ru`, retained
`scripts/validate_embedded.gd` and `scripts/validate_ui_text.gd`. Visible fixtures
use scratch preferences/saves and protect the designated city. Their initial
200 normal native ticks let the existing Agora spawn a peddler; no test-only
character or fabricated simulation inventory is installed. The refresh test
changes only a displayed count, then verifies the next native query restores it
without rebuilding tiles or changing speech/portrait/pause. The headless gate
compares peddler supplies against its actual Agora inspector and native cart loads
against their walker observations. Current evidence is in GODOT_VALIDATION.md.

This is a read-only panel change. Housing/production/trade rules, routes, RNG,
native save serialization, cart meshes and painted portraits are retained.
Other roles with no exposed native cargo state do not get invented inventory.
Broader campaign and minimum-Mac performance coverage remain pending.
