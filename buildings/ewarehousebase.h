#ifndef EWAREHOUSEBASE_H
#define EWAREHOUSEBASE_H

#include "estoragebuilding.h"

class eWarehouseBase : public eStorageBuilding {
public:
    using eStorageBuilding::eStorageBuilding;

    using eXY = std::vector<std::pair<double, double>>;
    // hd: the remastered building is shown; bays then draw the HD goods library
    // (Textures/Remastered/storage_goods) and empty bays draw nothing.
    void getSpaceOverlays(const eTileSize size,
                          std::vector<eOverlay>& os,
                          const eXY& xy,
                          const bool hd = false) const;
};

#endif // EWAREHOUSEBASE_H
