#include "eterrainedit.h"

#include "eiteratesquare.h"
#include "etilehelper.h"
#include "engine/egameboard.h"
#include "buildings/eruins.h"
#include "evectorhelpers.h"
#include "spawners/eboarspawner.h"
#include "spawners/edeerspawner.h"
#include "spawners/eentrypoint.h"
#include "spawners/eexitpoint.h"
#include "spawners/emonsterpoint.h"
#include "spawners/elandinvasionpoint.h"
#include "spawners/eseainvasionpoint.h"
#include "spawners/edisembarkpoint.h"
#include "spawners/edisasterpoint.h"
#include "spawners/elandslidepoint.h"

// Moved from the SDL view (eGameWidget::editFunc), so the Godot editor's brushes do exactly what the SDL editor's do.
eTerrainEdit::eApply eTerrainEdit::apply(eGameBoard& board, const eTerrainEditMode mode, const int modeId,
                                         const std::vector<eTile*>& stroke, eTile* const pressed, const eCityId city) {
    if(mode == eTerrainEditMode::none) {
        return nullptr;
    } else if(mode == eTerrainEditMode::scrub) {
        return [](eTile* const tile) {
            tile->incScrub(0.1);
        };
    } else if(mode == eTerrainEditMode::scrubArea) {
        return [stroke](eTile* const tile) {
            int dist = 100;
            for(int k = 1; k < 100; k++) {
                eIterateSquare::iterateDistance(k, [&dist, k, &stroke, tile](const int dx, const int dy) {
                    const auto t = tile->tileRel<eTile>(dx, dy);
                    const bool r = eVectorHelpers::contains(stroke, t);
                    if(!r) {
                        dist = k;
                        return true;
                    }
                    return false;
                });
                if(dist != 100) break;
            }
            tile->incScrub(dist*0.05);
        };
    } else if(mode == eTerrainEditMode::removeScrub) {
        return [](eTile* const tile) {
            tile->incScrub(-0.1);
        };
    }  else if(mode == eTerrainEditMode::softenScrub) {
        return [](eTile* const tile) {
            const auto ns = tile->neighbours(nullptr);
            double ss = tile->scrub();
            for(const auto& t : ns) {
                const auto tt = static_cast<eTile*>(t.second);
                ss += tt->scrub();
            }
            ss = ss/(1 + ns.size());
            tile->setScrub(ss);
        };
    } else if(mode == eTerrainEditMode::rainforest) {
        return [](eTile* const tile) {
            tile->setRainforest(true);
        };
    } else if(mode == eTerrainEditMode::normalForest) {
        return [](eTile* const tile) {
            tile->setRainforest(false);
        };
    } else if(mode == eTerrainEditMode::raise) {
        return [](eTile* const tile) {
            tile->setAltitude(tile->altitude() + 1);
        };
    } else if(mode == eTerrainEditMode::lower) {
        return [](eTile* const tile) {
            tile->setAltitude(tile->altitude() - 1);
        };
    } else if(mode == eTerrainEditMode::raiseHigh) {
        return [](eTile* const tile) {
            tile->setAltitude(tile->altitude() + 2);
        };
    } else if(mode == eTerrainEditMode::lowerHigh) {
        return [](eTile* const tile) {
            tile->setAltitude(tile->altitude() - 2);
        };
    } else if(mode == eTerrainEditMode::quake) {
        return [](eTile* const tile) {
            tile->setTerrain(eTerrain::quake);
        };
    } else if(mode == eTerrainEditMode::lava) {
        return [](eTile* const tile) {
            tile->setLavaZone(!tile->lavaZone());
        };
    } else if(mode == eTerrainEditMode::tidalWave) {
        return [](eTile* const tile) {
            tile->setTidalWaveZone(!tile->tidalWaveZone());
        };
    } else if(mode == eTerrainEditMode::landSlide) {
        return [](eTile* const tile) {
            tile->setLandSlideZone(!tile->landSlideZone());
        };
    } else if(mode == eTerrainEditMode::levelOut) {
        if(const auto t = pressed) {
            const int a = t->altitude();
            return [a](eTile* const tile) {
                tile->setAltitude(a);
            };
        }
    } else if(mode == eTerrainEditMode::resetElev) {
        return [](eTile* const tile) {
            tile->setAltitude(0);
        };
    } else if(mode == eTerrainEditMode::makeWalkable) {
        return [](eTile* const tile) {
            tile->setWalkableElev(!tile->walkableElev());
        };
    } else if(mode == eTerrainEditMode::halfSlope) {
        return [](eTile* const tile) {
            const int a = tile->altitude();
            const auto ns = tile->diagonalNeighbours(nullptr);
            for(const auto& n : ns) {
                const auto ntile = static_cast<eTile*>(n.second);
                const int na = ntile->altitude();
                if(na > a && tile->doubleAltitude() % 2 == 0) {
                    tile->setDoubleAltitude(2*na - 1);
                } else {
                    tile->setDoubleAltitude(2*a);
                }
            }
        };
    } else if(mode == eTerrainEditMode::boar) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eBoarSpawner>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::fish) {
        return [](eTile* const tile) {
            tile->setHasFish(!tile->hasFish());
        };
    } else if(mode == eTerrainEditMode::urchin) {
        return [](eTile* const tile) {
            tile->setHasUrchin(!tile->hasUrchin());
        };
    } else if(mode == eTerrainEditMode::deer) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eDeerSpawner>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::fire) {
        return [](eTile* const tile) {
            tile->setOnFire(true);
        };
    } else if(mode == eTerrainEditMode::ruins) {
        return [&board, city](eTile* const tile) {
            const auto pid = board.personPlayer();
            board.build(tile->x(), tile->y(), 1, 1, city, pid, false,
                  [&board, city]() { return e::make_shared<eRuins>(board, city); });
        };
    } else if(mode == eTerrainEditMode::entryPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eEntryPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::exitPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eExitPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::riverEntryPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eRiverEntryPoint>(
                modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::riverExitPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eRiverExitPoint>(
                modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::landInvasion) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eLandInvasionPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::seaInvasion) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eSeaInvasionPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::disembarkPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eDisembarkPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::monsterPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eMonsterPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::disasterPoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eDisasterPoint>(
                               modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::landSlidePoint) {
        return [&board, modeId](eTile* const tile) {
            const auto b = std::make_shared<eLandSlidePoint>(
                modeId, tile, board);
            tile->addBanner(b);
        };
    } else if(mode == eTerrainEditMode::cityTerritory) {
        return [modeId](eTile* const tile) {
            const auto cid = static_cast<eCityId>(modeId);
            tile->setCityId(cid);
        };
    } else {
        return [mode](eTile* const tile) {
            const auto terr = static_cast<eTerrain>(mode);
            tile->setTerrain(terr);
        };
    }
    return nullptr;
    return nullptr;
}

void eTerrainEdit::brushTiles(eGameBoard* const board, const int bSize,
                              const int cx, const int cy,
                              std::vector<eTile*>& result) {
    int cdx0;
    int cdy0;
    eTileHelper::tileIdToDTileId(cx, cy, cdx0, cdy0);
    const int x0 = cx - bSize + 1;
    const int y0 = cy;
    int dx0;
    int dy0;
    eTileHelper::tileIdToDTileId(x0, y0, dx0, dy0);
    for(int ddy = 0; ddy < 2*bSize - 1; ddy++) {
        const int dy = dy0 + ddy;
        const int w = (ddy % 2) ? bSize - 1 : bSize;
        int dx = dx0;
        if(ddy % 2) {
            if(cdy0 % 2 == bSize % 2) {
                dx += 1;
            }
        }
        for(int ddx = 0; ddx < w; ddx++) {
            const auto t = board->dtile(dx + ddx, dy);
            if(!t) continue;
            result.push_back(t);
        }
    }
}

void eTerrainEdit::squareTiles(eGameBoard* const board, const int bSize,
                               const int cx, const int cy,
                               std::vector<eTile*>& result) {
    const int x0 = cx - bSize/2;
    const int y0 = cy - bSize/2;
    for(int dx = 0; dx < bSize; dx++) {
        for(int dy = 0; dy < bSize; dy++) {
            const auto t = board->tile(x0 + dx, y0 + dy);
            if(!t) continue;
            result.push_back(t);
        }
    }
}

bool eTerrainEdit::finish(eGameBoard& board, const eTerrainEditMode mode) {
    bool heights = false;
    if(mode == eTerrainEditMode::raise ||
       mode == eTerrainEditMode::lower ||
       mode == eTerrainEditMode::raiseHigh ||
       mode == eTerrainEditMode::lowerHigh ||
       mode == eTerrainEditMode::levelOut ||
       mode == eTerrainEditMode::resetElev) {
        heights = true;
    } else if(mode == eTerrainEditMode::cityTerritory) {
        board.updateTerritoryBorders();
    }
    board.updateMarbleTiles();
    board.scheduleTerrainUpdate();
    return heights;
}

int eTerrainEdit::stroke(eGameBoard& board, const eTerrainEditMode mode, const int modeId,
                         const std::vector<eTile*>& tiles, eTile* const pressed, const eCityId city, bool* const heights) {
    const auto change = apply(board, mode, modeId, tiles, pressed, city);
    if(!change) return 0;
    for(const auto tile : tiles) change(tile);
    const bool h = finish(board, mode);
    if(heights) *heights = h;
    return int(tiles.size());
}
