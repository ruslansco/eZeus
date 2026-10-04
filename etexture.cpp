#include "etexture.h"
#include "egamedir.h"
#include "widgets/efonts.h"
#include "textures/egeometrybatch.h"
#include "ebenchtimers.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>

namespace {
// Reads an image's pixel size from its file header without decoding it. The embedded
// (Godot) backend never draws these sprites; it only needs their dimensions, and fully
// decoding the remastered sheets made the first city load take about two seconds.
// Returns false for anything but PNG or JPEG so the caller can use the normal path.
bool sImageSize(const std::string& path, int& w, int& h) {
    FILE* const f = std::fopen(path.c_str(), "rb");
    if(!f) return false;
    unsigned char head[26];
    const bool haveHead = std::fread(head, 1, sizeof(head), f) == sizeof(head);
    static const unsigned char png[8] = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
    if(haveHead && std::equal(png, png + 8, head) && head[12] == 'I' && head[13] == 'H' && head[14] == 'D' && head[15] == 'R') {
        w = (head[16] << 24) | (head[17] << 16) | (head[18] << 8) | head[19];
        h = (head[20] << 24) | (head[21] << 16) | (head[22] << 8) | head[23];
        std::fclose(f);
        return w > 0 && h > 0;
    }
    bool found = false;
    if(haveHead && head[0] == 0xFF && head[1] == 0xD8) {
        std::fseek(f, 2, SEEK_SET);
        for(int guard = 0; guard < 4096 && !found; ++guard) {
            int c = std::fgetc(f);
            if(c == EOF) break;
            if(c != 0xFF) continue;
            int marker = std::fgetc(f);
            while(marker == 0xFF) marker = std::fgetc(f);
            if(marker == EOF) break;
            if(marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) continue;
            unsigned char len[2];
            if(std::fread(len, 1, 2, f) != 2) break;
            const int length = (len[0] << 8) | len[1];
            const bool frame = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
            if(frame) {
                unsigned char dims[5];
                if(std::fread(dims, 1, 5, f) != 5) break;
                h = (dims[1] << 8) | dims[2];
                w = (dims[3] << 8) | dims[4];
                found = w > 0 && h > 0;
            } else if(length < 2 || std::fseek(f, length - 2, SEEK_CUR) != 0) {
                break;
            }
        }
    }
    std::fclose(f);
    return found;
}
}

eTexture::eTexture() {}

eTexture::~eTexture() {
    reset();
}

void eTexture::reset() {
    if(mTex) SDL_DestroyTexture(mTex);
    mTex = nullptr;
    mWidth = 0;
    mHeight = 0;
    mDensity = 1;
    mColorMod = SDL_Color{255, 255, 255, 255};
}

bool eTexture::create(SDL_Renderer* const r,
                      const int width, const int height) {
    reset();
    if(!r && eGameDir::embedded()) { mWidth = width; mHeight = height; return true; }
    mTex = SDL_CreateTexture(r, SDL_PIXELFORMAT_RGBA8888,
                             SDL_TEXTUREACCESS_TARGET, width, height);
    if(!mTex) return false;
    SDL_SetTextureBlendMode(mTex, SDL_BLENDMODE_BLEND);
    mWidth = width;
    mHeight = height;
    return true;
}

void eTexture::setAsRenderTarget(SDL_Renderer* const r) {
    eGeometryBatch::sFlush();
    SDL_SetRenderTarget(r, mTex);
}

bool eTexture::load(SDL_Renderer* const r, const std::string& path) {
    const eBenchScope bench(eBenchTimers::texLoad);
    reset();
    // EZEUS_DECODE_TEXTURES=1 restores the full decode, to compare against the header read.
    static const bool decodeAnyway = std::getenv("EZEUS_DECODE_TEXTURES") != nullptr;
    if(!r && eGameDir::embedded() && !decodeAnyway) {
        int w = 0, h = 0;
        if(sImageSize(path, w, h)) { mWidth = w; mHeight = h; return true; }
    }
    const auto surf = IMG_Load(path.c_str());
    if(!surf) {
        printf("Unable to load image %s! SDL_image Error: %s\n",
               path.c_str(), IMG_GetError());
        return false;
    }
    return load(r, surf);
}

bool eTexture::load(SDL_Renderer* const r,
                    SDL_Surface* const surf) {
    reset();
    if(!r && eGameDir::embedded()) {
        mWidth = surf->w; mHeight = surf->h; SDL_FreeSurface(surf); return true;
    }
    mTex = SDL_CreateTextureFromSurface(r, surf);
    mWidth = surf->w;
    mHeight = surf->h;
    SDL_FreeSurface(surf);
    if(!mTex) {
        printf("Unable to create texture from surface!"
               "SDL Error: %s\n", SDL_GetError());
        return false;
    }

    return true;
}

SDL_Texture*  generateTextTexture(SDL_Renderer* const r,
                                 const std::string& text,
                                 const SDL_Color& color,
                                 TTF_Font& font,
                                 const int width,
                                 int& w, int& h) {
    SDL_Surface* surf;
    if(width) {
        surf = TTF_RenderUTF8_Blended_Wrapped(&font, text.c_str(), color, width);
    } else {
        surf = TTF_RenderUTF8_Blended(&font, text.c_str(), color);
    }
    if(!surf) {
        printf("Unable to render text! SDL_ttf Error: %s\n",
               TTF_GetError());
        return nullptr;
    }
    const auto tex = SDL_CreateTextureFromSurface(r, surf);
    if(!tex) {
        printf("Unable to create texture from rendered text! "
               "SDL Error: %s\n", SDL_GetError());
        return nullptr;
    }
    w = surf->w;
    h = surf->h;
    SDL_FreeSurface(surf);
    return tex;
}

std::vector<std::string> textLines(const std::string& text,
                                   TTF_Font& font,
                                   const int width,
                                   const bool keepSpaces) {
    std::vector<std::string> result;
    const int ts = text.size();
    std::string word;
    std::string line;
    int index = 0;
    while(index < ts) {
        const bool isLast = index == ts - 1;
        const auto c = text[index++];
        if(c == ' ' || c == '\n' || isLast) {
            if(isLast && c != ' ' && c != '\n') word += c;
            int w = 0;
            int h = 0;
            const auto newLine = line + (line.empty() ? "" : " ") + word;
            TTF_SizeUTF8(&font, newLine.c_str(), &w, &h);
            if(line.empty() || w < width) {
                line = newLine;
                if(keepSpaces && c == ' ') line += ' ';
                if(c == '\n') {
                    result.push_back(line);
                    line = "";
                }
            } else {
                result.push_back(line);
                if(c == '\n') {
                    result.push_back(word);
                    line = "";
                } else {
                    line = word;
                }
            }
            word = "";
        } else {
            word += c;
        }
    }
    if(!word.empty()) line += (line.empty() ? "" : " ") + word;
    if(!line.empty()) result.push_back(line);
    return result;
}

bool eTexture::loadText(SDL_Renderer* const r,
                        const std::string& text,
                        const eFontColor color,
                        TTF_Font& fontIn,
                        const int width,
                        const eAlignment align) {
    const eBenchScope bench(eBenchTimers::text);
    // a Russian name in English text: the Cyrillic font for this text
    TTF_Font& font = *eFonts::forText(&fontIn, text);
    reset();

    if(width) {
        int w;
        int h;
        TTF_SizeUTF8(&font, text.c_str(), &w, &h);
        if(w > width) {
            const auto lines = textLines(text, font, width, true);
            mWidth = 0;
            mHeight = 0;
            std::vector<std::shared_ptr<eTexture>> texs;
            for(const auto& l : lines) {
                auto& tex = texs.emplace_back();
                if(!l.empty()) {
                    tex = std::make_shared<eTexture>();
                    tex->loadText(r, l, color, font);
                    mHeight += tex->height();
                    mWidth = std::max(mWidth, tex->width());
                } else {
                    mHeight += h;
                }
            }
            mTex = SDL_CreateTexture(r, SDL_PIXELFORMAT_ARGB8888,
                                     SDL_TEXTUREACCESS_TARGET, mWidth, mHeight);

            if(!mTex) {
                printf("Unable to create texture! "
                       "SDL Error: %s\n", SDL_GetError());
                return false;
            }
            {
                eGeometryBatch::sFlush();
                const auto previousTarget = SDL_GetRenderTarget(r);
    SDL_SetRenderTarget(r, mTex);
                const auto bm = SDL_ComposeCustomBlendMode(
                                    SDL_BLENDFACTOR_ONE,
                                    SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                    SDL_BLENDOPERATION_ADD,

                                    SDL_BLENDFACTOR_ONE,
                                    SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                    SDL_BLENDOPERATION_ADD);
                SDL_SetTextureBlendMode(mTex, bm);

                SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
                SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
                SDL_RenderFillRect(r, NULL);

                int y = 0;
                for(const auto& tex : texs) {
                    if(tex) {
                        const int w = tex->width();
                        const int x = align == eAlignment::hcenter ?
                                          (mWidth - w)/2 : 0;
                        const SDL_Rect dstRect{x, y, w, tex->height()};
                        SDL_RenderCopy(r, tex->mTex, NULL, &dstRect);
                        y += dstRect.h;
                    } else {
                        y += h;
                    }
                }

                SDL_SetRenderTarget(r, previousTarget);
            }

            return true;
        }
    }

    SDL_Color col1;
    SDL_Color col2;
    eFontColorHelpers::colors(color, col1, col2);

    int w;
    int h;
    const auto tex1 = generateTextTexture(r, text, col1,
                                          font, width, w, h);
    if(!tex1) return false;
    const auto tex2 = generateTextTexture(r, text, col2,
                                          font, width, w, h);
    if(!tex2) return false;

    const int dx = 1;
    const int dy = 1;

    mWidth = w + dx;
    mHeight = h + dy;
    mTex = SDL_CreateTexture(r, SDL_PIXELFORMAT_ARGB8888,
                             SDL_TEXTUREACCESS_TARGET, mWidth, mHeight);

    if(!mTex) {
        printf("Unable to create texture! "
               "SDL Error: %s\n", SDL_GetError());
        return false;
    }
    {
        eGeometryBatch::sFlush();
        const auto previousTarget = SDL_GetRenderTarget(r);
    SDL_SetRenderTarget(r, mTex);
        const auto bm = SDL_ComposeCustomBlendMode(
                            SDL_BLENDFACTOR_ONE,
                            SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                            SDL_BLENDOPERATION_ADD,

                            SDL_BLENDFACTOR_ONE,
                            SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                            SDL_BLENDOPERATION_ADD);
        SDL_SetTextureBlendMode(mTex, bm);

        SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_NONE);
        SDL_SetRenderDrawColor(r, 0, 0, 0, 0);
        SDL_RenderFillRect(r, NULL);

        const SDL_Rect dstRect2{0, 0, w, h};
        SDL_RenderCopy(r, tex2, NULL, &dstRect2);
        SDL_SetTextureAlphaMod(tex2, 128);
        SDL_RenderCopy(r, tex2, NULL, &dstRect2);
        const SDL_Rect dstRect1{dx, dy, w, h};
        SDL_RenderCopy(r, tex1, NULL, &dstRect1);
        SDL_SetTextureAlphaMod(tex1, 128);
        SDL_RenderCopy(r, tex1, NULL, &dstRect1);

        SDL_DestroyTexture(tex2);
        SDL_DestroyTexture(tex1);

        SDL_SetRenderTarget(r, previousTarget);
    }
    return true;
}

bool eTexture::loadText(SDL_Renderer* const r,
                        const std::string& text,
                        const eFontColor color,
                        const eFont& font,
                        const int width,
                        const eAlignment align) {
    const auto ttf = eFonts::requestFont(font);
    if(!ttf) return false;
    return loadText(r, text, color, *ttf, width, align);
}

void eTexture::render(SDL_Renderer* const r,
                      const SDL_Rect& srcRect,
                      const SDL_Rect& dstRect,
                      const bool flipped) const {
    if(mHiRes && !mFlipTex) {
        float sx = 1.f;
        float sy = 1.f;
        SDL_RenderGetScale(r, &sx, &sy);
        if(sx > 1.01f || sy > 1.01f) {
            const SDL_Rect hiSrc{srcRect.x - mX + mHiRes->x(),
                                 srcRect.y - mY + mHiRes->y(),
                                 srcRect.w, srcRect.h};
            mHiRes->render(r, hiSrc, dstRect, flipped);
            return;
        }
    }
    if(mFlipTex) {
        mFlipTex->render(r, srcRect, dstRect, true);
    } else if(mParentTex) {
        // A dense view of its parent maps logical source rects to parent pixels.
        const SDL_Rect src = mDensity == 1 ? srcRect :
            SDL_Rect{mX + (srcRect.x - mX)*mDensity, mY + (srcRect.y - mY)*mDensity,
                     srcRect.w*mDensity, srcRect.h*mDensity};
        mParentTex->render(r, src, dstRect, flipped);
    } else if(mTex) {
        eGeometryBatch::sFlush();
        const SDL_Rect src = mDensity == 1 ? srcRect :
            SDL_Rect{srcRect.x*mDensity, srcRect.y*mDensity,
                     srcRect.w*mDensity, srcRect.h*mDensity};
        if(flipped) {
            SDL_RenderCopyEx(r, mTex, &src, &dstRect, 0, nullptr,
                             SDL_RendererFlip::SDL_FLIP_HORIZONTAL);
        } else {
            SDL_RenderCopy(r, mTex, &src, &dstRect);
        }
    }
}

void eTexture::renderLeaning(SDL_Renderer* const r,
                             const SDL_Rect& srcRect,
                             const SDL_Rect& dstRect,
                             const float lean) const {
    if(std::abs(lean) < 0.05f || mFlipTex) return render(r, srcRect, dstRect);
    if(mHiRes) {
        float sx = 1.f;
        float sy = 1.f;
        SDL_RenderGetScale(r, &sx, &sy);
        if(sx > 1.01f || sy > 1.01f) {
            const SDL_Rect hiSrc{srcRect.x - mX + mHiRes->x(),
                                 srcRect.y - mY + mHiRes->y(),
                                 srcRect.w, srcRect.h};
            mHiRes->renderLeaning(r, hiSrc, dstRect, lean);
            return;
        }
    }
    if(mParentTex) {
        const SDL_Rect src = mDensity == 1 ? srcRect :
            SDL_Rect{mX + (srcRect.x - mX)*mDensity, mY + (srcRect.y - mY)*mDensity,
                     srcRect.w*mDensity, srcRect.h*mDensity};
        mParentTex->renderLeaning(r, src, dstRect, lean);
    } else if(mTex) {
        eGeometryBatch::sFlush();
        const SDL_Rect src = mDensity == 1 ? srcRect :
            SDL_Rect{srcRect.x*mDensity, srcRect.y*mDensity,
                     srcRect.w*mDensity, srcRect.h*mDensity};
        int tw = 0;
        int th = 0;
        SDL_QueryTexture(mTex, nullptr, nullptr, &tw, &th);
        if(tw <= 0 || th <= 0) return;
        // the texture's colour mod goes into the vertices (and only there)
        Uint8 cr = 255, cg = 255, cb = 255, ca = 255;
        SDL_GetTextureColorMod(mTex, &cr, &cg, &cb);
        SDL_GetTextureAlphaMod(mTex, &ca);
        SDL_SetTextureColorMod(mTex, 255, 255, 255);
        SDL_SetTextureAlphaMod(mTex, 255);
        const SDL_Color c{cr, cg, cb, ca};
        const float x0 = dstRect.x;
        const float y0 = dstRect.y;
        const float x1 = dstRect.x + dstRect.w;
        const float y1 = dstRect.y + dstRect.h;
        const float u0 = src.x/float(tw);
        const float v0 = src.y/float(th);
        const float u1 = (src.x + src.w)/float(tw);
        const float v1 = (src.y + src.h)/float(th);
        const SDL_Vertex v[4] = {{{x0 + lean, y0}, c, {u0, v0}},
                                 {{x1 + lean, y0}, c, {u1, v0}},
                                 {{x1, y1}, c, {u1, v1}},
                                 {{x0, y1}, c, {u0, v1}}};
        const int ids[6] = {0, 1, 2, 0, 2, 3};
        SDL_RenderGeometry(r, mTex, v, 4, ids, 6);
        SDL_SetTextureColorMod(mTex, cr, cg, cb);
        SDL_SetTextureAlphaMod(mTex, ca);
    }
}

void eTexture::render(SDL_Renderer* const r,
                      const int x, const int y,
                      const bool flipped) const {
    const int sx = mFlipTex ? mFlipTex->x() : mX;
    const int sy = mFlipTex ? mFlipTex->y() : mY;
    const int width = mFlipTex ? mFlipTex->width() : mWidth;
    const int height = mFlipTex ? mFlipTex->height() : mHeight;
    const SDL_Rect srcRect{sx, sy, width, height};
    const SDL_Rect dstRect{x, y, width, height};
    render(r, srcRect, dstRect, flipped);
}

void eTexture::renderRelPortion(SDL_Renderer* const r,
                                const int dstX,
                                const int dstY,
                                const int srcX,
                                const int w,
                                const bool flipped) const {
    const int sx = mFlipTex ? mFlipTex->x() : mX;
    const int sy = mFlipTex ? mFlipTex->y() : mY;
    const int width = mFlipTex ? mFlipTex->width() : mWidth;
    const int height = mFlipTex ? mFlipTex->height() : mHeight;
    const int ww = std::min(w + srcX, width) - srcX;
    SDL_Rect srcRect{sx + srcX, sy, ww, height};
    SDL_Rect dstRect{dstX, dstY, ww, height};
    if(srcRect.x < sx) {
        const int dx = sx - srcRect.x;
        srcRect.x += dx;
        dstRect.x += dx;
        srcRect.w -= dx;
        dstRect.w -= dx;
    }
    if(srcRect.y < sy) {
        const int dy = sy - srcRect.y;
        srcRect.y += dy;
        dstRect.y += dy;
        srcRect.h -= dy;
        dstRect.h -= dy;
    }
    if(srcRect.x + srcRect.w > sx + width) {
        const int dw = sx + width - srcRect.x - srcRect.w;
        srcRect.w += dw;
        dstRect.w += dw;
    }
    if(srcRect.y + srcRect.h > sy + height) {
        const int dh = sy + height - srcRect.y - srcRect.h;
        srcRect.h += dh;
        dstRect.h += dh;
    }
    if(srcRect.w <= 0 || srcRect.h <= 0 ||
       dstRect.w <= 0 || dstRect.h <= 0) return;
    if(mFlipTex) {
        srcRect.x = mFlipTex->width() - srcRect.x - srcRect.w;
    }
    render(r, srcRect, dstRect, flipped);
}

void eTexture::setOffset(const int x, const int y) {
    mOffsetX = x;
    mOffsetY = y;
}

bool eTexture::isNull() const {
    if(mFlipTex) return mFlipTex->isNull();
    else if(mParentTex) mParentTex->isNull();
    return mWidth <= 0 || mHeight <= 0;
}

void eTexture::setAlpha(const Uint8 alpha) {
    if(mFlipTex) mFlipTex->setAlpha(alpha);
    else if(mParentTex) mParentTex->setAlpha(alpha);
    else if(mTex) {
        SDL_SetTextureBlendMode(mTex, SDL_BLENDMODE_BLEND);
        SDL_SetTextureAlphaMod(mTex, alpha);
    }
}

void eTexture::clearAlphaMod() {
    setAlpha(255);
}

void eTexture::setColorMod(const Uint8 r, const Uint8 g, const Uint8 b) {
    if(mFlipTex) mFlipTex->setColorMod(r, g, b);
    else if(mParentTex) mParentTex->setColorMod(r, g, b);
    else if(mTex) {
        if(mColorMod.r == r && mColorMod.g == g && mColorMod.b == b) return;
        mColorMod = SDL_Color{r, g, b, 255};
        SDL_SetTextureColorMod(mTex, r, g, b);
    }
}

void eTexture::colorMod(Uint8& r, Uint8& g, Uint8& b) const {
    if(mFlipTex) return mFlipTex->colorMod(r, g, b);
    if(mParentTex) return mParentTex->colorMod(r, g, b);
    r = mColorMod.r;
    g = mColorMod.g;
    b = mColorMod.b;
}

void eTexture::clearColorMod() {
    setColorMod(255, 255, 255);
}

void eTexture::setFlipTex(const std::shared_ptr<eTexture>& tex) {
    mFlipTex = tex;
    mX = mFlipTex->x();
    mY = mFlipTex->y();
    mWidth = mFlipTex->width();
    mHeight = mFlipTex->height();
}

void eTexture::setParentTexture(const SDL_Rect& rect,
                                const std::shared_ptr<eTexture>& tex) {
    mParentTex = tex;
    mX = rect.x;
    mY = rect.y;
    mWidth = rect.w;
    mHeight = rect.h;
}

void eTexture::setDensity(const int d) {
    if(d < 1 || d == mDensity) return;
    mWidth = mWidth*mDensity/d;
    mHeight = mHeight*mDensity/d;
    mDensity = d;
}

void eTexture::setScaleMode(const SDL_ScaleMode mode) {
    if(mFlipTex) mFlipTex->setScaleMode(mode);
    else if(mParentTex) mParentTex->setScaleMode(mode);
    else if(mTex) SDL_SetTextureScaleMode(mTex, mode);
}
