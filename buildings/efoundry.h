#ifndef EFOUNDRY_H
#define EFOUNDRY_H

#include "eresourcecollectbuilding.h"

class eFoundry : public eResourceCollectBuilding {
public:
    eFoundry(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EFOUNDRY_H
