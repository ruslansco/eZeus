#include "eruins.h"

#include "textures/egametextures.h"

#include <map>

eRuins::eRuins(eGameBoard& board, const eCityId cid) :
    eBuilding(board, eBuildingType::ruins, 1, 1, cid) {

}

stdsptr<eTexture> eRuins::getTexture(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    const auto& texs = eGameTextures::terrain();
    const auto& coll = texs[sizeId].fTinyStones;
    const int id = seed() % coll.size();
    // Remastered Roman rubble (art/lots, 8 variants at the tiny stones' width), loaded on first use.
    static std::map<std::pair<int, int>, stdsptr<eTexture>> sHD;
    const auto key = std::make_pair(sizeId, id);
    auto it = sHD.find(key);
    if(it == sHD.end()) {
        const auto& blds = eGameTextures::buildings()[sizeId];
        const auto hd = blds.remasteredTall(coll.getTexture(id), "lots", "ruins_" + std::to_string(id % 8));
        it = sHD.emplace(key, hd).first;
    }
    if(it->second) return it->second;
    return coll.getTexture(id);
}

void eRuins::read(eReadStream& src) {
    eBuilding::read(src);
    src >> mWasType;
}

void eRuins::write(eWriteStream& dst) const {
    eBuilding::write(dst);
    dst << mWasType;
}
