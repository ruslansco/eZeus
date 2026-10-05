#include "eanimalbuilding.h"
#include "engine/egameboard.h"
#include "engine/etile.h"

eAnimalBuilding::eAnimalBuilding(
         eGameBoard& board,
         eCharacter* const a,
         const eBuildingType type,
         const eCityId cid) :
    eBuilding(board, type, 1, 1, cid),
    mA(a) {

}

eAnimalBuilding::~eAnimalBuilding() {
    if(mA) mA->kill();
}

void eAnimalBuilding::erase() {
    if(mA) {
        mA->kill();
        mA = nullptr;
    }
    const auto tiles = tilesUnder();
    getBoard().buildingErased(this);
    deleteLater();
    for(const auto t : tiles) {
        t->removeAnimalBuilding(this);
    }
}

void eAnimalBuilding::nextMonth() {
    const bool isCattle = type() == eBuildingType::cattle;
    if(!mA && !isCattle) erase();
}

void eAnimalBuilding::read(eReadStream& src) {
    eBuilding::read(src);
    auto& board = getBoard();
    src.readCharacter(&board, [this](eCharacter* const c) {
        mA = c;
    });
}

void eAnimalBuilding::write(eWriteStream& dst) const {
    eBuilding::write(dst);
    dst.writeCharacter(mA);
}

void eAnimalBuilding::setAnimal(eCharacter* const a) {
    mA = a;
}
