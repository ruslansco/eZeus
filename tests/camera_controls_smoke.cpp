#include "esettings.h"
#include "egamedir.h"
#include "widgets/emouseevent.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <limits>

// Run a copy from a disposable <temporary>/eZeus/Bin directory.
// Refuses to overwrite any existing settings file.
int main() {
    const auto path = eGameDir::settingsPath();
    if(std::filesystem::exists(path)) return 2;
    const auto check = [](bool ok, const char* why) {
        if(!ok) throw std::runtime_error(why);
    };
    const auto read = [&](const char* text) {
        std::ofstream(path) << text;
        eSettings s; s.read(); return s;
    };
    try {
        eKeyBindings defaults;
        check(defaults.fClone == SDL_SCANCODE_C && defaults.fCameraRotateLeft == SDL_SCANCODE_Q &&
              defaults.fCameraRotateRight == SDL_SCANCODE_E, "new defaults");
        auto s = read("key_clone \"Q\"\nkey_rotate \"R\"\n");
        check(s.fKeyBindings == defaults, "legacy defaults migrate");
        s.write(); eSettings roundTrip; roundTrip.read();
        check(roundTrip.fKeyBindings == defaults, "new settings persist");
        s = read("key_clone \"Q\"\nkey_pause \"C\"\n");
        check(s.fKeyBindings.fClone == SDL_SCANCODE_Q &&
              s.fKeyBindings.fCameraRotateLeft == SDL_SCANCODE_UNKNOWN &&
              s.fKeyBindings.fPause == SDL_SCANCODE_C, "C conflict preserves eyedropper");
        s.write(); roundTrip = {}; roundTrip.read();
        check(roundTrip.fKeyBindings == s.fKeyBindings, "unbound key persists");
        s = read("key_clone \"V\"\nkey_objectives \"E\"\n");
        check(s.fKeyBindings.fClone == SDL_SCANCODE_V && s.fKeyBindings.fObjectives == SDL_SCANCODE_E &&
              s.fKeyBindings.fCameraRotateLeft == SDL_SCANCODE_Q &&
              s.fKeyBindings.fCameraRotateRight == SDL_SCANCODE_UNKNOWN, "custom actions preserved");
        s = read("key_clone \"Q\"\nkey_camera_rotate_left \"J\"\nkey_camera_rotate_right \"L\"\n");
        check(s.fKeyBindings.fClone == SDL_SCANCODE_Q &&
              s.fKeyBindings.fCameraRotateLeft == SDL_SCANCODE_J &&
              s.fKeyBindings.fCameraRotateRight == SDL_SCANCODE_L, "explicit camera configuration");
        s = read("key_camera_rotate_right \"Q\"\n");
        check(s.fKeyBindings.fCameraRotateLeft == SDL_SCANCODE_UNKNOWN &&
              s.fKeyBindings.fCameraRotateRight == SDL_SCANCODE_Q, "partial configuration avoids duplicate");
        s = read("key_camera_rotate_left \"\"\nkey_camera_rotate_right \"\"\n");
        s.write(); roundTrip = {}; roundTrip.read();
        check(roundTrip.fKeyBindings == s.fKeyBindings, "explicit unbound directions persist");
        for(int dir = 0; dir < 4; ++dir) {
            for(int turns = -12; turns <= 12; ++turns) {
                const auto d = static_cast<eWorldDirection>(dir);
                check(eRotateWorldDirection(eRotateWorldDirection(d, turns), -turns) == d, "inverse rotation");
                check(eRotateWorldDirection(d, 4) == d, "full revolution");
            }
        }
        check(static_cast<int>(eRotateWorldDirection(eWorldDirection::N, std::numeric_limits<int>::min())) == 0,
              "large negative rotation");
        const eKeyPressEvent repeat(2, 3, false, false, eMouseButton::none, SDL_SCANCODE_Q, true);
        check(repeat.translated(4, 5).repeat() && repeat.withPosition(10, 10).repeat(), "repeat survives dispatch translation");
        std::filesystem::remove(path);
        std::cout << "PASS camera bindings: migration, conflicts, persistence, wraparound, repeat dispatch\n";
        return 0;
    } catch(const std::exception& e) {
        std::filesystem::remove(path);
        std::cerr << "FAIL " << e.what() << '\n';
        return 1;
    }
}
