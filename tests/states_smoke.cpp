#include "egamedir.h"
#include "textures/echaractertextures.h"

#include <cassert>
#include <fstream>
#include <iostream>
#include <map>

// states_smoke <name>...: loads each remastered all-state atlas (heroes, gods, monsters) through
// loadStatesHD at tile heights 15 and 30, every listed state into an 8-heading slot, and checks
// every frame exists with the atlas anchor offsets. Run from eZeus/Bin.
int main(int argc, char** argv) {
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    eGameDir::initialize();
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, 64, 64, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    int fails = 0;
    for(int a = 1; a < argc; a++) {
        const std::string name = argv[a];
        std::ifstream meta(eGameDir::texturesDir() + "Remastered/characters/" + name + "/person.txt");
        int cols, x0, y0, w, h;
        meta >> cols >> x0 >> y0 >> w >> h;
        std::map<std::string, std::pair<int, int>> states;
        std::string st; int n, heads;
        while(meta >> st >> n >> heads) states[st] = {n, heads};
        for(const int th : {15, 30}) {
            std::map<std::string, std::vector<eTextureCollection>> dirs;
            std::vector<ePersonHDSlot> slots;
            for(const auto& s : states) dirs[s.first];
            for(auto& d : dirs) slots.push_back({d.first.c_str(), &d.second, nullptr});
            const bool ok = loadStatesHD(slots, renderer, th, name);
            bool frames = ok;
            for(const auto& s : states) {
                const auto& v = dirs[s.first];
                frames = frames && v.size() == 8;
                for(const auto& c : v) frames = frames && c.size() == s.second.first && c.getTexture(0);
            }
            if(!frames) { std::cout << "FAIL " << name << " @" << th << "\n"; fails++; }
        }
        std::cout << "PASS? " << name << ": " << states.size() << " states\n";
    }
    return fails ? 1 : 0;
}
