#include "eagoraplacement.h"

#include "engine/egameboard.h"
#include "engine/edifficulty.h"
#include "engine/boardData/ecityfinances.h"
#include "buildings/eagoraspace.h"
#include "buildings/ecommonagora.h"
#include "buildings/egrandagora.h"
#include "buildings/eroad.h"
#include "buildings/evendor.h"

#include <climits>

namespace eAgoraPlacement {
namespace {
bool roadTile(eTile* const t) {
    if(!t) return false;
    if(!t->hasRoad()) return false;
    if(t->underBuildingType() != eBuildingType::road) return false;
    const auto ub = t->underBuilding();
    if(!ub) return false;
    const auto r = static_cast<eRoad*>(ub);
    return !r->underAgora();
}

std::vector<eTile*> placeBR(
        eGameBoard& board, eTile* const tile, const eCityId cid,
        const ePlayerId pid, const bool editor) {
    if(!roadTile(tile)) return {};
    const auto tr1 = tile->topRight<eTile>();
    if(!roadTile(tr1)) return {};
    const auto tr2 = tr1->topRight<eTile>();
    if(!roadTile(tr2)) return {};
    const auto tr3 = tr2->topRight<eTile>();
    if(!roadTile(tr3)) return {};
    const auto tr4 = tr3->topRight<eTile>();
    if(!roadTile(tr4)) return {};
    const auto tr5 = tr4->topRight<eTile>();
    if(!roadTile(tr5)) return {};
    std::vector<eTile*> brLobeTiles;
    brLobeTiles.push_back(tr5);
    brLobeTiles.push_back(tr4);
    brLobeTiles.push_back(tr3);
    brLobeTiles.push_back(tr2);
    brLobeTiles.push_back(tr1);
    brLobeTiles.push_back(tile);
    bool brLobe = true;
    {
        const int iMin = tile->x() + 1;
        const int iMax = iMin + 2;
        const int jMin = tile->y() - 5;
        const int jMax = jMin + 6;
        for(int i = iMin; i < iMax && brLobe; i++) {
            for(int j = jMin; j < jMax && brLobe; j++) {
                const auto t = board.tile(i, j);
                brLobeTiles.push_back(t);
                const bool cb = board.canBuild(i, j, 1, 1, editor, cid, pid);
                if(!cb) {
                    brLobe = false;
                    break;
                }
            }
        }
    }
    if(!brLobe) return {};
    return brLobeTiles;
}

std::vector<eTile*> placeTL(
        eGameBoard& board, eTile* const tile, const eCityId cid,
        const ePlayerId pid, const bool editor) {
    if(!roadTile(tile)) return {};
    const auto tr1 = tile->topRight<eTile>();
    if(!roadTile(tr1)) return {};
    const auto tr2 = tr1->topRight<eTile>();
    if(!roadTile(tr2)) return {};
    const auto tr3 = tr2->topRight<eTile>();
    if(!roadTile(tr3)) return {};
    const auto tr4 = tr3->topRight<eTile>();
    if(!roadTile(tr4)) return {};
    const auto tr5 = tr4->topRight<eTile>();
    if(!roadTile(tr5)) return {};
    std::vector<eTile*> tlLobeTiles;
    tlLobeTiles.push_back(tr5);
    tlLobeTiles.push_back(tr4);
    tlLobeTiles.push_back(tr3);
    tlLobeTiles.push_back(tr2);
    tlLobeTiles.push_back(tr1);
    tlLobeTiles.push_back(tile);
    bool tlLobe = true;
    {
        const int iMin = tile->x() - 3;
        const int iMax = iMin + 2;
        const int jMin = tile->y() - 5;
        const int jMax = jMin + 6;
        for(int i = iMax; i > iMin && tlLobe; i--) {
            for(int j = jMin; j < jMax && tlLobe; j++) {
                const auto t = board.tile(i, j);
                tlLobeTiles.push_back(t);
                const bool cb = board.canBuild(i, j, 1, 1, editor, cid, pid);
                if(!cb) {
                    tlLobe = false;
                    break;
                }
            }
        }
    }
    if(!tlLobe) return {};
    return tlLobeTiles;
}

std::vector<eTile*> placeBL(
        eGameBoard& board, eTile* const tile, const eCityId cid,
        const ePlayerId pid, const bool editor) {
    if(!roadTile(tile)) return {};
    const auto tl1 = tile->topLeft<eTile>();
    if(!roadTile(tl1)) return {};
    const auto tl2 = tl1->topLeft<eTile>();
    if(!roadTile(tl2)) return {};
    const auto tl3 = tl2->topLeft<eTile>();
    if(!roadTile(tl3)) return {};
    const auto tl4 = tl3->topLeft<eTile>();
    if(!roadTile(tl4)) return {};
    const auto tl5 = tl4->topLeft<eTile>();
    if(!roadTile(tl5)) return {};
    std::vector<eTile*> blLobeTiles;
    blLobeTiles.push_back(tl5);
    blLobeTiles.push_back(tl4);
    blLobeTiles.push_back(tl3);
    blLobeTiles.push_back(tl2);
    blLobeTiles.push_back(tl1);
    blLobeTiles.push_back(tile);
    bool blLobe = true;
    {
        const int iMin = tile->x() - 5;
        const int iMax = iMin + 6;
        const int jMin = tile->y() + 1;
        const int jMax = jMin + 2;
        for(int j = jMin; j < jMax && blLobe; j++) {
            for(int i = iMin; i < iMax && blLobe; i++) {
                const auto t = board.tile(i, j);
                blLobeTiles.push_back(t);
                const bool cb = board.canBuild(i, j, 1, 1, editor, cid, pid);
                if(!cb) {
                    blLobe = false;
                    break;
                }
            }
        }
    }
    if(!blLobe) return {};
    return blLobeTiles;
}

std::vector<eTile*> placeTR(
        eGameBoard& board, eTile* const tile, const eCityId cid,
        const ePlayerId pid, const bool editor) {
    if(!roadTile(tile)) return {};
    const auto tl1 = tile->topLeft<eTile>();
    if(!roadTile(tl1)) return {};
    const auto tl2 = tl1->topLeft<eTile>();
    if(!roadTile(tl2)) return {};
    const auto tl3 = tl2->topLeft<eTile>();
    if(!roadTile(tl3)) return {};
    const auto tl4 = tl3->topLeft<eTile>();
    if(!roadTile(tl4)) return {};
    const auto tl5 = tl4->topLeft<eTile>();
    if(!roadTile(tl5)) return {};
    std::vector<eTile*> trLobeTiles;
    trLobeTiles.push_back(tl5);
    trLobeTiles.push_back(tl4);
    trLobeTiles.push_back(tl3);
    trLobeTiles.push_back(tl2);
    trLobeTiles.push_back(tl1);
    trLobeTiles.push_back(tile);
    bool trLobe = true;
    {
        const int iMin = tile->x() - 5;
        const int iMax = iMin + 6;
        const int jMin = tile->y() - 3;
        const int jMax = jMin + 2;
        for(int j = jMax; j > jMin && trLobe; j--) {
            for(int i = iMin; i < iMax && trLobe; i++) {
                const auto t = board.tile(i, j);
                trLobeTiles.push_back(t);
                const bool cb = board.canBuild(i, j, 1, 1, editor, cid, pid);
                if(!cb) {
                    trLobe = false;
                    break;
                }
            }
        }
    }
    if(!trLobe) return {};
    return trLobeTiles;
}

}  // namespace

std::vector<eTile*> find(
        eGameBoard& board, eTile* const tile, const bool grand,
        eAgoraOrientation& bt, const eCityId cid,
        const ePlayerId pid, const bool editor) {
    if(!tile) return {};
    {
        const int xMin = tile->x() - 2;
        const int xMax = xMin + 3;
        const int yMin = tile->y() + 2;
        const int yMax = yMin + 3;
        for(int x = xMin; x < xMax; x++) {
            for(int y = yMin; y < yMax; y++) {
                const auto t = board.tile(x, y);
                if(!t) continue;
                const auto r = placeBR(board, t, cid, pid, editor);
                if(r.empty()) continue;
                bt = eAgoraOrientation::bottomRight;
                if(grand) {
                    const auto rr = placeTL(board, t, cid, pid, editor);
                    if(rr.empty()) continue;
                    std::vector<eTile*> rrr;
                    rrr.reserve(r.size() + rr.size());
                    rrr.insert(rrr.end(), rr.begin(), rr.end());
                    rrr.insert(rrr.end(), r.begin(), r.end());
                    return rrr;
                }
                return r;
            }
        }
    }
    {
        const int xMin = tile->x();
        const int xMax = xMin + 3;
        const int yMin = tile->y() + 2;
        const int yMax = yMin + 3;
        for(int x = xMin; x < xMax; x++) {
            for(int y = yMin; y < yMax; y++) {
                const auto t = board.tile(x, y);
                if(!t) continue;
                const auto r = placeTL(board, t, cid, pid, editor);
                if(r.empty()) continue;

                if(grand) {
                    bt = eAgoraOrientation::bottomRight;
                    const auto rr = placeBR(board, t, cid, pid, editor);
                    if(rr.empty()) continue;
                    std::vector<eTile*> rrr;
                    rrr.reserve(r.size() + rr.size());
                    rrr.insert(rrr.end(), r.begin(), r.end());
                    rrr.insert(rrr.end(), rr.begin(), rr.end());
                    return rrr;
                } else {
                    bt = eAgoraOrientation::topLeft;
                }
                return r;
            }
        }
    }
    {
        const int xMin = tile->x() + 2;
        const int xMax = xMin + 3;
        const int yMin = tile->y() - 2;
        const int yMax = yMin + 3;
        for(int x = xMin; x < xMax; x++) {
            for(int y = yMin; y < yMax; y++) {
                const auto t = board.tile(x, y);
                if(!t) continue;
                const auto r = placeBL(board, t, cid, pid, editor);
                if(r.empty()) continue;
                bt = eAgoraOrientation::bottomLeft;
                if(grand) {
                    const auto rr = placeTR(board, t, cid, pid, editor);
                    if(rr.empty()) continue;
                    std::vector<eTile*> rrr;
                    rrr.reserve(r.size() + rr.size());
                    rrr.insert(rrr.end(), rr.begin(), rr.end());
                    rrr.insert(rrr.end(), r.begin(), r.end());
                    return rrr;
                }
                return r;
            }
        }
    }
    {
        const int xMin = tile->x() + 2;
        const int xMax = xMin + 3;
        const int yMin = tile->y();
        const int yMax = yMin + 3;
        for(int x = xMin; x < xMax; x++) {
            for(int y = yMin; y < yMax; y++) {
                const auto t = board.tile(x, y);
                if(!t) continue;
                const auto r = placeTR(board, t, cid, pid, editor);
                if(r.empty()) continue;
                if(grand) {
                    bt = eAgoraOrientation::bottomLeft;
                    const auto rr = placeBL(board, t, cid, pid, editor);
                    if(rr.empty()) continue;
                    std::vector<eTile*> rrr;
                    rrr.reserve(r.size() + rr.size());
                    rrr.insert(rrr.end(), r.begin(), r.end());
                    rrr.insert(rrr.end(), rr.begin(), rr.end());
                    return rrr;
                } else {
                    bt = eAgoraOrientation::topRight;
                }
                return r;
            }
        }
    }
    return {};
}

stdsptr<eAgoraBase> build(eGameBoard& board, const std::vector<eTile*>& p, const bool grand,
                          const eAgoraOrientation bt, const eCityId viewedCity) {
    stdsptr<eAgoraBase> b;
    if(grand) b = e::make_shared<eGrandAgora>(bt, board, viewedCity);
    else b = e::make_shared<eCommonAgora>(bt, board, viewedCity);
    int x = INT_MAX;
    int y = INT_MAX;
    int w = 0;
    int h = 0;
    int ri = 0;
    for(const auto t : p) {
        const int tx = t->x();
        const int ty = t->y();
        if(tx < x) x = tx;
        if(ty < y) y = ty;
        if(t->hasRoad() && t->underBuildingType() == eBuildingType::road) {
            const auto bb = t->underBuilding();
            const auto r = static_cast<eRoad*>(bb);
            r->setUnderAgora(b.get());
            if(ri++ == 3) b->setCenterTile(t);
        } else {
            b->addUnderBuilding(t);
        }
    }
    const bool wide = bt == eAgoraOrientation::bottomLeft || bt == eAgoraOrientation::topRight;
    if(grand) {
        w = wide ? 6 : 5;
        h = wide ? 5 : 6;
    } else {
        w = wide ? 6 : 3;
        h = wide ? 3 : 6;
    }
    b->setTileRect(SDL_Rect{x, y, w, h});
    b->fillSpaces();
    return b;
}

eBuilding* spaceAt(eGameBoard& board, const int tx, const int ty) {
    const auto t = board.tile(tx, ty);
    if(!t) return nullptr;
    const auto b = t->underBuilding();
    if(!b || b->type() != eBuildingType::agoraSpace) return nullptr;
    return b;
}

bool canPlaceVendor(eGameBoard& board, const int tx, const int ty, const eResourceType resource) {
    const auto b = spaceAt(board, tx, ty);
    if(!b) return false;
    const auto space = static_cast<eAgoraSpace*>(b);
    if(space->agora()->vendor(resource)) return false;
    const auto ct = b->centerTile();
    if(!ct) return false;
    return ct->x() == tx && ct->y() == ty;
}

bool placeVendor(eGameBoard& board, const int tx, const int ty, const eResourceType resource,
                 const eCityId cid, const eVendorFactory& factory) {
    if(!canPlaceVendor(board, tx, ty, resource)) return false;
    const auto space = static_cast<eAgoraSpace*>(spaceAt(board, tx, ty));
    const auto agora = space->agora();
    const auto agoraP = agora->ref<eAgoraBase>();
    const auto fv = factory(board, cid);
    fv->setAgora(agoraP);
    agora->setBuilding(space, fv);
    const auto ppid = board.personPlayer();
    const auto diff = board.difficulty(ppid);
    const int cost = eDifficultyHelpers::buildingCost(diff, fv->type());
    board.incDrachmas(ppid, -cost, eFinanceTarget::construction);
    return true;
}
}  // namespace eAgoraPlacement
