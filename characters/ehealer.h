#ifndef EHEALER_H
#define EHEALER_H

#include "ebasicpatroler.h"
#include "ewalkerpresentation.h"

class eHealer : public eBasicPatroler {
public:
    eHealer(eGameBoard& board);
    void incTime(int by) override;
    std::shared_ptr<eTexture> getTexture(eTileSize size) const override;
    void beginVisualTick() { mPresentation.begin(absX(),absY(),time()); }
    void endVisualTick() { mPresentation.end(absX(),absY(),time()); }
    void sampleVisual(double alpha) { mPresentation.sample(alpha); }
    double visualX() const { return x()+(mPresentation.ready()?mPresentation.x()-absX():0); }
    double visualY() const { return y()+(mPresentation.ready()?mPresentation.y()-absY():0); }
private:
    eWalkerPresentation mPresentation;
};

#endif // EHEALER_H
