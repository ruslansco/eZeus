#include "egamemenu.h"
#include "engine/etradepartners.h"
#include "eworldwidget.h"

#include "textures/egametextures.h"
#include "emainwindow.h"
#include "echeckablebutton.h"
#include "engine/egameboard.h"
#include "engine/edifficulty.h"

#include "widgets/datawidgets/epopulationdatawidget.h"
#include "widgets/datawidgets/eemploymentdatawidget.h"
#include "widgets/datawidgets/eappealdatawidget.h"
#include "widgets/datawidgets/estoragedatawidget.h"
#include "widgets/datawidgets/ehygienesafetydatawidget.h"
#include "widgets/datawidgets/eculturedatawidget.h"
#include "widgets/datawidgets/esciencedatawidget.h"
#include "widgets/datawidgets/eadmindatawidget.h"
#include "widgets/datawidgets/ehusbandrydatawidget.h"
#include "widgets/datawidgets/emythologydatawidget.h"
#include "widgets/datawidgets/emilitarydatawidget.h"
#include "widgets/datawidgets/eoverviewdatawidget.h"
#include "eminimap.h"

#include "eeventwidget.h"

#include "egamewidget.h"

#include "elanguage.h"

#include "ebuildwidget.h"
#include "ebasicbutton.h"
#include "erotatebutton.h"
#include "epanelwidgets.h"
#include "epanelstyle.h"
#include "emenu3d.h"
#include "efonts.h"
#include "textures/egeometrybatch.h"

struct eSubButtonData {
    eBuildingMode fMode;
    std::string fName;
    std::function<void()> fPressedFunc;
    int fPrice;
    int fPriceSpace;
    const eTextureCollection* fColl;
    const eTextureCollection* fAColl;
    std::vector<eSPR> fSpr = {};
};

void tradePosts(const eCityId cid, std::vector<eSPR>& cs,
                eGameBoard& board, const bool showAllPossibleBuildings) {
    for(const auto& partner : eTradePartners::available(board, cid, showAllPossibleBuildings)) {
        const auto& c = partner.city;
        if(partner.water) {
            const auto name = eLanguage::zeusText(28, 60) + " " + c->name();
            const eSPR s{eBuildingMode::pier, name, 0, partner.index};
            cs.push_back(s);
        } else {
            const auto name = eLanguage::zeusText(28, 62) + " " + c->name();
            const eSPR s{eBuildingMode::tradePost, name, 0, partner.index};
            cs.push_back(s);
        }
    }
}

class eSubButton {
public:
    eSubButton(const eBuildingMode mode,
               eButton* const button,
               eButton* const abutton,
               const std::vector<eSPR>& children,
               eGameBoard& board) :
        mMode(mode),
        mButton(button),
        mAButton(abutton),
        mChildren(children),
        mBoard(board) {}

    void updateVisible(const eCityId cid, const bool showAllPossibleBuildings) {
        bool vis = false;
        const auto pid = mBoard.cityIdToPlayerId(cid);
        const auto ppid = mBoard.personPlayer();
        const bool a = mBoard.atlantean(cid);
        if(pid != ppid) {
            vis = showAllPossibleBuildings;
        } else if(mMode == eBuildingMode::tradePost) {
            std::vector<eSPR> cs;
            tradePosts(cid, cs, mBoard, showAllPossibleBuildings);
            vis = !cs.empty();
        } else if(mMode == eBuildingMode::palace) {
            vis = !mBoard.hasPalace(cid);
        } else if(mMode == eBuildingMode::stadium) {
            vis = !mBoard.atlantean(cid) && !mBoard.hasStadium(cid);
        } else if(mMode == eBuildingMode::museum) {
            vis = mBoard.atlantean(cid) && !mBoard.hasMuseum(cid);
        } else if(mMode == eBuildingMode::none) {
            for(const auto& c : mChildren) {
                const bool s = showAllPossibleBuildings ||
                               mBoard.supportsBuilding(cid, c.fMode);
                if(s) {
                    vis = true;
                    break;
                }
            }
        } else {
            vis = showAllPossibleBuildings ||
                  mBoard.supportsBuilding(cid, mMode);
        }
        if(mButton) {
            mButton->setVisible(vis && (!a || !mAButton));
        }
        if(mAButton) {
            mAButton->setVisible(vis && (a || !mButton));
        }
    }
private:
    const eBuildingMode mMode;
    eButton* const mButton;
    eButton* const mAButton;
    const std::vector<eSPR> mChildren;
    eGameBoard& mBoard;
};

eWidget* eGameMenu::createPriceWidget(const eInterfaceTextures& coll) {
    const auto r = new ePricePill(window());
    r->setNoPadding();
    const auto plabel = new eLabel("0", window());
    plabel->setTinyFontSize();
    plabel->setTinyPadding();
    plabel->fitContent();
    const auto ilabel = new eLabel(window());
    ilabel->setTexture(coll.fDrachmasUnit);
    ilabel->setTinyPadding();
    ilabel->fitContent();
    r->addWidget(ilabel);
    r->addWidget(plabel);
    r->stackHorizontally();
    r->fitContent();
    {
        const int pad = std::max(2, r->height()/4);
        r->setWidth(r->width() + pad);
        ilabel->setX(ilabel->x() + pad/2);
        plabel->setX(plabel->x() + pad/2);
    }
    plabel->align(eAlignment::vcenter);
    mPriceWidgets.push_back(r);
    mPriceLabels.push_back(plabel);
    r->hide();
    return r;
}

eWidget* eGameMenu::createSubButtons(
        const int resoltuionMult,
        const eButtonsDataVec& buttons) {
    const auto result = new eWidget(window());

    const int x = resoltuionMult*35;
    const int y = resoltuionMult*28;
    const std::vector<std::pair<int, int>> poses =
        {{0, 0}, {x, 0}, {0, y}, {x, y}};

    const int iMax = buttons.size();
    for(int i = 0; i < iMax; i++) {
        const auto& c = buttons[i];

        const auto createButton = [&](const eTextureCollection& texs) {
            const auto b = new ePanelTileButton(window());
            b->setTexture(texs.getTexture(0));
            b->setPadding(0);
            b->fitContent();
            b->setOpensList(!c.fSpr.empty());
            result->addWidget(b);
            b->setPressAction(c.fPressedFunc);
            b->setMouseEnterAction([c, this]() {
                mNameLabel->setText(c.fName);
                displayPrice(c.fPrice, c.fPriceSpace);
            });
            b->setMouseLeaveAction([c, this]() {
                mNameLabel->setText("");
                displayPrice(0, c.fPriceSpace);
            });
            const auto& pos = poses[i];
            b->setX(pos.first);
            b->setY(pos.second);

            return b;
        };

        const auto b = c.fColl ? createButton(*c.fColl) : nullptr;
        const auto ab = c.fAColl ? createButton(*c.fAColl) : nullptr;

        const auto subButton = new eSubButton(c.fMode, b, ab, c.fSpr, *mBoard);
        subButton->updateVisible(eCityId::neutralFriendly,
                                 mShowAllPossibleBuildings);
        mSubButtons.push_back(subButton);
    }

    result->setNoPadding();
    result->fitContent();

    return result;
}

eBuildButton* eGameMenu::createBuildButton(const eSPR& c) {
    const auto bb = new eBuildButton(window());
    const auto pid = mBoard->personPlayer();
    const auto diff = mBoard->difficulty(pid);
    const auto mode = c.fMode;
    const auto t = eBuildingModeHelpers::toBuildingType(mode);
    const int cost = eDifficultyHelpers::buildingCost(diff, t);
    bb->initialize(c.fName, c.fMarbleCost, cost);
    bb->setPressAction([this, c]() {
        setMode(c.fMode);
        mTradeCityId = c.fCity;
        closeBuildWidget();
    });
    return bb;
}

void eGameMenu::openBuildWidget(const int cmx, const int cmy,
                                const std::vector<eSPR>& cs) {
    const auto cid = mGW->viewedCity();
    const auto pid = mBoard->cityIdToPlayerId(cid);
    const auto ppid = mBoard->personPlayer();
    if(pid != ppid && !mShowAllPossibleBuildings) return;
    std::vector<eBuildButton*> ws;
    for(const auto& c : cs) {
        if(!mBoard->supportsBuilding(cid, c.fMode) &&
           !mShowAllPossibleBuildings) continue;
        const auto bb = createBuildButton(c);
        ws.push_back(bb);
    }
    if(ws.empty()) return;
    const auto bw = new eBuildWidget(window());
    bw->initialize(ws);
    bw->exec(cmx - bw->width(), cmy - bw->height(), this);
    setBuildWidget(bw);
}

void eGameMenu::setModeChangedAction(const eAction& func) {
    mModeChangeAct = func;
}

void eGameMenu::setUndoAction(const eAction& func) {
    if(mUndoButton) mUndoButton->setPressAction(func);
}

void eGameMenu::setUndoEnabled(const bool e) {
    if(mUndoButton && mUndoButton->enabled() != e) mUndoButton->setEnabled(e);
}

void eGameMenu::updateRequestButtons() {
    mOverDataW->updateRequestButtons();
}

void eGameMenu::setWorldDirection(const eWorldDirection dir) {
    mRotateButton->setDirection(dir);
}

void eGameMenu::update() {

}

void eGameMenu::setShowAllPossibleBuildings(const bool b) {
    mShowAllPossibleBuildings = b;
    updateButtonsVisibility();
}

void eGameMenu::displayPrice(const int price, const int loc) {
    const auto w = mPriceWidgets[loc];
    const auto l = mPriceLabels[loc];
    if(price <= 0) {
        w->hide();
    } else {
        l->setText(std::to_string(price));
        w->show();
    }
}

eGameMenu::~eGameMenu() {
    for(const auto s : mSubButtons) {
        delete s;
    }
    if(mCalmTex) SDL_DestroyTexture(mCalmTex);
    for(const auto& k : mKeyTex) {
        if(k.fTex) SDL_DestroyTexture(k.fTex);
    }
}

void eGameMenu::categoryChanged(const int i) {
    (void)i;
    // choosing a category leaves the big map
    if(mMapMode && mTabs) mTabs->setIndex(0);
}

int eGameMenu::currentCategory() const {
    const auto& bs = categoryButtons();
    for(int i = 0; i < static_cast<int>(bs.size()); i++) {
        if(bs[i]->checked()) return i;
    }
    return -1;
}

bool eGameMenu::openCategory(int i) {
    const auto& bs = categoryButtons();
    if(i < 0 || i >= static_cast<int>(bs.size())) return false;
    // culture and science share the rail slot
    if(i == 6 && mScienceButton && mScienceButton->visible()) i = 11;
    else if(i == 11 && mScienceButton && !mScienceButton->visible()) i = 6;
    if(i >= static_cast<int>(bs.size())) return false;
    const auto b = bs[i];
    if(!b->visible() || !b->enabled()) return false;
    if(!b->checked()) b->trigger();
    else if(mMapMode && mTabs) mTabs->setIndex(0);
    return true;
}

void eGameMenu::setMapTab(const bool m) {
    if(mTabs && m != mMapMode) mTabs->setIndex(m ? 1 : 0);
}

void eGameMenu::setMapMode(const bool m) {
    if(m == mMapMode || !mMiniMap || !mMapHome) return;
    mMapMode = m;
    int tx = 0;
    int ty = 0;
    mMiniMap->viewedTile(tx, ty);
    if(m) {
        mPageBeforeMap = nullptr;
        for(const auto& w : mWidgets) {
            if(w.fW->visible()) mPageBeforeMap = w.fW;
            w.fW->hide();
        }
        mMapHomeRect = SDL_Rect{mMiniMap->x(), mMiniMap->y(),
                                mMiniMap->width(), mMiniMap->height()};
        mMapHome->removeWidget(mMiniMap);
        removeWidget(mVeil);
        addWidget(mMiniMap);
        addWidget(mVeil);
        mMiniMap->setTileDim(2*mMult);
        const int mapH = mBoard ? mBoard->rotatedHeight()*mMiniMap->tileDim()/2 : 0;
        const int maxH = std::round(u(128));
        mMiniMap->resize(std::round(u(63.5)), mapH > 0 ? std::min(mapH, maxH) : maxH);
        mMiniMap->move(std::round(u(25.2)), std::round(u(14.5)));
        mNameLabel->hide();
    } else {
        removeWidget(mMiniMap);
        mMapHome->addWidget(mMiniMap);
        mMiniMap->setTileDim(2);
        mMiniMap->resize(mMapHomeRect.w, mMapHomeRect.h);
        mMiniMap->move(mMapHomeRect.x, mMapHomeRect.y);
        if(mPageBeforeMap) mPageBeforeMap->show();
        mNameLabel->show();
    }
    mMiniMap->viewTile(tx, ty);
    mMiniMap->scheduleUpdate();
    if(mVeil) mVeil->trigger();
}

void eGameMenu::paintEvent(ePainter& p) {
    using namespace ePanel;
    // EZEUS_SHOT_PANEL=<category index>|map opens that page (screenshots of the panel)
    static bool sShotPanelDone = false;
    if(!sShotPanelDone) {
        sShotPanelDone = true;
        if(const char* const s = getenv("EZEUS_SHOT_PANEL")) {
            const std::string v = s;
            const auto& bs = categoryButtons();
            if(v == "map") {
                if(mTabs) mTabs->setIndex(1);
            } else if(v == "world" || v == "world-city") {
                const auto win = window();
                const bool city = v == "world-city";
                win->addSlot([win, city]() {
                    win->showWorld();
                    if(city && win->worldWidget()) {
                        win->worldWidget()->selectNextCity(1);
                        win->worldWidget()->selectNextCity(1);
                    }
                });
            } else if(v == "summary" || v == "tips") {
                const auto gw = mGW;
                const bool summary = v == "summary";
                if(gw) window()->addSlot([gw, summary]() {
                    if(summary) gw->debugShowMonthlySummary();
                    else gw->debugShowTips();
                });
            } else if(v == "keys") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->showShortcutSheet(true); });
            } else if(v == "terrain") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->debugShowTerrainMenu(); });
            } else if(v == "advisor") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->showCityAdvisor(); });
            } else if(v == "messages-real") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->showMessageLog(); });
            } else if(v == "history-real") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->showCityHistory(); });
            } else if(v == "history" || v == "trade") {
                const auto gw = mGW;
                const bool history = v == "history";
                if(gw) window()->addSlot([gw, history]() {
                    if(history) gw->debugShowCityHistory();
                    else gw->showTradeSummary();
                });
            } else if(v == "place" || v == "road") {
                const auto gw = mGW;
                const bool road = v == "road";
                if(gw) window()->addSlot([gw, road]() { gw->debugPlacePreview(road); });
            } else if(v == "walker") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->debugHoverHouse(true); });
            } else if(v == "info" || v == "info-house" || v == "info-walker") {
                const auto gw = mGW;
                const std::string kind = v == "info" ? "building" : v.substr(5);
                if(gw) window()->addSlot([gw, kind]() { gw->debugOpenInfo(kind); });
            } else if(v == "house") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->debugHoverHouse(); });
            } else if(v == "toasts") {
                const auto gw = mGW;
                if(gw) window()->addSlot([gw]() { gw->debugShowToasts(); });
            } else if(v == "messages-gods") {
                const auto gw = mGW;
                if(gw) {
                    gw->debugFillMessageLog();
                    gw->setMessageFilter(3);
                    window()->addSlot([gw]() { gw->showMessageLog(); });
                }
            } else if(v == "messages" || v == "badge") {
                if(mGW) mGW->debugFillMessageLog();
                // after this frame: opening a dialog adds to the game widget mid-paint
                if(v == "messages" && mGW) {
                    const auto gw = mGW;
                    window()->addSlot([gw]() { gw->showMessageLog(); });
                }
            } else {
                const int i = atoi(s);
                if(i >= 0 && i < static_cast<int>(bs.size()) && !bs[i]->checked()) bs[i]->trigger();
            }
            // a screenshot wants the settled page, not the reveal
            for(const auto& w : mWidgets) {
                if(w.fW->visible()) mLastPage = w.fW;
            }
            if(mVeil) mVeil->cancel();
        }
    }
    const auto r = p.renderer();
    const float ox = p.x();
    const float oy = p.y();
    const float W = width();
    const float H = height();
    const float hair = std::max(1.f, u(.45));

    // the panel casts a soft shadow over the map
    {
        const auto wt = white(r);
        const float sw = u(9);
        const SDL_Color a{0, 0, 0, 0};
        const SDL_Color b{0, 0, 0, 120};
        const SDL_Vertex v[4] = {{{ox - sw, oy}, a, {.5f, .5f}}, {{ox, oy}, b, {.5f, .5f}},
                                 {{ox, oy + H}, b, {.5f, .5f}}, {{ox - sw, oy + H}, a, {.5f, .5f}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        eGeometryBatch::sFlush();
        SDL_RenderGeometry(r, wt, v, 4, ids, 6);
    }
    // lapis body
    if(const auto t = lapis(r)) {
        int tw = 0;
        int th = 0;
        SDL_QueryTexture(t, nullptr, nullptr, &tw, &th);
        for(int y = 0; y < H; y += th) {
            for(int x = 0; x < W; x += tw) {
                const int w = std::min<int>(tw, W - x);
                const int h = std::min<int>(th, H - y);
                const SDL_Rect src{0, 0, w, h};
                const SDL_Rect dst{static_cast<int>(ox) + x, static_cast<int>(oy) + y, w, h};
                SDL_RenderCopy(r, t, &src, &dst);
            }
        }
    } else {
        fill(r, SDL_FRect{ox, oy, W, H}, SDL_Color{12, 22, 46, 255});
    }
    gradient(r, SDL_FRect{ox, oy, W, H}, SDL_Color{6, 10, 24, 60}, SDL_Color{2, 4, 12, 150});

    // gold bevel along the edge that meets the map
    fill(r, SDL_FRect{ox, oy, std::max(1.f, u(.5)), H}, SDL_Color{2, 4, 10, 255});
    gradient(r, SDL_FRect{ox + std::max(1.f, u(.5)), oy, std::max(1.f, u(.6)), H},
             SDL_Color{246, 206, 110, 255}, SDL_Color{168, 120, 40, 255});
    fill(r, SDL_FRect{ox + std::max(1.f, u(.5)) + std::max(1.f, u(.6)), oy, 1, H},
         SDL_Color{255, 238, 180, 90});
    {
        const auto wt = white(r);
        const float x0 = ox + u(1.2);
        const float sw = u(3.5);
        const SDL_Color a{0, 0, 0, 110};
        const SDL_Color b{0, 0, 0, 0};
        const SDL_Vertex v[4] = {{{x0, oy}, a, {.5f, .5f}}, {{x0 + sw, oy}, b, {.5f, .5f}},
                                 {{x0 + sw, oy + H}, b, {.5f, .5f}}, {{x0, oy + H}, a, {.5f, .5f}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(r, wt, v, 4, ids, 6);
    }

    const SDL_Color wellTop{3, 7, 18, 165};
    const SDL_Color wellBottom{6, 12, 28, 185};
    const SDL_Color rimTop{236, 192, 96, 80};
    const SDL_Color rimBottom{150, 106, 34, 60};
    const auto well = [&](const SDL_FRect& f, const float rad, const bool strong) {
        roundRect(r, f, rad, wellTop, wellBottom);
        SDL_Color t = rimTop;
        SDL_Color b = rimBottom;
        if(strong) {
            t.a = 170;
            b.a = 120;
        }
        roundRect(r, f, rad, t, b, hair);
    };
    // category rail
    well(SDL_FRect{ox + u(1.8), oy + u(10.3), u(24.4), u(226.8)}, u(12), false);
    // content card
    {
        const SDL_FRect f{ox + u(23), oy + u(11.2), u(68), u(203.2)};
        roundRect(r, f, u(4), SDL_Color{20, 36, 70, 150}, SDL_Color{8, 14, 32, 195});
        roundRect(r, SDL_FRect{f.x + 1, f.y + 1, f.w - 2, u(20)}, u(4),
                  SDL_Color{140, 180, 240, 26}, SDL_Color{140, 180, 240, 0});
        roundRect(r, f, u(4), SDL_Color{240, 198, 104, 175}, SDL_Color{150, 106, 34, 110}, hair);
        if(!mMapMode && mTitleH > 0) {
            goldRule(r, f.x + u(4), oy + u(12) + mTitleH + u(.2), f.w - u(8), hair, 210, true);
        }
    }
    // map mode: a frame round the big map and the colour key under it
    if(mMapMode && mMiniMap) {
        const SDL_FRect mf{ox + mMiniMap->x() - 1.f, oy + mMiniMap->y() - 1.f,
                           mMiniMap->width() + 2.f, mMiniMap->height() + 2.f};
        roundRect(r, mf, u(1), SDL_Color{236, 192, 96, 200}, SDL_Color{150, 106, 34, 170}, hair);
        struct eKey { const char* fKey; const char* fText; SDL_Color fCol; };
        static const eKey keys[] = {
            {"map_key_roads", "Roads", {225, 225, 225, 255}},
            {"map_key_housing", "Housing", {164, 65, 49, 255}},
            {"map_key_elite", "Elite housing, temples", {238, 65, 16, 255}},
            {"map_key_palace", "Palace", {230, 162, 0, 255}},
            {"map_key_storage", "Storage and trade", {115, 186, 247, 255}},
            {"map_key_farms", "Farms and husbandry", {123, 113, 49, 255}},
            {"map_key_culture", "Culture", {33, 129, 115, 255}},
            {"map_key_other", "Other buildings, people", {10, 10, 10, 255}},
            {"map_key_fertile", "Fertile land", {155, 110, 110, 255}},
            {"map_key_forest", "Forest", {90, 129, 41, 255}},
            {"map_key_water", "Water", {25, 105, 115, 255}},
        };
        const int n = std::size(keys);
        if(mKeyTex.empty()) {
            const auto font = eFonts::defaultFont(std::max(9, static_cast<int>(std::round(u(4.6)))));
            for(const auto& k : keys) {
                const auto& s = eLanguage::text(k.fKey);
                int w = 0;
                int h = 0;
                const auto t = eMenu3D::makeText(r, font, s.empty() ? k.fText : s,
                                                 SDL_Color{255, 255, 255, 255}, w, h);
                mKeyTex.push_back({t, w, h});
            }
        }
        const float top = mf.y + mf.h + u(4);
        const float row = std::min(u(6.2), (oy + u(211) - top)/n);
        for(int i = 0; i < n; i++) {
            const float cy = top + row*(i + .5f);
            const float sx = ox + u(28);
            const float s = u(3.2);
            roundRect(r, SDL_FRect{sx, cy - s/2, s, s}, u(.7), keys[i].fCol, keys[i].fCol);
            roundRect(r, SDL_FRect{sx, cy - s/2, s, s}, u(.7), SDL_Color{240, 200, 110, 150},
                      SDL_Color{160, 112, 36, 150}, std::max(1.f, u(.3)));
            const auto& kt = mKeyTex[i];
            if(kt.fTex) {
                SDL_SetTextureColorMod(kt.fTex, 232, 224, 204);
                const SDL_FRect d{sx + s + u(2.2), cy - kt.fH/2.f, float(kt.fW), float(kt.fH)};
                SDL_RenderCopyF(r, kt.fTex, nullptr, &d);
            }
        }
    }

    // tools, events, footer
    well(SDL_FRect{ox + u(23), oy + u(216.4), u(68), u(20.2)}, u(10.1), false);
    well(SDL_FRect{ox + u(2), oy + u(239.4), u(89), u(40.4)}, u(4), false);
    well(SDL_FRect{ox + u(2), oy + u(281.3), u(89), u(18.8)}, u(9.4), false);

    // an empty event list: a quiet line of text instead of a blank box
    if(mEventW && mEventW->width() == 0) {
        if(!mCalmTex) {
            const auto& s = eLanguage::text("panel_calm");
            const std::string txt = s.empty() ? "All is calm" : s;
            const auto font = eFonts::defaultFont(std::max(9, static_cast<int>(std::round(u(5)))));
            mCalmTex = eMenu3D::makeText(r, font, txt, SDL_Color{255, 255, 255, 255}, mCalmW, mCalmH);
        }
        if(mCalmTex) {
            SDL_SetTextureColorMod(mCalmTex, 200, 186, 150);
            SDL_SetTextureAlphaMod(mCalmTex, 170);
            const float cx = ox + u(38.5);
            const float cy = oy + u(259.6);
            const SDL_FRect d{cx - mCalmW/2.f, cy - mCalmH/2.f, float(mCalmW), float(mCalmH)};
            SDL_RenderCopyF(r, mCalmTex, nullptr, &d);
            diamond(r, d.x - u(3.5), cy, u(.9), SDL_Color{214, 176, 70, 170});
            diamond(r, d.x + d.w + u(3.5), cy, u(.9), SDL_Color{214, 176, 70, 170});
        }
    }

    // the emblem at the foot of the panel, with a glint passing over it now and then
    {
        int ew = 0;
        int eh = 0;
        // between the footer and the bottom of the screen (the panel can be taller)
        const float bottom = std::min(oy + H, float(window()->height())) - u(3);
        const float top = oy + u(303);
        const float room = bottom - top;
        const float aspect = 1.08f;          // the emblem is a little taller than wide
        const float tw = std::min(u(58), room/aspect);
        const auto t = tw > u(14) ? emblem(r, static_cast<int>(std::ceil(tw)), ew, eh) : nullptr;
        if(t) {
            const float th = tw*eh/std::max(1, ew);
            const float cx = ox + W/2 + u(.6);
            glow(r, cx, top + th/2, tw*.62f, th*.62f, SDL_Color{255, 200, 110, 26}, true);
            glow(r, cx, top + th*.55f, tw*.5f, th*.5f, SDL_Color{0, 0, 0, 90}, false);
            const SDL_FRect d{cx - tw/2, top, tw, th};
            SDL_RenderCopyF(r, t, nullptr, &d);
            const double gt = std::fmod(time(), 7.0)/1.3;
            if(gt < 1) {
                const float gx = static_cast<float>(d.x - tw*.2 + (tw*1.4)*gt);
                glow(r, gx, top + th*.45f, tw*.14f, th*.55f,
                     SDL_Color{255, 236, 170, static_cast<Uint8>(90*std::sin(gt*3.14159))}, true);
            }
        }
    }

    // the open category: a gold marker that glides along the rail
    {
        const auto& bs = categoryButtons();
        eCheckableButton* on = nullptr;
        for(const auto b : bs) {
            if(b->visible() && b->checked()) on = b;
        }
        const double now = time();
        const double dt = mRailLast < 0 ? 0 : std::min(0.1, now - mRailLast);
        mRailLast = now;
        if(on) {
            int bx = 0;
            int by = 0;
            on->mapTo(this, bx, by);
            const double target = by + on->height()/2.0;
            if(mRailY < 0) mRailY = target;
            mRailY += (target - mRailY)*approach(dt, 13);
            const float cy = oy + static_cast<float>(mRailY);
            const Uint8 a = mMapMode ? 90 : 255;
            glow(r, ox + u(3.3), cy, u(3.2), u(9), SDL_Color{255, 196, 90, static_cast<Uint8>(a*.45)}, true);
            roundRect(r, SDL_FRect{ox + u(2.6), cy - u(6.5), std::max(2.f, u(1.2)), u(13)}, u(.6),
                      SDL_Color{255, 238, 170, a}, SDL_Color{196, 140, 48, a});
        }
    }

    // a new page in the content card: let the veil reveal it
    {
        eWidget* page = nullptr;
        for(const auto& w : mWidgets) {
            if(w.fW->visible()) page = w.fW;
        }
        if(page && page != mLastPage && mVeil) mVeil->trigger();
        if(page) mLastPage = page;
    }
}

void eGameMenu::initialize(eGameBoard* const b,
                           const eAction& goalsView) {
    mBoard = b;
    eGameMenuBase::initialize();

    int iRes;
    int mult;
    iResAndMult(iRes, mult);

    const auto& intrfc = eGameTextures::interface();
    const auto& coll = intrfc[iRes];
    const auto tex = coll.fGameMenuBackground;
    setTexture(tex);    // gives the panel its size; paintEvent draws the new design
    setPadding(0);
    fitContent();
    mMult = mult;
    // on tall screens the panel runs to the bottom edge
    setHeight(std::max(height(), window()->height()));

    const int cmx = -padding();
    const int cmy = 5*height()/8;

    const int dataWidWidth = 65*mult;
    const int dataWidHeight = 119*mult;

    const int wwHeight = 190*mult;
    const int wy = dataWidHeight + 31*mult;
    const int wx = 24*mult;

    const auto createDataWidgetBase =
        [&](eDataWidget* const dataW,
            eWidget* const w9,
            const std::string& name) {
        const auto ww9 = new eWidget(window());
        const auto alabel = new eLabel(window());
        alabel->setSmallFontSize();
        alabel->setTinyPadding();
        alabel->setYellowFontColor();
        alabel->setText(name);
        alabel->fitContent();
        mTitleH = alabel->height();
        ww9->addWidget(alabel);
        dataW->setWidth(dataWidWidth);
        dataW->setHeight(dataWidHeight);
        dataW->initialize();
        ww9->addWidget(dataW);
        ww9->setWidth(dataWidWidth);
        ww9->setHeight(wwHeight);
        ww9->stackVertically();
        alabel->align(eAlignment::hcenter);
        ww9->addWidget(w9);
        w9->setY(wy);
        ww9->fitContent();
        return ww9;
    };

    const auto createDataWidget =
        [&](eDataWidget* const dataW,
            const eButtonsDataVec& buttonsVec,
            const std::string& name) {
        const auto w9 = createSubButtons(mult, buttonsVec);
        return createDataWidgetBase(dataW, w9, name);
    };

    mNameLabel = new eFramedLabel(window());
    mNameLabel->setType(eFrameType::inner);
    mNameLabel->setFontRole(eFontRole::display);
    mNameLabel->setVerySmallFontSize();
    mNameLabel->setText("Recreational Areas");
    mNameLabel->setVeryTinyPadding();
    mNameLabel->fitContent();
    mNameLabel->setText("");
    mNameLabel->setWidth(dataWidWidth);
    mNameLabel->setX(wx);
    mNameLabel->setY(wy);
    addWidget(mNameLabel);

    {
        const auto ww = new eWidget(window());
        ww->setNoPadding();
        const int x = mult*35;
        const int y = mult*28;
        const std::vector<std::pair<int, int>> poses =
            {{0, 0}, {x, 0}, {0, y}, {x, y}};
        for(const auto& p : poses) {
            const auto w = createPriceWidget(coll);
            ww->addWidget(w);
            w->setX(p.first);
            w->setY(p.second);
        }
        ww->fitContent();
        addWidget(ww);
        ww->setX(wx);
        ww->setY(wy + 29*mult);
    }

    mPopDataW = new ePopulationDataWidget(*b, window());

    const auto pid = mBoard->personPlayer();
    const auto diff = mBoard->difficulty(pid);
    const int cost1 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::commonHouse);
    const int cost2 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::eliteHousing);

    const auto cha0 = [this]() {
        setMode(eBuildingMode::commonHousing);
    };
    const auto eha0 = [this]() {
        setMode(eBuildingMode::eliteHousing);
    };

    const auto buttonsVec0 = eButtonsDataVec{
                    {eBuildingMode::commonHousing,
                     eLanguage::zeusText(28, 2),
                     cha0, cost1, 0,
                     &coll.fCommonHousing,
                     &coll.fPoseidonCommonHousing},
                    {eBuildingMode::eliteHousing,
                     eLanguage::zeusText(28, 9),
                     eha0, cost2, 1,
                     &coll.fEliteHousing,
                     &coll.fPoseidonEliteHousing}};
    const auto ww0 = createDataWidget(mPopDataW, buttonsVec0,
                                      eLanguage::zeusText(88, 0));

    const std::vector<eSPR> ff1spr = {eSPR{eBuildingMode::wheatFarm, eLanguage::zeusText(28, 31)},
                                      eSPR{eBuildingMode::carrotFarm, eLanguage::zeusText(28, 33)},
                                      eSPR{eBuildingMode::onionFarm, eLanguage::zeusText(28, 32)}};

    const auto ff1 = [this, cmx, cmy, ff1spr]() {
        openBuildWidget(cmx, cmy, ff1spr);
    };

    const std::vector<eSPR> of1spr = {eSPR{eBuildingMode::vine, eLanguage::zeusText(28, 35)},
                                      eSPR{eBuildingMode::oliveTree, eLanguage::zeusText(28, 36)},
                                      eSPR{eBuildingMode::orangeTree, eLanguage::zeusText(28, 217)},
                                      eSPR{eBuildingMode::orangeTendersLodge, eLanguage::zeusText(28, 214)},
                                      eSPR{eBuildingMode::growersLodge, eLanguage::zeusText(28, 37)}};

    const auto of1 = [this, cmx, cmy, of1spr]() {
        openBuildWidget(cmx, cmy, of1spr);
    };

    const std::vector<eSPR> af1spr = {eSPR{eBuildingMode::dairy, eLanguage::zeusText(28, 42)},
                                      eSPR{eBuildingMode::goat, eLanguage::zeusText(28, 39)},
                                      eSPR{eBuildingMode::cardingShed, eLanguage::zeusText(28, 41)},
                                      eSPR{eBuildingMode::sheep, eLanguage::zeusText(28, 40)}};
    const auto af1 = [this, cmx, cmy, af1spr]() {
        openBuildWidget(cmx, cmy, af1spr);
    };

    const std::vector<eSPR> ah1spr = {eSPR{eBuildingMode::fishery, eLanguage::zeusText(28, 44)},
                                      eSPR{eBuildingMode::urchinQuay, eLanguage::zeusText(28, 45)},
                                      eSPR{eBuildingMode::huntingLodge, eLanguage::zeusText(28, 46)},
                                      eSPR{eBuildingMode::corral, eLanguage::zeusText(28, 216)},
                                      eSPR{eBuildingMode::cattle, eLanguage::zeusText(28, 220)}};

    const auto ah1 = [this, cmx, cmy, ah1spr]() {
        openBuildWidget(cmx, cmy, ah1spr);
    };



    mHusbDataW = new eHusbandryDataWidget(*b, window());
    const auto buttonsVec1 = eButtonsDataVec{
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 30),
                             ff1, 0, 0, &coll.fFoodFarming, nullptr, ff1spr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 34),
                             of1, 0, 1, &coll.fOtherFarming, nullptr, of1spr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 38),
                             af1, 0, 2, &coll.fAnimalFarming, nullptr, af1spr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 43),
                             ah1, 0, 3, &coll.fAnimalHunting, nullptr, ah1spr}};
    const auto ww1 = createDataWidget(mHusbDataW, buttonsVec1,
                                      eLanguage::zeusText(88, 1));

    const std::vector<eSPR> r2spr = {eSPR{eBuildingMode::mint, eLanguage::zeusText(28, 48)},
                                     eSPR{eBuildingMode::foundry, eLanguage::zeusText(28, 50)},
                                     eSPR{eBuildingMode::timberMill, eLanguage::zeusText(28, 51)},
                                     eSPR{eBuildingMode::masonryShop, eLanguage::zeusText(28, 49)},
                                     eSPR{eBuildingMode::refinery, eLanguage::zeusText(28, 211)},
                                     eSPR{eBuildingMode::blackMarbleWorkshop, eLanguage::zeusText(28, 218)}};
    const auto r2 = [this, cmx, cmy, r2spr]() {
        openBuildWidget(cmx, cmy, r2spr);
    };
    const std::vector<eSPR> p2spr = {eSPR{eBuildingMode::winery, eLanguage::zeusText(28, 53)},
                                     eSPR{eBuildingMode::olivePress, eLanguage::zeusText(28, 54)},
                                     eSPR{eBuildingMode::sculptureStudio, eLanguage::zeusText(28, 55)}};
    const auto p2 = [this, cmx, cmy, p2spr]() {
        openBuildWidget(cmx, cmy, p2spr);
    };
    const auto bg2 = [this]() {
        setMode(eBuildingMode::artisansGuild);
    };

    mEmplDataW = new eEmploymentDataWidget(*b, window());
    const int cost3 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::artisansGuild);
    const auto buttonsVec2 = eButtonsDataVec{
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 47),
                             r2, 0, 0, &coll.fResources, nullptr, r2spr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 52),
                             p2, 0, 1, &coll.fProcessing, nullptr, p2spr},
                            {eBuildingMode::artisansGuild,
                             eLanguage::zeusText(28, 56),
                             bg2, cost3, 2, &coll.fArtisansGuild, nullptr}};
    const auto ww2 = createDataWidget(mEmplDataW, buttonsVec2,
                                      eLanguage::zeusText(88, 2));


    const auto g3 = [this]() {
        setMode(eBuildingMode::granary);
    };
    const auto ww3 = [this]() {
        setMode(eBuildingMode::warehouse);
    };
    const std::vector<eSPR> a3spr = {eSPR{eBuildingMode::commonAgora, eLanguage::zeusText(28, 63)},
                                     eSPR{eBuildingMode::grandAgora, eLanguage::zeusText(28, 64)},
                                     eSPR{eBuildingMode::foodVendor, eLanguage::zeusText(28, 68)},
                                     eSPR{eBuildingMode::fleeceVendor, eLanguage::zeusText(28, 69)},
                                     eSPR{eBuildingMode::oilVendor, eLanguage::zeusText(28, 70)},
                                     eSPR{eBuildingMode::wineVendor, eLanguage::zeusText(28, 71)},
                                     eSPR{eBuildingMode::armsVendor, eLanguage::zeusText(28, 72)},
                                     eSPR{eBuildingMode::horseTrainer, eLanguage::zeusText(28, 73)},
                                     eSPR{eBuildingMode::chariotVendor, eLanguage::zeusText(28, 215)}};
    const auto a3 = [this, cmx, cmy, a3spr]() {
        openBuildWidget(cmx, cmy, a3spr);
    };
    const auto t3 = [this, cmx, cmy]() {
        std::vector<eSPR> cs;
        const auto cid = mGW->viewedCity();
        tradePosts(cid, cs, *mBoard, mShowAllPossibleBuildings);
        openBuildWidget(cmx, cmy, cs);
    };


    mStrgDataW = new eStorageDataWidget(*b, window());

    const int cost4 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::granary);
    const int cost5 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::warehouse);
    const auto buttonsVec3 = eButtonsDataVec{
                            {eBuildingMode::granary,
                             eLanguage::zeusText(28, 57),
                             g3, cost4, 0, &coll.fGranary, nullptr},
                            {eBuildingMode::warehouse,
                             eLanguage::zeusText(28, 58),
                             ww3, cost5, 1, &coll.fWarehouse, nullptr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 67),
                             a3, 0, 2, &coll.fAgoras, nullptr, a3spr},
                            {eBuildingMode::tradePost,
                             eLanguage::zeusText(28, 26),
                             t3, 0, 3, &coll.fTrade, nullptr}};
    const auto www3 = createDataWidget(mStrgDataW, buttonsVec3,
                                       eLanguage::zeusText(88, 3));


    const auto ff4 = [this]() {
        setMode(eBuildingMode::maintenanceOffice);
    };
    const auto f4 = [this]() {
        setMode(eBuildingMode::fountain);
    };
    const auto p4 = [this]() {
        setMode(eBuildingMode::watchpost);
    };
    const auto h4 = [this]() {
        setMode(eBuildingMode::hospital);
    };

    mHySaDataW = new eHygieneSafetyDataWidget(*b, window());
    const int cost6 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::fountain);
    const int cost7 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::hospital);
    const int cost8 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::maintenanceOffice);
    const int cost9 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::watchPost);
    const auto buttonsVec4 = eButtonsDataVec{
                            {eBuildingMode::fountain,
                             eLanguage::zeusText(28, 74),
                             f4, cost6, 0, &coll.fFountain, nullptr},
                            {eBuildingMode::hospital,
                             eLanguage::zeusText(28, 76),
                             h4, cost7, 1, &coll.fHospital, nullptr},
                            {eBuildingMode::maintenanceOffice,
                             eLanguage::zeusText(28, 121),
                             ff4, cost8, 2, &coll.fFireFighter, nullptr},
                            {eBuildingMode::watchpost,
                             eLanguage::zeusText(28, 124),
                             p4, cost9, 3, &coll.fPolice, nullptr}};
    const auto ww4 = createDataWidget(mHySaDataW, buttonsVec4,
                                      eLanguage::zeusText(88, 4));

    const auto p5 = [this]() {
        setMode(eBuildingMode::palace);
    };
    const auto tc5 = [this]() {
        setMode(eBuildingMode::taxOffice);
    };
    const auto bb5 = [this]() {
        setMode(eBuildingMode::bridge);
    };

    mAdminDataW = new eAdminDataWidget(*b, window());
    const int cost10 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::palace);
    const int cost11 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::taxOffice);
    const int cost12 = eDifficultyHelpers::buildingCost(
                          diff, eBuildingType::bridge);
    const std::vector<eSPR> d5spr = {eSPR{eBuildingMode::hippodromePiece, eLanguage::zeusText(28, 200)},
                                     eSPR{eBuildingMode::crosswalk, eLanguage::zeusText(28, 201)}};
    const auto d5 = [this, cmx, cmy, d5spr]() {
        openBuildWidget(cmx, cmy, d5spr);
    };
    const auto buttonsVec5 = eButtonsDataVec{
                            {eBuildingMode::palace,
                             eLanguage::zeusText(28, 117),
                             p5, cost10, 0, &coll.fPalace, nullptr},
                            {eBuildingMode::taxOffice,
                             eLanguage::zeusText(28, 122),
                             tc5, cost11, 1, &coll.fTaxCollector, nullptr},
                            {eBuildingMode::bridge,
                             eLanguage::zeusText(28, 120),
                             bb5, cost12, 2,
                             &coll.fBridge,
                             &coll.fPoseidonBridge},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 199),
                             d5, 0, 3, &coll.fHipodrome, &coll.fHipodrome, d5spr}};
    const auto ww5 = createDataWidget(mAdminDataW, buttonsVec5,
                                      eLanguage::zeusText(88, 5));



    eWidget* ww6 = nullptr;
    eWidget* ww7 = nullptr;
    {
         const std::vector<eSPR> p6spr = {eSPR{eBuildingMode::observatory, eLanguage::zeusText(28, 203)},
                                          eSPR{eBuildingMode::university, eLanguage::zeusText(28, 204)}};
         const auto p6 = [this, cmx, cmy, p6spr]() {
             openBuildWidget(cmx, cmy, p6spr);
         };
         const auto g6 = [this]() {
             setMode(eBuildingMode::bibliotheke);
         };
         const std::vector<eSPR> d6spr = {eSPR{eBuildingMode::laboratory, eLanguage::zeusText(28, 205)},
                                          eSPR{eBuildingMode::inventorsWorkshop, eLanguage::zeusText(28, 206)}};
         const auto d6 = [this, cmx, cmy, d6spr]() {
             openBuildWidget(cmx, cmy, d6spr);
         };
         const auto s6 = [this]() {
             setMode(eBuildingMode::museum);
         };
         mScienceDataW = new eScienceDataWidget(*mBoard, window());
         const int cost13 = eDifficultyHelpers::buildingCost(
                               diff, eBuildingType::bibliotheke);
         const int cost14 = eDifficultyHelpers::buildingCost(
                               diff, eBuildingType::museum);
         const auto buttonsVec6 = eButtonsDataVec{
                                 {eBuildingMode::bibliotheke,
                                  eLanguage::zeusText(28, 202),
                                  g6, cost13, 0, nullptr, &coll.fBibliotheke},
                                 {eBuildingMode::none,
                                  eLanguage::zeusText(28, 208),
                                  p6, 0, 1, nullptr, &coll.fAstronomy, p6spr},
                                 {eBuildingMode::none,
                                  eLanguage::zeusText(28, 209),
                                  d6, 0, 2, nullptr, &coll.fTechnology, d6spr},
                                 {eBuildingMode::museum,
                                  eLanguage::zeusText(28, 207),
                                  s6, cost14, 3, nullptr, &coll.fMuseum}};
         ww7 = createDataWidget(mScienceDataW, buttonsVec6,
                                eLanguage::zeusText(88, 24));
    }
    {
        const std::vector<eSPR> p6spr = {eSPR{eBuildingMode::podium, eLanguage::zeusText(28, 81)},
                                         eSPR{eBuildingMode::college, eLanguage::zeusText(28, 77)}};
        const auto p6 = [this, cmx, cmy, p6spr]() {
            openBuildWidget(cmx, cmy, p6spr);
        };
        const auto g6 = [this]() {
            setMode(eBuildingMode::gymnasium);
        };
        const std::vector<eSPR> d6spr = {eSPR{eBuildingMode::theater, eLanguage::zeusText(28, 82)},
                                         eSPR{eBuildingMode::dramaSchool, eLanguage::zeusText(28, 78)}};
        const auto d6 = [this, cmx, cmy, d6spr]() {
            openBuildWidget(cmx, cmy, d6spr);
        };
        const auto s6 = [this]() {
            setMode(eBuildingMode::stadium);
        };

        mCultureDataW = new eCultureDataWidget(*mBoard, window());
        const int cost13 = eDifficultyHelpers::buildingCost(
                              diff, eBuildingType::gymnasium);
        const int cost14 = eDifficultyHelpers::buildingCost(
                              diff, eBuildingType::stadium);
        const auto buttonsVec6 = eButtonsDataVec{
                                {eBuildingMode::none,
                                 eLanguage::zeusText(28, 137),
                                 p6, 0, 0, &coll.fPhilosophy, nullptr, p6spr},
                                {eBuildingMode::gymnasium,
                                 eLanguage::zeusText(28, 79),
                                 g6, cost13, 1, &coll.fGymnasium, nullptr},
                                {eBuildingMode::none,
                                 eLanguage::zeusText(28, 27),
                                 d6, 0, 2, &coll.fDrama, nullptr, d6spr},
                                {eBuildingMode::stadium,
                                 eLanguage::zeusText(28, 80),
                                 s6, cost14, 3, &coll.fStadium, nullptr}};
        ww6 = createDataWidget(mCultureDataW, buttonsVec6,
                               eLanguage::zeusText(88, 6));
    }



    const std::vector<eSPR> t7spr = {eSPR{eBuildingMode::templeZeus, eLanguage::zeusText(28, 84),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeZeus)},
                                     eSPR{eBuildingMode::templePoseidon, eLanguage::zeusText(28, 85),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templePoseidon)},
                                     eSPR{eBuildingMode::templeHades, eLanguage::zeusText(28, 95),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeHades)},
                                     eSPR{eBuildingMode::templeHera, eLanguage::zeusText(28, 96),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeHera)},
                                     eSPR{eBuildingMode::templeDemeter, eLanguage::zeusText(28, 86),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeDemeter)},
                                     eSPR{eBuildingMode::templeAthena, eLanguage::zeusText(28, 92),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeAthena)},
                                     eSPR{eBuildingMode::templeArtemis, eLanguage::zeusText(28, 88),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeArtemis)},
                                     eSPR{eBuildingMode::templeApollo, eLanguage::zeusText(28, 87),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeApollo)},
                                     eSPR{eBuildingMode::templeAtlas, eLanguage::zeusText(28, 97),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeAtlas)},
                                     eSPR{eBuildingMode::templeAres, eLanguage::zeusText(28, 89),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeAres)},
                                     eSPR{eBuildingMode::templeHephaestus, eLanguage::zeusText(28, 93),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeHephaestus)},
                                     eSPR{eBuildingMode::templeAphrodite, eLanguage::zeusText(28, 90),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeAphrodite)},
                                     eSPR{eBuildingMode::templeHermes, eLanguage::zeusText(28, 91),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeHermes)},
                                     eSPR{eBuildingMode::templeDionysus, eLanguage::zeusText(28, 94),
                                          eBuilding::sInitialMarbleCost(eBuildingType::templeDionysus)}};
    const auto t7 = [this, cmx, cmy, t7spr]() {
        openBuildWidget(cmx, cmy, t7spr);
    };

    const std::vector<eSPR> hs7spr = {eSPR{eBuildingMode::achillesHall, eLanguage::zeusText(185, 8)},
                                      eSPR{eBuildingMode::atalantaHall, eLanguage::zeusText(185, 14)},
                                      eSPR{eBuildingMode::bellerophonHall, eLanguage::zeusText(185, 15)},
                                      eSPR{eBuildingMode::herculesHall, eLanguage::zeusText(185, 9)},
                                      eSPR{eBuildingMode::jasonHall, eLanguage::zeusText(185, 10)},
                                      eSPR{eBuildingMode::odysseusHall, eLanguage::zeusText(185, 11)},
                                      eSPR{eBuildingMode::perseusHall, eLanguage::zeusText(185, 12)},
                                      eSPR{eBuildingMode::theseusHall, eLanguage::zeusText(185, 13)}};
    const auto hs7 = [this, cmx, cmy, hs7spr]() {
        openBuildWidget(cmx, cmy, hs7spr);
    };


    mMythDataW = new eMythologyDataWidget(*b, window());
    const auto buttonsVec7 = eButtonsDataVec{
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 83),
                             t7, 0, 0, &coll.fTemples,
                             &coll.fPoseidonTemples,
                             t7spr},
                            {eBuildingMode::none,
                             eLanguage::zeusText(28, 125),
                             hs7, 0, 1, &coll.fHeroShrines,
                             &coll.fPoseidonHeroShrines,
                             hs7spr}};
    const auto ww8 = createDataWidget(mMythDataW, buttonsVec7,
                                      eLanguage::zeusText(88, 7));


    const std::vector<eSPR> f8spr = {eSPR{eBuildingMode::wall, eLanguage::zeusText(28, 130)},
                                     eSPR{eBuildingMode::tower, eLanguage::zeusText(28, 132)},
                                     eSPR{eBuildingMode::gatehouse, eLanguage::zeusText(28, 131)}};
    const auto f8 = [this, cmx, cmy, f8spr]() {
        openBuildWidget(cmx, cmy, f8spr);
    };
    const std::vector<eSPR> mp8spr = {eSPR{eBuildingMode::armory, eLanguage::zeusText(28, 135)},
                                      eSPR{eBuildingMode::horseRanch, eLanguage::zeusText(28, 133)},
                                      eSPR{eBuildingMode::chariotFactory, eLanguage::zeusText(28, 212)},
                                      eSPR{eBuildingMode::triremeWharf, eLanguage::zeusText(28, 136)}};
    const auto mp8 = [this, cmx, cmy, mp8spr]() {
        openBuildWidget(cmx, cmy, mp8spr);
    };

    mMiltDataW = new eMilitaryDataWidget(*b, window());
    const auto buttonsVec8 = eButtonsDataVec{
                        {eBuildingMode::none,
                         eLanguage::zeusText(28, 139),
                         f8, 0, 0, &coll.fFortifications, nullptr, f8spr},
                        {eBuildingMode::none,
                         eLanguage::zeusText(28, 140),
                         mp8, 0, 1, &coll.fMilitaryProduction, nullptr, mp8spr}};
    const auto ww9 = createDataWidget(mMiltDataW, buttonsVec8,
                                      eLanguage::zeusText(88, 8));

    const std::vector<eSPR> bb9spr = {eSPR{eBuildingMode::park, eLanguage::zeusText(28, 128)},
                                      eSPR{eBuildingMode::waterPark, eLanguage::zeusText(28, 25)},
                                      eSPR{eBuildingMode::doricColumn, eLanguage::zeusText(28, 129)},
                                      eSPR{eBuildingMode::ionicColumn, eLanguage::zeusText(28, 145)},
                                      eSPR{eBuildingMode::corinthianColumn, eLanguage::zeusText(28, 146)},
                                      eSPR{eBuildingMode::avenue, eLanguage::zeusText(28, 118)},
                                      eSPR{eBuildingMode::boulevard, eLanguage::zeusText(28, 126)}};
    const auto bb9 = [this, cmx, cmy, bb9spr]() {
        openBuildWidget(cmx, cmy, bb9spr);
    };
    const std::vector<eSPR> r9spr = {eSPR{eBuildingMode::bench, eLanguage::zeusText(28, 127)},
                                     eSPR{eBuildingMode::birdBath, eLanguage::zeusText(28, 152)},
                                     eSPR{eBuildingMode::shortObelisk, eLanguage::zeusText(28, 24)},
                                     eSPR{eBuildingMode::tallObelisk, eLanguage::zeusText(28, 19)},
                                     eSPR{eBuildingMode::flowerGarden, eLanguage::zeusText(28, 15)},
                                     eSPR{eBuildingMode::gazebo, eLanguage::zeusText(28, 16)},
                                     eSPR{eBuildingMode::shellGarden, eLanguage::zeusText(28, 150)},
                                     eSPR{eBuildingMode::sundial, eLanguage::zeusText(28, 20)},
                                     eSPR{eBuildingMode::hedgeMaze, eLanguage::zeusText(28, 17)},
                                     eSPR{eBuildingMode::dolphinSculpture, eLanguage::zeusText(28, 148)},
                                     eSPR{eBuildingMode::orrery, eLanguage::zeusText(28, 149)},
                                     eSPR{eBuildingMode::spring, eLanguage::zeusText(28, 22)},
                                     eSPR{eBuildingMode::topiary, eLanguage::zeusText(28, 21)},
                                     eSPR{eBuildingMode::fishPond, eLanguage::zeusText(28, 18)},
                                     eSPR{eBuildingMode::baths, eLanguage::zeusText(28, 151)},
                                     eSPR{eBuildingMode::stoneCircle, eLanguage::zeusText(28, 23)}};
    const auto r9 = [this, cmx, cmy, r9spr]() {
        openBuildWidget(cmx, cmy, r9spr);
    };
    const std::vector<eSPR> m9spr = {eSPR{eBuildingMode::populationMonument, eLanguage::zeusText(198, 1)},
                                     eSPR{eBuildingMode::victoryMonument, eLanguage::zeusText(198, 2)},
                                     eSPR{eBuildingMode::colonyMonument, eLanguage::zeusText(198, 3)},
                                     eSPR{eBuildingMode::athleteMonument, eLanguage::zeusText(198, 4)},
                                     eSPR{eBuildingMode::conquestMonument, eLanguage::zeusText(198, 5)},
                                     eSPR{eBuildingMode::happinessMonument, eLanguage::zeusText(198, 6)},
                                     eSPR{eBuildingMode::heroicFigureMonument, eLanguage::zeusText(198, 7)},
                                     eSPR{eBuildingMode::diplomacyMonument, eLanguage::zeusText(198, 8)},
                                     eSPR{eBuildingMode::scholarMonument, eLanguage::zeusText(198, 9)},

                                     eSPR{eBuildingMode::aphroditeMonument, eLanguage::zeusText(198, 16)},
                                     eSPR{eBuildingMode::apolloMonument, eLanguage::zeusText(198, 13)},
                                     eSPR{eBuildingMode::aresMonument, eLanguage::zeusText(198, 15)},
                                     eSPR{eBuildingMode::artemisMonument, eLanguage::zeusText(198, 14)},
                                     eSPR{eBuildingMode::athenaMonument, eLanguage::zeusText(198, 18)},
                                     eSPR{eBuildingMode::atlasMonument, eLanguage::zeusText(198, 35)},
                                     eSPR{eBuildingMode::demeterMonument, eLanguage::zeusText(198, 12)},
                                     eSPR{eBuildingMode::dionysusMonument, eLanguage::zeusText(198, 20)},
                                     eSPR{eBuildingMode::hadesMonument, eLanguage::zeusText(198, 21)},
                                     eSPR{eBuildingMode::hephaestusMonument, eLanguage::zeusText(198, 19)},
                                     eSPR{eBuildingMode::heraMonument, eLanguage::zeusText(198, 34)},
                                     eSPR{eBuildingMode::hermesMonument, eLanguage::zeusText(198, 17)},
                                     eSPR{eBuildingMode::poseidonMonument, eLanguage::zeusText(198, 11)},
                                     eSPR{eBuildingMode::zeusMonument, eLanguage::zeusText(198, 10)}};
    const auto m9 = [this, cmx, cmy, m9spr]() {
        openBuildWidget(cmx, cmy, m9spr);
    };

    const std::vector<eSPR> p9spr = {eSPR{eBuildingMode::modestPyramid, eLanguage::zeusText(28, 100)},
                                     eSPR{eBuildingMode::pyramid, eLanguage::zeusText(28, 101)},
                                     eSPR{eBuildingMode::greatPyramid, eLanguage::zeusText(28, 102)},
                                     eSPR{eBuildingMode::majesticPyramid, eLanguage::zeusText(28, 103)},

                                     eSPR{eBuildingMode::smallMonumentToTheSky, eLanguage::zeusText(28, 104)},
                                     eSPR{eBuildingMode::monumentToTheSky, eLanguage::zeusText(28, 105)},
                                     eSPR{eBuildingMode::grandMonumentToTheSky, eLanguage::zeusText(28, 106)},

                                     eSPR{eBuildingMode::minorShrineAphrodite, eGod::sGodName(eGodType::aphrodite) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineApollo, eGod::sGodName(eGodType::apollo) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineAres, eGod::sGodName(eGodType::ares) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineArtemis, eGod::sGodName(eGodType::artemis) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineAthena, eGod::sGodName(eGodType::athena) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineAtlas, eGod::sGodName(eGodType::atlas) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineDemeter, eGod::sGodName(eGodType::demeter) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineDionysus, eGod::sGodName(eGodType::dionysus) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineHades, eGod::sGodName(eGodType::hades) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineHephaestus, eGod::sGodName(eGodType::hephaestus) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineHera, eGod::sGodName(eGodType::hera) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineHermes, eGod::sGodName(eGodType::hermes) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrinePoseidon, eGod::sGodName(eGodType::poseidon) + " " + eLanguage::zeusText(28, 107)},
                                     eSPR{eBuildingMode::minorShrineZeus, eGod::sGodName(eGodType::zeus) + " " + eLanguage::zeusText(28, 107)},

                                     eSPR{eBuildingMode::shrineAphrodite, eGod::sGodName(eGodType::aphrodite) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineApollo, eGod::sGodName(eGodType::apollo) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineAres, eGod::sGodName(eGodType::ares) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineArtemis, eGod::sGodName(eGodType::artemis) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineAthena, eGod::sGodName(eGodType::athena) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineAtlas, eGod::sGodName(eGodType::atlas) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineDemeter, eGod::sGodName(eGodType::demeter) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineDionysus, eGod::sGodName(eGodType::dionysus) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineHades, eGod::sGodName(eGodType::hades) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineHephaestus, eGod::sGodName(eGodType::hephaestus) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineHera, eGod::sGodName(eGodType::hera) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineHermes, eGod::sGodName(eGodType::hermes) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrinePoseidon, eGod::sGodName(eGodType::poseidon) + " " + eLanguage::zeusText(28, 108)},
                                     eSPR{eBuildingMode::shrineZeus, eGod::sGodName(eGodType::zeus) + " " + eLanguage::zeusText(28, 108)},

                                     eSPR{eBuildingMode::majorShrineAphrodite, eGod::sGodName(eGodType::aphrodite) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineApollo, eGod::sGodName(eGodType::apollo) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineAres, eGod::sGodName(eGodType::ares) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineArtemis, eGod::sGodName(eGodType::artemis) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineAthena, eGod::sGodName(eGodType::athena) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineAtlas, eGod::sGodName(eGodType::atlas) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineDemeter, eGod::sGodName(eGodType::demeter) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineDionysus, eGod::sGodName(eGodType::dionysus) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineHades, eGod::sGodName(eGodType::hades) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineHephaestus, eGod::sGodName(eGodType::hephaestus) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineHera, eGod::sGodName(eGodType::hera) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineHermes, eGod::sGodName(eGodType::hermes) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrinePoseidon, eGod::sGodName(eGodType::poseidon) + " " + eLanguage::zeusText(28, 109)},
                                     eSPR{eBuildingMode::majorShrineZeus, eGod::sGodName(eGodType::zeus) + " " + eLanguage::zeusText(28, 109)},

                                     eSPR{eBuildingMode::pyramidToThePantheon, eLanguage::zeusText(28, 110)},
                                     eSPR{eBuildingMode::altarOfOlympus, eLanguage::zeusText(28, 111)},
                                     eSPR{eBuildingMode::templeOfOlympus, eLanguage::zeusText(28, 112)},
                                     eSPR{eBuildingMode::observatoryKosmika, eLanguage::zeusText(28, 113)},
                                     eSPR{eBuildingMode::museumAtlantika, eLanguage::zeusText(28, 114)}};
    const auto p9 = [this, cmx, cmy, p9spr]() {
        openBuildWidget(cmx, cmy, p9spr);
    };

    mApplDataW = new eAppealDataWidget(*b, window());
    const auto buttonsVec = eButtonsDataVec{
                    {eBuildingMode::none,
                     eLanguage::zeusText(28, 142),
                     bb9, 0, 0, &coll.fBeautification, nullptr, bb9spr},
                    {eBuildingMode::none,
                     eLanguage::zeusText(28, 141),
                     r9, 0, 1, &coll.fRecreation, nullptr, r9spr},
                    {eBuildingMode::none,
                     eLanguage::zeusText(28, 157),
                     m9, 0, 2, &coll.fMonuments, nullptr, m9spr},
                    {eBuildingMode::none,
                     eLanguage::zeusText(28, 157),
                     p9, 0, 3, &coll.fPiramids,
                     nullptr,
                     p9spr}};
    const auto ww10 = createDataWidget(mApplDataW, buttonsVec,
                                      eLanguage::zeusText(88, 9));

    mOverDataW = new eOverviewDataWidget(*b, window());
    mMiniMap = new eMiniMap(window());
    mOverDataW->setMap(mMiniMap);
    mMiniMap->resize(dataWidWidth, 4*dataWidWidth/5);

    const auto ww11 = createDataWidgetBase(mOverDataW, mMiniMap,
                                           eLanguage::zeusText(88, 10));
    mWidgets.push_back({ww0, mPopDataW});
    mWidgets.push_back({ww1, mHusbDataW});
    mWidgets.push_back({ww2, mEmplDataW});
    mWidgets.push_back({www3, mStrgDataW});
    mWidgets.push_back({ww4, mHySaDataW});
    mWidgets.push_back({ww5, mAdminDataW});
    mWidgets.push_back({ww6, static_cast<eDataWidget*>(mCultureDataW)});
    mWidgets.push_back({ww7, static_cast<eDataWidget*>(mScienceDataW)});
    mWidgets.push_back({ww8, mMythDataW});
    mWidgets.push_back({ww9, mMiltDataW});
    mWidgets.push_back({ww10, mApplDataW});
    mWidgets.push_back({ww11, mOverDataW});

    for(const auto& ww : mWidgets) {
        const auto w = ww.fW;
        addWidget(w);
        w->move(wx, 12*mult);
        w->hide();
    }

    const int railW = 22*mult;
    const int railH = 20*mult;
    const auto b0 = addButton("population", railW, railH, mWidgets[0]);
    mPopulationButton = b0;
    const auto b1 = addButton("husbandry", railW, railH, mWidgets[1]);
    mHusbandryButton = b1;
    const auto b2 = addButton("industry", railW, railH, mWidgets[2]);
    mIndustryButton = b2;
    const auto b3 = addButton("distribution", railW, railH, mWidgets[3]);
    mDistributionButton = b3;
    const auto b4 = addButton("hygiene", railW, railH, mWidgets[4]);
    mHygieneSafetyButton = b4;
    const auto b5 = addButton("administration", railW, railH, mWidgets[5]);
    mAdministrationButton = b5;
    const auto b6a = addButton("culture", railW, railH, mWidgets[6]);
    mCultureButton = b6a;
    const auto b7 = addButton("mythology", railW, railH, mWidgets[8]);
    mMythologyButton = b7;
    const auto b8 = addButton("military", railW, railH, mWidgets[9]);
    mMilitaryButton = b8;
    const auto b9 = addButton("aesthetics", railW, railH, mWidgets[10]);
    mAesthethicsButton = b9;
    const auto b10 = addButton("overview", railW, railH, mWidgets[11]);
    mOverviewButton = b10;

    const auto setupButtonHover =
        [this](eCheckableButton* b0, const std::string& txt) {
        b0->setMouseEnterAction([this, txt]() {
            mNameLabel->setText(txt);
        });
        b0->setMouseLeaveAction([this]() {
            mNameLabel->setText("");
        });
    };

    setupButtonHover(b0, eLanguage::zeusText(88, 0));
    setupButtonHover(b1, eLanguage::zeusText(88, 1));
    setupButtonHover(b2, eLanguage::zeusText(88, 2));
    setupButtonHover(b3, eLanguage::zeusText(88, 3));
    setupButtonHover(b4, eLanguage::zeusText(88, 4));
    setupButtonHover(b5, eLanguage::zeusText(88, 5));
    setupButtonHover(b6a, eLanguage::zeusText(88, 6));
    setupButtonHover(b7, eLanguage::zeusText(88, 7));
    setupButtonHover(b8, eLanguage::zeusText(88, 8));
    setupButtonHover(b9, eLanguage::zeusText(88, 9));
    setupButtonHover(b10, eLanguage::zeusText(88, 10));

    b10->setChecked(true);
    ww11->setVisible(true);

    layoutButtons();

    const auto b6b = addButton("science", railW, railH, mWidgets[7]);
    setupButtonHover(b6b, eLanguage::zeusText(88, 24));
    b6b->hide();
    b6b->move(b6a->x(), b6a->y());
    mScienceButton = b6b;

    connectButtons();

    {
        // tools: road, roadblock, demolish, undo
        const auto tools = new eWidget(window());
        tools->setNoPadding();
        const int box = std::round(16.5*mult);
        const auto tool = [&](const char* icon, const std::string& tip,
                              const eBuildingMode mode) {
            const auto b = new ePanelActionButton(window(), icon);
            b->resize(box, box);
            b->setTooltip(tip);
            if(mode != eBuildingMode::none) {
                b->setPressAction([this, mode]() { setMode(mode); });
                b->setActivePredicate([this, mode]() { return mMode == mode; });
            }
            tools->addWidget(b);
            return b;
        };
        tool("road", eLanguage::zeusText(68, 20), eBuildingMode::road);
        tool("roadblock", eLanguage::zeusText(67, 27), eBuildingMode::roadblock);
        tool("demolish", eLanguage::zeusText(68, 30), eBuildingMode::erase);
        mUndoButton = tool("undo", eLanguage::zeusText(68, 10), eBuildingMode::none);
        mUndoButton->setEnabled(false);
        tools->resize(std::round(64.0*mult), box);
        tools->layoutHorizontally();
        tools->move(std::round(25.0*mult), std::round(217.8*mult));
        addWidget(tools);
    }

    {
        // Info / Map switch
        mTabs = new ePanelTabs(window());
        const auto txt = [](const char* key, const char* fallback) {
            const auto& s = eLanguage::text(key);
            return s.empty() ? std::string(fallback) : s;
        };
        mTabs->initialize(txt("panel_info", "Info"), txt("panel_map", "Map"));
        mTabs->resize(std::round(62.0*mult), std::round(9.5*mult));
        mTabs->move(std::round(26.5*mult), std::round(0.8*mult));
        mTabs->setChangeAction([this](const int i) { setMapMode(i == 1); });
        addWidget(mTabs);
    }
    {
        const auto butts = new eWidget(window());
        butts->setPadding(0);
        const int box = std::round(16.5*mult);
        const auto goals = new ePanelActionButton(window(), "goals");
        goals->resize(box, box);
        goals->setTooltip(eLanguage::zeusText(68, 9));
        goals->setPressAction(goalsView);
        butts->addWidget(goals);
        mRotateButton = new eRotateButton(window());
        mRotateButton->setModern(true);
        mRotateButton->resize(std::round(40.0*mult), box);
        butts->addWidget(mRotateButton);
        const auto world = new ePanelActionButton(window(), "world");
        world->resize(box, box);
        world->setTooltip(eLanguage::zeusText(68, 17));
        butts->addWidget(world);
        mWorldButton = world;
        butts->resize(std::round(84.0*mult), box);
        butts->layoutHorizontally();
        butts->move(std::round(4.5*mult), std::round(282.4*mult));
        addWidget(butts);
    }

    {
        mEventW = new eEventWidget(window());
        mEventW->setNoPadding();
        mEventW->setX(std::round(6.5*mult));
        mEventW->setY(std::round(243.5*mult));
        mEventW->setWidth(dataWidWidth);
        addWidget(mEventW);
    }

    {
        // messages: every message this session, with a count of new ones
        const int box = std::round(16.5*mult);
        const auto msgs = new ePanelActionButton(window(), "messages");
        msgs->resize(box, box);
        msgs->setTooltip(eLanguage::zeusText(68, 33));
        msgs->move(std::round(72.8*mult), std::round(251.3*mult));
        msgs->setPressAction([this]() {
            if(mGW) mGW->showMessageLog();
        });
        msgs->setBadge([this]() {
            return mGW ? mGW->unseenMessages() : 0;
        });
        addWidget(msgs);
    }

    mMapHome = ww11;
    mLastPage = ww11;

    // drawn over the content card after a category switch
    mVeil = new ePanelVeil(window());
    mVeil->resize(std::round(66.0*mult), std::round(202.0*mult));
    mVeil->move(std::round(24.0*mult), std::round(12.0*mult));
    addWidget(mVeil);

    mMiniMap->setBoard(b);

    updateButtonsVisibility();
}

void eGameMenu::setGameWidget(eGameWidget* const gw) {
    mGW = gw;
    mPopDataW->setGameWidget(gw);
    mHusbDataW->setGameWidget(gw);
    mEmplDataW->setGameWidget(gw);
    mStrgDataW->setGameWidget(gw);
    mApplDataW->setGameWidget(gw);
    mHySaDataW->setGameWidget(gw);
    mMiltDataW->setGameWidget(gw);
    mMythDataW->setGameWidget(gw);
    mAdminDataW->setGameWidget(gw);
    if(mCultureDataW) mCultureDataW->setGameWidget(gw);
    if(mScienceDataW) mScienceDataW->setGameWidget(gw);
    mOverDataW->setGameWidget(gw);

    mWorldButton->setPressAction([this]() {
        window()->showWorld();
    });

    mRotateButton->setDirectionSetter([gw](const eWorldDirection dir) {
        gw->setWorldDirection(dir);
    });
    updateButtonsVisibility();
}

eMiniMap* eGameMenu::miniMap() const {
    return mMiniMap;
}

void eGameMenu::pushEvent(const eEvent e, const eEventData& ed) {
    mEventW->pushEvent(e, ed);
}

void eGameMenu::tickEvents() {
    if(mEventW) {
        mEventW->tick();
    }
}

void eGameMenu::setViewTileHandler(const eViewTileHandler& h) {
    mEventW->setViewTileHandler(h);
}

void eGameMenu::closeBuildWidget() {
    if(!mBuildWidget) return;
    mBuildWidget->deleteLater();
    mBuildWidget = nullptr;
}

void eGameMenu::setBuildWidget(eBuildWidget* const bw) {
    closeBuildWidget();
    mBuildWidget = bw;
}

void eGameMenu::updateButtonsVisibility() {
    const auto cid = mGW ? mGW->viewedCity() :
                           eCityId::neutralFriendly;
    for(const auto s : mSubButtons) {
        s->updateVisible(cid, mShowAllPossibleBuildings);
    }
    const auto c = mBoard->boardCityWithId(cid);
    const bool science = c ? c->atlantean() : false;

    const auto pid = mBoard->cityIdToPlayerId(cid);
    const auto ppid = mBoard->personPlayer();
    const bool e = (c && pid == ppid) || mShowAllPossibleBuildings;

    mPopulationButton->setEnabled(e);
    mHusbandryButton->setEnabled(e);
    mIndustryButton->setEnabled(e);
    mDistributionButton->setEnabled(e);
    mHygieneSafetyButton->setEnabled(e);
    mAdministrationButton->setEnabled(e);
    mScienceButton->setEnabled(e);
    mCultureButton->setEnabled(e);
    mMythologyButton->setEnabled(e);
    mMilitaryButton->setEnabled(e);
    mAesthethicsButton->setEnabled(e);
    mOverviewButton->setEnabled(e);

    mScienceButton->setVisible(science);
    mCultureButton->setVisible(!science);
    if(science && mCultureButton->checked()) {
        mScienceButton->trigger();
    } else if(!science && mScienceButton->checked()) {
        mCultureButton->trigger();
    }
}

void eGameMenu::viewedCityChanged() {
    if(mEventW) {
        mEventW->clear();
    }
    mPopDataW->update();
    mHusbDataW->update();
    mEmplDataW->update();
    mStrgDataW->update();
    mApplDataW->update();
    mHySaDataW->update();
    mMiltDataW->update();
    mMythDataW->update();
    mAdminDataW->update();
    if(mCultureDataW) mCultureDataW->update();
    if(mScienceDataW) mScienceDataW->update();
    mOverDataW->update();
    updateButtonsVisibility();
    setMode(eBuildingMode::none);
}

void eGameMenu::setMode(const eBuildingMode mode) {
    closeBuildWidget();
    mMode = mode;
    if(mModeChangeAct) mModeChangeAct();
}

bool eGameMenu::mousePressEvent(const eMouseEvent& e) {
    closeBuildWidget();
    return eGameMenuBase::mouseEnterEvent(e);
}
