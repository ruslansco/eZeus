#ifndef EMINT_H
#define EMINT_H

#include "eresourcecollectbuilding.h"

class eMint : public eResourceCollectBuilding {
public:
    eMint(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EMINT_H
