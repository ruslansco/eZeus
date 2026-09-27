#include "erefinery.h"
#include "engine/egameboard.h"

#include "characters/eorichalcminer.h"
#include "textures/egametextures.h"
#include "buildings/ehdoverlays.h"

eRefinery::eRefinery(eGameBoard& board, const eCityId cid) :
    eResourceCollectBuilding(board,
                             &eBuildingTextures::fRefinery,
                             -5.47, -5.50,
                             &eBuildingTextures::fRefineryOverlay,
                             2, 1.0, -2.0,
                             [this]() { return e::make_shared<eOrichalcMiner>(getBoard()); },
                             eBuildingType::refinery,
                             eHasResourceObject::sCreate(eHasResourceObjectType::orichalc),
                             2, 2, 16, eResourceType::orichalc, cid) {
    eGameTextures::loadRefinery();
    setRawCountCollect(4);
}

std::shared_ptr<eTexture> eRefinery::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames = textures.fRefineryHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eResourceCollectBuilding::getTexture(size);
    // Remastered art: eight working poses while operating, worker-free idle
    // pose (column 8) otherwise.
    const bool working = enabled() && rawCount() > 0;
    return frames[working ? hdAnimFrame() : 8];
}

std::vector<eOverlay> eRefinery::getOverlays(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fRefineryHD[0][0]) {
        // Remastered: the stock this building holds, rendered in its own scene.
        const int sizeId_ = static_cast<int>(size);
        const auto& t_ = eGameTextures::buildings()[sizeId_];
        const int dir_ = static_cast<int>(getBoard().direction());
        const auto& set_ = t_.hdOverlays("refinery");
        std::vector<eOverlay> os_;
        eAddHDStock(os_, set_, t_.fRefineryHD, "stock", resource(), dir_, sizeId_);
        return os_;
    }
    return eResourceCollectBuilding::getOverlays(size);
}
