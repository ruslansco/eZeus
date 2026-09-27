#include "ewarehousebase.h"

#include "textures/egametextures.h"

#include <algorithm>

namespace {
    const char* sGoodName(const eResourceType type) {
        switch(type) {
        case eResourceType::urchin: return "urchin";
        case eResourceType::fish: return "fish";
        case eResourceType::meat: return "meat";
        case eResourceType::cheese: return "cheese";
        case eResourceType::carrots: return "carrots";
        case eResourceType::onions: return "onions";
        case eResourceType::wheat: return "wheat";
        case eResourceType::oranges: return "oranges";
        case eResourceType::wood: return "wood";
        case eResourceType::bronze: return "bronze";
        case eResourceType::marble: return "marble";
        case eResourceType::grapes: return "grapes";
        case eResourceType::olives: return "olives";
        case eResourceType::fleece: return "fleece";
        case eResourceType::sculpture: return "sculpture";
        case eResourceType::oliveOil: return "oliveOil";
        case eResourceType::wine: return "wine";
        case eResourceType::armor: return "armor";
        case eResourceType::blackMarble: return "blackMarble";
        case eResourceType::orichalc: return "orichalc";
        default: return nullptr;
        }
    }
}

void eWarehouseBase::getSpaceOverlays(const eTileSize size,
                                      std::vector<eOverlay>& os,
                                      const eXY& xy,
                                      const bool hd) const {
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings();
    const auto& texs = blds[sizeId];
    const int iMax = xy.size();
    const auto& goods = texs.hdOverlays("storage_goods");
    if(hd && !goods.empty()) {
        // One pile sprite per bay, level = units stored (1-4). The library sprites are cut
        // from one-tile cells drawn like a 1x1 building on the bay tile (N view: bays never
        // rotate). Drawn back to front so nearer piles cover farther ones.
        const auto& trr = eGameTextures::terrain()[sizeId];
        const int cellH = 160*texs.fTileH/60;
        std::vector<eOverlay> piles;
        for(int i = 0; i < iMax; i++) {
            const int count = resourceCount(i);
            const auto name = sGoodName(resourceType(i));
            if(count <= 0 || !name) continue;
            const int level = std::clamp(count, 1, 4);
            eOverlay o;
            if(!eBuildingTextures::sHDOverlay(goods, name + std::to_string(level), 0, cellH,
                                              trr.fTileW, trr.fTileH, o)) continue;
            o.fX += xy[i].first;
            o.fY += xy[i].second;        // same anchor as the original bay sprite
            piles.push_back(o);
        }
        std::stable_sort(piles.begin(), piles.end(), [](const eOverlay& a, const eOverlay& b) {
            return a.fX + a.fY < b.fX + b.fY;
        });
        os.insert(os.end(), piles.begin(), piles.end());
        return;
    }
    for(int i = 0; i < iMax; i++) {
        const int count = resourceCount(i);
        const auto type = resourceType(i);
        eOverlay& o = os.emplace_back();
        const auto& xxyy = xy[i];
        o.fX = xxyy.first;
        o.fY = xxyy.second;
        o.fAlignTop = true;
        if(type == eResourceType::none || count <= 0) {
            o.fTex = texs.fWarehouseEmpty;
            continue;
        }
        const int texId = std::clamp(count - 1, 0, 3);
        switch(type) {
        case eResourceType::urchin:
            o.fTex = texs.fWarehouseUrchin.getTexture(texId);
            break;
        case eResourceType::fish:
            o.fTex = texs.fWarehouseFish.getTexture(texId);
            break;
        case eResourceType::meat:
            o.fTex = texs.fWarehouseMeat.getTexture(texId);
            break;
        case eResourceType::cheese:
            o.fTex = texs.fWarehouseCheese.getTexture(texId);
            break;
        case eResourceType::carrots:
            o.fTex = texs.fWarehouseCarrots.getTexture(texId);
            break;
        case eResourceType::onions:
            o.fTex = texs.fWarehouseOnions.getTexture(texId);
            break;
        case eResourceType::wheat:
            o.fTex = texs.fWarehouseWheat.getTexture(texId);
            break;
        case eResourceType::oranges:
            o.fTex = texs.fWarehouseOranges.getTexture(texId);
            break;


        case eResourceType::wood:
            o.fTex = texs.fWarehouseWood.getTexture(texId);
            break;
        case eResourceType::bronze:
            o.fTex = texs.fWarehouseBronze.getTexture(texId);
            break;
        case eResourceType::marble:
            o.fTex = texs.fWarehouseMarble.getTexture(texId);
            break;
        case eResourceType::grapes:
            o.fTex = texs.fWarehouseGrapes.getTexture(texId);
            break;
        case eResourceType::olives:
            o.fTex = texs.fWarehouseOlives.getTexture(texId);
            break;
        case eResourceType::fleece:
            o.fTex = texs.fWarehouseFleece.getTexture(texId);
            break;
        case eResourceType::sculpture:
            o.fTex = texs.fWarehouseSculpture;
            break;
        case eResourceType::oliveOil:
            o.fTex = texs.fWarehouseOliveOil.getTexture(texId);
            break;
        case eResourceType::wine:
            o.fTex = texs.fWarehouseWine.getTexture(texId);
            break;
        case eResourceType::armor:
            o.fTex = texs.fWarehouseArmor.getTexture(texId);
            break;

        case eResourceType::blackMarble:
            o.fTex = texs.fWarehouseBlackMarble.getTexture(texId);
            break;
        case eResourceType::orichalc:
            o.fTex = texs.fWarehouseOrichalc.getTexture(texId);
            break;
        default: continue;
        }
    }

}
