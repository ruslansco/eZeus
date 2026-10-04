#include "eboatbase.h"

#include "textures/egametextures.h"

eBoatBase::eBoatBase(
        eGameBoard& board, const eCharTexs charTexs,
        const eCharacterType type) :
    eCharacter(board, type),
    mCharTexs(charTexs) {}

void eBoatBase::incTime(const int by) {
    const double x0=absX(), y0=absY();
    eCharacter::incTime(by);
    const double distance=std::hypot(absX()-x0,absY()-y0);
    if(distance<=speed()*.005*by+.001) mPresentation.travel(distance);
}

std::shared_ptr<eTexture> eBoatBase::getTexture(const eTileSize size) const {
    const int id = static_cast<int>(size);
    const auto& texs = eGameTextures::characters();
    const auto& colls = texs[id];
    const auto& charTexs = colls.*mCharTexs;
    const eTextureCollection* coll = nullptr;
    const int oid = static_cast<int>(rotatedOrientation());
    bool wrap = true;
    const auto a = actionType();
    switch(a) {
    case eCharacterActionType::stand:
        return charTexs.fStand.getTexture(oid);
    case eCharacterActionType::fight:
    case eCharacterActionType::fight2:
        if(!charTexs.fRemastered) return nullptr;
        coll = &charTexs.fSwim[oid];
        break;
    case eCharacterActionType::carry:
    case eCharacterActionType::walk:
        coll = &charTexs.fSwim[oid];
        break;
    case eCharacterActionType::die:
        wrap = false;
        coll = &charTexs.fDie[oid];
        break;
    default:
        return nullptr;
    }

    if(charTexs.fRemastered && wrap) {
        // One complete rowing/sail cycle is 1.28 simulation seconds. Sample
        // the same interpolated clock as the hull position; pause stays frozen.
        const double clock=mPresentation.ready()?mPresentation.time():time();
        return coll->getTexture(int(clock/80.0)%coll->size());
    }
    return eCharacter::getTexture(coll, wrap, false);
}
