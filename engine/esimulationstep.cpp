#include "esimulationstep.h"
#include "egameboard.h"
bool eSimulationStep(eGameBoard& board, int speed, bool maximumSpeed,
                     const std::function<bool()>& running,
                     const std::function<void()>& advanced) {
    board.incFrame();
    for(int i = 0; i < (maximumSpeed ? 5 : 1); ++i) {
        board.scheduleDataUpdate();
        board.updateAppealMapIfNeeded();
        board.handleFinishedTasks();
        const bool incTime = running();
        if(incTime) {
            if(board.episodeLost()) return false;
            if(advanced) advanced();
            board.incTime(speed);
        }
        board.emptyRubbish();
        if(maximumSpeed) board.waitUntilFinished();
        if(!incTime) break;
    }
    return true;
}
