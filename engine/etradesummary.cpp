#include "etradesummary.h"

#include "elanguage.h"
#include "engine/egameboard.h"
#include "engine/eboardcity.h"
#include "engine/eworldcity.h"
#include "engine/eworldboard.h"
#include "buildings/etradepost.h"

#include <algorithm>
#include <cstdlib>
#include <map>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

std::string number(const int v) {
    const bool ru = eLanguage::language() == "ru";
    std::string d = std::to_string(std::abs(v));
    std::string out;
    int n = 0;
    for(int i = static_cast<int>(d.size()) - 1; i >= 0; i--) {
        out.insert(out.begin(), d[i]);
        if(++n % 3 == 0 && i > 0) out.insert(0, ru ? " " : ",");
    }
    return (v < 0 ? "-" : "") + out;
}

std::string signedNumber(const int v) {
    return (v > 0 ? "+" : "") + number(v);
}


// goods that can sit in storage, in the order the game lists them
const eResourceType kGoods[] = {
    eResourceType::wheat, eResourceType::carrots, eResourceType::onions,
    eResourceType::fish, eResourceType::urchin, eResourceType::meat,
    eResourceType::cheese, eResourceType::oranges, eResourceType::grapes,
    eResourceType::olives, eResourceType::wine, eResourceType::oliveOil,
    eResourceType::fleece, eResourceType::wood, eResourceType::bronze,
    eResourceType::marble, eResourceType::blackMarble, eResourceType::orichalc,
    eResourceType::armor, eResourceType::sculpture, eResourceType::horse};
}

std::vector<eTradeSummaryLine> eTradeSummary::lines(eGameBoard& board, const eCityId cid) {
    std::vector<eTradeSummaryLine> out;
    const auto add = [&out](const std::string& left, const std::string& right = "",
                            const int font = 0, const int indent = 0) -> eTradeSummaryLine& {
        auto& l = out.emplace_back();
        l.fLeft = left;
        l.fRight = right;
        l.fFont = font;
        l.fIndent = indent;
        return l;
    };
    const auto city = board.boardCityWithId(cid);
    const auto pid = board.cityIdToPlayerId(cid);
    // partners: every city we have a trade post with, or traded with
    std::vector<eWorldCity*> partners;
    const auto addPartner = [&](eWorldCity* const c) {
        if(!c) return;
        if(std::find(partners.begin(), partners.end(), c) == partners.end()) {
            partners.push_back(c);
        }
    };
    std::map<eWorldCity*, eResourceType> exportsTo;
    std::map<eWorldCity*, eResourceType> importsFrom;
    if(city) {
        for(const auto tp : city->tradePosts()) {
            auto& c = tp->city();
            addPartner(&c);
            eResourceType imp;
            eResourceType exp;
            tp->getOrders(imp, exp);
            exportsTo[&c] = exportsTo[&c] | exp;
            importsFrom[&c] = importsFrom[&c] | imp;
        }
    }
    const auto& cities = board.world().cities();
    const auto byId = [&](const int id) -> eWorldCity* {
        for(const auto& c : cities) {
            if(static_cast<int>(c->cityId()) == id) return c.get();
        }
        return nullptr;
    };
    if(city) {
        for(const auto& y : city->tradeLedger().thisYear()) addPartner(byId(y.first));
        for(const auto& y : city->tradeLedger().lastYear()) addPartner(byId(y.first));
    }

    add(tr("trade_partners", "Trade partners"), "", 1).fHeader = true;
    if(partners.empty()) {
        add(tr("trade_none", "No trade routes yet. Open one on the world map, then build a trade post."),
            "", 0, 0).fLeftTone = eTradeTone::dim;
    }
    int totalNet = 0;
    for(const auto c : partners) {
        const int id = static_cast<int>(c->cityId());
        eTradeYear ty;
        eTradeYear ly;
        if(city) {
            const auto& t = city->tradeLedger().thisYear();
            const auto& l = city->tradeLedger().lastYear();
            if(t.count(id)) ty = t.at(id);
            if(l.count(id)) ly = l.at(id);
        }
        const int net = ty.fIncome - ty.fCost;
        totalNet += net;
        {
            auto& l = add(c->name(), signedNumber(net) + " " + tr("trade_dr", "dr."), 1, 0);
            l.fCard = true;
            l.fLeftTone = eTradeTone::gold;
            l.fRightTone = net > 0 ? eTradeTone::green : net < 0 ? eTradeTone::red : eTradeTone::dim;
        }
        {
            std::string status;
            eTradeTone sc = eTradeTone::dim;
            if(c->tradeShutdown()) {
                status = tr("trade_stopped", "Trade has stopped");
                sc = eTradeTone::red;
            } else if(!exportsTo.count(c)) {
                status = tr("trade_no_post", "No trade post");
            }
            const auto detail = tr("trade_this_year", "This year") + ": " +
                                tr("trade_earned", "earned") + " " + number(ty.fIncome) + ", " +
                                tr("trade_spent", "spent") + " " + number(ty.fCost);
            auto& l = add(detail, status, 0, 1);
            l.fLeftTone = eTradeTone::dim;
            l.fRightTone = sc;
        }
        {
            const int lnet = ly.fIncome - ly.fCost;
            auto& l = add(tr("trade_last_year", "Last year") + ": " + signedNumber(lnet) + " " +
                          tr("trade_dr", "dr."), "", 0, 1);
            l.fLeftTone = eTradeTone::dim;
        }
        const auto goodsLine = [&](const std::vector<eResourceTrade>& ts,
                                   const eResourceType on, const char* key,
                                   const char* fallback) {
            if(ts.empty()) return;
            add(tr(key, fallback), "", 0, 1).fLeftTone = eTradeTone::label;
            for(const auto& t : ts) {
                const int used = t.used(pid);
                const bool active = static_cast<bool>(on & t.fType);
                auto right = number(used) + " / " + number(t.fMax);
                eTradeTone rc = eTradeTone::dim;
                if(!active) {
                    right += "   " + tr("trade_off", "(off)");
                } else if(used >= t.fMax) {
                    rc = eTradeTone::amber;
                } else {
                    rc = eTradeTone::green;
                }
                auto& l = add(eResourceTypeHelpers::typeName(t.fType), right, 0, 2);
                l.fIcon = t.fType;
                l.fLeftTone = active ? eTradeTone::text : eTradeTone::dim;
                l.fRightTone = rc;
            }
        };
        goodsLine(c->buys(), exportsTo.count(c) ? exportsTo[c] : eResourceType::none,
                  "trade_they_buy", "They buy from us (this year / most):");
        goodsLine(c->sells(), importsFrom.count(c) ? importsFrom[c] : eResourceType::none,
                  "trade_they_sell", "They sell us (this year / most):");
    }
    if(partners.size() > 1) {
        auto& l = add(tr("trade_total", "All partners this year"),
                      signedNumber(totalNet) + " " + tr("trade_dr", "dr."), 1, 0);
        l.fRightTone = totalNet > 0 ? eTradeTone::green : totalNet < 0 ? eTradeTone::red : eTradeTone::dim;
    }

    // stock and its buyers
    add(tr("trade_stock", "Goods in storage"), "", 1).fHeader = true;
    bool anyStock = false;
    for(const auto type : kGoods) {
        const int count = city ? city->resourceCount(type) : 0;
        if(count <= 0) continue;
        anyStock = true;
        std::string buyers;      // with a trade post of ours
        std::string elsewhere;   // cities that would buy it, no trade post yet
        bool exported = false;
        bool quotaLeft = false;
        for(const auto& cc : cities) {
            const auto c = cc.get();
            const bool partner = exportsTo.count(c) > 0;
            if(!partner && !c->trades()) continue;
            for(const auto& t : c->buys()) {
                if(t.fType != type) continue;
                auto& list = partner ? buyers : elsewhere;
                if(!list.empty()) list += ", ";
                list += c->name();
                if(partner && static_cast<bool>(exportsTo[c] & type)) {
                    exported = true;
                    if(t.fMax - t.used(pid) > 0) quotaLeft = true;
                }
            }
        }
        std::string status;
        eTradeTone sc = eTradeTone::dim;
        if(buyers.empty() && !elsewhere.empty()) {
            status = tr("trade_wanted_by", "wanted by") + " " + elsewhere + " " +
                     tr("trade_no_route", "(no trade post)");
            sc = eTradeTone::amber;
        } else if(buyers.empty()) {
            status = tr("trade_no_buyer", "no buyer");
        } else if(!exported) {
            status = tr("trade_not_exported", "not exported to") + " " + buyers;
            sc = eTradeTone::amber;
        } else if(!quotaLeft) {
            status = tr("trade_quota_full", "buyers want no more this year");
            sc = eTradeTone::amber;
        } else {
            status = tr("trade_selling", "selling to") + " " + buyers;
            sc = eTradeTone::green;
        }
        auto& l = add(eResourceTypeHelpers::typeName(type) + "  " + number(count), status, 0, 1);
        l.fIcon = type;
        l.fRightTone = sc;
    }
    if(!anyStock) {
        add(tr("trade_empty_stock", "Nothing in storage."), "", 0, 0).fLeftTone = eTradeTone::dim;
    }

    return out;
}
