#ifndef ERUINS_H
#define ERUINS_H

#include "ebuilding.h"
#include <memory>

class eRuins : public eBuilding {
public:
    eRuins(eGameBoard& board, const eCityId cid);

    stdsptr<eTexture> getTexture(const eTileSize size) const override;

    void read(eReadStream& src) override;
    void write(eWriteStream& dst) const override;

    void setWasType(const eBuildingType type) { mWasType = type; }
    eBuildingType wasType() const { return mWasType; }
    // Presentation identity only. Native rubble remains one building per tile and
    // the save layout is unchanged; old saves are reconstructed by the adapter.
    using Site = std::shared_ptr<const SDL_Rect>;
    const Site& site() const { return mSite; }
    void setSite(const Site& site) { mSite = site; }
private:
    eBuildingType mWasType = eBuildingType::none;
    Site mSite;
};

#endif // ERUINS_H
