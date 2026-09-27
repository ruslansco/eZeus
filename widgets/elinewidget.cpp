#include "elinewidget.h"

#include "efontcolor.h"

void eLineWidget::sizeHint(int& w, int& h) {
    const auto res = resolution();
    const double m = res.multiplier();
    w = 2*m;
    h = 2*m;
}

void eLineWidget::paintEvent(ePainter& p) {
    const SDL_Color col1{212, 175, 72, 230};
    const SDL_Color col2{40, 28, 8, 160};

    p.fillRect(SDL_Rect{0, 0, width(), height()}, col1);
    const int hh = height()/2;
    p.fillRect(SDL_Rect{0, hh, width(), hh}, col2);
}
