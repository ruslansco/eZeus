#include "egamedir.h"
#include "textures/egametextures.h"
#include "characters/etradeboat.h"
#include "characters/etrireme.h"
#include "characters/actions/ewaitaction.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>
#include <cmath>
class SailStep : public eWaitAction {
public: using eWaitAction::eWaitAction;
 void increment(int by) override {
   character()->setX(character()->x()+.02);
   eWaitAction::increment(by);
 }
};
int main(int argc,char**argv) {
 SDL_setenv("SDL_VIDEODRIVER","dummy",1);
 assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
 auto surf=SDL_CreateRGBSurfaceWithFormat(0,1200,560,32,SDL_PIXELFORMAT_RGBA32);
 auto renderer=SDL_CreateSoftwareRenderer(surf);assert(renderer);
 eGameDir::initialize();assert(eGameTextures::initialize(renderer));
 eSettings settings;settings.fMediumTextures=settings.fLargeTextures=false;
 eGameTextures::setSettings(settings);
 const bool legacy=argc>1 && std::string(argv[1])=="legacy";
 eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);
 auto merchant=e::make_shared<eTradeBoat>(board);
 auto galley=e::make_shared<eTrireme>(board);
 const auto& all=eGameTextures::characters();
 for(int k=0;k<2;++k) {
  eBoatBase* boat=k?static_cast<eBoatBase*>(galley.get()):merchant.get();
  boat->setAction(e::make_shared<SailStep>(boat));
  for(int s=0;s<2;++s) {
   const auto& t=k?all[s].fTrireme:all[s].fTradeBoat;
   assert(t.fRemastered!=legacy);assert(t.fStand.size()==8);
   assert(t.fSwim.size()==8 && t.fDie.size()==8);
   if(legacy) {assert(t.fSwim[0].size()==8);continue;}
   const auto size=static_cast<eTileSize>(s);const int cell=112*(s+1);
   for(int map=0;map<4;++map) for(int d=0;d<8;++d) {
    board.setWorldDirection(static_cast<eWorldDirection>(map));boat->setOrientation(static_cast<eOrientation>(d));
    const int row=static_cast<int>(boat->rotatedOrientation());
    assert(t.fSwim[row].size()==16 && t.fDie[row].size()==12);
    auto tex=t.fSwim[row].getTexture(0);
    assert(tex->width()==cell && tex->height()==cell);
    assert(tex->offsetX()==-72 && tex->offsetY()==-96);
    boat->setActionType(eCharacterActionType::stand);assert(boat->getTexture(size)==t.fStand.getTexture(row));
    boat->setActionType(eCharacterActionType::walk);assert(boat->getTexture(size));
    boat->setActionType(eCharacterActionType::fight);assert(boat->getTexture(size));
    boat->setActionType(eCharacterActionType::fight2);assert(boat->getTexture(size));
    boat->setActionType(eCharacterActionType::die);
    assert(boat->getTexture(size)==t.fDie[row].getTexture(0));
    boat->incTime(220);assert(boat->getTexture(size)==t.fDie[row].getTexture(11));
    boat->incTime(40);assert(boat->getTexture(size)==t.fDie[row].getTexture(11));
   }
  }
  if(!legacy) {
   boat->setActionType(eCharacterActionType::walk);
   const double x0=boat->absX();
   boat->beginVisualTick();boat->incTime(50);boat->endVisualTick();boat->sampleVisual(.5);
   assert(std::abs(boat->visualX()-(x0+.01))<1e-9);
   const auto tex=boat->getTexture(eTileSize::s30);
   boat->sampleVisual(.5);assert(boat->getTexture(eTileSize::s30)==tex);
   boat->sampleVisual(1);assert(std::abs(boat->visualX()-boat->x())<1e-9);
  }
 }
 if(!legacy) {
  assert(!galley->getSecondaryTexture(eTileSize::s30).fTex);
  SDL_SetRenderDrawColor(renderer,52,121,133,255);SDL_RenderClear(renderer);
  for(int k=0;k<2;++k) for(int d=0;d<8;++d) {
   const auto& t=k?all[1].fTrireme:all[1].fTradeBoat;
   auto tex=t.fSwim[d].getTexture(0);
   // Draw the exact atlas source on water for alpha/fringe inspection.
   tex->render(renderer,(d%4)*300+35,(d/4)*130+k*280-24);
  }
  SDL_RenderPresent(renderer);assert(IMG_SavePNG(surf,eGameDir::path("ships_alignment.png").c_str())==0);
 }
 std::cout << "PASS: " << (legacy?"legacy boat fallback":"ships: anchors, eight headings, four map rotations, combat, sinking, interpolation and overlay suppression") << "\n";
}
