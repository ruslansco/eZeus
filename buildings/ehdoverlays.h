#ifndef EHDOVERLAYS_H
#define EHDOVERLAYS_H

#include <algorithm>
#include <algorithm>
#include <string>
#include <vector>

#include "eoverlay.h"
#include "textures/egametextures.h"

// Adds the remastered state overlay `key` (e.g. "stock3", "slot2_wheat") of a building whose
// HD atlas is `frames` to `os`, placed exactly on the building sprite for the board direction
// `dir` at zoom `sizeId`. Does nothing if the overlay is not installed.
inline bool eAddHDOverlay(std::vector<eOverlay>& os,
                          const eBuildingTextures::eHDOverlaySet& set,
                          const eBuildingTextures::eHDFrames& frames,
                          const std::string& key, const int dir, const int sizeId) {
    const auto& cell = frames[dir][0];
    if(!cell) return false;
    const auto& trr = eGameTextures::terrain()[sizeId];
    eOverlay o;
    if(!eBuildingTextures::sHDOverlay(set, key, dir, cell->height(), trr.fTileW, trr.fTileH, o)) {
        return false;
    }
    os.push_back(o);
    return true;
}

// Stock pile overlay: "<prefix><k>" for the largest rendered k <= n (k >= 1). Returns true if drawn.
inline bool eAddHDStock(std::vector<eOverlay>& os,
                        const eBuildingTextures::eHDOverlaySet& set,
                        const eBuildingTextures::eHDFrames& frames,
                        const std::string& prefix, const int n,
                        const int dir, const int sizeId) {
    for(int k = std::min(n, 16); k >= 1; k--) {
        if(eAddHDOverlay(os, set, frames, prefix + std::to_string(k), dir, sizeId)) return true;
    }
    return false;
}

#endif // EHDOVERLAYS_H
