#ifndef ERACINGHORSE_H
#define ERACINGHORSE_H

#include "missiles/emissile.h"

class eRacingHorse : public eMissile {
public:
    eRacingHorse(eGameBoard& board, const int id,
                 const std::vector<ePathPoint>& path = {});
    eRacingHorse(eGameBoard& board);

    std::shared_ptr<eTexture>
    getTexture(const eTileSize size) const override;

    // Which of the four racing teams (the colour of its sprites).
    int team() const { return mId % 4; }

    void read(eReadStream& src) override;
    void write(eWriteStream& dst) const override;
private:
    int mId;
};

#endif // ERACINGHORSE_H
