#ifndef EPANELWIDGETS_H
#define EPANELWIDGETS_H

#include "echeckablebutton.h"

#include <functional>
#include <string>

// Widgets of the in-game side panel, drawn with ePanel (epanelstyle.h).

// A category of the left rail: gold medallion that turns to a polished gold
// face while its category is open.
class ePanelCategoryButton : public eCheckableButton {
public:
    ePanelCategoryButton(eMainWindow* const window, const std::string& icon);
protected:
    void paintEvent(ePainter& p) override;
private:
    std::string mIcon;
    double mHover = 0;
    double mActive = 0;
    double mPress = 0;
    double mLast = -1;
};

// A tool or command medallion (road, demolish, world map ...). With an
// active predicate it lights while that tool is in use.
class ePanelActionButton : public eButton {
public:
    ePanelActionButton(eMainWindow* const window, const std::string& icon);

    ~ePanelActionButton();

    void setActivePredicate(const std::function<bool()>& f) { mActiveF = f; }
    void setIcon(const std::string& icon) { mIcon = icon; }
    void setDiameter(const double d) { mDiameter = d; }
    // A red count in the top-right corner while f() > 0 (new messages).
    void setBadge(const std::function<int()>& f) { mBadgeF = f; }
protected:
    void paintEvent(ePainter& p) override;
private:
    std::string mIcon;
    std::function<bool()> mActiveF;
    std::function<int()> mBadgeF;
    int mBadgeN = -1;
    SDL_Texture* mBadgeTex = nullptr;
    int mBadgeW = 0;
    int mBadgeH = 0;
    double mBadgeBorn = -1;
    double mDiameter = 0;
    double mHover = 0;
    double mActive = 0;
    double mPress = 0;
    double mLast = -1;
};

// A building button: the original illustration (cut out of its blue tile by
// art/panel/pack_panel.py) on a framed lapis tile; a chevron marks the ones
// that open a list.
class ePanelTileButton : public eButton {
public:
    using eButton::eButton;

    void setOpensList(const bool o) { mOpensList = o; }
protected:
    void paintEvent(ePainter& p) override;
private:
    bool mOpensList = false;
    double mHover = 0;
    double mLast = -1;
};

// Info / Map switch at the top of the panel.
class ePanelTabs : public eWidget {
public:
    using eWidget::eWidget;
    ~ePanelTabs();

    void initialize(const std::string& left, const std::string& right);
    void setIndex(const int i);
    int index() const { return mIndex; }
    void setChangeAction(const std::function<void(int)>& a) { mAction = a; }
protected:
    void paintEvent(ePainter& p) override;
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseEnterEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;
private:
    std::string mText[2];
    SDL_Texture* mTextTex[2] = {nullptr, nullptr};
    int mTextW[2] = {0, 0};
    int mTextH[2] = {0, 0};
    int mIndex = 0;
    int mHoverIndex = -1;
    double mSlide = 0;
    double mLast = -1;
    std::function<void(int)> mAction;
};

// A wide pill button with a text (Back to City on the world map).
class ePanelPillButton : public eButton {
public:
    ePanelPillButton(eMainWindow* const window, const std::string& text);
    ~ePanelPillButton();
protected:
    void paintEvent(ePainter& p) override;
private:
    std::string mLabel;
    SDL_Texture* mTex = nullptr;
    int mTW = 0;
    int mTH = 0;
    int mTexPx = 0;
    double mHover = 0;
    double mPress = 0;
    double mLast = -1;
};

// Pill behind a building's price.
class ePricePill : public eWidget {
public:
    using eWidget::eWidget;
protected:
    void paintEvent(ePainter& p) override;
};

// Drawn over the panel content right after a category switch: a quick
// lapis veil that clears from the top, so the new page reveals itself.
class ePanelVeil : public eWidget {
public:
    using eWidget::eWidget;
    void trigger();
    void cancel() { mStart = -10; }
protected:
    void paintEvent(ePainter& p) override;
private:
    double mStart = -10;
};

#endif // EPANELWIDGETS_H
