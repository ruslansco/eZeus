#include "emenubutton.h"

#include "emenuscene.h"
#include "emenu3d.h"
#include "textures/egeometrybatch.h"

#include <cmath>

using namespace eMenu3D;

void eMenuButton::setup(const std::string& text, const eStyle style,
                        const int minWidth) {
    mStyle = style;
    setSmallFontSize();
    setText(text);
    fitContent();
    const auto res = resolution();
    const int p = res.largePadding();
    setWidth(std::max(minWidth, width() + 4*p));
    setHeight(height() + p + p/2);
}

void eMenuButton::setSelected(const bool s) {
    mSelected = s;
}

void eMenuButton::paintEvent(ePainter& p) {
    const Uint64 now = SDL_GetPerformanceCounter();
    const double dt = mLast ? std::min(0.1, double(now - mLast)/SDL_GetPerformanceFrequency()) : 0;
    mLast = now;
    const bool hot = enabled() && hovered();
    mHover += ((hot ? 1.0 : 0.0) - mHover)*(1 - std::exp(-dt*14));

    const int colorState = (hot || mSelected) ? 1 : 0;
    if(colorState != mColorState) {
        mColorState = colorState;
        if(colorState) setYellowFontColor();
        else setLightFontColor();
    }

    auto& scene = eMenuScene::instance();
    const auto r = p.renderer();
    const auto white = scene.whiteTexture();
    const auto dot = scene.glowTexture();
    eGeometryBatch::sFlush();
    const float x = static_cast<float>(p.x());
    const float y = static_cast<float>(p.y() + (pressed() ? 1 : 0));
    const float w = static_cast<float>(width());
    const float h = static_cast<float>(height());
    const double hv = mHover;
    const float s = static_cast<float>(std::max(1.0, h/40.0));

    if(dot) {
        const auto blob = [&](const float bx, const float by, const float rx, const float ry,
                              const SDL_Color c, const SDL_BlendMode bm) {
            SDL_SetTextureBlendMode(dot, bm);
            const SDL_Vertex v[4] = {{{bx - rx, by - ry}, c, {0, 0}},
                                     {{bx + rx, by - ry}, c, {1, 0}},
                                     {{bx + rx, by + ry}, c, {1, 1}},
                                     {{bx - rx, by + ry}, c, {0, 1}}};
            const int ids[6] = {0, 1, 2, 0, 2, 3};
            SDL_RenderGeometry(r, dot, v, 4, ids, 6);
        };
        blob(x + w*0.5f, y + h*0.5f + 5*s, w*0.62f, h*1.0f,
             SDL_Color{0, 0, 0, 120}, SDL_BLENDMODE_BLEND);
        if(hv > 0.01) {
            blob(x + w*0.5f, y + h*0.5f, w*0.7f, h*1.6f,
                 SDL_Color{255, 196, 84, static_cast<Uint8>(80*hv)}, SDL_BLENDMODE_ADD);
        }
    }

    SDL_Color top, bottom;
    if(mStyle == eStyle::primary) {
        top = mix({84, 62, 22, 244}, {116, 88, 32, 250}, hv);
        bottom = mix({40, 27, 8, 246}, {58, 40, 12, 250}, hv);
    } else if(mSelected) {
        top = mix({62, 58, 40, 244}, {74, 70, 48, 248}, hv);
        bottom = mix({30, 28, 18, 246}, {38, 34, 22, 248}, hv);
    } else {
        top = mix({30, 46, 74, 238}, {46, 68, 104, 248}, hv);
        bottom = mix({13, 21, 38, 242}, {22, 34, 58, 248}, hv);
    }
    if(!enabled()) {
        top.a = bottom.a = 150;
    }
    SDL_SetTextureBlendMode(white, SDL_BLENDMODE_BLEND);
    {
        const SDL_FPoint q[4] = {{x, y}, {x + w, y}, {x + w, y + h}, {x, y + h}};
        const SDL_Color cs[4] = {top, top, bottom, bottom};
        drawFlat(r, white, q, cs);
    }
    const bool lit = mSelected || mStyle == eStyle::primary;
    const SDL_Color gold = mix(lit ? SDL_Color{232, 190, 72, 245} : SDL_Color{200, 162, 52, 220},
                               SDL_Color{255, 222, 110, 255}, hv);
    const SDL_Color bronze = mix({140, 100, 28, 190}, {205, 152, 50, 230}, hv);
    const auto frame = [&](const float in, const float t, const SDL_Color c) {
        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
        SDL_SetRenderDrawColor(r, c.r, c.g, c.b, c.a);
        const SDL_FRect rs[4] = {{x + in, y + in, w - 2*in, t},
                                 {x + in, y + h - in - t, w - 2*in, t},
                                 {x + in, y + in + t, t, h - 2*in - 2*t},
                                 {x + w - in - t, y + in + t, t, h - 2*in - 2*t}};
        SDL_RenderFillRectsF(r, rs, 4);
    };
    frame(0, std::max(1.f, 1.5f*s), gold);
    if(h > 26) frame(4*s, std::max(1.f, 0.8f*s), bronze);
    SDL_SetRenderDrawColor(r, 255, 250, 225, static_cast<Uint8>(35 + 40*hv));
    const SDL_FRect hl{x + 2*s, y + 2*s, w - 4*s, 1};
    SDL_RenderFillRectF(r, &hl);

    if(pressed()) {
        p.save();
        p.translate(0, 1);
        eButtonBase::paintEvent(p);
        p.restore();
    } else {
        eButtonBase::paintEvent(p);
    }
}
