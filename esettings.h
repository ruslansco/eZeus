#ifndef ESETTINGS_H
#define ESETTINGS_H

#include <SDL2/SDL_scancode.h>
#include "engine/etile.h"
#include "widgets/eresolution.h"

struct eKeyBindings {
  SDL_Scancode fMoveUp = SDL_SCANCODE_W;
  SDL_Scancode fMoveDown = SDL_SCANCODE_S;
  SDL_Scancode fMoveLeft = SDL_SCANCODE_A;
  SDL_Scancode fMoveRight = SDL_SCANCODE_D;

  SDL_Scancode fPause = SDL_SCANCODE_SPACE;
  SDL_Scancode fRotate = SDL_SCANCODE_R;
  SDL_Scancode fClone = SDL_SCANCODE_Q;
  SDL_Scancode fDemolish = SDL_SCANCODE_X;

  SDL_Scancode fSpeedUp = SDL_SCANCODE_RIGHTBRACKET;
  SDL_Scancode fSpeedDown = SDL_SCANCODE_LEFTBRACKET;
  SDL_Scancode fQuickSave = SDL_SCANCODE_F5;
  SDL_Scancode fObjectives = SDL_SCANCODE_O;

  bool operator==(const eKeyBindings& o) const {
    return fMoveUp == o.fMoveUp && fMoveDown == o.fMoveDown &&
           fMoveLeft == o.fMoveLeft && fMoveRight == o.fMoveRight &&
           fPause == o.fPause && fRotate == o.fRotate &&
           fClone == o.fClone && fDemolish == o.fDemolish &&
           fSpeedUp == o.fSpeedUp && fSpeedDown == o.fSpeedDown &&
           fQuickSave == o.fQuickSave && fObjectives == o.fObjectives;
  }
  bool operator!=(const eKeyBindings& o) const { return !(*this == o); }
};

struct eSettings {
  bool fTinyTextures = true;
  bool fSmallTextures = true;
  bool fMediumTextures = true;
  bool fLargeTextures = true;
  bool fFullscreen = true;
  eResolution fRes = eResolution(1920, 1080);
  std::string fLanguage = "en";
  std::string fAudioLanguage = "en";
  std::string fLeader = "";
  // Timed autosave: every fAutosaveMinutes of play, rotating through
  // "autosave 1.ez" (newest) .. "autosave <fAutosaveSlots>.ez". 0 disables.
  int fAutosaveMinutes = 10;
  int fAutosaveSlots = 5;
  eKeyBindings fKeyBindings;

  std::vector<eTileSize> availableSizes() const;

  void write() const;
  void read();
};

#endif // ESETTINGS_H

