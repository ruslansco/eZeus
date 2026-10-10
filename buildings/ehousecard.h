#ifndef EHOUSECARD_H
#define EHOUSECARD_H

#include "engine/eresourcetype.h"

#include <string>
#include <vector>

class eHouseBase;

// What the house card says about a house: its level, residents and what it needs for the next level (or lacks to keep its
// current one), missing needs first. The SDL hover card (widgets/ehousehovercard) and the Godot house card (`house_card`) both
// show this, so the two views word a house alike. The needs themselves are buildings/ehouseneeds.
struct eHouseCardLine {
    std::string fIcon;                              // a panel icon (water, culture, science, aesthetics), or
    eResourceType fResource = eResourceType::none;  // a good's icon
    std::string fLabel;
    std::string fDetail;
    std::string fNote;                              // venue kinds that do not reach the house
    bool fMet = true;
};

struct eHouseCard {
    bool fValid = false;    // false: no house, or no one lives there yet
    bool fElite = false;
    int fLevel = 0;
    int fLevels = 0;        // pips
    std::string fName;      // the level's name
    std::string fTargetName; // the level whose needs are listed (the next one, or the current one if it slips)
    int fTargetLevel = -1;
    int fPeople = 0;
    std::string fResidents; // "12 residents"
    int fTone = 0;          // 0 next level, 1 will decline, 2 improving or the finest
    std::string fStatus;
    std::vector<eHouseCardLine> fLines;

    // Changes whenever anything shown changes.
    std::string signature() const;
};

namespace eHouseCards {
    eHouseCard card(eHouseBase* const h);
}

#endif // EHOUSECARD_H
