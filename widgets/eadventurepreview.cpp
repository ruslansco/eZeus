#include "eadventurepreview.h"

#include "ebitmapwidget.h"
#include "emenuscene.h"
#include "emenu3d.h"
#include "textures/egeometrybatch.h"
#include "emainwindow.h"

#include <cmath>

using namespace eMenu3D;

namespace {
struct eFace {
    SDL_Texture* fTex = nullptr;
    float fU0 = 0, fV0 = 0, fU1 = 1, fV1 = 1;
    double fAspect = 4.0/3;
};

eFace face(const int b, const eUIScale scale) {
    eFace f;
    if(b < 0) return f;
    const auto t = eBitmapWidget::sTexture(b, scale);
    if(!t || !t->tex()) return f;
    int tw = 0, th = 0;
    SDL_QueryTexture(t->tex(), nullptr, nullptr, &tw, &th);
    if(tw <= 0 || th <= 0) return f;
    f.fTex = t->tex();
    const int d = t->density();
    f.fU0 = float(t->x()*d)/tw;
    f.fV0 = float(t->y()*d)/th;
    f.fU1 = float((t->x() + t->width())*d)/tw;
    f.fV1 = float((t->y() + t->height())*d)/th;
    f.fAspect = double(t->width())/std::max(1, t->height());
    return f;
}
}

void eAdventurePreview::setBitmap(const int b) {
    if(b == mBitmap) return;
    mPrevious = mBitmap;
    mBitmap = b;
    mFade = mPrevious < 0 ? 1 : 0;
}

void eAdventurePreview::paintEvent(ePainter& p) {
    const Uint64 now = SDL_GetPerformanceCounter();
    const double dt = mLast ? std::min(0.1, double(now - mLast)/SDL_GetPerformanceFrequency()) : 0;
    mLast = now;
    mTime += dt;
    mFade = std::min(1.0, mFade + dt*3.2);

    auto& scene = eMenuScene::instance();
    const auto r = p.renderer();
    const auto white = scene.whiteTexture();
    const auto dot = scene.glowTexture();
    const auto scale = resolution().uiScale();
    const auto cur = face(mBitmap, scale);
    const auto prev = face(mPrevious, scale);
    if(!cur.fTex) return;
    eGeometryBatch::sFlush();

    // the card: the picture's aspect, fitted with room for the tilt
    const double mw = width()*0.95;
    const double mh = height()*0.93;
    double cw = mw;
    double ch = cw/cur.fAspect;
    if(ch > mh) {
        ch = mh;
        cw = ch*cur.fAspect;
    }
    // hang from the top edge so the card lines up with the panels beside it;
    // the card is drawn supersampled in a local area around the widget
    const int margin = std::max(8, width()/20);
    const SDL_Rect area{p.x() - margin, p.y() - margin,
                        width() + 2*margin, height() + 2*margin};
    const double gx = p.x() + width()*0.5;
    const double gy = p.y() + (height() - ch)*0.2 + ch*0.5;
    const double cx = gx - area.x;
    const double cy = gy - area.y;
    const double u = height()/510.0;

    int mx, my;
    scene.mouseState(mx, my);
    const double nx = std::max(-1.5, std::min(1.5, (mx - gx)/(cw*0.8)));
    const double ny = std::max(-1.5, std::min(1.5, (my - gy)/(ch*0.8)));
    const double k = 1 - std::exp(-dt*5);
    const double deg = 3.14159265358979/180;
    mYaw += (-nx*6*deg - mYaw)*k;
    mPitch += (ny*5*deg - mPitch)*k;

    const eCamera cam{cx, cy, 1500*u};
    const eV3 pivot{cx, cy, 0};
    const eV3 f[4] = {{cx - cw/2, cy - ch/2, 0}, {cx + cw/2, cy - ch/2, 0},
                      {cx + cw/2, cy + ch/2, 0}, {cx - cw/2, cy + ch/2, 0}};

    if(dot) {
        SDL_SetTextureBlendMode(dot, SDL_BLENDMODE_BLEND);
        const float sx = static_cast<float>(gx), sy = static_cast<float>(gy + 16*u);
        const float rx = static_cast<float>(cw*0.62), ry = static_cast<float>(ch*0.64);
        const SDL_Color c{0, 0, 0, 170};
        const SDL_Vertex v[4] = {{{sx - rx, sy - ry}, c, {0, 0}}, {{sx + rx, sy - ry}, c, {1, 0}},
                                 {{sx + rx, sy + ry}, c, {1, 1}}, {{sx - rx, sy + ry}, c, {0, 1}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(r, dot, v, 4, ids, 6);
    }

    mSuper.begin(r, area, supersampleFactor(window()->width()));

    // gilded slab with the previous picture, the new one fading in over it
    SDL_Texture* const faces[2] = {prev.fTex && mFade < 1 ? prev.fTex : cur.fTex, cur.fTex};
    const double blend = prev.fTex && mFade < 1 ? mFade : 0;
    const auto& uv = prev.fTex && mFade < 1 ? prev : cur;
    SDL_FPoint quad[4];
    drawSlab(r, white, cam, f, eV3{0, 0, 16*u}, mYaw, mPitch, pivot, faces,
             0, 1, quad, uv.fU0, uv.fV0, uv.fU1, uv.fV1);
    eV3 fr[4];
    for(int i = 0; i < 4; i++) fr[i] = rotate(f[i], pivot, mYaw, mPitch);
    if(blend > 0) {
        drawQuad(r, cur.fTex, cam, fr, SDL_Color{255, 255, 255, static_cast<Uint8>(255*blend)},
                 8, 4, cur.fU0, cur.fV0, cur.fU1, cur.fV1);
    }

    // gold border inset on the picture
    const auto at = [&](const double a, const double b) {
        const eV3 top{fr[0].fX + (fr[1].fX - fr[0].fX)*a, fr[0].fY + (fr[1].fY - fr[0].fY)*a,
                      fr[0].fZ + (fr[1].fZ - fr[0].fZ)*a};
        const eV3 bot{fr[3].fX + (fr[2].fX - fr[3].fX)*a, fr[3].fY + (fr[2].fY - fr[3].fY)*a,
                      fr[3].fZ + (fr[2].fZ - fr[3].fZ)*a};
        return project(cam, eV3{top.fX + (bot.fX - top.fX)*b, top.fY + (bot.fY - top.fY)*b,
                                top.fZ + (bot.fZ - top.fZ)*b - 0.5});
    };
    const auto band = [&](const double a0, const double b0, const double a1, const double b1,
                          const SDL_Color c) {
        const SDL_FPoint q[4] = {at(a0, b0), at(a1, b0), at(a1, b1), at(a0, b1)};
        const SDL_Color cs[4] = {c, c, c, c};
        drawFlat(r, white, q, cs);
    };
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    const double tx = 4*u/cw;
    const double ty = 4*u/ch;
    const SDL_Color gold{226, 186, 70, 255};
    band(0, 0, 1, ty, gold);
    band(0, 1 - ty, 1, 1, gold);
    band(0, ty, tx, 1 - ty, gold);
    band(1 - tx, ty, 1, 1 - ty, gold);
    const double ix = 9*u/cw;
    const double iy = 9*u/ch;
    const double lx = 1.2*u/cw;
    const double ly = 1.2*u/ch;
    const SDL_Color line{255, 226, 130, 170};
    band(ix, iy, 1 - ix, iy + ly, line);
    band(ix, 1 - iy - ly, 1 - ix, 1 - iy, line);
    band(ix, iy, ix + lx, 1 - iy, line);
    band(1 - ix - lx, iy, 1 - ix, 1 - iy, line);

    // a slow glint across the picture
    if(dot) {
        const double s = std::fmod(mTime*0.16, 1.6) - 0.3;
        const double b0 = std::max(0.0, s - 0.12);
        const double b1 = std::min(1.0, s + 0.12);
        if(b1 > b0) {
            const auto p3 = [&](const double a, const double b) {
                const eV3 top{fr[0].fX + (fr[1].fX - fr[0].fX)*a, fr[0].fY + (fr[1].fY - fr[0].fY)*a,
                              fr[0].fZ + (fr[1].fZ - fr[0].fZ)*a};
                const eV3 bot{fr[3].fX + (fr[2].fX - fr[3].fX)*a, fr[3].fY + (fr[2].fY - fr[3].fY)*a,
                              fr[3].fZ + (fr[2].fZ - fr[3].fZ)*a};
                return eV3{top.fX + (bot.fX - top.fX)*b, top.fY + (bot.fY - top.fY)*b,
                           top.fZ + (bot.fZ - top.fZ)*b - 1};
            };
            const eV3 q[4] = {p3(b0, 0), p3(b1, 0), p3(b1, 1), p3(b0, 1)};
            SDL_SetTextureBlendMode(dot, SDL_BLENDMODE_ADD);
            drawQuad(r, dot, cam, q, SDL_Color{255, 244, 214, 38}, 2, 2,
                     static_cast<float>((b0 - (s - 0.12))/0.24), 0,
                     static_cast<float>((b1 - (s - 0.12))/0.24), 1);
        }
    }
    mSuper.end(r);
}
