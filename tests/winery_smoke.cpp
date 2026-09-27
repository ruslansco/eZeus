#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/ewinery.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>
int main(int argc,char**argv){
 SDL_setenv("SDL_VIDEODRIVER","dummy",1);assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
 auto surf=SDL_CreateRGBSurfaceWithFormat(0,64,64,32,SDL_PIXELFORMAT_RGBA32);auto r=SDL_CreateSoftwareRenderer(surf);assert(r);eGameDir::initialize();assert(eGameTextures::initialize(r));eSettings settings;eGameTextures::setSettings(settings);
 eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);eWinery w(board,eCityId::neutralFriendly);w.setFrameShift(0);const auto& c=eGameTextures::buildings();
 bool fallback=argc>1;if(fallback){assert(w.getTexture(eTileSize::s30)==c[1].fWinery);assert(w.getOverlays(eTileSize::s30).size()==1);std::cout<<"PASS: winery legacy fallback\n";return 0;}
 for(int z=0;z<4;z++)for(int d=0;d<4;d++){auto size=static_cast<eTileSize>(z);board.setWorldDirection(static_cast<eWorldDirection>(d));w.setEnabled(false);assert(w.getTexture(size)==c[z].fWineryHD[d][8]);for(int f=0;f<9;f++){auto t=c[z].fWineryHD[d][f];assert(t&&t->width()==80*(z+1)&&t->x()==f*80*(z+1));}w.setEnabled(true);w.add(eResourceType::grapes,4);for(int f=0;f<8;f++){w.setFrameShift(4*f);assert(w.getTexture(size)==c[z].fWineryHD[d][f]);}w.setEmployed(0);assert(w.getTexture(size)==c[z].fWineryHD[d][8]);w.setEmployed(12);}
 std::cout<<"PASS: winery 144 cells, rotations, working loop and idle states\n";
}
