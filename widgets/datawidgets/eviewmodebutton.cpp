#include "eviewmodebutton.h"

#include "textures/egametextures.h"
#include "widgets/epanelstyle.h"

#include <cmath>

eViewModeButton::eViewModeButton(const std::string& text,
                                 const eViewMode vm,
                                 eMainWindow* const window) :
    eCheckableButton(window), mVM(vm) {
    setCheckAction([this](const bool) {
        if(!mGW) return;
        const auto gwvm = mGW->viewMode();
        if(gwvm == mVM) {
            mGW->setViewMode(eViewMode::defaultView);
        } else {
            mGW->setViewMode(mVM);
        }
    });

    const auto& intrfc = eGameTextures::interface();
    const auto res = resolution();
    const int iRes = static_cast<int>(res.uiScale());
    const auto& texs = intrfc[iRes].fSeeButton;

    setTexture(texs.getTexture(0));
    setHoverTexture(texs.getTexture(1));
    setCheckedTexture(texs.getTexture(2));
    setVeryVeryTinyPadding();
    fitContent();

    const auto label = new eLabel(text, window);
    label->setVerySmallFontSize();
    label->setNoPadding();
    label->fitContent();
    addWidget(label);
    label->align(eAlignment::center);
    mLabel = label;
}

void eViewModeButton::setGameWidget(eGameWidget* const gw) {
    mGW = gw;
}

void eViewModeButton::paintEvent(ePainter& p) {
    if(mGW) {
        const auto vm = mGW->viewMode();
        setChecked(vm == mVM);
    }
    // a lapis pill with a gold rim; lit while its view is on
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    mHover += ((hovered() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    mOn += ((checked() ? 1.0 : 0.0) - mOn)*ePanel::approach(dt, 12);
    const int state = (checked() || hovered()) ? 1 : 0;
    if(mLabel && state != mColorState) {
        mColorState = state;
        if(state) mLabel->setYellowFontColor();
        else mLabel->setLightFontColor();
    }
    const auto r = p.renderer();
    const float x = p.x(), y = p.y(), w = width(), h = height();
    const SDL_FRect box{x + 1, y + 1, w - 2, h - 2};
    if(mOn > .01 || mHover > .01) {
        ePanel::glow(r, x + w/2, y + h/2, w*.6f, h*1.2f,
                     SDL_Color{255, 196, 90, static_cast<Uint8>(40*mHover + 45*mOn)}, true);
    }
    const auto mix = [](const Uint8 a, const Uint8 b, const double t) {
        return static_cast<Uint8>(std::round(a + (b - a)*t));
    };
    const double lit = std::max(mOn, .5*mHover);
    ePanel::roundRect(r, box, box.h/2,
                      SDL_Color{mix(22, 70, lit), mix(38, 58, lit), mix(70, 30, lit), 235},
                      SDL_Color{mix(8, 40, lit), mix(14, 30, lit), mix(32, 12, lit), 240});
    ePanel::roundRect(r, box, box.h/2, SDL_Color{240, 200, 110, static_cast<Uint8>(140 + 100*lit)},
                      SDL_Color{160, 112, 36, static_cast<Uint8>(120 + 100*lit)}, std::max(1.f, h/18.f));
    eWidget::paintEvent(p);
}
