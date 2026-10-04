#ifndef ERAND_H
#define ERAND_H

#include <random>
#include <algorithm>
#include <atomic>
#include <thread>

class eRand {
public:
    static int rand();
    // Reseeds the generator for deterministic replays and tests. Without a call the generator starts from
    // the EZEUS_SEED environment variable when it is set, otherwise from the hardware random device.
    static void seed(unsigned value);
    // Draws made from threads other than the one that created or reseeded the generator. The generator is
    // not thread safe, and such draws make replays depend on thread timing; deterministic code keeps this 0.
    static long offThreadDraws();
    // A deterministic 50% coin for filters that run inside worker-thread path searches (the shared generator
    // must not be drawn from there: it is not thread safe and its draw order follows thread timing). Draw
    // `salt` once on the game thread per search, then call this with the tile coordinates.
    static bool searchCoin(unsigned salt, int x, int y) {
        unsigned long long h = (static_cast<unsigned long long>(salt) << 32 | static_cast<unsigned>(x) * 73856093u ^ static_cast<unsigned>(y) * 19349663u) * 0x9E3779B97F4A7C15ull;
        h ^= h >> 29; h *= 0xBF58476D1CE4E5B9ull; h ^= h >> 32;
        return (h & 1) != 0;
    }

    // Randomness that is not part of the simulation: which of several sound files plays, which music track follows.
    // It never touches the simulation generator, so a sound can neither change a replay nor differ between the SDL
    // game (which plays it) and the embedded core (which hands the file name to the Godot front end). Not seedable,
    // safe from any thread.
    static int cosmetic() {
        static std::atomic<unsigned long long> state{std::random_device{}() * 0x9E3779B97F4A7C15ull + 1};
        unsigned long long z = state.fetch_add(0x9E3779B97F4A7C15ull) + 0x9E3779B97F4A7C15ull;
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull; z = (z ^ (z >> 27)) * 0x94D049BB133111EBull; z ^= z >> 31;
        return static_cast<int>(z & 0x7FFFFFFF);
    }

    template <typename T>
    static void randomShuffle(std::vector<T>& vec);
private:
    static std::random_device sDev;
    static std::mt19937 sRng;
    static std::uniform_int_distribution<int> sDist;
    static std::thread::id sOwner;
    static std::atomic<long> sOffThread;
};

template<typename T>
inline void eRand::randomShuffle(std::vector<T> &vec) {
    std::shuffle(vec.begin(), vec.end(), sRng);
}

#endif // ERAND_H
