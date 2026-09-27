// Validate packed costume frames through the real SDL person loader.
#include "egamedir.h"
#include "textures/echaractertextures.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <map>
int main(int argc,char**argv) {
 SDL_setenv("SDL_VIDEODRIVER","dummy",1);assert(SDL_Init(SDL_INIT_VIDEO)==0);
 assert(IMG_Init(IMG_INIT_PNG)&IMG_INIT_PNG);eGameDir::initialize();
 auto surface=SDL_CreateRGBSurfaceWithFormat(0,80,80,32,SDL_PIXELFORMAT_RGBA32);
 auto renderer=SDL_CreateSoftwareRenderer(surface);assert(renderer);
 for(int arg=1;arg<argc;++arg) {
  const std::string name=argv[arg];
  std::ifstream meta(eGameDir::texturesDir()+"Remastered/characters/"+name+"/person.txt");
  int cols,x,y,w,h;assert(meta>>cols>>x>>y>>w>>h);
  struct State {std::string name;int frames,heads;};std::vector<State> states;State s;
  while(meta>>s.name>>s.frames>>s.heads)states.push_back(s);
  for(int tileH:{15,30}) {
   eBasicCharacterTextures t(renderer);
   std::map<std::string,std::vector<eTextureCollection>> dirs;
   std::map<std::string,eTextureCollection> single;
   std::vector<ePersonHDSlot> slots;
   for(const auto& st:states)if(st.name!="walk"&&st.name!="die") {
    if(st.heads==8)slots.push_back({st.name.c_str(),&dirs[st.name],nullptr});
    else {auto it=single.emplace(st.name,eTextureCollection(renderer)).first;slots.push_back({st.name.c_str(),nullptr,&it->second});}
   }
   assert(loadPersonHD(t,slots,renderer,tileH,name));int index=0;
   for(const auto& st:states) {
    for(int d=0;d<st.heads;++d) {
     const auto& coll=st.name=="walk"?t.fWalk.at(d):st.name=="die"?t.fDie:st.heads==8?dirs.at(st.name).at(d):single.at(st.name);
     assert(coll.size()==st.frames);
     for(int f=0;f<st.frames;++f,++index) {
      const auto tex=coll.getTexture(f);assert(tex);
      assert(tex->width()==w*tileH/60&&tex->height()==h*tileH/60);
      assert(tex->offsetX()==(80-x)/2&&tex->offsetY()==(120-y)/2);
      assert(tex->x()==index%cols*w*tileH/60&&tex->y()==index/cols*h*tileH/60);
      assert(tex->density()==2);
     }
    }
   }
  }
  std::cout<<"PASS "<<name<<": native atlas states, every frame, both scales, density and anchor\n";
 }
 SDL_DestroyRenderer(renderer);SDL_FreeSurface(surface);IMG_Quit();SDL_Quit();
}
