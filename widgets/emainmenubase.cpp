#include "emainmenubase.h"

#include "emainwindow.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
const double kEntranceLength = 0.5;
}

eMainMenuBase::~eMainMenuBase() {
    if(mEntranceTex) SDL_DestroyTexture(mEntranceTex);
}

void eMainMenuBase::initialize(const eMenuShot shot,
                               const bool animateEntrance) {
    mShot = shot;
    mAnimate = animateEntrance;
    mEntranceDone = !animateEntrance;
    mEnterStart = -1;
    mEntering.clear();
    eMenuScene::instance().setShot(shot);
}

// The screen's panels are hidden from the normal paint pass for the first
// half second and drawn here instead, offscreen, then composited rising and
// fading in over the backdrop.
void eMainMenuBase::animateEntrance() {
    if(mEntranceDone) return;
    auto& scene = eMenuScene::instance();
    const auto r = renderer();
    if(mEnterStart < 0) {
        mEnterStart = scene.time();
        for(const auto c : children()) {
            if(!c->visible()) continue;
            mEntering.push_back(c);
            c->hide();
        }
    }
    const auto alive = [this](eWidget* const w) {
        const auto& cs = children();
        return std::find(cs.begin(), cs.end(), w) != cs.end();
    };
    const double t = (scene.time() - mEnterStart)/kEntranceLength;
    if(t >= 1) {
        for(const auto c : mEntering) {
            if(alive(c)) c->show();
        }
        mEntering.clear();
        mEntranceDone = true;
        if(mEntranceTex) SDL_DestroyTexture(mEntranceTex);
        mEntranceTex = nullptr;
        return;
    }
    const double u = 1 - std::max(0.0, t);
    const double e = 1 - u*u*u;

    int tw = 0;
    int th = 0;
    if(mEntranceTex) SDL_QueryTexture(mEntranceTex, nullptr, nullptr, &tw, &th);
    if(!mEntranceTex || tw != width() || th != height()) {
        if(mEntranceTex) SDL_DestroyTexture(mEntranceTex);
        mEntranceTex = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA8888,
                                         SDL_TEXTUREACCESS_TARGET,
                                         width(), height());
        if(!mEntranceTex) {
            for(const auto c : mEntering) if(alive(c)) c->show();
            mEntering.clear();
            mEntranceDone = true;
            return;
        }
        const auto pm = SDL_ComposeCustomBlendMode(
                            SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                            SDL_BLENDOPERATION_ADD,
                            SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                            SDL_BLENDOPERATION_ADD);
        SDL_SetTextureBlendMode(mEntranceTex, pm);
    }
    eGeometryBatch::sFlush();
    const auto previous = SDL_GetRenderTarget(r);
    SDL_SetRenderTarget(r, mEntranceTex);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
    SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
    SDL_RenderClear(r);
    ePainter pp(r);
    for(const auto c : mEntering) {
        if(alive(c)) c->paint(pp);
    }
    eGeometryBatch::sFlush();
    SDL_RenderSetClipRect(r, nullptr);
    SDL_SetRenderTarget(r, previous);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);

    const Uint8 a = static_cast<Uint8>(std::round(255*std::min(1.0, e*1.15)));
    SDL_SetTextureColorMod(mEntranceTex, a, a, a);
    SDL_SetTextureAlphaMod(mEntranceTex, a);
    const float dy = static_cast<float>((1 - e)*44*height()/1080.);
    const float sc = static_cast<float>(0.97 + 0.03*e);
    const float w = width()*sc;
    const float h = height()*sc;
    const SDL_FRect dst{(width() - w)*0.5f, (height() - h)*0.5f + dy, w, h};
    SDL_RenderCopyF(r, mEntranceTex, nullptr, &dst);
}

void eMainMenuBase::paintEvent(ePainter& p) {
    auto& scene = eMenuScene::instance();
    scene.paint(p.renderer(), width(), height());
    if(mAnimate) animateEntrance();
}

bool eMainMenuBase::keyPressEvent(const eKeyPressEvent& e) {
    if(e.key() == SDL_SCANCODE_ESCAPE && mBackAction) {
        const auto a = mBackAction;
        window()->addSlot(a);
        return true;
    }
    return false;
}
