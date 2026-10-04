#ifndef EBOATBASE_H
#define EBOATBASE_H

#include "echaracter.h"
#include "ewalkerpresentation.h"

#include "textures/echaractertextures.h"

class eBoatBase : public eCharacter {
public:
    using eCharTexs = eTradeBoatTextures eCharacterTextures::*;
    eBoatBase(eGameBoard& board, const eCharTexs charTexs,
              const eCharacterType type);

    std::shared_ptr<eTexture> getTexture(const eTileSize size) const;

    void incTime(int by) override;
    void beginVisualTick() { mPresentation.begin(absX(),absY(),time()); }
    void endVisualTick() { mPresentation.end(absX(),absY(),time()); }
    void sampleVisual(double alpha) { mPresentation.sample(alpha); }
    double visualX() const { return x()+(mPresentation.ready()?mPresentation.x()-absX():0); }
    double visualY() const { return y()+(mPresentation.ready()?mPresentation.y()-absY():0); }
    void setCharTexs(const eCharTexs& texs);
private:
    eCharTexs mCharTexs;
    eWalkerPresentation mPresentation;
};

#endif // EBOATBASE_H
