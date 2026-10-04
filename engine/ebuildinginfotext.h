#ifndef EBUILDINGINFOTEXT_H
#define EBUILDINGINFOTEXT_H

#include <string>
#include <vector>

class eHippodrome;
class eTriremeWharf;

// The lines of the SDL inspector pages that are more than the building's native info text: the hippodrome (racing, open or
// closed, the length and its verdict, the takings, the horses it has and needs) and the trireme wharf (the palace it needs,
// the wood and armour in store, no road). The SDL info widgets and the Godot inspector both ask here.
namespace eBuildingInfoText {
    std::vector<std::string> hippodrome(const eHippodrome& h);
    std::vector<std::string> triremeWharf(const eTriremeWharf& w);
    // The wharf's switch: the label of the state "shut down" (value 0) and of "working" (value 1).
    std::string triremeWharfSwitch(const bool working);
}

#endif // EBUILDINGINFOTEXT_H
