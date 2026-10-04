#include "eboulevard.h"

eBoulevard::eBoulevard(eGameBoard& board, const eCityId cid) :
    eAvenue(board, eBuildingType::boulevard, cid) {
}
