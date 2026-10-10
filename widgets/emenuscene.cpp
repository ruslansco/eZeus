#include "emenuscene.h"

#include "egamedir.h"
#include "textures/egeometrybatch.h"
#include "audio/esounds.h"

#include <SDL_image.h>

#include <algorithm>
#include <fstream>
#include <string>
#include <cmath>

namespace {
const double kImgW = 1920;
const double kImgH = 1080;
const int kDepthW = 480;
const int kDepthH = 270;
const int kGridX = 96;
const int kGridY = 54;
// The layers cover the screen with this margin, which absorbs parallax and
// camera moves (see project()).
const double kOverscan = 1.10;
const double kOrbitX = 30;
const double kOrbitY = 16;
const double kFocusDepth = 0.35;
const double kIntroLength = 3.4;
const double kPi = 3.14159265358979;

double clamp01(const double v) {
    return std::max(0.0, std::min(1.0, v));
}

double smoothstep(const double a, const double b, const double x) {
    const double t = clamp01((x - a)/(b - a));
    return t*t*(3 - 2*t);
}

double easeOutCubic(const double t) {
    const double u = 1 - clamp01(t);
    return 1 - u*u*u;
}

struct eShotParams {
    double fZoom, fCamX, fCamY, fBlur, fDim;
};

eShotParams shotParams(const eMenuShot s) {
    switch(s) {
    case eMenuShot::main: return {0.0, 0, 0, 0, 0};
    case eMenuShot::adventures: return {0.10, -46, 8, 1, 0.30};
    case eMenuShot::settings: return {0.08, 44, -4, 1, 0.34};
    case eMenuShot::roster: return {0.06, 0, 14, 1, 0.34};
    case eMenuShot::loading: return {0.16, 0, -12, 0, 0.10};
    case eMenuShot::dialog: return {0.035, 0, 0, 0.85, 0.22};
    }
    return {0, 0, 0, 0, 0};
}

SDL_Texture* makeTexture(SDL_Renderer* const r, const int w, const int h,
                         const std::vector<Uint8>& rgba,
                         const SDL_BlendMode bm) {
    const auto t = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA32,
                                     SDL_TEXTUREACCESS_STATIC, w, h);
    if(!t) return nullptr;
    SDL_UpdateTexture(t, nullptr, rgba.data(), w*4);
    SDL_SetTextureBlendMode(t, bm);
    SDL_SetTextureScaleMode(t, SDL_ScaleModeLinear);
    return t;
}

// Out of focus copy: premultiplied 4x downsample plus three box passes
// (about a 10 px gaussian at full size), drawn back up with linear filtering.
SDL_Texture* makeBlurred(SDL_Renderer* const r, SDL_Surface* const s) {
    const int w = s->w/4;
    const int h = s->h/4;
    if(w < 4 || h < 4) return nullptr;
    std::vector<float> buf(w*h*4, 0.f);
    const auto px = static_cast<const Uint8*>(s->pixels);
    for(int y = 0; y < h*4; y++) {
        const Uint8* row = px + y*s->pitch;
        for(int x = 0; x < w*4; x++) {
            const Uint8* p = row + x*4;
            const float a = p[3]/255.f;
            float* o = &buf[((y/4)*w + x/4)*4];
            o[0] += p[0]*a;
            o[1] += p[1]*a;
            o[2] += p[2]*a;
            o[3] += a;
        }
    }
    for(auto& v : buf) v /= 16.f;
    std::vector<float> tmp(buf.size());
    const int rad = 2;
    for(int pass = 0; pass < 3; pass++) {
        for(int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                float acc[4] = {0, 0, 0, 0};
                for(int k = -rad; k <= rad; k++) {
                    const int xx = std::max(0, std::min(w - 1, x + k));
                    const float* p = &buf[(y*w + xx)*4];
                    for(int c = 0; c < 4; c++) acc[c] += p[c];
                }
                for(int c = 0; c < 4; c++) tmp[(y*w + x)*4 + c] = acc[c]/(2*rad + 1);
            }
        }
        for(int y = 0; y < h; y++) {
            for(int x = 0; x < w; x++) {
                float acc[4] = {0, 0, 0, 0};
                for(int k = -rad; k <= rad; k++) {
                    const int yy = std::max(0, std::min(h - 1, y + k));
                    const float* p = &tmp[(yy*w + x)*4];
                    for(int c = 0; c < 4; c++) acc[c] += p[c];
                }
                for(int c = 0; c < 4; c++) buf[(y*w + x)*4 + c] = acc[c]/(2*rad + 1);
            }
        }
    }
    std::vector<Uint8> out(w*h*4);
    for(int i = 0; i < w*h; i++) {
        const float a = buf[i*4 + 3];
        for(int c = 0; c < 3; c++) {
            const float v = a > 1e-4f ? buf[i*4 + c]/a : 0.f;
            out[i*4 + c] = static_cast<Uint8>(std::min(255.f, v));
        }
        out[i*4 + 3] = static_cast<Uint8>(std::min(255.f, a*255.f));
    }
    return makeTexture(r, w, h, out, SDL_BLENDMODE_BLEND);
}

// Value noise for the drifting haze.
struct eNoise {
    std::vector<float> fLattice;
    int fN = 64;
    explicit eNoise(const unsigned seed) {
        std::mt19937 rng(seed);
        std::uniform_real_distribution<float> d(0.f, 1.f);
        fLattice.resize(fN*fN);
        for(auto& v : fLattice) v = d(rng);
    }
    float at(const int x, const int y) const {
        return fLattice[((y%fN + fN)%fN)*fN + (x%fN + fN)%fN];
    }
    float sample(const float x, const float y) const {
        const int x0 = static_cast<int>(std::floor(x));
        const int y0 = static_cast<int>(std::floor(y));
        float fx = x - x0;
        float fy = y - y0;
        fx = fx*fx*(3 - 2*fx);
        fy = fy*fy*(3 - 2*fy);
        const float a = at(x0, y0) + (at(x0 + 1, y0) - at(x0, y0))*fx;
        const float b = at(x0, y0 + 1) + (at(x0 + 1, y0 + 1) - at(x0, y0 + 1))*fx;
        return a + (b - a)*fy;
    }
    float fbm(float x, float y) const {
        float sum = 0.f;
        float amp = 0.5f;
        for(int o = 0; o < 5; o++) {
            sum += amp*sample(x, y);
            x *= 2.03f;
            y *= 2.01f;
            amp *= 0.5f;
        }
        return sum;
    }
};

// A thin, stretched streak of haze like the painted ones.
SDL_Texture* makeCloud(SDL_Renderer* const r, const unsigned seed) {
    const int w = 512;
    const int h = 112;
    const eNoise n(seed);
    std::vector<Uint8> px(w*h*4);
    for(int y = 0; y < h; y++) {
        for(int x = 0; x < w; x++) {
            const float u = x/float(w);
            const float v = y/float(h);
            const float ends = static_cast<float>(smoothstep(0.0, 0.22, u)*smoothstep(1.0, 0.7, u));
            const float centre = 0.5f + 0.08f*std::sin(u*6.f + seed);
            const float dv = (v - centre)/0.22f;
            const float band = std::exp(-dv*dv*2.2f);
            const float f = n.fbm(u*7.f, v*2.2f + seed*0.37f);
            const float dens = std::max(0.f, std::min(1.f, (f*band*ends - 0.16f)*2.6f));
            const float a = std::pow(dens, 1.25f);
            Uint8* p = &px[(y*w + x)*4];
            p[0] = static_cast<Uint8>(222 + 33*dens);
            p[1] = static_cast<Uint8>(226 + 29*dens);
            p[2] = 250;
            p[3] = static_cast<Uint8>(a*255.f);
        }
    }
    return makeTexture(r, w, h, px, SDL_BLENDMODE_BLEND);
}

SDL_Texture* makeDot(SDL_Renderer* const r) {
    const int s = 64;
    std::vector<Uint8> px(s*s*4);
    for(int y = 0; y < s; y++) {
        for(int x = 0; x < s; x++) {
            const float dx = (x + 0.5f)/s*2 - 1;
            const float dy = (y + 0.5f)/s*2 - 1;
            const float d2 = dx*dx + dy*dy;
            const float a = std::max(0.f, std::exp(-d2*4.5f) - 0.011f);
            Uint8* p = &px[(y*s + x)*4];
            p[0] = p[1] = p[2] = 255;
            p[3] = static_cast<Uint8>(std::min(255.f, a*258.f));
        }
    }
    return makeTexture(r, s, s, px, SDL_BLENDMODE_ADD);
}

SDL_Texture* makeVignette(SDL_Renderer* const r) {
    const int s = 256;
    std::vector<Uint8> px(s*s*4);
    for(int y = 0; y < s; y++) {
        for(int x = 0; x < s; x++) {
            const double dx = (x + 0.5)/s*2 - 1;
            const double dy = (y + 0.5)/s*2 - 1;
            const double d = std::sqrt(dx*dx*0.8 + dy*dy);
            const double a = std::pow(smoothstep(0.35, 1.45, d), 1.4);
            Uint8* p = &px[(y*s + x)*4];
            p[0] = 4; p[1] = 7; p[2] = 16;
            p[3] = static_cast<Uint8>(a*255);
        }
    }
    return makeTexture(r, s, s, px, SDL_BLENDMODE_BLEND);
}

// Light shaft: soft across, fading along its length.
SDL_Texture* makeRay(SDL_Renderer* const r) {
    const int w = 256;
    const int h = 64;
    std::vector<Uint8> px(w*h*4);
    for(int y = 0; y < h; y++) {
        for(int x = 0; x < w; x++) {
            const double u = x/double(w - 1);
            const double v = (y + 0.5)/h*2 - 1;
            const double a = std::exp(-v*v*3.5)*std::pow(1 - u, 1.6)*smoothstep(0.0, 0.08, u);
            Uint8* p = &px[(y*w + x)*4];
            p[0] = p[1] = p[2] = 255;
            p[3] = static_cast<Uint8>(a*255);
        }
    }
    return makeTexture(r, w, h, px, SDL_BLENDMODE_ADD);
}

// Cross-section of a lightning channel: bright core, wide soft glow.
SDL_Texture* makeBeam(SDL_Renderer* const r) {
    const int w = 64;
    const int h = 2;
    std::vector<Uint8> px(w*h*4);
    for(int y = 0; y < h; y++) {
        for(int x = 0; x < w; x++) {
            const double v = (x + 0.5)/w*2 - 1;
            const double a = 0.9*std::exp(-v*v*90) + 0.35*std::exp(-v*v*9) +
                             0.12*std::exp(-v*v*2);
            Uint8* p = &px[(y*w + x)*4];
            p[0] = p[1] = p[2] = 255;
            p[3] = static_cast<Uint8>(std::min(1.0, a)*255);
        }
    }
    return makeTexture(r, w, h, px, SDL_BLENDMODE_ADD);
}

void quadIndices(std::vector<int>& ids, const int base) {
    const int q[6] = {0, 1, 2, 0, 2, 3};
    for(const int i : q) ids.push_back(base + i);
}
} // namespace

void eMenuScene::eSpring::update(const double dt, const double omega) {
    // critically damped spring, sub-stepped for stability
    double left = dt;
    while(left > 1e-6) {
        const double h = std::min(left, 1/120.);
        const double a = omega*omega*(fTarget - fX) - 2*omega*fV;
        fV += a*h;
        fX += fV*h;
        left -= h;
    }
}

eMenuScene& eMenuScene::instance() {
    static eMenuScene sScene;
    return sScene;
}

void eMenuScene::mouseState(int& x, int& y) const {
    if(mPointerOverride) {
        x = mOverrideX;
        y = mOverrideY;
        return;
    }
    SDL_GetMouseState(&x, &y);
}

void eMenuScene::setPointerOverride(const int x, const int y) {
    mPointerOverride = true;
    mOverrideX = x;
    mOverrideY = y;
}

void eMenuScene::setShot(const eMenuShot shot) {
    mShot = shot;
    if(shot != eMenuShot::main && mIntroT < kIntroLength) {
        mIntroT = kIntroLength;
        mIntroStruck = true;
    }
    const auto p = shotParams(shot);
    mZoom.fTarget = p.fZoom;
    mCamX.fTarget = p.fCamX;
    mCamY.fTarget = p.fCamY;
    mBlur.fTarget = p.fBlur;
    mDim.fTarget = p.fDim;
}

void eMenuScene::playIntro() {
    mIntroT = 0;
    mIntroStruck = false;
    mNextStrike = 16;
}

void eMenuScene::skipIntro() {
    if(mIntroT >= kIntroLength) return;
    mIntroT = kIntroLength;
    mZoom.fX = mZoom.fTarget;
    mCamY.fX = mCamY.fTarget;
    mZoom.fV = mCamY.fV = 0;
    mIntroStruck = true;
}

void eMenuScene::strike(const bool sound) {
    makeBolt();
    mBoltT = 0;
    if(sound) eSounds::playMenuThunderSound();
}

void eMenuScene::parallax(const double d, float& dx, float& dy) const {
    const double u = mH/1080.;
    dx = static_cast<float>(-mCamX.fX*u*(d + 0.25) - mLookX*kOrbitX*u*(d - kFocusDepth));
    dy = static_cast<float>(-mCamY.fX*u*(d + 0.25) - mLookY*kOrbitY*u*(d - kFocusDepth));
}

SDL_FPoint eMenuScene::project(const double ix, const double iy,
                               const double d) const {
    // mostly a uniform zoom: a strong depth-dependent dolly would pull the
    // trees off the land and expose the fill painted behind them
    const double z = 1 + mZoom.fX*(0.9 + 0.1*d);
    float dx, dy;
    parallax(d, dx, dy);
    return SDL_FPoint{static_cast<float>(mW*0.5 + (ix - kImgW/2)*mScale*z + dx),
                      static_cast<float>(mH*0.5 + (iy - kImgH/2)*mScale*z + dy)};
}

void eMenuScene::loadLayer(SDL_Renderer* const r, const std::string& path,
                           eLayer& layer, const bool keepDepth) {
    (void)keepDepth;
    const auto surf = IMG_Load(path.c_str());
    if(!surf) {
        printf("eMenuScene: missing %s\n", path.c_str());
        return;
    }
    const auto rgba = SDL_ConvertSurfaceFormat(surf, SDL_PIXELFORMAT_RGBA32, 0);
    SDL_FreeSurface(surf);
    if(!rgba) return;
    layer.fSharp = SDL_CreateTextureFromSurface(r, rgba);
    if(layer.fSharp) {
        SDL_SetTextureBlendMode(layer.fSharp, SDL_BLENDMODE_BLEND);
        SDL_SetTextureScaleMode(layer.fSharp, SDL_ScaleModeLinear);
    }
    layer.fBlurred = makeBlurred(r, rgba);
    SDL_FreeSurface(rgba);
}

bool eMenuScene::initialize(SDL_Renderer* const r) {
    mRenderer = r;
    const auto dir = eGameDir::texturesDir() + "Menu/";
    loadLayer(r, dir + "menu_sky.jpg", mSky, false);
    loadLayer(r, dir + "menu_land.png", mLand, true);
    loadLayer(r, dir + "menu_trees.png", mTrees, false);

    mDepth.assign(kDepthW*kDepthH, 0.3f);
    mSway.assign(kDepthW*kDepthH, 0.f);
    if(const auto ds = IMG_Load((dir + "menu_depth.png").c_str())) {
        const auto rgba = SDL_ConvertSurfaceFormat(ds, SDL_PIXELFORMAT_RGBA32, 0);
        SDL_FreeSurface(ds);
        if(rgba && rgba->w == kDepthW && rgba->h == kDepthH) {
            const auto px = static_cast<const Uint8*>(rgba->pixels);
            for(int y = 0; y < kDepthH; y++) {
                for(int x = 0; x < kDepthW; x++) {
                    const Uint8* p = px + y*rgba->pitch + x*4;
                    mDepth[y*kDepthW + x] = p[0]/255.f;
                    mSway[y*kDepthW + x] = p[1]/255.f;
                }
            }
        }
        if(rgba) SDL_FreeSurface(rgba);
    }
    mHasLayers = mSky.fSharp && mLand.fSharp && mTrees.fSharp;
    // menu_scene.txt (written by art/menu/backdrop/pack_backdrop.py): "sun_side right" when
    // the backdrop is lit from the upper right; the painting is lit from the left.
    {
        std::ifstream f(dir + "menu_scene.txt");
        std::string key, value;
        while(f >> key >> value) {
            if(key == "sun_side") mSunRight = value == "right";
        }
    }
    if(!mHasLayers) {
        const auto path = eGameDir::texturesDir() + "Zeus_Data_Images/Zeus_FE_Registry.jpg";
        if(const auto s = IMG_Load(path.c_str())) {
            mFallback = SDL_CreateTextureFromSurface(r, s);
            SDL_FreeSurface(s);
        }
    }

    for(unsigned i = 0; i < 4; i++) {
        mCloudTex.push_back(makeCloud(r, 7 + i*13));
    }
    mDot = makeDot(r);
    mVignette = makeVignette(r);
    mRay = makeRay(r);
    mBeam = makeBeam(r);
    {
        std::vector<Uint8> white(4*4*4, 255);
        mWhite = makeTexture(r, 4, 4, white, SDL_BLENDMODE_BLEND);
    }

    std::uniform_real_distribution<double> u01(0, 1);
    const double cloudY[] = {70, 150, 250, 330, 470, 520};
    for(int i = 0; i < 6; i++) {
        eCloud c;
        c.fX = -300 + u01(mRng)*2400;
        c.fY = cloudY[i] + u01(mRng)*30;
        c.fW = 520 + u01(mRng)*520;
        c.fH = c.fW*(0.16 + u01(mRng)*0.08);
        c.fSpeed = 5 + u01(mRng)*9 + (i < 3 ? 4 : 0);
        c.fTex = i % 4;
        c.fAlpha = static_cast<Uint8>(i >= 4 ? 120 : 95 + u01(mRng)*70);
        mClouds.push_back(c);
    }
    for(int i = 0; i < 38; i++) {
        eMote m;
        m.fX = u01(mRng)*kImgW;
        m.fY = 300 + u01(mRng)*800;
        m.fD = 0.75 + u01(mRng)*0.6;
        m.fSize = 2.2 + u01(mRng)*3.8;
        m.fPhase = u01(mRng)*2*kPi;
        m.fVX = 4 + u01(mRng)*9;
        m.fVY = -(2 + u01(mRng)*6);
        mMotes.push_back(m);
    }

    // static index buffer for the layer meshes
    mIndices.clear();
    for(int j = 0; j < kGridY; j++) {
        for(int i = 0; i < kGridX; i++) {
            const int a = j*(kGridX + 1) + i;
            const int b = a + 1;
            const int c = a + kGridX + 1;
            const int d = c + 1;
            mIndices.insert(mIndices.end(), {a, b, d, a, d, c});
        }
    }
    mInitialized = true;
    return true;
}

void eMenuScene::spawnFlock() {
    std::uniform_real_distribution<double> u01(0, 1);
    mBirds.clear();
    mFlockDir = u01(mRng) < 0.5 ? 1 : -1;
    mFlockX = mFlockDir > 0 ? -160 : kImgW + 160;
    mFlockY = 170 + u01(mRng)*150;           // clear of the mountain ridges
    const int n = 4 + static_cast<int>(u01(mRng)*4);
    for(int i = 0; i < n; i++) {
        eBird b;
        b.fX = -mFlockDir*(i*34 + u01(mRng)*26);
        b.fY = (i % 2 ? 1 : -1)*(i*9 + u01(mRng)*12);
        b.fPhase = u01(mRng)*2*kPi;
        b.fSize = 7 + u01(mRng)*4;
        mBirds.push_back(b);
    }
}

void eMenuScene::makeBolt() {
    std::uniform_real_distribution<double> u01(0, 1);
    mBolts.clear();
    const auto branch = [&](SDL_FPoint a, SDL_FPoint b, const double width,
                            const double rough) {
        std::vector<SDL_FPoint> pts{a, b};
        double disp = rough;
        for(int level = 0; level < 6; level++) {
            std::vector<SDL_FPoint> next;
            for(size_t i = 0; i + 1 < pts.size(); i++) {
                const auto p = pts[i];
                const auto q = pts[i + 1];
                const double mx = (p.x + q.x)*0.5;
                const double my = (p.y + q.y)*0.5;
                const double dx = q.x - p.x;
                const double dy = q.y - p.y;
                const double len = std::max(1e-3, std::sqrt(dx*dx + dy*dy));
                const double off = (u01(mRng)*2 - 1)*disp;
                next.push_back(p);
                next.push_back({static_cast<float>(mx - dy/len*off),
                                static_cast<float>(my + dx/len*off)});
            }
            next.push_back(pts.back());
            pts.swap(next);
            disp *= 0.55;
        }
        mBolts.push_back({pts, width});
        return pts;
    };
    // either side of the emblem: over the mountain or above the acropolis
    const bool right = mBoltRight;
    mBoltRight = !mBoltRight;
    const double x0 = right ? 1260 + u01(mRng)*380 : 240 + u01(mRng)*360;
    const double x1 = x0 + (u01(mRng)*2 - 1)*160;
    const double y1 = 520 + u01(mRng)*90;
    const auto main = branch({static_cast<float>(x0), -30.f},
                             {static_cast<float>(x1), static_cast<float>(y1)},
                             1.0, 150);
    const int forks = 2 + static_cast<int>(u01(mRng)*2);
    for(int f = 0; f < forks; f++) {
        const auto& s = main[static_cast<size_t>((0.2 + 0.5*u01(mRng))*main.size())];
        const double ang = (u01(mRng) < 0.5 ? -1 : 1)*(0.4 + u01(mRng)*0.6);
        const double len = 120 + u01(mRng)*200;
        const SDL_FPoint e{static_cast<float>(s.x + std::sin(ang)*len),
                           static_cast<float>(s.y + std::cos(ang)*len)};
        branch(s, e, 0.45, 60);
    }
}

void eMenuScene::update(const double dt, const int w, const int h) {
    mTime += dt;
    std::uniform_real_distribution<double> u01(0, 1);

    int mx = w/2;
    int my = h/2;
    mouseState(mx, my);
    const double tx = std::max(-1.0, std::min(1.0, (mx - w*0.5)/(w*0.5)));
    const double ty = std::max(-1.0, std::min(1.0, (my - h*0.5)/(h*0.5)));
    const double k = 1 - std::exp(-dt*3.2);
    mPtrX += (tx - mPtrX)*k;
    mPtrY += (ty - mPtrY)*k;
    mLookX = mPtrX*0.85 + 0.22*std::sin(mTime*0.21) + 0.08*std::sin(mTime*0.53 + 1.3);
    mLookY = mPtrY*0.85 + 0.18*std::sin(mTime*0.17 + 0.7);

    if(mIntroT < kIntroLength) {
        mIntroT += dt;
        const double e = easeOutCubic(mIntroT/kIntroLength);
        mZoom.fX = mZoom.fTarget + 0.46*(1 - e);
        mCamY.fX = mCamY.fTarget - 46*(1 - e);
        mZoom.fV = mCamY.fV = 0;
        mCamX.update(dt, 2.6);
        if(!mIntroStruck && mIntroT > 0.75) {
            mIntroStruck = true;
            strike(true);
        }
    } else {
        mZoom.update(dt, 2.4);
        mCamX.update(dt, 2.4);
        mCamY.update(dt, 2.4);
    }
    mBlur.update(dt, 7);
    mDim.update(dt, 7);
    mBlur.fX = clamp01(mBlur.fX);
    mDim.fX = clamp01(mDim.fX);

    // lightning
    mBoltT += dt;
    if(mShot == eMenuShot::main && mIntroT >= kIntroLength) {
        mNextStrike -= dt;
        if(mNextStrike <= 0) {
            mNextStrike = 22 + u01(mRng)*26;
            strike(false);
        }
    }
    {
        const double t = mBoltT;
        double f = 0;
        if(t < 0.05) f = 1;
        else if(t < 0.09) f = 0.3;
        else if(t < 0.17) f = 0.95;
        else f = 0.95*std::exp(-(t - 0.17)*6);
        mFlash = t < 1.5 ? f : 0;
    }

    for(auto& c : mClouds) {
        c.fX += c.fSpeed*dt;
        if(c.fX > kImgW + 200) c.fX = -c.fW - 200 - u01(mRng)*300;
    }

    mNextFlock -= dt;
    if(mNextFlock <= 0) {
        spawnFlock();
        mNextFlock = 26 + u01(mRng)*24;
    }
    mFlockX += mFlockDir*52*dt;
    mFlockY += std::sin(mTime*0.4)*3*dt;

    for(auto& m : mMotes) {
        m.fX += (m.fVX + 4*std::sin(mTime*0.7 + m.fPhase))*dt;
        m.fY += (m.fVY + 3*std::cos(mTime*0.9 + m.fPhase))*dt;
        if(m.fY < 260 || m.fX > kImgW + 60) {
            m.fX = u01(mRng)*kImgW - 200;
            m.fY = 1000 + u01(mRng)*120;
        }
    }
}

void eMenuScene::drawMesh(SDL_Renderer* const r, SDL_Texture* const tex,
                          const int kind, const Uint8 alpha) {
    if(!tex || alpha == 0) return;
    mVerts.resize((kGridX + 1)*(kGridY + 1));
    const double swayU = mH/1080.;
    for(int j = 0; j <= kGridY; j++) {
        const double iy = j*kImgH/kGridY;
        for(int i = 0; i <= kGridX; i++) {
            const double ix = i*kImgW/kGridX;
            const int dx = std::min(kDepthW - 1, static_cast<int>(ix/4));
            const int dy = std::min(kDepthH - 1, static_cast<int>(iy/4));
            double d = 0;
            if(kind == 1) d = mDepth[dy*kDepthW + dx];
            else if(kind == 2) d = 1.0;
            auto p = project(ix, iy, d);
            if(kind == 2) {
                const double s = mSway[dy*kDepthW + dx];
                if(s > 0.001) {
                    const double wave = std::sin(mTime*1.15 + ix*0.004 + iy*0.002) +
                                        0.35*std::sin(mTime*2.3 + ix*0.013);
                    p.x += static_cast<float>(wave*4.5*s*swayU);
                }
            }
            auto& v = mVerts[j*(kGridX + 1) + i];
            v.position = p;
            v.color = SDL_Color{255, 255, 255, alpha};
            v.tex_coord = SDL_FPoint{static_cast<float>(ix/kImgW),
                                     static_cast<float>(iy/kImgH)};
        }
    }
    SDL_RenderGeometry(r, tex, mVerts.data(), mVerts.size(),
                       mIndices.data(), mIndices.size());
}

void eMenuScene::drawImageQuad(SDL_Renderer* const r, SDL_Texture* const tex,
                               const double ix, const double iy,
                               const double iw, const double ih,
                               const double d, const SDL_Color c) const {
    const SDL_FPoint p0 = project(ix, iy, d);
    const SDL_FPoint p1 = project(ix + iw, iy + ih, d);
    const SDL_Vertex v[4] = {
        {{p0.x, p0.y}, c, {0, 0}},
        {{p1.x, p0.y}, c, {1, 0}},
        {{p1.x, p1.y}, c, {1, 1}},
        {{p0.x, p1.y}, c, {0, 1}}};
    const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, tex, v, 4, ids, 6);
}

void eMenuScene::drawBolts(SDL_Renderer* const r, const Uint8 alpha) {
    if(mBolts.empty() || alpha == 0) return;
    std::vector<SDL_Vertex> vs;
    std::vector<int> ids;
    const double u = mScale;
    for(const auto& b : mBolts) {
        const double hw = (b.fWidth > 0.8 ? 46 : 28)*u;
        for(size_t i = 0; i + 1 < b.fPts.size(); i++) {
            const auto p = project(b.fPts[i].x, b.fPts[i].y, 0.1);
            const auto q = project(b.fPts[i + 1].x, b.fPts[i + 1].y, 0.1);
            const double dx = q.x - p.x;
            const double dy = q.y - p.y;
            const double len = std::max(1e-3, std::sqrt(dx*dx + dy*dy));
            // taper toward the end of each branch
            const double t0 = 1 - 0.6*double(i)/b.fPts.size();
            const double t1 = 1 - 0.6*double(i + 1)/b.fPts.size();
            const float nx = static_cast<float>(-dy/len);
            const float ny = static_cast<float>(dx/len);
            const SDL_Color c{225, 232, 255, alpha};
            const int base = vs.size();
            const float w0 = static_cast<float>(hw*t0*b.fWidth);
            const float w1 = static_cast<float>(hw*t1*b.fWidth);
            // extend a little along the segment so joints overlap
            const float ex = static_cast<float>(dx/len*w0*0.25);
            const float ey = static_cast<float>(dy/len*w0*0.25);
            vs.push_back({{p.x - ex + nx*w0, p.y - ey + ny*w0}, c, {0, 0}});
            vs.push_back({{p.x - ex - nx*w0, p.y - ey - ny*w0}, c, {1, 0}});
            vs.push_back({{q.x + ex - nx*w1, q.y + ey - ny*w1}, c, {1, 1}});
            vs.push_back({{q.x + ex + nx*w1, q.y + ey + ny*w1}, c, {0, 1}});
            quadIndices(ids, base);
        }
    }
    SDL_SetTextureBlendMode(mBeam, SDL_BLENDMODE_ADD);
    SDL_RenderGeometry(r, mBeam, vs.data(), vs.size(), ids.data(), ids.size());

    // bloom along the main channel
    if(mDot && !mBolts.empty()) {
        std::vector<SDL_Vertex> gv;
        std::vector<int> gi;
        const auto& pts = mBolts.front().fPts;
        const SDL_Color c{170, 185, 255, static_cast<Uint8>(alpha*0.22)};
        for(size_t i = 0; i < pts.size(); i += 8) {
            const auto p = project(pts[i].x, pts[i].y, 0.1);
            const float rr = static_cast<float>(150*u);
            const int base = gv.size();
            gv.push_back({{p.x - rr, p.y - rr}, c, {0, 0}});
            gv.push_back({{p.x + rr, p.y - rr}, c, {1, 0}});
            gv.push_back({{p.x + rr, p.y + rr}, c, {1, 1}});
            gv.push_back({{p.x - rr, p.y + rr}, c, {0, 1}});
            quadIndices(gi, base);
        }
        SDL_SetTextureBlendMode(mDot, SDL_BLENDMODE_ADD);
        SDL_RenderGeometry(r, mDot, gv.data(), gv.size(), gi.data(), gi.size());
    }
}

void eMenuScene::paint(SDL_Renderer* const r, const int w, const int h) {
    eGeometryBatch::sFlush();
    if(!mInitialized || mRenderer != r) {
        initialize(r);
    }
    const Uint64 now = SDL_GetPerformanceCounter();
    double dt = mLastCounter ? double(now - mLastCounter)/SDL_GetPerformanceFrequency() : 0.;
    mLastCounter = now;
    dt = std::max(0.0, std::min(0.1, dt));

    mW = w;
    mH = h;
    mScale = std::max(w/kImgW, h/kImgH)*kOverscan;
    update(dt, w, h);

    SDL_RenderSetClipRect(r, nullptr);
    SDL_SetRenderDrawColor(r, 10, 16, 28, 255);
    SDL_RenderFillRect(r, nullptr);

    const double blur = mBlur.fX;
    const Uint8 sharpA = static_cast<Uint8>(std::round(255*(1 - blur)));
    const Uint8 blurA = static_cast<Uint8>(std::round(255*blur));
    const double u = h/1080.;

    if(!mHasLayers) {
        if(mFallback) drawImageQuad(r, mFallback, 0, 0, kImgW, kImgH, 0.4,
                                    SDL_Color{255, 255, 255, 255});
    } else {
        // sky
        drawMesh(r, mSky.fSharp, 0, 255);
        drawMesh(r, mSky.fBlurred, 0, blurA);

        // sun glow in the top corner on the lit side of the backdrop
        SDL_SetTextureBlendMode(mDot, SDL_BLENDMODE_ADD);
        {
            const double pulse = 0.85 + 0.15*std::sin(mTime*0.35);
            drawImageQuad(r, mDot, mSunRight ? kImgW - 900 : -900, -1000, 1800, 1700, 0.02,
                          SDL_Color{255, 238, 205, static_cast<Uint8>(70*pulse)});
        }

        // drifting haze
        for(const auto& c : mClouds) {
            const auto tex = mCloudTex[c.fTex];
            if(!tex) continue;
            const Uint8 a = static_cast<Uint8>(c.fAlpha*(1 - 0.5*blur));
            drawImageQuad(r, tex, c.fX, c.fY, c.fW, c.fH, 0.04,
                          SDL_Color{255, 255, 255, a});
        }

        // gulls, behind the mountains
        if(!mBirds.empty() && mWhite) {
            std::vector<SDL_Vertex> vs;
            std::vector<int> ids;
            const Uint8 a = static_cast<Uint8>(200*(1 - 0.6*blur));
            const SDL_Color col{62, 66, 92, a};
            for(const auto& b : mBirds) {
                const double bx = mFlockX + b.fX;
                const double by = mFlockY + b.fY + 4*std::sin(mTime*0.9 + b.fPhase);
                const auto c = project(bx, by, 0.22);
                const double s = b.fSize*mScale;
                const double f = std::sin(mTime*6.5 + b.fPhase);
                for(const int side : {-1, 1}) {
                    const float ex = static_cast<float>(c.x + side*s*0.45);
                    const float ey = static_cast<float>(c.y - s*(0.18 + 0.28*f));
                    const float tx = static_cast<float>(c.x + side*s);
                    const float ty = static_cast<float>(c.y - s*0.55*f + s*0.12);
                    const float th = static_cast<float>(std::max(0.8, s*0.13));
                    const int base = vs.size();
                    vs.push_back({{c.x, c.y - th}, col, {0.5f, 0.5f}});
                    vs.push_back({{ex, ey - th}, col, {0.5f, 0.5f}});
                    vs.push_back({{ex, ey + th}, col, {0.5f, 0.5f}});
                    vs.push_back({{c.x, c.y + th}, col, {0.5f, 0.5f}});
                    vs.push_back({{tx, ty}, col, {0.5f, 0.5f}});
                    ids.insert(ids.end(), {base, base + 1, base + 2, base, base + 2, base + 3,
                                           base + 1, base + 4, base + 2});
                }
            }
            SDL_RenderGeometry(r, mWhite, vs.data(), vs.size(), ids.data(), ids.size());
        }

        // lightning behind the mountains and the flash it throws on the sky
        if(mFlash > 0.01) {
            drawBolts(r, static_cast<Uint8>(255*std::min(1.0, mFlash*1.1)));
            SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_ADD);
            SDL_SetRenderDrawColor(r, 150, 160, 230, static_cast<Uint8>(80*mFlash));
            SDL_RenderFillRect(r, nullptr);
        }

        drawMesh(r, mLand.fSharp, 1, sharpA);
        drawMesh(r, mLand.fBlurred, 1, blurA);
        drawMesh(r, mTrees.fSharp, 2, sharpA);
        drawMesh(r, mTrees.fBlurred, 2, blurA);
    }

    // light shafts from the sun
    if(mRay) {
        std::vector<SDL_Vertex> vs;
        std::vector<int> ids;
        const auto o = project(mSunRight ? kImgW + 140 : -140, -180, 0.05);
        const double angles[] = {0.36, 0.47, 0.58, 0.70, 0.83, 0.97};
        const double widths[] = {150, 90, 210, 120, 170, 100};
        for(int i = 0; i < 6; i++) {
            const double a0 = angles[i] + 0.025*std::sin(mTime*0.11 + i*1.7);
            const double a = mSunRight ? kPi - a0 : a0;
            const double len = 1900*mScale;
            const double wEnd = widths[i]*mScale;
            const double wStart = wEnd*0.18;
            const double cx = std::cos(a);
            const double cy = std::sin(a);
            const double nx = -cy;
            const double ny = cx;
            const double pulse = 0.5 + 0.5*std::sin(mTime*0.23 + i*2.1);
            const Uint8 al = static_cast<Uint8>((8 + 18*pulse)*(1 - 0.35*blur));
            const SDL_Color c{255, 236, 196, al};
            const int base = vs.size();
            const float ox = o.x, oy = o.y;
            const float ex = static_cast<float>(o.x + cx*len);
            const float ey = static_cast<float>(o.y + cy*len);
            vs.push_back({{static_cast<float>(ox + nx*wStart), static_cast<float>(oy + ny*wStart)}, c, {0, 0}});
            vs.push_back({{static_cast<float>(ex + nx*wEnd), static_cast<float>(ey + ny*wEnd)}, c, {1, 0}});
            vs.push_back({{static_cast<float>(ex - nx*wEnd), static_cast<float>(ey - ny*wEnd)}, c, {1, 1}});
            vs.push_back({{static_cast<float>(ox - nx*wStart), static_cast<float>(oy - ny*wStart)}, c, {0, 1}});
            quadIndices(ids, base);
        }
        SDL_SetTextureBlendMode(mRay, SDL_BLENDMODE_ADD);
        SDL_RenderGeometry(r, mRay, vs.data(), vs.size(), ids.data(), ids.size());
    }

    // pollen in the warm air; soft bokeh when the backdrop is out of focus
    if(mDot) {
        std::vector<SDL_Vertex> vs;
        std::vector<int> ids;
        for(const auto& m : mMotes) {
            const auto p = project(m.fX, m.fY, m.fD);
            const double tw = 0.55 + 0.45*std::sin(mTime*1.4 + m.fPhase*3);
            const double s = m.fSize*u*(1 + 2.6*blur)*(0.7 + 0.5*(m.fD - 0.75));
            const Uint8 a = static_cast<Uint8>(std::min(255.0, (70 + 70*tw)*(1 - 0.45*blur)));
            const SDL_Color c{255, 226, 168, a};
            const int base = vs.size();
            const float x0 = static_cast<float>(p.x - s), x1 = static_cast<float>(p.x + s);
            const float y0 = static_cast<float>(p.y - s), y1 = static_cast<float>(p.y + s);
            vs.push_back({{x0, y0}, c, {0, 0}});
            vs.push_back({{x1, y0}, c, {1, 0}});
            vs.push_back({{x1, y1}, c, {1, 1}});
            vs.push_back({{x0, y1}, c, {0, 1}});
            quadIndices(ids, base);
        }
        SDL_SetTextureBlendMode(mDot, SDL_BLENDMODE_ADD);
        SDL_RenderGeometry(r, mDot, vs.data(), vs.size(), ids.data(), ids.size());
    }

    if(mFlash > 0.01) {
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_ADD);
        SDL_SetRenderDrawColor(r, 200, 205, 255, static_cast<Uint8>(34*mFlash));
        SDL_RenderFillRect(r, nullptr);
    }

    if(mDim.fX > 0.004) {
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
        SDL_SetRenderDrawColor(r, 6, 10, 20, static_cast<Uint8>(255*mDim.fX));
        SDL_RenderFillRect(r, nullptr);
    }
    if(mVignette) {
        const Uint8 va = static_cast<Uint8>(std::min(255.0, 170 + 60*mDim.fX));
        SDL_SetTextureAlphaMod(mVignette, va);
        SDL_RenderCopy(r, mVignette, nullptr, nullptr);
    }
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
}
