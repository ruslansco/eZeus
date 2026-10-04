#ifndef ECITYADVISORWIDGET_H
#define ECITYADVISORWIDGET_H

#include "eframedwidget.h"

#include <string>
#include <utility>
#include <vector>

class eGameBoard;
class eGameWidget;
enum class eCityId;

// One thing the city advisor would have the player look at.
struct eAdvice {
    std::string fKey;       // stable id: "Go there" steps through fPlaces
    int fSeverity = 1;      // 0 all well, 1 worth a look, 2 serious
    std::string fIcon;      // Textures/Panel/icons/<name>.svg
    std::string fTitle;
    std::string fDetail;
    std::string fHint;
    std::vector<std::pair<int, int>> fPlaces;   // tiles, worst first
    int fWeight = 0;        // ranks advice of the same severity
};

namespace eCityAdvisor {
    // The city's problems right now, most serious first (at most `max`).
    std::vector<eAdvice> collect(eGameBoard& board, const eCityId cid,
                                 const int max = 7);
}

// The advisor window: a card per problem, each with a "Go there" button.
class eCityAdvisorWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    void initialize(eGameWidget* const gw, eGameBoard& board,
                    const eCityId cid, const eAction& close);
};

#endif // ECITYADVISORWIDGET_H
