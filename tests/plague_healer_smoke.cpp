#include "egamedir.h"
#include "enumbers.h"
#include "elanguage.h"
#include "textures/egametextures.h"
#include "engine/ecampaign.h"
#include "engine/egameboard.h"
#include "engine/eplague.h"
#include "buildings/esmallhouse.h"
#include "characters/ehealer.h"
#include "widgets/egamewidget.h"
#include "fileIO/ereadstream.h"
#include <fstream>
#include <iostream>

// A real native city, read only from the designated save. Treatment goes through
// the real walker/house service functions; no presentation flag is cleared here.
int main(int argc, char** argv) {
    if(argc != 3) return 2;
    const std::string engine = argv[1], lang = argv[2];
    eGameDir::initializeEmbedded(engine);
    eNumbers::sLoad(); eLanguage::reload(lang);
    eSettings settings;
    settings.fTinyTextures = settings.fMediumTextures = settings.fLargeTextures = false;
    settings.fSmallTextures = true;
    eGameTextures::setSettings(settings); eGameTextures::initialize(nullptr);
    std::ifstream file(engine + "/Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez", std::ios::binary);
    eReadStream input{eReadSource(&file)}; input.readFormat();
    eGameWidgetSettings view; view.read(input);
    eCampaign campaign; campaign.read(input); input.handlePostFuncs();
    campaign.loadStrings(); campaign.loadNumbers();
    auto& board = campaign.parentCityBoard(); board.waitUntilFinished();
    int checks = 0, failures = 0;
    const auto check = [&](bool pass, const char* text) {
        ++checks; if(!pass) ++failures;
        std::cout << "PLAGUE_HEALER_CHECK " << (pass ? "PASS " : "FAIL ") << lang << ' ' << text << '\n';
    };
    eSmallHouse* house = nullptr; eTile* road = nullptr;
    board.iterateOverAllTiles([&](eTile* tile) {
        if(house || !tile->hasRoad()) return;
        for(int dx = -1; dx <= 1; ++dx) for(int dy = -1; dy <= 1; ++dy) {
            const auto near = tile->tileRel<eTile>(dx,dy);
            const auto h = near ? dynamic_cast<eSmallHouse*>(near->underBuilding()) : nullptr;
            if(h && h->people() > 0) { house = h; road = tile; return; }
        }
    });
    check(house && road, "inhabited house is in native service range of a real road");
    if(!house || !road) return 1;
    const auto clear = [&]() {
        const auto plagues = board.plagues(house->cityId());
        for(const auto& plague : plagues) board.healPlague(plague);
    };
    const auto infectOnly = [&]() {
        clear(); eRand::seed(4242); board.startPlague(house);
        const auto plague = board.plagueForHouse(house);
        if(plague) {
            const auto infected = plague->houses();
            for(const auto other : infected) if(other != house) board.healHouse(other);
        }
        check(house->plague() && board.plagueForHouse(house), "infection is registered in the native outbreak");
    };
    auto healer = e::make_shared<eHealer>(board);
    healer->setBothCityIds(house->cityId());
    house->provide(eProvide::hygiene, 100000);
    const int people = house->people();
    infectOnly();
    house->provide(eProvide::hygiene, 100000);
    check(house->hygiene() == 100 && house->plague(), "hygiene alone does not masquerade as medical treatment");
    healer->setProvide(eProvide::hygiene, 0);
    healer->provideToBuilding(house);
    check(house->plague(), "an exhausted healer does not treat a house");
    healer->setProvide(eProvide::hygiene, 100000);
    healer->provideToBuilding(house);
    check(!house->plague() && !board.plagueForHouse(house), "a healer cures an infected house even at full hygiene");
    check(board.plagues(house->cityId()).empty(), "curing the last house removes its outbreak");
    check(house->people() == people && house->hygiene() == 100, "treatment preserves residents and full hygiene");
    infectOnly();
    healer->changeTile(road);
    check(!house->plague() && !board.plagueForHouse(house), "entering an adjacent road tile cures through normal walker service");
    check(board.plagues(house->cityId()).empty(), "road treatment clears the persistent native plague count");
    healer->changeTile(road);
    check(!house->plague() && house->people() == people, "repeat visits do not recreate infection or remove residents");
    house->timeChanged(eNumbers::sHouseHygieneDecrementPeriod + 1);
    const int hygieneBefore = house->hygiene();
    check(hygieneBefore < 100, "native hygiene decay prepares a house needing preventive care");
    infectOnly();
    healer->setProvide(eProvide::hygiene, 100000);
    healer->provideToBuilding(house);
    check(!house->plague() && house->hygiene() == 100 && healer->provideCount() == 100000 - (100 - hygieneBefore), "treatment also retains exact normal hygiene restoration and supply consumption");
    // Retain a second infected house outside this walker's service range.
    clear(); eRand::seed(4242); board.startPlague(house);
    const auto outbreak = board.plagueForHouse(house);
    eSmallHouse* untreated = nullptr;
    if(outbreak) for(const auto candidate : outbreak->houses()) {
        if(candidate == house) continue;
        bool reached = false;
        for(int dx = -1; dx <= 1; ++dx) for(int dy = -1; dy <= 1; ++dy) {
            const auto tile = road->tileRel<eTile>(dx,dy);
            if(tile && tile->underBuilding() == candidate) reached = true;
        }
        if(!reached && candidate->people() > 0) { untreated = candidate; break; }
    }
    check(untreated != nullptr, "outbreak includes an inhabited house outside the visit's service range");
    if(untreated) {
        healer->changeTile(road);
        check(!house->plague() && untreated->plague() && board.plagueForHouse(untreated), "treatment heals visited houses without clearing untreated neighbors");
        healer->provideToBuilding(untreated);
        check(!untreated->plague() && !board.plagueForHouse(untreated), "the other house recovers when the healer serves it");
    }
    clear();
    healer->changeTile(nullptr); healer.reset(); board.emptyRubbish();
    std::cout << "PLAGUE_HEALER_VALIDATION " << (failures ? "FAIL" : "PASS") << " checks=" << checks << '\n';
    return failures ? 1 : 0;
}
