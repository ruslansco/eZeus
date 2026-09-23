#include "emainmenu.h"

#include "ebutton.h"
#include "eframedbutton.h"
#include "eframedwidget.h"
#include "enamewidget.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "engine/eworldcity.h"
#include "egamedir.h"

#include <algorithm>


void eMainMenu::initialize(const eAction& newGameA,
                           const eAction& loadGameA,
                           const eAction& editGameA,
                           const eAction& settingsA,
                           const eAction& quitA,
                           const eAction& leaderA) {
    eMainMenuBase::initialize();

    const auto w = window();
    const auto res = resolution();
    const double mult = res.multiplier();

    // Load official 3D Zeus title emblem
    mLogoTex = std::make_shared<eTexture>();
    const std::string logoPath = eGameDir::texturesDir() + "Zeus_Title.png";
    mLogoTex->load(w->renderer(), logoPath);

    // Calculate dimensions
    const int logoW = static_cast<int>(400 * mult);
    const int logoH = static_cast<int>(213 * mult);
    const int logoTop = static_cast<int>(20 * mult);

    const int btnW = static_cast<int>(320 * mult);
    const int btnH = static_cast<int>(40 * mult);
    const int btnSpacing = static_cast<int>(12 * mult);

    // Classical menu stele/tablet container
    const auto menuPanel = new eFramedWidget(w);
    menuPanel->setType(eFrameType::outer);
    addWidget(menuPanel);

    const auto buttons = new eWidget(w);
    buttons->setNoPadding();
    menuPanel->addWidget(buttons);

    auto addMenuBtn = [&](const std::string& text, const eAction& a) {
        const auto b = new eFramedButton(w);
        b->setRenderBg(true);
        b->setUnderline(false);
        b->setSmallFontSize();
        b->setText(text);
        b->resize(btnW, btnH);
        b->setPressAction(a);
        buttons->addWidget(b);
        return b;
    };

    addMenuBtn(eLanguage::zeusText(1, 1), newGameA);
    addMenuBtn(eLanguage::zeusText(1, 3), loadGameA);
    addMenuBtn(eLanguage::zeusText(287, 3), editGameA);
    addMenuBtn(eLanguage::zeusText(2, 0), settingsA);
    addMenuBtn(eLanguage::zeusText(1, 5), quitA);

    // Stack all 5 buttons vertically with spacing
    buttons->stackVertically(btnSpacing);
    const int totalButtonsH = 5 * btnH + 4 * btnSpacing;
    buttons->resize(btnW, totalButtonsH);

    // Size menuPanel to enclose buttons with padding
    const int panelPadX = static_cast<int>(24 * mult);
    const int panelPadY = static_cast<int>(20 * mult);
    menuPanel->resize(btnW + 2 * panelPadX, totalButtonsH + 2 * panelPadY);
    buttons->setX(panelPadX);
    buttons->setY(panelPadY);

    menuPanel->align(eAlignment::hcenter);
    menuPanel->setY(logoTop + logoH + static_cast<int>(14 * mult));

    // Leader Profile Card (Top-Left)
    const auto leaderCard = new eFramedWidget(w);
    leaderCard->setType(eFrameType::outer);
    addWidget(leaderCard);

    const auto leaderInner = new eWidget(w);
    leaderInner->setNoPadding();
    leaderCard->addWidget(leaderInner);

    const std::string leaderStr = w->leader().empty() ? "None" : w->leader();
    const auto leaderLabel = new eLabel("LEADER: " + leaderStr, w);
    leaderLabel->setSmallFontSize();
    leaderLabel->setYellowFontColor();
    leaderLabel->fitContent();
    leaderInner->addWidget(leaderLabel);

    const auto switchBtn = new eFramedButton(w);
    switchBtn->setRenderBg(true);
    switchBtn->setUnderline(false);
    switchBtn->setVerySmallFontSize();
    switchBtn->setText(eLanguage::zeusText(292, 3)); // Roster / Leaders
    switchBtn->fitContent();
    switchBtn->resize(switchBtn->width() + static_cast<int>(18 * mult),
                      leaderLabel->height() + static_cast<int>(6 * mult));
    switchBtn->setPressAction(leaderA);
    leaderInner->addWidget(switchBtn);

    const int innerGap = static_cast<int>(14 * mult);
    leaderInner->stackHorizontally(innerGap);
    const int innerW = leaderLabel->width() + innerGap + switchBtn->width();
    const int innerH = std::max(leaderLabel->height(), switchBtn->height());
    leaderInner->resize(innerW, innerH);

    leaderLabel->setY((innerH - leaderLabel->height()) / 2);
    switchBtn->setY((innerH - switchBtn->height()) / 2);

    const int cardPadX = static_cast<int>(16 * mult);
    const int cardPadY = static_cast<int>(10 * mult);
    leaderCard->resize(innerW + 2 * cardPadX, innerH + 2 * cardPadY);
    leaderInner->setX(cardPadX);
    leaderInner->setY(cardPadY);

    leaderCard->setX(static_cast<int>(24 * mult));
    leaderCard->setY(static_cast<int>(20 * mult));

    // Bottom subtle footer
    const auto footer = new eLabel("eZeus HD • Master of Olympus & Poseidon", w);
    footer->setVerySmallFontSize();
    footer->fitContent();
    addWidget(footer);
    footer->align(eAlignment::hcenter);
    footer->setY(height() - footer->height() - static_cast<int>(10 * mult));
}

void eMainMenu::paintEvent(ePainter& p) {
    eMainMenuBase::paintEvent(p);
    if(mLogoTex && !mLogoTex->isNull()) {
        const auto res = resolution();
        const double mult = res.multiplier();
        const int lw = static_cast<int>(400 * mult);
        const int lh = static_cast<int>(213 * mult);
        const int lx = (width() - lw) / 2;
        const int ly = static_cast<int>(20 * mult);

        // Render clean, transparent 3D Zeus pediment logo
        p.drawTextureScaled(SDL_Rect{lx, ly, lw, lh}, mLogoTex);
    }
}

bool eMainMenu::mousePressEvent(const eMouseEvent& e) {
    (void)e;
    mPressed = true;
    return true;
}

bool eMainMenu::mouseReleaseEvent(const eMouseEvent& e) {
    (void)e;
    mPressed = false;
    return true;
}

bool eMainMenu::mouseMoveEvent(const eMouseEvent& e) {
    (void)e;
    return true;
}

bool eMainMenu::mouseEnterEvent(const eMouseEvent& e) {
    (void)e;
    mHover = true;
    return true;
}

bool eMainMenu::mouseLeaveEvent(const eMouseEvent& e) {
    (void)e;
    mHover = false;
    return true;
}
