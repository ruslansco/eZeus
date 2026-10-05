# Monster combat effects — 4 October 2026

The user requested fighting/destruction effects for Hydra and reported that
monster effects were missing. The native engine already has fight/fight2/die
poses and `eGodMissile` attacks for monsters. Godot previously omitted those
projectiles; building fire/smoke already had its own presentation.

## Implemented appearance

Hydra has green venom breath at its three sampled mouths, a soft travelling
trail, a spreading hit splash and a short dust cloud with falling stone pieces
when its target becomes native ruins. For opaque buildings, contact is drawn at
the near facade of the recorded native footprint. This is a presentation offset;
the actual native hit tile and damage stay unchanged. Water contacts use a pale
splash. All 17 monster types are recognized; other species currently use the
shared warm-coloured attack finish rather than individual authored effects.

`walker_combat.gd` plays the replacement Hydra fight/fight2/die poses through
existing native actions. The subsequent model pass implements the three-headed
reference and scale: see [monster art](GODOT_MONSTER_ART.md).

## Native authority and event transport

- `eGameBoard` has an optional, nonserialized missile observer. It is empty in
  the SDL reference. `eGodMissile::setTexture` observes launch, and `eMissile`
  observes impact after its original finish callback or cancellation on destroy.
- `eSimulationService` filters monster missiles and queues read-only launch,
  impact and cancellation records with monotonic session/event IDs, native time,
  speed, path endpoints, target water flag and original building footprint.
  It calls no gameplay command and draws no RNG. Detach removes the observer
  before destroying the board.
- The queue holds at most 256 cosmetic events. Delta snapshots drain it once,
  retaining launches and impacts even if a whole flight completes between two
  snapshots. Weak missile references discard expired tracking. Full snapshots
  visit the active missile registry to restore loaded in-flight projectiles;
  they do not scan tiles for effects or replay consumed impacts.
- Collapse dust requires a recorded original building and native ruins at the
  target after impact. Rendering never destroys a building, applies poison,
  answers a decision or invents damage. Native attack/collapse sequencing stays
  unchanged, including the native last-launch callback that may collapse a
  building before its final missile lands.

## Renderer contracts

`scripts/monster_effects.gd` lives under the city world and follows native clock
observations with the existing 0.1-second snapshot interval. It freezes when the
city is paused or blocked. `shaders/monster_puff.gdshader` has no wall-clock
`TIME`; deterministic trigonometric variation introduces no native randomness.
The renderer clears old effects if time or snapshot sequence restarts. It uses
two MultiMesh nodes (puffs/rings and stone debris), dynamic bounds, no lights,
physics, navigation or persistent damage areas.

Budgets: 32 active flights, 64 bursts, 512 puff instances and 128 debris pieces.
Overflow/expired effects disappear cosmetically. Native impact events alone
create hit bursts. Hydra origins interpolate its exported mouth probes at the
displayed combat phase and follow the actual model transform. Other species
retain approximate anchors. A missing nearby model uses the bounded fallback.
Original procedural effect source is development content with provenance
`needs_evidence`, recorded in `assets/monsters/effects_sources.json`; neither a
test pass nor this document grants release clearance.

## Rebuild and review

After changing shared native observation code, use
`./tools/build_godot_extension.sh` for the signed embedded library. Rebuild/sign
the native reference as required before replay parity checks. Run:

```sh
../tools/godot-runtime/Godot.app/Contents/MacOS/Godot --headless --path godot --log-file "$PWD/godot/captures/monster-effects-contract-engine.log" --script res://scripts/validate_monster_effects.gd
python3 tools/review_monster_effects.py --lang en --record
python3 tools/review_monster_effects.py --lang ru
python3 tools/replay_parity.py
```

Visible reviews run sequentially on the designated test city with disposable
preferences and save directories. The validator-only `test_monster_strike`
command invokes the original monster obstacle/destruction action. It is rejected
in ordinary play. The fixture tests actual native three-shot timing/collapse,
rather than a simulated renderer-side destruction. Capture tools hash the
designated save and player preferences before/after and close their owned window.

## Remaining coverage

Species-specific finishes beyond Hydra, same-tile native attacks that spawn no
missile, animated mouth/socket tracking for other species, in-flight save/load visual review,
multiple simultaneous combatants and minimum-Mac GPU profiling remain pending.
The common pipeline does not cover god, soldier or disaster missile art. Scoped
checks and captures are in [validation evidence](GODOT_VALIDATION.md); wider
combat/campaign parity and user art acceptance remain separate gates.
