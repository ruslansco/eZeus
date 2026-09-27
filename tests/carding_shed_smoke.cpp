#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/ecardingshed.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

// Remastered carding shed: 4x9 atlas at every zoom, rotation rows, working loop only
// while working, idle column otherwise, and legacy fallback.
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
    eCardingShed b(board, eCityId::neutralFriendly);
    b.setFrameShift(0);
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        assert(!textures[1].fCardingShedHD[0][0]);
        assert(b.getTexture(eTileSize::s30) == textures[1].fCardingShed);
        (void)b.getOverlays(eTileSize::s30);
        std::cout << "PASS: carding shed legacy fallback\n";
        return 0;
    }

    bool first = true;
    for(int zoom = 0; zoom < 4; ++zoom) {
        for(int direction = 0; direction < 4; ++direction) {
            const auto size = static_cast<eTileSize>(zoom);
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            b.setEnabled(false);
            assert(b.getTexture(size) == textures[zoom].fCardingShedHD[direction][8]);
            for(const auto& o : b.getOverlays(size)) assert(o.fTex && !o.fAlignTop);   // HD stock overlays only
            for(int frame = 0; frame < 9; ++frame) {
                const auto texture = textures[zoom].fCardingShedHD[direction][frame];
                assert(texture);
                assert(texture->width() == 80*(zoom + 1));
                assert(texture->x() == frame*80*(zoom + 1));
                assert(texture->y() == direction*80*(zoom + 1));
            }
            b.setEnabled(true);
            (void)first;
            
            for(int frame = 0; frame < 8; ++frame) {
                b.setFrameShift(4*frame);
                assert(b.getTexture(size) == textures[zoom].fCardingShedHD[direction][frame]);
            }
            b.setEmployed(0);
            assert(b.getTexture(size) == textures[zoom].fCardingShedHD[direction][8]);
            b.setEmployed(8);
        }
    }
    std::cout << "PASS: carding shed 144 cells, rotations, working loop and idle states\n";
}
