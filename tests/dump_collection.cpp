#include "egamedir.h"
#include "textures/egametextures.h"
#include "textures/egeometrybatch.h"

#include <cassert>
#include <fstream>
#include <iostream>

// Dumps legacy sprite collections (for remastering pieces that must sit exactly where the legacy
// sprite sat): dump_collection <out dir> <tileH 15|30|45|60>. Writes <out>/<name>_<id>.png (the
// sprite as is) and <out>/<name>.txt: "id width height offsetX offsetY" per sprite.
int main(int argc, char** argv) {
    assert(argc > 2);
    const std::string out = argv[1];
    const int th = atoi(argv[2]);
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    eGameDir::initialize();
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 2048, 2048, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    eGameTextures::setSettings(settings);
    eGameTextures::loadHippodrome();
    eGameTextures::loadPyramid();
    eGameTextures::loadPoseidonCommonHouse();
    eGameTextures::loadPoseidonEliteHouse();
    eGameTextures::loadOliveTree();
    eGameTextures::loadVine();
    eGameTextures::loadHorseRanch();
    eGameTextures::loadCommonHouse();
    const int sizeId = th == 15 ? 0 : th == 30 ? 1 : th == 45 ? 2 : 3;
    const_cast<eBuildingTextures&>(eGameTextures::buildings()[sizeId]).load();
    const_cast<eTerrainTextures&>(eGameTextures::terrain()[sizeId]).load();
    const auto& b = eGameTextures::buildings()[sizeId];
    const auto dumpTexs = [&](const std::string& name, const std::vector<std::shared_ptr<eTexture>>& texs) {
        std::ofstream txt(out + "/" + name + ".txt");
        for(int i = 0; i < (int)texs.size(); i++) {
            const auto& t = texs[i];
            if(!t) continue;
            txt << i << " " << t->width() << " " << t->height() << " " << t->offsetX() << " " << t->offsetY() << "\n";
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
            SDL_RenderClear(renderer);
            t->render(renderer, 0, 0);
            eGeometryBatch::sFlush();
            SDL_RenderFlush(renderer);
            auto sub = SDL_CreateRGBSurfaceWithFormat(0, t->width(), t->height(), 32, SDL_PIXELFORMAT_RGBA32);
            SDL_Rect r{0, 0, t->width(), t->height()};
            SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE);
            SDL_BlitSurface(surface, &r, sub, nullptr);
            IMG_SavePNG(sub, (out + "/" + name + "_" + std::to_string(i) + ".png").c_str());
            SDL_FreeSurface(sub);
        }
        std::cout << name << ": " << texs.size() << "\n";
    };
    const auto dump = [&](const std::string& name, const eTextureCollection& coll) {
        std::vector<std::shared_ptr<eTexture>> texs;
        for(int i = 0; i < coll.size(); i++) texs.push_back(coll.getTexture(i));
        dumpTexs(name, texs);
    };
    dump("hippodrome", b.fHippodrome);
    dump("pyramid", b.fPyramid);
    dump("pyramid2", b.fPyramid2);
    eGameTextures::loadBanners();
    {
        const auto& c = eGameTextures::characters()[sizeId];
        dump("banner_rod", c.fBannerRod);
        for(int i = 0; i < (int)c.fBanners.size(); i++) dump("banner" + std::to_string(i), c.fBanners[i]);
        dump("banner_tops", c.fBannerTops);
        dump("banner_ptops", c.fPoseidonBannerTops);
    }
    dump("olive", b.fOliveTree);
    dump("vine", b.fVine);
    dump("orange", b.fOrangeTree);
    dumpTexs("house_space", {b.fHouseSpace});
    dumpTexs("enclosure", {b.fHorseRanchEnclosure});
    dump("tiny_stones", eGameTextures::terrain()[sizeId].fTinyStones);
    for(int i = 0; i < (int)b.fPoseidonCommonHouse.size(); i++) dump("pcommon" + std::to_string(i), b.fPoseidonCommonHouse[i]);
    for(int i = 0; i < (int)b.fPoseidonEliteHouse.size(); i++) dump("pelite" + std::to_string(i), b.fPoseidonEliteHouse[i]);
}
