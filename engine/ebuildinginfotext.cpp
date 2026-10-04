#include "ebuildinginfotext.h"

#include "elanguage.h"
#include "engine/egameboard.h"
#include "buildings/ehippodrome.h"
#include "buildings/etriremewharf.h"

std::vector<std::string> eBuildingInfoText::hippodrome(const eHippodrome& h) {
    std::vector<std::string> lines;
    const auto text = [](const int s) { return eLanguage::zeusText(167, s); };
    if(h.racing()) lines.push_back(text(1));
    const bool closed = h.closed();
    if(!closed) lines.push_back(text(2));
    const int l = h.length();
    const bool working = h.working();
    if(working) {
        if(l < 8) lines.push_back(text(3));
        else if(l < 16) lines.push_back(text(4));
        else if(l < 32) lines.push_back(text(6));
        else if(l < 64) lines.push_back(text(8));
        else if(l < 128) lines.push_back(text(9));
        else lines.push_back(text(10));
    }
    lines.push_back(text(12) + " " + std::to_string(l) + " " + text(13));
    if(closed) {
        if(working) lines.push_back(text(14) + " " + std::to_string(h.drachmasPerMonth()) + " " + text(15));
        const int has = h.hasHorses();
        const int needs = h.neededHorses();
        if(has < needs) {
            lines.push_back(text(18) + " " + std::to_string(needs) + " " + text(19));
            lines.push_back(std::to_string(has) + " " + text(20));
        } else {
            lines.push_back(std::to_string(has) + " " + text(21));
        }
    }
    return lines;
}

std::vector<std::string> eBuildingInfoText::triremeWharf(const eTriremeWharf& w) {
    std::vector<std::string> lines;
    auto& board = w.getBoard();
    if(!board.hasPalace(w.cityId())) lines.push_back(eLanguage::zeusText(175, 18));
    const auto loads = eLanguage::zeusText(8, 55);
    lines.push_back(eLanguage::zeusText(175, 12) + " " + std::to_string(w.count(eResourceType::wood)) + " " + loads + "  " +
                    eLanguage::zeusText(175, 13) + " " + std::to_string(w.count(eResourceType::armor)) + " " + loads);
    if(!w.accessToRoad()) lines.push_back(eLanguage::zeusText(69, 4));
    return lines;
}

std::string eBuildingInfoText::triremeWharfSwitch(const bool working) {
    return eLanguage::zeusText(175, working ? 20 : 19);
}
