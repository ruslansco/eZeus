#include "ecolumn.h"

#include "textures/egametextures.h"
#include "textures/ebuildingtextures.h"
#include "engine/egameboard.h"

eDoricColumn::eDoricColumn(eGameBoard& board, const eCityId cid) :
    eColumn(board, &eBuildingTextures::fDoricColumn,
            eBuildingType::doricColumn, 1, 1, cid) {
    eGameTextures::loadColumns();
    setHD("doric_column");
}

eIonicColumn::eIonicColumn(eGameBoard& board, const eCityId cid) :
    eColumn(board, &eBuildingTextures::fIonicColumn,
            eBuildingType::ionicColumn, 1, 1, cid) {
    eGameTextures::loadColumns();
    setHD("ionic_column");
}

eCorinthianColumn::eCorinthianColumn(eGameBoard& board, const eCityId cid) :
    eColumn(board, &eBuildingTextures::fCorinthianColumn,
            eBuildingType::corinthianColumn, 1, 1, cid) {
    eGameTextures::loadColumns();
    setHD("corinthian_column");
}

std::vector<eOverlay> eColumn::getOverlays(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    const auto& bds = eGameTextures::buildings();
    const auto& texs = bds[sizeId];
    const auto t = centerTile();
    auto& board = getBoard();
    const auto dir = board.direction();
    std::vector<eOverlay> os;
    if(hdFrames(size)) {
        // Remastered: architrave sprites share the column's canvas and anchor.
        const auto link = [&](const char* const side) {
            const auto f = texs.remastered(hdId() + side);
            if(f) os.push_back(eOverlay{0, 0, (*f)[0][0], true});
        };
        if(const auto bl = t->bottomLeftRotated<eTile>(dir)) {
            if(bl->underBuildingType() == type()) link("_link_l");
        }
        if(const auto br = t->bottomRightRotated<eTile>(dir)) {
            if(br->underBuildingType() == type()) link("_link_r");
        }
        return os;
    }
    if(const auto bl = t->bottomLeftRotated<eTile>(dir)) {
        if(bl->underBuildingType() == type()) {
            os.push_back(eOverlay{-1.95, -1.9, texs.fColumnConnectionH});
        }
    }
    if(const auto br = t->bottomRightRotated<eTile>(dir)) {
        if(br->underBuildingType() == type()) {
            os.push_back(eOverlay{-1.45, -2.4, texs.fColumnConnectionW});
        }
    }
    return os;
}
