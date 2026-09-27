#include "efoundry.h"

#include "characters/ebronzeminer.h"
#include "textures/egametextures.h"
#include "engine/egameboard.h"

eFoundry::eFoundry(eGameBoard& board, const eCityId cid) :
    eResourceCollectBuilding(board,
                             &eBuildingTextures::fFoundry,
                             -3.80, -3.78,
                             &eBuildingTextures::fFoundryOverlay,
                             2, 1.0, -2.0,
                             [this]() { return e::make_shared<eBronzeMiner>(getBoard()); },
                             eBuildingType::foundry,
                             eHasResourceObject::sCreate(eHasResourceObjectType::copper),
                             2, 2, 15, eResourceType::bronze, cid) {
    eGameTextures::loadFoundry();
    setRawCountCollect(4);
}
std::shared_ptr<eTexture> eFoundry::getTexture(const eTileSize size) const {const auto& t=eGameTextures::buildings()[static_cast<int>(size)];const auto& f=t.fFoundryHD[static_cast<int>(getBoard().direction())];if(!f[0])return eResourceCollectBuilding::getTexture(size);return f[enabled()&&rawCount()>0?hdAnimFrame():8];}
std::vector<eOverlay> eFoundry::getOverlays(const eTileSize size) const {const auto& t=eGameTextures::buildings()[static_cast<int>(size)];if(t.fFoundryHD[0][0])return {};return eResourceCollectBuilding::getOverlays(size);}
