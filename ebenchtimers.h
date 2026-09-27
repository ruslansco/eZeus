#ifndef EBENCHTIMERS_H
#define EBENCHTIMERS_H

#include <chrono>

// Per-frame section timings reported by EZEUS_BENCH (development aid).
// A handful of clock reads per frame; negligible when not benchmarking.
struct eBenchTimers {
    enum eSection { sim, terrainUpdate, tiles, gamePaint, text, texLoad, widgets, cpu, present, count };
    static inline double sMs[count] = {};
    static void sReset() {
        for(double& v : sMs) v = 0;
    }
};

class eBenchScope {
public:
    explicit eBenchScope(const eBenchTimers::eSection s) :
        mSection(s), mStart(std::chrono::steady_clock::now()) {}
    ~eBenchScope() {
        const std::chrono::duration<double, std::milli> d =
            std::chrono::steady_clock::now() - mStart;
        eBenchTimers::sMs[mSection] += d.count();
    }
private:
    const eBenchTimers::eSection mSection;
    const std::chrono::steady_clock::time_point mStart;
};

#endif // EBENCHTIMERS_H
