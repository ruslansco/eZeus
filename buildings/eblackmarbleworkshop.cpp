#include "eblackmarbleworkshop.h"

#include "characters/emarbleminer.h"
#include "textures/egametextures.h"
#include "buildings/ehdoverlays.h"

#include "textures/emarbletile.h"

#include "characters/ecarttransporter.h"

#include "characters/actions/efollowaction.h"
#include "characters/actions/emovetoaction.h"

#include "eiteratesquare.h"
#include "engine/egameboard.h"

#include <algorithm>

eBlackMarbleWorkshop::eBlackMarbleWorkshop(eGameBoard& board, const eCityId cid) :
    eResourceCollectBuilding(board,
                             &eBuildingTextures::fBlackMarbleWorkshop,
                             0, 0, nullptr,
                             3, 0.5, -1.5,
                             [this]() { return e::make_shared<eMarbleMiner>(getBoard()); },
                             eBuildingType::blackMarbleWorkshop,
                             eHasResourceObject::sCreate(eHasResourceObjectType::blackMarble),
                             2, 2, 15, eResourceType::blackMarble, cid) {
    eGameTextures::loadMasonryShop();
    setAddResource(false);
    setRawInc(8);
    setRawCountCollect(0);
}

std::vector<eOverlay>
eBlackMarbleWorkshop::getOverlays(const eTileSize size) const {
    if(eGameTextures::buildings()[static_cast<int>(size)].fBlackMarbleWorkshopHD[0][0]) {
        // Remastered: the stock this building holds, rendered in its own scene.
        const int sizeId_ = static_cast<int>(size);
        const auto& t_ = eGameTextures::buildings()[sizeId_];
        const int dir_ = static_cast<int>(getBoard().direction());
        const auto& set_ = t_.hdOverlays("black_marble_workshop");
        std::vector<eOverlay> os_;
        eAddHDStock(os_, set_, t_.fBlackMarbleWorkshopHD, "stock", resource(), dir_, sizeId_);
        eAddHDStock(os_, set_, t_.fBlackMarbleWorkshopHD, "raw", rawCount(), dir_, sizeId_);
        return os_;
    }
    auto os = eResourceCollectBuilding::getOverlays(size);
    const int sizeId = static_cast<int>(size);
    const auto& btexs = eGameTextures::buildings()[sizeId];
    const int t = textureTime();
    const int rc = rawCount();
    if(rc) {
        const auto& stones = btexs.fBlackMarbleWorkshopStones;
        const int sid = std::clamp(8 - rc, 0, stones.size());

        eOverlay& o = os.emplace_back();
        o.fAlignTop = true;
        o.fTex = stones.getTexture(sid);
        o.fX = 0.25;
        o.fY = -0.75;
        if(sid > 0 && sid < 4) {
            o.fX -= 0.1;
            o.fY -= 0.1;
        } else if(sid == 4) {
            o.fY -= 0.15;
        } else if(sid == 5) {
            o.fX -= 0.10;
            o.fY -= 0.20;
        } else if(sid == 6) {
            o.fY -= 0.30;
        } else if(sid == 7) {
            o.fX -= 0.15;
            o.fY -= 0.5;
        }

        if(sid < 4) {
            eOverlay& o = os.emplace_back();
            const auto& ov = btexs.fMasonryShopOverlay1[0];
            const int id = t % ov.size();
            o.fTex = ov.getTexture(id);
            o.fX = 0.50;
            o.fY = -0.90;
        } else {
            eOverlay& o = os.emplace_back();
            const auto& ov = btexs.fMasonryShopOverlay2[0];
            const int id = t % ov.size();
            o.fTex = ov.getTexture(id);
            o.fX = 0.50;
            o.fY = -1.00;
        }
    }

    return os;
}

void eBlackMarbleWorkshop::timeChanged(const int by) {
    if(!mCollectActionSet) {
        mCollectActionSet = true;
        setCollectAction();
    }
    eResourceCollectBuilding::timeChanged(by);
}

void eBlackMarbleWorkshop::setCollectAction() {
    setCollectedAction(eTileActionType::blackMasonry);
}

std::shared_ptr<eTexture> eBlackMarbleWorkshop::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames = textures.fBlackMarbleWorkshopHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eResourceCollectBuilding::getTexture(size);
    // Remastered art: eight working poses while operating, worker-free idle
    // pose (column 8) otherwise.
    const bool working = enabled() && rawCount() > 0;
    return frames[working ? hdAnimFrame() : 8];
}
