#include "epyramidobservatory.h"
#include "engine/egameboard.h"

#include "textures/egametextures.h"
#include "epyramid.h"

ePyramidObservatory::ePyramidObservatory(
        const std::vector<eSanctCost>& cost,
        eGameBoard& board,
        const int elevation,
        const eCityId cid) :
    ePyramidElement(cost, board, eBuildingType::pyramidObservatory,
                    elevation, 5, cid) {
    eGameTextures::loadObservatory();
}

ePyramidObservatory::ePyramidObservatory(
        ePyramid* const pyramid,
        eGameBoard& board,
        const int elevation,
        const eCityId cid) :
    ePyramidElement(pyramid,
                    {eSanctCost{5, 5, 0}},
                    board, eBuildingType::pyramidObservatory,
                    elevation, 5, cid) {
    eGameTextures::loadObservatory();
}

stdsptr<eTexture> ePyramidObservatory::getTexture(const eTileSize size) const {
    if(!finished()) return nullptr;
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings()[sizeId];
    // Remastered Roman building (art/observatory), worker-free idle pose.
    const auto& hd = blds.fObservatoryHD[static_cast<int>(getBoard().direction())];
    if(hd[8]) return hd[8];
    return blds.fObservatory;
}
