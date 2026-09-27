#include "epanelwidgets.h"

#include "epanelstyle.h"
#include "emenu3d.h"
#include "efonts.h"
#include "audio/esounds.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
double frameDt(double& last) {
    const double now = ePanel::time();
    const double dt = last < 0 ? 0 : std::min(0.1, now - last);
    last = now;
    return dt;
}

double ease(const double t) {
    const double u = 1 - std::clamp(t, 0.0, 1.0);
    return 1 - u*u*u;
}
}

// --- category button ------------------------------------------------------------------------
ePanelCategoryButton::ePanelCategoryButton(eMainWindow* const window,
                                           const std::string& icon) :
    eCheckableButton(window), mIcon(icon) {
    setNoPadding();
}

void ePanelCategoryButton::paintEvent(ePainter& p) {
    const double dt = frameDt(mLast);
    mHover += ((hovered() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    mActive += ((checked() ? 1.0 : 0.0) - mActive)*ePanel::approach(dt, 10);
    mPress += ((pressed() ? 1.0 : 0.0) - mPress)*ePanel::approach(dt, 24);
    const float d = std::min(width(), height())*0.97f;
    ePanel::medallion(p.renderer(), p.x() + width()*0.5f, p.y() + height()*0.5f, d,
                      mIcon, mHover, mActive, mPress, enabled());
}

// --- action button ----------------------------------------------------------------------------
ePanelActionButton::ePanelActionButton(eMainWindow* const window,
                                       const std::string& icon) :
    eButton(window), mIcon(icon) {
    setNoPadding();
}

ePanelActionButton::~ePanelActionButton() {
    if(mBadgeTex) SDL_DestroyTexture(mBadgeTex);
}

void ePanelActionButton::paintEvent(ePainter& p) {
    const double dt = frameDt(mLast);
    const bool on = mActiveF && mActiveF();
    mHover += ((hovered() && enabled() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    mActive += ((on ? 1.0 : 0.0) - mActive)*ePanel::approach(dt, 10);
    mPress += ((pressed() ? 1.0 : 0.0) - mPress)*ePanel::approach(dt, 24);
    const float d = mDiameter > 0 ? mDiameter : std::min(width(), height())*0.97f;
    const auto r = p.renderer();
    ePanel::medallion(r, p.x() + width()*0.5f, p.y() + height()*0.5f, d,
                      mIcon, mHover, mActive, mPress, enabled());
    const int n = mBadgeF ? mBadgeF() : 0;
    if(n <= 0) {
        mBadgeBorn = -1;
        return;
    }
    const double now = ePanel::time();
    if(n != mBadgeN) {
        if(n > mBadgeN) mBadgeBorn = now;     // a new message: the badge pops
        mBadgeN = n;
        if(mBadgeTex) SDL_DestroyTexture(mBadgeTex);
        const auto font = eFonts::defaultFont(std::max(8, static_cast<int>(std::round(d*.3f))));
        mBadgeTex = eMenu3D::makeText(r, font, n > 99 ? "99+" : std::to_string(n),
                                      SDL_Color{255, 255, 255, 255}, mBadgeW, mBadgeH);
    }
    const double age = mBadgeBorn < 0 ? 1 : now - mBadgeBorn;
    const float pop = static_cast<float>(age < .4 ? 1 + .35*std::sin(age/.4*3.14159) : 1);
    const float bh = d*.42f*pop;
    const float bw = std::max(bh, mBadgeW + bh*.5f);
    const float cx = p.x() + width()*.5f + d*.34f;
    const float cy = p.y() + height()*.5f - d*.34f;
    const SDL_FRect box{cx - bw/2, cy - bh/2, bw, bh};
    ePanel::glow(r, cx, cy, bw*.9f, bh*.9f, SDL_Color{255, 60, 40, 90}, true);
    ePanel::roundRect(r, box, bh/2, SDL_Color{240, 70, 50, 255}, SDL_Color{170, 30, 26, 255});
    ePanel::roundRect(r, box, bh/2, SDL_Color{255, 220, 150, 230}, SDL_Color{200, 140, 60, 230},
                      std::max(1.f, bh/12.f));
    if(mBadgeTex) {
        const SDL_FRect t{cx - mBadgeW/2.f, cy - mBadgeH/2.f, float(mBadgeW), float(mBadgeH)};
        SDL_RenderCopyF(r, mBadgeTex, nullptr, &t);
    }
}

// --- building tile ------------------------------------------------------------------------------
void ePanelTileButton::paintEvent(ePainter& p) {
    const double dt = frameDt(mLast);
    mHover += ((hovered() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float x = p.x(), y = p.y(), w = width(), h = height();
    const float lift = static_cast<float>(-h*0.03*mHover + (pressed() ? h*0.03 : 0));
    const float rad = h*0.16f;
    ePanel::glow(r, x + w/2, y + h*0.62f, w*0.62f, h*0.62f, SDL_Color{0, 0, 0, 120}, false);
    if(mHover > 0.01) {
        ePanel::glow(r, x + w/2, y + h/2, w*0.75f, h*0.85f,
                     SDL_Color{255, 196, 90, static_cast<Uint8>(55*mHover)}, true);
    }
    const SDL_FRect box{x, y + lift, w, h};
    ePanel::roundRect(r, box, rad, SDL_Color{34, 54, 94, 225}, SDL_Color{10, 18, 38, 235});
    // a soft inner light at the top of the tile
    ePanel::roundRect(r, SDL_FRect{x + 1, y + lift + 1, w - 2, h*0.45f}, rad,
                      SDL_Color{120, 160, 220, static_cast<Uint8>(36 + 30*mHover)},
                      SDL_Color{120, 160, 220, 0});
    const Uint8 ra = static_cast<Uint8>(110 + 130*mHover);
    ePanel::roundRect(r, box, rad, SDL_Color{255, 222, 140, ra}, SDL_Color{190, 140, 50, ra},
                      std::max(1.f, h/30.f));
    const auto& tex = texture();
    if(tex) {
        const int tw = tex->width();
        const int th = tex->height();
        const float s = std::min(w/tw, h/th)*0.94f;
        const SDL_Rect src{tex->x(), tex->y(), tw, th};
        const int dw = static_cast<int>(std::round(tw*s));
        const int dh = static_cast<int>(std::round(th*s));
        const SDL_Rect dst{static_cast<int>(std::round(x + (w - dw)/2)),
                           static_cast<int>(std::round(y + lift + (h - dh)/2)), dw, dh};
        tex->render(r, src, dst);
    }
    if(mOpensList) {
        const int px = std::max(8, static_cast<int>(std::round(h*0.30f)));
        ePanel::drawIcon(r, "chevron", x + w - px*0.62f, y + lift + px*0.62f, px,
                         ePanel::kGoldPale);
    }
}

// --- info / map tabs ---------------------------------------------------------------------------
ePanelTabs::~ePanelTabs() {
    for(auto& t : mTextTex) {
        if(t) SDL_DestroyTexture(t);
    }
}

void ePanelTabs::initialize(const std::string& left, const std::string& right) {
    mText[0] = left;
    mText[1] = right;
    setNoPadding();
}

void ePanelTabs::setIndex(const int i) {
    if(i == mIndex) return;
    mIndex = i;
    if(mAction) mAction(i);
}

void ePanelTabs::paintEvent(ePainter& p) {
    const double dt = frameDt(mLast);
    mSlide += (mIndex - mSlide)*ePanel::approach(dt, 16);
    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float x = p.x(), y = p.y(), w = width(), h = height();
    const float rad = h/2;
    ePanel::roundRect(r, SDL_FRect{x, y, w, h}, rad, SDL_Color{6, 12, 26, 225}, SDL_Color{14, 24, 46, 225});
    ePanel::roundRect(r, SDL_FRect{x, y, w, h}, rad, SDL_Color{230, 186, 90, 130},
                      SDL_Color{150, 106, 34, 130}, std::max(1.f, h/22.f));
    const float inset = std::max(2.f, h*0.1f);
    const float segW = w/2;
    const SDL_FRect slider{x + inset + static_cast<float>(mSlide)*segW, y + inset,
                           segW - 2*inset, h - 2*inset};
    ePanel::glow(r, slider.x + slider.w/2, slider.y + slider.h/2, slider.w*0.7f, slider.h*1.3f,
                 SDL_Color{255, 190, 80, 60}, true);
    ePanel::roundRect(r, slider, slider.h/2, SDL_Color{255, 224, 146, 255}, SDL_Color{196, 140, 48, 255});
    ePanel::roundRect(r, SDL_FRect{slider.x + 1, slider.y + 1, slider.w - 2, slider.h*0.45f}, slider.h/2,
                      SDL_Color{255, 255, 255, 70}, SDL_Color{255, 255, 255, 0});

    const int fontPx = std::max(9, static_cast<int>(std::round(h*0.5f)));
    const char* icons[2] = {"info", "map"};
    for(int i = 0; i < 2; i++) {
        if(!mTextTex[i] && !mText[i].empty()) {
            const auto font = eFonts::defaultFont(fontPx);
            mTextTex[i] = eMenu3D::makeText(r, font, mText[i], SDL_Color{255, 255, 255, 255},
                                            mTextW[i], mTextH[i]);
        }
        const double on = 1 - std::min(1.0, std::abs(mSlide - i));
        SDL_Color c = ePanel::kGold;
        if(mHoverIndex == i && mIndex != i) c = ePanel::kGoldPale;
        c = SDL_Color{static_cast<Uint8>(c.r + (ePanel::kInk.r - c.r)*on),
                      static_cast<Uint8>(c.g + (ePanel::kInk.g - c.g)*on),
                      static_cast<Uint8>(c.b + (ePanel::kInk.b - c.b)*on), 255};
        const int ipx = std::max(8, static_cast<int>(std::round(h*0.56f)));
        const float gap = h*0.18f;
        const float total = ipx + gap + mTextW[i];
        const float cx0 = x + i*segW + (segW - total)/2;
        ePanel::drawIcon(r, icons[i], cx0 + ipx/2.f, y + h/2, ipx, c, on < 0.5);
        if(mTextTex[i]) {
            SDL_SetTextureColorMod(mTextTex[i], c.r, c.g, c.b);
            const SDL_FRect d{cx0 + ipx + gap, y + (h - mTextH[i])/2.f, float(mTextW[i]), float(mTextH[i])};
            SDL_RenderCopyF(r, mTextTex[i], nullptr, &d);
        }
    }
}

bool ePanelTabs::mousePressEvent(const eMouseEvent& e) {
    return e.button() == eMouseButton::left;
}

bool ePanelTabs::mouseReleaseEvent(const eMouseEvent& e) {
    if(e.button() != eMouseButton::left) return false;
    const int i = e.x() < width()/2 ? 0 : 1;
    if(i != mIndex) eSounds::playButtonSound();
    setIndex(i);
    return true;
}

bool ePanelTabs::mouseMoveEvent(const eMouseEvent& e) {
    mHoverIndex = e.x() < width()/2 ? 0 : 1;
    return true;
}

bool ePanelTabs::mouseEnterEvent(const eMouseEvent& e) {
    mHoverIndex = e.x() < width()/2 ? 0 : 1;
    return true;
}

bool ePanelTabs::mouseLeaveEvent(const eMouseEvent& e) {
    (void)e;
    mHoverIndex = -1;
    return true;
}

// --- price pill --------------------------------------------------------------------------------------
void ePricePill::paintEvent(ePainter& p) {
    const auto r = p.renderer();
    const SDL_FRect box{float(p.x()), float(p.y()), float(width()), float(height())};
    ePanel::roundRect(r, box, height()/2.f, SDL_Color{8, 14, 30, 235}, SDL_Color{16, 26, 50, 235});
    ePanel::roundRect(r, box, height()/2.f, SDL_Color{240, 200, 110, 170}, SDL_Color{170, 120, 40, 170},
                      std::max(1.f, height()/16.f));
}

// --- veil --------------------------------------------------------------------------------------------
void ePanelVeil::trigger() {
    mStart = ePanel::time();
}

void ePanelVeil::paintEvent(ePainter& p) {
    const double t = (ePanel::time() - mStart)/0.38;
    if(t >= 1 || t < 0) return;
    const auto r = p.renderer();
    const double e = ease(t);
    const float x = p.x(), y = p.y(), w = width(), h = height();
    const float edge = static_cast<float>(y + h*e);
    const Uint8 a = static_cast<Uint8>(215*(1 - e*0.6));
    ePanel::gradient(r, SDL_FRect{x, edge, w, y + h - edge}, SDL_Color{12, 22, 44, a}, SDL_Color{8, 14, 30, a});
    ePanel::goldRule(r, x, edge - 1, w, std::max(1.f, h/160.f), static_cast<Uint8>(230*(1 - e)), false);
    ePanel::glow(r, x + w/2, edge, w*0.6f, h*0.05f, SDL_Color{255, 200, 100, static_cast<Uint8>(70*(1 - e))}, true);
}

ePanelPillButton::ePanelPillButton(eMainWindow* const window,
                                   const std::string& text) :
    eButton(window), mLabel(text) {
    setNoPadding();
}

ePanelPillButton::~ePanelPillButton() {
    if(mTex) SDL_DestroyTexture(mTex);
}

void ePanelPillButton::paintEvent(ePainter& p) {
    const double dt = frameDt(mLast);
    mHover += ((hovered() && enabled() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
    mPress += ((pressed() ? 1.0 : 0.0) - mPress)*ePanel::approach(dt, 24);
    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float h = height();
    const float w = width();
    const float sh = static_cast<float>(mPress*h*0.04);
    const SDL_FRect f{float(p.x()), p.y() + sh, w, h};
    const double hv = mHover;
    ePanel::glow(r, f.x + w/2, f.y + h*0.6f, w*0.55f, h*0.9f, SDL_Color{0, 0, 0, 110}, false);
    if(hv > 0.01) {
        ePanel::glow(r, f.x + w/2, f.y + h/2, w*0.6f, h*1.1f,
                     SDL_Color{255, 196, 90, static_cast<Uint8>(60*hv)}, true);
    }
    const auto mix = [hv](const SDL_Color a, const SDL_Color b) {
        return SDL_Color{static_cast<Uint8>(a.r + (b.r - a.r)*hv),
                         static_cast<Uint8>(a.g + (b.g - a.g)*hv),
                         static_cast<Uint8>(a.b + (b.b - a.b)*hv), 255};
    };
    ePanel::roundRect(r, f, h/2, mix(SDL_Color{34, 58, 104, 255}, SDL_Color{255, 224, 146, 255}),
                      mix(SDL_Color{14, 26, 56, 255}, SDL_Color{196, 140, 48, 255}));
    ePanel::roundRect(r, SDL_FRect{f.x + 1, f.y + 1, w - 2, h*0.45f}, h/2,
                      SDL_Color{255, 255, 255, 40}, SDL_Color{255, 255, 255, 0});
    ePanel::roundRect(r, f, h/2, SDL_Color{246, 208, 120, 255}, SDL_Color{160, 112, 36, 255},
                      std::max(1.f, h/24.f));
    const int px = std::max(9, static_cast<int>(std::round(h*0.46f)));
    if(!mTex || mTexPx != px) {
        if(mTex) SDL_DestroyTexture(mTex);
        mTexPx = px;
        mTex = eMenu3D::makeText(r, eFonts::defaultFont(px), mLabel,
                                 SDL_Color{255, 255, 255, 255}, mTW, mTH);
    }
    if(mTex) {
        const auto c = mix(ePanel::kGoldPale, ePanel::kInk);
        SDL_SetTextureColorMod(mTex, c.r, c.g, c.b);
        const SDL_FRect d{std::round(f.x + (w - mTW)/2), std::round(f.y + (h - mTH)/2),
                          float(mTW), float(mTH)};
        SDL_RenderCopyF(r, mTex, nullptr, &d);
    }
}
