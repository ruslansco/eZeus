#ifndef EWEATHER_H
#define EWEATHER_H

#include <SDL2/SDL.h>

#include <string>

class eDate;

// Seasons and weather over the city, for looks only: a gentle colour grade
// through the year, and spells of a few days of fair weather, cloud, wind or
// rain (most in winter, hardly any in summer; storms bring lightning). The
// weather follows from the date, so a save always shows the same sky; it
// eases in and out in real time.
namespace eWeather {
    // Once a frame: the viewed city's date and the real seconds since the
    // last frame. enabled: eSettings::fWeather.
    void update(const eDate& date, const double dt, const bool enabled);
    bool enabled();

    // 0..1, eased
    double wind();
    double rain();
    double clouds();

    // 0 spring, 1 summer, 2 autumn, 3 winter
    int season();
    // "Winter · Rain", for the top bar's date tooltip
    std::string description();
    // Textures/Panel/icons/<name>.svg: the weather, or the season when fair
    std::string iconName();

    // How far the top of a tree sprite drawn at (sx, sy) leans with the
    // wind, in the sprite's own pixels (0 when disabled).
    float treeLean(const int sx, const int sy);

    // The season's grade, cloud shadows, rain and lightning over `area`
    // (screen pixels, render scale 1). A map point (wx, wy) shows at
    // ((wx + dx)*zoom, (wy + dy)*zoom).
    void paint(SDL_Renderer* const r, const SDL_Rect& area,
               const double dx, const double dy, const double zoom);

    // Screenshots: a fixed state instead of the date's.
    void setOverride(const double rain, const double wind,
                     const double clouds, const int month);
}

#endif // EWEATHER_H
