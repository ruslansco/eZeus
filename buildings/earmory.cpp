#include "earmory.h"

#include "textures/egametextures.h"
#include "enumbers.h"
#include "engine/egameboard.h"

eArmory::eArmory(eGameBoard& board,
                 const eCityId cid) :
    eProcessingBuilding(board,
                        &eBuildingTextures::fArmory,
                        -1.75, -3.15,
                        &eBuildingTextures::fArmoryOverlay,
                        eBuildingType::armory, 2, 2, 18,
                        eResourceType::bronze,
                        eResourceType::armor, 2,
                        eNumbers::sArmoryProcessingPeriod,
                        cid) {
    eGameTextures::loadArmory();
}

std::shared_ptr<eTexture> eArmory::getTexture(const eTileSize size) const {
    const auto& textures=eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames=textures.fArmoryHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eProcessingBuilding::getTexture(size);
    return frames[overlayEnabled()?hdAnimFrame():8];
}

std::vector<eOverlay> eArmory::getOverlays(const eTileSize size) const {
    const auto& textures=eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fArmoryHD[0][0]) return {};
    return eProcessingBuilding::getOverlays(size);
}
