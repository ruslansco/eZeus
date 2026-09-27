#include "ewinery.h"

#include "textures/egametextures.h"
#include "enumbers.h"
#include "engine/egameboard.h"

eWinery::eWinery(eGameBoard& board, const eCityId cid) :
    eProcessingBuilding(board,
                        &eBuildingTextures::fWinery,
                        -2.2, -3.25,
                        &eBuildingTextures::fWineryOverlay,
                        eBuildingType::winery, 2, 2, 12,
                        eResourceType::grapes,
                        eResourceType::wine, 1,
                        eNumbers::sWineryProcessingPeriod,
                        cid) {
    eGameTextures::loadWinery();
}

std::shared_ptr<eTexture> eWinery::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto direction = static_cast<int>(getBoard().direction());
    const auto& frames = textures.fWineryHD[direction];
    if(!frames[0]) return eProcessingBuilding::getTexture(size);
    const int frame = overlayEnabled() ? hdAnimFrame() : 8;
    return frames[frame];
}

std::vector<eOverlay> eWinery::getOverlays(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fWineryHD[0][0]) return {};
    return eProcessingBuilding::getOverlays(size);
}
