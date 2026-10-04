#include "estatedigest.h"

#include "esimulationstep.h"
#include "egameboard.h"
#include "fileIO/ewritestream.h"
#include "buildings/eemployingbuilding.h"
#include "characters/echaracter.h"

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <set>
#include <sstream>
#include <unistd.h>

namespace {
constexpr uint64_t kBasis = 1469598103934665603ull;
uint64_t fnv(uint64_t hash, const char* data, const size_t count) {
    for(size_t i = 0; i < count; ++i) {
        hash ^= static_cast<unsigned char>(data[i]);
        hash *= 1099511628211ull;
    }
    return hash;
}
std::string hex(const uint64_t value) {
    char text[24];
    std::snprintf(text, sizeof(text), "%016llx", static_cast<unsigned long long>(value));
    return text;
}
}

void eReplaySteps(eGameBoard& board, const int ticks) {
    // Loading leaves worker tasks (appeal map, path searches) running; they must finish before the
    // first step and after the last so the state is not read while it is being written.
    board.updateAppealMapIfNeeded();
    board.waitUntilFinished();
    for(int i = 0; i < ticks; ++i) {
        if(!eSimulationStep(board, 1, true, []() { return true; })) break;
    }
    board.waitUntilFinished();
}

std::string eStateDigest(eGameBoard& board, std::string* sections) {
    board.waitUntilFinished();
    uint64_t hash = kBasis;
    uint64_t part = kBasis;
    std::string parts;
    const auto add = [&](const std::string& line) {
        hash = fnv(hash, line.data(), line.size());
        hash = fnv(hash, "\n", 1);
        part = fnv(part, line.data(), line.size());
        part = fnv(part, "\n", 1);
    };
    const auto close = [&](const char* name) {
        parts += std::string(parts.empty() ? "" : " ") + name + "=" + hex(part);
        part = kBasis;
    };
    const auto pid = board.personPlayer();
    {
        std::ostringstream head;
        head << "time " << board.totalTime() << " money " << board.drachmas(pid) << " population " << board.population(pid);
        add(head.str());
        close("head");
    }
    std::set<const eBuilding*> seen;
    std::vector<std::string> buildings;
    board.iterateOverAllTiles([&](eTile* const t) {
        std::ostringstream line;
        line << "tile " << t->x() << ' ' << t->y() << ' ' << t->doubleAltitude() << ' ' << int(t->terrain()) << ' '
             << (t->hasRoad() ? 1 : 0);
        add(line.str());
        const auto b = t->underBuilding();
        if(!b || !seen.insert(b).second) return;
        const auto r = b->tileRect();
        std::ostringstream item;
        item << "building " << int(b->type()) << ' ' << r.x << ' ' << r.y << ' ' << r.w << ' ' << r.h << ' '
             << (b->enabled() ? 1 : 0) << ' ' << (b->isOnFire() ? 1 : 0);
        if(const auto employer = dynamic_cast<eEmployingBuilding*>(b)) {
            item << " employed " << employer->employed() << " shut " << (employer->shutDown() ? 1 : 0);
        }
        buildings.push_back(item.str());
    });
    close("tiles");
    std::sort(buildings.begin(), buildings.end());
    for(const auto& line : buildings) add(line);
    close("buildings");
    std::vector<std::string> characters;
    for(const auto c : board.characters()) {
        std::ostringstream line;
        line << "character " << int(c->type()) << ' ' << c->absX() << ' ' << c->absY() << ' '
             << int(c->orientation()) << ' ' << int(c->actionType()) << ' ' << (c->visible() ? 1 : 0);
        characters.push_back(line.str());
    }
    std::sort(characters.begin(), characters.end());
    for(const auto& line : characters) add(line);
    close("characters");
    if(sections) *sections = parts;
    return hex(hash) + ":" + std::to_string(buildings.size()) + ":" + std::to_string(characters.size()) + ":" +
           std::to_string(board.totalTime());
}

std::string eSaveDigest(const eGameBoard& board) {
    // The save writer targets files or fixed memory; a temporary file keeps it unchanged.
    const auto path = std::filesystem::temp_directory_path() /
                      ("ezeus-digest-" + std::to_string(getpid()) + ".bin");
    {
        std::ofstream file(path, std::ios::out | std::ios::binary | std::ios::trunc);
        eWriteTarget target(&file);
        eWriteStream dst(target);
        board.write(dst);
    }
    std::ifstream in(path, std::ios::in | std::ios::binary);
    uint64_t hash = kBasis;
    uint64_t bytes = 0;
    char buffer[65536];
    while(in) {
        in.read(buffer, sizeof(buffer));
        const auto count = static_cast<size_t>(in.gcount());
        hash = fnv(hash, buffer, count);
        bytes += count;
    }
    in.close();
    std::error_code ignored;
    // EZEUS_REPLAY_DUMP=<file> keeps the serialized state, to find where two replays first differ.
    if(const char* const keep = std::getenv("EZEUS_REPLAY_DUMP")) std::filesystem::copy_file(path, keep, std::filesystem::copy_options::overwrite_existing, ignored);
    std::filesystem::remove(path, ignored);
    return hex(hash) + ":" + std::to_string(bytes);
}
