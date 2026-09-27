#include "etemplestatuebuilding.h"

#include "textures/egametextures.h"
#include "engine/egameboard.h"

eTempleStatueBuilding::eTempleStatueBuilding(
        const eGodType god,
        const int id, eGameBoard& board,
        const eCityId cid) :
    eSanctBuilding({{0, 0, 1}}, board,
                   eBuildingType::templeStatue,
                   1, 1, cid),
    mGod(god), mId(id) {

}

std::shared_ptr<eTexture>
eTempleStatueBuilding::getTexture(const eTileSize size) const {
    const int p = progress();
    if(p <= 0) return nullptr;
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings()[sizeId];
    const eTextureCollection* coll = nullptr;
    switch(mGod) {
    case eGodType::aphrodite:
        coll = &blds.fAphroditeStatues;
        break;
    case eGodType::apollo:
        coll = &blds.fApolloStatues;
        break;
    case eGodType::ares:
        coll = &blds.fAresStatues;
        break;
    case eGodType::artemis:
        coll = &blds.fArtemisStatues;
        break;
    case eGodType::athena:
        coll = &blds.fAthenaStatues;
        break;
    case eGodType::atlas:
        coll = &blds.fAtlasStatues;
        break;
    case eGodType::demeter:
        coll = &blds.fDemeterStatues;
        break;
    case eGodType::dionysus:
        coll = &blds.fDionysusStatues;
        break;
    case eGodType::hades:
        coll = &blds.fHadesStatues;
        break;
    case eGodType::hephaestus:
        coll = &blds.fHephaestusStatues;
        break;
    case eGodType::hera:
        coll = &blds.fHeraStatues;
        break;
    case eGodType::hermes:
        coll = &blds.fHermesStatues;
        break;
    case eGodType::poseidon:
        coll = &blds.fPoseidonStatues;
        break;
    case eGodType::zeus:
        coll = &blds.fZeusStatues;
        break;
    }
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
        dirId=(mId+2)%4;
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
    // Remastered statue: row in the order of eBuildingTextures::sStatueGods.
    int hdRow = -1;
    switch(mGod) {
    case eGodType::zeus: hdRow = 0; break;
    case eGodType::poseidon: hdRow = 1; break;
    case eGodType::hades: hdRow = 2; break;
    case eGodType::demeter: hdRow = 3; break;
    case eGodType::athena: hdRow = 4; break;
    case eGodType::artemis: hdRow = 5; break;
    case eGodType::apollo: hdRow = 6; break;
    case eGodType::ares: hdRow = 7; break;
    case eGodType::hephaestus: hdRow = 8; break;
    case eGodType::aphrodite: hdRow = 9; break;
    case eGodType::hermes: hdRow = 10; break;
    case eGodType::dionysus: hdRow = 11; break;
    case eGodType::hera: hdRow = 12; break;
    case eGodType::atlas: hdRow = 13; break;
    }
    if(hdRow >= 0) {
        eGameTextures::loadGodStatueAnimationHD(hdRow,sizeId);
        // Only completed sanctuaries awaken. Display time drives cosmetic motion;
        // construction, divine visits and production retain their simulation clocks.
        const bool awake=monument() && monument()->finished();
        const int pose=awake?(board.animFrame(8.0)+(textureTime()-board.frame())/4)%16:16;
        if(const auto& animated=blds.fGodStatuesAnimated[hdRow][dirId][pose]) return animated;
        eGameTextures::loadGodStatuesHD();
        if(const auto& hd = blds.fGodStatuesHD[hdRow][dirId]) return hd;
    }
    if(!coll) return nullptr;
    return coll->getTexture(dirId);
}
