#ifndef EMAINMENUBASE_H
#define EMAINMENUBASE_H

#include "elabel.h"
#include "emenuscene.h"

// Front-end screen over the living backdrop (eMenuScene). Sub-screens
// slide up out of a soft veil when they appear and go back with Escape.
class eMainMenuBase : public eLabel {
public:
    using eLabel::eLabel;
    ~eMainMenuBase();

    void initialize(const eMenuShot shot = eMenuShot::adventures,
                    const bool animateEntrance = true);
    // Escape runs this (deferred to the end of the frame).
    void setBackAction(const eAction& a) { mBackAction = a; }
protected:
    void paintEvent(ePainter& p) override;
    bool keyPressEvent(const eKeyPressEvent& e) override;
private:
    void animateEntrance();

    eMenuShot mShot = eMenuShot::adventures;
    bool mAnimate = false;
    bool mEntranceDone = true;
    double mEnterStart = -1;
    std::vector<eWidget*> mEntering;
    SDL_Texture* mEntranceTex = nullptr;
    eAction mBackAction;
};

#endif // EMAINMENUBASE_H
