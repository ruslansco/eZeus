#include "elanguage.h"

#include "eloadtexthelper.h"

#include "exmlparser.h"
#include "egamedir.h"

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

    const std::string textXml = (lang == "ru") ? "Zeus_Text_ru.xml" : "Zeus_Text.xml";
    const std::string mmXml = (lang == "ru") ? "Zeus_MM_ru.xml" : "Zeus_MM.xml";
    const std::string langTxt = (lang == "ru") ? "Text/language_ru.txt" : "Text/language.txt";

    eXmlParser::sParse(fZeusText, eGameDir::exeDir() + "../" + textXml);
    eXmlParser::sParse(fZeusMM, eGameDir::exeDir() + "../" + mmXml);

    if(lang == "ru") {
        eLoadTextHelper::load(eGameDir::exeDir() + "../Text/language.txt", fText);
    }
    const std::string path = eGameDir::exeDir() + "../" + langTxt;
    return eLoadTextHelper::load(path, fText);
}
