#include "efonts.h"

#include "egamedir.h"

#include <algorithm>
#include <cmath>

std::map<eFont, TTF_Font*> eFonts::sFonts;
std::map<TTF_Font*, eFont> eFonts::sFontInfo;
std::string eFonts::sLanguage = "en";
bool eFonts::sClassic = false;

void eFonts::setLanguage(const std::string& lang) {
    if(sLanguage == lang) return;
    sLanguage = lang;
    clearFonts();
}

void eFonts::setClassic(const bool classic) {
    if(sClassic == classic) return;
    sClassic = classic;
    clearFonts();
}

const std::string& eFonts::language() {
    return sLanguage;
}

void eFonts::clearFonts() {
    for(auto& pair : sFonts) {
        if(pair.second) {
            TTF_CloseFont(pair.second);
        }
    }
    sFonts.clear();
    sFontInfo.clear();
}

TTF_Font* eFonts::requestFont(const eFont& font) {
    const auto it = sFonts.find(font);
    if(it != sFonts.end()) return it->second;
    const auto ttf = loadFont(font);
    if(ttf) {
        sFonts.insert({font, ttf});
        sFontInfo.insert({ttf, font});
    }
    return ttf;
}

TTF_Font* eFonts::defaultFont(const eResolution res) {
    const int fs = res.largeFontSize();
    return defaultFont(fs);
}

TTF_Font* eFonts::defaultFont(const int fs) {
    return font(eFontRole::body, fs);
}

TTF_Font* eFonts::displayFont(const int fs) {
    return font(eFontRole::display, fs);
}

TTF_Font* eFonts::headingFont(const int fs) {
    return font(eFontRole::heading, fs);
}

TTF_Font* eFonts::labelFont(const int fs) {
    return font(eFontRole::label, fs);
}

TTF_Font* eFonts::font(const eFontRole role, const int fs) {
    const auto dir = eGameDir::exeDir() + "../Fonts/";
    if(role == eFontRole::display || sClassic) {
        const std::string fontFile = (sLanguage == "ru") ? "Zeus_ru.ttf" : "Zeus.ttf";
        return requestFont({dir + fontFile, fs});
    }
    // Alegreya-UI.ttf is the Alegreya variable font with its line box
    // tightened (ascent 880, descent 270) to the Zeus font's line height;
    // its named instances are 1 Regular, 2 Medium, 3 Bold
    int instance = 1;
    switch(role) {
    case eFontRole::heading: instance = 3; break;
    case eFontRole::label: instance = 2; break;
    default: break;
    }
    if(const auto f = requestFont({dir + "Alegreya-UI.ttf", fs, instance})) return f;
    const std::string fontFile = (sLanguage == "ru") ? "Zeus_ru.ttf" : "Zeus.ttf";
    return requestFont({dir + fontFile, fs});
}

TTF_Font* eFonts::loadFont(const eFont& font) {
    const long index = static_cast<long>(font.fInstance) << 16;
    const auto ttf = TTF_OpenFontIndex(font.fPath.c_str(), font.fPtSize, index);
    if(!ttf) {
        printf("Failed to load font! SDL_ttf Error: %s\n", TTF_GetError());
    }
    return ttf;
}

TTF_Font* eFonts::forText(TTF_Font* const font, const std::string& text) {
    if(!font) return font;
    const auto it = sFontInfo.find(font);
    if(it == sFontInfo.end()) return font;
    const auto& info = it->second;
    static const std::string ru = "Zeus_ru.ttf";
    const auto& path = info.fPath;
    if(path.size() >= ru.size() &&
       path.compare(path.size() - ru.size(), ru.size(), ru) == 0) {
        return font;
    }
    // decode the UTF-8; plain ASCII never needs the other font
    const auto* s = reinterpret_cast<const unsigned char*>(text.c_str());
    const size_t n = text.size();
    for(size_t i = 0; i < n;) {
        const unsigned char c = s[i];
        Uint32 cp = c;
        int len = 1;
        if(c < 0x80) {
            i++;
            continue;
        } else if((c & 0xE0) == 0xC0 && i + 1 < n) {
            cp = ((c & 0x1F) << 6) | (s[i + 1] & 0x3F);
            len = 2;
        } else if((c & 0xF0) == 0xE0 && i + 2 < n) {
            cp = ((c & 0x0F) << 12) | ((s[i + 1] & 0x3F) << 6) | (s[i + 2] & 0x3F);
            len = 3;
        } else if((c & 0xF8) == 0xF0 && i + 3 < n) {
            cp = ((c & 0x07) << 18) | ((s[i + 1] & 0x3F) << 12) |
                 ((s[i + 2] & 0x3F) << 6) | (s[i + 3] & 0x3F);
            len = 4;
        }
        i += len;
        if(TTF_GlyphIsProvided32(font, cp)) continue;
        const auto dir = path.substr(0, path.find_last_of('/') + 1);
        const auto alt = requestFont({dir + ru, info.fPtSize});
        if(alt && TTF_GlyphIsProvided32(alt, cp)) return alt;
        return font;
    }
    return font;
}
