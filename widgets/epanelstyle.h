#ifndef EPANELSTYLE_H
#define EPANELSTYLE_H

#include <SDL2/SDL.h>

#include <string>

// Drawing kit of the in-game side panel ("lapis and gold"): the art in
// Textures/Panel/ (art/panel/: Blender-rendered medallions and emblem, a
// lapis stone tile, SVG icons rasterized here at the exact pixel size) and
// anti-aliased rounded shapes. All coordinates are screen pixels.
namespace ePanel {

// Seconds since the first call; drives the panel animations.
double time();
// Exponential approach factor for a frame of dt seconds at rate k.
double approach(const double dt, const double k);

enum class eMedalPart { ring, disc, discActive };

// White SVG icon (Textures/Panel/icons/<name>.svg) rasterized at px x px.
SDL_Texture* icon(SDL_Renderer* const r, const std::string& name, const int px);
// Medallion part, emblem and lapis textures (smallest packed size >= px).
SDL_Texture* medal(SDL_Renderer* const r, const eMedalPart part, const int px);
SDL_Texture* emblem(SDL_Renderer* const r, const int px, int& w, int& h);
SDL_Texture* lapis(SDL_Renderer* const r);
// Soft radial dot for glows and shadows; a white pixel for flat fills.
SDL_Texture* dot(SDL_Renderer* const r);
SDL_Texture* white(SDL_Renderer* const r);

void fill(SDL_Renderer* const r, const SDL_FRect& rect, const SDL_Color c);
// Vertical gradient.
void gradient(SDL_Renderer* const r, const SDL_FRect& rect,
              const SDL_Color top, const SDL_Color bottom);
// Anti-aliased rounded rectangle: filled (line <= 0) or an outline of
// `line` pixels, with a vertical colour gradient.
void roundRect(SDL_Renderer* const r, const SDL_FRect& rect, const float radius,
               const SDL_Color top, const SDL_Color bottom, const float line = 0);
void glow(SDL_Renderer* const r, const float cx, const float cy,
          const float rx, const float ry, const SDL_Color c, const bool additive);
// Gold rule fading out at both ends, with a small diamond in the middle.
void goldRule(SDL_Renderer* const r, const float x, const float y,
              const float w, const float thickness, const Uint8 alpha,
              const bool diamond);
void diamond(SDL_Renderer* const r, const float cx, const float cy,
             const float s, const SDL_Color c);
// Icon centred on (cx, cy) with a soft drop shadow, tinted c.
void drawIcon(SDL_Renderer* const r, const std::string& name,
              const float cx, const float cy, const int px,
              const SDL_Color c, const bool shadow = true, const double angle = 0);
// A gold medallion button face: enamel (or gold when active) inlay, icon, rim.
// hover/active/press are 0..1 animation amounts.
void medallion(SDL_Renderer* const r, const float cx, const float cy,
               const float diameter, const std::string& iconName,
               const double hover, const double active, const double press,
               const bool enabled = true);

// The panel's body (a shadow over the map on its left, lapis, a gold bevel)
// over x, y, w, h; unit is one unit of the original art in pixels.
void body(SDL_Renderer* const r, const float x, const float y,
          const float w, const float h, const float unit);
// A dark inset well with a thin gold rim.
void well(SDL_Renderer* const r, const SDL_FRect& f, const float radius,
          const float hairline, const bool strong = false);
// The laurel emblem centred on cx from top, at most maxW wide and fitting
// in room, with the passing glint.
void emblemAt(SDL_Renderer* const r, const float cx, const float top,
              const float maxW, const float room, const float unit);

extern const SDL_Color kGold;
extern const SDL_Color kGoldPale;
extern const SDL_Color kIvory;
extern const SDL_Color kInk;      // dark lapis, for icons on gold

}

#endif // EPANELSTYLE_H
