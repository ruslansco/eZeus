#include "egamedir.h"
#include "textures/egametextures.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include "engine/eworldcity.h"

#include "buildings/earmory.h"
#include "buildings/eblackmarbleworkshop.h"
#include "buildings/ecardingshed.h"
#include "buildings/echariotfactory.h"
#include "buildings/edairy.h"
#include "buildings/efishery.h"
#include "buildings/efoundry.h"
#include "buildings/efountain.h"
#include "buildings/egranary.h"
#include "buildings/egrowerslodge.h"
#include "buildings/ehorseranch.h"
#include "buildings/ehospital.h"
#include "buildings/ehuntinglodge.h"
#include "buildings/emaintenanceoffice.h"
#include "buildings/emasonryshop.h"
#include "buildings/emint.h"
#include "buildings/eolivepress.h"
#include "buildings/erefinery.h"
#include "buildings/esculpturestudio.h"
#include "buildings/etaxoffice.h"
#include "buildings/etimbermill.h"
#include "buildings/etower.h"
#include "buildings/ewheatfarm.h"
#include "buildings/ecorral.h"
#include "buildings/etradepost.h"
#include "buildings/eurchinquay.h"
#include "buildings/ewarehouse.h"
#include "buildings/ewatchpost.h"
#include "buildings/ewinery.h"

#include <cassert>
#include <functional>
#include <iostream>
#include <map>
#include <memory>

// Readability lineups (art/_kit/lineup.py): draws every remastered building exactly as the
// game does at zoom 30 (100%) - sprite plus overlays - on a transparent surface and saves
// <out>/<id>.png. Run once with Textures/Remastered present (HD) and once without (original art).
int main(int argc, char** argv) {
    assert(argc > 1);
    const std::string out = argv[1];
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 480, 480, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    assert(renderer);
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    eGameDir::initialize();
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    eGameTextures::setSettings(settings);
    eWorldBoard world;
    eGameBoard board(world);
    board.setRegisterBuildingsEnabled(false);
    board.addCityToBoard(eCityId::neutralFriendly);
    const auto city = std::make_shared<eWorldCity>();
    const auto c = eCityId::neutralFriendly;
    using F = std::function<std::shared_ptr<eBuilding>()>;
    const std::vector<std::pair<std::string, F>> all = {
        {"armory", [&] { return std::make_shared<eArmory>(board, c); }},
        {"black_marble_workshop", [&] { return std::make_shared<eBlackMarbleWorkshop>(board, c); }},
        {"carding_shed", [&] { return std::make_shared<eCardingShed>(board, c); }},
        {"chariot_factory", [&] { return std::make_shared<eChariotFactory>(board, c); }},
        {"dairy", [&] { return std::make_shared<eDairy>(board, c); }},
        {"fishery", [&] { return std::make_shared<eFishery>(board, eDiagonalOrientation::topRight, c); }},
        {"foundry", [&] { return std::make_shared<eFoundry>(board, c); }},
        {"fountain", [&] { return std::make_shared<eFountain>(board, c); }},
        {"granary", [&] { return std::make_shared<eGranary>(board, c); }},
        {"growers_lodge", [&] { return std::make_shared<eGrowersLodge>(board, eGrowerType::grapesAndOlives, c); }},
        {"horse_ranch", [&] { return std::make_shared<eHorseRanch>(board, c); }},
        {"hospital", [&] { return std::make_shared<eHospital>(board, c); }},
        {"hunting_lodge", [&] { return std::make_shared<eHuntingLodge>(board, c); }},
        {"maintenance_office", [&] { return std::make_shared<eMaintenanceOffice>(board, c); }},
        {"masonry_shop", [&] { return std::make_shared<eMasonryShop>(board, c); }},
        {"mint", [&] { return std::make_shared<eMint>(board, c); }},
        {"olive_press", [&] { return std::make_shared<eOlivePress>(board, c); }},
        {"orange_tenders_lodge", [&] { return std::make_shared<eGrowersLodge>(board, eGrowerType::oranges, c); }},
        {"refinery", [&] { return std::make_shared<eRefinery>(board, c); }},
        {"sculpture_studio", [&] { return std::make_shared<eSculptureStudio>(board, c); }},
        {"tax_office", [&] { return std::make_shared<eTaxOffice>(board, c); }},
        {"timber_mill", [&] { return std::make_shared<eTimberMill>(board, c); }},
        {"trade_post", [&] { return std::make_shared<eTradePost>(board, *city, c, eTradePostType::post); }},
        {"urchin_quay", [&] { return std::make_shared<eUrchinQuay>(board, eDiagonalOrientation::topRight, c); }},
        {"warehouse", [&] { return std::make_shared<eWarehouse>(board, c); }},
        {"watch_post", [&] { return std::make_shared<eWatchpost>(board, c); }},
        {"winery", [&] { return std::make_shared<eWinery>(board, c); }},
        {"tower", [&] { return std::make_shared<eTower>(board, c); }},
        {"wheat_farm", [&] { return std::make_shared<eWheatFarm>(board, c); }},
        {"corral", [&] { return std::make_shared<eCorral>(board, c); }},
    };
    const double W = 58, H = 30;
    const double ax = 240 - 2*W, ay = 400;       // footprint bounding-box bottom-left anchor
    for(const auto& [id, make] : all) {
        const auto b = make();
        b->setFrameShift(0);
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        const auto draw = [&](const std::shared_ptr<eTexture>& tex, double x, double y, bool top) {
            if(!tex) return;
            const int px = std::round(x - H*tex->offsetX()/30.);
            int py = std::round(y - H*tex->offsetY()/30.);
            if(top) py -= tex->height();
            tex->render(renderer, px, py);
        };
        draw(b->getTexture(eTileSize::s30), ax, ay, true);
        if(b->overlayEnabled() || id == "tower") {
            for(const auto& o : b->getOverlays(eTileSize::s30)) {
                draw(o.fTex, ax + .5*(o.fX - o.fY)*W, ay + .5*(o.fX + o.fY)*H, o.fAlignTop);
            }
        }
        IMG_SavePNG(surface, (out + "/" + id + ".png").c_str());
        std::cout << "dumped " << id << "\n";
    }
}
