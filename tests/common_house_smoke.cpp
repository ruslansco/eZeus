#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/esmallhouse.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

// Remastered common houses: 14 atlases (7 levels x 2 variants) of 4x9 cells at every zoom,
// rotation rows, the resident's 8-frame loop while inhabited, the vacant plot when empty, and
// per-atlas legacy fallback (missing / 8-column / 1 px / corrupt 30.png of any one house).
struct TestHouse : public eSmallHouse {
    using eSmallHouse::eSmallHouse;
    using eHouseBase::setLevel;
    using eHouseBase::setPeople;
};

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
    board.addCityToBoard(eCityId::neutralFriendly);      // houses keep the city's population data
    TestHouse h(board, eCityId::neutralFriendly);
    h.setFrameShift(0);
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        int missing = 0;
        h.setPeople(1);
        for(int level = 0; level < 7; ++level) {
            h.setLevel(level);
            for(int v = 0; v < 2; ++v) {
                h.setSeed(v);
                const auto& hd = textures[1].fCommonHouseHD[level*2 + v];
                const auto tex = h.getTexture(eTileSize::s30);
                if(!hd[0][0]) {
                    ++missing;
                    assert(tex == textures[1].fCommonHouse[level].getTexture(v));
                } else {
                    assert(tex == hd[0][0]);
                }
            }
        }
        assert(missing == 1);
        std::cout << "PASS: common house legacy fallback\n";
        return 0;
    }

    int cells = 0;
    for(int zoom = 0; zoom < 4; ++zoom) {
        const auto size = static_cast<eTileSize>(zoom);
        for(int direction = 0; direction < 4; ++direction) {
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            for(int level = 0; level < 7; ++level) {
                h.setLevel(level);
                for(int v = 0; v < 2; ++v) {
                    h.setSeed(v);
                    const auto& frames = textures[zoom].fCommonHouseHD[level*2 + v][direction];
                    for(int frame = 0; frame < 9; ++frame) {
                        const auto texture = frames[frame];
                        assert(texture);
                        assert(texture->width() == 80*(zoom + 1));
                        assert(texture->x() == frame*80*(zoom + 1));
                        assert(texture->y() == direction*80*(zoom + 1));
                        ++cells;
                    }
                    h.setPeople(0);
                    assert(h.getTexture(size) == textures[zoom].fHouseSpace);
                    h.setPeople(1);
                    for(int frame = 0; frame < 8; ++frame) {
                        h.setFrameShift(4*frame);
                        assert(h.getTexture(size) == frames[frame]);
                    }
                    h.setFrameShift(0);
                }
            }
        }
    }
    std::cout << "PASS: common houses " << cells << " cells, 7 levels x 2 variants, rotations, resident loop, vacant plot\n";
}
