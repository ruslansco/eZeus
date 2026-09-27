#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/etimbermill.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

// Remastered timber mill: 4x9 atlas at every zoom, rotation rows, working loop only
// while staffed with logs, idle column otherwise, and legacy fallback.
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
    eTimberMill mill(board, eCityId::neutralFriendly);
    mill.setFrameShift(0);
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        assert(!textures[1].fTimberMillHD[0][0]);
        assert(mill.getTexture(eTileSize::s30) == textures[1].fTimberMill);
        (void)mill.getOverlays(eTileSize::s30);
        std::cout << "PASS: timber mill legacy fallback\n";
        return 0;
    }

    for(int zoom = 0; zoom < 4; ++zoom) {
        for(int direction = 0; direction < 4; ++direction) {
            const auto size = static_cast<eTileSize>(zoom);
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            mill.setEnabled(false);
            assert(mill.getTexture(size) == textures[zoom].fTimberMillHD[direction][8]);
            for(const auto& o : mill.getOverlays(size)) assert(o.fTex && !o.fAlignTop);   // HD stock overlays only
            for(int frame = 0; frame < 9; ++frame) {
                const auto texture = textures[zoom].fTimberMillHD[direction][frame];
                assert(texture);
                assert(texture->width() == 80*(zoom + 1));
                assert(texture->x() == frame*80*(zoom + 1));
                assert(texture->y() == direction*80*(zoom + 1));
            }
            mill.setEnabled(true);
            // Staffed but without logs (first pass only): sawyers wait, idle pose.
            if(zoom == 0 && direction == 0) {
                assert(mill.getTexture(size) == textures[zoom].fTimberMillHD[direction][8]);
            }
            for(int load = 0; load < 4; ++load) mill.addRaw();
            for(int frame = 0; frame < 8; ++frame) {
                mill.setFrameShift(4*frame);
                assert(mill.getTexture(size) == textures[zoom].fTimberMillHD[direction][frame]);
            }
            mill.setEmployed(0);
            assert(mill.getTexture(size) == textures[zoom].fTimberMillHD[direction][8]);
            mill.setEmployed(12);
        }
    }
    std::cout << "PASS: timber mill 144 cells, rotations, working loop and idle states\n";
}
