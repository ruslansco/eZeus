#ifndef ETERRAINEDIT_H
#define ETERRAINEDIT_H

#include <functional>
#include <vector>

#include "engine/etile.h"

class eGameBoard;

// The map editor's tools (the SDL editor's terrain panel, eTerrainEditMenu, and the Godot editor's brushes).
enum class eTerrainEditMode {
    dry = static_cast<int>(eTerrain::dry),
    beach = static_cast<int>(eTerrain::beach),
    water = static_cast<int>(eTerrain::water),
    marsh = static_cast<int>(eTerrain::marsh),
    fertile = static_cast<int>(eTerrain::fertile),
    forest = static_cast<int>(eTerrain::forest),
    choppedForest = static_cast<int>(eTerrain::choppedForest),

    flatStones = static_cast<int>(eTerrain::flatStones),
    bronze = static_cast<int>(eTerrain::copper),
    silver = static_cast<int>(eTerrain::silver),
    orichalc = static_cast<int>(eTerrain::orichalc),
    tallStones = static_cast<int>(eTerrain::tallStones),
    marble = static_cast<int>(eTerrain::marble),

    none,
    scrub,
    scrubArea,
    removeScrub,
    softenScrub,

    rainforest,
    normalForest,

    raise,
    lower,
    raiseHigh,
    lowerHigh,
    levelOut,
    resetElev,
    halfSlope,
    makeWalkable,

    boar,
    deer,
    fish,
    urchin,

    fire,
    ruins,

    entryPoint,
    exitPoint,
    riverEntryPoint,
    riverExitPoint,
    landInvasion,
    seaInvasion,
    disembarkPoint,
    monsterPoint,

    quake,
    lava,
    tidalWave,
    landSlide,
    disasterPoint,
    landSlidePoint,

    cityTerritory,
    assignAllCityTerritory
};

// How a stroke picks its tiles: the rectangle dragged out (apply), a diamond or a square of the brush's size under the pointer.
enum class eBrushType {
    apply,
    brush,
    square
};

namespace eTerrainEdit {
    using eApply = std::function<void(eTile*)>;

    // What `mode` does to one tile of a stroke (nullptr for none). `modeId` is the tool's number (the point's id, the
    // city of a territory); `stroke` the stroke's tiles (scrub area measures each tile's distance to its edge); `pressed`
    // the tile the stroke began on (level out takes its height); `city` the district ruins are built for.
    eApply apply(eGameBoard& board, eTerrainEditMode mode, int modeId,
                 const std::vector<eTile*>& stroke, eTile* pressed, eCityId city);

    // The brush's tiles around (cx, cy): a diamond of `size` (1 to 5) or a square of `size` tiles on a side.
    void brushTiles(eGameBoard* board, int size, int cx, int cy, std::vector<eTile*>& result);
    void squareTiles(eGameBoard* board, int size, int cx, int cy, std::vector<eTile*>& result);

    // After a stroke: the board's territory borders, marble tiles and terrain. True when heights changed (a view then
    // recomputes its height range).
    bool finish(eGameBoard& board, eTerrainEditMode mode);

    // Applies one stroke of `mode` to `stroke` and finishes it; the number of tiles it went over.
    int stroke(eGameBoard& board, eTerrainEditMode mode, int modeId,
               const std::vector<eTile*>& stroke, eTile* pressed, eCityId city, bool* heights = nullptr);
}

#endif // ETERRAINEDIT_H
