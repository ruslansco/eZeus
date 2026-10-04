#include "epyramidmonument.h"

#include "textures/egametextures.h"
#include "epyramid.h"

#include "characters/gods/egod.h"
#include "engine/egameboard.h"

#include "../sanctuaries/etemplemonumentbuilding.h"

ePyramidMonument::ePyramidMonument(
        const std::vector<eSanctCost>& cost,
        eGameBoard& board,
        const int elevation,
        const eGodType type,
        const int id,
        const eCityId cid) :
    ePyramidElement(cost, board, eBuildingType::pyramidMonument,
                    elevation, 2, cid),
    mType(type), mId(id) {
    eSanctuary::sLoadMonumentTextures(type);
}

ePyramidMonument::ePyramidMonument(
        ePyramid* const pyramid,
        eGameBoard& board,
        const int elevation,
        const eGodType type,
        const int id,
        const eCityId cid) :
    ePyramidElement(pyramid,
                    {{0, 2, 0}, {0, 3, 0}},
                    board, eBuildingType::pyramidMonument,
                    elevation, 2, cid),
    mType(type), mId(id) {
    eSanctuary::sLoadMonumentTextures(type);
}

std::shared_ptr<eTexture>
ePyramidMonument::getTexture(const eTileSize size) const {
    const int p = 2 - maxProgress() + progress();
    if(p <= 0) return nullptr;
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings()[sizeId];
    if(p == 1) {
        return blds.fBlankMonument;
    }
    const auto coll = eTempleMonumentBuilding::sGodMonumentTextureCollection(size, mType);

    if(!coll) return nullptr;
    auto& board = getBoard();
    const auto dir = board.direction();
    int dirId;
    if(dir == eWorldDirection::N) {
        dirId = mId;
    } else if(dir == eWorldDirection::E) {
        if(mId == 0) {
            dirId = 3;
        } else if(mId == 1) {
            dirId = 0;
        } else if(mId == 2) {
            dirId = 1;
        } else { // if(mId == 3) {
            dirId = 2;
        }
    } else if(dir == eWorldDirection::S) {
        if(mId == 0) {
            dirId = 1;
        } else if(mId == 1) {
            dirId = 3;
        } else if(mId == 2) {
            dirId = 0;
        } else { // if(mId == 3) {
            dirId = 2;
        }
    } else { // if(dir == eWorldDirection::W) {
        if(mId == 0) {
            dirId = 1;
        } else if(mId == 1) {
            dirId = 2;
        } else if(mId == 2) {
            dirId = 3;
        } else { // if(mId == 3) {
            dirId = 0;
        }
    }
    // Remastered art shared with the sanctuaries (row order of eBuildingTextures::sStatueGods).
    const eGodType order[14] = {eGodType::zeus, eGodType::poseidon, eGodType::hades, eGodType::demeter,
                                eGodType::athena, eGodType::artemis, eGodType::apollo, eGodType::ares,
                                eGodType::hephaestus, eGodType::aphrodite, eGodType::hermes,
                                eGodType::dionysus, eGodType::hera, eGodType::atlas};
    eGameTextures::loadGodMonumentsHD();
    for(int row = 0; row < 14; ++row) {
        if(order[row] != mType) continue;
        if(const auto& hd = blds.fGodMonumentsHD[row][dirId]) return hd;
        break;
    }
    return coll->getTexture(dirId);
}
