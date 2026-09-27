#ifndef EWINERY_H
#define EWINERY_H

#include "eprocessingbuilding.h"

class eWinery : public eProcessingBuilding {
public:
    eWinery(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EWINERY_H
