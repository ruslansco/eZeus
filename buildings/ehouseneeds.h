#ifndef EHOUSENEEDS_H
#define EHOUSENEEDS_H

#include <vector>

class eHouseBase;

// What a house needs to stand at each level, copied from
// eSmallHouse::updateLevel and eEliteHousing::updateLevel (keep them in
// step). Used by the house hover card and the city advisor.
namespace eHouseNeeds {

enum class eNeed { food, water, fleece, oil, arms, wine, horse, venues, appeal };

// everything asked by a level and the ones below it
struct eNeeds {
    bool fFood = false;
    bool fWater = false;
    bool fFleece = false;
    bool fOil = false;
    bool fArms = false;
    bool fWine = false;
    bool fHorse = false;
    int fVenues = 0;
    double fAppeal = -1;  // must be above
};

// what the house has now
struct eHas {
    int fFood = 0;
    int fWater = 0;
    int fFleece = 0;
    int fOil = 0;
    int fArms = 0;
    int fWine = 0;
    int fHorse = 0;
    int fVenues = 0;
    double fAppeal = 0;
};

bool elite(const eHouseBase* const h);
int maxLevel(const bool elite);
eNeeds needs(const bool elite, const int level);
eHas has(const eHouseBase* const h);
bool met(const eNeeds& n, const eHas& h);
// the unmet ones, in the order above
std::vector<eNeed> missing(const eNeeds& n, const eHas& h);
// the highest level whose needs are all met
int supportedLevel(const eHouseBase* const h);

}

#endif // EHOUSENEEDS_H
