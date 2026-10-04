// Regression for legacy 2x2 half-cliff ownership swallowing per-tile ramps.
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include "engine/etile.h"
#include "buildings/eroad.h"
#include "textures/etiletotexture.h"
#include "textures/eterraintextures.h"
#include "textures/ebuildingtextures.h"
#include <cassert>
#include <iostream>

int main() {
    eWorldBoard world;
    eGameBoard board(world);
    board.initialize(8, 8);
    board.setRegisterBuildingsEnabled(false);
    const auto road=eRoad::make_shared<eRoad>(board,eCityId::neutralFriendly);
    eTerrainTextures terrain(60, 30, nullptr);
    eBuildingTextures buildings(60, 30, nullptr);
    for(int i = 0; i < 56; ++i) terrain.fHalfElevation.addTexture();
    for(int i = 0; i < 24; ++i) terrain.fElevation.addTexture();
    for(int i = 0; i < 12; ++i) terrain.fHalfElevation2.addTexture();
    std::vector<std::unique_ptr<eTile>> tiles;
    for(int y=0; y<5; ++y) for(int x=0; x<5; ++x)
        tiles.emplace_back(new eTile(x-4, y-3, x, y, board));
    const auto at = [&](int x, int y)->eTile* {
        return x<0 || y<0 || x>=5 || y>=5 ? nullptr : tiles[y*5+x].get();
    };
    for(int y=0; y<5; ++y) for(int x=0; x<5; ++x) {
        auto t=at(x,y);
        t->setTopLeft(at(x-1,y)); t->setBottomRight(at(x+1,y));
        t->setTopRight(at(x,y-1)); t->setBottomLeft(at(x,y+1));
    }
    auto center=at(2,2);
    for(int d=0; d<4; ++d) for(int parity=0; parity<2; ++parity) {
        const auto dir=static_cast<eWorldDirection>(d);
        for(auto& t:tiles) {
            t->setDoubleAltitude(parity, false);
            t->setDrawDim(1); t->setUnderTile(nullptr);
            t->setWalkableElev(false);
        }
        // Both parity variants previously selected an aggregate cliff even
        // when its owner was a walkable ramp; negative map IDs are intentional.
        center->bottomLeftRotated<eTile>(dir)->setDoubleAltitude(parity+1,false);
        center->bottomRotated<eTile>(dir)->setDoubleAltitude(parity+1,false);
        center->setDoubleAltitude(parity);
        assert(center->isHalfSlope());
        for(int state=0; state<3; ++state) {
            center->setWalkableElev(state!=0);
            center->setUnderBuilding(state==2 ? road : nullptr);
            int dim=0;
            const eTextureCollection* collection=nullptr;
            const auto tex=eTileToTexture::get(center,terrain,buildings,
                eTileSize::s30,true,dim,&collection,dir);
            assert(tex && dim==1 && !center->underTile());
            const int index=(state*8)+(parity==0?1:0);
            assert(tex==terrain.fHalfElevation.getTexture(index));
        }
    }
    std::cout << "PASS: half cliffs, walking ramps and road ramps retain independent tiles in all four views\n";
}
