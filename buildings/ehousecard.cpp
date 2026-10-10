#include "ehousecard.h"

#include "ehousebase.h"
#include "ehouseneeds.h"
#include "ebuilding.h"
#include "elanguage.h"
#include "engine/egameboard.h"

#include <algorithm>
#include <cstdio>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

std::string oneDecimal(const double v) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%.1f", v);
    return buf;
}
}

std::string eHouseCard::signature() const {
    std::string sig = std::to_string(fLevel) + "|" + std::to_string(fTone) + "|" + fName + "|" +
                      fResidents + "|" + fStatus;
    for(const auto& l : fLines) {
        sig += "|" + l.fLabel + "," + l.fDetail + "," + l.fNote + "," + (l.fMet ? "1" : "0");
    }
    return sig;
}

eHouseCard eHouseCards::card(eHouseBase* const h) {
    eHouseCard c;
    if(!h || h->people() <= 0) return c;
    c.fValid = true;
    const bool elite = h->type() == eBuildingType::eliteHousing;
    const int maxL = elite ? 4 : 6;
    const int level = std::clamp(h->level(), 0, maxL);
    const auto has = eHouseNeeds::has(h);
    const auto needs = [elite](const int l) {
        return eHouseNeeds::needs(elite, l);
    };
    const int supported = eHouseNeeds::supportedLevel(h);
    const auto name = [elite](const int l) {
        return eLanguage::zeusText(29, elite ? 8 + l : l);
    };
    c.fElite = elite;
    c.fLevel = level;
    c.fLevels = maxL + 1;
    c.fName = name(level);
    c.fPeople = h->people();
    c.fResidents = std::to_string(h->people()) + " " + tr("house_card_residents", "residents");
    // what to list: the next level's needs, or the current one's if it slips
    int target = -1;
    if(supported < level) {
        c.fTone = 1;
        c.fStatus = tr("house_card_decline", "Will decline, missing:");
        target = level;
    } else if(level >= maxL) {
        c.fTone = 2;
        c.fStatus = tr("house_card_top", "The finest home of its kind");
    } else if(supported > level) {
        c.fTone = 2;
        c.fStatus = tr("house_card_improving", "Improving soon") + ": " + name(level + 1);
        target = level + 1;
    } else {
        c.fStatus = tr("house_card_next", "Next level") + ": " + name(level + 1);
        target = level + 1;
    }
    if(target < 0) return c;
    c.fTargetLevel = target;
    c.fTargetName = name(target);
    const auto& board = h->getBoard();
    const bool science = board.atlantean(h->cityId());
    const auto n = needs(target);
    auto& lines = c.fLines;
    const auto good = [&](const bool need, const eResourceType type, const int count) {
        if(!need) return;
        auto& l = lines.emplace_back();
        l.fResource = type;
        l.fLabel = eResourceTypeHelpers::typeName(type);
        l.fDetail = std::to_string(count);
        l.fMet = count > 0;
    };
    good(n.fFood, eResourceType::food, has.fFood);
    if(n.fWater) {
        auto& l = lines.emplace_back();
        l.fIcon = "water";
        l.fLabel = tr("house_card_water", "Water");
        l.fMet = has.fWater > 0;
    }
    good(n.fFleece, eResourceType::fleece, has.fFleece);
    good(n.fOil, eResourceType::oliveOil, has.fOil);
    good(n.fArms, eResourceType::armor, has.fArms);
    good(n.fWine, eResourceType::wine, has.fWine);
    good(n.fHorse, eResourceType::horse, has.fHorse);
    if(n.fVenues > 0) {
        auto& l = lines.emplace_back();
        l.fIcon = science ? "science" : "culture";
        l.fLabel = science ? tr("house_card_science", "Science venues") :
                             tr("house_card_culture", "Culture venues");
        l.fDetail = std::to_string(has.fVenues) + " / " + std::to_string(n.fVenues);
        l.fMet = has.fVenues >= n.fVenues;
        if(!l.fMet) {
            // the kinds that do not reach this house yet
            const std::pair<bool, eBuildingType> kinds[] = {
                {h->philosophersInventors() > 0, science ? eBuildingType::inventorsWorkshop : eBuildingType::podium},
                {h->actorsAstronomers() > 0, science ? eBuildingType::observatory : eBuildingType::theater},
                {h->athletesScholars() > 0, science ? eBuildingType::university : eBuildingType::gymnasium},
                {h->competitorsCurators() > 0, science ? eBuildingType::museum : eBuildingType::stadium}};
            std::string lack;
            for(const auto& k : kinds) {
                if(k.first) continue;
                if(!lack.empty()) lack += ", ";
                lack += eBuilding::sNameForBuilding(k.second);
            }
            l.fNote = tr("house_card_reach", "Not reached by:") + " " + lack;
        }
    }
    if(n.fAppeal >= 0) {
        auto& l = lines.emplace_back();
        l.fIcon = "aesthetics";
        l.fLabel = tr("house_card_appeal", "Attractive surroundings");
        l.fDetail = oneDecimal(has.fAppeal) + " / " + oneDecimal(n.fAppeal);
        l.fMet = has.fAppeal > n.fAppeal;
    }
    // what is missing first
    std::stable_sort(lines.begin(), lines.end(), [](const eHouseCardLine& a, const eHouseCardLine& b) {
        return !a.fMet && b.fMet;
    });
    return c;
}
