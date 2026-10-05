#include "ehousehovercard.h"

#include "buildings/esmallhouse.h"
#include "buildings/eelitehousing.h"
#include "buildings/ehousecard.h"
#include "engine/egameboard.h"
#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "elanguage.h"
#include "etexture.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>
#include <cstdio>

namespace {

SDL_Color alpha(SDL_Color c, const double a) {
    c.a = static_cast<Uint8>(std::round(c.a*std::clamp(a, 0.0, 1.0)));
    return c;
}


const SDL_Color kRed{240, 96, 74, 255};
const SDL_Color kGreen{128, 214, 146, 255};
const SDL_Color kDim{156, 170, 196, 255};
}

eHouseHoverCard::~eHouseHoverCard() {
    clear();
}

void eHouseHoverCard::clear() {
    for(auto& t : mTexts) {
        if(t.fTex) SDL_DestroyTexture(t.fTex);
    }
    mTexts.clear();
    mIcons.clear();
}

eHouseHoverCard::eText& eHouseHoverCard::addText(
        const std::string& text, const int fontPx,
        const SDL_Color c, const int x, const int y,
        const eFontRole role) {
    auto& t = mTexts.emplace_back();
    t.fText = text;
    t.fFontPx = fontPx;
    t.fRole = role;
    t.fColor = c;
    t.fX = x;
    t.fY = y;
    if(const auto font = eFonts::font(role, fontPx)) {
        TTF_SizeUTF8(eFonts::forText(font, text), text.c_str(), &t.fW, &t.fH);
    }
    return t;
}

bool eHouseHoverCard::setHouse(eHouseBase* const h) {
    const auto card = eHouseCards::card(h);
    if(!card.fValid) return false;
    const auto sig = card.signature();
    if(sig == mSignature) return true;
    mSignature = sig;
    clear();
    const auto res = resolution();
    const double m = res.multiplier();
    const auto u = [m](const double v) { return static_cast<int>(std::round(v*m)); };
    const int pad = u(11);
    const int titleF = res.smallFontSize();
    const int textF = res.tinyFontSize();
    const int noteF = std::max(8, static_cast<int>(std::round(textF*0.88)));
    int wMax = u(230);

    mLevel = card.fLevel;
    mLevels = card.fLevels;
    mTone = card.fTone;

    int y = pad;
    {
        auto& t = addText(card.fName, titleF, SDL_Color{255, 222, 140, 255}, pad, y,
                          eFontRole::display);
        wMax = std::max(wMax, t.fW + 2*pad);
        y += t.fH;
    }
    {
        auto& t = addText(card.fResidents, textF, kDim, pad, y);
        mPipsX = pad + t.fW + u(10);
        mPipsY = y + t.fH/2;
        wMax = std::max(wMax, mPipsX + mLevels*u(10) + pad);
        y += t.fH;
    }
    y += u(5);
    mRuleY = y;
    y += u(6);
    {
        const SDL_Color c = card.fTone == 1 ? kRed : card.fTone == 2 ? kGreen : SDL_Color{236, 228, 208, 255};
        auto& t = addText(card.fStatus, textF, c, pad, y);
        wMax = std::max(wMax, t.fW + 2*pad);
        y += t.fH + u(3);
    }

    if(!card.fLines.empty()) {
        const int markS = u(11);
        const int iconS = u(17);
        const int iconX = pad + markS + u(6);
        const int labelX = iconX + iconS + u(7);
        const int rowH = std::max(iconS, textF + u(2)) + u(5);
        for(const auto& l : card.fLines) {
            const int cy = y + rowH/2;
            auto& mark = mIcons.emplace_back();
            mark.fSvg = l.fMet ? "check" : "close";
            mark.fColor = l.fMet ? kGreen : kRed;
            mark.fX = pad + markS/2;
            mark.fY = cy;
            mark.fS = markS;
            auto& ic = mIcons.emplace_back();
            if(!l.fIcon.empty()) {
                ic.fSvg = l.fIcon;
                ic.fColor = ePanel::kGoldPale;
            } else {
                ic.fRes = eResourceTypeHelpers::icon(res.uiScale(), l.fResource);
            }
            ic.fX = iconX + iconS/2;
            ic.fY = cy;
            ic.fS = iconS;
            const SDL_Color lc = l.fMet ? SDL_Color{190, 196, 206, 255} : SDL_Color{246, 240, 226, 255};
            auto& lt = addText(l.fLabel, textF, lc, labelX, 0);
            lt.fY = cy - lt.fH/2;
            int rowW = labelX + lt.fW + pad;
            if(!l.fDetail.empty()) {
                const SDL_Color dc = l.fMet ? kDim : SDL_Color{255, 190, 110, 255};
                auto& dt = addText(l.fDetail, textF, dc, 0, 0);
                dt.fY = cy - dt.fH/2;
                dt.fX = -dt.fW; // right aligned below, once the width is known
                rowW += dt.fW + u(14);
            }
            wMax = std::max(wMax, rowW);
            y += rowH;
            if(!l.fNote.empty()) {
                // wrapped by words to the card's usual width
                const int maxW = std::max(wMax, u(270)) - labelX - pad;
                const auto font = eFonts::defaultFont(noteF);
                std::vector<std::string> rows{""};
                size_t i = 0;
                while(i < l.fNote.size()) {
                    size_t j = l.fNote.find(' ', i);
                    if(j == std::string::npos) j = l.fNote.size();
                    const auto word = l.fNote.substr(i, j - i);
                    const auto tryRow = rows.back().empty() ? word : rows.back() + " " + word;
                    int tw = 0, th = 0;
                    if(font) TTF_SizeUTF8(eFonts::forText(font, tryRow), tryRow.c_str(), &tw, &th);
                    if(tw > maxW && !rows.back().empty()) rows.push_back(word);
                    else rows.back() = tryRow;
                    i = j + 1;
                }
                int ny = y - u(4);
                for(const auto& row : rows) {
                    auto& nt = addText(row, noteF, kDim, labelX, ny);
                    wMax = std::max(wMax, labelX + nt.fW + pad);
                    ny += nt.fH;
                }
                y = ny + u(4);
            }
        }
    }
    y += pad - u(3);
    for(auto& t : mTexts) {
        if(t.fX < 0) t.fX = wMax - pad + t.fX;
    }
    resize(wMax, y);
    return true;
}

void eHouseHoverCard::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    mShow = std::min(1.0, mShow + dt/0.14);
    const double a = eMenu3D::easeOutCubic(mShow);
    if(a <= 0.01) return;

    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float x = p.x();
    const float y = p.y() + static_cast<float>((1 - a)*height()*0.06);
    const float w = width();
    const float h = height();
    const double m = resolution().multiplier();
    const float line = std::max(1.f, static_cast<float>(m));
    const float rad = static_cast<float>(9*m);

    ePanel::glow(r, x + w/2, y + h*0.6f, w*0.64f, h*0.72f, alpha(SDL_Color{0, 0, 0, 160}, a), false);
    const SDL_FRect card{x, y, w, h};
    ePanel::roundRect(r, card, rad, alpha(SDL_Color{24, 40, 76, 244}, a),
                      alpha(SDL_Color{11, 19, 40, 244}, a));
    SDL_Color rimTop{246, 208, 120, 230};
    if(mTone == 1) rimTop = SDL_Color{250, 130, 100, 230};
    ePanel::roundRect(r, card, rad, alpha(rimTop, a),
                      alpha(SDL_Color{150, 106, 34, 220}, a), line);
    ePanel::goldRule(r, x + rad, y + mRuleY, w - 2*rad, line,
                     static_cast<Uint8>(170*a), false);

    // level pips: filled up to the current level
    const float ps = static_cast<float>(3.2*m);
    for(int i = 0; i < mLevels; i++) {
        const float px = x + mPipsX + i*static_cast<float>(10*m) + ps;
        const bool on = i <= mLevel;
        if(on) {
            ePanel::diamond(r, px, y + mPipsY, ps, alpha(ePanel::kGold, a));
        } else {
            ePanel::diamond(r, px, y + mPipsY, ps, alpha(SDL_Color{120, 132, 160, 150}, a));
            ePanel::diamond(r, px, y + mPipsY, ps*0.55f, alpha(SDL_Color{16, 26, 50, 255}, a));
        }
    }

    for(const auto& ic : mIcons) {
        if(!ic.fSvg.empty()) {
            ePanel::drawIcon(r, ic.fSvg, x + ic.fX, y + ic.fY, ic.fS, alpha(ic.fColor, a));
        } else if(ic.fRes && a > 0.6) {
            const int tw = ic.fRes->width();
            const int th = ic.fRes->height();
            if(tw <= 0 || th <= 0) continue;
            const double s = std::min(double(ic.fS)/tw, double(ic.fS)/th);
            const int dw = static_cast<int>(std::round(tw*s));
            const int dh = static_cast<int>(std::round(th*s));
            const SDL_Rect d{static_cast<int>(std::round(ic.fX - dw/2.0)),
                             static_cast<int>(std::round(y - p.y() + ic.fY - dh/2.0)),
                             dw, dh};
            p.drawTextureScaled(d, ic.fRes);
            eGeometryBatch::sFlush();
        }
    }

    for(auto& t : mTexts) {
        if(!t.fTex) {
            int tw, th;
            t.fTex = eMenu3D::makeText(r, eFonts::font(t.fRole, t.fFontPx), t.fText,
                                       SDL_Color{255, 255, 255, 255}, tw, th);
            t.fW = tw;
            t.fH = th;
        }
        if(!t.fTex) continue;
        const float o = std::max(1.f, static_cast<float>(m));
        SDL_SetTextureColorMod(t.fTex, 0, 0, 0);
        SDL_SetTextureAlphaMod(t.fTex, static_cast<Uint8>(130*a));
        const SDL_FRect sd{x + t.fX, y + t.fY + o, float(t.fW), float(t.fH)};
        SDL_RenderCopyF(r, t.fTex, nullptr, &sd);
        SDL_SetTextureColorMod(t.fTex, t.fColor.r, t.fColor.g, t.fColor.b);
        SDL_SetTextureAlphaMod(t.fTex, static_cast<Uint8>(t.fColor.a*a));
        const SDL_FRect d{x + t.fX, y + t.fY, float(t.fW), float(t.fH)};
        SDL_RenderCopyF(r, t.fTex, nullptr, &d);
    }
}
