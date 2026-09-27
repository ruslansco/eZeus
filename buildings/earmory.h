#ifndef EARMORY_H
#define EARMORY_H

#include "eprocessingbuilding.h"

class eArmory : public eProcessingBuilding {
public:
    eArmory(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EARMORY_H
