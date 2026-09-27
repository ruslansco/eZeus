#include "egranary.h"

#include "textures/egametextures.h"
#include "engine/egameboard.h"
#include "buildings/ehdoverlays.h"

eGranary::eGranary(eGameBoard& board, const eCityId cid) :
    eStorageBuilding(board, eBuildingType::granary,
                     4, 4, 18, eResourceType::food, cid),
    mTextures(eGameTextures::buildings()) {
    eGameTextures::loadGranary();
    setOverlayEnabledFunc([]() { return true; });
}

std::shared_ptr<eTexture> eGranary::getTexture(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    const auto direction = static_cast<int>(getBoard().direction());
    const auto& frames = mTextures[sizeId].fGranaryHD[direction];
    if(frames[0]) return frames[enabled() ? hdAnimFrame() : 8];
    return mTextures[sizeId].fGranary;
}

std::vector<eOverlay> eGranary::getOverlays(const eTileSize size) const {
    std::vector<eOverlay> os;
    const int sizeId = static_cast<int>(size);
    const auto& texs = mTextures[sizeId];
    if(texs.fGranaryHD[0][0]) {
        // Remastered granary: each of the 8 storage bays shows the food it holds.
        const int dir = static_cast<int>(getBoard().direction());
        const auto& set = texs.hdOverlays("granary");
        for(int i = 0; i < 8; i++) {
            if(resourceCount(i) <= 0) continue;
            const char* food = nullptr;
            switch(resourceType(i)) {
            case eResourceType::urchin: food = "urchin"; break;
            case eResourceType::fish: food = "fish"; break;
            case eResourceType::meat: food = "meat"; break;
            case eResourceType::cheese: food = "cheese"; break;
            case eResourceType::carrots: food = "carrots"; break;
            case eResourceType::onions: food = "onions"; break;
            case eResourceType::wheat: food = "wheat"; break;
            case eResourceType::oranges: food = "oranges"; break;
            default: break;
            }
            if(food) {
                eAddHDOverlay(os, set, texs.fGranaryHD, "slot" + std::to_string(i) + "_" + food, dir, sizeId);
            }
        }
        return os;
    }
    if(enabled()) {
        const auto& coll = texs.fGranaryOverlay;
        const int texId = textureTime() % coll.size();
        auto& o = os.emplace_back();
        o.fTex = coll.getTexture(texId);
        o.fX = 0.38;
        o.fY = -3.78;
    }
    const std::pair<double, double> xy[8] = {{-3.11, -5.1},
                                             {-3, -5.65},
                                             {-2.89, -6.25},

                                             {-2.64, -4.43},
                                             {-2.53, -5.00},
                                             {-2.42, -5.55},
                                             {-2.31, -6.13},
                                             {-2.20, -6.73}};
    for(int i = 0; i < 8; i++) {
        const int count = resourceCount(i);
        if(count <= 0) continue;
        const auto type = resourceType(i);
        if(type == eResourceType::none) continue;
        eOverlay& o = os.emplace_back();
        switch(type) {
        case eResourceType::urchin:
            o.fTex = texs.fGranaryUrchin;
            break;
        case eResourceType::fish:
            o.fTex = texs.fGranaryFish;
            break;
        case eResourceType::meat:
            o.fTex = texs.fGranaryMeat;
            break;
        case eResourceType::cheese:
            o.fTex = texs.fGranaryCheese;
            break;
        case eResourceType::carrots:
            o.fTex = texs.fGranaryCarrots;
            break;
        case eResourceType::onions:
            o.fTex = texs.fGranaryOnions;
            break;
        case eResourceType::wheat:
            o.fTex = texs.fGranaryWheat;
            break;
        case eResourceType::oranges:
            o.fTex = texs.fGranaryOranges;
            break;
        default: continue;
        }
        o.fX = xy[i].first;
        o.fY = xy[i].second;
        if(type == eResourceType::carrots) {
            o.fY += 0.15;
        } else if(type == eResourceType::fish) {
            o.fX -= 0.15;
        }
    }
    return os;
}
