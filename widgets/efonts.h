#ifndef EFONTS_H
#define EFONTS_H

#include <SDL2/SDL_ttf.h>
#include <map>
#include <string>

#include "eresolution.h"

struct eFont {
    std::string fPath;
    int fPtSize;
    // named instance of a variable font (FreeType face index >> 16)
    int fInstance = 0;

    bool isNull() const { return fPath.empty(); }
};

inline bool operator<(const eFont& p0, const eFont& p1) {
    if(p0.fPath == p1.fPath) {
        if(p0.fPtSize == p1.fPtSize) return p0.fInstance < p1.fInstance;
        return p0.fPtSize < p1.fPtSize;
    }
    return p0.fPath < p1.fPath;
}

// What a piece of text is for; each role has its own face.
//  display - the Greek Zeus font: window titles, building and people names
//  heading - Alegreya Bold: small headings inside cards and lists
//  label   - Alegreya Medium: buttons, tabs, badges, numbers on bars
//  body    - Alegreya Regular: everything else (the default)
// With the classic font option every role uses the Zeus font.
enum class eFontRole {
    display, heading, label, body
};

class eFonts {
public:
    static TTF_Font* requestFont(const eFont& font);
    static TTF_Font* font(const eFontRole role, const int fs);
    // body text
    static TTF_Font* defaultFont(const eResolution res);
    static TTF_Font* defaultFont(const int fs);
    static TTF_Font* displayFont(const int fs);
    static TTF_Font* headingFont(const int fs);
    static TTF_Font* labelFont(const int fs);
    static void setLanguage(const std::string& lang);
    static const std::string& language();
    static void setClassic(const bool classic);
    static bool classic() { return sClassic; }
    static void clearFonts();
    // font, or the Cyrillic font (Zeus_ru.ttf) at the same size when font
    // lacks a letter of text (Russian city names with English text)
    static TTF_Font* forText(TTF_Font* const font, const std::string& text);
private:
    static TTF_Font* loadFont(const eFont& font);

    static std::map<eFont, TTF_Font*> sFonts;
    static std::map<TTF_Font*, eFont> sFontInfo;
    static std::string sLanguage;
    static bool sClassic;
};

#endif // EFONTS_H
