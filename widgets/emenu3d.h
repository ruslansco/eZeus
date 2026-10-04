#ifndef EMENU3D_H
#define EMENU3D_H

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include "efonts.h"

#include "textures/egeometrybatch.h"

#include <cmath>
#include <string>
#include <vector>

// Small perspective toolkit for the front-end menus: rectangles living in a
// 3D space whose x/y are screen pixels and z points away from the viewer.
namespace eMenu3D {

struct eV3 {
    double fX = 0;
    double fY = 0;
    double fZ = 0;
};

struct eCamera {
    double fCX = 0; // vanishing point
    double fCY = 0;
    double fF = 1000; // focal length in pixels
};

inline SDL_FPoint project(const eCamera& c, const eV3& p) {
    const double s = c.fF/std::max(1.0, c.fF + p.fZ);
    return SDL_FPoint{static_cast<float>(c.fCX + (p.fX - c.fCX)*s),
                      static_cast<float>(c.fCY + (p.fY - c.fCY)*s)};
}

// Rotation around a vertical (yaw) then horizontal (pitch) axis through pivot.
inline eV3 rotate(const eV3& p, const eV3& pivot,
                  const double yaw, const double pitch) {
    double x = p.fX - pivot.fX;
    double y = p.fY - pivot.fY;
    double z = p.fZ - pivot.fZ;
    const double cy = std::cos(yaw), sy = std::sin(yaw);
    const double x1 = x*cy + z*sy;
    const double z1 = -x*sy + z*cy;
    x = x1;
    z = z1;
    const double cp = std::cos(pitch), sp = std::sin(pitch);
    const double y2 = y*cp - z*sp;
    const double z2 = y*sp + z*cp;
    return eV3{x + pivot.fX, y2 + pivot.fY, z2 + pivot.fZ};
}

// Textured quad tl, tr, br, bl, subdivided so the texture follows the
// perspective instead of SDL's per-triangle affine mapping.
inline void drawQuad(SDL_Renderer* const r, SDL_Texture* const tex,
                     const eCamera& cam, const eV3 q[4],
                     const SDL_Color c, const int sx = 6, const int sy = 2,
                     const float u0 = 0, const float v0 = 0,
                     const float u1 = 1, const float v1 = 1) {
    std::vector<SDL_Vertex> vs;
    std::vector<int> ids;
    vs.reserve((sx + 1)*(sy + 1));
    for(int j = 0; j <= sy; j++) {
        const double b = double(j)/sy;
        for(int i = 0; i <= sx; i++) {
            const double a = double(i)/sx;
            const eV3 top{q[0].fX + (q[1].fX - q[0].fX)*a,
                          q[0].fY + (q[1].fY - q[0].fY)*a,
                          q[0].fZ + (q[1].fZ - q[0].fZ)*a};
            const eV3 bot{q[3].fX + (q[2].fX - q[3].fX)*a,
                          q[3].fY + (q[2].fY - q[3].fY)*a,
                          q[3].fZ + (q[2].fZ - q[3].fZ)*a};
            const eV3 p{top.fX + (bot.fX - top.fX)*b,
                        top.fY + (bot.fY - top.fY)*b,
                        top.fZ + (bot.fZ - top.fZ)*b};
            vs.push_back({project(cam, p), c,
                          {static_cast<float>(u0 + (u1 - u0)*a),
                           static_cast<float>(v0 + (v1 - v0)*b)}});
        }
    }
    for(int j = 0; j < sy; j++) {
        for(int i = 0; i < sx; i++) {
            const int a = j*(sx + 1) + i;
            ids.insert(ids.end(), {a, a + 1, a + sx + 2, a, a + sx + 2, a + sx + 1});
        }
    }
    SDL_RenderGeometry(r, tex, vs.data(), vs.size(), ids.data(), ids.size());
}

// Screen-space quad with per-corner colours (gradients, flat fills).
inline void drawFlat(SDL_Renderer* const r, SDL_Texture* const white,
                     const SDL_FPoint q[4], const SDL_Color c[4]) {
    const SDL_Vertex v[4] = {{q[0], c[0], {0.5f, 0.5f}},
                             {q[1], c[1], {0.5f, 0.5f}},
                             {q[2], c[2], {0.5f, 0.5f}},
                             {q[3], c[3], {0.5f, 0.5f}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, white, v, 4, ids, 6);
}

// Clockwise on screen = facing the viewer (y points down).
inline bool facing(const SDL_FPoint q[4]) {
    double area = 0;
    for(int i = 0; i < 4; i++) {
        const auto& a = q[i];
        const auto& b = q[(i + 1)%4];
        area += double(a.x)*b.y - double(b.x)*a.y;
    }
    return area > 0;
}

inline bool contains(const SDL_FPoint q[4], const double x, const double y) {
    int pos = 0;
    int neg = 0;
    for(int i = 0; i < 4; i++) {
        const auto& a = q[i];
        const auto& b = q[(i + 1)%4];
        const double cr = (b.x - a.x)*(y - a.y) - (b.y - a.y)*(x - a.x);
        if(cr > 0) pos++;
        else if(cr < 0) neg++;
    }
    return pos == 0 || neg == 0;
}

// White-on-transparent text with a soft shadow baked in, ready for
// colour modulation.
inline SDL_Texture* makeText(SDL_Renderer* const r, TTF_Font* const font,
                             const std::string& text, const SDL_Color col,
                             int& w, int& h) {
    w = h = 0;
    if(!font || text.empty()) return nullptr;
    const auto s = TTF_RenderUTF8_Blended(eFonts::forText(font, text), text.c_str(), col);
    if(!s) return nullptr;
    const auto t = SDL_CreateTextureFromSurface(r, s);
    w = s->w;
    h = s->h;
    SDL_FreeSurface(s);
    if(t) {
        SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
        SDL_SetTextureScaleMode(t, SDL_ScaleModeLinear);
    }
    return t;
}

inline double easeOutBack(const double t) {
    const double c1 = 1.55;
    const double c3 = c1 + 1;
    const double u = t - 1;
    return 1 + c3*u*u*u + c1*u*u;
}

inline double easeOutCubic(const double t) {
    const double u = 1 - std::max(0.0, std::min(1.0, t));
    return 1 - u*u*u;
}

inline double clamp01(const double v) {
    return std::max(0.0, std::min(1.0, v));
}

inline SDL_Color mix(const SDL_Color a, const SDL_Color b, const double t) {
    const auto l = [t](const Uint8 x, const Uint8 y) {
        return static_cast<Uint8>(std::round(x + (y - x)*t));
    };
    return SDL_Color{l(a.r, b.r), l(a.g, b.g), l(a.b, b.b), l(a.a, b.a)};
}

// A tablet: front face f (tl tr br bl) extruded away along `extrude`, turned
// by yaw/pitch around pivot. Gold-leaf edges are drawn where they face the
// viewer, then faces[0] (and faces[1] blended in by hover) on the front.
// outQuad receives the projected front face for hit testing.
inline void drawSlab(SDL_Renderer* const r, SDL_Texture* const white,
                     const eCamera& cam, const eV3 f[4], const eV3& extrude,
                     const double yaw, const double pitch, const eV3& pivot,
                     SDL_Texture* const faces[2], const double hover,
                     const double alpha, SDL_FPoint outQuad[4],
                     const float u0 = 0, const float v0 = 0,
                     const float u1 = 1, const float v1 = 1) {
    eV3 fr[4];
    eV3 bk[4];
    for(int i = 0; i < 4; i++) {
        const eV3 b{f[i].fX + extrude.fX, f[i].fY + extrude.fY, f[i].fZ + extrude.fZ};
        fr[i] = rotate(f[i], pivot, yaw, pitch);
        bk[i] = rotate(b, pivot, yaw, pitch);
    }
    SDL_FPoint pf[4];
    SDL_FPoint pb[4];
    for(int i = 0; i < 4; i++) {
        pf[i] = project(cam, fr[i]);
        pb[i] = project(cam, bk[i]);
        if(outQuad) outQuad[i] = pf[i];
    }
    const Uint8 a = static_cast<Uint8>(std::round(255*clamp01(alpha)));
    const double h = clamp01(hover);
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    const auto side = [&](const SDL_FPoint q[4], const SDL_Color lo, const SDL_Color hi,
                          const SDL_Color loBack, const SDL_Color hiBack) {
        if(!facing(q)) return;
        SDL_Color front = mix(lo, hi, h);
        SDL_Color back = mix(loBack, hiBack, h);
        front.a = back.a = a;
        const SDL_Color cs[4] = {back, back, front, front};
        drawFlat(r, white, q, cs);
    };
    // each side listed as seen from outside: far edge first
    {
        const SDL_FPoint q[4] = {pb[0], pb[1], pf[1], pf[0]};
        side(q, {236, 196, 96, 255}, {255, 232, 150, 255}, {150, 112, 40, 255}, {190, 150, 70, 255});
    }
    {
        const SDL_FPoint q[4] = {pf[3], pf[2], pb[2], pb[3]};
        side(q, {70, 46, 12, 255}, {100, 70, 20, 255}, {112, 78, 22, 255}, {150, 110, 36, 255});
    }
    {
        const SDL_FPoint q[4] = {pb[3], pb[0], pf[0], pf[3]};
        side(q, {190, 146, 56, 255}, {236, 196, 96, 255}, {120, 86, 26, 255}, {160, 120, 44, 255});
    }
    {
        const SDL_FPoint q[4] = {pb[1], pb[2], pf[2], pf[1]};
        side(q, {150, 106, 34, 255}, {206, 160, 64, 255}, {96, 66, 20, 255}, {134, 96, 30, 255});
    }
    if(!facing(pf)) return;
    if(faces[0]) drawQuad(r, faces[0], cam, fr, SDL_Color{255, 255, 255, a}, 8, 2, u0, v0, u1, v1);
    const Uint8 ha = static_cast<Uint8>(std::round(a*h));
    if(faces[1] && ha > 0) drawQuad(r, faces[1], cam, fr, SDL_Color{255, 255, 255, ha}, 8, 2, u0, v0, u1, v1);
}

// Anti-aliasing for the tilted menu art (SDL geometry has none): whatever is
// drawn between begin() and end() goes to an offscreen target ss times the
// size of area, which end() filters back down onto the screen. Coordinates
// in between stay screen pixels relative to area's top-left corner.
class eSupersample {
public:
    ~eSupersample() {
        if(mTex) SDL_DestroyTexture(mTex);
    }

    bool begin(SDL_Renderer* const r, const SDL_Rect& area, const float ss) {
        mActive = false;
        if(area.w <= 0 || area.h <= 0) return false;
        const int tw = static_cast<int>(std::ceil(area.w*ss));
        const int th = static_cast<int>(std::ceil(area.h*ss));
        if(!mTex || tw != mTW || th != mTH) {
            if(mTex) SDL_DestroyTexture(mTex);
            mTex = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA8888,
                                     SDL_TEXTUREACCESS_TARGET, tw, th);
            if(!mTex) return false;
            mTW = tw;
            mTH = th;
            // the target holds premultiplied colour (blending onto clear black)
            SDL_SetTextureBlendMode(mTex, SDL_ComposeCustomBlendMode(
                SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, SDL_BLENDOPERATION_ADD,
                SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA, SDL_BLENDOPERATION_ADD));
            SDL_SetTextureScaleMode(mTex, SDL_ScaleModeLinear);
        }
        eGeometryBatch::sFlush();
        mArea = area;
        mPrev = SDL_GetRenderTarget(r);
        SDL_SetRenderTarget(r, mTex);
        SDL_RenderSetScale(r, float(tw)/area.w, float(th)/area.h);
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
        SDL_RenderClear(r);
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
        mActive = true;
        return true;
    }

    void end(SDL_Renderer* const r, const Uint8 alpha = 255) {
        if(!mActive) return;
        mActive = false;
        eGeometryBatch::sFlush();
        SDL_RenderSetScale(r, 1, 1);
        SDL_SetRenderTarget(r, mPrev);
        SDL_SetTextureColorMod(mTex, alpha, alpha, alpha);
        SDL_SetTextureAlphaMod(mTex, alpha);
        const SDL_FRect dst{float(mArea.x), float(mArea.y), float(mArea.w), float(mArea.h)};
        SDL_RenderCopyF(r, mTex, nullptr, &dst);
    }
private:
    SDL_Texture* mTex = nullptr;
    SDL_Texture* mPrev = nullptr;
    int mTW = 0;
    int mTH = 0;
    SDL_Rect mArea{0, 0, 0, 0};
    bool mActive = false;
};

// Supersampling factor for full-screen menu art (2x, less on huge screens).
inline float supersampleFactor(const int screenW) {
    return screenW <= 2600 ? 2.f : 1.5f;
}

} // namespace eMenu3D

#endif // EMENU3D_H
