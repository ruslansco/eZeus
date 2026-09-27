#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/eelitehousing.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

// Remastered elite houses: 14 atlases (7 levels x 2 variants) of 4x9 cells at every zoom,
// rotation rows, the resident's 8-frame loop while inhabited, the vacant plot when empty, and
// per-atlas legacy fallback (missing / 8-column / 1 px / corrupt 30.png of any one house).
struct TestHouse : public eEliteHousing {
    using eEliteHousing::eEliteHousing;
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
    h.setTileRect({10, 10, 4, 4});
    const auto tex = [&](const eTileSize s, int tx = 11, int ty = 12) { return h.getTextureSpace(tx, ty, s).fTex; };
    h.setFrameShift(0);
    eGameTextures::loadEliteHouse();                    // estates load lazily
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        int missing = 0;
        h.setPeople(1);
        for(int level = 0; level < 5; ++level) {
            h.setLevel(level);
            for(int v = 0; v < 2; ++v) {
                h.setSeed(v);
                const auto& hd = textures[1].fEliteHouseHD[level*2 + v];
                const auto t = tex(eTileSize::s30, 10, 10);
                if(!hd[0][0]) {
                    ++missing;
                    assert(t != hd[0][0] && t);                       // original quarter sprite
                } else {
                    assert(t == hd[0][0]);
                }
            }
        }
        assert(missing == 1);
        std::cout << "PASS: elite house legacy fallback\n";
        return 0;
    }

    int cells = 0;
    for(int zoom = 0; zoom < 4; ++zoom) {
        const auto size = static_cast<eTileSize>(zoom);
        for(int direction = 0; direction < 4; ++direction) {
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            for(int level = 0; level < 5; ++level) {
                h.setLevel(level);
                for(int v = 0; v < 2; ++v) {
                    h.setSeed(v);
                    const auto& frames = textures[zoom].fEliteHouseHD[level*2 + v][direction];
                    for(int frame = 0; frame < 9; ++frame) {
                        const auto texture = frames[frame];
                        assert(texture);
                        assert(texture->width() == 160*(zoom + 1));
                        assert(texture->x() == frame*160*(zoom + 1));
                        assert(texture->y() == direction*160*(zoom + 1));
                        ++cells;
                    }
                    h.setPeople(0);
                    assert(tex(size) != frames[0]);
                    h.setPeople(1);
                    for(int frame = 0; frame < 8; ++frame) {
                        h.setFrameShift(4*frame);
                        for(int tx = 10; tx < 14; ++tx) {
                            for(int ty = 10; ty < 14; ++ty) {
                                const auto ts = h.getTextureSpace(tx, ty, size);
                                assert(ts.fTex == frames[frame] && ts.fRect.w == 4 && ts.fRect.h == 4);
                            }
                        }
                    }
                    assert(!h.getTextureSpace(20, 20, size).fTex);
                    h.setFrameShift(0);
                }
            }
        }
    }
    std::cout << "PASS: elite houses " << cells << " cells, 5 levels x 2 variants, 16 tiles each, rotations, resident loop, vacant plot\n";
}
