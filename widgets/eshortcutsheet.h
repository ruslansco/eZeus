#ifndef ESHORTCUTSHEET_H
#define ESHORTCUTSHEET_H

#include "ewidget.h"
#include "efonts.h"

#include <string>
#include <vector>

struct eKeyBindings;

// Every keyboard and mouse shortcut of the game view, in columns of
// sections, shown by eGameWidget while H (or /) is held down.
class eShortcutSheet : public eWidget {
public:
    using eWidget::eWidget;
    ~eShortcutSheet();

    // Lays the sheet out for the current bindings and resizes to fit.
    // science: the city builds science rather than culture buildings.
    void build(const eKeyBindings& kb, const bool science);
    // Starts the fade in again.
    void restart() { mShow = mInstant ? 1 : 0; }
    // No fade in (screenshots).
    void setInstant(const bool i) { mInstant = i; }
protected:
    void paintEvent(ePainter& p) override;
private:
    struct eText {
        std::string fText;
        int fFontPx = 0;
        eFontRole fRole = eFontRole::body;
        SDL_Color fColor;
        int fX = 0;
        int fY = 0;
        int fW = 0;
        int fH = 0;
        SDL_Texture* fTex = nullptr;
    };
    struct eCap {
        SDL_Rect fRect;
    };
    struct eRule {
        int fX, fY, fW;
    };
    void clear();
    eText& addText(const std::string& text, const int fontPx,
                   const SDL_Color c, const int x, const int y,
                   const eFontRole role = eFontRole::body);
    static void sTextSize(const std::string& text, const int fontPx,
                          int& w, int& h,
                          const eFontRole role = eFontRole::body);

    std::vector<eText> mTexts;
    std::vector<eCap> mCaps;
    std::vector<eRule> mRules;
    int mTitleRuleY = 0;
    double mShow = 0;
    bool mInstant = false;
    double mLast = -1;
};

#endif // ESHORTCUTSHEET_H
