#ifndef ESOUNDVECTOR_H
#define ESOUNDVECTOR_H

#include <functional>
#include <string>
#include <vector>

#include <SDL_mixer.h>

class eSoundVector {
public:
    ~eSoundVector();

    int soundCount() const { return mPaths.size(); }
    void addPath(const std::string& path);
    void clear();
    void play(const int id, const int chn = -1);
    void playRandomSound();
    // The file of sound `id` (empty when there is none).
    std::string path(const int id) const;
    // The embedded core has no audio device: every sound the simulation or the interface asks for is handed to this
    // function as the file's path instead, and the Godot front end plays it. Null (the SDL game) plays through the mixer.
    using eSink = std::function<void(const std::string&)>;
    static void setSink(const eSink& sink);
private:
    std::vector<std::pair<Mix_Chunk*, std::string>> mPaths;
};

#endif // ESOUNDVECTOR_H
