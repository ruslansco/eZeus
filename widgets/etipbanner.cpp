#include "etipbanner.h"

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
}

eTipBanner::~eTipBanner() {
    if(mTex) SDL_DestroyTexture(mTex);
    if(mSurf) SDL_FreeSurface(mSurf);
}

void eTipBanner::initialize(const std::string& text) {
    setNoPadding();
    const auto res = resolution();
    const double m = res.multiplier();
    const int px = std::max(8, static_cast<int>(std::round(res.tinyFontSize()*1.08)));
    if(const auto font = eFonts::defaultFont(px)) {
        mSurf = TTF_RenderUTF8_Blended(eFonts::forText(font, text), text.c_str(),
                                       SDL_Color{255, 255, 255, 255});
    }
    if(mSurf) {
        mTW = mSurf->w;
        mTH = mSurf->h;
    }
    const int padY = static_cast<int>(std::round(5*m));
    const int h = mTH + 2*padY;
    mPadX = static_cast<int>(std::round(h*0.55));
    // a gold diamond in front of the text
    mTextX = mPadX + static_cast<int>(std::round(h*0.42));
    resize(mTextX + mTW + mPadX + static_cast<int>(std::round(2*m)), h);
}

void eTipBanner::setStackY(const int y) {
    if(mPlaced) mYOffset += this->y() - y;
    mPlaced = true;
    setY(y);
}

void eTipBanner::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    if(mLeaving) {
        mOut = std::min(1.0, mOut + dt/0.35);
        if(mOut >= 1) mGone = true;
    } else {
        mIn = std::min(1.0, mIn + dt/0.3);
    }
    const bool hover = hovered() && !mLeaving;
    mHover += ((hover ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    mYOffset *= 1 - ePanel::approach(dt, 12);
    if(std::abs(mYOffset) < 0.5) mYOffset = 0;

    const double ein = eMenu3D::easeOutCubic(mIn);
    const double a = ein*(1 - mOut);
    if(a <= 0.003) return;

    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const double m = resolution().multiplier();
    const float w = width();
    const float h = height();
    const float x = p.x();
    const float y = p.y() + static_cast<float>(mYOffset - (1 - ein)*h*0.6);
    const float line = std::max(1.f, static_cast<float>(m));
    const float rad = h/2;

    ePanel::glow(r, x + w/2, y + h*0.7f, w*0.56f, h*1.1f,
                 alpha(SDL_Color{0, 0, 0, 140}, a), false);
    const SDL_FRect pill{x, y, w, h};
    ePanel::roundRect(r, pill, rad, alpha(SDL_Color{30, 50, 92, 238}, a),
                      alpha(SDL_Color{13, 23, 48, 238}, a));
    if(mHover > 0.01) {
        ePanel::roundRect(r, pill, rad, alpha(SDL_Color{255, 255, 255, 16}, a*mHover),
                          alpha(SDL_Color{255, 255, 255, 5}, a*mHover));
    }
    ePanel::roundRect(r, pill, rad,
                      alpha(SDL_Color{246, 208, 120, 255}, a*(0.7 + 0.3*mHover)),
                      alpha(SDL_Color{150, 106, 34, 255}, a*(0.6 + 0.3*mHover)), line);
    ePanel::diamond(r, x + mPadX + static_cast<float>(h*0.12), y + h/2,
                    static_cast<float>(h*0.14), alpha(ePanel::kGold, a));

    if(mSurf && !mTex) {
        mTex = SDL_CreateTextureFromSurface(r, mSurf);
        if(mTex) {
            SDL_SetTextureBlendMode(mTex, SDL_BLENDMODE_BLEND);
            SDL_SetTextureScaleMode(mTex, SDL_ScaleModeLinear);
        }
    }
    if(mTex) {
        const float tx = x + mTextX;
        const float ty = y + (h - mTH)/2;
        const float o = std::max(1.f, static_cast<float>(m));
        SDL_SetTextureColorMod(mTex, 0, 0, 0);
        SDL_SetTextureAlphaMod(mTex, static_cast<Uint8>(130*a));
        const SDL_FRect sd{tx, ty + o, float(mTW), float(mTH)};
        SDL_RenderCopyF(r, mTex, nullptr, &sd);
        SDL_SetTextureColorMod(mTex, 246, 238, 218);
        SDL_SetTextureAlphaMod(mTex, static_cast<Uint8>(255*a));
        const SDL_FRect d{tx, ty, float(mTW), float(mTH)};
        SDL_RenderCopyF(r, mTex, nullptr, &d);
    }
}
