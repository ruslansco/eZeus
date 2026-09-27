#include "emessagelogwidget.h"

#include "egamewidget.h"
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
                    const bool fresh, const int w) {
        mFresh = fresh;
        setNoPadding();
        const int p = resolution().largePadding();
        mDate = new eLabel(date, window());
        mDate->setNoPadding();
        mDate->setTinyFontSize();
        mDate->fitContent();
        addWidget(mDate);
        mTitle = new eLabel(window());
        mTitle->setNoPadding();
        mTitle->setSmallFontSize();
        mTitle->setWrapWidth(w - 4*p);
        mTitle->setText(title);
        mTitle->fitContent();
        if(fresh) mTitle->setYellowFontColor();
        addWidget(mTitle);
        mDate->move(2*p, p/2);
        mTitle->move(2*p, mDate->y() + mDate->height());
        resize(w, mTitle->y() + mTitle->height() + p/2);
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
    bool mFresh = false;
    double mHover = 0;
    double mLast = -1;
};
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
    const int top = title->y() + title->height() + p;
    const auto scroll = new eScrollWidgetComplete(window());
    addWidget(scroll);
    scroll->resize(ww - 4*p, ok->y() - top - p);
    scroll->move(2*p, top);
    scroll->initialize();

    const auto list = new eWidget(window());
    list->setNoPadding();
    const int rowW = scroll->listWidth() - 2*res.tinyPadding();
    int y = 0;
    for(int i = static_cast<int>(log.size()) - 1; i >= 0; i--) {
        const auto& e = log[i];
        const auto row = new eMessageLogRow(window());
        const auto t = eMessageBox::sFormatTitle(e.fEd, e.fMsg.fTitle);
        row->initialize(e.fEd.fDate.shortString(), t, i >= seenBefore, rowW);
        row->setPressAction([gw, i, close]() {
            close();
            gw->replayMessage(i);
        });
        list->addWidget(row);
        row->setY(y);
        y += row->height() + p/3;
    }
    if(log.empty()) {
        const auto empty = new eLabel(tr("messages_empty", "No messages yet"), window());
        empty->setSmallFontSize();
        empty->fitContent();
        list->addWidget(empty);
        empty->move((rowW - empty->width())/2, 3*p);
    }
    list->fitContent();
    list->setWidth(rowW);
    scroll->setScrollArea(list);
}
