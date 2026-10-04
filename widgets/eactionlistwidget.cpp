#include "eactionlistwidget.h"

#include "eflatbutton.h"
#include "epanelstyle.h"
#include "textures/egeometrybatch.h"

#include <algorithm>

class eStateCheckingFlatButton : public eFlatButton {
public:
    using eFlatButton::eFlatButton;

    using eStateChecker = std::function<bool()>;
    void initialize(const std::string& text,
                    const eAction& a,
                    const eStateChecker& stateChecker) {
        int iRes;
        int mult;
        iResAndMult(iRes, mult);

        const int width = 64*mult;

        setWidth(width);
        setHeight(10*mult);

        setNoPadding();
        setTinyFontSize();
        setText(text);
        setPressAction(a);

        mStateChecker = stateChecker;
    }
protected:
    // a lapis pill with a gold rim; gold when its state holds
    void paintEvent(ePainter& p) override {
        mUpdateCounter++;
        if(mUpdateCounter >= 10 || mFirst) {
            mUpdateCounter = 0;
            const bool on = mStateChecker && mStateChecker();
            if(on != mOn || mFirst) {
                mOn = on;
                if(on) setDarkFontColor();
                else setYellowFontColor();
            }
            mFirst = false;
        }
        const double now = ePanel::time();
        const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
        mLast = now;
        mHover += ((hovered() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
        const auto r = p.renderer();
        eGeometryBatch::sFlush();
        const float h = height();
        const SDL_FRect f{float(p.x()), float(p.y()) + 1, float(width()), h - 2};
        const auto a = static_cast<Uint8>(150 + 80*mHover);
        if(mOn) {
            ePanel::roundRect(r, f, f.h/2, SDL_Color{255, 224, 146, 255}, SDL_Color{196, 140, 48, 255});
        } else {
            ePanel::roundRect(r, f, f.h/2, SDL_Color{30, 50, 92, a}, SDL_Color{14, 24, 50, a});
            ePanel::roundRect(r, f, f.h/2,
                              SDL_Color{240, 200, 110, static_cast<Uint8>(90 + 110*mHover)},
                              SDL_Color{160, 112, 36, static_cast<Uint8>(70 + 90*mHover)},
                              std::max(1.f, h/24.f));
        }
        eButtonBase::paintEvent(p);
    }
private:
    bool mOn = false;
    bool mFirst = true;
    double mHover = 0;
    double mLast = -1;
    int mUpdateCounter = 0;
    eStateChecker mStateChecker = nullptr;
};

eWidget* eActionListWidget::addAction(
        const std::string& text,
        const eAction& a,
        const eStateChecker& stateChecker) {
    const auto b = new eStateCheckingFlatButton(window());
    b->initialize(text, a, stateChecker);
    addWidget(b);
    return b;
}
