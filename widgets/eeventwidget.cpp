#include "eeventwidget.h"

#include "engine/egameboard.h"
#include "engine/eevent.h"
#include "textures/egametextures.h"
#include "engine/eeventdata.h"
#include "epanelstyle.h"

#include <cmath>

static bool sHasAlert(const eEvent e) {
    switch(e) {
    case eEvent::fire:
    case eEvent::collapse:
    case eEvent::earthquake:
    case eEvent::earthquakeGod:
    case eEvent::tidalWave:
    case eEvent::tidalWaveGod:
    case eEvent::lavaFlow:
    case eEvent::godVisit:
    case eEvent::godHelp:
    case eEvent::godInvasion:
    case eEvent::playerGodAttack:
    case eEvent::monsterInvasion:
    case eEvent::godMonsterUnleash:
    case eEvent::monsterInCity:
    case eEvent::heroArrival:
    case eEvent::invasion:
    case eEvent::playerInvasion:
    case eEvent::plague:
    case eEvent::armyReturns:
    case eEvent::aidArrives:
        return true;
    default:
        return false;
    }
}

eEventWidget::~eEventWidget() {
    clear();
}

void eEventWidget::removeEventItem(eEventItem& item) {
    if(item.fButton) {
        removeWidget(item.fButton);
        item.fButton->deleteLater();
        item.fButton = nullptr;
    }
}

void eEventWidget::relayout() {
    stackHorizontally();
    if(!mEvents.empty() && mEvents.front().fButton) {
        const auto btn = mEvents.front().fButton;
        setHeight(btn->height());
        setWidth(static_cast<int>(mEvents.size()) * btn->width());
    } else {
        setWidth(0);
        setHeight(0);
    }
}

void eEventWidget::pushEvent(const eEvent e, const eEventData& ed) {
    if(!sHasAlert(e)) {
        return;
    }

    // Deduplicate: if an alert for the same event and target already exists, refresh timer
    for(auto& item : mEvents) {
        if(item.fEvent == e) {
            bool sameTarget = false;
            if(ed.fChar && item.fChar && ed.fChar == item.fChar) {
                sameTarget = true;
            } else if(ed.fTile && item.fTile && ed.fTile == item.fTile) {
                sameTarget = true;
            }
            if(sameTarget) {
                item.fRemainingFrames = 420; // Refresh lifetime (~7s at 60fps)
                return;
            }
        }
    }

    // Maximum 4 notifications on screen: remove oldest if capacity reached
    while(mEvents.size() >= 4) {
        removeEventItem(mEvents.back());
        mEvents.pop_back();
    }

    const auto button = new eEventButton(e, window());
    prependWidget(button);

    eEventItem item;
    item.fButton = button;
    item.fRemainingFrames = 420;
    item.fEvent = e;
    item.fTile = ed.fTile;
    item.fChar = ed.fChar;
    mEvents.insert(mEvents.begin(), item);

    button->setPressAction([this, ed]() {
        if(mViewTileHandler) {
            const auto ch = ed.fChar;
            if(ch) {
                const auto tile = ch->tile();
                mViewTileHandler(tile);
            } else {
                const auto tile = ed.fTile;
                mViewTileHandler(tile);
            }
        }
    });

    const auto btnPtr = button;
    button->setRightPressAction([this, btnPtr]() {
        for(auto it = mEvents.begin(); it != mEvents.end(); ++it) {
            if(it->fButton == btnPtr) {
                removeEventItem(*it);
                mEvents.erase(it);
                relayout();
                break;
            }
        }
    });

    relayout();
}

void eEventWidget::tick() {
    if(mEvents.empty()) return;

    bool changed = false;
    for(auto it = mEvents.begin(); it != mEvents.end(); ) {
        it->fRemainingFrames--;
        if(it->fRemainingFrames <= 0) {
            removeEventItem(*it);
            it = mEvents.erase(it);
            changed = true;
        } else {
            ++it;
        }
    }

    if(changed) {
        relayout();
    }
}

void eEventWidget::clear() {
    for(auto& item : mEvents) {
        removeEventItem(item);
    }
    mEvents.clear();
    relayout();
}

void eEventWidget::setViewTileHandler(const eViewTileHandler& h) {
    mViewTileHandler = h;
}

eEventButton::eEventButton(const eEvent e,
                           eMainWindow* const window) :
    eButton(window) {
    const auto intrfc = eGameTextures::interface();
    const auto uiScale = resolution().uiScale();
    const int iRes = static_cast<int>(uiScale);
    const auto& texs = intrfc[iRes];
    const eTextureCollection* coll = nullptr;
    switch(e) {
    case eEvent::fire:
        coll = &texs.fFireAlert;
        break;
    case eEvent::collapse:
        coll = &texs.fCollapseAltert;
        break;
    case eEvent::earthquake:
    case eEvent::earthquakeGod:
        coll = &texs.fGroundFissureAlert;
        break;
    case eEvent::tidalWave:
    case eEvent::tidalWaveGod:
        coll = &texs.fFloodAlert;
        break;
    case eEvent::lavaFlow:
        coll = &texs.fLavaAltert;
        break;

    case eEvent::godVisit:
    case eEvent::godHelp:
        coll = &texs.fGodVisitAlert;
        break;

    case eEvent::godInvasion:
    case eEvent::playerGodAttack:
        coll = &texs.fGodAttackAlert;
        break;
    case eEvent::monsterInvasion:
    case eEvent::godMonsterUnleash:
    case eEvent::monsterInCity:
        coll = &texs.fMonsterAltert;
        break;
    case eEvent::heroArrival:
        coll = &texs.fHeroArrivalAlert;
        break;
    case eEvent::invasion:
    case eEvent::playerInvasion:
        coll = &texs.fInvasionAlert;
        break;
    case eEvent::plague:
        coll = &texs.fIllnessAlert;
        break;
    case eEvent::armyReturns:
    case eEvent::aidArrives:
        coll = &texs.fArmyComebackAlert;
        break;
    default:
        return;
    }

    if(!coll) return;

    setTexture(coll->getTexture(0));
    setHoverTexture(coll->getTexture(1));
    setPressedTexture(coll->getTexture(2));

    setNoPadding();
    fitContent();
}

// An alert on a tile that pulses red, popping in when it arrives.
void eEventButton::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    if(mBorn < 0) mBorn = now;
    const double age = now - mBorn;
    const double pop = age < .35 ? 1 + .25*std::sin(age/.35*3.14159) : 1;
    const double pulse = .55 + .45*std::sin(now*5);
    const auto r = p.renderer();
    const float w = width(), h = height();
    const float cx = p.x() + w/2, cy = p.y() + h/2;
    const float s = static_cast<float>(std::min(w, h)*.92*pop);
    const SDL_FRect box{cx - s/2, cy - s/2, s, s};
    ePanel::glow(r, cx, cy + s*.06f, s*.62f, s*.62f, SDL_Color{0, 0, 0, 140}, false);
    ePanel::glow(r, cx, cy, s*.85f, s*.85f,
                 SDL_Color{255, 70, 40, static_cast<Uint8>((hovered() ? 120 : 70)*pulse)}, true);
    ePanel::roundRect(r, box, s*.2f, SDL_Color{70, 18, 20, 235}, SDL_Color{28, 8, 12, 240});
    ePanel::roundRect(r, box, s*.2f, SDL_Color{255, 120, 90, static_cast<Uint8>(150 + 100*pulse)},
                      SDL_Color{200, 50, 40, static_cast<Uint8>(150 + 100*pulse)}, std::max(1.f, s/22.f));
    const auto& tex = texture();
    if(tex) {
        const float k = s*.84f/std::max(tex->width(), tex->height());
        const int dw = std::round(tex->width()*k);
        const int dh = std::round(tex->height()*k);
        const SDL_Rect src{tex->x(), tex->y(), tex->width(), tex->height()};
        const SDL_Rect dst{static_cast<int>(std::round(cx - dw/2.f)), static_cast<int>(std::round(cy - dh/2.f)), dw, dh};
        tex->render(r, src, dst);
    }
}
