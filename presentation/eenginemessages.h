#pragma once
// The words of the events the engine raises itself (eEvent::monthlySummary, shortageWarning, riskWarning).
// They have no entry in the game's message catalogue (eeventmessages.h): the SDL view writes them in
// eGameWidget::showMonthlySummary and eGameWidget::handleEvent from text/language*.txt and the city history.
// This is the embedded core's copy of that wording, with the same keys, English fallbacks and figures, so a
// card reads the same in both views and follows the core's language; keep the two in step. Nothing here
// changes the simulation: it only reads the event and the city's history.
#include <algorithm>
#include <cstdlib>
#include <string>
#include "elanguage.h"
#include "estringhelpers.h"
#include "engine/edate.h"
#include "engine/eboardcity.h"
#include "engine/ecityhistory.h"
#include "engine/eevent.h"
#include "engine/eeventdata.h"
#include "engine/egameboard.h"
#include "engine/eresourcetype.h"

namespace eEngineMessages {

// The language table's text for a key, or the English wording when the table has none.
inline std::string tr(const char* key, const char* fallback) {
    const auto& t = eLanguage::text(key);
    return t.empty() ? std::string(fallback) : t;
}

inline std::string signedChange(const int v) {
    if(v == 0) return "0"; // plain ASCII: the game fonts may lack the minus sign
    return (v > 0 ? "+" : "-") + std::to_string(std::abs(v));
}

// "<Month> in review": population, treasury and food as the month ended with their change over it, and the unrest.
// Like the SDL card it needs two consecutive monthly samples of the city's history; otherwise it says nothing.
inline bool monthlySummary(eGameBoard& board, const eEventData& ed, std::string& title, std::string& text) {
    if(!ed.fTarget.isCityTarget()) return false;
    const auto cid = ed.fTarget.cityTarget();
    const auto city = board.boardCityWithId(cid);
    if(!city) return false;
    const auto& samples = city->history().samples();
    if(samples.size() < 2) return false;
    const auto& now = samples.back();
    const auto& then = samples[samples.size() - 2];
    if(now.monthIndex() - then.monthIndex() != 1) return false;
    title = tr("summary_title", "%m in review");
    eStringHelpers::replaceAll(title, "%m", eMonthHelper::name(static_cast<eMonth>(std::clamp(then.fMonth, 0, 11))));
    if(board.personPlayerCitiesOnBoard().size() > 1) title = board.cityName(cid) + ": " + title;
    const auto item = [](const std::string& name, const int value, const int change) {
        return name + " " + std::to_string(value) + " (" + signedChange(change) + ")";
    };
    text = item(tr("summary_population", "Population"), now.fPopulation, now.fPopulation - then.fPopulation) +
           "\n" + item(tr("summary_treasury", "Treasury"), now.fDrachmas, now.fDrachmas - then.fDrachmas) +
           "\n" + item(tr("summary_food", "Food"), now.fFood, now.fFood - then.fFood) +
           "  \xC2\xB7  " + tr("summary_unrest", "Unrest") + " " + std::to_string(now.fUnrest) + "%";
    return true;
}

// "Running low: <goods>" / "Treasury running low": fResourceType, fResourceCount (the stock), fTime (months left).
inline void shortageWarning(const eEventData& ed, std::string& title, std::string& text) {
    const auto type = ed.fResourceType;
    if(type == eResourceType::drachmas) {
        title = tr("warn_treasury_title", "Treasury running low");
        text = tr("warn_treasury_text", "At the pace of the last three months, the treasury (%n drachmas) lasts about %m more months.");
    } else {
        title = tr("warn_title", "Running low: %s");
        text = tr("warn_text", "At the pace of the last three months, the stock of %s (%n) lasts about %m more months.");
        const auto name = eResourceTypeHelpers::typeName(type);
        eStringHelpers::replaceAll(title, "%s", name);
        eStringHelpers::replaceAll(text, "%s", name);
    }
    eStringHelpers::replaceAll(text, "%n", std::to_string(ed.fResourceCount));
    eStringHelpers::replaceAll(text, "%m", std::to_string(ed.fTime));
}

// Fire or collapse risk, or rising unrest: fTime is the kind (0 fire, 1 collapse, 2 unrest), fResourceCount how
// many buildings (the unrest percent), fReason the worst building's name.
inline void riskWarning(const eEventData& ed, std::string& title, std::string& text) {
    if(ed.fTime == 0) {
        title = ed.fReason.empty() ? tr("risk_fire_title0", "Fire risk high") :
                                     tr("risk_fire_title", "Fire risk high near the %b");
        text = tr("risk_fire_text", "%n buildings have had no upkeep for a long time and may catch fire. A maintenance office's walkers must pass them.");
    } else if(ed.fTime == 1) {
        title = ed.fReason.empty() ? tr("risk_collapse_title0", "Buildings may collapse") :
                                     tr("risk_collapse_title", "%n buildings about to collapse");
        text = tr("risk_collapse_text", "Worst is the %b. A maintenance office's walkers must pass these buildings to repair them.");
    } else {
        title = tr("risk_unrest_title", "Unrest is rising: %n%");
        text = tr("risk_unrest_text", "People grow restless without food, water or work, or with high taxes. The city advisor shows where.");
    }
    const auto n = std::to_string(ed.fResourceCount);
    for(auto* str : {&title, &text}) {
        eStringHelpers::replaceAll(*str, "%b", ed.fReason);
        eStringHelpers::replaceAll(*str, "%n", n);
    }
}

// The events this file words.
inline bool handles(const eEvent kind) {
    return kind == eEvent::monthlySummary || kind == eEvent::shortageWarning || kind == eEvent::riskWarning;
}

// Title and text for an engine event; false when the event is not one of these, or has nothing to say (a monthly
// summary without two consecutive samples), in which case the caller shows nothing for a handled event.
inline bool eventText(eGameBoard& board, const eEvent kind, const eEventData& ed, std::string& title, std::string& text) {
    switch(kind) {
    case eEvent::monthlySummary: return monthlySummary(board, ed, title, text);
    case eEvent::shortageWarning: shortageWarning(ed, title, text); return true;
    case eEvent::riskWarning: riskWarning(ed, title, text); return true;
    default: return false;
    }
}

}
