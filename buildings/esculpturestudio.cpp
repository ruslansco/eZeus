#include "esculpturestudio.h"

#include "textures/egametextures.h"
#include "enumbers.h"
#include "engine/egameboard.h"

eSculptureStudio::eSculptureStudio(eGameBoard& board,
                                   const eCityId cid) :
    eProcessingBuilding(board,
                        &eBuildingTextures::fSculptureStudio,
                        -3.73, -4.48,
                        &eBuildingTextures::fSculptureStudioOverlay,
                        eBuildingType::sculptureStudio, 2, 2, 12,
                        eResourceType::bronze,
                        eResourceType::sculpture, 4,
                        eNumbers::sSculptureStudioProcessingPeriod,
                        cid) {
    eGameTextures::loadSculptureStudio();
}

std::shared_ptr<eTexture> eSculptureStudio::getTexture(const eTileSize size) const {
    const auto& textures=eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames=textures.fSculptureStudioHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eProcessingBuilding::getTexture(size);
    return frames[overlayEnabled()?hdAnimFrame():8];
}

std::vector<eOverlay> eSculptureStudio::getOverlays(const eTileSize size) const {
    const auto& textures=eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fSculptureStudioHD[0][0]) return {};
    return eProcessingBuilding::getOverlays(size);
}
