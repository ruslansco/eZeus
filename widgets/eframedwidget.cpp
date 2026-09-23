#include "eframedwidget.h"

#include "textures/egametextures.h"

#include <random>

void eFramedWidget::setType(const eFrameType type) {
    mType = type;
}

void eFramedWidget::paintEvent(ePainter& p) {
    int iRes;
    int mult;
    iResAndMult(iRes, mult);

    const SDL_Rect r = rect();
    if(mType == eFrameType::outer || mType == eFrameType::message) {
        // Ambient soft drop shadow
        p.drawDropShadow(r, 10 * mult, 175);

        // Deep Aegean Midnight Stone background
        const SDL_Color bgDark{16, 26, 42, 238};
        p.fillRect(r, bgDark);

        // Subtle gradient highlight in upper third
        const int gh = std::min(r.h / 3, 40 * mult);
        if(gh > 0) {
            const SDL_Rect gradRect{r.x + 2, r.y + 2, r.w - 4, gh};
            p.fillRect(gradRect, SDL_Color{36, 56, 88, 55});
        }

        // Classical gold and bronze beveled frame
        p.drawGoldFrame(r, std::max(1, mult));

        // Corner decorative gold accents (L-shaped corners)
        const int cs = 6 * mult;
        if(r.w > 3 * cs && r.h > 3 * cs) {
            const SDL_Color goldAccent{255, 215, 0, 240};
            // Top-left
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, cs, 2}, goldAccent);
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, 2, cs}, goldAccent);
            // Top-right
            p.fillRect(SDL_Rect{r.x + r.w - cs - 1, r.y + 1, cs, 2}, goldAccent);
            p.fillRect(SDL_Rect{r.x + r.w - 3, r.y + 1, 2, cs}, goldAccent);
            // Bottom-left
            p.fillRect(SDL_Rect{r.x + 1, r.y + r.h - 3, cs, 2}, goldAccent);
            p.fillRect(SDL_Rect{r.x + 1, r.y + r.h - cs - 1, 2, cs}, goldAccent);
            // Bottom-right
            p.fillRect(SDL_Rect{r.x + r.w - cs - 1, r.y + r.h - 3, cs, 2}, goldAccent);
            p.fillRect(SDL_Rect{r.x + r.w - 3, r.y + r.h - cs - 1, 2, cs}, goldAccent);
        }
    } else { // eFrameType::inner
        // Inset dark background
        const SDL_Color bgInner{10, 16, 26, 215};
        p.fillRect(r, bgInner);

        // Inset bronze border
        const SDL_Color borderBronze{140, 105, 35, 190};
        p.drawRect(r, borderBronze, 1);

        // Inner shadow on top and left to give recessed depth
        if(r.w > 2 && r.h > 2) {
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, r.w - 2, 1}, SDL_Color{0, 0, 0, 90});
            p.fillRect(SDL_Rect{r.x + 1, r.y + 1, 1, r.h - 2}, SDL_Color{0, 0, 0, 90});
        }
    }
}
