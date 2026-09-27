// Run through art/characters/physician/validate_runtime.py after building/signing.
#include "egamedir.h"
#include "textures/egametextures.h"
#include "characters/ehealer.h"
#include "characters/actions/ewaitaction.h"
#include "characters/actions/emoveaction.h"
#include "characters/actions/walkable/ewalkableobject.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <algorithm>
#include <iostream>

// Controlled movement isolates presentation from path planning and random patrols.
class StepAction : public eWaitAction {
public:
    using eWaitAction::eWaitAction;
    void increment(int by) override {
        if(character()->actionType()==eCharacterActionType::walk)
            character()->setX(character()->x()+.64/24);
        eWaitAction::increment(by);
    }
};

class StraightPatrol : public eMoveAction {
public:
    StraightPatrol(eCharacter* c,eOrientation direction) :
        eMoveAction(c,eWalkableObject::sCreateAll(),eCharActionType::patrolMoveAction),mDirection(direction) {}
private:
    eCharacterActionState nextTurn(eOrientation& turn) override {
        turn=mDirection;return eCharacterActionState::running;
    }
    eOrientation mDirection;
};

int main(int argc,char** argv) {
    SDL_setenv("SDL_VIDEODRIVER","dummy",1);
    assert(SDL_Init(SDL_INIT_VIDEO)==0);
    assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
    auto surface=SDL_CreateRGBSurfaceWithFormat(0,1280,440,32,SDL_PIXELFORMAT_RGBA32);
    auto renderer=SDL_CreateSoftwareRenderer(surface);assert(renderer);
    eGameDir::initialize();assert(eGameTextures::initialize(renderer));
    eSettings settings;eGameTextures::setSettings(settings);
    const std::string mode=argc>1?argv[1]:"hd";
    eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);
    auto ownedHealer=e::make_shared<eHealer>(board);
    auto& healer=*ownedHealer;
    // Keep the isolated character alive while exercising its animation clock.
    healer.setAction(e::make_shared<StepAction>(&healer));
    const auto& all=eGameTextures::characters();
    assert(healer.type()==eCharacterType::healer && healer.provideCount()==100000 && healer.speed()==1);
    if(mode=="legacy" || mode=="v1") {
        const auto& t=all[1].fHealer;
        assert(t.fWalk.size()==8 && t.fWalk[0].size()==12 && t.fDie.size()==8);
        assert(t.fIdle.empty());
        assert((t.fWalk[0].getTexture(0)->width()==80)==(mode=="v1"));
        healer.setActionType(eCharacterActionType::walk);
        const auto row=static_cast<int>(healer.rotatedOrientation());
        for(int f=0;f<24;++f) {
            assert(healer.getTexture(eTileSize::s30)==t.fWalk[row].getTexture(f%12));
            healer.incTime(20);
        }
        SDL_SetRenderDrawColor(renderer,94,111,93,255);SDL_RenderClear(renderer);
        for(int d=0;d<8;++d) {
            auto tex=t.fWalk[d].getTexture(0);
            tex->render(renderer,80+160*d-tex->offsetX(),135-tex->offsetY());
        }
        SDL_RenderPresent(renderer);assert(IMG_SavePNG(surface,eGameDir::path("legacy.png").c_str())==0);
        std::cout<<"PASS: intact "<<mode<<" walk/death fallback\n";return 0;
    }
    const int expectedDensity=mode=="standard"?1:2;
    for(int z=0;z<4;++z) {
        const auto size=static_cast<eTileSize>(z);const auto& t=all[z].fHealer;
        const int cell=40*(z+1);assert(t.fWalk.size()==8 && t.fDie.size()==8 && t.fIdle.size()==8);
        for(int d=0;d<8;++d) {
            assert(t.fWalk[d].size()==24 && t.fIdle[d].size()==12);
            for(int f=0;f<24;++f) {
                const auto tex=t.fWalk[d].getTexture(f);
                assert(tex && tex->width()==cell && tex->height()==cell);
                assert(tex->x()==f*cell && tex->y()==d*cell);
                assert(tex->offsetX()==40 && tex->offsetY()==60 && tex->density()==expectedDensity);
            }
            for(int f=0;f<12;++f) {
                const auto tex=t.fIdle[d].getTexture(f);
                assert(tex->x()==(12*(d%2)+f)*cell && tex->y()==(8+d/2)*cell);
                assert(tex->width()==cell && tex->height()==cell && tex->offsetX()==40 && tex->offsetY()==60);
            }
            for(int w=0;w<4;++w) {
                board.setWorldDirection(static_cast<eWorldDirection>(w));
                healer.setOrientation(static_cast<eOrientation>(d));
                const int row=(d+2*w)%8; // N,W,S,E native rotation order
                healer.setActionType(eCharacterActionType::stand);
                for(int f=0;f<12;++f) {
                    healer.beginVisualTick();healer.incTime(50);healer.endVisualTick();healer.sampleVisual(1);
                    assert(healer.getTexture(size)==t.fIdle[row].getTexture((healer.time()/50)%12));
                }
                healer.setActionType(eCharacterActionType::walk);
                for(int f=0;f<48;++f) {
                    assert(healer.getTexture(size)==t.fWalk[row].getTexture(f%24));
                    const double start=healer.x();
                    healer.beginVisualTick();healer.incTime(6);healer.endVisualTick();
                    healer.sampleVisual(.5);assert(std::abs(healer.visualX()-start-.64/48)<1e-8);
                    healer.sampleVisual(1);assert(std::abs(healer.visualX()-healer.x())<1e-8);
                }
            }
        }
        healer.setActionType(eCharacterActionType::die);
        for(int f=0;f<12;++f) {
            auto tex=healer.getTexture(size);assert(tex==t.fDie.getTexture(std::min(f,7)));
            assert(tex->y()==12*cell && tex->offsetY()==60);
            healer.incTime(eCharacter::sTextureTimeDivisor);
        }
    }
    SDL_SetRenderDrawColor(renderer,94,111,93,255);SDL_RenderClear(renderer);
    for(int d=0;d<8;++d) {
        auto tex=all[3].fHealer.fWalk[d].getTexture(0);
        tex->render(renderer,80+160*d-80,170-120);
        SDL_SetRenderDrawColor(renderer,239,215,146,255);
        SDL_RenderDrawLine(renderer,76+160*d,170,84+160*d,170);
        SDL_RenderDrawLine(renderer,80+160*d,166,80+160*d,174);
        auto fallen=all[3].fHealer.fDie.getTexture(d);
        fallen->render(renderer,160*d,280);
    }
    SDL_RenderPresent(renderer);assert(IMG_SavePNG(surface,eGameDir::path("runtime_alignment.png").c_str())==0);
    {
        eGameBoard pathBoard(world);pathBoard.initialize(48,48);
        for(int direction=0;direction<8;++direction) {
            auto walker=e::make_shared<eHealer>(pathBoard);
            auto control=e::make_shared<eBasicPatroler>(pathBoard,&eCharacterTextures::fHealer,eCharacterType::waterDistributor);
            walker->changeTile(pathBoard.dtile(24,24));
            control->changeTile(pathBoard.dtile(24,24));
            walker->setActionType(eCharacterActionType::walk);
            control->setActionType(eCharacterActionType::walk);
            walker->setAction(e::make_shared<StraightPatrol>(walker.get(),static_cast<eOrientation>(direction)));
            control->setAction(e::make_shared<StraightPatrol>(control.get(),static_cast<eOrientation>(direction)));
            double traveled=0;
            for(int tick=0;tick<24;++tick) {
                const double x0=walker->absX(),y0=walker->absY();
                walker->beginVisualTick();
                const int substeps=tick==23?5:1,by=tick==23?100:10;
                for(int sub=0;sub<substeps;++sub) {
                    walker->incTime(by);control->incTime(by);
                    assert(std::abs(walker->absX()-control->absX())<1e-8);
                    assert(std::abs(walker->absY()-control->absY())<1e-8);
                }
                walker->endVisualTick();walker->sampleVisual(.5);
                const double moved=std::hypot(walker->absX()-x0,walker->absY()-y0);
                // Legacy movement may consume a tick at an exact tile boundary.
                // Compare with an unmodified patroler, not an idealized velocity.
                assert(moved<=.005*by*substeps+1e-8);
                assert(std::abs(walker->tile()->x()+walker->visualX()-(x0+walker->absX())*.5)<1e-8);
                assert(std::abs(walker->tile()->y()+walker->visualY()-(y0+walker->absY())*.5)<1e-8);
                const auto row=static_cast<int>(walker->rotatedOrientation());
                const int frame=int(std::floor((traveled+moved*.5)/.64*24+1e-8))%24;
                assert(walker->getTexture(eTileSize::s30)==all[1].fHealer.fWalk[row].getTexture(frame));
                traveled+=moved;
            }
            walker->kill();control->kill();pathBoard.emptyRubbish();
        }
    }
    std::cout<<"PASS: native eMoveAction in all 8 directions, tile crossings, unchanged speed and 5-substep fast-forward\n";
    std::cout<<"PASS: 1184 pose cells, 8 headings, 4 map rotations, 4 scales, distance-driven walk, breathing, sub-tick movement, death clamp, ground anchor, density "<<expectedDensity<<"\n";
}
