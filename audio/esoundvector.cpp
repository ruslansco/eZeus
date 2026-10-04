#include "esoundvector.h"

#include "erand.h"
#include "egamedir.h"
#include <filesystem>

Mix_Chunk* loadSound(const std::string& path) {
    const auto wav = Mix_LoadWAV(path.c_str());
    if(!wav) {
        printf("Failed to load sound '%s'!\n SDL_mixer Error: %s\n",
               path.c_str(), Mix_GetError());
        return nullptr;
    }
    return wav;
}

eSoundVector::~eSoundVector() {
    clear();
}

void eSoundVector::clear() {
    for(const auto& s : mPaths) {
        if(!s.first) continue;
        Mix_FreeChunk(s.first);
    }
    mPaths.clear();
}

const bool sLoadOnAdd = false;

void eSoundVector::addPath(const std::string& path) {
    const bool e = std::filesystem::exists(path);
    if(!e) printf("Missing audio file %s\n", path.c_str());
    const auto sound = sLoadOnAdd ? loadSound(path) : nullptr;
    mPaths.push_back({sound, path});
}

namespace {
eSoundVector::eSink gSink;
}

void eSoundVector::setSink(const eSink& sink) {
    gSink = sink;
}

void eSoundVector::play(const int id, const int chn) {
    const int idMax = mPaths.size();
    if(id < 0 || id >= idMax) return;
    auto& p = mPaths[id];
    if(gSink) {
        gSink(p.second);
        return;
    }
    if(eGameDir::embedded()) return;
    if(!p.first) p.first = loadSound(p.second);
    if(p.first) Mix_PlayChannel(chn, p.first, 0);
}

void eSoundVector::playRandomSound() {
    const int sc = soundCount();
    if(sc <= 0) return;
    const int id = eRand::cosmetic() % sc;
    play(id);
}

std::string eSoundVector::path(const int id) const {
    const int idMax = mPaths.size();
    if(id < 0 || id >= idMax) return "";
    return mPaths[id].second;
}
