#ifndef EOBJECTIVETRACKERWIDGET_H
#define EOBJECTIVETRACKERWIDGET_H

#include "ewidget.h"
#include <vector>
#include <string>

class eGameBoard;
class eGameWidget;

class eObjectiveTrackerWidget : public eWidget {
public:
    using eWidget::eWidget;

    void initialize(eGameWidget* const gw, eGameBoard* const board);
    void setBoard(eGameBoard* const board);
    void updatePosition();

    void toggleExpanded();
    void setExpanded(const bool exp);
    bool isExpanded() const { return mExpanded; }

    void toggleUserVisible();
    void setUserVisible(const bool vis);
    bool isUserVisible() const { return mUserVisible; }

    void refreshData();

protected:
    void paintEvent(ePainter& p) override;
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseEnterEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;

private:
    struct GoalItem {
        std::string text;
        std::string statusText;
        double progress = 0.0;
        bool met = false;
        SDL_Rect rect{0, 0, 0, 0};
    };

    void recalculateLayout();
    void drawCheckmark(ePainter& p, int bx, int by, int bsz, double mult) const;

    eGameWidget* mGW = nullptr;
    eGameBoard* mBoard = nullptr;

    bool mExpanded = true;
    bool mUserVisible = true;
    bool mHovered = false;
    int mHoveredRow = -1; // -1 none, 0 header, 1 info btn, 2 toggle btn, >= 10 goal row

    SDL_Rect mHeaderRect{0, 0, 0, 0};
    SDL_Rect mToggleBtnRect{0, 0, 0, 0};
    SDL_Rect mDetailsBtnRect{0, 0, 0, 0};

    std::vector<GoalItem> mGoals;
    int mMetCount = 0;
    int mTotalCount = 0;
    bool mAllMet = false;
};

#endif // EOBJECTIVETRACKERWIDGET_H
