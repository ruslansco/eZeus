#ifndef EEDITORSESSION_H
#define EEDITORSESSION_H

#include <memory>
#include <sstream>
#include <string>

class eCampaign;
class eGameBoard;

// The adventure editor of the SDL game (eEditorMainMenu, eEpisodesWidget, eEditorSettingsMenu, the goal and event
// editors, the world map's city settings and the terrain panel) as commands of the embedded core, for the Godot editor.
// Every change is made to the campaign the way the SDL widgets make it; the answers are JSON, worded by the game's own
// texts. A form is a list of fields: {id, label, kind: int|choice|bool, value, min, max, options:[{value, label}]}; a
// field is changed by its id. Saving writes the campaign as the SDL editor does (eCampaign::save).
class eEditorSession {
public:
    explicit eEditorSession(const std::shared_ptr<eCampaign>& campaign);

    eCampaign& campaign() { return *mCampaign; }
    eGameBoard& board();

    // `action` is the command's first word (all begin with "editor"); `in` holds the rest.
    std::string command(const std::string& action, std::istringstream& in);
    bool saved() const { return !mChanged; }
private:
    std::string overview();
    std::string episode(bool colony, int index);
    std::string event(bool colony, int index, int cid, int number);
    std::string world();
    std::string city(int index);

    std::shared_ptr<eCampaign> mCampaign;
    bool mChanged = false;
};

#endif // EEDITORSESSION_H
