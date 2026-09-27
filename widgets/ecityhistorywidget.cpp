#include "ecityhistorywidget.h"

#include "elabel.h"
#include "eokbutton.h"
#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "engine/edate.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

struct eSeries {
    const char* fKey;
    const char* fFallback;
    int eHistorySample::* fValue;
    SDL_Color fColor;
    bool fPercent;
};

const eSeries kSeries[] = {
    {"history_population", "Population", &eHistorySample::fPopulation, {255, 214, 120, 255}, false},
    {"history_treasury", "Treasury", &eHistorySample::fDrachmas, {246, 190, 70, 255}, false},
    {"history_food", "Food", &eHistorySample::fFood, {160, 214, 110, 255}, false},
    {"history_popularity", "Popularity", &eHistorySample::fPopularity, {120, 196, 255, 255}, true},
    {"history_unrest", "Unrest", &eHistorySample::fUnrest, {240, 104, 84, 255}, true},
    {"history_health", "Health", &eHistorySample::fHealth, {126, 222, 176, 255}, true}};
const int kNSeries = sizeof(kSeries)/sizeof(kSeries[0]);

std::string number(const int v) {
    const bool ru = eLanguage::language() == "ru";
    std::string d = std::to_string(std::abs(v));
    std::string out;
    int n = 0;
    for(int i = static_cast<int>(d.size()) - 1; i >= 0; i--) {
        out.insert(out.begin(), d[i]);
        if(++n % 3 == 0 && i > 0) out.insert(0, ru ? " " : ",");
    }
    return (v < 0 ? "-" : "") + out;
}

std::string yearString(const int y) {
    const auto era = y < 0 ? eLanguage::zeusText(20, 0) : eLanguage::zeusText(20, 1);
    return std::to_string(std::abs(y)) + " " + era;
}

std::string monthString(const eHistorySample& s) {
    return eMonthHelper::shortName(static_cast<eMonth>(s.fMonth)) + " " + yearString(s.fYear);
}

// a round step for about n gridlines over range
double niceStep(const double range, const int n) {
    if(range <= 0) return 1;
    const double raw = range/n;
    const double mag = std::pow(10, std::floor(std::log10(raw)));
    const double f = raw/mag;
    double nf = 1;
    if(f > 5) nf = 10;
    else if(f > 2) nf = 5;
    else if(f > 1) nf = 2;
    return std::max(1.0, nf*mag);
}

void quad(std::vector<SDL_Vertex>& v, const SDL_FPoint a, const SDL_FPoint b,
          const SDL_FPoint c, const SDL_FPoint d,
          const SDL_Color ca, const SDL_Color cb,
          const SDL_Color cc, const SDL_Color cd) {
    const SDL_FPoint z{0, 0};
    v.push_back({a, ca, z}); v.push_back({b, cb, z}); v.push_back({c, cc, z});
    v.push_back({a, ca, z}); v.push_back({c, cc, z}); v.push_back({d, cd, z});
}
}

eHistoryChart::~eHistoryChart() {
    for(auto& t : mTexts) {
        if(t.second.fTex) SDL_DestroyTexture(t.second.fTex);
    }
}

const eHistoryChart::eText& eHistoryChart::text(SDL_Renderer* const r,
                                                const std::string& s,
                                                const int px) {
    auto& t = mTexts[{s, px}];
    if(!t.fTex && !s.empty()) {
        t.fTex = eMenu3D::makeText(r, eFonts::defaultFont(px), s,
                                   SDL_Color{255, 255, 255, 255}, t.fW, t.fH);
    }
    return t;
}

void eHistoryChart::drawText(SDL_Renderer* const r, const std::string& s,
                             const int px, const float x, const float y,
                             const SDL_Color c, const int align) {
    const auto& t = text(r, s, px);
    if(!t.fTex) return;
    float xx = x;
    if(align == 1) xx -= t.fW/2.f;
    else if(align == 2) xx -= t.fW;
    SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
    SDL_SetTextureAlphaMod(t.fTex, c.a);
    const SDL_FRect d{std::round(xx), std::round(y), float(t.fW), float(t.fH)};
    SDL_RenderCopyF(r, t.fTex, nullptr, &d);
}

void eHistoryChart::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    mShown = std::min(1.0, mShown + dt/0.5);
    const double grow = eMenu3D::easeOutCubic(mShown);

    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
    const auto res = resolution();
    const double m = res.multiplier();
    const auto u = [m](const double v) { return static_cast<float>(v*m); };
    const float X = p.x();
    const float Y = p.y();
    const float W = width();
    const float H = height();
    const int smallF = res.smallFontSize();
    const int tinyF = res.tinyFontSize();
    const int bigF = res.largeFontSize();

    // series tabs
    const float tabH = u(26);
    mTabRects.clear();
    const float tabW = W/kNSeries;
    for(int i = 0; i < kNSeries; i++) {
        const SDL_FRect tr0{X + i*tabW + u(2), Y, tabW - u(4), tabH};
        mTabRects.push_back(SDL_FRect{tr0.x - X, tr0.y - Y, tr0.w, tr0.h});
        const bool on = i == mSeries;
        const bool hover = mMouseX >= tr0.x - X && mMouseX < tr0.x - X + tr0.w &&
                           mMouseY >= 0 && mMouseY < tabH;
        if(on) {
            ePanel::roundRect(r, tr0, tabH/2, SDL_Color{255, 224, 146, 255}, SDL_Color{196, 140, 48, 255});
        } else {
            ePanel::roundRect(r, tr0, tabH/2, SDL_Color{30, 50, 92, static_cast<Uint8>(hover ? 230 : 170)},
                              SDL_Color{14, 24, 50, static_cast<Uint8>(hover ? 230 : 170)});
            ePanel::roundRect(r, tr0, tabH/2, SDL_Color{240, 200, 110, static_cast<Uint8>(hover ? 200 : 110)},
                              SDL_Color{160, 112, 36, static_cast<Uint8>(hover ? 170 : 90)}, std::max(1.f, u(1)));
        }
        const auto& s = kSeries[i];
        const auto name = tr(s.fKey, s.fFallback);
        const auto& t = text(r, name, tinyF);
        const SDL_Color tc = on ? ePanel::kInk : (hover ? ePanel::kGoldPale : ePanel::kGold);
        drawText(r, name, tinyF, tr0.x + tr0.w/2, tr0.y + (tabH - t.fH)/2, tc, 1);
    }

    const auto& ser = kSeries[mSeries];
    const int n = mSamples.size();
    const float chartTop = Y + tabH + u(58);
    const float chartBottom = Y + H - u(24);
    const float chartLeft = X + u(62);
    const float chartRight = X + W - u(12);

    // range switch
    mRangeRects.clear();
    const char* rangeKeys[3][2] = {{"history_2y", "2 years"}, {"history_10y", "10 years"},
                                   {"history_all", "All"}};
    {
        float rx = X + W;
        const float rh = u(20);
        const float ry = Y + tabH + u(12);
        for(int i = 2; i >= 0; i--) {
            const auto label = tr(rangeKeys[i][0], rangeKeys[i][1]);
            const auto& t = text(r, label, tinyF);
            const float rw = t.fW + u(18);
            rx -= rw;
            const SDL_FRect rr{rx, ry, rw, rh};
            mRangeRects.insert(mRangeRects.begin(), SDL_FRect{rr.x - X, rr.y - Y, rr.w, rr.h});
            const bool on = i == mRange;
            if(on) {
                ePanel::roundRect(r, rr, rh/2, SDL_Color{240, 200, 110, 70}, SDL_Color{160, 112, 36, 70});
                ePanel::roundRect(r, rr, rh/2, SDL_Color{246, 208, 120, 230}, SDL_Color{160, 112, 36, 200},
                                  std::max(1.f, u(1)));
            }
            drawText(r, label, tinyF, rx + rw/2, ry + (rh - t.fH)/2,
                     on ? ePanel::kGoldPale : SDL_Color{170, 182, 206, 255}, 1);
            rx -= u(4);
        }
    }

    if(n < 2) {
        drawText(r, tr("history_empty", "The city's chronicle begins this month."), smallF,
                 X + W/2, Y + H/2 - u(14), ePanel::kIvory, 1);
        drawText(r, tr("history_empty2", "Each month adds a point to these charts."), tinyF,
                 X + W/2, Y + H/2 + u(10), SDL_Color{170, 182, 206, 255}, 1);
        return;
    }

    // visible samples
    const int want = mRange == 0 ? 24 : mRange == 1 ? 120 : n;
    const int first = std::max(0, n - want);
    const int count = n - first;
    int vmin = 0;
    int vmax = 1;
    for(int i = first; i < n; i++) {
        const int v = mSamples[i].*(ser.fValue);
        vmin = std::min(vmin, v);
        vmax = std::max(vmax, v);
    }
    if(ser.fPercent) vmax = std::max(vmax, 100);
    const double step = niceStep(vmax - vmin, 4);
    const double lo = std::floor(vmin/step)*step;
    const double hi = std::max(lo + step, std::ceil(vmax/step)*step);
    const auto yOf = [&](const double v) {
        return static_cast<float>(chartBottom - (v - lo)/(hi - lo)*(chartBottom - chartTop));
    };
    const auto xOf = [&](const int i) {
        if(count <= 1) return chartLeft;
        return static_cast<float>(chartLeft + double(i - first)/(count - 1)*(chartRight - chartLeft));
    };

    // headline: the latest value and the change over a year
    {
        const int latest = mSamples[n - 1].*(ser.fValue);
        auto head = number(latest) + (ser.fPercent ? "%" : "");
        drawText(r, head, bigF, X + u(4), Y + tabH + u(6), ser.fColor);
        const auto& ht = text(r, head, bigF);
        const int back = std::max(0, n - 13);
        const int delta = latest - mSamples[back].*(ser.fValue);
        const auto span = n - 1 - back >= 12 ? tr("history_year", "in a year") :
                                               tr("history_since", "since the start");
        const auto ds = (delta > 0 ? "+" : "") + number(delta) + (ser.fPercent ? "%" : "") + "  " + span;
        bool good = delta >= 0;
        if(mSeries == 4) good = delta <= 0; // unrest
        const SDL_Color dc = delta == 0 ? SDL_Color{170, 182, 206, 255} :
                             good ? SDL_Color{128, 214, 146, 255} : SDL_Color{240, 110, 90, 255};
        drawText(r, ds, tinyF, X + u(4) + ht.fW + u(10), Y + tabH + u(6) + ht.fH - text(r, ds, tinyF).fH - u(3), dc);
    }

    // grid and value labels
    for(double v = lo; v <= hi + 0.5; v += step) {
        const float y = yOf(v);
        ePanel::fill(r, SDL_FRect{chartLeft, y, chartRight - chartLeft, std::max(1.f, u(0.6))},
                     SDL_Color{150, 170, 210, static_cast<Uint8>(v == 0 ? 90 : 38)});
        const auto label = number(static_cast<int>(std::round(v))) + (ser.fPercent ? "%" : "");
        const auto& t = text(r, label, tinyF);
        drawText(r, label, tinyF, chartLeft - u(8), y - t.fH/2.f, SDL_Color{160, 174, 200, 255}, 2);
    }
    // year labels at each January, thinned to fit
    {
        const float minGap = u(64);
        float lastX = -1e9;
        for(int i = first; i < n; i++) {
            const auto& s = mSamples[i];
            if(s.fMonth != 0 && i != first) continue;
            const float x = xOf(i);
            if(x - lastX < minGap) continue;
            lastX = x;
            ePanel::fill(r, SDL_FRect{x, chartBottom, std::max(1.f, u(0.8)), u(4)},
                         SDL_Color{150, 170, 210, 120});
            drawText(r, yearString(s.fYear), tinyF, x, chartBottom + u(5),
                     SDL_Color{160, 174, 200, 255}, 1);
        }
    }

    // area and line, drawn left to right as they grow in
    const float reveal = chartLeft + static_cast<float>(grow)*(chartRight - chartLeft);
    std::vector<SDL_Vertex> area;
    std::vector<SDL_Vertex> line;
    const auto c = ser.fColor;
    const SDL_Color cTop{c.r, c.g, c.b, 90};
    const SDL_Color cBot{c.r, c.g, c.b, 0};
    const float base = yOf(std::max(lo, 0.0));
    const float lw = std::max(1.5f, u(2.2));
    for(int i = first; i < n - 1; i++) {
        float x0 = xOf(i);
        float x1 = xOf(i + 1);
        if(x0 > reveal) break;
        float y0 = yOf(mSamples[i].*(ser.fValue));
        float y1 = yOf(mSamples[i + 1].*(ser.fValue));
        if(x1 > reveal) {
            const float f = (reveal - x0)/std::max(0.001f, x1 - x0);
            y1 = y0 + (y1 - y0)*f;
            x1 = reveal;
        }
        quad(area, {x0, y0}, {x1, y1}, {x1, base}, {x0, base}, cTop, cTop, cBot, cBot);
        const float dx = x1 - x0;
        const float dy = y1 - y0;
        const float len = std::max(0.001f, std::sqrt(dx*dx + dy*dy));
        const float nx = -dy/len*lw/2;
        const float ny = dx/len*lw/2;
        quad(line, {x0 + nx, y0 + ny}, {x1 + nx, y1 + ny}, {x1 - nx, y1 - ny}, {x0 - nx, y0 - ny},
             c, c, c, c);
    }
    if(!area.empty()) SDL_RenderGeometry(r, nullptr, area.data(), area.size(), nullptr, 0);
    if(!line.empty()) SDL_RenderGeometry(r, nullptr, line.data(), line.size(), nullptr, 0);

    // readout under the mouse
    const float mx = X + mMouseX;
    const float my = Y + mMouseY;
    if(mMouseX >= 0 && mx >= chartLeft - u(6) && mx <= chartRight + u(6) &&
       my >= chartTop - u(10) && my <= chartBottom + u(6)) {
        int best = first;
        float bd = 1e9;
        for(int i = first; i < n; i++) {
            const float d = std::abs(xOf(i) - mx);
            if(d < bd) {
                bd = d;
                best = i;
            }
        }
        const float x = xOf(best);
        const int v = mSamples[best].*(ser.fValue);
        const float y = yOf(v);
        ePanel::fill(r, SDL_FRect{x, chartTop, std::max(1.f, u(1)), chartBottom - chartTop},
                     SDL_Color{255, 230, 170, 90});
        ePanel::glow(r, x, y, u(10), u(10), SDL_Color{c.r, c.g, c.b, 120}, true);
        const float dot = u(4.5);
        ePanel::roundRect(r, SDL_FRect{x - dot, y - dot, 2*dot, 2*dot}, dot, c, c);
        ePanel::roundRect(r, SDL_FRect{x - dot, y - dot, 2*dot, 2*dot}, dot,
                          SDL_Color{16, 26, 50, 255}, SDL_Color{16, 26, 50, 255}, std::max(1.f, u(1.2)));
        const auto l1 = monthString(mSamples[best]);
        const auto l2 = number(v) + (ser.fPercent ? "%" : "");
        const auto& t1 = text(r, l1, tinyF);
        const auto& t2 = text(r, l2, smallF);
        const float bw = std::max(t1.fW, t2.fW) + u(20);
        const float bh = t1.fH + t2.fH + u(12);
        float bx = x + u(12);
        if(bx + bw > X + W) bx = x - u(12) - bw;
        float by = std::clamp(y - bh - u(8), Y + tabH + u(4), chartBottom - bh);
        const SDL_FRect box{bx, by, bw, bh};
        ePanel::glow(r, bx + bw/2, by + bh*0.6f, bw*0.7f, bh, SDL_Color{0, 0, 0, 140}, false);
        ePanel::roundRect(r, box, u(6), SDL_Color{26, 44, 82, 245}, SDL_Color{12, 20, 42, 245});
        ePanel::roundRect(r, box, u(6), SDL_Color{246, 208, 120, 230}, SDL_Color{150, 106, 34, 220},
                          std::max(1.f, u(1)));
        drawText(r, l1, tinyF, bx + u(10), by + u(5), SDL_Color{170, 182, 206, 255});
        drawText(r, l2, smallF, bx + u(10), by + u(5) + t1.fH + u(2), c);
    }
}

bool eHistoryChart::mousePressEvent(const eMouseEvent& e) {
    return e.button() == eMouseButton::left;
}

bool eHistoryChart::mouseReleaseEvent(const eMouseEvent& e) {
    if(e.button() != eMouseButton::left) return false;
    const SDL_FPoint pt{float(e.x()), float(e.y())};
    for(int i = 0; i < static_cast<int>(mTabRects.size()); i++) {
        if(SDL_PointInFRect(&pt, &mTabRects[i])) {
            if(mSeries != i) mShown = 0;
            mSeries = i;
            return true;
        }
    }
    for(int i = 0; i < static_cast<int>(mRangeRects.size()); i++) {
        if(SDL_PointInFRect(&pt, &mRangeRects[i])) {
            if(mRange != i) mShown = 0;
            mRange = i;
            return true;
        }
    }
    return true;
}

bool eHistoryChart::mouseMoveEvent(const eMouseEvent& e) {
    mMouseX = e.x();
    mMouseY = e.y();
    return true;
}

bool eHistoryChart::mouseLeaveEvent(const eMouseEvent& e) {
    (void)e;
    mMouseX = mMouseY = -1;
    return true;
}

void eCityHistoryWidget::initialize(const eCityHistory& history,
                                    const eAction& close,
                                    const bool instant) {
    setType(eFrameType::message);
    const auto res = resolution();
    const double m = res.multiplier();
    const int p = res.largePadding();
    const auto win = window();
    const int ww = std::min(static_cast<int>(720*m), win->width()*3/4);
    const int hh = std::min(static_cast<int>(500*m), win->height() - 8*p);
    resize(ww, hh);

    const auto title = new eLabel(tr("history_title", "City History"), window());
    title->setHugeFontSize();
    title->setYellowFontColor();
    title->fitContent();
    addWidget(title);
    title->align(eAlignment::top | eAlignment::hcenter);
    title->setY(title->y() + p);

    const auto ok = new eOkButton(window());
    addWidget(ok);
    ok->align(eAlignment::bottom | eAlignment::right);
    ok->move(ok->x() - 2*p, ok->y() - 2*p);
    ok->setPressAction(close);

    const auto chart = new eHistoryChart(window());
    chart->setNoPadding();
    chart->setSamples(history.samples());
    if(instant) chart->settle();
    addWidget(chart);
    const int top = title->y() + title->height() + p;
    chart->move(3*p, top);
    chart->resize(ww - 6*p, ok->y() - top - p/2);
}
