#include "etradesummarywidget.h"

#include "elabel.h"
#include "eokbutton.h"
#include "escrollwidgetcomplete.h"
#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "etexture.h"
#include "engine/egameboard.h"
#include "engine/eworldcity.h"
#include "engine/eworldboard.h"
#include "buildings/etradepost.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

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

const SDL_Color kDim{156, 170, 196, 255};
const SDL_Color kGreen{128, 214, 146, 255};
const SDL_Color kRed{240, 110, 90, 255};
const SDL_Color kAmber{255, 196, 110, 255};
const SDL_Color kGoldText{255, 222, 140, 255};

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

eTradeSummaryList::~eTradeSummaryList() {
    for(auto& t : mTexts) {
        if(t.second.fTex) SDL_DestroyTexture(t.second.fTex);
    }
}

eTradeSummaryList::eLine& eTradeSummaryList::add(const std::string& left,
                                                 const std::string& right,
                                                 const int font,
                                                 const int indent) {
    auto& l = mLines.emplace_back();
    l.fLeft = left;
    l.fRight = right;
    l.fFont = font;
    l.fIndent = indent;
    return l;
}

const eTradeSummaryList::eText& eTradeSummaryList::text(SDL_Renderer* const r,
                                                        const std::string& s,
                                                        const int px) {
    auto& t = mTexts[{s, px}];
    if(!t.fTex && !s.empty()) {
        t.fTex = eMenu3D::makeText(r, eFonts::defaultFont(px), s,
                                   SDL_Color{255, 255, 255, 255}, t.fW, t.fH);
    }
    return t;
}

void eTradeSummaryList::initialize(eGameBoard& board, const eCityId cid,
                                   const int width) {
    setNoPadding();
    const auto city = board.boardCityWithId(cid);
    const auto pid = board.cityIdToPlayerId(cid);
    const auto res = resolution();
    const double m = res.multiplier();

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
            "", 0, 0).fLeftColor = kDim;
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
            l.fLeftColor = kGoldText;
            l.fRightColor = net > 0 ? kGreen : net < 0 ? kRed : kDim;
        }
        {
            std::string status;
            SDL_Color sc = kDim;
            if(c->tradeShutdown()) {
                status = tr("trade_stopped", "Trade has stopped");
                sc = kRed;
            } else if(!exportsTo.count(c)) {
                status = tr("trade_no_post", "No trade post");
            }
            const auto detail = tr("trade_this_year", "This year") + ": " +
                                tr("trade_earned", "earned") + " " + number(ty.fIncome) + ", " +
                                tr("trade_spent", "spent") + " " + number(ty.fCost);
            auto& l = add(detail, status, 0, 1);
            l.fLeftColor = kDim;
            l.fRightColor = sc;
        }
        {
            const int lnet = ly.fIncome - ly.fCost;
            auto& l = add(tr("trade_last_year", "Last year") + ": " + signedNumber(lnet) + " " +
                          tr("trade_dr", "dr."), "", 0, 1);
            l.fLeftColor = kDim;
        }
        const auto goodsLine = [&](const std::vector<eResourceTrade>& ts,
                                   const eResourceType on, const char* key,
                                   const char* fallback) {
            if(ts.empty()) return;
            add(tr(key, fallback), "", 0, 1).fLeftColor = SDL_Color{200, 208, 222, 255};
            for(const auto& t : ts) {
                const int used = t.used(pid);
                const bool active = static_cast<bool>(on & t.fType);
                auto right = number(used) + " / " + number(t.fMax);
                SDL_Color rc = kDim;
                if(!active) {
                    right += "   " + tr("trade_off", "(off)");
                } else if(used >= t.fMax) {
                    rc = kAmber;
                } else {
                    rc = kGreen;
                }
                auto& l = add(eResourceTypeHelpers::typeName(t.fType), right, 0, 2);
                l.fIcon = t.fType;
                l.fLeftColor = active ? SDL_Color{236, 230, 214, 255} : kDim;
                l.fRightColor = rc;
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
        l.fRightColor = totalNet > 0 ? kGreen : totalNet < 0 ? kRed : kDim;
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
        SDL_Color sc = kDim;
        if(buyers.empty() && !elsewhere.empty()) {
            status = tr("trade_wanted_by", "wanted by") + " " + elsewhere + " " +
                     tr("trade_no_route", "(no trade post)");
            sc = kAmber;
        } else if(buyers.empty()) {
            status = tr("trade_no_buyer", "no buyer");
        } else if(!exported) {
            status = tr("trade_not_exported", "not exported to") + " " + buyers;
            sc = kAmber;
        } else if(!quotaLeft) {
            status = tr("trade_quota_full", "buyers want no more this year");
            sc = kAmber;
        } else {
            status = tr("trade_selling", "selling to") + " " + buyers;
            sc = kGreen;
        }
        auto& l = add(eResourceTypeHelpers::typeName(type) + "  " + number(count), status, 0, 1);
        l.fIcon = type;
        l.fRightColor = sc;
    }
    if(!anyStock) {
        add(tr("trade_empty_stock", "Nothing in storage."), "", 0, 0).fLeftColor = kDim;
    }

    // layout
    const int tiny = res.tinyFontSize();
    const int small = res.smallFontSize();
    int y = 0;
    for(auto& l : mLines) {
        const int px = l.fFont ? small : tiny;
        int tw = 0;
        int th = px;
        if(const auto f = eFonts::defaultFont(px)) TTF_SizeUTF8(f, "Ag", &tw, &th);
        if(l.fHeader && y > 0) y += static_cast<int>(12*m);
        if(l.fCard) y += static_cast<int>(8*m);
        l.fY = y;
        l.fH = th + static_cast<int>((l.fHeader ? 8 : 3)*m);
        y += l.fH;
    }
    // each partner card spans its lines
    for(size_t i = 0; i < mLines.size(); i++) {
        if(!mLines[i].fCard) continue;
        size_t j = i + 1;
        while(j < mLines.size() && !mLines[j].fCard && !mLines[j].fHeader &&
              mLines[j].fIndent > 0) j++;
        mLines[i].fCardH = mLines[j - 1].fY + mLines[j - 1].fH - mLines[i].fY;
    }
    resize(width, y + static_cast<int>(8*m));
}

void eTradeSummaryList::paintEvent(ePainter& p) {
    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const auto res = resolution();
    const double m = res.multiplier();
    const float X = p.x();
    const float Y = p.y();
    const float W = width();
    const int tiny = res.tinyFontSize();
    const int small = res.smallFontSize();
    const float indentW = static_cast<float>(16*m);
    const float iconS = static_cast<float>(16*m);

    for(const auto& l : mLines) {
        if(l.fCard) {
            const SDL_FRect card{X, Y + l.fY - static_cast<float>(4*m), W,
                                 l.fCardH + static_cast<float>(8*m)};
            const float rad = static_cast<float>(8*m);
            ePanel::roundRect(r, card, rad, SDL_Color{34, 56, 100, 120}, SDL_Color{16, 26, 52, 120});
            ePanel::roundRect(r, card, rad, SDL_Color{240, 200, 110, 90}, SDL_Color{160, 112, 36, 60},
                              std::max(1.f, static_cast<float>(m)));
        }
    }
    for(const auto& l : mLines) {
        const int px = l.fFont ? small : tiny;
        float x = X + static_cast<float>(10*m) + l.fIndent*indentW;
        const float cy = Y + l.fY + l.fH/2.f;
        if(l.fIcon != eResourceType::none) {
            const auto tex = eResourceTypeHelpers::icon(res.uiScale(), l.fIcon);
            if(tex && tex->width() > 0 && tex->height() > 0) {
                const double s = std::min(iconS/tex->width(), iconS/tex->height());
                const int dw = std::round(tex->width()*s);
                const int dh = std::round(tex->height()*s);
                p.drawTextureScaled(SDL_Rect{static_cast<int>(x - X), static_cast<int>(cy - Y - dh/2.0), dw, dh}, tex);
                eGeometryBatch::sFlush();
            }
            x += iconS + static_cast<float>(6*m);
        }
        if(!l.fLeft.empty()) {
            const auto& t = text(r, l.fLeft, px);
            if(t.fTex) {
                const SDL_Color c = l.fHeader ? kGoldText : l.fLeftColor;
                SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
                SDL_SetTextureAlphaMod(t.fTex, c.a);
                const SDL_FRect d{std::round(x), std::round(cy - t.fH/2.f), float(t.fW), float(t.fH)};
                SDL_RenderCopyF(r, t.fTex, nullptr, &d);
            }
        }
        if(!l.fRight.empty()) {
            const auto& t = text(r, l.fRight, px);
            if(t.fTex) {
                const auto c = l.fRightColor;
                SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
                SDL_SetTextureAlphaMod(t.fTex, c.a);
                const SDL_FRect d{std::round(X + W - static_cast<float>(12*m) - t.fW),
                                  std::round(cy - t.fH/2.f), float(t.fW), float(t.fH)};
                SDL_RenderCopyF(r, t.fTex, nullptr, &d);
            }
        }
        if(l.fHeader) {
            ePanel::goldRule(r, X, Y + l.fY + l.fH - static_cast<float>(2*m), W,
                             std::max(1.f, static_cast<float>(m)), 170, false);
        }
    }
}

void eTradeSummaryWidget::initialize(eGameBoard& board, const eCityId cid,
                                     const eAction& close) {
    setType(eFrameType::message);
    const auto res = resolution();
    const double m = res.multiplier();
    const int p = res.largePadding();
    const auto win = window();
    const int ww = std::min(static_cast<int>(620*m), win->width()*3/4);
    const int hh = std::min(static_cast<int>(520*m), win->height() - 8*p);
    resize(ww, hh);

    const auto title = new eLabel(tr("trade_title", "Trade Summary"), window());
    title->setHugeFontSize();
    title->setYellowFontColor();
    title->fitContent();
    addWidget(title);
    title->align(eAlignment::top | eAlignment::hcenter);
    title->setY(title->y() + p);

    const auto ok = new eOkButton(window());
    addWidget(ok);
    ok->align(eAlignment::bottom | eAlignment::right);
    ok->move(ok->x() - 2*p, ok->y() - 2*p);
    ok->setPressAction(close);

    const int top = title->y() + title->height() + p;
    const auto scroll = new eScrollWidgetComplete(window());
    addWidget(scroll);
    scroll->resize(ww - 4*p, ok->y() - top - p);
    scroll->move(2*p, top);
    scroll->initialize();

    const auto list = new eTradeSummaryList(window());
    list->initialize(board, cid, scroll->listWidth() - res.tinyPadding());
    scroll->setScrollArea(list);
}
