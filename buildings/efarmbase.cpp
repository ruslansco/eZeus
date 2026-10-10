#include "efarmbase.h"

#include "textures/egametextures.h"
#include "enumbers.h"

#include <algorithm>
#include <string>

eFarmBase::eFarmBase(eGameBoard& board,
                     const eBuildingType type,
                     const int sw, const int sh,
                     const eResourceType resType,
                     const eCityId cid) :
    eResourceBuildingBase(board, type, sw, sh, 10, resType, cid),
    mTextures(eGameTextures::buildings())  {
    eGameTextures::loadPlantation();
    eGameTextures::loadRemastered("farm_base", 3);
    for(const char* crop : {"wheat", "carrots", "onions"}) {
        for(int k = 0; k < 6; k++) eGameTextures::loadRemastered(std::string("farm_") + crop + "_" + std::to_string(k), 1);
    }
}

std::shared_ptr<eTexture> eFarmBase::getTexture(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    // Remastered villa rustica: one screen-relative sprite, like the original.
    if(const auto hd = mTextures[sizeId].remastered("farm_base")) return (*hd)[0][0];
    return mTextures[sizeId].fPlantation;
}

std::vector<eOverlay> eFarmBase::getOverlays(const eTileSize size) const {
    std::vector<eOverlay> os;
    const int sizeId = static_cast<int>(size);
    const auto& texs = mTextures[sizeId];
    const std::pair<int, int> xy[5] = {{-1, -1},
                                       {0, -1},
                                       {1, -1},
                                       {1, -2},
                                       {1, -3}};
    const int fields = usedFields();
    for(int i = 0; i < 5; i++) {
        eOverlay& o = os.emplace_back();
        const auto& xxyy = xy[i];
        o.fX = xxyy.first;
        o.fY = xxyy.second;
        o.fAlignTop = true;
        const int texId = i >= fields ? 0 : std::clamp(mRipe, 0, 5);
        const auto type = resourceType();
        {
            const char* crop = type == eResourceType::onions ? "onions" :
                               type == eResourceType::carrots ? "carrots" : "wheat";
            const auto hd = texs.remastered(std::string("farm_") + crop + "_" + std::to_string(texId));
            if(hd) {
                o.fTex = (*hd)[0][0];      // a 1x1 field tile drawn where the legacy crop was
                continue;
            }
        }
        switch(type) {
        case eResourceType::onions:
            o.fTex = texs.fOnions.getTexture(texId);
            break;
        case eResourceType::carrots:
            o.fTex = texs.fCarrots.getTexture(texId);
            break;
        case eResourceType::wheat:
            o.fTex = texs.fWheat.getTexture(texId);
            break;
        default: break;
        }
    }
    return os;
}

double eFarmBase::harvestProgress() const {
    const double phase = eNumbers::sFarmRipePeriod > 0 ?
        std::clamp(mNextRipe/eNumbers::sFarmRipePeriod, 0.0, 1.0) : 0.0;
    return std::clamp((mRipe + phase)/5.0, 0.0, 1.0);
}

int eFarmBase::usedFields() const {
    return std::clamp(int(std::round(1 + effectiveness()*4)), 0, 5);
}

void eFarmBase::timeChanged(const int by) {
    if(enabled()) {
        mNextRipe += by*effectiveness();
        if(mNextRipe > eNumbers::sFarmRipePeriod) {
            mNextRipe = 0;
            if(++mRipe == 5) {
                addProduced(resourceType(), 4);
                mRipe = 0;
            }
        }
    }
    eResourceBuildingBase::timeChanged(by);
}

void eFarmBase::read(eReadStream& src) {
    eResourceBuildingBase::read(src);

    src >> mNextRipe;
    src >> mRipe;
}

void eFarmBase::write(eWriteStream& dst) const {
    eResourceBuildingBase::write(dst);

    dst << mNextRipe;
    dst << mRipe;
}
