#include "etradepartners.h"

#include "engine/egameboard.h"
#include "engine/eworldcity.h"
#include "engine/ecityid.h"

namespace eTradePartners {

std::vector<eTradePartner> available(eGameBoard& board, const eCityId cid, const bool showAllPossible) {
    std::vector<eTradePartner> result;
    const auto pid = board.cityIdToPlayerId(cid);
    const auto ppid = board.personPlayer();
    if(pid != ppid && !showAllPossible) return result;
    const auto& wrld = board.world();
    int i = -1;
    for(const auto& c : wrld.cities()) {
        const auto cCid = c->cityId();
        i++;
        if(c->isRival() && !showAllPossible) continue;
        if(cid == cCid) continue;
        if(!c->active() && !showAllPossible) continue;
        if(!c->visible() && !showAllPossible) continue;
        if(board.hasTradePost(cid, *c)) continue;
        const auto tradeCid = c->cityId();
        const auto tradePid = board.cityIdToPlayerId(tradeCid);
        const auto tradeC = board.boardCityWithId(tradeCid);
        const auto tradeTid = board.playerIdToTeamId(tradePid);
        const auto tid = board.playerIdToTeamId(pid);
        if(eTeamIdHelpers::isEnemy(tradeTid, tid)) continue;
        if(!c->buys().empty() || !c->sells().empty() ||
           (tradeC && pid == tradePid)) {
            result.push_back({i, c.get(), c->waterTrade(cid)});
        }
    }
    return result;
}

}
