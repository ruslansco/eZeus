#include "epyramidmuseum.h"
#include "engine/egameboard.h"

#include "textures/egametextures.h"
#include "epyramid.h"

ePyramidMuseum::ePyramidMuseum(
        const std::vector<eSanctCost>& cost,
        eGameBoard& board,
        const int elevation,
        const eCityId cid) :
    ePyramidElement(cost, board, eBuildingType::pyramidMuseum,
                    elevation, 6, cid) {
    eGameTextures::loadMuseum();
}

ePyramidMuseum::ePyramidMuseum(
        ePyramid* const pyramid,
        eGameBoard& board,
        const int elevation,
        const eCityId cid) :
    ePyramidElement(pyramid,
                    {eSanctCost{10, 10, 0}},
                    board, eBuildingType::pyramidMuseum,
                    elevation, 6, cid) {
    eGameTextures::loadMuseum();
}

stdsptr<eTexture> ePyramidMuseum::getTexture(const eTileSize size) const {
    if(!finished()) return nullptr;
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings()[sizeId];
    // Remastered Roman building (art/museum), worker-free idle pose.
    const auto& hd = blds.fMuseumHD[static_cast<int>(getBoard().direction())];
    if(hd[8]) return hd[8];
    return blds.fMuseum;
}
