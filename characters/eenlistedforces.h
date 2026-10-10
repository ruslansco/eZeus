#ifndef EENLISTEDFORCES_H
#define EENLISTEDFORCES_H

#include "characters/esoldierbanner.h"
#include "characters/heroes/ehero.h"
#include "engine/eworldcity.h"
#include "buildings/etriremewharf.h"

struct eEnlistedForces {
    std::vector<stdsptr<eSoldierBanner>> fSoldiers;
    std::vector<std::pair<eCityId, eHeroType>> fHeroes;
    std::vector<stdsptr<eWorldCity>> fAllies;
    bool fAres = false;
    eCityId fAresCity = eCityId::neutralFriendly;
    // Poseidon's navy abroad: the wharves whose manned triremes sail with the army (they come back to them).
    std::vector<stdptr<eTriremeWharf>> fTriremes;

    std::map<eCityId, eEnlistedForces> splitIntoCities() const;

    void read(eGameBoard& board,
              eReadStream& src);
    void write(eWriteStream& dst) const;

    void clear();

    void add(const eEnlistedForces& o);

    int strength() const;
    void kill(const double killFrac) const;

    int count() const;
};

#endif // EENLISTEDFORCES_H
