#ifndef EMASONRYSHOP_H
#define EMASONRYSHOP_H

#include "eresourcecollectbuilding.h"

class eMasonryShop : public eResourceCollectBuilding {
public:
    eMasonryShop(eGameBoard& board, const eCityId cid);

    std::shared_ptr<eTexture> getTexture(const eTileSize size) const override;
    std::vector<eOverlay> getOverlays(const eTileSize size) const override;

    void timeChanged(const int by);
private:
    void setCollectAction();

    bool mCollectActionSet = false;
};

#endif // EMASONRYSHOP_H
