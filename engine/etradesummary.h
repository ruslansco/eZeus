#ifndef ETRADESUMMARY_H
#define ETRADESUMMARY_H

#include "engine/eresourcetype.h"

#include <string>
#include <vector>

class eGameBoard;
enum class eCityId;

// How a part of a line reads: plain, dimmed, good (green), bad (red), a warning (amber), a partner's name (gold) or a
// sub-heading.
enum class eTradeTone { text, dim, green, red, amber, gold, label };

// One line of the trade summary. The SDL window (widgets/etradesummarywidget) and the Godot city window's trade page
// (`trade_summary`) both draw these lines, so the two views word and judge a city's trade alike.
struct eTradeSummaryLine {
    std::string fLeft;
    std::string fRight;
    eTradeTone fLeftTone = eTradeTone::text;
    eTradeTone fRightTone = eTradeTone::text;
    int fFont = 0;            // 0 body, 1 heading
    int fIndent = 0;
    bool fHeader = false;     // a section title (gold rule under it)
    bool fCard = false;       // starts a partner card
    eResourceType fIcon = eResourceType::none;
};

namespace eTradeSummary {
    // Each partner's trade this year and last with the goods they buy and sell, then the goods in storage and who would buy
    // them, booked from the city's eTradeLedger and its trade posts' orders.
    std::vector<eTradeSummaryLine> lines(eGameBoard& board, const eCityId cid);
}

#endif // ETRADESUMMARY_H
