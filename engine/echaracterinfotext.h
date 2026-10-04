#ifndef ECHARACTERINFOTEXT_H
#define ECHARACTERINFOTEXT_H

#include <string>

class eCharacter;
class eSoundVector;

// What the SDL character window says about a walker: its name, its occupation, the line it speaks (chosen from the
// city's state and what the walker is doing, with the matching recorded voice) and, for carts, its errand. The SDL
// info widget and the Godot character panel both ask here. Which of several lines is spoken uses cosmetic
// randomness, so looking at a walker never changes the simulation.
namespace eCharacterInfoText {
    struct eMessage {
        std::string fText;
        eSoundVector* fSounds = nullptr;
        int fSoundId = -1;

        bool playSound() const;
        // The voice file of the line (empty when the walker has none).
        std::string soundPath() const;
    };

    std::string name(const eCharacter* const c);
    std::string occupation(const eCharacter* const c);
    eMessage message(eCharacter* const c);
    std::string errand(eCharacter* const c);
}

#endif // ECHARACTERINFOTEXT_H
