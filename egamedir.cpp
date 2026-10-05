#include "egamedir.h"

#include <SDL2/SDL_filesystem.h>
#include <fstream>

#include <filesystem>

std::string eGameDir::sPath;
std::string eGameDir::sEmbeddedExeDir;
std::string eGameDir::sAdventuresDirOverride;

void eGameDir::initializeEmbedded(const std::string& engineDir) {
    const auto engine = std::filesystem::canonical(engineDir);
    sEmbeddedExeDir = engine.string() + "/Bin/";
    sPath = engine.parent_path().string() + "/";
}
std::string eGameDir::sAudioLanguage = "en";

void eGameDir::setAudioLanguage(const std::string& lang) {
    sAudioLanguage = lang;
}

const std::string& eGameDir::audioLanguage() {
    return sAudioLanguage;
}

std::string eGameDir::path(const std::string& path) {
    if(path.rfind("Audio/Voice/", 0) == 0) {
        const auto sub = path.substr(12);
        if(sAudioLanguage != "en") {
            const auto langPath = sPath + "Audio/Voice_" + sAudioLanguage + "/" + sub;
            if(std::filesystem::exists(langPath)) {
                return langPath;
            }
        }
        const auto enPath = sPath + "Audio/Voice_en/" + sub;
        if(std::filesystem::exists(enPath)) {
            return enPath;
        }
    }
    return sPath + path;
}

void eGameDir::initialize() {
    sPath = exeDir() + "../../";
    const auto zp = exeDir() + "../zeus_path.txt";
    std::ifstream file(zp);
    if(!file.good()) return;
    std::string str;
    const bool g = !!std::getline(file, str);
    if(!g) return;
    sPath = exeDir() + str;
}


std::string eGameDir::settingsPath() {
    return exeDir() + "../settings.txt";
}

std::string eGameDir::numbersPath() {
    return exeDir() + "../numbers.txt";
}

std::string eGameDir::iBinaryPath() {
    return exeDir() + "../interface.e";
}

std::string eGameDir::i15BinaryPath() {
    return exeDir() + "../i15.e";
}

std::string eGameDir::i30BinaryPath() {
    return exeDir() + "../i30.e";
}

std::string eGameDir::i45BinaryPath() {
    return exeDir() + "../i45.e";
}

std::string eGameDir::i60BinaryPath() {
    return exeDir() + "../i60.e";
}

std::string eGameDir::exeDir() {
    if(!sEmbeddedExeDir.empty()) return sEmbeddedExeDir;
    const auto d = SDL_GetBasePath();
    const std::string str(d);
    return str;
}

std::string eGameDir::adventuresDir() {
    if(!sAdventuresDirOverride.empty()) return sAdventuresDirOverride;
    return exeDir() + "../Adventures/";
}

std::string eGameDir::pakAdventuresDir() {
    // return "/home/ailuropoda/.eZeus/Zeus/Adventures/"; // !!!
    return eGameDir::path("Adventures/");
}

std::string eGameDir::saveDir() {
    return exeDir() + "../Save/";
}

std::string eGameDir::texturesDir() {
    const auto dir = eGameDir::path("Textures/");
    if(std::filesystem::exists(dir)) {
        return dir;
    }
    return exeDir() + "../Textures/";
}
