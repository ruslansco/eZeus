#ifndef ETOPBARWIDGET_H
#define ETOPBARWIDGET_H

#include "eframedwidget.h"
#include "elabel.h"

class eGameBoard;
class eGameWidget;
class eButton;

class eTopWidget : public eWidget {
public:
    using eWidget::eWidget;

    void initialize(const std::shared_ptr<eTexture>& icon,
                    const std::string& text) {
        setPadding(0);
        mIcon = new eLabel(window());
        mIcon->setPadding(0);
        mIcon->setTexture(icon);
        mIcon->fitContent();
        mText = new eLabel(window());
        mText->setX(1.5*mIcon->width());
        mText->setPadding(0);
        mText->setSmallFontSize();

        addWidget(mIcon);
        addWidget(mText);

        setText(text);

        mIcon->align(eAlignment::vcenter);
        mText->align(eAlignment::vcenter);
    }

    void setText(const std::string& text) {
        mText->setText(text);
        mText->fitContent();
        fitContent();
    }
private:
    eLabel* mIcon = nullptr;
    eLabel* mText = nullptr;
};

// Custom speed control widget that draws graphical speed indicators
class eSpeedControlWidget : public eWidget {
public:
    using eWidget::eWidget;

    enum class eSpeedState {
        paused, slow, normal, fast, vfast
    };

    void initialize(int mult);
    void setState(eSpeedState state);

    void setPauseAction(const eAction& a) { mPauseAction = a; }
    void setSlowAction(const eAction& a) { mSlowAction = a; }
    void setNormalAction(const eAction& a) { mNormalAction = a; }
    void setFastAction(const eAction& a) { mFastAction = a; }
    void setVFastAction(const eAction& a) { mVFastAction = a; }
protected:
    void paintEvent(ePainter& p);
    bool mousePressEvent(const eMouseEvent& e);
    bool mouseEnterEvent(const eMouseEvent& e);
    bool mouseLeaveEvent(const eMouseEvent& e);
    bool mouseMoveEvent(const eMouseEvent& e);
private:
    int hitTest(int x, int y) const;
    void drawPauseIcon(ePainter& p, int x, int cy, int sz,
                       const SDL_Color& color) const;
    void drawTriangles(ePainter& p, int x, int cy, int sz,
                       int count, const SDL_Color& color) const;

    eSpeedState mState = eSpeedState::normal;
    int mMult = 1;
    int mHoveredBtn = -1;
    bool mHovered = false;

    // Button regions (x start, width) for hit testing
    struct BtnRegion { int x; int w; };
    BtnRegion mBtnRegions[5];

    eAction mPauseAction;
    eAction mSlowAction;
    eAction mNormalAction;
    eAction mFastAction;
    eAction mVFastAction;
};

class eTopBarWidget : public eWidget {
public:
    using eWidget::eWidget;

    void initialize();
    void setBoard(eGameBoard* const board);
    void setGameWidget(eGameWidget* const gw);

    void paintEvent(ePainter& p);

    void updateSpeedControls();
private:
    void createSpeedControls();

    eGameBoard* mBoard = nullptr;
    eGameWidget* mGW = nullptr;
    eLabel* mCityLabel = nullptr;
    eTopWidget* mDrachmasWidget = nullptr;
    eTopWidget* mPopulationWidget = nullptr;
    eButton* mDateLabel = nullptr;
    int mTime = 0;

    // Speed controls
    eSpeedControlWidget* mSpeedControl = nullptr;
};

#endif // ETOPBARWIDGET_H
