#include "eoverviewdatawidget.h"

#include "eviewmodebutton.h"

#include "widgets/egamewidget.h"
#include "widgets/eframedbutton.h"

#include "elanguage.h"
#include "engine/ecitydata.h"
#include "engine/egameboard.h"
#include "estringhelpers.h"
#include "buildings/eheroshall.h"
#include "gameEvents/ereceiverequestevent.h"
#include "gameEvents/etroopsrequestevent.h"
#include "widgets/elinewidget.h"
#include "widgets/eminimap.h"
#include "widgets/epanelstyle.h"

#include <algorithm>
#include <cmath>

class eOverviewEntry : public eWidget {
public:
    using eWidget::eWidget;

    void initialize(const std::string& title) {
        setNoPadding();
        mTitleLabel = new eLabel(window());
        mTitleLabel->setNoPadding();
        mTitleLabel->setTinyFontSize();
        mTitleLabel->setText(title);
        mTitleLabel->fitContent();
        addWidget(mTitleLabel);

        mValueLabel = new eLabel(window());
        mValueLabel->setYellowFontColor();
        mValueLabel->setNoPadding();
        mValueLabel->setTinyFontSize();
        addWidget(mValueLabel);

        fitHeight();
    }

    void setTitle(const std::string& title) {
        mTitleLabel->setText(title);
        mTitleLabel->fitContent();
    }

    void setText(const std::string& txt) {
        mValueLabel->setText(txt);
        mValueLabel->fitContent();
        mValueLabel->align(eAlignment::right);
        mHasValue = !txt.empty();
    }

    // 0 good, 1 needs an eye, 2 trouble: tints the badge behind the value
    void setSeverity(const int s) { mSeverity = s; }
protected:
    void paintEvent(ePainter& p) override {
        static const SDL_Color cols[3] = {{70, 200, 110, 255}, {240, 180, 60, 255}, {236, 76, 60, 255}};
        const auto c = cols[std::clamp(mSeverity, 0, 2)];
        const auto r = p.renderer();
        const float h = height();
        const float pulse = mSeverity == 2 ?
            static_cast<float>(.6 + .4*std::sin(ePanel::time()*4)) : 1.f;
        if(mHasValue) {
            const float pad = h*.2f;
            const float bw = mValueLabel->width() + 2*pad;
            const float x = std::min(p.x() + mValueLabel->x() - pad, p.x() + width() - bw);
            const SDL_FRect box{x, p.y() + h*.06f, bw, h*.88f};
            ePanel::roundRect(r, box, box.h/2, SDL_Color{c.r, c.g, c.b, static_cast<Uint8>(58*pulse)},
                              SDL_Color{c.r, c.g, c.b, static_cast<Uint8>(34*pulse)});
            ePanel::roundRect(r, box, box.h/2, SDL_Color{c.r, c.g, c.b, static_cast<Uint8>(150*pulse)},
                              SDL_Color{c.r, c.g, c.b, static_cast<Uint8>(110*pulse)}, std::max(1.f, h/14.f));
        } else {
            const float s = h*.2f;
            ePanel::glow(r, p.x() + width() - s*1.6f, p.y() + h/2, s*2.2f, s*2.2f,
                         SDL_Color{c.r, c.g, c.b, static_cast<Uint8>(110*pulse)}, true);
            ePanel::diamond(r, p.x() + width() - s*1.6f, p.y() + h/2, s, c);
        }
    }
private:
    bool mHasValue = false;
    int mSeverity = 0;
    eLabel* mTitleLabel = nullptr;
    eLabel* mValueLabel = nullptr;
};

void eOverviewDataWidget::initialize() {
    mSeeProblems = new eViewModeButton(
                     eLanguage::zeusText(14, 18),
                     eViewMode::problems,
                     window());
    addViewButton(mSeeProblems);

    mSeeRoads = new eViewModeButton(
                     eLanguage::zeusText(14, 19),
                     eViewMode::roads,
                     window());
    addViewButton(mSeeRoads);

    eDataWidget::initialize();
    {
        const auto& t = eLanguage::text("history_title");
        setMoreInfoIcon("chart", t.empty() ? "City History" : t);
        showMoreInfoButton();
        const auto& at = eLanguage::text("adv_button");
        addFooterPill(at.empty() ? "City advisor" : at, [this]() {
            if(const auto gw = gameWidget()) gw->showCityAdvisor();
        });
    }

    const auto inner = innerWidget();
    const int innerW = inner->width();

    mPopularity = new eOverviewEntry(window());
    mPopularity->setWidth(innerW);
    mPopularity->initialize(eLanguage::zeusText(61, 1)); // popularity
    inner->addWidget(mPopularity);

    mFoodLevel = new eOverviewEntry(window());
    mFoodLevel->setWidth(innerW);
    mFoodLevel->initialize(eLanguage::zeusText(61, 4)); // food level
    inner->addWidget(mFoodLevel);

    mUnemployment = new eOverviewEntry(window());
    mUnemployment->setWidth(innerW);
    mUnemployment->initialize(eLanguage::zeusText(61, 107)); // unemployment
    inner->addWidget(mUnemployment);

    mHygiene = new eOverviewEntry(window());
    mHygiene->setWidth(innerW);
    mHygiene->initialize(eLanguage::zeusText(61, 6)); // hygiene
    inner->addWidget(mHygiene);

    mUnrest = new eOverviewEntry(window());
    mUnrest->setWidth(innerW);
    mUnrest->initialize(eLanguage::zeusText(61, 7)); // unrest
    inner->addWidget(mUnrest);

    mFinances = new eOverviewEntry(window());
    mFinances->setWidth(innerW);
    mFinances->initialize(eLanguage::zeusText(61, 8)); // finances
    inner->addWidget(mFinances);

    const auto spacer1 = new eWidget(window());
    spacer1->setHeight(spacing());
    inner->addWidget(spacer1);

    const auto l1 = new eLineWidget(window());
    l1->setNoPadding();
    l1->fitContent();
    l1->setWidth(innerW);
    inner->addWidget(l1);

    const auto spacer2 = new eWidget(window());
    spacer2->setHeight(spacing());
    inner->addWidget(spacer2);

    const auto requestsLabel = new eLabel(window());
    requestsLabel->setTinyFontSize();
    requestsLabel->setNoPadding();
    requestsLabel->setText(eLanguage::zeusText(61, 195)); // requests
    requestsLabel->fitContent();
    inner->addWidget(requestsLabel);
    requestsLabel->align(eAlignment::hcenter);

    mQuestButtons = new eWidget(window());
    mQuestButtons->setNoPadding();
    mQuestButtons->setWidth(innerW);
    inner->addWidget(mQuestButtons);

    inner->stackVertically();

    updateRequestButtons();
}

void eOverviewDataWidget::shown() {
    eDataWidget::show();
    if(mMap) mMap->scheduleUpdate();
}

stdsptr<eTexture> sGodIcon(const eUIScale scale,
                           const eGodType god) {
    const auto& intrfc = eGameTextures::interface();
    const int iRes = static_cast<int>(scale);
    const auto& coll = intrfc[iRes];
    switch(god) {
    case eGodType::zeus:
        return coll.fZeusQuestIcon;
    case eGodType::poseidon:
        return coll.fPoseidonQuestIcon;
    case eGodType::demeter:
        return coll.fDemeterQuestIcon;
    case eGodType::apollo:
        return coll.fApolloQuestIcon;
    case eGodType::artemis:
        return coll.fArtemisQuestIcon;
    case eGodType::ares:
        return coll.fAresQuestIcon;
    case eGodType::aphrodite:
        return coll.fAphroditeQuestIcon;
    case eGodType::hermes:
        return coll.fHermesQuestIcon;
    case eGodType::athena:
        return coll.fAthenaQuestIcon;
    case eGodType::hephaestus:
        return coll.fHephaestusQuestIcon;
    case eGodType::dionysus:
        return coll.fDionysusQuestIcon;
    case eGodType::hades:
        return coll.fHadesQuestIcon;

    case eGodType::hera:
        return coll.fHeraQuestIcon;
    case eGodType::atlas:
        return coll.fAtlasQuestIcon;
    }
    return nullptr;
}

class eRequestButton : public eButtonBase {
protected:
    using eButtonBase::eButtonBase;

    using eViableChecker = std::function<bool()>;
    void initialize(const stdsptr<eTexture>& icon,
                    const std::string& txt,
                    const eViableChecker& checker) {
        setNoPadding();

        mViableChecker = checker;

        mStateLabel = new eLabel(window());
        mStateLabel->setNoPadding();
        addWidget(mStateLabel);
        setViable(false);
        mStateLabel->fitContent();

        const auto iconLabel = new eLabel(window());
        iconLabel->setNoPadding();
        iconLabel->setTexture(icon);
        iconLabel->fitContent();
        addWidget(iconLabel);

        const auto textLabel = new eLabel(window());
        textLabel->setTinyFontSize();
        textLabel->setNoPadding();
        textLabel->setText(txt);
        textLabel->fitContent();
        addWidget(textLabel);

        setMouseEnterAction([textLabel]() {
            textLabel->setYellowFontColor();
        });
        setMouseLeaveAction([textLabel]() {
            textLabel->setLightFontColor();
        });

        stackHorizontally();
        fitHeight();
        mStateLabel->align(eAlignment::vcenter);
        iconLabel->align(eAlignment::vcenter);
        textLabel->align(eAlignment::vcenter);
    }
protected:
    void paintEvent(ePainter& p) override {
        if(mViableChecker) {
            const bool v = mViableChecker();
            setViable(v);
        }
        eButtonBase::paintEvent(p);
    }
private:
    void setViable(const bool f) {
        const auto res = resolution();
        const auto scale = res.uiScale();
        const int iRes = static_cast<int>(scale);
        const auto& intrfc = eGameTextures::interface();
        const auto& texs = intrfc[iRes];
        const auto& coll = f ? texs.fRequestFulfilledBox :
                               texs.fRequestWaitingBox;
        const auto tex = coll.getTexture(0);
        mStateLabel->setTexture(tex);
    }

    eViableChecker mViableChecker;
    eLabel* mStateLabel = nullptr;
};

class eResourceRequestButton : public eRequestButton {
public:
    using eRequestButton::eRequestButton;

    void initialize(const eResourceType resource,
                    const stdsptr<eWorldCity>& city,
                    const eViableChecker& checker) {
        const auto cityName = city->name();
        const auto res = resolution();
        const auto uiScale = res.uiScale();
        const auto resIcon = eResourceTypeHelpers::icon(uiScale, resource);

        eRequestButton::initialize(resIcon, cityName, checker);
    }
};

class eTroopsRequestButton : public eRequestButton {
public:
    using eRequestButton::eRequestButton;

    void initialize(const stdsptr<eWorldCity>& city,
                    const eViableChecker& checker) {
        const auto cityName = city->name();
        const auto res = resolution();
        const auto uiScale = res.uiScale();
        const int iRes = static_cast<int>(uiScale);
        const auto& intrfc = eGameTextures::interface();
        const auto& texs = intrfc[iRes];
        const auto& troopsIcon = texs.fTroopsRequestIcon;
        eRequestButton::initialize(troopsIcon, cityName, checker);
    }
};

class eGodQuestButton : public eRequestButton {
public:
    using eRequestButton::eRequestButton;

    void initialize(const eGodType god,
                    const eViableChecker& checker) {
        const auto godName = eGod::sGodName(god);
        const auto res = resolution();
        const auto uiScale = res.uiScale();
        const auto godIcon = sGodIcon(uiScale, god);

        eRequestButton::initialize(godIcon, godName, checker);
    }
};

void eOverviewDataWidget::updateRequestButtons() {
    mQuestButtons->removeChildren();
    addGodQuests();
    addCityRequests();
    mQuestButtons->stackVertically();
    mQuestButtons->fitHeight();
}

void eOverviewDataWidget::setMap(eMiniMap* const map) {
    mMap = map;
}

void eOverviewDataWidget::paintEvent(ePainter& p) {
    const bool update = ((mTime++) % 20) == 0;
    if(update) {
        const auto cid = viewedCity();
        // The verdicts are shared with the Godot city window (engine/ecitydata).
        const auto show = [](eOverviewEntry* const e, const eCityVerdict& v) {
            e->setText(v.text());
            e->setSeverity(v.fSeverity);
        };
        show(mPopularity, eCityData::popularity(mBoard.popularity(cid)));
        if(const auto husbData = mBoard.husbandryData(cid)) {
            show(mFoodLevel, eCityData::foodLevel(husbData->canSupport(), mBoard.population(cid)));
        }
        if(const auto emplData = mBoard.employmentData(cid)) {
            const auto line = eCityData::employment(emplData->freeJobVacancies(), emplData->employable(), emplData->unemployed());
            mUnemployment->setTitle(eLanguage::zeusText(61, line.fTitle));
            mUnemployment->setText(line.fValue);
            mUnemployment->setSeverity(line.fSeverity);
        }
        show(mHygiene, eCityData::hygiene(mBoard.health(cid)));
        show(mUnrest, eCityData::unrest(mBoard.unrest(cid)));
        show(mFinances, eCityData::finances(mBoard.finances(cid).thisYear().netInOutFlow()));
    }
    eWidget::paintEvent(p);
}

bool sHeroReady(eGameBoard& board, const eHeroType hero) {
    eHerosHall* hh = nullptr;
    const auto cids = board.personPlayerCitiesOnBoard();
    for(const auto cid : cids) {
        hh = board.heroHall(cid, hero);
        if(hh) break;
    }
    if(!hh) return false;
    const auto s = hh->stage();
    return s == eHeroSummoningStage::arrived;
}

void eOverviewDataWidget::addGodQuests() {
    const auto pid = mBoard.personPlayer();
    const auto& qs = mBoard.godQuests(pid);
    for(const auto qq : qs) {
        const auto q = qq->godQuest();
        const auto god = q.fGod;
        const auto b = new eGodQuestButton(window());
        b->setWidth(mQuestButtons->width());
        b->initialize(god, [this, q]() {
            return sHeroReady(mBoard, q.fHero);
        });
        b->setPressAction([this, q, qq, pid]() {
            eHerosHall* hh = nullptr;
            const auto cids = mBoard.personPlayerCitiesOnBoard();
            for(const auto cid : cids) {
                hh = mBoard.heroHall(cid, q.fHero);
                if(hh) break;
            }
            const auto heroName = eHero::sHeroName(q.fHero);
            const auto gw = gameWidget();
            std::string heroNeededTmpl;
            eStringHelpers::replace(heroNeededTmpl, "[hero_name]", heroName);
            if(hh) {
                const auto s = hh->stage();
                if(s == eHeroSummoningStage::arrived) {
                    const auto acceptA = [qq]() {
                        qq->fulfill();
                    };
                    const auto title = eLanguage::zeusText(185, 121);
                    auto text = eLanguage::zeusText(185, 122);
                    eStringHelpers::replace(text, "[hero_name]", heroName);
                    const auto questName = q.name();
                    eStringHelpers::replace(text, "[god_quest]", questName);
                    gw->showQuestion(title, text, acceptA);
                } else {
                    gw->showTip(pid, heroNeededTmpl);
                }
            } else {
                gw->showTip(pid, heroNeededTmpl);
            }
        });
        mQuestButtons->addWidget(b);
    }
}

void eOverviewDataWidget::addCityRequests() {
    const auto pid = mBoard.personPlayer();
    const auto& qs = mBoard.cityRequests(pid);
    for(const auto& qq : qs) {
        const auto q = qq->cityRequest();
        const auto b = new eResourceRequestButton(window());
        b->setWidth(mQuestButtons->width());
        b->initialize(q.fType, q.fCity, [this, q]() {
            const auto cids = mBoard.personPlayerCitiesOnBoard();
            for(const auto cid : cids) {
                const auto count = mBoard.resourceCount(cid, q.fType);
                if(count >= q.fCount) return true;
            }
            return false;
        });
        b->setPressAction([this, q, qq, pid]() {
            const auto gw = gameWidget();
            const auto cids = mBoard.personPlayerCitiesOnBoard();
            for(const auto cid : cids) {
                const auto count = mBoard.resourceCount(cid, q.fType);
                if(count >= q.fCount) {
                    const auto acceptA = [qq, cid]() {
                        qq->dispatch(cid);
                    };
                    const auto title = eLanguage::zeusText(5, 6); // Request
                    const auto text = eLanguage::zeusText(5, 7); // Dispatch goods?
                    gw->showQuestion(title, text, acceptA);
                } else {
                    const auto tip = eLanguage::zeusText(5, 9); // You do not have enough to fulfill the request
                    gw->showTip(pid, tip);
                }
            }
        });
        mQuestButtons->addWidget(b);
    }
    const auto& qqs = mBoard.cityTroopsRequests(pid);
    for(const auto& qq : qqs) {
        const auto b = new eTroopsRequestButton(window());
        b->setWidth(mQuestButtons->width());
        b->initialize(qq->city(), [this]() {
            const auto cids = mBoard.personPlayerCitiesOnBoard();
            for(const auto cid : cids) {
                const auto& bs = mBoard.banners(cid);
                for(const auto& b : bs) {
                    const bool a = b->isAbroad();
                    if(!a) return true;
                }
                const auto hs = mBoard.heroHalls(cid);
                for(const auto h : hs) {
                    const bool a = h->heroOnQuest();
                    if(!a) return true;
                }
            }
            return false;
        });
        b->setPressAction([qq]() {
            qq->dispatch();
        });
        mQuestButtons->addWidget(b);
    }
}

void eOverviewDataWidget::openMoreInfoWiget() {
    if(const auto gw = gameWidget()) gw->showCityHistory();
}
