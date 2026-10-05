#include "etradesummarywidget.h"

#include "elabel.h"
#include "eokbutton.h"
#include "escrollwidgetcomplete.h"
#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "etexture.h"
#include "engine/etradesummary.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

const SDL_Color kDim{156, 170, 196, 255};
const SDL_Color kGreen{128, 214, 146, 255};
const SDL_Color kRed{240, 110, 90, 255};
const SDL_Color kAmber{255, 196, 110, 255};
const SDL_Color kGoldText{255, 222, 140, 255};

}

eTradeSummaryList::~eTradeSummaryList() {
    for(auto& t : mTexts) {
        if(t.second.fTex) SDL_DestroyTexture(t.second.fTex);
    }
}

eTradeSummaryList::eLine& eTradeSummaryList::add(const std::string& left,
                                                 const std::string& right,
                                                 const int font,
                                                 const int indent) {
    auto& l = mLines.emplace_back();
    l.fLeft = left;
    l.fRight = right;
    l.fFont = font;
    l.fIndent = indent;
    return l;
}

const eTradeSummaryList::eText& eTradeSummaryList::text(SDL_Renderer* const r,
                                                        const std::string& s,
                                                        const int px,
                                                        const eFontRole role) {
    auto& t = mTexts[{s, px, role}];
    if(!t.fTex && !s.empty()) {
        t.fTex = eMenu3D::makeText(r, eFonts::font(role, px), s,
                                   SDL_Color{255, 255, 255, 255}, t.fW, t.fH);
    }
    return t;
}

void eTradeSummaryList::initialize(eGameBoard& board, const eCityId cid,
                                   const int width) {
    setNoPadding();
    const auto res = resolution();
    const double m = res.multiplier();
    const auto color = [](const eTradeTone t) {
        switch(t) {
        case eTradeTone::dim: return kDim;
        case eTradeTone::green: return kGreen;
        case eTradeTone::red: return kRed;
        case eTradeTone::amber: return kAmber;
        case eTradeTone::gold: return kGoldText;
        case eTradeTone::label: return SDL_Color{200, 208, 222, 255};
        default: return SDL_Color{236, 230, 214, 255};
        }
    };
    for(const auto& s : eTradeSummary::lines(board, cid)) {
        auto& l = add(s.fLeft, s.fRight, s.fFont, s.fIndent);
        l.fLeftColor = color(s.fLeftTone);
        l.fRightColor = color(s.fRightTone);
        l.fHeader = s.fHeader;
        l.fCard = s.fCard;
        l.fIcon = s.fIcon;
    }
    // layout
    const int tiny = res.tinyFontSize();
    const int small = res.smallFontSize();
    int y = 0;
    for(auto& l : mLines) {
        const int px = l.fFont ? small : tiny;
        int tw = 0;
        int th = px;
        const auto role = l.fFont ? eFontRole::heading : eFontRole::body;
        if(const auto f = eFonts::font(role, px)) TTF_SizeUTF8(f, "Ag", &tw, &th);
        if(l.fHeader && y > 0) y += static_cast<int>(12*m);
        if(l.fCard) y += static_cast<int>(8*m);
        l.fY = y;
        l.fH = th + static_cast<int>((l.fHeader ? 8 : 3)*m);
        y += l.fH;
    }
    // each partner card spans its lines
    for(size_t i = 0; i < mLines.size(); i++) {
        if(!mLines[i].fCard) continue;
        size_t j = i + 1;
        while(j < mLines.size() && !mLines[j].fCard && !mLines[j].fHeader &&
              mLines[j].fIndent > 0) j++;
        mLines[i].fCardH = mLines[j - 1].fY + mLines[j - 1].fH - mLines[i].fY;
    }
    resize(width, y + static_cast<int>(8*m));
}

void eTradeSummaryList::paintEvent(ePainter& p) {
    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const auto res = resolution();
    const double m = res.multiplier();
    const float X = p.x();
    const float Y = p.y();
    const float W = width();
    const int tiny = res.tinyFontSize();
    const int small = res.smallFontSize();
    const float indentW = static_cast<float>(16*m);
    const float iconS = static_cast<float>(16*m);

    for(const auto& l : mLines) {
        if(l.fCard) {
            const SDL_FRect card{X, Y + l.fY - static_cast<float>(4*m), W,
                                 l.fCardH + static_cast<float>(8*m)};
            const float rad = static_cast<float>(8*m);
            ePanel::roundRect(r, card, rad, SDL_Color{34, 56, 100, 120}, SDL_Color{16, 26, 52, 120});
            ePanel::roundRect(r, card, rad, SDL_Color{240, 200, 110, 90}, SDL_Color{160, 112, 36, 60},
                              std::max(1.f, static_cast<float>(m)));
        }
    }
    for(const auto& l : mLines) {
        const int px = l.fFont ? small : tiny;
        float x = X + static_cast<float>(10*m) + l.fIndent*indentW;
        const float cy = Y + l.fY + l.fH/2.f;
        if(l.fIcon != eResourceType::none) {
            const auto tex = eResourceTypeHelpers::icon(res.uiScale(), l.fIcon);
            if(tex && tex->width() > 0 && tex->height() > 0) {
                const double s = std::min(iconS/tex->width(), iconS/tex->height());
                const int dw = std::round(tex->width()*s);
                const int dh = std::round(tex->height()*s);
                p.drawTextureScaled(SDL_Rect{static_cast<int>(x - X), static_cast<int>(cy - Y - dh/2.0), dw, dh}, tex);
                eGeometryBatch::sFlush();
            }
            x += iconS + static_cast<float>(6*m);
        }
        if(!l.fLeft.empty()) {
            const auto& t = text(r, l.fLeft, px,
                                 l.fFont ? eFontRole::heading : eFontRole::body);
            if(t.fTex) {
                const SDL_Color c = l.fHeader ? kGoldText : l.fLeftColor;
                SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
                SDL_SetTextureAlphaMod(t.fTex, c.a);
                const SDL_FRect d{std::round(x), std::round(cy - t.fH/2.f), float(t.fW), float(t.fH)};
                SDL_RenderCopyF(r, t.fTex, nullptr, &d);
            }
        }
        if(!l.fRight.empty()) {
            const auto& t = text(r, l.fRight, px);
            if(t.fTex) {
                const auto c = l.fRightColor;
                SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
                SDL_SetTextureAlphaMod(t.fTex, c.a);
                const SDL_FRect d{std::round(X + W - static_cast<float>(12*m) - t.fW),
                                  std::round(cy - t.fH/2.f), float(t.fW), float(t.fH)};
                SDL_RenderCopyF(r, t.fTex, nullptr, &d);
            }
        }
        if(l.fHeader) {
            ePanel::goldRule(r, X, Y + l.fY + l.fH - static_cast<float>(2*m), W,
                             std::max(1.f, static_cast<float>(m)), 170, false);
        }
    }
}

void eTradeSummaryWidget::initialize(eGameBoard& board, const eCityId cid,
                                     const eAction& close) {
    setType(eFrameType::message);
    const auto res = resolution();
    const double m = res.multiplier();
    const int p = res.largePadding();
    const auto win = window();
    const int ww = std::min(static_cast<int>(620*m), win->width()*3/4);
    const int hh = std::min(static_cast<int>(520*m), win->height() - 8*p);
    resize(ww, hh);

    const auto title = new eLabel(tr("trade_title", "Trade Summary"), window());
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

    const int top = title->y() + title->height() + p;
    const auto scroll = new eScrollWidgetComplete(window());
    addWidget(scroll);
    scroll->resize(ww - 4*p, ok->y() - top - p);
    scroll->move(2*p, top);
    scroll->initialize();

    const auto list = new eTradeSummaryList(window());
    list->initialize(board, cid, scroll->listWidth() - res.tinyPadding());
    scroll->setScrollArea(list);
}
