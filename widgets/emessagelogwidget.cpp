#include "emessagelogwidget.h"

#include "egamewidget.h"
#include <memory>
#include <functional>
#include "characters/echaracter.h"
#include "efonts.h"
#include "emenu3d.h"
#include "epanelwidgets.h"
#include "emessagebox.h"
#include "eokbutton.h"
#include "escrollwidgetcomplete.h"
#include "epanelstyle.h"
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

// One message: its date above its title; a gold diamond marks new ones.
class eMessageLogRow : public eButtonBase {
public:
    using eButtonBase::eButtonBase;

    void initialize(const std::string& date, const std::string& title,
                    const bool fresh, const int w, const eAction& goTo) {
        mFresh = fresh;
        setNoPadding();
        const int p = resolution().largePadding();
        int goW = 0;
        if(goTo) {
            const int s = std::round(22*resolution().multiplier());
            const auto b = new ePanelActionButton(window(), "map");
            b->resize(s, s);
            b->setTooltip(eLanguage::zeusText(12, 1)); // go to site of event
            b->setPressAction(goTo);
            addWidget(b);
            mGo = b;
            goW = s + p;
        }
        mDate = new eLabel(date, window());
        mDate->setNoPadding();
        mDate->setTinyFontSize();
        mDate->fitContent();
        addWidget(mDate);
        mTitle = new eLabel(window());
        mTitle->setNoPadding();
        mTitle->setSmallFontSize();
        mTitle->setWrapWidth(w - 4*p - goW);
        mTitle->setText(title);
        mTitle->fitContent();
        if(fresh) mTitle->setYellowFontColor();
        addWidget(mTitle);
        mDate->move(2*p, p/2);
        mTitle->move(2*p, mDate->y() + mDate->height());
        resize(w, mTitle->y() + mTitle->height() + p/2);
        if(mGo) mGo->move(w - mGo->width() - p, (height() - mGo->height())/2);
    }
protected:
    void paintEvent(ePainter& p) override {
        const double now = ePanel::time();
        const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
        mLast = now;
        mHover += ((hovered() ? 1.0 : 0.0) - mHover)*ePanel::approach(dt, 14);
        const auto r = p.renderer();
        eGeometryBatch::sFlush();
        const float x = p.x(), y = p.y(), w = width(), h = height();
        const SDL_FRect box{x + 1, y + 1, w - 2, h - 2};
        const Uint8 a = static_cast<Uint8>(40 + 70*mHover);
        ePanel::roundRect(r, box, h*.18f, SDL_Color{40, 62, 104, a}, SDL_Color{16, 26, 50, a});
        ePanel::roundRect(r, box, h*.18f, SDL_Color{240, 200, 110, static_cast<Uint8>(40 + 150*mHover)},
                          SDL_Color{160, 112, 36, static_cast<Uint8>(30 + 120*mHover)},
                          std::max(1.f, h/40.f));
        if(mFresh) {
            const float s = std::max(2.f, h*.07f);
            ePanel::glow(r, x + s*3, y + h/2, s*3, s*3, SDL_Color{255, 200, 90, 90}, true);
            ePanel::diamond(r, x + s*3, y + h/2, s, ePanel::kGoldPale);
        }
    }
private:
    eLabel* mDate = nullptr;
    eLabel* mTitle = nullptr;
    eWidget* mGo = nullptr;
    bool mFresh = false;
    double mHover = 0;
    double mLast = -1;
};

// All / Military / Trade / Gods / Disasters, each with its count.
class eMessageFilterBar : public eWidget {
public:
    using eWidget::eWidget;
    ~eMessageFilterBar() {
        for(auto& t : mTex) if(t.fTex) SDL_DestroyTexture(t.fTex);
    }
    void initialize(const std::vector<std::string>& labels, const int index,
                    const std::function<void(int)>& changed) {
        setNoPadding();
        mLabels = labels;
        mIndex = index;
        mChanged = changed;
        mTex.resize(labels.size());
    }
protected:
    void paintEvent(ePainter& p) override {
        const auto r = p.renderer();
        eGeometryBatch::sFlush();
        const int n = mLabels.size();
        if(n == 0) return;
        const float W = width();
        const float H = height();
        const float gap = std::max(2.f, H*0.12f);
        const float tw = (W - gap*(n - 1))/n;
        const int px = std::max(9, static_cast<int>(std::round(H*0.46f)));
        for(int i = 0; i < n; i++) {
            const SDL_FRect f{p.x() + i*(tw + gap), float(p.y()), tw, H};
            const bool on = i == mIndex;
            const bool hover = mMouseX >= f.x - p.x() && mMouseX < f.x - p.x() + tw && mMouseY >= 0;
            if(on) {
                ePanel::roundRect(r, f, H/2, SDL_Color{255, 224, 146, 255}, SDL_Color{196, 140, 48, 255});
            } else {
                ePanel::roundRect(r, f, H/2, SDL_Color{30, 50, 92, static_cast<Uint8>(hover ? 230 : 170)},
                                  SDL_Color{14, 24, 50, static_cast<Uint8>(hover ? 230 : 170)});
                ePanel::roundRect(r, f, H/2, SDL_Color{240, 200, 110, static_cast<Uint8>(hover ? 200 : 110)},
                                  SDL_Color{160, 112, 36, static_cast<Uint8>(hover ? 170 : 90)},
                                  std::max(1.f, H/24.f));
            }
            auto& t = mTex[i];
            if(!t.fTex || t.fPx != px) {
                if(t.fTex) SDL_DestroyTexture(t.fTex);
                t.fPx = px;
                t.fTex = eMenu3D::makeText(r, eFonts::labelFont(px), mLabels[i],
                                           SDL_Color{255, 255, 255, 255}, t.fW, t.fH);
            }
            if(t.fTex) {
                const SDL_Color c = on ? ePanel::kInk : (hover ? ePanel::kGoldPale : ePanel::kGold);
                SDL_SetTextureColorMod(t.fTex, c.r, c.g, c.b);
                const float s = std::min(1.f, (tw - H*0.5f)/std::max(1, t.fW));
                const SDL_FRect d{std::round(f.x + (tw - t.fW*s)/2), std::round(f.y + (H - t.fH*s)/2),
                                  t.fW*s, t.fH*s};
                SDL_RenderCopyF(r, t.fTex, nullptr, &d);
            }
        }
    }
    bool mousePressEvent(const eMouseEvent& e) override {
        return e.button() == eMouseButton::left;
    }
    bool mouseReleaseEvent(const eMouseEvent& e) override {
        if(e.button() != eMouseButton::left) return false;
        const int n = mLabels.size();
        if(n == 0) return true;
        const float gap = std::max(2.f, height()*0.12f);
        const float tw = (width() - gap*(n - 1))/n;
        const int i = std::clamp(static_cast<int>(e.x()/(tw + gap)), 0, n - 1);
        if(i != mIndex) {
            mIndex = i;
            if(mChanged) mChanged(i);
        }
        return true;
    }
    bool mouseMoveEvent(const eMouseEvent& e) override {
        mMouseX = e.x();
        mMouseY = e.y();
        return true;
    }
    bool mouseLeaveEvent(const eMouseEvent& e) override {
        (void)e;
        mMouseX = mMouseY = -1;
        return true;
    }
private:
    struct eText {
        SDL_Texture* fTex = nullptr;
        int fW = 0;
        int fH = 0;
        int fPx = 0;
    };
    std::vector<std::string> mLabels;
    std::vector<eText> mTex;
    int mIndex = 0;
    int mMouseX = -1;
    int mMouseY = -1;
    std::function<void(int)> mChanged;
};
}

eMessageLogWidget::~eMessageLogWidget() {
    if(mList && *mList) (*mList)->deleteLater();
}

void eMessageLogWidget::initialize(eGameWidget* const gw, const int seenBefore,
                                   const eAction& close) {
    setType(eFrameType::message);
    const auto res = resolution();
    const double m = res.multiplier();
    const int p = res.largePadding();
    const auto win = window();
    const int ww = std::min(static_cast<int>(520*m), win->width()*2/3);
    const int hh = std::min(static_cast<int>(470*m), win->height() - 8*p);
    resize(ww, hh);

    const auto title = new eLabel(tr("messages_title", "Messages"), window());
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

    const auto& log = gw->messageLog();

    // filter tabs; a tab shows how many messages it holds
    const std::pair<const char*, const char*> names[] = {
        {"messages_all", "All"}, {"messages_military", "Military"},
        {"messages_trade", "Trade"}, {"messages_gods", "Gods"},
        {"messages_disasters", "Disasters"}};
    const eMessageCategory cats[] = {eMessageCategory::other, eMessageCategory::military,
                                     eMessageCategory::trade, eMessageCategory::gods,
                                     eMessageCategory::disasters};
    std::vector<std::string> labels;
    for(int i = 0; i < 5; i++) {
        int count = 0;
        for(const auto& e : log) {
            if(i == 0 || e.fCategory == cats[i]) count++;
        }
        labels.push_back(tr(names[i].first, names[i].second) + " " + std::to_string(count));
    }
    const auto bar = new eMessageFilterBar(window());
    addWidget(bar);
    bar->resize(ww - 6*p, std::round(22*m));
    bar->move(3*p, title->y() + title->height() + p/2);

    const int top = bar->y() + bar->height() + p/2;
    const auto scroll = new eScrollWidgetComplete(window());
    addWidget(scroll);
    scroll->resize(ww - 4*p, ok->y() - top - p);
    scroll->move(2*p, top);
    scroll->initialize();

    const auto list = std::make_shared<eWidget*>(nullptr);
    mList = list;
    const auto fill = [this, gw, scroll, list, close, seenBefore, p, cats](const int filter) {
        const auto& log = gw->messageLog();
        const auto res = resolution();
        if(*list) (*list)->deleteLater();
        const auto l = new eWidget(window());
        *list = l;
        l->setNoPadding();
        const int rowW = scroll->listWidth() - 2*res.tinyPadding();
        int y = 0;
        for(int i = static_cast<int>(log.size()) - 1; i >= 0; i--) {
            const auto& e = log[i];
            if(filter > 0 && e.fCategory != cats[filter]) continue;
            eAction goTo;
            eTile* tile = e.fEd.fTile;
            if(const auto ch = e.fEd.fChar) {
                if(ch->tile()) tile = ch->tile();
            }
            if(tile) {
                goTo = [gw, tile, close]() {
                    close();
                    gw->viewTile(tile);
                };
            }
            const auto row = new eMessageLogRow(window());
            const auto t = eMessageBox::sFormatTitle(e.fEd, e.fMsg.fTitle);
            row->initialize(e.fEd.fDate.shortString(), t, i >= seenBefore, rowW, goTo);
            row->setPressAction([gw, i, close]() {
                close();
                gw->replayMessage(i);
            });
            l->addWidget(row);
            row->setY(y);
            y += row->height() + p/3;
        }
        if(y == 0) {
            const auto empty = new eLabel(tr("messages_empty", "No messages yet"), window());
            empty->setSmallFontSize();
            empty->fitContent();
            l->addWidget(empty);
            empty->move((rowW - empty->width())/2, 3*p);
        }
        l->fitContent();
        l->setWidth(rowW);
        scroll->setScrollArea(l);
        scroll->scrollToTheTop();
    };
    const int filter = std::clamp(gw->messageFilter(), 0, 4);
    bar->initialize(labels, filter, [gw, fill](const int f) {
        gw->setMessageFilter(f);
        fill(f);
    });
    fill(filter);
}
