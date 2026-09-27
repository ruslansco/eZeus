#ifndef ETIMBERMILL_H
#define ETIMBERMILL_H

#include "eresourcecollectbuilding.h"

class eTimberMill : public eResourceCollectBuilding {
public:
    eTimberMill(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};


#endif // ETIMBERMILL_H
