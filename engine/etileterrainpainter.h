#ifndef ETILETERRAINPAINTER_H
#define ETILETERRAINPAINTER_H

class eTexture;
class eTextureCollection;

#include "pointers/estdselfref.h"

struct eTileTerrainPainter {
    stdsptr<eTexture> fTex = nullptr;
    const eTextureCollection* fColl = nullptr;
    int fDrawDim = 1;
    // Remastered base terrain (eTerrainHD): 0 - sprite, 1 - sand/grass plate,
    // 2 - open water plate, 3 - shore, 4 - forest (fHDSheet: 0 zeusLand1,
    // 1 zeusTrees, 2 poseidonTrees), 5 - husbandry (fertile) meadow, 6 - rock outcrop (HD ground + HD rock sprite), 7 - elevation cliff/ramp
    // (fHDSheet: 0 zeusElevationTiles, 1 zeusElevationTiles2), 8 - paved road (fHDSheet:
    // 0 plain, 1 pretty / avenue), 9 - avenue tile (paving + HD decoration).
    int fHD = 0;
    int fHDSheet = 0;

    stdsptr<eTexture> getTexture(const int frame) const;
};

#endif // ETILETERRAINPAINTER_H
