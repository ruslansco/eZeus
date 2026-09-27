#include "elanguage.h"

#include "eloadtexthelper.h"

#include "exmlparser.h"
#include "egamedir.h"
#include <filesystem>

eLanguage eLanguage::instance;

const std::string& eLanguage::text(const std::string& key) {
    return instance.fText[key];
}

const std::string& eLanguage::zeusText(const int g, const int s) {
    return instance.fZeusText[g][s];
}

const eMM& eLanguage::zeusMM(const int id) {
    return instance.fZeusMM[id];
}

bool eLanguage::load(const std::string& lang) {
    return instance.loadImpl(lang);
}

bool eLanguage::reload(const std::string& lang) {
    instance.mLoaded = false;
    instance.fText.clear();
    instance.fZeusText.clear();
    instance.fZeusMM.clear();
    return instance.loadImpl(lang);
}

bool eLanguage::loaded() {
    return instance.mLoaded;
}

const std::string& eLanguage::language() {
    return instance.mLanguage;
}

bool eLanguage::loadImpl(const std::string& lang) {
    if(mLoaded && mLanguage == lang) return false;
    mLoaded = true;
    mLanguage = lang;

    const std::string baseDir = eGameDir::exeDir() + "../";

    std::string textXml = "Zeus_Text.xml";
    if(lang != "en") {
        const std::string candidate = "Zeus_Text_" + lang + ".xml";
        if(std::filesystem::exists(baseDir + candidate)) {
            textXml = candidate;
        }
    }

    std::string mmXml = "Zeus_MM.xml";
    if(lang != "en") {
        const std::string candidate = "Zeus_MM_" + lang + ".xml";
        if(std::filesystem::exists(baseDir + candidate)) {
            mmXml = candidate;
        }
    }

    eXmlParser::sParse(fZeusText, baseDir + textXml);
    eXmlParser::sParse(fZeusMM, baseDir + mmXml);

    // Always load base English strings first as default fallback
    eLoadTextHelper::load(baseDir + "text/language.txt", fText);

    // Overlay language-specific translations if present
    if(lang != "en") {
        const std::string langTxt = baseDir + "text/language_" + lang + ".txt";
        if(std::filesystem::exists(langTxt)) {
            eLoadTextHelper::load(langTxt, fText);
        }
    }
    return true;
}
