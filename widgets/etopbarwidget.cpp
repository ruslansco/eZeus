#include "etopbarwidget.h"
#include "epanelstyle.h"

#include <cmath>

#include "engine/egameboard.h"
#include "engine/boardData/epopulationdata.h"
#include "textures/egametextures.h"
#include "ebutton.h"
#include "edatewidget.h"
#include "egamewidget.h"

#include "emainwindow.h"
#include "eweather.h"

namespace {
// The season, or the weather when it is not fair, beside the date.
class eWeatherBadge : public eWidget {
public:
    using eWidget::eWidget;
protected:
    void paintEvent(ePainter& p) override {
        const auto icon = eWeather::iconName();
        const auto tip = eWeather::description();
        if(tip != mTip) {
            mTip = tip;
            setTooltip(tip);
        }
        const int px = std::min(width(), height());
        ePanel::drawIcon(p.renderer(), icon, p.x() + width()/2.f,
                         p.y() + height()/2.f, px, ePanel::kGold);
    }
private:
    std::string mTip;
};
}

// ============================================================
//  eSpeedControlWidget — graphical speed indicator
// ============================================================

void eSpeedControlWidget::initialize(int mult) {
    mMult = mult;
    setPadding(0);

    // Layout: [Pause] sep [>] sep [>>] sep [>>>] sep [>>>>]
    // Each triangle is ~sz wide, pause icon is ~sz wide
    const int sz = 5 * mult;      // icon height/width unit
    const int gap = 2 * mult;     // gap between buttons
    const int sepW = 1 * mult;    // separator width
    const int triW = sz;          // single triangle width
    const int pauseW = sz;        // pause icon width

    int x = gap;

    // Button 0: Pause  ||
    mBtnRegions[0] = {x, pauseW};
    x += pauseW + gap + sepW + gap;

    // Button 1: Slow  >
    mBtnRegions[1] = {x, triW};
    x += triW + gap;

    // Button 2: Normal  >>
    mBtnRegions[2] = {x, static_cast<int>(triW * 1.6)};
    x += static_cast<int>(triW * 1.6) + gap;

    // Button 3: Fast  >>>
    mBtnRegions[3] = {x, static_cast<int>(triW * 2.2)};
    x += static_cast<int>(triW * 2.2) + gap;

    // Button 4: Very Fast  >>>>
    mBtnRegions[4] = {x, static_cast<int>(triW * 2.8)};
    x += static_cast<int>(triW * 2.8) + gap;

    // Speed text readout
    const int textW = static_cast<int>(26 * mult);
    mSpeedTextRegion = {x, textW};
    x += textW + gap;

    setWidth(x);
    setHeight(sz + 4 * mult);
}

void eSpeedControlWidget::setState(eSpeedState state) {
    mState = state;
}

int eSpeedControlWidget::hitTest(int mx, int my) const {
    for(int i = 0; i < 5; i++) {
        const auto& r = mBtnRegions[i];
        if(mx >= r.x && mx < r.x + r.w) {
            return i;
        }
    }
    return -1;
}

void eSpeedControlWidget::drawPauseIcon(ePainter& p, int x, int cy,
                                         int sz, const SDL_Color& color) const {
    const int barW = std::max(2, sz / 4);
    const int barH = sz;
    const int gap = std::max(2, sz / 4);
    const int halfH = barH / 2;

    // Two vertical bars
    SDL_Rect bar1{x, cy - halfH, barW, barH};
    p.fillRect(bar1, color);

    SDL_Rect bar2{x + barW + gap, cy - halfH, barW, barH};
    p.fillRect(bar2, color);
}

void eSpeedControlWidget::drawTriangles(ePainter& p, int x, int cy,
                                         int sz, int count,
                                         const SDL_Color& color) const {
    const int triW = static_cast<int>(sz * 0.7);
    const int overlap = std::max(1, triW / 4);
    const int halfH = sz / 2;

    for(int i = 0; i < count; i++) {
        const int tx = x + i * (triW - overlap);
        // Filled triangle pointing right using horizontal scanlines
        // Top vertex: (tx, cy - halfH), Bottom: (tx, cy + halfH), Tip: (tx+triW, cy)
        for(int row = -halfH; row <= halfH; row++) {
            // Linearly interpolate width based on distance from center
            const double frac = 1.0 - std::abs(static_cast<double>(row)) / halfH;
            const int rowW = std::max(1, static_cast<int>(triW * frac));
            SDL_Rect line{tx, cy + row, rowW, 1};
            p.fillRect(line, color);
        }
    }
}

void eSpeedControlWidget::paintEvent(ePainter& p) {
    const int sz = 5 * mMult;
    const int cy = height() / 2;   // vertical center

    // Colors
    const SDL_Color gold       = {212, 175, 55, 255};    // Active gold
    const SDL_Color brightGold = {255, 223, 100, 255};   // Hover gold
    const SDL_Color dimGray    = {100, 105, 115, 160};   // Inactive
    const SDL_Color sepColor   = {80, 90, 100, 120};     // Separator

    // Determine active button index
    int activeBtn = -1;
    switch(mState) {
    case eSpeedState::paused: activeBtn = 0; break;
    case eSpeedState::normal: activeBtn = 1; break;
    case eSpeedState::fast:   activeBtn = 2; break;
    case eSpeedState::vfast:  activeBtn = 3; break;
    case eSpeedState::max:    activeBtn = 4; break;
    }

    auto colorForBtn = [&](int idx) -> SDL_Color {
        if(idx == activeBtn) return gold;
        if(mHovered && idx == mHoveredBtn) return brightGold;
        return dimGray;
    };

    // Draw separator line between pause and speed buttons
    const int sepX = (mBtnRegions[0].x + mBtnRegions[0].w +
                      mBtnRegions[1].x) / 2;
    const int sepH = sz;
    SDL_Rect sepRect{sepX, cy - sepH/2, std::max(1, mMult/2 + 1), sepH};
    p.fillRect(sepRect, sepColor);

    // Draw pause icon
    drawPauseIcon(p, mBtnRegions[0].x, cy, sz, colorForBtn(0));

    // Draw speed triangles: 1, 2, 3, 4 triangles
    drawTriangles(p, mBtnRegions[1].x, cy, sz, 1, colorForBtn(1));
    drawTriangles(p, mBtnRegions[2].x, cy, sz, 2, colorForBtn(2));
    drawTriangles(p, mBtnRegions[3].x, cy, sz, 3, colorForBtn(3));
    drawTriangles(p, mBtnRegions[4].x, cy, sz, 4, colorForBtn(4));

    // Draw current speed readout text
    std::string speedStr;
    switch(mState) {
    case eSpeedState::paused: speedStr = "PAUSED"; break;
    case eSpeedState::normal: speedStr = "100%";   break;
    case eSpeedState::fast:   speedStr = "250%";   break;
    case eSpeedState::vfast:  speedStr = "500%";   break;
    case eSpeedState::max:    speedStr = "MAX";    break;
    }

    auto font = eFonts::labelFont(resolution().verySmallFontSize());
    p.setFont(font);
    const int textY = (height() - resolution().verySmallFontSize()) / 2;
    p.drawText(mSpeedTextRegion.x + 2 * mMult, textY, speedStr,
               mState == eSpeedState::paused ? eFontColor::yellow : eFontColor::light);
}

bool eSpeedControlWidget::mousePressEvent(const eMouseEvent& e) {
    const int btn = hitTest(e.x(), e.y());
    switch(btn) {
    case 0: if(mPauseAction)  mPauseAction();  return true;
    case 1: if(mNormalAction) mNormalAction(); return true;
    case 2: if(mFastAction)   mFastAction();   return true;
    case 3: if(mVFastAction)  mVFastAction();  return true;
    case 4: if(mMaxAction)    mMaxAction();    return true;
    }
    return false;
}

bool eSpeedControlWidget::mouseEnterEvent(const eMouseEvent& e) {
    mHovered = true;
    mHoveredBtn = hitTest(e.x(), e.y());
    return false;
}

bool eSpeedControlWidget::mouseLeaveEvent(const eMouseEvent& e) {
    (void)e;
    mHovered = false;
    mHoveredBtn = -1;
    return false;
}

bool eSpeedControlWidget::mouseMoveEvent(const eMouseEvent& e) {
    mHoveredBtn = hitTest(e.x(), e.y());
    return false;
}

// ============================================================
//  eTopBarWidget
// ============================================================

void eTopBarWidget::initialize() {
    const auto& intrfc = eGameTextures::interface();
    const auto uiScale = resolution().uiScale();
    const int icoll = static_cast<int>(uiScale);
    const int mult = icoll + 1;
    const auto& coll = intrfc[icoll];
    setPadding(0);

    const auto s0 = new eWidget(window());
    s0->setWidth(mult*20);

    mDrachmasWidget = new eTopWidget(window());
    mDrachmasWidget->initialize(coll.fDrachmasTopMenu, "-");

    const auto s1 = new eWidget(window());
    s1->setWidth(mult*20);

    mCityLabel = new eLabel("-", window());
    mCityLabel->setSmallFontSize();
    mCityLabel->setNoPadding();
    mCityLabel->fitContent();

    const auto s2 = new eWidget(window());
    s2->setWidth(mult*20);

    mPopulationWidget = new eTopWidget(window());
    mPopulationWidget->initialize(coll.fPopulationTopMenu, "-");

    const auto s3 = new eWidget(window());
    s3->setWidth(mult*20);

    mDateLabel = new eButton(window());
    mDateLabel->setPressAction([this]() {
        if(!mBoard) return;
        const auto dw = new eDateWidget(window());
        dw->initialize([this](const eDate& d) {
            mBoard->setDate(d);
            mDateLabel->setText(d.shortString());
        }, false);
        dw->setDate(mBoard->date());
        window()->execDialog(dw);
        dw->align(eAlignment::center);
    });
    const eDate date(30, eMonth::january, -1500);
    mDateLabel->setSmallFontSize();
    mDateLabel->setText(date.shortString());
    mDateLabel->fitContent();
    mDateLabel->setEnabled(false);

    const auto s35 = new eWidget(window());
    s35->setWidth(mult*3);
    const auto weather = new eWeatherBadge(window());
    weather->setNoPadding();
    weather->resize(std::round(mult*7.5), std::round(mult*7.5));

    const auto s4 = new eWidget(window());
    s4->setWidth(mult*8);

    // Create graphical speed controls
    createSpeedControls();

    const auto s5 = new eWidget(window());
    s5->setWidth(mult*15);

    addWidget(s0);
    addWidget(mCityLabel);
    addWidget(s1);
    addWidget(mDrachmasWidget);
    addWidget(s2);
    addWidget(mPopulationWidget);
    addWidget(s3);
    addWidget(mDateLabel);
    addWidget(s35);
    addWidget(weather);
    addWidget(s4);
    addWidget(mSpeedControl);
    addWidget(s5);

    setHeight(12*mult);

    mCityLabel->align(eAlignment::vcenter);
    mDrachmasWidget->align(eAlignment::vcenter);
    mPopulationWidget->align(eAlignment::vcenter);
    mDateLabel->align(eAlignment::vcenter);
    weather->align(eAlignment::vcenter);
    mSpeedControl->align(eAlignment::vcenter);

    layoutHorizontally();
}

void eTopBarWidget::createSpeedControls() {
    const auto uiScale = resolution().uiScale();
    const int icoll = static_cast<int>(uiScale);
    const int mult = icoll + 1;

    mSpeedControl = new eSpeedControlWidget(window());
    mSpeedControl->initialize(mult);

    // Wire up press actions
    mSpeedControl->setPauseAction([this]() {
        if(!mGW) return;
        mGW->switchPause();
    });

    mSpeedControl->setNormalAction([this]() {
        if(!mGW) return;
        if(mGW->isPaused()) mGW->switchPause();
        mGW->setSpeedId(0);
    });

    mSpeedControl->setFastAction([this]() {
        if(!mGW) return;
        if(mGW->isPaused()) mGW->switchPause();
        mGW->setSpeedId(1);
    });

    mSpeedControl->setVFastAction([this]() {
        if(!mGW) return;
        if(mGW->isPaused()) mGW->switchPause();
        mGW->setSpeedId(2);
    });

    mSpeedControl->setMaxAction([this]() {
        if(!mGW) return;
        if(mGW->isPaused()) mGW->switchPause();
        mGW->setSpeedId(3);
    });

    updateSpeedControls();
}

void eTopBarWidget::updateSpeedControls() {
    if(!mGW || !mSpeedControl) return;

    const bool paused = mGW->isPaused();
    const int sid = mGW->speedId();

    using S = eSpeedControlWidget::eSpeedState;

    if(paused) {
        mSpeedControl->setState(S::paused);
    } else if(sid == 0) {
        mSpeedControl->setState(S::normal);
    } else if(sid == 1) {
        mSpeedControl->setState(S::fast);
    } else if(sid == 2) {
        mSpeedControl->setState(S::vfast);
    } else {
        mSpeedControl->setState(S::max);
    }
}

void eTopBarWidget::setBoard(eGameBoard* const board) {
    mBoard = board;
}

void eTopBarWidget::setGameWidget(eGameWidget* const gw) {
    mGW = gw;
    updateSpeedControls();
}

void eTopBarWidget::paintEvent(ePainter& p) {
    if(mBoard) {
        const auto cid = mGW->viewedCity();
        const auto pid = mBoard->personPlayer();
        const auto& wb = mBoard->world();
        const auto c = wb.cityWithId(cid);

        const auto label = c ? c->name() : "-";
        mCityLabel->setText(label);
        mCityLabel->fitContent();

        const auto popData = mBoard->populationData(cid);
        if(popData) {
            const int pop = popData->population();
            mPopulationWidget->setText(std::to_string(pop));
        } else {
            mPopulationWidget->setText("-");
        }

        const int d = mBoard->drachmas(pid);
        mDrachmasWidget->setText(std::to_string(d));

        mDateLabel->setText(mBoard->date().shortString());
        mDateLabel->setEnabled(mBoard->editorMode());

        // lapis strip with a gold hairline, matching the side panel
        const auto rend = p.renderer();
        const float x0 = p.x(), y0 = p.y(), w = width(), h = height();
        if(const auto t = ePanel::lapis(rend)) {
            int tw = 0;
            int th = 0;
            SDL_QueryTexture(t, nullptr, nullptr, &tw, &th);
            for(int x = 0; x < w; x += tw) {
                const int cw = std::min<int>(tw, w - x);
                const SDL_Rect src{0, 0, cw, std::min<int>(th, h)};
                const SDL_Rect dst{static_cast<int>(x0) + x, static_cast<int>(y0), cw, std::min<int>(th, h)};
                SDL_RenderCopy(rend, t, &src, &dst);
            }
        }
        ePanel::gradient(rend, SDL_FRect{x0, y0, w, h}, SDL_Color{4, 8, 20, 110}, SDL_Color{2, 4, 12, 170});
        ePanel::gradient(rend, SDL_FRect{x0, y0, w, h*.45f}, SDL_Color{140, 180, 240, 22}, SDL_Color{140, 180, 240, 0});
        const float hair = std::max(1.f, h/28.f);
        ePanel::gradient(rend, SDL_FRect{x0, y0 + h - hair, w, hair}, SDL_Color{236, 192, 96, 255},
                         SDL_Color{168, 120, 40, 255});
        ePanel::gradient(rend, SDL_FRect{x0, y0 + h, w, h*.35f}, SDL_Color{0, 0, 0, 110}, SDL_Color{0, 0, 0, 0});
    } else {
        mDateLabel->setEnabled(false);
    }
}
