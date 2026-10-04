#ifndef ESHOREPLACEMENT_H
#define ESHOREPLACEMENT_H

#include "engine/ecityid.h"
#include "engine/eorientation.h"

class eGameBoard;
class eTile;
class eWorldCity;

// Buildings that stand on the shore (fisheries, piers) and the sea piers that carry trade: where one fits, whether the
// water beside it leads to the sea, and how a pier and its trade post are laid. They were part of the SDL game widget;
// the widget and the embedded simulation service share them so the two views cannot disagree.
namespace eShorePlacement {
// A tile with nothing on it, no banner in the way, no cliff and nobody standing on it.
bool tileBuildable(eTile* const tile);
// The 2x2 shore spot whose first tile is (tx, ty - 1): the orientation of the water beside it, when there is a fit.
bool canBuildFishery(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o);
// Whether the water tile leads (through water) to the river entry point of the city, i.e. to the sea.
bool waterAccess(eGameBoard& board, const eCityId cid, const int tx, const int ty);
// The 4x4 land the pier's trade post takes: its first tile.
void pierPostCorner(const int tx, const int ty, const eDiagonalOrientation o, int& minX, int& minY);
// A pier at (tx, ty) (the shore spot's tile, as above) and its trade post on the land behind it.
bool canBuildPier(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o,
                  const eCityId cid, const ePlayerId pid, const bool forestAllowed);
bool pierHasSeaAccess(eGameBoard& board, const int tx, const int ty, const eCityId cid);
// Lays the pier and its trade post for `partner`. The caller has checked canBuildPier; the cost is the trade post's,
// charged by the board when the post is built.
bool placePier(eGameBoard& board, const int tx, const int ty, const eDiagonalOrientation o, eWorldCity& partner,
               const eCityId cid, const ePlayerId pid, const bool editor);
}

#endif // ESHOREPLACEMENT_H
