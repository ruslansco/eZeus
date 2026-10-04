#ifndef ETRADEPARTNERS_H
#define ETRADEPARTNERS_H

#include <vector>

#include "engine/ecityid.h"

class eGameBoard;
class eWorldCity;

// The cities a city can open a trade post (or a sea pier) with. The SDL build panel and the embedded core list the same
// partners: not a rival, not the city itself, active and visible, no post there yet, not an enemy, and something to trade.
struct eTradePartner {
    int index;          // position in the world's city list: what the build command names the partner by
    eWorldCity* city;
    bool water;         // reached by sea: a pier, not a land trade post
};

namespace eTradePartners {
std::vector<eTradePartner> available(eGameBoard& board, const eCityId cid, const bool showAllPossible);
}

#endif // ETRADEPARTNERS_H
