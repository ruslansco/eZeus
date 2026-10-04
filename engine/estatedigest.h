#pragma once
#include <string>
class eGameBoard;

// Deterministic replays. Steps the shared simulation order (eSimulationStep) exactly `ticks` times with the
// game unpaused and no pending-decision gate, five sub-steps per tick so that worker tasks finish in a
// fixed order. The SDL executable (EZEUS_REPLAY) and the embedded service use this one function.
void eReplaySteps(eGameBoard& board, int ticks);

// "<16 hex digits>:<buildings>:<characters>:<time>": a 64-bit FNV-1a digest of the gameplay state (terrain,
// roads, every building's type, footprint, state and employment, every character's type, position, heading
// and action, the treasury, population and clock), sorted so container order does not matter.
// Cosmetic randomised fields that the save format also stores are deliberately not part of it.
// `sections`, when given, receives one digest per part (head, tiles, buildings, characters) for diagnosing
// where two replays diverge.
std::string eStateDigest(eGameBoard& board, std::string* sections = nullptr);

// Digest of the complete serialized save of the board ("<16 hex digits>:<bytes>"). The save also stores
// cosmetic randomised values, so it is informational: two equal gameplay digests may still differ here.
std::string eSaveDigest(const eGameBoard& board);
