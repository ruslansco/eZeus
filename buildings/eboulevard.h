#ifndef EBOULEVARD_H
#define EBOULEVARD_H

#include "eavenue.h"

class eBoulevard : public eAvenue {
public:
    eBoulevard(eGameBoard& board, const eCityId cid);
};

#endif // EBOULEVARD_H
