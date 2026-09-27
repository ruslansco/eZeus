#ifndef EWORLDMENU_H
#define EWORLDMENU_H

#include "elabel.h"

#include "ebutton.h"
#include "engine/eworldcity.h"
#include "pointers/estdselfref.h"

#include <functional>

class eWorldGoodsWidget;
class eWorldTributeWidget;

class eWorldBoard;

class eWorldMenu : public eLabel {
public:
    using eLabel::eLabel;

    void initialize(const eAction& openRequest,
                    const eAction& openFulfill,
                    const eAction& openGift,
                    const eAction& openRaid,
                    const eAction& openConquer,
                    const bool showText = true);

    void setCity(const stdsptr<eWorldCity>& c);
    void setWorldBoard(eWorldBoard* const b);
    void setText(const std::string& text);
    void updateLabels() const;
    void updateButtonsEnabled() const;
    // The arrows beside the attitude: select the previous (-1) or next (1) city.
    void setCycleAction(const std::function<void(int)>& a) { mCycle = a; }
protected:
    // lapis and gold, like the city's side panel (eGameMenu)
    void paintEvent(ePainter& p) override;
private:
    float u(const double v) const { return static_cast<float>(v*mMult); }
    int mMult = 1;
    std::function<void(int)> mCycle;

    eWorldBoard* mBoard = nullptr;

    eLabel* mTextLabel = nullptr;

    eLabel* mRelationshipLabel = nullptr;
    eLabel* mNameLabel = nullptr;
    eLabel* mLeaderLabel = nullptr;

    eLabel* mAttitudeLabel = nullptr;

    eWorldGoodsWidget* mGoodsWidget = nullptr;
    eWorldTributeWidget* mTributeWidget = nullptr;

    eButton* mRequestButton = nullptr;
    eButton* mFulfillButton = nullptr;
    eButton* mGiftButton = nullptr;
    eButton* mRaidButton = nullptr;
    eButton* mConquerButton = nullptr;

    stdsptr<eWorldCity> mCity;

    bool mShowText = true;
};

#endif // EWORLDMENU_H
