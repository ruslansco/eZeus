#ifndef EPLAYERCONQUESTEVENTBASE_H
#define EPLAYERCONQUESTEVENTBASE_H

#include "earmyeventbase.h"

class ePlayerConquestEventBase : public eArmyEventBase {
public:
    ePlayerConquestEventBase(const eCityId cid,
                             const eGameEventType type,
                             const eGameEventBranch branch,
                             eGameBoard& board);
    ~ePlayerConquestEventBase();

    // Ares marches with the army; he comes home to his sanctuary in city `aresCity`.
    void addAres(const eCityId aresCity);
protected:
    void removeConquestEvent();
};

#endif // EPLAYERCONQUESTEVENTBASE_H
