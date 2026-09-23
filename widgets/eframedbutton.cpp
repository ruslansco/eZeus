#include "eframedbutton.h"

#include "textures/egametextures.h"

#include <random>

void eFramedButton::paintEvent(ePainter& p) {
    int iRes;
    int mult;
    iResAndMult(iRes, mult);

    const SDL_Rect r = rect();

    if(mRenderBg) {
        if(hovered()) {
            // Ambient subtle glow
            p.drawDropShadow(r, 4 * mult, 120);

            // Elevated hover background
            const SDL_Color bgHover{35, 55, 85, 245};
            p.fillRect(r, bgHover);

            // Amber gold tint overlay
            const SDL_Color goldTint{255, 215, 0, 35};
            p.fillRect(r, goldTint);

            // Glowing gold border
            const SDL_Color borderGold{255, 215, 0, 255};
            p.drawRect(r, borderGold, std::max(1, mult));

            // Top highlight line
            const SDL_Color topHighlight{255, 255, 220, 90};
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, r.w - 2, 1}, topHighlight);
        } else if(pressed()) {
            // Inset pressed state
            const SDL_Color bgPressed{14, 22, 34, 250};
            p.fillRect(r, bgPressed);

            const SDL_Color borderPressed{212, 175, 55, 220};
            p.drawRect(r, borderPressed, std::max(1, mult));
        } else {
            // Normal state: dark Aegean stone
            const SDL_Color bgNormal{22, 34, 52, 235};
            p.fillRect(r, bgNormal);

            // Warm bronze/gold border
            const SDL_Color borderNormal{175, 135, 45, 210};
            p.drawRect(r, borderNormal, std::max(1, mult));

            // Top subtle highlight line
            const SDL_Color topHighlight{255, 255, 255, 40};
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, r.w - 2, 1}, topHighlight);

            // Bottom subtle shadow
            const SDL_Color botShadow{0, 0, 0, 70};
            p.fillRect(SDL_Rect{r.x + 1, r.y + r.h - 2, r.w - 2, 1}, botShadow);
        }
    } else {
        if(hovered()) {
            // Subtle underline or border for un-rendered bg buttons
            const SDL_Color borderGold{255, 215, 0, 180};
            p.drawRect(r, borderGold, 1);
        }
    }

    eButton::paintEvent(p);
}

void eFramedButton::renderBg(ePainter& p) {
    (void)p;
}
