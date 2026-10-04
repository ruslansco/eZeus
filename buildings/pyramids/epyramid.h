#ifndef EPYRAMID_H
#define EPYRAMID_H

#include "../emonument.h"

#include "engine/eorientation.h"

enum class eGodType;

struct ePyramidSettings {
    eBuildingType fType;
    std::vector<bool> fLevels;
};

// One piece of a pyramid's layout as `initialize` places it: the offset of its first tile from the footprint's, its elevation
// (the level it stands on) and, for a piece of more than one tile, its size (it extends toward smaller x and y from that tile).
struct ePyramidPlan {
    enum class eKind {
        wall, top, tile, statue, monument,
        altar, temple, observatory, museum
    };
    eKind fKind = eKind::top;
    eOrientation fOrientation = eOrientation::top;
    int fElevation = 0;
    int fX = 0;
    int fY = 0;
    int fW = 1;
    int fH = 1;
    int fSpecial = 0;
    int fSpecial2 = 0;
};

class ePyramid : public eMonument {
public:
    ePyramid(eGameBoard& board,
             const eBuildingType type,
             const int sw, const int sh,
             const eCityId cid);

    void erase() override;

    void initialize(const std::vector<bool>& levels);

    void buildingProgressed() override;

    void read(eReadStream& src) override;
    void write(eWriteStream& dst) const override;

    eSanctCost swapMarbleIfDark(const int e, eSanctCost cost) const;

    bool darkLevel(const int n) const { return mDark[n]; }

    static void sDimensions(const eBuildingType type,
                            int& sw, int& sh);
    static std::vector<ePyramidPlan> sPlan(const eBuildingType type);
    static int sLevels(const eBuildingType type);
    static eGodType sGod(const eBuildingType type);
    static eBuildingType sSwitchGod(const eBuildingType srcType,
                                    const eGodType god);
    static bool sIsToGod(const eBuildingType type);
private:
    stdsptr<ePyramid> mSelf;

    std::vector<bool> mDark;
};

#endif // EPYRAMID_H
