#ifndef EOLIVEPRESS_H
#define EOLIVEPRESS_H

#include "eprocessingbuilding.h"

class eOlivePress : public eProcessingBuilding {
public:
    eOlivePress(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // EOLIVEPRESS_H
