#ifndef EADVENTURELIST_H
#define EADVENTURELIST_H

#include <string>
#include <vector>

#include "engine/ecampaign.h"

// The adventures a new game can start from: the campaigns of the engine's own Adventures folder and every .pak
// found under the game's Adventures folder, with their titles and introductions in the current language. The
// SDL menu and the embedded Godot front end list the same adventures.
namespace eAdventureList {
bool readPakGlossary(const std::string& filename, eCampaignGlossary& glossary);
std::vector<eCampaignGlossary> scan();
}

#endif // EADVENTURELIST_H
