#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/ewarehouse.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <algorithm>
#include <cassert>
#include <iostream>

// Remastered warehouse (N row for every direction): 4x9 atlas at every zoom, rotation rows, working loop only
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
    eWarehouse b(board, eCityId::neutralFriendly);
    b.setFrameShift(0);
    const auto& textures = eGameTextures::buildings();

    if(argc > 1) {
        assert(!textures[1].fWarehouseHD[0][0]);
        assert(b.getTexture(eTileSize::s30) == textures[1].fWarehouse);
        (void)b.getOverlays(eTileSize::s30);
        std::cout << "PASS: warehouse legacy fallback\n";
        return 0;
    }

    bool first = true;
    for(int zoom = 0; zoom < 4; ++zoom) {
        for(int direction = 0; direction < 4; ++direction) {
            const auto size = static_cast<eTileSize>(zoom);
            board.setWorldDirection(static_cast<eWorldDirection>(direction));
            b.setEnabled(false);
            assert(b.getTexture(size) == textures[zoom].fWarehouseHD[0][8]);
            // goods bays stay as overlays; the legacy worker overlay is dropped
            assert(b.getOverlays(size).empty());          // empty HD yard: bays are part of the paving
            for(int frame = 0; frame < 9; ++frame) {
                const auto texture = textures[zoom].fWarehouseHD[direction][frame];
                assert(texture);
                assert(texture->width() == 120*(zoom + 1));
                assert(texture->x() == frame*120*(zoom + 1));
                assert(texture->y() == direction*120*(zoom + 1));
            }
            b.setEnabled(true);
            (void)first;
            
            for(int frame = 0; frame < 8; ++frame) {
                b.setFrameShift(4*frame);
                assert(b.getTexture(size) == textures[zoom].fWarehouseHD[0][frame]);
            }
            b.setEmployed(0);
            assert(b.getTexture(size) == textures[zoom].fWarehouseHD[0][8]);
            b.setEmployed(12);
        }
    }
    std::cout << "PASS: warehouse 144 cells, rotations, working loop and idle states\n";
    // Stocked yard: one HD pile per filled bay, level = units, from the shared goods library.
    b.setMaxCount({{eResourceType::wheat, 16}, {eResourceType::wood, 16}, {eResourceType::wine, 16}});
    assert(b.addNotAccept(eResourceType::wheat, 3) == 3 && b.addNotAccept(eResourceType::wood, 4) == 4 &&
           b.addNotAccept(eResourceType::wine, 2) == 2);
    for(int zoom = 0; zoom < 4; ++zoom) for(int direction = 0; direction < 4; ++direction) {
        board.setWorldDirection(static_cast<eWorldDirection>(direction));
        const auto os = b.getOverlays(static_cast<eTileSize>(zoom));
        const auto& lib = textures[zoom].hdOverlays("storage_goods");
        assert(os.size() == 3);
        for(const char* key : {"wheat3", "wood4", "wine2"}) {
            const auto& tex = lib.at(key)[0].fTex;
            assert(tex && std::count_if(os.begin(), os.end(), [&](const eOverlay& o) { return o.fTex == tex; }) == 1);
            // zoomed-in views (15/30 px sets drawn scaled up) swap in the twice-as-dense sprite
            if(zoom <= 1) assert(tex->hiRes() && tex->hiRes()->width() == tex->width() && tex->hiRes()->height() == tex->height());
        }
        for(size_t i = 1; i < os.size(); ++i) assert(os[i - 1].fX + os[i - 1].fY <= os[i].fX + os[i].fY);   // back to front
        for(const auto& o : os) assert(!o.fAlignTop);
    }
    std::cout << "PASS: warehouse HD goods piles for every filled bay, zoom and direction\n";
}
