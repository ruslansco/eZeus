#include "echaractertextures.h"
#include "egamedir.h"
#include <filesystem>
#include <fstream>
#include <algorithm>

#include "espriteloader.h"

#include "offsets/SprMain.h"
#include "offsets/Zeus_Greek.h"
#include "offsets/SprAmbient.h"

#include "spriteData/peddler15.h"
#include "spriteData/peddler30.h"
#include "spriteData/peddler45.h"
#include "spriteData/peddler60.h"

#include "spriteData/actor15.h"
#include "spriteData/actor30.h"
#include "spriteData/actor45.h"
#include "spriteData/actor60.h"

#include "spriteData/ox15.h"
#include "spriteData/ox30.h"
#include "spriteData/ox45.h"
#include "spriteData/ox60.h"

#include "spriteData/porter15.h"
#include "spriteData/porter30.h"
#include "spriteData/porter45.h"
#include "spriteData/porter60.h"

#include "spriteData/oxHandler15.h"
#include "spriteData/oxHandler30.h"
#include "spriteData/oxHandler45.h"
#include "spriteData/oxHandler60.h"

#include "spriteData/trailer15.h"
#include "spriteData/trailer30.h"
#include "spriteData/trailer45.h"
#include "spriteData/trailer60.h"

#include "spriteData/settlers115.h"
#include "spriteData/settlers130.h"
#include "spriteData/settlers145.h"
#include "spriteData/settlers160.h"

#include "spriteData/settlers215.h"
#include "spriteData/settlers230.h"
#include "spriteData/settlers245.h"
#include "spriteData/settlers260.h"

#include "spriteData/fireFighter15.h"
#include "spriteData/fireFighter30.h"
#include "spriteData/fireFighter45.h"
#include "spriteData/fireFighter60.h"

#include "spriteData/watchman15.h"
#include "spriteData/watchman30.h"
#include "spriteData/watchman45.h"
#include "spriteData/watchman60.h"

#include "spriteData/goatherd15.h"
#include "spriteData/goatherd30.h"
#include "spriteData/goatherd45.h"
#include "spriteData/goatherd60.h"

#include "spriteData/bronzeMiner15.h"
#include "spriteData/bronzeMiner30.h"
#include "spriteData/bronzeMiner45.h"
#include "spriteData/bronzeMiner60.h"

#include "spriteData/artisan15.h"
#include "spriteData/artisan30.h"
#include "spriteData/artisan45.h"
#include "spriteData/artisan60.h"

#include "spriteData/foodVendor15.h"
#include "spriteData/foodVendor30.h"
#include "spriteData/foodVendor45.h"
#include "spriteData/foodVendor60.h"

#include "spriteData/fleeceVendor15.h"
#include "spriteData/fleeceVendor30.h"
#include "spriteData/fleeceVendor45.h"
#include "spriteData/fleeceVendor60.h"

#include "spriteData/oilVendor15.h"
#include "spriteData/oilVendor30.h"
#include "spriteData/oilVendor45.h"
#include "spriteData/oilVendor60.h"

#include "spriteData/wineVendor15.h"
#include "spriteData/wineVendor30.h"
#include "spriteData/wineVendor45.h"
#include "spriteData/wineVendor60.h"

#include "spriteData/armsVendor15.h"
#include "spriteData/armsVendor30.h"
#include "spriteData/armsVendor45.h"
#include "spriteData/armsVendor60.h"

#include "spriteData/horseVendor15.h"
#include "spriteData/horseVendor30.h"
#include "spriteData/horseVendor45.h"
#include "spriteData/horseVendor60.h"

#include "spriteData/fleecedSheep15.h"
#include "spriteData/fleecedSheep30.h"
#include "spriteData/fleecedSheep45.h"
#include "spriteData/fleecedSheep60.h"

#include "spriteData/horse15.h"
#include "spriteData/horse30.h"
#include "spriteData/horse45.h"
#include "spriteData/horse60.h"

#include "spriteData/shepherd15.h"
#include "spriteData/shepherd30.h"
#include "spriteData/shepherd45.h"
#include "spriteData/shepherd60.h"

#include "spriteData/marbleMiner15.h"
#include "spriteData/marbleMiner30.h"
#include "spriteData/marbleMiner45.h"
#include "spriteData/marbleMiner60.h"

#include "spriteData/silverMiner15.h"
#include "spriteData/silverMiner30.h"
#include "spriteData/silverMiner45.h"
#include "spriteData/silverMiner60.h"

#include "spriteData/archer15.h"
#include "spriteData/archer30.h"
#include "spriteData/archer45.h"
#include "spriteData/archer60.h"

#include "spriteData/lumberjack15.h"
#include "spriteData/lumberjack30.h"
#include "spriteData/lumberjack45.h"
#include "spriteData/lumberjack60.h"

#include "spriteData/taxCollector15.h"
#include "spriteData/taxCollector30.h"
#include "spriteData/taxCollector45.h"
#include "spriteData/taxCollector60.h"

#include "spriteData/transporter15.h"
#include "spriteData/transporter30.h"
#include "spriteData/transporter45.h"
#include "spriteData/transporter60.h"

#include "spriteData/grower15.h"
#include "spriteData/grower30.h"
#include "spriteData/grower45.h"
#include "spriteData/grower60.h"

#include "spriteData/trader15.h"
#include "spriteData/trader30.h"
#include "spriteData/trader45.h"
#include "spriteData/trader60.h"

#include "spriteData/waterDistributor15.h"
#include "spriteData/waterDistributor30.h"
#include "spriteData/waterDistributor45.h"
#include "spriteData/waterDistributor60.h"

#include "spriteData/rockThrower15.h"
#include "spriteData/rockThrower30.h"
#include "spriteData/rockThrower45.h"
#include "spriteData/rockThrower60.h"

#include "spriteData/hoplite15.h"
#include "spriteData/hoplite30.h"
#include "spriteData/hoplite45.h"
#include "spriteData/hoplite60.h"

#include "spriteData/horseman15.h"
#include "spriteData/horseman30.h"
#include "spriteData/horseman45.h"
#include "spriteData/horseman60.h"

#include "spriteData/healer15.h"
#include "spriteData/healer30.h"
#include "spriteData/healer45.h"
#include "spriteData/healer60.h"

#include "spriteData/nudeSheep15.h"
#include "spriteData/nudeSheep30.h"
#include "spriteData/nudeSheep45.h"
#include "spriteData/nudeSheep60.h"

#include "spriteData/cart15.h"
#include "spriteData/cart30.h"
#include "spriteData/cart45.h"
#include "spriteData/cart60.h"

#include "spriteData/boar15.h"
#include "spriteData/boar30.h"
#include "spriteData/boar45.h"
#include "spriteData/boar60.h"

#include "spriteData/gymnast15.h"
#include "spriteData/gymnast30.h"
#include "spriteData/gymnast45.h"
#include "spriteData/gymnast60.h"

#include "spriteData/competitor15.h"
#include "spriteData/competitor30.h"
#include "spriteData/competitor45.h"
#include "spriteData/competitor60.h"

#include "spriteData/goat15.h"
#include "spriteData/goat30.h"
#include "spriteData/goat45.h"
#include "spriteData/goat60.h"

#include "spriteData/wolf15.h"
#include "spriteData/wolf30.h"
#include "spriteData/wolf45.h"
#include "spriteData/wolf60.h"

#include "spriteData/hunter15.h"
#include "spriteData/hunter30.h"
#include "spriteData/hunter45.h"
#include "spriteData/hunter60.h"

#include "spriteData/philosopher15.h"
#include "spriteData/philosopher30.h"
#include "spriteData/philosopher45.h"
#include "spriteData/philosopher60.h"

#include "spriteData/fishingBoat15.h"
#include "spriteData/fishingBoat30.h"
#include "spriteData/fishingBoat45.h"
#include "spriteData/fishingBoat60.h"

#include "spriteData/urchinGatherer15.h"
#include "spriteData/urchinGatherer30.h"
#include "spriteData/urchinGatherer45.h"
#include "spriteData/urchinGatherer60.h"

#include "spriteData/tradeBoat15.h"
#include "spriteData/tradeBoat30.h"
#include "spriteData/tradeBoat45.h"
#include "spriteData/tradeBoat60.h"

#include "spriteData/greekHoplite15.h"
#include "spriteData/greekHoplite30.h"
#include "spriteData/greekHoplite45.h"
#include "spriteData/greekHoplite60.h"

#include "spriteData/greekHorseman15.h"
#include "spriteData/greekHorseman30.h"
#include "spriteData/greekHorseman45.h"
#include "spriteData/greekHorseman60.h"

#include "spriteData/greekRockThrower15.h"
#include "spriteData/greekRockThrower30.h"
#include "spriteData/greekRockThrower45.h"
#include "spriteData/greekRockThrower60.h"

#include "spriteData/foodCart15.h"
#include "spriteData/foodCart30.h"
#include "spriteData/foodCart45.h"
#include "spriteData/foodCart60.h"

#include "spriteData/donkey15.h"
#include "spriteData/donkey30.h"
#include "spriteData/donkey45.h"
#include "spriteData/donkey60.h"

#include "spriteData/banners15.h"
#include "spriteData/banners30.h"
#include "spriteData/banners45.h"
#include "spriteData/banners60.h"

#include "spriteData/poseidonBannerTops15.h"
#include "spriteData/poseidonBannerTops30.h"
#include "spriteData/poseidonBannerTops45.h"
#include "spriteData/poseidonBannerTops60.h"

#include "espriteloader.h"

eCharacterTextures::eCharacterTextures(const int tileW, const int tileH,
                                       SDL_Renderer* const renderer) :
    fTileW(tileW), fTileH(tileH),
    fRenderer(renderer),

    fPeddler(renderer),
    fActor(renderer),
    fTaxCollector(renderer),
    fWaterDistributor(renderer),
    fWatchman(renderer),
    fFireFighter(renderer),
    fHealer(renderer),
    fGymnast(renderer),
    fCompetitor(renderer),
    fPhilosopher(renderer),

    fOx(renderer),
    fOxHandler(renderer),

    fEmptyTrailer(renderer),
    fWoodTrailer1(renderer),
    fWoodTrailer2(renderer),
    fMarbleTrailer1(renderer),
    fMarbleTrailer2(renderer),
    fBlackMarbleTrailer1(renderer),
    fBlackMarbleTrailer2(renderer),
    fSculptureTrailer(renderer),
    fEmptyBigTrailer(renderer),
    fMarbleBigTrailer(renderer),
    fBlackMarbleBigTrailer(renderer),

    fMarbleMiner(renderer),
    fSilverMiner(renderer),
    fBronzeMiner(renderer),
    fOrichalcMiner(renderer),
    fLumberjack(renderer),

    fArtisan(renderer),

    fHunter(renderer),
    fDeerHunter(renderer),

    fShepherd(renderer),
    fGoatherd(renderer),

    fFoodVendor(renderer),
    fFleeceVendor(renderer),
    fOilVendor(renderer),
    fWineVendor(renderer),
    fArmsVendor(renderer),
    fHorseVendor(renderer),

    fGrower(renderer),

    fBoar(renderer),
    fDeer(renderer),
    fWolf(renderer),

    fCattle1(renderer),
    fCattle2(renderer),
    fCattle3(renderer),
    fBull(renderer),
    fButcher(renderer),

    fGoat(renderer),
    fNudeSheep(renderer),
    fFleecedSheep(renderer),
    fHorse(renderer),

    fSettlers1(renderer),
    fSettlers2(renderer),

    fTransporter(renderer),

    fEmptyCart(renderer),

    fOrangeTender(renderer),

    fArcher(renderer),
    fPoseidonTowerArcher(renderer),

    fRockThrower(renderer),
    fHoplite(renderer),
    fHorseman(renderer),

    fHoplitePoseidon(renderer),
    fArcherPoseidon(renderer),

    fGreekRockThrower(renderer),
    fGreekHoplite(renderer),
    fGreekHorseman(renderer),

    fAmazonSpear(renderer),
    fAmazonArcher(renderer),

    fTrojanHoplite(renderer),
    fTrojanSpearthrower(renderer),
    fTrojanHorseman(renderer),

    fCentaurHorseman(renderer),
    fCentaurArcher(renderer),

    fEgyptianHoplite(renderer),
    fEgyptianArcher(renderer),

    fMayanHoplite(renderer),
    fMayanArcher(renderer),

    fPhoenicianHorseman(renderer),
    fPhoenicianArcher(renderer),

    fOceanidHoplite(renderer),
    fOceanidSpearthrower(renderer),

    fPersianHoplite(renderer),
    fPersianHorseman(renderer),
    fPersianArcher(renderer),

    fAtlanteanHoplite(renderer),
    fAtlanteanArcher(renderer),

    fBannerRod(renderer),
    fBannerTops(renderer),
    fPoseidonBannerTops(renderer),

    fTrader(renderer),
    fDonkey(renderer),

    fPorter(renderer),

    fFishingBoat(renderer),
    fUrchinGatherer(renderer),

    fTradeBoat(renderer),
    fTrireme(renderer),
    fEnemyBoat(renderer),

    fDisgruntled(renderer),
    fSick(renderer),
    fHomeless(renderer),

    fKraken(renderer),
    fScylla(renderer),

    fScholar(renderer),
    fAstronomer(renderer),
    fInventor(renderer),
    fCurator(renderer),

    fChariotVendor(renderer),

    fElephant(renderer),

    fEliteCitizen(renderer),

    fRacingHorse1(renderer),
    fRacingHorse2(renderer),
    fRacingHorse3(renderer),
    fRacingHorse4(renderer) {

}

void eCharacterTextures::loadAll() {
    loadPeddler();
    loadActor();
    loadOx();
    loadPorter();
    loadOxHandler();
    loadTrailer();
    loadSettlers();
    loadFireFighter();
    loadWatchman();
    loadGoatherd();
    loadBronzeMiner();
    loadOrichalcMiner();
    loadArtisan();
    loadFoodVendor();
    loadFleeceVendor();
    loadOilVendor();
    loadWineVendor();
    loadArmsVendor();
    loadHorseVendor();
    loadSheep();
    loadHorse();
    loadShepherd();
    loadMarbleMiner();
    loadSilverMiner();
    loadArcher();
    loadPoseidonTowerArcher();
    loadLumberjack();
    loadTaxCollector();
    loadTransporter();
    loadGrower();
    loadOrangeTender();
    loadTrader();
    loadWaterDistributor();

    loadRockThrower();
    loadHoplite();
    loadHorseman();

    loadAmazonSpear();
    loadAmazonArcher();

    loadTrojanHoplite();
    loadTrojanSpearthrower();
    loadTrojanHorseman();

    loadCentaurHorseman();
    loadCentaurArcher();

    loadPersianHoplite();
    loadPersianHorseman();
    loadPersianArcher();

    loadEgyptianHoplite();
    loadEgyptianChariot();
    loadEgyptianArcher();

    loadMayanHoplite();
    loadMayanArcher();

    loadOceanidHoplite();
    loadOceanidSpearthrower();

    loadPhoenicianHorseman();
    loadPhoenicianArcher();

    loadAtlanteanHoplite();
    loadAtlanteanChariot();
    loadAtlanteanArcher();

    loadAresWarrior();

    loadHealer();
    loadCart();
    loadOrichalcCart();
    loadOrangesCart();
    loadBlackMarbleTrailer();
    loadBoar();
    loadGymnast();
    loadCompetitor();
    loadGoat();
    loadWolf();
    loadHunter();
    loadDeerHunter();
    loadPhilosopher();
    loadUrchinGatherer();
    loadFishingBoat();
    loadTradeBoat();
    loadTrireme();
    loadTriremeOverlay();
    loadEnemyBoat();
    loadDeer();
    loadGreekHoplite();
    loadGreekHorseman();
    loadGreekRockThrower();
    loadDonkey();

    loadDisgruntled();
    loadSick();
    loadHomeless();

    loadCalydonianBoar();
    loadCerberus();
    loadChimera();
    loadCyclops();
    loadDragon();
    loadEchidna();
    loadHarpie();
    loadHector();
    loadHydra();
    loadKraken();
    loadMaenads();
    loadMedusa();
    loadMinotaur();
    loadScylla();
    loadSphinx();
    loadTalos();

    loadAchilles();
    loadAtalanta();
    loadBellerophon();
    loadHeracles();
    loadJason();
    loadOdysseus();
    loadPerseus();
    loadTheseus();

    loadScholar();
    loadAstronomer();
    loadInventor();
    loadCurator();

    loadHoplitePoseidon();
    loadArcherPoseidon();
    loadChariotPoseidon();

    loadCattle();
    loadBull();
    loadButcher();

    loadChariotVendor();

    loadChariot();

    loadElephant();

    loadSatyr();

    loadBanners();

    loadEliteCitizen();
}

void loadBasicTexture(eBasicCharacterTextures& tex,
                      const int start,
                      eSpriteLoader& loader) {
    loader.loadSkipFlipped(start, start, start + 96, tex.fWalk);

    for(int i = start + 96; i < start + 104; i++) {
        loader.load(start, i, tex.fDie);
    }
}

void eCharacterTextures::loadPeddler() {
    if(fPeddlerLoaded) return;
    fPeddlerLoaded = true;
    if(loadPersonHD(fPeddler, {}, fRenderer, fTileH, "peddler")) return;
    const auto& sds = spriteData(fTileH,
                                 ePeddlerSpriteData15,
                                 ePeddlerSpriteData30,
                                 ePeddlerSpriteData45,
                                 ePeddlerSpriteData60);
    eSpriteLoader loader(fTileH, "peddler", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fPeddler, 1, loader);
}

void eCharacterTextures::loadActor() {
    if(fActorLoaded) return;
    fActorLoaded = true;
    if(loadPersonHD(fActor, {}, fRenderer, fTileH, "actor")) return;
    const auto& sds = spriteData(fTileH,
                                 eActorSpriteData15,
                                 eActorSpriteData30,
                                 eActorSpriteData45,
                                 eActorSpriteData60);
    eSpriteLoader loader(fTileH, "actor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fActor, 105, loader);
}

namespace {
// Remastered ox-train trailers (art/characters/trailer): trailer.txt names each load, 8 heading
// cells apiece (person.txt layout); they replace the legacy sprites of the matching collection.
void loadTrailerHD(const std::vector<std::pair<std::string, eTextureCollection*>>& colls,
                   SDL_Renderer* const renderer, const int tileH) {
    if(tileH != 15 && tileH != 30) return;
    const auto dir = eGameDir::texturesDir() + "Remastered/characters/trailer/";
    std::ifstream meta(dir + "trailer.txt");
    int cols, x0, y0, w, h;
    if(!(meta >> cols >> x0 >> y0 >> w >> h) || cols <= 0) return;
    std::vector<std::string> names;
    std::string name;
    int frames, heads;
    while(meta >> name >> frames >> heads) {
        if(frames != 1 || heads != 8) return;
        names.push_back(name);
    }
    const int rows = (8*static_cast<int>(names.size()) + cols - 1)/cols;
    const int cw = w*tileH/60;
    const int ch = h*tileH/60;
    const auto sheet = std::make_shared<eTexture>();
    bool loaded = false;
    for(const int density : {2, 1}) {
        const auto path = dir + std::to_string(tileH) + (density == 2 ? "@2x.png" : ".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer, path)) continue;
        if(sheet->width() != cols*cw*density || sheet->height() != rows*ch*density) continue;
        sheet->setDensity(density);
        sheet->setScaleMode(SDL_ScaleModeLinear);
        loaded = true;
        break;
    }
    if(!loaded) return;
    for(int v = 0; v < static_cast<int>(names.size()); v++) {
        for(const auto& [n, coll] : colls) {
            if(n != names[v]) continue;
            for(int d = 0; d < 8 && d < coll->size(); d++) {
                const int i = 8*v + d;
                const auto t = std::make_shared<eTexture>();
                t->setParentTexture({i%cols*cw, i/cols*ch, cw, ch}, sheet);
                t->setOffset((80 - x0)/2, (120 - y0)/2);   // ground anchor, tile-height-30 units
                coll->replaceTexture(d, t);
            }
        }
    }
}
}

void eCharacterTextures::loadOx() {
    if(fOxLoaded) return;
    fOxLoaded = true;
    if(loadAnimalHD(fOx, nullptr, nullptr, fRenderer, fTileH, "ox")) return;   // art/characters/animals (ox)

    const auto& sds = spriteData(fTileH,
                                 eOxSpriteData15,
                                 eOxSpriteData30,
                                 eOxSpriteData45,
                                 eOxSpriteData60);
    eSpriteLoader loader(fTileH, "ox", sds,
                         &eSprMainOffset, fRenderer);
    loader.loadSkipFlipped(209, 209, 305, fOx.fWalk);

    for(auto& coll : fOx.fWalk) {
        const int iMax = coll.size();
        for(int i = 0; i < iMax; i++) {
            auto& tex = coll.getTexture(i);
            tex->setOffset(tex->offsetX(),
                           tex->offsetY() + 4);
        }
    }

    for(int i = 497; i < 505; i++) {
        loader.load(209, i, fOx.fDie);
    }
}

void eCharacterTextures::loadPorter() {
    if(fPorterLoaded) return;
    fPorterLoaded = true;
    if(loadPersonHD(fPorter, {}, fRenderer, fTileH, "porter")) return;

    const auto& sds = spriteData(fTileH,
                                 ePorterSpriteData15,
                                 ePorterSpriteData30,
                                 ePorterSpriteData45,
                                 ePorterSpriteData60);
    eSpriteLoader loader(fTileH, "porter", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fPorter, 1233, loader);
}

void eCharacterTextures::loadOxHandler() {
    if(fOxHandlerLoaded) return;
    fOxHandlerLoaded = true;
    if(loadPersonHD(fOxHandler, {}, fRenderer, fTileH, "oxhandler")) return;   // art/characters/people/people3.py

    const auto& sds = spriteData(fTileH,
                                 eOxHandlerSpriteData15,
                                 eOxHandlerSpriteData30,
                                 eOxHandlerSpriteData45,
                                 eOxHandlerSpriteData60);
    eSpriteLoader loader(fTileH, "oxHandler", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fOxHandler, 1337, loader);
}

void eCharacterTextures::loadTrailer() {
    if(fTrailerLoaded) return;
    fTrailerLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eTrailerSpriteData15,
                                 eTrailerSpriteData30,
                                 eTrailerSpriteData45,
                                 eTrailerSpriteData60);
    eSpriteLoader loader(fTileH, "trailer", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadTrailer(2991, 2991, 2999, fEmptyTrailer, -7);
    loader.loadTrailer(2991, 2999, 3007, fWoodTrailer1, -7);
    loader.loadTrailer(2991, 3007, 3015, fWoodTrailer2, -7);
    loader.loadTrailer(2991, 3015, 3023, fMarbleTrailer1, -7);
    loader.loadTrailer(2991, 3023, 3031, fMarbleTrailer2, -7);
    loader.loadTrailer(2991, 3031, 3039, fSculptureTrailer, -7);
    loader.loadTrailer(2991, 3039, 3047, fEmptyBigTrailer, -4);
    loader.loadTrailer(2991, 3047, 3055, fMarbleBigTrailer, -4);

    loadBlackMarbleTrailer();
    loadTrailerHD({{"empty", &fEmptyTrailer}, {"wood1", &fWoodTrailer1}, {"wood2", &fWoodTrailer2},
                   {"marble1", &fMarbleTrailer1}, {"marble2", &fMarbleTrailer2}, {"sculpture", &fSculptureTrailer},
                   {"bigempty", &fEmptyBigTrailer}, {"bigmarble", &fMarbleBigTrailer},
                   {"blackmarble1", &fBlackMarbleTrailer1}, {"blackmarble2", &fBlackMarbleTrailer2},
                   {"bigblackmarble", &fBlackMarbleBigTrailer}}, fRenderer, fTileH);
}

void eCharacterTextures::loadSettlers() {
    if(fSettlersLoaded) return;
    fSettlersLoaded = true;
    if(!loadPersonHD(fSettlers1, {}, fRenderer, fTileH, "settlers1")) {
        const auto& sds = spriteData(fTileH,
                                     eSettlers1SpriteData15,
                                     eSettlers1SpriteData30,
                                     eSettlers1SpriteData45,
                                     eSettlers1SpriteData60);
        eSpriteLoader loader(fTileH, "settlers1", sds,
                             &eSprMainOffset, fRenderer);
        loadBasicTexture(fSettlers1, 505, loader);
    }
    if(!loadPersonHD(fSettlers2, {}, fRenderer, fTileH, "settlers2")) {
        const auto& sds = spriteData(fTileH,
                                     eSettlers2SpriteData15,
                                     eSettlers2SpriteData30,
                                     eSettlers2SpriteData45,
                                     eSettlers2SpriteData60);
        eSpriteLoader loader(fTileH, "settlers2", sds,
                             &eSprMainOffset, fRenderer);
        loadBasicTexture(fSettlers2, 1793, loader);
    }
}

void eCharacterTextures::loadFireFighter() {
    if(fFireFighterLoaded) return;
    fFireFighterLoaded = true;
    if(loadPersonHD(fFireFighter, {{"carry", &fFireFighter.fCarry}, {"putout", &fFireFighter.fPutOut}}, fRenderer, fTileH, "firefighter")) return;
    const auto& sds = spriteData(fTileH,
                                 eFireFighterSpriteData15,
                                 eFireFighterSpriteData30,
                                 eFireFighterSpriteData45,
                                 eFireFighterSpriteData60);
    eSpriteLoader loader(fTileH, "fireFighter", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(609, 609, 705,
                           fFireFighter.fWalk);
    loader.loadSkipFlipped(609, 705, 801,
                           fFireFighter.fCarry);
    loader.loadSkipFlipped(609, 809, 1129,
                           fFireFighter.fPutOut);

    for(int i = 801; i < 809; i++) {
        loader.load(609, i, fFireFighter.fDie);
    }
}

void eCharacterTextures::loadWatchman() {
    if(fWatchmanLoaded) return;
    fWatchmanLoaded = true;
    if(loadPersonHD(fWatchman, {{"fight", &fWatchman.fFight}}, fRenderer, fTileH, "watchman")) return;
    const auto& sds = spriteData(fTileH,
                                 eWatchmanSpriteData15,
                                 eWatchmanSpriteData30,
                                 eWatchmanSpriteData45,
                                 eWatchmanSpriteData60);
    eSpriteLoader loader(fTileH, "watchman", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(2209, 2209, 2305, fWatchman.fWalk);
    loader.loadSkipFlipped(2209, 2313, 2377, fWatchman.fFight);

    for(int i = 2305; i < 2313; i++) {
        loader.load(2209, i, fWatchman.fDie);
    }
}

void eCharacterTextures::loadGoatherd() {
    if(fGoatherdLoaded) return;
    fGoatherdLoaded = true;
    if(loadPersonHD(fGoatherd, {{"carry", &fGoatherd.fCarry}, {"collect", nullptr, &fGoatherd.fCollect}, {"fight", nullptr, &fGoatherd.fFight}}, fRenderer, fTileH, "goatherd")) return;
    const auto& sds = spriteData(fTileH,
                                 eGoatherdSpriteData15,
                                 eGoatherdSpriteData30,
                                 eGoatherdSpriteData45,
                                 eGoatherdSpriteData60);
    eSpriteLoader loader(fTileH, "goatherd", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(2377, 2377, 2473, fGoatherd.fWalk);
    for(int i = 2481; i < 2489; i++) {
        loader.load(2377, i, fGoatherd.fCollect);
    }
    loader.loadSkipFlipped(2377, 2489, 2585, fGoatherd.fCarry);

    for(int i = 2473; i < 2481; i++) {
        loader.load(2377, i, fGoatherd.fDie);
    }
    for(int i = 2585; i < 2595; i++) {
        loader.load(2377, i, fGoatherd.fFight);
    }
}

void eCharacterTextures::loadBronzeMiner() {
    if(fBronzeMinerLoaded) return;
    fBronzeMinerLoaded = true;
    if(loadPersonHD(fBronzeMiner, {{"collect", &fBronzeMiner.fCollect}, {"carry", &fBronzeMiner.fCarry}}, fRenderer, fTileH, "bronzeminer")) return;
    const auto& sds = spriteData(fTileH,
                                 eBronzeMinerSpriteData15,
                                 eBronzeMinerSpriteData30,
                                 eBronzeMinerSpriteData45,
                                 eBronzeMinerSpriteData60);
    eSpriteLoader loader(fTileH, "bronzeMiner", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(2595, 2595, 2691, fBronzeMiner.fWalk);
    loader.loadSkipFlipped(2595, 2711, 2807, fBronzeMiner.fCarry);
    loader.loadSkipFlipped(2595, 2807, 2887, fBronzeMiner.fCollect);

    for(int i = 2691; i < 2699; i++) {
        loader.load(2595, i, fBronzeMiner.fDie);
    }
}

void eCharacterTextures::loadArtisan() {
    if(fArtisanLoaded) return;
    fArtisanLoaded = true;
    if(loadPersonHD(fArtisan, {{"build", &fArtisan.fBuild}, {"buildstanding", &fArtisan.fBuildStanding}}, fRenderer, fTileH, "artisan")) return;   // art/characters/people/people3.py
    const auto& sds = spriteData(fTileH,
                                 eArtisanSpriteData15,
                                 eArtisanSpriteData30,
                                 eArtisanSpriteData45,
                                 eArtisanSpriteData60);
    eSpriteLoader loader(fTileH, "artisan", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(1545, 1545, 1641, fArtisan.fWalk);
    loader.loadSkipFlipped(1545, 1649, 1721, fArtisan.fBuild);
    loader.loadSkipFlipped(1545, 1721, 1793, fArtisan.fBuildStanding);

    for(int i = 1641; i < 1649; i++) {
        loader.load(1545, i, fArtisan.fDie);
    }
}

void eCharacterTextures::loadFoodVendor() {
    if(fFoodVendorLoaded) return;
    fFoodVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eFoodVendorSpriteData15,
                                 eFoodVendorSpriteData30,
                                 eFoodVendorSpriteData45,
                                 eFoodVendorSpriteData60);
    eSpriteLoader loader(fTileH, "foodVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fFoodVendor, 2887, loader);
}

void eCharacterTextures::loadFleeceVendor() {
    if(fFleeceVendorLoaded) return;
    fFleeceVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eFleeceVendorSpriteData15,
                                 eFleeceVendorSpriteData30,
                                 eFleeceVendorSpriteData45,
                                 eFleeceVendorSpriteData60);
    eSpriteLoader loader(fTileH, "fleeceVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fFleeceVendor, 1897, loader);
}

void eCharacterTextures::loadOilVendor() {
    if(fOilVendorLoaded) return;
    fOilVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eOilVendorSpriteData15,
                                 eOilVendorSpriteData30,
                                 eOilVendorSpriteData45,
                                 eOilVendorSpriteData60);
    eSpriteLoader loader(fTileH, "oilVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fOilVendor, 5297, loader);
}

void eCharacterTextures::loadWineVendor() {
    if(fWineVendorLoaded) return;
    fWineVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eWineVendorSpriteData15,
                                 eWineVendorSpriteData30,
                                 eWineVendorSpriteData45,
                                 eWineVendorSpriteData60);
    eSpriteLoader loader(fTileH, "wineVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fWineVendor, 5401, loader);
}

void eCharacterTextures::loadArmsVendor() {
    if(fArmsVendorLoaded) return;
    fArmsVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eArmsVendorSpriteData15,
                                 eArmsVendorSpriteData30,
                                 eArmsVendorSpriteData45,
                                 eArmsVendorSpriteData60);
    eSpriteLoader loader(fTileH, "armsVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fArmsVendor, 2105, loader);
}

void eCharacterTextures::loadHorseVendor() {
    if(fHorseVendorLoaded) return;
    fHorseVendorLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eHorseVendorSpriteData15,
                                 eHorseVendorSpriteData30,
                                 eHorseVendorSpriteData45,
                                 eHorseVendorSpriteData60);
    eSpriteLoader loader(fTileH, "horseVendor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fHorseVendor, 1129, loader);
}

void eCharacterTextures::loadSheep() {
    if(fSheepLoaded) return;
    fSheepLoaded = true;

    if(!loadAnimalHD(fFleecedSheep, &fFleecedSheep.fFight, &fFleecedSheep.fLayDown,
                     fRenderer, fTileH, "sheep_fleeced")) {
        const auto& sds = spriteData(fTileH,
                                     eFleecedSheepSpriteData15,
                                     eFleecedSheepSpriteData30,
                                     eFleecedSheepSpriteData45,
                                     eFleecedSheepSpriteData60);
        eSpriteLoader loader(fTileH, "fleecedSheep", sds,
                             &eSprMainOffset, fRenderer);
        loader.loadSkipFlipped(3183, 3183, 3279, fFleecedSheep.fWalk);
        loader.loadSkipFlipped(3183, 3287, 3351, fFleecedSheep.fFight);
        loader.loadSkipFlipped(3183, 3351, 3415, fFleecedSheep.fLayDown);

        for(int i = 3279; i < 3287; i++) {
            loader.load(3183, i, fFleecedSheep.fDie);
        }
    }

    if(!loadAnimalHD(fNudeSheep, &fNudeSheep.fFight, &fNudeSheep.fLayDown,
                     fRenderer, fTileH, "sheep_nude")) {
        const auto& sds = spriteData(fTileH,
                                     eNudeSheepSpriteData15,
                                     eNudeSheepSpriteData30,
                                     eNudeSheepSpriteData45,
                                     eNudeSheepSpriteData60);
        eSpriteLoader loader(fTileH, "nudeSheep", sds,
                             &eSprMainOffset, fRenderer);
        loader.loadSkipFlipped(7873, 7873, 7969, fNudeSheep.fWalk);
        loader.loadSkipFlipped(7873, 7977, 8041, fNudeSheep.fFight);
        loader.loadSkipFlipped(7873, 8041, 8105, fNudeSheep.fLayDown);

        for(int i = 7969; i < 7977; i++) {
            loader.load(7873, i, fNudeSheep.fDie);
        }
    }
}

void eCharacterTextures::loadHorse() {
    if(fHorseLoaded) return;
    fHorseLoaded = true;
    const auto& sds = spriteData(fTileH,
                                 eHorseSpriteData15,
                                 eHorseSpriteData30,
                                 eHorseSpriteData45,
                                 eHorseSpriteData60);
    eSpriteLoader loader(fTileH, "horse", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(5001, 5001, 5097, fHorse.fWalk);
    loader.loadSkipFlipped(5001, 5105, 5297, fHorse.fStand);

    for(int i = 5097; i < 5105; i++) {
        loader.load(5001, i, fHorse.fDie);
    }
}

void eCharacterTextures::loadShepherd() {
    if(fShepherdLoaded) return;
    fShepherdLoaded = true;
    if(loadPersonHD(fShepherd, {{"carry", &fShepherd.fCarry}, {"collect", nullptr, &fShepherd.fCollect}, {"fight", nullptr, &fShepherd.fFight}}, fRenderer, fTileH, "shepherd")) return;
    const auto& sds = spriteData(fTileH,
                                 eShepherdSpriteData15,
                                 eShepherdSpriteData30,
                                 eShepherdSpriteData45,
                                 eShepherdSpriteData60);
    eSpriteLoader loader(fTileH, "shepherd", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(3415, 3415, 3511, fShepherd.fWalk);
    for(int i = 3519; i < 3531; i++) {
        loader.load(3415, i, fShepherd.fCollect);
    }
    loader.loadSkipFlipped(3415, 3531, 3627, fShepherd.fCarry);

    for(int i = 3627; i < 3637; i++) {
        loader.load(3415, i, fShepherd.fFight);
    }
    for(int i = 3511; i < 3519; i++) {
        loader.load(3415, i, fShepherd.fDie);
    }
}

void eCharacterTextures::loadMarbleMiner() {
    if(fMarbleMinerLoaded) return;
    fMarbleMinerLoaded = true;
    if(loadPersonHD(fMarbleMiner, {{"collect", &fMarbleMiner.fCollect}}, fRenderer, fTileH, "marbleminer")) return;   // art/characters/people/people3.py
    const auto& sds = spriteData(fTileH,
                                 eMarbleMinerSpriteData15,
                                 eMarbleMinerSpriteData30,
                                 eMarbleMinerSpriteData45,
                                 eMarbleMinerSpriteData60);
    eSpriteLoader loader(fTileH, "marbleMiner", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(11044, 11044, 11140, fMarbleMiner.fWalk);
    loader.loadSkipFlipped(11044, 11148, 11228, fMarbleMiner.fCollect);

    for(int i = 11140; i < 11148; i++) {
        loader.load(11044, i, fMarbleMiner.fDie);
    }
}

void eCharacterTextures::loadSilverMiner() {
    if(fSilverMinerLoaded) return;
    fSilverMinerLoaded = true;
    if(loadPersonHD(fSilverMiner, {{"collect", &fSilverMiner.fCollect}, {"carry", &fSilverMiner.fCarry}}, fRenderer, fTileH, "silverminer")) return;   // art/characters/people/people3.py
    const auto& sds = spriteData(fTileH,
                                 eSilverMinerSpriteData15,
                                 eSilverMinerSpriteData30,
                                 eSilverMinerSpriteData45,
                                 eSilverMinerSpriteData60);
    eSpriteLoader loader(fTileH, "silverMiner", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(3741, 3741, 3837, fSilverMiner.fWalk);
    loader.loadSkipFlipped(3741, 3857, 3953, fSilverMiner.fCarry);
    loader.loadSkipFlipped(3741, 3953, 4033, fSilverMiner.fCollect);

    for(int i = 3837; i < 3845; i++) {
        loader.load(3741, i, fSilverMiner.fDie);
    }
}

void eCharacterTextures::loadArcher() {
    if(fArcherLoaded) return;
    fArcherLoaded = true;
    if(loadPersonHD(fArcher, {{"fight", &fArcher.fFight}, {"patrol", &fArcher.fPatrol}}, fRenderer, fTileH, "archer")) return;   // art/characters/people/people4.py
    const auto& sds = spriteData(fTileH,
                                 eArcherSpriteData15,
                                 eArcherSpriteData30,
                                 eArcherSpriteData45,
                                 eArcherSpriteData60);
    eSpriteLoader loader(fTileH, "archer", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(4033, 4033, 4129, fArcher.fWalk);
    loader.loadSkipFlipped(4033, 4137, 4233, fArcher.fFight);
    loader.loadSkipFlipped(4033, 4233, 4329, fArcher.fPatrol);

    for(int i = 4129; i < 4137; i++) {
        loader.load(4033, i, fArcher.fDie);
    }
}

void eCharacterTextures::loadLumberjack() {
    if(fLumberjackLoaded) return;
    fLumberjackLoaded = true;
    if(loadPersonHD(fLumberjack, {{"collect", &fLumberjack.fCollect}, {"carry", &fLumberjack.fCarry}}, fRenderer, fTileH, "lumberjack")) return;   // art/characters/people/people3.py
    const auto& sds = spriteData(fTileH,
                                 eLumberjackSpriteData15,
                                 eLumberjackSpriteData30,
                                 eLumberjackSpriteData45,
                                 eLumberjackSpriteData60);
    eSpriteLoader loader(fTileH, "lumberjack", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(4329, 4329, 4425, fLumberjack.fWalk);
    loader.loadSkipFlipped(4329, 4433, 4529, fLumberjack.fCollect);
    loader.loadSkipFlipped(4329, 4529, 4625, fLumberjack.fCarry);

    for(int i = 4425; i < 4433; i++) {
        loader.load(4329, i, fLumberjack.fDie);
    }
}

void eCharacterTextures::loadTaxCollector() {
    if(fTaxCollectorLoaded) return;
    fTaxCollectorLoaded = true;
    if(loadPersonHD(fTaxCollector, {}, fRenderer, fTileH, "taxcollector")) return;
    const auto& sds = spriteData(fTileH,
                                 eTaxCollectorSpriteData15,
                                 eTaxCollectorSpriteData30,
                                 eTaxCollectorSpriteData45,
                                 eTaxCollectorSpriteData60);
    eSpriteLoader loader(fTileH, "taxCollector", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fTaxCollector, 4625, loader);
}

namespace {
bool loadCharacterHD(eBasicCharacterTextures& tex, SDL_Renderer* renderer, int tileH,
                     const std::string& name);
void loadCartHD(std::vector<std::shared_ptr<eTexture>>& cells,
                SDL_Renderer* renderer, const int tileH);
}

void eCharacterTextures::loadTransporter() {
    if(fTransporterLoaded) return;
    fTransporterLoaded = true;
    if(loadCharacterHD(fTransporter, fRenderer, fTileH, "transporter")) return;
    const auto& sds = spriteData(fTileH,
                                 eTransporterSpriteData15,
                                 eTransporterSpriteData30,
                                 eTransporterSpriteData45,
                                 eTransporterSpriteData60);
    eSpriteLoader loader(fTileH, "transporter", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fTransporter, 4729, loader);
}

void eCharacterTextures::loadGrower() {
    if(fGrowerLoaded) return;
    fGrowerLoaded = true;
    if(!loadPersonHD(fGrower, {{"workgrapes", &fGrower.fWorkOnGrapes}, {"workolives", &fGrower.fWorkOnOlives},
                               {"collectgrapes", &fGrower.fCollectGrapes}, {"collectolives", &fGrower.fCollectOlives}},
                     fRenderer, fTileH, "grower")) {
        const auto& sds = spriteData(fTileH,
                                     eGrowerSpriteData15,
                                     eGrowerSpriteData30,
                                     eGrowerSpriteData45,
                                     eGrowerSpriteData60);
        eSpriteLoader loader(fTileH, "grower", sds,
                             &eSprMainOffset, fRenderer);

        loader.loadSkipFlipped(5505, 5505, 5601, fGrower.fWalk);
        loader.loadSkipFlipped(5505, 5609, 5689, fGrower.fWorkOnGrapes);
        loader.loadSkipFlipped(5505, 5689, 5769, fGrower.fWorkOnOlives);
        loader.loadSkipFlipped(5505, 5769, 5849, fGrower.fCollectGrapes);
        loader.loadSkipFlipped(5505, 5849, 5929, fGrower.fCollectOlives);

        for(int i = 5601; i < 5609; i++) {
            loader.load(5505, i, fGrower.fDie);
        }
    }
    loadOrangeTender();
}

void eCharacterTextures::loadTrader() {
    if(fTraderLoaded) return;
    fTraderLoaded = true;
    if(loadPersonHD(fTrader, {}, fRenderer, fTileH, "trader")) return;
    const auto& sds = spriteData(fTileH,
                                 eTraderSpriteData15,
                                 eTraderSpriteData30,
                                 eTraderSpriteData45,
                                 eTraderSpriteData60);
    eSpriteLoader loader(fTileH, "trader", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fTrader, 5929, loader);
}

void eCharacterTextures::loadWaterDistributor() {
    if(fWaterDistributorLoaded) return;
    fWaterDistributorLoaded = true;
    if(loadPersonHD(fWaterDistributor, {}, fRenderer, fTileH, "waterdistributor")) return;
    const auto& sds = spriteData(fTileH,
                                 eWaterDistributorSpriteData15,
                                 eWaterDistributorSpriteData30,
                                 eWaterDistributorSpriteData45,
                                 eWaterDistributorSpriteData60);
    eSpriteLoader loader(fTileH, "waterDistributor", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fWaterDistributor, 6737, loader);
}

void eCharacterTextures::loadRockThrower() {
    if(fRockThrowerLoaded) return;
    fRockThrowerLoaded = true;
    if(loadPersonHD(fRockThrower, {{"fight", &fRockThrower.fFight}, {"fight2", &fRockThrower.fFight2}}, fRenderer, fTileH, "rockthrower")) return;   // art/characters/people/people4.py
    const auto& sds = spriteData(fTileH,
                                 eRockThrowerSpriteData15,
                                 eRockThrowerSpriteData30,
                                 eRockThrowerSpriteData45,
                                 eRockThrowerSpriteData60);
    eSpriteLoader loader(fTileH, "rockThrower", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(6841, 6841, 6937, fRockThrower.fWalk);
    loader.loadSkipFlipped(6841, 6945, 7041, fRockThrower.fFight2);
    loader.loadSkipFlipped(6841, 7041, 7105, fRockThrower.fFight);

    for(int i = 6937; i < 6945; i++) {
        loader.load(6841, i, fRockThrower.fDie);
    }
}

void eCharacterTextures::loadHoplite() {
    if(fHopliteLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eHopliteSpriteData15,
                                 eHopliteSpriteData30,
                                 eHopliteSpriteData45,
                                 eHopliteSpriteData60);
    fHopliteLoaded = true;
    if(loadPersonHD(fHoplite, {{"fight", &fHoplite.fFight}}, fRenderer, fTileH, "hoplite")) return;   // art/characters/people/people4.py
    eSpriteLoader loader(fTileH, "hoplite", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(7105, 7105, 7201, fHoplite.fWalk);
    loader.loadSkipFlipped(7105, 7209, 7273, fHoplite.fFight);

    for(int i = 7201; i < 7209; i++) {
        loader.load(7105, i, fHoplite.fDie);
    }
}

void eCharacterTextures::loadHorseman() {
    if(fHorsemanLoaded) return;
    fHorsemanLoaded = true;
    if(loadPersonHD(fHorseman, {{"fight", &fHorseman.fFight}}, fRenderer, fTileH, "horseman")) return;   // art/characters/people/people4.py

    const auto& sds = spriteData(fTileH,
                                 eHorsemanSpriteData15,
                                 eHorsemanSpriteData30,
                                 eHorsemanSpriteData45,
                                 eHorsemanSpriteData60);
    eSpriteLoader loader(fTileH, "horseman", sds,
                         &eSprMainOffset, fRenderer);
    loader.loadSkipFlipped(7273, 7273, 7369, fHorseman.fWalk);
    loader.loadSkipFlipped(7273, 7377, 7473, fHorseman.fFight);

    for(int i = 7369; i < 7377; i++) {
        loader.load(7273, i, fHorseman.fDie);
    }
}

namespace {
// Remastered walker atlas in Textures/Remastered/characters/<name>/.
// V2: 24 walk columns × 8 rows, paired 12-frame idle rows, then death.
// Also accept the 12×9 layout (12 walk frames, death in row 8).
bool loadCharacterHD(eBasicCharacterTextures& tex, SDL_Renderer* renderer, int tileH,
                     const std::string& name) {
    const auto base=eGameDir::texturesDir()+"Remastered/characters/"+name+"/"+std::to_string(tileH);
    const auto sheet=std::make_shared<eTexture>();
    const int cell=160*tileH/60;
    int frames=0,deathRow=8;
    for(const int density : {2,1}) {
        const auto path=base+(density==2?"@2x.png":".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer,path)) continue;
        if(sheet->width()==24*cell*density && sheet->height()==13*cell*density) {
            frames=24;deathRow=12;
        } else if(sheet->width()==12*cell*density && sheet->height()==9*cell*density) {
            frames=12;deathRow=8;
        } else continue;
        sheet->setDensity(density);sheet->setScaleMode(SDL_ScaleModeLinear);break;
    }
    if(!frames) return false;
    const auto add=[&](eTextureCollection& collection,int column,int row) {
        auto& t=collection.addTexture();
        t->setParentTexture({column*cell,row*cell,cell,cell},sheet);t->setOffset(40,60);
    };
    for(int direction=0;direction<8;++direction) {
        tex.fWalk.emplace_back(renderer);
        for(int f=0;f<frames;++f) add(tex.fWalk.back(),f,direction);
        if(frames==24) {
            tex.fIdle.emplace_back(renderer);
            for(int f=0;f<12;++f) add(tex.fIdle.back(),12*(direction%2)+f,8+direction/2);
        }
    }
    for(int f=0;f<8;++f) add(tex.fDie,f,deathRow);
    return true;
}
}

bool loadStatesHD(const std::vector<ePersonHDSlot>& slots, SDL_Renderer* renderer, int tileH,
                  const std::string& name) {
    if(tileH != 15 && tileH != 30) return false;
    const auto dir = eGameDir::texturesDir() + "Remastered/characters/" + name + "/";
    std::ifstream meta(dir + "person.txt");
    int cols, x0, y0, w, h;
    if(!(meta >> cols >> x0 >> y0 >> w >> h) || cols <= 0) return false;
    struct eState { std::string fName; int fFrames; int fHeads; };
    std::vector<eState> states;
    eState st;
    while(meta >> st.fName >> st.fFrames >> st.fHeads) states.push_back(st);
    const auto slotFor = [&](const std::string& n) -> const ePersonHDSlot* {
        for(const auto& s : slots) if(n == s.fState) return &s;
        return nullptr;
    };
    int total = 0;
    for(const auto& s : states) {
        const auto slot = slotFor(s.fName);
        if(s.fFrames <= 0 || !slot || (s.fHeads != 1 && s.fHeads != 8)) return false;
        if(s.fHeads == 8 ? !slot->fDirs : !(slot->fSingle || slot->fDirs)) return false;
        total += s.fFrames*s.fHeads;
    }
    for(const auto& s : slots) {
        bool found = false;
        for(const auto& t : states) found = found || t.fName == s.fState;
        if(!found) return false;
    }
    const int rows = (total + cols - 1)/cols;
    const int cw = w*tileH/60;
    const int ch = h*tileH/60;
    const auto sheet = std::make_shared<eTexture>();
    bool loaded = false;
    for(const int density : {2, 1}) {
        const auto path = dir + std::to_string(tileH) + (density == 2 ? "@2x.png" : ".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer, path)) continue;
        if(sheet->width() != cols*cw*density || sheet->height() != rows*ch*density) continue;
        sheet->setDensity(density);
        sheet->setScaleMode(SDL_ScaleModeLinear);
        loaded = true;
        break;
    }
    if(!loaded) return false;
    int i = 0;
    const auto cell = [&](eTextureCollection& coll, const int idx) {
        auto& t = coll.addTexture();
        t->setParentTexture({idx%cols*cw, idx/cols*ch, cw, ch}, sheet);
        t->setOffset((80 - x0)/2, (120 - y0)/2);   // ground anchor, tile-height-30 units
    };
    for(const auto& s : states) {
        const auto slot = slotFor(s.fName);
        if(s.fHeads == 8 || !slot->fSingle) {
            auto& v = *slot->fDirs;
            v.clear();
            for(int d = 0; d < 8; d++) {
                v.emplace_back(renderer);
                const int first = s.fHeads == 8 ? i + d*s.fFrames : i;
                for(int f = 0; f < s.fFrames; f++) cell(v.back(), first + f);
            }
        } else {
            for(int f = 0; f < s.fFrames; f++) cell(*slot->fSingle, i + f);
        }
        i += s.fFrames*s.fHeads;
    }
    return true;
}

bool loadPersonHD(eBasicCharacterTextures& tex, const std::vector<ePersonHDSlot>& slots,
                  SDL_Renderer* renderer, int tileH, const std::string& name) {
    if(tileH != 15 && tileH != 30) return false;
    const auto dir = eGameDir::texturesDir() + "Remastered/characters/" + name + "/";
    std::ifstream meta(dir + "person.txt");
    int cols, x0, y0, w, h;
    if(!(meta >> cols >> x0 >> y0 >> w >> h) || cols <= 0) return false;
    struct eState { std::string fName; int fFrames; int fHeads; };
    std::vector<eState> states;
    eState st;
    while(meta >> st.fName >> st.fFrames >> st.fHeads) states.push_back(st);
    // Every state needs a destination of the right shape, and every slot a state.
    const auto slotFor = [&](const std::string& n) -> const ePersonHDSlot* {
        for(const auto& s : slots) if(n == s.fState) return &s;
        return nullptr;
    };
    int total = 0;
    bool walk = false, die = false;
    for(const auto& s : states) {
        if(s.fFrames <= 0 || (s.fHeads != 1 && s.fHeads != 8)) return false;
        if(s.fName == "walk") { if(s.fHeads != 8) return false; walk = true; }
        else if(s.fName == "die") { if(s.fHeads != 1) return false; die = true; }
        else {
            const auto slot = slotFor(s.fName);
            if(!slot || (s.fHeads == 8 ? !slot->fDirs : !slot->fSingle)) return false;
        }
        total += s.fFrames*s.fHeads;
    }
    if(!walk || !die) return false;
    for(const auto& s : slots) {
        bool found = false;
        for(const auto& t : states) found = found || t.fName == s.fState;
        if(!found) return false;
    }
    const int rows = (total + cols - 1)/cols;
    const int cw = w*tileH/60;
    const int ch = h*tileH/60;
    const auto sheet = std::make_shared<eTexture>();
    bool loaded = false;
    for(const int density : {2, 1}) {
        const auto path = dir + std::to_string(tileH) + (density == 2 ? "@2x.png" : ".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer, path)) continue;
        if(sheet->width() != cols*cw*density || sheet->height() != rows*ch*density) continue;
        sheet->setDensity(density);
        sheet->setScaleMode(SDL_ScaleModeLinear);
        loaded = true;
        break;
    }
    if(!loaded) return false;
    int i = 0;
    const auto next = [&](eTextureCollection& coll) {
        auto& t = coll.addTexture();
        t->setParentTexture({i%cols*cw, i/cols*ch, cw, ch}, sheet);
        t->setOffset((80 - x0)/2, (120 - y0)/2);   // ground anchor, tile-height-30 units
        i++;
    };
    for(const auto& s : states) {
        if(s.fHeads == 8) {
            auto& v = s.fName == "walk" ? tex.fWalk : *slotFor(s.fName)->fDirs;
            v.clear();
            for(int d = 0; d < 8; d++) {
                v.emplace_back(renderer);
                for(int f = 0; f < s.fFrames; f++) next(v.back());
            }
        } else {
            auto& c = s.fName == "die" ? tex.fDie : *slotFor(s.fName)->fSingle;
            for(int f = 0; f < s.fFrames; f++) next(c);
        }
    }
    return true;
}

bool loadAnimalHD(eBasicCharacterTextures& tex,
                  std::vector<eTextureCollection>* fight,
                  std::vector<eTextureCollection>* lay,
                  SDL_Renderer* renderer, int tileH,
                  const std::string& name) {
    if(tileH != 15 && tileH != 30) return false;
    const auto dir = eGameDir::texturesDir() + "Remastered/characters/" + name + "/";
    std::ifstream meta(dir + "anim.txt");
    int nw, nf, nl, nd, cols, x0, y0, w, h;
    if(!(meta >> nw >> nf >> nl >> nd >> cols >> x0 >> y0 >> w >> h)) return false;
    if(nw <= 0 || nd <= 0 || cols <= 0 || nf < 0 || nl < 0 ||
       (nf > 0 && !fight) || (nl > 0 && !lay)) return false;
    const int total = 8*(nw + nf + nl) + nd;
    const int rows = (total + cols - 1)/cols;
    const int cw = w*tileH/60;
    const int ch = h*tileH/60;
    const auto sheet = std::make_shared<eTexture>();
    bool loaded = false;
    for(const int density : {2, 1}) {
        const auto path = dir + std::to_string(tileH) + (density == 2 ? "@2x.png" : ".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer, path)) continue;
        if(sheet->width() != cols*cw*density || sheet->height() != rows*ch*density) continue;
        sheet->setDensity(density);
        sheet->setScaleMode(SDL_ScaleModeLinear);
        loaded = true;
        break;
    }
    if(!loaded) return false;
    int i = 0;
    const auto next = [&](eTextureCollection& coll) {
        auto& t = coll.addTexture();
        t->setParentTexture({i%cols*cw, i/cols*ch, cw, ch}, sheet);
        t->setOffset((80 - x0)/2, (120 - y0)/2);   // ground anchor, tile-height-30 units
        i++;
    };
    const auto rowsOf = [&](std::vector<eTextureCollection>& v, const int n) {
        v.clear();
        for(int d = 0; d < 8; d++) {
            v.emplace_back(renderer);
            for(int f = 0; f < n; f++) next(v.back());
        }
    };
    rowsOf(tex.fWalk, nw);
    if(fight) rowsOf(*fight, nf);
    if(lay) rowsOf(*lay, nl);
    for(int f = 0; f < nd; f++) next(tex.fDie);
    return true;
}

int eCharacterTextures::sCartHDRow(const eResourceType type, const int level) {
    // Row order written by art/characters/transporter/package_sprites.py.
    static const eResourceType food[] = {
        eResourceType::urchin, eResourceType::fish, eResourceType::meat,
        eResourceType::cheese, eResourceType::carrots, eResourceType::onions,
        eResourceType::wheat, eResourceType::oranges, eResourceType::grapes,
        eResourceType::olives};
    static const eResourceType goods[] = {
        eResourceType::wine, eResourceType::oliveOil, eResourceType::fleece,
        eResourceType::bronze, eResourceType::orichalc, eResourceType::armor};
    for(int i = 0; i < 10; i++) {
        if(food[i] == type) return 1 + 3*i + std::clamp(level, 0, 2);
    }
    for(int i = 0; i < 6; i++) {
        if(goods[i] == type) return 31 + 2*i + std::clamp(level, 0, 1);
    }
    return 0;
}

namespace {
// Handcart atlas: 8 orientation columns x <rows> cargo rows of <w>x<h> logical
// cells (tile height 60 units), cut from the 160 px canvas at (x, y). cart.txt
// holds "rows x y w h"; the ground anchor sits at (80, 120) of that canvas.
void loadCartHD(std::vector<std::shared_ptr<eTexture>>& cells,
                SDL_Renderer* renderer, const int tileH) {
    const auto dir = eGameDir::texturesDir() + "Remastered/characters/cart/";
    std::ifstream meta(dir + "cart.txt");
    int rows = 0, x0 = 0, y0 = 0, w = 0, h = 0;
    if(!(meta >> rows >> x0 >> y0 >> w >> h) || rows != 43) return;
    const int cw = w*tileH/60;
    const int ch = h*tileH/60;
    const auto sheet = std::make_shared<eTexture>();
    bool loaded = false;
    for(const int density : {2, 1}) {
        const auto path = dir + std::to_string(tileH) + (density == 2 ? "@2x.png" : ".png");
        if(!std::filesystem::exists(path) || !sheet->load(renderer, path)) continue;
        if(sheet->width() != 8*cw*density || sheet->height() != rows*ch*density) continue;
        sheet->setDensity(density);
        sheet->setScaleMode(SDL_ScaleModeLinear);
        loaded = true;
        break;
    }
    if(!loaded) return;
    // Offsets are in tile-height-30 units: the anchor within the cell, halved.
    const int ox = (80 - x0)/2;
    const int oy = (120 - y0)/2;
    cells.clear();
    for(int row = 0; row < rows; row++) {
        for(int o = 0; o < 8; o++) {
            auto t = std::make_shared<eTexture>();
            t->setParentTexture({o*cw, row*ch, cw, ch}, sheet);
            t->setOffset(ox, oy);
            cells.push_back(std::move(t));
        }
    }
}
}

void eCharacterTextures::loadHealer() {
    if(fHealerLoaded) return;
    fHealerLoaded = true;
    if(loadCharacterHD(fHealer, fRenderer, fTileH, "physician")) return;
    const auto& sds = spriteData(fTileH,
                                 eHealerSpriteData15,
                                 eHealerSpriteData30,
                                 eHealerSpriteData45,
                                 eHealerSpriteData60);
    eSpriteLoader loader(fTileH, "healer", sds,
                         &eSprMainOffset, fRenderer);

    loadBasicTexture(fHealer, 7473, loader);
}

void eCharacterTextures::loadCart() {
    if(fCartLoaded) return;
    fCartLoaded = true;
    {
        const auto& sds = spriteData(fTileH,
                                     eCartSpriteData15,
                                     eCartSpriteData30,
                                     eCartSpriteData45,
                                     eCartSpriteData60);
        eSpriteLoader loader(fTileH, "cart", sds,
                             &eSprMainOffset, fRenderer);

        loader.loadSkipFlipped(8428, 8428, 8436, fEmptyCart);
        loader.loadSkipFlipped(8428, 8436, 8460, fUrchinCart);
        loader.loadSkipFlipped(8428, 8460, 8484, fFishCart);
        loader.loadSkipFlipped(8428, 8484, 8508, fMeatCart);
        loader.loadSkipFlipped(8428, 8508, 8532, fCheeseCart);
        loader.loadSkipFlipped(8428, 8532, 8556, fCarrotsCart);
        loader.loadSkipFlipped(8428, 8556, 8580, fOnionsCart);
        loader.loadSkipFlipped(8428, 8580, 8604, fWheatCart);
        loader.loadSkipFlipped(8428, 8604, 8620, fBronzeCart);
        loader.loadSkipFlipped(8428, 8620, 8644, fGrapesCart);
        loader.loadSkipFlipped(8428, 8644, 8668, fOlivesCart);
        loader.loadSkipFlipped(8428, 8668, 8684, fFleeceCart);
        loader.loadSkipFlipped(8428, 8684, 8700, fArmorCart);
        loader.loadSkipFlipped(8428, 8700, 8716, fOliveOilCart);
        loader.loadSkipFlipped(8428, 8716, 8732, fWineCart);
    }
    loadOrangesCart();
    loadOrichalcCart();
    loadCartHD(fCartHD, fRenderer, fTileH);
}

void eCharacterTextures::loadBoar() {
    if(fBoarLoaded) return;
    fBoarLoaded = true;
    if(loadAnimalHD(fBoar, &fBoar.fFight, &fBoar.fLayDown, fRenderer, fTileH,
                    "boar")) return;
    const auto& sds = spriteData(fTileH,
                                 eBoarSpriteData15,
                                 eBoarSpriteData30,
                                 eBoarSpriteData45,
                                 eBoarSpriteData60);
    eSpriteLoader loader(fTileH, "boar", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(10124, 10124, 10220, fBoar.fWalk);
    loader.loadSkipFlipped(10124, 10228, 10356, fBoar.fFight);
    loader.loadSkipFlipped(10124, 10356, 10420, fBoar.fLayDown);

    for(int i = 10220; i < 10228; i++) {
        loader.load(10124, i, fBoar.fDie);
    }
}

void eCharacterTextures::loadGymnast() {
    if(fGymnastLoaded) return;
    fGymnastLoaded = true;
    if(loadPersonHD(fGymnast, {}, fRenderer, fTileH, "gymnast")) return;

    const auto& sds = spriteData(fTileH,
                                 eGymnastSpriteData15,
                                 eGymnastSpriteData30,
                                 eGymnastSpriteData45,
                                 eGymnastSpriteData60);
    eSpriteLoader loader(fTileH, "gymnast", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fGymnast, 10588, loader);
}

void eCharacterTextures::loadCompetitor() {
    if(fCompetitorLoaded) return;
    fCompetitorLoaded = true;
    if(loadPersonHD(fCompetitor, {}, fRenderer, fTileH, "competitor")) return;

    const auto& sds = spriteData(fTileH,
                                 eCompetitorSpriteData15,
                                 eCompetitorSpriteData30,
                                 eCompetitorSpriteData45,
                                 eCompetitorSpriteData60);
    eSpriteLoader loader(fTileH, "competitor", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fCompetitor, 10692, loader);
}

void eCharacterTextures::loadGoat() {
    if(fGoatLoaded) return;
    fGoatLoaded = true;
    if(loadAnimalHD(fGoat, &fGoat.fFight, &fGoat.fLayDown, fRenderer, fTileH,
                    "goat")) return;

    const auto& sds = spriteData(fTileH,
                                 eGoatSpriteData15,
                                 eGoatSpriteData30,
                                 eGoatSpriteData45,
                                 eGoatSpriteData60);
    eSpriteLoader loader(fTileH, "goat", sds,
                         &eSprMainOffset, fRenderer);
    loader.loadSkipFlipped(11228, 11228, 11324, fGoat.fWalk);
    loader.loadSkipFlipped(11228, 11332, 11460, fGoat.fFight);
    loader.loadSkipFlipped(11228, 11460, 11524, fGoat.fLayDown);

    for(int i = 11324; i < 11332; i++) {
        loader.load(11228, i, fGoat.fDie);
    }
}

void eCharacterTextures::loadWolf() {
    if(fWolfLoaded) return;
    fWolfLoaded = true;
    if(loadAnimalHD(fWolf, &fWolf.fFight, &fWolf.fLayDown, fRenderer, fTileH,
                    "wolf")) return;

    const auto& sds = spriteData(fTileH,
                                 eWolfSpriteData15,
                                 eWolfSpriteData30,
                                 eWolfSpriteData45,
                                 eWolfSpriteData60);
    eSpriteLoader loader(fTileH, "wolf", sds,
                         &eSprMainOffset, fRenderer);
    loader.loadSkipFlipped(11524, 11524, 11620, fWolf.fWalk);
    loader.loadSkipFlipped(11524, 11628, 11756, fWolf.fFight);
    loader.loadSkipFlipped(11524, 11756, 11820, fWolf.fLayDown);

    for(int i = 11620; i < 11628; i++) {
        loader.load(11524, i, fWolf.fDie);
    }
}

void eCharacterTextures::loadHunter() {
    if(fHunterLoaded) return;
    fHunterLoaded = true;
    if(!loadPersonHD(fHunter, {{"collect", &fHunter.fCollect}, {"carry", &fHunter.fCarry}},
                     fRenderer, fTileH, "hunter")) {

        const auto& sds = spriteData(fTileH,
                                     eHunterSpriteData15,
                                     eHunterSpriteData30,
                                     eHunterSpriteData45,
                                     eHunterSpriteData60);
        eSpriteLoader loader(fTileH, "hunter", sds,
                             &eSprMainOffset, fRenderer);
        loader.loadSkipFlipped(11820, 11820, 11916, fHunter.fWalk);
        loader.loadSkipFlipped(11820, 11924, 12019, fHunter.fCollect);
        loader.loadSkipFlipped(11820, 12032, 12128, fHunter.fCarry);

        for(int i = 11916; i < 11924; i++) {
            loader.load(11820, i, fHunter.fDie);
        }
    }
    loadDeerHunter();
}

void eCharacterTextures::loadPhilosopher() {
    if(fPhilosopherLoaded) return;
    fPhilosopherLoaded = true;
    if(loadPersonHD(fPhilosopher, {}, fRenderer, fTileH, "philosopher")) return;

    const auto& sds = spriteData(fTileH,
                                 ePhilosopherSpriteData15,
                                 ePhilosopherSpriteData30,
                                 ePhilosopherSpriteData45,
                                 ePhilosopherSpriteData60);
    eSpriteLoader loader(fTileH, "philosopher", sds,
                         &eSprMainOffset, fRenderer);
    loadBasicTexture(fPhilosopher, 12128, loader);
}

void eCharacterTextures::loadUrchinGatherer() {
    if(fUrchinGathererLoaded) return;
    fUrchinGathererLoaded = true;
    {   // HD: the "walk" state of the atlas is his wading / swimming.
        eBasicCharacterTextures hd(fRenderer);
        auto& u = fUrchinGatherer;
        if(loadPersonHD(hd, {{"collect", &u.fCollect}, {"carry", &u.fCarry}, {"deposit", &u.fDeposit}},
                        fRenderer, fTileH, "urchin")) {
            u.fSwim = std::move(hd.fWalk);
            for(int i = 0; i < hd.fDie.size(); i++) u.fDie.addTexture() = hd.fDie.getTexture(i);
            return;
        }
    }

    const auto& sds = spriteData(fTileH,
                                 eUrchinGathererSpriteData15,
                                 eUrchinGathererSpriteData30,
                                 eUrchinGathererSpriteData45,
                                 eUrchinGathererSpriteData60);
    eSpriteLoader loader(fTileH, "urchinGatherer", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadSkipFlipped(9508, 9508, 9604, fUrchinGatherer.fSwim);
    loader.loadSkipFlipped(9508, 9604, 9924, fUrchinGatherer.fCollect);
    loader.loadSkipFlipped(9508, 9924, 10020, fUrchinGatherer.fCarry);
    loader.loadSkipFlipped(9508, 10020, 10116, fUrchinGatherer.fDeposit);
    for(int i = 10116; i < 10124; i++) {
        loader.load(9508, i, fUrchinGatherer.fDie);
    }
}

void eCharacterTextures::loadFishingBoat() {
    if(fFishingBoatLoaded) return;
    fFishingBoatLoaded = true;

    const auto& sds = spriteData(fTileH,
                                 eFishingBoatSpriteData15,
                                 eFishingBoatSpriteData30,
                                 eFishingBoatSpriteData45,
                                 eFishingBoatSpriteData60);
    eSpriteLoader loader(fTileH, "fishingBoat", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadBoatSkipFlipped(10796, 10797, 10860, fFishingBoat.fSwim);
    loader.loadSkipFlipped(10796, 10860, 10940, fFishingBoat.fCollect);
    loader.loadSkipFlipped(10796, 10940, 10948, fFishingBoat.fStand);
    loader.loadSkipFlipped(10796, 10948, 11036, fFishingBoat.fDie);
}

// Naval atlases use independent eight-direction sailing and sinking sheets.
// Validate both before publishing: a partial installation must use legacy art.
bool loadShipHD(eTradeBoatTextures& tex, SDL_Renderer* renderer,
                const int tileH, const std::string& name) {
    // Native zoom uses 15/30px tiles (street zoom magnifies 30px). Like the
    // people remaster, avoid preloading unused 45/60px atlases into GPU memory.
    if(tileH != 15 && tileH != 30) return false;
    const auto dir = eGameDir::texturesDir() + "Remastered/ships/" + name + "/";
    const int cell = 448*tileH/60;
    std::shared_ptr<eTexture> sheets[2];
    const int frames[2] = {16, 12};
    const char* states[2] = {"sail", "sink"};
    for(int state=0; state<2; ++state) {
        for(int density : {2, 1}) {
            const auto path = dir + states[state] + "_" + std::to_string(tileH) +
                              (density == 2 ? "@2x.png" : ".png");
            if(!std::filesystem::exists(path)) continue;
            auto sheet = std::make_shared<eTexture>();
            if(!sheet->load(renderer, path) ||
               sheet->width() != frames[state]*cell*density ||
               sheet->height() != 8*cell*density) continue;
            sheet->setDensity(density);
            sheet->setScaleMode(SDL_ScaleModeLinear);
            sheets[state] = sheet;
            break;
        }
        if(!sheets[state]) return false;
    }
    for(int state=0; state<2; ++state) {
        auto& dirs = state == 0 ? tex.fSwim : tex.fDie;
        dirs.clear();
        for(int d=0; d<8; ++d) {
            dirs.emplace_back(renderer);
            for(int f=0; f<frames[state]; ++f) {
                auto& t = dirs.back().addTexture();
                t->setParentTexture({f*cell,d*cell,cell,cell},sheets[state]);
                t->setOffset(-72,-96); // waterline anchor (224,312) at tileH 60
            }
        }
    }
    for(int d=0; d<8; ++d) tex.fStand.addTexture() = tex.fSwim[d].getTexture(0);
    tex.fRemastered = true;
    return true;
}

void eCharacterTextures::loadTradeBoat() {
    if(fTradeBoatLoaded) return;
    fTradeBoatLoaded = true;
    if(loadShipHD(fTradeBoat, fRenderer, fTileH, "trade_ship")) return;

    const auto& sds = spriteData(fTileH,
                                 eTradeBoatSpriteData15,
                                 eTradeBoatSpriteData30,
                                 eTradeBoatSpriteData45,
                                 eTradeBoatSpriteData60);
    eSpriteLoader loader(fTileH, "tradeBoat", sds,
                         &eSprMainOffset, fRenderer);

    loader.loadBoatSkipFlipped(10420, 10421, 10484, fTradeBoat.fSwim);
    loader.loadSkipFlipped(10420, 10484, 10580, fTradeBoat.fDie);
    loader.loadSkipFlipped(10420, 10580, 10588, fTradeBoat.fStand);
}

void eCharacterTextures::loadGreekRockThrower() {
    if(fGreekRockThrowerLoaded) return;
    fGreekRockThrowerLoaded = true;
    if(loadPersonHD(fGreekRockThrower, {{"fight", &fGreekRockThrower.fFight}, {"fight2", &fGreekRockThrower.fFight2}}, fRenderer, fTileH, "greekrockthrower")) return;   // art/characters/people/people10.py

    const auto& sds = spriteData(fTileH,
                                 eGreekRockThrowerSpriteData15,
                                 eGreekRockThrowerSpriteData30,
                                 eGreekRockThrowerSpriteData45,
                                 eGreekRockThrowerSpriteData60);
    eSpriteLoader loader(fTileH, "greekRockThrower", sds,
                         &eZeus_GreekOffset, fRenderer);
    loader.loadSkipFlipped(369, 369, 465, fGreekRockThrower.fWalk);
    loader.loadSkipFlipped(369, 473, 569, fGreekRockThrower.fFight2);
    loader.loadSkipFlipped(369, 569, 633, fGreekRockThrower.fFight);

    for(int i = 465; i < 473; i++) {
        loader.load(369, i, fGreekRockThrower.fDie);
    }
}

void eCharacterTextures::loadGreekHoplite() {
    if(fGreekHopliteLoaded) return;
    fGreekHopliteLoaded = true;
    if(loadPersonHD(fGreekHoplite, {{"fight", &fGreekHoplite.fFight}}, fRenderer, fTileH, "greekhoplite")) return;   // art/characters/people/people10.py

    const auto& sds = spriteData(fTileH,
                                 eGreekHopliteSpriteData15,
                                 eGreekHopliteSpriteData30,
                                 eGreekHopliteSpriteData45,
                                 eGreekHopliteSpriteData60);
    eSpriteLoader loader(fTileH, "greekHoplite", sds,
                         &eZeus_GreekOffset, fRenderer);
    loader.loadSkipFlipped(1, 1, 97, fGreekHoplite.fWalk);
    loader.loadSkipFlipped(1, 105, 169, fGreekHoplite.fFight);

    for(int i = 97; i < 105; i++) {
        loader.load(1, i, fGreekHoplite.fDie);
    }
}

void eCharacterTextures::loadGreekHorseman() {
    if(fGreekHorsemanLoaded) return;
    fGreekHorsemanLoaded = true;
    if(loadPersonHD(fGreekHorseman, {{"fight", &fGreekHorseman.fFight}}, fRenderer, fTileH, "greekhorseman")) return;   // art/characters/people/people10.py

    const auto& sds = spriteData(fTileH,
                                 eGreekHorsemanSpriteData15,
                                 eGreekHorsemanSpriteData30,
                                 eGreekHorsemanSpriteData45,
                                 eGreekHorsemanSpriteData60);
    eSpriteLoader loader(fTileH, "greekHorseman", sds,
                         &eZeus_GreekOffset, fRenderer);
    loader.loadSkipFlipped(169, 169, 265, fGreekHorseman.fWalk);
    loader.loadSkipFlipped(169, 273, 369, fGreekHorseman.fFight);

    for(int i = 265; i < 273; i++) {
        loader.load(169, i, fGreekHorseman.fDie);
    }
}

void eCharacterTextures::loadDonkey() {
    if(fDonkeyLoaded) return;
    fDonkeyLoaded = true;
    if(loadAnimalHD(fDonkey, nullptr, nullptr, fRenderer, fTileH, "donkey")) return;

    const auto& sds = spriteData(fTileH,
                                 eDonkeySpriteData15,
                                 eDonkeySpriteData30,
                                 eDonkeySpriteData45,
                                 eDonkeySpriteData60);
    eSpriteLoader loader(fTileH, "donkey", sds,
                         &eSprAmbientOffset, fRenderer);
    loadBasicTexture(fDonkey, 529, loader);
}

namespace {
// Frame-matched remastered sprites (art/banners): Textures/Remastered/<dir>/<tileH>/<prefix><i>.png of
// exactly the legacy sprite's size replaces it (offsets kept), with the 2*tileH file as its sharper
// twin for zoomed-in views.
void replaceRemastered(eTextureCollection& coll, SDL_Renderer* const renderer, const int tileH,
                       const std::string& dir, const std::string& prefix, const int count = -1) {
    const auto base = eGameDir::texturesDir() + "Remastered/" + dir + "/";
    const int n = count < 0 ? coll.size() : std::min(count, coll.size());
    for(int i = 0; i < n; i++) {
        const auto& old = coll.getTexture(i);
        if(!old) continue;
        const auto path = base + std::to_string(tileH) + "/" + prefix + std::to_string(i) + ".png";
        if(!std::filesystem::exists(path)) continue;
        const auto sheet = std::make_shared<eTexture>();
        if(!sheet->load(renderer, path) || sheet->width() != old->width() || sheet->height() != old->height()) continue;
        sheet->setScaleMode(SDL_ScaleModeLinear);
        const auto tex = std::make_shared<eTexture>();
        tex->setParentTexture({0, 0, sheet->width(), sheet->height()}, sheet);
        tex->setOffset(old->offsetX(), old->offsetY());
        const auto hiPath = base + std::to_string(2*tileH) + "/" + prefix + std::to_string(i) + ".png";
        const auto hi = std::make_shared<eTexture>();
        if(tileH <= 30 && std::filesystem::exists(hiPath) && hi->load(renderer, hiPath) &&
           hi->width() == 2*sheet->width() && hi->height() == 2*sheet->height()) {
            hi->setScaleMode(SDL_ScaleModeLinear);
            const auto dense = std::make_shared<eTexture>();
            dense->setParentTexture({0, 0, hi->width(), hi->height()}, hi);
            dense->setDensity(2);
            const auto hiTex = std::make_shared<eTexture>();
            hiTex->setParentTexture({0, 0, sheet->width(), sheet->height()}, dense);
            tex->setHiRes(hiTex);
        }
        coll.replaceTexture(i, tex);
    }
}
}

void eCharacterTextures::loadBanners() {
    if(fBannersLoaded) return;
    fBannersLoaded = true;

    {
        const auto& sds = spriteData(fTileH,
                                     eBannersSpriteData15,
                                     eBannersSpriteData30,
                                     eBannersSpriteData45,
                                     eBannersSpriteData60);
        eSpriteLoader loader(fTileH, "banners", sds,
                             nullptr, fRenderer);

        for(int i = 1; i < 22; i++) {
            loader.load(1, i, fBannerRod);
        }

        int ban = 0;
        for(int i = 43; i < 204;) {
            fBanners.emplace_back(fRenderer);
            auto& bani = fBanners[ban++];
            for(int j = 0; j < 7; j++, i++) {
                loader.load(1, i, bani);
            }
        }

        for(int i = 204; i < 207; i++) {
            loader.load(1, i, fBannerTops);
        }
    }
    {
        const auto& sds = spriteData(fTileH,
                                     ePoseidonBannerTopsSpriteData15,
                                     ePoseidonBannerTopsSpriteData30,
                                     ePoseidonBannerTopsSpriteData45,
                                     ePoseidonBannerTopsSpriteData60);
        eSpriteLoader loader(fTileH, "poseidonBannerTops", sds,
                             nullptr, fRenderer);

        for(int i = 44; i < 47; i++) {
            loader.load(44, i, fPoseidonBannerTops);
        }
    }
    // Roman standards (art/banners): signum pole, vexilla, gilded emblems.
    replaceRemastered(fBannerRod, fRenderer, fTileH, "banners", "rod_", 1);
    for(int b = 0; b < static_cast<int>(fBanners.size()); b++) {
        replaceRemastered(fBanners[b], fRenderer, fTileH, "banners", "flag" + std::to_string(b) + "_");
    }
    replaceRemastered(fBannerTops, fRenderer, fTileH, "banners", "top_");
    replaceRemastered(fPoseidonBannerTops, fRenderer, fTileH, "banners", "ptop_");
}
