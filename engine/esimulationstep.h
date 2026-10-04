#pragma once
#include <functional>
class eGameBoard;
bool eSimulationStep(eGameBoard& board, int speed, bool maximumSpeed,
                     const std::function<bool()>& running,
                     const std::function<void()>& advanced = {});
