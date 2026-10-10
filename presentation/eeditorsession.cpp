#include "eeditorsession.h"

#include <algorithm>
#include <functional>
#include <map>
#include <cstdio>
#include <iomanip>
#include <set>
#include <vector>
#include <filesystem>

#include "engine/ecampaign.h"
#include "engine/egameboard.h"
#include "engine/eterrainedit.h"
#include "engine/eworldboard.h"
#include "elanguage.h"
#include "egamedir.h"
#include "evectorhelpers.h"
#include "buildings/ebuilding.h"
#include "buildings/esmallhouse.h"
#include "buildings/eelitehousing.h"
#include "characters/esoldierbanner.h"
#include "characters/gods/egod.h"
#include "characters/heroes/ehero.h"
#include "characters/monsters/emonster.h"
#include "gameEvents/egameevent.h"
#include "gameEvents/ecityeventvalue.h"
#include "gameEvents/eresourceeventvalue.h"
#include "gameEvents/ecounteventvalue.h"
#include "gameEvents/egodeventvalue.h"
#include "gameEvents/emonstereventvalue.h"
#include "gameEvents/emonsterseventvalue.h"
#include "gameEvents/epointeventvalue.h"
#include "gameEvents/egodreasoneventvalue.h"
#include "gameEvents/eattackingcityeventvalue.h"
#include "gameEvents/ecitybecomesevent.h"
#include "gameEvents/ereceiverequestevent.h"
#include "gameEvents/etroopsrequestevent.h"
#include "gameEvents/emonsterinvasioneventbase.h"
#include "gameEvents/etidalwaveevent.h"
#include "gameEvents/egodattackevent.h"
#include "gameEvents/einvasionevent.h"
#include "gameEvents/egodquesteventbase.h"
#include "gameEvents/egoddisasterevent.h"

namespace {
std::string q(const std::string& s) {
    std::ostringstream out; out << '"';
    for(unsigned char c : s) {
        if(c == '"' || c == '\\') out << '\\' << c;
        else if(c == '\n') out << "\\n";
        else if(c == '\r') out << "\\r";
        else if(c == '\t') out << "\\t";
        else if(c < 32) out << "\\u" << std::hex << std::setw(4) << std::setfill('0') << int(c) << std::dec;
        else out << c;
    }
    out << '"'; return out.str();
}
std::string error(const std::string& code) { return "{\"error\":\"" + code + "\"}"; }

// One field of a form. `options` for a choice: value and label.
struct eField {
    std::string fId;
    std::string fLabel;
    std::string fKind; // int, choice, bool
    int fValue = 0;
    int fMin = 0;
    int fMax = 99999;
    std::vector<std::pair<int, std::string>> fOptions;
    std::string json() const {
        std::ostringstream o;
        o << "{\"id\":" << q(fId) << ",\"label\":" << q(fLabel) << ",\"kind\":\"" << fKind << "\",\"value\":" << fValue;
        if(fKind == "int") o << ",\"min\":" << fMin << ",\"max\":" << fMax;
        if(fKind == "choice") {
            o << ",\"options\":["; bool first = true;
            for(const auto& option : fOptions) { if(!first) o << ','; first = false; o << "{\"value\":" << option.first << ",\"label\":" << q(option.second) << '}'; }
            o << ']';
        }
        o << '}'; return o.str();
    }
};
std::string fieldsJson(const std::vector<eField>& fields) {
    std::ostringstream o; o << '['; bool first = true;
    for(const auto& f : fields) { if(!first) o << ','; first = false; o << f.json(); }
    o << ']'; return o.str();
}
eField intField(const std::string& id, const std::string& label, int value, int min = 0, int max = 99999) {
    eField f; f.fId = id; f.fLabel = label; f.fKind = "int"; f.fValue = value; f.fMin = min; f.fMax = max; return f;
}
eField choiceField(const std::string& id, const std::string& label, int value, const std::vector<std::pair<int, std::string>>& options) {
    eField f; f.fId = id; f.fLabel = label; f.fKind = "choice"; f.fValue = value; f.fOptions = options; return f;
}
eField boolField(const std::string& id, const std::string& label, bool value) {
    eField f; f.fId = id; f.fLabel = label; f.fKind = "bool"; f.fValue = value ? 1 : 0; return f;
}

std::vector<std::pair<int, std::string>> godOptions() {
    std::vector<std::pair<int, std::string>> r;
    for(int g = 0; g <= int(eGodType::zeus); ++g) r.push_back({g, eGod::sGodName(static_cast<eGodType>(g))});
    return r;
}
std::vector<std::pair<int, std::string>> monsterOptions() {
    std::vector<std::pair<int, std::string>> r;
    for(int m = 0; m <= int(eMonsterType::satyr); ++m) r.push_back({m, eMonster::sMonsterName(static_cast<eMonsterType>(m))});
    return r;
}
std::vector<std::pair<int, std::string>> heroOptions() {
    std::vector<std::pair<int, std::string>> r;
    for(int h = 0; h <= int(eHeroType::theseus); ++h) r.push_back({h, eHero::sHeroName(static_cast<eHeroType>(h))});
    return r;
}
// Goods (and drachmas), as the SDL resource buttons offer them; "none" first where a slot may be empty.
std::vector<std::pair<int, std::string>> resourceOptions(const bool withNone) {
    std::vector<std::pair<int, std::string>> r;
    if(withNone) r.push_back({int(eResourceType::none), "-"});
    for(const auto t : eResourceTypeHelpers::extractResourceTypes(eResourceType::allBasic | eResourceType::drachmas))
        r.push_back({int(t), eResourceTypeHelpers::typeName(t)});
    return r;
}
std::vector<std::pair<int, std::string>> cityOptions(eWorldBoard& world, const bool withNone) {
    std::vector<std::pair<int, std::string>> r;
    if(withNone) r.push_back({-1, "-"});
    for(const auto& c : world.cities()) r.push_back({int(c->cityId()), c->nameWithId()});
    return r;
}
std::vector<std::pair<int, std::string>> monthOptions() {
    std::vector<std::pair<int, std::string>> r;
    for(int m = 0; m < 12; ++m) r.push_back({m, eLanguage::zeusText(160, m)});
    return r;
}

// The events an editor may add (the SDL event chooser's list, in its order, with its names).
struct eEventKind { eGameEventType fType; std::function<std::string()> fName; };
const std::vector<eEventKind>& eventKinds() {
    static const std::vector<eEventKind> kinds{
        {eGameEventType::godAttack, [] { return eLanguage::zeusText(156, 27); }},
        {eGameEventType::monsterUnleashed, [] { return eLanguage::zeusText(182, 1); }},
        {eGameEventType::monsterInvasion, [] { return eLanguage::zeusText(182, 2); }},
        {eGameEventType::monsterInCity, [] { return eLanguage::zeusText(182, 0); }},
        {eGameEventType::invasion, [] { return eLanguage::zeusText(156, 2); }},
        {eGameEventType::receiveRequest, [] { return eLanguage::zeusText(156, 1); }},
        {eGameEventType::giftFrom, [] { return eLanguage::zeusText(156, 23); }},
        {eGameEventType::godQuest, [] { return eLanguage::zeusText(156, 4); }},
        {eGameEventType::militaryChange, [] { return eLanguage::text("military_change_long_name"); }},
        {eGameEventType::economicChange, [] { return eLanguage::text("economic_change_long_name"); }},
        {eGameEventType::troopsRequest, [] { return eLanguage::zeusText(290, 6); }},
        {eGameEventType::godDisaster, [] { return eLanguage::zeusText(35, 13); }},
        {eGameEventType::rivalArmyAway, [] { return eLanguage::zeusText(156, 20); }},
        {eGameEventType::earthquake, [] { return eLanguage::zeusText(156, 3); }},
        {eGameEventType::lavaFlow, [] { return eLanguage::zeusText(156, 24); }},
        {eGameEventType::tidalWave, [] { return eLanguage::zeusText(156, 25); }},
        {eGameEventType::sinkLand, [] { return eLanguage::zeusText(156, 28); }},
        {eGameEventType::cityBecomes, [] { return eLanguage::zeusText(290, 35); }},
        {eGameEventType::tradeShutdowns, [] { return eLanguage::zeusText(35, 2); }},
        {eGameEventType::tradeOpensUp, [] { return eLanguage::zeusText(35, 3); }},
        {eGameEventType::supplyChange, [] { return eLanguage::text("supply_change_short_name"); }},
        {eGameEventType::demandChange, [] { return eLanguage::text("demand_change_short_name"); }},
        {eGameEventType::priceChange, [] { return eLanguage::text("price_change_short_name"); }},
        {eGameEventType::wageChange, [] { return eLanguage::text("wage_change"); }},
    };
    return kinds;
}

// The terrain tools by name (the SDL terrain panel's actions).
const std::map<std::string, eTerrainEditMode>& toolModes() {
    using M = eTerrainEditMode;
    static const std::map<std::string, eTerrainEditMode> modes{
        {"dry", M::dry}, {"beach", M::beach}, {"water", M::water}, {"marsh", M::marsh}, {"fertile", M::fertile}, {"forest", M::forest},
        {"chopped_forest", M::choppedForest}, {"flat_stones", M::flatStones}, {"copper", M::bronze}, {"silver", M::silver}, {"orichalc", M::orichalc},
        {"tall_stones", M::tallStones}, {"marble", M::marble}, {"scrub", M::scrub}, {"scrub_area", M::scrubArea}, {"remove_scrub", M::removeScrub},
        {"soften_scrub", M::softenScrub}, {"rainforest", M::rainforest}, {"normal_forest", M::normalForest}, {"raise", M::raise}, {"lower", M::lower},
        {"raise_high", M::raiseHigh}, {"lower_high", M::lowerHigh}, {"level_out", M::levelOut}, {"reset_elevation", M::resetElev},
        {"half_slope", M::halfSlope}, {"walkable", M::makeWalkable}, {"boar", M::boar}, {"deer", M::deer}, {"fish", M::fish}, {"urchin", M::urchin},
        {"fire", M::fire}, {"ruins", M::ruins}, {"entry_point", M::entryPoint}, {"exit_point", M::exitPoint}, {"river_entry", M::riverEntryPoint},
        {"river_exit", M::riverExitPoint}, {"land_invasion", M::landInvasion}, {"sea_invasion", M::seaInvasion}, {"disembark", M::disembarkPoint},
        {"monster_point", M::monsterPoint}, {"quake", M::quake}, {"lava", M::lava}, {"tidal_wave", M::tidalWave}, {"land_slide", M::landSlide},
        {"disaster_point", M::disasterPoint}, {"land_slide_point", M::landSlidePoint}, {"territory", M::cityTerritory},
        {"assign_territory", M::assignAllCityTerritory}};
    return modes;
}

// The goals an editor may add (the SDL goal chooser's list).
const std::vector<eEpisodeGoalType>& goalKinds() {
    static const std::vector<eEpisodeGoalType> kinds{
        eEpisodeGoalType::population, eEpisodeGoalType::treasury, eEpisodeGoalType::sanctuary, eEpisodeGoalType::support,
        eEpisodeGoalType::quest, eEpisodeGoalType::yearlyProduction, eEpisodeGoalType::slay, eEpisodeGoalType::yearlyProfit,
        eEpisodeGoalType::rule, eEpisodeGoalType::housing, eEpisodeGoalType::setAsideGoods, eEpisodeGoalType::surviveUntil,
        eEpisodeGoalType::completeBefore, eEpisodeGoalType::tradingPartners};
    return kinds;
}

// The buildings an episode lets a city build or not (the SDL editor's buildings list).
const std::vector<eBuildingType>& optionalBuildings() {
    static const std::vector<eBuildingType> list{
        eBuildingType::eliteHousing, eBuildingType::wheatFarm, eBuildingType::carrotsFarm, eBuildingType::onionsFarm,
        eBuildingType::vine, eBuildingType::oliveTree, eBuildingType::orangeTree, eBuildingType::dairy, eBuildingType::cardingShed,
        eBuildingType::fishery, eBuildingType::urchinQuay, eBuildingType::huntingLodge, eBuildingType::corral, eBuildingType::mint,
        eBuildingType::foundry, eBuildingType::timberMill, eBuildingType::masonryShop, eBuildingType::refinery,
        eBuildingType::blackMarbleWorkshop, eBuildingType::winery, eBuildingType::olivePress, eBuildingType::sculptureStudio,
        eBuildingType::armory, eBuildingType::horseRanch, eBuildingType::chariotFactory, eBuildingType::triremeWharf,
        eBuildingType::hippodromePiece,
        eBuildingType::commonHouse, eBuildingType::road, eBuildingType::fountain,
        eBuildingType::hospital, eBuildingType::maintenanceOffice, eBuildingType::watchPost,
        eBuildingType::taxOffice, eBuildingType::palace, eBuildingType::warehouse, eBuildingType::granary,
        eBuildingType::tradePost, eBuildingType::pier, eBuildingType::commonAgora, eBuildingType::grandAgora,
        eBuildingType::foodVendor, eBuildingType::fleeceVendor, eBuildingType::oilVendor,
        eBuildingType::wineVendor, eBuildingType::armsVendor, eBuildingType::horseTrainer,
        eBuildingType::chariotVendor, eBuildingType::gymnasium, eBuildingType::podium,
        eBuildingType::dramaSchool, eBuildingType::theater, eBuildingType::college, eBuildingType::stadium,
        eBuildingType::bibliotheke, eBuildingType::observatory, eBuildingType::university,
        eBuildingType::laboratory, eBuildingType::inventorsWorkshop, eBuildingType::museum,
        eBuildingType::artisansGuild, eBuildingType::wall, eBuildingType::tower, eBuildingType::gatehouse,
        eBuildingType::bridge, eBuildingType::park, eBuildingType::bench, eBuildingType::gazebo,
        eBuildingType::flowerGarden, eBuildingType::hedgeMaze, eBuildingType::fishPond,
        eBuildingType::tallObelisk, eBuildingType::shortObelisk, eBuildingType::sundial,
        eBuildingType::topiary, eBuildingType::spring, eBuildingType::stoneCircle,
        eBuildingType::waterPark, eBuildingType::dolphinSculpture, eBuildingType::orrery,
        eBuildingType::shellGarden, eBuildingType::baths, eBuildingType::birdBath,
        eBuildingType::avenue, eBuildingType::boulevard, eBuildingType::doricColumn,
        eBuildingType::ionicColumn, eBuildingType::corinthianColumn};
    return list;
}

// The fields of a goal, as the SDL goal editor (eEpisodeGoalWidget) offers them for its type.
std::vector<eField> goalFields(const eEpisodeGoal& g, eWorldBoard& world) {
    std::vector<eField> f;
    const auto count = [&](int max) { f.push_back(intField("count", eLanguage::zeusText(44, 361), g.fRequiredCount, 0, max)); };
    switch(g.fType) {
    case eEpisodeGoalType::population:
    case eEpisodeGoalType::treasury:
    case eEpisodeGoalType::hippodrome:
    case eEpisodeGoalType::yearlyProfit: count(99999); break;
    case eEpisodeGoalType::tradingPartners:
        count(99);
        f.push_back(boolField("working_route", eLanguage::text("working_trade_routes_option"), g.fEnumInt2 == 1));
        break;
    case eEpisodeGoalType::sanctuary: f.push_back(choiceField("enum1", eLanguage::zeusText(44, 215), g.fEnumInt1, godOptions())); break;
    case eEpisodeGoalType::support: {
        std::vector<std::pair<int, std::string>> kinds;
        for(const auto t : {eBannerType::rockThrower, eBannerType::hoplite, eBannerType::horseman, eBannerType::trireme})
            kinds.push_back({int(t), eSoldierBanner::sName(t, false)});
        f.push_back(choiceField("enum1", eLanguage::zeusText(44, 358), g.fEnumInt1, kinds));
        count(99999);
    } break;
    case eEpisodeGoalType::quest:
        f.push_back(choiceField("enum1", eLanguage::zeusText(44, 391), g.fEnumInt1, godOptions()));
        f.push_back(choiceField("enum2", eLanguage::zeusText(44, 357), g.fEnumInt2, {{0, "1"}, {1, "2"}}));
        break;
    case eEpisodeGoalType::yearlyProduction:
    case eEpisodeGoalType::setAsideGoods:
        f.push_back(choiceField("enum1", eLanguage::zeusText(44, 360), g.fEnumInt1, resourceOptions(false)));
        count(g.fType == eEpisodeGoalType::yearlyProduction ? 999 : 99999);
        break;
    case eEpisodeGoalType::slay: f.push_back(choiceField("enum1", eLanguage::zeusText(44, 175), g.fEnumInt1, monsterOptions())); break;
    case eEpisodeGoalType::rule: f.push_back(choiceField("enum1", eLanguage::zeusText(44, 359), g.fEnumInt1, cityOptions(world, false))); break;
    case eEpisodeGoalType::housing: {
        std::vector<std::pair<int, std::string>> levels;
        for(int i = 0; i < 7; ++i) levels.push_back({i, eSmallHouse::sName(i)});
        for(int i = 0; i < 5; ++i) levels.push_back({7 + i, eEliteHousing::sName(i)});
        f.push_back(choiceField("housing", eLanguage::zeusText(44, 358), g.fEnumInt1 ? 7 + g.fEnumInt2 : g.fEnumInt2, levels));
        count(99999);
    } break;
    case eEpisodeGoalType::surviveUntil:
    case eEpisodeGoalType::completeBefore:
        f.push_back(intField("enum1", eLanguage::zeusText(8, 45), g.fEnumInt1, 1, 31));
        f.push_back(choiceField("enum2", eLanguage::zeusText(8, 5), g.fEnumInt2, monthOptions()));
        f.push_back(intField("count", eLanguage::zeusText(8, 9), g.fRequiredCount, -9999, 9999));
        break;
    case eEpisodeGoalType::pyramid:
        f.push_back(intField("enum1", eLanguage::zeusText(44, 378), g.fEnumInt1, -1, 9999));
        count(100);
        break;
    }
    return f;
}

// The fields of an event, as the SDL event editor (eEventWidgetBase and the four special ones) offers them.
std::vector<eField> eventFields(eGameEvent& e) {
    std::vector<eField> f;
    auto& world = *e.worldBoard();
    if(const auto ee = dynamic_cast<eCityBecomesEvent*>(&e)) {
        const std::vector<std::pair<int, std::string>> o{
            {int(eCityBecomesType::ally), eLanguage::zeusText(253, 0)}, {int(eCityBecomesType::rival), eLanguage::zeusText(253, 1)},
            {int(eCityBecomesType::vassal), eLanguage::zeusText(253, 2)}, {int(eCityBecomesType::active), eLanguage::zeusText(44, 248)},
            {int(eCityBecomesType::inactive), eLanguage::zeusText(44, 249)}, {int(eCityBecomesType::visible), eLanguage::zeusText(44, 307)},
            {int(eCityBecomesType::invisible), eLanguage::zeusText(44, 306)}, {int(eCityBecomesType::rebellionOver), eLanguage::zeusText(35, 23)},
            {int(eCityBecomesType::conquered), eLanguage::zeusText(35, 24)}};
        f.push_back(choiceField("becomes", eLanguage::zeusText(44, 358), int(ee->type()), o));
    }
    if(const auto ee = dynamic_cast<eReceiveRequestEvent*>(&e)) {
        const std::vector<std::pair<int, std::string>> o{
            {int(eReceiveRequestType::general), eLanguage::zeusText(290, 1)}, {int(eReceiveRequestType::festival), eLanguage::zeusText(290, 2)},
            {int(eReceiveRequestType::project), eLanguage::zeusText(290, 3)}, {int(eReceiveRequestType::famine), eLanguage::zeusText(290, 4)},
            {int(eReceiveRequestType::financialWoes), eLanguage::zeusText(290, 5)}};
        f.push_back(choiceField("request", eLanguage::zeusText(44, 358), int(ee->requestType()), o));
    }
    if(const auto ee = dynamic_cast<eTroopsRequestEvent*>(&e)) {
        const std::vector<std::pair<int, std::string>> o{
            {int(eTroopsRequestEventType::cityUnderAttack), eLanguage::zeusText(290, 7)},
            {int(eTroopsRequestEventType::cityAttacksRival), eLanguage::zeusText(290, 8)},
            {int(eTroopsRequestEventType::greekCityTerrorized), eLanguage::zeusText(290, 9)}};
        f.push_back(choiceField("troops", eLanguage::zeusText(44, 358), int(ee->type()), o));
        f.push_back(choiceField("effect", eLanguage::zeusText(44, 286), int(ee->effect()),
            {{0, eLanguage::zeusText(44, 287)}, {1, eLanguage::zeusText(44, 288)}, {2, eLanguage::zeusText(44, 289)}}));
    }
    if(const auto ee = dynamic_cast<ePointEventValue*>(&e)) {
        f.push_back(intField("point_min", eLanguage::zeusText(44, 362), ee->minPointId(), 1, 999));
        f.push_back(intField("point_max", eLanguage::zeusText(44, 362), ee->maxPointId(), 1, 999));
    }
    if(const auto ee = dynamic_cast<eCountEventValue*>(&e)) {
        f.push_back(intField("count_min", eLanguage::zeusText(44, 361), ee->minCount(), 0, 99999));
        f.push_back(intField("count_max", eLanguage::zeusText(44, 361), ee->maxCount(), 0, 99999));
    }
    if(const auto ee = dynamic_cast<eResourceEventValue*>(&e)) {
        for(int i = 0; i < 3; ++i) f.push_back(choiceField("resource" + std::to_string(i), eLanguage::zeusText(44, 360), int(ee->resourceType(i)), resourceOptions(true)));
    }
    if(const auto ee = dynamic_cast<eMonstersEventValue*>(&e)) {
        auto options = monsterOptions(); options.insert(options.begin(), {-1, "-"});
        for(int i = 0; i < 3; ++i) { bool valid; const auto m = ee->monsterType(i, valid); f.push_back(choiceField("monster" + std::to_string(i), eLanguage::zeusText(44, 360), valid ? int(m) : -1, options)); }
    }
    if(const auto ee = dynamic_cast<eMonsterInvasionEventBase*>(&e)) {
        f.push_back(choiceField("aggressive", eLanguage::zeusText(44, 177), int(ee->aggressivness()),
            {{0, eLanguage::zeusText(94, 0)}, {1, eLanguage::zeusText(94, 1)}, {2, eLanguage::zeusText(94, 2)}, {3, eLanguage::zeusText(94, 3)}}));
    }
    if(const auto ee = dynamic_cast<eTidalWaveEvent*>(&e)) {
        f.push_back(choiceField("permanent", eLanguage::zeusText(44, 394), ee->permanent() ? 1 : 0, {{0, eLanguage::zeusText(18, 0)}, {1, eLanguage::zeusText(18, 1)}}));
    }
    if(const auto ee = dynamic_cast<eCityEventValue*>(&e)) {
        f.push_back(choiceField("city_min", eLanguage::zeusText(44, 359), ee->minCityId(), cityOptions(world, false)));
        f.push_back(choiceField("city_max", eLanguage::zeusText(44, 359), ee->maxCityId(), cityOptions(world, false)));
    }
    if(const auto ee = dynamic_cast<eAttackingCityEventValue*>(&e)) {
        const auto& c = ee->attackingCity();
        f.push_back(choiceField("attacker", eLanguage::zeusText(44, 271), c ? int(c->cityId()) : -1, cityOptions(world, true)));
    }
    if(const auto ee = dynamic_cast<eGodReasonEventValue*>(&e)) {
        f.push_back(choiceField("god_reason", eLanguage::zeusText(44, 215), ee->godReason() ? 1 : 0, {{0, eLanguage::zeusText(18, 0)}, {1, eLanguage::zeusText(18, 1)}}));
    }
    if(const auto ee = dynamic_cast<eGodEventValue*>(&e)) f.push_back(choiceField("god", eLanguage::zeusText(44, 215), int(ee->god()), godOptions()));
    if(const auto ee = dynamic_cast<eMonsterEventValue*>(&e)) f.push_back(choiceField("monster", eLanguage::zeusText(44, 175), int(ee->monster()), monsterOptions()));
    if(const auto ee = dynamic_cast<eGodAttackEvent*>(&e)) {
        f.push_back(boolField("random", eLanguage::text("random"), ee->random()));
        for(int g = 0; g <= int(eGodType::zeus); ++g)
            f.push_back(boolField("attacker" + std::to_string(g), eGod::sGodName(static_cast<eGodType>(g)), eVectorHelpers::contains(ee->types(), static_cast<eGodType>(g))));
    }
    if(const auto ee = dynamic_cast<eInvasionEvent*>(&e)) {
        f.push_back(choiceField("hardcoded", eLanguage::zeusText(44, 358), ee->hardcoded() ? 0 : 1, {{0, eLanguage::text("hardcoded")}, {1, eLanguage::text("from_city")}}));
    }
    if(const auto ee = dynamic_cast<eGodQuestEventBase*>(&e)) {
        f.push_back(choiceField("quest_god", eLanguage::zeusText(44, 391), int(ee->god()), godOptions()));
        f.push_back(choiceField("quest_id", eLanguage::zeusText(44, 357), ee->id() == eGodQuestId::godQuest1 ? 0 : 1, {{0, "1"}, {1, "2"}}));
        f.push_back(choiceField("quest_hero", eLanguage::zeusText(44, 267), int(ee->hero()), heroOptions()));
    }
    if(const auto ee = dynamic_cast<eGodDisasterEvent*>(&e)) f.push_back(intField("duration", eLanguage::zeusText(44, 356), ee->duration(), 0, 9999));
    // When: years (a range), months and days after the episode begins; the period between runs; how often it repeats.
    f.push_back(intField("years_min", eLanguage::zeusText(8, 9), e.datePlusYearsMin()));
    f.push_back(intField("years_max", eLanguage::zeusText(8, 9), e.datePlusYearsMax()));
    f.push_back(intField("months", eLanguage::zeusText(8, 5), e.datePlusMonths()));
    f.push_back(intField("days", eLanguage::zeusText(8, 45), e.datePlusDays()));
    f.push_back(intField("period_min", eLanguage::text("period:"), e.periodMin(), 31, 99999));
    f.push_back(intField("period_max", eLanguage::text("period:"), e.periodMax(), 31, 99999));
    f.push_back(intField("repeat", eLanguage::text("repeat:"), e.repeat(), 0, 99999));
    f.push_back(choiceField("complete", eLanguage::zeusText(44, 157), e.episodeCompleteEvent() ? 1 : 0, {{0, eLanguage::zeusText(44, 157)}, {1, eLanguage::zeusText(44, 160)}}));
    if(!e.warnings().empty() || e.type() == eGameEventType::receiveRequest || e.type() == eGameEventType::troopsRequest)
        f.push_back(intField("warning", eLanguage::zeusText(44, 368), e.warningMonths()));
    return f;
}

bool setEventField(eGameEvent& e, const std::string& id, const int v) {
    auto& world = *e.worldBoard();
    const auto cityById = [&](int cid) -> stdsptr<eWorldCity> { return cid < 0 ? nullptr : world.cityWithId(static_cast<eCityId>(cid)); };
    if(id == "years_min") e.setDatePlusYearsMin(std::max(0, v));
    else if(id == "years_max") e.setDatePlusYearsMax(std::max(0, v));
    else if(id == "months") e.setDatePlusMonths(std::max(0, v));
    else if(id == "days") e.setDatePlusDays(std::max(0, v));
    else if(id == "period_min") e.setPeriodMin(std::max(31, v));
    else if(id == "period_max") e.setPeriodMax(std::max(31, v));
    else if(id == "repeat") e.setRepeat(std::max(0, v));
    else if(id == "complete") e.setEpisodeCompleteEvent(v == 1);
    else if(id == "warning") e.setWarningMonths(std::max(0, v));
    else if(const auto ee = dynamic_cast<eCityBecomesEvent*>(&e); ee && id == "becomes") ee->setType(static_cast<eCityBecomesType>(v));
    else if(const auto ee = dynamic_cast<eReceiveRequestEvent*>(&e); ee && id == "request") ee->setRequestType(static_cast<eReceiveRequestType>(v));
    else if(const auto ee = dynamic_cast<eTroopsRequestEvent*>(&e); ee && id == "troops") ee->setType(static_cast<eTroopsRequestEventType>(v));
    else if(const auto ee = dynamic_cast<eTroopsRequestEvent*>(&e); ee && id == "effect") ee->setEffect(static_cast<eTroopsRequestEventEffect>(std::clamp(v, 0, 2)));
    else if(const auto ee = dynamic_cast<ePointEventValue*>(&e); ee && id == "point_min") ee->setMinPointId(std::clamp(v, 1, 999));
    else if(const auto ee = dynamic_cast<ePointEventValue*>(&e); ee && id == "point_max") ee->setMaxPointId(std::clamp(v, 1, 999));
    else if(const auto ee = dynamic_cast<eCountEventValue*>(&e); ee && id == "count_min") ee->setMinCount(std::max(0, v));
    else if(const auto ee = dynamic_cast<eCountEventValue*>(&e); ee && id == "count_max") ee->setMaxCount(std::max(0, v));
    else if(const auto ee = dynamic_cast<eResourceEventValue*>(&e); ee && id.rfind("resource", 0) == 0 && id.size() == 9 && id[8] >= '0' && id[8] <= '2') ee->setResourceType(id[8] - '0', static_cast<eResourceType>(v));
    else if(const auto ee = dynamic_cast<eMonstersEventValue*>(&e); ee && id.rfind("monster", 0) == 0 && id.size() == 8 && id[7] >= '0' && id[7] <= '2') {
        if(v < 0) {
            // An empty slot: the others are kept (the SDL buttons can only choose a monster; this clears one).
            std::vector<eMonsterType> kept; const int slot = id[7] - '0';
            for(int i = 0; i < 3; ++i) { bool valid; const auto m = ee->monsterType(i, valid); if(valid && i != slot) kept.push_back(m); }
            ee->setMonsterTypes(kept);
        } else ee->setMonsterType(id[7] - '0', static_cast<eMonsterType>(std::clamp(v, 0, int(eMonsterType::satyr))));
    }
    else if(const auto ee = dynamic_cast<eMonsterInvasionEventBase*>(&e); ee && id == "aggressive") ee->setAggressivness(static_cast<eMonsterAggressivness>(std::clamp(v, 0, 3)));
    else if(const auto ee = dynamic_cast<eTidalWaveEvent*>(&e); ee && id == "permanent") ee->setPermanent(v == 1);
    else if(const auto ee = dynamic_cast<eCityEventValue*>(&e); ee && id == "city_min") ee->setMinCityId(v);
    else if(const auto ee = dynamic_cast<eCityEventValue*>(&e); ee && id == "city_max") ee->setMaxCityId(v);
    else if(const auto ee = dynamic_cast<eAttackingCityEventValue*>(&e); ee && id == "attacker") ee->setAttackingCity(cityById(v));
    else if(const auto ee = dynamic_cast<eGodReasonEventValue*>(&e); ee && id == "god_reason") ee->setGodReason(v == 1);
    else if(const auto ee = dynamic_cast<eGodEventValue*>(&e); ee && id == "god") ee->setGod(static_cast<eGodType>(std::clamp(v, 0, int(eGodType::zeus))));
    else if(const auto ee = dynamic_cast<eMonsterEventValue*>(&e); ee && id == "monster") ee->setMonster(static_cast<eMonsterType>(std::clamp(v, 0, int(eMonsterType::satyr))));
    else if(const auto ee = dynamic_cast<eGodAttackEvent*>(&e); ee && id == "random") ee->setRandom(v == 1);
    else if(const auto ee = dynamic_cast<eGodAttackEvent*>(&e); ee && id.rfind("attacker", 0) == 0 && id.size() > 8) {
        const int g = std::stoi(id.substr(8)); if(g < 0 || g > int(eGodType::zeus)) return false;
        auto types = ee->types(); const auto god = static_cast<eGodType>(g);
        if(v) { if(!eVectorHelpers::contains(types, god)) types.push_back(god); } else eVectorHelpers::remove(types, god);
        ee->setTypes(types);
    }
    else if(const auto ee = dynamic_cast<eInvasionEvent*>(&e); ee && id == "hardcoded") ee->setHardcoded(v == 0);
    else if(const auto ee = dynamic_cast<eGodQuestEventBase*>(&e); ee && id == "quest_god") ee->setGod(static_cast<eGodType>(std::clamp(v, 0, int(eGodType::zeus))));
    else if(const auto ee = dynamic_cast<eGodQuestEventBase*>(&e); ee && id == "quest_id") ee->setId(v == 0 ? eGodQuestId::godQuest1 : eGodQuestId::godQuest2);
    else if(const auto ee = dynamic_cast<eGodQuestEventBase*>(&e); ee && id == "quest_hero") ee->setHero(static_cast<eHeroType>(std::clamp(v, 0, int(eHeroType::theseus))));
    else if(const auto ee = dynamic_cast<eGodDisasterEvent*>(&e); ee && id == "duration") ee->setDuration(std::max(0, v));
    else return false;
    return true;
}

bool setGoalField(eEpisodeGoal& g, const std::string& id, const int v) {
    if(id == "count") g.fRequiredCount = v;
    else if(id == "enum1") g.fEnumInt1 = v;
    else if(id == "enum2") g.fEnumInt2 = v;
    else if(id == "housing") { g.fEnumInt1 = v > 6 ? 1 : 0; g.fEnumInt2 = v > 6 ? v - 7 : v; }
    else if(id == "working_route" && g.fType == eEpisodeGoalType::tradingPartners && (v == 0 || v == 1)) g.fEnumInt2 = v;
    else return false;
    return true;
}
}

eEditorSession::eEditorSession(const std::shared_ptr<eCampaign>& campaign) :
    mCampaign(campaign) {}

eGameBoard& eEditorSession::board() { return mCampaign->parentCityBoard(); }

std::string eEditorSession::overview() {
    auto& c = *mCampaign;
    auto& world = c.worldBoard();
    std::ostringstream o;
    const auto date = c.date();
    o << "{\"kind\":\"editor\",\"title\":" << q(c.titleText()) << ",\"introduction\":" << q(c.introductionText()) << ",\"complete\":" << q(c.completeText())
      << ",\"saved\":" << (mChanged ? "false" : "true") << ",\"date\":[" << date.day() << ',' << int(date.month()) << ',' << date.year() << "],\"date_text\":" << q(date.shortString())
      << ",\"months\":[";
    for(int m = 0; m < 12; ++m) { if(m) o << ','; o << q(eLanguage::zeusText(160, m)); }
    o << "],\"funds\":[";
    bool first = true;
    auto& b = c.parentCityBoard();
    for(const auto pid : b.playersOnBoard()) {
        if(!first) o << ','; first = false;
        o << "{\"player\":" << int(pid) << ",\"name\":" << q(b.cityName(b.playerCapital(pid))) << ",\"value\":" << c.initialFunds(pid) << '}';
    }
    o << "],\"prices\":["; first = true;
    for(const auto& p : c.prices()) {
        if(!first) o << ','; first = false;
        o << "{\"resource\":" << int(p.first) << ",\"name\":" << q(eResourceTypeHelpers::typeName(p.first)) << ",\"value\":" << p.second << ",\"default\":" << eResourceTypeHelpers::defaultPrice(p.first) << '}';
    }
    o << "],\"parent\":["; first = true;
    const auto& parents = c.parentCityEpisodes();
    for(size_t i = 0; i < parents.size(); ++i) {
        if(!first) o << ','; first = false;
        o << "{\"index\":" << i << ",\"title\":" << q(parents[i]->fTitle) << ",\"next\":\"" << (parents[i]->fNextEpisode == eEpisodeType::parentCity ? "parent" : "colony")
          << "\",\"last\":" << (i + 1 == parents.size() ? "true" : "false") << ",\"goals\":" << parents[i]->fGoals.size() << '}';
    }
    o << "],\"colonies\":["; first = true;
    const auto& colonies = c.colonyEpisodes();
    for(size_t i = 0; i < colonies.size(); ++i) {
        if(!first) o << ','; first = false;
        const auto& city = colonies[i]->fCity;
        o << "{\"index\":" << i << ",\"title\":" << q(colonies[i]->fTitle) << ",\"city\":" << (city ? int(city->cityId()) : -1) << ",\"city_name\":" << q(city ? city->name() : std::string()) << '}';
    }
    o << "],\"colony_cities\":["; first = true;
    for(const auto& city : world.cities()) {
        if(!city->isColony()) continue;
        if(!first) o << ','; first = false;
        o << "{\"id\":" << int(city->cityId()) << ",\"name\":" << q(city->nameWithId()) << '}';
    }
    o << "],\"labels\":{\"parent\":" << q(eLanguage::zeusText(195, 9)) << ",\"colony\":" << q(eLanguage::zeusText(195, 12))
      << ",\"next_parent\":" << q(eLanguage::zeusText(195, 14)) << ",\"next_colony\":" << q(eLanguage::zeusText(195, 15))
      << ",\"victory\":" << q(eLanguage::zeusText(195, 50)) << ",\"insert\":" << q(eLanguage::zeusText(195, 17)) << ",\"delete\":" << q(eLanguage::zeusText(195, 18))
      << ",\"settings\":" << q(eLanguage::zeusText(195, 13)) << ",\"funds\":" << q(eLanguage::zeusText(44, 39)) << ",\"prices\":" << q(eLanguage::zeusText(54, 9))
      << ",\"reset_prices\":" << q(eLanguage::zeusText(44, 214)) << ",\"edit_map\":" << q(eLanguage::zeusText(195, 3)) << ",\"edit_world\":" << q(eLanguage::zeusText(195, 4))
      << ",\"save\":" << q(eLanguage::zeusText(44, 74)) << ",\"quit\":" << q(eLanguage::zeusText(5, 0)) << ",\"title\":" << q(eLanguage::zeusText(195, 6))
      << ",\"introduction\":" << q(eLanguage::zeusText(195, 7)) << ",\"complete_text\":" << q(eLanguage::zeusText(195, 8))
      << ",\"gods\":" << q(eLanguage::zeusText(44, 162)) << ",\"events\":" << q(eLanguage::zeusText(44, 94)) << ",\"goals\":" << q(eLanguage::zeusText(44, 45))
      << ",\"buildings\":" << q(eLanguage::zeusText(44, 44)) << ",\"max_sanctuaries\":" << q(eLanguage::zeusText(44, 291)) << ",\"clear\":" << q(eLanguage::zeusText(195, 44))
      << ",\"save_question\":" << q(eLanguage::zeusText(195, 23)) << ",\"save_detail\":" << q(eLanguage::zeusText(195, 25)) << "}}";
    return o.str();
}

std::string eEditorSession::episode(const bool colony, const int index) {
    auto& c = *mCampaign;
    eEpisode* ep = nullptr;
    if(colony) { if(index >= 0 && index < int(c.colonyEpisodes().size())) ep = c.colonyEpisodes()[index].get(); }
    else if(index >= 0 && index < int(c.parentCityEpisodes().size())) ep = c.parentCityEpisodes()[index].get();
    if(!ep || !ep->fBoard) return error("unknown_episode");
    auto& world = c.worldBoard();
    auto& b = *ep->fBoard;
    std::ostringstream o;
    o << "{\"kind\":\"episode\",\"colony\":" << (colony ? "true" : "false") << ",\"index\":" << index << ",\"title\":" << q(ep->fTitle) << ",\"cities\":[";
    bool first = true;
    for(const auto cid : b.citiesOnBoard()) {
        if(!first) o << ','; first = false;
        o << "{\"id\":" << int(cid) << ",\"name\":" << q(b.cityName(cid)) << ",\"gods\":[";
        bool firstGod = true;
        const auto gods = ep->fFriendlyGods.find(cid);
        if(gods != ep->fFriendlyGods.end()) for(const auto g : gods->second) { if(!firstGod) o << ','; firstGod = false; o << int(g); }
        o << "],\"events\":[";
        bool firstEvent = true; int number = 0;
        const auto events = ep->fEvents.find(cid);
        if(events != ep->fEvents.end()) for(const auto& e : events->second) {
            if(!firstEvent) o << ','; firstEvent = false;
            o << "{\"index\":" << number++ << ",\"type\":" << int(e->type()) << ",\"name\":" << q(e->longDatedName()) << '}';
        }
        o << "],\"buildings\":[";
        bool firstBuilding = true;
        // Read without adding an entry for the city (only a change adds one, as in the SDL list).
        const eAvailableBuildings none{};
        const auto entry = ep->fAvailableBuildings.find(cid);
        const auto& available = entry == ep->fAvailableBuildings.end() ? none : entry->second;
        for(const auto type : optionalBuildings()) {
            if(!firstBuilding) o << ','; firstBuilding = false;
            o << "{\"type\":" << int(type) << ",\"name\":" << q(eBuilding::sNameForBuilding(type)) << ",\"available\":" << (available.available(type) ? "true" : "false") << '}';
        }
        const auto max = ep->fMaxSanctuaries.find(cid);
        o << "],\"max_sanctuaries\":" << (max == ep->fMaxSanctuaries.end() ? 16 : max->second) << '}';
    }
    o << "],\"goals\":["; first = true; int number = 0;
    for(const auto& g : ep->fGoals) {
        if(!first) o << ','; first = false;
        o << "{\"index\":" << number++ << ",\"type\":" << int(g->fType) << ",\"type_name\":" << q(eEpisodeGoal::sText(g->fType))
          << ",\"text\":" << q(g->text(colony, false, b)) << ",\"fields\":" << fieldsJson(goalFields(*g, world)) << '}';
    }
    o << "],\"gods\":[";
    first = true;
    for(const auto& g : godOptions()) { if(!first) o << ','; first = false; o << "{\"value\":" << g.first << ",\"label\":" << q(g.second) << '}'; }
    o << "],\"goal_kinds\":["; first = true;
    for(const auto t : goalKinds()) { if(!first) o << ','; first = false; o << "{\"value\":" << int(t) << ",\"label\":" << q(eEpisodeGoal::sText(t)) << '}'; }
    o << "],\"event_kinds\":["; first = true;
    for(const auto& k : eventKinds()) { if(!first) o << ','; first = false; o << "{\"value\":" << int(k.fType) << ",\"label\":" << q(k.fName()) << '}'; }
    o << "]}";
    return o.str();
}

std::string eEditorSession::event(const bool colony, const int index, const int cid, const int number) {
    auto& c = *mCampaign;
    eEpisode* ep = nullptr;
    if(colony) { if(index >= 0 && index < int(c.colonyEpisodes().size())) ep = c.colonyEpisodes()[index].get(); }
    else if(index >= 0 && index < int(c.parentCityEpisodes().size())) ep = c.parentCityEpisodes()[index].get();
    if(!ep) return error("unknown_episode");
    const auto found = ep->fEvents.find(static_cast<eCityId>(cid));
    if(found == ep->fEvents.end() || number < 0 || number >= int(found->second.size())) return error("unknown_event");
    auto& e = *found->second[number];
    std::ostringstream o;
    o << "{\"kind\":\"event\",\"index\":" << number << ",\"city\":" << cid << ",\"type\":" << int(e.type()) << ",\"name\":" << q(e.longDatedName())
      << ",\"fields\":" << fieldsJson(eventFields(e)) << '}';
    return o.str();
}

std::string eEditorSession::world() {
    auto& world = mCampaign->worldBoard();
    std::ostringstream o;
    // The world picture (as the world map's own `image`).
    const int n = int(world.map()); char image[40];
    if(n <= int(eWorldMap::greece8)) std::snprintf(image, sizeof(image), "Zeus_MapOfGreece%02d.JPG", n + 1);
    else std::snprintf(image, sizeof(image), "Poseidon_map%02d.jpg", n - int(eWorldMap::poseidon1) + 1);
    o << "{\"kind\":\"editor_world\",\"map\":" << n << ",\"image\":" << q(image) << ",\"cities\":[";
    bool first = true; int index = 0;
    for(const auto& c : world.cities()) {
        if(!first) o << ','; first = false;
        o << "{\"index\":" << index++ << ",\"id\":" << int(c->cityId()) << ",\"name\":" << q(c->name()) << ",\"label\":" << q(c->nameWithId())
          << ",\"type\":" << q(eWorldCity::sTypeName(c->type())) << ",\"x\":" << c->x() << ",\"y\":" << c->y() << ",\"visible\":" << (c->visible() ? "true" : "false")
          << ",\"active\":" << (c->state() == eCityState::active ? "true" : "false") << ",\"on_board\":" << (c->isOnBoard() ? "true" : "false")
          << ",\"player\":" << int(world.cityIdToPlayerId(c->cityId())) << ",\"team\":" << int(world.cityIdToTeamId(c->cityId())) << '}';
    }
    o << "],\"labels\":{\"add\":" << q(eLanguage::text("add_city")) << ",\"settings\":" << q(eLanguage::text("settings")) << ",\"buys\":" << q(eLanguage::zeusText(47, 1))
      << ",\"sells\":" << q(eLanguage::zeusText(47, 2)) << "}}";
    return o.str();
}

std::string eEditorSession::city(const int index) {
    auto& world = mCampaign->worldBoard();
    const auto& cities = world.cities();
    if(index < 0 || index >= int(cities.size())) return error("unknown_city");
    const auto& c = cities[index];
    const auto pid = world.personPlayer();
    std::vector<eField> f;
    std::vector<std::pair<int, std::string>> types;
    for(const auto t : {eCityType::parentCity, eCityType::colony, eCityType::foreignCity, eCityType::distantCity, eCityType::enchantedPlace, eCityType::destroyedCity})
        types.push_back({int(t), eWorldCity::sTypeName(t)});
    f.push_back(choiceField("type", eLanguage::zeusText(44, 358), int(c->type()), types));
    const auto type = c->type();
    if(type == eCityType::foreignCity)
        f.push_back(choiceField("relationship", eLanguage::text("relationship"), int(c->relationship()),
            {{int(eForeignCityRelationship::vassal), eLanguage::zeusText(253, 2)}, {int(eForeignCityRelationship::ally), eLanguage::zeusText(253, 0)},
             {int(eForeignCityRelationship::rival), eLanguage::zeusText(253, 1)}}));
    if(type == eCityType::foreignCity || type == eCityType::colony || type == eCityType::parentCity) {
        std::vector<std::pair<int, std::string>> nations;
        std::vector<eNationality> list{eNationality::greek, eNationality::atlantean};
        if(type == eCityType::foreignCity) list = {eNationality::greek, eNationality::trojan, eNationality::persian, eNationality::centaur, eNationality::amazon,
                                                   eNationality::egyptian, eNationality::mayan, eNationality::phoenician, eNationality::oceanid, eNationality::atlantean};
        for(const auto n : list) nations.push_back({int(n), eWorldCity::sNationalityName(n)});
        f.push_back(choiceField("nationality", eLanguage::text("nationality"), int(c->nationality()), nations));
    }
    if(type == eCityType::foreignCity || type == eCityType::colony) {
        // The SDL settings offer five steps of regard, named for the relationship.
        std::vector<eCityAttitude> steps;
        if(c->isAlly()) steps = {eCityAttitude::annoyed, eCityAttitude::apatheticA, eCityAttitude::sympathetic, eCityAttitude::congenial, eCityAttitude::helpful};
        else if(c->isVassal() || c->isColony()) steps = {eCityAttitude::angry, eCityAttitude::bitter, eCityAttitude::loyal, eCityAttitude::dedicated, eCityAttitude::devoted};
        else steps = {eCityAttitude::furious, eCityAttitude::displeased, eCityAttitude::apatheticR, eCityAttitude::respectful, eCityAttitude::admiring};
        std::vector<std::pair<int, std::string>> o;
        for(int i = 0; i < 5; ++i) o.push_back({i, eWorldCity::sAttitudeName(steps[i])});
        f.push_back(choiceField("attitude", eLanguage::text("attitude"), std::clamp(int((c->attitude(pid) - 10)/20 + .5), 0, 4), o));
    }
    if(type == eCityType::distantCity) {
        std::vector<std::pair<int, std::string>> dirs;
        for(int d = 0; d <= int(eDistantDirection::NW); ++d) dirs.push_back({d, eWorldCity::sDirectionName(static_cast<eDistantDirection>(d))});
        f.push_back(choiceField("direction", eLanguage::text("direction"), int(c->direction()), dirs));
    }
    f.push_back(choiceField("active", eLanguage::zeusText(44, 248), c->state() == eCityState::active ? 0 : 1, {{0, eLanguage::zeusText(44, 248)}, {1, eLanguage::zeusText(44, 249)}}));
    f.push_back(choiceField("visible", eLanguage::zeusText(44, 307), c->visible() ? 1 : 0, {{0, eLanguage::zeusText(44, 306)}, {1, eLanguage::zeusText(44, 307)}}));
    f.push_back(intField("military", eLanguage::zeusText(44, 349), c->militaryStrength(), 1, 6));
    f.push_back(intField("wealth", eLanguage::zeusText(44, 350), c->wealth(), 1, 6));
    f.push_back(choiceField("tribute_type", eLanguage::text("tribute"), int(c->tributeType()), resourceOptions(true)));
    f.push_back(intField("tribute_count", eLanguage::text("tribute"), c->tributeCount(), 0, 99999));
    std::ostringstream o;
    o << "{\"kind\":\"editor_city\",\"index\":" << index << ",\"name\":" << q(c->name()) << ",\"leader\":" << q(c->leader()) << ",\"fields\":" << fieldsJson(f)
      << ",\"names\":[";
    bool first = true; for(const auto& n : eWorldCity::sNames()) { if(!first) o << ','; first = false; o << q(n); }
    o << "],\"leaders\":["; first = true; for(const auto& n : eWorldCity::sLeaders()) { if(!first) o << ','; first = false; o << q(n); }
    const auto trades = [&](const char* key, const std::vector<eResourceTrade>& list) {
        o << "],\"" << key << "\":["; bool firstTrade = true;
        for(const auto& t : list) { if(!firstTrade) o << ','; firstTrade = false; o << "{\"resource\":" << int(t.fType) << ",\"name\":" << q(eResourceTypeHelpers::typeName(t.fType)) << ",\"max\":" << t.fMax << '}'; }
    };
    trades("buys", c->buys());
    trades("sells", c->sells());
    o << "],\"resources\":["; first = true;
    for(const auto& r : resourceOptions(false)) { if(!first) o << ','; first = false; o << "{\"value\":" << r.first << ",\"label\":" << q(r.second) << '}'; }
    o << "]}";
    return o.str();
}

std::string eEditorSession::command(const std::string& action, std::istringstream& in) {
    auto& c = *mCampaign;
    // An episode named by its kind (p or c) and number.
    const auto episodeOf = [&](std::string& kind, int& index) -> eEpisode* {
        if(!(in >> kind >> index)) return nullptr;
        if(kind == "c") return index >= 0 && index < int(c.colonyEpisodes().size()) ? c.colonyEpisodes()[index].get() : nullptr;
        if(kind == "p") return index >= 0 && index < int(c.parentCityEpisodes().size()) ? c.parentCityEpisodes()[index].get() : nullptr;
        return nullptr;
    };
    if(action == "editor") return overview();
    if(action == "editor_single_parent") {
        // Explicit editor operation; never replaces an existing adventure.
        std::string name; std::getline(in, name);
        const auto start = name.find_first_not_of(' ');
        name = start == std::string::npos ? std::string() : name.substr(start);
        if(name.empty() || name.size() > 48 || name.find_first_of("/\\:*?\"<>|") != std::string::npos ||
           name.front() == '.' || name.front() == ' ' || name.back() == ' ')
            return error("invalid_name");
        if(std::filesystem::exists(std::filesystem::path(eGameDir::adventuresDir()) / name))
            return error("name_taken");
        c.keepParentAsSingleEpisode(name);
        mChanged = true;
        return overview();
    }
    if(action == "editor_episode") {
        std::string kind; int index; if(!episodeOf(kind, index)) return error("unknown_episode");
        return episode(kind == "c", index);
    }
    if(action == "editor_date") {
        int d, m, y; if(!(in >> d >> m >> y) || d < 1 || d > 31 || m < 0 || m > 11) return error("invalid_date");
        c.setDate(eDate(d, static_cast<eMonth>(m), y)); mChanged = true; return overview();
    }
    if(action == "editor_difficulty") {
        int value;
        if(!(in >> value) || value < 0 || value > int(eDifficulty::olympian))
            return error("invalid_difficulty");
        c.setDifficulty(static_cast<eDifficulty>(value));
        mChanged = true;
        return overview();
    }
    if(action == "editor_funds") {
        int pid, value; if(!(in >> pid >> value) || value < 0 || value > 99999) return error("invalid_funds");
        c.setInitialFunds(static_cast<ePlayerId>(pid), value); mChanged = true; return overview();
    }
    if(action == "editor_price") {
        int resource, value; if(!(in >> resource >> value) || value < 0 || value > 99999) return error("invalid_price");
        auto& prices = c.prices(); const auto found = prices.find(static_cast<eResourceType>(resource));
        if(found == prices.end()) return error("unknown_resource");
        found->second = value; mChanged = true; return overview();
    }
    if(action == "editor_prices_reset") {
        for(auto& p : c.prices()) p.second = eResourceTypeHelpers::defaultPrice(p.first);
        mChanged = true; return overview();
    }
    if(action == "editor_episode_add") { c.addParentCityEpisode(); mChanged = true; return overview(); }
    if(action == "editor_episode_insert" || action == "editor_episode_delete" || action == "editor_episode_victory" || action == "editor_episode_next") {
        int index; if(!(in >> index) || index < 0 || index >= int(c.parentCityEpisodes().size())) return error("unknown_episode");
        if(action == "editor_episode_insert") c.insertParentCityEpisode(index);
        else if(action == "editor_episode_delete") { if(c.parentCityEpisodes().size() < 2) return error("last_episode"); c.deleteParentCityEpisode(index); }
        else if(action == "editor_episode_victory") c.setVictoryParentCityEpisode(index);
        else { auto& next = c.parentCityEpisodes()[index]->fNextEpisode; next = next == eEpisodeType::parentCity ? eEpisodeType::colony : eEpisodeType::parentCity; }
        mChanged = true; return overview();
    }
    if(action == "editor_episode_copy") {
        // editor_episode_copy <p|c> <from> <to>: the SDL settings button's right-click "copy from"; a `from` of -1 clears.
        std::string kind; int from, to; if(!(in >> kind >> from >> to)) return error("unknown_episode");
        const bool colony = kind == "c"; const int n = colony ? int(c.colonyEpisodes().size()) : int(c.parentCityEpisodes().size());
        if(to < 0 || to >= n || from >= n || from == to || from < -1) return error("unknown_episode");
        eEpisode* target = colony ? static_cast<eEpisode*>(c.colonyEpisodes()[to].get()) : c.parentCityEpisodes()[to].get();
        if(from == -1) target->clear();
        else c.copyEpisodeSettings(colony ? static_cast<eEpisode*>(c.colonyEpisodes()[from].get()) : c.parentCityEpisodes()[from].get(), target);
        mChanged = true; return episode(colony, to);
    }
    if(action == "editor_colony_city") {
        int index, cid; if(!(in >> index >> cid) || index < 0 || index >= int(c.colonyEpisodes().size())) return error("unknown_episode");
        const auto city = c.worldBoard().cityWithId(static_cast<eCityId>(cid));
        if(!city || !city->isColony()) return error("not_a_colony");
        c.colonyEpisodes()[index]->fCity = city; mChanged = true; return overview();
    }
    if(action == "editor_gods" || action == "editor_building" || action == "editor_max_sanctuaries" || action == "editor_goal_add" || action == "editor_goal_remove"
       || action == "editor_goal_set" || action == "editor_event_add" || action == "editor_event_remove" || action == "editor_event" || action == "editor_event_set") {
        std::string kind; int index; const auto ep = episodeOf(kind, index);
        if(!ep || !ep->fBoard) return error("unknown_episode");
        const bool colony = kind == "c";
        const auto cityOn = [&](int cid) { return eVectorHelpers::contains(ep->fBoard->citiesOnBoard(), static_cast<eCityId>(cid)); };
        if(action == "editor_gods") {
            // editor_gods <p|c> <i> <city> <god,god,...|->: the city's friendly gods.
            int cid; std::string list; if(!(in >> cid >> list) || !cityOn(cid)) return error("unknown_city");
            std::vector<eGodType> gods; std::istringstream parts(list == "-" ? std::string() : list); std::string part;
            while(std::getline(parts, part, ',')) { if(part.empty()) continue; const int g = std::atoi(part.c_str()); if(g < 0 || g > int(eGodType::zeus)) return error("unknown_god");
                const auto god = static_cast<eGodType>(g); if(!eVectorHelpers::contains(gods, god)) gods.push_back(god); }
            ep->fFriendlyGods[static_cast<eCityId>(cid)] = gods;
        } else if(action == "editor_building") {
            int cid, type, on; if(!(in >> cid >> type >> on) || !cityOn(cid)) return error("unknown_city");
            const auto t = static_cast<eBuildingType>(type);
            if(!eVectorHelpers::contains(optionalBuildings(), t)) return error("not_optional");
            auto& available = ep->fAvailableBuildings[static_cast<eCityId>(cid)];
            if(on) available.allow(t); else available.disallow(t);
        } else if(action == "editor_max_sanctuaries") {
            int cid, n; if(!(in >> cid >> n) || !cityOn(cid)) return error("unknown_city");
            if(n < 0 || n > 16) return error("invalid_count");
            ep->fMaxSanctuaries[static_cast<eCityId>(cid)] = n;
        } else if(action == "editor_goal_add") {
            int type; if(!(in >> type)) return error("unknown_goal");
            const auto t = static_cast<eEpisodeGoalType>(type);
            if(!eVectorHelpers::contains(goalKinds(), t)) return error("unknown_goal");
            // As the SDL goal chooser makes a new goal.
            const auto g = std::make_shared<eEpisodeGoal>(); g->fType = t;
            switch(t) {
            case eEpisodeGoalType::sanctuary: g->fRequiredCount = 100; break;
            case eEpisodeGoalType::pyramid: g->fRequiredCount = 1; g->fEnumInt1 = -1; break;
            case eEpisodeGoalType::rule: case eEpisodeGoalType::quest: case eEpisodeGoalType::slay: g->fRequiredCount = 1; break;
            case eEpisodeGoalType::yearlyProduction: case eEpisodeGoalType::setAsideGoods: g->fEnumInt1 = int(eResourceType::marble); break;
            default: break;
            }
            ep->fGoals.push_back(g);
        } else if(action == "editor_goal_remove" || action == "editor_goal_set") {
            int number; if(!(in >> number) || number < 0 || number >= int(ep->fGoals.size())) return error("unknown_goal");
            if(action == "editor_goal_remove") ep->fGoals.erase(ep->fGoals.begin() + number);
            else { std::string id; int value; if(!(in >> id >> value) || !setGoalField(*ep->fGoals[number], id, value)) return error("unknown_field"); }
        } else if(action == "editor_event_add") {
            int cid, type; if(!(in >> cid >> type) || !cityOn(cid)) return error("unknown_city");
            const auto t = static_cast<eGameEventType>(type);
            bool known = false; for(const auto& k : eventKinds()) known = known || k.fType == t;
            if(!known) return error("unknown_event");
            // As the SDL event chooser makes a new event: an episode event 150 days after the start, once.
            const auto e = eGameEvent::sCreate(static_cast<eCityId>(cid), t, eGameEventBranch::root, *ep->fBoard);
            if(!e) return error("unknown_event");
            e->setIsEpisodeEvent(true);
            const int period = 150;
            e->initializeDate(eDate(1, eMonth::january, -1500) + period, period, 1);
            auto& list = ep->fEvents[static_cast<eCityId>(cid)];
            list.push_back(e);
            mChanged = true;
            return event(colony, index, cid, int(list.size()) - 1);
        } else {
            int cid, number; if(!(in >> cid >> number) || !cityOn(cid)) return error("unknown_city");
            auto& list = ep->fEvents[static_cast<eCityId>(cid)];
            if(number < 0 || number >= int(list.size())) return error("unknown_event");
            if(action == "editor_event") return event(colony, index, cid, number);
            if(action == "editor_event_remove") list.erase(list.begin() + number);
            else {
                std::string id; int value; if(!(in >> id >> value)) return error("unknown_field");
                try { if(!setEventField(*list[number], id, value)) return error("unknown_field"); } catch(const std::exception&) { return error("unknown_field"); }
                mChanged = true;
                return event(colony, index, cid, number);
            }
        }
        mChanged = true;
        return episode(colony, index);
    }
    if(action == "editor_paint") {
        // editor_paint <tool> <tool id> <apply|brush|square> <size> <x0> <y0> [<x1> <y1> ...]: one stroke of a terrain tool (named as
        // in toolModes). With "apply" the tiles are the rectangle from the first point to the last; a brush adds its tiles around each point.
        std::string tool, brush; int id, size; if(!(in >> tool >> id >> brush >> size)) return error("invalid_paint");
        const auto found = toolModes().find(tool); if(found == toolModes().end()) return error("unknown_tool");
        auto& b = board();
        const auto toolMode = found->second;
        std::vector<std::pair<int, int>> points; int x, y;
        while(in >> x >> y) points.push_back({x, y});
        if(points.empty()) return error("invalid_paint");
        if(toolMode == eTerrainEditMode::assignAllCityTerritory) {
            b.assignAllTerritory(static_cast<eCityId>(id)); b.updateTerritoryBorders(); mChanged = true;
            return "{\"kind\":\"paint\",\"changed\":1,\"heights\":false}";
        }
        std::vector<eTile*> tiles;
        const auto add = [&](eTile* t) { if(t && !eVectorHelpers::contains(tiles, t)) tiles.push_back(t); };
        if(brush == "apply") {
            const auto a = points.front(), z = points.back();
            for(int tx = std::min(a.first, z.first); tx <= std::max(a.first, z.first); ++tx)
                for(int ty = std::min(a.second, z.second); ty <= std::max(a.second, z.second); ++ty) add(b.tile(tx, ty));
        } else if(brush == "brush" || brush == "square") {
            if(size < 1 || size > 6) return error("invalid_paint");
            for(const auto& p : points) {
                std::vector<eTile*> around;
                if(brush == "brush") eTerrainEdit::brushTiles(&b, size, p.first, p.second, around);
                else eTerrainEdit::squareTiles(&b, size, p.first, p.second, around);
                for(const auto t : around) add(t);
            }
        } else return error("invalid_paint");
        if(tiles.empty()) return error("out_of_map");
        b.waitUntilFinished();
        bool heights = false;
        const auto city = tiles.front()->cityId();
        const int n = eTerrainEdit::stroke(b, toolMode, id, tiles, b.tile(points.front().first, points.front().second), city, &heights);
        if(n) mChanged = true;
        return "{\"kind\":\"paint\",\"changed\":" + std::to_string(n) + ",\"heights\":" + (heights ? "true" : "false") + '}';
    }
    if(action == "editor_world") return world();
    if(action == "editor_world_map") {
        // As the SDL map button: the next world picture.
        auto& w = c.worldBoard(); auto m = w.map();
        m = m == eWorldMap::poseidon4 ? eWorldMap::greece1 : static_cast<eWorldMap>(int(m) + 1);
        w.setMap(m); mChanged = true; return world();
    }
    if(action == "editor_city_add") {
        // As the SDL "add city": a new city of a new player on the player's team, then placed where it was asked.
        double x, y; if(!(in >> x >> y) || x < 0 || x > 1 || y < 0 || y > 1) return error("invalid_position");
        auto& w = c.worldBoard();
        const auto city = std::make_shared<eWorldCity>();
        const auto cid = w.firstFreeCityId(); city->setCityId(cid);
        const auto pid = w.firstFreePlayerId(); city->setCapitalOf(pid);
        w.setPlayerTeam(pid, w.playerIdToTeamId(w.personPlayer()));
        w.addCity(city); w.moveCityToPlayer(cid, pid);
        city->move(x, y);
        mChanged = true; return world();
    }
    if(action == "editor_city_team") {
        // Explicit content authoring: assign one off-board city an independent
        // player/team. Foreign diplomacy alone is not a combat-team assignment.
        int index,team;if(!(in>>index>>team) || team<0 || team>int(eTeamId::team9))return error("invalid_team");
        auto& world=c.worldBoard();const auto& cities=world.cities();
        if(index<0 || index>=int(cities.size()))return error("unknown_city");
        const auto city=cities[index];
        if(city->type()!=eCityType::foreignCity || city->isOnBoard())return error("foreign_city_required");
        const auto player=world.firstFreePlayerId();
        world.moveCityToPlayer(city->cityId(),player);world.setPlayerTeam(player,static_cast<eTeamId>(team));
        city->setCapitalOf(player);mChanged=true;
        return "{\"kind\":\"editor_city_team\",\"index\":"+std::to_string(index)+",\"player\":"+std::to_string(int(player))+",\"team\":"+std::to_string(team)+"}";
    }
    if(action == "editor_city" || action == "editor_city_move" || action == "editor_city_set" || action == "editor_city_name" || action == "editor_city_leader" || action == "editor_city_trade") {
        int index; if(!(in >> index)) return error("unknown_city");
        auto& w = c.worldBoard(); const auto& cities = w.cities();
        if(index < 0 || index >= int(cities.size())) return error("unknown_city");
        const auto& city = cities[index];
        if(action == "editor_city") return this->city(index);
        if(action == "editor_city_move") {
            double x, y; if(!(in >> x >> y) || x < 0 || x > 1 || y < 0 || y > 1) return error("invalid_position");
            city->move(x, y); mChanged = true; return world();
        }
        if(action == "editor_city_name" || action == "editor_city_leader") {
            std::string rest; std::getline(in, rest);
            const auto start = rest.find_first_not_of(' '); rest = start == std::string::npos ? std::string() : rest.substr(start);
            if(rest.empty() || rest.size() > 64) return error("invalid_name");
            if(action == "editor_city_name") city->setName(rest); else city->setLeader(rest);
            mChanged = true; return this->city(index);
        }
        if(action == "editor_city_trade") {
            // editor_city_trade <index> <buys|sells> <resource> <max, 0 removes>
            std::string side; int resource, max; if(!(in >> side >> resource >> max) || (side != "buys" && side != "sells") || max < 0 || max > 999) return error("invalid_trade");
            const auto r = static_cast<eResourceType>(resource);
            bool known = false; for(const auto& o : resourceOptions(false)) known = known || o.first == resource;
            if(!known) return error("unknown_resource");
            auto& list = side == "buys" ? city->buys() : city->sells();
            const auto found = std::find_if(list.begin(), list.end(), [r](const eResourceTrade& t) { return t.fType == r; });
            if(max == 0) { if(found != list.end()) list.erase(found); }
            else if(found != list.end()) found->fMax = max;
            else { eResourceTrade t; t.fType = r; t.fMax = max; list.push_back(t); }
            mChanged = true; return this->city(index);
        }
        std::string id; int v; if(!(in >> id >> v)) return error("unknown_field");
        const auto pid = w.personPlayer();
        if(id == "type") {
            if(v < 0 || v > int(eCityType::destroyedCity)) return error("unknown_field");
            city->setType(static_cast<eCityType>(v));
            // A parent city or colony is Greek or Atlantean (as the SDL settings set it).
            if((city->type() == eCityType::parentCity || city->type() == eCityType::colony) && city->nationality() != eNationality::atlantean) city->setNationality(eNationality::greek);
        }
        else if(id == "relationship") city->setRelationship(static_cast<eForeignCityRelationship>(std::clamp(v, 0, 2)));
        else if(id == "nationality") city->setNationality(static_cast<eNationality>(std::clamp(v, 0, int(eNationality::atlantean))));
        else if(id == "attitude") city->setAttitude(10 + std::clamp(v, 0, 4)*20, pid);
        else if(id == "direction") city->setDirection(static_cast<eDistantDirection>(std::clamp(v, 0, int(eDistantDirection::NW))));
        else if(id == "active") city->setState(v == 0 ? eCityState::active : eCityState::inactive);
        else if(id == "visible") city->setVisible(v == 1);
        else if(id == "military") city->setMilitaryStrength(std::clamp(v, 1, 6));
        else if(id == "wealth") city->setWealth(std::clamp(v, 1, 6));
        else if(id == "tribute_type") city->setTributeType(static_cast<eResourceType>(v));
        else if(id == "tribute_count") city->setTributeCount(std::clamp(v, 0, 99999));
        else return error("unknown_field");
        mChanged = true;
        return this->city(index);
    }
    if(action == "editor_save") {
        if(!c.save()) return error("save_failed");
        mChanged = false;
        return overview();
    }
    return error("unsupported_command");
}
