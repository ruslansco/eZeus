#ifndef ECITYADVISOR_H
#define ECITYADVISOR_H

#include <string>
#include <utility>
#include <vector>

class eGameBoard;
enum class eCityId;

// One thing the city advisor would have the player look at. The SDL advisor window (widgets/ecityadvisorwidget) and the
// Godot city window's advisor page (`city_advisor`) both list these, so the two views rank a city alike.
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

#endif // ECITYADVISOR_H
