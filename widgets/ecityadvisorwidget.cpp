#include "ecityadvisorwidget.h"

#include "egamewidget.h"
#include "elabel.h"
#include "eokbutton.h"
#include "escrollwidgetcomplete.h"
#include "epanelstyle.h"
#include "epanelwidgets.h"
#include "efonts.h"
#include "elanguage.h"
#include "emainwindow.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}
}

namespace {
// One advice: a tone disc with its icon, the title, the detail and the
// hint, and a "Go there" button when it has places.
class eAdviceRow : public eWidget {
public:
    using eWidget::eWidget;
    ~eAdviceRow() {
        for(auto& t : mTexts) {
            if(t.fTex) SDL_DestroyTexture(t.fTex);
            if(t.fSurf) SDL_FreeSurface(t.fSurf);
        }
    }

    void initialize(const eAdvice& a, const int w, const std::string& goText,
                    const eAction& go) {
        setNoPadding();
        mSeverity = a.fSeverity;
        mIcon = a.fIcon;
        const auto res = resolution();
        const double m = res.multiplier();
        mPad = std::round(10*m);
        mDisc = std::round(30*m);
        const int textX = mPad + mDisc + std::round(10*m);
        int goW = 0;
        if(go) {
            const auto b = new ePanelPillButton(window(), goText);
            const int bh = std::round(22*m);
            int tw = 0;
            int th = 0;
            if(const auto f = eFonts::labelFont(std::max(9, static_cast<int>(std::round(bh*0.46f))))) {
                TTF_SizeUTF8(eFonts::forText(f, goText), goText.c_str(), &tw, &th);
            }
            b->resize(tw + std::round(26*m), bh);
            b->setPressAction(go);
            addWidget(b);
            mGo = b;
            goW = b->width() + mPad;
        }
        const int wrap = w - textX - mPad - goW;
        int y = mPad;
        const auto add = [&](const std::string& s, const int px, const SDL_Color c,
                             const eFontRole role = eFontRole::body) {
            if(s.empty()) return;
            auto& t = mTexts.emplace_back();
            const auto f = eFonts::font(role, px);
            if(f) t.fSurf = TTF_RenderUTF8_Blended_Wrapped(eFonts::forText(f, s), s.c_str(), SDL_Color{255, 255, 255, 255},
                                                         std::max(1, wrap));
            t.fColor = c;
            t.fX = textX;
            t.fY = y;
            if(t.fSurf) y += t.fSurf->h + std::round(2*m);
        };
        const SDL_Color titleC = a.fSeverity == 2 ? SDL_Color{255, 170, 140, 255} :
                                 a.fSeverity == 1 ? SDL_Color{255, 222, 140, 255} :
                                                    SDL_Color{150, 226, 170, 255};
        add(a.fTitle, res.smallFontSize(), titleC, eFontRole::heading);
        add(a.fDetail, res.tinyFontSize(), SDL_Color{236, 230, 214, 255});
        add(a.fHint, std::max(8, static_cast<int>(std::round(res.tinyFontSize()*0.92))),
            SDL_Color{156, 170, 196, 255});
        const int h = std::max(y + mPad - static_cast<int>(std::round(2*m)), mDisc + 2*mPad);
        resize(w, h);
        if(mGo) mGo->move(w - mGo->width() - mPad, (h - mGo->height())/2);
    }
protected:
    void paintEvent(ePainter& p) override {
        const auto r = p.renderer();
        eGeometryBatch::sFlush();
        const double m = resolution().multiplier();
        const float x = p.x();
        const float y = p.y();
        const float w = width();
        const float h = height();
        const float rad = static_cast<float>(8*m);
        const SDL_FRect card{x, y, w, h};
        ePanel::roundRect(r, card, rad, SDL_Color{34, 56, 100, 130}, SDL_Color{14, 24, 50, 130});
        SDL_Color rim{240, 200, 110, 110};
        if(mSeverity == 2) rim = SDL_Color{250, 120, 96, 170};
        ePanel::roundRect(r, card, rad, rim, SDL_Color{150, 106, 34, 70}, std::max(1.f, static_cast<float>(m)));
        SDL_Color top{44, 76, 140, 255};
        SDL_Color bottom{18, 34, 74, 255};
        if(mSeverity == 2) {
            top = SDL_Color{214, 64, 46, 255};
            bottom = SDL_Color{112, 20, 18, 255};
        } else if(mSeverity == 0) {
            top = SDL_Color{70, 150, 96, 255};
            bottom = SDL_Color{24, 72, 46, 255};
        }
        const float cx = x + mPad + mDisc/2.f;
        const float cy = y + mPad + mDisc/2.f;
        const SDL_FRect disc{cx - mDisc/2.f, cy - mDisc/2.f, float(mDisc), float(mDisc)};
        ePanel::roundRect(r, disc, mDisc/2.f, top, bottom);
        ePanel::roundRect(r, disc, mDisc/2.f, SDL_Color{255, 226, 150, 255}, SDL_Color{168, 118, 40, 255},
                          std::max(1.f, static_cast<float>(m)));
        ePanel::drawIcon(r, mIcon, cx, cy, static_cast<int>(std::round(mDisc*0.58)), ePanel::kIvory);
        for(auto& t : mTexts) {
            if(!t.fSurf) continue;
            if(!t.fTex) {
                t.fTex = SDL_CreateTextureFromSurface(r, t.fSurf);
                if(t.fTex) SDL_SetTextureBlendMode(t.fTex, SDL_BLENDMODE_BLEND);
            }
            if(!t.fTex) continue;
            SDL_SetTextureColorMod(t.fTex, t.fColor.r, t.fColor.g, t.fColor.b);
            const SDL_FRect d{x + t.fX, y + t.fY, float(t.fSurf->w), float(t.fSurf->h)};
            SDL_RenderCopyF(r, t.fTex, nullptr, &d);
        }
    }
private:
    struct eText {
        SDL_Surface* fSurf = nullptr;
        SDL_Texture* fTex = nullptr;
        SDL_Color fColor;
        int fX = 0;
        int fY = 0;
    };
    std::vector<eText> mTexts;
    std::string mIcon;
    int mSeverity = 1;
    int mPad = 0;
    int mDisc = 0;
    eWidget* mGo = nullptr;
};
}

void eCityAdvisorWidget::initialize(eGameWidget* const gw, eGameBoard& board,
                                    const eCityId cid, const eAction& close) {
    setType(eFrameType::message);
    const auto res = resolution();
    const double m = res.multiplier();
    const int p = res.largePadding();
    const auto win = window();
    const int ww = std::min(static_cast<int>(620*m), win->width()*3/4);
    const int hh = std::min(static_cast<int>(540*m), win->height() - 8*p);
    resize(ww, hh);

    const auto title = new eLabel(tr("adv_title", "City Advisor"), window());
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

    const auto list = new eWidget(window());
    list->setNoPadding();
    const int rowW = scroll->listWidth() - res.tinyPadding();
    int y = 0;
    const auto advice = eCityAdvisor::collect(board, cid);
    for(const auto& a : advice) {
        const auto row = new eAdviceRow(window());
        eAction go;
        std::string goText;
        if(!a.fPlaces.empty()) {
            const int n = a.fPlaces.size();
            const int next = gw->advisorPlaceIndex(a.fKey, n);
            goText = tr("adv_go", "Go there");
            if(n > 1) goText += "  " + std::to_string(next + 1) + "/" + std::to_string(n);
            const auto key = a.fKey;
            const auto places = a.fPlaces;
            go = [gw, key, places, close]() {
                close();
                gw->advisorGoTo(key, places);
            };
        }
        row->initialize(a, rowW, goText, go);
        list->addWidget(row);
        row->setY(y);
        y += row->height() + p/2;
    }
    list->fitContent();
    list->setWidth(rowW);
    scroll->setScrollArea(list);
}
