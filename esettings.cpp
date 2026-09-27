#include "esettings.h"

#include <cstdlib>

#include <algorithm>

#include <fstream>
#include <iostream>

#include "egamedir.h"
#include "eloadtexthelper.h"

std::vector<eTileSize> eSettings::availableSizes() const {
    std::vector<eTileSize> sizes;
    if(fTinyTextures) {
        sizes.push_back(eTileSize::s15);
    }
    if(fSmallTextures) {
        sizes.push_back(eTileSize::s30);
    }
    if(fMediumTextures) {
        sizes.push_back(eTileSize::s45);
    }
    if(fLargeTextures) {
        sizes.push_back(eTileSize::s60);
    }
    return sizes;
}

void eSettings::write() const {
    // screenshot / benchmark runs must not change the player's settings
    if(getenv("EZEUS_SHOT") || getenv("EZEUS_MENU_SHOT")) return;
    const auto path = eGameDir::settingsPath();
    std::ofstream file;
    file.open(path);
    file << "tiny_textures" << " " <<
            (fTinyTextures ? "\"true\"" : "\"false\"") << "\n";
    file << "small_textures" << " " <<
            (fSmallTextures ? "\"true\"" : "\"false\"") << "\n";
    file << "medium_textures" << " " <<
            (fMediumTextures ? "\"true\"" : "\"false\"") << "\n";
    file << "large_textures" << " " <<
            (fLargeTextures ? "\"true\"" : "\"false\"") << "\n";
    file << "fullscreen" << " " <<
            (fFullscreen ? "\"true\"" : "\"false\"") << "\n";
    const auto wStr = std::to_string(fRes.width());
    file << "width" << " " << "\"" << wStr << "\"" << "\n";
    const auto hStr = std::to_string(fRes.height());
    file << "height" << " " << "\"" << hStr << "\"" << "\n";
    file << "language" << " \"" << fLanguage << "\"\n";
    file << "audio_language" << " \"" << fAudioLanguage << "\"\n";
    file << "leader" << " \"" << fLeader << "\"\n";
    file << "autosave_minutes" << " \"" << fAutosaveMinutes << "\"\n";
    file << "autosave_slots" << " \"" << fAutosaveSlots << "\"\n";
    auto writeKey = [&](const char* name, SDL_Scancode code) {
        const char* keyName = SDL_GetScancodeName(code);
        file << name << " \"" << (keyName ? keyName : "") << "\"\n";
    };
    writeKey("key_move_up", fKeyBindings.fMoveUp);
    writeKey("key_move_down", fKeyBindings.fMoveDown);
    writeKey("key_move_left", fKeyBindings.fMoveLeft);
    writeKey("key_move_right", fKeyBindings.fMoveRight);
    writeKey("key_pause", fKeyBindings.fPause);
    writeKey("key_rotate", fKeyBindings.fRotate);
    writeKey("key_clone", fKeyBindings.fClone);
    writeKey("key_demolish", fKeyBindings.fDemolish);
    writeKey("key_speed_up", fKeyBindings.fSpeedUp);
    writeKey("key_speed_down", fKeyBindings.fSpeedDown);
    writeKey("key_quick_save", fKeyBindings.fQuickSave);
    writeKey("key_objectives", fKeyBindings.fObjectives);
    file.close();
}

void eSettings::read() {
    const auto path = eGameDir::settingsPath();
    std::map<std::string, std::string> settings;
    const bool r = eLoadTextHelper::load(path, settings);
    if(!r) return;
    fTinyTextures = settings["tiny_textures"] == "true";
    fSmallTextures = settings["small_textures"] == "true";
    fMediumTextures = settings["medium_textures"] == "true";
    fLargeTextures = settings["large_textures"] == "true";
    fFullscreen = settings["fullscreen"] == "true";
    const auto widthStr = settings["width"];
    const auto heightStr = settings["height"];
    if(!widthStr.empty() && !heightStr.empty()) {
        const int width = std::stoi(widthStr);
        const int height = std::stoi(heightStr);
        fRes = eResolution(width, height);
    }
    if(settings.find("language") != settings.end() && !settings["language"].empty()) {
        fLanguage = settings["language"];
    }
    if(settings.find("audio_language") != settings.end() && !settings["audio_language"].empty()) {
        fAudioLanguage = settings["audio_language"];
    }
    if(settings.find("leader") != settings.end() && !settings["leader"].empty()) {
        fLeader = settings["leader"];
    }
    const auto readInt = [&](const std::string& name, int& to, const int min, const int max) {
        const auto it = settings.find(name);
        if(it == settings.end() || it->second.empty()) return;
        try {
            to = std::clamp(std::stoi(it->second), min, max);
        } catch(...) {}
    };
    readInt("autosave_minutes", fAutosaveMinutes, 0, 240);
    readInt("autosave_slots", fAutosaveSlots, 1, 20);

    auto readKey = [&](const std::string& name, SDL_Scancode& code) {
        if(settings.find(name) != settings.end() && !settings[name].empty()) {
            SDL_Scancode parsed = SDL_GetScancodeFromName(settings[name].c_str());
            if(parsed != SDL_SCANCODE_UNKNOWN) {
                code = parsed;
            }
        }
    };
    readKey("key_move_up", fKeyBindings.fMoveUp);
    readKey("key_move_down", fKeyBindings.fMoveDown);
    readKey("key_move_left", fKeyBindings.fMoveLeft);
    readKey("key_move_right", fKeyBindings.fMoveRight);
    readKey("key_pause", fKeyBindings.fPause);
    readKey("key_rotate", fKeyBindings.fRotate);
    readKey("key_clone", fKeyBindings.fClone);
    readKey("key_demolish", fKeyBindings.fDemolish);
    readKey("key_speed_up", fKeyBindings.fSpeedUp);
    readKey("key_speed_down", fKeyBindings.fSpeedDown);
    readKey("key_quick_save", fKeyBindings.fQuickSave);
    readKey("key_objectives", fKeyBindings.fObjectives);
}

