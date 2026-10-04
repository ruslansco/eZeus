#ifndef EBUILDPLACEMENT_H
#define EBUILDPLACEMENT_H

#include <vector>

#include "engine/ecityid.h"
#include "engine/eorientation.h"
#include "characters/gods/egod.h"

class eGameBoard;
class eTile;
enum class eTerrain;
enum class eBuildingType;

// The buildings of the SDL build menu that are not one rectangle: the palace with its paved ring, the stadium's two
// halves, the horse ranch and its paddock, a god's monument and its tiles, the shore buildings, bridges, columns and
// avenues laid along a path, roadblocks, the hippodrome's plates and its crosswalks. They were part of the SDL game
// widget; the widget and the embedded simulation service share them so the two views cannot disagree. Coordinates are
// the SDL view's: (tx, ty) is the tile under the pointer, and `rotate` / `rotateId` the view's turn of the building.
namespace eBuildPlacement {
struct ePalaceTilePlan {
    int fX;
    int fY;
    bool fOther; // the corner tiles carry a lamp
};

// The stadium: 10x5 tiles, or 5x10 when turned; its first tile.
void stadiumRect(const int tx, const int ty, const bool rotate,
                 int& minX, int& minY, int& w, int& h);
bool canBuildStadium(eGameBoard& board, const int tx, const int ty, const bool rotate,
                     const eCityId cid, const ePlayerId pid, const bool editor);
bool buildStadium(eGameBoard& board, const int tx, const int ty, const bool rotate,
                  const eCityId cid, const ePlayerId pid, const bool editor);

// The palace: 8x4 tiles (4x8 turned) and a ring of paving tiles around three of its sides.
void palaceRect(const int tx, const int ty, const bool rotate,
                int& minX, int& minY, int& w, int& h);
std::vector<ePalaceTilePlan> palaceTiles(const int tx, const int ty, const bool rotate);
bool canBuildPalace(eGameBoard& board, const int tx, const int ty, const bool rotate,
                    const eCityId cid, const ePlayerId pid, const bool editor);
bool buildPalace(eGameBoard& board, const int tx, const int ty, const bool rotate,
                 const eCityId cid, const ePlayerId pid, const bool editor);

// The horse ranch (3x3) and its paddock (4x4) on the side `rotateId` names (0 bottom right, 1 top right, 2 top left,
// 3 bottom left).
void horseRanchRects(const int tx, const int ty, const int rotateId,
                     int& ranchX, int& ranchY, int& paddockX, int& paddockY);
bool canBuildHorseRanch(eGameBoard& board, const int tx, const int ty, const int rotateId,
                        const eCityId cid, const ePlayerId pid, const bool editor);
bool buildHorseRanch(eGameBoard& board, const int tx, const int ty, const int rotateId,
                     const eCityId cid, const ePlayerId pid, const bool editor);

// A god's monument: a 2x2 monument at (tx, ty - 1) and paving on the free tiles of the 4x4 around it. The caller records
// it as built (eGameBoard::built) when this returns true.
bool canBuildGodMonument(eGameBoard& board, const int tx, const int ty,
                         const eCityId cid, const ePlayerId pid, const bool editor);
bool buildGodMonument(eGameBoard& board, const int tx, const int ty, const eGodType god,
                      const eCityId cid, const ePlayerId pid, const bool editor);

// Shore buildings. A fishery or urchin quay takes the 2x2 shore spot of eShorePlacement::canBuildFishery; a trireme
// wharf takes the 3x3 around (tx, ty) and needs water that leads to the sea.
bool canBuildTriremeWharf(eGameBoard& board, const int tx, const int ty, eDiagonalOrientation& o);
bool triremeWharfSeaAccess(eGameBoard& board, const int tx, const int ty, const eCityId cid);
// `type` is eBuildingType::fishery, urchinQuay or triremeWharf; the caller has checked the spot. The cost is charged.
void placeShoreBuilding(eGameBoard& board, const eBuildingType type, const int tx, const int ty,
                        const eDiagonalOrientation o, const eCityId cid, const ePlayerId pid, const bool editor);

// A bridge from the shore tile `t` straight across water (or a quake's chasm); the tiles it would take.
bool bridgeTiles(eTile* const t, const eTerrain terr, std::vector<eTile*>& tiles, bool& rotated);
// Lays the bridge's road tiles and charges them.
void buildBridge(eGameBoard& board, const std::vector<eTile*>& tiles,
                 const eCityId cid, const ePlayerId pid, const bool editor);

// The SDL drags: a path from (fromX, fromY) (the tile under the pointer) to (toX, toY) (where the drag began), and the
// tiles it passes in the order the SDL view builds them. A road path may cross roads and avenues; a column path columns.
bool roadPath(eGameBoard& board, const int fromX, const int fromY, const int toX, const int toY,
              const bool editor, std::vector<eOrientation>& path);
bool columnPath(eGameBoard& board, const int fromX, const int fromY, const int toX, const int toY,
                std::vector<eOrientation>& path);
std::vector<eTile*> pathTiles(eTile* const start, const std::vector<eOrientation>& path, const bool found);

// Avenues and boulevards: the median tiles along the path and, beside each, the road the SDL view lays (an avenue one
// flank, a boulevard both).
struct eAvenuePlan {
    std::vector<eTile*> fMedians;
    bool fAxis1 = true; // the path runs top left - bottom right
};
eAvenuePlan avenuePlan(eTile* const start, const std::vector<eOrientation>& path, const bool found);
// The flank roads beside a median tile, as the board stands now (an avenue picks the side that has road already).
std::vector<eTile*> avenueFlanks(const eAvenuePlan& plan, eTile* const median, const bool boulevard);
// Builds the plan as the SDL view does (median, then its flanks, tile by tile, while the treasury allows). Returns
// whether anything was built.
bool buildAvenue(eGameBoard& board, const eAvenuePlan& plan, const bool boulevard,
                 const eCityId cid, const ePlayerId pid, const bool editor);
// Whether the median of an avenue (or boulevard) can go on `t`, and whether a flank road can.
bool canBuildAvenueMedian(eGameBoard& board, eTile* const t, const bool boulevard,
                          const eCityId cid, const ePlayerId pid, const bool editor);
bool canBuildAvenueFlank(eGameBoard& board, eTile* const t,
                         const eCityId cid, const ePlayerId pid, const bool editor);

// A roadblock on an ordinary street (not a bridge). Returns whether it was set.
bool canPlaceRoadblock(eTile* const t);
bool placeRoadblock(eTile* const t);

// The hippodrome plates (ids 0-7) that fit the 4x4 at (tx, ty) beside the city's existing plates.
std::vector<int> hippodromePieceIds(eGameBoard& board, const eCityId cid, const int tx, const int ty);
bool buildHippodromePiece(eGameBoard& board, const int tx, const int ty, const int id,
                          const eCityId cid, const ePlayerId pid, const bool editor);
// A crosswalk over the straight hippodrome plate at (tx, ty); the tiles it would take.
bool crosswalkTiles(eGameBoard& board, const int tx, const int ty, std::vector<eTile*>& tiles);
bool buildCrosswalk(eGameBoard& board, const int tx, const int ty,
                    const eCityId cid, const ePlayerId pid, const bool editor);
}

#endif // EBUILDPLACEMENT_H
