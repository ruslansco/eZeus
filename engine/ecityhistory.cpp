#include "ecityhistory.h"

#include "fileIO/ereadstream.h"
#include "fileIO/ewritestream.h"

void eCityHistory::add(const eHistorySample& s) {
    // one sample a month: a reload or a repeated call replaces it
    if(!mSamples.empty() && mSamples.back().monthIndex() == s.monthIndex()) {
        mSamples.back() = s;
        return;
    }
    mSamples.push_back(s);
    if(static_cast<int>(mSamples.size()) > sMaxSamples) {
        mSamples.erase(mSamples.begin());
    }
}

int eCityHistory::lastWarning(const int key) const {
    const auto it = mLastWarning.find(key);
    return it == mLastWarning.end() ? -1 : it->second;
}

void eCityHistory::setLastWarning(const int key, const int month) {
    mLastWarning[key] = month;
}

int eCityHistory::lastWarningMonths(const int key) const {
    const auto it = mLastWarningMonths.find(key);
    return it == mLastWarningMonths.end() ? 1000 : it->second;
}

void eCityHistory::setLastWarningMonths(const int key, const int months) {
    mLastWarningMonths[key] = months;
}

void eCityHistory::read(eReadStream& src) {
    int n;
    src >> n;
    mSamples.clear();
    mSamples.reserve(n);
    for(int i = 0; i < n; i++) {
        auto& s = mSamples.emplace_back();
        src >> s.fYear;
        src >> s.fMonth;
        src >> s.fPopulation;
        src >> s.fDrachmas;
        src >> s.fFood;
        src >> s.fFleece;
        src >> s.fOil;
        src >> s.fWine;
        src >> s.fArms;
        src >> s.fHorses;
        src >> s.fPopularity;
        src >> s.fUnrest;
        src >> s.fHealth;
    }
    for(auto* m : {&mLastWarning, &mLastWarningMonths}) {
        m->clear();
        int nw;
        src >> nw;
        for(int i = 0; i < nw; i++) {
            int key;
            int value;
            src >> key;
            src >> value;
            (*m)[key] = value;
        }
    }
}

void eCityHistory::write(eWriteStream& dst) const {
    dst << static_cast<int>(mSamples.size());
    for(const auto& s : mSamples) {
        dst << s.fYear;
        dst << s.fMonth;
        dst << s.fPopulation;
        dst << s.fDrachmas;
        dst << s.fFood;
        dst << s.fFleece;
        dst << s.fOil;
        dst << s.fWine;
        dst << s.fArms;
        dst << s.fHorses;
        dst << s.fPopularity;
        dst << s.fUnrest;
        dst << s.fHealth;
    }
    for(const auto* m : {&mLastWarning, &mLastWarningMonths}) {
        dst << static_cast<int>(m->size());
        for(const auto& w : *m) {
            dst << w.first;
            dst << w.second;
        }
    }
}

void eTradeLedger::addExport(const int cid, const eResourceType type,
                             const int count, const int drachmas) {
    auto& y = mThisYear[cid];
    y.fExported[type] += count;
    y.fIncome += drachmas;
}

void eTradeLedger::addImport(const int cid, const eResourceType type,
                             const int count, const int drachmas) {
    auto& y = mThisYear[cid];
    y.fImported[type] += count;
    y.fCost += drachmas;
}

void eTradeLedger::nextYear() {
    mLastYear = mThisYear;
    mThisYear.clear();
}

namespace {
void readYears(eReadStream& src, std::map<int, eTradeYear>& years) {
    years.clear();
    int n;
    src >> n;
    for(int i = 0; i < n; i++) {
        int cid;
        src >> cid;
        auto& y = years[cid];
        src >> y.fIncome;
        src >> y.fCost;
        for(auto* m : {&y.fExported, &y.fImported}) {
            int nr;
            src >> nr;
            for(int j = 0; j < nr; j++) {
                eResourceType type;
                int count;
                src >> type;
                src >> count;
                (*m)[type] = count;
            }
        }
    }
}

void writeYears(eWriteStream& dst, const std::map<int, eTradeYear>& years) {
    dst << static_cast<int>(years.size());
    for(const auto& y : years) {
        dst << y.first;
        dst << y.second.fIncome;
        dst << y.second.fCost;
        for(const auto* m : {&y.second.fExported, &y.second.fImported}) {
            dst << static_cast<int>(m->size());
            for(const auto& r : *m) {
                dst << r.first;
                dst << r.second;
            }
        }
    }
}
}

void eTradeLedger::read(eReadStream& src) {
    readYears(src, mThisYear);
    readYears(src, mLastYear);
}

void eTradeLedger::write(eWriteStream& dst) const {
    writeYears(dst, mThisYear);
    writeYears(dst, mLastYear);
}
