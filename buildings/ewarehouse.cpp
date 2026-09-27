#include "ewarehouse.h"

#include "textures/egametextures.h"

eWarehouse::eWarehouse(eGameBoard& board, const eCityId cid) :
    eWarehouseBase(board, eBuildingType::warehouse, 3, 3, 12,
                   eResourceType::warehouse, cid) {
    setOverlayEnabledFunc([]() { return true; });
    eGameTextures::loadWarehouseHD();
}

std::shared_ptr<eTexture> eWarehouse::getTexture(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings();
    // Remastered storehouse on the rear tile. The goods bays are fixed screen
    // overlays that never rotate, so the N row is used for every direction.
    const auto& frames = blds[sizeId].fWarehouseHD[0];
    if(frames[0]) return frames[enabled() ? hdAnimFrame() : 8];
    return blds[sizeId].fWarehouse;
}

std::vector<eOverlay> eWarehouse::getOverlays(const eTileSize size) const {
    std::vector<eOverlay> os;
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings();
    const auto& texs = blds[sizeId];
    if(enabled() && !texs.fWarehouseHD[0][0]) {
        const auto& coll = texs.fWarehouseOverlay;
        const int texId = textureTime() % coll.size();
        auto& o = os.emplace_back();
        o.fTex = coll.getTexture(texId);
        o.fX = -1.24;
        o.fY = -4.32;
    }
    const eXY xy = {{-1, -2},
                    {-1, -1},

                    {0, -3},
                    {0, -2},
                    {0, -1},

                    {1, -3},
                    {1, -2},
                    {1, -1}};

    getSpaceOverlays(size, os, xy, static_cast<bool>(texs.fWarehouseHD[0][0]));

    return os;
}
