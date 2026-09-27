#include "ecardingshed.h"
#include "engine/egameboard.h"

#include "characters/eshepherd.h"
#include "textures/egametextures.h"
#include "buildings/ehdoverlays.h"
#include "characters/actions/eshepherdaction.h"

#include <algorithm>

stdsptr<eResourceCollectorBase> cardingShedCharGenerator(eGameBoard& board) {
    return e::make_shared<eShepherd>(board);
}

eCardingShed::eCardingShed(eGameBoard& board, const eCityId cid) :
    eShepherBuildingBase(board, &eBuildingTextures::fCardingShed,
                         -0.98, -2.15,
                         &eBuildingTextures::fCardingShedOverlay,
                         cardingShedCharGenerator,
                         eBuildingType::cardingShed,
                         eResourceType::fleece,
                         eCharacterType::sheep,
                         2, 2, 8, cid),
    mTextures(eGameTextures::buildings())  {
    eGameTextures::loadCardingShed();
}

std::vector<eOverlay> eCardingShed::getOverlays(const eTileSize size) const {
    if(eGameTextures::buildings()[static_cast<int>(size)].fCardingShedHD[0][0]) {
        // Remastered: the stock this building holds, rendered in its own scene.
        const int sizeId_ = static_cast<int>(size);
        const auto& t_ = eGameTextures::buildings()[sizeId_];
        const int dir_ = static_cast<int>(getBoard().direction());
        const auto& set_ = t_.hdOverlays("carding_shed");
        std::vector<eOverlay> os_;
        eAddHDStock(os_, set_, t_.fCardingShedHD, "stock", resource(), dir_, sizeId_);
        return os_;
    }
    const int sizeId = static_cast<int>(size);
    const auto& texs = eGameTextures::interface()[sizeId];
    auto os = eShepherBuildingBase::getOverlays(size);
    if(resource() > 0) {
        const int res = std::clamp((resource() + 1)/2, 0, 4);

        for(int i = 0; i < res; i++) {
            eOverlay fleece;
            fleece.fTex = texs.fFleeceUnit;
            fleece.fX = 0.3 - i*0.2 + (i > 1 ? 0.5 : 0);
            fleece.fY = -1.6 - i*0.2;
            os.push_back(fleece);
        }
    }
    return os;
}

std::shared_ptr<eTexture> eCardingShed::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames = textures.fCardingShedHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eShepherBuildingBase::getTexture(size);
    // Remastered art: eight working poses while operating, worker-free idle
    // pose (column 8) otherwise.
    const bool working = enabled();
    return frames[working ? hdAnimFrame() : 8];
}
