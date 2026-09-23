#ifndef ESETTINGS_H
#define ESETTINGS_H

#include "engine/etile.h"
#include "widgets/eresolution.h"

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

  std::vector<eTileSize> availableSizes() const;

  void write() const;
  void read();
};

#endif // ESETTINGS_H
