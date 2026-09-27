#include "textures/eterrainhd.h"
#include "textures/egeometrybatch.h"
#include "egamedir.h"
#include "etexture.h"
#include "engine/etilebase.h"
#include <cassert>
#include <cmath>
#include <iostream>
#include <vector>
#include <cstring>

class DepthTile final : public eTileBase {
public:
    bool hasRoad() const override { return false; }
    bool hasCharacter(const eHasChar&) const override { return false; }
    eBuildingType underBuildingType() const override { return static_cast<eBuildingType>(0); }
    bool onFire() const override { return false; }
    void setOnFire(bool) override {}
};

int main(int argc,char** argv) {
    assert(argc==7);
    const int H=std::stoi(argv[1]),W=2*H;
    assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
    auto window=SDL_CreateWindow("Terrain verification",0,0,480,320,SDL_WINDOW_HIDDEN);
    auto renderer=SDL_CreateRenderer(window,-1,SDL_RENDERER_ACCELERATED|SDL_RENDERER_TARGETTEXTURE);
    assert(renderer);eGameDir::initialize();
    const auto hd=eTerrainHD::get(renderer,W,H);
    if(std::string(argv[2])=="fallback") { assert(!hd);std::cout<<"PASS: invalid or missing terrain falls back\n";return 0; }
    assert(hd && hd->hasShores());
    // Visual bathymetry must fade into open water and update after an edit.
    std::vector<DepthTile> grid(81);
    const auto tile=[&](int x,int y)->DepthTile* {
        return x<0 || x>=9 || y<0 || y>=9 ? nullptr : &grid[y*9+x];
    };
    for(int y=0;y<9;++y) for(int x=0;x<9;++x) {
        auto t=tile(x,y);t->setTerrain(x==0?eTerrain::dry:eTerrain::water);
        t->setTopLeft(tile(x-1,y));t->setBottomRight(tile(x+1,y));
        t->setTopRight(tile(x,y-1));t->setBottomLeft(tile(x,y+1));
    }
    const float coast=hd->shallowWeight(tile(1,4)),mid=hd->shallowWeight(tile(2,4)),far=hd->shallowWeight(tile(3,4));
    assert(coast>mid && mid>far && far>0 && hd->shallowWeight(tile(4,4))==0);
    assert(hd->shallowWeight(nullptr)==0);
    for(int y=0;y<9;++y) tile(0,y)->setTerrain(eTerrain::water);
    eTerrainHD::sFinishFrame(renderer);
    assert(hd->shallowWeight(tile(1,4))==0);
    eTerrainHD::sEnabled=false;assert(!eTerrainHD::get(renderer,W,H));eTerrainHD::sEnabled=true;
    eTexture canvas;assert(canvas.create(renderer,480,320));canvas.setAsRenderTarget(renderer);
    SDL_Rect viewport{3,4,450,300},clip{10,12,320,230};
    SDL_RenderSetViewport(renderer,&viewport);SDL_RenderSetScale(renderer,1.25f,1.25f);
    SDL_RenderSetClipRect(renderer,&clip);SDL_SetRenderDrawColor(renderer,11,22,33,44);
    SDL_SetRenderDrawBlendMode(renderer,SDL_BLENDMODE_ADD);
    SDL_RenderGetViewport(renderer,&viewport);
    hd->prepareFrame(renderer,0);
    SDL_Rect got;SDL_RenderGetViewport(renderer,&got);assert(!memcmp(&got,&viewport,sizeof got));
    SDL_RenderGetClipRect(renderer,&got);assert(!memcmp(&got,&clip,sizeof got));
    float sx,sy;SDL_RenderGetScale(renderer,&sx,&sy);assert(sx==1.25f&&sy==1.25f);
    Uint8 red,green,blue,alpha;SDL_GetRenderDrawColor(renderer,&red,&green,&blue,&alpha);
    assert(red==11&&green==22&&blue==33&&alpha==44 && SDL_GetRenderTarget(renderer)==canvas.tex());
    SDL_BlendMode mode;SDL_GetRenderDrawBlendMode(renderer,&mode);assert(mode==SDL_BLENDMODE_ADD);
    SDL_RenderSetScale(renderer,1,1);SDL_RenderSetViewport(renderer,nullptr);SDL_RenderSetClipRect(renderer,nullptr);
    eTerrainHD::sFinishFrame(renderer);
    const float waterWeights[4]={.8f,.8f,.8f,.8f};const SDL_Color white{255,255,255,255};
    auto parent=std::make_shared<eTexture>();
    eTexture legacy;legacy.setParentTexture({std::stoi(argv[3]),std::stoi(argv[4]),std::stoi(argv[5]),std::stoi(argv[6])},parent);
    auto capture=[&](Uint64 time) {
        SDL_SetRenderDrawColor(renderer,7,9,12,255);SDL_RenderClear(renderer);
        hd->prepareFrame(renderer,time);
        for(int u=-12;u<13;++u) for(int v=-12;v<13;++v) {
            const double x=240+(u-v)*W*.5,y=160+(u+v)*H*.5;
            if(std::string(argv[2])=="seams" && (u+v)%3==0)
                hd->drawShore(renderer,x,y,u,v,legacy,x,y+H-legacy.height(),white);
            else hd->drawWater(renderer,x,y,u,v,waterWeights,white);
        }
        eTerrainHD::sFinishFrame(renderer);
        std::vector<Uint8> pixels(480*320*4);
        assert(SDL_RenderReadPixels(renderer,nullptr,SDL_PIXELFORMAT_RGBA32,pixels.data(),480*4)==0);
        for(size_t i=3;i<pixels.size();i+=4) assert(pixels[i]==255);
        for(int y=110;y<210;++y) for(int x=140;x<340;++x) {
            const int i=(y*480+x)*4;
            assert(!(pixels[i]==7 && pixels[i+1]==9 && pixels[i+2]==12));
        }
        return pixels;
    };
    const auto first=capture(0),nearby=capture(2),middle=capture(166),end=capture(333),loop=capture(8000);
    if(std::string(argv[2])=="seams") {
        // Constant input materials must stay constant across every shared edge.
        // This detects both shallow double-blending and opaque neighbour bleed.
        for(int c=0;c<3;++c) {
            int low=255,high=0;
            for(int y=110;y<210;++y) for(int x=140;x<340;++x) {
                const int value=first[(y*480+x)*4+c];
                low=std::min(low,value);high=std::max(high,value);
            }
            assert(high-low<=1);
        }
        std::cout<<"PASS: terrain "<<H<<", open/shore water has no diamond-edge grid\n";
        return 0;
    }
    assert(first==loop && first!=middle && middle!=end);
    double small=0,big=0;
    for(size_t i=0;i<first.size();++i) {small+=std::abs(int(first[i])-nearby[i]);big+=std::abs(int(first[i])-end[i]);}
    assert(small<big && small/first.size()<2);
    hd->prepareFrame(renderer,750);
    const float grass[4]={0,.33f,1,.66f};
    hd->drawGround(renderer,80,80,1,2,grass,white);
    hd->drawShore(renderer,220,100,2,3,legacy,220,100+H-legacy.height(),white);
    eTerrainHD::sFinishFrame(renderer);
    auto image=SDL_CreateRGBSurfaceWithFormat(0,480,320,32,SDL_PIXELFORMAT_RGBA32);
    SDL_RenderReadPixels(renderer,nullptr,SDL_PIXELFORMAT_RGBA32,image->pixels,image->pitch);
    assert(IMG_SavePNG(image,eGameDir::path("terrain_runtime.png").c_str())==0);SDL_FreeSurface(image);
    std::cout<<"PASS: terrain "<<H<<", frame blending, eight-second loop, coherent tiles, depth falloff and live edit, renderer state, shore stencil, F9 fallback\n";
}
