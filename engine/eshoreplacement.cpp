#include "eshoreplacement.h"

#include "engine/egameboard.h"
#include "engine/eknownendpathfinder.h"
#include "ebuildablehelpers.h"
#include "buildings/epier.h"
#include "buildings/etradepost.h"

namespace eShorePlacement {

bool tileBuildable(eTile* const t) {
    if(!t) return false;
    if(t->underBuilding()) return false;
    const auto& banners = t->banners();
    for(const auto& b : banners) {
        if(!b->buildable()) return false;
    }
    if(t->isElevationTile()) return false;
    const auto& chars = t->characters();
    if(!chars.empty()) return false;
    return true;
}

bool canBuildFishery(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o) {
    for(int x = tx; x < tx + 2; x++) {
        for(int y = ty - 1; y < ty - 1 + 2; y++) {
            const auto t = board.tile(x, y);
            const bool b = tileBuildable(t);
            if(!b) return false;
        }
    }
    const auto t = board.tile(tx, ty);
    if(!t) return false;
    const bool tr = eBuildableHelpers::canBuildFisheryTR(t);
    if(tr) {
        o = eDiagonalOrientation::topRight;
        return true;
    }
    const bool br = eBuildableHelpers::canBuildFisheryBR(t);
    if(br) {
        o = eDiagonalOrientation::bottomRight;
        return true;
    }
    const bool bl = eBuildableHelpers::canBuildFisheryBL(t);
    if(bl) {
        o = eDiagonalOrientation::bottomLeft;
        return true;
    }
    const bool tl = eBuildableHelpers::canBuildFisheryTL(t);
    if(tl) {
        o = eDiagonalOrientation::topLeft;
        return true;
    }
    return false;
}

bool waterAccess(eGameBoard& board, const eCityId cid, const int tx, const int ty) {
    const auto t = board.tile(tx, ty);
    if(!t) return false;
    if(!t->hasWater()) return false;
    const auto riverEntry = board.riverEntryPoint(cid);
    if(!riverEntry) return false;
    eKnownEndPathFinder p([](eTileBase* const tile) {
        return tile->hasWater();
    }, riverEntry);
    const int w = board.width();
    const int h = board.height();
    const bool r = p.findPath({0, 0, w, h}, t, 1000, true, w, h);
    return r;
}

void pierPostCorner(const int tx, const int ty, const eDiagonalOrientation o, int& minX, int& minY) {
    switch(o) {
    case eDiagonalOrientation::topRight: {
        minX = tx - 1;
        minY = ty + 1;
    } break;
    case eDiagonalOrientation::bottomRight: {
        minX = tx - 4;
        minY = ty - 2;
    } break;
    case eDiagonalOrientation::bottomLeft: {
        minX = tx - 1;
        minY = ty - 5;
    } break;
    default:
    case eDiagonalOrientation::topLeft: {
        minX = tx + 2;
        minY = ty - 2;
    } break;
    }
}

bool canBuildPier(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o,
                  const eCityId cid, const ePlayerId pid, const bool forestAllowed) {
    const bool r = canBuildFishery(board, tx, ty, o);
    if(!r) return false;
    int minX;
    int minY;
    pierPostCorner(tx, ty, o, minX, minY);
    return board.canBuildBase(minX, minX + 4, minY, minY + 4, forestAllowed, cid, pid);
}

bool pierHasSeaAccess(eGameBoard& board, const int tx, const int ty, const eCityId cid) {
    const int minX = tx;
    const int minY = ty - 1;
    bool accessToSea = false;
    for(int x = minX; x < minX + 2; x++) {
        for(int y = minY; y < minY + 2; y++) {
            const auto t = board.tile(x, y);
            if(!t) continue;
            if(t->hasWater()) {
                accessToSea = waterAccess(board, cid, x, y);
                x += 2;
                break;
            }
        }
    }
    return accessToSea;
}

bool placePier(eGameBoard& board, const int tx, const int ty, const eDiagonalOrientation o, eWorldCity& partner,
               const eCityId cid, const ePlayerId pid, const bool editor) {
    const int minX = tx;
    const int minY = ty - 1;
    const auto b = e::make_shared<ePier>(board, o, cid);
    const auto tile = board.tile(tx, ty);
    b->setCenterTile(tile);
    b->setTileRect({tx, minY, 2, 2});
    for(int x = minX; x < minX + 2; x++) {
        for(int y = minY; y < minY + 2; y++) {
            const auto t = board.tile(x, y);
            if(t) {
                t->setUnderBuilding(b);
                b->addUnderBuilding(t);
            }
        }
    }
    int px = tx;
    int py = ty;
    switch(o) {
    case eDiagonalOrientation::topRight: {
        py += 3;
    } break;
    case eDiagonalOrientation::bottomRight: {
        px -= 3;
    } break;
    case eDiagonalOrientation::bottomLeft: {
        py -= 3;
    } break;
    default:
    case eDiagonalOrientation::topLeft: {
        px += 3;
    } break;
    }
    const auto tp = e::make_shared<eTradePost>(board, partner, cid, eTradePostType::pier);
    tp->setOrientation(o);
    tp->setUnpackBuilding(b.get());
    const bool built = board.build(px, py, 4, 4, cid, pid, editor, [&]() { return tp; });
    b->setTradePost(tp.get());
    return built;
}

}  // namespace eShorePlacement
