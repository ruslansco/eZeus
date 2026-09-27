#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/emuseum.h"
#include "buildings/eobservatory.h"
#include "buildings/elaboratory.h"
#include "buildings/estadium.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>

template<class T,class Frames> void check(T& b, eGameBoard& board, Frames member,int n,int staff,bool fallback){
 const auto& textures=eGameTextures::buildings();
 assert(b.spanW()==n&&b.spanH()==n);
 if(fallback){assert(!(textures[1].*member)[0][0]);assert(b.getTexture(eTileSize::s30));return;}
 for(int z=0;z<4;++z)for(int d=0;d<4;++d){
  auto size=static_cast<eTileSize>(z);board.setWorldDirection(static_cast<eWorldDirection>(d));auto& a=textures[z].*member;
  b.setEmployed(staff);b.setEnabled(false);assert(b.getTexture(size)==a[d][8]);
  for(int f=0;f<9;++f){auto t=a[d][f];assert(t);assert(t->width()==n*40*(z+1));assert(t->offsetX()==10*n);assert(t->offsetY()==(n==6?-33:n==5?-27:-22));assert(t->x()==f*t->width());assert(t->y()==d*t->height());}
  b.setEnabled(true);for(int f=0;f<8;++f){b.setFrameShift(f*4);assert(b.getTexture(size)==a[d][f]);}
  b.setEmployed(0);assert(b.getTexture(size)==a[d][8]);assert(b.getOverlays(size).empty());
 }
}
int main(int argc,char**argv){
 SDL_setenv("SDL_VIDEODRIVER","dummy",1);assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
 auto surface=SDL_CreateRGBSurfaceWithFormat(0,64,64,32,SDL_PIXELFORMAT_RGBA32);auto renderer=SDL_CreateSoftwareRenderer(surface);assert(renderer);
 eGameDir::initialize();assert(eGameTextures::initialize(renderer));eSettings settings;eGameTextures::setSettings(settings);
 eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);const auto cid=eCityId::neutralFriendly;
 const std::string target=argc>1?argv[1]:"full";bool fallback=target!="full";
 if(!fallback||target=="museum"){eMuseum b(board,cid);check(b,board,&eBuildingTextures::fMuseumHD,6,50,fallback);}
 if(!fallback||target=="observatory"){eObservatory b(board,cid);check(b,board,&eBuildingTextures::fObservatoryHD,5,18,fallback);}
 if(!fallback||target=="laboratory"){eLaboratory b(board,cid);check(b,board,&eBuildingTextures::fLaboratoryHD,4,9,fallback);}
 if(!fallback||target=="stadium")for(bool rotated:{false,true}){
  eStadium b(board,rotated,cid);b.setTileRect({10,20,rotated?5:10,rotated?10:5});
  assert(b.spanW()==(rotated?5:10)&&b.spanH()==(rotated?10:5));
  if(fallback){assert(!eGameTextures::buildings()[1].fStadiumAHD[0][0]);assert(b.getTextureSpace(10,20,eTileSize::s30).fTex);continue;}
  for(int z=0;z<4;++z)for(int d=0;d<4;++d)for(bool active:{false,true}){
   board.setWorldDirection(static_cast<eWorldDirection>(d));b.setEmployed(45);b.setEnabled(active);
   for(int f=0;f<8;++f){b.setFrameShift(f*4);for(int half=0;half<2;++half){
    auto t=b.getTextureSpace(10+(rotated?0:half*5),20+(rotated?half*5:0),static_cast<eTileSize>(z));
    auto& a=half?eGameTextures::buildings()[z].fStadiumBHD:eGameTextures::buildings()[z].fStadiumAHD;
    assert(t.fTex&&t.fTex==a[(d+rotated)%4][active?f:8]);
    assert(t.fRect.w==5&&t.fRect.h==5);assert(t.fRect.x==10+(rotated?0:half*5));assert(t.fRect.y==20+(rotated?half*5:0));
   }}
  }
 }
 std::cout<<"PASS: Roman landmarks "<<target<<"; rotation, scales, staffing, loop and footprints\n";
}
