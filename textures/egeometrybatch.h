#ifndef EGEOMETRYBATCH_H
#define EGEOMETRYBATCH_H

#include <SDL2/SDL.h>

// Collects textured quads (HD terrain diamonds) and submits them as one
// SDL_RenderGeometry call per texture instead of one call per quad, which
// otherwise dominates the frame when zoomed out.
//
// Quads are grouped by texture in order of first use, so a run of queued
// quads may be reordered across tiles. That is only valid for flat,
// non-overlapping ground; anything else must be drawn after sFlush().
// Every other draw, clip, scale or render-target change must call sFlush()
// first (eTexture::render, ePainter and the game widget do).
class eGeometryBatch {
public:
    static void sQueueQuad(SDL_Renderer* const r,
                           SDL_Texture* const tex,
                           const SDL_Vertex v[4]);
    // Four perimeter vertices and an independent center (fertile-tile marker).
    static void sQueueFan(SDL_Renderer* r, SDL_Texture* tex, const SDL_Vertex v[5]);
    static void sFlush();
};

#endif // EGEOMETRYBATCH_H
