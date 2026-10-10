#include "ehealer.h"

#include "textures/egametextures.h"
#include "buildings/esmallhouse.h"
#include "engine/egameboard.h"

eHealer::eHealer(eGameBoard& board) :
    eBasicPatroler(board, &eCharacterTextures::fHealer,
                   eCharacterType::healer) {
    eGameTextures::loadHealer();
    setProvide(eProvide::hygiene, 100000);
}

void eHealer::provideToBuilding(eBuilding* const b) {
    if(!b || provideCount() <= 0) return;
    eBasicPatroler::provideToBuilding(b);
    // A medical visit treats an existing infection as well as restoring
    // hygiene. Full-hygiene houses still need treatment; use the board's
    // recovery path to remove the house from its outbreak and alert count.
    if(const auto house = dynamic_cast<eSmallHouse*>(b)) {
        if(house->plague()) getBoard().healHouse(house);
    }
}

void eHealer::incTime(const int by) {
    const double x0=absX(), y0=absY();
    const bool walking=actionType()==eCharacterActionType::walk;
    eBasicPatroler::incTime(by);
    const double distance=std::hypot(absX()-x0,absY()-y0);
    if((walking || actionType()==eCharacterActionType::walk) &&
       distance<=speed()*.005*by+.001) mPresentation.travel(distance);
}

std::shared_ptr<eTexture> eHealer::getTexture(const eTileSize size) const {
    const auto& tex=eGameTextures::characters()[static_cast<int>(size)].fHealer;
    const auto row=static_cast<int>(rotatedOrientation());
    // Old 12-frame HD sheets and original assets retain their original contract.
    if(tex.fWalk[row].size()!=24 || tex.fIdle.size()!=8)
        return eBasicPatroler::getTexture(size);
    if(actionType()==eCharacterActionType::walk)
        return tex.fWalk[row].getTexture(mPresentation.walkFrame(24,.64));
    if(actionType()==eCharacterActionType::stand) {
        const double clock=mPresentation.ready()?mPresentation.time():time();
        return tex.fIdle[row].getTexture(int(clock/600.0*12)%12);
    }
    return eBasicPatroler::getTexture(size);
}
