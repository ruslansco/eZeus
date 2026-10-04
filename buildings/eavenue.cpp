#include "eavenue.h"

#include "textures/egametextures.h"
#include "engine/egameboard.h"

eAvenue::eAvenue(eGameBoard& board, const eCityId cid) :
    eBuilding(board, eBuildingType::avenue, 1, 1, cid) {
    eGameTextures::loadAvenue();
}

eAvenue::eAvenue(eGameBoard& board, const eBuildingType type, const eCityId cid) :
    eBuilding(board, type, 1, 1, cid) {
    eGameTextures::loadAvenue();
}

static inline bool isAvenueOrBoulevard(const eBuildingType t) {
    return t == eBuildingType::avenue || t == eBuildingType::boulevard;
}

int eAvenue::provide(const eProvide p, const int n) {
    const auto t = centerTile();
    if(!t) return eBuilding::provide(p, n);
    int rem = n;
    for(const int x : {-1, 0, 1}) {
        for(const int y : {-1, 0, 1}) {
            const auto tt = t->tileRel<eTile>(x, y);
            if(!tt) continue;
            if(const auto b = tt->underBuilding()) {
                const auto tp = b->type();
                if(isAvenueOrBoulevard(tp)) continue;
                const int r = b->provide(p, rem);
                rem -= r;
                if(rem <= 0) return n;
            }
        }
    }
    return n - rem;
}

using eTileGetter = eTile* (eTile::*)(const eWorldDirection) const;
bool isSingle(eTile* const t,
              eTileGetter tg1,
              eTileGetter tg2,
              const eWorldDirection dir) {
    if(!t) return true;
    const int tx = t->x();
    const int ty = t->y();
    const auto tl = (t->*tg1)(dir);
    const auto br = (t->*tg2)(dir);
    const bool tlb = tl && isAvenueOrBoulevard(tl->underBuildingType());
    const bool brb = br && isAvenueOrBoulevard(br->underBuildingType());
    bool single = true;
    if(tlb && brb) {
        bool s = false;
        if(tl) {
            if(const auto tltl = (tl->*tg1)(dir)) {
                s = !isAvenueOrBoulevard(tltl->underBuildingType());
            }
        }
        if(br && !s) {
            if(const auto brbr = (br->*tg2)(dir)) {
                s = !isAvenueOrBoulevard(brbr->underBuildingType());
            }
        }
        single = s;
    }
    if(!single) {
        const int id = tx + ty;
        single = id % 5 > 0;
    }
    return single;
}

std::shared_ptr<eTexture>
eAvenue::getTexture(const eTileSize size) const {
    const int sizeId = static_cast<int>(size);
    const auto& blds = eGameTextures::buildings()[sizeId];
    const auto& avn = blds.fAvenue;
    const auto t = centerTile();

    auto& board = getBoard();
    const auto dir = board.direction();

    const auto tl = t->topLeftRotated<eTile>(dir);
    const auto br = t->bottomRightRotated<eTile>(dir);
    const auto bl = t->bottomLeftRotated<eTile>(dir);
    const auto tr = t->topRightRotated<eTile>(dir);

    const auto tlt = tl ? tl->underBuildingType() : eBuildingType::none;
    const auto brt = br ? br->underBuildingType() : eBuildingType::none;
    const auto blt = bl ? bl->underBuildingType() : eBuildingType::none;
    const auto trt = tr ? tr->underBuildingType() : eBuildingType::none;

    const bool tlb = isAvenueOrBoulevard(tlt) ||
                     tlt == eBuildingType::road;
    const bool brb = isAvenueOrBoulevard(brt) ||
                     brt == eBuildingType::road;
    const bool blb = isAvenueOrBoulevard(blt) ||
                     blt == eBuildingType::road;
    const bool trb = isAvenueOrBoulevard(trt) ||
                     trt == eBuildingType::road;

    eTileGetter tg1 = nullptr;
    eTileGetter tg2 = nullptr;
    int collId = 0;
    int id = 0;
    const bool tlm = isAvenueOrBoulevard(tlt);
    const bool brm = isAvenueOrBoulevard(brt);
    const bool blm = isAvenueOrBoulevard(blt);
    const bool trm = isAvenueOrBoulevard(trt);

    const bool axis1Med = tlm || brm;
    const bool axis2Med = blm || trm;

    if(axis1Med && !axis2Med) {
        tg1 = &eTile::topLeftRotated<eTile>;
        tg2 = &eTile::bottomRightRotated<eTile>;
        if(trb && blb) {
            collId = 0;
        } else if(trb) {
            collId = 0;
        } else {
            collId = 1;
        }
    } else if(axis2Med && !axis1Med) {
        tg1 = &eTile::topRightRotated<eTile>;
        tg2 = &eTile::bottomLeftRotated<eTile>;
        if(tlb && brb) {
            collId = 2;
        } else if(tlb) {
            collId = 2;
        } else {
            collId = 3;
        }
    } else if(axis1Med && axis2Med) {
        if(tlb && brb && blb && trb) {
            const auto b = t->bottomRotated<eTile>(dir);
            const auto l = t->leftRotated<eTile>(dir);
            const auto r = t->rightRotated<eTile>(dir);

            const auto bt = b ? b->underBuildingType() : eBuildingType::none;
            const auto lt = l ? l->underBuildingType() : eBuildingType::none;
            const auto rt = r ? r->underBuildingType() : eBuildingType::none;

            const bool lb = isAvenueOrBoulevard(lt) || lt == eBuildingType::road;
            const bool bb = isAvenueOrBoulevard(bt) || bt == eBuildingType::road;
            const bool rb = isAvenueOrBoulevard(rt) || rt == eBuildingType::road;

            collId = 4;
            if(!bb) {
                id = 0;
            } else if(!rb) {
                id = 1;
            } else if(!lb) {
                id = 2;
            } else {
                id = 3;
            }
        } else if(trb && brb && !tlb && !blb) {
            collId = 4;
            id = 4;
        } else if(blb && brb && !tlb && !trb) {
            collId = 4;
            id = 5;
        } else if(blb && tlb && !brb && !trb) {
            collId = 4;
            id = 6;
        } else if(tlb && trb && !brb && !blb) {
            collId = 4;
            id = 7;
        } else {
            collId = 4;
            id = 0;
        }
    } else if(tlb && brb) {
        tg1 = &eTile::topLeftRotated<eTile>;
        tg2 = &eTile::bottomRightRotated<eTile>;
        collId = (trb || blb) ? 0 : 1;
    } else if(blb && trb) {
        tg1 = &eTile::topRightRotated<eTile>;
        tg2 = &eTile::bottomLeftRotated<eTile>;
        collId = (tlb || brb) ? 2 : 3;
    } else if(trb && brb && !tlb && !blb) {
        collId = 4;
        id = 4;
    } else if(blb && brb && !tlb && !trb) {
        collId = 4;
        id = 5;
    } else if(blb && tlb && !brb && !trb) {
        collId = 4;
        id = 6;
    } else if(tlb && trb && !brb && !blb) {
        collId = 4;
        id = 7;
    } else if(tlb || brb) {
        tg1 = &eTile::topLeftRotated<eTile>;
        tg2 = &eTile::bottomRightRotated<eTile>;
        collId = (trb || blb) ? 0 : 1;
    } else if(blb || trb) {
        tg1 = &eTile::topRightRotated<eTile>;
        tg2 = &eTile::bottomLeftRotated<eTile>;
        collId = (tlb || brb) ? 2 : 3;
    }
    if(tg1 && tg2) {
        const bool s = isSingle(t, tg1, tg2, dir);
        const bool tls = isSingle((t->*tg1)(dir), tg1, tg2, dir);
        const bool brs = isSingle((t->*tg2)(dir), tg1, tg2, dir);
        if(s && !tls) {
            id = 3;
        } else if(s && !brs) {
            id = 5;
        } else if(!s) {
            const int ids[] = {4, 6, 7};
            id = ids[seed() % 3];
        } else {
            const int ids[] = {0, 1, 2, 8};
            id = ids[seed() % 4];
        }
    }
    const auto& coll = avn[collId];
    return coll.getTexture(id);
}

eTile* eAvenue::road() const {
    const auto t = centerTile();
    const auto tl = t->topLeft<eTile>();
    if(tl && tl->hasRoad()) return tl;
    const auto br = t->bottomRight<eTile>();
    if(br && br->hasRoad()) return br;
    const auto bl = t->bottomLeft<eTile>();
    if(bl && bl->hasRoad()) return bl;
    const auto tr = t->topRight<eTile>();
    if(tr && tr->hasRoad()) return tr;
    return nullptr;
}
