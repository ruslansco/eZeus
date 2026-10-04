#include "eobjectivetrackerwidget.h"

#include <algorithm>
#include <cmath>

#include "egamewidget.h"
#include "engine/egameboard.h"
#include "engine/eepisodegoal.h"
#include "engine/ecampaign.h"
#include "engine/eworldcity.h"
#include "emainwindow.h"
#include "elanguage.h"
#include "efonts.h"
#include "epainter.h"
#include "eresolution.h"

void eObjectiveTrackerWidget::initialize(eGameWidget* const gw, eGameBoard* const board) {
    mGW = gw;
    mBoard = board;
    setPadding(0);
    mExpanded = true;
    mUserVisible = true;
    refreshData();
    updatePosition();
}

void eObjectiveTrackerWidget::setBoard(eGameBoard* const board) {
    mBoard = board;
    refreshData();
    updatePosition();
}

void eObjectiveTrackerWidget::updatePosition() {
    if(!mGW) return;
    const auto res = resolution();
    const double mult = res.multiplier();

    const int px = static_cast<int>(12 * mult);
    const int topH = mGW->topBarHeight();
    const int py = (topH > 0 ? topH : static_cast<int>(24 * mult)) + static_cast<int>(8 * mult);

    move(px, py);
    recalculateLayout();
}

void eObjectiveTrackerWidget::toggleExpanded() {
    setExpanded(!mExpanded);
}

void eObjectiveTrackerWidget::setExpanded(const bool exp) {
    mExpanded = exp;
    recalculateLayout();
}

void eObjectiveTrackerWidget::toggleUserVisible() {
    setUserVisible(!mUserVisible);
}

void eObjectiveTrackerWidget::setUserVisible(const bool vis) {
    mUserVisible = vis;
    setVisible(mUserVisible && mBoard && !mBoard->editorMode() && !mGoals.empty());
}

void eObjectiveTrackerWidget::refreshData() {
    if(!mBoard || mBoard->editorMode()) {
        mGoals.clear();
        mMetCount = 0;
        mTotalCount = 0;
        mAllMet = false;
        setVisible(false);
        return;
    }

    const auto& boardGoals = mBoard->goals();
    if(boardGoals.empty()) {
        mGoals.clear();
        mMetCount = 0;
        mTotalCount = 0;
        mAllMet = false;
        setVisible(false);
        return;
    }

    const auto w = window();
    const auto c = w ? w->campaign() : nullptr;
    const auto e = c ? c->currentEpisode() : nullptr;
    const auto et = c ? c->currentEpisodeType() : eEpisodeType::parentCity;
    const bool col = et == eEpisodeType::colony;
    const auto capitalCid = mBoard->currentCityId();
    const auto capital = mBoard->boardCityWithId(capitalCid);
    const bool atlantean = capital ? capital->atlantean() : false;

    mGoals.clear();
    mMetCount = 0;
    mTotalCount = static_cast<int>(boardGoals.size());

    for(const auto& g : boardGoals) {
        if(!g) continue;
        GoalItem item;
        item.met = g->met();
        if(item.met) mMetCount++;

        item.text = g->text(col, atlantean, *mBoard);
        item.statusText = g->statusText(*mBoard);

        // Calculate numerical progress [0.0 .. 1.0]
        if(item.met) {
            item.progress = 1.0;
        } else {
            switch(g->fType) {
            case eEpisodeGoalType::population:
            case eEpisodeGoalType::treasury:
            case eEpisodeGoalType::housing:
            case eEpisodeGoalType::support:
            case eEpisodeGoalType::yearlyProduction:
            case eEpisodeGoalType::yearlyProfit:
            case eEpisodeGoalType::tradingPartners:
                if(g->fRequiredCount > 0) {
                    item.progress = std::clamp(static_cast<double>(g->fStatusCount) / g->fRequiredCount, 0.0, 1.0);
                }
                break;
            case eEpisodeGoalType::sanctuary:
            case eEpisodeGoalType::pyramid:
                if(g->fEnumInt1 == -1) {
                    if(g->fRequiredCount > 0) {
                        item.progress = std::clamp(static_cast<double>(g->fStatusCount) / g->fRequiredCount, 0.0, 1.0);
                    }
                } else {
                    item.progress = std::clamp(static_cast<double>(g->fStatusCount) / 100.0, 0.0, 1.0);
                }
                break;
            case eEpisodeGoalType::setAsideGoods:
                if(g->fRequiredCount > 0) {
                    item.progress = std::clamp(static_cast<double>(g->fPreviewCount) / g->fRequiredCount, 0.0, 1.0);
                }
                break;
            default:
                item.progress = item.met ? 1.0 : 0.0;
                break;
            }
        }

        mGoals.push_back(item);
    }

    mAllMet = (mTotalCount > 0 && mMetCount >= mTotalCount);
    setVisible(mUserVisible && !mGoals.empty());
    recalculateLayout();
}

void eObjectiveTrackerWidget::recalculateLayout() {
    const auto res = resolution();
    const double mult = res.multiplier();

    const int w = mExpanded ? static_cast<int>(270 * mult) : static_cast<int>(195 * mult);
    const int hHeader = static_cast<int>(28 * mult);
    const int hRow = static_cast<int>(38 * mult);

    int totalH = hHeader;
    if(mExpanded && !mGoals.empty()) {
        totalH += static_cast<int>(mGoals.size()) * hRow + static_cast<int>(6 * mult);
    }

    resize(w, totalH);

    mHeaderRect = {0, 0, w, hHeader};

    // Toggle button on the far right
    const int btnSz = static_cast<int>(18 * mult);
    const int btnY = (hHeader - btnSz) / 2;
    mToggleBtnRect = {w - btnSz - static_cast<int>(5 * mult), btnY, btnSz, btnSz};

    // Details [i] button right before toggle
    mDetailsBtnRect = {mToggleBtnRect.x - btnSz - static_cast<int>(4 * mult), btnY, btnSz, btnSz};

    // Row bounds
    if(mExpanded) {
        for(size_t i = 0; i < mGoals.size(); ++i) {
            mGoals[i].rect = {
                static_cast<int>(4 * mult),
                hHeader + static_cast<int>(3 * mult) + static_cast<int>(i) * hRow,
                w - static_cast<int>(8 * mult),
                hRow - static_cast<int>(2 * mult)
            };
        }
    }
}

void eObjectiveTrackerWidget::drawCheckmark(ePainter& p, int bx, int by, int bsz, double mult) const {
    // Fill emerald green box with border
    const SDL_Rect box{bx, by, bsz, bsz};
    p.fillRect(box, SDL_Color{46, 204, 113, 235});
    p.drawRect(box, SDL_Color{30, 140, 75, 255}, 1);

    // Draw clean white checkmark
    const int th = std::max(1, static_cast<int>(1.5 * mult));
    const int cx = bx + static_cast<int>(3 * mult);
    const int cy = by + static_cast<int>(6 * mult);

    const SDL_Color checkCol{255, 255, 255, 255};
    // Down stroke
    p.fillRect({cx, cy, th, th}, checkCol);
    p.fillRect({cx + th, cy + th, th, th}, checkCol);
    // Up stroke
    p.fillRect({cx + 2 * th, cy + th, th, th}, checkCol);
    p.fillRect({cx + 3 * th, cy, th, th}, checkCol);
    p.fillRect({cx + 4 * th, cy - th, th, th}, checkCol);
    p.fillRect({cx + 5 * th, cy - 2 * th, th, th}, checkCol);
}

void eObjectiveTrackerWidget::paintEvent(ePainter& p) {
    if(!mUserVisible || !mBoard || mBoard->editorMode() || mGoals.empty()) {
        return;
    }

    // Refresh goal numbers dynamically
    refreshData();

    const auto res = resolution();
    const double mult = res.multiplier();
    const int w = width();
    const int h = height();
    const int hHeader = static_cast<int>(28 * mult);

    const SDL_Rect panelRect{0, 0, w, h};

    // Soft drop shadow
    p.drawDropShadow(panelRect, static_cast<int>(3 * mult), 120);

    // Aegean Midnight Stone background
    const SDL_Color bgMidnight{14, 22, 36, 228};
    p.fillRect(panelRect, bgMidnight);

    // Header background: victory gold-green if all goals met, else Aegean blue
    const SDL_Color bgHeader = mAllMet ? SDL_Color{30, 52, 32, 245} : SDL_Color{22, 34, 54, 245};
    p.fillRect({1, 1, w - 2, hHeader - 1}, bgHeader);

    // Header gold divider line (when expanded)
    if(mExpanded && !mGoals.empty()) {
        p.fillRect({2, hHeader - 1, w - 4, 1}, SDL_Color{212, 175, 55, 140});
    }

    // Double-line gold frame
    p.drawGoldFrame(panelRect, 1);

    // Classical decorative temple pillar icon on the left
    const int icX = static_cast<int>(7 * mult);
    const int icY = hHeader / 2;
    p.fillRect({icX, icY - static_cast<int>(5 * mult), static_cast<int>(3 * mult), static_cast<int>(10 * mult)},
               SDL_Color{212, 175, 55, 230});
    p.fillRect({icX - static_cast<int>(1 * mult), icY - static_cast<int>(6 * mult), static_cast<int>(5 * mult), static_cast<int>(2 * mult)},
               SDL_Color{240, 205, 80, 255});
    p.fillRect({icX - static_cast<int>(1 * mult), icY + static_cast<int>(4 * mult), static_cast<int>(5 * mult), static_cast<int>(2 * mult)},
               SDL_Color{240, 205, 80, 255});

    // Header title: "OBJECTIVES" / "ЦЕЛИ"
    std::string title = eLanguage::zeusText(62, 8);
    if(title.empty()) title = "Objectives";
    if(mAllMet) title += " *";

    auto titleFont = eFonts::headingFont(res.smallFontSize());
    p.setFont(titleFont);
    const int titleX = static_cast<int>(16 * mult);
    const int titleY = (hHeader - res.smallFontSize()) / 2;
    p.drawText(titleX, titleY, title, mAllMet ? eFontColor::light : eFontColor::yellow);

    // Badge counter pill: [ 2/4 ]
    const std::string badgeStr = std::to_string(mMetCount) + "/" + std::to_string(mTotalCount);
    int bw = 0, bh = 0;
    auto badgeFont = eFonts::labelFont(res.verySmallFontSize());
    if(badgeFont) TTF_SizeUTF8(eFonts::forText(badgeFont, badgeStr), badgeStr.c_str(), &bw, &bh);

    const int badgePadding = static_cast<int>(5 * mult);
    const int badgeW = bw + 2 * badgePadding;
    const int badgeH = static_cast<int>(18 * mult);
    const int badgeX = mDetailsBtnRect.x - badgeW - static_cast<int>(5 * mult);
    const int badgeY = (hHeader - badgeH) / 2;
    const SDL_Rect rBadge{badgeX, badgeY, badgeW, badgeH};

    const SDL_Color badgeBg = mAllMet ? SDL_Color{46, 204, 113, 200} : SDL_Color{16, 26, 42, 220};
    p.fillRect(rBadge, badgeBg);
    p.drawRect(rBadge, mAllMet ? SDL_Color{60, 230, 130, 240} : SDL_Color{180, 150, 60, 180}, 1);

    p.setFont(badgeFont);
    p.drawText(badgeX + badgePadding, badgeY + (badgeH - bh) / 2, badgeStr,
               mAllMet ? eFontColor::light : eFontColor::yellow);

    // Details button [i]
    const bool hoverDetails = (mHovered && mHoveredRow == 1);
    if(hoverDetails) {
        p.fillRect(mDetailsBtnRect, SDL_Color{255, 215, 0, 45});
    }
    p.drawRect(mDetailsBtnRect, hoverDetails ? SDL_Color{255, 220, 100, 255} : SDL_Color{180, 150, 60, 180}, 1);
    auto infoFont = eFonts::defaultFont(res.tinyFontSize());
    p.setFont(infoFont);
    int iw = 0, ih = 0;
    if(infoFont) TTF_SizeUTF8(infoFont, "i", &iw, &ih);
    p.drawText(mDetailsBtnRect.x + (mDetailsBtnRect.w - iw) / 2,
               mDetailsBtnRect.y + (mDetailsBtnRect.h - ih) / 2,
               "i", eFontColor::yellow);

    // Collapse / Expand button [▲] / [▼]
    const bool hoverToggle = (mHovered && mHoveredRow == 2);
    if(hoverToggle) {
        p.fillRect(mToggleBtnRect, SDL_Color{255, 215, 0, 45});
    }
    p.drawRect(mToggleBtnRect, hoverToggle ? SDL_Color{255, 220, 100, 255} : SDL_Color{180, 150, 60, 180}, 1);

    // Draw arrow icon inside toggle button
    const SDL_Color arrColor = hoverToggle ? SDL_Color{255, 230, 120, 255} : SDL_Color{212, 175, 55, 220};
    const int midX = mToggleBtnRect.x + mToggleBtnRect.w / 2;
    const int midY = mToggleBtnRect.y + mToggleBtnRect.h / 2;
    const int arrSz = static_cast<int>(3.5 * mult);

    if(mExpanded) {
        // Up arrow ▲
        for(int row = -arrSz; row <= 0; ++row) {
            const int lineW = (row + arrSz) * 2 + 1;
            p.fillRect({midX - lineW / 2, midY + row, lineW, 1}, arrColor);
        }
    } else {
        // Down arrow ▼
        for(int row = 0; row <= arrSz; ++row) {
            const int lineW = (arrSz - row) * 2 + 1;
            p.fillRect({midX - lineW / 2, midY + row, lineW, 1}, arrColor);
        }
    }

    // Paint Goal Items (when expanded)
    if(mExpanded) {
        auto goalFont = eFonts::defaultFont(res.verySmallFontSize());
        auto subFont = eFonts::defaultFont(res.tinyFontSize());

        for(size_t i = 0; i < mGoals.size(); ++i) {
            const auto& item = mGoals[i];
            const auto& r = item.rect;

            // Hover row highlight
            const bool hoverRow = (mHovered && mHoveredRow == static_cast<int>(10 + i));
            if(hoverRow) {
                p.fillRect(r, SDL_Color{255, 215, 0, 25});
            }

            // Status Checkbox / Icon
            const int boxSz = static_cast<int>(13 * mult);
            const int boxX = r.x + static_cast<int>(5 * mult);
            const int boxY = r.y + static_cast<int>(4 * mult);

            if(item.met) {
                drawCheckmark(p, boxX, boxY, boxSz, mult);
            } else {
                // Incomplete hollow bronze box with subtle center dot
                const SDL_Rect box{boxX, boxY, boxSz, boxSz};
                p.fillRect(box, SDL_Color{16, 24, 38, 220});
                p.drawRect(box, SDL_Color{180, 150, 70, 200}, 1);
                p.fillRect({boxX + boxSz / 2 - 1, boxY + boxSz / 2 - 1, 2, 2}, SDL_Color{140, 120, 60, 160});
            }

            // Description text
            const int textX = r.x + static_cast<int>(23 * mult);
            const int textY = r.y + static_cast<int>(2 * mult);
            const int maxTextW = r.w - static_cast<int>(26 * mult);

            std::string displayText = item.text;
            if(goalFont) {
                int tw = 0, th = 0;
                TTF_SizeUTF8(eFonts::forText(goalFont, displayText), displayText.c_str(), &tw, &th);
                if(tw > maxTextW) {
                    while(!displayText.empty() && tw > maxTextW) {
                        displayText.pop_back();
                        while(!displayText.empty() && (displayText.back() & 0xC0) == 0x80) {
                            displayText.pop_back();
                        }
                        std::string testStr = displayText + "...";
                        TTF_SizeUTF8(eFonts::forText(goalFont, testStr), testStr.c_str(), &tw, &th);
                        if(tw <= maxTextW) {
                            displayText = testStr;
                            break;
                        }
                    }
                }
            }

            p.setFont(goalFont);
            p.drawText(textX, textY, displayText,
                       item.met ? eFontColor::light : eFontColor::yellow);

            // Numerical status subtext (e.g. "1,200" or "45%")
            const int subY = r.y + static_cast<int>(17 * mult);
            p.setFont(subFont);
            p.drawText(textX, subY, item.statusText,
                       item.met ? eFontColor::light : eFontColor::light);

            // Mini Progress Bar
            const int barX = textX;
            const int barY = r.y + r.h - static_cast<int>(6 * mult);
            const int barW = r.w - static_cast<int>(28 * mult);
            const int barH = static_cast<int>(4 * mult);

            // Bar background & border
            p.fillRect({barX, barY, barW, barH}, SDL_Color{12, 18, 28, 230});
            p.drawRect({barX, barY, barW, barH}, SDL_Color{70, 60, 40, 180}, 1);

            // Bar fill
            const int fillW = std::clamp(static_cast<int>(barW * item.progress), 0, barW);
            if(fillW > 0) {
                const SDL_Color fillColor = item.met ? SDL_Color{46, 204, 113, 230} : SDL_Color{212, 175, 55, 230};
                p.fillRect({barX + 1, barY + 1, std::max(0, fillW - 2), barH - 2}, fillColor);
                // Subtle highlight shine along top of bar
                if(fillW > 4 && barH > 3) {
                    const SDL_Color hlColor = item.met ? SDL_Color{120, 255, 160, 120} : SDL_Color{255, 240, 160, 120};
                    p.fillRect({barX + 2, barY + 1, fillW - 4, 1}, hlColor);
                }
            }
        }
    }
}

bool eObjectiveTrackerWidget::mousePressEvent(const eMouseEvent& e) {
    if(!mUserVisible || !mBoard || mGoals.empty()) return false;

    const SDL_Point pt{e.x(), e.y()};

    // Details button clicked
    if(SDL_PointInRect(&pt, &mDetailsBtnRect)) {
        if(mGW) mGW->showGoals();
        return true;
    }

    // Toggle button clicked
    if(SDL_PointInRect(&pt, &mToggleBtnRect)) {
        toggleExpanded();
        return true;
    }

    // Header clicked
    if(SDL_PointInRect(&pt, &mHeaderRect)) {
        toggleExpanded();
        return true;
    }

    // Row clicked
    if(mExpanded) {
        for(size_t i = 0; i < mGoals.size(); ++i) {
            if(SDL_PointInRect(&pt, &mGoals[i].rect)) {
                if(mGW) mGW->showGoals();
                return true;
            }
        }
    }

    return false;
}

bool eObjectiveTrackerWidget::mouseMoveEvent(const eMouseEvent& e) {
    const SDL_Point pt{e.x(), e.y()};
    int newHover = -1;

    if(SDL_PointInRect(&pt, &mDetailsBtnRect)) {
        newHover = 1;
    } else if(SDL_PointInRect(&pt, &mToggleBtnRect)) {
        newHover = 2;
    } else if(SDL_PointInRect(&pt, &mHeaderRect)) {
        newHover = 0;
    } else if(mExpanded) {
        for(size_t i = 0; i < mGoals.size(); ++i) {
            if(SDL_PointInRect(&pt, &mGoals[i].rect)) {
                newHover = static_cast<int>(10 + i);
                break;
            }
        }
    }

    if(newHover != mHoveredRow) {
        mHoveredRow = newHover;
    }

    return false;
}

bool eObjectiveTrackerWidget::mouseEnterEvent(const eMouseEvent& e) {
    mHovered = true;
    mouseMoveEvent(e);
    return false;
}

bool eObjectiveTrackerWidget::mouseLeaveEvent(const eMouseEvent& e) {
    (void)e;
    mHovered = false;
    mHoveredRow = -1;
    return false;
}
