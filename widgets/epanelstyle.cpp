#include "epanelstyle.h"

#include "egamedir.h"
#include "textures/egeometrybatch.h"

#include <SDL2/SDL_image.h>

#include <algorithm>
#include <cmath>
#include <map>
#include <vector>

namespace ePanel {

void body(SDL_Renderer* const r, const float ox, const float oy,
          const float W, const float H, const float unit) {
    const auto u = [unit](const double v) { return static_cast<float>(v*unit); };
    eGeometryBatch::sFlush();
    {
        const auto wt = white(r);
        const float sw = u(9);
        const SDL_Color a{0, 0, 0, 0};
        const SDL_Color b{0, 0, 0, 120};
        const SDL_Vertex v[4] = {{{ox - sw, oy}, a, {.5f, .5f}}, {{ox, oy}, b, {.5f, .5f}},
                                 {{ox, oy + H}, b, {.5f, .5f}}, {{ox - sw, oy + H}, a, {.5f, .5f}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(r, wt, v, 4, ids, 6);
    }
    if(const auto t = lapis(r)) {
        int tw = 0;
        int th = 0;
        SDL_QueryTexture(t, nullptr, nullptr, &tw, &th);
        for(int y = 0; y < H; y += th) {
            for(int x = 0; x < W; x += tw) {
                const int w = std::min<int>(tw, W - x);
                const int h = std::min<int>(th, H - y);
                const SDL_Rect src{0, 0, w, h};
                const SDL_Rect dst{static_cast<int>(ox) + x, static_cast<int>(oy) + y, w, h};
                SDL_RenderCopy(r, t, &src, &dst);
            }
        }
    } else {
        fill(r, SDL_FRect{ox, oy, W, H}, SDL_Color{12, 22, 46, 255});
    }
    gradient(r, SDL_FRect{ox, oy, W, H}, SDL_Color{6, 10, 24, 60}, SDL_Color{2, 4, 12, 150});
    const float a = std::max(1.f, u(.5));
    const float b = std::max(1.f, u(.6));
    fill(r, SDL_FRect{ox, oy, a, H}, SDL_Color{2, 4, 10, 255});
    gradient(r, SDL_FRect{ox + a, oy, b, H}, SDL_Color{246, 206, 110, 255}, SDL_Color{168, 120, 40, 255});
    fill(r, SDL_FRect{ox + a + b, oy, 1, H}, SDL_Color{255, 238, 180, 90});
    {
        const auto wt = white(r);
        const float x0 = ox + u(1.2);
        const float sw = u(3.5);
        const SDL_Color c0{0, 0, 0, 110};
        const SDL_Color c1{0, 0, 0, 0};
        const SDL_Vertex v[4] = {{{x0, oy}, c0, {.5f, .5f}}, {{x0 + sw, oy}, c1, {.5f, .5f}},
                                 {{x0 + sw, oy + H}, c1, {.5f, .5f}}, {{x0, oy + H}, c0, {.5f, .5f}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(r, wt, v, 4, ids, 6);
    }
}

void well(SDL_Renderer* const r, const SDL_FRect& f, const float radius,
          const float hairline, const bool strong) {
    roundRect(r, f, radius, SDL_Color{3, 7, 18, 165}, SDL_Color{6, 12, 28, 185});
    roundRect(r, f, radius, SDL_Color{236, 192, 96, static_cast<Uint8>(strong ? 170 : 80)},
              SDL_Color{150, 106, 34, static_cast<Uint8>(strong ? 120 : 60)}, hairline);
}

void emblemAt(SDL_Renderer* const r, const float cx, const float top,
              const float maxW, const float room, const float unit) {
    const float aspect = 1.08f;
    const float tw = std::min(maxW, room/aspect);
    if(tw <= 14*unit) return;
    int ew = 0;
    int eh = 0;
    const auto t = emblem(r, static_cast<int>(std::ceil(tw)), ew, eh);
    if(!t) return;
    const float th = tw*eh/std::max(1, ew);
    glow(r, cx, top + th/2, tw*.62f, th*.62f, SDL_Color{255, 200, 110, 26}, true);
    glow(r, cx, top + th*.55f, tw*.5f, th*.5f, SDL_Color{0, 0, 0, 90}, false);
    const SDL_FRect d{cx - tw/2, top, tw, th};
    SDL_RenderCopyF(r, t, nullptr, &d);
    const double gt = std::fmod(time(), 7.0)/1.3;
    if(gt < 1) {
        const float gx = static_cast<float>(d.x - tw*.2 + (tw*1.4)*gt);
        glow(r, gx, top + th*.45f, tw*.14f, th*.55f,
             SDL_Color{255, 236, 170, static_cast<Uint8>(90*std::sin(gt*3.14159))}, true);
    }
}

const SDL_Color kGold{236, 192, 96, 255};
const SDL_Color kGoldPale{255, 232, 160, 255};
const SDL_Color kIvory{242, 234, 214, 255};
const SDL_Color kInk{16, 30, 62, 255};

namespace {
const int kMedalSizes[] = {26, 34, 44, 56, 72, 96, 128, 176, 256};
const int kEmblemSizes[] = {112, 160, 224, 320, 448, 640};

SDL_Renderer* sRenderer = nullptr;
std::map<std::pair<std::string, int>, SDL_Texture*> sIcons;
std::map<std::string, SDL_Texture*> sFiles;
std::map<std::pair<int, int>, SDL_Texture*> sRounds;
SDL_Texture* sDot = nullptr;
SDL_Texture* sWhite = nullptr;

// Textures belong to one renderer; drop the caches when it changes.
void checkRenderer(SDL_Renderer* const r) {
    if(r == sRenderer) return;
    sRenderer = r;
    sIcons.clear();
    sFiles.clear();
    sRounds.clear();
    sDot = nullptr;
    sWhite = nullptr;
}

std::string dir() {
    return eGameDir::texturesDir() + "Panel/";
}

SDL_Texture* fromPixels(SDL_Renderer* const r, const int w, const int h,
                        const std::vector<Uint8>& rgba) {
    const auto t = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA32,
                                     SDL_TEXTUREACCESS_STATIC, w, h);
    if(!t) return nullptr;
    SDL_UpdateTexture(t, nullptr, rgba.data(), w*4);
    SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
    SDL_SetTextureScaleMode(t, SDL_ScaleModeLinear);
    return t;
}

SDL_Texture* file(SDL_Renderer* const r, const std::string& name) {
    checkRenderer(r);
    const auto it = sFiles.find(name);
    if(it != sFiles.end()) return it->second;
    SDL_Texture* t = nullptr;
    if(const auto s = IMG_Load((dir() + name).c_str())) {
        t = SDL_CreateTextureFromSurface(r, s);
        SDL_FreeSurface(s);
        if(t) {
            SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
            SDL_SetTextureScaleMode(t, SDL_ScaleModeLinear);
        }
    } else {
        printf("ePanel: missing %s\n", (dir() + name).c_str());
    }
    sFiles[name] = t;
    return t;
}

// A (2R+2) square holding a rounded rectangle of radius R, anti-aliased;
// line > 0 keeps only an outline that many pixels wide (in tenths).
SDL_Texture* roundTex(SDL_Renderer* const r, const int R, const int line10) {
    checkRenderer(r);
    const auto key = std::make_pair(R, line10);
    const auto it = sRounds.find(key);
    if(it != sRounds.end()) return it->second;
    const int n = 2*R + 2;
    std::vector<Uint8> px(n*n*4, 255);
    const double lw = line10/10.0;
    for(int y = 0; y < n; y++) {
        for(int x = 0; x < n; x++) {
            // distance from the rounded rectangle's edge (negative inside)
            const double fx = x + 0.5;
            const double fy = y + 0.5;
            const double cx = std::clamp(fx, double(R), double(n - R));
            const double cy = std::clamp(fy, double(R), double(n - R));
            const double d = std::hypot(fx - cx, fy - cy) - R;
            double cov = std::clamp(0.5 - d, 0.0, 1.0);
            if(line10 > 0) cov *= std::clamp(d + lw + 0.5, 0.0, 1.0);
            px[(y*n + x)*4 + 3] = static_cast<Uint8>(std::round(cov*255));
        }
    }
    const auto t = fromPixels(r, n, n, px);
    sRounds[key] = t;
    return t;
}

SDL_Color lerp(const SDL_Color a, const SDL_Color b, const double t) {
    const auto l = [t](const Uint8 x, const Uint8 y) {
        return static_cast<Uint8>(std::round(x + (y - x)*std::clamp(t, 0.0, 1.0)));
    };
    return SDL_Color{l(a.r, b.r), l(a.g, b.g), l(a.b, b.b), l(a.a, b.a)};
}
}

double time() {
    static const Uint64 start = SDL_GetPerformanceCounter();
    return double(SDL_GetPerformanceCounter() - start)/SDL_GetPerformanceFrequency();
}

double approach(const double dt, const double k) {
    return 1 - std::exp(-std::max(0.0, dt)*k);
}

SDL_Texture* icon(SDL_Renderer* const r, const std::string& name, const int px) {
    checkRenderer(r);
    const auto key = std::make_pair(name, px);
    const auto it = sIcons.find(key);
    if(it != sIcons.end()) return it->second;
    SDL_Texture* t = nullptr;
    const auto path = dir() + "icons/" + name + ".svg";
    if(const auto rw = SDL_RWFromFile(path.c_str(), "rb")) {
        if(const auto s = IMG_LoadSizedSVG_RW(rw, px, px)) {
            t = SDL_CreateTextureFromSurface(r, s);
            SDL_FreeSurface(s);
            if(t) {
                SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND);
                SDL_SetTextureScaleMode(t, SDL_ScaleModeLinear);
            }
        }
        SDL_RWclose(rw);
    }
    if(!t) printf("ePanel: missing icon %s\n", path.c_str());
    sIcons[key] = t;
    return t;
}

SDL_Texture* medal(SDL_Renderer* const r, const eMedalPart part, const int px) {
    int s = kMedalSizes[std::size(kMedalSizes) - 1];
    for(const int k : kMedalSizes) {
        if(k >= px) {
            s = k;
            break;
        }
    }
    const char* n = part == eMedalPart::ring ? "ring" :
                    part == eMedalPart::disc ? "disc" : "disc_active";
    return file(r, std::string(n) + "_" + std::to_string(s) + ".png");
}

SDL_Texture* emblem(SDL_Renderer* const r, const int px, int& w, int& h) {
    int s = kEmblemSizes[std::size(kEmblemSizes) - 1];
    for(const int k : kEmblemSizes) {
        if(k >= px) {
            s = k;
            break;
        }
    }
    const auto t = file(r, "emblem_" + std::to_string(s) + ".png");
    w = h = 0;
    if(t) SDL_QueryTexture(t, nullptr, nullptr, &w, &h);
    return t;
}

SDL_Texture* lapis(SDL_Renderer* const r) {
    return file(r, "lapis.png");
}

SDL_Texture* dot(SDL_Renderer* const r) {
    checkRenderer(r);
    if(sDot) return sDot;
    const int n = 64;
    std::vector<Uint8> px(n*n*4, 255);
    for(int y = 0; y < n; y++) {
        for(int x = 0; x < n; x++) {
            const double dx = (x + 0.5)/n*2 - 1;
            const double dy = (y + 0.5)/n*2 - 1;
            const double a = std::max(0.0, std::exp(-(dx*dx + dy*dy)*4.2) - 0.015);
            px[(y*n + x)*4 + 3] = static_cast<Uint8>(std::min(255.0, a*260));
        }
    }
    sDot = fromPixels(r, n, n, px);
    return sDot;
}

SDL_Texture* white(SDL_Renderer* const r) {
    checkRenderer(r);
    if(sWhite) return sWhite;
    std::vector<Uint8> px(4*4*4, 255);
    sWhite = fromPixels(r, 4, 4, px);
    return sWhite;
}

void fill(SDL_Renderer* const r, const SDL_FRect& rect, const SDL_Color c) {
    gradient(r, rect, c, c);
}

void gradient(SDL_Renderer* const r, const SDL_FRect& rect,
              const SDL_Color top, const SDL_Color bottom) {
    eGeometryBatch::sFlush();
    const auto w = white(r);
    SDL_SetTextureBlendMode(w, SDL_BLENDMODE_BLEND);
    const float x0 = rect.x, x1 = rect.x + rect.w;
    const float y0 = rect.y, y1 = rect.y + rect.h;
    const SDL_Vertex v[4] = {{{x0, y0}, top, {.5f, .5f}}, {{x1, y0}, top, {.5f, .5f}},
                             {{x1, y1}, bottom, {.5f, .5f}}, {{x0, y1}, bottom, {.5f, .5f}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, w, v, 4, ids, 6);
}

void roundRect(SDL_Renderer* const r, const SDL_FRect& rect, const float radius,
               const SDL_Color top, const SDL_Color bottom, const float line) {
    if(rect.w <= 0 || rect.h <= 0) return;
    eGeometryBatch::sFlush();
    const int R = std::max(1, static_cast<int>(std::round(std::min({radius, rect.w/2, rect.h/2}))));
    const int l10 = line > 0 ? std::max(5, static_cast<int>(std::round(line*10))) : 0;
    const auto t = roundTex(r, R, l10);
    if(!t) return;
    const float c = R + 1;
    const float n = 2*R + 2;
    const float xs[4] = {rect.x, rect.x + c, rect.x + rect.w - c, rect.x + rect.w};
    const float ys[4] = {rect.y, rect.y + c, rect.y + rect.h - c, rect.y + rect.h};
    const float us[4] = {0, c/n, 1 - c/n, 1};
    std::vector<SDL_Vertex> vs;
    vs.reserve(16);
    for(int j = 0; j < 4; j++) {
        const double t01 = (ys[j] - rect.y)/rect.h;
        const auto col = lerp(top, bottom, t01);
        for(int i = 0; i < 4; i++) {
            vs.push_back({{xs[i], ys[j]}, col, {us[i], us[j]}});
        }
    }
    std::vector<int> ids;
    for(int j = 0; j < 3; j++) {
        for(int i = 0; i < 3; i++) {
            const int a = j*4 + i;
            ids.insert(ids.end(), {a, a + 1, a + 5, a, a + 5, a + 4});
        }
    }
    SDL_RenderGeometry(r, t, vs.data(), vs.size(), ids.data(), ids.size());
}

void glow(SDL_Renderer* const r, const float cx, const float cy,
          const float rx, const float ry, const SDL_Color c, const bool additive) {
    if(c.a == 0) return;
    eGeometryBatch::sFlush();
    const auto d = dot(r);
    SDL_SetTextureBlendMode(d, additive ? SDL_BLENDMODE_ADD : SDL_BLENDMODE_BLEND);
    const SDL_Vertex v[4] = {{{cx - rx, cy - ry}, c, {0, 0}}, {{cx + rx, cy - ry}, c, {1, 0}},
                             {{cx + rx, cy + ry}, c, {1, 1}}, {{cx - rx, cy + ry}, c, {0, 1}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, d, v, 4, ids, 6);
    SDL_SetTextureBlendMode(d, SDL_BLENDMODE_BLEND);
}

void diamond(SDL_Renderer* const r, const float cx, const float cy,
             const float s, const SDL_Color c) {
    eGeometryBatch::sFlush();
    const auto w = white(r);
    const SDL_Vertex v[4] = {{{cx, cy - s}, c, {.5f, .5f}}, {{cx + s, cy}, c, {.5f, .5f}},
                             {{cx, cy + s}, c, {.5f, .5f}}, {{cx - s, cy}, c, {.5f, .5f}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, w, v, 4, ids, 6);
}

void goldRule(SDL_Renderer* const r, const float x, const float y,
              const float w, const float thickness, const Uint8 alpha,
              const bool withDiamond) {
    eGeometryBatch::sFlush();
    const auto wt = white(r);
    SDL_Color c = kGold;
    SDL_Color e = kGold;
    c.a = alpha;
    e.a = 0;
    const float h = thickness;
    const float xm = x + w/2;
    const SDL_Vertex v[6] = {{{x, y}, e, {.5f, .5f}}, {{xm, y}, c, {.5f, .5f}},
                             {{x + w, y}, e, {.5f, .5f}}, {{x + w, y + h}, e, {.5f, .5f}},
                             {{xm, y + h}, c, {.5f, .5f}}, {{x, y + h}, e, {.5f, .5f}}};
    const int ids[12] = {0, 1, 4, 0, 4, 5, 1, 2, 3, 1, 3, 4};
    SDL_RenderGeometry(r, wt, v, 6, ids, 12);
    if(withDiamond) {
        SDL_Color dc = kGoldPale;
        dc.a = alpha;
        diamond(r, xm, y + h/2, h*2.2f, dc);
    }
}

void drawIcon(SDL_Renderer* const r, const std::string& name,
              const float cx, const float cy, const int px,
              const SDL_Color c, const bool shadow, const double angle) {
    const auto t = icon(r, name, px);
    if(!t) return;
    eGeometryBatch::sFlush();
    const SDL_FRect d{cx - px/2.f, cy - px/2.f, float(px), float(px)};
    if(shadow) {
        const float o = std::max(1.f, px/22.f);
        SDL_SetTextureColorMod(t, 0, 0, 0);
        SDL_SetTextureAlphaMod(t, static_cast<Uint8>(c.a*0.55));
        const SDL_FRect sd{d.x, d.y + o, d.w, d.h};
        SDL_RenderCopyExF(r, t, nullptr, &sd, angle, nullptr, SDL_FLIP_NONE);
    }
    SDL_SetTextureColorMod(t, c.r, c.g, c.b);
    SDL_SetTextureAlphaMod(t, c.a);
    SDL_RenderCopyExF(r, t, nullptr, &d, angle, nullptr, SDL_FLIP_NONE);
    SDL_SetTextureColorMod(t, 255, 255, 255);
    SDL_SetTextureAlphaMod(t, 255);
}

void medallion(SDL_Renderer* const r, const float cx, const float cy,
               const float diameter, const std::string& iconName,
               const double hover, const double active, const double press,
               const bool enabled) {
    eGeometryBatch::sFlush();
    const double pulse = 0.5 + 0.5*std::sin(time()*2.4);
    const float s = static_cast<float>(diameter*(1 + 0.05*hover*(1 - active) - 0.05*press));
    const float y = static_cast<float>(cy + 0.03*diameter*press);
    const Uint8 dim = enabled ? 255 : 110;
    glow(r, cx, y + s*0.09f, s*0.6f, s*0.58f, SDL_Color{0, 0, 0, static_cast<Uint8>(enabled ? 150 : 90)}, false);
    if(active > 0.01) {
        glow(r, cx, y, s*0.95f, s*0.95f,
             SDL_Color{255, 190, 80, static_cast<Uint8>((55 + 35*pulse)*active)}, true);
    }
    if(hover > 0.01) {
        glow(r, cx, y, s*0.8f, s*0.8f, SDL_Color{255, 200, 110, static_cast<Uint8>(60*hover)}, true);
    }
    const SDL_FRect d{cx - s/2, y - s/2, s, s};
    const int px = static_cast<int>(std::ceil(s));
    if(const auto t = medal(r, eMedalPart::disc, px)) {
        SDL_SetTextureAlphaMod(t, dim);
        SDL_SetTextureColorMod(t, enabled ? 255 : 150, enabled ? 255 : 150, enabled ? 255 : 150);
        SDL_RenderCopyF(r, t, nullptr, &d);
    }
    if(active > 0.01) {
        if(const auto t = medal(r, eMedalPart::discActive, px)) {
            SDL_SetTextureAlphaMod(t, static_cast<Uint8>(255*std::min(1.0, active)));
            SDL_SetTextureColorMod(t, 255, 255, 255);
            SDL_RenderCopyF(r, t, nullptr, &d);
        }
    }
    const int ipx = std::max(8, static_cast<int>(std::round(s*0.5)));
    SDL_Color ic = lerp(kGold, kGoldPale, hover);
    ic = lerp(ic, kInk, active);
    if(!enabled) ic = SDL_Color{120, 116, 106, 255};
    if(!iconName.empty()) drawIcon(r, iconName, cx, y + s*0.01f, ipx, ic, active < 0.5);
    if(const auto t = medal(r, eMedalPart::ring, px)) {
        const Uint8 g = enabled ? static_cast<Uint8>(225 + 30*hover) : 140;
        SDL_SetTextureColorMod(t, g, g, enabled ? static_cast<Uint8>(215 + 40*hover) : 130);
        SDL_SetTextureAlphaMod(t, dim);
        SDL_RenderCopyF(r, t, nullptr, &d);
        SDL_SetTextureColorMod(t, 255, 255, 255);
    }
}

}
