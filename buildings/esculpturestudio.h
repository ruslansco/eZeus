#ifndef ESCULPTURESTUDIO_H
#define ESCULPTURESTUDIO_H

#include "eprocessingbuilding.h"

class eSculptureStudio : public eProcessingBuilding {
public:
    eSculptureStudio(eGameBoard& board, const eCityId cid);
    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;
};

#endif // ESCULPTURESTUDIO_H
