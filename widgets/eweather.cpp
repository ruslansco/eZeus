#include "eweather.h"

#include "engine/edate.h"
#include "epanelstyle.h"
#include "elanguage.h"
#include "audio/esounds.h"
#include "textures/egeometrybatch.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

namespace {
struct eSky {
    double fRain = 0;
    double fWind = 0;
    double fClouds = 0;
    bool fStorm = false;
};

bool gEnabled = true;
bool gStarted = false;
eSky gTarget;
eSky gNow;
double gMonth = 6;           // 0..12, continuous through the year
int gSeason = 1;

bool gOverride = false;
bool gForceOff = false;      // EZEUS_SHOT_WEATHER=off
eSky gOverrideSky;
int gOverrideMonth = 6;

double gFlash = 0;           // lightning, fading
double gNextStrike = 8;      // seconds to the next strike in a storm
double gThunderIn = -1;      // seconds to the thunderclap

struct eDrop {
    float fX, fY, fSpeed, fLen;
};
std::vector<eDrop> gDrops;

uint32_t hash(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

double unit(const uint32_t h) {
    return (h & 0xffffff)/double(0x1000000);
}

double frand() {
    return std::rand()/double(RAND_MAX);
}

// how likely a spell of rain is, by month (a Mediterranean year)
const double kRainChance[12] = {0.45, 0.40, 0.30, 0.22, 0.12, 0.04,
                                0.02, 0.03, 0.08, 0.22, 0.35, 0.45};

// the season's grade: a multiply colour, then a little light added
struct eGrade {
    double fMod[3];
    double fAdd[3];
};
const eGrade kGrades[12] = {
    {{224, 230, 244}, {0, 2, 8}},     // January: cool, a little darker
    {{230, 236, 244}, {0, 2, 6}},
    {{244, 252, 240}, {0, 3, 0}},     // March: fresh
    {{248, 255, 240}, {2, 5, 0}},
    {{255, 255, 238}, {4, 5, 0}},
    {{255, 250, 230}, {8, 6, 0}},     // June: warm
    {{255, 246, 222}, {10, 7, 0}},
    {{255, 244, 220}, {10, 6, 0}},
    {{255, 242, 218}, {8, 4, 0}},     // September: golden
    {{252, 236, 212}, {7, 3, 0}},
    {{240, 232, 226}, {3, 2, 2}},
    {{226, 230, 242}, {0, 2, 7}}};

eSky skyFor(const eDate& date) {
    const int month = static_cast<int>(date.month());
    int doy = date.day() - 1;
    for(int m = 0; m < month; m++) doy += eMonthHelper::days(static_cast<eMonth>(m));
    // spells of four days
    const uint32_t key = static_cast<uint32_t>(date.year()*97 + doy/4 + 100000);
    const double r0 = unit(hash(key*3 + 1));
    const double r1 = unit(hash(key*3 + 2));
    const double r2 = unit(hash(key*3 + 3));
    const bool cold = month >= 9 || month <= 2;
    eSky s;
    if(r0 < kRainChance[month]) {
        s.fRain = 0.45 + 0.55*r1;
        s.fStorm = cold && s.fRain > 0.86;
        s.fClouds = 0.85 + 0.15*r2;
        s.fWind = std::max(0.45, 0.35 + 0.5*r2 + (s.fStorm ? 0.3 : 0));
    } else {
        const bool summer = month >= 5 && month <= 7;
        s.fClouds = (summer ? 0.08 : 0.18) + (summer ? 0.25 : 0.45)*r1;
        s.fWind = 0.08 + 0.55*r2*r2 + (cold ? 0.12 : 0);
    }
    s.fWind = std::min(1.0, s.fWind);
    return s;
}

void fillMode(SDL_Renderer* const r, const SDL_Rect& a, const SDL_BlendMode mode,
              const double c[3], const Uint8 alpha) {
    SDL_SetRenderDrawBlendMode(r, mode);
    SDL_SetRenderDrawColor(r, static_cast<Uint8>(std::clamp(c[0], 0.0, 255.0)),
                           static_cast<Uint8>(std::clamp(c[1], 0.0, 255.0)),
                           static_cast<Uint8>(std::clamp(c[2], 0.0, 255.0)), alpha);
    SDL_RenderFillRect(r, &a);
    SDL_SetRenderDrawBlendMode(r, SDL_BLENDMODE_BLEND);
}
}

void eWeather::setOverride(const double rain, const double wind,
                           const double clouds, const int month) {
    gOverride = true;
    gOverrideSky.fRain = rain;
    gOverrideSky.fWind = wind;
    gOverrideSky.fClouds = clouds;
    gOverrideSky.fStorm = rain > 0.86;
    gOverrideMonth = std::clamp(month, 0, 11);
    gStarted = false;
}

void eWeather::update(const eDate& date, const double dt, const bool enabled) {
    gEnabled = enabled && !gForceOff;
    static bool sEnvRead = false;
    if(!sEnvRead) {
        sEnvRead = true;
        // EZEUS_SHOT_WEATHER=<rain>,<wind>,<clouds>,<month 0-11> (screenshots)
        if(const char* const s = getenv("EZEUS_SHOT_WEATHER")) {
            if(std::string(s) == "off") gForceOff = true;
            double v[4] = {0, 0, 0, 6};
            std::sscanf(s, "%lf,%lf,%lf,%lf", &v[0], &v[1], &v[2], &v[3]);
            setOverride(v[0], v[1], v[2], static_cast<int>(v[3]));
        }
    }
    int month = static_cast<int>(date.month());
    double day = (date.day() - 1)/double(std::max(1, eMonthHelper::days(date.month())));
    if(gOverride) {
        gTarget = gOverrideSky;
        month = gOverrideMonth;
        day = 0.5;
    } else {
        gTarget = skyFor(date);
    }
    gMonth = month + day;
    gSeason = ((month + 12 - 2)/3) % 4;   // March-May spring ...
    if(!gStarted) {
        gStarted = true;
        gNow = gTarget;
    } else {
        const double k = ePanel::approach(dt, 0.35);
        gNow.fRain += (gTarget.fRain - gNow.fRain)*k;
        gNow.fWind += (gTarget.fWind - gNow.fWind)*k;
        gNow.fClouds += (gTarget.fClouds - gNow.fClouds)*k;
        gNow.fStorm = gTarget.fStorm;
    }

    // lightning in a storm, the thunder a moment later
    gFlash = std::max(0.0, gFlash - dt*3.2);
    if(gEnabled && gNow.fStorm && gNow.fRain > 0.6 && !gOverride) {
        gNextStrike -= dt;
        if(gNextStrike <= 0) {
            gFlash = 1;
            gThunderIn = 0.5 + 1.8*frand();
            gNextStrike = 12 + 30*frand();
        }
    }
    if(gThunderIn >= 0) {
        gThunderIn -= dt;
        if(gThunderIn < 0) eSounds::playMenuThunderSound();
    }
}

bool eWeather::enabled() { return gEnabled; }
double eWeather::wind() { return gNow.fWind; }
double eWeather::rain() { return gNow.fRain; }
double eWeather::clouds() { return gNow.fClouds; }
int eWeather::season() { return gSeason; }

std::string eWeather::description() {
    const auto tr = [](const char* key, const char* fallback) {
        const auto& t = eLanguage::text(key);
        return t.empty() ? std::string(fallback) : t;
    };
    static const char* const seasons[4][2] = {{"weather_spring", "Spring"},
                                              {"weather_summer", "Summer"},
                                              {"weather_autumn", "Autumn"},
                                              {"weather_winter", "Winter"}};
    std::string s = tr(seasons[gSeason][0], seasons[gSeason][1]);
    if(!gEnabled) return s;
    std::string w;
    if(gTarget.fStorm) w = tr("weather_storm", "Storm");
    else if(gTarget.fRain > 0.05) w = tr("weather_rain", "Rain");
    else if(gTarget.fWind > 0.5) w = tr("weather_windy", "Windy");
    else if(gTarget.fClouds > 0.45) w = tr("weather_cloudy", "Cloudy");
    else w = tr("weather_fair", "Fair");
    return s + "  ·  " + w;
}

std::string eWeather::iconName() {
    static const char* const seasons[4] = {"season_spring", "season_summer",
                                           "season_autumn", "season_winter"};
    if(gEnabled) {
        if(gTarget.fStorm) return "weather_storm";
        if(gTarget.fRain > 0.05) return "weather_rain";
        if(gTarget.fWind > 0.5) return "weather_wind";
        if(gTarget.fClouds > 0.45) return "weather_cloud";
    }
    return seasons[gSeason];
}

float eWeather::treeLean(const int sx, const int sy) {
    if(!gEnabled) return 0;
    const double t = ePanel::time();
    const double w = gNow.fWind;
    const double gust = 0.55 + 0.45*std::sin(t*0.45 + sx*0.0035 - sy*0.002);
    const double phase = t*(1.3 + 1.3*w) + sx*0.045 + sy*0.03;
    const double a = 0.25 + 2.6*w;
    return static_cast<float>(a*gust*(0.5 + 0.5*std::sin(phase)));
}

void eWeather::paint(SDL_Renderer* const r, const SDL_Rect& area,
                     const double dx, const double dy, const double zoom) {
    if(!gEnabled || area.w <= 0 || area.h <= 0) return;
    eGeometryBatch::sFlush();
    const double t = ePanel::time();
    const double rain = gNow.fRain;
    const double cl = gNow.fClouds;

    // cloud shadows, drifting over the map with the wind
    {
        const double tileW = 3600;
        const double tileH = 2200;
        const double speed = 8 + 34*gNow.fWind;
        const double ox = t*speed;
        const double oy = t*speed*0.28;
        const double wx0 = -dx - 700;
        const double wy0 = -dy - 500;
        const double wx1 = -dx + area.w/zoom + 700;
        const double wy1 = -dy + area.h/zoom + 500;
        const auto dotTex = ePanel::dot(r);
        SDL_SetTextureBlendMode(dotTex, SDL_BLENDMODE_BLEND);
        std::vector<SDL_Vertex> vs;
        std::vector<int> ids;
        const int i0 = static_cast<int>(std::floor((wx0 - ox)/tileW));
        const int i1 = static_cast<int>(std::floor((wx1 - ox)/tileW));
        const int j0 = static_cast<int>(std::floor((wy0 - oy)/tileH));
        const int j1 = static_cast<int>(std::floor((wy1 - oy)/tileH));
        for(int i = i0; i <= i1; i++) {
            for(int j = j0; j <= j1; j++) {
                for(int k = 0; k < 9; k++) {
                    const uint32_t h = hash(static_cast<uint32_t>((i*7919 + j)*31 + k));
                    const double show = unit(hash(h + 1));
                    if(show > cl*1.15) continue;
                    const double fade = std::clamp((cl*1.15 - show)*5, 0.0, 1.0);
                    const double cx = ox + (i + unit(h))*tileW;
                    const double cy = oy + (j + unit(hash(h + 2)))*tileH;
                    const double size = 260 + 380*unit(hash(h + 3));
                    for(int b = 0; b < 3; b++) {
                        const double bx = cx + (b - 1)*size*0.55;
                        const double by = cy + (b == 1 ? -0.18 : 0.08)*size;
                        const double rx = size*(b == 1 ? 0.8 : 0.6)*zoom;
                        const double ry = rx*0.55;
                        const float sx = static_cast<float>(area.x + (bx + dx)*zoom);
                        const float sy = static_cast<float>(area.y + (by + dy)*zoom);
                        const Uint8 a = static_cast<Uint8>(std::round((34 + 40*rain)*fade));
                        const SDL_Color c{8, 12, 28, a};
                        const int base = vs.size();
                        vs.push_back({{float(sx - rx), float(sy - ry)}, c, {0, 0}});
                        vs.push_back({{float(sx + rx), float(sy - ry)}, c, {1, 0}});
                        vs.push_back({{float(sx + rx), float(sy + ry)}, c, {1, 1}});
                        vs.push_back({{float(sx - rx), float(sy + ry)}, c, {0, 1}});
                        for(const int id : {0, 1, 2, 0, 2, 3}) ids.push_back(base + id);
                    }
                }
            }
        }
        if(!vs.empty()) {
            SDL_RenderGeometry(r, dotTex, vs.data(), vs.size(), ids.data(), ids.size());
        }
    }

    // the season's grade, darker and cooler under rain
    {
        const double pos = gMonth - 0.5;
        const double fl = std::floor(pos);
        const int m0 = (static_cast<int>(fl) % 12 + 12) % 12;
        const int m1 = (m0 + 1) % 12;
        const double f = pos - fl;
        double mod[3];
        double add[3];
        const double wet[3] = {196, 205, 220};
        const double dim = 1 - 0.05*cl;
        for(int c = 0; c < 3; c++) {
            mod[c] = kGrades[m0].fMod[c]*(1 - f) + kGrades[m1].fMod[c]*f;
            add[c] = kGrades[m0].fAdd[c]*(1 - f) + kGrades[m1].fAdd[c]*f;
            mod[c] = (mod[c]*(1 - 0.9*rain) + wet[c]*0.9*rain*mod[c]/255)*dim;
            add[c] *= 1 - rain;
        }
        fillMode(r, area, SDL_BLENDMODE_MOD, mod, 255);
        if(add[0] + add[1] + add[2] > 0.5) fillMode(r, area, SDL_BLENDMODE_ADD, add, 255);
    }

    // rain: slanted streaks falling through the view
    if(rain > 0.01) {
        static double sLast = -1;
        const double fdt = sLast < 0 ? 0 : std::min(0.1, t - sLast);
        sLast = t;
        const int maxDrops = 1400;
        if(gDrops.empty()) {
            gDrops.resize(maxDrops);
            for(auto& d : gDrops) {
                d.fX = frand();
                d.fY = frand();
                d.fSpeed = 0.8f + 0.45f*frand();
                d.fLen = 0.7f + 0.6f*frand();
            }
        }
        const double slant = 0.16 + 0.28*gNow.fWind;
        const double scale = area.h/1080.0;
        const double len = 34*scale;
        const float wdt = std::max(1.f, static_cast<float>(1.6*scale));
        const int n = std::min(maxDrops, static_cast<int>(maxDrops*rain*(area.w*area.h)/(1920.0*1080)));
        std::vector<SDL_Vertex> vs;
        std::vector<int> ids;
        vs.reserve(n*4);
        ids.reserve(n*6);
        const Uint8 a = static_cast<Uint8>(90 + 90*rain);
        for(int i = 0; i < n; i++) {
            auto& d = gDrops[i];
            d.fY += static_cast<float>(fdt*1.5*d.fSpeed);
            d.fX += static_cast<float>(fdt*1.5*d.fSpeed*slant*area.h/area.w);
            if(d.fY > 1) {
                d.fY -= 1;
                d.fX = frand();
            }
            if(d.fX > 1) d.fX -= 1;
            const float x = area.x + d.fX*area.w;
            const float y = area.y + d.fY*area.h;
            const float l = static_cast<float>(len*d.fLen);
            const float tx = x - static_cast<float>(l*slant);
            const float ty = y - l;
            const SDL_Color head{198, 212, 232, a};
            const SDL_Color tail{198, 212, 232, 0};
            const int base = vs.size();
            vs.push_back({{tx, ty}, tail, {0.5f, 0.5f}});
            vs.push_back({{tx + wdt, ty}, tail, {0.5f, 0.5f}});
            vs.push_back({{x + wdt, y}, head, {0.5f, 0.5f}});
            vs.push_back({{x, y}, head, {0.5f, 0.5f}});
            for(const int id : {0, 1, 2, 0, 2, 3}) ids.push_back(base + id);
        }
        if(!vs.empty()) {
            SDL_RenderGeometry(r, ePanel::white(r), vs.data(), vs.size(), ids.data(), ids.size());
        }
    }

    // lightning: two quick flickers
    if(gFlash > 0.01) {
        const double f = gFlash > 0.75 ? 1 : (gFlash > 0.55 ? 0.35 : gFlash);
        const double c[3] = {210*f*0.45, 220*f*0.45, 255*f*0.45};
        fillMode(r, area, SDL_BLENDMODE_ADD, c, 255);
    }
}
