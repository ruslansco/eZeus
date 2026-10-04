#include "ebuildplacement.h"

#include <SDL2/SDL_rect.h>

#include "engine/egameboard.h"
#include "engine/eboardcity.h"
#include "engine/epathfinder.h"
#include "engine/edifficulty.h"
#include "engine/eshoreplacement.h"
#include "ebuildablehelpers.h"
#include "evectorhelpers.h"
#include "buildings/allbuildings.h"

namespace eBuildPlacement {

void stadiumRect(const int tx, const int ty, const bool rotate,
                 int& minX, int& minY, int& w, int& h) {
    w = rotate ? 5 : 10;
    h = rotate ? 10 : 5;
    int maxX, maxY;
    eGameBoard::sBuildTiles(minX, minY, maxX, maxY, tx, ty, w, h);
}

bool canBuildStadium(eGameBoard& board, const int tx, const int ty, const bool rotate,
                     const eCityId cid, const ePlayerId pid, const bool editor) {
    const int dx = rotate ? 0 : 5;
    const int dy = rotate ? 5 : 0;
    const auto t1 = board.tile(tx, ty);
    if(!t1) return false;
    const bool cb1 = board.canBuild(t1->x(), t1->y(), 5, 5, editor, cid, pid);
    if(!cb1) return false;
    const auto t2 = t1->tileRel<eTile>(dx, dy);
    if(!t2) return false;
    return board.canBuild(t2->x(), t2->y(), 5, 5, editor, cid, pid);
}

bool buildStadium(eGameBoard& board, const int tx, const int ty, const bool rotate,
                  const eCityId cid, const ePlayerId pid, const bool editor) {
    if(!canBuildStadium(board, tx, ty, rotate, cid, pid, editor)) return false;
    const int sw = rotate ? 5 : 10;
    const int sh = rotate ? 10 : 5;
    return board.build(tx, ty, sw, sh, cid, pid, editor, [&]() {
        return e::make_shared<eStadium>(board, rotate, cid);
    });
}

void palaceRect(const int tx, const int ty, const bool rotate,
                int& minX, int& minY, int& w, int& h) {
    w = rotate ? 4 : 8;
    h = rotate ? 8 : 4;
    int maxX, maxY;
    eGameBoard::sBuildTiles(minX, minY, maxX, maxY, tx, ty, w, h);
}

std::vector<ePalaceTilePlan> palaceTiles(const int tx, const int ty, const bool rotate) {
    const int sw = rotate ? 4 : 8;
    const int sh = rotate ? 8 : 4;
    const int tminX = tx - 2;
    const int tminY = ty - 3;
    const int tmaxX = tminX + (rotate ? 6 : 9);
    const int tmaxY = tminY + (rotate ? 9 : 6);
    const SDL_Rect rect{tminX + 1, tminY + 1, sw, sh};
    std::vector<ePalaceTilePlan> tiles;
    for(int x = tminX; x < tmaxX; x++) {
        for(int y = tminY; y < tmaxY; y++) {
            const SDL_Point pt{x, y};
            if(SDL_PointInRect(&pt, &rect)) continue;
            bool other = x == tminX && y == tminY;
            if(!other) {
                if(rotate) {
                    other = x == tmaxX - 1 && y == tminY;
                } else {
                    other = x == tminX && y == tmaxY - 1;
                }
            }
            tiles.push_back({x, y, other});
        }
    }
    return tiles;
}

bool canBuildPalace(eGameBoard& board, const int tx, const int ty, const bool rotate,
                    const eCityId cid, const ePlayerId pid, const bool editor) {
    for(const auto& t : palaceTiles(tx, ty, rotate)) {
        if(!board.canBuild(t.fX, t.fY, 1, 1, editor, cid, pid)) return false;
    }
    const int dx = rotate ? 0 : 4;
    const int dy = rotate ? 4 : 0;
    const auto t1 = board.tile(tx, ty);
    if(!t1) return false;
    const bool cb1 = board.canBuild(t1->x(), t1->y(), 4, 4, editor, cid, pid);
    if(!cb1) return false;
    const auto t2 = t1->tileRel<eTile>(dx, dy);
    if(!t2) return false;
    return board.canBuild(t2->x(), t2->y(), 4, 4, editor, cid, pid);
}

bool buildPalace(eGameBoard& board, const int tx, const int ty, const bool rotate,
                 const eCityId cid, const ePlayerId pid, const bool editor) {
    if(!canBuildPalace(board, tx, ty, rotate, cid, pid, editor)) return false;
    const int sw = rotate ? 4 : 8;
    const int sh = rotate ? 8 : 4;
    const auto s = e::make_shared<ePalace>(board, rotate, cid);
    for(const auto& t : palaceTiles(tx, ty, rotate)) {
        board.build(t.fX, t.fY, 1, 1, cid, pid, editor, [&]() {
            const auto pt = e::make_shared<ePalaceTile>(board, t.fOther, cid);
            pt->setPalace(s.get());
            s->addTile(pt.get());
            return pt;
        });
    }
    return board.build(tx, ty, sw, sh, cid, pid, editor, [&]() {
        return s;
    });
}

static void horseRanchOffset(const int rotateId, int& dx, int& dy) {
    dx = 0;
    dy = 0;
    if(rotateId == 0) { // bottomRight
        dx = 3;
    } else if(rotateId == 1) { // topRight
        dy = -3;
        dx = -1;
    } else if(rotateId == 2) { // topLeft
        dx = -4;
        dy = 1;
    } else if(rotateId == 3) { // bottomLeft
        dy = 4;
    }
}

void horseRanchRects(const int tx, const int ty, const int rotateId,
                     int& ranchX, int& ranchY, int& paddockX, int& paddockY) {
    int dx, dy;
    horseRanchOffset(rotateId, dx, dy);
    int maxX, maxY;
    eGameBoard::sBuildTiles(ranchX, ranchY, maxX, maxY, tx, ty, 3, 3);
    eGameBoard::sBuildTiles(paddockX, paddockY, maxX, maxY, tx + dx, ty + dy, 4, 4);
}

bool canBuildHorseRanch(eGameBoard& board, const int tx, const int ty, const int rotateId,
                        const eCityId cid, const ePlayerId pid, const bool editor) {
    const bool cb1 = board.canBuild(tx, ty, 3, 3, editor, cid, pid);
    if(!cb1) return false;
    int dx, dy;
    horseRanchOffset(rotateId, dx, dy);
    return board.canBuild(tx + dx, ty + dy, 4, 4, editor, cid, pid);
}

bool buildHorseRanch(eGameBoard& board, const int tx, const int ty, const int rotateId,
                     const eCityId cid, const ePlayerId pid, const bool editor) {
    if(!canBuildHorseRanch(board, tx, ty, rotateId, cid, pid, editor)) return false;
    int dx, dy;
    horseRanchOffset(rotateId, dx, dy);
    const auto hr = e::make_shared<eHorseRanch>(board, cid);
    const auto hre = e::make_shared<eHorseRanchEnclosure>(board, cid);
    hre->setRanch(hr.get());
    hr->setEnclosure(hre.get());
    board.build(tx, ty, 3, 3, cid, pid, editor, [hr]() { return hr; });
    board.build(tx + dx, ty + dy, 4, 4, cid, pid, editor, [hre]() { return hre; });
    return true;
}

bool canBuildGodMonument(eGameBoard& board, const int tx, const int ty,
                         const eCityId cid, const ePlayerId pid, const bool editor) {
    return board.canBuild(tx, ty, 4, 4, editor, cid, pid);
}

bool buildGodMonument(eGameBoard& board, const int tx, const int ty, const eGodType god,
                      const eCityId cid, const ePlayerId pid, const bool editor) {
    const int tminX = tx - 1;
    const int tminY = ty - 2;
    const int tmaxX = tminX + 4;
    const int tmaxY = tminY + 4;
    if(!canBuildGodMonument(board, tx, ty, cid, pid, editor)) return false;
    const auto s = e::make_shared<eGodMonument>(god, eGodQuestId::godQuest1, board, cid);
    const bool b = board.build(tminX + 1, tminY + 2, 2, 2, cid, pid, editor, [&]() {
        return s;
    });
    for(int x = tminX; x < tmaxX; x++) {
        for(int y = tminY; y < tmaxY; y++) {
            const bool cb = board.canBuild(x, y, 1, 1, editor, cid, pid);
            if(!cb) continue;
            board.build(x, y, 1, 1, cid, pid, editor, [&]() {
                const auto t = e::make_shared<eGodMonumentTile>(board, cid);
                t->setMonument(s.get());
                s->addTile(t.get());
                return t;
            });
        }
    }
    return b;
}

bool canBuildTriremeWharf(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o) {
    for(int x = tx - 1; x < tx - 1 + 3; x++) {
        for(int y = ty - 1; y < ty - 1 + 3; y++) {
            const auto t = board.tile(x, y);
            const bool b = eShorePlacement::tileBuildable(t);
            if(!b) return false;
        }
    }
    {
        const auto t = board.tile(tx - 1, ty);
        if(!t) return false;
        const bool tr = eBuildableHelpers::canBuildFisheryTR(t);
        if(tr) {
            const auto br = t->bottomRight<eTile>();
            const bool tr = eBuildableHelpers::canBuildFisheryTR(br);
            if(tr) {
                o = eDiagonalOrientation::topRight;
                return true;
            }
        }
    }
    {
        const auto t = board.tile(tx, ty);
        if(!t) return false;
        const bool br = eBuildableHelpers::canBuildFisheryBR(t);
        if(br) {
            const auto bl = t->bottomLeft<eTile>();
            const bool br = eBuildableHelpers::canBuildFisheryBR(bl);
            if(br) {
                o = eDiagonalOrientation::bottomRight;
                return true;
            }
        }
    }
    {
        const auto t = board.tile(tx - 1, ty + 1);
        if(!t) return false;
        const bool bl = eBuildableHelpers::canBuildFisheryBL(t);
        if(bl) {
            const auto br = t->bottomRight<eTile>();
            const bool bl = eBuildableHelpers::canBuildFisheryBL(br);
            if(bl) {
                o = eDiagonalOrientation::bottomLeft;
                return true;
            }
        }
    }
    {
        const auto t = board.tile(tx - 1, ty + 1);
        if(!t) return false;
        const bool tl = eBuildableHelpers::canBuildFisheryTL(t);
        if(tl) {
            const auto tr = t->topRight<eTile>();
            const bool tl = eBuildableHelpers::canBuildFisheryTL(tr);
            if(tl) {
                o = eDiagonalOrientation::topLeft;
                return true;
            }
        }
    }
    return false;
}

bool triremeWharfSeaAccess(eGameBoard& board, const int tx, const int ty, const eCityId cid) {
    const int minX = tx - 1;
    const int minY = ty - 1;
    for(int x = minX; x < minX + 3; x++) {
        for(int y = minY; y < minY + 3; y++) {
            const auto t = board.tile(x, y);
            if(!t) continue;
            if(t->hasWater()) return eShorePlacement::waterAccess(board, cid, x, y);
        }
    }
    return false;
}

void placeShoreBuilding(eGameBoard& board, const eBuildingType type, const int tx, const int ty,
                        const eDiagonalOrientation o, const eCityId cid, const ePlayerId pid, const bool editor) {
    stdsptr<eBuilding> b;
    SDL_Rect rect;
    if(type == eBuildingType::triremeWharf) {
        b = e::make_shared<eTriremeWharf>(board, o, cid);
        rect = {tx - 1, ty - 1, 3, 3};
    } else if(type == eBuildingType::urchinQuay) {
        b = e::make_shared<eUrchinQuay>(board, o, cid);
        rect = {tx, ty - 1, 2, 2};
    } else {
        b = e::make_shared<eFishery>(board, o, cid);
        rect = {tx, ty - 1, 2, 2};
    }
    const auto tile = board.tile(tx, ty);
    b->setCenterTile(tile);
    b->setTileRect(rect);
    for(int x = rect.x; x < rect.x + rect.w; x++) {
        for(int y = rect.y; y < rect.y + rect.h; y++) {
            const auto t = board.tile(x, y);
            if(t) {
                t->setUnderBuilding(b);
                b->addUnderBuilding(t);
            }
        }
    }
    if(!editor) {
        const auto diff = board.difficulty(pid);
        const int cost = eDifficultyHelpers::buildingCost(diff, type);
        board.incDrachmas(pid, -cost, eFinanceTarget::construction);
    }
}

bool bridgeTiles(eTile* const t, const eTerrain terr, std::vector<eTile*>& tiles, bool& rotated) {
    tiles.clear();
    rotated = false;
    if(!t) return false;
    if(!t->isShoreTile(terr)) return false;
    if(t->underBuilding()) return false;
    const auto tl = t->topLeft<eTile>();
    if(!tl) return false;
    const auto tr = t->topRight<eTile>();
    if(!tr) return false;
    const auto bl = t->bottomLeft<eTile>();
    if(!bl) return false;
    const auto br = t->bottomRight<eTile>();
    if(!br) return false;

    if(tr->isShoreTile(terr) && bl->isShoreTile(terr)) {
        if(br->hasTerrain(terr)) {
            if(tl->hasTerrain(terr)) return false;
            auto tt = t;
            tiles.push_back(tt);
            while(true) {
                const auto ttt = tt->bottomRight<eTile>();
                if(!ttt || ttt->hasBridge() || !ttt->hasTerrain(terr)) break;
                tt = ttt;
                tiles.push_back(tt);
                if(tt->isShoreTile(terr)) break;
            }
            if(!tt) return false;
            const auto tt_tr = tt->topRight<eTile>();
            const auto tt_bl = tt->bottomLeft<eTile>();
            if(!tt_tr->isShoreTile(terr) || !tt_bl->isShoreTile(terr)) {
                return false;
            }
            const auto tt_tl = tt->bottomRight<eTile>();
            if(tt_tl->hasTerrain(terr)) return false;
        } else {
            auto tt = t;
            tiles.push_back(tt);
            while(true) {
                const auto ttt = tt->topLeft<eTile>();
                if(!ttt || ttt->hasBridge() || !ttt->hasTerrain(terr)) break;
                tt = ttt;
                tiles.push_back(tt);
                if(tt->isShoreTile(terr)) break;
            }
            if(!tt) return false;
            const auto tt_tr = tt->topRight<eTile>();
            const auto tt_bl = tt->bottomLeft<eTile>();
            if(!tt_tr->isShoreTile(terr) || !tt_bl->isShoreTile(terr)) {
                return false;
            }
            const auto tt_tl = tt->topLeft<eTile>();
            if(tt_tl->hasTerrain(terr)) return false;
        }
        return !tr->underBuilding() && !bl->underBuilding();
    } else if(tl->isShoreTile(terr) && br->isShoreTile(terr)) {
        rotated = true;
        if(bl->hasTerrain(terr)) {
            if(tr->hasTerrain(terr)) return false;
            auto tt = t;
            tiles.push_back(tt);
            while(true) {
                const auto ttt = tt->bottomLeft<eTile>();
                if(!ttt || ttt->hasBridge() || !ttt->hasTerrain(terr)) break;
                tt = ttt;
                tiles.push_back(tt);
                if(tt->isShoreTile(terr)) break;
            }
            if(!tt) return false;
            const auto tt_tl = tt->topLeft<eTile>();
            const auto tt_br = tt->bottomRight<eTile>();
            if(!tt_tl->isShoreTile(terr) || !tt_br->isShoreTile(terr)) {
                return false;
            }
            const auto tt_bl = tt->bottomLeft<eTile>();
            if(tt_bl->hasTerrain(terr)) return false;
        } else {
            auto tt = t;
            tiles.push_back(tt);
            while(true) {
                const auto ttt = tt->topRight<eTile>();
                if(!ttt || ttt->hasBridge() || !ttt->hasTerrain(terr)) break;
                tt = ttt;
                tiles.push_back(tt);
                if(tt->isShoreTile(terr)) break;
            }
            if(!tt) return false;
            const auto tt_tl = tt->topLeft<eTile>();
            const auto tt_br = tt->bottomRight<eTile>();
            if(!tt_tl->isShoreTile(terr) || !tt_br->isShoreTile(terr)) {
                return false;
            }
            const auto tt_tr = tt->topRight<eTile>();
            if(tt_tr->hasTerrain(terr)) return false;
        }
        return !tl->underBuilding() && !br->underBuilding();
    }

    return false;
}

void buildBridge(eGameBoard& board, const std::vector<eTile*>& tiles,
                 const eCityId cid, const ePlayerId pid, const bool editor) {
    for(const auto t : tiles) {
        const auto b = e::make_shared<eRoad>(board, cid);
        b->setCenterTile(t);
        b->setTileRect({t->x(), t->y(), 1, 1});
        t->setUnderBuilding(b);
        b->addUnderBuilding(t);
    }

    if(!editor) {
        const auto diff = board.difficulty(pid);
        const int cost = eDifficultyHelpers::buildingCost(diff, eBuildingType::bridge);
        board.incDrachmas(pid, -tiles.size()*cost, eFinanceTarget::construction);
    }
}

bool roadPath(eGameBoard& board, const int fromX, const int fromY, const int toX, const int toY,
              const bool editor, std::vector<eOrientation>& path) {
    const auto allowed = editor ? eTerrain::buildableAfterClear :
                                  eTerrain::buildable;
    ePathFinder p([allowed](eTileBase* const t) {
        const auto terr = t->terrain();
        const bool tr = static_cast<bool>(allowed & terr);
        if(!tr) return false;
        const auto bt = t->underBuildingType();
        const bool r = bt == eBuildingType::road ||
                       bt == eBuildingType::avenue ||
                       bt == eBuildingType::boulevard ||
                       bt == eBuildingType::none;
        if(!r) return false;
        if(!t->walkableElev() && t->isElevationTile()) return false;
        return true;
    }, [toX, toY](eTileBase* const t) {
        return t->x() == toX && t->y() == toY;
    });
    const auto startTile = board.tile(fromX, fromY);
    const int w = board.width();
    const int h = board.height();
    const bool r = p.findPath({0, 0, w, h}, startTile, 100, true, w, h);
    if(!r) return false;
    return p.extractPath(path);
}

bool columnPath(eGameBoard& board, const int fromX, const int fromY, const int toX, const int toY,
                std::vector<eOrientation>& path) {
    ePathFinder p([](eTileBase* const t) {
        const auto terr = t->terrain();
        const bool tr = static_cast<bool>(eTerrain::buildable & terr);
        if(!tr) return false;
        if(t->isElevationTile()) return false;
        const auto bt = t->underBuildingType();
        const bool r = bt == eBuildingType::doricColumn ||
                       bt == eBuildingType::ionicColumn ||
                       bt == eBuildingType::corinthianColumn ||
                       bt == eBuildingType::none;
        if(!r) return false;
        return true;
    }, [toX, toY](eTileBase* const t) {
        return t->x() == toX && t->y() == toY;
    });
    const auto startTile = board.tile(fromX, fromY);
    const int w = board.width();
    const int h = board.height();
    const bool r = p.findPath({0, 0, w, h}, startTile, 100, true, w, h);
    if(!r) return false;
    return p.extractPath(path);
}

std::vector<eTile*> pathTiles(eTile* const start, const std::vector<eOrientation>& path, const bool found) {
    std::vector<eTile*> tiles;
    if(!start) return tiles;
    if(found && !path.empty()) {
        eTile* t = start;
        for(int i = (int)path.size() - 1; i >= 0; i--) {
            if(!t) break;
            tiles.push_back(t);
            t = t->neighbour<eTile>(path[i]);
        }
        if(t) tiles.push_back(t);
    } else {
        tiles.push_back(start);
    }
    return tiles;
}

eAvenuePlan avenuePlan(eTile* const start, const std::vector<eOrientation>& path, const bool found) {
    eAvenuePlan plan;
    if(!start) return plan;
    plan.fMedians = pathTiles(start, path, found);

    int axis1Count = 0;
    int axis2Count = 0;
    for(const auto ori : path) {
        if(ori == eOrientation::topLeft || ori == eOrientation::bottomRight) {
            axis1Count++;
        } else if(ori == eOrientation::topRight || ori == eOrientation::bottomLeft) {
            axis2Count++;
        }
    }
    bool isAxis1 = (axis1Count >= axis2Count);
    if(!found || path.empty()) {
        const auto tl = start->topLeft<eTile>();
        const auto br = start->bottomRight<eTile>();
        const auto tr = start->topRight<eTile>();
        const auto bl = start->bottomLeft<eTile>();
        const bool r1 = (tl && tl->hasRoad()) || (br && br->hasRoad());
        const bool r2 = (tr && tr->hasRoad()) || (bl && bl->hasRoad());
        if(r2 && !r1) isAxis1 = false;
    }
    plan.fAxis1 = isAxis1;
    return plan;
}

std::vector<eTile*> avenueFlanks(const eAvenuePlan& plan, eTile* const t, const bool boulevard) {
    if(!t) return {};
    if(boulevard) {
        if(plan.fAxis1) return {t->topRight<eTile>(), t->bottomLeft<eTile>()};
        return {t->topLeft<eTile>(), t->bottomRight<eTile>()};
    }
    if(plan.fAxis1) {
        const auto tr = t->topRight<eTile>();
        const auto bl = t->bottomLeft<eTile>();
        if(bl && bl->hasRoad()) return {bl};
        if(tr && tr->hasRoad()) return {tr};
        return {tr ? tr : bl};
    } else {
        const auto tl = t->topLeft<eTile>();
        const auto br = t->bottomRight<eTile>();
        if(br && br->hasRoad()) return {br};
        if(tl && tl->hasRoad()) return {tl};
        return {tl ? tl : br};
    }
}

bool canBuildAvenueMedian(eGameBoard& board, eTile* const t, const bool boulevard,
                          const eCityId cid, const ePlayerId pid, const bool editor) {
    if(!t) return false;
    if(t->underBuildingType() == (boulevard ? eBuildingType::boulevard : eBuildingType::avenue)) return false;
    return board.canBuildAvenue(t, cid, pid, editor);
}

bool canBuildAvenueFlank(eGameBoard& board, eTile* const t,
                         const eCityId cid, const ePlayerId pid, const bool editor) {
    if(!t) return false;
    if(t->underBuildingType() == eBuildingType::road ||
       t->underBuildingType() == eBuildingType::avenue ||
       t->underBuildingType() == eBuildingType::boulevard) return false;
    if(t->underBuilding()) return false;
    const int rx = t->x();
    const int ry = t->y();
    return board.canBuildBase(rx, rx + 1, ry, ry + 1, editor, cid, pid, false, true);
}

bool buildAvenue(eGameBoard& board, const eAvenuePlan& plan, const bool boulevard,
                 const eCityId cid, const ePlayerId pid, const bool editor) {
    bool r = false;
    const auto buildMedianTile = [&](eTile* const t) {
        if(!canBuildAvenueMedian(board, t, boulevard, cid, pid, editor)) return;
        const int d = board.drachmas(pid);
        if(!editor && d < -1000) return;
        const auto ubt = t->underBuildingType();
        if(ubt == eBuildingType::road || (boulevard && ubt == eBuildingType::avenue)) {
            const auto ub = t->underBuilding();
            if(ub) ub->eBuilding::erase();
        }
        r = board.build(t->x(), t->y(), 1, 1, cid, pid, editor, [&]() -> stdsptr<eBuilding> {
            if(boulevard) return e::make_shared<eBoulevard>(board, cid);
            return e::make_shared<eAvenue>(board, cid);
        }, false, true) || r;
    };
    const auto buildRoadTile = [&](eTile* const t) {
        if(!canBuildAvenueFlank(board, t, cid, pid, editor)) return;
        const int d = board.drachmas(pid);
        if(!editor && d < -1000) return;
        r = board.build(t->x(), t->y(), 1, 1, cid, pid, editor,
              [&]() { return e::make_shared<eRoad>(board, cid); },
              false, true) || r;
    };
    for(const auto t : plan.fMedians) {
        if(!t) continue;
        buildMedianTile(t);
        for(const auto f : avenueFlanks(plan, t, boulevard)) buildRoadTile(f);
    }
    board.scheduleTerrainUpdate();
    return r;
}

bool canPlaceRoadblock(eTile* const t) {
    if(!t || !t->hasRoad() || t->hasBridge() || t->underBuildingType() != eBuildingType::road) return false;
    return !static_cast<eRoad*>(t->underBuilding())->isRoadblock();
}

bool placeRoadblock(eTile* const t) {
    if(!canPlaceRoadblock(t)) return false;
    static_cast<eRoad*>(t->underBuilding())->setRoadblock(true);
    return true;
}

std::vector<int> hippodromePieceIds(eGameBoard& board, const eCityId cid, const int tx, const int ty) {
    std::vector<int> ids;
    const auto hs = board.buildings(cid, eBuildingType::hippodromePiece);
    if(hs.empty()) {
        ids = {0, 1, 2, 3, 4, 5, 6, 7};
        return ids;
    }

    int minX;
    int minY;
    int maxX;
    int maxY;
    eGameBoard::sBuildTiles(minX, minY, maxX, maxY, tx, ty, 4, 4);
    maxY--;
    maxX--;
    bool topLeft = false;
    bool topRight = false;
    bool bottomRight = false;
    bool bottomLeft = false;

    bool topLeftBlocked = false;
    bool topRightBlocked = false;
    bool bottomRightBlocked = false;
    bool bottomLeftBlocked = false;

    const auto hippodromeAt = [&](const int x, const int y) {
        const auto b = board.buildingAt(x, y);
        if(!b) return static_cast<eHippodromePiece*>(nullptr);
        const auto type = b->type();
        if(type == eBuildingType::hippodromePiece) {
            const auto h = static_cast<eHippodromePiece*>(b);
            return h;
        } else if(type == eBuildingType::road) {
            const auto r = static_cast<eRoad*>(b);
            return r->aboveHippodrome();
        }
        return static_cast<eHippodromePiece*>(nullptr);
    };

    {
        const int x = minX - 1;
        const auto b1 = hippodromeAt(x, minY);
        const auto b2 = hippodromeAt(x, maxY);
        if(b1 == b2 && b1 && b2) {
            const int id = b1->id();
            topLeftBlocked = true;
            topLeft = id == 0 || id == 4 || id == 5 || id == 7;
        }
    }
    {
        const int y = minY - 1;
        const auto b1 = hippodromeAt(minX, y);
        const auto b2 = hippodromeAt(maxX, y);
        if(b1 == b2 && b1 && b2) {
            const int id = b1->id();
            topRightBlocked = true;
            topRight = id == 1 || id == 2 || id == 6 || id == 7;
        }
    }
    {
        const int x = maxX + 1;
        const auto b1 = hippodromeAt(x, minY);
        const auto b2 = hippodromeAt(x, maxY);
        if(b1 == b2 && b1 && b2) {
            const int id = b1->id();
            bottomRightBlocked = true;
            bottomRight = id == 0 || id == 1 || id == 3 || id == 4;
        }
    }
    {
        const int y = maxY + 1;
        const auto b1 = hippodromeAt(minX, y);
        const auto b2 = hippodromeAt(maxX, y);
        if(b1 == b2 && b1 && b2) {
            const int id = b1->id();
            bottomLeftBlocked = true;
            bottomLeft = id == 2 || id == 3 || id == 5 || id == 6;
        }
    }

    if(topLeft && bottomRight) {
        ids = {0, 4};
    } else if(topLeft && bottomLeft) {
        ids = {1};
    } else if(topRight && bottomLeft) {
        ids = {2, 6};
    } else if(topLeft && topRight) {
        ids = {3};
    } else if(topRight && bottomRight) {
        ids = {5};
    } else if(bottomLeft && bottomRight) {
        ids = {7};
    } else if(topLeft) {
        ids = {0, 1, 3, 4};
    } else if(topRight) {
        ids = {2, 3, 5, 6};
    } else if(bottomRight) {
        ids = {0, 4, 5, 7};
    } else if(bottomLeft) {
        ids = {1, 2, 6, 7};
    }

    if(!topLeft && topLeftBlocked) {
        eVectorHelpers::remove(ids, 0);
        eVectorHelpers::remove(ids, 1);
        eVectorHelpers::remove(ids, 3);
        eVectorHelpers::remove(ids, 4);
    }
    if(!topRight && topRightBlocked) {
        eVectorHelpers::remove(ids, 2);
        eVectorHelpers::remove(ids, 3);
        eVectorHelpers::remove(ids, 5);
        eVectorHelpers::remove(ids, 6);
    }
    if(!bottomRight && bottomRightBlocked) {
        eVectorHelpers::remove(ids, 0);
        eVectorHelpers::remove(ids, 4);
        eVectorHelpers::remove(ids, 5);
        eVectorHelpers::remove(ids, 7);
    }
    if(!bottomLeft && bottomLeftBlocked) {
        eVectorHelpers::remove(ids, 1);
        eVectorHelpers::remove(ids, 2);
        eVectorHelpers::remove(ids, 6);
        eVectorHelpers::remove(ids, 7);
    }
    return ids;
}

bool buildHippodromePiece(eGameBoard& board, const int tx, const int ty, const int id,
                          const eCityId cid, const ePlayerId pid, const bool editor) {
    const bool r = board.build(tx, ty, 4, 4, cid, pid, editor, [&]() {
        const auto b = e::make_shared<eHippodromePiece>(board, cid);
        b->setId(id);
        return b;
    });
    if(r) {
        const auto c = board.boardCityWithId(cid);
        if(c) c->updateHippodromes();
    }
    return r;
}

// The plate's id once it carries a crosswalk (a straight one), or -1.
static int crosswalkId(eGameBoard& board, const int tx, const int ty, eHippodromePiece*& h) {
    h = nullptr;
    const auto b = board.buildingAt(tx, ty);
    if(!b || b->type() != eBuildingType::hippodromePiece) return -1;
    for(int dx = -1; dx <= 1; dx++) {
        for(int dy = -1; dy <= 1; dy++) {
            if(dx == 0 && dy == 0) continue;
            const auto bb = board.buildingAt(tx + dx, ty + dy);
            if(bb && bb->type() == eBuildingType::road) {
                const auto r = static_cast<eRoad*>(bb);
                if(r->aboveHippodrome() == b) return -1;
            }
        }
    }
    h = static_cast<eHippodromePiece*>(b);
    int id = h->id();
    if(id == 0) {
        id = 4;
    } else if(id == 6) {
        id = 2;
    } else if(id != 2 && id != 4) {
        return -1;
    }
    return id;
}

bool crosswalkTiles(eGameBoard& board, const int tx, const int ty, std::vector<eTile*>& tiles) {
    tiles.clear();
    eHippodromePiece* h = nullptr;
    const int id = crosswalkId(board, tx, ty, h);
    if(id == -1) return false;
    const auto& r = h->tileRect();
    if(id == 2) {
        for(int x = r.x; x < r.x + r.w; x++) tiles.push_back(board.tile(x, ty));
    } else {
        for(int y = r.y; y < r.y + r.h; y++) tiles.push_back(board.tile(tx, y));
    }
    return true;
}

bool buildCrosswalk(eGameBoard& board, const int tx, const int ty,
                    const eCityId cid, const ePlayerId pid, const bool editor) {
    eHippodromePiece* h = nullptr;
    const int id = crosswalkId(board, tx, ty, h);
    if(id == -1) return false;
    h->setId(id);
    const auto& r = h->tileRect();
    const auto buildCrosswalk = [&](eTile* const t) {
        const auto b = e::make_shared<eRoad>(board, cid);
        b->setCenterTile(t);
        b->setTileRect({t->x(), t->y(), 1, 1});
        t->setUnderBuilding(b);
        b->addUnderBuilding(t);
        b->setAboveHippodrome(h);
        return b.get();
    };
    if(id == 2) {
        int i = 0;
        for(int x = r.x; x < r.x + r.w; x++) {
            const auto t = board.tile(x, ty);
            const auto r = buildCrosswalk(t);
            if(i == 1 || i == 2) {
                r->setCharacterAltitude(2);
            }
            i++;
        }
    } else {
        int i = 0;
        for(int y = r.y; y < r.y + r.h; y++) {
            const auto t = board.tile(tx, y);
            const auto r = buildCrosswalk(t);
            if(i == 1 || i == 2) {
                r->setCharacterAltitude(2);
            }
            i++;
        }
    }

    if(!editor) {
        const auto diff = board.difficulty(pid);
        const int cost = eDifficultyHelpers::buildingCost(diff, eBuildingType::crosswalk);
        board.incDrachmas(pid, -cost, eFinanceTarget::construction);
    }
    return true;
}
}
