#ifndef EMAINMENU_H
#define EMAINMENU_H

#include "emainmenubase.h"

class eMainMenu : public eMainMenuBase {
public:
    using eMainMenuBase::eMainMenuBase;

    void initialize(const eAction& newGameA,
                    const eAction& loadGameA,
                    const eAction& editGameA,
                    const eAction& settingsA,
                    const eAction& quitA,
                    const eAction& leaderA);
protected:
    void paintEvent(ePainter& p) override;
private:
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseEnterEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;

    bool mPressed = false;
    bool mHover = false;
    std::shared_ptr<eTexture> mLogoTex;
};

#endif // EMAINMENU_H
