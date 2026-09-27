#include "egamedir.h"
#include "textures/egametextures.h"
#include "buildings/egranary.h"
#include "engine/egameboard.h"
#include "engine/eworldboard.h"
#include <cassert>
#include <iostream>
#include <map>
#include <string>
int main(int argc,char**){
 SDL_setenv("SDL_VIDEODRIVER","dummy",1);assert(SDL_Init(SDL_INIT_VIDEO)==0);assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);
 auto surface=SDL_CreateRGBSurfaceWithFormat(0,64,64,32,SDL_PIXELFORMAT_RGBA32);auto renderer=SDL_CreateSoftwareRenderer(surface);assert(renderer);eGameDir::initialize();assert(eGameTextures::initialize(renderer));eSettings settings;eGameTextures::setSettings(settings);
 eWorldBoard world;eGameBoard board(world);board.setRegisterBuildingsEnabled(false);eGranary granary(board,eCityId::neutralFriendly);granary.setFrameShift(0);const auto& textures=eGameTextures::buildings();
 if(argc>1){assert(granary.getTexture(eTileSize::s30)==textures[1].fGranary);(void)granary.getOverlays(eTileSize::s30);std::cout<<"PASS: granary legacy fallback\n";return 0;}
 for(int zoom=0;zoom<4;++zoom)for(int direction=0;direction<4;++direction){auto size=static_cast<eTileSize>(zoom);board.setWorldDirection(static_cast<eWorldDirection>(direction));granary.setEnabled(false);assert(granary.getTexture(size)==textures[zoom].fGranaryHD[direction][8]);for(int frame=0;frame<9;++frame){auto texture=textures[zoom].fGranaryHD[direction][frame];assert(texture&&texture->width()==160*(zoom+1)&&texture->x()==frame*160*(zoom+1));}granary.setEnabled(true);for(int frame=0;frame<8;++frame){granary.setFrameShift(4*frame);assert(granary.getTexture(size)==textures[zoom].fGranaryHD[direction][frame]);}granary.setEmployed(0);assert(granary.getTexture(size)==textures[zoom].fGranaryHD[direction][8]);granary.setEmployed(18);}
 std::cout<<"PASS: granary 144 cells, rotations, staffed loop and idle states\n";
 // Stored food: every filled bay draws the overlay for its food, at every zoom and direction.
 granary.setMaxCount({{eResourceType::wheat,32},{eResourceType::cheese,32},{eResourceType::fish,32}});
 assert(granary.addNotAccept(eResourceType::wheat,4)>0&&granary.addNotAccept(eResourceType::cheese,4)>0&&granary.addNotAccept(eResourceType::fish,4)>0);
 int filled=0;for(int i=0;i<8;++i)if(granary.resourceCount(i)>0)++filled;assert(filled==3);
 const std::map<eResourceType,std::string> names{{eResourceType::wheat,"wheat"},{eResourceType::cheese,"cheese"},{eResourceType::fish,"fish"}};
 for(int zoom=0;zoom<4;++zoom)for(int direction=0;direction<4;++direction){auto size=static_cast<eTileSize>(zoom);board.setWorldDirection(static_cast<eWorldDirection>(direction));
  const auto os=granary.getOverlays(size);int k=0;
  for(int i=0;i<8;++i){if(granary.resourceCount(i)<=0)continue;const auto key="slot"+std::to_string(i)+"_"+names.at(granary.resourceType(i));
   const auto& set=textures[zoom].hdOverlays("granary");assert(set.count(key));const auto& sp=set.at(key)[direction];
   if(!sp.fTex)continue;                                   // bay fully hidden behind the storehouse in this view
   assert(k<(int)os.size()&&os[k].fTex==sp.fTex&&!os[k].fAlignTop);
   assert(sp.fOX>=0&&sp.fOY>=0&&sp.fOX+sp.fTex->width()<=160*(zoom+1)&&sp.fOY+sp.fTex->height()<=160*(zoom+1));++k;}
  assert(k==(int)os.size()&&(direction==0||direction==1?k==filled:k<=filled));}
 std::cout<<"PASS: granary stored food overlays for every filled bay, zoom and direction\n";
}
