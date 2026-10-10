#include "eenlistedforces.h"

#include <algorithm>

#include "engine/egameboard.h"
#include "enumbers.h"
#include "fileIO/efileformat.h"

// A trireme's weight in a battle abroad, against a company's soldiers (the original game counted ships with the army).
const int gTriremeStrength = 10;

std::map<eCityId, eEnlistedForces>
eEnlistedForces::splitIntoCities() const {
    std::map<eCityId, eEnlistedForces> forces;
    for(const auto& s : fSoldiers) {
        const auto cid = s->cityId();
        forces[cid].fSoldiers.push_back(s);
    }
    for(const auto& s : fHeroes) {
        forces[s.first].fHeroes.push_back(s);
    }
    for(const auto& w : fTriremes) {
        if(!w) continue;
        forces[w->cityId()].fTriremes.push_back(w);
    }
    if(fAres) {
        const auto cid = fAresCity;
        forces[cid].fAres = true;
        forces[cid].fAresCity = cid;
    }
    if(!forces.empty()) {
        const auto cid = forces.begin()->first;
        forces[cid].fAllies = fAllies;
    }

    return forces;
}

void eEnlistedForces::read(eGameBoard& board,
                           eReadStream& src) {
    auto& wboard = board.world();
    {
        int ns;
        src >> ns;
        for(int i = 0; i < ns; i++) {
            const auto func = [this](const stdsptr<eSoldierBanner>& b) {
                if(b) fSoldiers.push_back(b);
            };
            src.readSoldierBanner(&board, func);
        }
    }
    {
        int nh;
        src >> nh;
        for(int i = 0; i < nh; i++) {
            eCityId cid;
            src >> cid;
            eHeroType h;
            src >> h;
            fHeroes.push_back({cid, h});
        }
    }
    {
        int nc;
        src >> nc;
        for(int i = 0; i < nc; i++) {
            const auto func = [this](const stdsptr<eWorldCity>& c) {
                fAllies.push_back(c);
            };
            src.readCity(&wboard, func);
        }
    }

    src >> fAres;
    src >> fAresCity;

    if(src.formatVersion() >= eFileFormat::zeusGuide) {
        int nt;
        src >> nt;
        for(int i = 0; i < nt; i++) {
            src.readBuilding(&board, [this](eBuilding* const b) {
                if(const auto w = dynamic_cast<eTriremeWharf*>(b)) {
                    fTriremes.push_back(w);
                }
            });
        }
    }
}

void eEnlistedForces::write(eWriteStream& dst) const {
    dst << fSoldiers.size();
    for(const auto& s : fSoldiers) {
        dst.writeSoldierBanner(s.get());
    }

    dst << fHeroes.size();
    for(const auto& h : fHeroes) {
        dst << h.first;
        dst << h.second;
    }

    dst << fAllies.size();
    for(const auto& c : fAllies) {
        dst.writeCity(c.get());
    }

    dst << fAres;
    dst << fAresCity;

    dst << fTriremes.size();
    for(const auto& w : fTriremes) {
        dst.writeBuilding(w.get());
    }
}

void eEnlistedForces::clear() {
    fSoldiers.clear();
    fHeroes.clear();
    fAllies.clear();
    fAres = false;
    fTriremes.clear();
}

void eEnlistedForces::add(const eEnlistedForces& o) {
    for(const auto& s : o.fSoldiers) {
        fSoldiers.push_back(s);
    }
    for(const auto& h : o.fHeroes) {
        fHeroes.push_back(h);
    }
    for(const auto& a : o.fAllies) {
        fAllies.push_back(a);
    }
    for(const auto& w : o.fTriremes) {
        fTriremes.push_back(w);
    }
    if(o.fAres && !fAres) fAresCity = o.fAresCity;
    fAres = fAres || o.fAres;
}

const double gHelpFrac = 0.33;

int eEnlistedForces::strength() const {
    double str = 0;
    for(const auto& s : fSoldiers) {
        double mult = 1.;
        switch(s->type()) {
        case eBannerType::horseman:
            mult = eNumbers::sArmyStrengthHorsemanMult;
            break;
        default:
            break;
        }

        str += mult*s->count();
    }
    for(const auto& c : fAllies) {
        str += gHelpFrac*c->troops();
    }
    str += 8*fHeroes.size();
    if(fAres) str += 8;
    str += gTriremeStrength*fTriremes.size();
    return std::round(str);
}

void eEnlistedForces::kill(const double killFrac) const {
    for(const auto& s : fSoldiers) {
        const auto cid = s->cityId();
        const int oC = s->count();
        int nC = std::round((1 - killFrac)*oC);
        nC = std::clamp(nC, 0, eNumbers::sSoldiersPerBanner);
        auto& board = s->getBoard();
        const auto type = s->type();
        for(int i = nC; i < oC; i++) {
            s->decCount();
            switch(type) {
            case eBannerType::hoplite:
                board.hopliteKilled(cid);
                break;
            case eBannerType::horseman:
                board.horsemanKilled(cid);
                break;
            default:
                break;
            }
        }
    }

    for(const auto& c : fAllies) {
        const int t = c->troops();
        c->setTroops((1 - gHelpFrac*killFrac)*t);
    }
    // The same share of the ships is lost; their wharves build new ones.
    const int lost = std::round(killFrac*fTriremes.size());
    for(int i = 0; i < lost && i < int(fTriremes.size()); i++) {
        const auto& w = fTriremes[fTriremes.size() - 1 - i];
        if(w) w->triremeLost();
    }
}

int eEnlistedForces::count() const {
    int result = 0;
    for(const auto& b : fSoldiers) {
        result += b->count();
    }
    for(const auto& f : fAllies) {
        std::vector<eSoldierBanner*> solds;
        int infantry;
        int cavalry;
        int archers;
        f->troopsByType(infantry, cavalry, archers);
        result += infantry;
        result += cavalry;
        result += archers;
    }
    return result;
}
