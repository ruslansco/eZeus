#include "echaractertextures.h"

#include "espriteloader.h"

#include "offsets/zeus_hydra.h"
#include "offsets/zeus_kraken.h"
#include "offsets/zeus_maenads.h"
#include "offsets/zeus_medusa.h"
#include "offsets/zeus_minotaur.h"
#include "offsets/zeus_scylla.h"
#include "offsets/Poseidon_Sphinx.h"
#include "offsets/zeus_talos.h"
#include "offsets/zeus_satyr.h"

#include "spriteData/hydra15.h"
#include "spriteData/hydra30.h"
#include "spriteData/hydra45.h"
#include "spriteData/hydra60.h"

#include "spriteData/kraken15.h"
#include "spriteData/kraken30.h"
#include "spriteData/kraken45.h"
#include "spriteData/kraken60.h"

#include "spriteData/maenads15.h"
#include "spriteData/maenads30.h"
#include "spriteData/maenads45.h"
#include "spriteData/maenads60.h"

#include "spriteData/medusa15.h"
#include "spriteData/medusa30.h"
#include "spriteData/medusa45.h"
#include "spriteData/medusa60.h"

#include "spriteData/minotaur15.h"
#include "spriteData/minotaur30.h"
#include "spriteData/minotaur45.h"
#include "spriteData/minotaur60.h"

#include "spriteData/scylla15.h"
#include "spriteData/scylla30.h"
#include "spriteData/scylla45.h"
#include "spriteData/scylla60.h"

#include "spriteData/sphinx15.h"
#include "spriteData/sphinx30.h"
#include "spriteData/sphinx45.h"
#include "spriteData/sphinx60.h"

#include "spriteData/talos15.h"
#include "spriteData/talos30.h"
#include "spriteData/talos45.h"
#include "spriteData/talos60.h"

#include "spriteData/satyr15.h"
#include "spriteData/satyr30.h"
#include "spriteData/satyr45.h"
#include "spriteData/satyr60.h"

void eCharacterTextures::loadHydra() {
    if(fHydraLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eHydraSpriteData15,
                                 eHydraSpriteData30,
                                 eHydraSpriteData45,
                                 eHydraSpriteData60);
    fHydraLoaded = true;
    if(loadStatesHD({{"walk", &fHydra.fWalk}, {"die", &fHydra.fDie}, {"fight", &fHydra.fFight}, {"fight2", &fHydra.fFight2}}, fRenderer, fTileH, "hydra")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "hydra", sds,
                         &eZeus_hydraOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 121, fHydra.fWalk);
    loader.loadSkipFlipped(1, 121, 289, fHydra.fDie);
    loader.loadSkipFlipped(1, 289, 473, fHydra.fFight);
    loader.loadSkipFlipped(1, 473, 609, fHydra.fFight2);
}

void eCharacterTextures::loadKraken() {
    if(fKrakenLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eKrakenSpriteData15,
                                 eKrakenSpriteData30,
                                 eKrakenSpriteData45,
                                 eKrakenSpriteData60);
    fKrakenLoaded = true;
    if(loadStatesHD({{"walk", &fKraken.fWalk}, {"die", nullptr, &fKraken.fDie}, {"fight", &fKraken.fFight}, {"fight2", &fKraken.fFight2}}, fRenderer, fTileH, "kraken")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "kraken", sds,
                         &eZeus_krakenOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 169, fKraken.fWalk);
    for(int i = 169; i < 200; i++) {
        loader.load(1, i, fKraken.fDie);
    }
    loader.loadSkipFlipped(1, 200, 488, fKraken.fFight);
    loader.loadSkipFlipped(1, 488, 728, fKraken.fFight2);
}

void eCharacterTextures::loadMaenads() {
    if(fMaenadsLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eMaenadsSpriteData15,
                                 eMaenadsSpriteData30,
                                 eMaenadsSpriteData45,
                                 eMaenadsSpriteData60);
    fMaenadsLoaded = true;
    if(loadStatesHD({{"walk", &fMaenads.fWalk}, {"die", &fMaenads.fDie}, {"fight", &fMaenads.fFight}, {"fight2", &fMaenads.fFight2}}, fRenderer, fTileH, "maenads")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "maenads", sds,
                         &eZeus_maenadsOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 129, fMaenads.fWalk);
    loader.loadSkipFlipped(1, 129, 289, fMaenads.fDie);
    loader.loadSkipFlipped(1, 289, 457, fMaenads.fFight);
    loader.loadSkipFlipped(1, 457, 561, fMaenads.fFight2);
}

void eCharacterTextures::loadMedusa() {
    if(fMedusaLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eMedusaSpriteData15,
                                 eMedusaSpriteData30,
                                 eMedusaSpriteData45,
                                 eMedusaSpriteData60);
    fMedusaLoaded = true;
    if(loadStatesHD({{"walk", &fMedusa.fWalk}, {"die", &fMedusa.fDie}, {"fight", &fMedusa.fFight}, {"fight2", &fMedusa.fFight2}}, fRenderer, fTileH, "medusa")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "medusa", sds,
                         &eZeus_medusaOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 129, fMedusa.fWalk);
    loader.loadSkipFlipped(1, 129, 273, fMedusa.fDie);
    loader.loadSkipFlipped(1, 273, 409, fMedusa.fFight);
    loader.loadSkipFlipped(1, 409, 545, fMedusa.fFight2);
}

void eCharacterTextures::loadMinotaur() {
    if(fMinotaurLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eMinotaurSpriteData15,
                                 eMinotaurSpriteData30,
                                 eMinotaurSpriteData45,
                                 eMinotaurSpriteData60);
    fMinotaurLoaded = true;
    if(loadStatesHD({{"walk", &fMinotaur.fWalk}, {"die", &fMinotaur.fDie}, {"fight", &fMinotaur.fFight}, {"fight2", &fMinotaur.fFight2}}, fRenderer, fTileH, "minotaur")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "minotaur", sds,
                         &eZeus_minotaurOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 161, fMinotaur.fWalk);
    loader.loadSkipFlipped(1, 161, 321, fMinotaur.fDie);
    loader.loadSkipFlipped(1, 321, 481, fMinotaur.fFight);
    loader.loadSkipFlipped(1, 481, 641, fMinotaur.fFight2);
}

void eCharacterTextures::loadScylla() {
    if(fScyllaLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eScyllaSpriteData15,
                                 eScyllaSpriteData30,
                                 eScyllaSpriteData45,
                                 eScyllaSpriteData60);
    fScyllaLoaded = true;
    if(loadStatesHD({{"walk", &fScylla.fWalk}, {"die", nullptr, &fScylla.fDie}, {"fight", &fScylla.fFight}, {"fight2", &fScylla.fFight2}}, fRenderer, fTileH, "scylla")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "scylla", sds,
                         &eZeus_scyllaOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 161, fScylla.fWalk);
    for(int i = 161; i < 192; i++) {
        loader.load(1, i, fScylla.fDie);
    }
    loader.loadSkipFlipped(1, 192, 432, fScylla.fFight);
    loader.loadSkipFlipped(1, 432, 680, fScylla.fFight2);
}

void eCharacterTextures::loadSphinx() {
    if(fSphinxLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eSphinxSpriteData15,
                                 eSphinxSpriteData30,
                                 eSphinxSpriteData45,
                                 eSphinxSpriteData60);
    fSphinxLoaded = true;
    if(loadStatesHD({{"walk", &fSphinx.fWalk}, {"die", &fSphinx.fDie}, {"fight", &fSphinx.fFight}, {"fight2", &fSphinx.fFight2}}, fRenderer, fTileH, "sphinx")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "sphinx", sds,
                         &ePoseidon_SphinxOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 137, fSphinx.fWalk);
    loader.loadSkipFlipped(1, 137, 321, fSphinx.fDie);
    loader.loadSkipFlipped(1, 321, 529, fSphinx.fFight);
    loader.loadSkipFlipped(1, 529, 793, fSphinx.fFight2);
}

void eCharacterTextures::loadTalos() {
    if(fTalosLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eTalosSpriteData15,
                                 eTalosSpriteData30,
                                 eTalosSpriteData45,
                                 eTalosSpriteData60);
    fTalosLoaded = true;
    if(loadStatesHD({{"walk", &fTalos.fWalk}, {"die", &fTalos.fDie}, {"fight", &fTalos.fFight}, {"fight2", &fTalos.fFight2}}, fRenderer, fTileH, "talos")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "talos", sds,
                         &eZeus_talosOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 145, fTalos.fWalk);
    loader.loadSkipFlipped(1, 145, 273, fTalos.fDie);
    loader.loadSkipFlipped(1, 273, 393, fTalos.fFight);
    loader.loadSkipFlipped(1, 393, 545, fTalos.fFight2);
}

void eCharacterTextures::loadSatyr() {
    if(fSatyrLoaded) return;
    const auto& sds = spriteData(fTileH,
                                 eSatyrSpriteData15,
                                 eSatyrSpriteData30,
                                 eSatyrSpriteData45,
                                 eSatyrSpriteData60);
    fSatyrLoaded = true;
    if(loadStatesHD({{"walk", &fSatyr.fWalk}, {"die", &fSatyr.fDie}, {"fight", &fSatyr.fFight}, {"fight2", &fSatyr.fFight2}}, fRenderer, fTileH, "satyr")) return;   // art/characters/people/people7.py
    eSpriteLoader loader(fTileH, "satyr", sds,
                         &eZeus_satyrOffset, fRenderer);

    loader.loadSkipFlipped(1, 1, 129, fSatyr.fWalk);
    loader.loadSkipFlipped(1, 129, 289, fSatyr.fDie);
    loader.loadSkipFlipped(1, 289, 417, fSatyr.fFight);
    loader.loadSkipFlipped(1, 417, 561, fSatyr.fFight2);
}
