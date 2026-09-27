#ifndef EREFINERY_H
#define EREFINERY_H

#include "eresourcecollectbuilding.h"

class eRefinery : public eResourceCollectBuilding {
public:
    eRefinery(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EREFINERY_H
