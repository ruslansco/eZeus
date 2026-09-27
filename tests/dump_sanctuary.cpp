#include "egamedir.h"
#include "textures/egametextures.h"

#include <cassert>
#include <iostream>
#include <string>

// Reference dump of the original sanctuary sprites (art/sanctuary/original/*.png) at zoom 30:
// temple pieces (4 views x 3 construction stages), god statues, altar, paving, monuments.
// Each PNG is the sprite on a transparent canvas; the name carries its offset for alignment.
int main(int argc, char** argv) {
    assert(argc > 1);
    const std::string out = argv[1];
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 800, 800, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    assert(renderer);
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    eGameDir::initialize();
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    eGameTextures::setSettings(settings);
    eGameTextures::loadZeusSanctuary();
    eGameTextures::loadPoseidonSanctuary();
    eGameTextures::loadZeusMonuments();
    eGameTextures::loadAthenaMonuments();
    eGameTextures::loadHadesMonuments();
    const auto& b = eGameTextures::buildings()[1];
    const auto save = [&](const std::shared_ptr<eTexture>& tex, const std::string& name) {
        if(!tex) return;
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        tex->render(renderer, 0, 0);
        SDL_Rect r{0, 0, tex->width(), tex->height()};
        auto crop = SDL_CreateRGBSurfaceWithFormat(0, r.w, r.h, 32, SDL_PIXELFORMAT_RGBA32);
        SDL_BlitSurface(surface, &r, crop, nullptr);
        const auto path = out + "/" + name + "_o" + std::to_string(tex->offsetX()) + "_" +
                          std::to_string(tex->offsetY()) + ".png";
        IMG_SavePNG(crop, path.c_str());
        SDL_FreeSurface(crop);
    };
    for(size_t d = 0; d < b.fSanctuary.size(); d++) {
        for(int s = 0; s < b.fSanctuary[d].size(); s++) {
            save(b.fSanctuary[d].getTexture(s), "temple_id" + std::to_string(d) + "_stage" + std::to_string(s));
        }
    }
    for(int d = 0; d < b.fPoseidonSanctuary.size(); d++) save(b.fPoseidonSanctuary.getTexture(d), "poseidon_temple_id" + std::to_string(d));
    const std::pair<const char*, const eTextureCollection*> statues[] = {
        {"zeus", &b.fZeusStatues}, {"poseidon", &b.fPoseidonStatues}, {"hades", &b.fHadesStatues},
        {"demeter", &b.fDemeterStatues}, {"athena", &b.fAthenaStatues}, {"artemis", &b.fArtemisStatues},
        {"apollo", &b.fApolloStatues}, {"ares", &b.fAresStatues}, {"hephaestus", &b.fHephaestusStatues},
        {"aphrodite", &b.fAphroditeStatues}, {"hermes", &b.fHermesStatues}, {"dionysus", &b.fDionysusStatues}};
    for(const auto& [n, c] : statues) {
        for(int d = 0; d < c->size(); d++) save(c->getTexture(d), std::string("statue_") + n + "_" + std::to_string(d));
    }
    save(b.fSanctuaryAltar, "altar");
    for(int i = 0; i < b.fSanctuaryTiles.size(); i++) save(b.fSanctuaryTiles.getTexture(i), "tile" + std::to_string(i));
    for(int i = 0; i < b.fSanctuarySpace.size(); i++) save(b.fSanctuarySpace.getTexture(i), "space" + std::to_string(i));
    for(int i = 0; i < b.fSanctuaryFire.size(); i += 4) save(b.fSanctuaryFire.getTexture(i), "fire" + std::to_string(i));
    for(int i = 0; i < b.fSanctuaryHOverlay.size(); i += 8) save(b.fSanctuaryHOverlay.getTexture(i), "overlayH" + std::to_string(i));
    save(b.fBlankMonument, "monument_blank");
    for(int i = 0; i < b.fZeusMonuments.size(); i++) save(b.fZeusMonuments.getTexture(i), "monument_zeus" + std::to_string(i));
    for(int i = 0; i < b.fAthenaMonuments.size(); i++) save(b.fAthenaMonuments.getTexture(i), "monument_athena" + std::to_string(i));
    std::cout << "dumped sanctuary sprites\n";
}
