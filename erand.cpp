#include "erand.h"

#include "elimits.h"

#include <cstdlib>
#include <cstdio>
#ifndef _WIN32
#include <execinfo.h>
#include <unistd.h>
#endif

std::random_device eRand::sDev;
static unsigned initialSeed(std::random_device& device) {
    if(const char* const env = std::getenv("EZEUS_SEED")) return static_cast<unsigned>(std::strtoul(env, nullptr, 10));
    return device();
}
std::mt19937 eRand::sRng(initialSeed(sDev));
std::uniform_int_distribution<int> eRand::sDist(0, __INT_MAX__);
std::thread::id eRand::sOwner = std::this_thread::get_id();
std::atomic<long> eRand::sOffThread{0};

int eRand::rand() {
    if(std::this_thread::get_id() != sOwner) {
        const long n = ++sOffThread;
        // EZEUS_RAND_TRACE=<count>: print the call stack of the first draws made from a worker thread.
        static const long traced = std::getenv("EZEUS_RAND_TRACE") ? std::atol(std::getenv("EZEUS_RAND_TRACE")) : 0;
        if(n <= traced) {
#ifndef _WIN32
            void* frames[24];
            const int depth = backtrace(frames, 24);
            dprintf(2, "RAND_OFF_THREAD draw %ld\n", n);
            backtrace_symbols_fd(frames, depth, 2);
#else
            // Preserve the counter and RNG sequence without POSIX-only tracing.
            std::fprintf(stderr, "RAND_OFF_THREAD draw %ld\n", n);
#endif
        }
    }
    return sDist(sRng);
}

long eRand::offThreadDraws() {
    return sOffThread.load();
}

void eRand::seed(const unsigned value) {
    sOwner = std::this_thread::get_id();
    sRng.seed(value);
    sDist.reset();
}
