#include "efonts.h"
#include "emainmenu.h"

#include "elanguage.h"
#include "emainwindow.h"
#include "egamedir.h"
#include "audio/esounds.h"
#include "textures/egeometrybatch.h"

#include <SDL_image.h>

#include <algorithm>
#include <cmath>

using namespace eMenu3D;

namespace {
bool sIntroPlayed = false;

const double kLeaveLength = 0.38;
const double kStrikeLeaveLength = 0.5;
const double kQuitLength = 0.55;
const double kDeg = 3.14159265358979/180;

// Text of a language key, or the English fallback when the key is missing.
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

const SDL_Color kIvory{242, 234, 214, 255};
const SDL_Color kGold{255, 212, 92, 255};
const SDL_Color kGoldDim{214, 184, 112, 255};

void fillRect(SDL_Renderer* const r, const float x, const float y,
              const float w, const float h, const SDL_Color c) {
    SDL_SetRenderDrawColor(r, c.r, c.g, c.b, c.a);
    const SDL_FRect rect{x, y, w, h};
    SDL_RenderFillRectF(r, &rect);
}

void frameRect(SDL_Renderer* const r, const float x, const float y,
               const float w, const float h, const float t,
               const SDL_Color c) {
    fillRect(r, x, y, w, t, c);
    fillRect(r, x, y + h - t, w, t, c);
    fillRect(r, x, y + t, t, h - 2*t, c);
    fillRect(r, x + w - t, y + t, t, h - 2*t, c);
}

void diamond(SDL_Renderer* const r, SDL_Texture* const white,
             const float cx, const float cy, const float s,
             const SDL_Color c) {
    const SDL_FPoint q[4] = {{cx, cy - s}, {cx + s, cy}, {cx, cy + s}, {cx - s, cy}};
    const SDL_Color cs[4] = {c, c, c, c};
    drawFlat(r, white, q, cs);
}

void drawText(SDL_Renderer* const r, SDL_Texture* const t,
              const float x, const float y, const int w, const int h,
              const float shadow) {
    if(!t) return;
    SDL_SetTextureColorMod(t, 0, 0, 0);
    SDL_SetTextureAlphaMod(t, 150);
    const SDL_FRect sd{x, y + shadow, float(w), float(h)};
    SDL_RenderCopyF(r, t, nullptr, &sd);
    SDL_SetTextureColorMod(t, 255, 255, 255);
    SDL_SetTextureAlphaMod(t, 255);
    const SDL_FRect d{x, y, float(w), float(h)};
    SDL_RenderCopyF(r, t, nullptr, &d);
}

// A soft glow or shadow (the scene's radial dot) centred on (x, y).
void blob(SDL_Renderer* const r, SDL_Texture* const dot,
          const float x, const float y, const float rx, const float ry,
          const SDL_Color c, const bool additive) {
    if(!dot || c.a == 0) return;
    SDL_SetTextureBlendMode(dot, additive ? SDL_BLENDMODE_ADD : SDL_BLENDMODE_BLEND);
    const SDL_Vertex v[4] = {{{x - rx, y - ry}, c, {0, 0}},
                             {{x + rx, y - ry}, c, {1, 0}},
                             {{x + rx, y + ry}, c, {1, 1}},
                             {{x - rx, y + ry}, c, {0, 1}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, dot, v, 4, ids, 6);
}

} // namespace

eMainMenu::~eMainMenu() {
    freeTextures();
    if(mLogo) SDL_DestroyTexture(mLogo);
    if(mLogoBolt) SDL_DestroyTexture(mLogoBolt);
}

void eMainMenu::setContinue(const std::string& subtitle, const eAction& a) {
    mContinueSub = subtitle;
    mContinueA = a;
}

void eMainMenu::initialize(const eAction& newGameA,
                           const eAction& loadGameA,
                           const eAction& editGameA,
                           const eAction& settingsA,
                           const eAction& quitA,
                           const eAction& leaderA) {
    eMainMenuBase::initialize(eMenuShot::main, false);
    auto& scene = eMenuScene::instance();

    if(mContinueA) {
        eItem c;
        c.fText = tr("menu_continue", "Continue");
        c.fSub = mContinueSub;
        c.fAction = mContinueA;
        c.fKind = eKind::strike;
        c.fHero = true;
        mItems.push_back(c);
    }
    const auto add = [&](const std::string& text, const eAction& a, const eKind k) {
        eItem i;
        i.fText = text;
        i.fAction = a;
        i.fKind = k;
        mItems.push_back(i);
    };
    add(eLanguage::zeusText(1, 1), newGameA, eKind::strike);
    add(eLanguage::zeusText(1, 3), loadGameA, eKind::dialog);
    add(eLanguage::zeusText(287, 3), editGameA, eKind::transition);
    add(eLanguage::zeusText(2, 0), settingsA, eKind::transition);
    add(eLanguage::zeusText(1, 5), quitA, eKind::quit);
    mLeaderA = leaderA;

    for(int i = 1; i <= 10; i++) {
        const auto t = eLanguage::text("menu_tip_" + std::to_string(i));
        if(!t.empty()) mTips.push_back(t);
    }

    mIntro = !sIntroPlayed;
    if(mIntro) {
        sIntroPlayed = true;
        scene.playIntro();
    }
    mStartTime = scene.time();
}

void eMainMenu::renderTargetsReset() {
    mTexturesDirty = true;
    eMainMenuBase::renderTargetsReset();
}

void eMainMenu::freeTextures() {
    for(auto& i : mItems) {
        for(auto& f : i.fFace) {
            if(f) SDL_DestroyTexture(f);
            f = nullptr;
        }
    }
    for(auto& c : mChip) {
        if(c) SDL_DestroyTexture(c);
        c = nullptr;
    }
    if(mChipHint) SDL_DestroyTexture(mChipHint);
    mChipHint = nullptr;
    if(mFooter) SDL_DestroyTexture(mFooter);
    mFooter = nullptr;
    if(mTipTex) SDL_DestroyTexture(mTipTex);
    mTipTex = nullptr;
    mTipId = -1;
}

SDL_Texture* eMainMenu::renderFace(SDL_Renderer* const r, const eItem& it,
                                   const bool hover, const int w, const int h) {
    const auto white = eMenuScene::instance().whiteTexture();
    const auto tex = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA8888,
                                       SDL_TEXTUREACCESS_TARGET, w, h);
    if(!tex) return nullptr;
    SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(tex, SDL_ScaleModeLinear);
    const double s = h/(it.fHero ? 84.0 : 60.0); // pixels per design unit

    eGeometryBatch::sFlush();
    const auto previous = SDL_GetRenderTarget(r);
    SDL_SetRenderTarget(r, tex);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
    SDL_RenderClear(r);

    // body: deep Aegean stone, or bronze for the hero tablet
    SDL_Color top, bottom;
    if(it.fHero) {
        top = hover ? SDL_Color{112, 84, 30, 250} : SDL_Color{84, 62, 22, 244};
        bottom = hover ? SDL_Color{56, 38, 12, 250} : SDL_Color{40, 27, 8, 246};
    } else {
        top = hover ? SDL_Color{46, 68, 104, 248} : SDL_Color{30, 46, 74, 238};
        bottom = hover ? SDL_Color{22, 34, 58, 248} : SDL_Color{13, 21, 38, 242};
    }
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_NONE);
    {
        const SDL_FPoint q[4] = {{0, 0}, {float(w), 0}, {float(w), float(h)}, {0, float(h)}};
        const SDL_Color cs[4] = {top, top, bottom, bottom};
        drawFlat(r, white, q, cs);
    }
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);

    const float t1 = static_cast<float>(std::max(1.0, 1.6*s));
    const float t2 = static_cast<float>(std::max(1.0, 1.0*s));
    const SDL_Color gold = hover ? SDL_Color{255, 218, 96, 255} : SDL_Color{212, 175, 55, 235};
    const SDL_Color bronze = hover ? SDL_Color{205, 152, 50, 230} : SDL_Color{150, 108, 30, 200};
    fillRect(r, 0, 0, w, std::max(1.f, float(s)), SDL_Color{255, 250, 225, static_cast<Uint8>(hover ? 70 : 40)});
    const float i1 = static_cast<float>(3*s);
    const float i2 = static_cast<float>(7*s);
    frameRect(r, i1, i1, w - 2*i1, h - 2*i1, t1, gold);
    frameRect(r, i2, i2, w - 2*i2, h - 2*i2, t2, bronze);

    // label (and the save line of the hero tablet)
    const double titlePt = (it.fHero ? 30 : 26)*s;
    const auto font = eFonts::displayFont(static_cast<int>(std::round(titlePt)));
    int tw = 0, th = 0;
    const auto title = makeText(r, font, it.fText, hover ? kGold : kIvory, tw, th);
    int sw = 0, sh = 0;
    SDL_Texture* sub = nullptr;
    if(it.fHero && !it.fSub.empty()) {
        const auto sfont = eFonts::defaultFont(static_cast<int>(std::round(16*s)));
        sub = makeText(r, sfont, it.fSub, hover ? SDL_Color{244, 224, 160, 255} : kGoldDim, sw, sh);
    }
    const float tx = (w - tw)*0.5f;
    const float ty = it.fHero ? static_cast<float>(h*0.40 - th*0.5) : (h - th)*0.5f;
    drawText(r, title, tx, ty, tw, th, static_cast<float>(2*s));
    if(sub) {
        drawText(r, sub, (w - sw)*0.5f, static_cast<float>(h*0.73 - sh*0.5), sw, sh,
                 static_cast<float>(1.5*s));
    }

    // ornaments: diamonds at the ends, gold rules running toward the label
    const float cy = it.fHero ? static_cast<float>(h*0.40) : h*0.5f;
    const float dx = static_cast<float>(22*s);
    const float ds = static_cast<float>(4.5*s);
    const SDL_Color orn = hover ? SDL_Color{255, 226, 120, 255} : SDL_Color{214, 176, 70, 220};
    diamond(r, white, dx, cy, ds, orn);
    diamond(r, white, w - dx, cy, ds, orn);
    const float gap = static_cast<float>(18*s);
    const float lineL = dx + ds + static_cast<float>(6*s);
    const float lineR = tx - gap;
    if(lineR - lineL > 8*s) {
        const SDL_Color rule{orn.r, orn.g, orn.b, static_cast<Uint8>(hover ? 190 : 120)};
        fillRect(r, lineL, cy - t2*0.5f, lineR - lineL, t2, rule);
        fillRect(r, w - lineR, cy - t2*0.5f, lineR - lineL, t2, rule);
    }

    if(title) SDL_DestroyTexture(title);
    if(sub) SDL_DestroyTexture(sub);
    SDL_SetRenderTarget(r, previous);
    return tex;
}

SDL_Texture* eMainMenu::renderChip(SDL_Renderer* const r, const bool hover,
                                   const int w, const int h) {
    const auto white = eMenuScene::instance().whiteTexture();
    const auto tex = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA8888,
                                       SDL_TEXTUREACCESS_TARGET, w, h);
    if(!tex) return nullptr;
    SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(tex, SDL_ScaleModeLinear);
    const double s = h/72.0;

    eGeometryBatch::sFlush();
    const auto previous = SDL_GetRenderTarget(r);
    SDL_SetRenderTarget(r, tex);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
    SDL_RenderClear(r);
    const SDL_Color top = hover ? SDL_Color{44, 66, 100, 246} : SDL_Color{26, 40, 64, 232};
    const SDL_Color bottom = hover ? SDL_Color{20, 32, 54, 246} : SDL_Color{12, 19, 34, 236};
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_NONE);
    {
        const SDL_FPoint q[4] = {{0, 0}, {float(w), 0}, {float(w), float(h)}, {0, float(h)}};
        const SDL_Color cs[4] = {top, top, bottom, bottom};
        drawFlat(r, white, q, cs);
    }
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
    const SDL_Color gold = hover ? SDL_Color{255, 218, 96, 255} : SDL_Color{212, 175, 55, 230};
    const float i1 = static_cast<float>(3*s);
    frameRect(r, i1, i1, w - 2*i1, h - 2*i1, static_cast<float>(std::max(1.0, 1.5*s)), gold);

    const auto lfont = eFonts::labelFont(static_cast<int>(std::round(15*s)));
    const auto nfont = eFonts::displayFont(static_cast<int>(std::round(25*s)));
    const std::string leader = window()->leader().empty() ? "-" : window()->leader();
    int lw, lh, nw, nh;
    const auto l = makeText(r, lfont, tr("leader", "Leader"), kGoldDim, lw, lh);
    const auto n = makeText(r, nfont, leader, hover ? kGold : kIvory, nw, nh);
    const float x = static_cast<float>(40*s);
    drawText(r, l, x, static_cast<float>(12*s), lw, lh, static_cast<float>(1.5*s));
    drawText(r, n, x, static_cast<float>(h - nh - 11*s), nw, nh, static_cast<float>(2*s));
    diamond(r, white, static_cast<float>(21*s), h*0.5f, static_cast<float>(6*s),
            hover ? SDL_Color{255, 226, 120, 255} : SDL_Color{214, 176, 70, 230});
    if(l) SDL_DestroyTexture(l);
    if(n) SDL_DestroyTexture(n);
    SDL_SetRenderTarget(r, previous);
    return tex;
}

void eMainMenu::buildTextures(SDL_Renderer* const r) {
    freeTextures();
    const double u = std::min(height()/1080., width()/1500.);
    const double ss = mSS; // faces match the supersampled target
    for(auto& it : mItems) {
        it.fFaceW = static_cast<int>(std::round(500*u*ss));
        it.fFaceH = static_cast<int>(std::round((it.fHero ? 84 : 60)*u*ss));
        it.fFace[0] = renderFace(r, it, false, it.fFaceW, it.fFaceH);
        it.fFace[1] = renderFace(r, it, true, it.fFaceW, it.fFaceH);
    }
    {
        const auto nfont = eFonts::displayFont(static_cast<int>(std::round(25*u*ss)));
        int nw = 0, nh = 0;
        const std::string leader = window()->leader().empty() ? "-" : window()->leader();
        if(nfont) TTF_SizeUTF8(eFonts::forText(nfont, leader), leader.c_str(), &nw, &nh);
        int lw = 0, lh = 0;
        const auto lfont = eFonts::labelFont(static_cast<int>(std::round(15*u*ss)));
        if(lfont) TTF_SizeUTF8(lfont, tr("leader", "Leader").c_str(), &lw, &lh);
        mChipH = static_cast<int>(std::round(72*u*ss));
        mChipW = std::max(static_cast<int>(std::round(210*u*ss)),
                          std::max(nw, lw) + static_cast<int>(std::round(64*u*ss)));
        mChip[0] = renderChip(r, false, mChipW, mChipH);
        mChip[1] = renderChip(r, true, mChipW, mChipH);
        const auto hfont = eFonts::defaultFont(std::max(11, static_cast<int>(std::round(15*u))));
        mChipHint = makeText(r, hfont, eLanguage::zeusText(292, 3), kGoldDim, mChipHintW, mChipHintH);
    }
    {
        const auto ffont = eFonts::defaultFont(std::max(11, static_cast<int>(std::round(15*u))));
        mFooter = makeText(r, ffont, "eZeus HD  -  Master of Olympus & Poseidon",
                           SDL_Color{230, 224, 210, 255}, mFooterW, mFooterH);
    }
    if(!mLogo) {
        const auto dir = eGameDir::texturesDir();
        if(const auto s = IMG_Load((dir + "Zeus_Title.png").c_str())) {
            mLogoW = s->w;
            mLogoH = s->h;
            mLogo = SDL_CreateTextureFromSurface(r, s);
            SDL_FreeSurface(s);
            if(mLogo) SDL_SetTextureScaleMode(mLogo, SDL_ScaleModeLinear);
        }
        if(const auto s = IMG_Load((dir + "Menu/menu_logo_bolt.png").c_str())) {
            mLogoBolt = SDL_CreateTextureFromSurface(r, s);
            SDL_FreeSurface(s);
            if(mLogoBolt) {
                SDL_SetTextureBlendMode(mLogoBolt, SDL_BLENDMODE_ADD);
                SDL_SetTextureScaleMode(mLogoBolt, SDL_ScaleModeLinear);
            }
        }
    }
    mTexScale = u;
    mTexturesDirty = false;
}

double eMainMenu::uiTime() const {
    return eMenuScene::instance().time() - mStartTime;
}

bool eMainMenu::modal() const {
    return !children().empty();
}

void eMainMenu::drawTips(SDL_Renderer* const r, const double alpha) {
    if(mTips.empty() || alpha <= 0.01) return;
    const double u = mTexScale;
    const double period = 9;
    const double t = uiTime() - 2.5;
    if(t < 0) return;
    const int id = static_cast<int>(t/period) % mTips.size();
    const double ph = std::fmod(t, period);
    const double a = alpha*std::min(clamp01(ph/0.7), clamp01((period - ph)/0.7));
    if(id != mTipId) {
        if(mTipTex) SDL_DestroyTexture(mTipTex);
        const auto font = eFonts::defaultFont(std::max(13, static_cast<int>(std::round(19*u))));
        const std::string text = tr("menu_tip", "Tip") + ":  " + mTips[id];
        mTipTex = makeText(r, font, text, kIvory, mTipW, mTipH);
        mTipId = id;
    }
    if(!mTipTex) return;
    const float x = (width() - mTipW)*0.5f;
    const float y = static_cast<float>(height() - 62*u - mTipH*0.5);
    const auto dot = eMenuScene::instance().glowTexture();
    blob(r, dot, width()*0.5f, y + mTipH*0.5f, static_cast<float>(mTipW*0.62),
         static_cast<float>(mTipH*1.9), SDL_Color{0, 0, 0, static_cast<Uint8>(185*a)}, false);
    SDL_SetTextureAlphaMod(mTipTex, static_cast<Uint8>(230*a));
    SDL_SetTextureColorMod(mTipTex, 255, 255, 255);
    const SDL_FRect d{x, y, float(mTipW), float(mTipH)};
    SDL_RenderCopyF(r, mTipTex, nullptr, &d);
    const auto white = eMenuScene::instance().whiteTexture();
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    const SDL_Color orn{214, 176, 70, static_cast<Uint8>(220*a)};
    diamond(r, white, x - static_cast<float>(16*u), y + mTipH*0.5f, static_cast<float>(4*u), orn);
    diamond(r, white, x + mTipW + static_cast<float>(16*u), y + mTipH*0.5f, static_cast<float>(4*u), orn);
}

void eMainMenu::paintEvent(ePainter& p) {
    eMainMenuBase::paintEvent(p);
    auto& scene = eMenuScene::instance();
    const auto r = p.renderer();
    const double u = std::min(height()/1080., width()/1500.);
    const double ss = supersampleFactor(width());
    if(ss != mSS) {
        mSS = ss;
        mTexturesDirty = true;
    }
    if(mTexturesDirty || std::abs(u - mTexScale) > 1e-6) buildTextures(r);

    const double now = scene.time();
    const double dt = mLastFrame < 0 ? 0 : std::min(0.1, now - mLastFrame);
    mLastFrame = now;
    const double t = uiTime();

    const bool isModal = modal();
    if(isModal != mWasModal) {
        mWasModal = isModal;
        scene.setShot(isModal ? eMenuShot::dialog : eMenuShot::main);
        if(!isModal) mSelected = -1;
    }
    const double modalFade = isModal ? 0.0 : 1.0;

    // timeline: the intro holds the menu back until the emblem has landed
    const double logoStart = mIntro ? 0.55 : 0.0;
    const double itemsStart = mIntro ? 1.2 : 0.08;
    const double chipStart = mIntro ? 1.9 : 0.25;

    double leave = 0;
    double leaveLen = kLeaveLength;
    if(mLeaveId >= 0) {
        const auto k = mLeaveId < static_cast<int>(mItems.size()) ? mItems[mLeaveId].fKind : eKind::transition;
        leaveLen = k == eKind::quit ? kQuitLength : k == eKind::strike ? kStrikeLeaveLength : kLeaveLength;
        leave = clamp01((now - mLeaveTime)/leaveLen);
        if(leave >= 1 && !mLeaveFired) {
            mLeaveFired = true;
            const auto a = mLeaveId < static_cast<int>(mItems.size()) ? mItems[mLeaveId].fAction : mLeaderA;
            if(a) window()->addSlot(a);
        }
    }
    const double leaveFade = 1 - leave;

    float px, py;
    scene.parallax(1.25, px, py);
    px *= 0.55f;
    py *= 0.55f;

    const eCamera cam{width()*0.5, height()*0.45, 1050*u};
    const double yaw = -scene.lookX()*7*kDeg;
    const double pitch = scene.lookY()*4.5*kDeg;
    const auto dot = scene.glowTexture();

    // the tilting art is drawn supersampled, so its edges and text stay smooth
    mSuper.begin(r, SDL_Rect{0, 0, width(), height()}, static_cast<float>(mSS));

    // --- emblem --------------------------------------------------------------
    if(mLogo) {
        const double lt = clamp01((t - logoStart)/0.55);
        const double la = clamp01(lt*1.6)*leaveFade*(0.25 + 0.75*modalFade);
        if(la > 0.001) {
            const double sc = 1.22 - 0.22*easeOutBack(lt);
            const double lw = 600*u*sc;
            const double lh = lw*mLogoH/std::max(1, mLogoW);
            const double cx = width()*0.5 + px;
            const double cy = 34*u + 300*u*0.5 + py + std::sin(now*0.8)*5*u - leave*40*u;
            const double flash = scene.flash();
            blob(r, dot, static_cast<float>(cx), static_cast<float>(cy + 10*u),
                 static_cast<float>(lw*0.62), static_cast<float>(lh*0.62),
                 SDL_Color{255, 214, 140, static_cast<Uint8>((46 + 70*flash)*la)}, true);
            const eV3 pivot{cx, cy, -20*u};
            eV3 q[4] = {{cx - lw/2, cy - lh/2, -20*u}, {cx + lw/2, cy - lh/2, -20*u},
                        {cx + lw/2, cy + lh/2, -20*u}, {cx - lw/2, cy + lh/2, -20*u}};
            for(auto& v : q) v = rotate(v, pivot, yaw*0.6, pitch*0.6);
            SDL_SetTextureBlendMode(mLogo, SDL_BLENDMODE_BLEND);
            drawQuad(r, mLogo, cam, q, SDL_Color{255, 255, 255, static_cast<Uint8>(255*la)}, 8, 4);
            if(mLogoBolt) {
                // the thunderbolt in Zeus' fist crackles, and blazes with each strike
                const double crackle = 0.35 + 0.25*std::sin(now*11.3)*std::sin(now*4.1 + 1) +
                                       0.2*std::max(0.0, std::sin(now*23.0)*std::sin(now*1.7));
                const double b = clamp01(crackle*0.55 + flash*1.2)*la;
                if(b > 0.01) {
                    drawQuad(r, mLogoBolt, cam, q, SDL_Color{255, 255, 255, static_cast<Uint8>(255*b)}, 8, 4);
                    const double bx = cx - lw/2 + lw*0.14;
                    const double by = cy - lh/2 + lh*0.45;
                    blob(r, dot, static_cast<float>(bx), static_cast<float>(by),
                         static_cast<float>(lw*0.16), static_cast<float>(lh*0.55),
                         SDL_Color{255, 244, 150, static_cast<Uint8>(120*b)}, true);
                }
            }
        }
    }

    // --- tablets -------------------------------------------------------------
    const double gap = 13*u;
    double colH = 0;
    for(const auto& it : mItems) colH += (it.fHero ? 84 : 60)*u + gap;
    colH -= gap;
    const double colW = 500*u;
    const double colTop = 34*u + 300*u + 44*u;
    const eV3 pivot{width()*0.5 + px, colTop + colH*0.5 + py, 0};

    int hovered = -1;
    if(!isModal && mLeaveId < 0) {
        int mx, my;
        scene.mouseState(mx, my);
        hovered = itemAt(mx, my);
        if(hovered >= 0) {
            mKeyboardNav = false;
            mSelected = hovered;
        } else if(!mKeyboardNav) {
            mSelected = -1;
        }
    }

    double y = colTop;
    const double hk = 1 - std::exp(-dt*12);
    for(int i = 0; i < static_cast<int>(mItems.size()); i++) {
        auto& it = mItems[i];
        const double ih = (it.fHero ? 84 : 60)*u;
        const double target = (i == mSelected || i == mLeaveId) ? 1 : 0;
        it.fHover += (target - it.fHover)*hk;
        const double pressT = (i == mPressedId) ? 1 : 0;
        it.fPress += (pressT - it.fPress)*(1 - std::exp(-dt*20));

        const double et = clamp01((t - itemsStart - i*0.075)/0.62);
        double flip = (1 - easeOutBack(et))*1.3;
        double z = (1 - easeOutCubic(et))*260*u;
        double a = clamp01(et*2.4)*(0.18 + 0.82*modalFade);
        if(mLeaveId >= 0) {
            const double l2 = leave*leave;
            if(i == mLeaveId) {
                z -= 90*u*easeOutCubic(leave);
                a *= 1 - l2;
            } else {
                z += 280*u*l2;
                flip -= 0.9*l2;
                a *= 1 - leave;
            }
        }
        z += -30*u*it.fHover + 12*u*it.fPress;

        const double cx = pivot.fX;
        const double cy = pivot.fY - colH*0.5 + (y - colTop) + ih*0.5;
        y += ih + gap;
        it.fHit = false;
        if(a <= 0.005) continue;

        // shadow and glow beneath
        {
            const eV3 c = rotate(eV3{cx, cy, z}, pivot, yaw, pitch);
            const auto sp = project(cam, c);
            const double lift = std::max(0.0, -z)/(30*u);
            blob(r, dot, sp.x, static_cast<float>(sp.y + (10 + 8*lift)*u),
                 static_cast<float>(colW*0.62), static_cast<float>(ih*(0.95 + 0.25*lift)),
                 SDL_Color{0, 0, 0, static_cast<Uint8>(150*a)}, false);
            if(it.fHover > 0.01) {
                blob(r, dot, sp.x, sp.y, static_cast<float>(colW*0.75), static_cast<float>(ih*1.9),
                     SDL_Color{255, 196, 84, static_cast<Uint8>(95*a*it.fHover)}, true);
            }
        }

        const double hw = colW*0.5;
        const double hh = ih*0.5;
        eV3 f[4] = {{cx - hw, cy - hh, z}, {cx + hw, cy - hh, z},
                    {cx + hw, cy + hh, z}, {cx - hw, cy + hh, z}};
        // flip around the tablet's own horizontal axis
        const eV3 own{cx, cy, z + 9*u};
        for(auto& v : f) v = rotate(v, own, 0, flip);
        // the thickness turns with the flip
        const double depth = 18*u;
        const eV3 extrude{0, -depth*std::sin(flip), depth*std::cos(flip)};
        SDL_Texture* const faces[2] = {it.fFace[0], it.fFace[1]};
        drawSlab(r, scene.whiteTexture(), cam, f, extrude, yaw, pitch, pivot, faces,
                 it.fHover, a, it.fQuad);
        it.fHit = a > 0.5 && et > 0.6;

        // a glint sweeping across the hovered tablet
        if(it.fHover > 0.02 && dot) {
            const double s = std::fmod(now*0.5 + i*0.37, 1.7) - 0.35;
            const double b0 = std::max(0.0, s - 0.1);
            const double b1 = std::min(1.0, s + 0.1);
            if(b1 > b0) {
                eV3 rf[4];
                for(int k = 0; k < 4; k++) rf[k] = rotate(f[k], pivot, yaw, pitch);
                const auto at = [&](const double uu, const int top) {
                    const eV3& a0 = top ? rf[0] : rf[3];
                    const eV3& a1 = top ? rf[1] : rf[2];
                    const double sk = top ? 0.05 : -0.05;
                    const double w = clamp01(uu + sk);
                    return eV3{a0.fX + (a1.fX - a0.fX)*w, a0.fY + (a1.fY - a0.fY)*w,
                               a0.fZ + (a1.fZ - a0.fZ)*w - 0.5};
                };
                const eV3 q[4] = {at(b0, 1), at(b1, 1), at(b1, 0), at(b0, 0)};
                SDL_SetTextureBlendMode(dot, SDL_BLENDMODE_ADD);
                drawQuad(r, dot, cam, q, SDL_Color{255, 240, 200, static_cast<Uint8>(60*a*it.fHover)},
                         2, 2, static_cast<float>((b0 - (s - 0.1))/0.2), 0,
                         static_cast<float>((b1 - (s - 0.1))/0.2), 1);
            }
        }
    }

    // --- leader chip -----------------------------------------------------------
    {
        const double ct = clamp01((t - chipStart)/0.5);
        const double ca = easeOutCubic(ct)*leaveFade*(0.2 + 0.8*modalFade);
        int mx, my;
        scene.mouseState(mx, my);
        const bool over = !isModal && mLeaveId < 0 && mChipHit && ::contains(mChipQuad, mx, my);
        mChipHover += ((over || mLeaveId == static_cast<int>(mItems.size()) ? 1 : 0) - mChipHover)*hk;
        mChipHit = false;
        if(ca > 0.005 && mChip[0]) {
            const double cw = mChipW/mSS;
            const double ch = mChipH/mSS;
            const double x0 = 30*u - (1 - easeOutCubic(ct))*80*u + px*0.4;
            const double y0 = 26*u + py*0.4;
            const double z = -14*u*mChipHover;
            const eV3 cpiv{x0 + cw/2, y0 + ch/2, z};
            const eV3 f[4] = {{x0, y0, z}, {x0 + cw, y0, z}, {x0 + cw, y0 + ch, z}, {x0, y0 + ch, z}};
            blob(r, dot, static_cast<float>(x0 + cw/2), static_cast<float>(y0 + ch/2 + 10*u),
                 static_cast<float>(cw*0.62), static_cast<float>(ch*0.9),
                 SDL_Color{0, 0, 0, static_cast<Uint8>(130*ca)}, false);
            SDL_Texture* const faces[2] = {mChip[0], mChip[1]};
            drawSlab(r, scene.whiteTexture(), cam, f, eV3{0, 0, 12*u}, yaw*0.5, pitch*0.5, cpiv, faces, mChipHover, ca, mChipQuad);
            mChipHit = ca > 0.6;
            if(mChipHint && mChipHover > 0.02) {
                SDL_SetTextureAlphaMod(mChipHint, static_cast<Uint8>(230*mChipHover*ca));
                const SDL_FRect d{static_cast<float>(x0 + 8*u), static_cast<float>(y0 + ch + 12*u),
                                  float(mChipHintW), float(mChipHintH)};
                SDL_RenderCopyF(r, mChipHint, nullptr, &d);
            }
        }
    }

    mSuper.end(r);

    // --- footer and tips ----------------------------------------------------------
    const double footA = clamp01((t - chipStart)/0.8)*leaveFade*modalFade;
    if(mFooter && footA > 0.01) {
        SDL_SetTextureAlphaMod(mFooter, static_cast<Uint8>(130*footA));
        const SDL_FRect d{static_cast<float>(26*u), static_cast<float>(height() - 18*u - mFooterH),
                          float(mFooterW), float(mFooterH)};
        SDL_RenderCopyF(r, mFooter, nullptr, &d);
    }
    drawTips(r, footA);

    // intro: fade up from black; exit: fade down to black
    double black = 0;
    if(mIntro) black = std::max(black, 1 - clamp01(t/0.9));
    if(mLeaveId >= 0 && mLeaveId < static_cast<int>(mItems.size()) &&
       mItems[mLeaveId].fKind == eKind::quit) {
        black = std::max(black, leave);
    }
    if(black > 0.003) {
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
        SDL_SetRenderDrawColor(r, 0, 0, 0, static_cast<Uint8>(255*black));
        SDL_RenderFillRect(r, nullptr);
    }
}

int eMainMenu::itemAt(const int x, const int y) const {
    for(int i = 0; i < static_cast<int>(mItems.size()); i++) {
        const auto& it = mItems[i];
        if(!it.fHit) continue;
        if(::contains(it.fQuad, x, y)) return i;
    }
    return -1;
}

void eMainMenu::activate(const int id) {
    if(mLeaveId >= 0 || modal()) return;
    auto& scene = eMenuScene::instance();
    eSounds::playButtonSound();
    const int n = static_cast<int>(mItems.size());
    if(id == n) { // leader chip
        mLeaveId = id;
        mLeaveTime = scene.time();
        return;
    }
    if(id < 0 || id >= n) return;
    const auto& it = mItems[id];
    switch(it.fKind) {
    case eKind::dialog:
        mSelected = -1;
        mPressedId = -1;
        if(it.fAction) it.fAction();
        return;
    case eKind::strike:
        scene.strike(true);
        break;
    default:
        break;
    }
    mLeaveId = id;
    mLeaveTime = scene.time();
}

bool eMainMenu::mousePressEvent(const eMouseEvent& e) {
    if(modal() || mLeaveId >= 0) return true;
    auto& scene = eMenuScene::instance();
    if(scene.introTime() < 3.4 && mIntro && uiTime() < 2.2) {
        scene.skipIntro();
        mStartTime = scene.time() - 10;
        mIntro = false;
        return true;
    }
    if(e.button() != eMouseButton::left) return true;
    mPressedId = itemAt(e.x(), e.y());
    if(mPressedId < 0 && mChipHit && ::contains(mChipQuad, e.x(), e.y())) {
        mPressedId = static_cast<int>(mItems.size());
    }
    return true;
}

bool eMainMenu::mouseReleaseEvent(const eMouseEvent& e) {
    const int pressed = mPressedId;
    mPressedId = -1;
    if(modal() || mLeaveId >= 0 || pressed < 0) return true;
    if(e.button() != eMouseButton::left) return true;
    const int n = static_cast<int>(mItems.size());
    if(pressed == n) {
        if(::contains(mChipQuad, e.x(), e.y())) activate(n);
        return true;
    }
    if(itemAt(e.x(), e.y()) == pressed) activate(pressed);
    return true;
}

bool eMainMenu::mouseMoveEvent(const eMouseEvent& e) {
    (void)e;
    return true;
}

bool eMainMenu::keyPressEvent(const eKeyPressEvent& e) {
    if(modal() || mLeaveId >= 0) return true;
    auto& scene = eMenuScene::instance();
    const auto k = e.key();
    if(mIntro && uiTime() < 2.2) {
        scene.skipIntro();
        mStartTime = scene.time() - 10;
        mIntro = false;
        return true;
    }
    const int n = static_cast<int>(mItems.size());
    if(n == 0) return true;
    if(k == SDL_SCANCODE_UP || k == SDL_SCANCODE_W || k == SDL_SCANCODE_KP_8) {
        mKeyboardNav = true;
        mSelected = mSelected <= 0 ? n - 1 : mSelected - 1;
    } else if(k == SDL_SCANCODE_DOWN || k == SDL_SCANCODE_S || k == SDL_SCANCODE_KP_2 ||
              k == SDL_SCANCODE_TAB) {
        mKeyboardNav = true;
        mSelected = (mSelected + 1) % n;
    } else if(k == SDL_SCANCODE_RETURN || k == SDL_SCANCODE_KP_ENTER ||
              k == SDL_SCANCODE_SPACE) {
        activate(mSelected < 0 ? 0 : mSelected);
    } else if(k == SDL_SCANCODE_ESCAPE) {
        mKeyboardNav = true;
        mSelected = n - 1; // Exit Game, confirm with Enter
    } else if(k >= SDL_SCANCODE_1 && k <= SDL_SCANCODE_9) {
        const int id = k - SDL_SCANCODE_1;
        if(id < n) activate(id);
    }
    return true;
}
