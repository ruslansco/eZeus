#include "ecitydata.h"

#include "elanguage.h"
#include "engine/eboardcity.h"
#include "engine/etaxrate.h"

#include <algorithm>
#include <cmath>

std::string eCityVerdict::text() const {
    return eLanguage::zeusText(fGroup, fString);
}

std::vector<eTaxRate> eCityData::taxRatesInOrder() {
    return {eTaxRate::none, eTaxRate::low, eTaxRate::veryLow, eTaxRate::normal,
            eTaxRate::high, eTaxRate::veryHigh, eTaxRate::outrageous};
}

eTaxRate eCityData::stepTaxRate(const eTaxRate rate, const int step) {
    const auto order = taxRatesInOrder();
    const int n = order.size();
    int i = std::find(order.begin(), order.end(), rate) - order.begin();
    if(i >= n) i = 3;
    return order[std::clamp(i + step, 0, n - 1)];
}

eCityVerdict eCityData::popularity(const int pop) {
    int string;
    if(pop > 90) string = 38; // superb
    else if(pop > 85) string = 37; // great
    else if(pop > 80) string = 36; // high
    else if(pop > 75) string = 34; // good
    else if(pop > 70) string = 33; // ok
    else if(pop > 60) string = 32; // poor
    else if(pop > 50) string = 31; // bad
    else if(pop > 40) string = 28; // awful
    else string = 27; // terrible
    return {61, string, pop > 80 ? 0 : pop > 60 ? 1 : 2};
}

eCityVerdict eCityData::foodLevel(const int a, const int pop) {
    int string;
    if(pop == 0 || a < 0.75*pop) string = 94; // too low
    else if(a < 0.85*pop) string = 95; // low
    else string = 97; // good
    return {61, string, string == 97 ? 0 : string == 95 ? 1 : 2};
}

eCityVerdict eCityData::hygiene(const int h) {
    int string;
    if(h > 90) string = 137; // perfect
    else if(h > 85) string = 136; // great
    else if(h > 80) string = 135; // excellent
    else if(h > 75) string = 134; // very good
    else if(h > 70) string = 133; // good
    else if(h > 65) string = 132; // ok
    else if(h > 60) string = 131; // not good
    else if(h > 55) string = 130; // poor
    else if(h > 50) string = 129; // bad
    else if(h > 45) string = 128; // terrible
    else string = 127; // appalling
    return {61, string, h > 70 ? 0 : h > 55 ? 1 : 2};
}

eCityVerdict eCityData::unrest(const int u) {
    int string;
    if(u == 0) string = 149; // none
    else if(u > 10) string = 144; // severe
    else if(u > 5) string = 146; // high
    else string = 148; // low
    return {61, string, u == 0 ? 0 : u > 5 ? 2 : 1};
}

eCityVerdict eCityData::finances(const int net) {
    int string;
    if(net > 250) string = 153; // up
    else if(net < -100) string = 155; // down
    else string = 154; // ok
    return {61, string, string == 153 ? 0 : string == 154 ? 1 : 2};
}

eCityData::eEmploymentLine eCityData::employment(const int f, const int w, const int u) {
    if(u == 0) return {115, "", 0}; // employment good
    if(f > 0) return {111, std::to_string(f), w > 0 && f > w/5 ? 2 : 1}; // workers needed
    int per = w == 0 ? 0 : std::round(100.*u/w);
    per = std::clamp(per, 0, 100);
    return {107, std::to_string(per) + "%", per > 10 ? 2 : 1}; // unemployment
}

eCityVerdict eCityData::foodOpinion(const int a, const int pop) {
    int string;
    if(pop == 0 || a < 0.75*pop) string = 3; // far too little
    else if(a < 0.85*pop) string = 4; // much too little
    else if(a < 0.95*pop) string = 5; // too little
    else if(a < 1.10*pop) string = 6; // just enough
    else if(a < 1.35*pop) string = 7; // plenty
    else string = 8; // surplus
    return {57, string, string >= 6 ? 0 : string == 5 ? 1 : 2};
}

eCityVerdict eCityData::hygieneLevel(const int h) {
    int string;
    if(h > 90) string = 12;
    else if(h > 85) string = 11;
    else if(h > 80) string = 10;
    else if(h > 75) string = 9;
    else if(h > 70) string = 8;
    else if(h > 65) string = 7;
    else if(h > 60) string = 6;
    else if(h > 55) string = 5;
    else if(h > 50) string = 4;
    else if(h > 45) string = 3;
    else string = 2;
    return {56, string, h > 70 ? 0 : h > 55 ? 1 : 2};
}

eCityVerdict eCityData::unrestLevel(const int u) {
    int string;
    if(u > 8) string = 19;
    else if(u > 6) string = 20;
    else if(u > 4) string = 21;
    else if(u > 0) string = 22;
    else string = 23; // no unrest
    return {56, string, u == 0 ? 0 : u > 5 ? 2 : 1};
}

int eCityData::immigrationLimitText(const int v, const eImmigrationLimitedBy limit) {
    if(v <= 0) return 13; // lack of housing vacancies
    switch(limit) {
    case eImmigrationLimitedBy::lowWages: return 14;
    case eImmigrationLimitedBy::unemployment: return 15;
    case eImmigrationLimitedBy::lackOfFood: return 16;
    case eImmigrationLimitedBy::highTaxes: return 17;
    case eImmigrationLimitedBy::prolongedDebt: return 18;
    case eImmigrationLimitedBy::excessiveMilitaryService: return 19;
    default: return 13;
    }
}

int eCityData::peopleDirectionText(const int arrived, const int left) {
    if(left > arrived) return 21; // people are leaving the city
    if(arrived > left) return 20; // people wish to come to the city
    return 0;
}

int eCityData::coverageText(const int c) {
    if(c < 20) return 14; // terrible
    if(c < 40) return 13; // poor
    if(c < 60) return 12; // ok
    if(c < 80) return 11; // not bad
    return 10; // good
}

int eCityData::commemorativeText(const int id) {
    // population, victory, colony, athlete, conquest, happiness, heroic, diplomacy, scholar
    static const int strings[] = {5, 7, 10, 13, 8, 11, 6, 9, 12};
    return strings[std::clamp(id, 0, 8)];
}

int eCityData::sanctuaryStateText(const bool finished, const bool sacrificing) {
    if(!finished) return 9; // needs materials
    return sacrificing ? 3 : 2; // sacrificing, working
}

eCityData::eSoldiers eCityData::soldiers(const int inCity, const int standingDown) {
    if(inCity == 0 && standingDown == 0) return eSoldiers::none;
    if(inCity > 0) return eSoldiers::allCalled;
    return eSoldiers::atPalace;
}

int eCityData::soldiersText(const eSoldiers s) {
    switch(s) {
    case eSoldiers::none: return 82; // no soldiers
    case eSoldiers::allCalled: return 6; // all called
    default: return 8; // at palace
    }
}

int eCityData::soldiersTooltip(const eSoldiers s) {
    switch(s) {
    case eSoldiers::none: return 37; // no soldiers to command
    case eSoldiers::allCalled: return 170; // click to send all soldiers home
    default: return 171; // click to muster all
    }
}

int eCityData::towersText(const int towers, const bool manning) {
    if(towers == 0) return 84; // no towers
    return manning ? 11 : 12; // manning, not manning
}

int eCityData::towersTooltip(const int towers, const bool manning) {
    if(towers == 0) return 39; // no towers to man
    return manning ? 174 : 175; // click to send home, click to man
}
