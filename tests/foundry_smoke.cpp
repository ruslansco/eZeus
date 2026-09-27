#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/efoundry.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

int main(int argc, char**) {
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 64, 64, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    assert(renderer);
    eGameDir::initialize();
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    eGameTextures::setSettings(settings);
    eWorldBoard world;
    eGameBoard board(world);
    board.setRegisterBuildingsEnabled(false);
    eFoundry foundry(board, eCityId::neutralFriendly);
    foundry.setFrameShift(0);
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        assert(foundry.getTexture(eTileSize::s30) == textures[1].fFoundry);
        (void)foundry.getOverlays(eTileSize::s30);
        std::cout << "PASS: foundry legacy fallback\n";
        return 0;
    }

    for(int zoom = 0; zoom < 4; ++zoom) {
        for(int direction = 0; direction < 4; ++direction) {
            const auto size = static_cast<eTileSize>(zoom);
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            foundry.setEnabled(false);
            assert(foundry.getTexture(size) == textures[zoom].fFoundryHD[direction][8]);
            for(int frame = 0; frame < 9; ++frame) {
                const auto texture = textures[zoom].fFoundryHD[direction][frame];
                assert(texture);
                assert(texture->width() == 80*(zoom + 1));
                assert(texture->x() == frame*80*(zoom + 1));
            }
            foundry.setEnabled(true);
            for(int load = 0; load < 4; ++load) foundry.addRaw();
            for(int frame = 0; frame < 8; ++frame) {
                foundry.setFrameShift(4*frame);
                assert(foundry.getTexture(size) == textures[zoom].fFoundryHD[direction][frame]);
            }
            foundry.setEmployed(0);
            assert(foundry.getTexture(size) == textures[zoom].fFoundryHD[direction][8]);
            foundry.setEmployed(15);
        }
    }
    std::cout << "PASS: foundry 144 cells, rotations, working loop and idle states\n";
}
