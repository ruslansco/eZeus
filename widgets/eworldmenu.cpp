#include "eworldmenu.h"

#include "textures/egametextures.h"

#include "ebutton.h"
#include "emainwindow.h"
#include "eworldgoodswidget.h"
#include "eworldtributewidget.h"
#include "egamewidget.h"
#include "engine/eworldboard.h"

#include "elanguage.h"
#include "epanelstyle.h"
#include "epanelwidgets.h"
#include "textures/egeometrybatch.h"

#include <cmath>

void eWorldMenu::initialize(const eAction& openRequest,
                            const eAction& openFulfill,
                            const eAction& openGift,
                            const eAction& openRaid,
                            const eAction& openConquer,
                            const bool showText) {
    int iRes;
    int mult;
    iResAndMult(iRes, mult);

    const auto& intrfc = eGameTextures::interface();
    const auto& coll = intrfc[iRes];
    const auto tex = coll.fWorldMenuBackground;
    setTexture(tex);    // gives the panel its width; paintEvent draws the new design
    setPadding(0);
    fitContent();
    mMult = mult;
    // on tall screens the panel runs to the bottom
    setHeight(std::max(height(), window()->height()));
    const int W = width();

    const auto tr = [](const char* key, const char* fallback) {
        const auto& t = eLanguage::text(key);
        return t.empty() ? std::string(fallback) : t;
    };
    const auto medal = [&](const std::string& icon, const double cx,
                           const double cy, const double d) {
        const auto b = new ePanelActionButton(window(), icon);
        const int s = std::round(d*mult);
        b->resize(s, s);
        b->move(std::round(cx*mult - s/2.), std::round(cy*mult - s/2.));
        addWidget(b);
        return b;
    };

    {
        // the attitude, between arrows that step through the cities
        const double cy = 74.5;
        const auto prev = medal("chevron_left", 10.5, cy, 15);
        prev->setTooltip(tr("world_prev_city", "Previous city"));
        prev->setPressAction([this]() { if(mCycle) mCycle(-1); });
        const auto next = medal("chevron", W/double(mult) - 10.5, cy, 15);
        next->setTooltip(tr("world_next_city", "Next city"));
        next->setPressAction([this]() { if(mCycle) mCycle(1); });
        prev->setVisible(showText);
        next->setVisible(showText);
    }

    {
        const double y1 = 243;
        const double y2 = 268.5;
        const double d = 23;
        const double c = W/double(mult)/2;
        mRequestButton = medal("request", c - 29, y1, d);
        mRequestButton->setTooltip(eLanguage::zeusText(44, 308));
        mFulfillButton = medal("fulfill", c, y1, d);
        mFulfillButton->setTooltip(eLanguage::zeusText(44, 310));
        mGiftButton = medal("gift", c + 29, y1, d);
        mGiftButton->setTooltip(eLanguage::zeusText(44, 311));
        mRaidButton = medal("raid", c - 14.5, y2, d);
        mRaidButton->setTooltip(eLanguage::zeusText(44, 312));
        mConquerButton = medal("conquer", c + 14.5, y2, d);
        mConquerButton->setTooltip(eLanguage::zeusText(44, 313));
        // choosing a colony puts its own text on the panel
        for(const auto b : {mRequestButton, mFulfillButton, mGiftButton,
                            mRaidButton, mConquerButton}) {
            b->setVisible(showText);
        }

        mRequestButton->setPressAction([this, openRequest]() {
            const bool editor = mBoard && mBoard->editorMode();
            if(editor) return;
            if(openRequest) openRequest();
        });
        mFulfillButton->setPressAction([this, openFulfill]() {
            const bool editor = mBoard && mBoard->editorMode();
            if(editor) return;
            if(openFulfill) openFulfill();
        });
        mGiftButton->setPressAction([this, openGift]() {
            const bool editor = mBoard && mBoard->editorMode();
            if(editor) return;
            if(openGift) openGift();
        });
        mRaidButton->setPressAction([this, openRaid]() {
            const bool editor = mBoard && mBoard->editorMode();
            if(editor) return;
            if(openRaid) openRaid();
        });
        mConquerButton->setPressAction([this, openConquer]() {
            const bool editor = mBoard && mBoard->editorMode();
            if(editor) return;
            if(openConquer) openConquer();
        });

        if(showText) {
            const auto back = new ePanelPillButton(window(), eLanguage::zeusText(47, 8));
            back->resize(W - std::round(12*mult), std::round(15*mult));
            back->move(std::round(6*mult), std::round(284*mult));
            back->setPressAction([this](){
                const bool editor = mBoard && mBoard->editorMode();
                if(editor) return;
                window()->showGame(static_cast<eGameBoard*>(nullptr),
                                   eGameWidgetSettings());
            });
            addWidget(back);
        }

        const auto wat = new eWidget(window());
        wat->setNoPadding();
        wat->resize(W - std::round(38*mult), std::round(15*mult));
        wat->move(std::round(19*mult), std::round(67*mult));
        addWidget(wat);

        mAttitudeLabel = new eLabel("unknown", window());
        mAttitudeLabel->setTooltip(eLanguage::zeusText(44, 333));
        mAttitudeLabel->setSmallFontSize();
        mAttitudeLabel->setYellowFontColor();
        mAttitudeLabel->fitContent();
        wat->addWidget(mAttitudeLabel);
        mAttitudeLabel->align(eAlignment::center);
    }

    {
        mRelationshipLabel = new eLabel("a", window());
        mRelationshipLabel->setNoPadding();
        mRelationshipLabel->setSmallFontSize();
        mRelationshipLabel->fitContent();
        addWidget(mRelationshipLabel);
        mRelationshipLabel->align(eAlignment::hcenter);
        const int rly = 16*mult;
        mRelationshipLabel->setY(rly);

        mNameLabel = new eLabel("a", window());
        mNameLabel->setNoPadding();
        mNameLabel->setFontRole(eFontRole::display);
        mNameLabel->setSmallFontSize();
        mNameLabel->setYellowFontColor();
        mNameLabel->fitContent();
        addWidget(mNameLabel);
        mNameLabel->align(eAlignment::hcenter);
        mNameLabel->setY(rly + mRelationshipLabel->height());

        mLeaderLabel = new eLabel("a", window());
        mLeaderLabel->setNoPadding();
        mLeaderLabel->setTinyFontSize();
        mLeaderLabel->fitContent();
        addWidget(mLeaderLabel);
        mLeaderLabel->align(eAlignment::hcenter);
        mLeaderLabel->setY(mNameLabel->y() + mNameLabel->height());
    }

    {
        mTextLabel = new eLabel(window());
        mTextLabel->setNoPadding();
        addWidget(mTextLabel);
        mTextLabel->setX(mult*10);
        mTextLabel->setY(mult*90);
        const int w = mult*75;
        mTextLabel->setWrapWidth(w);
        mTextLabel->setWrapAlignment(eAlignment::hcenter);
        mTextLabel->setWidth(w);
        mTextLabel->setHeight(mult*105);
        mTextLabel->setVisible(showText);
        mShowText = showText;
    }

    {
        mGoodsWidget = new eWorldGoodsWidget(window());
        addWidget(mGoodsWidget);
        mGoodsWidget->setX(mult*10);
        mGoodsWidget->setY(mult*90);

        mGoodsWidget->setWidth(mult*75);
        mGoodsWidget->setHeight(mult*105);

        mGoodsWidget->initialize();
    }

    {
        mTributeWidget = new eWorldTributeWidget(window());
        addWidget(mTributeWidget);

        mTributeWidget->setX(mult*7);
        mTributeWidget->setY(mult*205);

        mTributeWidget->setWidth(mult*84);
        mTributeWidget->setHeight(mult*21);

        mTributeWidget->initialize();
    }

    setCity(nullptr);
}

void eWorldMenu::setCity(const stdsptr<eWorldCity>& c) {
    if(!c && mShowText) {
        const auto text = eLanguage::zeusText(47, 5);
        mTextLabel->setText(text);
        mTextLabel->show();
    } else {
        mTextLabel->hide();
    }

    mCity = c;

    updateButtonsEnabled();
    updateLabels();

    if(mBoard) {
        const auto pid = mBoard->personPlayer();
        mGoodsWidget->setPlayerId(pid);
    }
    mGoodsWidget->setCity(c);
    mTributeWidget->setCity(c);
}

void eWorldMenu::setWorldBoard(eWorldBoard* const b) {
    mBoard = b;
}

void eWorldMenu::setText(const std::string& text) {
    setCity(nullptr);
    mTextLabel->setText(text);
    mTextLabel->show();
}

void eWorldMenu::updateLabels() const {
    if(!mCity) {
        mAttitudeLabel->setText("");
        mRelationshipLabel->setText("");
        mNameLabel->setText("");
        mLeaderLabel->setText("");
        return;
    }

    const auto rel = mCity->relationship();
    const auto type = mCity->type();
    const bool cc = mCity->isCurrentCity();
    const bool onBoardNeutral = mCity->isOnBoardNeutral();
    const bool onBoardColony = mCity->isOnBoardColony();
    mNameLabel->setText(mCity->name());
    const auto leader = eLanguage::zeusText(44, 328);
    if(onBoardNeutral) {
        mAttitudeLabel->setText("");
        mRelationshipLabel->setText("");
        mLeaderLabel->setText("");
    } else if(onBoardColony) {
        mAttitudeLabel->setText("");
        mLeaderLabel->setText("");
    } else {
        mLeaderLabel->setText(leader + " " + mCity->leader());
    }

    if(cc || onBoardColony) {
        mAttitudeLabel->setText("");
    } else {
        const auto ppid = mBoard->personPlayer();
        const auto at = mCity->attitudeClass(ppid);
        const auto atStr = eWorldCity::sAttitudeName(at);
        mAttitudeLabel->setText(atStr);
        mAttitudeLabel->fitContent();
        mAttitudeLabel->align(eAlignment::center);
    }

    {
        int group = -1;
        int string = -1;
        if(cc) {
            group = 47;
            string = 0;
        } else {
            switch(type) {
            case eCityType::parentCity:
                group = 39;
                string = 0;
                break;
            case eCityType::colony:
                group = 253;
                string = 3;
                break;
            case eCityType::foreignCity: {
                switch(rel) {
                case eForeignCityRelationship::vassal:
                    group = 253;
                    string = 2;
                    break;
                case eForeignCityRelationship::ally:
                    group = 253;
                    string = 0;
                    break;
                case eForeignCityRelationship::rival:
                    group = 253;
                    string = 1;
                    break;
                }
            } break;

            case eCityType::distantCity:
                group = 39;
                string = 4;
                break;
            case eCityType::enchantedPlace:
                group = 39;
                string = 5;
                break;
            case eCityType::destroyedCity:
                group = 39;
                string = 6;
                break;
            }
        }
        const auto relStr = eLanguage::zeusText(group, string);
        mRelationshipLabel->setText(relStr);
        mRelationshipLabel->fitContent();
        mRelationshipLabel->align(eAlignment::hcenter);
    }
}

void eWorldMenu::updateButtonsEnabled() const {
    if(!mCity) {
        mRequestButton->setEnabled(false);
        mFulfillButton->setEnabled(false);
        mGiftButton->setEnabled(false);
        mRaidButton->setEnabled(false);
        mConquerButton->setEnabled(false);
    } else {
        const bool cc = mCity->isCurrentCity();
        const auto rel = mCity->relationship();
        const auto type = mCity->type();
        const bool vassalOrColony = (type == eCityType::foreignCity &&
                                     rel == eForeignCityRelationship::vassal) ||
                                    type == eCityType::colony;
        const bool distant = type == eCityType::distantCity;
        const bool onBoard = mCity->isOnBoard();
        const bool onBoardNeutral = mCity->isOnBoardNeutral();
        const bool onBoardPlayerColony = mCity->isOnBoardColony();
        const auto ppid = mBoard->personPlayer();
        const bool ownedOnBoardColony = onBoardPlayerColony && mCity->playerId() == ppid;
        const bool onBoardEnemyColony = onBoardPlayerColony && !ownedOnBoardColony;

        mRequestButton->setEnabled(!distant && !cc &&
                                   !onBoardPlayerColony && !onBoardNeutral);
        mFulfillButton->setEnabled(!distant && !cc &&
                                   !onBoardPlayerColony && !onBoardNeutral);
        mGiftButton->setEnabled(!distant && !cc &&
                                !onBoardPlayerColony && !onBoardNeutral);
        mRaidButton->setEnabled(!vassalOrColony &&
                                !distant && !cc && !onBoard);

        const auto cids = mBoard->personPlayerCities();
        int nPlayerOnBoard = 0;
        for(const auto cid : cids) {
            const auto c = mBoard->cityWithId(cid);
            if(!c) continue;
            const bool ob = c->isOnBoard();
            if(!ob) continue;
            nPlayerOnBoard++;
        }
        const bool sendReinforcements = nPlayerOnBoard > 1 && (ownedOnBoardColony || cc);
        if(sendReinforcements) {
            mConquerButton->setEnabled(true);
            mConquerButton->setTooltip(eLanguage::zeusText(41, 7));
        } else {
            mConquerButton->setEnabled((!vassalOrColony || mCity->conqueredByRival() || onBoardEnemyColony) &&
                                       !distant && !cc && !ownedOnBoardColony &&
                                       !onBoardNeutral);
            mConquerButton->setTooltip(eLanguage::zeusText(44, 313));
        }
    }
}

void eWorldMenu::paintEvent(ePainter& p) {
    using namespace ePanel;
    const auto r = p.renderer();
    const float ox = p.x();
    const float oy = p.y();
    const float W = width();
    const float H = height();
    const float hair = std::max(1.f, u(.45));
    body(r, ox, oy, W, H, mMult);
    const float bottom = std::min(oy + H, float(window()->height())) - u(3);
    const float top = oy + u(304);
    emblemAt(r, ox + W/2 + u(.6), top, u(58), bottom - top, mMult);
    if(!mShowText) return;   // colony selection: its own content

    // name plate
    {
        const SDL_FRect f{ox + u(4), oy + u(7), W - u(8), u(52)};
        roundRect(r, f, u(4), SDL_Color{20, 36, 70, 150}, SDL_Color{8, 14, 32, 195});
        roundRect(r, SDL_FRect{f.x + 1, f.y + 1, f.w - 2, u(18)}, u(4),
                  SDL_Color{140, 180, 240, 26}, SDL_Color{140, 180, 240, 0});
        roundRect(r, f, u(4), SDL_Color{240, 198, 104, 175}, SDL_Color{150, 106, 34, 110}, hair);
        if(mCity) {
            diamond(r, f.x + u(6), f.y + u(6), u(1.1), SDL_Color{214, 176, 70, 200});
            diamond(r, f.x + f.w - u(6), f.y + u(6), u(1.1), SDL_Color{214, 176, 70, 200});
        }
    }
    // attitude between its arrows
    well(r, SDL_FRect{ox + u(19), oy + u(66.5), W - u(38), u(16)}, u(8), hair, true);
    // goods / text card
    {
        const SDL_FRect f{ox + u(4), oy + u(87), W - u(8), u(112)};
        roundRect(r, f, u(4), SDL_Color{20, 36, 70, 150}, SDL_Color{8, 14, 32, 195});
        roundRect(r, f, u(4), SDL_Color{240, 198, 104, 175}, SDL_Color{150, 106, 34, 110}, hair);
    }
    // tribute
    well(r, SDL_FRect{ox + u(4), oy + u(202), W - u(8), u(26)}, u(4), hair);
    // actions
    well(r, SDL_FRect{ox + u(4), oy + u(230), W - u(8), u(51)}, u(6), hair);
}
