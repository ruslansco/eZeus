#include "epainter.h"

#include "textures/egeometrybatch.h"

ePainter::ePainter(SDL_Renderer* const renderer) :
    mRenderer(renderer) {

}

void ePainter::save() {
    ePainterSave save;
    save.fX = mX;
    save.fY = mY;
    save.fFont = mFont;
    mSaves.emplace(mSaves.end(), save);
}

void ePainter::restore() {
    if(mSaves.empty()) return;
    const auto save = mSaves.back();
    mSaves.pop_back();
    mX = save.fX;
    mY = save.fY;
    mFont = save.fFont;
}

void ePainter::translate(const int x, const int y) {
    mX += x;
    mY += y;
}

void ePainter::setFont(TTF_Font* const font) {
    mFont = font;
}

void ePainter::drawTexture(const int x, const int y,
                           const std::shared_ptr<eTexture>& tex,
                           const eAlignment align) const {
    int xx = x;
    if(static_cast<bool>(align & eAlignment::left)) {
        xx -= tex->width();
    } else if(static_cast<bool>(align & eAlignment::hcenter)) {
        xx -= tex->width()/2;
    }

    int yy = y;
    if(static_cast<bool>(align & eAlignment::top)) {
        yy -= tex->height();
    } else if(static_cast<bool>(align & eAlignment::vcenter)) {
        yy -= tex->height()/2;
    }

    drawTexture(xx, yy, tex);
}

void ePainter::drawTexture(const SDL_Rect& rect,
                           const std::shared_ptr<eTexture>& tex,
                           const eAlignment align) const {
    int xx;
    if(static_cast<bool>(align & eAlignment::right)) {
        xx = rect.x + rect.w - tex->width();
    } else if(static_cast<bool>(align & eAlignment::hcenter)) {
        xx = rect.x + (rect.w - tex->width())/2;
    } else {
        xx = rect.x;
    }

    int yy;
    if(static_cast<bool>(align & eAlignment::bottom)) {
        yy = rect.y + rect.h - tex->height();
    } else if(static_cast<bool>(align & eAlignment::vcenter)) {
        yy = rect.y + (rect.h - tex->height())/2;
    } else {
        yy = rect.y;
    }

    drawTexture(xx, yy, tex);
}

void ePainter::drawTexture(const int x, const int y,
                           const std::shared_ptr<eTexture>& tex) const {
    if(!tex) return;
    tex->render(mRenderer, mX + x, mY + y);
}

void ePainter::drawTextureScaled(const SDL_Rect& dstRect,
                                 const std::shared_ptr<eTexture>& tex) const {
    if(!tex) return;
    const SDL_Rect sRect{tex->x(), tex->y(), tex->width(), tex->height()};
    const SDL_Rect dRect{dstRect.x + mX, dstRect.y + mY, dstRect.w, dstRect.h};
    tex->render(mRenderer, sRect, dRect);
}

void ePainter::fillRect(const SDL_Rect& rect,
                        const SDL_Color& color) const {
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawBlendMode(mRenderer, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(mRenderer, color.r, color.g, color.b, color.a);
    const SDL_Rect dRect{rect.x + mX, rect.y + mY, rect.w, rect.h};
    SDL_RenderFillRect(mRenderer, &dRect);
}

void ePainter::drawRect(const SDL_Rect& rect,
                        const SDL_Color& color,
                        const int width) {
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawBlendMode(mRenderer, SDL_BLENDMODE_BLEND);
    const SDL_Rect r1{rect.x,
                      rect.y,
                      rect.w,
                      width};
    const SDL_Rect r2{rect.x,
                      rect.y + rect.h - width,
                      rect.w,
                      width};
    const SDL_Rect r3{rect.x,
                      rect.y + width,
                      width,
                      rect.h - 2*width};
    const SDL_Rect r4{rect.x + rect.w - width,
                      rect.y + width,
                      width,
                      rect.h - 2*width};
    fillRect(r1, color);
    fillRect(r2, color);
    fillRect(r3, color);
    fillRect(r4, color);
}

void ePainter::drawDropShadow(const SDL_Rect& rect,
                              const int size,
                              const uint8_t maxAlpha) const {
    if(size <= 0 || maxAlpha == 0) return;
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawBlendMode(mRenderer, SDL_BLENDMODE_BLEND);
    const int steps = 4;
    for(int i = steps; i >= 1; --i) {
        const int expand = i * size / steps;
        const int offsetY = (i * size) / (steps * 2) + 2;
        const uint8_t a = static_cast<uint8_t>((maxAlpha * (steps - i + 1)) / (steps * 3));
        if(a == 0) continue;
        const SDL_Color shadowCol{0, 0, 0, a};
        fillRect(SDL_Rect{rect.x - expand / 2, rect.y + offsetY, rect.w + expand, rect.h + expand / 2}, shadowCol);
    }
}

void ePainter::drawGoldFrame(const SDL_Rect& rect,
                             const int borderWidth) const {
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawBlendMode(mRenderer, SDL_BLENDMODE_BLEND);
    // Outer shadow border
    const SDL_Color outerDark{10, 16, 26, 240};
    // Primary gold border
    const SDL_Color primaryGold{212, 175, 55, 235}; // #d4af37
    // Inner bronze accent
    const SDL_Color innerBronze{168, 122, 28, 200}; // #a87a1c
    // Top highlight line
    const SDL_Color topHighlight{255, 240, 180, 70};

    // Draw outer dark rim
    const_cast<ePainter*>(this)->drawRect(rect, outerDark, 1);

    // Primary gold border
    const int w = std::max(1, borderWidth);
    const SDL_Rect rGold{rect.x + 1, rect.y + 1, rect.w - 2, rect.h - 2};
    const_cast<ePainter*>(this)->drawRect(rGold, primaryGold, w);

    // Inner bronze line
    if(rect.w > 2 * (w + 2) && rect.h > 2 * (w + 2)) {
        const SDL_Rect rBronze{rect.x + 1 + w, rect.y + 1 + w, rect.w - 2 * (w + 1), rect.h - 2 * (w + 1)};
        const_cast<ePainter*>(this)->drawRect(rBronze, innerBronze, 1);
    }

    // Top subtle bevel highlight
    if(rect.w > 4) {
        const SDL_Rect rHighlight{rect.x + 2, rect.y + 2, rect.w - 4, 1};
        fillRect(rHighlight, topHighlight);
    }
}

void ePainter::drawText(const int x, const int y,
                        const std::string& text,
                        const eFontColor color,
                        const eAlignment align) const {
    if(!mFont) return;

    const auto tex = std::make_shared<eTexture>();
    tex->loadText(mRenderer, text, color, *mFont);

    drawTexture(x, y, tex, align);
}

void ePainter::drawText(const SDL_Rect& rect,
                        const std::string& text,
                        const eFontColor color,
                        const eAlignment align) const {
    if(!mFont) return;

    const auto tex = std::make_shared<eTexture>();
    tex->loadText(mRenderer, text, color, *mFont);

    drawTexture(rect, tex, align);
}

void ePainter::drawPolygon(std::vector<SDL_Point> pts,
                           const SDL_Color& color) const {
    for(auto& pt : pts) {
        pt.x += mX;
        pt.y += mY;
    }
    eGeometryBatch::sFlush();
    SDL_SetRenderDrawColor(mRenderer, color.r, color.g, color.b, color.a);
    SDL_RenderDrawLines(mRenderer, pts.data(), pts.size());
}

void ePainter::setClipRect(const SDL_Rect* const rect) {
    eGeometryBatch::sFlush();
    if(rect) {
        const auto r = SDL_Rect{rect->x + mX, rect->y + mY,
                                rect->w, rect->h};
        SDL_RenderSetClipRect(mRenderer, &r);
    } else {
        SDL_RenderSetClipRect(mRenderer, nullptr);
    }
}
