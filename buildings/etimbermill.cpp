#include "etimbermill.h"

#include "characters/elumberjack.h"
#include "engine/egameboard.h"
#include "textures/egametextures.h"
#include "buildings/ehdoverlays.h"

eTimberMill::eTimberMill(eGameBoard& board, const eCityId cid) :
    eResourceCollectBuilding(board,
                             &eBuildingTextures::fTimberMill,
                             -3.65, -3.65,
                             &eBuildingTextures::fTimberMillOverlay,
                             3, 0.9, -1.1,
                             [this]() { return e::make_shared<eLumberjack>(getBoard()); },
                             eBuildingType::timberMill,
                             eHasResourceObject::sCreate(eHasResourceObjectType::forest),
                             2, 2, 12, eResourceType::wood, cid) {
    eGameTextures::loadTimberMill();
    setRawCountCollect(4);
}

std::shared_ptr<eTexture> eTimberMill::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto direction = static_cast<int>(getBoard().direction());
    const auto& frames = textures.fTimberMillHD[direction];
    if(!frames[0]) return eResourceCollectBuilding::getTexture(size);
    // Sawyers work only while staffed and supplied with logs; column 8 is the
    // worker-free idle pose.
    const bool working = enabled() && rawCount() > 0;
    return frames[working ? hdAnimFrame() : 8];
}

std::vector<eOverlay> eTimberMill::getOverlays(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fTimberMillHD[0][0]) {
        // Remastered: the stock this building holds, rendered in its own scene.
        const int sizeId_ = static_cast<int>(size);
        const auto& t_ = eGameTextures::buildings()[sizeId_];
        const int dir_ = static_cast<int>(getBoard().direction());
        const auto& set_ = t_.hdOverlays("timber_mill");
        std::vector<eOverlay> os_;
        eAddHDStock(os_, set_, t_.fTimberMillHD, "stock", resource(), dir_, sizeId_);
        return os_;
    }
    return eResourceCollectBuilding::getOverlays(size);
}
