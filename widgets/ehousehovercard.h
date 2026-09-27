#ifndef EHOUSEHOVERCARD_H
#define EHOUSEHOVERCARD_H

#include "ewidget.h"

#include "engine/eresourcetype.h"

#include <memory>
#include <string>
#include <vector>

class eHouseBase;
class eTexture;

// Shown by eGameWidget while the mouse rests on a house: its level, and what
// it still needs to reach the next one (or what it lacks to keep the current
// one), each need ticked or crossed.
class eHouseHoverCard : public eWidget {
public:
    using eWidget::eWidget;
    ~eHouseHoverCard();

    // Refreshes the card for h; returns false when there is nothing to show
    // (no house, or no one lives there yet).
    bool setHouse(eHouseBase* const h);
    // Starts the fade in again (a different house).
    void restart() { mShow = mInstant ? 1 : 0; }
    // No fade in (screenshots).
    void setInstant(const bool i) { mInstant = i; }
protected:
    void paintEvent(ePainter& p) override;
private:
    struct eText {
        std::string fText;
        int fFontPx = 0;
        SDL_Color fColor;
        int fX = 0;
        int fY = 0;
        int fW = 0;
        int fH = 0;
        SDL_Texture* fTex = nullptr;
    };
    struct eIcon {
        std::string fSvg;               // or
        std::shared_ptr<eTexture> fRes;
        SDL_Color fColor;
        int fX = 0;
        int fY = 0;
        int fS = 0;
    };
    void clear();
    eText& addText(const std::string& text, const int fontPx,
                   const SDL_Color c, const int x, const int y);

    std::string mSignature;
    std::vector<eText> mTexts;
    std::vector<eIcon> mIcons;
    int mLevel = 0;
    int mLevels = 0;
    int mPipsY = 0;
    int mPipsX = 0;
    int mRuleY = 0;
    int mTone = 0;       // 0 next level, 1 declining, 2 top level / improving
    double mShow = 0;
    bool mInstant = false;
    double mLast = -1;
};

#endif // EHOUSEHOVERCARD_H
