#ifndef EMUSIC_H
#define EMUSIC_H

#include "emusicvector.h"

#include <functional>
#include <memory>
#include <map>

enum class eMusicType {
    none, setup, music, battle
};

class eMusic {
public:
    eMusic();

    static void loadMenu();
    static void load();
    static bool loaded();

    static void incTime();

    static void playMenuMusic();
    static void playRandomMusic();
    static void playRandomBattleMusic();
    static void playMissionIntroMusic();
    static void playMissionVictoryMusic();
    static void playCampaignVictoryMusic();

    static bool playCampaignVoice(const std::string& path);
    static void clearCampaignVoices();

    // Without a music object (the embedded core, which has no audio device) the simulation's music requests go to
    // this function by name: "menu", "city", "battle", "mission_intro", "mission_victory" or "campaign_victory".
    // Before this existed an invasion in the embedded core dereferenced the missing object.
    using eModeSink = std::function<void(const std::string&)>;
    static void setModeSink(const eModeSink& sink);
private:
    static void mode(const char* name);
    void incTimeImpl();

    void playMenuMusicImpl();
    void playRandomMusicImpl();
    void playRandomBattleMusicImpl();
    void playMissionIntroMusicImpl();
    void playMissionVictoryMusicImpl();
    void playCampaignVictoryMusicImpl();
    bool playCampaignVoiceImpl(const std::string& path);
    void clearCampaignVoicesImpl();

    void loadImpl();
    void loadMenuImpl();
    static eMusic* sInstance;

    bool mLoaded{false};
    bool mMenuLoaded{false};
    eMusicType mMusicType{eMusicType::none};

    std::map<std::string, std::shared_ptr<eMusicVector>> mCampaignVoice;

    eMusicVector mSetupMusic;
    eMusicVector mMusic;
    eMusicVector mBattleMusic;
    eMusicVector mMissionIntro;
    eMusicVector mMissionVictory;
    eMusicVector mCampaignVictory;
};

#endif // EMUSIC_H
