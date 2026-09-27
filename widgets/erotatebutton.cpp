#include "erotatebutton.h"

#include "audio/esounds.h"
#include "elanguage.h"
#include "epanelstyle.h"

#include <cmath>

eRotateButton::eRotateButton(eMainWindow* const window) :
    eLabel(window) {
    setNoPadding();
    updateTexture();
    fitContent();
}

void eRotateButton::setEnabled(const bool b) {
    mEnabled = b;
}

bool eRotateButton::enabled() const {
    return mEnabled;
}

bool eRotateButton::pressed() const {
    return mPressed;
}

bool eRotateButton::hovered() const {
    return mHover;
}

void eRotateButton::setDirection(const eWorldDirection dir) {
    mDirection = dir;
    updateTexture();
}

void eRotateButton::setDirectionSetter(const eDirectionSetter& s) {
    mSetter = s;
}

bool eRotateButton::mousePressEvent(const eMouseEvent& e) {
    if(!mEnabled) return false;
    const auto b = e.button();
    if(b == eMouseButton::left) {
        mPressed = true;

        eSounds::playButtonSound();
        updateTexture();
        return true;
    } else {
        return false;
    }
}

bool eRotateButton::mouseReleaseEvent(const eMouseEvent& e) {
    if(!mEnabled) return false;
    const auto b = e.button();
    if(b == eMouseButton::left) {
        mPressed = false;
        const auto oldD = mDirection;
        if(mHovered == eButtonHoverPortion::center) {
            mDirection = eWorldDirection::N;
        } else if(mHovered == eButtonHoverPortion::left) {
            if(mDirection == eWorldDirection::N) {
                mDirection = eWorldDirection::E;
            } else {
                const int i = static_cast<int>(mDirection) - 1;
                mDirection = static_cast<eWorldDirection>(i);
            }
        } else if(mHovered == eButtonHoverPortion::right) {
            if(mDirection == eWorldDirection::E) {
                mDirection = eWorldDirection::N;
            } else {
                const int i = static_cast<int>(mDirection) + 1;
                mDirection = static_cast<eWorldDirection>(i);
            }
        }
        if(mDirection == oldD) return true;
        if(mSetter) mSetter(mDirection);
        updateTexture();
        return true;
    } else {
        return false;
    }
}

bool eRotateButton::mouseMoveEvent(const eMouseEvent& e) {
    if(!mEnabled) return false;
    (void)e;
    const int x = e.x();
    const int w = width()/3;
    if(x < w) {
        mHovered = eButtonHoverPortion::left;
        setTooltip(eLanguage::zeusText(68, 45));
    } else if(x < 2*w) {
        mHovered = eButtonHoverPortion::center;
        setTooltip(eLanguage::zeusText(68, 44));
    } else {
        mHovered = eButtonHoverPortion::right;
        setTooltip(eLanguage::zeusText(68, 46));
    }
    updateTexture();
    return true;
}

bool eRotateButton::mouseEnterEvent(const eMouseEvent& e) {
    if(!mEnabled) return false;
    (void)e;
    mHover = true;
    updateTexture();
    return true;
}

bool eRotateButton::mouseLeaveEvent(const eMouseEvent& e) {
    if(!mEnabled) return false;
    (void)e;
    mHover = false;
    updateTexture();
    return true;
}

void eRotateButton::updateTexture() {
    int dx = 0;
    if(mEnabled) {
        if(!mHover) {
            dx = 0;
        } else if(mPressed) {
            if(mHovered == eButtonHoverPortion::center) {
                dx = 4;
            } else if(mHovered == eButtonHoverPortion::left) {
                dx = 5;
            } else if(mHovered == eButtonHoverPortion::right) {
                dx = 6;
            }
        } else { // !mPressed
            if(mHovered == eButtonHoverPortion::center) {
                dx = 1;
            } else if(mHovered == eButtonHoverPortion::left) {
                dx = 2;
            } else if(mHovered == eButtonHoverPortion::right) {
                dx = 3;
            }
        }
    } else {
        dx = 7;
    }
    const int ddx = static_cast<int>(mDirection);
    const int texId = 8*ddx + dx;

    const auto res = resolution();
    const auto uiScale = res.uiScale();
    const int iRes = static_cast<int>(uiScale);

    const auto& intrfc = eGameTextures::interface();
    const auto& coll = intrfc[iRes].fRotation;

    setTexture(coll.getTexture(texId));
}

void eRotateButton::paintEvent(ePainter& p) {
    if(!mModern) return eLabel::paintEvent(p);
    const auto r = p.renderer();
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    for(int i = 0; i < 3; i++) {
        const auto portion = i == 0 ? eButtonHoverPortion::left :
                             i == 1 ? eButtonHoverPortion::center :
                                      eButtonHoverPortion::right;
        const double target = (mHover && mEnabled && mHovered == portion) ? 1 : 0;
        mHoverAnim[i] += (target - mHoverAnim[i])*ePanel::approach(dt, 14);
    }
    // the needle turns the short way round to the new heading
    const double target = 90.0*static_cast<int>(mDirection);
    double diff = std::fmod(target - mNeedle + 540.0, 360.0) - 180.0;
    mNeedle += diff*ePanel::approach(dt, 9);

    const float x = p.x(), y = p.y(), w = width(), h = height();
    const float ph = h*0.78f;
    const SDL_FRect pill{x, y + (h - ph)/2, w, ph};
    ePanel::roundRect(r, pill, ph/2, SDL_Color{6, 12, 26, 230}, SDL_Color{16, 26, 50, 230});
    ePanel::roundRect(r, pill, ph/2, SDL_Color{236, 192, 96, 150}, SDL_Color{150, 106, 34, 120},
                      std::max(1.f, h/26.f));
    const float seg = w/3;
    const int ipx = std::max(8, static_cast<int>(std::round(ph*0.72f)));
    for(const int i : {0, 2}) {
        const double hv = mHoverAnim[i];
        const float cx = x + seg*(i + .5f) + (i == 0 ? -seg*.08f : seg*.08f);
        if(hv > .01) {
            ePanel::glow(r, cx, y + h/2, seg*.55f, ph*.7f, SDL_Color{255, 200, 110, static_cast<Uint8>(70*hv)}, true);
        }
        const SDL_Color c{static_cast<Uint8>(236 + 19*hv), static_cast<Uint8>(192 + 40*hv),
                          static_cast<Uint8>(96 + 64*hv), static_cast<Uint8>(mEnabled ? 255 : 110)};
        ePanel::drawIcon(r, i == 0 ? "rotate_left" : "rotate_right", cx, y + h/2, ipx, c);
    }
    const float d = h*0.98f;
    ePanel::medallion(r, x + w/2, y + h/2, d, "", mHoverAnim[1], 0, mPressed ? 1 : 0, mEnabled);
    const int cpx = std::max(8, static_cast<int>(std::round(d*0.6f)));
    const SDL_Color cc{static_cast<Uint8>(236 + 19*mHoverAnim[1]), static_cast<Uint8>(192 + 40*mHoverAnim[1]),
                       static_cast<Uint8>(96 + 64*mHoverAnim[1]), 255};
    ePanel::drawIcon(r, "compass", x + w/2, y + h/2, cpx, cc, true, mNeedle);
}
