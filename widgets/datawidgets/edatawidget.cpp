#include "edatawidget.h"

#include "engine/ecitydata.h"

#include "eviewmodebutton.h"
#include "widgets/ebasicbutton.h"
#include "widgets/epanelwidgets.h"
#include "textures/egametextures.h"
#include "elanguage.h"
#include "engine/egameboard.h"

eDataWidget::eDataWidget(eGameBoard& b, eMainWindow* const w) :
    eWidget(w), mBoard(b) {}

void eDataWidget::initialize() {
    int h = 0;
    for(const auto b : mButtons) {
        addWidget(b);
        b->align(eAlignment::hcenter);
        h += b->height();
    }

    const int pp = spacing();
    const auto space = new eWidget(window());
    space->setPadding(pp);
    space->fitContent();
    addWidget(space);

    const auto frame = new eFramedWidget(window());
    frame->setType(eFrameType::inner);
    frame->setHeight(height() - h + pp);
    frame->setWidth(width());
    frame->setTinyPadding();
    addWidget(frame);

    mInnerWidget = new eWidget(window());
    const int hhh = frame->height() - 2*pp;
    mInnerWidget->setHeight(hhh);
    const int www = frame->width() - 2*pp;
    mInnerWidget->setWidth(www);
    mInnerWidget->setNoPadding();
    frame->addWidget(mInnerWidget);
    mInnerWidget->move(pp, pp);

    {
        // same footprint as the original magnifier sprite
        const int iRes = static_cast<int>(resolution().uiScale());
        const auto& tex = eGameTextures::interface()[iRes].fMoreInfo.getTexture(0);
        const auto b = new ePanelActionButton(window(), "more");
        b->resize(tex ? tex->width() : 20, tex ? tex->height() : 20);
        mMoreInfo = b;
    }
    frame->addWidget(mMoreInfo);
    mMoreInfo->align(eAlignment::right | eAlignment::bottom);
    mMoreInfo->move(mMoreInfo->x() - pp, mMoreInfo->y() - pp);
    mMoreInfo->setPressAction([this]() {
        openMoreInfoWiget();
    });
    mMoreInfo->setTooltip(eLanguage::zeusText(51, 79));
    mMoreInfo->hide();

    stackVertically();
    setNoPadding();
    fitContent();
}

void eDataWidget::setGameWidget(eGameWidget* const gw) {
    mGW = gw;
    for(const auto b : mButtons) {
        b->setGameWidget(gw);
    }
}

void eDataWidget::shown() {
    mTime = 0;
}

void eDataWidget::update() {
    mTime = 0;
}

void eDataWidget::addViewButton(eViewModeButton* const b) {
    mButtons.push_back(b);
}

int eDataWidget::spacing() const {
    const auto res = resolution();
    const double m = res.multiplier();
    return 3*m;
}

void eDataWidget::showMoreInfoButton() {
    mMoreInfo->show();
}

void eDataWidget::setMoreInfoIcon(const std::string& icon, const std::string& tooltip) {
    if(const auto b = dynamic_cast<ePanelActionButton*>(mMoreInfo)) b->setIcon(icon);
    mMoreInfo->setTooltip(tooltip);
}

int eDataWidget::sCoverageToText(const int c) {
    return eCityData::coverageText(c);
}

eCityId eDataWidget::viewedCity() {
    auto cid = mGW->viewedCity();
    const auto ppid = mBoard.personPlayer();
    const auto pid = mBoard.cityIdToPlayerId(cid);
    if(ppid != pid) {
        cid = lastPersonCityId();
    } else {
        setLastPersonCityId(cid);
    }
    return cid;
}

void eDataWidget::addFooterPill(const std::string& text, const eAction& a) {
    const auto frame = mMoreInfo->parent();
    if(!frame) return;
    const int pp = spacing();
    const auto b = new ePanelPillButton(window(), text);
    const int h = mMoreInfo->height();
    b->resize(frame->width() - mMoreInfo->width() - 4*pp, h);
    frame->addWidget(b);
    b->move(pp + pp/2, mMoreInfo->y());
    b->setPressAction(a);
}
