#ifndef EAGORAPLACEMENT_H
#define EAGORAPLACEMENT_H

#include <functional>
#include <vector>

#include "buildings/eagorabase.h"
#include "engine/ecityid.h"
#include "engine/eresourcetype.h"
#include "pointers/estdpointer.h"

class eGameBoard;
class eTile;
class eVendor;

// The rules for laying an agora over a stretch of road and for putting vendors on its spaces. They were part of
// the SDL game widget; the widget and the embedded simulation service share them so the two views can never
// disagree about where an agora fits or what it costs to fill.
namespace eAgoraPlacement {
// Where an agora fits for a pointer over `tile`: the tiles of the road strip and of the building lobe beside it
// (two lobes for a grand agora), with the orientation found. Empty when there is no room.
std::vector<eTile*> find(eGameBoard& board, eTile* const tile, const bool grand,
                         eAgoraOrientation& orientation, const eCityId cid,
                         const ePlayerId pid, const bool editor);

// Lays the agora over `tiles` (as returned by find): road tiles stay roads but belong to it, the others are taken
// by it, the vendor spaces are filled. The caller charges the construction cost.
stdsptr<eAgoraBase> build(eGameBoard& board, const std::vector<eTile*>& tiles, const bool grand,
                          const eAgoraOrientation orientation, const eCityId viewedCity);

// The vendor space that covers `tile`, or null.
eBuilding* spaceAt(eGameBoard& board, const int tx, const int ty);

// Native rule for one vendor: the tile must be the centre tile of an empty vendor space of an agora that has no
// vendor of this kind yet.
bool canPlaceVendor(eGameBoard& board, const int tx, const int ty, const eResourceType resource);

using eVendorFactory = std::function<stdsptr<eVendor>(eGameBoard&, const eCityId)>;
// Replaces the space centred on (tx, ty) by a new vendor and charges its cost to the person player.
bool placeVendor(eGameBoard& board, const int tx, const int ty, const eResourceType resource,
                 const eCityId cid, const eVendorFactory& factory);
}

#endif // EAGORAPLACEMENT_H
