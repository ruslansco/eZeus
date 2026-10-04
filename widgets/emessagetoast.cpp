#include "emessagetoast.h"

#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
SDL_Color alpha(SDL_Color c, const double a) {
    c.a = static_cast<Uint8>(std::round(c.a*std::clamp(a, 0.0, 1.0)));
    return c;
}

SDL_Surface* renderText(const int fontPx, const std::string& text,
                        const int wrap,
                        const eFontRole role = eFontRole::body) {
    if(text.empty()) return nullptr;
    const auto font = eFonts::font(role, fontPx);
    if(!font) return nullptr;
    return TTF_RenderUTF8_Blended_Wrapped(eFonts::forText(font, text), text.c_str(),
                                          SDL_Color{255, 255, 255, 255},
                                          std::max(1, wrap));
}
}

eMessageToast::~eMessageToast() {
    for(int i = 0; i < 3; i++) {
        if(mTex[i]) SDL_DestroyTexture(mTex[i]);
        if(mSurf[i]) SDL_FreeSurface(mSurf[i]);
    }
}

void eMessageToast::initialize(const std::string& icon, const eTone tone,
                               const std::string& title,
                               const std::string& text,
                               const std::string& meta,
                               const int width) {
    setNoPadding();
    mIcon = icon;
    mTone = tone;
    mLife = tone == eTone::alarm ? 9 : 7;
    const auto res = resolution();
    const double m = res.multiplier();
    mPad = std::max(4, static_cast<int>(std::round(9*m)));
    mDisc = std::max(14, static_cast<int>(std::round(30*m)));
    mTextX = mPad + mDisc + static_cast<int>(std::round(8*m));
    const int closeW = static_cast<int>(std::round(12*m));
    const int wrap = width - mTextX - mPad - closeW;

    const int tf = res.smallFontSize();
    const int bf = res.tinyFontSize();
    const int mf = std::max(8, static_cast<int>(std::round(bf*0.9)));
    // news is scanned at a glance: a bold sans title, not the display face
    mSurf[0] = renderText(tf, title, wrap, eFontRole::heading);
    mSurf[1] = renderText(bf, text, wrap);
    mSurf[2] = renderText(mf, meta, wrap);
    int h = mPad;
    const int gaps[3] = {0, static_cast<int>(std::round(2*m)),
                         static_cast<int>(std::round(4*m))};
    for(int i = 0; i < 3; i++) {
        if(!mSurf[i]) continue;
        mTW[i] = mSurf[i]->w;
        mTH[i] = mSurf[i]->h;
        h += gaps[i] + mTH[i];
    }
    h += mPad + static_cast<int>(std::round(2*m));
    h = std::max(h, 2*mPad + mDisc);
    resize(width, h);
}

void eMessageToast::setStackY(const int y) {
    if(mPlaced) mYOffset += this->y() - y;
    mPlaced = true;
    setY(y);
}

void eMessageToast::dismiss() {
    mLeaving = true;
}

bool eMessageToast::overClose(const int x, const int y) const {
    const int s = mPad + static_cast<int>(std::round(12*resolution().multiplier()));
    return x >= width() - s && y <= s;
}

bool eMessageToast::mouseReleaseEvent(const eMouseEvent& e) {
    if(e.button() == eMouseButton::left && overClose(e.x(), e.y())) {
        dismiss();
        return true;
    }
    return eButtonBase::mouseReleaseEvent(e);
}

bool eMessageToast::mouseMoveEvent(const eMouseEvent& e) {
    mMouseX = e.x();
    mMouseY = e.y();
    return eButtonBase::mouseMoveEvent(e);
}

bool eMessageToast::mouseLeaveEvent(const eMouseEvent& e) {
    mMouseX = mMouseY = -1;
    return eButtonBase::mouseLeaveEvent(e);
}

void eMessageToast::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    const bool hover = hovered() && !mLeaving;
    mHover += ((hover ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    const bool closeHover = hover && overClose(mMouseX, mMouseY);
    mCloseHover += ((closeHover ? 1.0 : 0.0) - mCloseHover)*ePanel::approach(dt, 18);
    if(mLeaving) {
        mOut = std::min(1.0, mOut + dt/0.45);
        if(mOut >= 1) mGone = true;
    } else {
        mIn = std::min(1.0, mIn + dt/0.4);
        if(!hover) mShown += dt;
        if(mShown > mLife) mLeaving = true;
    }
    mYOffset *= 1 - ePanel::approach(dt, 12);
    if(std::abs(mYOffset) < 0.5) mYOffset = 0;

    const double ein = eMenu3D::easeOutCubic(mIn);
    const double a = ein*(1 - mOut);
    if(a <= 0.003) return;

    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float w = width();
    const float h = height();
    const float x = p.x() + static_cast<float>((1 - ein)*w*0.4 + mOut*w*0.15);
    const float y = p.y() + static_cast<float>(mYOffset);
    const double m = resolution().multiplier();

    // shadow, card, rim
    ePanel::glow(r, x + w/2, y + h*0.62f, w*0.62f, h*0.9f,
                 alpha(SDL_Color{0, 0, 0, 150}, a), false);
    const SDL_FRect card{x, y, w, h};
    const float rad = mPad*0.9f;
    ePanel::roundRect(r, card, rad, alpha(SDL_Color{26, 44, 82, 240}, a),
                      alpha(SDL_Color{12, 20, 42, 240}, a));
    if(mHover > 0.01) {
        ePanel::roundRect(r, card, rad, alpha(SDL_Color{255, 255, 255, 14}, a*mHover),
                          alpha(SDL_Color{255, 255, 255, 4}, a*mHover));
    }
    const float line = std::max(1.f, static_cast<float>(m));
    ePanel::roundRect(r, card, rad,
                      alpha(SDL_Color{246, 208, 120, 255}, a*(0.62 + 0.38*mHover)),
                      alpha(SDL_Color{150, 106, 34, 255}, a*(0.55 + 0.35*mHover)), line);

    // tone disc with its icon
    SDL_Color top{44, 76, 140, 255};
    SDL_Color bottom{18, 34, 74, 255};
    SDL_Color glowC{120, 170, 255, 70};
    if(mTone == eTone::alarm) {
        top = SDL_Color{214, 64, 46, 255};
        bottom = SDL_Color{112, 20, 18, 255};
        glowC = SDL_Color{255, 90, 50, 110};
    } else if(mTone == eTone::good) {
        top = SDL_Color{70, 150, 96, 255};
        bottom = SDL_Color{24, 72, 46, 255};
        glowC = SDL_Color{120, 230, 150, 70};
    }
    const float cx = x + mPad + mDisc/2.f;
    const float cy = y + mPad + mDisc/2.f;
    double pulse = 0.6;
    if(mTone == eTone::alarm) pulse = 0.55 + 0.45*std::sin(now*5.0);
    ePanel::glow(r, cx, cy, mDisc*0.95f, mDisc*0.95f, alpha(glowC, a*pulse), true);
    const SDL_FRect disc{cx - mDisc/2.f, cy - mDisc/2.f, float(mDisc), float(mDisc)};
    ePanel::roundRect(r, disc, mDisc/2.f, alpha(top, a), alpha(bottom, a));
    ePanel::roundRect(r, disc, mDisc/2.f, alpha(SDL_Color{255, 226, 150, 255}, a),
                      alpha(SDL_Color{168, 118, 40, 255}, a), line);
    const int ipx = static_cast<int>(std::round(mDisc*0.58));
    ePanel::drawIcon(r, mIcon, cx, cy, ipx, alpha(ePanel::kIvory, a));

    // title, text, date line
    const SDL_Color colors[3] = {SDL_Color{255, 222, 140, 255},
                                 SDL_Color{236, 230, 214, 255},
                                 SDL_Color{160, 174, 200, 255}};
    const int gaps[3] = {0, static_cast<int>(std::round(2*m)),
                         static_cast<int>(std::round(4*m))};
    float ty = y + mPad;
    for(int i = 0; i < 3; i++) {
        if(!mSurf[i]) continue;
        if(!mTex[i]) {
            mTex[i] = SDL_CreateTextureFromSurface(r, mSurf[i]);
            if(mTex[i]) {
                SDL_SetTextureBlendMode(mTex[i], SDL_BLENDMODE_BLEND);
                SDL_SetTextureScaleMode(mTex[i], SDL_ScaleModeLinear);
            }
        }
        ty += gaps[i];
        if(mTex[i]) {
            const auto c = colors[i];
            SDL_SetTextureColorMod(mTex[i], 0, 0, 0);
            SDL_SetTextureAlphaMod(mTex[i], static_cast<Uint8>(120*a));
            const float o = std::max(1.f, static_cast<float>(m));
            const SDL_FRect sd{x + mTextX, ty + o, float(mTW[i]), float(mTH[i])};
            SDL_RenderCopyF(r, mTex[i], nullptr, &sd);
            SDL_SetTextureColorMod(mTex[i], c.r, c.g, c.b);
            SDL_SetTextureAlphaMod(mTex[i], static_cast<Uint8>(255*a));
            const SDL_FRect d{x + mTextX, ty, float(mTW[i]), float(mTH[i])};
            SDL_RenderCopyF(r, mTex[i], nullptr, &d);
        }
        ty += mTH[i];
    }

    // time left, as a gold thread along the bottom
    const double left = mLeaving ? 0 : std::clamp(1 - mShown/mLife, 0.0, 1.0);
    const float inset = rad;
    const float bw = (w - 2*inset)*static_cast<float>(left);
    if(bw > 1) {
        const float th = std::max(1.f, static_cast<float>(1.5*m));
        ePanel::fill(r, SDL_FRect{x + inset, y + h - th - line - 1, bw, th},
                     alpha(SDL_Color{240, 196, 100, 150}, a));
    }

    // close cross, on hover
    if(mHover > 0.02) {
        const int s = static_cast<int>(std::round(11*m));
        const float ccx = x + w - mPad - s/2.f;
        const float ccy = y + mPad + s/2.f;
        if(mCloseHover > 0.02) {
            ePanel::glow(r, ccx, ccy, s*1.1f, s*1.1f,
                         alpha(SDL_Color{255, 200, 110, 70}, a*mCloseHover), true);
        }
        const SDL_Color cc{static_cast<Uint8>(190 + 65*mCloseHover),
                           static_cast<Uint8>(180 + 50*mCloseHover),
                           static_cast<Uint8>(160 - 20*mCloseHover), 255};
        ePanel::drawIcon(r, "close", ccx, ccy, s, alpha(cc, a*mHover), false);
    }
}
