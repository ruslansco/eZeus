#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/emonument.h"
#include "buildings/sanctuaries/etemplestatuebuilding.h"
#include "buildings/sanctuaries/etemplebuilding.h"
#include "buildings/sanctuaries/etempletilebuilding.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

int main(int argc,char** argv) {
    const std::string mode=argc>1?argv[1]:"full";
    SDL_setenv("SDL_VIDEODRIVER","dummy",1);
    assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
    auto surface=SDL_CreateRGBSurfaceWithFormat(0,1200,700,32,SDL_PIXELFORMAT_RGBA32);
    auto renderer=SDL_CreateSoftwareRenderer(surface);assert(renderer);
    eGameDir::initialize();assert(eGameTextures::initialize(renderer));
    eSettings settings;eGameTextures::setSettings(settings);eGameTextures::loadSanctuary();
    eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);
    eMonument monument(board,eBuildingType::temple,4,8,0,eCityId::neutralFriendly);
    
    auto temple=e::make_shared<eTempleBuilding>(0,board,eCityId::neutralFriendly);
    temple->setMonument(&monument);monument.registerElement(temple);
    auto statue=e::make_shared<eTempleStatueBuilding>(eGodType::zeus,0,board,eCityId::neutralFriendly);
    statue->setMonument(&monument);monument.registerElement(statue);statue->setFrameShift(0);
    assert(!statue->getTexture(eTileSize::s30));assert(!temple->getTexture(eTileSize::s30));
    statue->incProgress();
    const auto& b=eGameTextures::buildings();
    if(mode=="fallback" || mode=="legacy") {
        auto t=statue->getTexture(eTileSize::s30);assert(t);
        assert(!b[1].fGodStatuesAnimated[0][0][0]);
        if(mode=="fallback") assert(t==b[1].fGodStatuesHD[0][0]);
        else assert(t==b[1].fZeusStatues.getTexture(0));
        temple->incProgress();auto tt=temple->getTexture(eTileSize::s30);assert(tt);
        if(mode=="legacy") assert(tt==b[1].fSanctuary[0].getTexture(0));
        std::cout<<"PASS: sanctuary "<<mode<<" textures and construction remain available\n";return 0;
    }
    
    for(int z=0;z<4;++z) {
        const auto size=static_cast<eTileSize>(z);
        assert(statue->getTexture(size)==b[z].fGodStatuesAnimated[0][0][16]);
    }
    // Construction stages and their exact offsets; full monument must be built to awaken.
    
    for(int stage=0;stage<3;++stage) {
        temple->incProgress();
        for(int z=0;z<4;++z) assert(temple->getTexture(static_cast<eTileSize>(z))==b[z].fSanctuaryHD[0][stage]);
    }
    assert(monument.finished());assert(temple->getOverlays(eTileSize::s30).empty());
    
    const eGodType gods[14]={eGodType::zeus,eGodType::poseidon,eGodType::hades,eGodType::demeter,
        eGodType::athena,eGodType::artemis,eGodType::apollo,eGodType::ares,eGodType::hephaestus,
        eGodType::aphrodite,eGodType::hermes,eGodType::dionysus,eGodType::hera,eGodType::atlas};
    const int count=mode=="zeus"?1:14;
    for(int g=0;g<count;++g) for(int id=0;id<4;++id) {
        eTempleStatueBuilding s(gods[g],id,board,eCityId::neutralFriendly);
        s.setMonument(&monument);s.incProgress();
        assert(s.spanW()==1&&s.spanH()==1&&s.cost().fSculpture==1);
        for(int z=0;z<4;++z) for(int d=0;d<4;++d) {
            board.setWorldDirection(static_cast<eWorldDirection>(d));
            for(int f=0;f<16;++f) {
                s.setFrameShift(f*4);auto t=s.getTexture(static_cast<eTileSize>(z));assert(t);
                assert(t==b[z].fGodStatuesAnimated[g][(id+d)%4][f]);
                assert(t->width()==60*(z+1)&&t->height()==120*(z+1));
                assert(t->offsetX()==30 && t->offsetY()==-5);
            }
        }
    }
    
    board.setWorldDirection(eWorldDirection::N);statue->setFrameShift(0);
    auto first=statue->getTexture(eTileSize::s30);
    board.advanceAnimTime(125);assert(statue->getTexture(eTileSize::s30)==b[1].fGodStatuesAnimated[0][0][1]);
    board.incFrame();assert(statue->getTexture(eTileSize::s30)==b[1].fGodStatuesAnimated[0][0][1]);
    board.advanceAnimTime(1875);assert(statue->getTexture(eTileSize::s30)==first);
    temple->destroy();assert(statue->getTexture(eTileSize::s30)==b[1].fGodStatuesAnimated[0][0][16]);
    
    for(int id=0;id<6;++id) {
        eTempleTileBuilding floor(id,board,eCityId::neutralFriendly);floor.setMonument(&monument);
        assert(!floor.getTileTexture(eTileSize::s30));floor.incProgress();
        for(int z=0;z<4;++z) {
            auto t=floor.getTileTexture(static_cast<eTileSize>(z));assert(t);
            if(mode!="zeus") assert(t==b[z].fSanctuaryPavingHD[id]);
        }
    }
    std::cout<<"PASS: sanctuary "<<count<<" gods, 4 scales, all statue orientations, 16-pose loop, display clock, idle construction, footprints and costs\n";
}
