#ifndef ECITYHISTORYWIDGET_H
#define ECITYHISTORYWIDGET_H

#include "eframedwidget.h"

#include "engine/ecityhistory.h"

#include <map>
#include <string>
#include <vector>

// Line chart of one series of a city's monthly record, with a tab per
// series, a range switch and a readout under the mouse.
class eHistoryChart : public eWidget {
public:
    using eWidget::eWidget;
    ~eHistoryChart();

    void setSamples(const std::vector<eHistorySample>& s) { mSamples = s; }
    // Skips the draw-in (screenshots).
    void settle() { mShown = 1; mLast = -1; }
protected:
    void paintEvent(ePainter& p) override;
    bool mousePressEvent(const eMouseEvent& e) override;
    bool mouseReleaseEvent(const eMouseEvent& e) override;
    bool mouseMoveEvent(const eMouseEvent& e) override;
    bool mouseLeaveEvent(const eMouseEvent& e) override;
private:
    struct eText {
        SDL_Texture* fTex = nullptr;
        int fW = 0;
        int fH = 0;
    };
    const eText& text(SDL_Renderer* const r, const std::string& s, const int px);
    void drawText(SDL_Renderer* const r, const std::string& s, const int px,
                  const float x, const float y, const SDL_Color c,
                  const int align = 0); // 0 left, 1 centre, 2 right

    std::vector<eHistorySample> mSamples;
    std::map<std::pair<std::string, int>, eText> mTexts;
    int mSeries = 0;
    int mRange = 1;          // 0: 2 years, 1: 10 years, 2: all
    int mMouseX = -1;
    int mMouseY = -1;
    std::vector<SDL_FRect> mTabRects;
    std::vector<SDL_FRect> mRangeRects;
    double mShown = 0;
    double mLast = -1;
};

class eGameWidget;

class eCityHistoryWidget : public eFramedWidget {
public:
    using eFramedWidget::eFramedWidget;

    void initialize(const eCityHistory& history, const eAction& close,
                    const bool instant = false);
};

#endif // ECITYHISTORYWIDGET_H
