#ifndef ESANCTUARY_H
#define ESANCTUARY_H

#include "../eemployingbuilding.h"
#include "../emonument.h"

#include "esanctuaryblueprint.h"
#include "characters/gods/egod.h"
#include "engine/edate.h"

class eBuildingTextures;
class eGameEvent;

enum class eHelpDenialReason {
    tooSoon,
    noTarget,
    error
};

class eSanctuary : public eMonument {
public:
    eSanctuary(eGameBoard& board,
               const eBuildingType type,
               const int sw, const int sh,
               const int maxEmployees,
               const eCityId cid);
    ~eSanctuary();

    void erase() override;

    void timeChanged(const int by) override;
    void nextMonth() override;

    void buildingProgressed() override;

    void read(eReadStream& src) override;
    void write(eWriteStream& dst) const override;

    std::vector<eTile*> warriorTiles() const;
    void addWarriorTile(eTile* const t);
    void addSpecialTile(eTile* const t);

    bool askForAttack(const eCityId cid, eHelpDenialReason& reason);
    bool askForHelp(eHelpDenialReason& reason);

    eGod* god() const { return mGod; }

    eGodType godType() const;

    eGod* spawnGod();
    void spawnPatrolingGod();

    void godComeback();
    bool godAbroad() const { return mGodAbroad; }

    double helpTimeFraction() const;
    double helpAttackTimeFraction() const;

    // The original game's oracle (Zeus' Stronghold and the Oracle of Apollo): a consultation foretells the soonest event that
    // will reach the city within two years (an invasion, an angry god, a monster, a request, a gift, a quest or a disaster).
    // The oracle answers again after the god's help period.
    struct eOracleAnswer {
        bool fGranted = false;
        const eGameEvent* fEvent = nullptr; // nullptr: nothing is coming
        int fDays = 0;
    };
    bool hasOracle() const;
    eOracleAnswer consultOracle();
    double oracleTimeFraction() const;

    static stdsptr<eSanctuary> sCreate(
            const eBuildingType type,
            const int sw, const int sh,
            eGameBoard& board, const eCityId cid);

    static void sLoadMonumentTextures(const eGodType type);

    void setSpawnWait(const int w);

    bool sacrificing() const;
private:
    stdptr<eGod> mGod;
    bool mGodAbroad = false;
    int mSpawnWait = 0;

    bool mAskedForHelp = false;
    int mCheckHelpNeeded = 0;
    int mHelpTimer = 10000000;
    int mOracleTimer = 10000000;

    std::vector<eTile*> mWarriorTiles;
    std::vector<eTile*> mSpecialTiles;
};

#endif // ESANCTUARY_H
