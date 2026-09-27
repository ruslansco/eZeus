#include "emint.h"
#include "engine/egameboard.h"

#include "characters/esilverminer.h"
#include "textures/egametextures.h"

eMint::eMint(eGameBoard& board, const eCityId cid) :
    eResourceCollectBuilding(board,
                             &eBuildingTextures::fMint,
                             -3.73, -3.73,
                             &eBuildingTextures::fMintOverlay,
                             3, 0.5, -1.5,
                             [this]() { return e::make_shared<eSilverMiner>(getBoard()); },
                             eBuildingType::mint,
                             eHasResourceObject::sCreate(eHasResourceObjectType::silver),
                             2, 2, 15, eResourceType::silver, cid) {
    eGameTextures::loadMint();
    setRawCountCollect(4);
}

std::shared_ptr<eTexture> eMint::getTexture(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    const auto& frames = textures.fMintHD[static_cast<int>(getBoard().direction())];
    if(!frames[0]) return eResourceCollectBuilding::getTexture(size);
    // Remastered art: eight working poses while operating, worker-free idle
    // pose (column 8) otherwise.
    const bool working = enabled() && rawCount() > 0;
    return frames[working ? hdAnimFrame() : 8];
}

std::vector<eOverlay> eMint::getOverlays(const eTileSize size) const {
    const auto& textures = eGameTextures::buildings()[static_cast<int>(size)];
    if(textures.fMintHD[0][0]) return {};
    return eResourceCollectBuilding::getOverlays(size);
}
