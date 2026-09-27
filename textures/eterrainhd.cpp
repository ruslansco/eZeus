#include "eterrainhd.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <map>

#include "etexture.h"
#include "egamedir.h"
#include "egeometrybatch.h"
#include "engine/etilebase.h"

bool eTerrainHD::sEnabled = true;
bool eTerrainHD::sAlphaDirty = false;
Uint64 eTerrainHD::sFrameSerial = 0;
const float eTerrainHD::sShoreShallow = .8f;

namespace {
    // Eight-second cyclic sea. Adjacent poses blend at display refresh rate.
    constexpr Uint64 sWaterLoopMs = 8000;
    // Diamonds are drawn this much larger (screen px) than the tile so that
    // they close any sub-pixel gap to neighbouring sprite tiles. Overlaps are
    // invisible: neighbouring plate tiles sample identical plate content.

    std::shared_ptr<eTexture> loadPlate(SDL_Renderer* const r,
                                        const std::string& dir,
                                        const std::string& name) {
        const auto tex = std::make_shared<eTexture>();
        const auto hi = dir + name + "@2x.png";
        if(std::filesystem::exists(hi) && tex->load(r, hi)) {
            tex->setDensity(2);tex->setScaleMode(SDL_ScaleModeLinear);
            return tex;
        }
        const auto lo = dir + name + ".png";
        if(std::filesystem::exists(lo) && tex->load(r, lo)) {
            tex->setScaleMode(SDL_ScaleModeLinear);return tex;
        }
        return nullptr;
    }
}

eTerrainHD::eTerrainHD(const int tileW, const int tileH) :
    mTileW(tileW), mTileH(tileH) {}

eTerrainHD* eTerrainHD::get(SDL_Renderer* const r,
                            const int tileW, const int tileH) {
    if(!sEnabled) return nullptr;
    static std::map<int, std::unique_ptr<eTerrainHD>> sPlates;
    const auto it = sPlates.find(tileH);
    if(it != sPlates.end()) return it->second.get();
    std::unique_ptr<eTerrainHD> t(new eTerrainHD(tileW, tileH));
    if(!t->load(r)) t.reset();
    const auto ptr = t.get();
    sPlates[tileH] = std::move(t);
    return ptr;
}

bool eTerrainHD::load(SDL_Renderer* const r) {
    const auto dir = eGameDir::texturesDir() + "Terrain/" +
                     std::to_string(mTileH) + "/";
    if(!std::filesystem::exists(dir)) return false;
    mSand = loadPlate(r, dir, "sand");
    mScrub = loadPlate(r, dir, "scrub");
    mScrubSparse = loadPlate(r, dir, "scrub_sparse");
    mFertile = loadPlate(r, dir, "fertile");
    mFertileSparse = loadPlate(r, dir, "fertile_sparse");
    mShallow = loadPlate(r, dir, "shallow");
    mBakedCoastal=std::filesystem::exists(dir+"coastal_material_v3.txt");
    for(int i = 0; i < 100; i++) {
        const std::string n = i < 10 ? "0" + std::to_string(i) :
                                       std::to_string(i);
        const auto f = loadPlate(r, dir, "water_" + n);
        if(!f) break;
        mWater.push_back(f);
    }
    for(int i=0;i<100;++i) {
        const auto f=loadPlate(r,dir,"shallow_"+(i<10?std::string("0"):std::string())+std::to_string(i));
        if(!f) break;
        mShallowFrames.push_back(f);
    }
    mShoreFoam = loadPlate(r,dir,"zeusLand1_foam");
    mShoreMask = loadPlate(r, dir, "zeusLand1_mask");
    mShoreDeco = loadPlate(r, dir, "zeusLand1_deco");
    mTrees[0] = loadPlate(r, dir, "zeusLand1_trees");
    mTrees[1] = loadPlate(r, dir, "zeusTrees_trees");
    mTrees[2] = loadPlate(r, dir, "poseidonTrees_trees");
    mRocks = loadPlate(r, dir, "zeusLand1_rocks");
    mCliffs[0] = loadPlate(r, dir, "zeusElevationTiles_cliffs");
    mCliffs[1] = loadPlate(r, dir, "zeusElevationTiles2_cliffs");
    mRoad = loadPlate(r, dir, "road");
    mRoadPretty = loadPlate(r, dir, "road_pretty");
    mRoadEdges = loadPlate(r, dir, "road_edges");
    mAvenueDeco = loadPlate(r, dir, "avenue_deco");
    const auto valid=[&](const std::shared_ptr<eTexture>& t) {
        if(!t) return false;
        const int pw=t->width()-2*mTileW,ph=t->height()-2*mTileH;
        return pw>0 && ph>0 && pw%mTileW==0 && ph%mTileH==0 && pw/mTileW==ph/mTileH;
    };
    const auto sequenceValid=[&](const std::vector<std::shared_ptr<eTexture>>& frames) {
        for(const auto& t : frames)
            if(!valid(t) || t->width()!=frames[0]->width() || t->height()!=frames[0]->height() ||
               t->density()!=frames[0]->density()) return false;
        return true;
    };
    if(!sequenceValid(mShallowFrames)) mShallowFrames.clear();
    if(mScrubSparse && !valid(mScrubSparse)) mScrubSparse.reset();
    if(mFertile && !valid(mFertile)) mFertile.reset();
    if(mRoad && !valid(mRoad)) mRoad.reset();
    if(mRoadPretty && !valid(mRoadPretty)) mRoadPretty.reset();
    if(mRoadEdges && (mRoadEdges->width() != 4*mTileW || mRoadEdges->height() != 2*mTileH)) mRoadEdges.reset();
    if(mFertileSparse && (!mFertile || !valid(mFertileSparse))) mFertileSparse.reset();
    if(mShoreMask && mShoreDeco &&
       (mShoreMask->width()!=mShoreDeco->width() || mShoreMask->height()!=mShoreDeco->height())) {
        mShoreMask.reset();mShoreDeco.reset();mShoreFoam.reset();
    }
    if(mShoreFoam && (!mShoreMask || mShoreFoam->width()!=mShoreMask->width() ||
                     mShoreFoam->height()!=mShoreMask->height())) mShoreFoam.reset();
    const bool ok = valid(mSand) && valid(mScrub) && valid(mShallow) && !mWater.empty() && sequenceValid(mWater);
    if(ok) {
        printf("Loaded HD terrain plates for tile height %i (%i water frames)\n",
               mTileH, static_cast<int>(mWater.size()));
    }
    return ok;
}

namespace {
    // Blend whole repeating plates once per viewport frame. Tiles keep one batched
    // draw each, and shore stencils sample exactly the same surface as open water.
    const eTexture* blendSea(SDL_Renderer* r,
                            const std::vector<std::shared_ptr<eTexture>>& frames,
                            std::shared_ptr<eTexture>& target,Uint64 milliseconds) {
        if(frames.empty()) return nullptr;
        const double phase=(milliseconds%sWaterLoopMs)/double(sWaterLoopMs)*frames.size();
        const int first=int(phase), next=(first+1)%frames.size();
        const auto& a=*frames[first];const auto& b=*frames[next];
        if(frames.size()==1) return &a;
        const auto additive=SDL_ComposeCustomBlendMode(
            SDL_BLENDFACTOR_ONE,SDL_BLENDFACTOR_ONE,SDL_BLENDOPERATION_ADD,
            SDL_BLENDFACTOR_ONE,SDL_BLENDFACTOR_ONE,SDL_BLENDOPERATION_ADD);
        if(SDL_SetTextureBlendMode(a.tex(),additive)!=0 || SDL_SetTextureBlendMode(b.tex(),additive)!=0) {
            SDL_SetTextureBlendMode(a.tex(),SDL_BLENDMODE_BLEND);
            SDL_SetTextureBlendMode(b.tex(),SDL_BLENDMODE_BLEND);return &a;
        }
        if(!target) {
            target=std::make_shared<eTexture>();
            if(!target->create(r,a.width()*a.density(),a.height()*a.density())) {
                target.reset();SDL_SetTextureBlendMode(a.tex(),SDL_BLENDMODE_BLEND);
                SDL_SetTextureBlendMode(b.tex(),SDL_BLENDMODE_BLEND);return &a;
            }
            target->setDensity(a.density());target->setScaleMode(SDL_ScaleModeLinear);
        }
        eGeometryBatch::sFlush();
        auto previous=SDL_GetRenderTarget(r);
        SDL_Rect viewport,clip;SDL_RenderGetViewport(r,&viewport);SDL_RenderGetClipRect(r,&clip);
        const bool clipped=SDL_RenderIsClipEnabled(r);
        float scaleX,scaleY;SDL_RenderGetScale(r,&scaleX,&scaleY);
        Uint8 red,green,blue,alpha;SDL_GetRenderDrawColor(r,&red,&green,&blue,&alpha);
        SDL_BlendMode drawMode;SDL_GetRenderDrawBlendMode(r,&drawMode);
        SDL_SetRenderTarget(r,target->tex());SDL_RenderSetScale(r,1,1);
        SDL_RenderSetViewport(r,nullptr);SDL_RenderSetClipRect(r,nullptr);
        SDL_SetRenderDrawColor(r,0,0,0,0);SDL_RenderClear(r);
        const Uint8 weight=Uint8(std::lround((phase-first)*255));
        const auto layer=[&](const eTexture& texture,Uint8 w) {
            SDL_SetTextureColorMod(texture.tex(),w,w,w);SDL_SetTextureAlphaMod(texture.tex(),w);
            SDL_RenderCopy(r,texture.tex(),nullptr,nullptr);
            SDL_SetTextureColorMod(texture.tex(),255,255,255);SDL_SetTextureAlphaMod(texture.tex(),255);
            SDL_SetTextureBlendMode(texture.tex(),SDL_BLENDMODE_BLEND);
        };
        layer(a,255-weight);layer(b,weight);
        SDL_SetRenderTarget(r,previous);SDL_RenderSetScale(r,scaleX,scaleY);
        SDL_RenderSetViewport(r,&viewport);SDL_RenderSetClipRect(r,clipped?&clip:nullptr);
        SDL_SetRenderDrawColor(r,red,green,blue,alpha);SDL_SetRenderDrawBlendMode(r,drawMode);
        return target.get();
    }

    // Shore masks must sample the same already-composited shallow water as
    // adjoining open-water tiles. A tinted sprite overlay has an antialiased
    // diamond border and leaves a dark seam along otherwise continuous water.
    const eTexture* blendCoastal(SDL_Renderer* r,const eTexture& water,
                                 const eTexture& shallow,
                                 std::shared_ptr<eTexture>& target) {
        if(water.width()!=shallow.width() || water.height()!=shallow.height() ||
           water.density()!=shallow.density()) return &water;
        if(!target) {
            target=std::make_shared<eTexture>();
            if(!target->create(r,water.width()*water.density(),water.height()*water.density())) {
                target.reset();return &water;
            }
            target->setDensity(water.density());target->setScaleMode(SDL_ScaleModeLinear);
        }
        eGeometryBatch::sFlush();
        auto previous=SDL_GetRenderTarget(r);
        SDL_Rect viewport,clip;SDL_RenderGetViewport(r,&viewport);SDL_RenderGetClipRect(r,&clip);
        const bool clipped=SDL_RenderIsClipEnabled(r);
        float sx,sy;SDL_RenderGetScale(r,&sx,&sy);
        Uint8 red,green,blue,alpha;SDL_GetRenderDrawColor(r,&red,&green,&blue,&alpha);
        SDL_BlendMode drawMode;SDL_GetRenderDrawBlendMode(r,&drawMode);
        SDL_SetRenderTarget(r,target->tex());SDL_RenderSetScale(r,1,1);
        SDL_RenderSetViewport(r,nullptr);SDL_RenderSetClipRect(r,nullptr);
        SDL_SetTextureBlendMode(water.tex(),SDL_BLENDMODE_NONE);
        SDL_RenderCopy(r,water.tex(),nullptr,nullptr);
        SDL_SetTextureBlendMode(water.tex(),SDL_BLENDMODE_BLEND);
        SDL_SetTextureAlphaMod(shallow.tex(),Uint8(std::lround(255*eTerrainHD::sShoreShallow)));
        SDL_RenderCopy(r,shallow.tex(),nullptr,nullptr);
        SDL_SetTextureAlphaMod(shallow.tex(),255);
        SDL_SetRenderTarget(r,previous);SDL_RenderSetScale(r,sx,sy);
        SDL_RenderSetViewport(r,&viewport);SDL_RenderSetClipRect(r,clipped?&clip:nullptr);
        SDL_SetRenderDrawColor(r,red,green,blue,alpha);SDL_SetRenderDrawBlendMode(r,drawMode);
        return target.get();
    }
}

void eTerrainHD::prepareFrame(SDL_Renderer* r,Uint64 milliseconds) const {
    if(mPreparedFrame==sFrameSerial) return;
    mPreparedFrame=sFrameSerial;mFrameTime=milliseconds;
    mCurrentWater=blendSea(r,mWater,mWaterBlend,milliseconds);
    mCurrentShallow=mShallowFrames.empty()?mShallow.get():blendSea(r,mShallowFrames,mShallowBlend,milliseconds);
    mCurrentCoastal=mBakedCoastal?mCurrentShallow:
        blendCoastal(r,*mCurrentWater,*mCurrentShallow,mCoastalBlend);
}

float eTerrainHD::shallowWeight(const eTileBase* tile) const {
    if(!tile) return 0.f;
    if(tile->terrain()!=eTerrain::water) return sShoreShallow;
    if(mDepthFrame!=sFrameSerial) {
        mDepthWeights.clear();
        mDepthFrame=sFrameSerial;
    }
    const auto found=mDepthWeights.find(tile);
    if(found!=mDepthWeights.end()) return found->second;
    int distanceSquared=16;
    for(int dy=-3;dy<=3;++dy) for(int dx=-3;dx<=3;++dx) {
        const int d=dx*dx+dy*dy;
        if(d==0 || d>=distanceSquared) continue;
        const auto neighbour=tile->tileRel(dx,dy);
        if(neighbour && neighbour->terrain()!=eTerrain::water) distanceSquared=d;
    }
    const float t=std::clamp((std::sqrt(float(distanceSquared))-1.4f)/2.6f,0.f,1.f);
    const float weight=sShoreShallow*(1-t*t*(3-2*t));
    mDepthWeights.emplace(tile,weight);
    return weight;
}

float eTerrainHD::fertileField(const eTileBase* tile) const {
    if(!tile) return 0.f;
    if(mFertileFrame!=sFrameSerial) {
        mFertileField.clear();
        mFertileFrame=sFrameSerial;
    }
    const auto found=mFertileField.find(tile);
    if(found!=mFertileField.end()) return found->second;
    float neighbours=0.f;
    for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
        if(!x && !y) continue;
        const auto n=tile->tileRel(x,y);
        if(n && n->terrain()==eTerrain::fertile) neighbours+=1.f;
    }
    const float value=(tile->terrain()==eTerrain::fertile?.55f:0.f)+.45f*neighbours/8.f;
    mFertileField.emplace(tile,value);
    return value;
}

void eTerrainHD::fertileWeights(const eTileBase* tile, eWorldDirection dir, float weights[5]) const {
    if(!tile) { std::fill(weights,weights+5,0.f);return; }
    const eTileBase* nb[4][3] = {
        {tile->topLeftRotated(dir),tile->topRightRotated(dir),tile->topRotated(dir)},
        {tile->topRightRotated(dir),tile->bottomRightRotated(dir),tile->rightRotated(dir)},
        {tile->bottomRightRotated(dir),tile->bottomLeftRotated(dir),tile->bottomRotated(dir)},
        {tile->bottomLeftRotated(dir),tile->topLeftRotated(dir),tile->leftRotated(dir)}};
    const auto curve=[](float value) {
        const float t=std::clamp((value-.03f)/.80f,0.f,1.f);
        return t*t*(3.f-2.f*t);
    };
    const float self=fertileField(tile);
    for(int c=0;c<4;++c)
        weights[c]=curve((self+fertileField(nb[c][0])+fertileField(nb[c][1])+fertileField(nb[c][2]))*.25f);
    weights[4]=curve(self);
    if(tile->terrain()==eTerrain::fertile) weights[4]=std::max(.86f,weights[4]);
}

void eTerrainHD::drawPlate(SDL_Renderer* const r,
                           const eTexture& plate,
                           const double x, const double y,
                           const int u, const int v,
                           const float alpha[4],
                           const SDL_Color& mod,
                           const bool batched,
                           const float bleed,
                           const float centerAlpha) const {
    // Plate layout (logical px): the repeating block is P tiles along both
    // map axes, i.e. PW = P*W wide and PH = P*H high on screen, surrounded
    // by a margin so any diamond fits: size = (PW + 2W) x (PH + 2H), lattice
    // origin at (W/2, H/2).
    const double W = mTileW;
    const double H = mTileH;
    const double pw = plate.width() - 2*W;
    const double ph = plate.height() - 2*H;
    if(pw <= 0 || ph <= 0) return;
    double px = std::fmod(0.5*(u - v)*W, pw);
    if(px < 0) px += pw;
    double py = std::fmod(0.5*(u + v)*H, ph);
    if(py < 0) py += ph;
    px += 0.5*W;
    py += 0.5*H;

    const float e = bleed;
    const float ex = 2*e;
    const float dx[4] = {float(0.5*W), float(W) + ex, float(0.5*W), -ex};
    const float dy[4] = {-e, float(0.5*H), float(H) + e, float(0.5*H)};
    const float tw = plate.width();
    const float th = plate.height();
    SDL_Vertex vs[5];
    for(int i = 0; i < 4; i++) {
        auto& vt = vs[i];
        vt.position.x = x + dx[i];
        vt.position.y = y + dy[i];
        vt.color = SDL_Color{mod.r, mod.g, mod.b,
                             Uint8(std::lround(255*std::clamp(alpha[i], 0.f, 1.f)))};
        vt.tex_coord.x = (px + dx[i])/tw;
        vt.tex_coord.y = (py + dy[i])/th;
    }
    if(centerAlpha>=0.f) {
        vs[4]={{float(x+W*.5),float(y+H*.5)},
               {mod.r,mod.g,mod.b,Uint8(std::lround(255*std::clamp(centerAlpha,0.f,1.f)))},
               {float((px+W*.5)/tw),float((py+H*.5)/th)}};
        eGeometryBatch::sQueueFan(r,plate.tex(),vs);
        return;
    }
    if(batched) {
        eGeometryBatch::sQueueQuad(r, plate.tex(), vs);
        return;
    }
    eGeometryBatch::sFlush();
    static const int ids[6] = {0, 1, 2, 0, 2, 3};
    SDL_RenderGeometry(r, plate.tex(), vs, 4, ids, 6);
}

void eTerrainHD::drawGround(SDL_Renderer* const r,
                            const double x, const double y,
                            const int u, const int v,
                            const float scrub[4],
                            const SDL_Color& mod) const {
    static const float one[4] = {1, 1, 1, 1};
    drawPlate(r, *mSand, x, y, u, v, one, mod, true, 0.f);
    if(scrub[0] <= 0 && scrub[1] <= 0 && scrub[2] <= 0 && scrub[3] <= 0) return;
    if(!mScrubSparse) {
        drawPlate(r, *mScrub, x, y, u, v, scrub, mod, true, 0.f);
        return;
    }
    // Scattered tufts come in first, then the dense sward fills in.
    float sparse[4];
    float dense[4];
    for(int i = 0; i < 4; i++) {
        sparse[i] = std::min(1.f, 2*scrub[i]);
        dense[i] = std::max(0.f, 2*scrub[i] - 1);
    }
    drawPlate(r, *mScrubSparse, x, y, u, v, sparse, mod, true, 0.f);
    if(dense[0] > 0 || dense[1] > 0 || dense[2] > 0 || dense[3] > 0) {
        drawPlate(r, *mScrub, x, y, u, v, dense, mod, true, 0.f);
    }
}

void eTerrainHD::drawFertile(SDL_Renderer* const r,
                             const double x, const double y,
                             const int u, const int v,
                             const float weights[5],
                             const SDL_Color& mod) const {
    if(!mFertile) return;
    if(std::all_of(weights,weights+5,[](float w){return w<=0;})) return;
    if(!mFertileSparse) {
        drawPlate(r, *mFertile, x, y, u, v, weights, mod, true, 0.f, weights[4]);
        return;
    }
    float sparse[5];
    float dense[5];
    for(int i = 0; i < 5; i++) {
        sparse[i] = std::min(1.f, 2*weights[i]);
        dense[i] = std::max(0.f, 2*weights[i] - 1);
    }
    drawPlate(r, *mFertileSparse, x, y, u, v, sparse, mod, true, 0.f, sparse[4]);
    if(std::any_of(dense,dense+5,[](float w){return w>0;})) {
        drawPlate(r, *mFertile, x, y, u, v, dense, mod, true, 0.f, dense[4]);
    }
}

namespace {
    // Copies the source alpha into the frame's alpha, leaving colour untouched.
    SDL_BlendMode writeAlphaMode() {
        static const auto m = SDL_ComposeCustomBlendMode(
            SDL_BLENDFACTOR_ZERO, SDL_BLENDFACTOR_ONE, SDL_BLENDOPERATION_ADD,
            SDL_BLENDFACTOR_ONE, SDL_BLENDFACTOR_ZERO, SDL_BLENDOPERATION_ADD);
        return m;
    }
    // Blends the source over the frame weighted by the frame's alpha.
    SDL_BlendMode throughAlphaMode() {
        static const auto m = SDL_ComposeCustomBlendMode(
            SDL_BLENDFACTOR_DST_ALPHA, SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA, SDL_BLENDOPERATION_ADD,
            SDL_BLENDFACTOR_ZERO, SDL_BLENDFACTOR_ONE, SDL_BLENDOPERATION_ADD);
        return m;
    }
}

void eTerrainHD::drawShore(SDL_Renderer* const r,
                           const double x, const double y,
                           const int u, const int v,
                           const eTexture& legacy,
                           const int sx, const int sy,
                           const SDL_Color& mod) const {
    static const float one[4] = {1, 1, 1, 1};
    drawPlate(r, *mSand, x, y, u, v, one, mod, true, 0.f);

    const SDL_Rect src{legacy.x(), legacy.y(), legacy.width(), legacy.height()};
    // Legacy shoreline sheets are 58/29 pixels wide; the modern diamonds are
    // 60/30. Fit the mask to that width so the last columns cannot retain a
    // neighbouring tile's stencil or leave isolated blue pixels on the bank.
    const SDL_Rect dst{sx, sy, mTileW, legacy.height()};
    SDL_SetTextureBlendMode(mShoreMask->tex(), writeAlphaMode());
    mShoreMask->render(r, src, dst);
    sAlphaDirty = true;

    prepareFrame(r,SDL_GetTicks64());
    const auto& water = *mCurrentCoastal;
    SDL_SetTextureBlendMode(water.tex(), throughAlphaMode());
    drawPlate(r, water, x, y, u, v, one, mod, false, 0.f);
    SDL_SetTextureBlendMode(water.tex(), SDL_BLENDMODE_BLEND);

    SDL_SetTextureColorMod(mShoreDeco->tex(), mod.r, mod.g, mod.b);
    mShoreDeco->render(r, src, dst);
    SDL_SetTextureColorMod(mShoreDeco->tex(), 255, 255, 255);
    if(mShoreFoam) {
        const double phase=(mFrameTime%sWaterLoopMs)/double(sWaterLoopMs)*6.28318530718-.10*(u+v);
        mShoreFoam->setColorMod(mod.r,mod.g,mod.b);
        mShoreFoam->setAlpha(Uint8(170+65*std::sin(phase)));
        mShoreFoam->render(r,src,dst);
        mShoreFoam->clearAlphaMod();mShoreFoam->clearColorMod();
    }
}

bool eTerrainHD::hasTrees(const int sheet) const {
    return sheet >= 0 && sheet < 3 && mTrees[sheet];
}

void eTerrainHD::drawForest(SDL_Renderer* const r,
                            const double x, const double y,
                            const int u, const int v,
                            const float scrub[4],
                            const eTexture& legacy, const int sheet,
                            const int sx, const int sy,
                            const SDL_Color& mod) const {
    drawGround(r, x, y, u, v, scrub, mod);
    const auto& trees = mTrees[sheet];
    const SDL_Rect src{legacy.x(), legacy.y(), legacy.width(), legacy.height()};
    const SDL_Rect dst{sx, sy, legacy.width(), legacy.height()};
    SDL_SetTextureColorMod(trees->tex(), mod.r, mod.g, mod.b);
    trees->render(r, src, dst);
    SDL_SetTextureColorMod(trees->tex(), 255, 255, 255);
}

void eTerrainHD::drawRocks(SDL_Renderer* const r, const eTexture& legacy,
                           const int sx, const int sy, const SDL_Color& mod) const {
    const SDL_Rect src{legacy.x(), legacy.y(), legacy.width(), legacy.height()};
    const SDL_Rect dst{sx, sy, legacy.width(), legacy.height()};
    SDL_SetTextureColorMod(mRocks->tex(), mod.r, mod.g, mod.b);
    mRocks->render(r, src, dst);
    SDL_SetTextureColorMod(mRocks->tex(), 255, 255, 255);
}

void eTerrainHD::drawCliff(SDL_Renderer* const r, const eTexture& legacy, const int sheet,
                           const int sx, const int sy, const SDL_Color& mod) const {
    const auto& t = mCliffs[sheet];
    const SDL_Rect src{legacy.x(), legacy.y(), legacy.width(), legacy.height()};
    const SDL_Rect dst{sx, sy, legacy.width(), legacy.height()};
    SDL_SetTextureColorMod(t->tex(), mod.r, mod.g, mod.b);
    t->render(r, src, dst);
    SDL_SetTextureColorMod(t->tex(), 255, 255, 255);
}

void eTerrainHD::drawRoad(SDL_Renderer* const r,
                          const double x, const double y,
                          const int u, const int v,
                          const bool pretty, const int open,
                          const SDL_Color& mod) const {
    static const float one[4] = {1, 1, 1, 1};
    drawPlate(r, pretty ? *mRoadPretty : *mRoad, x, y, u, v, one, mod);
    if(!open) return;
    eGeometryBatch::sFlush();
    SDL_SetTextureColorMod(mRoadEdges->tex(), mod.r, mod.g, mod.b);
    const SDL_Rect dst{int(std::round(x)), int(std::round(y)), mTileW, mTileH};
    for(int side = 0; side < 4; side++) {
        if(!(open & (1 << side))) continue;
        const SDL_Rect src{side*mTileW, (pretty ? 1 : 0)*mTileH, mTileW, mTileH};
        mRoadEdges->render(r, src, dst);
    }
    SDL_SetTextureColorMod(mRoadEdges->tex(), 255, 255, 255);
}

void eTerrainHD::drawAvenueDeco(SDL_Renderer* const r, const eTexture& legacy,
                                const int sx, const int sy, const SDL_Color& mod) const {
    const SDL_Rect src{legacy.x(), legacy.y(), legacy.width(), legacy.height()};
    const SDL_Rect dst{sx, sy, legacy.width(), legacy.height()};
    SDL_SetTextureColorMod(mAvenueDeco->tex(), mod.r, mod.g, mod.b);
    mAvenueDeco->render(r, src, dst);
    SDL_SetTextureColorMod(mAvenueDeco->tex(), 255, 255, 255);
}

void eTerrainHD::sFinishFrame(SDL_Renderer* const r) {
    eGeometryBatch::sFlush();
    ++sFrameSerial;
    if(!sAlphaDirty) return;
    sAlphaDirty = false;
    float sx, sy;
    SDL_RenderGetScale(r, &sx, &sy);
    SDL_RenderSetScale(r, 1, 1);
    SDL_Rect clip;
    const bool clipped = SDL_RenderIsClipEnabled(r);
    SDL_RenderGetClipRect(r, &clip);
    SDL_RenderSetClipRect(r, nullptr);
    SDL_BlendMode old;
    SDL_GetRenderDrawBlendMode(r, &old);
    Uint8 cr, cg, cb, ca;
    SDL_GetRenderDrawColor(r, &cr, &cg, &cb, &ca);
    SDL_SetRenderDrawBlendMode(r, writeAlphaMode());
    SDL_SetRenderDrawColor(r, 0, 0, 0, 255);
    SDL_RenderFillRect(r, nullptr);
    SDL_SetRenderDrawBlendMode(r, old);
    SDL_SetRenderDrawColor(r, cr, cg, cb, ca);
    if(clipped) SDL_RenderSetClipRect(r, &clip);
    SDL_RenderSetScale(r, sx, sy);
}

void eTerrainHD::drawWater(SDL_Renderer* const r,
                           const double x, const double y,
                           const int u, const int v,
                           const float shallow[4],
                           const SDL_Color& mod) const {
    static const float one[4] = {1, 1, 1, 1};
    prepareFrame(r,SDL_GetTicks64());
    // Water layers tessellate exactly. Bleeding the next opaque tile over a
    // previous tile's translucent shallow layer creates a diagonal dark grid.
    drawPlate(r, *mCurrentWater, x, y, u, v, one, mod, true, 0.f);
    if(shallow[0] > 0 || shallow[1] > 0 || shallow[2] > 0 || shallow[3] > 0) {
        float weight[4];
        for(int i=0;i<4;++i) weight[i]=mBakedCoastal?
            std::min(1.f,shallow[i]/sShoreShallow):shallow[i];
        drawPlate(r, *mCurrentShallow, x, y, u, v, weight, mod, true, 0.f);
    }
}
