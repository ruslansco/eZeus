#include "egamedir.h"
#include "textures/egametextures.h"

#include <cassert>
#include <functional>
#include <iostream>

// Reference sheets for walker remasters (art/characters/*): for each animal, one row
// per animation (walk, fight, lay down: heading argv[2], default 1 = right; die: its single
// row) plus a row with the first walk frame in all eight headings, drawn at tile
// height 30 with the engine's offsets and anchored at (40, 60) of each 80 px cell.
// Usage: dump_characters <out dir>; writes <out>/<name>.png (whatever textures are
// installed: run with and without Textures/Remastered/characters to compare).
int main(int argc, char** argv) {
    assert(argc > 1);
    const std::string out = argv[1];
    SDL_setenv("SDL_VIDEODRIVER", "dummy", 1);
    assert(SDL_Init(SDL_INIT_VIDEO) == 0);
    assert(IMG_Init(IMG_INIT_PNG) & IMG_INIT_PNG);
    eGameDir::initialize();
    const int cell = 80;
    const int cols = 28;
    auto surface = SDL_CreateRGBSurfaceWithFormat(0, cols*cell, 5*cell, 32, SDL_PIXELFORMAT_RGBA32);
    auto renderer = SDL_CreateSoftwareRenderer(surface);
    assert(renderer);
    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
    assert(eGameTextures::initialize(renderer));
    eSettings settings;
    eGameTextures::setSettings(settings);
    eGameTextures::loadSheep();
    eGameTextures::loadGoat();
    eGameTextures::loadBoar();
    eGameTextures::loadDeer();
    eGameTextures::loadWolf();
    eGameTextures::loadDonkey();
    const auto& texs = eGameTextures::characters()[1];
    const auto draw = [&](const std::shared_ptr<eTexture>& tex, int col, int row) {
        if(!tex) return;
        tex->render(renderer, col*cell + 40 - tex->offsetX(), row*cell + 60 - tex->offsetY());
    };
    const auto dump = [&](const std::string& name, const eBasicCharacterTextures& t,
                          const std::vector<eTextureCollection>* fight,
                          const std::vector<eTextureCollection>* lay) {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        const int dir = argc > 2 ? std::atoi(argv[2]) : 1;
        const auto row = [&](const eTextureCollection& c, int r) {
            for(int i = 0; i < c.size() && i < cols; i++) draw(c.getTexture(i), i, r);
            std::cout << name << " row " << r << ": " << c.size() << " frames\n";
        };
        if(!t.fWalk.empty()) row(t.fWalk[dir], 0);
        if(fight && !fight->empty()) row((*fight)[dir], 1);
        if(lay && !lay->empty()) row((*lay)[dir], 2);
        row(t.fDie, 3);
        for(int d = 0; d < 8 && d < (int)t.fWalk.size(); d++) draw(t.fWalk[d].getTexture(0), d, 4);
        IMG_SavePNG(surface, (out + "/" + name + ".png").c_str());
    };
    const auto animal = [&](const std::string& name, const eAnimalTextures& t) {
        dump(name, t, &t.fFight, &t.fLayDown);
    };
    animal("sheep_fleeced", texs.fFleecedSheep);
    animal("sheep_nude", texs.fNudeSheep);
    animal("goat", texs.fGoat);
    animal("boar", texs.fBoar);
    animal("deer", texs.fDeer);
    animal("wolf", texs.fWolf);
    dump("donkey", texs.fDonkey, nullptr, nullptr);

    // People: one row per animation (heading argv[2]) or single-heading collection.
    eGameTextures::loadFireFighter();
    eGameTextures::loadSick();
    eGameTextures::loadGrower();
    eGameTextures::loadShepherd();
    eGameTextures::loadGoatherd();
    eGameTextures::loadTrader();
    eGameTextures::loadPhilosopher();
    eGameTextures::loadActor();
    eGameTextures::loadCompetitor();
    eGameTextures::loadWatchman();
    using V = std::vector<eTextureCollection>;
    struct Row { const V* v; const eTextureCollection* c; };
    const auto people = [&](const std::string& name, const eBasicCharacterTextures& t, std::vector<Row> rows) {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        const int dir = argc > 2 ? std::atoi(argv[2]) : 1;
        rows.insert(rows.begin(), Row{&t.fWalk, nullptr});
        rows.push_back(Row{nullptr, &t.fDie});
        int r = 0;
        for(const auto& row : rows) {
            const eTextureCollection* c = row.c ? row.c : (row.v && !row.v->empty() ? &(*row.v)[dir] : nullptr);
            if(!c) continue;
            for(int i = 0; i < c->size() && i < cols; i++) draw(c->getTexture(i), i, r);
            std::cout << name << " row " << r << ": " << c->size() << " frames\n";
            if(++r == 4) break;
        }
        IMG_SavePNG(surface, (out + "/" + name + ".png").c_str());
    };
    people("firefighter", texs.fFireFighter, {{&texs.fFireFighter.fCarry, nullptr}, {&texs.fFireFighter.fPutOut, nullptr}});
    people("sick", texs.fSick, {{&texs.fSick.fFight, nullptr}});
    people("grower", texs.fGrower, {{&texs.fGrower.fWorkOnGrapes, nullptr}, {&texs.fGrower.fCollectOlives, nullptr}});
    people("shepherd", texs.fShepherd, {{nullptr, &texs.fShepherd.fCollect}, {nullptr, &texs.fShepherd.fFight}});
    people("goatherd", texs.fGoatherd, {{nullptr, &texs.fGoatherd.fCollect}, {nullptr, &texs.fGoatherd.fFight}});
    people("watchman", texs.fWatchman, {{&texs.fWatchman.fFight, nullptr}});
    people("trader", texs.fTrader, {});
    people("philosopher", texs.fPhilosopher, {});
    people("actor", texs.fActor, {});
    people("competitor", texs.fCompetitor, {});

    eGameTextures::loadHunter();
    eGameTextures::loadPorter();
    eGameTextures::loadPeddler();
    eGameTextures::loadTaxCollector();
    eGameTextures::loadWaterDistributor();
    eGameTextures::loadScholar();
    eGameTextures::loadGymnast();
    eGameTextures::loadUrchinGatherer();
    eGameTextures::loadSettlers();
    eGameTextures::loadBronzeMiner();
    people("hunter", texs.fHunter, {{&texs.fHunter.fCollect, nullptr}, {&texs.fHunter.fCarry, nullptr}});
    people("deerhunter", texs.fDeerHunter, {{&texs.fDeerHunter.fCollect, nullptr}, {&texs.fDeerHunter.fCarry, nullptr}});
    people("bronzeminer", texs.fBronzeMiner, {{&texs.fBronzeMiner.fCollect, nullptr}, {&texs.fBronzeMiner.fCarry, nullptr}});
    people("orangetender", texs.fOrangeTender, {{&texs.fOrangeTender.fWorkOnTree, nullptr}, {&texs.fOrangeTender.fCollect, nullptr}});
    people("porter", texs.fPorter, {});
    people("peddler", texs.fPeddler, {});
    people("taxcollector", texs.fTaxCollector, {});
    people("waterdistributor", texs.fWaterDistributor, {});
    people("scholar", texs.fScholar, {});
    people("gymnast", texs.fGymnast, {});
    people("settlers1", texs.fSettlers1, {});
    people("settlers2", texs.fSettlers2, {});
    {   // urchin gatherer: swim, collect, carry, deposit (no walk set)
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        const int dir = argc > 2 ? std::atoi(argv[2]) : 1;
        const auto& u = texs.fUrchinGatherer;
        const std::vector<eTextureCollection>* rows[4] = {&u.fSwim, &u.fCollect, &u.fCarry, &u.fDeposit};
        for(int r = 0; r < 4; r++)
            for(int i = 0; i < (*rows[r])[dir].size() && i < cols; i++) draw((*rows[r])[dir].getTexture(i), i, r);
        IMG_SavePNG(surface, (out + "/urchin.png").c_str());
    }
    return 0;
}
