#ifndef EMAINMENU_H
#define EMAINMENU_H

#include "emainmenubase.h"
#include "emenu3d.h"

// Title screen: the Zeus emblem over the living backdrop and a column of
// gold-edged tablets drawn in perspective (tilt toward the cursor, lift on
// hover, flip in on entry). Mouse, arrow keys / W S, Enter and 1-6 work.
class eMainMenu : public eMainMenuBase {
public:
    using eMainMenuBase::eMainMenuBase;
    ~eMainMenu();

    // Adds a "Continue" tablet for the most recent save; call before
    // initialize().
    void setContinue(const std::string& subtitle, const eAction& a);

    void initialize(const eAction& newGameA,
                    const eAction& loadGameA,
                    const eAction& editGameA,
                    const eAction& settingsA,
                    const eAction& quitA,
                    const eAction& leaderA);

    void renderTargetsReset() override;
protected:
    void paintEvent(ePainter& p) override;
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool keyPressEvent(const eKeyPressEvent& e) override;
private:
    enum class eKind {
        transition, // tablets fall away, then the action
        strike,     // lightning, tablets fall away, then the action
        dialog,     // modal over the menu, no transition
        quit        // fade to black
    };

    struct eItem {
        std::string fText;
        std::string fSub;
        eAction fAction;
        eKind fKind = eKind::transition;
        bool fHero = false;
        SDL_Texture* fFace[2] = {nullptr, nullptr};
        int fFaceW = 0;
        int fFaceH = 0;
        double fHover = 0;
        double fPress = 0;
        SDL_FPoint fQuad[4];
        bool fHit = false;
    };

    void freeTextures();
    void buildTextures(SDL_Renderer* const r);
    SDL_Texture* renderFace(SDL_Renderer* const r, const eItem& it,
                            const bool hover, const int w, const int h);
    SDL_Texture* renderChip(SDL_Renderer* const r, const bool hover,
                            const int w, const int h);
    void drawTips(SDL_Renderer* const r, const double alpha);

    int itemAt(const int x, const int y) const;
    void activate(const int id);
    double uiTime() const;
    bool modal() const;

    std::string mContinueSub;
    eAction mContinueA;
    eAction mLeaderA;

    std::vector<eItem> mItems;
    int mSelected = -1;
    int mPressedId = -1;
    bool mKeyboardNav = false;

    // leader chip (top left)
    SDL_Texture* mChip[2] = {nullptr, nullptr};
    int mChipW = 0;
    int mChipH = 0;
    double mChipHover = 0;
    SDL_FPoint mChipQuad[4];
    bool mChipHit = false;
    SDL_Texture* mChipHint = nullptr;
    int mChipHintW = 0;
    int mChipHintH = 0;

    SDL_Texture* mLogo = nullptr;
    SDL_Texture* mLogoBolt = nullptr;
    int mLogoW = 0;
    int mLogoH = 0;

    SDL_Texture* mFooter = nullptr;
    int mFooterW = 0;
    int mFooterH = 0;

    std::vector<std::string> mTips;
    int mTipId = -1;
    SDL_Texture* mTipTex = nullptr;
    int mTipW = 0;
    int mTipH = 0;

    double mTexScale = -1;
    double mSS = 2;
    eMenu3D::eSupersample mSuper;
    bool mTexturesDirty = true;

    double mStartTime = 0;  // scene time when this menu appeared
    bool mIntro = false;
    double mLeaveTime = -1; // scene time when an item was chosen
    int mLeaveId = -1;
    bool mLeaveFired = false;
    bool mWasModal = false;

    double mLastFrame = -1;
};

#endif // EMAINMENU_H
