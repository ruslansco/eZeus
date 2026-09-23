#include "efonts.h"

#include "egamedir.h"

std::map<eFont, TTF_Font*> eFonts::sFonts;
std::string eFonts::sLanguage = "en";

void eFonts::setLanguage(const std::string& lang) {
    if(sLanguage == lang) return;
    sLanguage = lang;
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
}

TTF_Font* eFonts::requestFont(const eFont& font) {
    const auto it = sFonts.find(font);
    if(it != sFonts.end()) return it->second;
    const auto ttf = loadFont(font);
    if(ttf) sFonts.insert({font, ttf});
    return ttf;
}

TTF_Font* eFonts::defaultFont(const eResolution res) {
    const int fs = res.largeFontSize();
    return defaultFont(fs);
}

TTF_Font* eFonts::defaultFont(const int fs) {
    const std::string fontFile = (sLanguage == "ru") ? "Zeus_ru.ttf" : "Zeus.ttf";
    return requestFont({eGameDir::exeDir() + "../Fonts/" + fontFile, fs});
}

TTF_Font* eFonts::loadFont(const eFont& font) {
    const auto ttf = TTF_OpenFont(font.fPath.c_str(), font.fPtSize);
    if(!ttf) {
        printf("Failed to load font! SDL_ttf Error: %s\n", TTF_GetError());
    }
    return ttf;
}
