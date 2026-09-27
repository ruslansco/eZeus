#ifndef ECITYHISTORY_H
#define ECITYHISTORY_H

#include <map>
#include <vector>

#include "eresourcetype.h"

class eReadStream;
class eWriteStream;

// One month of a city, taken as the month begins (eBoardCity::nextMonth).
struct eHistorySample {
    int fYear = 0;
    int fMonth = 0;        // 0-11
    int fPopulation = 0;
    int fDrachmas = 0;
    int fFood = 0;         // in granaries and storehouses
    int fFleece = 0;
    int fOil = 0;
    int fWine = 0;
    int fArms = 0;
    int fHorses = 0;
    int fPopularity = 0;   // 0-100
    int fUnrest = 0;       // percent
    int fHealth = 0;       // 0-100

    int monthIndex() const { return fYear*12 + fMonth; }
};

// What the city history chart shows and what the early warnings watch.
class eCityHistory {
public:
    static const int sMaxSamples = 1200; // a hundred years

    void add(const eHistorySample& s);
    const std::vector<eHistorySample>& samples() const { return mSamples; }
    bool empty() const { return mSamples.empty(); }

    // The month a warning about key (a resource, or drachmas) was last
    // given, as a monthIndex; -1 if never.
    int lastWarning(const int key) const;
    void setLastWarning(const int key, const int month);
    // What it said: months left then.
    int lastWarningMonths(const int key) const;
    void setLastWarningMonths(const int key, const int months);

    void read(eReadStream& src);
    void write(eWriteStream& dst) const;
private:
    std::vector<eHistorySample> mSamples;
    std::map<int, int> mLastWarning;
    std::map<int, int> mLastWarningMonths;
};

// Trade with each partner city, this year and last (eTradePost::buy/sell).
struct eTradeYear {
    int fIncome = 0;
    int fCost = 0;
    std::map<eResourceType, int> fExported;
    std::map<eResourceType, int> fImported;
};

class eTradeLedger {
public:
    void addExport(const int cid, const eResourceType type,
                   const int count, const int drachmas);
    void addImport(const int cid, const eResourceType type,
                   const int count, const int drachmas);
    void nextYear();

    const std::map<int, eTradeYear>& thisYear() const { return mThisYear; }
    const std::map<int, eTradeYear>& lastYear() const { return mLastYear; }

    void read(eReadStream& src);
    void write(eWriteStream& dst) const;
private:
    std::map<int, eTradeYear> mThisYear;
    std::map<int, eTradeYear> mLastYear;
};

#endif // ECITYHISTORY_H
