// Run through art/olive_press/validate_runtime.py after building the game.
#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/eolivepress.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include "widgets/etilepainter.h"
#include <cassert>
#include <iostream>

int main(int argc, char** argv) {
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 1360, 370, 32, SDL_PIXELFORMAT_RGBA32);
    assert(surface);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    assert(renderer);
    eGameDir::initialize();
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    const bool fallback = argc > 1 && std::string(argv[1]) == "fallback";
    if(fallback) settings.fMediumTextures = settings.fLargeTextures = false;
    eGameTextures::setSettings(settings);

    {
        eWorldBoard world;
        eGameBoard board(world);
        board.setRegisterBuildingsEnabled(false);
        eOlivePress press(board, eCityId::neutralFriendly);
        press.setFrameShift(0);
        const auto& collections = eGameTextures::buildings();
        assert(press.spanW() == 2 && press.spanH() == 2);
        if(fallback) {
            const auto tex = press.getTexture(eTileSize::s30);
            assert(tex && tex == collections[1].fOlivePress);
            assert(!collections[1].fOlivePressHD[0][0]);
            assert(press.getOverlays(eTileSize::s30).size() == 1);
            assert(collections[1].fOlivePressOverlay.size() == 12);
            std::cout << "PASS: legacy artwork and animation fallback\n";
        } else {
            for(int s = 0; s < 4; ++s) {
                const auto size = static_cast<eTileSize>(s);
                const int cell = 80*(s+1);
                for(int d = 0; d < 4; ++d) {
                    board.setWorldDirection(static_cast<eWorldDirection>(d));
                    press.setEnabled(false);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][8]);
                    assert(press.getOverlays(size).empty());
                    for(int f = 0; f < 9; ++f) {
                        auto tex = collections[s].fOlivePressHD[d][f];
                        assert(tex && tex->width() == cell && tex->height() == cell);
                        assert(tex->x() == f*cell && tex->y() == d*cell);
                        assert(tex->offsetX() == 20 && tex->offsetY() == -11);
                    }
                    press.setEnabled(true);
                    press.add(eResourceType::olives, -4);
                    press.setFrameShift(12);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][8]);
                    press.add(eResourceType::olives, 4);
                    for(int f = 0; f < 8; ++f) {
                        press.setFrameShift(4*f);
                        assert(press.getTexture(size) == collections[s].fOlivePressHD[d][f]);
                        press.setFrameShift(4*f+3);
                        assert(press.getTexture(size) == collections[s].fOlivePressHD[d][f]);
                    }
                    press.setFrameShift(32);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][0]);
                    press.setFrameShift(64);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][0]);
                    press.setShutDown(true);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][8]);
                    press.setShutDown(false);
                    // No employees, even with olives on hand: do not show workers.
                    press.setEmployed(0);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][8]);
                    press.setEmployed(12);
                    assert(press.getTexture(size) == collections[s].fOlivePressHD[d][0]);
                }
            }
            SDL_SetRenderDrawColor(renderer, 45, 62, 55, 255);
            SDL_RenderClear(renderer);
            for(int d = 0; d < 4; ++d) {
                board.setWorldDirection(static_cast<eWorldDirection>(d));
                press.setEmployed(12);
                press.setFrameShift(8); // Down-stroke, two workers, oil flowing.
                ePainter painter(renderer);
                const int x = d*340 + 30;
                painter.translate(x, 335);
                eTilePainter tp(painter, eTileSize::s60, 120, 60);
                tp.drawTexture(0, 0, press.getTexture(eTileSize::s60), eAlignment::top);
                // The grid outline should hug the foundation in every direction.
                SDL_SetRenderDrawColor(renderer, 210, 197, 107, 255);
                SDL_Point diamond[] = {{x,275},{x+120,215},{x+240,275},{x+120,335},{x,275}};
                SDL_RenderDrawLines(renderer, diamond, 5);
            }
            SDL_RenderPresent(renderer);
            assert(IMG_SavePNG(surface, (eGameDir::path("runtime_alignment.png")).c_str()) == 0);
            std::cout << "PASS: 144 sprite cells, four zoom sizes, four directions, eight-frame working loop, four-tick cadence, separate worker-free idle/starved/closed/unstaffed states, alignment render\n";
        }
    }
    // Static texture collections own the renderer's textures until process exit.
    return 0;
}
