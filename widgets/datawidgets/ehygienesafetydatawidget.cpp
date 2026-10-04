#include "ehygienesafetydatawidget.h"

#include "eviewmodebutton.h"
#include "widgets/emultilinelabel.h"
#include "widgets/elinewidget.h"
#include "engine/egameboard.h"

#include "elanguage.h"
#include "engine/ecitydata.h"

void eHygieneSafetyDataWidget::initialize() {
    mSeeWater = new eViewModeButton(
                     eLanguage::zeusText(14, 5),
                     eViewMode::water,
                     window());
    addViewButton(mSeeWater);


    mSeeHygiene = new eViewModeButton(
                     eLanguage::zeusText(14, 6),
                     eViewMode::hygiene,
                     window());
    addViewButton(mSeeHygiene);


    mSeeHazards = new eViewModeButton(
                     eLanguage::zeusText(14, 7),
                     eViewMode::hazards,
                     window());
    addViewButton(mSeeHazards);


    mSeeUnrest = new eViewModeButton(
                     eLanguage::zeusText(14, 8),
                     eViewMode::unrest,
                     window());

    addViewButton(mSeeUnrest);

    eDataWidget::initialize();

    const auto inner = innerWidget();
    const int iw = inner->width();

    const auto chtitle = new eLabel(window());
    chtitle->setVerySmallFontSize();
    chtitle->setNoPadding();
    chtitle->setText(eLanguage::zeusText(56, 1)); // city hygiene
    chtitle->fitContent();
    inner->addWidget(chtitle);
    chtitle->align(eAlignment::hcenter);

    mHygieneLabel = new eLabel(window());
    mHygieneLabel->setNoPadding();
    mHygieneLabel->setYellowFontColor();
    mHygieneLabel->setVerySmallFontSize();
    mHygieneLabel->setText(eLanguage::zeusText(56, 10)); // excellent
    mHygieneLabel->fitContent();
    inner->addWidget(mHygieneLabel);
    mHygieneLabel->align(eAlignment::hcenter);

    const auto spacer1 = new eWidget(window());
    spacer1->setHeight(spacing());
    inner->addWidget(spacer1);

    const auto l1 = new eLineWidget(window());
    l1->setNoPadding();
    l1->fitContent();
    l1->setWidth(iw);
    inner->addWidget(l1);

    const auto spacer2 = new eWidget(window());
    spacer2->setHeight(spacing());
    inner->addWidget(spacer2);

    {
        const auto unrestTitle = new eLabel(window());
        unrestTitle->setTinyFontSize();
        unrestTitle->setNoPadding();
        unrestTitle->setText(eLanguage::zeusText(56, 17)); // unrest
        unrestTitle->fitContent();
        inner->addWidget(unrestTitle);
        unrestTitle->align(eAlignment::hcenter);
    }
    {
        mUnrestLabel = new eLabel(window());
        mUnrestLabel->setWrapWidth(iw);
        mUnrestLabel->setWrapAlignment(eAlignment::hcenter);
        mUnrestLabel->setNoPadding();
        mUnrestLabel->setVerySmallFontSize();
        mUnrestLabel->setYellowFontColor();
        mUnrestLabel->setText(eLanguage::zeusText(56, 23)); // no unrest
        mUnrestLabel->fitContent();

        inner->addWidget(mUnrestLabel);
        mUnrestLabel->align(eAlignment::hcenter);
    }
    inner->stackVertically();
}

void eHygieneSafetyDataWidget::paintEvent(ePainter& p) {
    const bool update = ((mTime++) % 20) == 0;
    if(update) {
        const auto cid = viewedCity();
        mHygieneLabel->setText(eCityData::hygieneLevel(mBoard.health(cid)).text());
        mUnrestLabel->setText(eCityData::unrestLevel(mBoard.unrest(cid)).text());
        mUnrestLabel->fitContent();
        mUnrestLabel->align(eAlignment::hcenter);
    }
    eWidget::paintEvent(p);
}
