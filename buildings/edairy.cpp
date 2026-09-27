#include "edairy.h"
#include "engine/egameboard.h"

#include "characters/egoatherd.h"
#include "textures/egametextures.h"
#include "buildings/ehdoverlays.h"
#include "characters/actions/eshepherdaction.h"

#include <algorithm>

stdsptr<eResourceCollectorBase> dairyCharGenerator(eGameBoard& board) {
    return e::make_shared<eGoatherd>(board);
}

eDairy::eDairy(eGameBoard& board, const eCityId cid) :
    eShepherBuildingBase(board, &eBuildingTextures::fDairy,
                         -1.35, -2.95,
                         &eBuildingTextures::fDairyOverlay,
                         dairyCharGenerator,
                         eBuildingType::dairy,
                         eResourceType::cheese,
                         eCharacterType::goat,
                         2, 2, 8, cid),
    mTextures(eGameTextures::buildings())  {
    eGameTextures::loadDairy();
}

std::vector<eOverlay> eDairy::getOverlays(const eTileSize size) const {
    if(eGameTextures::buildings()[static_cast<int>(size)].fDairyHD[0][0]) {
        // Remastered: the stock this building holds, rendered in its own scene.
        const int sizeId_ = static_cast<int>(size);
        const auto& t_ = eGameTextures::buildings()[sizeId_];
        const int dir_ = static_cast<int>(getBoard().direction());
        const auto& set_ = t_.hdOverlays("dairy");
        std::vector<eOverlay> os_;
        eAddHDStock(os_, set_, t_.fDairyHD, "stock", resource(), dir_, sizeId_);
        return os_;
    }
    const int sizeId = static_cast<int>(size);
    const auto& texs = mTextures[sizeId];
    auto os = eShepherBuildingBase::getOverlays(size);
    if(resource() > 0) {
        eOverlay cheeese;
        const int res = std::clamp(resource() - 1, 0, 4);
        cheeese.fTex = texs.fWaitingCheese.getTexture(res);
        cheeese.fX = 0;
        cheeese.fY = -1.5;

        os.push_back(cheeese);
    }
    return os;
}

std::shared_ptr<eTexture> eDairy::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames = textures.fDairyHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eShepherBuildingBase::getTexture(size);
    // Remastered art: eight working poses while operating, worker-free idle
    // pose (column 8) otherwise.
    const bool working = enabled();
    return frames[working ? hdAnimFrame() : 8];
}
