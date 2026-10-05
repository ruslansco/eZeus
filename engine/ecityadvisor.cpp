#include "ecityadvisor.h"

#include "elanguage.h"
#include "estringhelpers.h"
#include "engine/egameboard.h"
#include "engine/eboardcity.h"
#include "engine/edifficulty.h"
#include "buildings/esmallhouse.h"
#include "buildings/eelitehousing.h"
#include "buildings/ehouseneeds.h"
#include "buildings/eemployingbuilding.h"
#include "engine/etile.h"

#include <algorithm>
#include <cmath>
#include <map>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

std::string num(const int n) {
    return std::to_string(n);
}

using eNeed = eHouseNeeds::eNeed;

std::string needName(const eNeed n, const bool science) {
    switch(n) {
    case eNeed::food: return tr("adv_need_food", "food");
    case eNeed::water: return tr("adv_need_water", "water");
    case eNeed::fleece: return tr("adv_need_fleece", "fleece");
    case eNeed::oil: return tr("adv_need_oil", "olive oil");
    case eNeed::arms: return tr("adv_need_arms", "armor");
    case eNeed::wine: return tr("adv_need_wine", "wine");
    case eNeed::horse: return tr("adv_need_horse", "horses");
    case eNeed::venues: return science ? tr("adv_need_science", "more science venues") :
                                         tr("adv_need_culture", "more culture venues");
    case eNeed::appeal: return tr("adv_need_appeal", "more attractive surroundings");
    }
    return "";
}

std::string needHint(const eNeed n, const bool science) {
    switch(n) {
    case eNeed::food: return tr("adv_hint_food", "An agora with a food vendor must reach them, and the granaries need food.");
    case eNeed::water: return tr("adv_hint_water", "Build a fountain whose water carrier walks past them.");
    case eNeed::fleece: return tr("adv_hint_fleece", "Stock fleece at an agora fleece vendor: shear sheep or import it.");
    case eNeed::oil: return tr("adv_hint_oil", "Stock olive oil at an agora oil vendor: press olives or import it.");
    case eNeed::arms: return tr("adv_hint_arms", "Armor from an armory must be sold at an agora nearby.");
    case eNeed::wine: return tr("adv_hint_wine", "Wine from a winery or imports must be sold at an agora nearby.");
    case eNeed::horse: return tr("adv_hint_horse", "Horses from a horse ranch must reach them.");
    case eNeed::venues: return science ?
            tr("adv_hint_science", "More kinds of science venues (inventors' workshop, observatory, university, museum) must reach them.") :
            tr("adv_hint_culture", "More kinds of culture venues (podium, theater, gymnasium, stadium) must reach them.");
    case eNeed::appeal: return tr("adv_hint_appeal", "Add parks, statues and gardens nearby; keep industry away.");
    }
    return "";
}

std::string needIcon(const eNeed n) {
    switch(n) {
    case eNeed::food: return "husbandry";
    case eNeed::water: return "water";
    case eNeed::fleece:
    case eNeed::oil:
    case eNeed::wine: return "amphora";
    case eNeed::arms:
    case eNeed::horse: return "military";
    case eNeed::venues: return "culture";
    case eNeed::appeal: return "aesthetics";
    }
    return "population";
}

std::pair<int, int> at(eBuilding* const b) {
    const auto t = b->centerTile();
    if(t) return {t->x(), t->y()};
    const auto& r = b->tileRect();
    return {r.x, r.y};
}
}

std::vector<eAdvice> eCityAdvisor::collect(eGameBoard& board, const eCityId cid,
                                           const int max) {
    std::vector<eAdvice> out;
    const auto city = board.boardCityWithId(cid);
    if(!city) return out;
    const auto pid = board.cityIdToPlayerId(cid);
    const auto diff = board.difficulty(pid);
    const bool science = board.atlantean(cid);

    // --- houses: slipping, or stuck below their next level
    std::map<eNeed, std::vector<std::pair<int, int>>> declining;
    std::map<eNeed, std::vector<std::pair<int, int>>> stuck;
    std::vector<std::pair<int, int>> plague;
    std::vector<std::pair<int, int>> angry;
    // --- risks and workers
    std::vector<std::pair<int, eBuilding*>> fire;
    std::vector<std::pair<int, eBuilding*>> collapse;
    std::vector<std::pair<double, eBuilding*>> shortStaffed;
    int idle = 0;

    for(const auto b : city->allBuildings()) {
        if(!b) continue;
        const auto type = b->type();
        if(type == eBuildingType::commonHouse || type == eBuildingType::eliteHousing) {
            const auto h = static_cast<eHouseBase*>(b);
            if(h->people() <= 0) continue;
            const bool e = eHouseNeeds::elite(h);
            const int maxL = eHouseNeeds::maxLevel(e);
            const int level = std::clamp(h->level(), 0, maxL);
            const auto hs = eHouseNeeds::has(h);
            const int sup = eHouseNeeds::supportedLevel(h);
            if(sup < level) {
                const auto m = eHouseNeeds::missing(eHouseNeeds::needs(e, level), hs);
                if(!m.empty()) declining[m.front()].push_back(at(b));
            } else if(sup == level && level < maxL) {
                const auto m = eHouseNeeds::missing(eHouseNeeds::needs(e, level + 1), hs);
                if(!m.empty()) stuck[m.front()].push_back(at(b));
            }
            if(!e) {
                const auto sh = static_cast<eSmallHouse*>(h);
                if(sh->plague()) plague.push_back(at(b));
                if(sh->disgruntled()) angry.push_back(at(b));
            }
        }
        if(!b->isOnFire()) {
            const int m = b->maintenance();
            if(m < 35 && eBuilding::sFlammable(type) &&
               eDifficultyHelpers::fireRisk(diff, type) > 0) {
                fire.push_back({m, b});
            }
            if(m < 35 && eDifficultyHelpers::damageRisk(diff, type) > 0) {
                collapse.push_back({m, b});
            }
        }
        if(const auto eb = dynamic_cast<eEmployingBuilding*>(b)) {
            const int maxE = eb->maxEmployees();
            if(maxE > 0 && !eb->shutDown()) {
                const double f = double(eb->employed())/maxE;
                if(f < 0.75) shortStaffed.push_back({f, b});
                if(eb->employed() == 0) idle++;
            }
        }
    }

    {
        int n = 0;
        std::vector<std::pair<int, eNeed>> byCount;
        std::vector<std::pair<int, int>> all;
        for(const auto& d : declining) {
            n += d.second.size();
            byCount.push_back({static_cast<int>(d.second.size()), d.first});
        }
        if(n > 0) {
            std::sort(byCount.rbegin(), byCount.rend());
            std::string detail = tr("adv_missing", "Missing") + ": ";
            for(size_t i = 0; i < byCount.size(); i++) {
                if(i) detail += ", ";
                detail += needName(byCount[i].second, science) + " (" + num(byCount[i].first) + ")";
            }
            for(const auto& c : byCount) {
                const auto& v = declining[c.second];
                all.insert(all.end(), v.begin(), v.end());
            }
            auto& a = out.emplace_back();
            a.fKey = "decline";
            a.fSeverity = 2;
            a.fIcon = "population";
            a.fTitle = tr("adv_decline", "Houses about to decline") + ": " + num(n);
            a.fDetail = detail;
            a.fHint = needHint(byCount.front().second, science);
            a.fPlaces = all;
            a.fWeight = 1000 + n;
        }
    }
    {
        std::vector<std::pair<int, eNeed>> byCount;
        for(const auto& d : stuck) byCount.push_back({static_cast<int>(d.second.size()), d.first});
        std::sort(byCount.rbegin(), byCount.rend());
        int shown = 0;
        for(const auto& c : byCount) {
            if(shown >= 2 || c.first < 2) break;
            shown++;
            auto& a = out.emplace_back();
            a.fKey = "stuck" + std::to_string(static_cast<int>(c.second));
            a.fSeverity = 1;
            a.fIcon = needIcon(c.second);
            a.fTitle = tr("adv_stuck", "Houses that can't improve") + ": " + num(c.first);
            a.fDetail = tr("adv_they_need", "They need") + " " + needName(c.second, science);
            a.fHint = needHint(c.second, science);
            a.fPlaces = stuck[c.second];
            a.fWeight = c.first;
        }
    }
    if(!plague.empty()) {
        auto& a = out.emplace_back();
        a.fKey = "plague";
        a.fSeverity = 2;
        a.fIcon = "hygiene";
        a.fTitle = tr("adv_plague", "Plague in houses") + ": " + num(plague.size());
        a.fHint = tr("adv_hint_plague", "Hospitals and clean water fight disease; keep healers walking past.");
        a.fPlaces = plague;
        a.fWeight = 900 + plague.size();
    }
    const auto riskAdvice = [&](std::vector<std::pair<int, eBuilding*>>& v, const char* key,
                                const char* titleKey, const char* titleFb, const std::string& icon) {
        if(v.empty()) return;
        std::sort(v.begin(), v.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
        auto& a = out.emplace_back();
        a.fKey = key;
        a.fSeverity = (v.front().first < 15 || v.size() >= 6) ? 2 : 1;
        a.fIcon = icon;
        a.fTitle = tr(titleKey, titleFb) + ": " + num(v.size());
        a.fDetail = tr("adv_worst_first", "Worst first; care has run low where maintenance walkers don't pass.");
        a.fHint = tr("adv_hint_maintenance", "Build a maintenance office whose walkers pass these streets.");
        for(const auto& p : v) a.fPlaces.push_back(at(p.second));
        a.fWeight = 500 + v.size();
    };
    riskAdvice(fire, "fire", "adv_fire", "Buildings at risk of fire", "fire");
    riskAdvice(collapse, "collapse", "adv_collapse", "Buildings at risk of collapse", "collapse");

    if(!angry.empty() || city->unrest() >= 15) {
        auto& a = out.emplace_back();
        a.fKey = "unrest";
        a.fSeverity = city->unrest() >= 30 ? 2 : 1;
        a.fIcon = "military";
        a.fTitle = tr("adv_unrest", "Unrest") + ": " + num(city->unrest()) + "%";
        if(!angry.empty()) {
            a.fDetail = tr("adv_angry", "Angry households") + ": " + num(angry.size());
        }
        a.fHint = tr("adv_hint_unrest", "People grow unhappy without food, water or work, or with high taxes.");
        a.fPlaces = angry;
        a.fWeight = city->unrest();
    }

    {
        const auto& ed = city->employmentData();
        const int employable = ed.employable();
        const int unemployed = ed.unemployed();
        if(shortStaffed.size() >= 2) {
            std::sort(shortStaffed.begin(), shortStaffed.end(),
                      [](const auto& a, const auto& b) { return a.first < b.first; });
            auto& a = out.emplace_back();
            a.fKey = "workers";
            a.fSeverity = (idle >= 5 || shortStaffed.size() >= 20) ? 2 : 1;
            a.fIcon = "population";
            a.fTitle = tr("adv_workers", "Buildings short of workers") + ": " + num(shortStaffed.size());
            a.fDetail = tr("adv_idle", "Not working at all") + ": " + num(idle) + "   " +
                        tr("adv_free_jobs", "Free jobs") + ": " + num(ed.freeJobVacancies());
            a.fHint = tr("adv_hint_workers", "More housing brings more workers; the administration page can put workers where they matter.");
            for(const auto& p : shortStaffed) a.fPlaces.push_back(at(p.second));
            a.fWeight = shortStaffed.size();
        }
        if(employable > 20 && unemployed*10 > employable) {
            auto& a = out.emplace_back();
            a.fKey = "unemployment";
            a.fSeverity = unemployed*5 > employable ? 2 : 1;
            a.fIcon = "population";
            a.fTitle = tr("adv_unemployment", "Unemployment") + ": " +
                       num(std::round(100.0*unemployed/employable)) + "%";
            a.fDetail = tr("adv_unemployed", "Without work") + ": " + num(unemployed);
            a.fHint = tr("adv_hint_unemployment", "Build workplaces; idle people grow unhappy.");
            a.fWeight = unemployed;
        }
    }

    // --- stores and money, from the monthly record
    {
        const auto& ss = city->history().samples();
        const int food = city->resourceCount(eResourceType::food);
        const int pop = city->population();
        int foodLeft = -1;
        int moneyLeft = -1;
        const int n = ss.size();
        if(n >= 4) {
            const auto& now = ss[n - 1];
            const auto& then = ss[n - 4];
            const double f = (then.fFood - now.fFood)/3.0;
            if(f >= 1 && food > 0) foodLeft = static_cast<int>(food/f);
            const double d = (then.fDrachmas - now.fDrachmas)/3.0;
            const int money = city->resourceCount(eResourceType::drachmas);
            if(d >= 20 && money > 0) moneyLeft = static_cast<int>(money/d);
        }
        if(pop > 0 && food <= 0) {
            auto& a = out.emplace_back();
            a.fKey = "food";
            a.fSeverity = 2;
            a.fIcon = "husbandry";
            a.fTitle = tr("adv_no_food", "No food in the granaries");
            a.fHint = tr("adv_hint_granary", "Farms, fishing and hunting fill the granaries; food vendors take from there.");
            a.fWeight = 800;
        } else if(foodLeft >= 0 && foodLeft <= 6) {
            auto& a = out.emplace_back();
            a.fKey = "food";
            a.fSeverity = foodLeft <= 3 ? 2 : 1;
            a.fIcon = "husbandry";
            auto t = tr("adv_food_left", "Food lasts about %m more months");
            eStringHelpers::replaceAll(t, "%m", num(std::max(1, foodLeft)));
            a.fTitle = t;
            a.fDetail = tr("adv_in_store", "In storage") + ": " + num(food);
            a.fHint = tr("adv_hint_granary", "Farms, fishing and hunting fill the granaries; food vendors take from there.");
            a.fWeight = 700 - foodLeft;
        }
        const int money = city->resourceCount(eResourceType::drachmas);
        if(money < 0) {
            auto& a = out.emplace_back();
            a.fKey = "money";
            a.fSeverity = 2;
            a.fIcon = "coins";
            a.fTitle = tr("adv_debt", "The treasury is in debt") + ": " + num(money);
            a.fHint = tr("adv_hint_debt", "Building stops at 1000 in debt. Raise taxes, export goods or cut wages.");
            a.fWeight = 850;
        } else if(moneyLeft >= 0 && moneyLeft <= 6) {
            auto& a = out.emplace_back();
            a.fKey = "money";
            a.fSeverity = moneyLeft <= 3 ? 2 : 1;
            a.fIcon = "coins";
            auto t = tr("adv_money_left", "The treasury lasts about %m more months");
            eStringHelpers::replaceAll(t, "%m", num(std::max(1, moneyLeft)));
            a.fTitle = t;
            a.fHint = tr("adv_hint_money", "Spending runs ahead of income: check taxes, wages and trade.");
            a.fWeight = 600 - moneyLeft;
        }
        if(plague.empty() && pop > 0 && city->health() < 50) {
            auto& a = out.emplace_back();
            a.fKey = "health";
            a.fSeverity = 1;
            a.fIcon = "hygiene";
            a.fTitle = tr("adv_health", "Poor health") + ": " + num(city->health()) + "%";
            a.fHint = tr("adv_hint_health", "Hospitals and fountains keep people healthy.");
            a.fWeight = 100 - city->health();
        }
    }

    std::stable_sort(out.begin(), out.end(), [](const eAdvice& a, const eAdvice& b) {
        if(a.fSeverity != b.fSeverity) return a.fSeverity > b.fSeverity;
        return a.fWeight > b.fWeight;
    });
    if(static_cast<int>(out.size()) > max) out.resize(max);
    if(out.empty()) {
        auto& a = out.emplace_back();
        a.fKey = "fine";
        a.fSeverity = 0;
        a.fIcon = "goals";
        a.fTitle = tr("adv_fine", "The city is in good order");
        a.fHint = tr("adv_hint_fine", "Nothing needs your attention right now.");
    }
    return out;
}
