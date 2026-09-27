#include "eolivepress.h"

#include "textures/egametextures.h"
#include "enumbers.h"
#include "engine/egameboard.h"

eOlivePress::eOlivePress(eGameBoard& board,
                         const eCityId cid) :
    eProcessingBuilding(board,
                        &eBuildingTextures::fOlivePress,
                        -3.65, -3.75,
                        &eBuildingTextures::fOlivePressOverlay,
                        eBuildingType::olivePress, 2, 2, 12,
                        eResourceType::olives,
                        eResourceType::oliveOil, 1,
                        eNumbers::sOlivePressProcessingPeriod,
                        cid) {
    eGameTextures::loadOlivePress();
}

std::shared_ptr<eTexture> eOlivePress::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto direction = static_cast<int>(getBoard().direction());
    const auto& frames = textures.fOlivePressHD[direction];
    if(!frames[0]) return eProcessingBuilding::getTexture(size);
    // Eight working poses follow the existing visual clock. The separate idle
    // pose has no workers or flowing oil; it must never enter the working loop.
    const int frame = overlayEnabled() ? hdAnimFrame() : 8;
    return frames[frame];
}

std::vector<eOverlay> eOlivePress::getOverlays(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fOlivePressHD[0][0]) return {};
    return eProcessingBuilding::getOverlays(size);
}
