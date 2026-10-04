#include "ehouseneeds.h"

#include "esmallhouse.h"
#include "eelitehousing.h"

#include <algorithm>

namespace eHouseNeeds {

bool elite(const eHouseBase* const h) {
    return h->type() == eBuildingType::eliteHousing;
}

int maxLevel(const bool elite) {
    return elite ? 4 : 6;
}

eNeeds needs(const bool elite, const int l) {
    eNeeds n;
    if(elite) {
        if(l >= 1) {
            n.fFood = n.fFleece = n.fOil = true;
            n.fVenues = 3;
            n.fAppeal = 5;
        }
        if(l >= 2) { n.fArms = true; n.fAppeal = 7; }
        if(l >= 3) { n.fWine = true; n.fAppeal = 9; }
        if(l >= 4) { n.fHorse = true; n.fVenues = 4; n.fAppeal = 10; }
    } else {
        if(l >= 1) n.fFood = true;
        if(l >= 2) { n.fWater = true; n.fVenues = 1; }
        if(l >= 3) { n.fFleece = true; n.fAppeal = 2; }
        if(l >= 4) n.fVenues = 2;
        if(l >= 5) { n.fOil = true; n.fAppeal = 5; }
        if(l >= 6) { n.fVenues = 3; n.fAppeal = 8; }
    }
    return n;
}

eHas has(const eHouseBase* const h) {
    eHas r;
    r.fFood = h->food();
    r.fFleece = h->fleece();
    r.fOil = h->oil();
    if(elite(h)) {
        const auto eh = static_cast<const eEliteHousing*>(h);
        r.fArms = eh->arms();
        r.fWine = eh->wine();
        r.fHorse = eh->horses();
    } else {
        r.fWater = static_cast<const eSmallHouse*>(h)->water();
    }
    r.fVenues = (h->philosophersInventors() > 0) + (h->actorsAstronomers() > 0) +
                (h->athletesScholars() > 0) + (h->competitorsCurators() > 0);
    r.fAppeal = h->appeal();
    return r;
}

std::vector<eNeed> missing(const eNeeds& n, const eHas& h) {
    std::vector<eNeed> r;
    if(n.fFood && h.fFood <= 0) r.push_back(eNeed::food);
    if(n.fWater && h.fWater <= 0) r.push_back(eNeed::water);
    if(n.fFleece && h.fFleece <= 0) r.push_back(eNeed::fleece);
    if(n.fOil && h.fOil <= 0) r.push_back(eNeed::oil);
    if(n.fArms && h.fArms <= 0) r.push_back(eNeed::arms);
    if(n.fWine && h.fWine <= 0) r.push_back(eNeed::wine);
    if(n.fHorse && h.fHorse <= 0) r.push_back(eNeed::horse);
    if(h.fVenues < n.fVenues) r.push_back(eNeed::venues);
    if(n.fAppeal >= 0 && !(h.fAppeal > n.fAppeal)) r.push_back(eNeed::appeal);
    return r;
}

bool met(const eNeeds& n, const eHas& h) {
    return missing(n, h).empty();
}

int supportedLevel(const eHouseBase* const h) {
    const bool e = elite(h);
    const auto hs = has(h);
    int s = 0;
    for(int l = 1; l <= maxLevel(e); l++) {
        if(met(needs(e, l), hs)) s = l;
    }
    return s;
}

}
