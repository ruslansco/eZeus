#include "eshortcutsheet.h"

#include "esettings.h"
#include "epanelstyle.h"
#include "efonts.h"
#include "emenu3d.h"
#include "elanguage.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>

namespace {
std::string tr(const std::string& key, const std::string& fallback) {
    const auto& s = eLanguage::text(key);
    return s.empty() ? fallback : s;
}

SDL_Color alpha(SDL_Color c, const double a) {
    c.a = static_cast<Uint8>(std::round(c.a*std::clamp(a, 0.0, 1.0)));
    return c;
}

std::string keyName(const SDL_Scancode k) {
    switch(k) {
    case SDL_SCANCODE_ESCAPE: return "Esc";
    case SDL_SCANCODE_DELETE: return "Del";
    case SDL_SCANCODE_RETURN: return "Enter";
    case SDL_SCANCODE_BACKSPACE: return "Backspace";
    default: break;
    }
    const std::string n = SDL_GetScancodeName(k);
    return n.empty() ? "?" : n;
}

struct eRow {
    std::vector<std::string> fCaps;
    std::string fText;
    bool fHeading = false;
};

eRow heading(const std::string& t) {
    eRow r;
    r.fText = t;
    r.fHeading = true;
    return r;
}

const SDL_Color kHead{255, 214, 120, 255};
const SDL_Color kRowText{232, 226, 210, 255};
const SDL_Color kCapText{250, 244, 228, 255};
const SDL_Color kDim{156, 170, 196, 255};
}

eShortcutSheet::~eShortcutSheet() {
    clear();
}

void eShortcutSheet::clear() {
    for(auto& t : mTexts) {
        if(t.fTex) SDL_DestroyTexture(t.fTex);
    }
    mTexts.clear();
    mCaps.clear();
    mRules.clear();
}

void eShortcutSheet::sTextSize(const std::string& text, const int fontPx,
                               int& w, int& h, const eFontRole role) {
    w = h = 0;
    if(const auto font = eFonts::font(role, fontPx)) {
        TTF_SizeUTF8(eFonts::forText(font, text), text.c_str(), &w, &h);
    }
}

eShortcutSheet::eText& eShortcutSheet::addText(
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
    sTextSize(text, fontPx, t.fW, t.fH, role);
    return t;
}

void eShortcutSheet::build(const eKeyBindings& kb, const bool science) {
    clear();
    setNoPadding();
    const auto res = resolution();
    const double m = res.multiplier();

    const std::string sh = "Shift+";
    const std::string ctrl = "Ctrl+";
    std::vector<std::vector<eRow>> cols(3);

    // camera and game
    auto& c0 = cols[0];
    c0.push_back(heading(tr("keys_camera", "Camera")));
    c0.push_back({{keyName(kb.fMoveUp) + keyName(kb.fMoveLeft) +
                   keyName(kb.fMoveDown) + keyName(kb.fMoveRight),
                   tr("keys_arrows", "Arrows")},
                  tr("keys_move", "Move the view")});
    c0.push_back({{"Shift"}, tr("keys_fast", "Hold to move faster")});
    c0.push_back({{tr("keys_wheel", "Wheel")}, tr("keys_zoom", "Zoom in / out")});
    c0.push_back({{tr("keys_middle", "Middle button")}, tr("keys_drag", "Drag the view")});
    c0.push_back({{keyName(kb.fCameraRotateLeft), keyName(kb.fCameraRotateRight)},
                  tr("keys_camera_rotate", "Rotate view left / right")});
    c0.push_back({{"F1-F4"}, tr("keys_bookmark", "Jump to a bookmark")});
    c0.push_back({{ctrl + "F1-F4"}, tr("keys_set_bookmark", "Set a bookmark")});
    c0.push_back(heading(tr("keys_game", "Game")));
    {
        std::vector<std::string> pause{keyName(kb.fPause)};
        if(kb.fPause != SDL_SCANCODE_P) pause.push_back("P");
        c0.push_back({pause, tr("keys_pause", "Pause")});
    }
    c0.push_back({{keyName(kb.fSpeedDown), keyName(kb.fSpeedUp)},
                  tr("keys_speed", "Slower / faster")});
    c0.push_back({{keyName(kb.fQuickSave), ctrl + "S"}, tr("keys_quicksave", "Quick save")});
    c0.push_back({{keyName(kb.fObjectives)}, tr("keys_objectives", "Goals tracker")});
    c0.push_back({{"F6", "F7", "F8"}, tr("keys_resolution", "Window size")});
    c0.push_back({{"F9"}, tr("keys_terrain", "Original / new terrain")});
    c0.push_back({{"Esc"}, tr("keys_menu", "Game menu")});

    // the build panel and building
    auto& c1 = cols[1];
    c1.push_back(heading(tr("keys_panel", "Build panel")));
    const int catText[11] = {0, 1, 2, 3, 4, 5, science ? 24 : 6, 7, 8, 9, 10};
    const char* const catKey[11] = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"};
    for(int i = 0; i < 11; i++) {
        c1.push_back({{sh + catKey[i]}, eLanguage::zeusText(88, catText[i])});
    }
    c1.push_back(heading(tr("keys_building", "Building")));
    c1.push_back({{keyName(kb.fRotate)}, tr("keys_rotate_building", "Rotate building preview")});
    c1.push_back({{keyName(kb.fClone), tr("keys_middle_click", "Middle click")},
                  tr("keys_copy", "Copy a building")});
    c1.push_back({{keyName(kb.fDemolish), "Del"}, tr("keys_demolish", "Demolish")});
    c1.push_back({{ctrl + "Z"}, tr("keys_undo", "Undo building")});
    c1.push_back({{"Esc"}, tr("keys_cancel", "Put the tool away")});

    // overlays
    auto& c2 = cols[2];
    c2.push_back(heading(tr("keys_overlays", "Overlays")));
    const char* const ov[10][2] = {
        {"keys_ov_water", "Water"},
        {"keys_ov_supplies", "Food and goods"},
        {"keys_ov_hygiene", "Hygiene and health"},
        {"keys_ov_hazards", "Fire and collapse risk"},
        {"keys_ov_appeal", "Appeal"},
        {"keys_ov_taxes", "Taxes"},
        {"keys_ov_unrest", "Unrest and crime"},
        {"keys_ov_security", "Security"},
        {"keys_ov_roads", "Roads"},
        {"keys_ov_problems", "Problems"}};
    for(int i = 0; i < 9; i++) {
        c2.push_back({{std::to_string(i + 1)}, tr(ov[i][0], ov[i][1])});
    }
    c2.push_back({{"Tab"}, tr(ov[9][0], ov[9][1])});
    c2.push_back({{"0", "`"}, tr("keys_ov_normal", "Normal view")});

    // layout
    const int rowPx = std::max(8, static_cast<int>(std::round(res.tinyFontSize()*1.02)));
    const int capPx = std::max(7, static_cast<int>(std::round(res.tinyFontSize()*0.86)));
    const int headPx = res.smallFontSize();
    const int titlePx = std::max(headPx + 2, static_cast<int>(std::round(res.largeFontSize()*0.95)));
    const int pad = static_cast<int>(std::round(16*m));
    const int capPadX = static_cast<int>(std::round(4.5*m));
    const int capPadY = static_cast<int>(std::round(1.5*m));
    const int capGap = static_cast<int>(std::round(3*m));
    const int textGap = static_cast<int>(std::round(9*m));
    const int colGap = static_cast<int>(std::round(24*m));
    const int rowGap = static_cast<int>(std::round(3.5*m));
    const int headGap = static_cast<int>(std::round(9*m));

    int tw, th;
    sTextSize("Hg", capPx, tw, th, eFontRole::label);
    const int capH = th + 2*capPadY;
    sTextSize("Hg", rowPx, tw, th);
    const int rowH = std::max(capH, th);

    int y0 = pad;
    // mTexts grows below, so these are kept by index
    const int titleId = mTexts.size();
    addText(tr("keys_title", "Keyboard shortcuts"), titlePx, kHead, pad, y0,
            eFontRole::display);
    const int titleH = mTexts[titleId].fH;
    const int titleW = mTexts[titleId].fW;
    const int hintId = mTexts.size();
    auto& hint = addText(tr("keys_hint", "Shown while you hold H"), rowPx, kDim, pad, 0);
    hint.fY = y0 + titleH - hint.fH - static_cast<int>(std::round(1*m));
    const int hintW = hint.fW;
    y0 += titleH + static_cast<int>(std::round(5*m));
    mTitleRuleY = y0;
    y0 += static_cast<int>(std::round(9*m));

    int x = pad;
    int bottom = y0;
    for(const auto& col : cols) {
        // the widest set of key caps, so the texts line up
        int capsW = 0;
        int textW = 0;
        for(const auto& r : col) {
            if(r.fHeading) continue;
            int w = 0;
            for(const auto& c : r.fCaps) {
                int cw, ch;
                sTextSize(c, capPx, cw, ch, eFontRole::label);
                w += std::max(capH, cw + 2*capPadX) + capGap;
            }
            capsW = std::max(capsW, w - capGap);
            int dw, dh;
            sTextSize(r.fText, rowPx, dw, dh);
            textW = std::max(textW, dw);
        }
        int colW = capsW + textGap + textW;
        for(const auto& r : col) {
            if(!r.fHeading) continue;
            int hw, hh;
            sTextSize(r.fText, headPx, hw, hh, eFontRole::heading);
            colW = std::max(colW, hw);
        }

        int y = y0;
        bool first = true;
        for(const auto& r : col) {
            if(r.fHeading) {
                if(!first) y += headGap;
                const auto& t = addText(r.fText, headPx, kHead, x, y,
                                        eFontRole::heading);
                y += t.fH + static_cast<int>(std::round(1*m));
                mRules.push_back({x, y, colW});
                y += static_cast<int>(std::round(4*m));
            } else {
                int cx = x;
                for(const auto& c : r.fCaps) {
                    int cw, ch;
                    sTextSize(c, capPx, cw, ch, eFontRole::label);
                    const int w = std::max(capH, cw + 2*capPadX);
                    const int cy = y + (rowH - capH)/2;
                    mCaps.push_back({SDL_Rect{cx, cy, w, capH}});
                    addText(c, capPx, kCapText, cx + (w - cw)/2, cy + capPadY,
                            eFontRole::label);
                    cx += w + capGap;
                }
                int dw, dh;
                sTextSize(r.fText, rowPx, dw, dh);
                addText(r.fText, rowPx, kRowText, x + capsW + textGap, y + (rowH - dh)/2);
                y += rowH + rowGap;
            }
            first = false;
        }
        bottom = std::max(bottom, y);
        x += colW + colGap;
    }
    const int w = std::max(x - colGap + pad, pad + titleW + textGap*3 + hintW + pad);
    mTexts[hintId].fX = w - pad - hintW;
    resize(w, bottom - rowGap + pad);
}

void eShortcutSheet::paintEvent(ePainter& p) {
    const double now = ePanel::time();
    const double dt = mLast < 0 ? 0 : std::min(0.1, now - mLast);
    mLast = now;
    mShow = std::min(1.0, mShow + dt/0.16);
    const double a = eMenu3D::easeOutCubic(mShow);
    if(a <= 0.01) return;

    const auto r = p.renderer();
    eGeometryBatch::sFlush();
    const float x = p.x();
    const float y = p.y() + static_cast<float>((1 - a)*height()*0.03);
    const float w = width();
    const float h = height();
    const double m = resolution().multiplier();
    const float line = std::max(1.f, static_cast<float>(m));
    const float rad = static_cast<float>(11*m);

    ePanel::glow(r, x + w/2, y + h*0.55f, w*0.62f, h*0.66f,
                 alpha(SDL_Color{0, 0, 0, 170}, a), false);
    const SDL_FRect card{x, y, w, h};
    ePanel::roundRect(r, card, rad, alpha(SDL_Color{24, 40, 76, 246}, a),
                      alpha(SDL_Color{11, 19, 40, 246}, a));
    ePanel::roundRect(r, card, rad, alpha(SDL_Color{246, 208, 120, 235}, a),
                      alpha(SDL_Color{150, 106, 34, 225}, a), line);
    const float pad = static_cast<float>(16*m);
    ePanel::goldRule(r, x + pad, y + mTitleRuleY, w - 2*pad, line,
                     static_cast<Uint8>(200*a), true);
    for(const auto& ru : mRules) {
        ePanel::goldRule(r, x + ru.fX, y + ru.fY, ru.fW, std::max(1.f, line*0.75f),
                         static_cast<Uint8>(120*a), false);
    }

    // key caps: a raised dark key with a pale gold rim
    const float capRad = static_cast<float>(3*m);
    for(const auto& c : mCaps) {
        const SDL_FRect f{x + c.fRect.x, y + c.fRect.y,
                          float(c.fRect.w), float(c.fRect.h)};
        const SDL_FRect sh{f.x, f.y + line, f.w, f.h};
        ePanel::roundRect(r, sh, capRad, alpha(SDL_Color{0, 0, 0, 120}, a),
                          alpha(SDL_Color{0, 0, 0, 120}, a));
        ePanel::roundRect(r, f, capRad, alpha(SDL_Color{52, 78, 132, 255}, a),
                          alpha(SDL_Color{26, 42, 82, 255}, a));
        ePanel::roundRect(r, f, capRad, alpha(SDL_Color{240, 206, 130, 210}, a),
                          alpha(SDL_Color{140, 100, 36, 200}, a), line*0.8f);
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
